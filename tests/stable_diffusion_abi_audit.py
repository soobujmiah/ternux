#!/usr/bin/env python3
"""Fail closed on Stable Diffusion ARM64 extension layout and ABI regressions."""
from __future__ import annotations

import hashlib
import json
import pathlib
import subprocess
import sys


def fail(message: str) -> None:
    raise SystemExit(f"Stable Diffusion ABI audit failed: {message}")


root = pathlib.Path(sys.argv[1]).resolve()
binary = root / "bin/sd-cli"
manifest_path = root / "build-manifest.json"
license_dir = root / "share/licenses"
for required in (binary, manifest_path, root / "env.sh", license_dir / "SHA256SUMS"):
    if not required.exists():
        fail(f"missing required path: {required.relative_to(root)}")
if not binary.is_file() or not binary.stat().st_mode & 0o111:
    fail("bin/sd-cli is not an executable regular file")

header = subprocess.check_output(["readelf", "-h", str(binary)], text=True)
if "AArch64" not in header or "ELF64" not in header:
    fail("sd-cli is not ELF64 AArch64")
dynamic = subprocess.check_output(["readelf", "-d", str(binary)], text=True)
if "/home/runner" in dynamic or "/workspace/" in dynamic:
    fail("dynamic section leaks build-host paths")
needed = subprocess.check_output(["readelf", "-d", str(binary)], text=True)
for library in ("libgomp.so.1",):
    if library not in needed:
        fail(f"expected dynamic runtime dependency absent: {library}")
ldd = subprocess.check_output(["ldd", str(binary)], text=True)
if "not found" in ldd:
    fail("unresolved runtime dependency")

environment = (root / "env.sh").read_text()
if "ternux_freedreno_icd.json" not in environment or "freedreno_icd.aarch64.json" not in environment:
    fail("environment helper does not discover the managed or distro Freedreno Vulkan ICD")

manifest = json.loads(manifest_path.read_text())
if manifest.get("artifact") != "ternux-stable-diffusion-vulkan-linux-arm64-master-1053":
    fail("unexpected artifact identity")
if manifest.get("target") != "linux-aarch64" or manifest.get("backends") != ["CPU", "Vulkan"]:
    fail("target/backend metadata mismatch")
if manifest.get("weights_included") is not False:
    fail("model weights must stay external to this runtime artifact")
if manifest.get("upstream_commit") != "5a1ba5d895bec4e07deab80d6d791721cd59d9c2":
    fail("upstream commit pin mismatch")

checksums = license_dir / "SHA256SUMS"
listed = 0
for line in checksums.read_text().splitlines():
    digest, rel = line.split("  ", 1)
    target = (license_dir / rel).resolve()
    if license_dir.resolve() not in target.parents or not target.is_file():
        fail(f"unsafe or missing license path: {rel}")
    actual = hashlib.sha256(target.read_bytes()).hexdigest()
    if actual != digest:
        fail(f"license checksum mismatch: {rel}")
    listed += 1
if listed < 1:
    fail("no license notices bundled")
print(f"Stable Diffusion ARM64 ABI audit passed; checked {listed} license notices")
