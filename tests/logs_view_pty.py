#!/usr/bin/env python3
"""Drive the real Advanced Log Viewer (ternux logs view) in a pseudo-terminal.

Mirrors tests/workload_menu_pty.py's approach: a real `script`-backed PTY
with scripted raw keypresses, asserting against the captured byte stream
rather than reimplementing a VT100 emulator (unlike tests/ui_render.py,
which needs exact screen geometry; this only needs to confirm the
pause/search/export/scroll behaviors actually work end to end).
"""
from __future__ import annotations

import os
import shutil
import shlex
import subprocess
import sys
import tempfile
from pathlib import Path

root = Path(sys.argv[1]).resolve()
script = shutil.which("script")
if script is None:
    raise SystemExit("util-linux script command is required for the PTY integration test")

tmp = Path(tempfile.mkdtemp(prefix="ternux-logview-"))
log_file = tmp / "sample.log"
export_file = tmp / "export.txt"
lines = [f"line-{i:03d}" for i in range(100)]
lines[50] = "MAGIC-NEEDLE-12345"
log_file.write_text("\n".join(lines) + "\n")

command_program = r'''
stty rows 20 cols 80
source "$1/lib/logs.sh"
TERNUX_LOG_DIR="$2"
tnx_cmd_logs view "$3"
'''
command = (
    f"bash -c {shlex.quote(command_program)} logs-view-test "
    f"{shlex.quote(str(root))} {shlex.quote(str(tmp))} {shlex.quote(str(log_file))}"
)

keys = (
    b"j" * 3          # scroll down 3 lines from the initial live/bottom view (also pauses)
    + b"g"             # jump to top
    + b"j" * 3         # scroll down 3 more lines from the top
    + b"/" + b"MAGIC-NEEDLE\r"  # search
    + b"e" + str(export_file).encode() + b"\r"  # export the (single) match
    + b"q"
)
result = subprocess.run(
    [script, "-qec", command, "/dev/null"],
    input=keys,
    capture_output=True,
    timeout=30,
    env={**os.environ},
)
output = result.stdout + result.stderr

if result.returncode != 0:
    raise SystemExit(f"logs view exited with status {result.returncode}: {output[-500:]!r}")
if b"[LIVE]" not in output:
    raise SystemExit(f"initial view did not start in live-follow mode: {output[-500:]!r}")
if b"[PAUSED]" not in output:
    raise SystemExit(f"scrolling did not pause live-follow mode: {output[-500:]!r}")
if b"line-000" not in output:
    raise SystemExit(f"'g' (go to top) did not show the first line: {output[-500:]!r}")
if b"line-020" not in output:
    # Rows 20x80 -> an 18-line body; 'g' alone only shows line-000..line-017,
    # so line-020 becoming visible is proof 'j' actually scrolled rather
    # than a line that would already be on screen right after 'g'.
    raise SystemExit(f"'j' x3 from the top did not scroll past the initial page: {output[-500:]!r}")
if b"MAGIC-NEEDLE-12345" not in output:
    raise SystemExit(f"search did not surface the matching line: {output[-500:]!r}")
if not export_file.exists():
    raise SystemExit(f"export did not create a file: {output[-500:]!r}")
exported = export_file.read_text()
if exported.strip() != "MAGIC-NEEDLE-12345":
    raise SystemExit(f"export wrote unexpected content: {exported!r}")

shutil.rmtree(tmp, ignore_errors=True)
print("Advanced Log Viewer PTY test passed: live/paused state, scroll, search, and export-matches-only all work")
