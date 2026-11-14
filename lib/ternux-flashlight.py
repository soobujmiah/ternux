#!/usr/bin/env python3
"""Toggle Termux:API camera torch from the Ternux desktop."""
import fcntl
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

TORCH = "/data/data/com.termux/files/usr/bin/termux-torch"
STATE = Path.home() / ".cache/ternux/flashlight.json"
LOCK = Path.home() / ".cache/ternux/flashlight.lock"


def termux_environment():
    env = os.environ.copy()
    env.pop("LD_PRELOAD", None)
    return env


def api_error(*outputs):
    for output in outputs:
        detail = (output or "").strip()
        if not detail:
            continue
        try:
            payload = json.loads(detail)
            if isinstance(payload, dict):
                detail = str(payload.get("error") or payload.get("message") or detail)
        except json.JSONDecodeError:
            pass
        if "android.permission.CAMERA" in detail or "Please grant" in detail:
            return ("Termux:API needs Android Camera permission. Open Android Settings → Apps → "
                    "Termux:API → Permissions → Camera and allow access.")
        return detail
    return ""


def state_is_on(path=STATE):
    try:
        return json.loads(path.read_text()).get("on") is True
    except (OSError, ValueError, AttributeError):
        return False


def notify(message):
    executable = shutil.which("notify-send")
    if executable:
        try:
            subprocess.run([executable, "--app-name=Ternux", "Ternux Flashlight", message],
                           check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                           timeout=5)
        except (OSError, subprocess.SubprocessError):
            pass


def set_torch(command, state_path=STATE, torch=TORCH, runner=subprocess.run):
    if command not in ("on", "off", "toggle"):
        raise ValueError("Usage: ternux-flashlight [toggle|on|off]")
    state_path = Path(state_path)
    lock_path = state_path.with_suffix(".lock")
    state_path.parent.mkdir(parents=True, exist_ok=True)
    lock_path.parent.mkdir(parents=True, exist_ok=True)
    with lock_path.open("a", encoding="utf-8") as lock_file:
        fcntl.flock(lock_file.fileno(), fcntl.LOCK_EX)
        current = state_is_on(state_path)
        target = ("off" if current else "on") if command == "toggle" else command
        env = termux_environment()
        try:
            result = runner([str(torch), target], check=False, capture_output=True,
                            text=True, timeout=15, env=env)
        except (OSError, subprocess.SubprocessError) as exc:
            raise RuntimeError(str(exc)) from exc
        error = api_error(result.stderr, result.stdout)
        if result.returncode != 0 or error:
            raise RuntimeError(error or f"Termux:API flashlight command failed (exit {result.returncode}).")
        payload = json.dumps({"on": target == "on"}) + "\n"
        fd, temporary = tempfile.mkstemp(prefix=".flashlight.", dir=state_path.parent)
        try:
            with os.fdopen(fd, "w", encoding="utf-8") as output:
                output.write(payload)
                output.flush()
                os.fsync(output.fileno())
            os.chmod(temporary, 0o600)
            os.replace(temporary, state_path)
        finally:
            try:
                os.unlink(temporary)
            except FileNotFoundError:
                pass
        return target


def main(argv=None):
    argv = list(sys.argv[1:] if argv is None else argv)
    command = argv[0] if argv else "toggle"
    if len(argv) > 1:
        print("Usage: ternux-flashlight [toggle|on|off]", file=sys.stderr)
        return 2
    try:
        target = set_torch(command)
    except (RuntimeError, ValueError) as exc:
        message = str(exc)
        print(message, file=sys.stderr)
        notify(message)
        return 1
    message = "Flashlight is on." if target == "on" else "Flashlight is off."
    notify(message)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
