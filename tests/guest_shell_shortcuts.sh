#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin"
cat > "$TMP/bin/ternux" <<'CLI'
#!/usr/bin/env bash
printf '%s\n' "$*"
CLI
chmod 0755 "$TMP/bin/ternux"

declare -A expected=(
  [db]='distro shell debian'
  [dbr]='distro root debian'
  [dbroot]='distro root debian'
  [ub]='distro shell ubuntu'
  [ubr]='distro root ubuntu'
  [ubroot]='distro root ubuntu'
  [alp]='distro shell alpine'
  [alpr]='distro root alpine'
  [alproot]='distro root alpine'
)
for name in "${!expected[@]}"; do
  ln -s "$ROOT/bin/ternux-shell-shortcut" "$TMP/bin/$name"
  actual="$("$TMP/bin/$name" -- id)"
  [ "$actual" = "${expected[$name]} -- id" ] || {
    printf 'Shortcut %s dispatched as %s, expected %s\n' "$name" "$actual" "${expected[$name]} -- id" >&2
    exit 1
  }
done
echo "PASS: all Debian, Ubuntu, and Alpine user/root commands dispatch through the packaged CLI"
