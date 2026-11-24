#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/home" "$TMP/prefix"
export HOME="$TMP/home" PREFIX="$TMP/prefix" TERNUX_STATE_DIR="$TMP/state" TERNUX_LOG_DIR="$TMP/log"

# Exercise the real guest-login timeout validation as well as the generated
# root setup script, while replacing only the device-facing commands.
. "$ROOT/lib/core.sh"
. "$ROOT/lib/phases.sh"
tnx_distro() { printf '%s\n' debian; }
tnx_distro_profile() { TNX_DP_FAMILY=apt; }
tnx_request_microphone_permission() { return 0; }
tnx_request_camera_permission() { return 0; }
_tnx_configure_pulse_bridge() { _TNX_PULSE_CHANGED=0; return 0; }
_tnx_configure_guest_codex_installer_default() { return 0; }
script_index=0
timeout() {
  [[ "$1" == --signal=TERM && "$2" == --kill-after=1 ]] || return 90
  shift 2
  printf '%s\n' "$1" >> "$TMP/guest-timeouts"
  shift
  "$@"
}
proot-distro() {
  script_index=$((script_index + 1))
  if [[ " $* " == *" bash -c "* ]]; then
    printf '%s\n' "${@: -1}" > "$TMP/guest-${script_index}.sh"
  fi
  return 0
}
tnx_phase_audio_fonts ternux en_US.UTF-8 >/dev/null
[[ -s "$TMP/guest-1.sh" ]] || { echo 'FAIL: generated guest root script was not captured' >&2; exit 1; }
grep -qx 4800 "$TMP/guest-timeouts" || { echo 'FAIL: guest login rejected the audio recovery timeout' >&2; exit 1; }
if tnx_guest_login --_tnx-timeout-seconds 4801 -- true >/dev/null 2>&1; then
  echo 'FAIL: guest login accepted a timeout above its maximum' >&2
  exit 1
fi
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
  if [[ "${FIXTURE_RETRY_MISSING:-0}" == 1 ]]; then
    if [[ -e "$FIXTURE_FIRST_INSTALL" ]]; then
      [[ ! -e "$FIXTURE_DPKG_PENDING" && -e "$FIXTURE_APT_REPAIR" ]] || exit 1
      : > "$FIXTURE_RETRY_DONE"
      exit 0
    fi
    : > "$FIXTURE_FIRST_INSTALL"
  fi
  if [[ "${FIXTURE_APT_INSTALL_RC:-124}" == 0 ]]; then
    [[ ! -e "$FIXTURE_DPKG_PENDING" ]] || { echo "APT ran before dpkg repair" >&2; exit 1; }
    exit 0
  fi
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
    [[ "${FIXTURE_CONFIGURE_FAIL:-0}" != 1 ]] || exit 1
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
if [[ "${FIXTURE_RETRY_MISSING:-0}" == 1 && ! -e "$FIXTURE_RETRY_DONE" ]]; then
  printf '%s\n' 'not-installed'
else
  printf '%s\n' installed
fi
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

# Scenario 2: dpkg was already interrupted before this phase started (left by
# an earlier phase). The installer must repair it before APT runs, without a
# manual `dpkg --configure -a` inside the guest.
rm -f "$FIXTURE_DPKG_PENDING" "$FIXTURE_DPKG_CONFIGURED" "$FIXTURE_APT_REPAIR"
: > "$FIXTURE_DPKG_PENDING"
FIXTURE_APT_INSTALL_RC=0 PATH="$TMP/bin:$PATH" bash "$TMP/guest-1.sh" > "$TMP/output-prerepair.log" 2>&1 || {
  cat "$TMP/output-prerepair.log" >&2
  echo 'FAIL: pre-existing interrupted dpkg was not repaired before APT install' >&2
  exit 1
}
grep -Fq 'Interrupted dpkg configuration found; automatically completing it before installing locale/font packages' "$TMP/output-prerepair.log"
[[ -e "$FIXTURE_DPKG_CONFIGURED" && ! -e "$FIXTURE_DPKG_PENDING" ]] || {
  echo 'FAIL: pre-repair did not run dpkg --configure -a before APT install' >&2
  exit 1
}
echo 'PASS: pre-existing interrupted dpkg is repaired before APT install without a manual guest step'

# Scenario 3: recovery completes, but the first failed transaction never
# installed all requested packages. Retry installation after dependency repair.
rm -f "$FIXTURE_DPKG_PENDING" "$FIXTURE_DPKG_CONFIGURED" "$FIXTURE_APT_REPAIR"
export FIXTURE_FIRST_INSTALL="$TMP/first-install" FIXTURE_RETRY_DONE="$TMP/retry-done"
FIXTURE_RETRY_MISSING=1 PATH="$TMP/bin:$PATH" bash "$TMP/guest-1.sh" > "$TMP/output-retry.log" 2>&1 || {
  cat "$TMP/output-retry.log" >&2
  echo 'FAIL: missing packages were not retried after dpkg recovery' >&2
  exit 1
}
grep -Fq 'Retrying missing locale/font packages after dpkg recovery' "$TMP/output-retry.log"
[[ -e "$FIXTURE_RETRY_DONE" && ! -e "$FIXTURE_DPKG_PENDING" ]] || exit 1
echo 'PASS: missing locale/font packages are retried after recovery'

# An actual dpkg configuration failure must stop the phase, not hide errors.
rm -f "$FIXTURE_DPKG_CONFIGURED" "$FIXTURE_APT_REPAIR"
: > "$FIXTURE_DPKG_PENDING"
if FIXTURE_CONFIGURE_FAIL=1 PATH="$TMP/bin:$PATH" bash "$TMP/guest-1.sh" > "$TMP/output-failure.log" 2>&1; then
  echo 'FAIL: unrecoverable dpkg configuration was ignored' >&2
  exit 1
fi
grep -Fq 'dpkg could not configure the interrupted packages' "$TMP/output-failure.log"
echo 'PASS: unrecoverable dpkg errors stop the phase'
