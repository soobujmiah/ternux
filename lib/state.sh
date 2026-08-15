# =============================================================================
#  ternux — state management library
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah) — MIT License
#  https://github.com/soobujmiah/ternux
# =============================================================================

# shellcheck source=lib/core.sh
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"

# ---------------------------------------------------------------------------
# State commands
# ---------------------------------------------------------------------------

tnx_state_show() {
  tnx_header "Ternux State"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "State directory:" "$TERNUX_STATE_DIR"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Version:" "$TERNUX_VERSION"
  echo ""

  # Show completed phases
  if [ -f "$TERNUX_STATE_DIR/phases" ]; then
    tnx_info "Completed phases:"
    while IFS= read -r phase; do
      printf "  ${TNX_CG}✓${TNX_C0}  %s\n" "$phase"
    done < "$TERNUX_STATE_DIR/phases"
    echo ""
  else
    tnx_info "No phases completed."
    echo ""
  fi

  # Show state key-values
  if [ -f "$TERNUX_STATE_DIR/state" ]; then
    tnx_info "Configuration:"
    while IFS='=' read -r key val; do
      case "$key" in
        backend|renderer|driver_version|install_phase) ;;
        *) continue ;;
      esac
      printf "  ${TNX_CD}%-20s${TNX_C0} %s\n" "$key:" "$val"
    done < "$TERNUX_STATE_DIR/state"
    echo ""
  fi

  # Show benchmark history
  if [ -f "$TERNUX_STATE_DIR/benchmarks" ]; then
    tnx_info "Benchmark history:"
    while IFS= read -r line; do
      printf "  ${TNX_CD}%s${TNX_C0}\n" "$line"
    done < "$TERNUX_STATE_DIR/benchmarks"
    echo ""
  fi

  # Show repair history
  if [ -f "$TERNUX_STATE_DIR/repairs" ]; then
    tnx_info "Repair history:"
    while IFS= read -r line; do
      printf "  ${TNX_CD}%s${TNX_C0}\n" "$line"
    done < "$TERNUX_STATE_DIR/repairs"
    echo ""
  fi
}

tnx_state_export_json() {
  tnx_json_init
  tnx_json_add "command" "state"
  tnx_json_add "status" "ok"
  tnx_json_add "version" "$TERNUX_VERSION"
  tnx_json_add "state_dir" "$TERNUX_STATE_DIR"

  # Phases
  local phases=""
  if [ -f "$TERNUX_STATE_DIR/phases" ]; then
    phases=$(tr '\n' ',' < "$TERNUX_STATE_DIR/phases" | sed 's/,$//')
  fi
  tnx_json_add "completed_phases" "$phases"

  # Backend
  local backend renderer
  backend=$(tnx_state_get "backend")
  renderer=$(tnx_state_get "renderer")
  tnx_json_add "backend" "${backend:-unknown}"
  tnx_json_add "renderer" "${renderer:-unknown}"

  tnx_json_end
}