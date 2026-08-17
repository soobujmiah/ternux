# =============================================================================
#  ternux — installer UI
#  Persistent framed log, color, progress, banners, and readable fallbacks.
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah) — MIT License
#  https://github.com/soobujmiah/ternux
# =============================================================================

# shellcheck source=lib/core.sh
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"

_TNX_UI_LOADED=1
_TNX_SIG_NAME="Sobuj Miah"
_TNX_SIG_COLORS=("$TNX_CG" "$TNX_CC" "$TNX_CY" "$TNX_CM" "$TNX_CB" "$TNX_CW")
_TNX_FRAME_ACTIVE=0
_TNX_FRAME_MODE="off"

_tnx_sig() {
  local tick="${1:-0}" n=${#_TNX_SIG_NAME}
  local i phase ch
  phase=$((tick % 6))
  for ((i=0; i<n; i++)); do
    ch="${_TNX_SIG_NAME:$i:1}"
    [ "$ch" = " " ] && printf ' ' || printf '%s%s%s' "${_TNX_SIG_COLORS[$(((i+phase)%6))]}" "$ch" "$TNX_C0"
  done
}

_tnx_repeat() {
  local char="$1" count="$2" out="" i
  for ((i=0; i<count; i++)); do out+="$char"; done
  printf '%s' "$out"
}

_tnx_strip_controls() {
  local text="${1//$'\r'/}" match=""
  while [[ "$text" =~ $'\033'\[[0-9\;\?]*[[:alpha:]] ]]; do
    match="${BASH_REMATCH[0]}"
    text="${text//$match/}"
  done
  # Erase-line and a few package-manager sequences can use a non-letter final.
  while [[ "$text" =~ $'\033'\[[0-9\;\?]*[@-~] ]]; do
    match="${BASH_REMATCH[0]}"
    text="${text//$match/}"
  done
  printf '%s' "$text"
}

_tnx_frame_line_color() {
  local lower="${1,,}"
  case "$lower" in
    *fatal*|*fail*|*error:*|*"error "*|*failed*) printf '%s' "$TNX_CR" ;;
    *warn*|*warning*|*"held back"*)              printf '%s' "$TNX_CY" ;;
    *"[ ok ]"*|*"setting up"*|*installed*|*fetched*|*complete*) printf '%s' "$TNX_CG" ;;
    get:*|hit:*|*download*|*unpack*|*package*)    printf '%s' "$TNX_CC" ;;
    *task*|*phase*)                               printf '%s' "$TNX_CM" ;;
    *)                                            printf '%s' "$TNX_CW" ;;
  esac
}

_tnx_frame_draw_dashboard() {
  [ "${_TNX_FRAME_MODE:-off}" = "dashboard" ] || return 0
  local state="${1:-RUNNING}" cols="$_TNX_FRAME_COLS" inner=$((_TNX_FRAME_COLS - 4))
  local rule title identity phase footer state_color="$TNX_CC"
  [ "$state" = "COMPLETE" ] && state_color="$TNX_CG"
  [ "$state" = "FAILED" ] && state_color="$TNX_CR"

  rule="$(_tnx_repeat '─' "$((_TNX_FRAME_COLS - 2))")"
  title="ternux v${TERNUX_VERSION}  •  ONE-CLICK INSTALLER"
  identity="by ${_TNX_SIG_NAME}  •  base ~3–4 GB  •  complete ~10–12 GB"
  phase="${state}  [${_TNX_FRAME_CUR}/${_TNX_FRAME_TOTAL}]  ${_TNX_FRAME_TITLE}"
  footer="live log  •  ${TERNUX_LOG_FILE}"

  printf '\0337\033[r'
  printf '\033[1;1H%s┌%s┐%s' "$TNX_CM" "$rule" "$TNX_C0"
  printf '\033[2;1H%s│%s %s%-*.*s%s %s│%s' "$TNX_CM" "$TNX_C0" "$TNX_CW" "$inner" "$inner" "$title" "$TNX_C0" "$TNX_CM" "$TNX_C0"
  printf '\033[3;1H%s│%s %s%-*.*s%s %s│%s' "$TNX_CM" "$TNX_C0" "$TNX_CG" "$inner" "$inner" "$identity" "$TNX_C0" "$TNX_CM" "$TNX_C0"
  printf '\033[4;1H%s│%s %s%-*.*s%s %s│%s' "$TNX_CM" "$TNX_C0" "$state_color" "$inner" "$inner" "$phase" "$TNX_C0" "$TNX_CM" "$TNX_C0"
  printf '\033[5;1H%s├%s┤%s' "$TNX_CM" "$rule" "$TNX_C0"
  printf '\033[%d;1H%s├%s┤%s' "$((_TNX_FRAME_ROWS - 2))" "$TNX_CM" "$rule" "$TNX_C0"
  printf '\033[%d;1H%s│%s %s%-*.*s%s %s│%s' "$((_TNX_FRAME_ROWS - 1))" "$TNX_CM" "$TNX_C0" "$TNX_CD" "$inner" "$inner" "$footer" "$TNX_C0" "$TNX_CM" "$TNX_C0"
  printf '\033[%d;1H%s└%s┘%s' "$_TNX_FRAME_ROWS" "$TNX_CM" "$rule" "$TNX_C0"
  printf '\033[6;%dr\0338' "$((_TNX_FRAME_ROWS - 3))"
}

