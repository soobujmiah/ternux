# =============================================================================
#  ternux — installer UI (renderer rev 2)
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
#    3. The frame keeps one gutter column on each side and never writes into
#       the last terminal column. Touching that column arms the pending-wrap
#       state, and the next newline then wraps the row — which is what turned
#       the log window into a shredded, overlapping frame. The left gutter is
#       cosmetic: flush against both edges reads as cramped on a phone.
#    4. A full-screen repaint happens ONLY on open, on close, and on a real
#       terminal resize. Everything else touches a single row. A repaint driven
#       by a timer is what makes a log impossible to read.
#    5. Terminal size is measured through the kernel (stty/tput) and cached.
#       The measured (raw) size is compared against the previous raw size —
#       never against the clamped drawing size — otherwise a clamp difference
#       looks like a permanent resize and the screen redraws forever.
#    6. Carriage-return progress output (apt, dpkg, proot-distro, curl) is
#       collapsed in place on one transient row instead of being converted into
#       thousands of scrolling lines.
#    7. Nothing in the per-line hot path forks a subprocess. Command
#       substitution inside the render loop is what makes a phone stutter.
#
#  Environment
#    TERNUX_UI=auto|dashboard|plain|off   renderer selection (default auto)
#    TERNUX_NO_ANIM=1                     freeze spinner/colour cycling
#    TERNUX_COLS / TERNUX_ROWS            force a geometry (testing)
#    TERNUX_QUIET=1 / TERNUX_JSON=1       renderer disabled
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah)
#  Licensed under the Apache License, Version 2.0.
#  https://github.com/soobujmiah/ternux
# =============================================================================

# shellcheck source=lib/core.sh
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"
# Device information for the dashboard's hardware panel.
# shellcheck source=lib/detect.sh
. "$(dirname "${BASH_SOURCE[0]}")/detect.sh"

_TNX_UI_LOADED=1
_TNX_SIG_NAME="Sobuj Miah"
_TNX_SIG_WIDTH=${#_TNX_SIG_NAME}
_TNX_SIG_COLORS=("$TNX_CG" "$TNX_CC" "$TNX_CG" "$TNX_CC" "$TNX_CG" "$TNX_CG")
_TNX_FRAME_ACTIVE=0
_TNX_FRAME_MODE="off"

# Frame geometry and animation state.
_TNX_FRAME_COLS=80          # drawing width of the frame (< terminal columns)
_TNX_FRAME_X=2              # 1-based column the frame starts at (left gutter)
_TNX_FRAME_ROWS=24          # drawing height of the frame (<= terminal rows)
_TNX_TERM_COLS=0            # last raw measurement, used for resize detection
_TNX_TERM_ROWS=0
_TNX_SIZE_OK=0              # 1 when the terminal size could really be measured
_TNX_FRAME_TOTAL=11
_TNX_FRAME_CUR=0
_TNX_FRAME_TITLE="Preparing installation"
_TNX_FRAME_BACKEND="auto"
_TNX_FRAME_TICK=0
_TNX_FRAME_T0=0
_TNX_TTY=0
[ -t 1 ] && _TNX_TTY=1
_TNX_ANIM=1
[ "${TERNUX_NO_ANIM:-0}" = "1" ] && _TNX_ANIM=0
_TNX_NEED_NL=0

# Layout row indices (computed from the current terminal size).
_TNX_LY_TITLE=2; _TNX_LY_TITLE2=0; _TNX_LY_TITLE3=0; _TNX_LY_TITLE4=0; _TNX_LY_TITLE5=0; _TNX_LY_IDENT=3; _TNX_LY_VER=4; _TNX_LY_BY=5; _TNX_LY_DIV1=6; _TNX_LY_DEV0=7; _TNX_LY_DEV_ON=1
_TNX_LY_PROG=12; _TNX_LY_BAR=13; _TNX_LY_TASK=14; _TNX_LY_DIV2=15; _TNX_LY_LOGTOP=16
_TNX_LY_LOGBOT=21; _TNX_LY_DIV3=22; _TNX_LY_FOOTER=23; _TNX_LY_BOT=24
# Device panel content.
_TNX_FRAME_DEV_LABELS=()
_TNX_FRAME_DEV_VALUES=()
_TNX_FRAME_STORAGE="?"

# Renderer tuning. Times are milliseconds.
_TNX_READ_TIMEOUT=0.12      # idle granularity of the stream loop
_TNX_ANIM_MS=900            # gentle title/footer animation interval
_TNX_TRANSIENT_MS=90        # in-place progress refresh interval
_TNX_RESIZE_MS=1200         # resize poll interval (SIGWINCH bypasses it)
_TNX_FLOOD_LINES=40         # painted log lines per second before coalescing

# Scratch globals written by the fork-free helpers below.
_TNX_SP=""; _TNX_CLIP=""; _TNX_CLIPW=0; _TNX_TXT=""; _TNX_LC=""
_TNX_IMPORTANT=0; _TNX_SIG=""; _TNX_RULE=""; _TNX_NOW=0
printf -v _TNX_SPACES '%*s' 240 ''

# ── Fork-free string helpers -----------------------------------------------

# _TNX_SP <- $1 spaces (clamped to the scratch buffer).
_tnx_pad() {
  local n="${1:-0}"
  (( n < 0 )) && n=0
  (( n > 240 )) && n=240
  _TNX_SP="${_TNX_SPACES:0:n}"
}

# Legacy helper kept for callers outside the render loop.
_tnx_repeat() {
  local char="$1" count="$2" out=""
  (( count < 0 )) && count=0
  printf -v out '%*s' "$count" ''
  printf '%s' "${out// /$char}"
}

# _TNX_RULE <- a full-width ASCII rule for the current frame width.
_tnx_rule_cache() {
  local n=$(( _TNX_FRAME_COLS - 2 )) r="" pattern='*+=-~^-=+*' i idx
  (( n < 1 )) && n=1
  for ((i=0; i<n; i++)); do idx=$((i % ${#pattern})); r+="${pattern:idx:1}"; done
  _TNX_RULE="$r"
}

_tnx_frame_rule() { printf '%s' "$_TNX_RULE"; }

# _TNX_NOW <- monotonic-ish milliseconds. EPOCHREALTIME is a bash builtin
# variable (no fork); SECONDS is the portable fallback.
if [ -n "${EPOCHREALTIME:-}" ]; then
  _tnx_now() {
    local t="${EPOCHREALTIME/,/.}"
    _TNX_NOW=$(( 10#${t%.*} * 1000 + 10#${t#*.} / 1000 ))
  }
else
  _tnx_now() { _TNX_NOW=$(( SECONDS * 1000 )); }
fi

# _TNX_TXT <- $1 with CR, ANSI/OSC escapes and stray control bytes removed.
_tnx_stripv() {
  local t="$1" rest="" out="" ch code
  t="${t//$'\r'/}"
  if [[ $t == *$'\033'* ]]; then
    rest="$t"; out=""
    while [[ $rest == *$'\033'* ]]; do
      out+="${rest%%$'\033'*}"
      rest="${rest#*$'\033'}"
      case "$rest" in
        '['*)
          rest="${rest#'['}"
          while [ -n "$rest" ]; do
            ch="${rest:0:1}"; rest="${rest:1}"
            printf -v code '%d' "'$ch" 2>/dev/null || code=64
            (( code >= 64 && code <= 126 )) && break
          done
          ;;
        ']'*)
          # OSC sequence: runs to BEL or ST.
          if [[ $rest == *$'\a'* ]]; then rest="${rest#*$'\a'}"
          elif [[ $rest == *$'\033\\'* ]]; then rest="${rest#*$'\033\\'}"
          else rest=""; fi
          ;;
        *) rest="${rest:1}" ;;
      esac
    done
    t="$out$rest"
  fi
  t="${t//$'\t'/    }"
  t="${t//[$'\001'-$'\010'$'\013'$'\014'$'\016'-$'\037'$'\177']/}"
  _TNX_TXT="$t"
}

_tnx_strip_controls() { _tnx_stripv "$1"; printf '%s' "$_TNX_TXT"; }

# _TNX_CW <- display cells for one code point, biased to 2 when in doubt.
#
# Invariant 1 is the reason this table exists: middle dot, bullet and braille
# render two cells wide at normal zoom on many Android fonts, and all three sit
# *below* the CJK range, so a single "> U+2E7F is wide" threshold counts them as
# one and the right border is pushed out. Over-estimating only clips a log line
# a cell early, which is cosmetic; under-estimating shreds the frame.
#
# ternux's own frame is pure ASCII (`= + |`), so nothing here can narrow it —
# this only ever applies to text coming out of apt, dpkg, curl and friends.
_tnx_cellwidth() {
  local c="$1"
  _TNX_CW=1
  if (( c == 9641 )); then _TNX_CW=1                               # installer pixel glyph: ▩
  elif (( c > 11903 )); then _TNX_CW=2                            # CJK onwards, emoji
  elif (( c == 183 || c == 8226 )); then _TNX_CW=2                # middle dot, bullet
  elif (( c >= 8592 && c <= 8959 )); then _TNX_CW=2               # arrows, math operators
  elif (( c >= 9312 && c <= 9727 )); then _TNX_CW=2               # enclosed alnum, box drawing, shapes
  elif (( c >= 9728 && c <= 10175 )); then _TNX_CW=2              # misc symbols, dingbats
  elif (( c >= 10240 && c <= 10495 )); then _TNX_CW=2             # braille
  fi
}

# _TNX_CLIP / _TNX_CLIPW <- $2 clipped to at most $1 display cells.
# Pure-ASCII input takes a single-slice fast path; anything else is measured
# per character so wide glyphs never push the right border out.
_tnx_clipv() {
  local max="$1" s="$2"
  (( max < 3 )) && max=3
  case "$s" in
    *[!\ -~]*) ;;
    *)
      if (( ${#s} <= max )); then _TNX_CLIP="$s"; _TNX_CLIPW=${#s}
      else _TNX_CLIP="${s:0:max-1}~"; _TNX_CLIPW=$max; fi
      return 0 ;;
  esac
  local n=${#s} i=0 w=0 out="" ch code cw
  while (( i < n && w < max )); do
    ch="${s:i:1}"
    printf -v code '%d' "'$ch" 2>/dev/null || code=63
    _tnx_cellwidth "$code"; cw=$_TNX_CW
    (( w + cw > max )) && break
    out+="$ch"; w=$(( w + cw )); i=$(( i + 1 ))
  done
  if (( i < n )); then
    while (( w + 1 > max && ${#out} > 0 )); do
      ch="${out: -1}"; out="${out:0:${#out}-1}"
      printf -v code '%d' "'$ch" 2>/dev/null || code=63
      _tnx_cellwidth "$code"; w=$(( w - _TNX_CW ))
    done
    out+='~'; w=$(( w + 1 ))
  fi
  _TNX_CLIP="$out"; _TNX_CLIPW=$w
}

_tnx_clip() { _tnx_clipv "${2:-76}" "$1"; printf '%s' "$_TNX_CLIP"; }

# _TNX_LC <- severity colour for a log line; _TNX_IMPORTANT <- 1 for lines
# that must never be dropped by burst coalescing.
_tnx_line_color() {
  local lower="${1,,}"
  _TNX_IMPORTANT=0
  case "$lower" in
    *fatal*|*fail*|*error:*|*"error "*|*failed*|"e: "*)
      _TNX_LC="$TNX_CR"; _TNX_IMPORTANT=1 ;;
    *warn*|*warning*|*"held back"*|"w: "*)
      _TNX_LC="$TNX_CY"; _TNX_IMPORTANT=1 ;;
    *"[ ok ]"*|*"[done]"*|*complete*)
      _TNX_LC="$TNX_CG"; _TNX_IMPORTANT=1 ;;
    *"setting up"*|*installed*|*fetched*)
      _TNX_LC="$TNX_CG" ;;
    get:*|hit:*|*download*|*unpack*|*package*)
      _TNX_LC="$TNX_CC" ;;
    *task*|*phase*|*"[info]"*)
      _TNX_LC="$TNX_CC"; _TNX_IMPORTANT=1 ;;
    *)
      _TNX_LC="$TNX_CW" ;;
  esac
}

_tnx_frame_line_color() { _tnx_line_color "$1"; printf '%s' "$_TNX_LC"; }

# _TNX_SIG <- the signature, colour-cycled by tick (or plain when animation
# is disabled). Display width is always $_TNX_SIG_WIDTH.
_tnx_sigv() {
  local tick="${1:-0}" i ch out="" phase
  if [ "$_TNX_ANIM" != "1" ] || [ -z "$TNX_C0" ]; then
    _TNX_SIG="$_TNX_SIG_NAME"
    return 0
  fi
  phase=$(( tick % 6 ))
  for ((i=0; i<_TNX_SIG_WIDTH; i++)); do
    ch="${_TNX_SIG_NAME:$i:1}"
    if [ "$ch" = " " ]; then out+=' '
    else out+="${_TNX_SIG_COLORS[$(((i+phase)%6))]}$ch$TNX_C0"; fi
  done
  _TNX_SIG="$out"
}

_tnx_sig() { _tnx_sigv "${1:-0}"; printf '%s' "$_TNX_SIG"; }

# ── Geometry ---------------------------------------------------------------

# Measure the real terminal size. Sets _TNX_TERM_COLS/_TNX_TERM_ROWS and
# _TNX_SIZE_OK. Never called from the per-line path.
_tnx_measure() {
  local c=0 r=0 sz=""
  # Ask the kernel for the window size, not the environment: COLUMNS/LINES are
  # only refreshed for interactive shells and `tput` trusts them blindly, which
  # would hide every resize. The controlling terminal is tried first, then the
  # descriptors this process shares with it (stderr stays attached to the
  # terminal even while stdin is the pipe carrying a phase's output).
  if [ -n "${TERNUX_COLS:-}" ] && [ -n "${TERNUX_ROWS:-}" ]; then
    c="$TERNUX_COLS"; r="$TERNUX_ROWS"
  else
    sz="$(stty size </dev/tty 2>/dev/null)" || sz=""
    [ -n "$sz" ] || sz="$(stty size <&2 2>/dev/null)" || sz=""
    if [ -z "$sz" ] && [ "$_TNX_TTY" = "1" ]; then
      sz="$(stty size <&1 2>/dev/null)" || sz=""
    fi
    if [ -n "$sz" ]; then
      r="${sz%% *}"; c="${sz##* }"
    elif [ "$_TNX_TTY" = "1" ]; then
      c="$(tput cols 2>/dev/null)"; r="$(tput lines 2>/dev/null)"
    fi
  fi
  case "${c:-}" in ''|*[!0-9]*) c=0 ;; esac
  case "${r:-}" in ''|*[!0-9]*) r=0 ;; esac
  if (( c >= 8 && r >= 6 )); then
    _TNX_TERM_COLS=$c; _TNX_TERM_ROWS=$r; _TNX_SIZE_OK=1
    return 0
  fi
  if (( ${COLUMNS:-0} >= 8 && ${LINES:-0} >= 6 )); then
    _TNX_TERM_COLS=$COLUMNS; _TNX_TERM_ROWS=$LINES; _TNX_SIZE_OK=1
    return 0
  fi
  # No reliable measurement: keep a safe default and never claim a resize.
  _TNX_TERM_COLS=80; _TNX_TERM_ROWS=24; _TNX_SIZE_OK=0
  return 1
}

