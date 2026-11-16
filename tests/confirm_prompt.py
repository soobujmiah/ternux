#!/usr/bin/env python3
"""Ensure confirmation prompts remain visible behind the installer stream."""

from __future__ import annotations

import os
import pty
import select
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="ternux-confirm-") as temporary:
        pid, master = pty.fork()
        if pid == 0:
            os.environ.update(
                HOME=temporary,
                TERNUX_STATE_DIR=f"{temporary}/state",
                TERM="dumb",
                NO_COLOR="1",
            )
            os.execlp(
                "bash",
                "bash",
                "-c",
                '. "$1/lib/core.sh"; tnx_confirm "visible permission prompt" no 2>&1 | cat >/dev/null; echo CONFIRMED',
                "confirm-test",
                str(ROOT),
            )

        output = bytearray()
        deadline = time.monotonic() + 8
        sent_answer = False
        status = None
        while time.monotonic() < deadline:
            ready, _, _ = select.select([master], [], [], 0.2)
            if ready:
                try:
                    chunk = os.read(master, 4096)
                except OSError:
                    chunk = b""
                output.extend(chunk)
                if not sent_answer and b"visible permission prompt [y/N]: " in output:
                    os.write(master, b"y\n")
                    sent_answer = True
            waited, status = os.waitpid(pid, os.WNOHANG)
            if waited:
                break
        else:
            os.kill(pid, 9)
            os.waitpid(pid, 0)
            raise AssertionError("confirmation prompt was not visible on the controlling terminal")

        rendered = output.decode(errors="replace")
        if not sent_answer or "CONFIRMED" not in rendered or status is None or os.waitstatus_to_exitcode(status) != 0:
            raise AssertionError(f"confirmation interaction failed: {rendered!r}")

    print("installer confirmation prompt is visible and accepts terminal input")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
