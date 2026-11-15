#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export TERNUX_STATE_DIR="$TMP/state" HOME="$TMP/home" TMPDIR="$TMP/tmp"
mkdir -p "$TERNUX_STATE_DIR/session" "$TERNUX_STATE_DIR/distros/kali/session" \
  "$TERNUX_STATE_DIR/distros/debian/session" "$TERNUX_STATE_DIR/distros/ubuntu/session" "$HOME"

. "$ROOT/lib/info.sh"
tnx_detect_android_version(){ echo 16; }
tnx_detect_android_sdk(){ echo 36; }
tnx_detect_arch(){ echo aarch64; }
tnx_detect_model(){ echo DeviceTest; }
tnx_detect_manufacturer(){ echo TestMaker; }
tnx_detect_ram_gb(){ echo 8; }
tnx_detect_storage_gb(){ echo 20; }
tnx_detect_termux_version(){ echo 0.119.0; }
tnx_detect_gpu(){ echo 'PowerVR'; }
tnx_detect_vulkan_state(){ echo HARDWARE_AVAILABLE; }
tnx_vulkan_legacy_status(){ echo 'no (driver missing)'; }
tnx_state_get(){ echo virgl; }
tnx_detect_phantom_killer(){ echo 'unreadable (not exposed)'; }
tnx_detect_renderer(){ echo 'not running (Termux:X11 stopped)'; }
TERNUX_JSON=1 tnx_cmd_info > "$TMP/info.json"
python3 - "$TMP/info.json" <<'PY'
import json,sys
data=json.load(open(sys.argv[1]))
assert data['android_sdk']=='36'
assert data['gpu']=='PowerVR'
assert data['cpu_cores']!='unknown'
assert data['ram_available_gb']!='unknown'
assert data['graphics_state']=='DISPLAY_STOPPED'
assert data['renderer'].startswith('not running')
assert 'phantom_process_killer' in data
PY
TERNUX_JSON=0 tnx_cmd_info > "$TMP/info.txt"
grep -q '^  Device and host$' "$TMP/info.txt"
grep -q '^  Resources$' "$TMP/info.txt"
grep -q '^  Graphics$' "$TMP/info.txt"

. "$ROOT/lib/state.sh"
proot-distro(){ [ "$*" = 'list --quiet' ] && printf 'alpine\nubuntu\nkali\ndebian\n'; }
tnx_distro_state_get(){ case "$1:$2" in kali:status) echo ready;; *) return 1;; esac; }
TERNUX_JSON=1 tnx_cmd_state > "$TMP/state.json"
python3 - "$TMP/state.json" <<'PY'
import json,sys
data=json.load(open(sys.argv[1]))
assert data['distro']=='debian'
assert data['installed_profiles']=='debian:installed:1,ubuntu:installed:2,kali:ready:3,alpine:installed:4'
PY
TERNUX_JSON=0 tnx_cmd_state > "$TMP/state.txt"
grep -q 'Installed managed profiles:' "$TMP/state.txt"
grep -q 'kali.*display :3.*ready' "$TMP/state.txt"
python3 - "$TMP/state.txt" <<'PY'
import pathlib,sys
lines=pathlib.Path(sys.argv[1]).read_text().splitlines()
names=['debian','ubuntu','kali','alpine']
positions=[next(i for i,line in enumerate(lines) if line.lstrip().startswith(name+' ')) for name in names]
assert positions==sorted(positions), positions
PY
. "$ROOT/lib/distro.sh"
[ "$(_tnx_distro_short_name kali)" = kali ]
! tnx_distro_known "$(tnx_distro_canonical kal)"

printf 'kali\n' > "$TERNUX_STATE_DIR/session/distro"
printf 'Kali session detail\n' > "$TERNUX_STATE_DIR/distros/kali/session/desktop.log"
printf 'Debian session detail\n' > "$TERNUX_STATE_DIR/session/desktop.log"
. "$ROOT/lib/logs.sh"
tnx_cmd_logs desktop show > "$TMP/desktop.log.txt"
grep -q 'Desktop Session Log: kali' "$TMP/desktop.log.txt"
grep -q 'Kali session detail' "$TMP/desktop.log.txt"
printf 'Ubuntu session detail\n' > "$TERNUX_STATE_DIR/distros/ubuntu/session/desktop.log"
tnx_cmd_logs desktop show ubuntu > "$TMP/ubuntu-desktop.log.txt"
grep -q 'Desktop Session Log: ubuntu' "$TMP/ubuntu-desktop.log.txt"
grep -q 'Ubuntu session detail' "$TMP/ubuntu-desktop.log.txt"
tnx_cmd_logs list > "$TMP/log-list.txt"
grep -q 'kali/session/desktop.log' "$TMP/log-list.txt"
grep -q 'session/desktop.log' "$TMP/log-list.txt"

. "$ROOT/lib/desktop.sh"
pgrep(){ return 1; }
tnx_desktop_session_live(){ return 1; }
tnx_pulseaudio_ready(){ return 0; }
TERNUX_JSON=1 tnx_cmd_status kali > "$TMP/status.json"
python3 - "$TMP/status.json" <<'PY'
import json,sys
data=json.load(open(sys.argv[1]))
assert data['distro']=='kali'
assert data['display']==':3'
assert data['desktop_log'].endswith('/distros/kali/session/desktop.log')
PY

proot-distro(){ [ "$*" = 'list --quiet' ] && printf 'debian\nubuntu\nkali\n'; }
tnx_proot_container_installed(){ case "$1" in debian|ubuntu|kali) return 0;; *) return 1;; esac; }
TERNUX_JSON=1 tnx_cmd_status > "$TMP/status-all.json"
python3 - "$TMP/status-all.json" <<'PY'
import json,sys
x=json.load(open(sys.argv[1]))
assert x['command']=='status'
assert [g['distro'] for g in x['guests']]==['debian','ubuntu','kali']
PY
TERNUX_JSON=0 tnx_cmd_status > "$TMP/status-all.txt"
grep -q 'Guest:.*debian' "$TMP/status-all.txt"
grep -q 'Guest:.*ubuntu' "$TMP/status-all.txt"
grep -q 'Guest:.*kali' "$TMP/status-all.txt"

echo 'info, state, and per-guest log checks passed'
