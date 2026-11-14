#!/usr/bin/env python3
"""Loopback-only, read-only Ternux Control Center web client."""
from __future__ import annotations

import argparse
import ipaddress
import json
import os
import secrets
import shutil
import subprocess
import sys
import threading
import time
import urllib.parse
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

MAX_SNAPSHOT = 512 * 1024
MAX_HTTP_CLIENTS = 8
SESSION_TTL_SECONDS = 3600
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
                env={**os.environ, "TERNUX_JSON": "1"},
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


class LocalServer(ThreadingHTTPServer):
    daemon_threads = True
    allow_reuse_address = False

    request_queue_size = 16

    def __init__(self, server_address, handler, token: str, asset_dir: Path):
        self.token = token
        self.token_expires = time.monotonic() + SESSION_TTL_SECONDS
        self.asset_dir = asset_dir.resolve(strict=True)
        self.client_slots = threading.BoundedSemaphore(MAX_HTTP_CLIENTS)
        super().__init__(server_address, handler)
        self.local_host = f"127.0.0.1:{self.server_port}"
        self.local_origin = f"http://{self.local_host}"

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
        self.close_connection = True

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

    def do_HEAD(self):
        if not self._is_loopback_request():
            self._write(403, b"Forbidden\n", "text/plain; charset=utf-8")
            return
        self._write(405, b"Read-only Control Center\n", "text/plain; charset=utf-8")

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
        self._write(404, b"Not found\n", "text/plain; charset=utf-8")

    def do_POST(self):
        if not self._is_loopback_request():
            self._write(403, b"Forbidden\n", "text/plain; charset=utf-8")
            return
        self._write(405, b"Read-only Control Center\n", "text/plain; charset=utf-8")

    def do_PUT(self):
        self.do_POST()

    def do_DELETE(self):
        self.do_POST()

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
    print("Ternux Control Center (read-only)", flush=True)
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
    parser = argparse.ArgumentParser(description="Run the loopback-only read-only Ternux Control Center.", allow_abbrev=False)
    parser.add_argument("--no-open", action="store_true", help="print the local URL without opening a browser")
    args = parser.parse_args(argv)
    try:
        return serve(open_browser=not args.no_open)
    except (OSError, RuntimeError) as exc:
        print(f"[control-center] {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
