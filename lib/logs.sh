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
    desktop|session) _tnx_logs_desktop "${1:-show}" "${2:-}" ;;
    clear|--clear) _tnx_logs_clear ;;
    list|--list)   _tnx_logs_list ;;
    --help|-h)     tnx_help_logs ;;
    *) tnx_fail "Usage: ternux logs [show|tail|clear|list]"; return 1 ;;
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
