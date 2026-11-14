#!/usr/bin/env python3
"""Security and integration tests for the read-only local Control Center."""
from __future__ import annotations

import importlib.util
import json
import os
import signal
import subprocess
import tempfile
import threading
import unittest
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("ternux_control_center", ROOT / "lib/control_center.py")
assert SPEC and SPEC.loader
control = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(control)


class ControlCenterTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="tx-control-")
        self.addCleanup(self.temp.cleanup)
        self.prefix = Path(self.temp.name)
        bindir = self.prefix / "bin"
        bindir.mkdir()
        self.log = self.prefix / "commands.log"
        cli = bindir / "ternux"
        cli.write_text(
            "#!/usr/bin/env python3\n"
            "import json, os, sys\n"
            f"log = {str(self.log)!r}\n"
            "with open(log, 'a', encoding='utf-8') as stream: stream.write(' '.join(sys.argv[1:]) + '\\n')\n"
            "command = sys.argv[2]\n"
            "rows = {\n"
            "'status': {'schema_version':'1.0.0','command':'manager.status','status':'available','guest_manager_available':True,'installed_guest_count':1,'running_desktops':['debian'],'timestamp':'2026-11-14T00:00:00Z'},\n"
            "'guests': {'schema_version':'1.0.0','command':'manager.guests','status':'ok','count':1,'guests':[{'name':'debian','state':'installed','desktop_profile':True,'display':1,'qualification':'device-qualified'}]},\n"
            "'displays': {'schema_version':'1.3.0','command':'manager.displays','status':'ok','native_display':0,'count':1,'migration_preview':{'status':'preview-only','executor_implemented':True,'ready_to_execute':False,'plan_id':'sha256:'+'0'*64},'guests':[{'name':'debian','current_display':1,'target_display':1,'running':True,'target_conflict':False,'migration_action':'keep','migration_blockers':[]}]},\n"
            "'capabilities': {'schema_version':'1.0.0','command':'manager.capabilities','status':'ok','count':4,'operations':[]},\n"
            "}\n"
            "print(json.dumps(rows[command]))\n"
        )
        cli.chmod(0o755)
        self.env = {**os.environ, "PREFIX": str(self.prefix)}
        self.patch = patch.dict(os.environ, self.env)
        self.patch.start()
        self.addCleanup(self.patch.stop)
        self.server = control.LocalServer(("127.0.0.1", 0), control.Handler, "test-session-key", ROOT / "lib/control-center")
        self.thread = threading.Thread(target=self.server.serve_forever, kwargs={"poll_interval": 0.02}, daemon=True)
        self.thread.start()
        self.addCleanup(self.close_server)
        self.origin = f"http://127.0.0.1:{self.server.server_port}"

    def close_server(self):
        if getattr(self, "server", None):
            self.server.shutdown()
            self.server.server_close()
            self.thread.join(timeout=2)

    def request(self, path, *, token=None, host=None, origin=None, method="GET"):
        headers = {}
        if token is not None:
            headers["Authorization"] = f"Bearer {token}"
        if host:
            headers["Host"] = host
        if origin:
            headers["Origin"] = origin
        req = urllib.request.Request(self.origin + path, headers=headers, method=method)
        try:
            return urllib.request.urlopen(req, timeout=3)
        except urllib.error.HTTPError as exc:
            exc.read()
            exc.close()
            return exc

    def test_page_uses_external_assets_and_security_headers(self):
        response = self.request("/")
        self.assertEqual(response.status, 200)
        page = response.read().decode()
        self.assertIn("Ternux Control Center", page)
        self.assertIn('src="app.js"', page)
        app = (ROOT / "lib" / "control-center" / "app.js").read_text()
        self.assertIn("executor_implemented !== true", app)
        self.assertIn("tx manager migrate --apply", app)
        self.assertIn("preview.plan_id", app)
        self.assertIn("default-src 'self'", response.headers["Content-Security-Policy"])
        self.assertEqual(response.headers["Cache-Control"], "no-store, max-age=0")
        self.assertEqual(response.headers["Referrer-Policy"], "no-referrer")

    def test_snapshot_requires_temporary_bearer_and_returns_read_only_data(self):
        denied = self.request("/api/v1/snapshot")
        self.assertEqual(denied.code, 401)
        self.assertFalse(self.log.exists())
        response = self.request("/api/v1/snapshot", token="test-session-key")
        self.assertEqual(response.status, 200)
        payload = json.loads(response.read())
        self.assertEqual(payload["schema_version"], "1.0.0")
        self.assertTrue(payload["read_only"])
        self.assertEqual(payload["snapshot"]["guests"]["guests"][0]["name"], "debian")
        self.assertEqual(payload["snapshot"]["displays"]["migration_preview"]["status"], "preview-only")
        self.assertEqual(self.log.read_text().splitlines(), [f"manager {name} --json" for name in control.COMMANDS])

    def test_manager_command_help_documents_dashboard_and_python_requirement(self):
        completed = subprocess.run(
            ["bash", str(ROOT / "bin/ternux"), "--help", "control"],
            text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=5,
            env={**os.environ, "TERNUX_LIB_DIR": str(ROOT / "lib")},
        )
        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertIn("127.0.0.1", completed.stdout)
        self.assertIn("pkg install python", completed.stdout)

    def test_cli_starts_loopback_dashboard_and_stops_cleanly(self):
        process = subprocess.Popen(
            ["bash", str(ROOT / "bin/ternux"), "control", "--no-open"],
            stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            text=True, env={**os.environ, "PREFIX": str(self.prefix), "TERNUX_LIB_DIR": str(ROOT / "lib")},
        )
        try:
            heading = process.stdout.readline().strip()
            listening = process.stdout.readline().strip()
            open_line = process.stdout.readline().strip()
            self.assertEqual(heading, "Ternux Control Center (read-only)")
            self.assertIn("loopback only", listening)
            self.assertTrue(open_line.startswith("Open: http://127.0.0.1:"), open_line)
            url = urllib.parse.urlsplit(open_line.removeprefix("Open: "))
            base = f"{url.scheme}://{url.netloc}"
            with urllib.request.urlopen(base + "/", timeout=3) as page:
                self.assertEqual(page.status, 200)
            request = urllib.request.Request(
                base + "/api/v1/snapshot",
                headers={"Authorization": f"Bearer {url.fragment}"},
            )
            with urllib.request.urlopen(request, timeout=5) as response:
                snapshot = json.loads(response.read())
            self.assertTrue(snapshot["read_only"])
            schema = json.loads((ROOT / "docs/v3/schemas/control-center-snapshot-v1.schema.json").read_text())
            self.assertEqual(snapshot["schema_version"], schema["properties"]["schema_version"]["const"])
            self.assertEqual(set(snapshot["snapshot"]), set(schema["properties"]["snapshot"]["required"]))
            self.assertEqual(snapshot["snapshot"]["guests"]["guests"][0]["name"], "debian")
        finally:
            if process.poll() is None:
                process.send_signal(signal.SIGINT)
                process.wait(timeout=5)
            if process.stdout:
                process.stdout.close()
            if process.stderr:
                process.stderr.close()
        self.assertEqual(process.returncode, 0)

    def test_expired_session_key_is_rejected(self):
        self.server.token_expires = 0
        response = self.request("/api/v1/snapshot", token="test-session-key")
        self.assertEqual(response.code, 401)
        self.assertFalse(self.log.exists())

    def test_foreign_host_and_origin_are_rejected(self):
        response = self.request("/", host="attacker.example")
        self.assertEqual(response.code, 403)
        response = self.request("/api/v1/snapshot", token="test-session-key", origin="https://attacker.example")
        self.assertEqual(response.code, 403)
        self.assertFalse(self.log.exists())

    def test_unknown_routes_and_mutations_are_not_available(self):
        self.assertEqual(self.request("/api/v1/start", token="test-session-key").code, 404)
        self.assertEqual(self.request("/api/v1/snapshot", token="test-session-key", method="POST").code, 405)
        self.assertEqual(self.request("/api/v1/snapshot", token="test-session-key", method="HEAD").code, 405)
        self.assertFalse(self.log.exists())

    def test_manager_errors_are_preserved_as_status_instead_of_becoming_empty_guest_list(self):
        cli = self.prefix / "bin/ternux"
        cli.write_text(
            "#!/usr/bin/env python3\nimport json,sys\n"
            "command=sys.argv[2]\n"
            "payload={'schema_version':'1.0.0','command':'manager.'+command,'status':'error','code':'GUEST_MANAGER_UNAVAILABLE','message':'proot-distro is not installed.'}\n"
            "print(json.dumps(payload))\n"
            "sys.exit(1)\n"
        )
        cli.chmod(0o755)
        response = self.request("/api/v1/snapshot", token="test-session-key")
        self.assertEqual(response.status, 200)
        payload = json.loads(response.read())
        guests = payload["snapshot"]["guests"]
        self.assertEqual(guests["status"], "error")
        self.assertEqual(guests["code"], "GUEST_MANAGER_UNAVAILABLE")


if __name__ == "__main__":
    unittest.main(verbosity=2)
