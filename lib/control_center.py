#!/usr/bin/env python3
"""Loopback-only Ternux Control Center web client and guest action adapter."""
from __future__ import annotations

import argparse
import fcntl
import hashlib
import ipaddress
import json
import os
import re
import secrets
import shutil
import signal
import stat
import subprocess
import sys
import threading
import time
import urllib.parse
import uuid
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

MAX_SNAPSHOT = 512 * 1024
MAX_HTTP_CLIENTS = 8
MAX_REQUEST_BODY = 8192
MAX_JOBS = 512
JOB_RETENTION_SECONDS = 30 * 24 * 60 * 60
SESSION_TTL_SECONDS = 3600
PLAN_TTL_SECONDS = 120
GUEST_NAME = re.compile(r"^[a-z][a-z0-9._-]{0,63}$")
IDEMPOTENCY_KEY = re.compile(r"^[A-Za-z0-9._:-]{16,128}$")
COMMANDS = ("status", "guests", "displays", "capabilities")


def cli_path() -> Path:
    prefix = Path(os.environ.get("PREFIX", "/data/data/com.termux/files/usr"))
    candidate = prefix / "bin/ternux"
    if candidate.is_file():
        return candidate
    raise RuntimeError("Ternux CLI is missing from PREFIX/bin.")


def read_snapshot() -> dict:
    cli = cli_path()
    snapshot = {}
    for command in COMMANDS:
        try:
            completed = subprocess.run(
                [str(cli), "manager", command, "--json"],
                stdin=subprocess.DEVNULL,
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                timeout=12,
                check=False,
                env={**{key: value for key, value in os.environ.items() if key != "LD_LIBRARY_PATH"}, "TERNUX_JSON": "1"},
            )
        except subprocess.TimeoutExpired as exc:
            raise RuntimeError("A manager read operation timed out.") from exc
        if len(completed.stdout) > MAX_SNAPSHOT:
            raise RuntimeError("The manager snapshot exceeded its size limit.")
        try:
            value = json.loads(completed.stdout.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            raise RuntimeError("The manager returned invalid JSON.") from exc
        if not isinstance(value, dict) or value.get("command") != f"manager.{command}":
            raise RuntimeError("The manager returned an unexpected response.")
        snapshot[command] = value
    payload = {"schema_version": "1.0.0", "read_only": True, "snapshot": snapshot}
    if len(json.dumps(payload, ensure_ascii=False).encode("utf-8")) > MAX_SNAPSHOT:
        raise RuntimeError("The combined manager snapshot exceeded its size limit.")
    return payload


def _strict_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError("duplicate JSON field")
        result[key] = value
    return result


def _decode_request(handler) -> dict:
    content_type = handler.headers.get_content_type()
    if content_type != "application/json":
        raise ValueError("Content-Type must be application/json")
    if handler.headers.get("Transfer-Encoding") is not None:
        raise ValueError("Transfer-Encoding is not supported")
    raw_length = handler.headers.get("Content-Length", "")
    if not raw_length.isdecimal():
        raise ValueError("Content-Length is required")
    length = int(raw_length)
    if length < 1 or length > MAX_REQUEST_BODY:
        raise ValueError("Request body exceeds the limit")
    body = handler.rfile.read(length)
    if len(body) != length:
        raise ValueError("Request body is incomplete")
    value = json.loads(body.decode("utf-8"), object_pairs_hook=_strict_object)
    if not isinstance(value, dict):
        raise ValueError("Request body must be a JSON object")
    return value


def _control_jobs_dir(create: bool = False) -> Path:
    prefix = Path(os.environ.get("PREFIX", "/data/data/com.termux/files/usr"))
    base = prefix / "var/lib/ternux/control"
    jobs = base / "jobs"
    if create:
        for directory in (prefix / "var", prefix / "var/lib", prefix / "var/lib/ternux", base, jobs):
            try:
                directory.mkdir(mode=0o700)
            except FileExistsError:
                pass
            info = directory.lstat()
            if not stat.S_ISDIR(info.st_mode):
                raise RuntimeError("The manager job directory is not a safe directory.")
            if directory in {base, jobs} and info.st_mode & 0o077:
                os.chmod(directory, 0o700)
    else:
        if not jobs.exists():
            return jobs
        if jobs.is_symlink() or not jobs.is_dir():
            raise RuntimeError("The manager job directory is not a safe directory.")
    return jobs


def _control_server_lock() -> int:
    jobs = _control_jobs_dir(create=True)
    path = jobs.parent / "server.lock"
    fd = os.open(path, os.O_CREAT | os.O_RDWR | getattr(os, "O_NOFOLLOW", 0), 0o600)
    try:
        os.fchmod(fd, 0o600)
        fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        return fd
    except BlockingIOError:
        os.close(fd)
        raise RuntimeError("The Ternux Control Center is already running.") from None
    except BaseException:
        os.close(fd)
        raise


def _job_lock(jobs: Path):
    jobs.mkdir(parents=True, mode=0o700, exist_ok=True)
    lock_path = jobs / ".lock"
    fd = os.open(lock_path, os.O_CREAT | os.O_RDWR | getattr(os, "O_NOFOLLOW", 0), 0o600)
    os.fchmod(fd, 0o600)
    fcntl.flock(fd, fcntl.LOCK_EX)
    return fd


def _read_job(path: Path) -> dict:
    flags = os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0)
    fd = os.open(path, flags)
    try:
        info = os.fstat(fd)
        if not stat.S_ISREG(info.st_mode) or info.st_size > MAX_REQUEST_BODY * 4:
            raise RuntimeError("A manager job record is invalid.")
        with os.fdopen(fd, "r", encoding="utf-8", closefd=False) as stream:
            value = json.load(stream, object_pairs_hook=_strict_object)
    finally:
        os.close(fd)
    if not isinstance(value, dict) or value.get("id") != path.stem:
        raise RuntimeError("A manager job record is invalid.")
    return value


