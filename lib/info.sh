# =============================================================================
#  ternux — system information command (machine-readable output supported)
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah)
#  Licensed under the Apache License, Version 2.0.
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
  if ! tnx_is_termux && [ "${TERNUX_JSON:-0}" != "1" ]; then
    tnx_warn "Not running in Termux — limited information."
  fi

  local android_ver android_sdk arch model manufacturer ram ram_available storage termux_ver gpu vulkan vulkan_state graphics_state backend phantom renderer cpu_cores load

  android_ver="$(tnx_detect_android_version)"
  android_sdk="$(tnx_detect_android_sdk)"
  arch="$(tnx_detect_arch)"
  model="$(tnx_detect_model)"
  manufacturer="$(tnx_detect_manufacturer)"
  ram="$(tnx_detect_ram_gb)"
  ram_available="$(awk '/MemAvailable/{printf "%.1f", $2/1048576}' /proc/meminfo 2>/dev/null)"
  [ -n "$ram_available" ] || ram_available="unknown"
  cpu_cores="$(nproc 2>/dev/null || awk '/^processor[[:space:]]*:/ { n++ } END { if (n) print n }' /proc/cpuinfo 2>/dev/null)"
  [ -n "$cpu_cores" ] || cpu_cores="unavailable"
  load="$(awk '{print $1", "$2", "$3}' /proc/loadavg 2>/dev/null || true)"
  [ -n "$load" ] || load="unavailable (Android restricts /proc/loadavg)"
  storage="$(tnx_detect_storage_gb)"
  termux_ver="$(tnx_detect_termux_version)"
  gpu="$(tnx_detect_gpu)"
  vulkan_state="$(tnx_detect_vulkan_state)"
  vulkan="$(tnx_vulkan_legacy_status "$vulkan_state")"
  backend="$(tnx_canonical_backend "$(tnx_state_get "backend" || tnx_detect_backend)")"
  phantom="$(tnx_detect_phantom_killer)"
  renderer="$(tnx_detect_renderer)"
  graphics_state="$(tnx_detect_graphics_state "$vulkan_state" "$renderer")"

  # JSON output
  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    tnx_json_object "info" "ok" \
      "android_version" "$android_ver" \
      "android_sdk" "$android_sdk" \
      "architecture" "$arch" \
      "model" "$model" \
      "manufacturer" "$manufacturer" \
      "ram_gb" "$ram" \
      "ram_available_gb" "$ram_available" \
      "cpu_cores" "$cpu_cores" \
      "load_average" "$load" \
      "storage_gb" "${storage}" \
      "termux_version" "$termux_ver" \
      "gpu" "$gpu" \
      "vulkan" "$vulkan" \
      "vulkan_state" "$vulkan_state" \
      "graphics_state" "$graphics_state" \
      "backend" "$backend" \
      "renderer" "${renderer:-unknown}" \
      "phantom_process_killer" "$phantom"
    return 0
  fi

  tnx_header "Ternux System Information"
  printf "  ${TNX_CC}Device and host${TNX_C0}\n"
  tnx_print_field 'Ternux:' "v${TERNUX_VERSION}"
  tnx_print_field 'Android:' "$android_ver (SDK $android_sdk)"
  tnx_print_field 'Device:' "$manufacturer $model · $cpu_cores CPU cores"
  tnx_print_field 'Architecture:' "$arch"
  tnx_print_field 'Termux:' "$termux_ver"
  printf "  ${TNX_CC}Resources${TNX_C0}\n"
  tnx_print_field 'Memory:' "$ram GB total · $ram_available GB available"
  tnx_print_field 'Storage:' "$storage GB free"
  tnx_print_field 'Load average:' "$load"
  printf "  ${TNX_CC}Graphics${TNX_C0}\n"
  tnx_print_field 'GPU:' "$gpu"
  tnx_print_field 'Vulkan:' "$vulkan"
  tnx_print_field 'Vulkan state:' "$vulkan_state"
  tnx_print_field 'Graphics state:' "$graphics_state"
  tnx_print_field 'Backend:' "$backend"
  tnx_print_field 'Renderer:' "${renderer:-unknown}"
  tnx_print_field 'Phantom process killer:' "$phantom"
  echo ""
}
