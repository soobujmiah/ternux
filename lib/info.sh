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
  printf "  ${TNX_CW}%-22s${TNX_C0} v${TERNUX_VERSION}\n" "Ternux:"
  printf "  ${TNX_CW}%-22s${TNX_C0} %s (SDK %s)\n" "Android:" "$android_ver" "$android_sdk"
  printf "  ${TNX_CW}%-22s${TNX_C0} %s %s · %s CPU cores\n" "Device:" "$manufacturer" "$model" "$cpu_cores"
  printf "  ${TNX_CW}%-22s${TNX_C0} %s\n" "Architecture:" "$arch"
  printf "  ${TNX_CW}%-22s${TNX_C0} %s\n" "Termux:" "$termux_ver"
  printf "  ${TNX_CC}Resources${TNX_C0}\n"
  printf "  ${TNX_CW}%-22s${TNX_C0} %s GB total · %s GB available\n" "Memory:" "$ram" "$ram_available"
  printf "  ${TNX_CW}%-22s${TNX_C0} %s GB free\n" "Storage:" "$storage"
  printf "  ${TNX_CW}%-22s${TNX_C0} %s\n" "Load average:" "$load"
  printf "  ${TNX_CC}Graphics${TNX_C0}\n"
  printf "  ${TNX_CW}%-22s${TNX_C0} %s\n" "GPU:" "$gpu"
  printf "  ${TNX_CW}%-22s${TNX_C0} %s\n" "Vulkan:" "$vulkan"
  printf "  ${TNX_CW}%-22s${TNX_C0} %s\n" "Vulkan state:" "$vulkan_state"
  printf "  ${TNX_CW}%-22s${TNX_C0} %s\n" "Graphics state:" "$graphics_state"
  printf "  ${TNX_CW}%-22s${TNX_C0} %s\n" "Backend:" "$backend"
  printf "  ${TNX_CW}%-22s${TNX_C0} %s\n" "Renderer:" "${renderer:-unknown}"
  printf "  ${TNX_CW}%-22s${TNX_C0} %s\n" "Phantom process killer:" "$phantom"
  echo ""
}
