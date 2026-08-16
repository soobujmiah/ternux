# =============================================================================
#  ternux — log management
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah) — MIT License
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
    clear|--clear) _tnx_logs_clear ;;
    list|--list)   _tnx_logs_list ;;
    --help|-h)     tnx_help_logs ;;
    *) tnx_fail "Usage: ternux logs [show|tail|clear|list]"; return 1 ;;
  esac
}

_tnx_logs_show() {
  local lines="${1:-50}"
  [ ! -f "$TERNUX_LOG_FILE" ] && { tnx_fail "No log file found: $TERNUX_LOG_FILE"; return 1; }

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
}

_tnx_logs_list() {
  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    local files=""
    [ -d "$TERNUX_LOG_DIR" ] && files="$(ls -1 "$TERNUX_LOG_DIR" 2>/dev/null | tr '\n' ',' | sed 's/,$//')"
    tnx_json_object "logs" "ok" "log_dir" "$TERNUX_LOG_DIR" "files" "$files"
    return 0
  fi

  tnx_header "Log Files"
  [ -d "$TERNUX_LOG_DIR" ] && ls -lh "$TERNUX_LOG_DIR" 2>/dev/null | awk 'NR>1{printf "  %s %5s %s\n", $1, $5, $9}' || tnx_info "No log files found"
  echo ""
}