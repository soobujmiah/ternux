#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PHASES="$ROOT/lib/phases.sh"

# APT transactions in guest setup must have both network limits and a hard
# process deadline. The base desktop transaction installs several hundred
# packages, so its process deadline must accommodate slower mirrors/devices.
grep -Fq 'timeout --signal=TERM --kill-after=10 300 apt-get update' "$PHASES"
grep -Fq 'timeout --signal=TERM --kill-after=10 900 apt install -y' "$PHASES"
grep -Fq 'timeout --signal=TERM --kill-after=10 3600 apt install -y -o APT::Install-Recommends=false' "$PHASES"
grep -Fq 'Acquire::http::Timeout=30 -o Acquire::https::Timeout=30' "$PHASES"
grep -Fq 'timeout --signal=TERM --kill-after=10 900 apt install -y \$DPKG_FORCE -o Acquire::Retries=2 -o Acquire::http::Timeout=30 -o Acquire::https::Timeout=30 "\$browser_package"' "$PHASES"
grep -Fq -- "-w '%{http_code} %{speed_download}'" "$PHASES"
grep -Fq 'APT operation failed; refreshing the distro-configured repositories before retrying.' "$PHASES"
grep -Fq 'command timeout --signal=TERM --kill-after=10 300 apt update' "$PHASES"
grep -Fq 'refresh_repo_metadata()' "$PHASES"
grep -Fq 'pacman) pacman -Syy --noconfirm' "$PHASES"
grep -Fq 'dnf) dnf makecache --refresh' "$PHASES"
grep -Fq 'xbps) xbps-install -S' "$PHASES"
grep -Fq 'trap cleanup_staged_assets EXIT' "$PHASES"

audio_phase="$(sed -n '/tnx_phase_audio_fonts() {/,/^}/p' "$PHASES")"
audio_phase_code="$(sed '/^[[:space:]]*#/d' <<<"$audio_phase")"
grep -Fq 'tnx_guest_login --_tnx-timeout-seconds 1200 --shared-tmp --user root' <<<"$audio_phase"
grep -Fq 'timeout --signal=TERM --kill-after=10 300 apt-get update' <<<"$audio_phase"
grep -Fq 'timeout --signal=TERM --kill-after=10 180 env DEBIAN_FRONTEND=noninteractive apt-get install' <<<"$audio_phase"
grep -Fq 'dpkg-query -W -f='\''\${db:Status-Status}'\''' <<<"$audio_phase"
grep -Fq 'dpkg --audit' <<<"$audio_phase"
grep -Fq 'locale/font packages are installed and dpkg is clean; continuing.' <<<"$audio_phase"
grep -Fq 'timeout --signal=TERM --kill-after=5 90 locale-gen' <<<"$audio_phase"
! grep -Eq '(^|[[:space:]])sudo([[:space:]]|$)' <<<"$audio_phase_code"
grep -Fq 'timeout --signal=TERM --kill-after=5 60 fc-cache -f' "$PHASES"
grep -Fq 'tnx_guest_login --_tnx-timeout-seconds 1200 --shared-tmp --user "$user_name"' "$PHASES"

echo 'base and optional guest setup steps have bounded network and wall-clock limits'
