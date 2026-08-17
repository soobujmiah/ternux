# =============================================================================
#  ternux — installer UI
#  Persistent framed dashboard: device panel, fixed step progress bar, a
#  framed live log, and an animated footer.
#
#  Stability rules (learned the hard way on Android terminals):
#    1. The frame is built ONLY from ASCII characters. Box-drawing, block,
#       braille, bullet and middle-dot glyphs are "ambiguous width" and render
#       two cells wide at normal zoom on many Android fonts/locales, which
#       breaks every width calculation and makes borders overlap the log.
#    2. Exactly one process writes to the terminal. The spinner and resize
#       detection are driven inline from the stream loop (via `read -t`), never
#       from a background subshell that races the main cursor.
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah) — MIT License
#  https://github.com/soobujmiah/ternux
# =============================================================================

# shellcheck source=lib/core.sh
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"
# Device information for the dashboard's hardware panel.
# shellcheck source=lib/detect.sh
. "$(dirname "${BASH_SOURCE[0]}")/detect.sh"

_TNX_UI_LOADED=1
_TNX_SIG_NAME="Sobuj Miah"
_TNX_SIG_COLORS=("$TNX_CG" "$TNX_CC" "$TNX_CY" "$TNX_CM" "$TNX_CB" "$TNX_CW")
_TNX_FRAME_ACTIVE=0
_TNX_FRAME_MODE="off"

# Frame geometry and animation state.
_TNX_FRAME_COLS=80
_TNX_FRAME_ROWS=24
_TNX_FRAME_TOTAL=11
_TNX_FRAME_CUR=0
_TNX_FRAME_TITLE="Preparing installation"
_TNX_FRAME_BACKEND="auto"
_TNX_FRAME_TICK=0
# Layout row indices (computed from the current terminal size).
_TNX_LY_TITLE=2; _TNX_LY_IDENT=3; _TNX_LY_DEV0=5; _TNX_LY_DEV_ON=1
_TNX_LY_PROG=8; _TNX_LY_DIV2=9; _TNX_LY_LOGTOP=10
_TNX_LY_LOGBOT=21; _TNX_LY_DIV3=22; _TNX_LY_FOOTER=23; _TNX_LY_BOT=24
# Device panel content.
_TNX_FRAME_DEV_LABELS=()
_TNX_FRAME_DEV_VALUES=()

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
  while [[ "$text" =~ $'\033'\[[0-9\;?]*[[:alpha:]] ]]; do
    match="${BASH_REMATCH[0]}"
    text="${text//$match/}"
  done
  # Erase-line and a few package-manager sequences can use a non-letter final.
  while [[ "$text" =~ $'\033'\[[0-9\;?]*[@-~] ]]; do
    match="${BASH_REMATCH[0]}"
    text="${text//$match/}"
  done
  printf '%s' "$text"
}

# Clip a control-free string to at most $2 cells, ellipsizing with a plain "~"
# when truncated. The frame itself is ASCII, but package output and device
# values can carry arbitrary Unicode; the 2-cell clip slack absorbs occasional
# ambiguous-width characters so lines never wrap past the right border.
_tnx_clip() {
  local s="$1" max="${2:-76}"
  [ "$max" -lt 3 ] && max=3
  local n=${#s}
  if [ "$n" -le "$max" ]; then
    printf '%s' "$s"
    return 0
  fi
  local out="" i=0 ch code cw w=0 limit=$((max - 1))
  case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in
    *[Uu][Tt][Ff]-8*|*[Uu][Tt][Ff]8*)
      while [ "$i" -lt "$n" ] && [ "$w" -lt "$limit" ]; do
        ch="${s:i:1}"
        printf -v code '%d' "'$ch" 2>/dev/null || code=0
        cw=1
        (( code > 11903 )) && cw=2
        (( w + cw > limit )) && break
        out+="$ch"; w=$((w + cw)); i=$((i + 1))
      done
      ;;
    *)
      out="${s:0:$limit}"; i=$limit
      ;;
  esac
  [ "$i" -lt "$n" ] && printf '%s~' "$out" || printf '%s' "$out"
}

