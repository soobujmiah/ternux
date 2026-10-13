#!/usr/bin/env python3
"""Audit every ELF in the pinned llama.cpp package before release."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path


MIN_GLIBC = (2, 38)
EXPECTED_RUNPATH = "$ORIGIN/../lib"
SYSTEM_LIBRARIES = {
    "libc.so.6",
    "libcrypto.so.3",
    "libgcc_s.so.1",
    "libgomp.so.1",
    "libm.so.6",
    "libssl.so.3",
    "libstdc++.so.6",
    "libvulkan.so.1",
    "ld-linux-aarch64.so.1",
}


def readelf(*args: str) -> str:
    return subprocess.check_output(["readelf", *args], text=True)


def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {Path(sys.argv[0]).name} PACKAGE_ROOT", file=sys.stderr)
        return 2
    root = Path(sys.argv[1])
    if not root.is_dir():
        print(f"package directory does not exist: {root}", file=sys.stderr)
        return 2

    elf_files: list[Path] = []
    for path in sorted(root.rglob("*")):
        if not path.is_file():
            continue
        try:
            with path.open("rb") as stream:
                is_elf = stream.read(4) == b"\x7fELF"
        except OSError as exc:
            print(f"cannot read {path}: {exc}", file=sys.stderr)
            return 1
        if is_elf:
            elf_files.append(path)

    if not elf_files:
        print("package contains no ELF files", file=sys.stderr)
        return 1

    errors: list[str] = []
    sonames: set[str] = set()
    objects: list[tuple[Path, set[str]]] = []
    maximum_glibc = (0, 0)

    for path in elf_files:
        label = str(path.relative_to(root))
        try:
            header = readelf("-h", str(path))
            dynamic = readelf("-d", str(path))
            versions = readelf("--version-info", str(path))
        except subprocess.CalledProcessError as exc:
            errors.append(f"{label}: readelf failed with status {exc.returncode}")
            continue

        if not re.search(r"^\s*Machine:\s+AArch64\s*$", header, re.MULTILINE):
            errors.append(f"{label}: ELF machine is not AArch64")

        soname_match = re.search(r"\(SONAME\).*?\[([^]]+)\]", dynamic)
        if soname_match:
            sonames.add(soname_match.group(1))

        runpaths = re.findall(r"\((?:RUNPATH|RPATH)\).*?\[([^]]+)\]", dynamic)
        if not runpaths or any(value != EXPECTED_RUNPATH for value in runpaths):
            errors.append(f"{label}: expected RUNPATH {EXPECTED_RUNPATH!r}, found {runpaths or 'none'}")
        if any(token in dynamic for token in ("/home/runner", "/workspace/", "/data/data/")):
            errors.append(f"{label}: contains a build-host or Termux path")

        needed = set(re.findall(r"\(NEEDED\).*?\[([^]]+)\]", dynamic))
        objects.append((path, needed))
        for major, minor in re.findall(r"Name: GLIBC_(\d+)\.(\d+)", versions):
            required = (int(major), int(minor))
            maximum_glibc = max(maximum_glibc, required)
            if required > MIN_GLIBC:
                errors.append(f"{label}: requires GLIBC_{major}.{minor}, above the 2.38 baseline")

    for path, needed in objects:
        label = str(path.relative_to(root))
        for library in sorted(needed - sonames - SYSTEM_LIBRARIES):
            errors.append(f"{label}: unresolved package dependency {library}")

    if errors:
        print("llama.cpp package ABI audit failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print(
        f"llama.cpp package ABI audit passed: {len(elf_files)} AArch64 ELF files; "
        f"maximum GLIBC requirement {maximum_glibc[0]}.{maximum_glibc[1]}; "
        f"all package dependencies resolve; RUNPATH is {EXPECTED_RUNPATH}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
