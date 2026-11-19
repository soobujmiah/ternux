#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home" TERNUX_STATE_DIR="$TMP/state" PREFIX="$TMP/prefix" NO_COLOR=1 TERM=dumb
export TERNUX_USER_PASSWORD=test-sudo TERNUX_STARTUP_PASSWORD=test-startup
mkdir -p "$HOME" "$TERNUX_STATE_DIR" "$PREFIX"
. "$ROOT/lib/core.sh"
. "$ROOT/lib/phases.sh"
. "$ROOT/lib/desktop.sh"
. "$ROOT/lib/distro.sh"

[ -x "$ROOT/bin/ternux" ]
[ "$(tnx_distro_state_dir debian)" = "$TERNUX_STATE_DIR/distros/debian" ]
! tnx_distro_state_dir '../escape' >/dev/null 2>&1
tnx_distro_state_set debian backend zink
tnx_distro_state_set ubuntu backend virgl
tnx_state_set user ternux
tnx_distro_state_set ubuntu user sobuj_dev2
[ "$(tnx_distro_state_get debian backend)" = zink ]
[ "$(tnx_distro_state_get ubuntu backend)" = virgl ]
[ "$(tnx_distro_user ubuntu)" = sobuj_dev2 ]
[ "$(tnx_distro_user debian)" = ternux ]
[ "$(tnx_distro_state_get debian backend)" != "$(tnx_distro_state_get ubuntu backend)" ]

(
  export TERNUX_STATE_DIR="$TMP/root-password-resume-state"
  mkdir -p "$TERNUX_STATE_DIR"
  tnx_proot_container_installed() { return 0; }
  tnx_distro_phase_mark debian root_password
  ! tnx_install_phase_done root_password debian
  tnx_distro_phase_mark debian user_password
  tnx_install_phase_done root_password debian
)

# Changing the selected guest password keeps the root account in sync without
# placing the secret in argv, the environment, or command output.
(
  . "$ROOT/lib/password.sh"
  tnx_state_get() { case "$1" in distro) printf debian ;; user) printf sbj ;; esac; }
  _tnx_password_read_new() { TNX_NEW_PASSWORD=password-change-secret; }
  tnx_guest_login() { [ "$1" = --user ] && [ "$2" = root ] && [ "$3" = -- ] && [ "$4" = chpasswd ] || return 90; cat > "$TMP/password-change-input"; }
  result="$(tnx_cmd_password sudo 2>&1)"
  [ "$(cat "$TMP/password-change-input")" = "sbj:password-change-secret
root:password-change-secret" ]
  ! printf '%s' "$result" | grep -q password-change-secret
)
echo 'PASS: a pending sudo-password phase forces root password synchronization on resume'

# On Adreno, prefer Zink only for profiles with pinned compatible Mesa assets;
# the remaining profiles use the VirGL/virpipe route.
TERNUX_KGSL_DEVICE="$TMP/kgsl-present"
: > "$TERNUX_KGSL_DEVICE"
[ "$(tnx_gpu_backend_auto debian)" = zink ]
zink_profiles="debian ubuntu kali alpine archlinux fedora opensuse void deepin"
for distro in $TERNUX_DISTRO_KNOWN; do
  case " $zink_profiles " in
    *" $distro "*) [ "$(tnx_gpu_backend_auto "$distro")" = zink ] ;;
    *) [ "$(tnx_gpu_backend_auto "$distro")" = virgl ] ;;
  esac
done
[ "$(tnx_gpu_backend_auto ubuntu)" = zink ]
[ "$(tnx_gpu_backend_auto alpine)" = zink ]
[ "$(tnx_gpu_backend_auto kali)" = zink ]
[ "$(tnx_freedreno_asset_name kali kali 2026.3 kali-rolling)" = mesa-for-android-container_27.0.0-devel-20261025-r2_debian_testing_arm64.tar.gz ]
[ "$(tnx_expected_freedreno_sha "$(tnx_freedreno_asset_name kali kali 2026.3 kali-rolling)")" = 25a05d624bb215b656b8446d1b559e36af24e8f7d9c1529445fe97f6f777dc73 ]
for distro in $TERNUX_DISTRO_KNOWN; do
  unset _TNX_DISTRO
  export TERNUX_DISTRO="$distro"
  tnx_phase_launcher ternux auto en_US.UTF-8 >/dev/null
  launcher="$TERNUX_STATE_DIR/distros/$distro/launcher.sh"
  case " $zink_profiles " in
    *" $distro "*)
    grep -q -- '--env MESA_LOADER_DRIVER_OVERRIDE=zink' "$launcher"
      ;;
    *)
    grep -q -- '--env GALLIUM_DRIVER=virpipe' "$launcher"
    grep -q 'virgl_test_server_android' "$launcher"
      ;;
  esac
