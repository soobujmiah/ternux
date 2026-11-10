#!/usr/bin/env python3
"""Keep bundled webfont attribution and full SIL OFL texts in sync."""
from hashlib import sha256
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
NOTICE = (ROOT / "NOTICE").read_text(encoding="utf-8")
LICENSES = (ROOT / "assets/fonts/LICENSES.md").read_text(encoding="utf-8")

assets = {
    "atma-regular.ttf": "Copyright 2015 The Atma Project Authors",
    "caveat-bold-latin.woff2": "Copyright 2014 The Caveat Project Authors",
    "jetbrains-mono-latin.woff2": "Copyright 2020 The JetBrains Mono Project Authors",
    "noto-bengali.woff2": "Copyright 2025 The Noto Project Authors",
    "space-grotesk-latin.woff2": "Copyright 2020 The Space Grotesk Project Authors",
}
for filename, attribution in assets.items():
    assert (ROOT / "assets/fonts" / filename).is_file(), filename
    assert filename in LICENSES, f"font asset missing from attribution inventory: {filename}"
    assert attribution in LICENSES, f"font metadata attribution missing: {attribution}"
    assert attribution in NOTICE, f"product NOTICE attribution missing: {attribution}"

license_hashes = {
    "NOTO-SANS-BENGALI-OFL.txt": "754f0e221aa7d5a915489f3bf1f20fe53ddc35ab2834a4d91656d78f9622de70",
    "ATMA-OFL.txt": "30ac5dae4c0ceeadd011cb25012b34907cabefbc99c66086fd0541850995ab0f",
}
for filename, expected_hash in license_hashes.items():
    path = ROOT / "assets/fonts" / filename
    text = path.read_text(encoding="utf-8")
    assert "SIL OPEN FONT LICENSE Version 1.1" in text, filename
    assert len(text.splitlines()) >= 80, f"incomplete OFL text: {filename}"
    assert sha256(path.read_bytes()).hexdigest() == expected_hash, filename
    assert filename in NOTICE, f"NOTICE does not link to {filename}"

assert "85d80394cbbbb798ca0a41c983902e6cf77be3a3" in LICENSES
assert "Copyright 2015 Google Inc." not in NOTICE
assert "Copyright 2020 JetBrains s.r.o." not in NOTICE
print("font license inventory and OFL attribution checks passed")