# Convert the measured size into the frame's drawing geometry. The frame
# deliberately leaves the last terminal column unused (rule 3).
_tnx_apply_size() {
  local c="$_TNX_TERM_COLS" r="$_TNX_TERM_ROWS"
  # One column of gutter on each side: flush against both edges reads as
  # cramped on a phone, and the right-hand column also keeps the terminal out
  # of pending-wrap when the last cell is written.
  c=$(( c - 2 ))
  (( c > 200 )) && c=200
  (( c < 6 )) && c=6
  (( r > 200 )) && r=200
  (( r < 6 )) && r=6
  _TNX_FRAME_COLS=$c
  _TNX_FRAME_ROWS=$r
  _tnx_rule_cache
}

_tnx_term_size() { _tnx_measure; _tnx_apply_size; }

# Width for the append-only "plain" frame (no full-screen control), clamped so
# the frame never overflows a narrow terminal. Stores it in _TNX_FRAME_COLS.
_tnx_plain_cols() {
  local cols=80
  _tnx_measure >/dev/null 2>&1 || true
  [ "$_TNX_SIZE_OK" = "1" ] && cols=$(( _TNX_TERM_COLS - 2 ))
  (( cols > 200 )) && cols=200
  (( cols < 6 )) && cols=6
  _TNX_FRAME_COLS=$cols
  _tnx_rule_cache
  printf '%s' "$cols"
}