done
TERNUX_DISTRO=ubuntu
unset _TNX_DISTRO
tnx_phase_launcher sobuj_dev2 auto en_US.UTF-8 >/dev/null
grep -q '/home/sobuj_dev2/' "$TERNUX_STATE_DIR/distros/ubuntu/launcher.sh"
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
[ "$(wc -l < "$TMP/install-calls")" -eq 2 ] || { echo "FAIL: install call count"; exit 1; }
grep -q -- '^--yes --distro debian --user ternux --shell bash --batch-confirmed --workloads none$' "$TMP/install-calls" || { echo "FAIL: Debian batch arguments"; cat "$TMP/install-calls"; exit 1; }
grep -q -- '^--yes --distro ubuntu --user ternux --shell bash --batch-confirmed --workloads none$' "$TMP/install-calls" || { echo "FAIL: Ubuntu batch arguments"; cat "$TMP/install-calls"; exit 1; }
tnx_install_single() { printf '%s|%s\n' "${TERNUX_STARTUP_PASSWORD:-}" "$*" >> "$TMP/startup-password-forwarding"; }
TERNUX_USER_PASSWORD=test-sudo
tnx_install --distros debian,ubuntu --yes >/dev/null
[ "$(wc -l < "$TMP/startup-password-forwarding")" -eq 2 ] || { echo "FAIL: startup forward count"; cat "$TMP/startup-password-forwarding"; exit 1; }
grep -q '^test-startup|--yes --distro debian ' "$TMP/startup-password-forwarding" || { echo "FAIL: Debian startup forwarding"; cat "$TMP/startup-password-forwarding"; exit 1; }
grep -q '^test-startup|--yes --distro ubuntu ' "$TMP/startup-password-forwarding" || { echo "FAIL: Ubuntu startup forwarding"; cat "$TMP/startup-password-forwarding"; exit 1; }
if TERNUX_STARTUP_PASSWORD= tnx_install --distros debian,ubuntu --yes >/dev/null 2>&1; then exit 1; fi
if tnx_install --distros debian,arch >/dev/null 2>&1; then exit 1; fi
if tnx_install --distros debian,debian >/dev/null 2>&1; then exit 1; fi

# Interactive multi-guest identity choices are collected before any profile
# installation, and the host shell is asked only once for the whole batch.
: > "$TMP/precollect-order"
tnx_prompt_shell() { printf 'shell:%s\n' "$1" >> "$TMP/precollect-order"; printf 'zsh\n'; }
tnx_prompt_username() { printf 'user:%s\n' "$3" >> "$TMP/precollect-order"; printf 'user-%s\n' "$3"; }
tnx_prompt_workloads() { printf 'workload:%s\n' "$1" >> "$TMP/precollect-order"; printf '\n'; }
tnx_prompt_user_password() { printf 'sudo:%s\n' "$2" >> "$TMP/precollect-order"; TERNUX_USER_PASSWORD="test-sudo-$2"; }
tnx_prompt_startup_password() { TERNUX_STARTUP_PASSWORD=test-startup; }
tnx_summary_box() { printf 'summary\n' >> "$TMP/precollect-order"; }
tnx_confirm() { printf 'confirm\n' >> "$TMP/precollect-order"; return 0; }
tnx_install_single() { printf 'install:%s:%s\n' "$TERNUX_USER_PASSWORD" "$*" >> "$TMP/precollect-order"; }
tnx_header() { :; }
tnx_next_steps() { printf 'next:%s\n' "$@" >> "$TMP/precollect-order"; }
tnx_install --distros debian,ubuntu,alpine >/dev/null
expected_precollect=(shell:bash user:debian workload:auto user:ubuntu workload:auto user:alpine workload:auto sudo:debian sudo:ubuntu sudo:alpine summary confirm)
for i in "${!expected_precollect[@]}"; do
  [ "$(sed -n "$((i + 1))p" "$TMP/precollect-order")" = "${expected_precollect[i]}" ]
