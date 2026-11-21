#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/home" "$TMP/prefix"
export HOME="$TMP/home" PREFIX="$TMP/prefix" TERNUX_STATE_DIR="$TMP/state" TERNUX_LOG_DIR="$TMP/log"

# Capture the real generated root setup script while avoiding any device access.
. "$ROOT/lib/phases.sh"
tnx_distro() { printf '%s\n' debian; }
tnx_distro_profile() { TNX_DP_FAMILY=apt; }
tnx_request_microphone_permission() { return 0; }
tnx_request_camera_permission() { return 0; }
_tnx_configure_pulse_bridge() { _TNX_PULSE_CHANGED=0; return 0; }
_tnx_configure_guest_codex_installer_default() { return 0; }
script_index=0
tnx_guest_login() {
  script_index=$((script_index + 1))
  if [[ " $* " == *" bash -c "* ]]; then
    printf '%s\n' "${@: -1}" > "$TMP/guest-${script_index}.sh"
  fi
  return 0
}
tnx_phase_audio_fonts ternux en_US.UTF-8 >/dev/null
[[ -s "$TMP/guest-1.sh" ]] || { echo 'FAIL: generated guest root script was not captured' >&2; exit 1; }
bash -n "$TMP/guest-1.sh"

cat > "$TMP/bin/timeout" <<'MOCK'
#!/usr/bin/env bash
set -e
while (($#)); do
  case "$1" in
    --signal=*|--kill-after=*) shift ;;
    [0-9]*) shift; break ;;
    *) echo "unexpected timeout argument: $1" >&2; exit 90 ;;
  esac
done
exec "$@"
MOCK
cat > "$TMP/bin/apt-get" <<'MOCK'
#!/usr/bin/env bash
set -e
if [[ "${1:-}" == update ]]; then exit 0; fi
if [[ "${1:-}" == install ]]; then
  : > "$FIXTURE_DPKG_PENDING"
  exit 124
fi
if [[ "${1:-}" == -f && "${2:-}" == install ]]; then
  : > "$FIXTURE_APT_REPAIR"
  exit 0
fi
echo "unexpected apt-get invocation: $*" >&2
exit 91
MOCK
cat > "$TMP/bin/dpkg" <<'MOCK'
#!/usr/bin/env bash
set -e
for arg in "$@"; do
  if [[ "$arg" == --audit ]]; then
    if [[ -e "$FIXTURE_DPKG_PENDING" ]]; then
      printf '%s\n' 'libc6:arm64: package is unpacked but not configured'
    fi
    exit 0
  fi
done
for arg in "$@"; do
  if [[ "$arg" == --configure ]]; then
    : > "$FIXTURE_DPKG_CONFIGURED"
    rm -f "$FIXTURE_DPKG_PENDING"
    exit 0
  fi
done
echo "unexpected dpkg invocation: $*" >&2
exit 92
MOCK
cat > "$TMP/bin/dpkg-query" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' installed
MOCK
cat > "$TMP/bin/locale-gen" <<'MOCK'
#!/usr/bin/env bash
exit 0
MOCK
cat > "$TMP/bin/grep" <<'MOCK'
#!/usr/bin/env bash
for arg in "$@"; do
  [[ "$arg" == /etc/locale.gen ]] && exit 0
done
exec /usr/bin/grep "$@"
MOCK
chmod +x "$TMP/bin/"*

export FIXTURE_DPKG_PENDING="$TMP/dpkg-pending" FIXTURE_DPKG_CONFIGURED="$TMP/dpkg-configured" FIXTURE_APT_REPAIR="$TMP/apt-repair"
PATH="$TMP/bin:$PATH" bash "$TMP/guest-1.sh" > "$TMP/output.log" 2>&1 || {
  cat "$TMP/output.log" >&2
  echo 'FAIL: interrupted locale/font package setup did not recover automatically' >&2
  exit 1
}
grep -Fq 'automatically completing dpkg configuration' "$TMP/output.log"
grep -Fq 'package configuration was recovered and all locale/font packages are installed; continuing.' "$TMP/output.log"
[[ -e "$FIXTURE_DPKG_CONFIGURED" && -e "$FIXTURE_APT_REPAIR" && ! -e "$FIXTURE_DPKG_PENDING" ]] || {
  echo 'FAIL: dpkg configure and APT dependency repair were not both run' >&2
  exit 1
}
echo 'PASS: interrupted locale/font APT setup repairs dpkg and continues when packages are complete'
