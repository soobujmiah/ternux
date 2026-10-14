#!/usr/bin/env python3
"""Minimal MCP server that renders with Blender on the Adreno GPU, headlessly.

Why this exists
---------------
The measured GPU path on this hardware is exactly:

    Xvfb :9 -screen 0 1280x720x24 &
    DISPLAY=:9 GALLIUM_DRIVER=zink blender -b --factory-startup --python render.py

Both halves are load-bearing: with no display Blender falls back to EGL and ends
with ``EGL_BAD_MATCH``; with a display but no ``GALLIUM_DRIVER=zink`` Mesa picks
``llvmpipe``, which dies with ``Illegal instruction`` on Adreno. Either way the
render produces zero frames. See docs/WORKLOADS.md and docs/GRAPHICS-PERSISTENCE.md.

An agent that shells out to Blender itself has to remember that environment on
every call, and MCP servers that drive Blender through an in-Blender addon need
addons enabled (so no ``--factory-startup``) and a live main loop, which
``blender -b`` does not provide. This server takes the third route: it keeps the
verified command intact and only wraps it, so the renderer an agent reaches
through MCP is the same one the benchmarks were taken with.

Protocol: MCP over stdio, newline-delimited JSON-RPC 2.0. No third-party
dependencies — Python standard library only.

Deliberate limits
-----------------
* It never enumerates a directory. Every path is one the caller named.
* It never deletes or overwrites anything except the output paths Blender itself
  writes, and it refuses a relative path.
* It starts ``Xvfb`` only if that display is not already up, and never stops one
  it did not start.
* It runs the Python scripts it is given. That is the same authority an agent
  already has in this workspace, and it is local stdio only — but it is the
  reason this server should not be exposed to anything but a local client.
"""

from __future__ import annotations

import json
import os
import re
import shutil
import signal
import subprocess
import sys
import time
from pathlib import Path

SERVER_NAME = "blender-gpu"
SERVER_VERSION = "0.1.0"
DEFAULT_PROTOCOL = "2024-11-05"

DEFAULT_DISPLAY = os.environ.get("TERNUX_BLENDER_DISPLAY", ":9")
DEFAULT_SCREEN = os.environ.get("TERNUX_BLENDER_SCREEN", "1280x720x24")
DEFAULT_DRIVER = os.environ.get("TERNUX_BLENDER_GALLIUM", "zink")
DEFAULT_TIMEOUT = 1800
MAX_TAIL_LINES = 40

SAVED_RE = re.compile(r"^Saved: '(.+)'", re.M)
TIME_RE = re.compile(r"^ *Time: (\d+):(\d+)\.(\d+)", re.M)


class ToolError(Exception):
    """A failure that is the caller's to fix, reported as tool output."""


# --------------------------------------------------------------------------- #
# environment
# --------------------------------------------------------------------------- #

def display_socket(display: str) -> Path:
    return Path("/tmp/.X11-unix") / ("X" + display.lstrip(":"))


def xvfb_running(display: str) -> bool:
    return display_socket(display).exists()


def ensure_xvfb(display: str, screen: str) -> str:
    """Bring up a virtual display if that one is not already serving."""
    if xvfb_running(display):
        return f"display {display} already up (left as it was)"
    if not shutil.which("Xvfb"):
        raise ToolError(
            "Xvfb is not installed, so there is no GPU path: install it with "
            "`sudo apt install -y --no-install-recommends blender xvfb` "
            "(ternux: `bash install.sh --with-blender`)."
        )
    subprocess.Popen(
        ["Xvfb", display, "-screen", "0", screen],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )
    for _ in range(100):  # up to ~10s
        if xvfb_running(display):
            return f"started Xvfb on {display} ({screen})"
        time.sleep(0.1)
    raise ToolError(f"started Xvfb on {display} but its socket never appeared")


def gpu_env(display: str) -> dict[str, str]:
    env = dict(os.environ)
    env["DISPLAY"] = display
    env["GALLIUM_DRIVER"] = DEFAULT_DRIVER
    return env


def blender_binary() -> str:
    binary = os.environ.get("TERNUX_BLENDER_BIN") or shutil.which("blender")
    if not binary:
        raise ToolError(
            "blender is not on PATH: install it with "
            "`sudo apt install -y --no-install-recommends blender xvfb` "
            "(ternux: `bash install.sh --with-blender`)."
        )
    return binary


# --------------------------------------------------------------------------- #
# running blender
# --------------------------------------------------------------------------- #

def absolute_existing(value: str, label: str) -> Path:
    if not value or not value.startswith("/"):
        raise ToolError(f"{label} must be an absolute path, got {value!r}")
    path = Path(value)
    if not path.is_file():
        raise ToolError(f"{label} does not exist: {path}")
    return path


