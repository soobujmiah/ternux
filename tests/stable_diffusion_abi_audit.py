#!/usr/bin/env python3
"""Fail closed on Stable Diffusion ARM64 ABI and notice-bundle regressions."""
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
required_paths = (
    binary, manifest_path, root / "env.sh", license_dir / "INDEX.txt",
    license_dir / "SHA256SUMS", license_dir / "COMPONENTS.json",
    license_dir / "BUNDLE-METADATA.json", license_dir / "README.md",
)
for required in required_paths:
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
for library in ("libgomp.so.1",):
    if library not in dynamic:
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
if manifest.get("license_index") != "share/licenses/INDEX.txt":
    fail("build manifest does not point to the license index")
if manifest.get("license_components") != "share/licenses/COMPONENTS.json":
    fail("build manifest does not point to the component/license manifest")

index_path = license_dir / "INDEX.txt"
checksums = license_dir / "SHA256SUMS"
indexed = index_path.read_text().splitlines()
if not indexed or indexed != sorted(set(indexed)):
    fail("license index is empty, duplicated, or unsorted")
components = json.loads((license_dir / "COMPONENTS.json").read_text())
if components.get("schema_version") != 1:
    fail("unsupported component/license manifest schema")
if components.get("artifact") != manifest.get("artifact"):
    fail("component/license manifest artifact identity mismatch")
if components.get("upstream", {}).get("commit") != manifest.get("upstream_commit"):
    fail("component/license manifest upstream commit mismatch")
if components.get("upstream", {}).get("submodules", {}).get("ggml", {}).get("commit") != "135ce1e0e3f2b0693d3de93d4f6b5fa0a1947820":
    fail("component/license manifest ggml pin mismatch")
component_ids = [component.get("id") for component in components.get("components", [])]
if not component_ids or len(component_ids) != len(set(component_ids)):
    fail("component manifest is empty or has duplicate IDs")
for component in components["components"]:
    source_tree = component.get("source_tree")
    if source_tree is not None:
        for rel in component.get("license_files", []):
            if f"{source_tree}/{rel}" not in indexed:
                fail(f"component license omitted: {component.get('id')}: {rel}")
        for rel in component.get("embedded_notice_sources", []):
            if f"source-notices/{source_tree}/{rel}" not in indexed:
                fail(f"embedded source notice omitted: {component.get('id')}: {rel}")
    for rel in component.get("archive_license_files", []):
        if rel not in indexed:
            fail(f"archive license omitted: {component.get('id')}: {rel}")

checksum_lines = checksums.read_text().splitlines()
checksum_entries = {}
for line in checksum_lines:
    digest, rel = line.split("  ", 1)
    target = (license_dir / rel).resolve()
    if license_dir.resolve() not in target.parents or not target.is_file():
        fail(f"unsafe or missing license path: {rel}")
    actual = hashlib.sha256(target.read_bytes()).hexdigest()
    if actual != digest:
        fail(f"license checksum mismatch: {rel}")
    checksum_entries[rel] = digest
if len(checksum_entries) != len(checksum_lines) or set(checksum_entries) != set(indexed):
    fail("license index and checksum inventory differ or contain duplicates")
required_notices = (
    "stable-diffusion.cpp/LICENSE", "stable-diffusion.cpp/ggml/LICENSE",
    "stable-diffusion.cpp/ggml/AUTHORS",
    "stable-diffusion.cpp/thirdparty/LICENSE.darts_clone.txt",
    "stable-diffusion.cpp/thirdparty/oniguruma/COPYING",
    "stable-diffusion.cpp/thirdparty/utf8proc/LICENSE.md",
    "source-notices/stable-diffusion.cpp/thirdparty/miniz.h",
    "source-notices/stable-diffusion.cpp/thirdparty/json.hpp",
    "source-notices/stable-diffusion.cpp/thirdparty/stb_image.h",
    "source-notices/stable-diffusion.cpp/thirdparty/stb_image_write.h",
    "source-notices/stable-diffusion.cpp/thirdparty/stb_image_resize.h",
    "TERNUX-LICENSE", "TERNUX-NOTICE",
)
for required in required_notices:
    if required not in indexed:
        fail(f"required upstream/project license missing: {required}")
print(f"Stable Diffusion ARM64 ABI and component-license audit passed; checked {len(indexed)} bundle items")
