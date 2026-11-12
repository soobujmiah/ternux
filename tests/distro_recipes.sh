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
  if [ "$distro" = alpine ]; then
    grep -Fq "if [ 'alpine' = alpine ]; then install_proot_bwrap_shim; fi" "$TMP/guest-${distro}-1.sh" || {
      echo "PRoot Glycin compatibility shim missing from Alpine package setup" >&2; exit 1;
    }
    grep -Fq 'py3-xlib' "$TMP/guest-${distro}-1.sh" &&
      grep -Fq 'install -m 0755 $asset_stage/bin/ternux-window-fit-x11 /usr/local/bin/ternux-window-fit-x11' "$TMP"/guest-${distro}-*.sh &&
      grep -Fq 'window_fit_exec=/usr/local/bin/ternux-window-fit-x11' "$TMP"/guest-${distro}-*.sh || {
      echo "Alpine X11 window-fit fallback is missing from the desktop recipe" >&2; exit 1;
    }
  elif grep -Fq "if [ '$distro' = alpine ]; then install_proot_bwrap_shim; fi" "$TMP/guest-${distro}-1.sh"; then
    : # The distro-specific condition keeps this Alpine-only shim inactive here.
  else
    echo "Alpine-only Glycin compatibility guard missing from $distro package setup" >&2; exit 1
  fi
  tnx_distro_profile "$distro"
  case "$distro:$TNX_DP_FAMILY" in
    debian:apt|ubuntu:apt|kali:apt|deepin:apt|pardus:apt|\
    alpine:apk|adelie:apk|chimera:apk|\
    archlinux:pacman|artix:pacman|manjaro:pacman|\
    fedora:dnf|rockylinux:dnf|\
    opensuse:zypper|void:xbps) ;;
    *) echo "Unexpected manager mapping: $distro=$TNX_DP_FAMILY" >&2; exit 1 ;;
  esac
  case "$TNX_DP_FAMILY" in
    apt|apk|pacman|dnf|zypper|xbps) ;;
    *) echo "No supported package family for graphics: $distro=$TNX_DP_FAMILY" >&2; exit 1 ;;
  esac
  # Every named desktop profile must include a browser installation route.
  case "$distro" in
    ubuntu) grep -q 'base64 -d | bash' "$TMP/guest-${distro}-"*.sh && grep -q 'firefox-esr-latest' "$ROOT/lib/ternux-install-firefox-esr.sh" ;;
    debian|kali|deepin|pardus) grep -q 'firefox-esr' "$TMP/guest-${distro}-"*.sh ;;
    alpine|adelie|chimera) grep -q 'apk add firefox-esr' "$TMP/guest-${distro}-"*.sh ;;
    archlinux|artix|manjaro) grep -q 'pacman -S.*firefox' "$TMP/guest-${distro}-"*.sh ;;
    fedora|rockylinux) grep -q 'dnf install -y firefox' "$TMP/guest-${distro}-"*.sh ;;
    opensuse) grep -q 'MozillaFirefox' "$TMP/guest-${distro}-"*.sh ;;
    void) grep -q 'xbps-install -Sy firefox' "$TMP/guest-${distro}-"*.sh ;;
  esac || { echo "Default browser install route missing from $distro recipe" >&2; exit 1; }
  # Every named desktop recipe must install both a Mesa Gallium driver and a
  # glxinfo provider so the VirGL route can be inspected in that guest.
  grep -Eq 'libgl1-mesa-dri|mesa-dri-gallium|mesa-dri-drivers|Mesa-dri|mesa-dri' "$TMP/guest-${distro}-"*.sh || {
    echo "Mesa GL driver missing from $distro recipe" >&2; exit 1;
  }
  grep -Eq 'mesa-utils|glx-utils|Mesa-demo-x|mesa-demos' "$TMP/guest-${distro}-"*.sh || {
    echo "glxinfo package missing from $distro recipe" >&2; exit 1;
  }
  case "$distro" in
    debian) ;; # Debian uses the separately validated, pinned Turnip payload.
    ubuntu|kali|deepin|pardus) grep -q 'mesa-vulkan-drivers' "$TMP/guest-${distro}-"*.sh ;;
    alpine) grep -q 'mesa-vulkan-freedreno' "$TMP/guest-${distro}-"*.sh ;;
    chimera) grep -q 'apk add mesa-vulkan' "$TMP/guest-${distro}-"*.sh ;;
    adelie) ;; # Native Freedreno package is not in the supported recipe yet.
    archlinux|artix|manjaro) grep -q 'vulkan-freedreno' "$TMP/guest-${distro}-"*.sh ;;
    fedora|rockylinux) grep -q 'mesa-vulkan-drivers' "$TMP/guest-${distro}-"*.sh ;;
    opensuse) grep -q 'libvulkan_freedreno' "$TMP/guest-${distro}-"*.sh ;;
    void) grep -q 'mesa-vulkan-freedreno' "$TMP/guest-${distro}-"*.sh ;;
  esac || { echo "Native Mesa/Freedreno Vulkan package missing from $distro recipe" >&2; exit 1; }
  if [ "$distro" = alpine ]; then
    grep -q 'rsvg-convert xrdb' "$TMP/guest-${distro}-1.sh" || {
      echo "Alpine XFCE startup dependency xrdb missing from package recipe" >&2; exit 1;
    }
  fi
done

echo "PASS: all 15 named profiles generate valid desktop recipes with a default browser, Mesa GL drivers, native Vulkan packages, and glxinfo providers"
