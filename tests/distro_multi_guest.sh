#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home" TERNUX_STATE_DIR="$TMP/state" PREFIX="$TMP/prefix" NO_COLOR=1 TERM=dumb
mkdir -p "$HOME" "$TERNUX_STATE_DIR" "$PREFIX"
. "$ROOT/lib/core.sh"
. "$ROOT/lib/phases.sh"
. "$ROOT/lib/desktop.sh"
. "$ROOT/lib/distro.sh"

[ "$(tnx_distro_state_dir debian)" = "$TERNUX_STATE_DIR/distros/debian" ]
! tnx_distro_state_dir '../escape' >/dev/null 2>&1
tnx_distro_state_set debian backend zink
tnx_distro_state_set ubuntu backend virgl
[ "$(tnx_distro_state_get debian backend)" = zink ]
[ "$(tnx_distro_state_get ubuntu backend)" = virgl ]
[ "$(tnx_distro_state_get debian backend)" != "$(tnx_distro_state_get ubuntu backend)" ]
# On Adreno, prefer distro-native Zink/Freedreno for profiles with package
# support; Adélie currently falls back to the shared VirGL/virpipe route.
TERNUX_KGSL_DEVICE="$TMP/kgsl-present"
: > "$TERNUX_KGSL_DEVICE"
[ "$(tnx_gpu_backend_auto debian)" = zink ]
for distro in $TERNUX_DISTRO_KNOWN; do
  if [ "$distro" = adelie ]; then
    [ "$(tnx_gpu_backend_auto "$distro")" = virgl ]
  else
    [ "$(tnx_gpu_backend_auto "$distro")" = zink ]
  fi
done
[ "$(tnx_gpu_backend_auto ubuntu)" = zink ]
[ "$(tnx_gpu_backend_auto alpine)" = zink ]
# All profiles emit Zink for Adreno/KGSL, with distro-native driver packages
# installed by their family recipe; VirGL remains the explicit compatibility route.
for distro in $TERNUX_DISTRO_KNOWN; do
  unset _TNX_DISTRO
  export TERNUX_DISTRO="$distro"
  tnx_phase_launcher ternux auto en_US.UTF-8 >/dev/null
  launcher="$TERNUX_STATE_DIR/distros/$distro/launcher.sh"
  if [ "$distro" != adelie ]; then
    grep -q -- '--env MESA_LOADER_DRIVER_OVERRIDE=zink' "$launcher"
  else
    grep -q -- '--env GALLIUM_DRIVER=virpipe' "$launcher"
    grep -q 'virgl_test_server_android' "$launcher"
  fi
done
rm -f "$TERNUX_KGSL_DEVICE"
[ "$(tnx_gpu_backend_auto debian)" = virgl ]

tnx_distro_profile ubuntu
[ "$TNX_DP_FAMILY" = apt ] && [ "$TNX_DP_EXTRA_HOLD" = snapd ]

tnx_install_single() { printf '%s\n' "$*" >> "$TMP/install-calls"; }
proot-distro() {
  case "$*" in
    'list --quiet')
      printf 'debian\nubuntu\n'
      [ ! -e "$TMP/alpine-image-installed" ] || printf 'alpine\n'
      ;;
    'install --name alpine alpine:latest')
      : > "$TMP/alpine-image-installed"
      printf '%s\n' "$*" >> "$TMP/proot-calls"
      ;;
    *) printf '%s\n' "$*" >> "$TMP/proot-calls" ;;
  esac
}
tnx_install --distros debian,ubuntu --yes
[ "$(wc -l < "$TMP/install-calls")" -eq 2 ]
grep -qx -- '--yes --distro debian' "$TMP/install-calls"
grep -qx -- '--yes --distro ubuntu' "$TMP/install-calls"
if tnx_install --distros debian,arch >/dev/null 2>&1; then exit 1; fi
if tnx_install --distros debian,debian >/dev/null 2>&1; then exit 1; fi