def _write_job(jobs: Path, value: dict):
    jobs.mkdir(parents=True, mode=0o700, exist_ok=True)
    name = value["id"] + ".json"
    final = jobs / name
    temporary = jobs / ("." + name + "." + secrets.token_hex(8) + ".tmp")
    data = json.dumps(value, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    if len(data) > MAX_REQUEST_BODY * 4:
        raise RuntimeError("The manager job record exceeded its size limit.")
    flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL | getattr(os, "O_NOFOLLOW", 0)
    fd = os.open(temporary, flags, 0o600)
    try:
        with os.fdopen(fd, "wb") as stream:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, final)
        dir_fd = os.open(jobs, os.O_RDONLY | getattr(os, "O_DIRECTORY", 0))
        try:
            os.fsync(dir_fd)
        finally:
            os.close(dir_fd)
    finally:
        try:
            temporary.unlink()
        except FileNotFoundError:
            pass


def _public_job(value: dict) -> dict:
    return {key: value[key] for key in ("id", "kind", "guest", "state", "phase", "created_at", "updated_at", "cancelable", "error") if key in value}


def _snapshot_guest(snapshot: dict, guest: str) -> tuple[dict, dict]:
    data = snapshot.get("snapshot", {})
    guests = data.get("guests", {}).get("guests")
    displays = data.get("displays", {}).get("guests")
    if not isinstance(guests, list) or not isinstance(displays, list):
        raise RuntimeError("Manager guest state is unavailable.")
    item = next((row for row in guests if isinstance(row, dict) and row.get("name") == guest), None)
    display = next((row for row in displays if isinstance(row, dict) and row.get("name") == guest), None)
    if item is None or item.get("desktop_profile") is not True or display is None:
        raise ValueError("Only an installed Ternux desktop guest can use this action.")
    if not isinstance(display.get("running"), bool):
        raise RuntimeError("Manager guest lifecycle state is unavailable.")
    return item, display


