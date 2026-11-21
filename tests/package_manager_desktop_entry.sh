#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

export TNX_CAPTURED_SETUP="$TMP/guest-setup.sh"
bash -c '
  . "$1/lib/phases.sh"
  tnx_debian_installed() { return 0; }
  tnx_guest_run_script() {
    printf "%s" "$1" > "$TNX_CAPTURED_SETUP"
    return 1
  }
  tnx_phase_debian ternux >/dev/null 2>&1 || true
' _ "$ROOT"

bash -n "$TNX_CAPTURED_SETUP"
mkdir -p "$TMP/assets/applications" "$TMP/output"
cp "$ROOT/lib/ternux-assets/applications/ternux-package-manager.desktop" \
  "$TMP/assets/applications/"

export TNX_TEST_TMP="$TMP"
python3 - <<'PY'
import os
from pathlib import Path

root = Path(os.environ["TNX_TEST_TMP"])
lines = Path(os.environ["TNX_CAPTURED_SETUP"]).read_text().splitlines()
start = next(
    index - 1
    for index, line in enumerate(lines)
    if "apt) package_manager_name='Synaptic Package Manager'" in line
)
end = next(
    index
    for index, line in enumerate(lines[start:], start)
    if 'chmod 0644 "/usr/local/share/applications/$package_manager_desktop"' in line
)
rewrite = "\n".join(lines[start : end + 1]) + "\n"
rewrite = rewrite.replace("/usr/local/share/applications", str(root / "output"))
(root / "rewrite.sh").write_text("set -e\n" + rewrite)
PY

FAMILY=apt asset_stage="$TMP/assets" bash "$TMP/rewrite.sh"
entry="$TMP/output/ternux-synaptic.desktop"
grep -Fxq 'Name=Synaptic Package Manager' "$entry"
grep -Fxq 'Name[bn]=Synaptic Package Manager' "$entry"
grep -Fxq 'Icon=synaptic' "$entry"
echo 'PASS: generated guest setup preserves spaced package-manager names and writes its desktop entry'