# Open one persistent frame after confirmation and keep it until the final
# status. Full-screen scroll regions are used only on capable interactive
# terminals; every other environment gets an append-only framed stream.
tnx_frame_open() {
  local total="${1:-11}" backend="${2:-auto}" user_name="${3:-ternux}" profile="${4:-base}"
  if [ "${TERNUX_QUIET:-0}" = "1" ] || [ "${TERNUX_JSON:-0}" = "1" ]; then
    _TNX_FRAME_ACTIVE=0; _TNX_FRAME_MODE="off"
    export _TNX_FRAME_ACTIVE _TNX_FRAME_MODE
    return 0
  fi

  mkdir -p "$TERNUX_LOG_DIR" 2>/dev/null || true
  : >> "$TERNUX_LOG_FILE" 2>/dev/null || true
  _TNX_FRAME_TOTAL="$total"
  _TNX_FRAME_CUR=0
  _TNX_FRAME_TITLE="Preparing installation"
  _TNX_FRAME_BACKEND="$backend"
  _TNX_FRAME_USER="$user_name"
  _TNX_FRAME_PROFILE="$profile"
  _TNX_FRAME_ACTIVE=1
  _TNX_FRAME_MODE="plain"

  if [ -t 1 ] && [ -n "$TNX_C0" ] && [ "${TERNUX_NO_ANIM:-0}" != "1" ]; then
    _TNX_FRAME_COLS="$(tput cols 2>/dev/null || echo 80)"
    _TNX_FRAME_ROWS="$(tput lines 2>/dev/null || echo 24)"
    case "$_TNX_FRAME_COLS:$_TNX_FRAME_ROWS" in *[!0-9:]*|:*) _TNX_FRAME_COLS=80; _TNX_FRAME_ROWS=24 ;; esac
    [ "$_TNX_FRAME_COLS" -gt 100 ] && _TNX_FRAME_COLS=100
    if [ "$_TNX_FRAME_COLS" -ge 58 ] && [ "$_TNX_FRAME_ROWS" -ge 16 ]; then
      _TNX_FRAME_MODE="dashboard"
    fi
  fi

  export _TNX_FRAME_ACTIVE _TNX_FRAME_MODE _TNX_FRAME_TOTAL _TNX_FRAME_CUR
  export _TNX_FRAME_TITLE _TNX_FRAME_BACKEND _TNX_FRAME_USER _TNX_FRAME_PROFILE
  export _TNX_FRAME_COLS="${_TNX_FRAME_COLS:-80}" _TNX_FRAME_ROWS="${_TNX_FRAME_ROWS:-24}"

  tnx_log_info "Installation frame opened: backend=$backend user=$user_name profile=$profile"
  if [ "$_TNX_FRAME_MODE" = "dashboard" ]; then
    printf '\033[?25l\033[2J\033[H'
    _tnx_frame_draw_dashboard "RUNNING"
    printf '\033[6;1H'
  else
    local rule="$(_tnx_repeat '─' 70)"
    printf '%s┌%s┐%s\n' "$TNX_CM" "$rule" "$TNX_C0"
    printf '%s│%s %st e r n u x  •  one-click installer%s\n' "$TNX_CM" "$TNX_CG" "$TNX_CW" "$TNX_C0"
    printf '%s│%s by %s%s%s  •  base ~3–4 GB  •  complete ~10–12 GB\n' "$TNX_CM" "$TNX_C0" "$TNX_CG" "$_TNX_SIG_NAME" "$TNX_C0"
    printf '%s├%s┤%s\n' "$TNX_CM" "$rule" "$TNX_C0"
  fi
}