# Legacy/global phase markers from a completed Debian install must not make an
# interrupted Ubuntu install look complete when it is resumed.
if (
  . "$ROOT/lib/phases.sh"
  export TERNUX_STATE_DIR="$TMP/resume-state" TERNUX_UI=off
  mkdir -p "$TERNUX_STATE_DIR"
  tnx_state_set user ternux
  tnx_state_set locale en_US.UTF-8
  tnx_state_set install_backend auto
  tnx_state_set install_shell bash
  tnx_state_set distro ubuntu
  tnx_distro_state_set debian status ready
  tnx_distro_state_set ubuntu status incomplete
  for phase in preflight packages cli; do tnx_state_mark "phase_$phase"; done
  for phase in debian gpu audio_fonts launcher aliases extras phantom verify; do
    tnx_state_mark "phase_$phase"
    tnx_distro_phase_mark debian "$phase"
  done
  order="$TMP/ubuntu-resume-order"
  tnx_require_termux(){ :; }; tnx_confirm(){ :; }; tnx_banner(){ :; }
  tnx_phase_header(){ :; }; tnx_celebrate(){ :; }; tnx_summary_box(){ :; }
  tnx_next_steps(){ :; }; tnx_log_error(){ :; }
  for phase in preflight packages cli debian gpu audio_fonts launcher aliases extras phantom verify; do
    eval "tnx_phase_${phase}(){ printf '%s\\n' '${phase}' >> '$order'; }"
  done
  tnx_install --distro ubuntu --resume --yes >/dev/null 2>&1 || exit 1
  [ "$(tr '\n' ' ' < "$order")" = 'debian gpu audio_fonts launcher aliases phantom verify ' ] || exit 1
  [ "$(tnx_distro_state_get ubuntu status)" = ready ] || exit 1
  tnx_state_done phase_debian && tnx_distro_phase_done debian debian && tnx_distro_phase_done ubuntu debian
); then
  echo 'PASS: resuming one guest does not skip its phases because another guest completed them'
else
  echo 'FAIL: guest-scoped install resume phases' >&2
  exit 1
fi


# Guest shell/exec routes through the selected distro and keeps the established
# isolated-login plus scoped storage behavior.
tnx_proot_container_installed() {
  case "$1" in
    debian|ubuntu) return 0 ;;
    alpine) [ -e "$TMP/alpine-image-installed" ] ;;
    *) return 1 ;;
  esac
}
tnx_guest_login() { printf '%s|%s\n' "$TERNUX_DISTRO" "$*" >> "$TMP/login-calls"; }
tnx_distro_state_set ubuntu user ubuntu-user
mkdir -p "$TERNUX_STATE_DIR/distros/alpine"
printf 'user=ternux\n' > "$TERNUX_STATE_DIR/distros/alpine/profile"
tnx_cmd_distro shell ubuntu
[ "$(cat "$TMP/login-calls")" = 'ubuntu|--user ubuntu-user' ]
tnx_cmd_distro exec debian -- printf '%s' ok
[ "$(tail -n 1 "$TMP/login-calls")" = 'debian|-- printf %s ok' ]
tnx_cmd_distro image-install alpine:latest alpine
[ "$(cat "$TMP/proot-calls")" = 'install --name alpine alpine:latest' ]
tnx_cmd_distro shell alpine
[ "$(tail -n 1 "$TMP/login-calls")" = 'alpine|--user ternux' ]
tnx_cmd_distro search 'debian bookworm'
[ "$(tail -n 1 "$TMP/proot-calls")" = 'search debian bookworm' ]
if tnx_cmd_distro search >/dev/null 2>&1; then exit 1; fi
if tnx_cmd_distro search one two >/dev/null 2>&1; then exit 1; fi
tnx_cmd_distro list > "$TMP/distro-list"
grep -q 'alpine.*Ternux recipe available' "$TMP/distro-list"
grep -q 'debian.*Ternux recipe available' "$TMP/distro-list"

