# =============================================================================
#  ternux — device detection and profiling library
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah) — MIT License
#  https://github.com/soobujmiah/ternux
# =============================================================================

# shellcheck source=lib/core.sh
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"

# ---------------------------------------------------------------------------
# Device profile — a comprehensive hardware/software snapshot
# ---------------------------------------------------------------------------
tnx_detect_android_version() {
  getprop ro.build.version.release 2>/dev/null || echo "unknown"
}

tnx_detect_android_sdk() {
  getprop ro.build.version.sdk 2>/dev/null || echo 0
}

tnx_detect_arch() {
  uname -m 2>/dev/null || echo "unknown"
}

tnx_detect_model() {
  getprop ro.product.model 2>/dev/null || echo "unknown"
}

tnx_detect_manufacturer() {
  getprop ro.product.manufacturer 2>/dev/null || echo "unknown"
}

tnx_detect_ram_gb() {
  awk '/MemTotal/{printf "%d", ($2/1048576)+0.5}' /proc/meminfo 2>/dev/null || echo "?"
}

tnx_detect_storage_gb() {
  local path="${1:-$HOME}"
  df -Pk "$path" 2>/dev/null | awk 'NR==2{print int($4/1024/1024)}' || echo "?"
}

tnx_detect_termux_version() {
  dpkg -s com.termux 2>/dev/null | grep '^Version:' | awk '{print $2}' || \
  apt-cache policy com.termux 2>/dev/null | grep 'Installed:' | awk '{print $2}' || \
  echo "unknown"
}

# ---------------------------------------------------------------------------
# GPU Detection
# ---------------------------------------------------------------------------
tnx_detect_gpu() {
  # Check for Adreno via KGSL node
  if [ -e /dev/kgsl-3d0 ]; then
    # Try to get the GPU name from the device
    local gpu_model
    gpu_model="$(cat /sys/class/kgsl/kgsl-3d0/gpu_model 2>/dev/null || true)"
    if [ -n "$gpu_model" ]; then
      echo "Adreno ($gpu_model)"
    else
      echo "Adreno"
    fi
    return 0
  fi

  # Check via /proc or dmesg for other GPUs
  if grep -qi "mali" /proc/cpuinfo 2>/dev/null || grep -qi "mali" /sys/class/misc/mali*/device/uevent 2>/dev/null; then
    echo "Mali"
    return 0
  fi

  if getprop ro.hardware 2>/dev/null | grep -qi "exynos"; then
    echo "Xclipse (Exynos)"
    return 0
  fi

  echo "unknown"
}

tnx_detect_vulkan() {
  # Check if a Vulkan ICD is present in Termux
  if ls /data/data/com.termux/files/usr/lib/libvulkan* 2>/dev/null | head -1 >/dev/null; then
    echo "yes"
    return 0
  fi
  # Check if proot-debian has Vulkan
  if tnx_has_cmd proot-distro; then
    if proot-distro login debian -- bash -c 'ldconfig -p 2>/dev/null | grep -q libvulkan' 2>/dev/null; then
      echo "yes"
      return 0
    fi
  fi
  # Check /dev/kgsl which implies Vulkan support on Adreno
  if [ -e /dev/kgsl-3d0 ]; then
    echo "yes (Adreno)"
    return 0
  fi
  echo "no"
}

tnx_detect_backend() {
  local gpu
  gpu="$(tnx_detect_gpu)"
  case "$gpu" in
    Adreno*) echo "zink-turnip" ;;
    *) echo "virgl" ;;
  esac
}

tnx_detect_renderer() {
  if tnx_has_cmd proot-distro; then
    proot-distro login debian -- bash -c '
      if command -v glxinfo >/dev/null 2>&1; then
        glxinfo 2>/dev/null | grep "renderer string" | head -1 | sed "s/.*: //"
      elif [ -f /usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so ]; then
        echo "zink Vulkan (Adreno via Turnip)"
      else
        echo "unknown"
      fi
    ' 2>/dev/null || echo "unknown"
  else
    echo "unknown"
  fi
}

# ---------------------------------------------------------------------------
# Detect if phantom process killer is enabled (Android 12+)
# ---------------------------------------------------------------------------
tnx_detect_phantom_killer() {
  local sdk
  sdk="$(tnx_detect_android_sdk)"
  [ "$sdk" -lt 31 ] 2>/dev/null && { echo "disabled (pre-Android 12)"; return 0; }
  local cur
  cur="$(settings get global settings_enable_monitor_phantom_procs 2>/dev/null || echo "unknown")"
  case "$cur" in
    0|false) echo "disabled" ;;
    1|true)  echo "enabled" ;;
    *)       echo "unknown" ;;
  esac
}

# ---------------------------------------------------------------------------
# Generate a full device profile (used by `ternux profile` and `ternux info`)
# ---------------------------------------------------------------------------
tnx_profile() {
  local android_ver arch model manufacturer ram storage termux_ver gpu vulkan backend phantom

  android_ver="$(tnx_detect_android_version)"
  arch="$(tnx_detect_arch)"
  model="$(tnx_detect_model)"
  manufacturer="$(tnx_detect_manufacturer)"
  ram="$(tnx_detect_ram_gb)"
  storage="$(tnx_detect_storage_gb)"
  termux_ver="$(tnx_detect_termux_version)"
  gpu="$(tnx_detect_gpu)"
  vulkan="$(tnx_detect_vulkan)"
  backend="$(tnx_detect_backend)"
  phantom="$(tnx_detect_phantom_killer)"

  # Export for other commands to use
  export TNX_ANDROID="$android_ver"
  export TNX_ARCH="$arch"
  export TNX_MODEL="$model"
  export TNX_MANUFACTURER="$manufacturer"
  export TNX_RAM="$ram"
  export TNX_STORAGE="$storage"
  export TNX_GPU="$gpu"
  export TNX_VULKAN="$vulkan"
  export TNX_BACKEND="$backend"
  export TNX_PHANTOM="$phantom"

  # Return profile as JSON
  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    tnx_json_object "profile" "complete" \
      "android_version" "$android_ver" \
      "architecture" "$arch" \
      "model" "$model" \
      "manufacturer" "$manufacturer" \
      "ram_gb" "$ram" \
      "storage_gb" "$storage" \
      "termux_version" "$termux_ver" \
      "gpu" "$gpu" \
      "vulkan" "$vulkan" \
      "backend" "$backend" \
      "phantom_process_killer" "$phantom"
    return 0
  fi

  # Human-readable output
  tnx_header "Device Profile"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Android version:" "$android_ver"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Architecture:" "$arch"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Model:" "$model"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Manufacturer:" "$manufacturer"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s GB\n" "RAM:" "$ram"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s GB free\n" "Storage:" "$storage"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Termux version:" "$termux_ver"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "GPU:" "$gpu"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Vulkan:" "$vulkan"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "GPU backend:" "$backend"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Phantom killer:" "$phantom"
  echo ""
}