# Update the fixed phase line in dashboard mode, or print a colored separator
# in append-only mode.
tnx_frame_phase() {
  local cur="$1" total="$2" title="$3"
  _TNX_FRAME_CUR="$cur"; _TNX_FRAME_TOTAL="$total"; _TNX_FRAME_TITLE="$title"
  export _TNX_FRAME_CUR _TNX_FRAME_TOTAL _TNX_FRAME_TITLE
  tnx_log_info "Phase $cur/$total: $title"

  if [ "${_TNX_FRAME_MODE:-off}" = "dashboard" ]; then
    _tnx_frame_draw_dashboard "RUNNING"
  elif [ "${_TNX_FRAME_MODE:-off}" = "plain" ]; then
    printf '%s│%s %s[%s/%s]%s %s%s%s\n' "$TNX_CM" "$TNX_C0" "$TNX_CC" "$cur" "$total" "$TNX_C0" "$TNX_CG" "$title" "$TNX_C0"
  else
    tnx_phase_header "$cur" "$total" "$title"
  fi
}

# Consume a command/phase stream, normalize CR progress updates to one record,
# retain every visible line in the install log, and color by severity/activity.
tnx_frame_stream() {
  local line="" clean="" color="" inner=76
  [ "${_TNX_FRAME_MODE:-off}" = "off" ] && { cat; return; }
  [ "${_TNX_FRAME_MODE:-off}" = "dashboard" ] && inner=$((_TNX_FRAME_COLS - 4))

  # Package managers often rewrite one progress row with carriage returns.
  # Turn each visible update into a real line so the frame and log never merge
  # several status messages into one unreadable record.
  while IFS= read -r line || [ -n "$line" ]; do
    clean="$(_tnx_strip_controls "$line")"
    printf '%s\n' "$clean" >> "$TERNUX_LOG_FILE" 2>/dev/null || true
    color="$(_tnx_frame_line_color "$clean")"
    if [ "$_TNX_FRAME_MODE" = "dashboard" ]; then
      printf '\r\033[K%s│%s %s%-*.*s%s %s│%s\n' \
        "$TNX_CM" "$TNX_C0" "$color" "$inner" "$inner" "$clean" "$TNX_C0" "$TNX_CM" "$TNX_C0"
    else
      printf '%s│%s %s%s%s\n' "$TNX_CM" "$TNX_C0" "$color" "$clean" "$TNX_C0"
    fi
  done < <(tr '\r' '\n')
}

# Restore terminal state even when called by a signal/EXIT trap.
tnx_frame_restore_terminal() {
  if [ "${_TNX_FRAME_MODE:-off}" = "dashboard" ]; then
    printf '\033[r\033[?25h' 2>/dev/null || true
  fi
}

