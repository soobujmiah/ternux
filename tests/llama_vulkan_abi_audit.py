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


def audit_component_manifest(root: Path) -> list[str]:
    manifest_path = root / "COMPONENTS.json"
    if not manifest_path.is_file():
        return ["missing file-by-file COMPONENTS.json source map"]
    errors: list[str] = []
    try:
        import json

        data = json.loads(manifest_path.read_text(encoding="utf-8"))
        if data.get("schema_version") != 1:
            errors.append("unsupported COMPONENTS.json schema version")
        if data.get("artifact") != "ternux-llama-vulkan-linux-arm64-b11582":
            errors.append("COMPONENTS.json artifact identity mismatch")
        build_manifest = json.loads((root / "build-manifest.json").read_text(encoding="utf-8"))
        if data.get("upstream_commit") != build_manifest.get("upstream_commit"):
            errors.append("COMPONENTS.json upstream commit differs from build-manifest.json")
        if data.get("ternux_commit") != build_manifest.get("ternux_commit"):
            errors.append("COMPONENTS.json Ternux commit differs from build-manifest.json")
        records = data.get("files")
        if not isinstance(records, list):
            return errors + ["COMPONENTS.json files is not a list"]
        entries: dict[str, dict[str, object]] = {}
        for record in records:
            if not isinstance(record, dict):
                errors.append("COMPONENTS.json contains a non-object file record")
                continue
            relative = record.get("path")
            if not isinstance(relative, str) or Path(relative).is_absolute() or ".." in Path(relative).parts:
                errors.append(f"unsafe component-map path: {relative!r}")
                continue
            if relative in entries:
                errors.append(f"duplicate component-map path: {relative}")
                continue
            entries[relative] = record
            path = root / relative
            if not path.is_file() or path.is_symlink() and not path.exists():
                errors.append(f"component-map file is missing: {relative}")
                continue
            if record.get("sha256") != hashlib.sha256(path.read_bytes()).hexdigest():
                errors.append(f"component-map checksum mismatch: {relative}")
            if not isinstance(record.get("component"), str) or not record["component"]:
                errors.append(f"component-map label missing: {relative}")
            sources = record.get("source_paths")
            if not isinstance(sources, list) or not sources or any(not isinstance(x, str) or not x for x in sources):
                errors.append(f"source mapping missing: {relative}")
            if record.get("license_inventory") != "share/licenses/upstream/INDEX.txt":
                errors.append(f"license inventory reference missing: {relative}")
            if not isinstance(record.get("source_repository"), str) or not record["source_repository"]:
                errors.append(f"source repository missing: {relative}")
            if not isinstance(record.get("source_commit"), str) or len(record["source_commit"]) != 40:
                errors.append(f"source commit missing or malformed: {relative}")
            source_paths = record.get("source_paths")
            if not isinstance(source_paths, list) or not source_paths or any(not isinstance(x, str) or not x for x in source_paths):
                errors.append(f"source paths missing: {relative}")
        expected = {
            path.relative_to(root).as_posix()
            for path in root.rglob("*")
            if path.is_file() and path != manifest_path
        }
        if set(entries) != expected:
            missing = sorted(expected - set(entries))
            extra = sorted(set(entries) - expected)
            if missing:
                errors.append(f"component map omits packaged files: {missing[:8]}")
            if extra:
                errors.append(f"component map lists absent files: {extra[:8]}")
    except (OSError, ValueError, TypeError) as exc:
        errors.append(f"cannot audit component map: {exc}")
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
    errors.extend(audit_component_manifest(root))
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
