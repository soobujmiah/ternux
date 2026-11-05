# =============================================================================
#  ternux — GPU backend management
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah)
#  Licensed under the Apache License, Version 2.0.
#  https://github.com/soobujmiah/ternux
# =============================================================================

# shellcheck source=lib/core.sh
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"
# shellcheck source=lib/detect.sh
. "$(dirname "${BASH_SOURCE[0]}")/detect.sh"
# Use the installer's pinned, archive-validated Turnip updater.
# shellcheck source=lib/phases.sh
. "$(dirname "${BASH_SOURCE[0]}")/phases.sh"

# Friendly GPU-focused alias for backend management.
tnx_cmd_gpu() {
  local subcmd="${1:-show}"
  shift 2>/dev/null || true
  case "$subcmd" in
    update|--update) _tnx_backend_update ;;
    show|--show) _tnx_backend_show ;;
    --help|-h) tnx_help_gpu ;;
    *) tnx_fail "Usage: ternux gpu [show|update]"; return 1 ;;
  esac
}

# ---------------------------------------------------------------------------
# tnx_cmd_backend
# ---------------------------------------------------------------------------
tnx_cmd_backend() {
  local subcmd="${1:-show}"
  shift 2>/dev/null || true

  case "$subcmd" in
    show|--show)   _tnx_backend_show ;;
    set|--set)     _tnx_backend_set "${1:-}" ;;
    detect|--detect) _tnx_backend_detect ;;
    update|--update) _tnx_backend_update ;;
    --help|-h)     tnx_help_backend ;;
    *) tnx_fail "Usage: ternux backend [show|set|detect|update]"; return 1 ;;
  esac
}

_tnx_backend_update() {
  local backend
  backend="$(tnx_canonical_backend "$(tnx_state_get "backend")")"
  [ -n "$backend" ] || backend="$(tnx_detect_backend)"
  [ "$backend" = "zink-turnip" ] && backend="zink"
  if [ "$backend" != "zink" ]; then
    tnx_info "VirGL uses the Termux host renderer; there is no guest Turnip driver to update."
    [ "${TERNUX_JSON:-0}" = "1" ] && tnx_json_object "gpu" "unchanged" "backend" "$backend" "reason" "turnip_not_used"
    return 0
  fi
  tnx_info "Refreshing the validated Debian Turnip driver and ICD. Android's vendor GPU driver is managed by the device OS."
  local phase_output="" phase_status=0
  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    phase_output="$(tnx_phase_gpu "$backend" 2>&1)" || phase_status=$?
    [ -n "$phase_output" ] && printf '%s\n' "$phase_output" >&2
  else
    tnx_phase_gpu "$backend" || phase_status=$?
  fi
  if [ "$phase_status" -eq 0 ]; then
    tnx_ok "Turnip driver refreshed from Ternux's validated release. Restart the desktop to load it."
    [ "${TERNUX_JSON:-0}" = "1" ] && tnx_json_object "gpu" "updated" "backend" "$backend" "restart_required" "true"
    return 0
  fi
  [ "${TERNUX_JSON:-0}" = "1" ] && tnx_json_object "gpu" "error" "backend" "$backend" "reason" "driver_update_failed"
  return 1
}

_tnx_backend_show() {
  local current_backend renderer gpu
  current_backend="$(tnx_canonical_backend "$(tnx_state_get "backend")")"
  gpu="$(tnx_detect_gpu)"
  renderer=""

  # Try to get renderer if Debian is available
  if tnx_debian_installed; then
    renderer="$(tnx_detect_renderer)"
  fi

  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    tnx_json_object "backend" "ok" \
      "gpu" "$gpu" \
      "backend" "${current_backend:-$(tnx_detect_backend)}" \
      "renderer" "${renderer:-unknown}" \
      "vulkan" "$(tnx_detect_vulkan)" \
      "available_backends" "zink,virgl"
    return 0
  fi

  tnx_header "GPU Backend"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Detected GPU:" "$gpu"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Configured:" "${current_backend:-not set}"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Renderer:" "${renderer:-unknown}"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Vulkan:" "$(tnx_detect_vulkan)"
  echo ""
  printf "  Available: zink (Zink/Turnip on Adreno), virgl (compatibility route)\n"
  echo ""
}

_tnx_backend_set() {
  local backend="$1"
  [ -z "$backend" ] && { tnx_fail "Usage: ternux backend set [zink|virgl|auto]"; return 1; }

  case "$backend" in
    zink|zink-turnip)
      # Accept the older descriptive spelling at the CLI boundary, then store
      # the canonical value used by install.sh and lib/phases.sh.
      backend="zink"
      [ ! -e "${TERNUX_KGSL_DEVICE:-/dev/kgsl-3d0}" ] && {
        [ "${TERNUX_JSON:-0}" = "1" ] && { tnx_json_object "backend" "error" "reason" "no_kgsl_device"; return 1; }
        tnx_fail "Zink/Turnip requires Adreno GPU (/dev/kgsl-3d0). Use 'ternux backend set virgl' instead."
        return 1
      } ;;
    virgl)
      if ! tnx_has_cmd virgl_test_server_android && ! tnx_has_cmd virgl_test_server; then
        tnx_warn "VirGL renderer not detected. Install: pkg install virglrenderer-android -y"
      fi ;;
    auto)
      backend="$(tnx_detect_backend)"
      tnx_info "Auto-detected: $backend" ;;
    *) tnx_fail "Unknown backend '$backend'. Valid: zink, virgl, auto"; return 1 ;;
  esac

  tnx_state_set "backend" "$backend"
  tnx_ok "Backend set to '$backend'"
  tnx_info "Run 'ternux repair' to apply the new configuration."

  [ "${TERNUX_JSON:-0}" = "1" ] && tnx_json_object "backend" "updated" "backend" "$backend"
  return 0
}

_tnx_backend_detect() {
  local backend
  backend="$(tnx_detect_backend)"
  tnx_state_set "backend" "$backend"
  tnx_ok "Detected backend: $backend"
  [ "${TERNUX_JSON:-0}" = "1" ] && tnx_json_object "backend" "detected" "gpu" "$(tnx_detect_gpu)" "backend" "$backend"
  return 0
}