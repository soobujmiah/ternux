#!/usr/bin/env python3
"""Regression tests for upstream and transitive Stable Diffusion notices."""
from __future__ import annotations

import hashlib
import importlib.util
from pathlib import Path
import tempfile

source = Path(__file__).resolve().parents[1] / "tools/build_stable_diffusion_license_bundle.py"
spec = importlib.util.spec_from_file_location("sd_license_bundle", source)
assert spec and spec.loader
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

with tempfile.TemporaryDirectory() as temporary:
    root = Path(temporary)
    upstream = root / "stable-diffusion.cpp"
    deps = root / "build/_deps"
    output = root / "package/share/licenses"
    files = {
        upstream / "LICENSE": b"main upstream license\n",
        upstream / "vendor/ggml/LICENSE": b"nested vendored license\n",
        upstream / "vendor/ggml/COPYING": b"nested copying notice\n",
        upstream / "NOTICE": b"upstream notice\n",
        deps / "codec/COPYRIGHT.txt": b"dependency copyright\n",
        deps / "unicode/AUTHORS": b"dependency authors\n",
        deps / "crypto/PATENTS": b"dependency patents\n",
        deps / "parser/UNLICENSE": b"dependency unlicense\n",
        deps / "project/README.md": b"not a notice\n",
    }
    for path, content in files.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(content)
    project_license = root / "LICENSE"
    project_notice = root / "NOTICE"
    project_license.write_bytes(b"Ternux license\n")
    project_notice.write_bytes(b"Ternux notice\n")

    expected = {
        "stable-diffusion.cpp/LICENSE",
        "stable-diffusion.cpp/vendor/ggml/LICENSE",
        "stable-diffusion.cpp/vendor/ggml/COPYING",
        "stable-diffusion.cpp/NOTICE",
        "build/_deps/codec/COPYRIGHT.txt",
        "build/_deps/unicode/AUTHORS",
        "build/_deps/crypto/PATENTS",
        "build/_deps/parser/UNLICENSE",
        "TERNUX-LICENSE",
        "TERNUX-NOTICE",
    }
    index = module.build_bundle(
        [("stable-diffusion.cpp", upstream), ("build/_deps", deps)],
        [(project_license, "TERNUX-LICENSE"), (project_notice, "TERNUX-NOTICE")],
        output,
        ["stable-diffusion.cpp/LICENSE", "TERNUX-LICENSE", "TERNUX-NOTICE"],
    )
    assert set(index) == expected, (set(index) - expected, expected - set(index))
    assert (output / "stable-diffusion.cpp/vendor/ggml/LICENSE").read_bytes() == b"nested vendored license\n"
    assert "INDEX.txt" in {path.name for path in output.iterdir()}
    listed = (output / "SHA256SUMS").read_text().splitlines()
    assert len(listed) == len(expected)
    for line in listed:
        digest, relative = line.split("  ", 1)
        assert hashlib.sha256((output / relative).read_bytes()).hexdigest() == digest
    assert set((output / "INDEX.txt").read_text().splitlines()) == expected

    try:
        module.build_bundle([("stable-diffusion.cpp", upstream)], [], output, [])
    except ValueError as exc:
        assert "non-empty output" in str(exc)
    else:
        raise AssertionError("non-empty output directory was accepted")

    escaped = root / "external" / "LICENSE"
    escaped.parent.mkdir()
    escaped.write_text("outside source tree\n")
    (upstream / "vendor/ggml/LICENSE-OUTSIDE").symlink_to(escaped)
    try:
        module.collect_files([("stable-diffusion.cpp", upstream)], [])
    except ValueError as exc:
        assert "escapes source tree" in str(exc)
    else:
        raise AssertionError("license symlink escaping source tree was accepted")

print("Stable Diffusion license bundle tests passed")
