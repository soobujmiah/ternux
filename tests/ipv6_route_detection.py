#!/usr/bin/env python3
"""Verify the embedded APT route probes recognize IPv6 default routes."""
from __future__ import annotations

import re
import subprocess
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = (root / "lib/phases.sh").read_text()
programs = []
for route_path in re.finditer(r"' /proc/net/ipv6_route", source):
    awk_start = source.rfind("awk '", 0, route_path.start())
    if awk_start < 0:
        raise SystemExit("route path is not preceded by an awk program")
    programs.append(source[awk_start + len("awk '"):route_path.start()])
if len(programs) != 2:
    raise SystemExit(f"expected both embedded APT probes, found {len(programs)}")

valid_default = (
    "00000000000000000000000000000000 00 "
    "00000000000000000000000000000000 00 "
    "fe800000000000000000000000000001 "
    "00000000 00000000 00000000 00000000 wlan0\n"
)
non_default = (
    "20010db8000000000000000000000000 40 "
    "00000000000000000000000000000000 00 "
    "00000000000000000000000000000000 "
    "00000000 00000000 00000000 00000000 eth0\n"
)

for number, raw_program in enumerate(programs, start=1):
    program = raw_program.replace(r"\$", "$").replace(r'\"', '"')
    for route, expected, label in (
        (valid_default, 0, "default route"),
        (non_default, 1, "non-default route"),
    ):
        result = subprocess.run(
            ["awk", program], input=route, text=True, capture_output=True, check=False
        )
        if result.returncode != expected:
            raise SystemExit(
                f"probe {number} mishandled {label}: status={result.returncode}, "
                f"stderr={result.stderr!r}"
            )
print("PASS: both APT route probes accept IPv6 defaults and reject non-default routes")
