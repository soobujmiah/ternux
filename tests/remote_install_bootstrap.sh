#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin"
printf 'echo installed > "$FIXTURE_MARKER"\n' > "$TMP/installer.sh"
export FIXTURE_INSTALLER="$TMP/installer.sh" FIXTURE_MARKER="$TMP/ran"

cat > "$TMP/bin/pkg" <<'MOCK'
#!/usr/bin/env bash
exit 0
MOCK
cat > "$TMP/bin/curl" <<'MOCK'
#!/usr/bin/env bash
[[ "${CURL_MODE:-fail}" == healthy ]] || exit 22
while (($#)); do
  if [[ "$1" == -o ]]; then cp "$FIXTURE_INSTALLER" "$2"; exit 0; fi
  shift
done
exit 2
MOCK
cat > "$TMP/bin/wget" <<'MOCK'
#!/usr/bin/env bash
[[ "${WGET_MODE:-healthy}" == healthy ]] || exit 8
while (($#)); do
  if [[ "$1" == -O || "$1" == -qO ]]; then cp "$FIXTURE_INSTALLER" "$2"; exit 0; fi
  if [[ "$1" == -qO* ]]; then cp "$FIXTURE_INSTALLER" "${1#-qO}"; exit 0; fi
  shift
done
exit 2
MOCK
chmod +x "$TMP/bin/pkg" "$TMP/bin/curl" "$TMP/bin/wget"
command="$(sed -n '/^bash -c .*raw\.githubusercontent\.com\/soobujmiah\/ternux\/main\/install\.sh/p' "$ROOT/README.md" | head -n 1)"
[[ -n "$command" ]] || { echo 'FAIL: documented installer command not found' >&2; exit 1; }

PATH="$TMP/bin:$PATH" CURL_MODE=fail WGET_MODE=healthy bash -c "$command"
[[ -f "$TMP/ran" ]] || { echo 'FAIL: wget fallback did not run the downloaded installer' >&2; exit 1; }
rm -f "$TMP/ran"
PATH="$TMP/bin:$PATH" CURL_MODE=healthy WGET_MODE=healthy bash -c "$command"
[[ -f "$TMP/ran" ]] || { echo 'FAIL: healthy curl did not run the downloaded installer' >&2; exit 1; }
rm -f "$TMP/ran"
if PATH="$TMP/bin:$PATH" CURL_MODE=fail WGET_MODE=fail bash -c "$command"; then
  echo 'FAIL: bootstrap accepted two failed downloaders' >&2
  exit 1
fi
[[ ! -e "$TMP/ran" ]] || { echo 'FAIL: installer ran after both downloads failed' >&2; exit 1; }
echo 'PASS: documented bootstrap retries with wget and runs only a downloaded installer'
