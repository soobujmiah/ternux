#!/usr/bin/env python3
"""Device-safe integration checks for the explicit read-only manager socket."""
import json
import os
import socket
import subprocess
import tempfile
import time
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DAEMON = ROOT / "lib/managerd.py"
CLI = ROOT / "bin/ternux"


class ManagerServiceTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="txm-")
        self.prefix = Path(self.tmp.name)
        (self.prefix / "bin").mkdir()
        wrapper = self.prefix / "bin/ternux"
        wrapper.write_text(
            "#!/bin/sh\n"
            f"export TERNUX_LIB_DIR={str(ROOT / 'lib')!r}\n"
            f"exec bash {str(CLI)!r} \"$@\"\n"
        )
        wrapper.chmod(0o755)
        self.env = os.environ.copy()
        self.env["PREFIX"] = str(self.prefix)
        self.env["TERNUX_LIB_DIR"] = str(ROOT / "lib")
        self.socket_path = self.prefix / "var/lib/ternux/control/manager.sock"
        self.proc = self.start_server()
        deadline = time.monotonic() + 5
        ready = False
        while time.monotonic() < deadline:
            if self.proc.poll() is not None:
                self.fail("service exited before binding its socket")
            try:
                with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as probe:
                    probe.settimeout(0.1)
                    probe.connect(str(self.socket_path))
                ready = True
                break
            except OSError:
                time.sleep(0.02)
        self.assertTrue(ready, "service did not begin listening")
        self.assertTrue(self.socket_path.exists(), "service did not bind socket")

    def tearDown(self):
        if getattr(self, "proc", None) and self.proc.poll() is None:
            self.proc.terminate()
            self.proc.wait(timeout=5)
        self.tmp.cleanup()

    def start_server(self):
        return subprocess.Popen(
            ["python3", str(DAEMON), "serve"], env=self.env,
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )

    def send(self, payload: bytes) -> dict:
        client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        client.settimeout(20)
        client.connect(str(self.socket_path))
        client.sendall(payload)
        client.shutdown(socket.SHUT_WR)
        response = bytearray()
        while True:
            part = client.recv(8192)
            if not part:
                break
            response.extend(part)
        client.close()
        return json.loads(response)

    @staticmethod
    def request(operation="manager.capabilities", **changes):
        value = {
            "schema_version": "1.0.0",
            "request_id": "a4b1dd90-2a51-4bde-97d1-7d67f47c5021",
            "operation": operation,
            "arguments": {},
        }
        value.update(changes)
        return (json.dumps(value) + "\n").encode()

    def test_socket_is_private_and_read_only_request_succeeds(self):
        self.assertEqual(self.socket_path.parent.stat().st_mode & 0o777, 0o700)
        self.assertEqual(self.socket_path.stat().st_mode & 0o777, 0o600)
        self.assertEqual((self.socket_path.parent / "manager.lock").stat().st_mode & 0o777, 0o600)
        reply = self.send(self.request())
        self.assertEqual(reply["request_id"], "a4b1dd90-2a51-4bde-97d1-7d67f47c5021")
        self.assertEqual(reply["status"], "ok")
        self.assertEqual(reply["result"]["command"], "manager.capabilities")

    def test_all_read_only_operations_are_served(self):
        for operation in ("manager.status", "manager.guests", "manager.capabilities"):
            with self.subTest(operation=operation):
                reply = self.send(self.request(operation))
                self.assertEqual(reply["status"], "ok")
                self.assertEqual(reply["result"]["command"], operation)

    def test_invalid_schema_operation_arguments_and_framing_fail_closed(self):
        cases = [
            (b"not-json\n", "INVALID_JSON"),
            (b'{"schema_version":"1.0.0","schema_version":"1.0.0","request_id":"a4b1dd90-2a51-4bde-97d1-7d67f47c5021","operation":"manager.capabilities","arguments":{}}\n', "INVALID_JSON"),
            (self.request(schema_version="9.0.0"), "UNSUPPORTED_SCHEMA_VERSION"),
            (self.request(operation="manager.start"), "UNKNOWN_OPERATION"),
            (self.request(arguments={"shell": "arbitrary command"}), "INVALID_ARGUMENTS"),
            (self.request()[:-1], "INVALID_FRAMING"),
            (self.request() + b"{}\n", "INVALID_FRAMING"),
        ]
        for payload, code in cases:
            with self.subTest(code=code):
                self.assertEqual(self.send(payload)["error"]["code"], code)

    def test_oversized_input_is_rejected(self):
        self.assertEqual(self.send(b"x" * 9000)["error"]["code"], "REQUEST_TOO_LARGE")

    def test_concurrent_clients_and_graceful_shutdown(self):
        replies = []
        failures = []

        def call():
            try:
                replies.append(self.send(self.request()))
            except Exception as exc:  # make thread failures visible to unittest
                failures.append(exc)

        import threading
        clients = [threading.Thread(target=call) for _ in range(4)]
        for client in clients:
            client.start()
        for client in clients:
            client.join(timeout=20)
        self.assertFalse(failures)
        self.assertEqual(len(replies), 4)
        self.assertTrue(all(reply["status"] == "ok" for reply in replies))
        self.proc.terminate()
        self.proc.wait(timeout=5)
        self.assertFalse(self.socket_path.exists())

    def test_stale_socket_is_recovered(self):
        self.proc.terminate()
        self.proc.wait(timeout=5)
        stale = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        stale.bind(str(self.socket_path))
        stale.close()
        self.proc = self.start_server()
        deadline = time.monotonic() + 5
        ready = False
        while time.monotonic() < deadline:
            if self.proc.poll() is not None:
                break
            try:
                with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as probe:
                    probe.settimeout(0.1)
                    probe.connect(str(self.socket_path))
                ready = True
                break
            except OSError:
                time.sleep(0.02)
        self.assertTrue(ready, "service failed to recover stale socket")
        self.assertEqual(self.send(self.request())["status"], "ok")

    def test_second_service_refuses_live_socket_without_removing_it(self):
        result = subprocess.run(
            ["python3", str(DAEMON), "serve"], env=self.env,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=5,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(b"already running", result.stderr)
        self.assertTrue(self.socket_path.exists())
        self.assertEqual(self.send(self.request())["status"], "ok")


if __name__ == "__main__":
    unittest.main(verbosity=2)
