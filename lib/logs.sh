# =============================================================================
#  ternux — log management library
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah) — MIT License
#  https://github.com/soobujmiah/ternux
# =============================================================================

# shellcheck source=lib/core.sh
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"

# ---------------------------------------------------------------------------
# Log commands
# ---------------------------------------------------------------------------

tnx_logs_show() {
  local log_file="${1:-$TERNUX_LOG_FILE}"
  local lines="${2:-50}"

  if [ ! -f "$log_file" ]; then
    tnx_fail "Log file not found: $log_file"
    return 1
  fi

  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    local last_lines
    last_lines="$(tail -n "$lines" "$log_file" 2>/dev/null | head -c 16000)"
    # Escape for JSON
    last_lines="${last_lines//\\/\\\\}"
    last_lines="${last_lines//\"/\\\"}"
    last_lines="${last_lines//$'\n'/\\n}"
    last_lines="${last_lines//$'\t'/\\t}"
    last_lines="${last_lines//$'\r'/\\r}"

    tnx_json_object "logs" "ok" \
      "log_file" "$log_file" \
      "lines_requested" "$lines" \
      "lines_available" "$(wc -l < "$log_file" 2>/dev/null || echo 0)" \
      "content" "$last_lines"
    return 0
  fi

  tnx_header "Ternux Logs"
  printf "  ${TNX_CD}File: %s${TNX_C0}\n" "$log_file"
  printf "  ${TNX_CD}Size: %s lines${TNX_C0}\n" "$(wc -l < "$log_file" 2>/dev/null || echo 0)"
  echo ""

  tail -n "$lines" "$log_file" | while IFS= read -r line; do
    printf "  %s\n" "$line"
  done
  echo ""
}

tnx_logs_tail() {
  local log_file="${1:-$TERNUX_LOG_FILE}"

  if [ ! -f "$log_file" ]; then
    tnx_fail "Log file not found: $log_file"
    return 1
  fi

  tnx_info "Tailing log file: $log_file"
  tnx_info "Press Ctrl+C to stop."
  echo ""

  tail -f "$log_file"
}

tnx_logs_clear() {
  local log_file="${1:-$TERNUX_LOG_FILE}"

  if tnx_confirm "Clear the log file ($log_file)?"; then
    : > "$log_file"
    tnx_ok "Log file cleared: $log_file"

    if [ "${TERNUX_JSON:-0}" = "1" ]; then
      tnx_json_object "logs" "cleared" "log_file" "$log_file"
    fi
  else
    tnx_info "Cancelled."
  fi
}

tnx_logs_list() {
  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    local files
    files="$(ls -1 "$TERNUX_LOG_DIR" 2>/dev/null | tr '\n' ',' | sed 's/,$//')"
    tnx_json_object "logs" "ok" "log_dir" "$TERNUX_LOG_DIR" "files" "$files"
    return 0
  fi

  tnx_header "Available Log Files"
  if [ -d "$TERNUX_LOG_DIR" ]; then
    ls -lh "$TERNUX_LOG_DIR" 2>/dev/null | awk 'NR>1 {printf "  %s %5s %s\n", $1, $5, $9}'
  else
    tnx_info "No log files found."
  fi
  echo ""
}