# Compute fixed row indices for the current terminal size. Full layout includes
# the device panel; a short/narrow viewport drops it.
_tnx_frame_layout() {
  local R="$_TNX_FRAME_ROWS" C="$_TNX_FRAME_COLS"
  _TNX_LY_DEV_ON=0
  if (( R >= 26 && C >= 46 )); then
    _TNX_LY_LOGO_ROWS=5
    _TNX_LY_TITLE=2; _TNX_LY_TITLE2=3; _TNX_LY_TITLE3=4; _TNX_LY_TITLE4=5; _TNX_LY_TITLE5=6
    _TNX_LY_IDENT=7; _TNX_LY_VER=8; _TNX_LY_BY=9; _TNX_LY_DIV1=10
    _TNX_LY_DEV_ON=1; _TNX_LY_DEV0=11
    _TNX_LY_PROG=16; _TNX_LY_BAR=17; _TNX_LY_TASK=18; _TNX_LY_DIV2=19; _TNX_LY_LOGTOP=20
  elif (( R >= 18 && C >= 46 )); then
    _TNX_LY_LOGO_ROWS=5
    _TNX_LY_TITLE=2; _TNX_LY_TITLE2=3; _TNX_LY_TITLE3=4; _TNX_LY_TITLE4=5; _TNX_LY_TITLE5=6
    _TNX_LY_IDENT=7; _TNX_LY_VER=8; _TNX_LY_BY=0; _TNX_LY_DIV1=9; _TNX_LY_DEV0=0
    _TNX_LY_PROG=10; _TNX_LY_BAR=11; _TNX_LY_TASK=12; _TNX_LY_DIV2=13; _TNX_LY_LOGTOP=14
  elif (( R >= 18 && C >= 39 )); then
    _TNX_LY_LOGO_ROWS=0
    _TNX_LY_TITLE=2; _TNX_LY_TITLE2=3; _TNX_LY_TITLE3=0; _TNX_LY_TITLE4=0; _TNX_LY_TITLE5=0
    _TNX_LY_IDENT=4; _TNX_LY_VER=5; _TNX_LY_BY=6; _TNX_LY_DIV1=7; _TNX_LY_DEV0=0
    _TNX_LY_PROG=8; _TNX_LY_BAR=9; _TNX_LY_TASK=10; _TNX_LY_DIV2=11; _TNX_LY_LOGTOP=12
  elif (( R >= 16 && C >= 46 )); then
    _TNX_LY_LOGO_ROWS=5
    _TNX_LY_TITLE=2; _TNX_LY_TITLE2=3; _TNX_LY_TITLE3=4; _TNX_LY_TITLE4=5; _TNX_LY_TITLE5=6
    _TNX_LY_IDENT=7; _TNX_LY_VER=8; _TNX_LY_BY=0; _TNX_LY_DIV1=9; _TNX_LY_DEV0=0
    _TNX_LY_PROG=10; _TNX_LY_BAR=0; _TNX_LY_TASK=0; _TNX_LY_DIV2=11; _TNX_LY_LOGTOP=12
  elif (( R >= 16 && C >= 27 )); then
    _TNX_LY_LOGO_ROWS=0
    _TNX_LY_TITLE=2; _TNX_LY_TITLE2=3; _TNX_LY_TITLE3=0; _TNX_LY_TITLE4=0; _TNX_LY_TITLE5=0
    _TNX_LY_IDENT=4; _TNX_LY_VER=5; _TNX_LY_BY=6; _TNX_LY_DIV1=7; _TNX_LY_DEV0=0
    _TNX_LY_PROG=8; _TNX_LY_BAR=0; _TNX_LY_TASK=0; _TNX_LY_DIV2=9; _TNX_LY_LOGTOP=10
  else
    _TNX_LY_LOGO_ROWS=0
    _TNX_LY_TITLE=2; _TNX_LY_TITLE2=0; _TNX_LY_TITLE3=0; _TNX_LY_TITLE4=0; _TNX_LY_TITLE5=0
    _TNX_LY_IDENT=3; _TNX_LY_VER=4; _TNX_LY_BY=0; _TNX_LY_DIV1=5; _TNX_LY_DEV0=0
    _TNX_LY_PROG=6; _TNX_LY_BAR=0; _TNX_LY_TASK=0; _TNX_LY_DIV2=7; _TNX_LY_LOGTOP=8
  fi
  _TNX_LY_LOGBOT=$(( R - 3 )); _TNX_LY_DIV3=$(( R - 2 )); _TNX_LY_FOOTER=$(( R - 1 )); _TNX_LY_BOT=$R
  (( _TNX_LY_LOGBOT < _TNX_LY_LOGTOP )) && _TNX_LY_LOGBOT=$_TNX_LY_LOGTOP
}

# True when the current geometry can host a compact dashboard with a log row.
_tnx_frame_fits() {
  (( _TNX_FRAME_COLS >= 22 )) || return 1
  (( _TNX_FRAME_ROWS >= 16 )) || return 1
  _tnx_frame_layout
  (( _TNX_LY_LOGBOT - _TNX_LY_LOGTOP + 1 >= 1 ))
}

# Snapshot the hardware/software profile shown in the device panel. Values may
# contain non-ASCII (from getprop), so they are clipped by display width at
# paint time.
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
  _TNX_FRAME_STORAGE="$storage"
  backend="${_TNX_FRAME_BACKEND:-auto}"
  _TNX_FRAME_DEV_LABELS=("Device" "Android" "Graphics" "Resources" "CPU")
  _TNX_FRAME_DEV_VALUES=(
    "${model} - ${arch}"
    "Android ${android} (SDK ${sdk})"
    "${gpu} - ${backend} - Vulkan ${vulkan}"
    "${ram} GB RAM - ${storage} GB free; base ~3-4 GB"
    "sampling..."
  )
  _tnx_frame_cpu_sample 0
}

# Read aggregate CPU counters from procfs with Bash builtins only. The first
# sample establishes a baseline; subsequent samples update the dashboard no
# more than once per second.
_tnx_frame_cpu_sample() {
  local now="${_TNX_NOW:-0}" user nice system idle iowait irq softirq steal total idle_all delta_total delta_idle pct cores load
  (( now - ${_TNX_CPU_SAMPLE_T0:-0} >= 1000 )) || [ "${1:-1}" = "0" ] || return 0
  if [ ! -r /proc/stat ]; then
    cores="$(awk '/^processor[[:space:]]*:/ {n++} END {print n+0}' /proc/cpuinfo 2>/dev/null)"
    load="$(awk '{print $1}' /proc/loadavg 2>/dev/null)"
    _TNX_FRAME_DEV_VALUES[4]="${cores:-?} cores; load ${load:-n/a}"
    _TNX_CPU_SAMPLE_T0=$now
    return 0
  fi
  read -r _ _TNX_CPU_USER _TNX_CPU_NICE _TNX_CPU_SYSTEM _TNX_CPU_IDLE _TNX_CPU_IOWAIT _TNX_CPU_IRQ _TNX_CPU_SOFTIRQ _TNX_CPU_STEAL _ < /proc/stat || {
    cores="$(awk '/^processor[[:space:]]*:/ {n++} END {print n+0}' /proc/cpuinfo 2>/dev/null)"
    load="$(awk '{print $1}' /proc/loadavg 2>/dev/null)"
    _TNX_FRAME_DEV_VALUES[4]="${cores:-?} cores; load ${load:-n/a}"
    _TNX_CPU_SAMPLE_T0=$now
    return 0
  }
  user="${_TNX_CPU_USER:-0}"; nice="${_TNX_CPU_NICE:-0}"; system="${_TNX_CPU_SYSTEM:-0}"
  idle="${_TNX_CPU_IDLE:-0}"; iowait="${_TNX_CPU_IOWAIT:-0}"; irq="${_TNX_CPU_IRQ:-0}"
  softirq="${_TNX_CPU_SOFTIRQ:-0}"; steal="${_TNX_CPU_STEAL:-0}"
  total=$(( user + nice + system + idle + iowait + irq + softirq + steal ))
  idle_all=$(( idle + iowait ))
  if [ -n "${_TNX_CPU_PREV_TOTAL:-}" ]; then
    delta_total=$(( total - _TNX_CPU_PREV_TOTAL )); delta_idle=$(( idle_all - _TNX_CPU_PREV_IDLE ))
    if (( delta_total > 0 )); then
      pct=$(( (delta_total - delta_idle) * 100 / delta_total ))
      (( pct < 0 )) && pct=0
      (( pct > 100 )) && pct=100
      _TNX_FRAME_DEV_VALUES[4]="${pct}% utilization"
    fi
  fi
  _TNX_CPU_PREV_TOTAL=$total; _TNX_CPU_PREV_IDLE=$idle_all; _TNX_CPU_SAMPLE_T0=$now
}

# ── Static painters (absolute positioning; save/restore cursor) -------------

# Wrap pre-built content (exactly `inner` visible cells wide, colours allowed)
# in the left/right borders and paint it at an absolute row.
_tnx_frame_box_row() {
  local row="$1" content="$2"
  printf '\0337\033[%d;%dH\033[K%s|%s %s %s|%s\0338' "$row" "$_TNX_FRAME_X" "$TNX_CC" "$TNX_C0" "$content" "$TNX_CC" "$TNX_C0"
}

