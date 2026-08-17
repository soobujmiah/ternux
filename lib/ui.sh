# =============================================================================
#  ternux — UI library (animated banners, live status, progress, celebration)
#  Visual identity with color, motion, and liveness.
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah) — MIT License
#  https://github.com/soobujmiah/ternux
# =============================================================================

# shellcheck source=lib/core.sh
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"

# ── Color aliases (already defined in core.sh, used here for convenience) ──
# TNX_C0 reset, TNX_CG green, TNX_CC cyan, TNX_CY yellow, TNX_CR red,
# TNX_CM magenta, TNX_CB blue, TNX_CW white, TNX_CD dim

# ── Rainbow signature ──────────────────────────────────────────────────────
_TNX_SIG_NAME="Sobuj Miah"
_TNX_SIG_COLORS=("$TNX_CG" "$TNX_CC" "$TNX_CY" "$TNX_CM" "$TNX_CB" "$TNX_CW")

_tnx_sig() {
  local tick="${1:-0}" n=${#_TNX_SIG_NAME}
  local i phase ch
  phase=$(( tick % 6 ))
  for ((i=0; i<n; i++)); do
    ch="${_TNX_SIG_NAME:$i:1}"
    [ "$ch" = " " ] && printf ' ' || printf '%s%s%s' "${_TNX_SIG_COLORS[$(((i+phase)%6))]}" "$ch" "$TNX_C0"
  done
}

# ── Animated banner — matrix-style reveal ──────────────────────────────────
tnx_banner() {
  [ "${TERNUX_QUIET:-0}" = "1" ] && return 0
  if [ ! -t 1 ] || [ -z "$TNX_C0" ]; then
    # Plain text fallback
    echo "ternux v${TERNUX_VERSION} — Linux desktop for Android with Zink and VirGL graphics routes"
    echo "${TERNUX_REPO}"
    echo ""
    return 0
  fi
  local rows=(
    "  _______ ______ _____  _   _ _    ___   __"
    " |__   __|  ____|  __ \| \ | | |  | \ \ / /"
    "    | |  | |__  | |__) |  \| | |  | |\ V /"
    "    | |  |  __| |  _  /| . \` | |  | | > <"
    "    | |  | |____| | \ \| |\  | |__| |/ . \\"
    "    |_|  |______|_|  \_\_| \_|\____//_/ \_\\"
  )
  local charset="░▒▓#%&*+=<>/|01"
  local i j pass len ch out grad=0
  [ -n "$TNX_C0" ] && grad=1

  # Animated reveal (3 passes)
  for pass in 1 2 3; do
    for i in 0 1 2 3 4 5; do
      [ "$grad" = "1" ] && printf "\033[1;38;5;%dm" "$((34 + i * 3))"
      len=${#rows[$i]}; out=""
      for ((j=0; j<len; j++)); do
        ch="${rows[$i]:$j:1}"
        [ "$ch" = " " ] && out+=" " && continue
        [ "$pass" -eq 3 ] || [ $((RANDOM % (4 - pass))) -eq 0 ] && out+="$ch" || out+="${charset:$((RANDOM % ${#charset})):1}"
      done
      printf "%s${TNX_C0}\n" "$out"
    done
    [ "$pass" -lt 3 ] && { sleep 0.07; printf '\033[6A'; }
  done
  sleep 0.05

  # Tagline
  printf "  ${TNX_CG}Linux desktop for Android with Zink and VirGL graphics routes${TNX_C0}\n"

  # Animated signature line
  local t2=0
  while [ "$t2" -lt 12 ]; do
    printf "\r  ${TNX_CD}v${TERNUX_VERSION} · by ${TNX_C0}$(_tnx_sig "$t2")${TNX_CD} · MIT${TNX_C0}   "
    sleep 0.05
    t2=$((t2+1))
  done
  printf "\r  ${TNX_CD}v${TERNUX_VERSION} · by ${TNX_C0}$(_tnx_sig 0)${TNX_CD} · MIT${TNX_C0}\n\n"
}

# ── Phase header with billboard ────────────────────────────────────────────
# Shows:  [3/11]  GPU driver setup (zink)
#         ═══════════════════════════════════
tnx_phase_header() {
  [ "${TERNUX_QUIET:-0}" = "1" ] && return 0
  local num="${1:-?}" total="${2:-9}" title="$3"
  local w=30 i=0
  echo ""
  # Sweeping top rule
  printf "  ${TNX_CM}"
  while [ "$i" -lt "$w" ]; do printf '━'; sleep 0.005; i=$((i+1)); done
  printf "${TNX_C0}\n"
  # Title line
  printf "  ${TNX_CW}[%s/%s]${TNX_C0}  ${TNX_CG}%s${TNX_C0}\n" "$num" "$total" "$title"
  # Sweeping bottom rule
  i=0; printf "  ${TNX_CD}"
  while [ "$i" -lt "$w" ]; do printf '─'; sleep 0.003; i=$((i+1)); done
  printf "${TNX_C0}\n"
}

# ── Live status line during operations ─────────────────────────────────────
# Shows:  ⠋ [2/11] ██▓░░░░░░░  Installing packages  ▮░░░░░░░░░░░  03:45
tnx_live_status() {
  local tick="$1" cur="$2" tot="$3" label="$4"
  local spin=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  local frame="${spin[$((tick % 10))]}"
  local w=10 j=0 bar="" p

  # Phase bar
  while [ "$j" -lt $((cur * w / tot)) ]; do bar="${bar}█"; j=$((j+1)); done
  while [ "$j" -lt "$w" ]; do bar="${bar}░"; j=$((j+1)); done

  # Sliding activity track
  local tw=8 bw=2 span
  span=$((2*(tw-bw)))
  p=$(( tick % span ))
  [ "$p" -gt $((tw - bw)) ] && p=$((span - p))
  local track=""
  for j in $(seq 0 $((tw-1))); do
    [ "$j" -ge "$p" ] && [ "$j" -lt $((p+bw)) ] && track="${track}${TNX_CG}▮${TNX_C0}" || track="${track}${TNX_CD}░${TNX_C0}"
  done

  local mins secs
  mins=$((SECONDS / 60)) secs=$((SECONDS % 60))
  printf "\r${TNX_CC}%s${TNX_C0} ${TNX_CD}[%d/%d]${TNX_C0} ${TNX_CG}%s${TNX_C0} ${TNX_CW}%-24.24s${TNX_C0} %s ${TNX_CD}%02d:%02d${TNX_C0}" \
    "$frame" "$cur" "$tot" "$bar" "$label" "$track" "$mins" "$secs"
}

tnx_live_clear() { printf "\r\033[K"; }

# ── Spinner wrapper with live status ───────────────────────────────────────
tnx_spin_run() {
  local label="$1"; shift
  local rc=0 cur="${_TNX_PHASE_CUR:-0}" tot="${_TNX_PHASE_TOT:-1}"
  [ "$tot" -eq 0 ] && tot=1
  [ "${TERNUX_QUIET:-0}" = "1" ] && { "$@" 2>/dev/null; return $?; }

  "$@" >/dev/null 2>&1 &
  local pid=$! i=0

  while kill -0 "$pid" 2>/dev/null; do
    tnx_live_status "$i" "$cur" "$tot" "$label"
    i=$((i+1))
    sleep 0.08
  done
  wait "$pid"; rc=$?
  tnx_live_clear

  if [ "$rc" -eq 0 ]; then
    printf "${TNX_CG}✓${TNX_C0}  %s\n" "$label"
  else
    printf "${TNX_CR}✗${TNX_C0}  %s\n" "$label"
  fi
  return "$rc"
}

# ── Phase checklist (shown at end) ─────────────────────────────────────────
# Shows:  pkg ✓   deb ✓   gpu ✓   aud ✓   lnc ✓   als ✓   ext ·   phm ✓   ver ✓
tnx_phase_checklist() {
  [ "${TERNUX_QUIET:-0}" = "1" ] && return 0
  local phases=("$@")
  local short=("pkg" "deb" "gpu" "aud" "lnc" "als" "ext" "phm" "ver" "cli")
  local i idx mark out=""
  for i in "${!phases[@]}"; do
    idx=$((i))
    if tnx_state_done "phase_${phases[$i]}" 2>/dev/null; then
      mark="${TNX_CG}✓${TNX_C0}"
    else
      mark="${TNX_CD}·${TNX_C0}"
    fi
    out="${out}${TNX_CD}${short[$idx]:-$idx}${TNX_C0}${mark}  "
  done
  printf "  %s\n" "$out"
}

# ── Summary box (bordered, colored) ────────────────────────────────────────
tnx_summary_box() {
  [ "${TERNUX_QUIET:-0}" = "1" ] && return 0
  local title="$1"; shift
  local pairs=("$@")
  local w=46

  echo ""
  printf "  ${TNX_CD}┌%s┐${TNX_C0}\n" "$(printf '─%.0s' $(seq 1 $w))"
  printf "  ${TNX_CD}│${TNX_C0} ${TNX_CG}%s${TNX_C0}${TNX_CD}%s${TNX_CD}│${TNX_C0}\n" "$title" "$(printf ' %.0s' $(seq 1 $((w - ${#title}))))"
  printf "  ${TNX_CD}│${TNX_C0}%s${TNX_CD}│${TNX_C0}\n" "$(printf '─%.0s' $(seq 1 $w))"

  local i
  for ((i=0; i<${#pairs[@]}; i+=2)); do
    local k="${pairs[$i]}" v="${pairs[$((i+1))]}"
    printf "  ${TNX_CD}│${TNX_C0} ${TNX_CW}%-18s${TNX_C0} %s\n" "$k:" "$v"
  done
  printf "  ${TNX_CD}└%s┘${TNX_C0}\n" "$(printf '─%.0s' $(seq 1 $w))"
}

# ── Celebration ────────────────────────────────────────────────────────────
tnx_celebrate() {
  [ "${TERNUX_QUIET:-0}" = "1" ] && return 0
  printf "\n  ${TNX_CG}▐▓▒░ ${TNX_CW}I N S T A L L   C O M P L E T E${TNX_CG} ░▒▓▌${TNX_C0}\n"
  printf "  ${TNX_CD}   desktop · GPU · audio — all verified${TNX_C0}\n"
  local i=0
  while [ "$i" -lt 12 ]; do
    printf "\r  ${TNX_CD}   built with ♥ by ${TNX_C0}$(_tnx_sig "$i")   "
    sleep 0.05
    i=$((i+1))
  done
  printf "\r  ${TNX_CD}   built with ♥ by ${TNX_C0}$(_tnx_sig 0)\n"
}

# ── Next steps ─────────────────────────────────────────────────────────────
tnx_next_steps() {
  [ "${TERNUX_QUIET:-0}" = "1" ] && return 0
  local steps=("$@")
  printf "\n${TNX_CW}Next steps${TNX_C0}\n"
  local i
  for i in "${!steps[@]}"; do
    printf "  ${TNX_CC}%d.${TNX_C0} %s\n" "$((i+1))" "${steps[$i]}"
  done
  echo ""
}
