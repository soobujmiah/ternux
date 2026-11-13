# =============================================================================
#  ternux — core library
#  Shared utilities, I/O helpers, version info, and JSON/CLI framework.
#  Every other library sources this first.
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah)
#  Licensed under the Apache License, Version 2.0.
#  https://github.com/soobujmiah/ternux
# =============================================================================

TERNUX_VERSION="2.0.0"
TERNUX_NAME="ternux"
TERNUX_DESC="Linux desktop for Android with Zink and VirGL graphics routes"
TERNUX_REPO="https://github.com/soobujmiah/ternux"
# Immutable source snapshot shared by the standalone bootstrap and CLI fallback.
# Keep these values aligned with install.sh; refresh only from a reviewed archive.
TERNUX_SOURCE_COMMIT="6adf64606b4219e310bdabed52c799ea07e5a9b2"
TERNUX_SOURCE_SHA256="12c414fef74b11f6f18ea7c844e5e2da0d27fc0d05b8c16edd7dd6894cd43fd2"
TERNUX_GUEST_CLI_SHA256="305f3b0642b4fd948fb022fec08a8c569b18909a34eedd80ac0e6f8ab0cbbe67"
TERNUX_STATE_DIR="${TERNUX_STATE_DIR:-$HOME/.local/share/ternux}"
TERNUX_LOG_DIR="${TERNUX_LOG_DIR:-${TMPDIR:-/data/data/com.termux/files/usr/tmp}/ternux}"
TERNUX_LOG_FILE="$TERNUX_LOG_DIR/ternux.log"

# Legacy state file (from older versions) — used as fallback
TERNUX_LEGACY_STATE="$HOME/.ternux-state"

# ---------------------------------------------------------------------------
# Guest distribution
#
# Official PRoot-Distro aliases with a supported desktop package manager receive
# a family-based Ternux recipe; arbitrary OCI images remain shell-only.
# Resolution: explicit TERNUX_DISTRO, saved choice, then Debian.
# ---------------------------------------------------------------------------
TERNUX_DISTRO_VERIFIED="debian ubuntu alpine"
TERNUX_DISTRO_KNOWN="debian ubuntu alpine archlinux fedora opensuse void kali artix chimera deepin manjaro pardus rockylinux adelie"

tnx_distro() {
  if [ -z "${_TNX_DISTRO:-}" ]; then
    _TNX_DISTRO="${TERNUX_DISTRO:-}"
    if [ -z "$_TNX_DISTRO" ] && command -v tnx_state_get >/dev/null 2>&1; then
      _TNX_DISTRO="$(tnx_state_get distro 2>/dev/null || true)"
    fi
    [ -n "$_TNX_DISTRO" ] || _TNX_DISTRO="debian"
  fi
  printf '%s' "$_TNX_DISTRO"
}

# True when the resolved guest is one ternux has verified on a device.
tnx_distro_verified() {
  case " $TERNUX_DISTRO_VERIFIED " in
    *" ${1:-$(tnx_distro)} "*) return 0 ;;
  esac
  return 1
}

# Prefer native Mesa Zink/Turnip on Adreno/KGSL for every distro profile.
# Each guest installs its own distro-built Mesa/Freedreno packages; Debian's
# separately pinned asset remains specific to the validated Debian profile.
tnx_gpu_backend_auto() {
  local distro="${1:-$(tnx_distro)}"
  if [ "$distro" != adelie ] && [ -e "${TERNUX_KGSL_DEVICE:-/dev/kgsl-3d0}" ]; then
    printf 'zink'
  else
    printf 'virgl'
  fi
}

# True when the name is one ternux has a profile for at all.
tnx_distro_known() {
  case " $TERNUX_DISTRO_KNOWN " in
    *" ${1:-$(tnx_distro)} "*) return 0 ;;
  esac
  return 1
}

