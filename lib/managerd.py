#!/usr/bin/env python3
"""Small, explicit, read-only Unix-socket transport for the Ternux manager."""
from __future__ import annotations

import json
import fcntl
import os
import re
import select
import signal
import socket
import stat
import struct
import subprocess
import sys
import threading
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

SCHEMA_VERSION = "1.0.0"
MAX_REQUEST = 8192
MAX_RESPONSE = 262144
MAX_CLIENTS = 8
READ_TIMEOUT = 5.0
OPERATIONS = {
    "manager.displays": "displays",
    "manager.status": "status",
    "manager.guests": "guests",
    "manager.capabilities": "capabilities",
}
UUID4 = re.compile(r"^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$")
stop_event = threading.Event()
slots = threading.BoundedSemaphore(MAX_CLIENTS)


def socket_path() -> Path:
    prefix = os.environ.get("PREFIX", "/data/data/com.termux/files/usr")
    return Path(prefix) / "var/lib/ternux/control/manager.sock"


def error_response(request_id: str, code: str, message: str, retryable: bool = False) -> dict:
    return {
        "schema_version": SCHEMA_VERSION,
        "request_id": request_id,
        "status": "error",
        "error": {"code": code, "message": message[:2048], "retryable": retryable},
    }


def strict_json_object(pairs: list[tuple[str, object]]) -> dict:
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError("INVALID_JSON")
        result[key] = value
    return result


def validate_request(value: object) -> tuple[str, str]:
    if not isinstance(value, dict) or set(value) != {"schema_version", "request_id", "operation", "arguments"}:
        raise ValueError("INVALID_REQUEST")
    request_id = value["request_id"]
    if not isinstance(request_id, str) or not UUID4.fullmatch(request_id):
        raise ValueError("INVALID_REQUEST_ID")
    if value["schema_version"] != SCHEMA_VERSION:
        raise ValueError("UNSUPPORTED_SCHEMA_VERSION")
    operation = value["operation"]
    if not isinstance(operation, str):
        raise ValueError("UNKNOWN_OPERATION")
    if operation not in OPERATIONS:
        raise ValueError("UNKNOWN_OPERATION")
    if value["arguments"] != {} or not isinstance(value["arguments"], dict):
        raise ValueError("INVALID_ARGUMENTS")
    return request_id, operation


def cli_path() -> str:
    prefix = os.environ.get("PREFIX", "/data/data/com.termux/files/usr")
    return str(Path(prefix) / "bin/ternux")