# A live Debian display must not be reported as an Ubuntu session.
tnx_desktop_session_live() { [ "$(tnx_distro)" = debian ]; }
tnx_pulseaudio_ready() { return 1; }
mkdir -p "$TERNUX_STATE_DIR/session"
printf 'debian\n' > "$TERNUX_STATE_DIR/session/distro"
printf 'READY\n' > "$TERNUX_STATE_DIR/session/desktop.state"
TERNUX_JSON=1 tnx_cmd_status ubuntu > "$TMP/status.json"
grep -q '"status":"stopped"' "$TMP/status.json"


# Generated shortcuts route to per-distro user/root contexts, and xgo prompts
# across every installed guest while clearly identifying shell-only images.
tnx_distro_state_set ubuntu status ready
mkdir -p "$HOME/.local/share/ternux/distros/ubuntu"
printf 'status=ready\n' > "$HOME/.local/share/ternux/distros/ubuntu/profile"
TERNUX_DISTRO=ubuntu tnx_phase_aliases alice bash >/dev/null
bash -n "$HOME/.bashrc"
grep -q "alias tx='ternux'" "$HOME/.bashrc"
grep -q 'db() { _ternux_guest_login debian --shared-tmp --user' "$HOME/.bashrc"
grep -q 'dbroot() { _ternux_guest_login debian --shared-tmp' "$HOME/.bashrc"
grep -q 'dbr() { dbroot "\$@"; }' "$HOME/.bashrc"
grep -q 'ub() { _ternux_guest_login ubuntu --shared-tmp --user' "$HOME/.bashrc"
grep -q 'ubroot() { _ternux_guest_login ubuntu --shared-tmp' "$HOME/.bashrc"
grep -q 'ubr() { ubroot "\$@"; }' "$HOME/.bashrc"
grep -q 'alp() { _ternux_guest_login alpine --shared-tmp --user' "$HOME/.bashrc"
grep -q 'alproot() { _ternux_guest_login alpine --shared-tmp' "$HOME/.bashrc"
grep -q 'alpr() { alproot "\$@"; }' "$HOME/.bashrc"
grep -q 'archx() { _ternux_guest_login archlinux --shared-tmp --user' "$HOME/.bashrc"
grep -q 'fed() { _ternux_guest_login fedora --shared-tmp --user' "$HOME/.bashrc"
grep -q 'suse() { _ternux_guest_login opensuse --shared-tmp --user' "$HOME/.bashrc"
grep -q 'vsh() { _ternux_guest_login void --shared-tmp --user' "$HOME/.bashrc"
grep -q 'kal() { _ternux_guest_login kali --shared-tmp --user' "$HOME/.bashrc"
if command -v script >/dev/null 2>&1; then
  printf 'jj \r' | script -qec "stty rows 30 cols 80; TERM=xterm-256color bash -c 'source '$ROOT'/lib/phases.sh; tnx_prompt_distro debian 20'" /dev/null > "$TMP/distro-multi-prompt"
  grep -q 'SPACE/number toggle' "$TMP/distro-multi-prompt"
  grep -q 'debian,alpine' "$TMP/distro-multi-prompt"
  printf '3\r' | script -qec "stty rows 30 cols 80; TERM=xterm-256color bash -c 'source '$ROOT'/lib/phases.sh; tnx_prompt_distro debian 20'" /dev/null > "$TMP/distro-number-toggle"
  grep -q 'debian,alpine' "$TMP/distro-number-toggle"
  printf '10\r' | script -qec "stty rows 30 cols 80; TERM=xterm-256color bash -c 'source '$ROOT'/lib/phases.sh; tnx_prompt_distro debian 20'" /dev/null > "$TMP/distro-number-multidigit"
  grep -q 'debian,chimera' "$TMP/distro-number-multidigit"
  printf 'jjjjjjjjj \r' | script -qec "stty rows 16 cols 32; TERM=xterm-256color bash -c 'source '$ROOT'/lib/phases.sh; tnx_prompt_distro debian 20'" /dev/null > "$TMP/distro-compact-menu"
  grep -q 'Selected: debian, chimera' "$TMP/distro-compact-menu"
  grep -q 'J/K move | Space toggle' "$TMP/distro-compact-menu"
  printf 'q' | script -qec "stty rows 30 cols 80; TERM=xterm-256color bash -c 'source '$ROOT'/lib/phases.sh; tnx_prompt_distro debian 20'" /dev/null > "$TMP/distro-menu-default"
  grep -q 'debian' "$TMP/distro-menu-default"
  printf '1,3\n' | script -qec "stty rows 10 cols 24; TERM=xterm-256color bash -c 'source '$ROOT'/lib/phases.sh; tnx_prompt_distro debian 20'" /dev/null > "$TMP/distro-small-terminal"
  grep -q 'debian,alpine' "$TMP/distro-small-terminal"
