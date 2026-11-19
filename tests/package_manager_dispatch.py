#!/usr/bin/env python3
"""Exercise the native package-manager menu with isolated command stubs."""
from __future__ import annotations

import os
import subprocess
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
launcher = root / "lib/ternux-assets/bin/ternux-package-manager"
families = {
    "apt": ("apt-get", "APT", ["apt update", "apt upgrade", "apt-cache search query", "apt install -y -- example-pkg", "apt remove -y -- example-pkg", "dpkg-query -W -f=${binary:Package}\\n"]),
    "apk": ("apk", "APK", ["apk update", "apk upgrade", "apk search -v query", "apk add -- example-pkg", "apk del -- example-pkg", "apk info"]),
    "pacman": ("pacman", "Pacman", ["pacman -Syy", "pacman -Syu", "pacman -Ss query", "pacman -S example-pkg", "pacman -R example-pkg", "pacman -Q"]),
    "dnf": ("dnf", "DNF", ["dnf makecache --refresh", "dnf upgrade", "dnf search query", "dnf install example-pkg", "dnf remove example-pkg", "dnf list --installed"]),
    "zypper": ("zypper", "Zypper", ["zypper --non-interactive refresh", "zypper update", "zypper search query", "zypper install example-pkg", "zypper remove example-pkg", "zypper packages --installed-only"]),
    "xbps": ("xbps-install", "XBPS", ["xbps-install -S", "xbps-install -Su", "xbps-query -Rs query", "xbps-install example-pkg", "xbps-remove example-pkg", "xbps-query -l"]),
}
inputs = "1\n2\n3\nquery\n4\nexample-pkg\n5\nexample-pkg\n6\n0\n"

with tempfile.TemporaryDirectory(prefix="ternux-pm-dispatch-") as temp:
    temp_root = Path(temp)
    for family, (detect_binary, manager_label, expected) in families.items():
        bindir = temp_root / family
        bindir.mkdir()
        log = temp_root / f"{family}.log"
        commands = {detect_binary}
        if family == "apt":
            commands.update(("apt", "apt-cache", "dpkg-query"))
        elif family == "xbps":
            commands.update(("xbps-query", "xbps-remove"))
        else:
            commands.add(family)
        for command in commands | {"sudo"}:
            executable = bindir / command
            if command == "sudo":
                body = '#!/bin/sh\nexec "$@"\n'
            else:
                body = '#!/bin/sh\nprintf "%s" "$0" >> "$PM_LOG"\nfor arg in "$@"; do printf " %s" "$arg" >> "$PM_LOG"; done\nprintf "\\n" >> "$PM_LOG"\n'
            executable.write_text(body)
            executable.chmod(0o755)

        environment = os.environ.copy()
        manager_file = temp_root / f"{family}.manager"
        manager_file.write_text(f"{family}\n")
        environment.update(
            PATH=f"{bindir}:/system/bin",
            PM_LOG=str(log),
            TERNUX_PACKAGE_MANAGER_FILE=str(manager_file),
        )
        result = subprocess.run(
            [str(launcher), "--terminal"],
            input=inputs,
            text=True,
            capture_output=True,
            env=environment,
            timeout=10,
        )
        actual = [line.replace(f"{bindir}/", "") for line in log.read_text().splitlines()] if log.exists() else []
        if result.returncode != 0 or actual != expected or f"{manager_label} package manager" not in result.stdout:
            raise SystemExit(
                f"{family} dispatch mismatch: status={result.returncode}, "
                f"actual={actual!r}, expected={expected!r}, label={manager_label!r}, stderr={result.stderr!r}"
            )
        print(f"{family}: all six native package operations dispatched")

print("PASS: all six supported package-manager menus route actions to native tools")
