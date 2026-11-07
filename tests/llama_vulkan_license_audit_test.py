#!/usr/bin/env python3
"""Unit checks for the llama.cpp artifact's upstream notice bundle audit."""
import hashlib
import importlib.util
from pathlib import Path
import tempfile

source = Path(__file__).with_name("llama_vulkan_abi_audit.py")
spec = importlib.util.spec_from_file_location("llama_vulkan_abi_audit", source)
assert spec and spec.loader
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    bundle = root / "share/licenses/upstream"
    bundle.mkdir(parents=True)
    (root / "LLAMA-CPP-LICENSE").write_text("top-level license\n")
    text = b"third-party license terms\n"
    (bundle / "LICENSE.txt").write_bytes(text)
    notice = b"attribution notice\n"
    (bundle / "NOTICE.txt").write_bytes(notice)
    (bundle / "INDEX.txt").write_text("LICENSE.txt\nNOTICE.txt\n")
    digest = hashlib.sha256(text).hexdigest()
    notice_digest = hashlib.sha256(notice).hexdigest()
    (bundle / "SHA256SUMS").write_text(
        f"{digest}  LICENSE.txt\n{notice_digest}  NOTICE.txt\n")
    assert module.audit_license_bundle(root) == []
    (bundle / "LICENSE.txt").write_text("modified terms\n")
    assert any("checksum mismatch" in issue for issue in module.audit_license_bundle(root))
    (bundle / "INDEX.txt").write_text("../outside\n")
    assert any("unsafe upstream license path" in issue for issue in module.audit_license_bundle(root))

print("llama.cpp upstream license bundle audit tests passed")
