#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home" TERNUX_STATE_DIR="$TMP/state"
mkdir -p "$HOME"
. "$ROOT/lib/distro.sh"
tnx_proot_container_installed() { return 0; }
tnx_distro_state_get() { [ "$1" = alpine ] && [ "$2" = user ] && printf 'ternux\n'; }
tnx_guest_login() { printf 'LOGIN'; printf ' <%s>' "$@"; printf '\n'; }
tnx_fail() { printf 'FAIL:%s\n' "$1" >&2; }

user_result="$(tnx_cmd_distro shell alpine -- id)"
[ "$user_result" = 'LOGIN <--user> <ternux> <--> <id>' ]
root_result="$(tnx_cmd_distro root alpine -- id)"
[ "$root_result" = 'LOGIN <--> <id>' ]
interactive_user="$(tnx_cmd_distro shell alpine)"
[ "$interactive_user" = 'LOGIN <--user> <ternux>' ]
interactive_root="$(tnx_cmd_distro root alpine)"
[ "$interactive_root" = 'LOGIN <>' ]
echo "PASS: user and root guest shell commands preserve identity and -- command boundaries"