_tnx_frame_paint_header() {
  local tick="${1:-${_TNX_FRAME_TICK:-0}}" inner=$(( _TNX_FRAME_COLS - 4 )) content="" title tpad trpad tsp trsp logo_color
  local -a logo_colors=("$TNX_CG" "$TNX_CC" "$TNX_CG" "$TNX_CC" "$TNX_CG" "$TNX_CG")
  logo_color="${logo_colors[$((tick % ${#logo_colors[@]}))]}"
  if (( _TNX_LY_LOGO_ROWS == 5 )); then
    local -a logo
    if (( inner >= 50 )); then
    logo=(
      '▩▩▩▩▩    ▩▩▩▩▩    ▩▩▩▩     ▩   ▩    ▩   ▩    ▩   ▩'
      '  ▩      ▩        ▩   ▩    ▩▩  ▩    ▩   ▩    ▩   ▩'
      '  ▩      ▩▩▩▩     ▩▩▩▩     ▩ ▩ ▩    ▩   ▩     ▩ ▩ '
      '  ▩      ▩        ▩ ▩      ▩  ▩▩    ▩   ▩      ▩  '
      '  ▩      ▩▩▩▩▩    ▩  ▩     ▩   ▩    ▩▩▩▩▩     ▩ ▩ '
    )
    else
    logo=(
      '▩▩▩▩▩  ▩▩▩▩▩  ▩▩▩▩   ▩   ▩  ▩   ▩  ▩   ▩'
      '  ▩    ▩      ▩   ▩  ▩▩  ▩  ▩   ▩  ▩   ▩'
      '  ▩    ▩▩▩▩   ▩▩▩▩   ▩ ▩ ▩  ▩   ▩   ▩ ▩ '
      '  ▩    ▩      ▩ ▩    ▩  ▩▩  ▩   ▩    ▩  '
      '  ▩    ▩▩▩▩▩  ▩  ▩   ▩   ▩  ▩▩▩▩▩   ▩ ▩ '
    )
    fi
    local row
    for ((row=0; row<5; row++)); do
      _tnx_frame_logo_line "$(( _TNX_LY_TITLE + row ))" "${logo[$row]}" "$((tick + row))"
    done
  elif (( _TNX_LY_TITLE2 > 0 )); then
    _tnx_frame_center_line "$_TNX_LY_TITLE" 'T E R N U X' "$logo_color"
    _tnx_frame_center_line "$_TNX_LY_TITLE2" 'T E R N U X' "${logo_colors[$(((tick + 3) % ${#logo_colors[@]}))]}"
  else
    _tnx_clipv "$inner" 'T E R N U X'
    title="$_TNX_CLIP"
    tpad=$(( (inner - _TNX_CLIPW) / 2 )); (( tpad < 0 )) && tpad=0
    trpad=$(( inner - _TNX_CLIPW - tpad )); (( trpad < 0 )) && trpad=0
    _tnx_pad "$tpad"; tsp="$_TNX_SP"
    _tnx_pad "$trpad"; trsp="$_TNX_SP"
    printf -v content '%s%s%s%s%s%s' "$tsp" "$logo_color" "$title" "$TNX_C0" "$trsp" "$TNX_C0"
    _tnx_frame_box_row "$_TNX_LY_TITLE" "$content"
  fi

  _tnx_frame_center_line "$_TNX_LY_IDENT" 'Linux Workstation In Your Pocket' "${logo_colors[$(((tick + 2) % ${#logo_colors[@]}))]}"
  if (( _TNX_LY_BY > 0 )); then
    _tnx_frame_center_line "$_TNX_LY_VER" "v${TERNUX_VERSION}" "$TNX_CY"
    _tnx_frame_center_line "$_TNX_LY_BY" 'by Sobuj Miah (@soobujmiah)' "${logo_colors[$(((tick + 4) % ${#logo_colors[@]}))]}"
  else
    _tnx_frame_center_line "$_TNX_LY_VER" "v${TERNUX_VERSION}  |  by Sobuj Miah" "$TNX_CY"
  fi
}

_tnx_frame_center_line() {
  local row="$1" text="$2" color="$3" inner=$(( _TNX_FRAME_COLS - 4 )) content tpad trpad tsp trsp
  _tnx_clipv "$inner" "$text"
  tpad=$(( (inner - _TNX_CLIPW) / 2 )); (( tpad < 0 )) && tpad=0
  trpad=$(( inner - _TNX_CLIPW - tpad )); (( trpad < 0 )) && trpad=0
  _tnx_pad "$tpad"; tsp="$_TNX_SP"
  _tnx_pad "$trpad"; trsp="$_TNX_SP"
  printf -v content '%s%s%s%s%s' "$tsp" "$color" "$_TNX_CLIP" "$TNX_C0" "$trsp"
  _tnx_frame_box_row "$row" "$content"
}

