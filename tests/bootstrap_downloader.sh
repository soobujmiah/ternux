#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin"
printf 'verified source bundle fixture\n' > "$TMP/payload"
: > "$TMP/log"
export MOCK_DOWNLOAD_LOG="$TMP/log" MOCK_DOWNLOAD_PAYLOAD="$TMP/payload"

cat > "$TMP/bin/curl" <<'MOCK_CURL'
#!/usr/bin/env bash
printf 'curl:%s\n' "$1" >> "$MOCK_DOWNLOAD_LOG"
if [ "$1" = --version ]; then [ "${MOCK_CURL_MODE:-broken}" = healthy ]; exit; fi
[ "${MOCK_CURL_MODE:-broken}" = download-fails ] && exit 22
out=""
while [ "$#" -gt 0 ]; do
  if [ "$1" = -o ]; then out="$2"; shift 2; else shift; fi
done
cp "$MOCK_DOWNLOAD_PAYLOAD" "$out"
MOCK_CURL
cat > "$TMP/bin/wget" <<'MOCK_WGET'
#!/usr/bin/env bash
printf 'wget:%s\n' "$1" >> "$MOCK_DOWNLOAD_LOG"
if [ "$1" = --version ]; then [ "${MOCK_WGET_MODE:-healthy}" = healthy ]; exit; fi
[ "${MOCK_WGET_MODE:-healthy}" = healthy ] || exit 8
out=""
while [ "$#" -gt 0 ]; do
  if [ "$1" = -O ]; then out="$2"; shift 2; else shift; fi
done
cp "$MOCK_DOWNLOAD_PAYLOAD" "$out"
MOCK_WGET
chmod +x "$TMP/bin/curl" "$TMP/bin/wget"

awk '/^_tnx_download_archive\(\) \{/ { copy=1 } copy { print } copy && /^}/ { exit }' \
  "$ROOT/install.sh" > "$TMP/downloader.sh"
. "$TMP/downloader.sh"

export PATH="$TMP/bin:$PATH"
MOCK_CURL_MODE=broken MOCK_WGET_MODE=healthy
export MOCK_CURL_MODE MOCK_WGET_MODE
: > "$MOCK_DOWNLOAD_LOG"
_tnx_download_archive https://example.invalid/source.tar.gz "$TMP/from-wget"
cmp -s "$TMP/payload" "$TMP/from-wget"
grep -Fxq 'curl:--version' "$MOCK_DOWNLOAD_LOG"
grep -Fxq 'wget:--version' "$MOCK_DOWNLOAD_LOG"
grep -Fxq 'wget:-q' "$MOCK_DOWNLOAD_LOG"
! grep -Fq 'curl:-fL' "$MOCK_DOWNLOAD_LOG"
printf 'PASS: broken curl is skipped and working wget downloads the source archive\n'

MOCK_CURL_MODE=healthy MOCK_WGET_MODE=healthy
export MOCK_CURL_MODE MOCK_WGET_MODE
: > "$MOCK_DOWNLOAD_LOG"
_tnx_download_archive https://example.invalid/source.tar.gz "$TMP/from-curl"
cmp -s "$TMP/payload" "$TMP/from-curl"
grep -Fxq 'curl:--version' "$MOCK_DOWNLOAD_LOG"
grep -Fxq 'curl:-fL' "$MOCK_DOWNLOAD_LOG"
! grep -Fq 'wget:' "$MOCK_DOWNLOAD_LOG"
printf 'PASS: working curl remains the preferred downloader\n'

MOCK_CURL_MODE=download-fails MOCK_WGET_MODE=healthy
export MOCK_CURL_MODE MOCK_WGET_MODE
: > "$MOCK_DOWNLOAD_LOG"
_tnx_download_archive https://example.invalid/source.tar.gz "$TMP/network-fallback"
cmp -s "$TMP/payload" "$TMP/network-fallback"
grep -Fxq 'wget:-q' "$MOCK_DOWNLOAD_LOG"
printf 'PASS: wget is tried when a working curl cannot fetch the archive\n'

MOCK_CURL_MODE=broken MOCK_WGET_MODE=broken
export MOCK_CURL_MODE MOCK_WGET_MODE
: > "$MOCK_DOWNLOAD_LOG"
if _tnx_download_archive https://example.invalid/source.tar.gz "$TMP/unavailable"; then
  echo 'FAIL: unavailable download tools were accepted' >&2
  exit 1
fi
[ ! -e "$TMP/unavailable" ]
printf 'PASS: unavailable download tools fail without leaving a partial archive\n'