# Recompute terminal size (clamped). Called on open, repaint and by the stream
# loop's resize checks.
_tnx_term_size() {
  local cols=0 rows=0
  if [ -t 1 ]; then
    cols="$(tput cols 2>/dev/null || echo 0)"
    rows="$(tput lines 2>/dev/null || echo 0)"
  fi
  case "$cols:$rows" in *[!0-9:]*|:*) cols=0; rows=0 ;; esac
  [ "${cols:-0}" -ge 20 ] || cols=80
  [ "${rows:-0}" -ge 8 ] || rows=24
  [ "$cols" -gt 160 ] && cols=160
  [ "$rows" -gt 100 ] && rows=100
  _TNX_FRAME_COLS="$cols"
  _TNX_FRAME_ROWS="$rows"
}

# Width for the append-only "plain" frame (no full-screen control), clamped so
# the frame never overflows a narrow terminal. Stores it in _TNX_FRAME_COLS.
_tnx_plain_cols() {
  local cols=80
  if [ -t 1 ]; then cols="$(tput cols 2>/dev/null || echo 80)"; fi
  case "$cols" in *[!0-9]*) cols=80 ;; esac
  [ "$cols" -gt 80 ] && cols=80
  [ "$cols" -lt 24 ] && cols=24
  _TNX_FRAME_COLS="$cols"
  printf '%s' "$cols"
}

# Compute fixed row indices for the current terminal size. Full layout includes
# the device panel; a short/narrow viewport drops it.
_tnx_frame_layout() {
  local R="$_TNX_FRAME_ROWS" C="$_TNX_FRAME_COLS"
  _TNX_LY_DEV_ON=0
  if [ "$R" -ge 17 ] && [ "$C" -ge 44 ]; then
    _TNX_LY_DEV_ON=1
    _TNX_LY_TITLE=2; _TNX_LY_IDENT=3
    _TNX_LY_DEV0=5
    _TNX_LY_PROG=8; _TNX_LY_DIV2=9; _TNX_LY_LOGTOP=10
  else
    _TNX_LY_TITLE=2; _TNX_LY_IDENT=3
    _TNX_LY_DEV0=0
    _TNX_LY_PROG=5; _TNX_LY_DIV2=6; _TNX_LY_LOGTOP=7
  fi
  _TNX_LY_LOGBOT=$((R - 3))
  _TNX_LY_DIV3=$((R - 2))
  _TNX_LY_FOOTER=$((R - 1))
  _TNX_LY_BOT=$R
}