def run_blender(args: list[str], display: str, timeout: int) -> dict:
    """Run one Blender process on the GPU path and summarise what it did."""
    notes = [ensure_xvfb(display, DEFAULT_SCREEN)]
    command = [blender_binary(), "-b", "--factory-startup", *args]
    started = time.monotonic()
    try:
        proc = subprocess.run(
            command,
            env=gpu_env(display),
            capture_output=True,
            text=True,
            timeout=timeout,
            start_new_session=True,
        )
    except subprocess.TimeoutExpired as exc:
        raise ToolError(
            f"blender did not finish within {timeout}s and was killed; "
            f"partial output:\n{tail(exc.stdout or '')}"
        ) from exc
    elapsed = time.monotonic() - started
    stdout = proc.stdout or ""
    stderr = proc.stderr or ""

    saved = SAVED_RE.findall(stdout)
    frame_times = [
        int(m[0]) * 60 + int(m[1]) + int(m[2]) / (10 ** len(m[2]))
        for m in TIME_RE.findall(stdout)
    ]
    diagnosis = diagnose(proc.returncode, saved, stdout + stderr)
    return {
        "command": f"DISPLAY={display} GALLIUM_DRIVER={DEFAULT_DRIVER} " + " ".join(command),
        "env": {"DISPLAY": display, "GALLIUM_DRIVER": DEFAULT_DRIVER},
        "exit_code": proc.returncode,
        "wall_seconds": round(elapsed, 2),
        "frames_written": len(saved),
        "outputs": saved[-10:],
        "mean_frame_seconds": round(sum(frame_times) / len(frame_times), 3) if frame_times else None,
        "notes": notes,
        "diagnosis": diagnosis,
        "stdout_tail": tail(stdout),
        "stderr_tail": tail(stderr) if stderr.strip() else "",
    }


def diagnose(exit_code: int, saved: list[str], output: str) -> str:
    """Name the two failures that look like a bad scene but are the GPU path."""
    if "EGL_BAD_MATCH" in output:
        return ("EGL_BAD_MATCH: Blender found no X display and fell back to EGL. "
                "The virtual display is missing, not the scene.")
    if "Illegal instruction" in output or exit_code in (-signal.SIGILL, 132):
        return ("Illegal instruction: Mesa selected llvmpipe, which SIGILLs on this "
                "Adreno. GALLIUM_DRIVER=zink is what prevents it.")
    if exit_code != 0:
        return f"blender exited {exit_code}; read stdout_tail for its own error"
    if not saved:
        return ("blender exited 0 but wrote no frame: check that the script sets an "
                "output path and actually calls a render operator")
    return "ok"


def tail(text: str) -> str:
    lines = text.rstrip().splitlines()
    return "\n".join(lines[-MAX_TAIL_LINES:])


# --------------------------------------------------------------------------- #
# tools
# --------------------------------------------------------------------------- #

def tool_gpu_check(args: dict) -> dict:
    display = args.get("display") or DEFAULT_DISPLAY
    notes = [ensure_xvfb(display, DEFAULT_SCREEN)]
    result: dict = {"display": display, "notes": notes}

    if shutil.which("glxinfo"):
        probe = subprocess.run(
            ["glxinfo", "-B"], env=gpu_env(display),
            capture_output=True, text=True, timeout=120,
        )
        renderer = next(
            (line.split(":", 1)[1].strip()
             for line in probe.stdout.splitlines() if "OpenGL renderer string" in line),
            "",
        )
        result["opengl_renderer"] = renderer
        result["gpu_path_ok"] = "zink" in renderer.lower()
        if not result["gpu_path_ok"]:
            result["diagnosis"] = (
                f"renderer is {renderer or 'unreadable'}, not zink — a render down this "
                "path would use llvmpipe and SIGILL on Adreno"
            )
    else:
        result["opengl_renderer"] = None
        result["gpu_path_ok"] = None
        result["diagnosis"] = "glxinfo is not installed, so the renderer could not be read"

    version = subprocess.run(
        [blender_binary(), "--version"], capture_output=True, text=True, timeout=120,
    )
    result["blender"] = (version.stdout or "").splitlines()[0].strip() if version.stdout else None
    return result


def tool_render_script(args: dict) -> dict:
    script = absolute_existing(args.get("script", ""), "script")
    display = args.get("display") or DEFAULT_DISPLAY
    timeout = int(args.get("timeout_seconds") or DEFAULT_TIMEOUT)
    blend = args.get("blend")
    extra: list[str] = []
    if blend:
        extra.append(str(absolute_existing(blend, "blend")))
    extra += ["--python", str(script)]
    script_args = args.get("script_args") or []
    if script_args:
        extra += ["--", *[str(a) for a in script_args]]
    return run_blender(extra, display, timeout)


def tool_render_blend(args: dict) -> dict:
    blend = absolute_existing(args.get("blend", ""), "blend")
    output = args.get("output")
    if not output or not output.startswith("/"):
        raise ToolError("output must be an absolute path prefix, e.g. /sdcard/Blender/out/frame_")
    Path(output).parent.mkdir(parents=True, exist_ok=True)
    display = args.get("display") or DEFAULT_DISPLAY
    timeout = int(args.get("timeout_seconds") or DEFAULT_TIMEOUT)

    extra = [str(blend), "-o", output]
    start, end = args.get("frame_start"), args.get("frame_end")
    if start is not None and end is not None:
        extra += ["-s", str(int(start)), "-e", str(int(end)), "-a"]
    elif start is not None:
        extra += ["-f", str(int(start))]
    else:
        extra += ["-a"]
    return run_blender(extra, display, timeout)