# Stable short names accepted by desktop commands as well as shell aliases.
tnx_distro_canonical() {
  case "${1:-}" in
    db) printf debian ;; ub) printf ubuntu ;; alp) printf alpine ;;
    archx) printf archlinux ;; fed) printf fedora ;; suse) printf opensuse ;;
    vsh) printf void ;; kal) printf kali ;; art) printf artix ;;
    chim) printf chimera ;; deep) printf deepin ;; manj) printf manjaro ;;
    par) printf pardus ;; rock) printf rockylinux ;; adel) printf adelie ;;
    *) printf '%s' "${1:-}" ;;
  esac
}

# Package-manager families for official PRoot-Distro aliases. Sets TNX_DP_*.
# These recipes share the Ternux desktop assets but remain device-unverified
# except for the established Debian profile.
tnx_distro_display() {
  local distro="${1:-$(tnx_distro)}" display=""
  display="$(tnx_distro_state_get "$distro" display 2>/dev/null || true)"
  if [[ "$display" =~ ^[0-9]{1,2}$ ]]; then printf '%s' "$display"; return 0; fi
  case "$distro" in
    debian) printf '0' ;; ubuntu) printf '1' ;; alpine) printf '2' ;;
    archlinux) printf '3' ;; fedora) printf '4' ;; opensuse) printf '5' ;; void) printf '6' ;; kali) printf '7' ;;
    artix) printf '8' ;; chimera) printf '9' ;; deepin) printf '10' ;; manjaro) printf '11' ;; pardus) printf '12' ;; rockylinux) printf '13' ;; adelie) printf '14' ;;
    *) return 1 ;;
  esac
}

tnx_distro_tag() {
  local distro="${1:-$(tnx_distro)}"
  [[ "$distro" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]] || return 2
  printf 'ternux-%s' "$distro"
}

tnx_distro_session_dir() {
  local distro="${1:-$(tnx_distro)}"
  if [ "$distro" = debian ]; then printf '%s/session' "$TERNUX_STATE_DIR"
  else printf '%s/session' "$(tnx_distro_state_dir "$distro")"; fi
}

tnx_distro_state_dir() {
  local distro="${1:-$(tnx_distro)}"
  [[ "$distro" =~ ^[a-zA-Z0-9._-]+$ ]] || return 2
  printf '%s/distros/%s' "$TERNUX_STATE_DIR" "$distro"
}

tnx_distro_state_get() {
  local distro="${1:-$(tnx_distro)}" key="${2:-}" file line
  [[ "$key" =~ ^[a-zA-Z0-9._-]+$ ]] || return 2
  file="$(tnx_distro_state_dir "$distro")/profile"
  [ -f "$file" ] || return 1
  line="$(grep -sm1 "^${key}=" "$file")" || return 1
  printf '%s\n' "${line#*=}"
}

tnx_distro_state_set() {
  local distro="${1:-$(tnx_distro)}" key="${2:-}" value="${3-}" dir file tmp
  [[ "$key" =~ ^[a-zA-Z0-9._-]+$ && "$value" != *$'\n'* ]] || return 2
  dir="$(tnx_distro_state_dir "$distro")" || return 2
  mkdir -p "$dir" || return 1
  file="$dir/profile"; tmp="$dir/.profile.tmp.$$"
  if [ -f "$file" ]; then
    awk -v key="$key" -v value="$value" 'index($0,key "=")==1 { print key "=" value; found=1; next } { print } END { if (!found) print key "=" value }' "$file" > "$tmp" || { rm -f "$tmp"; return 1; }
  else
    printf '%s=%s\n' "$key" "$value" > "$tmp" || { rm -f "$tmp"; return 1; }
  fi
  chmod 0600 "$tmp" && mv -f "$tmp" "$file"
}

tnx_distro_desktop_ready() {
  local distro="${1:-$(tnx_distro)}" recorded=""
  recorded="$(tnx_distro_state_get "$distro" status 2>/dev/null || true)"
  if [ -n "$recorded" ]; then
    [ "$recorded" = ready ]
    return $?
  fi
  # Upgrade compatibility: older single-Debian installs recorded successful
  # verification globally before per-guest profiles were introduced.
  [ "$(tnx_state_get distro 2>/dev/null || true)" = "$distro" ] && tnx_state_done phase_verify
}