# Snapshot the hardware/software profile shown in the device panel. Values may
# contain non-ASCII (from getprop), so they are clipped with slack at paint
# time.
_tnx_frame_gather_device() {
  local model android sdk arch gpu vulkan ram storage backend
  model="$(tnx_detect_model 2>/dev/null || echo '?')";    model="${model:-unknown}"
  android="$(tnx_detect_android_version 2>/dev/null || echo '?')"; android="${android:-?}"
  sdk="$(tnx_detect_android_sdk 2>/dev/null || echo '?')"; sdk="${sdk:-?}"
  arch="$(tnx_detect_arch 2>/dev/null || echo '?')";      arch="${arch:-?}"
  gpu="$(tnx_detect_gpu 2>/dev/null || echo 'unknown')";  gpu="${gpu:-unknown}"
  vulkan="$(tnx_detect_vulkan 2>/dev/null || echo '?')";  vulkan="${vulkan:-?}"
  ram="$(tnx_detect_ram_gb 2>/dev/null || echo '?')";     ram="${ram:-?}"
  storage="$(tnx_detect_storage_gb 2>/dev/null || echo '?')"; storage="${storage:-?}"
  backend="${_TNX_FRAME_BACKEND:-auto}"
  _TNX_FRAME_DEV_LABELS=("Device" "Graphics" "Memory")
  _TNX_FRAME_DEV_VALUES=(
    "${model} - Android ${android} (SDK ${sdk})"
    "${gpu} - backend ${backend} - Vulkan ${vulkan}"
    "${ram} GB RAM - ${storage} GB free - ${arch}"
  )
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

# ── Static painters (absolute positioning; save/restore cursor) -------------

# Wrap pre-built content (exactly `inner` visible cells wide, colors allowed)
# in the left/right borders and paint it at an absolute row.
_tnx_frame_box_row() {
  local row="$1" content="$2"
  printf '\0337\033[%d;1H\033[K%s|%s %s %s|%s\0338' "$row" "$TNX_CM" "$TNX_C0" "$content" "$TNX_CM" "$TNX_C0"
}

# A full-width horizontal rule of ASCII "=" (unambiguous width).
_tnx_frame_rule() {
  _tnx_repeat '=' "$((_TNX_FRAME_COLS - 2))"
}

_tnx_frame_paint_header() {
  local inner=$((_TNX_FRAME_COLS - 4)) content=""
  local title; title="$(_tnx_clip "ternux v${TERNUX_VERSION} - ONE-CLICK INSTALLER" "$inner")"
  local tlen=${#title}
  local tpad=$(( (inner - tlen) / 2 )); [ "$tpad" -lt 0 ] && tpad=0
  local trpad=$(( inner - tlen - tpad )); [ "$trpad" -lt 0 ] && trpad=0
  local tsp trsp
  tsp="$(_tnx_repeat ' ' "$tpad")"; trsp="$(_tnx_repeat ' ' "$trpad")"
  printf -v content '%s%s%s%s%s' "$tsp" "$TNX_CG" "$title" "$TNX_C0" "$trsp"
  _tnx_frame_box_row "$_TNX_LY_TITLE" "$content"

  local pre="by " post="  -  base ~3-4 GB  -  complete ~10-12 GB"
  local fixed=$(( ${#pre} + 10 ))
  local postmax=$(( inner - fixed )); [ "$postmax" -lt 3 ] && postmax=3
  local postc; postc="$(_tnx_clip "$post" "$postmax")"
  local ipad=$(( inner - fixed - ${#postc} )); [ "$ipad" -lt 0 ] && ipad=0
  local isp; isp="$(_tnx_repeat ' ' "$ipad")"
  printf -v content '%s%s%s%s%s%s%s%s' "$TNX_CD" "$pre" "$TNX_C0" "$(_tnx_sig 0)" "$TNX_CD" "$postc" "$isp" "$TNX_C0"
  _tnx_frame_box_row "$_TNX_LY_IDENT" "$content"
}

_tnx_frame_paint_device() {
  local i row label value vc pad spaces content inner=$((_TNX_FRAME_COLS - 4))
  for i in 0 1 2; do
    row=$((_TNX_LY_DEV0 + i))
    label="${_TNX_FRAME_DEV_LABELS[$i]:-}"
    value="${_TNX_FRAME_DEV_VALUES[$i]:-}"
    vc="$(_tnx_clip "$value" "$((inner - 12))")"
    pad=$(( inner - 12 - ${#vc} )); [ "$pad" -lt 0 ] && pad=0
    spaces="$(_tnx_repeat ' ' "$pad")"
    printf -v content '%s%-9s%s %s%s%s' "$TNX_CC" "$label" "$TNX_C0" "$TNX_CW" "$vc" "$spaces"
    _tnx_frame_box_row "$row" "$content"
  done
}

_tnx_frame_paint_progress() {
  local sc="${1:-$TNX_CC}" inner=$((_TNX_FRAME_COLS - 4)) row="${_TNX_LY_PROG:-8}"
  local cur="${_TNX_FRAME_CUR:-0}" total="${_TNX_FRAME_TOTAL:-1}" title="${_TNX_FRAME_TITLE:-}"
  [ "$total" -le 0 ] && total=1
  local barw=18
  [ "$inner" -lt 44 ] && barw=12
  local filled empty
  filled=$(( cur * barw / total ))
  empty=$(( barw - filled ))
  local bar="" i
  for ((i=0;i<filled;i++)); do bar+="#"; done
  for ((i=0;i<empty;i++)); do bar+="-"; done
  local cnt="${cur}/${total}"
  local fixed=$(( 6 + ${#cnt} + 2 + barw + 2 ))
  local titlemax=$(( inner - fixed )); [ "$titlemax" -lt 1 ] && titlemax=1
  local ttitle; ttitle="$(_tnx_clip "$title" "$titlemax")"
  local pad=$(( inner - fixed - ${#ttitle} )); [ "$pad" -lt 0 ] && pad=0
  local spaces; spaces="$(_tnx_repeat ' ' "$pad")"
  local content=""
  printf -v content '%sSTEPS %s%s%s%s  %s%s%s%s  %s%s%s' \
    "$TNX_CW" "$TNX_CC" "$cnt" "$TNX_C0" "$TNX_CW" "$sc" "$bar" "$TNX_C0" "$TNX_CG" "$ttitle" "$spaces"
  _tnx_frame_box_row "$row" "$content"
}

_tnx_frame_paint_footer() {
  local tick="${1:-0}" inner=$((_TNX_FRAME_COLS - 4)) row="${_TNX_LY_FOOTER:-$((_TNX_FRAME_ROWS - 1))}"
  local sp spc
  sp='|/-\'
  spc="${sp:$((tick % 4)):1}"
  local pre="(c) 2026 " post=" - ${TERNUX_REPO#https://} - MIT"
  local fixed=$(( ${#pre} + 10 ))
  local postmax=$(( inner - fixed - 1 )); [ "$postmax" -lt 3 ] && postmax=3
  local postc; postc="$(_tnx_clip "$post" "$postmax")"
  local pad=$(( inner - fixed - ${#postc} - 1 )); [ "$pad" -lt 0 ] && pad=0
  local spaces; spaces="$(_tnx_repeat ' ' "$pad")"
  local content=""
  printf -v content '%s%s%s%s%s%s%s%s' \
    "$TNX_CD" "$pre" "$TNX_C0" "$(_tnx_sig "$tick")" "$TNX_CD" "$postc" "$spaces" "$spc"
  _tnx_frame_box_row "$row" "$content"
}

# Paint one already-cleaned log line into the scroll region. Clipped with
# slack so non-ASCII package output never overflows the right border.
_tnx_frame_paint_logline() {
  local clean="$1" inner=$((_TNX_FRAME_COLS - 4))
  local clipped; clipped="$(_tnx_clip "$clean" "$((inner - 2))")"
  local pad=$(( inner - ${#clipped} )); [ "$pad" -lt 0 ] && pad=0
  local spaces; spaces="$(_tnx_repeat ' ' "$pad")"
  local color; color="$(_tnx_frame_line_color "$clean")"
  printf '\r\033[K%s|%s %s%s%s%s %s|%s\n' \
    "$TNX_CM" "$TNX_C0" "$color" "$clipped" "$spaces" "$TNX_C0" "$TNX_CM" "$TNX_C0"
}

# Repaint the log region from the on-disk log so a resize never loses content.
_tnx_frame_repaint_log() {
  local n=$(( _TNX_LY_LOGBOT - _TNX_LY_LOGTOP + 1 ))
  printf '\033[%d;1H' "$_TNX_LY_LOGTOP"
  [ -f "$TERNUX_LOG_FILE" ] || return 0
  tail -n "$n" "$TERNUX_LOG_FILE" 2>/dev/null | while IFS= read -r ln; do
    _tnx_frame_paint_logline "$ln"
  done
}

# Full dashboard repaint: clear, chrome, scroll region, log tail, cursor.
_tnx_frame_draw_dashboard() {
  [ "${_TNX_FRAME_MODE:-off}" = "dashboard" ] || return 0
  local state="${1:-RUNNING}"
  _tnx_term_size
  _tnx_frame_layout
  local cols="$_TNX_FRAME_COLS" rows="$_TNX_FRAME_ROWS"
  local rule; rule="$(_tnx_frame_rule)"
  local state_color="$TNX_CC"
  [ "$state" = "COMPLETE" ] && state_color="$TNX_CG"
  [ "$state" = "FAILED" ] && state_color="$TNX_CR"

  printf '\033[?25l\033[r\033[2J\033[H'
  printf '\033[1;1H%s+%s+%s' "$TNX_CM" "$rule" "$TNX_C0"
  _tnx_frame_paint_header
  printf '\033[4;1H%s+%s+%s' "$TNX_CM" "$rule" "$TNX_C0"
  if [ "$_TNX_LY_DEV_ON" = "1" ]; then
    _tnx_frame_paint_device
  fi
  _tnx_frame_paint_progress "$state_color"
  printf '\033[%d;1H%s+%s+%s' "$_TNX_LY_DIV2" "$TNX_CM" "$rule" "$TNX_C0"
  printf '\033[%d;1H%s+%s+%s' "$_TNX_LY_DIV3" "$TNX_CM" "$rule" "$TNX_C0"
  _tnx_frame_paint_footer "$_TNX_FRAME_TICK"
  printf '\033[%d;1H%s+%s+%s' "$_TNX_LY_BOT" "$TNX_CM" "$rule" "$TNX_C0"

  printf '\033[%d;%dr' "$_TNX_LY_LOGTOP" "$_TNX_LY_LOGBOT"
  _tnx_frame_repaint_log
}

# ── Resize re-fit (called from the main process only) -----------------------

# Re-fit the frame when the terminal size changed (font/zoom or the on-screen
# keyboard). Returns 0 when a redraw happened.
_tnx_frame_refit() {
  [ "${_TNX_FRAME_MODE:-off}" = "dashboard" ] || return 1
  local ncols nrows
  ncols="$(tput cols 2>/dev/null || echo 0)"
  nrows="$(tput lines 2>/dev/null || echo 0)"
  case "$ncols:$nrows" in *[!0-9:]*|:*) ncols=0; nrows=0 ;; esac
  if [ "${ncols:-0}" != "$_TNX_FRAME_COLS" ] || [ "${nrows:-0}" != "$_TNX_FRAME_ROWS" ]; then
    _tnx_frame_draw_dashboard "RUNNING"
    return 0
  fi
  return 1
}

# Open one persistent frame after confirmation and keep it until the final
# status. Full-screen dashboards are used only on capable interactive
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
  _TNX_FRAME_TICK=0
  _TNX_FRAME_ACTIVE=1
  _TNX_FRAME_MODE="plain"

  if [ -t 1 ] && [ -n "$TNX_C0" ]; then
    _tnx_term_size
    if [ "$_TNX_FRAME_COLS" -ge 44 ] && [ "$_TNX_FRAME_ROWS" -ge 16 ]; then
      _TNX_FRAME_MODE="dashboard"
    fi
  fi

  export _TNX_FRAME_ACTIVE _TNX_FRAME_MODE _TNX_FRAME_TOTAL _TNX_FRAME_CUR
  export _TNX_FRAME_TITLE _TNX_FRAME_BACKEND _TNX_FRAME_USER _TNX_FRAME_PROFILE
  export _TNX_FRAME_COLS _TNX_FRAME_ROWS

  tnx_log_info "Installation frame opened: backend=$backend user=$user_name profile=$profile"
  if [ "$_TNX_FRAME_MODE" = "dashboard" ]; then
    _tnx_frame_gather_device
    _tnx_frame_draw_dashboard "RUNNING"
  else
    local cols inner rule
    cols="$(_tnx_plain_cols)"
    inner=$((cols - 4))
    rule="$(_tnx_repeat '=' "$((cols - 2))")"
    printf '%s+%s+%s\n' "$TNX_CM" "$rule" "$TNX_C0"
    printf '%s|%s %s%s%s\n' "$TNX_CM" "$TNX_CG" "$TNX_CW" "$(_tnx_clip 't e r n u x  -  one-click installer' "$inner")" "$TNX_C0"
    printf '%s|%s by %s%s%s%s%s\n' "$TNX_CM" "$TNX_C0" "$TNX_CG" "$_TNX_SIG_NAME" "$TNX_C0" \
      "$(_tnx_clip '  -  base ~3-4 GB  -  complete ~10-12 GB' "$((inner - 3 - ${#_TNX_SIG_NAME}))")" "$TNX_C0"
    printf '%s+%s+%s\n' "$TNX_CM" "$rule" "$TNX_C0"
  fi
}

# Update the fixed step/progress line in dashboard mode, or print a colored
# separator in append-only mode.
tnx_frame_phase() {
  local cur="$1" total="$2" title="$3"
  _TNX_FRAME_CUR="$cur"; _TNX_FRAME_TOTAL="$total"; _TNX_FRAME_TITLE="$title"
  export _TNX_FRAME_CUR _TNX_FRAME_TOTAL _TNX_FRAME_TITLE
  tnx_log_info "Phase $cur/$total: $title"

  if [ "${_TNX_FRAME_MODE:-off}" = "dashboard" ]; then
    local old_c="$_TNX_FRAME_COLS" old_r="$_TNX_FRAME_ROWS"
    _tnx_term_size
    if [ "$_TNX_FRAME_COLS" != "$old_c" ] || [ "$_TNX_FRAME_ROWS" != "$old_r" ]; then
      _tnx_frame_draw_dashboard "RUNNING"
    else
      _tnx_frame_layout
      _tnx_frame_paint_progress "$TNX_CC"
      _tnx_frame_paint_footer "$_TNX_FRAME_TICK"
    fi
  elif [ "${_TNX_FRAME_MODE:-off}" = "plain" ]; then
    local cols tmax ttitle
    cols="$(_tnx_plain_cols)"
    tmax=$((cols - 6 - ${#cur} - ${#total})); [ "$tmax" -lt 3 ] && tmax=3
    ttitle="$(_tnx_clip "$title" "$tmax")"
    printf '%s|%s %s[%s/%s]%s %s%s%s\n' "$TNX_CM" "$TNX_C0" "$TNX_CC" "$cur" "$total" "$TNX_C0" "$TNX_CG" "$ttitle" "$TNX_C0"
  else
    tnx_phase_header "$cur" "$total" "$title"
  fi
}

# Consume a command/phase stream, normalize CR progress updates to one record,
# retain every visible line in the install log, and color by severity/activity.
# The spinner and resize re-fit run inline here (single writer, no background
# process), ticking whenever input pauses via `read -t` and periodically
# between lines.
tnx_frame_stream() {
  local line="" clean="" color="" inner=76
  local linecount=0 rc
  [ "${_TNX_FRAME_MODE:-off}" = "off" ] && { cat; return; }
  if [ "${_TNX_FRAME_MODE:-off}" = "dashboard" ]; then
    _tnx_term_size
    inner=$((_TNX_FRAME_COLS - 4))
  else
    inner=$(( $(_tnx_plain_cols) - 4 ))
  fi

  while :; do
    if IFS= read -r -t 0.15 line; then
      clean="$(_tnx_strip_controls "$line")"
      printf '%s\n' "$clean" >> "$TERNUX_LOG_FILE" 2>/dev/null || true
      if [ "${_TNX_FRAME_MODE:-off}" = "dashboard" ]; then
        _tnx_frame_paint_logline "$clean"
        linecount=$((linecount + 1))
        if [ $((linecount % 12)) -eq 0 ]; then
          _TNX_FRAME_TICK=$((_TNX_FRAME_TICK + 1))
          _tnx_frame_paint_footer "$_TNX_FRAME_TICK"
          _tnx_frame_refit
        fi
      else
        local clipped; clipped="$(_tnx_clip "$clean" "$((inner - 2))")"
        color="$(_tnx_frame_line_color "$clean")"
        printf '%s|%s %s%s%s\n' "$TNX_CM" "$TNX_C0" "$color" "$clipped" "$TNX_C0"
      fi
    else
      rc=$?
      if [ "$rc" -ge 128 ]; then
        # Read timed out: no input for a tick. Animate the footer and re-check
        # for a terminal resize while a long phase is running.
        if [ "${_TNX_FRAME_MODE:-off}" = "dashboard" ]; then
          _TNX_FRAME_TICK=$((_TNX_FRAME_TICK + 1))
          _tnx_frame_paint_footer "$_TNX_FRAME_TICK"
          _tnx_frame_refit
        fi
        continue
      fi
      # EOF (or error): the phase stream is done.
      break
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
    local cols rule color
    cols="$(_tnx_plain_cols)"
    rule="$(_tnx_repeat '=' "$((cols - 2))")" color="$TNX_CR"
    [ "$status" = "success" ] && color="$TNX_CG"
    printf '%s|%s %sInstallation %s%s\n' "$TNX_CM" "$TNX_C0" "$color" "$status" "$TNX_C0"
    printf '%s+%s+%s\n' "$TNX_CM" "$rule" "$TNX_C0"
  fi
  _TNX_FRAME_ACTIVE=0
  _TNX_FRAME_MODE="off"
  export _TNX_FRAME_ACTIVE _TNX_FRAME_MODE
}

# ── Banner -----------------------------------------------------------------
tnx_banner() {
  [ "${TERNUX_QUIET:-0}" = "1" ] && return 0
  if [ ! -t 1 ] || [ -z "$TNX_C0" ] || [ "${TERNUX_NO_ANIM:-0}" = "1" ]; then
    printf '%sternux v%s%s - Linux desktop for Android\n' "$TNX_CG" "$TERNUX_VERSION" "$TNX_C0"
    printf 'Zink and VirGL graphics routes - by %s\n%s\n\n' "$_TNX_SIG_NAME" "$TERNUX_REPO"
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
  local charset="#%&*+=<>/|01" i j pass len ch out
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
  printf '  %sv%s - by %s%s%s - MIT%s\n\n' "$TNX_CD" "$TERNUX_VERSION" "$TNX_C0" "$(_tnx_sig 0)" "$TNX_CD" "$TNX_C0"
}

# ── Phase header used when no install frame is active ----------------------
tnx_phase_header() {
  [ "${TERNUX_QUIET:-0}" = "1" ] && return 0
  local num="${1:-?}" total="${2:-?}" title="$3"
  printf '\n  %s================================%s\n' "$TNX_CM" "$TNX_C0"
  printf '  %s[%s/%s]%s  %s%s%s\n' "$TNX_CW" "$num" "$total" "$TNX_C0" "$TNX_CG" "$title" "$TNX_C0"
  printf '  %s--------------------------------%s\n' "$TNX_CD" "$TNX_C0"
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
    if tnx_state_done "phase_${phases[$i]}" 2>/dev/null; then mark="${TNX_CG}x${TNX_C0}"
    else mark="${TNX_CD}.${TNX_C0}"; fi
    out+="${TNX_CD}${short[$i]:-$i}${TNX_C0}${mark}  "
  done
  printf '  %s\n' "$out"
}

# ── Summary box ------------------------------------------------------------
tnx_summary_box() {
  [ "${TERNUX_QUIET:-0}" = "1" ] && return 0
  local title="$1"; shift
  local pairs=("$@") w=52 i k v row
  printf '\n  %s+%s+%s\n' "$TNX_CM" "$(_tnx_repeat '-' "$w")" "$TNX_C0"
  printf -v row '%-*.*s' "$((w - 2))" "$((w - 2))" "$title"
  printf '  %s|%s %s%s%s %s|%s\n' "$TNX_CM" "$TNX_C0" "$TNX_CG" "$row" "$TNX_C0" "$TNX_CM" "$TNX_C0"
  printf '  %s+%s+%s\n' "$TNX_CM" "$(_tnx_repeat '-' "$w")" "$TNX_C0"
  for ((i=0; i<${#pairs[@]}; i+=2)); do
    k="${pairs[$i]}"; v="${pairs[$((i+1))]}"
    printf -v row '%-16s %-*.*s' "$k:" "$((w - 19))" "$((w - 19))" "$v"
    printf '  %s|%s %s%-*.*s%s %s|%s\n' "$TNX_CM" "$TNX_C0" "$TNX_CW" "$((w - 2))" "$((w - 2))" "$row" "$TNX_C0" "$TNX_CM" "$TNX_C0"
  done
  printf '  %s+%s+%s\n' "$TNX_CM" "$(_tnx_repeat '-' "$w")" "$TNX_C0"
}

tnx_celebrate() {
  [ "${TERNUX_QUIET:-0}" = "1" ] && return 0
  printf '\n  %s== %sI N S T A L L   C O M P L E T E%s ==%s\n' "$TNX_CG" "$TNX_CW" "$TNX_CG" "$TNX_C0"
  printf '  %sdesktop - GPU - audio - host CLI - guest companion verified%s\n' "$TNX_CD" "$TNX_C0"
  printf '  %sbuilt with <3 by %s%s%s\n' "$TNX_CD" "$TNX_C0" "$(_tnx_sig 0)" "$TNX_C0"
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