def _plan_snapshot(operation: str, guest: str) -> dict:
    snapshot = read_snapshot()
    if any(snapshot.get("snapshot", {}).get(name, {}).get("status") not in {"ok", "available"} for name in ("guests", "displays")):
        raise RuntimeError("Manager guest state is unavailable.")
    item, display = _snapshot_guest(snapshot, guest)
    before = bool(display["running"])
    plan = {
        "schema_version": "1.0.0",
        "operation": operation,
        "guest": guest,
        "observed": {
            "running": before,
            "current_display": display.get("current_display"),
            "registry_lifecycle": display.get("registry_lifecycle"),
            "target_display": display.get("target_display"),
            "target_conflict": display.get("target_conflict"),
            "target_socket_present": display.get("target_socket_present"),
            "target_lock_present": display.get("target_lock_present"),
            "target_server_running": display.get("target_server_running"),
            "migration_required": display.get("migration_required"),
            "desktop_profile": item["desktop_profile"],
        },
    }
    if display.get("migration_required") is True:
        raise ActionBlocked("A display migration is required before Control Center lifecycle actions. Use the Ternux CLI to stop the guest, migrate the saved display, then start it again.")
    canonical = json.dumps(plan, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    plan["plan_id"] = "sha256:" + hashlib.sha256(canonical).hexdigest()
    plan["already_satisfied"] = before == (operation == "start")
    return plan


def _prune_expired_jobs(jobs: Path):
    if not jobs.exists():
        return
    cutoff = int(time.time()) - JOB_RETENTION_SECONDS
    with os.scandir(jobs) as entries:
        paths = [Path(entry.path) for entry in entries if entry.name.endswith(".json") and entry.is_file(follow_symlinks=False)]
    for path in paths:
        value = _read_job(path)
        if value.get("state") in {"SUCCEEDED", "FAILED", "INTERRUPTED"} and isinstance(value.get("updated_at"), int) and value["updated_at"] < cutoff:
            path.unlink()


def _recover_interrupted_jobs(jobs: Path):
    if not jobs.exists():
        return
    if jobs.is_symlink() or not jobs.is_dir():
        raise RuntimeError("The manager job directory is not a safe directory.")
    with os.scandir(jobs) as entries:
        records = [Path(entry.path) for entry in entries if entry.name.endswith(".json") and entry.is_file(follow_symlinks=False)]
    if len(records) > MAX_JOBS:
        raise RuntimeError("The manager job store is full.")
    fd = _job_lock(jobs)
    try:
        for path in records:
            value = _read_job(path)
            if value.get("state") in {"QUEUED", "RUNNING"}:
                now = int(time.time())
                value.update(state="INTERRUPTED", phase="reconcile-required", updated_at=now,
                             error={"code": "SERVICE_INTERRUPTED", "message": "The previous Control Center session ended before this job recorded completion."})
                _write_job(jobs, value)
    finally:
        os.close(fd)


def _guest_reached_desired_state(operation: str, guest: str, timeout: int) -> bool:
    deadline = time.monotonic() + timeout
    while True:
        try:
            plan = _plan_snapshot(operation, guest)
            if plan["already_satisfied"]:
                return True
        except (RuntimeError, ValueError):
            pass
        if time.monotonic() >= deadline:
            return False
        time.sleep(1)


def _run_guest_action(server, job_id: str):
    jobs = server.jobs_dir
    fd = _job_lock(jobs)
    try:
        path = jobs / (job_id + ".json")
        job = _read_job(path)
        if job.get("state") != "QUEUED":
            return
        now = int(time.time())
        job.update(state="RUNNING", phase="starting" if job["kind"] == "guest.start" else "stopping", updated_at=now)
        _write_job(jobs, job)
    finally:
        os.close(fd)

    operation = "start" if job["kind"] == "guest.start" else "stop"
    timeout = 300 if operation == "start" else 120
    process = None
    try:
        cli = cli_path()
        env = os.environ.copy()
        env.pop("LD_LIBRARY_PATH", None)
        env["TERNUX_JSON"] = "1"
        process = subprocess.Popen(
            [str(cli), operation, job["guest"]], stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, env=env,
            start_new_session=True,
        )
        return_code = process.wait(timeout=timeout)
        if return_code == 0:
            fd = _job_lock(jobs)
            try:
                job = _read_job(jobs / (job_id + ".json"))
                job.update(state="RUNNING", phase="verifying", updated_at=int(time.time()))
                _write_job(jobs, job)
            finally:
                os.close(fd)
            verified = _guest_reached_desired_state(operation, job["guest"], 20)
            state = "SUCCEEDED" if verified else "INTERRUPTED"
            error = None if verified else {"code": "STATE_NOT_CONFIRMED", "message": "The command returned successfully, but Ternux could not confirm the requested guest state. Check status before retrying."}
        else:
            state = "FAILED"
            error = {"code": "LIFECYCLE_COMMAND_FAILED", "message": "Ternux could not complete the requested guest lifecycle action."}
    except subprocess.TimeoutExpired:
        if process is not None:
            try:
                os.killpg(process.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
            try:
                process.wait(timeout=3)
            except subprocess.TimeoutExpired:
                try:
                    os.killpg(process.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                try:
                    process.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    pass
        state = "INTERRUPTED"
        error = {"code": "LIFECYCLE_TIMEOUT", "message": "The action timed out. Check guest status before retrying."}
    except OSError:
        state = "FAILED"
        error = {"code": "TERNUX_CLI_UNAVAILABLE", "message": "The Ternux CLI could not start the requested action."}
    except (ValueError, RuntimeError, subprocess.SubprocessError):
        state = "INTERRUPTED"
        error = {"code": "ACTION_STATE_UNCERTAIN", "message": "The action result could not be confirmed. Check guest status before retrying."}
    fd = _job_lock(jobs)
    try:
        job = _read_job(jobs / (job_id + ".json"))
        job.update(state=state, phase="complete" if state == "SUCCEEDED" else "reconcile-required",
                   updated_at=int(time.time()), error=error)
        _write_job(jobs, job)
    finally:
        os.close(fd)


class ActionBlocked(RuntimeError):
    pass


def _run_guest_action_tracked(server, job_id: str):
    try:
        _run_guest_action(server, job_id)
    finally:
        with server.state_lock:
            server.job_threads.discard(threading.current_thread())


class LocalServer(ThreadingHTTPServer):
    daemon_threads = True
    allow_reuse_address = False

    request_queue_size = 16

    def __init__(self, server_address, handler, token: str, asset_dir: Path):
        self.token = token
        self.token_expires = time.monotonic() + SESSION_TTL_SECONDS
        self.asset_dir = asset_dir.resolve(strict=True)
        self.client_slots = threading.BoundedSemaphore(MAX_HTTP_CLIENTS)
        self.plans = {}
        self.job_threads = set()
        self.state_lock = threading.RLock()
        self.control_lock_fd = _control_server_lock()
        try:
            self.jobs_dir = _control_jobs_dir(create=False)
            _prune_expired_jobs(self.jobs_dir)
            _recover_interrupted_jobs(self.jobs_dir)
            super().__init__(server_address, handler)
            self.local_host = f"127.0.0.1:{self.server_port}"
            self.local_origin = f"http://{self.local_host}"
        except BaseException:
            fcntl.flock(self.control_lock_fd, fcntl.LOCK_UN)
            os.close(self.control_lock_fd)
            raise

    def server_close(self):
        try:
            super().server_close()
        finally:
            fd = getattr(self, "control_lock_fd", None)
            if fd is not None:
                self.control_lock_fd = None
                fcntl.flock(fd, fcntl.LOCK_UN)
                os.close(fd)

    def get_request(self):
        request, address = super().get_request()
        request.settimeout(5.0)
        return request, address

    def process_request(self, request, client_address):
        if not self.client_slots.acquire(blocking=False):
            self.shutdown_request(request)
            return
        try:
            super().process_request(request, client_address)
        except BaseException:
            self.client_slots.release()
            raise

    def process_request_thread(self, request, client_address):
        try:
            super().process_request_thread(request, client_address)
        finally:
            self.client_slots.release()


class Handler(BaseHTTPRequestHandler):
    server: LocalServer
    protocol_version = "HTTP/1.1"
    server_version = "TernuxControl/1"
    sys_version = ""

    def log_message(self, _format, *_args):
        # Do not write bearer credentials or request paths into shell history/logs.
        return

    def _write(self, status: int, body: bytes, content_type: str):
        self.close_connection = True
        try:
            self.send_response(status)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store, max-age=0")
            self.send_header("Pragma", "no-cache")
            self.send_header("X-Content-Type-Options", "nosniff")
            self.send_header("Referrer-Policy", "no-referrer")
            self.send_header("X-Frame-Options", "DENY")
            self.send_header("Permissions-Policy", "camera=(), microphone=(), geolocation=()")
            self.send_header("Content-Security-Policy", "default-src 'self'; script-src 'self'; style-src 'self'; connect-src 'self'; img-src 'self' data:; object-src 'none'; base-uri 'none'; frame-ancestors 'none'; form-action 'none'")
            self.send_header("Connection", "close")
            self.end_headers()
            if self.command != "HEAD":
                self.wfile.write(body)
        except (BrokenPipeError, ConnectionResetError, ConnectionAbortedError):
            # Browsers routinely navigate away while a polling response is in
            # flight. A peer disconnect must not produce a request-thread trace.
            return

    def _is_loopback_request(self) -> bool:
        try:
            address = ipaddress.ip_address(self.client_address[0])
        except ValueError:
            return False
        host = self.headers.get("Host", "").lower()
        if not address.is_loopback or host not in {self.server.local_host, f"localhost:{self.server.server_port}"}:
            return False
        origin = self.headers.get("Origin")
        if origin is not None and origin != self.server.local_origin and origin != f"http://localhost:{self.server.server_port}":
            return False
        return True

    def _authorized(self) -> bool:
        supplied = self.headers.get("Authorization", "")
        return time.monotonic() < self.server.token_expires and secrets.compare_digest(supplied, f"Bearer {self.server.token}")

    def _mutation_authorized(self) -> bool:
        origin = self.headers.get("Origin")
        csrf = self.headers.get("X-Ternux-CSRF", "")
        return (
            self._authorized()
            and origin in {self.server.local_origin, f"http://localhost:{self.server.server_port}"}
            and secrets.compare_digest(csrf, self.server.token)
        )

    def _json(self, status: int, value: dict):
        body = json.dumps(value, ensure_ascii=False, separators=(",", ":")).encode("utf-8") + b"\n"
        self._write(status, body, "application/json; charset=utf-8")

    def do_HEAD(self):
        if not self._is_loopback_request():
            self._write(403, b"Forbidden\n", "text/plain; charset=utf-8")
            return
        self._write(405, b"Method not allowed\n", "text/plain; charset=utf-8")

    def do_GET(self):
        if not self._is_loopback_request():
            self._write(403, b"Forbidden\n", "text/plain; charset=utf-8")
            return
        path = urllib.parse.urlsplit(self.path).path
        if path == "/":
            self._asset("index.html", "text/html; charset=utf-8")
            return
        if path in {"/app.css", "/app.js"}:
            name = path[1:]
            content_type = "text/css; charset=utf-8" if name.endswith(".css") else "text/javascript; charset=utf-8"
            self._asset(name, content_type)
            return
        if path == "/api/v1/snapshot":
            if not self._authorized():
                self._write(401, b'{"error":"AUTH_REQUIRED"}\n', "application/json; charset=utf-8")
                return
            try:
                payload = json.dumps(read_snapshot(), ensure_ascii=False, separators=(",", ":")).encode("utf-8") + b"\n"
            except RuntimeError as exc:
                payload = json.dumps({"error": "SNAPSHOT_UNAVAILABLE", "message": str(exc)}, separators=(",", ":")).encode() + b"\n"
                self._write(503, payload, "application/json; charset=utf-8")
                return
            self._write(200, payload, "application/json; charset=utf-8")
            return
        match = re.fullmatch(r"/api/v1/jobs/([0-9a-f-]{36})", path)
        if match:
            if not self._authorized():
                self._json(401, {"error": "AUTH_REQUIRED"})
                return
            try:
                job_id = str(uuid.UUID(match.group(1)))
                path = _control_jobs_dir(create=False) / (job_id + ".json")
                if path.parent.exists():
                    job = _read_job(path)
                else:
                    self._json(404, {"error": "JOB_NOT_FOUND"})
                    return
            except FileNotFoundError:
                self._json(404, {"error": "JOB_NOT_FOUND"})
                return
            except (ValueError, OSError, RuntimeError):
                self._json(503, {"error": "JOB_STORE_UNAVAILABLE"})
                return
            self._json(200, {"job": _public_job(job)})
            return
        self._write(404, b"Not found\n", "text/plain; charset=utf-8")

    def do_POST(self):
        if not self._is_loopback_request():
            self._write(403, b"Forbidden\n", "text/plain; charset=utf-8")
            return
        path = urllib.parse.urlsplit(self.path).path
        if path not in {"/api/v1/guest-plans", "/api/v1/guest-actions"}:
            self._write(405 if path.startswith("/api/") else 404, b"Method not allowed\n", "text/plain; charset=utf-8")
            return
        if not self._mutation_authorized():
            self._json(403, {"error": "MUTATION_AUTH_REQUIRED"})
            return
        try:
            request = _decode_request(self)
        except (UnicodeDecodeError, json.JSONDecodeError, ValueError):
            self._json(400, {"error": "INVALID_REQUEST"})
            return
        if path == "/api/v1/guest-plans":
            self._create_guest_plan(request)
            return
        if path == "/api/v1/guest-actions":
            self._submit_guest_action(request)
            return
        self._write(404, b"Not found\n", "text/plain; charset=utf-8")

    def _create_guest_plan(self, request: dict):
        if set(request) != {"operation", "guest"}:
            self._json(400, {"error": "INVALID_PLAN_REQUEST"})
            return
        operation, guest = request.get("operation"), request.get("guest")
        if operation not in {"start", "stop"} or not isinstance(guest, str) or not GUEST_NAME.fullmatch(guest):
            self._json(400, {"error": "INVALID_PLAN_REQUEST"})
            return
        try:
            plan = _plan_snapshot(operation, guest)
        except ValueError as exc:
            self._json(404, {"error": "GUEST_NOT_ACTIONABLE", "message": str(exc)})
            return
        except ActionBlocked as exc:
            self._json(409, {"error": "GUEST_ACTION_BLOCKED", "message": str(exc)})
            return
        except RuntimeError:
            self._json(503, {"error": "GUEST_STATE_UNAVAILABLE"})
            return
        confirmation = secrets.token_urlsafe(32)
        expires = time.monotonic() + PLAN_TTL_SECONDS
        with self.server.state_lock:
            now = time.monotonic()
            for plan_id, pending in list(self.server.plans.items()):
                if pending["expires"] <= now or pending["used"]:
                    self.server.plans.pop(plan_id, None)
            if len(self.server.plans) >= 128:
                self._json(429, {"error": "TOO_MANY_PENDING_PLANS"})
                return
            self.server.plans[plan["plan_id"]] = {"plan": plan, "confirmation": confirmation, "expires": expires, "used": False}
        self._json(200, {"status": "confirmation-required", "plan": plan, "confirmation": confirmation, "expires_in": PLAN_TTL_SECONDS})

    def _submit_guest_action(self, request: dict):
        if set(request) != {"plan_id", "confirmation", "idempotency_key"}:
            self._json(400, {"error": "INVALID_ACTION_REQUEST"})
            return
        plan_id, confirmation, idempotency_key = request.get("plan_id"), request.get("confirmation"), request.get("idempotency_key")
        if (not isinstance(plan_id, str) or not re.fullmatch(r"sha256:[a-f0-9]{64}", plan_id)
                or not isinstance(confirmation, str) or len(confirmation) > 128
                or not isinstance(idempotency_key, str) or not IDEMPOTENCY_KEY.fullmatch(idempotency_key)):
            self._json(400, {"error": "INVALID_ACTION_REQUEST"})
            return
        request_digest = hashlib.sha256(plan_id.encode()).hexdigest()
        # The Control Center is private to this Termux app UID. Scope replay keys to
        # that client identity and operation, not to the short-lived browser token.
        client_digest = hashlib.sha256(f"{os.getuid()}\0{idempotency_key}".encode()).hexdigest()
        with self.server.state_lock:
            pending = self.server.plans.get(plan_id)
        try:
            jobs = _control_jobs_dir(create=True)
            idempotency_digest = hashlib.sha256(idempotency_key.encode()).hexdigest()
            lock_fd = _job_lock(jobs)
            try:
                _prune_expired_jobs(jobs)
                records = [Path(entry.path) for entry in os.scandir(jobs) if entry.name.endswith(".json") and entry.is_file(follow_symlinks=False)]
                if len(records) > MAX_JOBS:
                    self._json(507, {"error": "JOB_STORE_FULL"})
                    return
                for record_path in records:
                    existing = _read_job(record_path)
                    if existing.get("client_digest") != client_digest or existing.get("idempotency_digest") != idempotency_digest:
                        continue
                    if existing.get("request_digest") != request_digest:
                        self._json(409, {"error": "IDEMPOTENCY_CONFLICT"})
                        return
                    self._json(200, {"status": "existing", "job": _public_job(existing)})
                    return
                with self.server.state_lock:
                    if pending is None or pending["expires"] <= time.monotonic() or pending["used"] or not secrets.compare_digest(confirmation, pending["confirmation"]):
                        self._json(409, {"error": "CONFIRMATION_INVALID_OR_EXPIRED"})
                        return
                    plan = pending["plan"]
                    pending["used"] = True
            finally:
                os.close(lock_fd)

            operation, guest = plan["operation"], plan["guest"]
            fresh = _plan_snapshot(operation, guest)
            if fresh["plan_id"] != plan_id:
                self._json(409, {"error": "PLAN_STALE", "message": "Guest state changed. Review a new plan."})
                return

            # Reacquire and repeat the idempotency lookup because state validation
            # deliberately runs outside the filesystem lock and may be slow.
            lock_fd = _job_lock(jobs)
            try:
                records = [Path(entry.path) for entry in os.scandir(jobs) if entry.name.endswith(".json") and entry.is_file(follow_symlinks=False)]
                if len(records) >= MAX_JOBS:
                    self._json(507, {"error": "JOB_STORE_FULL"})
                    return
                for record_path in records:
                    existing = _read_job(record_path)
                    if existing.get("client_digest") != client_digest or existing.get("idempotency_digest") != idempotency_digest:
                        continue
                    if existing.get("request_digest") != request_digest:
                        self._json(409, {"error": "IDEMPOTENCY_CONFLICT"})
                        return
                    self._json(200, {"status": "existing", "job": _public_job(existing)})
                    return
                job_id = str(uuid.uuid4())
                now = int(time.time())
                state = "SUCCEEDED" if plan["already_satisfied"] else "QUEUED"
                phase = "already-in-desired-state" if state == "SUCCEEDED" else "queued"
                job = {
                    "id": job_id,
                    "kind": f"guest.{operation}",
                    "guest": guest,
                    "state": state,
                    "phase": phase,
                    "created_at": now,
                    "updated_at": now,
                    "cancelable": False,
                    "request_digest": request_digest,
                    "client_digest": client_digest,
                    "idempotency_digest": idempotency_digest,
                    "plan_id": plan_id,
                    "error": None,
                }
                _write_job(jobs, job)
            finally:
                os.close(lock_fd)
        except ActionBlocked as exc:
            self._json(409, {"error": "GUEST_ACTION_BLOCKED", "message": str(exc)})
            return
        except (OSError, RuntimeError):
            self._json(503, {"error": "JOB_STORE_UNAVAILABLE"})
            return
        if not plan["already_satisfied"]:
            worker = threading.Thread(target=_run_guest_action_tracked, args=(self.server, job_id), daemon=True)
            with self.server.state_lock:
                self.server.job_threads.add(worker)
            worker.start()
        self._json(202, {"status": "accepted", "job": _public_job(job)})

    def do_PUT(self):
        if not self._is_loopback_request():
            self._write(403, b"Forbidden\n", "text/plain; charset=utf-8")
            return
        self._write(405, b"Method not allowed\n", "text/plain; charset=utf-8")

    def do_DELETE(self):
        self.do_PUT()

    def _asset(self, name: str, content_type: str):
        candidate = self.server.asset_dir / name
        try:
            if candidate.parent.resolve(strict=True) != self.server.asset_dir or candidate.is_symlink():
                raise FileNotFoundError
            body = candidate.read_bytes()
        except (OSError, RuntimeError):
            self._write(404, b"Not found\n", "text/plain; charset=utf-8")
            return
        if len(body) > 256 * 1024:
            self._write(500, b"Asset too large\n", "text/plain; charset=utf-8")
            return
        self._write(200, body, content_type)


def serve(open_browser: bool = True) -> int:
    token = secrets.token_urlsafe(32)
    asset_dir = Path(__file__).resolve().parent / "control-center"
    server = LocalServer(("127.0.0.1", 0), Handler, token, asset_dir)
    url = f"{server.local_origin}/#{token}"
    print("Ternux Control Center", flush=True)
    print("Listening on loopback only. Session key expires after one hour; press Ctrl-C to close.", flush=True)
    print(f"Open: {url}", flush=True)
    if open_browser:
        opener = shutil.which("termux-open-url")
        if opener:
            try:
                subprocess.Popen([opener, url], stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
            except OSError:
                pass
        else:
            webbrowser.open(url, new=2, autoraise=False)
    try:
        server.serve_forever(poll_interval=0.25)
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
        print("Control Center stopped.", flush=True)
    return 0


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description="Run the loopback-only Ternux Control Center.", allow_abbrev=False)
    parser.add_argument("--no-open", action="store_true", help="print the local URL without opening a browser")
    args = parser.parse_args(argv)
    try:
        return serve(open_browser=not args.no_open)
    except (OSError, RuntimeError) as exc:
        print(f"[control-center] {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
