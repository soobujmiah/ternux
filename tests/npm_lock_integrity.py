#!/usr/bin/env python3
"""Require immutable registry locations and valid SHA-512 SRI in the npm lock."""
import base64
import json
from pathlib import Path
from urllib.parse import urlparse

lock = json.loads(Path("package-lock.json").read_text())
assert lock.get("lockfileVersion") == 3, "expected npm lockfile v3"
packages = lock.get("packages", {})
checked = 0
for path, entry in packages.items():
    if not path:  # root project entry has no downloadable artifact
        continue
    if entry.get("link") or entry.get("inBundle"):
        continue
    resolved = entry.get("resolved", "")
    parsed = urlparse(resolved)
    assert parsed.scheme == "https" and parsed.hostname == "registry.npmjs.org", (
        f"{path}: missing exact HTTPS npm registry source"
    )
    digests = [token[7:] for token in entry.get("integrity", "").split() if token.startswith("sha512-")]
    assert digests, f"{path}: missing SHA-512 SRI"
    try:
        assert any(len(base64.b64decode(value, validate=True)) == 64 for value in digests)
    except (ValueError, AssertionError):
        raise AssertionError(f"{path}: invalid SHA-512 SRI digest")
    checked += 1
print(f"npm lock integrity policy: {checked} package records verified")