TOOLS = [
    {
        "name": "gpu_check",
        "description": (
            "Verify the headless GPU render path before trusting a render: brings up Xvfb if "
            "needed, reports the OpenGL renderer string (must be zink/Turnip on Adreno) and the "
            "Blender version. Run this first when a render produced zero frames."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {"display": {"type": "string", "description": "X display, default :9"}},
        },
        "handler": tool_gpu_check,
    },
    {
        "name": "render_script",
        "description": (
            "Run a Blender Python (bpy) script headlessly on the Adreno GPU: "
            "DISPLAY=<display> GALLIUM_DRIVER=zink blender -b --factory-startup [blend] --python <script>. "
            "Returns frames written, mean frame time, the output paths Blender reported, and a "
            "diagnosis for the two GPU-path failures (EGL_BAD_MATCH, llvmpipe SIGILL). Paths must "
            "be absolute."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {
                "script": {"type": "string", "description": "absolute path to the .py script"},
                "blend": {"type": "string", "description": "optional .blend to open first"},
                "script_args": {"type": "array", "items": {"type": "string"},
                                "description": "arguments passed after -- to the script"},
                "display": {"type": "string", "description": "X display, default :9"},
                "timeout_seconds": {"type": "integer", "description": "default 1800"},
            },
            "required": ["script"],
        },
        "handler": tool_render_script,
    },
    {
        "name": "render_blend",
        "description": (
            "Render an existing .blend file headlessly on the Adreno GPU with the same verified "
            "environment. Give frame_start/frame_end for a range, frame_start alone for one frame, "
            "or neither for the file's own range. Paths must be absolute."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {
                "blend": {"type": "string", "description": "absolute path to the .blend"},
                "output": {"type": "string",
                           "description": "absolute output prefix passed to blender -o"},
                "frame_start": {"type": "integer"},
                "frame_end": {"type": "integer"},
                "display": {"type": "string", "description": "X display, default :9"},
                "timeout_seconds": {"type": "integer", "description": "default 1800"},
            },
            "required": ["blend", "output"],
        },
        "handler": tool_render_blend,
    },
]

HANDLERS = {tool["name"]: tool["handler"] for tool in TOOLS}
TOOL_SCHEMAS = [{k: v for k, v in tool.items() if k != "handler"} for tool in TOOLS]


# --------------------------------------------------------------------------- #
# JSON-RPC plumbing
# --------------------------------------------------------------------------- #

def respond(message: dict) -> None:
    sys.stdout.write(json.dumps(message) + "\n")
    sys.stdout.flush()


def handle(request: dict) -> dict | None:
    method = request.get("method")
    request_id = request.get("id")

    if method == "initialize":
        params = request.get("params") or {}
        return {
            "jsonrpc": "2.0", "id": request_id,
            "result": {
                "protocolVersion": params.get("protocolVersion") or DEFAULT_PROTOCOL,
                "capabilities": {"tools": {}},
                "serverInfo": {"name": SERVER_NAME, "version": SERVER_VERSION},
            },
        }
    if method in ("notifications/initialized", "notifications/cancelled"):
        return None
    if method == "ping":
        return {"jsonrpc": "2.0", "id": request_id, "result": {}}
    if method == "tools/list":
        return {"jsonrpc": "2.0", "id": request_id, "result": {"tools": TOOL_SCHEMAS}}
    if method == "tools/call":
        params = request.get("params") or {}
        name = params.get("name")
        handler = HANDLERS.get(name)
        if not handler:
            return {"jsonrpc": "2.0", "id": request_id,
                    "error": {"code": -32602, "message": f"unknown tool: {name}"}}
        try:
            payload = handler(params.get("arguments") or {})
            is_error = False
        except ToolError as exc:
            payload, is_error = {"error": str(exc)}, True
        except Exception as exc:  # unexpected: report it, do not kill the server
            payload, is_error = {"error": f"{type(exc).__name__}: {exc}"}, True
        return {
            "jsonrpc": "2.0", "id": request_id,
            "result": {
                "content": [{"type": "text", "text": json.dumps(payload, indent=2)}],
                "isError": is_error,
            },
        }
    if request_id is None:
        return None
    return {"jsonrpc": "2.0", "id": request_id,
            "error": {"code": -32601, "message": f"method not found: {method}"}}


def main() -> int:
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            request = json.loads(line)
        except json.JSONDecodeError:
            respond({"jsonrpc": "2.0", "id": None,
                     "error": {"code": -32700, "message": "parse error"}})
            continue
        reply = handle(request)
        if reply is not None:
            respond(reply)
    return 0


if __name__ == "__main__":
    sys.exit(main())