done
grep -q '^install:test-sudo-debian:--distro debian --user user-debian --shell zsh --batch-confirmed --workloads none$' "$TMP/precollect-order"
grep -q '^install:test-sudo-ubuntu:--distro ubuntu --user user-ubuntu --shell zsh --batch-confirmed --workloads none$' "$TMP/precollect-order"
grep -q '^install:test-sudo-alpine:--distro alpine --user user-alpine --shell zsh --batch-confirmed --workloads none$' "$TMP/precollect-order"
grep -q '^next:Start debian desktop: ternux start debian$' "$TMP/precollect-order"
grep -q '^next:Open ubuntu shell: ternux distro shell ubuntu$' "$TMP/precollect-order"
grep -q '^next:Open alpine shell: ternux distro shell alpine$' "$TMP/precollect-order"

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
  tnx_state_set cli_source_identity 'pin:0000000000000000000000000000000000000000'
  tnx_install_phase_done cli && exit 1
  tnx_state_set cli_source_identity "$(tnx_cli_source_identity)"
  tnx_proot_container_installed(){ return 0; }
  for phase in debian root_password user_password startup_password gpu audio_fonts launcher aliases extras phantom verify; do
    tnx_state_mark "phase_$phase"
    tnx_distro_phase_mark debian "$phase"
  done
  order="$TMP/ubuntu-resume-order"
  tnx_require_termux(){ :; }; tnx_confirm(){ :; }; tnx_banner(){ :; }
  tnx_phase_header(){ :; }; tnx_celebrate(){ :; }; tnx_summary_box(){ :; }
  tnx_next_steps(){ :; }; tnx_log_error(){ :; }
  for phase in preflight packages cli debian root_password gpu audio_fonts launcher aliases extras phantom verify; do
    eval "tnx_phase_${phase}(){ printf '%s\\n' '${phase}' >> '$order'; }"
  done
  TERNUX_USER_PASSWORD=test-sudo tnx_install --distro ubuntu --resume --yes >/dev/null 2>&1 || exit 1
  [ "$(tr '\n' ' ' < "$order")" = 'debian root_password gpu audio_fonts launcher aliases phantom verify ' ] || exit 1
  [ "$(tnx_distro_state_get ubuntu status)" = ready ] || exit 1
  tnx_state_done phase_debian && tnx_distro_phase_done debian debian && tnx_distro_phase_done ubuntu debian
); then
  echo 'PASS: resuming one guest does not skip its phases because another guest completed them'
else
  echo 'FAIL: guest-scoped install resume phases' >&2
  exit 1
fi


# A removed profile may retain an old guest ledger; resume must verify the
# actual PRoot container before trusting any guest phase marker.
if (
  . "$ROOT/lib/core.sh"
  export TERNUX_STATE_DIR="$TMP/stale-guest-state"
  mkdir -p "$TERNUX_STATE_DIR/distros/ubuntu"
  printf 'phase_gpu\nphase_verify\n' > "$TERNUX_STATE_DIR/distros/ubuntu/phases"
  tnx_proot_container_installed(){ return 1; }
  tnx_install_phase_done gpu ubuntu && exit 1
  tnx_proot_container_installed(){ return 0; }
  tnx_install_phase_done gpu ubuntu
); then
  echo 'PASS: resume never trusts a guest phase ledger after its PRoot container is removed'
else
  echo 'FAIL: resume accepted stale phase markers for a removed guest' >&2
  exit 1
fi

# A managed install must clear a removed guest's ledger before recreating its
# rootfs, so stale GPU/verification markers cannot skip work on the new guest.
if (
  . "$ROOT/lib/core.sh"
  export TERNUX_STATE_DIR="$TMP/reset-missing-guest-state"
  dir="$TERNUX_STATE_DIR/distros/ubuntu"
  mkdir -p "$dir/session"
  printf 'phase_gpu\nphase_verify\n' > "$dir/phases"
  : > "$dir/session/desktop.state"
  tnx_proot_container_installed(){ return 1; }
  tnx_install_reset_missing_guest_state ubuntu || exit 1
  [ ! -e "$dir/phases" ] && [ ! -e "$dir/session" ] || exit 1
  printf 'phase_gpu\n' > "$dir/phases"
  mkdir -p "$dir/session"
  tnx_proot_container_installed(){ return 0; }
  tnx_install_reset_missing_guest_state ubuntu || exit 1
  [ -e "$dir/phases" ] && [ -e "$dir/session" ]
); then
  echo 'PASS: managed reinstall resets guest ledger only when its PRoot container is absent'
else
  echo 'FAIL: missing-container install did not safely reset stale guest state' >&2
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
: > "$TMP/proot-calls"
tnx_cmd_distro image-install alpine:latest alpine
[ "$(cat "$TMP/proot-calls")" = 'install --name alpine alpine:latest' ]
tnx_cmd_distro shell alpine
[ "$(tail -n 1 "$TMP/login-calls")" = 'alpine|--user ternux' ]
tnx_cmd_distro search 'debian bookworm'
[ "$(tail -n 1 "$TMP/proot-calls")" = 'search debian bookworm' ]
if tnx_cmd_distro search >/dev/null 2>&1; then exit 1; fi
if tnx_cmd_distro search one two >/dev/null 2>&1; then exit 1; fi
tnx_cmd_distro list > "$TMP/distro-list"
grep -q 'alpine.*short=alp' "$TMP/distro-list"
grep -q 'debian.*short=db' "$TMP/distro-list"
grep -q 'installed · setup needed' "$TMP/distro-list"
grep -q 'kali.*kali.*:3' "$TMP/distro-list"
grep -q 'alpine.*alp.*:4' "$TMP/distro-list"
tnx_cmd_distro > "$TMP/distro-overview"
! cmp -s "$TMP/distro-list" "$TMP/distro-overview"
grep -q 'tx distro list.*Show all managed profiles' "$TMP/distro-overview"

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
! grep -q "^alias tx=" "$HOME/.bashrc"
grep -q "alias killx='tx stop'" "$HOME/.bashrc"
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
grep -q 'kali() { _ternux_guest_login kali --shared-tmp --user' "$HOME/.bashrc"
grep -q 'kalir() { _ternux_guest_login kali --shared-tmp' "$HOME/.bashrc"
grep -q 'kaliroot() { kalir "\$@"; }' "$HOME/.bashrc"
! grep -q '^kal() {' "$HOME/.bashrc"

