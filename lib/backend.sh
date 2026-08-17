# =============================================================================
#  ternux — GPU backend management
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah) — MIT License
#  https://github.com/soobujmiah/ternux
# =============================================================================

# shellcheck source=lib/core.sh
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"
# shellcheck source=lib/detect.sh
. "$(dirname "${BASH_SOURCE[0]}")/detect.sh"

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
    --help|-h)     tnx_help_backend ;;
    *) tnx_fail "Usage: ternux backend [show|set|detect]"; return 1 ;;
  esac
}

_tnx_backend_show() {
  local current_backend renderer gpu
  current_backend="$(tnx_canonical_backend "$(tnx_state_get "backend")")"
  gpu="$(tnx_detect_gpu)"
  renderer=""

  # Try to get renderer if Debian is available
  if tnx_has_cmd proot-distro && proot-distro list 2>/dev/null | grep -q "debian.*installed"; then
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
      [ ! -e /dev/kgsl-3d0 ] && {
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