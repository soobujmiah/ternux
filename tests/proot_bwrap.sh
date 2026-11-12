#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

source_script="$ROOT/lib/ternux-assets/bin/ternux-proot-bwrap"
test_wrapper="$TMP/bwrap"
sed \
  -e "s#/usr/libexec/glycin-loaders#$TMP/glycin-loaders#g" \
  -e "s#/usr/lib/glycin-loaders#$TMP/legacy-glycin-loaders#g" \
  -e "s#/usr/bin/bwrap#$TMP/real-bwrap#g" \
  "$source_script" > "$test_wrapper"
chmod 0755 "$test_wrapper"
bash -n "$test_wrapper"

mkdir -p "$TMP/glycin-loaders/2+"
cat > "$TMP/glycin-loaders/2+/glycin-svg" <<'LOADER'
#!/usr/bin/env bash
set -euo pipefail
[[ "${1:-}" = --dbus-fd && "${2:-}" =~ ^[0-9]+$ ]]
IFS= read -r -u "$2" payload
printf 'GLYCIN:%s\n' "$payload"
LOADER
chmod 0755 "$TMP/glycin-loaders/2+/glycin-svg"

cat > "$TMP/real-bwrap" <<'REAL_BWRAP'
#!/usr/bin/env bash
printf 'REAL_BWRAP'
printf ' <%s>' "$@"
printf '\n'
REAL_BWRAP
chmod 0755 "$TMP/real-bwrap"

printf 'inherited-fd\n' > "$TMP/fd-data"
loader_result="$(bash "$test_wrapper" --unshare-all --ro-bind /usr /usr \
  "$TMP/glycin-loaders/2+/glycin-svg" --dbus-fd 9 9<"$TMP/fd-data")"
[ "$loader_result" = 'GLYCIN:inherited-fd' ]

fallback_result="$(bash "$test_wrapper" --unshare-all --ro-bind /usr /usr /bin/true)"
[ "$fallback_result" = 'REAL_BWRAP <--unshare-all> <--ro-bind> </usr> </usr> </bin/true>' ]

if bash "$test_wrapper" "$TMP/glycin-loaders/2+/glycin-svg" >/dev/null 2>&1; then
  echo "Glycin loader without a D-Bus fd unexpectedly ran" >&2
  exit 1
else
  [ "$?" -eq 125 ]
fi

echo "PASS: Glycin gets only its inherited D-Bus fd; every other bwrap call stays on the real binary"
