# =============================================================================
#  ternux — log management
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah)
#  Licensed under the Apache License, Version 2.0.
#  https://github.com/soobujmiah/ternux
# =============================================================================

# shellcheck source=lib/core.sh
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"

# ---------------------------------------------------------------------------
# tnx_cmd_logs
# ---------------------------------------------------------------------------
tnx_cmd_logs() {
  local subcmd="${1:-show}"
  shift 2>/dev/null || true

  case "$subcmd" in
    show|--show)   _tnx_logs_show "${1:-50}" ;;
    tail|--tail)   _tnx_logs_tail ;;
    view|--view)   _tnx_logs_view "${1:-$TERNUX_LOG_FILE}" ;;
    desktop|session) _tnx_logs_desktop "${1:-show}" "${2:-}" ;;
    clear|--clear) _tnx_logs_clear ;;
    list|--list)   _tnx_logs_list ;;
    --help|-h)     tnx_help_logs ;;
    *) tnx_fail "Usage: ternux logs [show|tail|view [FILE]|clear|list]"; return 1 ;;
  esac
}

_tnx_logs_show() {
  local lines="${1:-50}"
  [ ! -f "$TERNUX_LOG_FILE" ] && { tnx_info "No log file found: $TERNUX_LOG_FILE"; return 0; }

  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    local content
    content="$(tail -n "$lines" "$TERNUX_LOG_FILE" 2>/dev/null)"
    content="${content//\"/\\\"}"
    content="${content//$'\n'/\\n}"
    tnx_json_object "logs" "ok" "log_file" "$TERNUX_LOG_FILE" \
      "lines" "$lines" \
      "available" "$(wc -l < "$TERNUX_LOG_FILE" 2>/dev/null || echo 0)" \
      "content" "$content"
    return 0
  fi

  tnx_header "Ternux Logs"
  printf "  ${TNX_CD}File: %s${TNX_C0}\n" "$TERNUX_LOG_FILE"
  printf "  ${TNX_CD}Size: %s lines${TNX_C0}\n" "$(wc -l < "$TERNUX_LOG_FILE" 2>/dev/null || echo 0)"
  echo ""
  tail -n "$lines" "$TERNUX_LOG_FILE" | while IFS= read -r line; do printf "  %s\n" "$line"; done
  echo ""
}

_tnx_logs_tail() {
  [ ! -f "$TERNUX_LOG_FILE" ] && { tnx_fail "No log file found"; return 1; }
  tnx_info "Tailing: $TERNUX_LOG_FILE (Ctrl+C to stop)"
  echo ""
  tail -f "$TERNUX_LOG_FILE"
}

_tnx_logs_clear() {
  [ ! -f "$TERNUX_LOG_FILE" ] && { tnx_info "No log to clear"; return 0; }
  tnx_confirm "Clear $TERNUX_LOG_FILE?" || { tnx_info "Cancelled"; return 0; }
  : > "$TERNUX_LOG_FILE"
  tnx_ok "Log cleared"
  [ "${TERNUX_JSON:-0}" = "1" ] && tnx_json_object "logs" "cleared"
  return 0
}

_tnx_logs_list() {
  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    local files=""
    [ -d "$TERNUX_LOG_DIR" ] && files="$(ls -1 "$TERNUX_LOG_DIR" 2>/dev/null | tr '\n' ',' | sed 's/,$//')"
    tnx_json_object "logs" "ok" "log_dir" "$TERNUX_LOG_DIR" "files" "$files"
    return 0
  fi

  tnx_header "Log Files"
  local found=0 file
  if [ -d "$TERNUX_LOG_DIR" ]; then
    ls -lh "$TERNUX_LOG_DIR" 2>/dev/null | awk 'NR>1{printf "  %s %5s %s\n", $1, $5, $9}'
    found=1
  fi
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    printf "  %s  %s bytes  %s\n" "$(date -r "$file" '+%Y-%m-%d %H:%M' 2>/dev/null || echo unknown)" "$(wc -c < "$file" 2>/dev/null || echo 0)" "$file"
    found=1
  done < <(find "$TERNUX_STATE_DIR/session" "$TERNUX_STATE_DIR/distros" -type f -name 'desktop.log*' -print 2>/dev/null | sort)
  [ "$found" -eq 1 ] || tnx_info "No log files found"
  echo ""
}