fi
cat > "$TMP/check-xgo.sh" <<'EOF'
proot-distro() { printf 'alpine\ndebian\nubuntu\n'; }
ternux() { printf 'START:%s\n' "$*"; }
. "$HOME/.bashrc"
xgo
EOF
printf '3\n' | bash --noprofile --norc "$TMP/check-xgo.sh" > "$TMP/xgo-output"
grep -q 'recipe available; not configured' "$TMP/xgo-output"
grep -q 'START:start ubuntu' "$TMP/xgo-output"

# Stopping Ubuntu must not touch Debian's independently stored session.
mkdir -p "$TERNUX_STATE_DIR/session"
printf 'debian\n' > "$TERNUX_STATE_DIR/session/distro"
tnx_cmd_stop ubuntu >/dev/null 2>&1
[ "$(cat "$TERNUX_STATE_DIR/session/distro")" = debian ]

# With both tagged guest displays ready, stop accepts multiple selections.
export TMPDIR="$TMP/tmp"
mkdir -p "$TMPDIR/.X11-unix"
python3 - "$TMPDIR/.X11-unix" <<'PY_SOCKETS'
import socket,sys
for n in ('0','1'):
 s=socket.socket(socket.AF_UNIX); s.bind(sys.argv[1]+'/X'+n); s.close()
PY_SOCKETS
sleep 30 & debian_pid=$!
sleep 30 & ubuntu_pid=$!
for distro in debian ubuntu; do
  session="$(tnx_distro_session_dir "$distro")"
  mkdir -p "$session"
  printf 'READY\n' > "$session/desktop.state"
  printf 'READY\n' > "$session/desktop.pid.ready"
  printf '%s\n' "$distro" > "$session/distro"
  if [ "$distro" = debian ]; then pid="$debian_pid"; else pid="$ubuntu_pid"; fi
  printf '%s\n' "$pid" > "$session/desktop.pid"
  printf '%s %s %s\n' "$pid" "$(tnx_process_start_identity "$pid")" "$pid" > "$session/desktop.pid.identity"
done
stop_calls="$TMP/stop-calls"
tnx_cmd_stop() { printf '%s\n' "$1" >> "$stop_calls"; }
printf '2\n' | _tnx_stop_select > "$TMP/stop-single-picker"
[ "$(cat "$stop_calls")" = ubuntu ]
: > "$stop_calls"
printf '1,2\n' | _tnx_stop_select > "$TMP/stop-picker"
[ "$(cat "$stop_calls")" = $'debian\nubuntu' ]
grep -q 'Display :0' "$TMP/stop-picker"
grep -q 'Display :1' "$TMP/stop-picker"
printf 'all\n' | _tnx_stop_select > "$TMP/stop-all-picker"
[ "$(wc -l < "$stop_calls")" -eq 4 ]
kill "$debian_pid" "$ubuntu_pid" 2>/dev/null || true
wait "$debian_pid" "$ubuntu_pid" 2>/dev/null || true
echo 'PASS: guest profiles, multi-install, shell shortcuts, xgo picker, multi-display stop picker, and lifecycle guards'
