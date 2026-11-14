# =============================================================================
#  ternux — device detection and profiling library
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah)
#  Licensed under the Apache License, Version 2.0.
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
  local version="${TERMUX_APP__APP_VERSION_NAME:-${TERMUX_VERSION:-}}"
  [ -n "$version" ] && { echo "$version"; return 0; }

  version="$(dpkg-query -W -f='${Version}' com.termux 2>/dev/null || true)"
  [ -n "$version" ] && { echo "$version"; return 0; }

  version="$(tnx_termux_apt_cache policy com.termux 2>/dev/null | awk '/Installed:/ {print $2; exit}')"
  [ -n "$version" ] && echo "$version" || echo "unknown"
}

# ---------------------------------------------------------------------------
# GPU Detection
# ---------------------------------------------------------------------------
tnx_detect_gpu() {
  # Check for Adreno via KGSL node
  if [ -e "${TERNUX_KGSL_DEVICE:-/dev/kgsl-3d0}" ]; then
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

tnx_vulkan_probe_guest() {
  local bind_args=()
  [ -e "${TERNUX_KGSL_DEVICE:-/dev/kgsl-3d0}" ] && bind_args+=(--bind "${TERNUX_KGSL_DEVICE:-/dev/kgsl-3d0}:/dev/kgsl")
  tnx_guest_login --shared-tmp "${bind_args[@]}" -- bash -c '
    overlay="$(cat /etc/ternux/mesa-overlay 2>/dev/null || true)"
    overlay_libdir="$(cat /etc/ternux/mesa-overlay-libdir 2>/dev/null || true)"
    case "$overlay" in /usr/local/lib/ternux/*)
      case "$overlay_libdir" in
        "$overlay"/*) [ -d "$overlay_libdir" ] || overlay_libdir="" ;;
        *) overlay_libdir="" ;;
      esac
      if [ -z "$overlay_libdir" ]; then
        for candidate in "$overlay/lib/aarch64-linux-gnu" "$overlay/lib"; do
          if [ -d "$candidate" ]; then overlay_libdir="$candidate"; break; fi
        done
      fi
      case "$overlay_libdir" in "$overlay"/*)
      export LD_LIBRARY_PATH="$overlay_libdir${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      export VK_DRIVER_FILES="$overlay/share/vulkan/icd.d/ternux_freedreno_icd.json"
      export VK_ICD_FILENAMES="$VK_DRIVER_FILES"
      ;;
      esac
      ;;
    esac
    loader=no; icd=no; enum_rc=127; report=""
    ldconfig -p 2>/dev/null | grep -q libvulkan && loader=yes
    for d in /etc/vulkan/icd.d /usr/share/vulkan/icd.d /usr/local/share/vulkan/icd.d /usr/local/lib/aarch64-linux-gnu/vulkan/icd.d; do
      if [ -d "$d" ] && find "$d" -maxdepth 1 -type f -name "*.json" -print -quit 2>/dev/null | grep -q .; then icd=yes; break; fi
    done
    if command -v timeout >/dev/null 2>&1 && command -v vulkaninfo >/dev/null 2>&1; then
      report="$(timeout 10s vulkaninfo --summary 2>&1)"; enum_rc=$?
    fi
    printf "TNX_LOADER=%s\\nTNX_ICD=%s\\nTNX_ENUM_RC=%s\\n%s\\n" "$loader" "$icd" "$enum_rc" "$report"
  ' 2>/dev/null
}

tnx_vulkan_probe_host() {
  local prefix="${PREFIX:-/data/data/com.termux/files/usr}" report="" rc=127 loader=no icd=no
  compgen -G "$prefix/lib/libvulkan*.so*" >/dev/null && loader=yes
  for d in "$prefix/share/vulkan/icd.d" "$prefix/lib/vulkan/icd.d"; do
    if [ -d "$d" ] && find "$d" -maxdepth 1 -type f -name "*.json" -print -quit 2>/dev/null | grep -q .; then icd=yes; break; fi
  done
  if tnx_has_cmd timeout && tnx_has_cmd vulkaninfo; then report="$(timeout 10s vulkaninfo --summary 2>&1)"; rc=$?; fi
  printf 'TNX_LOADER=%s\nTNX_ICD=%s\nTNX_ENUM_RC=%s\n%s\n' "$loader" "$icd" "$rc" "$report"
}

tnx_vulkan_probe_has_hardware() {
  printf '%s\n' "${1:-}" | awk '
    function flush_device() {
      if (hardware && driver !~ /(llvmpipe|lavapipe|softpipe)/) found=1
    }
    /^GPU[0-9]+:/ { flush_device(); hardware=0; driver="" }
    /deviceType[[:space:]]*=[[:space:]]*PHYSICAL_DEVICE_TYPE_(INTEGRATED_GPU|DISCRETE_GPU)/ { hardware=1 }
    /driverName[[:space:]]*=/ { driver=$0 }
    END { flush_device(); exit !found }
  '
}

tnx_detect_vulkan_state() {
  local probe="" loader="no" icd="no" enum_rc=127 gpu
  if tnx_has_cmd proot-distro; then
    probe="$(tnx_vulkan_probe_guest 2>/dev/null || true)"
  fi
  if [ -z "$probe" ]; then probe="$(tnx_vulkan_probe_host 2>/dev/null || true)"; fi
  loader="$(printf '%s\n' "$probe" | sed -n 's/^TNX_LOADER=//p' | head -1)"
  icd="$(printf '%s\n' "$probe" | sed -n 's/^TNX_ICD=//p' | head -1)"
  enum_rc="$(printf '%s\n' "$probe" | sed -n 's/^TNX_ENUM_RC=//p' | head -1)"
  gpu="$(tnx_detect_gpu)"

  if tnx_vulkan_probe_has_hardware "$probe"; then
    echo VULKAN_READY
  elif printf '%s\n' "$probe" | grep -Eqi 'deviceName[[:space:]]*=[[:space:]]*(llvmpipe|lavapipe|softpipe)' ||
       printf '%s\n' "$probe" | grep -Eq 'deviceType[[:space:]]*=[[:space:]]*PHYSICAL_DEVICE_TYPE_CPU'; then
    echo SOFTWARE_FALLBACK
  elif [ "$loader" != yes ]; then
    if [ "$gpu" = unknown ]; then echo NOT_DETECTED
    elif [ -e "${TERNUX_KGSL_DEVICE:-/dev/kgsl-3d0}" ]; then echo LOADER_MISSING
    else echo HARDWARE_AVAILABLE
    fi
  elif [ "$icd" != yes ]; then
    if [ -e "${TERNUX_KGSL_DEVICE:-/dev/kgsl-3d0}" ]; then echo DRIVER_MISSING; else echo ICD_MISSING; fi
  elif [ "$enum_rc" = 127 ]; then
    echo PROBE_UNAVAILABLE
  elif [ "$enum_rc" != 0 ]; then
    echo DEVICE_ENUMERATION_FAILED
  else
    echo DEVICE_ENUMERATION_FAILED
  fi
}

tnx_vulkan_legacy_status() {
  case "${1:-$(tnx_detect_vulkan_state)}" in
    VULKAN_READY) echo yes ;;
    PROBE_UNAVAILABLE) echo "unverified (vulkaninfo missing)" ;;
    SOFTWARE_FALLBACK) echo "no (software fallback)" ;;
    *) echo "no ($1)" ;;
  esac
}

tnx_detect_vulkan() {
  tnx_vulkan_legacy_status "$(tnx_detect_vulkan_state)"
}

tnx_renderer_is_software() {
  printf '%s\n' "${1:-}" | grep -Eiq \
    'llvmpipe|lavapipe|softpipe|swrast|swiftshader|software[[:space:]_-]*rasterizer|gdi[[:space:]_-]*generic'
}

tnx_detect_graphics_state() {
  local vulkan_state="${1:-$(tnx_detect_vulkan_state)}" renderer="${2:-$(tnx_detect_renderer)}"
  if tnx_renderer_is_software "$renderer"; then
    echo SOFTWARE_FALLBACK
  elif [ -z "$renderer" ] || [ "$renderer" = unknown ]; then
    echo "$vulkan_state"
  else
    echo OPENGL_ACCELERATION_READY
  fi
}

tnx_detect_backend() {
  # Backend recommendations depend on both the host GPU and the selected
  # guest: the pinned Zink/Turnip payload is only qualified for Debian.
  tnx_gpu_backend_auto "$(tnx_distro)"
}

tnx_detect_renderer() {
  local display="${DISPLAY:-}" renderer display_num=""
  if ! tnx_has_cmd proot-distro; then
    echo "unknown"
    return 0
  fi

  # A doctor command launched from Termux does not inherit the guest desktop's
  # DISPLAY. Probe the live Termux:X11 display when it is running so the result
  # reflects the renderer actually used by Xfce, rather than "unknown".
  if [ -z "$display" ] && pgrep -f "^termux-x11 com\\.termux\\.x11([[:space:]]|$)" >/dev/null 2>&1; then
    display_num="$(tnx_distro_display 2>/dev/null || true)"
    [ -n "$display_num" ] || display_num=0
    display=:$display_num
  fi
  renderer="$(tnx_guest_login --shared-tmp --shared-x11 -- env "DISPLAY=$display" bash -c '
    overlay="$(cat /etc/ternux/mesa-overlay 2>/dev/null || true)"
    overlay_libdir="$(cat /etc/ternux/mesa-overlay-libdir 2>/dev/null || true)"
    case "$overlay" in /usr/local/lib/ternux/*)
      case "$overlay_libdir" in
        "$overlay"/*) [ -d "$overlay_libdir" ] || overlay_libdir="" ;;
        *) overlay_libdir="" ;;
      esac
      if [ -z "$overlay_libdir" ]; then
        for candidate in "$overlay/lib/aarch64-linux-gnu" "$overlay/lib"; do
          if [ -d "$candidate" ]; then overlay_libdir="$candidate"; break; fi
        done
      fi
      case "$overlay_libdir" in "$overlay"/*)
      export LD_LIBRARY_PATH="$overlay_libdir${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      export LIBGL_DRIVERS_PATH="$overlay_libdir/dri"
      export VK_DRIVER_FILES="$overlay/share/vulkan/icd.d/ternux_freedreno_icd.json"
      export VK_ICD_FILENAMES="$VK_DRIVER_FILES"
      ;;
      esac
      ;;
    esac
    renderer=""
    if [ -n "${DISPLAY:-}" ] && command -v glxinfo >/dev/null 2>&1 &&
       command -v timeout >/dev/null 2>&1; then
      renderer="$(timeout 5s glxinfo 2>/dev/null |
        sed -n "s/^OpenGL renderer string: //p" | head -1 || true)"
    fi
    # Driver/ICD files are installation evidence only. Report a renderer only
    # when glxinfo queries the selected X11 display successfully.
    [ -n "$renderer" ] && printf "%s\n" "$renderer" || echo "unknown"
  ' 2>/dev/null)" || renderer=unknown
  [ -n "$renderer" ] && echo "$renderer" || echo "unknown"
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
  local vulkan_state
  vulkan_state="$(tnx_detect_vulkan_state)"
  vulkan="$(tnx_vulkan_legacy_status "$vulkan_state")"
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
      "vulkan_state" "$vulkan_state" \
      "graphics_state" "$(tnx_detect_graphics_state "$vulkan_state" unknown)" \
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
