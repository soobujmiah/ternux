#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export TERNUX_STATE_DIR="$TMP/state" HOME="$TMP/home"
mkdir -p "$HOME" "$TERNUX_STATE_DIR"
. "$ROOT/lib/doctor.sh"
tnx_is_termux(){ :; }
tnx_has_cmd(){ return 0; }
proot-distro(){ [ "$*" = 'list --quiet' ] && printf 'debian installed\nkali installed\n'; }
tnx_proot_container_installed(){ case "$1" in debian|kali) return 0;; *) return 1;; esac; }
tnx_debian_installed(){ return 0; }
tnx_guest_login(){
  case "$(tnx_distro)" in
    debian) printf 'guest.arch=aarch64\nguest.glibc=2.41\nguest.os=Debian\nguest.sudo=yes\nguest.cmd.startxfce4=yes\nguest.cmd.glxinfo=yes\nguest.cmd.xdpyinfo=yes\nguest.cmd.pactl=yes\nguest.dpkg_audit=0\nguest.disk_free_gb=20\n' ;;
    kali) printf 'guest.arch=aarch64\nguest.glibc=2.43\nguest.os=Kali\nguest.sudo=yes\nguest.cmd.startxfce4=yes\nguest.cmd.glxinfo=yes\nguest.cmd.xdpyinfo=yes\nguest.cmd.pactl=yes\nguest.dpkg_audit=0\nguest.disk_free_gb=10\n' ;;
  esac
}
tnx_detect_storage_gb(){ echo 20; }
tnx_detect_vulkan_state(){ echo VULKAN_READY; }
tnx_vulkan_legacy_status(){ echo yes; }
tnx_detect_gpu(){ echo Adreno; }
tnx_detect_backend(){ echo virgl; }
tnx_detect_renderer(){ echo virgl; }
tnx_detect_phantom_killer(){ echo disabled; }
tnx_detect_android_version(){ echo 16; }
tnx_detect_android_sdk(){ echo 36; }
tnx_detect_arch(){ echo aarch64; }

TERNUX_JSON=1 tnx_cmd_doctor > "$TMP/all.json" || [ "$?" -le 2 ]
python3 - "$TMP/all.json" <<'PY'
import json,sys
x=json.load(open(sys.argv[1])); guests=[c for c in x['checks'] if c['category']=='guest']
titles=' '.join(c['title'] for c in guests)
assert 'Debian' in titles and 'Kali' in titles
assert len(guests) >= 2
PY
TERNUX_JSON=1 tnx_cmd_doctor db > "$TMP/db.json" || [ "$?" -le 2 ]
python3 - "$TMP/db.json" <<'PY'
import json,sys
x=json.load(open(sys.argv[1])); guests=[c for c in x['checks'] if c['category']=='guest']
assert guests and all('Kali' not in c['title'] for c in guests)
assert any('Debian' in c['title'] for c in guests)
PY
TERNUX_JSON=1 tnx_cmd_doctor gpu > "$TMP/gpu.json" || [ "$?" -le 2 ]
python3 - "$TMP/gpu.json" <<'PY'
import json,sys
x=json.load(open(sys.argv[1])); assert x['checks'] and {c['category'] for c in x['checks']} == {'graphics'}
PY
TERNUX_JSON=1 tnx_cmd_doctor kali gpu > "$TMP/kali-gpu.json" || [ "$?" -le 2 ]
python3 - "$TMP/kali-gpu.json" <<'PY'
import json,sys
x=json.load(open(sys.argv[1])); assert x['checks'] and {c['category'] for c in x['checks']} == {'graphics'}
PY
echo 'all-guest, distro-scoped, and GPU-only doctor checks passed'
