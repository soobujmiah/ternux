#!/usr/bin/env python3
"""Audit every ELF in the pinned llama.cpp package before release."""

from __future__ import annotations

import hashlib
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


def audit_license_bundle(root: Path) -> list[str]:
    """Check the indexed upstream license texts and their complete hash list."""
    bundle = root / "share/licenses/upstream"
    index = bundle / "INDEX.txt"
    checksums = bundle / "SHA256SUMS"
    errors: list[str] = []
    if not (root / "LLAMA-CPP-LICENSE").is_file():
        errors.append("missing top-level LLAMA-CPP-LICENSE")
    if not index.is_file() or not checksums.is_file():
        return errors + ["missing upstream license INDEX.txt or SHA256SUMS"]
    try:
        indexed = [line for line in index.read_text(encoding="utf-8").splitlines() if line]
        entries: dict[str, str] = {}
        for line in checksums.read_text(encoding="utf-8").splitlines():
            digest, separator, relative = line.partition("  ")
            if not separator or len(digest) != 64 or relative in entries:
                errors.append(f"malformed or duplicate upstream license checksum: {line!r}")
                continue
            entries[relative] = digest
        if not indexed:
            errors.append("upstream license index is empty")
        if len(indexed) != len(set(indexed)):
            errors.append("upstream license index contains duplicates")
        if set(indexed) != set(entries):
            errors.append("upstream license index and checksum manifest list different files")
        for relative in indexed:
            path = bundle / relative
            if Path(relative).is_absolute() or ".." in Path(relative).parts:
                errors.append(f"unsafe upstream license path: {relative}")
                continue
            if not path.is_file() or path.is_symlink():
                errors.append(f"missing or non-regular upstream license file: {relative}")
                continue
            actual = hashlib.sha256(path.read_bytes()).hexdigest()
            if entries.get(relative) != actual:
                errors.append(f"upstream license checksum mismatch: {relative}")
    except (OSError, UnicodeError) as exc:
        errors.append(f"cannot read upstream license bundle: {exc}")
    return errors


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

    errors: list[str] = audit_license_bundle(root)
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
