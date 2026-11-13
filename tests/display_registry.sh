#!/usr/bin/env bash
# Validate v3 display identity defaults without changing device display state.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

env TERNUX_STATE_DIR="$TMP/state" HOME="$TMP/home" bash -c '
  . "$1/lib/core.sh"
  [ "$TERNUX_NATIVE_DISPLAY" = 0 ] || exit 1

  expected="debian:1 ubuntu:2 alpine:3 archlinux:4 fedora:5 opensuse:6 void:7 kali:8 artix:9 chimera:10 deepin:11 manjaro:12 pardus:13 rockylinux:14 adelie:15"
  seen=" "
  for item in $expected; do
    name="${item%:*}"; display="${item#*:}"
    [ "$(tnx_distro_target_display "$name")" = "$display" ] || exit 1
    [ "$(tnx_distro_display "$name")" = "$display" ] || exit 1
    case "$seen" in *" $display "*) exit 1;; esac
    seen+="$display "
  done

  # Installed v2 guests keep their persisted display identities until an
  # explicit migration; the v3 target remains visible separately.
  tnx_distro_state_set debian display 0 || exit
  tnx_distro_state_set ubuntu display 1 || exit
  tnx_distro_state_set alpine display 2 || exit
  [ "$(tnx_distro_display debian)" = 0 ] || exit
  [ "$(tnx_distro_display ubuntu)" = 1 ] || exit
  [ "$(tnx_distro_display alpine)" = 2 ] || exit
  [ "$(tnx_distro_target_display debian)" = 1 ] || exit
  [ "$(tnx_distro_target_display ubuntu)" = 2 ] || exit
  [ "$(tnx_distro_target_display alpine)" = 3 ] || exit
' _ "$ROOT"

env TERNUX_STATE_DIR="$TMP/state-collision" HOME="$TMP/home-collision" bash -c '
  . "$1/lib/desktop.sh"
  pgrep() {
    [ "${1:-}" = -f ] || return 1
    case "${2:-}" in *" :7("*) return 0;; *) return 1;; esac
  }
  tnx_x11_server_running_on_display 7 || exit 1
  if tnx_x11_server_running_on_display 8; then exit 1; fi
  if tnx_x11_server_running_on_display 100; then exit 1; fi
' _ "$ROOT"

for collision_kind in foreign-path server-only; do
  env TERNUX_STATE_DIR="$TMP/state-start-$collision_kind" HOME="$TMP/home-start-$collision_kind" \
    TMPDIR="$TMP/tmp-start-$collision_kind" COLLISION_KIND="$collision_kind" bash -c '
      mkdir -p "$TERNUX_STATE_DIR/distros/debian" "$TMPDIR/.X11-unix" "$HOME"
      printf "#!/usr/bin/env bash\n# TERNUX_DESKTOP_LAUNCHER=21\n" > "$TERNUX_STATE_DIR/distros/debian/launcher.sh"
      chmod 0755 "$TERNUX_STATE_DIR/distros/debian/launcher.sh"
      if [ "$COLLISION_KIND" = foreign-path ]; then
        printf "owned by another application\n" > "$TMPDIR/.X11-unix/X1"
        pgrep(){ return 1; }
      else
        pgrep(){ [[ "$*" == *" :1("* ]] && return 0; return 1; }
      fi
      . "$1/lib/desktop.sh"
      tnx_has_cmd(){ [ "$1" = flock ]; }
      tnx_proot_container_installed(){ return 0; }
      TERNUX_JSON=1
      if tnx_cmd_start >/dev/null 2>&1; then exit 1; fi
      [ ! -e "$TERNUX_STATE_DIR/session/desktop.pid" ] || exit 1
      if [ "$COLLISION_KIND" = foreign-path ]; then
        grep -q "owned by another application" "$TMPDIR/.X11-unix/X1" || exit 1
      fi
    ' _ "$ROOT" || exit 1
done

printf '%s\n' 'display identity and v2 preservation checks passed'
