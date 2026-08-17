#!/data/data/com.termux/files/usr/bin/bash
# =============================================================================
#  ternux — clean removal script
#
#  Usage
#    curl -fsSL https://soobujmiah.github.io/ternux/uninstall.sh | bash
#    bash uninstall.sh [session|launcher|state|container|all] [--yes]
#    bash uninstall.sh [1|2|3|4|5] [--yes]
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah) — MIT License
#  https://github.com/soobujmiah/ternux
# =============================================================================
set -u

# Detect and delegate to ternux CLI if available
for _try in \
  "/data/data/com.termux/files/usr/bin/ternux" \
  "${PREFIX:-}/bin/ternux" \
  "$HOME/.local/bin/ternux" \
  "$(cd "$(dirname "$0")" && pwd)/bin/ternux"; do
  if [ -x "$_try" ]; then
    exec "$_try" uninstall "$@"
  fi
done

# Local checkout fallback: run the same scoped implementation directly.
_root="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$_root/lib/core.sh" ] && [ -f "$_root/lib/uninstall.sh" ]; then
  # shellcheck source=lib/core.sh
  . "$_root/lib/core.sh"
  # shellcheck source=lib/uninstall.sh
  . "$_root/lib/uninstall.sh"
  tnx_cmd_uninstall "$@"
  exit $?
fi

# Direct-pipe fallback: fetch the same scoped implementation used by the CLI.
# Download every dependency first and syntax-check both files before sourcing
# either one. This keeps the published curl route functional without silently
# substituting a destructive catch-all script.
_TNX_REMOTE_LOADED=0
_tnx_load_remote_uninstaller() {
  local base="https://raw.githubusercontent.com/soobujmiah/ternux/main"
  local tmpdir="" file=""
  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/ternux-uninstall.XXXXXX")" || return 1

  for file in core.sh uninstall.sh; do
    if command -v curl >/dev/null 2>&1; then
      curl -fsSL --max-time 15 "$base/lib/$file" -o "$tmpdir/$file" 2>/dev/null || {
        rm -rf "$tmpdir"; return 1;
      }
    elif command -v wget >/dev/null 2>&1; then
      wget -q --timeout=15 "$base/lib/$file" -O "$tmpdir/$file" 2>/dev/null || {
        rm -rf "$tmpdir"; return 1;
      }
    else
      rm -rf "$tmpdir"
      return 1
    fi
  done

  for file in "$tmpdir/core.sh" "$tmpdir/uninstall.sh"; do
    bash -n "$file" 2>/dev/null || { rm -rf "$tmpdir"; return 1; }
  done

  # shellcheck disable=SC1090
  . "$tmpdir/core.sh" || { rm -rf "$tmpdir"; return 1; }
  # lib/uninstall.sh locates this downloaded core.sh beside itself.
  # shellcheck disable=SC1090
  . "$tmpdir/uninstall.sh" || { rm -rf "$tmpdir"; return 1; }
  rm -rf "$tmpdir"
  _TNX_REMOTE_LOADED=1
  tnx_cmd_uninstall "$@"
}

_tnx_load_remote_uninstaller "$@"
_tnx_rc=$?
[ "$_TNX_REMOTE_LOADED" = "1" ] && exit "$_tnx_rc"

cat >&2 << 'EOF'
[FATAL] Could not load the scoped ternux uninstaller.

Preferred recovery:
  git clone https://github.com/soobujmiah/ternux.git
  cd ternux
  bash uninstall.sh

If the ternux CLI is installed, run:
  ternux uninstall

No components were removed by this fallback.
EOF
exit "$_tnx_rc"