_tnx_logs_desktop() {
  local action="${1:-show}" distro="${2:-}" file
  if [ -z "${2:-}" ] && tnx_distro_known "$(tnx_distro_canonical "$action")"; then
    distro="$action"
    action=show
  fi
  if [ "$action" != show ] && [ "$action" != tail ]; then
    tnx_fail "Usage: tx logs desktop [show|tail] [DISTRO]"
    return 2
  fi
  if [ -z "$distro" ]; then
    distro="$(cat "$TERNUX_STATE_DIR/session/distro" 2>/dev/null || true)"
    [ -n "$distro" ] || distro="${TERNUX_DISTRO:-$(tnx_distro)}"
  fi
  distro="$(tnx_distro_canonical "$distro")"
  tnx_distro_known "$distro" || { tnx_fail "Unknown managed guest: $distro"; return 2; }
  file="$(tnx_distro_session_dir "$distro")/desktop.log"
  [ -f "$file" ] || { tnx_info "No desktop log found: $file"; return 0; }
  case "$action" in
    tail) tnx_info "Tailing desktop log: $file (Ctrl+C to stop)"; tail -f "$file" ;;
    show) tnx_header "Desktop Session Log: $distro"; printf "  File: %s\n  Lines: %s\n\n" "$file" "$(wc -l < "$file" 2>/dev/null || echo 0)"; tail -n 100 "$file" ;;
    *) tnx_fail "Usage: ternux logs desktop [show|tail]"; return 1 ;;
  esac
}

# ---------------------------------------------------------------------------
# Advanced Log Viewer (V3-PLAN.md workstream 08): pause, search, export and
# scroll on top of a live-following pager. Built on lib/ui.sh's existing
# kernel-measured geometry (_tnx_measure) and the raw-keypress-with-resize-
# poll pattern already used by lib/phases.sh's distro picker, rather than
# reimplementing either. Falls back to a plain `show` dump whenever there
# is no interactive terminal to drive it from (piped output, dumb TERM,
# non-interactive CI) — same graceful-degradation rule as that picker.
# ---------------------------------------------------------------------------
# Plain, non-interactive dump of the requested FILE — not necessarily
# $TERNUX_LOG_FILE, so this cannot reuse _tnx_logs_show (which is tied to
# that one specific log).
_tnx_logs_view_fallback() {
  local file="$1"
  tnx_header "Ternux Logs"
  printf "  ${TNX_CD}File: %s${TNX_C0}\n" "$file"
  printf "  ${TNX_CD}Size: %s lines${TNX_C0}\n" "$(wc -l < "$file" 2>/dev/null || echo 0)"
  echo ""
  tail -n 200 "$file" | while IFS= read -r line; do printf "  %s\n" "$line"; done
  echo ""
}

