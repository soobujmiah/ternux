#!/usr/bin/env python3
"""Audit source-controlled Ternux files installed on this Termux host.

Run from a current checkout on the Termux host with all four named guests:
    python3 tests/live_source_parity.py

Package versions supplied by Android, Termux, and distro package managers are
outside this source-parity check.
"""

from __future__ import annotations

import hashlib
import os
import shutil
import subprocess
import sys
from pathlib import Path, PurePosixPath

ROOT = Path(__file__).resolve().parents[1]
PREFIX = Path(os.environ.get("PREFIX", "/data/data/com.termux/files/usr"))
DISTROS = ("debian", "ubuntu", "kali", "alpine")
PROFILES = Path.home() / ".local/share/ternux/distros"
checked = errors = 0


def report(message: str) -> None:
    global errors
    errors += 1
    print(f"FAIL {message}")


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def guest_run(distro: str, *args: str, input: bytes | None = None) -> bytes:
    result = subprocess.run(
        ["proot-distro", "login", "--isolated", distro, "--", *args],
        input=input,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=60,
    )
    if result.returncode:
        raise RuntimeError(f"{distro}: {result.stderr.decode(errors='replace').strip()}")
    return result.stdout


def check_bytes(label: str, source: Path, installed: bytes) -> None:
    global checked
    checked += 1
    if not source.is_file() or source.read_bytes() != installed:
        report(f"{label}: expected source {source.relative_to(ROOT)}")


def check_host() -> None:
    global checked
    tracked = subprocess.check_output(["git", "ls-files", "-z", "lib"], cwd=ROOT).split(b"\0")
    for raw in tracked:
        if not raw:
            continue
        source = ROOT / os.fsdecode(raw)
        target = PREFIX / "lib/ternux" / source.relative_to(ROOT / "lib")
        checked += 1
        if not target.is_file() or source.read_bytes() != target.read_bytes():
            report(f"native module/resource mismatch: {source.relative_to(ROOT)}")
    for source_rel, targets in (
        ("bin/ternux", ("bin/ternux",)),
        ("bin/tx", ("bin/tx",)),
        ("bin/ternux-shell-shortcut", tuple(f"bin/{n}" for n in
            ("db", "dbr", "dbroot", "ub", "ubr", "ubroot", "kali", "kalir", "kaliroot", "alp", "alpr", "alproot"))),
        ("share/terfetch/terfetch", ("bin/terfetch",)),
    ):
        source = ROOT / source_rel
        for relative in targets:
            target = PREFIX / relative
            checked += 1
            if not target.is_file() or source.read_bytes() != target.read_bytes():
                report(f"native command mismatch: {relative}")
    phases = (ROOT / "lib/phases.sh").read_text()
    expected = block(phases, phases.index('cat >> "$rc_tmp"'))
    for rc in (Path.home() / ".bashrc", Path.home() / ".zshrc"):
        if rc.is_file():
            checked += 1
            actual = block(rc.read_text())
            if actual != expected or rc.read_text().count("# TERNUX TERFETCH START BEGIN") != 1:
                report(f"native Terfetch hook mismatch: {rc}")


def block(text: str, offset: int = 0) -> str:
    begin, end = "# TERNUX TERFETCH START BEGIN", "# TERNUX TERFETCH START END"
    start = text.index(begin, offset)
    return text[start:text.index(end, start) + len(end)]