tnx_frame_close() {
  local status="${1:-failed}" failed_cur="${2:-${_TNX_FRAME_CUR:-0}}"
  local failed_title="${3:-${_TNX_FRAME_TITLE:-installation phase}}" state="FAILED"
  [ "$status" = "success" ] && state="COMPLETE"
  tnx_log_info "Installation frame closed: $status"

  if [ "${_TNX_FRAME_MODE:-off}" = "dashboard" ]; then
    if [ "$status" = "success" ]; then
      _TNX_FRAME_TITLE="Installation complete"
      _TNX_FRAME_CUR="$_TNX_FRAME_TOTAL"
    else
      _TNX_FRAME_TITLE="Failed: $failed_title"
      _TNX_FRAME_CUR="$failed_cur"
    fi
    export _TNX_FRAME_TITLE _TNX_FRAME_CUR
    _tnx_frame_draw_dashboard "$state"
    tnx_frame_restore_terminal
    printf '\033[%d;1H\n' "$_TNX_FRAME_ROWS"
  elif [ "${_TNX_FRAME_MODE:-off}" = "plain" ]; then
    local rule="$(_tnx_repeat '─' 70)" color="$TNX_CR"
    [ "$status" = "success" ] && color="$TNX_CG"
    printf '%s│%s %sInstallation %s%s\n' "$TNX_CM" "$TNX_C0" "$color" "$status" "$TNX_C0"
    printf '%s└%s┘%s\n' "$TNX_CM" "$rule" "$TNX_C0"
  fi
  _TNX_FRAME_ACTIVE=0
  _TNX_FRAME_MODE="off"
  export _TNX_FRAME_ACTIVE _TNX_FRAME_MODE
}

