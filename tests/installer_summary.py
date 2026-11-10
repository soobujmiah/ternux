#!/usr/bin/env python3
"""Check installer summary-card alignment and wrapping at phone widths."""
from __future__ import annotations

import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ANSI = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")
SCRIPT = r'''
. "$1/lib/ui.sh"
tnx_summary_box "Install Plan" \
  "GPU route" "Zink / Turnip" \
  "User" "ternux" \
  "Storage estimate" "6 GB free before install; base ~4-4.6 GB, complete ~10.5-12.5 GB" \
  "Host CLI" "/data/data/com.termux/files/usr/bin/ternux"
'''


def render(cols: int) -> list[str]:
    env = dict(os.environ)
    env.update({"COLUMNS": str(cols), "TERM": "dumb", "NO_COLOR": "1"})
    proc = subprocess.run(
        ["bash", "-c", SCRIPT, "summary-test", str(ROOT)],
        check=True,
        capture_output=True,
        text=True,
        env=env,
    )
    return [ANSI.sub("", line) for line in proc.stdout.splitlines() if line.strip()]


def check(cols: int) -> None:
    lines = render(cols)
    body = [line for line in lines if line.lstrip().startswith("|") and not line.lstrip().startswith("+_")]
    columns = [line.index(" | ") for line in body if " | " in line]
    if cols >= 36:
        assert columns and len(set(columns)) == 1, f"{cols} columns: field/value separators do not align: {body!r}"
        assert any(re.match(r"^  \| +\| ", line) for line in body), "continuation rows should align under values"
    assert all(len(line) <= cols for line in lines), f"{cols} columns: a row overflowed: {lines!r}"
    joined = " ".join(" ".join(body).split())
    assert any("GPU route" in line for line in body), "first field label should remain visible"
    assert "Zink" in joined and "Turnip" in joined, "first field value should remain readable"
    assert any("Storage estimate" in line for line in body), "storage label should remain visible"
    assert "base" in joined and "4-4.6" in joined, "wrapped storage details should remain readable"
    assert any("Host CLI" in line for line in body), "host CLI label should remain visible"
    assert "/data/" in joined and "ternux" in joined, "long path should remain present"
    print(f"ok - {cols} columns: aligned fields, safe wrapping, no overflow")


def main() -> int:
    try:
        check(58)
        check(36)
        check(24)
    except (AssertionError, subprocess.CalledProcessError) as exc:
        print(f"not ok - {exc}", file=sys.stderr)
        return 1
    print("# 3 phone-width summary layouts passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
