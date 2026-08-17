# =============================================================================
#  ternux — core library
#  Shared utilities, I/O helpers, version info, and JSON/CLI framework.
#  Every other library sources this first.
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah) — MIT License
#  https://github.com/soobujmiah/ternux
# =============================================================================

TERNUX_VERSION="1.3.1"
TERNUX_NAME="ternux"
TERNUX_DESC="Linux desktop for Android with Zink and VirGL graphics routes"
TERNUX_REPO="https://github.com/soobujmiah/ternux"
TERNUX_STATE_DIR="${TERNUX_STATE_DIR:-$HOME/.local/share/ternux}"
TERNUX_LOG_DIR="${TERNUX_LOG_DIR:-${TMPDIR:-/data/data/com.termux/files/usr/tmp}/ternux}"
TERNUX_LOG_FILE="$TERNUX_LOG_DIR/ternux.log"

# Legacy state file (from older versions) — used as fallback
TERNUX_LEGACY_STATE="$HOME/.ternux-state"

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

tnx_debian_installed() { tnx_proot_container_installed debian; }

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
  if grep -qs "^${key}=" "$TERNUX_STATE_DIR/state" 2>/dev/null; then
    sed -i "s/^${key}=.*/${key}=${val}/" "$TERNUX_STATE_DIR/state"
  else
    echo "${key}=${val}" >> "$TERNUX_STATE_DIR/state"
  fi
}

tnx_state_done() {
  local phase="$1"
  [ -f "$TERNUX_STATE_DIR/phases" ] && grep -qsx "$phase" "$TERNUX_STATE_DIR/phases"
}

tnx_state_mark() {
  local phase="$1"
  tnx_state_done "$phase" || echo "$phase" >> "$TERNUX_STATE_DIR/phases"
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
  local a
  read -r -p "${TNX_CC}?${TNX_C0} $1 [y/N]: " a || return 1
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