#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home" TERNUX_STATE_DIR="$TMP/state" PREFIX="$TMP/prefix" TERNUX_LOG_DIR="$TMP/log"
mkdir -p "$HOME" "$TERNUX_STATE_DIR" "$PREFIX/bin"
. "$ROOT/lib/phases.sh"

tnx_debian_installed() { return 0; }
tnx_install_guest_cli() { return 0; }
tnx_request_microphone_permission() { return 0; }
_tnx_configure_pulse_bridge() { _TNX_PULSE_CHANGED=0; return 0; }

script_num=0
tnx_guest_login() {
  local arg distro="${_TNX_DISTRO:-$TERNUX_DISTRO}"
  for arg in "$@"; do
    if [ "$arg" = -c ]; then
      script_num=$((script_num + 1))
      printf '%s\n' "${@: -1}" > "$TMP/guest-${distro}-${script_num}.sh"
      break
    fi
  done
  return 0
}

profiles="debian ubuntu alpine archlinux fedora opensuse void kali artix chimera deepin manjaro pardus rockylinux adelie"
for distro in $profiles; do
  unset _TNX_DISTRO
  export TERNUX_DISTRO="$distro"
  script_num=0
  tnx_phase_debian ternux >/dev/null
  tnx_phase_audio_fonts ternux en_US.UTF-8 >/dev/null
  [ "$script_num" -eq 3 ] || { echo "Expected three guest scripts for $distro, found $script_num" >&2; exit 1; }
  for generated in "$TMP/guest-${distro}-"*.sh; do bash -n "$generated"; done
  tnx_distro_profile "$distro"
  case "$distro:$TNX_DP_FAMILY" in
    debian:apt|ubuntu:apt|kali:apt|deepin:apt|pardus:apt|\
    alpine:apk|adelie:apk|chimera:apk|\
    archlinux:pacman|artix:pacman|manjaro:pacman|\
    fedora:dnf|rockylinux:dnf|\
    opensuse:zypper|void:xbps) ;;
    *) echo "Unexpected manager mapping: $distro=$TNX_DP_FAMILY" >&2; exit 1 ;;
  esac
done

echo "PASS: generated desktop, account, locale and font scripts parse for all 15 named profiles"