# Animate the symbol strokes of the large TERNUX wordmark with a moving colour
# wave. The ASCII glyph stays fixed, so the name remains readable throughout.
_tnx_frame_logo_line() {
  local row="$1" text="$2" tick="${3:-0}" inner=$(( _TNX_FRAME_COLS - 4 ))
  local i ch color pad left right content="" phase
  local -a colors=("$TNX_CG" "$TNX_CC" "$TNX_CY" "$TNX_CG" "$TNX_CC" "$TNX_CY")
  _tnx_clipv "$inner" "$text"
  pad=$(( (inner - _TNX_CLIPW) / 2 )); (( pad < 0 )) && pad=0
  left="$(_tnx_repeat ' ' "$pad")"
  right="$(_tnx_repeat ' ' "$((inner - _TNX_CLIPW - pad))")"
  content="$left"
  for ((i=0; i<${#_TNX_CLIP}; i++)); do
    ch="${_TNX_CLIP:i:1}"
    case "$ch" in
      '▩') phase=$(( (i + tick) % ${#colors[@]} )); color="${colors[$phase]}" ;;
      *) color="$TNX_C0" ;;
    esac
    content+="${color}${ch}"
  done
  content+="${TNX_C0}${right}${TNX_C0}"
  _tnx_frame_box_row "$row" "$content"
}

_tnx_frame_paint_device() {
  local i row label value inner=$(( _TNX_FRAME_COLS - 4 )) content
  for i in 0 1 2 3 4; do
    row=$(( _TNX_LY_DEV0 + i ))
    label="${_TNX_FRAME_DEV_LABELS[$i]:-}"
    value="${_TNX_FRAME_DEV_VALUES[$i]:-}"
    _tnx_clipv $(( inner - 10 )) "$value"
    _tnx_pad $(( inner - 10 - _TNX_CLIPW ))
    printf -v content '%s%-9s%s %s%s%s%s' \
      "$TNX_CC" "$label" "$TNX_C0" "$TNX_CW" "$_TNX_CLIP" "$_TNX_SP" "$TNX_C0"
    _tnx_frame_box_row "$row" "$content"
  done
}

_tnx_frame_paint_progress() {
  local sc="${1:-$TNX_CC}" inner=$(( _TNX_FRAME_COLS - 4 )) row="${_TNX_LY_PROG:-8}"
  local cur="${_TNX_FRAME_CUR:-0}" total="${_TNX_FRAME_TOTAL:-1}" title="${_TNX_FRAME_TITLE:-}"
  (( total <= 0 )) && total=1
  (( cur < 0 )) && cur=0
  (( cur > total )) && cur=$total
  local cnt="${cur}/${total}" filled empty bar tmp barw=18
  if (( _TNX_LY_BAR > 0 && _TNX_LY_TASK > 0 )); then
    local barw=$(( _TNX_FRAME_COLS - 2 )) content
    filled=$(( cur * barw / total )); (( filled > barw )) && filled=$barw
    empty=$(( barw - filled ))
    printf -v tmp '%*s' "$filled" ''; bar="${tmp// /#}"
    printf -v tmp '%*s' "$empty" ''; bar+="${tmp// /-}"
    _tnx_frame_center_line "$row" "STEPS ${cnt}" "$sc"
    printf '\0337\033[%d;%dH|%s%s%s%s|\033[K\0338' \
      "$_TNX_LY_BAR" "$_TNX_FRAME_X" "$sc" "$bar" "$TNX_C0" "$TNX_C0"
    _tnx_clipv $(( inner - 1 )) "$title"
    _tnx_pad $(( inner - _TNX_CLIPW - 1 ))
    printf -v content '%s%s%s%s ' "$TNX_CG" "$_TNX_CLIP" "$TNX_C0" "$_TNX_SP"
    _tnx_frame_box_row "$_TNX_LY_TASK" "$content"
    return 0
  fi
  local barw=18
  (( inner < 52 )) && barw=12
  (( inner < 40 )) && barw=8
  (( inner < 26 )) && barw=4
  filled=$(( cur * barw / total ))
  (( filled > barw )) && filled=$barw
  empty=$(( barw - filled ))
  bar=""; tmp=""
  printf -v tmp '%*s' "$filled" ''; bar="${tmp// /#}"
  printf -v tmp '%*s' "$empty" '';  bar+="${tmp// /-}"
  if (( inner < 28 )); then
    local compact="${cnt} [${bar}]" available=$(( inner - ${#cnt} - 3 ))
    (( available < 0 )) && available=0
    if (( available > 0 )) && [ -n "$title" ]; then
      _tnx_clipv "$available" "$title"
      compact+=" ${_TNX_CLIP}"
    fi
    _tnx_clipv "$inner" "$compact"
    _tnx_pad $(( inner - _TNX_CLIPW ))
    _tnx_frame_box_row "$row" "${sc}${_TNX_CLIP}${TNX_C0}${_TNX_SP}"
    return 0
  fi
  local fixed=$(( 6 + ${#cnt} + 2 + barw + 2 ))
  local titlemax=$(( inner - fixed )); (( titlemax < 1 )) && titlemax=1
  _tnx_clipv "$titlemax" "$title"
  _tnx_pad $(( inner - fixed - _TNX_CLIPW ))
  local content=""
  printf -v content '%sSTEPS %s%s%s%s  %s%s%s%s  %s%s%s' \
    "$TNX_CW" "$TNX_CC" "$cnt" "$TNX_C0" "$TNX_CW" "$sc" "$bar" "$TNX_C0" \
    "$TNX_CG" "$_TNX_CLIP" "$_TNX_SP" "$TNX_C0"
  _tnx_frame_box_row "$row" "$content"
}

_tnx_frame_paint_footer() {
  local tick="${1:-0}" inner=$(( _TNX_FRAME_COLS - 4 )) row="${_TNX_LY_FOOTER:-$(( _TNX_FRAME_ROWS - 1 ))}"
  local sp='|/-\' spc elapsed mins secs right rightw content left leftw pre fixed center_start right_start gap_left gap_right
  spc="${sp:$((tick % 4)):1}"
  [ "$_TNX_ANIM" = "1" ] || spc='*'
  elapsed=$(( SECONDS - _TNX_FRAME_T0 ))
  (( elapsed < 0 )) && elapsed=0
  mins=$(( elapsed / 60 )); secs=$(( elapsed % 60 ))
  printf -v right '%02d:%02d %s' "$mins" "$secs" "$spc"
  rightw=${#right}
  left="Free:${_TNX_FRAME_STORAGE:-?}G"; leftw=${#left}
  pre="https://soobujmiah.github.io/"
  (( inner < 40 )) && pre="soobujmiah.github.io"
  fixed=${#pre}
  local palette=("$TNX_CG" "$TNX_CC" "$TNX_CG" "$TNX_CC" "$TNX_CG" "$TNX_CG")
  local copyright_color="${palette[$((tick % ${#palette[@]}))]}"
  if (( leftw + fixed + rightw + 2 > inner )); then
    pre="soobujmiah.github.io"; fixed=${#pre}
    printf -v right '%d:%02d' "$mins" "$secs"; rightw=${#right}
    left="${_TNX_FRAME_STORAGE:-?}G"; leftw=${#left}
  fi
  center_start=$(( (inner - fixed) / 2 ))
  right_start=$(( inner - rightw ))
  gap_left=$(( center_start - leftw )); gap_right=$(( right_start - center_start - fixed ))
  if (( inner < 20 )); then
    local compact="soobujmiah.github.io"
    _tnx_clipv "$inner" "$compact"
    content="${copyright_color}${_TNX_CLIP}${TNX_C0}"
    _tnx_pad $(( inner - _TNX_CLIPW )); content+="$_TNX_SP"
  elif (( gap_left < 1 || gap_right < 1 )); then
    _tnx_clipv "$inner" "$pre"
    _tnx_pad $(( inner - _TNX_CLIPW ))
    content="${copyright_color}${_TNX_CLIP}${TNX_C0}${_TNX_SP}"
  else
    _tnx_pad "$gap_left"; local sp_left="$_TNX_SP"
    _tnx_pad "$gap_right"; local sp_right="$_TNX_SP"
    printf -v content '%s%s%s%s%s%s%s%s%s' \
      "$TNX_CD" "$left" "$sp_left" "$copyright_color" "$pre" "$TNX_C0" "$sp_right" "$TNX_CD" "$right"
    local content_width=$(( leftw + gap_left + fixed + gap_right + rightw ))
    if (( content_width < inner )); then
      _tnx_pad $(( inner - content_width )); content+="$_TNX_SP"
    fi
  fi
  _tnx_frame_box_row "$row" "$content"
}

# Paint one already-cleaned log line inside the scroll region. Pass 1 as $2 for
# an in-place (progress) row that the next line is allowed to replace.
#
# The newline is emitted lazily, *before* the next row, so the cursor always
# rests on the row it just drew. That keeps the bottom line of the log window
# in use (a trailing newline would waste it) and lets an in-place progress row
# be replaced by the line that finishes it.
_tnx_frame_paint_logline() {
  local clean="$1" hold="${2:-0}" inner=$(( _TNX_FRAME_COLS - 4 ))
  _tnx_clipv $(( inner - 1 )) "$clean"
  _tnx_pad $(( inner - _TNX_CLIPW ))
  _tnx_line_color "$clean"
  [ "${_TNX_NEED_NL:-0}" = "1" ] && printf '\n'
  printf '\r\033[K%*s%s|%s %s%s%s%s %s|%s\r' "$(( _TNX_FRAME_X - 1 ))" "" \
    "$TNX_CM" "$TNX_C0" "$_TNX_LC" "$_TNX_CLIP" "$_TNX_SP" "$TNX_C0" "$TNX_CM" "$TNX_C0"
  if [ "$hold" = "1" ]; then _TNX_NEED_NL=0; else _TNX_NEED_NL=1; fi
}

# Repaint the log region from the recorded stream so a resize never loses
# content. One `tail` per resize is acceptable; nothing here runs per line.
_tnx_frame_repaint_log() {
  local n=$(( _TNX_LY_LOGBOT - _TNX_LY_LOGTOP + 1 )) ln
  printf '\033[%d;%dH' "$_TNX_LY_LOGTOP" "$_TNX_FRAME_X"
  _TNX_NEED_NL=0
  [ -n "${_TNX_STREAM_LOG:-}" ] && [ -f "${_TNX_STREAM_LOG:-}" ] || return 0
  while IFS= read -r ln; do
    _tnx_frame_paint_logline "$ln"
  done < <(tail -n "$n" "${_TNX_STREAM_LOG:-}" 2>/dev/null)
}

# Full dashboard repaint: clear, chrome, scroll region, log tail, cursor.
# This is the ONLY function that clears the screen.
_tnx_frame_draw_dashboard() {
  [ "${_TNX_FRAME_MODE:-off}" = "dashboard" ] || return 0
  local state="${1:-RUNNING}"
  _tnx_frame_layout
  local state_color="$TNX_CC"
  [ "$state" = "COMPLETE" ] && state_color="$TNX_CG"
  [ "$state" = "FAILED" ] && state_color="$TNX_CR"

  printf '\033[?25l\033[r\033[2J\033[H'
  printf '\033[1;%dH%s+%s+%s' "$_TNX_FRAME_X" "$TNX_CG" "$_TNX_RULE" "$TNX_C0"
  _tnx_frame_paint_header
  printf '\033[%d;%dH%s+%s+%s' "$_TNX_LY_DIV1" "$_TNX_FRAME_X" "$TNX_CG" "$_TNX_RULE" "$TNX_C0"
  if [ "$_TNX_LY_DEV_ON" = "1" ]; then
    _tnx_frame_paint_device
  fi
  _tnx_frame_paint_progress "$state_color"
  printf '\033[%d;%dH%s+%s+%s' "$_TNX_LY_DIV2" "$_TNX_FRAME_X" "$TNX_CG" "$_TNX_RULE" "$TNX_C0"
  printf '\033[%d;%dH%s+%s+%s' "$_TNX_LY_DIV3" "$_TNX_FRAME_X" "$TNX_CG" "$_TNX_RULE" "$TNX_C0"
  _tnx_frame_paint_footer "$_TNX_FRAME_TICK"
  printf '\033[%d;%dH%s+%s+%s' "$_TNX_LY_BOT" "$_TNX_FRAME_X" "$TNX_CG" "$_TNX_RULE" "$TNX_C0"

  printf '\033[%d;%dr' "$_TNX_LY_LOGTOP" "$_TNX_LY_LOGBOT"
  _tnx_frame_repaint_log
}

# ── Resize re-fit -----------------------------------------------------------

# Re-fit the frame when the terminal really changed size (font/zoom change or
# the on-screen keyboard). Compares raw measurements against the previous raw
# measurement, so clamping can never masquerade as a resize. Returns 0 when a
# redraw happened.
_tnx_frame_refit() {
  [ "${_TNX_FRAME_MODE:-off}" = "dashboard" ] || [ "${_TNX_FRAME_MODE:-off}" = "plain" ] || return 1
  [ "${TERNUX_UI:-auto}" != "plain" ] || return 1
  [ "$_TNX_SIZE_OK" = "1" ] || return 1
  local oc="$_TNX_TERM_COLS" or="$_TNX_TERM_ROWS"
  _tnx_measure || return 1
  if [ "$_TNX_TERM_COLS" = "$oc" ] && [ "$_TNX_TERM_ROWS" = "$or" ]; then
    return 1
  fi
  _tnx_apply_size
  if _tnx_frame_fits; then
    _TNX_FRAME_MODE="dashboard"
    trap '_TNX_RESIZE_PENDING=1' WINCH
    _tnx_frame_gather_device
    _tnx_frame_draw_dashboard "RUNNING"
    return 0
  else
    # The terminal became too small for a dashboard: fall back cleanly instead
    # of drawing a broken frame.
    printf '\033[r\033[?25h\033[2J\033[H'
    _TNX_FRAME_MODE="plain"
    _TNX_FRAME_COLS=$(( _TNX_TERM_COLS - 2 ))
    (( _TNX_FRAME_COLS > 200 )) && _TNX_FRAME_COLS=200
    (( _TNX_FRAME_COLS < 6 )) && _TNX_FRAME_COLS=6
    _tnx_rule_cache
    _TNX_NEED_NL=0
    printf '%s+%s+%s\n' "$TNX_CM" "$_TNX_RULE" "$TNX_C0"
    return 0
  fi
  _tnx_frame_draw_dashboard "RUNNING"
  return 0
}

# ── Frame lifecycle ---------------------------------------------------------

# Open one persistent frame after confirmation and keep it until the final
# status. Full-screen dashboards are used only on capable interactive
# terminals; every other environment gets an append-only framed stream.
tnx_frame_open() {
  local total="${1:-11}" backend="${2:-auto}" user_name="${3:-ternux}" profile="${4:-base}"
  local want="${TERNUX_UI:-auto}"
  if [ "${TERNUX_QUIET:-0}" = "1" ] || [ "${TERNUX_JSON:-0}" = "1" ] || [ "$want" = "off" ]; then
    _TNX_FRAME_ACTIVE=0; _TNX_FRAME_MODE="off"
    export _TNX_FRAME_ACTIVE _TNX_FRAME_MODE
    return 0
  fi

  # Re-read the switches: --no-anim / --ui may be parsed after this library was
  # sourced.
  _TNX_ANIM=1
  [ "${TERNUX_NO_ANIM:-0}" = "1" ] && _TNX_ANIM=0
  if [ -t 1 ]; then _TNX_TTY=1; else _TNX_TTY=0; fi

  mkdir -p "$TERNUX_LOG_DIR" 2>/dev/null || true
  : >> "$TERNUX_LOG_FILE" 2>/dev/null || true
  _TNX_STREAM_LOG="$TERNUX_LOG_DIR/install-stream.log"
  : > "$_TNX_STREAM_LOG" 2>/dev/null || _TNX_STREAM_LOG=""
  _TNX_FRAME_TOTAL="$total"
  _TNX_FRAME_CUR=0
  _TNX_FRAME_TITLE="Preparing installation"
  _TNX_FRAME_BACKEND="$backend"
  _TNX_FRAME_USER="$user_name"
  _TNX_FRAME_PROFILE="$profile"
  _TNX_FRAME_TICK=0
  _TNX_FRAME_T0=$SECONDS
  _TNX_FRAME_STORAGE="$(tnx_detect_storage_gb 2>/dev/null || echo '?')"
  _TNX_FRAME_STORAGE="${_TNX_FRAME_STORAGE:-?}"
  _TNX_FRAME_ACTIVE=1
  _TNX_FRAME_MODE="plain"
  _TNX_NEED_NL=0

  if [ "$want" != "plain" ] && [ "$_TNX_TTY" = "1" ] && [ -n "$TNX_C0" ]; then
    _tnx_term_size
    if [ "$want" = "dashboard" ] || [ "$_TNX_SIZE_OK" = "1" ]; then
      if _tnx_frame_fits; then
        _TNX_FRAME_MODE="dashboard"
      fi
    fi
  fi

  export _TNX_FRAME_ACTIVE _TNX_FRAME_MODE _TNX_FRAME_TOTAL _TNX_FRAME_CUR
  export _TNX_FRAME_TITLE _TNX_FRAME_BACKEND _TNX_FRAME_USER _TNX_FRAME_PROFILE
  export _TNX_FRAME_COLS _TNX_FRAME_ROWS _TNX_TERM_COLS _TNX_TERM_ROWS
  export _TNX_SIZE_OK _TNX_FRAME_T0 _TNX_STREAM_LOG _TNX_ANIM

  tnx_log_info "Installation frame opened: mode=$_TNX_FRAME_MODE backend=$backend user=$user_name profile=$profile"
  if [ "$_TNX_FRAME_MODE" = "dashboard" ]; then
    trap '_TNX_RESIZE_PENDING=1' WINCH
    _tnx_frame_gather_device
    _tnx_frame_draw_dashboard "RUNNING"
  else
    local cols inner
    cols="$(_tnx_plain_cols)"
    inner=$(( cols - 4 ))
    printf '%s+%s+%s\n' "$TNX_CM" "$_TNX_RULE" "$TNX_C0"
    if (( inner >= 35 )); then
      _tnx_clipv "$inner" '***** ***** ****  *   * *   * *   *'
      printf '%s|%s %s%s%s\n' "$TNX_CM" "$TNX_CG" "$TNX_CW" "$_TNX_CLIP" "$TNX_C0"
      _tnx_clipv "$inner" '  *   *     *   * **  * *   *  * * '
      printf '%s|%s %s%s%s\n' "$TNX_CM" "$TNX_CC" "$TNX_CW" "$_TNX_CLIP" "$TNX_C0"
      _tnx_clipv "$inner" '  *   ***** *  ** * * * ***** *   *'
      printf '%s|%s %s%s%s\n' "$TNX_CM" "$TNX_CG" "$TNX_CW" "$_TNX_CLIP" "$TNX_C0"
    else
      _tnx_clipv "$inner" '*<== T E R N U X ==>*'
      printf '%s|%s %s%s%s\n' "$TNX_CM" "$TNX_CG" "$TNX_CW" "$_TNX_CLIP" "$TNX_C0"
    fi
    _tnx_clipv "$inner" 'Linux Workstation In Your Pocket'
    printf '%s|%s %s%s%s\n' "$TNX_CM" "$TNX_CD" "$TNX_CW" "$_TNX_CLIP" "$TNX_C0"
    _tnx_clipv "$inner" "v${TERNUX_VERSION}"
    printf '%s|%s %s%s%s\n' "$TNX_CM" "$TNX_CY" "$TNX_CW" "$_TNX_CLIP" "$TNX_C0"
    _tnx_clipv "$inner" 'by Sobuj Miah (@soobujmiah)'
    printf '%s|%s %s%s%s\n' "$TNX_CM" "$TNX_CD" "$TNX_CW" "$_TNX_CLIP" "$TNX_C0"
    printf '%s|%s %s%s%s\n' "$TNX_CM" "$TNX_CD" "$TNX_CW" "$_TNX_CLIP" "$TNX_C0"
    _tnx_clipv "$inner" 'Storage estimate: base ~3-4 GB; complete ~10-12 GB'
    printf '%s|%s %s%s%s\n' "$TNX_CM" "$TNX_CD" "$TNX_CW" "$_TNX_CLIP" "$TNX_C0"
    _tnx_clipv "$inner" 'Portfolio: soobujmiah.github.io'
    printf '%s|%s %s%s%s\n' "$TNX_CM" "$TNX_CY" "$TNX_CW" "$_TNX_CLIP" "$TNX_C0"
    printf '%s+%s+%s\n' "$TNX_CM" "$_TNX_RULE" "$TNX_C0"
  fi
}

# Update the fixed step/progress line in dashboard mode, or print a colored
# separator in append-only mode.
tnx_frame_phase() {
  local cur="$1" total="$2" title="$3"
  _TNX_FRAME_CUR="$cur"; _TNX_FRAME_TOTAL="$total"; _TNX_FRAME_TITLE="$title"
  export _TNX_FRAME_CUR _TNX_FRAME_TOTAL _TNX_FRAME_TITLE
  tnx_log_info "Phase $cur/$total: $title"

  # A dashboard can return after zooming back out or closing the keyboard.
  # Plain mode is append-only, so retry at phase boundaries before printing.
  if [ "${_TNX_FRAME_MODE:-off}" = "plain" ] && [ "${_TNX_TTY:-0}" = "1" ]; then
    _tnx_frame_refit || true
  fi

  if [ "${_TNX_FRAME_MODE:-off}" = "dashboard" ]; then
    # A phase stream runs in a pipeline subshell; a resize it handled cannot
    # propagate back, so the phase boundary re-measures before repainting.
    if ! _tnx_frame_refit; then
      _tnx_frame_paint_progress "$TNX_CC"
      _tnx_frame_paint_footer "$_TNX_FRAME_TICK"
    fi
  fi
  if [ "${_TNX_FRAME_MODE:-off}" = "dashboard" ]; then
    if [ -n "${_TNX_STREAM_LOG:-}" ]; then
      printf -- '--- [%s/%s] %s\n' "$cur" "$total" "$title" >> "${_TNX_STREAM_LOG:-}" 2>/dev/null || true
    fi
    _tnx_frame_paint_logline "--- [$cur/$total] $title"
  elif [ "${_TNX_FRAME_MODE:-off}" = "plain" ]; then
    local cols tmax
    cols="$(_tnx_plain_cols)"
    tmax=$(( cols - 6 - ${#cur} - ${#total} )); (( tmax < 3 )) && tmax=3
    _tnx_clipv "$tmax" "$title"
    printf '%s|%s %s[%s/%s]%s %s%s%s\n' "$TNX_CM" "$TNX_C0" "$TNX_CC" "$cur" "$total" \
      "$TNX_C0" "$TNX_CG" "$_TNX_CLIP" "$TNX_C0"
  else
    tnx_phase_header "$cur" "$total" "$title"
  fi
}

# ── Stream engine -----------------------------------------------------------
#
# Consume a command/phase stream and render it as one readable log:
#   * carriage-return progress (apt/dpkg/curl) collapses onto one row that
#     updates in place instead of scrolling the window away;
#   * partial reads are buffered, so a slowly arriving line is never split;
#   * bursts are coalesced to a readable rate with an explicit "+N lines"
#     marker — the complete stream always lands in the log file;
#   * the spinner and the resize check are driven from the same loop, so this
#     process stays the only writer to the terminal.

# Report lines that burst-coalescing held back, so the window never lies.
_tnx_flush_skipped() {
  (( ${_TNX_SKIPPED:-0} > 0 )) || return 0
  local n="$_TNX_SKIPPED" last="$_TNX_SKIPPED_LAST"
  _TNX_SKIPPED=0; _TNX_SKIPPED_LAST=""
  [ -n "$last" ] && _tnx_frame_paint_logline "$last"
  _tnx_frame_paint_logline "    ... +$n more lines (full log: $TERNUX_LOG_FILE)"
  _TNX_TRANSIENT=0
}

_tnx_stream_commit() {
  local raw="$1"
  # Keep only what a terminal would actually show for CR-updated output.
  while [ -n "$raw" ] && [ "${raw: -1}" = $'\r' ]; do raw="${raw:0:${#raw}-1}"; done
  raw="${raw##*$'\r'}"
  _tnx_stripv "$raw"
  local clean="$_TNX_TXT"

  # Record everything, always.
  printf '%s\n' "$clean" >> "$TERNUX_LOG_FILE" 2>/dev/null || true
  if [ -n "${_TNX_STREAM_LOG:-}" ]; then
    printf '%s\n' "$clean" >> "${_TNX_STREAM_LOG:-}" 2>/dev/null || true
  fi

  # Collapse runs of blank lines and exact repeats.
  case "$clean" in
    *[![:space:]]*) _TNX_LAST_BLANK=0 ;;
    *)
      [ "$_TNX_LAST_BLANK" = "1" ] && return 0
      _TNX_LAST_BLANK=1
      _TNX_LAST_LINE=""
      ;;
  esac
  if [ -n "$clean" ] && [ "$clean" = "$_TNX_LAST_LINE" ]; then
    return 0
  fi
  _TNX_LAST_LINE="$clean"

  if [ "$_TNX_MODE_DASH" = "1" ]; then
    _tnx_now
    if (( _TNX_NOW - _TNX_WIN_T0 >= 1000 )); then
      _tnx_flush_skipped
      _TNX_WIN_T0=$_TNX_NOW
      _TNX_WIN_N=0
    fi
    _TNX_WIN_N=$(( _TNX_WIN_N + 1 ))
    _tnx_line_color "$clean"
    if (( _TNX_WIN_N > _TNX_FLOOD_LINES )) && [ "$_TNX_IMPORTANT" != "1" ]; then
      _TNX_SKIPPED=$(( _TNX_SKIPPED + 1 ))
      _TNX_SKIPPED_LAST="$clean"
      return 0
    fi
    _tnx_flush_skipped
    _tnx_frame_paint_logline "$clean"
    _TNX_TRANSIENT=0
  else
    local inner=$(( _TNX_FRAME_COLS - 4 ))
    _tnx_clipv $(( inner - 1 )) "$clean"
    _tnx_line_color "$clean"
    printf '%s%s|%s %s%s%s\n' "${_TNX_EL:-}" "$TNX_CM" "$TNX_C0" "$_TNX_LC" "$_TNX_CLIP" "$TNX_C0"
    _TNX_TRANSIENT=0
  fi
}

# Render buffered, newline-less output (a progress bar) on one held row.
_tnx_stream_transient() {
  local raw="$1"
  [ "$_TNX_TTY" = "1" ] || return 0
  raw="${raw##*$'\r'}"
  case "$raw" in *[![:space:]]*) ;; *) return 0 ;; esac
  _tnx_now
  (( _TNX_NOW - _TNX_TRANS_T0 < _TNX_TRANSIENT_MS )) && return 0
  _TNX_TRANS_T0=$_TNX_NOW
  _tnx_stripv "$raw"
  if [ "$_TNX_MODE_DASH" = "1" ]; then
    _tnx_frame_paint_logline "$_TNX_TXT" 1
  else
    local inner=$(( _TNX_FRAME_COLS - 4 ))
    _tnx_clipv $(( inner - 1 )) "$_TNX_TXT"
    printf '\r\033[K%*s%s|%s %s%s%s\r' "$(( _TNX_FRAME_X - 1 ))" "" "$TNX_CM" "$TNX_C0" "$TNX_CD" "$_TNX_CLIP" "$TNX_C0"
  fi
  _TNX_TRANSIENT=1
}

_tnx_stream_idle() {
  # Animate at most every _TNX_ANIM_MS, poll for a resize at most every
  # _TNX_RESIZE_MS (a SIGWINCH short-circuits the poll).
  [ "$_TNX_MODE_DASH" = "1" ] || return 0
  _tnx_now
  if [ "${_TNX_RESIZE_PENDING:-0}" = "1" ] || (( _TNX_NOW - _TNX_RESIZE_T0 >= _TNX_RESIZE_MS )); then
    _TNX_RESIZE_PENDING=0
    _TNX_RESIZE_T0=$_TNX_NOW
    if _tnx_frame_refit; then
      [ "${_TNX_FRAME_MODE:-off}" = "dashboard" ] || _TNX_MODE_DASH=0
      _TNX_TRANSIENT=0
      return 0
    fi
  fi
  if [ "$_TNX_ANIM" = "1" ] && (( _TNX_NOW - _TNX_ANIM_T0 >= _TNX_ANIM_MS )); then
    _TNX_ANIM_T0=$_TNX_NOW
    _TNX_FRAME_TICK=$(( _TNX_FRAME_TICK + 1 ))
    _tnx_frame_paint_header "$_TNX_FRAME_TICK"
    _tnx_frame_paint_progress "${_TNX_SIG_COLORS[$((_TNX_FRAME_TICK % ${#_TNX_SIG_COLORS[@]}))]}"
    _tnx_frame_paint_footer "$_TNX_FRAME_TICK"
  fi
  if [ "${_TNX_LY_DEV_ON:-0}" = "1" ]; then
    local old_cpu="${_TNX_FRAME_DEV_VALUES[4]:-}"
    _tnx_frame_cpu_sample
    if [ "${_TNX_FRAME_DEV_VALUES[4]:-}" != "$old_cpu" ]; then
      _tnx_frame_paint_device
    fi
  fi
  if (( _TNX_NOW - _TNX_WIN_T0 >= 1000 )); then
    _tnx_flush_skipped
    _TNX_WIN_T0=$_TNX_NOW
    _TNX_WIN_N=0
  fi
  return 0
}

tnx_frame_stream() {
  [ "${_TNX_FRAME_MODE:-off}" = "off" ] && { cat; return; }

  local line="" buf="" rc=0
  _TNX_MODE_DASH=0
  [ "${_TNX_FRAME_MODE:-off}" = "dashboard" ] && _TNX_MODE_DASH=1
  if [ "$_TNX_MODE_DASH" = "1" ]; then
    _tnx_frame_layout
  else
    _tnx_plain_cols >/dev/null
  fi

  _TNX_EL=""
  [ "$_TNX_TTY" = "1" ] && _TNX_EL=$'\r\033[K'
  _TNX_LAST_LINE=""; _TNX_LAST_BLANK=1; _TNX_TRANSIENT=0
  _TNX_SKIPPED=0; _TNX_SKIPPED_LAST=""; _TNX_WIN_N=0
  _tnx_now
  _TNX_WIN_T0=$_TNX_NOW; _TNX_ANIM_T0=$_TNX_NOW
  _TNX_RESIZE_T0=$_TNX_NOW; _TNX_TRANS_T0=0
  _TNX_RESIZE_PENDING=0
  trap '_TNX_RESIZE_PENDING=1' WINCH

  while :; do
    if IFS= read -r -t "$_TNX_READ_TIMEOUT" line; then
      buf+="$line"
      _tnx_stream_commit "$buf"
      buf=""
    else
      rc=$?
      # A timed-out read keeps whatever it consumed in $line: append it so a
      # slowly produced line is reassembled instead of being cut in half.
      buf+="$line"
      if (( rc > 128 )); then
        [ -n "$buf" ] && _tnx_stream_transient "$buf"
        _tnx_stream_idle
        continue
      fi
      [ -n "$buf" ] && _tnx_stream_commit "$buf"
      break
    fi
  done

  _tnx_flush_skipped
  # Release the row this subshell was drawing on: the parent process keeps
  # writing to the same terminal and cannot see this shell's cursor state.
  if [ "$_TNX_MODE_DASH" = "1" ]; then
    if [ "${_TNX_NEED_NL:-0}" = "1" ] || [ "$_TNX_TRANSIENT" = "1" ]; then printf '\n'; fi
  elif [ "$_TNX_TRANSIENT" = "1" ]; then
    printf '\n'
  fi
  _TNX_TRANSIENT=0
  trap - WINCH
}

# ── Close / restore ---------------------------------------------------------

# Restore terminal state even when called by a signal/EXIT trap.
tnx_frame_restore_terminal() {
  if [ "${_TNX_FRAME_MODE:-off}" = "dashboard" ]; then
    printf '\033[r\033[?25h' 2>/dev/null || true
  fi
}

tnx_frame_close() {
  local status="${1:-failed}" failed_cur="${2:-${_TNX_FRAME_CUR:-0}}"
  local failed_title="${3:-${_TNX_FRAME_TITLE:-installation phase}}" state="FAILED"
  local reserved=0
  [ "$status" = "success" ] && state="COMPLETE"
  tnx_log_info "Installation frame closed: $status"

  if [ "${_TNX_FRAME_MODE:-off}" = "plain" ] && [ "${_TNX_TTY:-0}" = "1" ]; then
    _tnx_frame_refit || true
  fi

  if [ "${_TNX_FRAME_MODE:-off}" = "dashboard" ]; then
    # The last phase ran in a subshell: re-measure before the final paint or
    # the closing frame would be drawn at a stale width.
    if _tnx_measure; then
      _tnx_apply_size
      _tnx_frame_fits || { _TNX_FRAME_MODE="plain"; printf '\033[r\033[?25h\033[2J\033[H'; }
    fi
  fi

  if [ "${_TNX_FRAME_MODE:-off}" = "dashboard" ]; then
    if [ "$status" = "success" ]; then
      _TNX_FRAME_TITLE="Installation complete"
      _TNX_FRAME_CUR="$_TNX_FRAME_TOTAL"
    else
      _TNX_FRAME_TITLE="Failed: $failed_title"
      _TNX_FRAME_CUR="$failed_cur"
    fi
    export _TNX_FRAME_TITLE _TNX_FRAME_CUR
    _TNX_ANIM=0
    # Reserve the last rows for a scrollback-friendly recap so the final frame
    # is not pushed off the screen by it.
    if (( _TNX_FRAME_ROWS >= 17 )); then
      _TNX_FRAME_ROWS=$(( _TNX_FRAME_ROWS - 3 ))
      reserved=1
    fi
    _tnx_frame_draw_dashboard "$state"
    tnx_frame_restore_terminal
    # Hand the terminal back below the frame; a dashboard cannot be scrolled,
    # so the outcome and the log path are repeated as ordinary text.
    if [ "$reserved" = "1" ]; then
      printf '\033[%d;1H' "$(( _TNX_FRAME_ROWS + 1 ))"
    else
      printf '\033[%d;1H\n' "$_TNX_FRAME_ROWS"
    fi
    if [ "$status" = "success" ]; then
      printf '\033[K%s[ OK ]%s  Installation complete - %s/%s phases.\n' \
        "$TNX_CG" "$TNX_C0" "$_TNX_FRAME_CUR" "$_TNX_FRAME_TOTAL"
    else
      printf '\033[K%s[FAIL]%s  Stopped at phase %s/%s: %s\n' \
        "$TNX_CR" "$TNX_C0" "$failed_cur" "$_TNX_FRAME_TOTAL" "$failed_title"
    fi
    printf '\033[K%sFull log:%s %s\n' "$TNX_CD" "$TNX_C0" "$TERNUX_LOG_FILE"
  elif [ "${_TNX_FRAME_MODE:-off}" = "plain" ]; then
    local color="$TNX_CR"
    [ "$status" = "success" ] && color="$TNX_CG"
    _tnx_plain_cols >/dev/null
    printf '%s|%s %sInstallation %s%s\n' "$TNX_CM" "$TNX_C0" "$color" "$status" "$TNX_C0"
    printf '%s+%s+%s\n' "$TNX_CM" "$_TNX_RULE" "$TNX_C0"
    printf '%sFull log:%s %s\n' "$TNX_CD" "$TNX_C0" "$TERNUX_LOG_FILE"
  fi
  trap - WINCH 2>/dev/null || true
  _TNX_FRAME_ACTIVE=0
  _TNX_FRAME_MODE="off"
  export _TNX_FRAME_ACTIVE _TNX_FRAME_MODE
}

# ── Banner -----------------------------------------------------------------
tnx_banner() {
  # Installer branding is rendered in the persistent frame, not flashed before it.
  return 0
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
  local pairs=("$@") w=52 i k v row cols maxw prefix remaining word line content
  cols="${COLUMNS:-}"
  if [ -t 1 ]; then cols="$(stty size < /dev/tty 2>/dev/null | awk '{print $2}')"; fi
  [[ "$cols" =~ ^[0-9]+$ ]] || cols=80
  (( cols > 100 )) && cols=100
  # Keep a clear gutter around the plan: Android floating edge panels can
  # cover the terminal's last few cells without changing the reported width.
  if (( cols >= 48 )); then w=$((cols - 8)); else w=$((cols - 6)); fi
  (( w > 76 )) && w=76; (( w < 10 )) && w=10
  maxw=$((w - 2))
  printf '\n  %s+%s+%s\n' "$TNX_CM" "$(_tnx_repeat '-' "$w")" "$TNX_C0"
  printf -v row '%-*.*s' "$((w - 2))" "$((w - 2))" "$title"
  printf '  %s|%s %s%s%s %s|%s\n' "$TNX_CM" "$TNX_C0" "$TNX_CG" "$row" "$TNX_C0" "$TNX_CM" "$TNX_C0"
  printf '  %s+%s+%s\n' "$TNX_CM" "$(_tnx_repeat '-' "$w")" "$TNX_C0"
  for ((i=0; i<${#pairs[@]}; i+=2)); do
    k="${pairs[$i]}"; v="${pairs[$((i+1))]}"
    prefix="$k:"
    if (( ${#prefix} >= maxw )); then prefix="${prefix:0:$((maxw - 1))}"; fi
    remaining="${v:-}"
    if [ -z "$remaining" ]; then printf '  %s|%s %s%-*s%s %s|%s\n' "$TNX_CM" "$TNX_C0" "$TNX_CW" "$maxw" "$prefix" "$TNX_C0" "$TNX_CM" "$TNX_C0"; continue; fi
    line="$prefix"
    while [ -n "$remaining" ]; do
      word="${remaining%% *}"
      if [ "$word" = "$remaining" ]; then remaining=""; else remaining="${remaining#* }"; fi
      if (( ${#line} > 0 && ${#line} + ${#word} + 1 > maxw )); then
        printf '  %s|%s %s%-*s%s %s|%s\n' "$TNX_CM" "$TNX_C0" "$TNX_CW" "$maxw" "$line" "$TNX_C0" "$TNX_CM" "$TNX_C0"
        line="  $word"
      else
        line+=" "
        line+="$word"
      fi
    done
    printf '  %s|%s %s%-*s%s %s|%s\n' "$TNX_CM" "$TNX_C0" "$TNX_CW" "$maxw" "$line" "$TNX_C0" "$TNX_CM" "$TNX_C0"
  done
  printf '  %s+%s+%s\n' "$TNX_CM" "$(_tnx_repeat '-' "$w")" "$TNX_C0"
}

tnx_celebrate() {
  [ "${TERNUX_QUIET:-0}" = "1" ] && return 0
  _tnx_sigv 0
  printf '\n  %s== %sI N S T A L L   C O M P L E T E%s ==%s\n' "$TNX_CG" "$TNX_CW" "$TNX_CG" "$TNX_C0"
  printf '  %sdesktop - GPU - audio - host CLI - guest companion verified%s\n' "$TNX_CD" "$TNX_C0"
  printf '  %sbuilt with <3 by %s%s%s\n' "$TNX_CD" "$TNX_C0" "$_TNX_SIG" "$TNX_C0"
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