# ── Banner -----------------------------------------------------------------
tnx_banner() {
  [ "${TERNUX_QUIET:-0}" = "1" ] && return 0
  if [ ! -t 1 ] || [ -z "$TNX_C0" ] || [ "${TERNUX_NO_ANIM:-0}" = "1" ]; then
    printf '%sternux v%s%s — Linux desktop for Android\n' "$TNX_CG" "$TERNUX_VERSION" "$TNX_C0"
    printf 'Zink and VirGL graphics routes • by %s\n%s\n\n' "$_TNX_SIG_NAME" "$TERNUX_REPO"
    return 0
  fi

  local rows=(
    "  _______ ______ _____  _   _ _    ___   __"
    " |__   __|  ____|  __ \\| \\ | | |  | \\ \\ / /"
    "    | |  | |__  | |__) |  \\| | |  | |\\ V /"
    '    | |  |  __| |  _  /| . \` | |  | | > <'
    "    | |  | |____| | \\ \\| |\\  | |__| |/ . \\\\"
    "    |_|  |______|_|  \\_\\_| \\_|\\____//_/ \\_\\\\"
  )
  local charset="░▒▓#%&*+=<>/|01" i j pass len ch out
  for pass in 1 2 3; do
    for i in 0 1 2 3 4 5; do
      printf '\033[1;38;5;%dm' "$((34 + i * 3))"
      len=${#rows[$i]}; out=""
      for ((j=0; j<len; j++)); do
        ch="${rows[$i]:$j:1}"
        [ "$ch" = " " ] && { out+=" "; continue; }
        if [ "$pass" -eq 3 ] || [ $((RANDOM % (4 - pass))) -eq 0 ]; then out+="$ch"
        else out+="${charset:$((RANDOM % ${#charset})):1}"; fi
      done
      printf '%s%s\n' "$out" "$TNX_C0"
    done
    [ "$pass" -lt 3 ] && { sleep 0.07; printf '\033[6A'; }
  done
  printf '  %sLinux desktop for Android with Zink and VirGL graphics routes%s\n' "$TNX_CG" "$TNX_C0"
  printf '  %sv%s · by %s%s%s · MIT%s\n\n' "$TNX_CD" "$TERNUX_VERSION" "$TNX_C0" "$(_tnx_sig 0)" "$TNX_CD" "$TNX_C0"
}

# ── Phase header used when no install frame is active ----------------------
tnx_phase_header() {
  [ "${TERNUX_QUIET:-0}" = "1" ] && return 0
  local num="${1:-?}" total="${2:-?}" title="$3"
  printf '\n  %s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n' "$TNX_CM" "$TNX_C0"
  printf '  %s[%s/%s]%s  %s%s%s\n' "$TNX_CW" "$num" "$total" "$TNX_C0" "$TNX_CG" "$title" "$TNX_C0"
  printf '  %s──────────────────────────────%s\n' "$TNX_CD" "$TNX_C0"
}

# Commands are intentionally foregrounded: output is never discarded behind
# a spinner, so package-manager failures remain visible and logged by the frame.
tnx_spin_run() {
  local label="$1"; shift
  local rc=0
  printf '%s[TASK]%s %s%s%s\n' "$TNX_CM" "$TNX_C0" "$TNX_CC" "$label" "$TNX_C0"
  "$@" 2>&1; rc=$?
  if [ "$rc" -eq 0 ]; then
    printf '%s[DONE]%s %s\n' "$TNX_CG" "$TNX_C0" "$label"
  else
    printf '%s[FAIL]%s %s (status %s)\n' "$TNX_CR" "$TNX_C0" "$label" "$rc"
  fi
  return "$rc"
}

# ── Phase checklist --------------------------------------------------------
tnx_phase_checklist() {
  [ "${TERNUX_QUIET:-0}" = "1" ] && return 0
  local phases=("$@") short=("pre" "pkg" "cli" "deb" "gpu" "aud" "lnc" "als" "ext" "phm" "ver")
  local i mark out=""
  for i in "${!phases[@]}"; do
    if tnx_state_done "phase_${phases[$i]}" 2>/dev/null; then mark="${TNX_CG}✓${TNX_C0}"
    else mark="${TNX_CD}·${TNX_C0}"; fi
    out+="${TNX_CD}${short[$i]:-$i}${TNX_C0}${mark}  "
  done
  printf '  %s\n' "$out"
}

# ── Summary box ------------------------------------------------------------
tnx_summary_box() {
  [ "${TERNUX_QUIET:-0}" = "1" ] && return 0
  local title="$1"; shift
  local pairs=("$@") w=52 i k v row
  printf '\n  %s┌%s┐%s\n' "$TNX_CM" "$(_tnx_repeat '─' "$w")" "$TNX_C0"
  printf -v row '%-*.*s' "$((w - 2))" "$((w - 2))" "$title"
  printf '  %s│%s %s%s%s %s│%s\n' "$TNX_CM" "$TNX_C0" "$TNX_CG" "$row" "$TNX_C0" "$TNX_CM" "$TNX_C0"
  printf '  %s├%s┤%s\n' "$TNX_CM" "$(_tnx_repeat '─' "$w")" "$TNX_C0"
  for ((i=0; i<${#pairs[@]}; i+=2)); do
    k="${pairs[$i]}"; v="${pairs[$((i+1))]}"
    printf -v row '%-16s %-*.*s' "$k:" "$((w - 19))" "$((w - 19))" "$v"
    printf '  %s│%s %s%-*.*s%s %s│%s\n' "$TNX_CM" "$TNX_C0" "$TNX_CW" "$((w - 2))" "$((w - 2))" "$row" "$TNX_C0" "$TNX_CM" "$TNX_C0"
  done
  printf '  %s└%s┘%s\n' "$TNX_CM" "$(_tnx_repeat '─' "$w")" "$TNX_C0"
}

tnx_celebrate() {
  [ "${TERNUX_QUIET:-0}" = "1" ] && return 0
  printf '\n  %s▐▓▒░ %sI N S T A L L   C O M P L E T E%s ░▒▓▌%s\n' "$TNX_CG" "$TNX_CW" "$TNX_CG" "$TNX_C0"
  printf '  %sdesktop · GPU · audio · host CLI · guest companion verified%s\n' "$TNX_CD" "$TNX_C0"
  printf '  %sbuilt with ♥ by %s%s%s\n' "$TNX_CD" "$TNX_C0" "$(_tnx_sig 0)" "$TNX_C0"
}

tnx_next_steps() {
  [ "${TERNUX_QUIET:-0}" = "1" ] && return 0
  local steps=("$@") i
  printf '\n%sNext steps%s\n' "$TNX_CW" "$TNX_C0"
  for i in "${!steps[@]}"; do
    printf '  %s%d.%s %s\n' "$TNX_CC" "$((i+1))" "$TNX_C0" "${steps[$i]}"
  done
  echo ""
}
