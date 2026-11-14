#!/usr/bin/env python3
"""Security and integration tests for the local Ternux Control Center."""
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
import time
from pathlib import Path
from unittest.mock import Mock, patch

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("ternux_control_center", ROOT / "lib/control_center.py")
assert SPEC and SPEC.loader
control = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(control)


class CapturedHTTPError:
    def __init__(self, error):
        self.code = error.code
        self.status = error.code
        self._body = error.read()
        error.close()

    def read(self):
        return self._body


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
            f"state = {str(self.prefix / 'guest-state')!r}\n"
            "with open(log, 'a', encoding='utf-8') as stream: stream.write(' '.join(sys.argv[1:]) + '\\n')\n"
            "if len(sys.argv) > 1 and sys.argv[1] in {'start','stop'}: open(state,'w',encoding='utf-8').write(sys.argv[1]); print(json.dumps({'command':sys.argv[1],'status':'ok'})); sys.exit(0)\n"
            "command = sys.argv[2]\n"
            "rows = {\n"
            "'status': {'schema_version':'1.0.0','command':'manager.status','status':'available','guest_manager_available':True,'installed_guest_count':1,'running_desktops':['debian'],'timestamp':'2026-11-14T00:00:00Z'},\n"
            "'guests': {'schema_version':'1.0.0','command':'manager.guests','status':'ok','count':1,'guests':[{'name':'debian','state':'installed','desktop_profile':True,'display':1,'qualification':'device-qualified'}]},\n"
            "'displays': {'schema_version':'1.3.0','command':'manager.displays','status':'ok','native_display':0,'count':1,'migration_preview':{'status':'preview-only','executor_implemented':True,'ready_to_execute':False,'plan_id':'sha256:'+'0'*64},'guests':[{'name':'debian','current_display':1,'target_display':1,'registry_lifecycle':'READY','running':not os.path.exists(state) or open(state,encoding='utf-8').read() == 'start','target_conflict':False,'migration_required':False,'target_socket_present':False,'target_lock_present':False,'target_server_running':False,'migration_action':'keep','migration_blockers':[]}]},\n"
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
            for worker in tuple(self.server.job_threads):
                worker.join(timeout=5)

    def request(self, path, *, token=None, csrf=None, host=None, origin=None, method="GET", payload=None):
        headers = {}
        body = None
        if token is not None:
            headers["Authorization"] = f"Bearer {token}"
        if csrf is not None:
            headers["X-Ternux-CSRF"] = csrf
        if host:
            headers["Host"] = host
        if origin:
            headers["Origin"] = origin
        if payload is not None:
            body = json.dumps(payload).encode()
            headers["Content-Type"] = "application/json"
        req = urllib.request.Request(self.origin + path, data=body, headers=headers, method=method)
        try:
            return urllib.request.urlopen(req, timeout=3)
        except urllib.error.HTTPError as exc:
            return CapturedHTTPError(exc)

    def test_page_uses_external_assets_and_security_headers(self):
        response = self.request("/")
        self.assertEqual(response.status, 200)
        page = response.read().decode()
        self.assertIn("Ternux Control Center", page)
        self.assertIn("LOCAL CONTROL", page)
        self.assertIn('src="app.js"', page)
        app = (ROOT / "lib" / "control-center" / "app.js").read_text()
        self.assertIn("data-lifecycle", app)
        self.assertIn("X-Ternux-CSRF", app)
        self.assertIn("Stop this desktop in Termux, apply its display migration", app)
        self.assertIn("It will verify the target and only remove a socket it proves stale", app)
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

    def test_only_one_control_center_service_owns_durable_job_recovery(self):
        with self.assertRaises(RuntimeError):
            control.LocalServer(("127.0.0.1", 0), control.Handler, "another-session-token", ROOT / "lib" / "control-center")

    def test_client_disconnect_during_response_is_closed_without_traceback(self):
        handler = object.__new__(control.Handler)
        handler.command = "GET"
        handler.close_connection = False
        handler.send_response = Mock()
        handler.send_header = Mock()
        handler.end_headers = Mock()
        handler.wfile = Mock()
        handler.wfile.write.side_effect = BrokenPipeError("peer closed")

        handler._write(200, b"response", "text/plain")

        self.assertTrue(handler.close_connection)
        handler.end_headers.assert_called_once()
        handler.wfile.write.assert_called_once_with(b"response")

    def test_cli_starts_loopback_dashboard_and_stops_cleanly(self):
        self.server.shutdown()
        self.server.server_close()
        self.thread.join(timeout=2)
        self.server = None
        process = subprocess.Popen(
            ["bash", str(ROOT / "bin/ternux"), "control", "--no-open"],
            stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            text=True, env={**os.environ, "PREFIX": str(self.prefix), "TERNUX_LIB_DIR": str(ROOT / "lib")},
        )
        try:
            heading = process.stdout.readline().strip()
            listening = process.stdout.readline().strip()
            open_line = process.stdout.readline().strip()
            self.assertEqual(heading, "Ternux Control Center")
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

    def post(self, path, payload, *, token="test-session-key", csrf="test-session-key", origin=None):
        return self.request(path, token=token, csrf=csrf, origin=origin or self.origin, method="POST", payload=payload)

    def make_plan(self, operation="stop", guest="debian"):
        response = self.post("/api/v1/guest-plans", {"operation": operation, "guest": guest})
        self.assertEqual(response.status, 200)
        return json.loads(response.read())

    def test_guest_lifecycle_requires_loopback_bearer_origin_and_csrf(self):
        payload = {"operation": "stop", "guest": "debian"}
        self.assertEqual(self.request("/api/v1/guest-plans", method="POST", payload=payload).code, 403)
        self.assertEqual(self.post("/api/v1/guest-plans", payload, csrf="wrong").code, 403)
        self.assertEqual(self.post("/api/v1/guest-plans", payload, origin="https://attacker.example").code, 403)
        self.assertFalse(self.log.exists())

    def test_start_plan_delegates_stale_display_conflict_check_to_manager_cli(self):
        original = control.read_snapshot
        def occupied_target_snapshot():
            data = original()
            data["snapshot"]["displays"]["guests"][0]["target_conflict"] = True
            return data
        with patch.object(control, "read_snapshot", side_effect=occupied_target_snapshot):
            plan = self.make_plan("start")
        self.assertTrue(plan["plan"]["observed"]["target_conflict"])
        self.assertEqual(plan["status"], "confirmation-required")

    def test_guest_actions_fail_closed_when_display_migration_is_required(self):
        original = control.read_snapshot
        def migration_required_snapshot():
            data = original()
            data["snapshot"]["displays"]["guests"][0]["migration_required"] = True
            return data
        with patch.object(control, "read_snapshot", side_effect=migration_required_snapshot):
            response = self.post("/api/v1/guest-plans", {"operation": "stop", "guest": "debian"})
        self.assertEqual(response.code, 409)
        self.assertEqual(json.loads(response.read())["error"], "GUEST_ACTION_BLOCKED")
        commands = self.log.read_text().splitlines() if self.log.exists() else []
        self.assertFalse(any(row.startswith(("start ", "stop ")) for row in commands))

    def test_guest_plan_is_typed_and_confirmation_is_bound_to_exact_plan(self):
        self.assertEqual(self.post("/api/v1/guest-plans", {"operation": "start;rm", "guest": "debian"}).code, 400)
        self.assertEqual(self.post("/api/v1/guest-plans", {"operation": "stop", "guest": "../debian"}).code, 400)
        plan = self.make_plan("stop")
        self.assertEqual(plan["status"], "confirmation-required")
        self.assertEqual(plan["plan"]["operation"], "stop")
        self.assertEqual(plan["plan"]["guest"], "debian")
        self.assertRegex(plan["plan"]["plan_id"], r"^sha256:[a-f0-9]{64}$")
        self.assertNotIn("test-session-key", json.dumps(plan))
        wrong = self.post("/api/v1/guest-actions", {"plan_id": plan["plan"]["plan_id"], "confirmation": "wrong", "idempotency_key": "test-stop-key-0001"})
        self.assertEqual(wrong.code, 409)
        commands = self.log.read_text().splitlines() if self.log.exists() else []
        self.assertFalse(any(row.startswith(("start ", "stop ")) for row in commands))

    def test_guest_action_is_journaled_idempotent_and_executes_only_typed_cli_argv(self):
        plan = self.make_plan("stop")
        body = {"plan_id": plan["plan"]["plan_id"], "confirmation": plan["confirmation"], "idempotency_key": "test-stop-key-0001"}
        response = self.post("/api/v1/guest-actions", body)
        self.assertEqual(response.status, 202)
        job = json.loads(response.read())["job"]
        self.assertEqual(job["kind"], "guest.stop")
        self.assertIn(job["state"], {"QUEUED", "RUNNING", "SUCCEEDED"})
        replay = self.post("/api/v1/guest-actions", body)
        self.assertEqual(replay.status, 200)
        self.assertEqual(json.loads(replay.read())["job"]["id"], job["id"])
        deadline = time.monotonic() + 3
        final = job
        while time.monotonic() < deadline:
            response = self.request(f"/api/v1/jobs/{job['id']}", token="test-session-key")
            self.assertEqual(response.status, 200)
            final = json.loads(response.read())["job"]
            if final["state"] in {"SUCCEEDED", "FAILED", "INTERRUPTED"}:
                break
            time.sleep(0.02)
        self.assertEqual(final["state"], "SUCCEEDED")
        self.assertFalse(final["cancelable"])
        commands = self.log.read_text().splitlines()
        self.assertEqual(commands.count("stop debian"), 1)
        self.assertNotIn(";", commands[-1])
        job_file = next((self.prefix / "var/lib/ternux/control/jobs").glob("*.json"))
        self.assertEqual(job_file.stat().st_mode & 0o777, 0o600)
        self.assertNotIn("test-session-key", job_file.read_text())

    def test_confirmation_is_reserved_before_concurrent_action_validation(self):
        plan = self.make_plan("stop")
        body = {"plan_id": plan["plan"]["plan_id"], "confirmation": plan["confirmation"], "idempotency_key": "first-reservation-key-01"}
        entered, release = threading.Event(), threading.Event()
        original = control._plan_snapshot
        def delayed_snapshot(operation, guest):
            entered.set()
            if not release.wait(3):
                raise RuntimeError("test snapshot gate timed out")
            return original(operation, guest)
        responses = []
        with patch.object(control, "_plan_snapshot", side_effect=delayed_snapshot):
            first = threading.Thread(target=lambda: responses.append(self.post("/api/v1/guest-actions", body)))
            first.start()
            self.assertTrue(entered.wait(2), "first action did not reach state revalidation")
            duplicate = self.post("/api/v1/guest-actions", {**body, "idempotency_key": "second-reservation-key-02"})
            self.assertEqual(duplicate.code, 409)
            release.set()
            first.join(timeout=5)
        self.assertFalse(first.is_alive())
        self.assertEqual(len(responses), 1)
        self.assertEqual(responses[0].status, 202)

    def test_same_idempotency_key_with_different_plan_is_rejected(self):
        first = self.make_plan("stop")
        first_body = {"plan_id": first["plan"]["plan_id"], "confirmation": first["confirmation"], "idempotency_key": "shared-key-for-test-0001"}
        response = self.post("/api/v1/guest-actions", first_body)
        self.assertEqual(response.status, 202)
        response.read()
        second = self.make_plan("start")
        second_body = {"plan_id": second["plan"]["plan_id"], "confirmation": second["confirmation"], "idempotency_key": "shared-key-for-test-0001"}
        conflict = self.post("/api/v1/guest-actions", second_body)
        self.assertEqual(conflict.code, 409)
        self.assertEqual(json.loads(conflict.read())["error"], "IDEMPOTENCY_CONFLICT")
        self.assertEqual(self.log.read_text().splitlines().count("stop debian"), 1)
        self.assertNotIn("start debian", self.log.read_text())

    def test_stale_confirmation_is_rejected_after_guest_state_changes(self):
        plan = self.make_plan("stop")
        old_reader = control.read_snapshot
        def changed_snapshot():
            data = old_reader()
            data["snapshot"]["displays"]["guests"][0]["running"] = False
            return data
        with patch.object(control, "read_snapshot", side_effect=changed_snapshot):
            response = self.post("/api/v1/guest-actions", {"plan_id": plan["plan"]["plan_id"], "confirmation": plan["confirmation"], "idempotency_key": "stale-plan-key-00001"})
        self.assertEqual(response.code, 409)
        self.assertEqual(json.loads(response.read())["error"], "PLAN_STALE")
        self.assertFalse(self.log.read_text().splitlines()[-1].startswith("stop "))

    def test_command_success_without_observed_guest_state_is_not_reported_as_success(self):
        plan = self.make_plan("stop")
        with patch.object(control, "_guest_reached_desired_state", return_value=False):
            response = self.post("/api/v1/guest-actions", {"plan_id": plan["plan"]["plan_id"], "confirmation": plan["confirmation"], "idempotency_key": "verify-state-key-000001"})
            self.assertEqual(response.status, 202)
            job_id = json.loads(response.read())["job"]["id"]
            deadline = time.monotonic() + 3
            while time.monotonic() < deadline:
                final = json.loads(self.request(f"/api/v1/jobs/{job_id}", token="test-session-key").read())["job"]
                if final["state"] in {"SUCCEEDED", "FAILED", "INTERRUPTED"}:
                    break
                time.sleep(0.02)
        self.assertEqual(final["state"], "INTERRUPTED")
        self.assertEqual(final["error"]["code"], "STATE_NOT_CONFIRMED")

    def test_old_terminal_jobs_are_pruned_but_active_jobs_are_retained(self):
        jobs = control._control_jobs_dir(create=True)
        old_id = "00000000-0000-4000-8000-000000000002"
        active_id = "00000000-0000-4000-8000-000000000003"
        control._write_job(jobs, {"id": old_id, "kind": "guest.stop", "guest": "debian", "state": "SUCCEEDED", "phase": "complete", "created_at": 1, "updated_at": 1, "cancelable": False})
        control._write_job(jobs, {"id": active_id, "kind": "guest.start", "guest": "ubuntu", "state": "RUNNING", "phase": "starting", "created_at": 1, "updated_at": 1, "cancelable": False})
        control._prune_expired_jobs(jobs)
        self.assertFalse((jobs / f"{old_id}.json").exists())
        self.assertTrue((jobs / f"{active_id}.json").exists())

    def test_interrupted_durable_job_is_marked_for_reconciliation_on_restart(self):
        jobs = control._control_jobs_dir(create=True)
        job_id = "00000000-0000-4000-8000-000000000001"
        control._write_job(jobs, {"id": job_id, "kind": "guest.start", "guest": "debian", "state": "RUNNING", "phase": "starting", "created_at": 1, "updated_at": 1, "cancelable": False})
        control._recover_interrupted_jobs(jobs)
        job = control._read_job(jobs / f"{job_id}.json")
        self.assertEqual(job["state"], "INTERRUPTED")
        self.assertEqual(job["phase"], "reconcile-required")
        self.assertEqual(job["error"]["code"], "SERVICE_INTERRUPTED")

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