_tnx_logs_view() {
  local file="${1:-$TERNUX_LOG_FILE}"
  [ -f "$file" ] || { tnx_fail "No log file found: $file"; return 1; }

  # /dev/tty is not always available to the controlling process (observed
  # on CI containers) even when stdin itself is a real terminal — mirror
  # lib/phases.sh's tnx_prompt_distro, which tries /dev/tty first and
  # falls back to stdin, rather than assuming /dev/tty always works.
  # Everything below keeps assuming fd 3 uniformly either way.
  if { exec 3<>/dev/tty; } 2>/dev/null; then :
  elif [ -t 0 ]; then exec 3<&0
  else
    _tnx_logs_view_fallback "$file"
    return 0
  fi
  # Deliberately not checking $TERM here: it reflects the environment's
  # declared terminal capabilities, not whether fd 3 is a real tty that
  # can be put in raw mode — lib/phases.sh's distro/workload pickers
  # already rely on -t alone for the same reason, and TERM=dumb is
  # routinely set even under a real pty (observed on CI).
  if ! [ -t 3 ]; then
    exec 3<&-
    _tnx_logs_view_fallback "$file"
    return 0
  fi

  # shellcheck source=lib/ui.sh
  . "$(dirname "${BASH_SOURCE[0]}")/ui.sh"

  local old_stty
  old_stty="$(stty -g <&3 2>/dev/null || true)"
  if [ -z "$old_stty" ] || ! stty -echo -icanon min 1 time 0 <&3 2>/dev/null; then
    [ -n "$old_stty" ] && stty "$old_stty" <&3 2>/dev/null
    exec 3<&-
    _tnx_logs_view_fallback "$file"
    return 0
  fi
  trap '_tnx_logs_view_cleanup "$old_stty"' INT TERM EXIT

  local -a lines=()
  mapfile -t lines < <(tail -n 20000 -- "$file" 2>/dev/null)
  local total="${#lines[@]}" offset=0 follow=1 search="" match_idx=-1
  local -a matches=()
  local last_size
  last_size="$(wc -c < "$file" 2>/dev/null || echo 0)"
  _tnx_measure

  local body_rows key seq read_status size

  while :; do
    body_rows=$(( _TNX_TERM_ROWS - 2 )); (( body_rows < 1 )) && body_rows=1
    if [ "$follow" -eq 1 ]; then
      offset=$(( total - body_rows )); (( offset < 0 )) && offset=0
    fi
    _tnx_logs_view_draw "$body_rows"

    IFS= read -r -s -n 1 -t 0.5 -u 3 key
    read_status=$?
    # `if cond; then ...; fi` with no else is 0 whenever cond is false,
    # regardless of cond's own exit status — the read's actual status
    # must be captured right here, not inferred from the if construct,
    # or every idle poll (any read that times out) would be
    # indistinguishable from true EOF/signal and kill the viewer.
    if (( read_status == 0 )); then
      case "$key" in
        j) follow=0; (( offset + 1 <= total - 1 )) && offset=$(( offset + 1 )) ;;
        k) follow=0; (( offset > 0 )) && offset=$(( offset - 1 )) ;;
        ' ') follow=0; offset=$(( offset + body_rows )); (( offset > total - 1 )) && offset=$(( total - 1 )); (( offset < 0 )) && offset=0 ;;
        b) follow=0; offset=$(( offset - body_rows )); (( offset < 0 )) && offset=0 ;;
        g) follow=0; offset=0 ;;
        G) follow=0; offset=$(( total - body_rows )); (( offset < 0 )) && offset=0 ;;
        $'\033')
          IFS= read -r -s -n 2 -t 1 -u 3 seq || seq=""
          case "$seq" in
            '[A') follow=0; (( offset > 0 )) && offset=$(( offset - 1 )) ;;
            '[B') follow=0; (( offset + 1 <= total - 1 )) && offset=$(( offset + 1 )) ;;
          esac
          ;;
        f) follow=1 ;;
        /) _tnx_logs_view_search; follow=0 ;;
        n) _tnx_logs_view_jump_match 1; follow=0 ;;
        N) _tnx_logs_view_jump_match -1; follow=0 ;;
        e) _tnx_logs_view_export ;;
        q|Q) break ;;
      esac
      continue
    fi
    if (( read_status <= 128 )); then break; fi

    size="$(stty size <&3 2>/dev/null || true)"
    if [ -n "$size" ]; then
      local new_rows="${size%% *}" new_cols="${size##* }"
      [ "$new_rows" != "$_TNX_TERM_ROWS" ] || [ "$new_cols" != "$_TNX_TERM_COLS" ] && _tnx_measure
    fi

    if [ "$follow" -eq 1 ]; then
      local current_size
      current_size="$(wc -c < "$file" 2>/dev/null || echo 0)"
      if [ "$current_size" -lt "$last_size" ]; then
        lines=(); mapfile -t lines < <(tail -n 20000 -- "$file" 2>/dev/null)
        total="${#lines[@]}"; matches=(); search=""; match_idx=-1
      elif [ "$current_size" -gt "$last_size" ]; then
        local -a new_lines=()
        mapfile -t new_lines < <(tail -c "+$(( last_size + 1 ))" -- "$file" 2>/dev/null)
        lines+=("${new_lines[@]}")
        total="${#lines[@]}"
        # Keep the in-memory buffer bounded during a long-running live
        # follow session (the same 20000-line cap the initial load uses).
        if (( total > 20000 )); then
          lines=("${lines[@]: -20000}")
          total=20000
          matches=(); search=""; match_idx=-1
        fi
      fi
      last_size="$current_size"
    fi
  done

  _tnx_logs_view_cleanup "$old_stty"
  trap - INT TERM EXIT
}