# The tx executable must resolve in an interactive Bash shell; do not mask it
# with an alias to a non-executable or missing `ternux` path.
mkdir -p "$PREFIX/bin"
cat > "$PREFIX/bin/tx" <<'TX_TEST'
#!/usr/bin/env bash
printf 'tx-wrapper-ok:%s\n' "$*"
TX_TEST
chmod 0755 "$PREFIX/bin/tx"
interactive_tx="$(PATH="$PREFIX/bin:$PATH" HOME="$HOME" bash --noprofile --rcfile "$HOME/.bashrc" -ic 'tx --version' 2>/dev/null)"
grep -Fq 'tx-wrapper-ok:--version' <<< "$interactive_tx"
if command -v script >/dev/null 2>&1; then
  printf 'jj \r' | script -qec "stty rows 30 cols 80; TERM=xterm-256color bash -c 'source '$ROOT'/lib/phases.sh; tnx_prompt_distro debian 20'" /dev/null > "$TMP/distro-multi-prompt"
  grep -q 'SPACE/number toggle' "$TMP/distro-multi-prompt"
  grep -q 'debian,kali' "$TMP/distro-multi-prompt"
  printf '4\r' | script -qec "stty rows 30 cols 80; TERM=xterm-256color bash -c 'source '$ROOT'/lib/phases.sh; tnx_prompt_distro debian 20'" /dev/null > "$TMP/distro-number-toggle"
  grep -q 'debian,alpine' "$TMP/distro-number-toggle"
  printf '10\r' | script -qec "stty rows 30 cols 80; TERM=xterm-256color bash -c 'source '$ROOT'/lib/phases.sh; tnx_prompt_distro debian 20'" /dev/null > "$TMP/distro-number-multidigit"
  grep -q 'debian,chimera' "$TMP/distro-number-multidigit"
  printf 'jjjjjjjjj \r' | script -qec "stty rows 16 cols 32; TERM=xterm-256color bash -c 'source '$ROOT'/lib/phases.sh; tnx_prompt_distro debian 20'" /dev/null > "$TMP/distro-compact-menu"
  grep -q 'Selected: debian, chimera' "$TMP/distro-compact-menu"
  grep -q 'J/K move | Space toggle' "$TMP/distro-compact-menu"
  printf 'q' | script -qec "stty rows 30 cols 80; TERM=xterm-256color bash -c 'source '$ROOT'/lib/phases.sh; tnx_prompt_distro debian 20'" /dev/null > "$TMP/distro-menu-default"
  grep -q 'debian' "$TMP/distro-menu-default"
  printf '1,4\n' | script -qec "stty rows 10 cols 24; TERM=xterm-256color bash -c 'source '$ROOT'/lib/phases.sh; tnx_prompt_distro debian 20'" /dev/null > "$TMP/distro-small-terminal"
  grep -q 'debian,alpine' "$TMP/distro-small-terminal"
fi
cat > "$TMP/check-xgo.sh" <<'EOF'
proot-distro() { printf 'alpine\ndebian\nubuntu\n'; }
tx() { printf 'START:%s\n' "$*"; }
ternux() { printf 'START:%s\n' "$*"; }
. "$HOME/.bashrc"
xgo
EOF
printf '2\n' | bash --noprofile --norc "$TMP/check-xgo.sh" > "$TMP/xgo-output"
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
grep -q 'Display :1' "$TMP/stop-picker"
grep -q 'Display :2' "$TMP/stop-picker"
printf 'all\n' | _tnx_stop_select > "$TMP/stop-all-picker"
[ "$(wc -l < "$stop_calls")" -eq 4 ]
kill "$debian_pid" "$ubuntu_pid" 2>/dev/null || true
wait "$debian_pid" "$ubuntu_pid" 2>/dev/null || true
echo 'PASS: guest profiles, multi-install, shell shortcuts, xgo picker, multi-display stop picker, and lifecycle guards'
