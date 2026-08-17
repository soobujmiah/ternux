# =============================================================================
#  ternux — installation state query
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah) — MIT License
#  https://github.com/soobujmiah/ternux
# =============================================================================

# shellcheck source=lib/core.sh
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"

# ---------------------------------------------------------------------------
# tnx_cmd_state
# ---------------------------------------------------------------------------
tnx_cmd_state() {
  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    _tnx_state_export_json
    return 0
  fi
  _tnx_state_show
}

_tnx_state_show() {
  [ "${TERNUX_QUIET:-0}" = "1" ] && return 0
  tnx_header "Installation State"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "State dir:" "$TERNUX_STATE_DIR"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Version:" "$TERNUX_VERSION"
  echo ""

  if [ -f "$TERNUX_STATE_DIR/phases" ]; then
    tnx_info "Completed phases:"
    while IFS= read -r phase; do printf "  ${TNX_CG}✓${TNX_C0}  %s\n" "$phase"; done < "$TERNUX_STATE_DIR/phases"
    echo ""
  else
    tnx_info "No phases completed. Run 'ternux install'."
    echo ""
  fi

  if [ -f "$TERNUX_STATE_DIR/state" ]; then
    tnx_info "Configuration:"
    while IFS='=' read -r key val; do
      case "$key" in
        backend)
          printf "  ${TNX_CD}%-20s${TNX_C0} %s\n" "$key:" "$(tnx_canonical_backend "$val")" ;;
        renderer|version|updated_at)
          printf "  ${TNX_CD}%-20s${TNX_C0} %s\n" "$key:" "$val" ;;
      esac
    done < "$TERNUX_STATE_DIR/state"
    echo ""
  fi

  for hist in benchmarks repairs; do
    [ -f "$TERNUX_STATE_DIR/$hist" ] && {
      tnx_info "${hist} history:"
      tail -5 "$TERNUX_STATE_DIR/$hist" | while IFS= read -r line; do printf "  ${TNX_CD}%s${TNX_C0}\n" "$line"; done
      echo ""
    }
  done
  return 0
}

_tnx_state_export_json() {
  tnx_json_init
  tnx_json_add "command" "state"
  tnx_json_add "status" "ok"
  tnx_json_add "timestamp" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  tnx_json_add "version" "$TERNUX_VERSION"
  tnx_json_add "state_dir" "$TERNUX_STATE_DIR"

  local phases=""
  [ -f "$TERNUX_STATE_DIR/phases" ] && phases="$(tr '\n' ',' < "$TERNUX_STATE_DIR/phases" | sed 's/,$//')"
  tnx_json_add "completed_phases" "$phases"
  tnx_json_add "backend" "$(tnx_canonical_backend "$(tnx_state_get "backend" || echo "unknown")")"
  tnx_json_add "renderer" "$(tnx_state_get "renderer" || echo "unknown")"
  tnx_json_end
}