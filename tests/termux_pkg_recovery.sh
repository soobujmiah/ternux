#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$BASH_SOURCE")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home" PREFIX="$TMP/prefix" TERNUX_STATE_DIR="$TMP/state" NO_COLOR=1 TERM=dumb
mkdir -p "$HOME" "$PREFIX" "$TERNUX_STATE_DIR"
. "$ROOT/lib/phases.sh"

mode=pkg-failure
smoke_count=0
LOG="$TMP/commands"
: > "$LOG"

tnx_spin_run() {
  local label="$1"; shift
  [ "$label" != "Install the Termux:X11 client" ] || { printf 'x11-client\n' >> "$LOG"; return 0; }
  "$@"
}
tnx_termux_pkg() {
  printf 'pkg:%s\n' "$*" >> "$LOG"
  case "$mode:$1" in
    pkg-failure:update|pkg-failure:upgrade) return 1 ;;
    *) return 0 ;;
  esac
}
tnx_termux_apt_get() {
  printf 'apt:%s\n' "$*" >> "$LOG"
  return 0
}
tnx_has_cmd() { return 0; }
_tnx_host_download_tools_smoke() {
  smoke_count=$((smoke_count + 1))
  printf 'smoke:%s\n' "$smoke_count" >> "$LOG"
  if [ "$mode" = smoke-failure ] && [ "$smoke_count" -eq 1 ]; then return 1; fi
  return 0
}
proot-distro() { return 0; }
termux-x11() { return 0; }
pulseaudio() { return 0; }
setsid() { return 0; }

tnx_phase_packages auto
grep -q '^pkg:update ' "$LOG"
grep -q '^apt:update ' "$LOG"
grep -q '^pkg:upgrade ' "$LOG"
grep -q '^apt:full-upgrade ' "$LOG"
grep -q '^smoke:1$' "$LOG"

mode=smoke-failure
smoke_count=0
: > "$LOG"
tnx_termux_pkg() { printf 'pkg:%s\n' "$*" >> "$LOG"; return 0; }
tnx_phase_packages auto
grep -q '^apt:update ' "$LOG"
grep -q '^apt:full-upgrade ' "$LOG"
grep -q '^smoke:2$' "$LOG"
echo 'PASS: Termux package failures and broken download-tool linkage recover through apt-get full-upgrade'

# A user with an already-installed Ternux host CLI must be able to repair the
# exact curl/OpenSSL mismatch without first relying on the broken curl binary.
. "$ROOT/lib/repair.sh"
repair_curl=broken
: > "$LOG"
tnx_has_cmd() { [ "$1" = curl ]; }
curl() { [ "$repair_curl" = working ]; }
tnx_termux_apt_get() {
  printf 'repair-apt:%s\n' "$*" >> "$LOG"
  case "$*" in
    *full-upgrade*) repair_curl=working ;;
  esac
  return 0
}
tnx_ok() { :; }
tnx_warn() { :; }
tnx_fail() { printf '%s\n' "$*" >> "$LOG"; }
_TNX_REPAIR_CHANGED=0
_tnx_repair_curl
test "$_TNX_REPAIR_CHANGED" = 1
grep -q '^repair-apt:update -y -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef$' "$LOG"
grep -q '^repair-apt:full-upgrade -y -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef$' "$LOG"
! grep -q '^pkg:' "$LOG"
printf 'PASS: curl repair recovers a broken Termux host from apt-get without invoking broken pkg/curl paths\n'
