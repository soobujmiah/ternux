#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PHASES="$ROOT/lib/phases.sh"

# APT transactions in guest setup must have both network limits and a hard
# process deadline. The base desktop transaction installs several hundred
# packages, so its process deadline must accommodate slower mirrors/devices.
grep -Fq 'timeout --signal=TERM --kill-after=10 300 apt update' "$PHASES"
grep -Fq 'timeout --signal=TERM --kill-after=10 900 apt install -y' "$PHASES"
grep -Fq 'timeout --signal=TERM --kill-after=10 3600 apt install -y -o APT::Install-Recommends=false' "$PHASES"
grep -Fq 'Acquire::http::Timeout=30 -o Acquire::https::Timeout=30' "$PHASES"
grep -Fq 'timeout --signal=TERM --kill-after=10 900 apt install -y \$DPKG_FORCE -o Acquire::Retries=2 -o Acquire::http::Timeout=30 -o Acquire::https::Timeout=30 "\$browser_package"' "$PHASES"

grep -Fq 'timeout --signal=TERM --kill-after=5 90 sudo locale-gen' "$PHASES"
grep -Fq 'timeout --signal=TERM --kill-after=5 60 fc-cache -f' "$PHASES"
grep -Fq 'tnx_guest_login --_tnx-timeout-seconds 1200 --shared-tmp --user "$user_name"' "$PHASES"
! sed -n '/tnx_phase_audio_fonts() {/,/^}/p' "$PHASES" | grep -Fq 'sudo locale-gen'

echo 'base and optional guest setup steps have bounded network and wall-clock limits'
