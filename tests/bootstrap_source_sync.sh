#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

bootstrap_commit="$(sed -n 's/^_TNX_BOOTSTRAP_COMMIT="\([0-9a-f]*\)"$/\1/p' "$ROOT/install.sh")"
bootstrap_sha="$(sed -n 's/^_TNX_BOOTSTRAP_SHA256="\([0-9a-f]*\)"$/\1/p' "$ROOT/install.sh")"
cli_commit="$(sed -n 's/^TERNUX_SOURCE_COMMIT="\([0-9a-f]*\)"$/\1/p' "$ROOT/lib/core.sh")"
cli_sha="$(sed -n 's/^TERNUX_SOURCE_SHA256="\([0-9a-f]*\)"$/\1/p' "$ROOT/lib/core.sh")"

[[ "$bootstrap_commit" == "$cli_commit" && "$bootstrap_sha" == "$cli_sha" ]] || {
  echo "FAIL: standalone and CLI source pins differ" >&2
  exit 1
}

archive="$TMP/source.tar.gz"
curl -fsSL --retry 2 --connect-timeout 15 \
  "https://codeload.github.com/soobujmiah/ternux/tar.gz/$bootstrap_commit" \
  -o "$archive"
printf '%s  %s\n' "$bootstrap_sha" "$archive" | sha256sum --check --status || {
  echo "FAIL: pinned source archive does not match its SHA-256" >&2
  exit 1
}

tar -xzf "$archive" -C "$TMP"
root_name="$(tar -tzf "$archive" | sed -n '1{s#/.*##;p;}')"
[[ -n "$root_name" && -f "$TMP/$root_name/install.sh" ]] || {
  echo "FAIL: pinned source archive has no installer root" >&2
  exit 1
}
mkdir -p "$TMP/current" "$TMP/pinned"
cp -a "$ROOT/install.sh" "$ROOT/bin" "$ROOT/lib" "$TMP/current/"
cp -a "$TMP/$root_name/install.sh" "$TMP/$root_name/bin" "$TMP/$root_name/lib" "$TMP/pinned/"

# The snapshot is the preceding immutable commit because a commit cannot embed
# its own SHA-256. Normalize only the four pin values; installed code must match.
for tree in "$TMP/current" "$TMP/pinned"; do
  sed -E -i \
    's/^(_TNX_BOOTSTRAP_COMMIT|_TNX_BOOTSTRAP_SHA256|TERNUX_SOURCE_COMMIT|TERNUX_SOURCE_SHA256)=.*/\1=<PIN>/' \
    "$tree/install.sh" "$tree/lib/core.sh"
done
if ! diff -ru "$TMP/current" "$TMP/pinned"; then
  echo "FAIL: pinned archive is stale relative to installer/CLI source" >&2
  exit 1
fi

echo "PASS: standalone and CLI share a verified source snapshot matching current code"
