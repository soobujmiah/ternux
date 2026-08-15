# =============================================================================
#  ternux — system information command (AI-native)
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah) — MIT License
#  https://github.com/soobujmiah/ternux
# =============================================================================

# shellcheck source=lib/core.sh
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"
# shellcheck source=lib/detect.sh
. "$(dirname "${BASH_SOURCE[0]}")/detect.sh"

# ---------------------------------------------------------------------------
# tnx_cmd_info — structured device + software summary
# ---------------------------------------------------------------------------
tnx_cmd_info() {
  if ! tnx_is_termux; then
    if [ "${TERNUX_JSON:-0}" = "1" ]; then
      tnx_json_object "info" "ok" "version" "$TERNUX_VERSION" "note" "Not running in Termux — limited information"
      return 0
    fi
    tnx_warn "Not running in Termux — limited information."
  fi

  local android_ver arch model manufacturer ram storage termux_ver gpu vulkan backend phantom renderer

  android_ver="$(tnx_detect_android_version)"
  arch="$(tnx_detect_arch)"
  model="$(tnx_detect_model)"
  manufacturer="$(tnx_detect_manufacturer)"
  ram="$(tnx_detect_ram_gb)"
  storage="$(tnx_detect_storage_gb)"
  termux_ver="$(tnx_detect_termux_version)"
  gpu="$(tnx_detect_gpu)"
  vulkan="$(tnx_detect_vulkan)"
  backend="$(tnx_state_get "backend" || tnx_detect_backend)"
  phantom="$(tnx_detect_phantom_killer)"
  renderer="$(tnx_detect_renderer)"

  # JSON output (AI-native)
  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    tnx_json_object "info" "ok" \
      "version" "$TERNUX_VERSION" \
      "android_version" "$android_ver" \
      "architecture" "$arch" \
      "model" "$model" \
      "manufacturer" "$manufacturer" \
      "ram_gb" "$ram" \
      "storage_gb" "${storage}" \
      "termux_version" "$termux_ver" \
      "gpu" "$gpu" \
      "vulkan" "$vulkan" \
      "backend" "$backend" \
      "renderer" "${renderer:-unknown}" \
      "phantom_process_killer" "$phantom"
    return 0
  fi

  tnx_header "Ternux System Information"
  printf "  ${TNX_CW}%-22s${TNX_C0} v${TERNUX_VERSION}\n" "ternux:"
  printf "  ${TNX_CW}%-22s${TNX_C0} %s\n" "Android:" "$android_ver"
  printf "  ${TNX_CW}%-22s${TNX_C0} %s\n" "Architecture:" "$arch"
  printf "  ${TNX_CW}%-22s${TNX_C0} %s %s\n" "Device:" "$manufacturer" "$model"
  printf "  ${TNX_CW}%-22s${TNX_C0} %s GB\n" "RAM:" "$ram"
  printf "  ${TNX_CW}%-22s${TNX_C0} %s GB free\n" "Storage:" "$storage"
  printf "  ${TNX_CW}%-22s${TNX_C0} %s\n" "Termux:" "$termux_ver"
  printf "  ${TNX_CW}%-22s${TNX_C0} %s\n" "GPU:" "$gpu"
  printf "  ${TNX_CW}%-22s${TNX_C0} %s\n" "Vulkan:" "$vulkan"
  printf "  ${TNX_CW}%-22s${TNX_C0} %s\n" "Backend:" "$backend"
  printf "  ${TNX_CW}%-22s${TNX_C0} %s\n" "Renderer:" "${renderer:-unknown}"
  printf "  ${TNX_CW}%-22s${TNX_C0} %s\n" "Phantom killer:" "$phantom"
  echo ""
}