tnx_distro_profile() {
  TNX_DP_FAMILY=""
  TNX_DP_MESA_HOLD="mesa-vulkan-drivers libgl1-mesa-dri libglx-mesa0 libgbm1 libegl-mesa0"
  TNX_DP_EXTRA_HOLD=""
  case "${1:-$(tnx_distro)}" in
    debian|ubuntu|kali|deepin|pardus) TNX_DP_FAMILY="apt" ;;
    alpine|adelie) TNX_DP_FAMILY="apk" ;;
    archlinux|artix|manjaro) TNX_DP_FAMILY="pacman" ;;
    fedora|rockylinux) TNX_DP_FAMILY="dnf" ;;
    opensuse) TNX_DP_FAMILY="zypper" ;;
    void) TNX_DP_FAMILY="xbps" ;;
    chimera) TNX_DP_FAMILY="apk" ;;
    *) return 1 ;;
  esac
  [ "${1:-$(tnx_distro)}" != ubuntu ] || TNX_DP_EXTRA_HOLD="snapd"
}

# Add only directory mounts explicitly granted by the user. The allowlist is
# validated on every login so stale paths or hand-edited entries fail closed.
tnx_storage_guest_args() {
  local -n _tnx_login_args="$1"
  local file="$TERNUX_STATE_DIR/storage-allowlist" host guest root resolved expected_guest extra
  # Android shared storage is a standard guest mount, matching the default
  # SD Card desktop shortcut. Termux must already have storage permission.
  root="$(realpath -e /sdcard 2>/dev/null || true)"
  if [ -n "$root" ] && [ -d "$root" ]; then
    _tnx_login_args+=(--bind "$root:/sdcard")
  fi
  [ -e "$file" ] || return 0
  [ ! -L "$file" ] && [ -f "$file" ] || { echo "Unsafe Ternux storage allowlist; refusing storage mounts." >&2; return 1; }
  [ -n "$root" ] && [ -d "$root" ] || { echo "Granted Android storage is unavailable; run termux-setup-storage and retry." >&2; return 1; }
  while IFS=$'\t' read -r host guest extra; do
    [ -n "$host" ] || continue
    expected_guest="/sdcard/${host#"$root"/}"
    [ -z "$extra" ] && [[ "$host" == "$root"/* && "$host" != *:* && "$guest" == "$expected_guest" && "$guest" != *:* ]] || { echo "Out-of-scope Ternux storage grant; refusing storage mounts." >&2; return 1; }
    resolved="$(realpath -e -- "$host" 2>/dev/null)" || { echo "A granted storage directory is no longer available: $guest" >&2; return 1; }
    [ "$resolved" = "$host" ] && [ -d "$host" ] || { echo "A granted storage directory changed identity: $guest" >&2; return 1; }
    if [ "$guest" != /sdcard ] || [ -z "$root" ]; then _tnx_login_args+=(--bind "$host:$guest"); fi
  done < "$file"
}

# Run a command in an isolated guest. Android shared storage is opt-in and
# scoped to directories recorded by `ternux storage grant`.
tnx_guest_login() {
  local timeout_seconds=""
  local -a login_args=(--isolated)
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --shared-x11)
        login_args+=(--shared-x11)
        shift
        ;;
      --_tnx-timeout-seconds)
        [ "$#" -ge 2 ] && [[ "$2" =~ ^[1-9][0-9]{0,2}$ ]] || {
          echo "Invalid internal PRoot timeout." >&2
          return 2
        }
        timeout_seconds="$2"
        shift 2
        ;;
      *) break ;;
    esac
  done
  tnx_storage_guest_args login_args || return $?
  if [ -n "$timeout_seconds" ]; then
    tnx_has_cmd timeout || return 127
    timeout --signal=TERM --kill-after=1 "$timeout_seconds" \
      proot-distro login "${login_args[@]}" "$(tnx_distro)" "$@"
  else
    proot-distro login "${login_args[@]}" "$(tnx_distro)" "$@"
  fi
}

# Avoid a host toolchain override shadowing Termux libraries in APT.
tnx_termux_pkg() { LD_LIBRARY_PATH= pkg "$@"; }
tnx_termux_apt_cache() { LD_LIBRARY_PATH= apt-cache "$@"; }

# ---------------------------------------------------------------------------
# UTC timestamp (ISO 8601) — used for all log entries and JSON output
# ---------------------------------------------------------------------------
__tnx_ts() { date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo "unknown"; }

# ---------------------------------------------------------------------------
# Colours / styling (respect NO_COLOR and non-TTY)
# ---------------------------------------------------------------------------
if [ -n "${NO_COLOR:-}" ] || [ "${TERM:-dumb}" = "dumb" ] || [ ! -t 1 ]; then
  TNX_C0=""; TNX_CG=""; TNX_CC=""; TNX_CY=""; TNX_CR=""; TNX_CM=""; TNX_CB=""; TNX_CW=""; TNX_CD=""
else
  TNX_C0=$'\033[0m';    TNX_CG=$'\033[1;32m'; TNX_CC=$'\033[1;36m'
  TNX_CY=$'\033[1;33m'; TNX_CR=$'\033[1;31m'; TNX_CM=$'\033[1;35m'
  TNX_CB=$'\033[1;34m'; TNX_CW=$'\033[1;37m'; TNX_CD=$'\033[2m'
fi

# ---------------------------------------------------------------------------
# I/O: info, ok, warn, fail, die, step, progress
# ---------------------------------------------------------------------------
tnx_info() { [ "${TERNUX_QUIET:-0}" != "1" ] && [ "${TERNUX_JSON:-0}" != "1" ] && printf "${TNX_CB}[INFO]${TNX_C0}  %s\n" "$1"; }
tnx_ok()   { [ "${TERNUX_QUIET:-0}" != "1" ] && [ "${TERNUX_JSON:-0}" != "1" ] && printf "${TNX_CG}[ OK ]${TNX_C0}  %s\n" "$1"; }
tnx_warn() { [ "${TERNUX_QUIET:-0}" != "1" ] && [ "${TERNUX_JSON:-0}" != "1" ] && printf "${TNX_CY}[WARN]${TNX_C0}  %s\n" "$1"; }
tnx_fail() { [ "${TERNUX_QUIET:-0}" != "1" ] && [ "${TERNUX_JSON:-0}" != "1" ] && printf "${TNX_CR}[FAIL]${TNX_C0}  %s\n" "$1"; }
tnx_die()  {
  tnx_fail "$1"
  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    tnx_json_object "error" "fatal" "message" "$1"
  fi
  exit "${2:-1}"
}
tnx_step() { [ "${TERNUX_JSON:-0}" != "1" ] && printf "\n${TNX_CM}==>${TNX_C0} ${TNX_CW}%s${TNX_C0}\n" "$1"; }
tnx_debug(){ [ "${TERNUX_VERBOSE:-0}" = "1" ] && [ "${TERNUX_JSON:-0}" != "1" ] && printf "${TNX_CD}[DEBUG]${TNX_C0} %s\n" "$1"; }
tnx_header(){ [ "${TERNUX_QUIET:-0}" != "1" ] && [ "${TERNUX_JSON:-0}" != "1" ] && printf "\n${TNX_CD}━━━ %s ━━━${TNX_C0}\n" "$1"; }

# ---------------------------------------------------------------------------
# JSON output builder — assemble a machine-readable JSON record
# ---------------------------------------------------------------------------
# Usage: tnx_json_start; tnx_json_add "key" "val"; tnx_json_end
#        tnx_json_object <cmd> <status> <extra_keyvals...>
#
# The JSON object is accumulated in $TNX_JSON and printed/done at the end.
# This avoids fragile ad-hoc string concatenation.
TNX_JSON=""
TNX_JSON_PARTS=""

tnx_json_init() {
  TNX_JSON=""
  TNX_JSON_PARTS=""
}

tnx_json_add() {
  local key="$1" val="$2"
  # Escape for JSON string
  val="${val//\\/\\\\}"
  val="${val//\"/\\\"}"
  val="${val//$'\n'/\\n}"
  val="${val//$'\t'/\\t}"
  val="${val//$'\r'/\\r}"
  [ -n "$TNX_JSON_PARTS" ] && TNX_JSON_PARTS+=","
  TNX_JSON_PARTS+="\"${key}\":\"${val}\""
}

tnx_json_add_raw() {
  local key="$1" val="$2"
  [ -n "$TNX_JSON_PARTS" ] && TNX_JSON_PARTS+=","
  TNX_JSON_PARTS+="\"${key}\":${val}"
}

tnx_json_add_array() {
  local key="$1"; shift
  local items="[" item escaped
  local first=1
  for item in "$@"; do
    escaped="${item//\\/\\\\}"
    escaped="${escaped//\"/\\\"}"
    escaped="${escaped//$'\n'/\\n}"
    escaped="${escaped//$'\t'/\\t}"
    escaped="${escaped//$'\r'/\\r}"
    [ "$first" -eq 0 ] && items+=","
    items+="\"${escaped}\""
    first=0
  done
  items+="]"
  [ -n "$TNX_JSON_PARTS" ] && TNX_JSON_PARTS+=","
  TNX_JSON_PARTS+="\"${key}\":${items}"
}

tnx_json_end() {
  echo "{${TNX_JSON_PARTS}}"
}

tnx_json_object() {
  local cmd="$1" status="$2"; shift 2
  tnx_json_init
  tnx_json_add "command" "$cmd"
  tnx_json_add "status" "$status"
  tnx_json_add "timestamp" "$(__tnx_ts)"
  tnx_json_add "version" "$TERNUX_VERSION"
  # Add extra key-value pairs passed as arguments (key1 val1 key2 val2...)
  local extra_keys=("$@")
  for ((i=0; i<${#extra_keys[@]}; i+=2)); do
    local k="${extra_keys[$i]}" v="${extra_keys[$((i+1))]}"
    tnx_json_add "$k" "$v"
  done
  tnx_json_end
}

# ---------------------------------------------------------------------------
# Global CLI flags (set by bin/ternux before loading libraries)
# ---------------------------------------------------------------------------
[ -z "${TERNUX_JSON:-}" ]    && TERNUX_JSON=0
[ -z "${TERNUX_VERBOSE:-}" ] && TERNUX_VERBOSE=0
[ -z "${TERNUX_QUIET:-}" ]   && TERNUX_QUIET=0

# ---------------------------------------------------------------------------
# Platform detection helpers
# ---------------------------------------------------------------------------
tnx_is_termux() {
  [ -d "/data/data/com.termux/files/usr" ] && return 0
  return 1
}

tnx_require_termux() {
  tnx_is_termux && return 0
  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    tnx_json_object "error" "fatal" "message" "Not running in Termux environment"
    exit 1
  fi
  tnx_die "This does not look like a Termux environment.\nInstall the main Termux release from F-Droid or GitHub, then run this inside Termux.\nKeep Termux and plugins from one source; the Google Play line is separate and experimental." 1
}

tnx_has_cmd() { command -v "$1" >/dev/null 2>&1; }

# Probe an installed PRoot-Distro container without depending on the human
# `list` layout. PRoot-Distro 5 prints installed names with `list --quiet`,
# while older Termux releases used a multi-line Alias/Status display and stored
# root files under installed-rootfs/. Check the machine-readable interface and
# both known layouts, then retain a conservative legacy-output fallback.
tnx_proot_container_installed() {
  local name="${1:-debian}" prefix="${PREFIX:-/data/data/com.termux/files/usr}"
  local runtime="$prefix/var/lib/proot-distro" listing=""

  tnx_has_cmd proot-distro || return 1

  if [ -d "$runtime/containers/$name/rootfs" ] ||
     [ -d "$runtime/installed-rootfs/$name" ]; then
    return 0
  fi

  listing="$(proot-distro list --quiet 2>/dev/null || true)"
  if printf '%s\n' "$listing" | grep -Fqx -- "$name"; then
    return 0
  fi

  # Compatibility with pre-v5 output and simple test doubles. Match either a
  # same-line "debian ... installed" record or an Alias followed by Status.
  listing="$(proot-distro list 2>/dev/null || true)"
  printf '%s\n' "$listing" | awk -v wanted="$name" '
    BEGIN { wanted=tolower(wanted); candidate=0; found=0 }
    {
      line=tolower($0)
      if (line ~ "(^|[^[:alnum:]_])" wanted "([^[:alnum:]_]|$).*installed") found=1
      if (line ~ "alias[[:space:]]*:[[:space:]]*" wanted "([[:space:]]|$)") candidate=1
      else if (candidate && line ~ "status[[:space:]]*:[[:space:]]*installed") found=1
      else if (candidate && line ~ "alias[[:space:]]*:") candidate=0
    }
    END { exit(found ? 0 : 1) }
  '
}

tnx_debian_installed() { tnx_proot_container_installed "$(tnx_distro)"; }

# Preserve compatibility with state written before the backend names were
# simplified, but never expose or persist the legacy spelling in new output.
tnx_canonical_backend() {
  case "${1:-}" in
    zink-turnip) printf '%s' "zink" ;;
    *) printf '%s' "${1:-}" ;;
  esac
}

# ---------------------------------------------------------------------------
# Download helper with fallback
# ---------------------------------------------------------------------------
tnx_download() {
  local url="$1" dest="$2" attempt=1
  if tnx_has_cmd curl; then
    while [ "$attempt" -le 3 ]; do
      curl -fL --retry 3 --retry-delay 2 --connect-timeout 15 --max-time 900 \
        -o "$dest" "$url" 2>/dev/null && return 0
      rm -f "$dest"
      attempt=$((attempt + 1))
      [ "$attempt" -le 3 ] && sleep "$attempt"
    done
  fi
  attempt=1
  if tnx_has_cmd wget; then
    while [ "$attempt" -le 3 ]; do
      wget -q --timeout=900 --tries=3 -O "$dest" "$url" 2>/dev/null && return 0
      rm -f "$dest"
      attempt=$((attempt + 1))
      [ "$attempt" -le 3 ] && sleep "$attempt"
    done
  fi
  return 1
}

# ---------------------------------------------------------------------------
# State management — with legacy ~/.ternux-state sync
# ---------------------------------------------------------------------------
tnx_state_init() {
  mkdir -p "$TERNUX_STATE_DIR" "$TERNUX_LOG_DIR" 2>/dev/null || true
  # Migrate legacy state if it exists and new state doesn't
  if [ -f "$TERNUX_LEGACY_STATE" ] && [ ! -f "$TERNUX_STATE_DIR/phases" ]; then
    mkdir -p "$TERNUX_STATE_DIR"
    cp "$TERNUX_LEGACY_STATE" "$TERNUX_STATE_DIR/legacy_phases" 2>/dev/null || true
  fi
}

tnx_state_get() {
  local key="$1" line=""
  [ -f "$TERNUX_STATE_DIR/state" ] || return 1
  line="$(grep -sm1 "^${key}=" "$TERNUX_STATE_DIR/state")" || return 1
  printf '%s\n' "${line#*=}"
}

tnx_state_set() {
  local key="$1" val="$2"
  mkdir -p "$TERNUX_STATE_DIR"
  local state_file="$TERNUX_STATE_DIR/state" tmp_file="$TERNUX_STATE_DIR/.state.tmp.$$"
  # Values include URLs and paths, so they must not be interpolated into a sed
  # replacement expression. Rewrite through awk variables and atomically swap.
  if [ -f "$state_file" ]; then
    awk -v key="$key" -v val="$val" '
      index($0, key "=") == 1 { print key "=" val; found=1; next }
      { print }
      END { if (!found) print key "=" val }
    ' "$state_file" > "$tmp_file" || { rm -f "$tmp_file"; return 1; }
  else
    printf '%s=%s\n' "$key" "$val" > "$tmp_file" || { rm -f "$tmp_file"; return 1; }
  fi
  mv -f "$tmp_file" "$state_file"
}

tnx_state_done() {
  local phase="$1"
  [ -f "$TERNUX_STATE_DIR/phases" ] && grep -qsx "$phase" "$TERNUX_STATE_DIR/phases"
}

tnx_state_mark() {
  local phase="$1"
  tnx_state_done "$phase" || echo "$phase" >> "$TERNUX_STATE_DIR/phases"
}

# Host bootstrap phases are shared, while desktop configuration is owned by
# each named guest. Keep the old aggregate phase file for existing readers,
# but use a per-guest ledger when deciding what an interrupted install may skip.
tnx_distro_phase_done() {
  local distro="${1:-$(tnx_distro)}" phase="${2:-}" file
  [[ "$phase" =~ ^[a-z][a-z0-9_]*$ ]] || return 2
  file="$(tnx_distro_state_dir "$distro")/phases"
  [ -f "$file" ] && grep -qsx "phase_$phase" "$file"
}

tnx_distro_phase_mark() {
  local distro="${1:-$(tnx_distro)}" phase="${2:-}" dir file tmp
  [[ "$phase" =~ ^[a-z][a-z0-9_]*$ ]] || return 2
  dir="$(tnx_distro_state_dir "$distro")" || return 2
  mkdir -p "$dir" || return 1
  file="$dir/phases"
  tnx_distro_phase_done "$distro" "$phase" && return 0
  tmp="$dir/.phases.tmp.$$"
  { [ ! -f "$file" ] || cat "$file"; printf 'phase_%s\n' "$phase"; } > "$tmp" || { rm -f "$tmp"; return 1; }
  chmod 0600 "$tmp" && mv -f "$tmp" "$file"
}

tnx_install_phase_done() {
  local phase="${1#phase_}" distro="${2:-$(tnx_distro)}"
  case "$phase" in
    preflight|packages|cli) tnx_state_done "phase_$phase" ;;
    *) tnx_distro_phase_done "$distro" "$phase" ;;
  esac
}

tnx_install_phase_mark() {
  local phase="${1#phase_}" distro="${2:-$(tnx_distro)}"
  tnx_state_mark "phase_$phase" || return 1
  case "$phase" in
    preflight|packages|cli) return 0 ;;
    *) tnx_distro_phase_mark "$distro" "$phase" ;;
  esac
}

tnx_state_clear() {
  rm -rf "$TERNUX_STATE_DIR"
  rm -f "$TERNUX_LEGACY_STATE"
  tnx_state_init
}

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
tnx_log() {
  local level="$1" msg="$2"
  if mkdir -p "$TERNUX_LOG_DIR" 2>/dev/null; then
    printf '%s [%s] %s\n' "$(__tnx_ts)" "$level" "$msg" >> "$TERNUX_LOG_FILE" 2>/dev/null || true
  fi
}

tnx_log_info()  { tnx_log "INFO" "$1"; }
tnx_log_warn()  { tnx_log "WARN" "$1"; }
tnx_log_error() { tnx_log "ERROR" "$1"; }

# ---------------------------------------------------------------------------
# Utility: confirm action
# ---------------------------------------------------------------------------
tnx_confirm() {
  [ "${TERNUX_YES:-0}" = "1" ] && return 0
  [ -t 0 ] || { tnx_info "$1 -> y (non-interactive)"; return 0; }
  local a default="${2:-no}" prompt="[y/N]"
  [ "$default" = "yes" ] && prompt="[Y/n]"
  read -r -p "${TNX_CC}?${TNX_C0} $1 $prompt: " a || return 1
  if [ "$default" = "yes" ] && [ -z "$a" ]; then return 0; fi
  case "$a" in [Yy]|[Yy][Ee][Ss]) return 0 ;; *) return 1 ;; esac
}

# ---------------------------------------------------------------------------
# Initialise environment on source
# ---------------------------------------------------------------------------
tnx_state_init

# Persist the Debian account selected by `--user` so every later CLI command
# (doctor, verify, benchmark, repair) targets the same account.
if [ -z "${TERNUX_USER:-}" ]; then
  TERNUX_USER="$(tnx_state_get "user" 2>/dev/null || true)"
fi
TERNUX_USER="${TERNUX_USER:-ternux}"
export TERNUX_USER
