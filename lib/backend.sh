# =============================================================================
#  ternux — GPU backend management library
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah) — MIT License
#  https://github.com/soobujmiah/ternux
# =============================================================================

# shellcheck source=lib/core.sh
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"
# shellcheck source=lib/detect.sh
. "$(dirname "${BASH_SOURCE[0]}")/detect.sh"

# ---------------------------------------------------------------------------
# Backend management commands
# ---------------------------------------------------------------------------

tnx_backend_show() {
  local current_backend renderer gpu
  current_backend="$(tnx_state_get "backend")"
  renderer="$(tnx_state_get "renderer")"
  gpu="$(tnx_detect_gpu)"

  [ -z "$current_backend" ] && current_backend="$(tnx_detect_backend)"
  [ -z "$renderer" ] && renderer="$(tnx_detect_renderer)"

  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    tnx_json_object "backend" "ok" \
      "gpu" "$gpu" \
      "backend" "$current_backend" \
      "renderer" "$renderer" \
      "vulkan" "$(tnx_detect_vulkan)" \
      "available_backends" "zink-turnip,virgl"
    return 0
  fi

  tnx_header "GPU Backend"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Detected GPU:" "$gpu"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Current backend:" "${current_backend:-not set}"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Renderer:" "${renderer:-unknown}"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Vulkan:" "$(tnx_detect_vulkan)"
  echo ""
  printf "  Available backends:\n"
  printf "    ${TNX_CG}zink-turnip${TNX_C0}  — Vulkan-backed OpenGL (Adreno GPU)\n"
  printf "    ${TNX_CG}virgl${TNX_C0}        — Compatibility path (any GPU)\n"
  echo ""
}

tnx_backend_set() {
  local backend="$1"
  case "$backend" in
    zink|zink-turnip)
      backend="zink-turnip"
      if [ ! -e /dev/kgsl-3d0 ]; then
        if [ "${TERNUX_JSON:-0}" = "1" ]; then
          tnx_json_object "backend" "error" "gpu" "$(tnx_detect_gpu)" "backend" "$backend" "reason" "No Adreno GPU detected; zink-turnip requires /dev/kgsl-3d0"
        else
          tnx_fail "Zink/Turnip requires an Adreno GPU (/dev/kgsl-3d0). Use 'ternux backend set virgl' instead."
        fi
        return 1
      fi
      ;;
    virgl)
      backend="virgl"
      if ! tnx_has_cmd virgl_test_server_android && ! tnx_has_cmd virgl_test_server; then
        tnx_warn "VirGL host renderer not detected. Install with: pkg install virglrenderer-android -y"
      fi
      ;;
    auto)
      backend="$(tnx_detect_backend)"
      tnx_info "Auto-detected backend: $backend"
      ;;
    *)
      tnx_fail "Unknown backend '$backend'. Valid options: zink-turnip, virgl, auto"
      return 1
      ;;
  esac

  tnx_state_set "backend" "$backend"
  tnx_ok "Backend set to '$backend'"
  tnx_info "Run 'ternux repair' to apply the new backend configuration."

  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    tnx_json_object "backend" "updated" "gpu" "$(tnx_detect_gpu)" "backend" "$backend"
  fi
}

tnx_backend_detect() {
  local backend
  backend="$(tnx_detect_backend)"
  tnx_state_set "backend" "$backend"
  tnx_ok "Detected backend: $backend"

  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    tnx_json_object "backend" "detected" "gpu" "$(tnx_detect_gpu)" "backend" "$backend"
  fi
}