def handle_payload(payload: bytes) -> bytes:
    request_id = "00000000-0000-4000-8000-000000000000"
    try:
        if not payload.endswith(b"\n") or payload.count(b"\n") != 1:
            raise ValueError("INVALID_FRAMING")
        request = json.loads(payload[:-1].decode("utf-8"), object_pairs_hook=strict_json_object)
        request_id, operation = validate_request(request)
        command = [cli_path(), "manager", OPERATIONS[operation], "--json"]
        completed = subprocess.run(
            command,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            timeout=15,
            check=False,
            env=os.environ.copy(),
        )
        if completed.returncode != 0:
            return json.dumps(error_response(request_id, "MANAGER_OPERATION_FAILED", "The read-only manager operation failed.", True), separators=(",", ":")).encode() + b"\n"
        try:
            result = json.loads(completed.stdout.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            raise ValueError("INVALID_MANAGER_RESPONSE") from exc
        if not isinstance(result, dict) or result.get("command") != operation:
            raise ValueError("INVALID_MANAGER_RESPONSE")
        response = {"schema_version": SCHEMA_VERSION, "request_id": request_id, "status": "ok", "result": result}
        encoded = json.dumps(response, separators=(",", ":"), ensure_ascii=False).encode("utf-8") + b"\n"
        if len(encoded) > MAX_RESPONSE:
            return json.dumps(error_response(request_id, "RESPONSE_TOO_LARGE", "The manager response exceeded the transport limit."), separators=(",", ":")).encode() + b"\n"
        return encoded
    except subprocess.TimeoutExpired:
        response = error_response(request_id, "OPERATION_TIMEOUT", "The manager operation timed out.", True)
    except (UnicodeDecodeError, json.JSONDecodeError):
        response = error_response(request_id, "INVALID_JSON", "Request must be valid UTF-8 JSON.")
    except ValueError as exc:
        code = str(exc)
        messages = {
            "INVALID_JSON": "Request must be valid UTF-8 JSON without duplicate fields.",
            "INVALID_FRAMING": "Send exactly one newline-terminated JSON request.",
            "INVALID_REQUEST": "Request fields do not match the v1 contract.",
            "INVALID_REQUEST_ID": "request_id must be a UUIDv4.",
            "UNSUPPORTED_SCHEMA_VERSION": "This service supports schema version 1.0.0.",
            "UNKNOWN_OPERATION": "The requested operation is not available.",
            "INVALID_ARGUMENTS": "This operation accepts an empty arguments object.",
            "INVALID_MANAGER_RESPONSE": "The manager returned an invalid response.",
        }
        response = error_response(request_id, code, messages.get(code, "The request is invalid."))
    except OSError:
        response = error_response(request_id, "MANAGER_UNAVAILABLE", "The Ternux CLI could not be started.", True)
    return json.dumps(response, separators=(",", ":"), ensure_ascii=False).encode("utf-8") + b"\n"


def peer_is_same_uid(client: socket.socket) -> bool:
    # Linux/Android provides SO_PEERCRED. Refuse the connection if the kernel
    # cannot establish its owner rather than trusting socket filesystem mode.
    option = getattr(socket, "SO_PEERCRED", None)
    if option is None:
        return False
    try:
        _pid, uid, _gid = struct.unpack("3i", client.getsockopt(socket.SOL_SOCKET, option, struct.calcsize("3i")))
        return uid == os.getuid()
    except (OSError, struct.error):
        return False


def serve_client(client: socket.socket) -> None:
    try:
        if not peer_is_same_uid(client):
            return
        deadline = time.monotonic() + READ_TIMEOUT
        chunks = bytearray()
        while len(chunks) <= MAX_REQUEST:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise TimeoutError("request read timed out")
            client.settimeout(remaining)
            part = client.recv(min(2048, MAX_REQUEST + 1 - len(chunks)))
            if not part:
                break
            chunks.extend(part)
            if b"\n" in part:
                break
        if len(chunks) > MAX_REQUEST:
            # Drain until EOF/timeout so closing the oversized request does
            # not discard unread bytes and reset the error response.
            while True:
                try:
                    remaining = deadline - time.monotonic()
                    if remaining <= 0:
                        break
                    client.settimeout(remaining)
                    if not client.recv(4096):
                        break
                except (OSError, TimeoutError):
                    break
            data = json.dumps(error_response("00000000-0000-4000-8000-000000000000", "REQUEST_TOO_LARGE", "Request exceeds 8192 bytes."), separators=(",", ":")).encode() + b"\n"
        else:
            data = handle_payload(bytes(chunks))
        client.sendall(data)
    except (OSError, TimeoutError):
        pass
    finally:
        client.close()
        slots.release()


def prepare_parent(path: Path) -> None:
    parent = path.parent
    parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    prefix = Path(os.environ.get("PREFIX", "/data/data/com.termux/files/usr"))
    try:
        relative = parent.relative_to(prefix)
    except ValueError as exc:
        raise RuntimeError("manager socket directory must remain beneath PREFIX") from exc
    component = prefix
    for name in relative.parts:
        component = component / name
        if component.is_symlink():
            raise RuntimeError("manager socket path contains a symlink")
    if parent.is_symlink() or not parent.is_dir():
        raise RuntimeError("manager socket directory must be a real directory")
    os.chmod(parent, 0o700)
    if parent.stat().st_uid != os.getuid():
        raise RuntimeError("manager socket directory is not owned by this Termux user")


def acquire_instance_lock(path: Path) -> int:
    lock_path = path.with_name("manager.lock")
    if lock_path.is_symlink():
        raise RuntimeError("refusing a symlinked manager lock")
    flags = os.O_CREAT | os.O_RDWR | getattr(os, "O_NOFOLLOW", 0)
    descriptor = os.open(lock_path, flags, 0o600)
    metadata = os.fstat(descriptor)
    if not stat.S_ISREG(metadata.st_mode) or metadata.st_uid != os.getuid():
        os.close(descriptor)
        raise RuntimeError("manager lock must be a regular file owned by this Termux user")
    os.fchmod(descriptor, 0o600)
    try:
        fcntl.flock(descriptor, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError as exc:
        os.close(descriptor)
        raise RuntimeError("manager service is already running") from exc
    return descriptor


def serve() -> int:
    path = socket_path()
    prepare_parent(path)
    lock_fd = acquire_instance_lock(path)
    if path.is_symlink() or (path.exists() and not stat.S_ISSOCK(path.lstat().st_mode)):
        os.close(lock_fd)
        raise RuntimeError("refusing to replace a non-socket manager path")
    try:
        server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    except OSError:
        os.close(lock_fd)
        raise
    bound_identity = None
    try:
        try:
            server.bind(str(path))
            bound_stat = path.lstat()
            bound_identity = (bound_stat.st_dev, bound_stat.st_ino)
        except OSError as exc:
            import errno
            if exc.errno not in (errno.EADDRINUSE, errno.EAGAIN):
                raise
            probe = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            try:
                probe.settimeout(0.5)
                probe.connect(str(path))
            except OSError as probe_error:
                if probe_error.errno == errno.ENOENT:
                    server.bind(str(path))
                elif probe_error.errno == errno.ECONNREFUSED:
                    stale = path.lstat()
                    if not stat.S_ISSOCK(stale.st_mode):
                        raise RuntimeError("manager socket path changed while checking stale state")
                    current = path.lstat()
                    if (current.st_dev, current.st_ino) != (stale.st_dev, stale.st_ino):
                        raise RuntimeError("manager socket changed while checking stale state")
                    path.unlink()
                    server.bind(str(path))
                else:
                    raise RuntimeError("cannot prove whether the existing manager socket is stale; refusing to replace it") from probe_error
                bound_stat = path.lstat()
                bound_identity = (bound_stat.st_dev, bound_stat.st_ino)
            else:
                raise RuntimeError("manager service is already running")
            finally:
                probe.close()
        os.chmod(path, 0o600)
        server.listen(MAX_CLIENTS)
        signal.signal(signal.SIGTERM, lambda _signum, _frame: stop_event.set())
        signal.signal(signal.SIGINT, lambda _signum, _frame: stop_event.set())
        print(f"Ternux manager service listening on {path} (read-only; Ctrl-C to stop)", flush=True)
        with ThreadPoolExecutor(max_workers=MAX_CLIENTS, thread_name_prefix="ternux-manager") as workers:
            while not stop_event.is_set():
                readable, _, _ = select.select([server], [], [], 0.5)
                if not readable:
                    continue
                client, _ = server.accept()
                if not slots.acquire(blocking=False):
                    client.close()
                    continue
                try:
                    workers.submit(serve_client, client)
                except RuntimeError:
                    client.close()
                    slots.release()
    finally:
        server.close()
        try:
            current = path.lstat()
            if bound_identity == (current.st_dev, current.st_ino) and stat.S_ISSOCK(current.st_mode):
                path.unlink()
        except OSError:
            pass
        os.close(lock_fd)
    return 0


if __name__ == "__main__":
    if sys.argv[1:] != ["serve"]:
        print("Usage: python3 managerd.py serve", file=sys.stderr)
        raise SystemExit(2)
    try:
        raise SystemExit(serve())
    except (OSError, RuntimeError) as exc:
        print(f"[managerd] {exc}", file=sys.stderr)
        raise SystemExit(1)
