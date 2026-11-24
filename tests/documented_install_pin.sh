#!/usr/bin/env bash
# The downloaded standalone script must bootstrap the same reviewed source as
# the current installer, not the snapshot from one generation earlier.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
pin="$(python3 - "$ROOT" <<'PY'
from pathlib import Path
import re
import sys
root = Path(sys.argv[1])
paths = ["README.md", "bn/README.md", "docs/INSTALLATION.md", "docs/QUICK-START.md", "docs/TROUBLESHOOTING.md", "bn/docs/INSTALLATION.md", "bn/docs/QUICK-START.md", "bn/docs/TROUBLESHOOTING.md", "src/pages/index.astro", "src/pages/bn/index.astro"]
pattern = re.compile(r'https://raw\.githubusercontent\.com/soobujmiah/ternux/([0-9a-f]{40})/install\.sh')
pins = set()
for path in paths:
    matches = pattern.findall((root / path).read_text(encoding='utf-8'))
    if len(matches) != 2 or len(set(matches)) != 1:
        sys.exit(f'FAIL: {path} must pin curl and wget to the same installer commit')
    pins.update(matches)
if len(pins) != 1:
    sys.exit('FAIL: documented installer pins differ')
print(pins.pop())
PY
)"
curl -fsSL --retry 2 --connect-timeout 15 "https://codeload.github.com/soobujmiah/ternux/tar.gz/$pin" -o "$TMP/documented.tar.gz"
tar -xzf "$TMP/documented.tar.gz" -C "$TMP"
root_name="$(tar -tzf "$TMP/documented.tar.gz" | sed -n '1{s#/.*##;p;}')"
if ! cmp -s "$ROOT/install.sh" "$TMP/$root_name/install.sh"; then
  echo 'FAIL: documented installer does not match the current bootstrap (possibly a stale source pin)' >&2
  exit 1
fi
echo "PASS: all documented curl/wget commands download the current installer bootstrap"