def source_path(path: str) -> Path | None:
    p = PurePosixPath(path)
    if path == "/usr/local/bin/ternux":
        return ROOT / "bin/ternux-guest"
    if path == "/usr/local/bin/terfetch":
        return ROOT / "share/terfetch/terfetch"
    if path == "/usr/local/bin/bwrap":
        return ROOT / "lib/ternux-assets/bin/ternux-proot-bwrap"
    if path == "/usr/local/lib/ternux/libternux-faccessat.so":
        return ROOT / "lib/ternux-assets/bin/ternux-proot-faccessat-arm64.so"
    parts = p.parts
    if parts[:5] == ("/", "usr", "share", "backgrounds", "ternux"):
        return ROOT / "lib/ternux-assets/wallpapers" / p.name
    if parts[:5] == ("/", "usr", "share", "backgrounds", "ternux-v3"):
        return ROOT / "lib/ternux-assets/wallpapers-v3" / Path(*p.parts[5:])
    if path.startswith("/usr/share/icons/Ternux/"):
        return ROOT / "lib/ternux-assets/icons/Ternux" / Path(path.removeprefix("/usr/share/icons/Ternux/"))
    if path.startswith("/usr/share/themes/Green/"):
        return ROOT / "lib/ternux-assets/themes/Green" / Path(path.removeprefix("/usr/share/themes/Green/"))
    if path.startswith("/usr/share/applications/ternux-"):
        return ROOT / "lib/ternux-assets/applications" / p.name
    aliases = {
        "ternux-camera": "lib/ternux-camera.py",
        "ternux-recorder": "lib/ternux-recorder.py",
        "ternux-flashlight": "lib/ternux-flashlight.py",
        "ternux-panel-shortcuts": "lib/ternux-panel-shortcuts.sh",
        "ternux-welcome": "lib/ternux-welcome.sh",
    }
    if p.parts[:4] == ("/", "usr", "local", "bin"):
        if p.name in aliases:
            return ROOT / aliases[p.name]
        for directory in ("lib/ternux-assets/bin", "bin", "lib"):
            candidate = ROOT / directory / p.name
            if candidate.is_file():
                return candidate
    return None


def guest_manifest(distro: str) -> dict[str, str]:
    command = r'''set -e
for f in /usr/local/bin/ternux* /usr/local/bin/terfetch /usr/local/bin/evolution /usr/local/bin/bwrap \
 /usr/local/lib/ternux/* /usr/share/applications/ternux-*.desktop /usr/share/backgrounds/ternux/*; do
 [ ! -f "$f" ] || case "$f" in
  /usr/share/applications/ternux-camera.desktop|/usr/share/applications/ternux-photos.desktop|/usr/share/applications/ternux-recorder.desktop) continue ;;
 esac
 [ ! -f "$f" ] || sha256sum "$f"
done
for d in /usr/share/icons/Ternux /usr/share/themes/Green; do
 [ ! -d "$d" ] || find "$d" -type f ! -name icon-theme.cache ! -name '*.png' -exec sha256sum {} +
done
'''
    # Alpine's tracked rasterizer generates PNGs and updates index.theme at
    # install time; compare source SVGs and the rasterizer binary itself.
    if distro == "alpine":
        command = command.replace("! -name '*.png'", "! -name '*.png' ! -name index.theme")
    result: dict[str, str] = {}
    for line in guest_run(distro, "/bin/sh", "-c", command).decode().splitlines():
        value, path = line.split(None, 1)
        result[path.strip().lstrip("*")] = value
    return result


def check_guest(distro: str) -> None:
    global checked
    config = PROFILES / distro / "profile"
    if not config.is_file():
        report(f"missing installed guest profile: {distro}")
        return
    user = next((x[5:] for x in config.read_text().splitlines() if x.startswith("user=")), "ternux")
    manifest = guest_manifest(distro)
    for target, actual_hash in manifest.items():
        source = source_path(target)
        if source is None:
            report(f"{distro} has unmapped Ternux-owned file: {target}")
            continue
        global_checked(1)
        if actual_hash != digest(source.read_bytes()):
            report(f"{distro} source mismatch: {source.relative_to(ROOT)} -> {target}")
    helper = ROOT / "lib/ternux-assets/bin/ternux-configure-prompt"
    check_bytes(f"{distro}:prompt-configurator", helper, guest_run(distro, "cat", "/usr/local/bin/ternux-configure-prompt"))
    template = block(helper.read_text()).replace(r"\$", "$")
    for name in (".bashrc", ".zshrc"):
        target = f"/home/{user}/{name}"
        try:
            text = guest_run(distro, "cat", target).decode()
        except RuntimeError:
            continue
        global_checked(1)
        try:
            actual = block(text)
        except ValueError:
            report(f"{distro}: missing Terfetch hook in {target}")
            continue
        if actual != template or text.count("# TERNUX TERFETCH START BEGIN") != 1:
            report(f"{distro}: stale Terfetch hook in {target}")


def global_checked(amount: int) -> None:
    global checked
    checked += amount


def main() -> int:
    if not shutil.which("proot-distro"):
        print("Run on the Termux host with proot-distro installed.", file=sys.stderr)
        return 2
    check_host()
    for distro in DISTROS:
        check_guest(distro)
    print(f"Checked {checked} Ternux-owned live paths across native Termux and {len(DISTROS)} guests.")
    print(f"Source parity: {'PASS' if errors == 0 else f'FAIL ({errors} mismatches)'}")
    return 0 if errors == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
