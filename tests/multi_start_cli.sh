#!/usr/bin/env bash
set -u
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export TERNUX_STATE_DIR="$TMP/state" HOME="$TMP/home" START_CALLS="$TMP/calls"
mkdir -p "$HOME" "$TERNUX_STATE_DIR"
. "$ROOT/lib/desktop.sh"
tnx_proot_container_installed(){ return 0; }
tnx_cmd_start_impl(){ printf '%s\n' "$1" >> "$START_CALLS"; [ "$1" != ubuntu ]; }

rc=0
tnx_cmd_start debian ub alp || rc=$?
[ "$rc" -eq 1 ]
[ "$(tr '\n' ' ' < "$START_CALLS")" = 'debian ubuntu alpine ' ]
: > "$START_CALLS"
TERNUX_JSON=1
output="$(tnx_cmd_start db ub alp)"; rc=$?
[ "$rc" -eq 1 ]
grep -Fq '"status":"partial_failure"' <<<"$output"
grep -Fq '"guests":["debian","ubuntu","alpine"]' <<<"$output"
grep -Fq '"results":["debian:started","ubuntu:failed (exit 1)","alpine:started"]' <<<"$output"
echo 'multi-guest start checks passed'
