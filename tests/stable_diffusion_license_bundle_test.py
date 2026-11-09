#!/usr/bin/env python3
"""Regression tests for Stable Diffusion license inventory generation."""
from __future__ import annotations

import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile

repo = Path(__file__).resolve().parents[1]
source = repo / "tools/build_stable_diffusion_license_bundle.py"
spec = importlib.util.spec_from_file_location("sd_license_bundle", source)
assert spec and spec.loader
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
components_path = repo / "packaging/stable-diffusion/components.json"
components = module._load_components(components_path)
ternux_component = next(component for component in components["components"] if component["id"] == "ternux")
assert ternux_component["license"] == "Apache-2.0", ternux_component
assert "TERNUX-LICENSE" in ternux_component["archive_license_files"]
assert "TERNUX-NOTICE" in ternux_component["archive_license_files"]

with tempfile.TemporaryDirectory() as temporary:
    root = Path(temporary)
    upstream = root / "stable-diffusion.cpp"
    deps = root / "build/_deps"
    output = root / "package/share/licenses"
    project_license = root / "LICENSE"
    project_notice = root / "NOTICE"
    project_license.write_bytes(b"Ternux license\n")
    project_notice.write_bytes(b"Ternux notice\n")

    # Materialize every source file required by the checked-in component manifest.
    for component in components["components"]:
        label = component.get("source_tree")
        if label != "stable-diffusion.cpp":
            continue
        for relative in component.get("license_files", []) + component.get("embedded_notice_sources", []):
            path = upstream / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(f"fixture: {relative}\n".encode())
    (upstream / "LICENSE").write_bytes(b"main upstream license\n")
    (upstream / "ggml/AUTHORS").write_bytes(b"ggml authors attribution\n")
    (upstream / "ggml/LICENSE").write_bytes(b"ggml license\n")
    (upstream / "thirdparty/LICENSE.darts_clone.txt").write_bytes(b"darts license\n")
    (upstream / "thirdparty/oniguruma/COPYING").write_bytes(b"oniguruma license\n")
    (upstream / "thirdparty/utf8proc/LICENSE.md").write_bytes(b"utf8proc license\n")
    (upstream / "NOTICE").write_bytes(b"upstream notice\n")
    deps.mkdir(parents=True)
    (deps / "codec").mkdir()
    (deps / "codec/COPYRIGHT.txt").write_bytes(b"dependency copyright\n")
    (deps / "project").mkdir()
    (deps / "project/README.md").write_bytes(b"not a notice\n")

    index = module.build_bundle(
        [("stable-diffusion.cpp", upstream)],
        [("cmake-deps", deps)],
        [(project_license, "TERNUX-LICENSE"), (project_notice, "TERNUX-NOTICE")],
        components_path,
        output,
        ["stable-diffusion.cpp/LICENSE", "stable-diffusion.cpp/ggml/AUTHORS",
         "TERNUX-LICENSE", "TERNUX-NOTICE"],
    )
    expected_source_notices = {
        "source-notices/stable-diffusion.cpp/thirdparty/miniz.h",
        "source-notices/stable-diffusion.cpp/thirdparty/json.hpp",
        "source-notices/stable-diffusion.cpp/thirdparty/stb_image.h",
        "source-notices/stable-diffusion.cpp/thirdparty/stb_image_write.h",
        "source-notices/stable-diffusion.cpp/thirdparty/stb_image_resize.h",
    }
    assert expected_source_notices <= set(index)
    assert "stable-diffusion.cpp/thirdparty/oniguruma/COPYING" in index
    assert "stable-diffusion.cpp/thirdparty/utf8proc/LICENSE.md" in index
    assert "stable-diffusion.cpp/thirdparty/LICENSE.darts_clone.txt" in index
    assert "cmake-deps/codec/COPYRIGHT.txt" in index
    assert "cmake-deps/project/README.md" not in index
    assert json.loads((output / "COMPONENTS.json").read_text()) == components
    metadata = json.loads((output / "BUNDLE-METADATA.json").read_text())
    assert metadata["source_trees"] == [
        {"label": "cmake-deps", "present": True, "notice_files": 1},
        {"label": "stable-diffusion.cpp", "present": True, "notice_files": 7},
    ]
    assert (output / "source-notices/stable-diffusion.cpp/thirdparty/json.hpp").read_bytes() == (upstream / "thirdparty/json.hpp").read_bytes()
    listed = (output / "SHA256SUMS").read_text().splitlines()
    assert len(listed) == len(index) and len(listed) == len(set(line.split("  ", 1)[1] for line in listed))
    for line in listed:
        digest, relative = line.split("  ", 1)
        assert hashlib.sha256((output / relative).read_bytes()).hexdigest() == digest
    assert (output / "INDEX.txt").read_text().splitlines() == index

    # A genuinely absent optional dependency tree must be recorded, not assumed
    # to exist and not silently represented as a present empty directory.
    absent_output = root / "package/missing-deps"
    absent_index = module.build_bundle(
        [("stable-diffusion.cpp", upstream)],
        [("cmake-deps", root / "missing/_deps")],
        [(project_license, "TERNUX-LICENSE"), (project_notice, "TERNUX-NOTICE")],
        components_path,
        absent_output,
        ["stable-diffusion.cpp/LICENSE", "TERNUX-LICENSE", "TERNUX-NOTICE"],
    )
    absent_metadata = json.loads((absent_output / "BUNDLE-METADATA.json").read_text())
    assert absent_metadata["source_trees"][0] == {
        "label": "cmake-deps", "present": False, "notice_files": 0
    }
    assert "source-notices/stable-diffusion.cpp/thirdparty/miniz.h" in absent_index

    # Duplicate destination paths and duplicate manifest IDs fail closed.
    try:
        module.collect_files(
            [("stable-diffusion.cpp", upstream)], [],
            [(project_license, "stable-diffusion.cpp/LICENSE")], components
        )
    except ValueError as exc:
        assert "duplicate bundle path" in str(exc)
    else:
        raise AssertionError("duplicate license destination was accepted")
    duplicate_manifest = root / "duplicate-components.json"
    duplicate_data = dict(components)
    duplicate_data["components"] = components["components"] + [components["components"][0]]
    duplicate_manifest.write_text(json.dumps(duplicate_data))
    try:
        module._load_components(duplicate_manifest)
    except ValueError as exc:
        assert "unique" in str(exc)
    else:
        raise AssertionError("duplicate component ID was accepted")

    # Required source trees and component license entries fail closed.
    try:
        module.collect_files([("stable-diffusion.cpp", root / "missing-source")], [], [], components)
    except FileNotFoundError as exc:
        assert "required source tree is missing" in str(exc)
    else:
        raise AssertionError("missing required upstream source tree was accepted")

    (upstream / "thirdparty/oniguruma/COPYING").unlink()
    try:
        module.collect_files([("stable-diffusion.cpp", upstream)], [], [], components)
    except ValueError as exc:
        assert "thirdparty/oniguruma/COPYING" in str(exc)
    else:
        raise AssertionError("missing compiled component license was accepted")

    escaped = root / "external/LICENSE"
    escaped.parent.mkdir()
    escaped.write_text("outside source tree\n")
    (upstream / "vendor").mkdir()
    (upstream / "vendor/LICENSE-OUTSIDE").symlink_to(escaped)
    try:
        module.collect_files([("stable-diffusion.cpp", upstream)], [], [], components)
    except ValueError as exc:
        assert "escapes source tree" in str(exc)
    else:
        raise AssertionError("license symlink escaping source tree was accepted")

print("Stable Diffusion license bundle tests passed")