_tnx_logs_view_draw() {
  local body_rows="$1" i start end ln
  printf '\033[H\033[2J' >&2
  start=$offset; end=$(( offset + body_rows )); (( end > total )) && end=$total
  for (( i = start; i < end; i++ )); do
    ln="${lines[$i]}"
    # Wide characters (CJK, emoji) occupy two terminal cells but count as
    # one character to a bash substring, so clipping by character count
    # can overshoot the measured column width; _tnx_clipv (lib/ui.sh)
    # already clips by display-cell width for exactly this reason.
    _tnx_clipv "$_TNX_TERM_COLS" "$ln"
    if [ -n "$search" ] && [[ "$ln" == *"$search"* ]]; then
      printf '%s%s%s\n' "$TNX_CY" "$_TNX_CLIP" "$TNX_C0" >&2
    else
      printf '%s\n' "$_TNX_CLIP" >&2
    fi
  done
  local follow_label="LIVE"
  [ "$follow" -eq 1 ] || follow_label="PAUSED"
  local search_label=""
  [ -n "$search" ] && search_label="  search: ${search} (${#matches[@]} match(es))"
  printf '%s%s%s\n' "$TNX_CM" "$(printf '%*s' "$(( _TNX_TERM_COLS - 1 ))" '' | tr ' ' '-')" "$TNX_C0" >&2
  printf '%s[%s]%s line %s/%s%s  %sj/k scroll  space/b page  g/G top/bot  / search  n/N next/prev  e export  f follow  q quit%s\n' \
    "$TNX_CY" "$follow_label" "$TNX_C0" "$(( offset + 1 ))" "$total" "$search_label" "$TNX_CD" "$TNX_C0" >&2
}

# Reads one line of input a raw character at a time, entirely without
# toggling stty modes. Rapid synthetic input (as a test drives, or a
# paste) can arrive before a mode switch takes effect and race with the
# terminal's own canonical line buffering — staying in the same raw mode
# used by the main key loop the whole time avoids that race outright,
# and is simple enough not to need real line editing beyond backspace.
_tnx_logs_view_read_line() {
  local prompt="$1" buf="" ch
  printf '%s' "$prompt" >&2
  while IFS= read -r -s -n 1 -u 3 ch; do
    # `read -n 1` strips both CR and LF from the character it returns, so
    # a successful read with an empty $ch is Enter, not a literal
    # zero-length character — there is no other way to tell them apart.
    [ -n "$ch" ] || break
    case "$ch" in
      $'\177'|$'\010')
        if [ -n "$buf" ]; then buf="${buf%?}"; printf '\b \b' >&2; fi
        ;;
      *) buf+="$ch"; printf '%s' "$ch" >&2 ;;
    esac
  done
  printf '%s' "$buf"
}

_tnx_logs_view_search() {
  local pattern i
  printf '\033[H\033[2J' >&2
  pattern="$(_tnx_logs_view_read_line '/')"
  search="$pattern"
  matches=()
  match_idx=-1
  [ -n "$search" ] || return 0
  for (( i = 0; i < total; i++ )); do
    [[ "${lines[$i]}" == *"$search"* ]] && matches+=("$i")
  done
  (( ${#matches[@]} > 0 )) && { match_idx=0; offset="${matches[0]}"; }
}

_tnx_logs_view_jump_match() {
  local direction="$1"
  (( ${#matches[@]} > 0 )) || return 0
  match_idx=$(( (match_idx + direction + ${#matches[@]}) % ${#matches[@]} ))
  offset="${matches[$match_idx]}"
}

_tnx_logs_view_export() {
  local dest default_dest i
  default_dest="$TERNUX_LOG_DIR/logs-export-$(date +%Y%m%d-%H%M%S 2>/dev/null || echo export).txt"
  printf '\033[H\033[2J' >&2
  dest="$(_tnx_logs_view_read_line "Export to [$default_dest]: ")"
  [ -n "$dest" ] || dest="$default_dest"
  mkdir -p "$(dirname "$dest")" 2>/dev/null || true
  if [ -n "$search" ]; then
    # An active search with zero matches must export nothing, not
    # silently fall back to the whole buffer — the status line already
    # told the user "0 match(es)".
    for i in "${matches[@]}"; do printf '%s\n' "${lines[$i]}"; done > "$dest" 2>/dev/null
  else
    printf '%s\n' "${lines[@]}" > "$dest" 2>/dev/null
  fi
  tnx_log_info "Exported log view to $dest"
}

_tnx_logs_view_cleanup() {
  local old_stty="$1"
  [ -n "$old_stty" ] && stty "$old_stty" <&3 2>/dev/null
  exec 3<&- 2>/dev/null
  printf '\033[H\033[2J' >&2
}
