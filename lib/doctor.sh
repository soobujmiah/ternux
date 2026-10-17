# =============================================================================
#  ternux — diagnostics (doctor) and verify commands
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
# tnx_cmd_doctor — categorised diagnostics with structured JSON
#
#   ternux doctor [CATEGORY...] [--quick] [--strict] [--json]
#
# Every check is recorded as one row: status|category|id|title|detail|fix.
# Rendering (human or JSON) happens after collection, so both outputs always
# describe exactly the same set of checks. Statuses: ok, warn, fail, info
# (info is context and never counts as an issue).
# ---------------------------------------------------------------------------
TNX_DOCTOR_CATEGORIES="system host guest graphics extensions"
TNX_DOCTOR_EXTENSIONS="llama-vulkan llama-htp-experimental wine-hangover"
_TNX_DR_US=$'\x1f'
declare -a _TNX_DR_ROWS=()
declare -a _TNX_DR_FILTER=()
declare -A _TNX_DR_GUEST=()

_tnx_dr_add() { # status category id title [detail] [fix]
  _TNX_DR_ROWS+=("$1${_TNX_DR_US}$2${_TNX_DR_US}$3${_TNX_DR_US}$4${_TNX_DR_US}${5:-}${_TNX_DR_US}${6:-}")
}

_tnx_dr_want() {
  [ ${#_TNX_DR_FILTER[@]} -eq 0 ] && return 0
  local c
  for c in "${_TNX_DR_FILTER[@]}"; do [ "$c" = "$1" ] && return 0; done
  return 1
}

_tnx_dr_jesc() {
  local v="$1"
  v="${v//\\/\\\\}"; v="${v//\"/\\\"}"
  v="${v//$'\n'/\\n}"; v="${v//$'\t'/\\t}"; v="${v//$'\r'/\\r}"
  printf '%s' "$v"
}

# Runs inside the Debian guest (serialised with `declare -f`). It only reads
# state and prints `key=value` lines; it never installs or changes anything.
_tnx_doctor_guest_probe() {
  local one root="$HOME/.local/opt/ternux-extensions" e name manifest artifact out libs
  _p() { printf '%s=%s\n' "$1" "$(printf '%s' "$2" | tr '\n\r' '  ')"; }
  _p guest.arch "$(uname -m 2>/dev/null)"
  _p guest.glibc "$(getconf GNU_LIBC_VERSION 2>/dev/null | awk '{print $2}')"
  _p guest.os "$( (. /etc/os-release 2>/dev/null && printf '%s' "${PRETTY_NAME:-unknown}") )"
  if sudo -n true >/dev/null 2>&1; then _p guest.sudo yes; else _p guest.sudo no; fi
  for one in startxfce4 glxinfo xdpyinfo pactl; do
    if command -v "$one" >/dev/null 2>&1; then _p "guest.cmd.$one" yes; else _p "guest.cmd.$one" no; fi
  done
  _p guest.dpkg_audit "$(dpkg --audit 2>/dev/null | grep -c . )"
  _p guest.disk_free_gb "$(df -Pk "$HOME" 2>/dev/null | awk 'NR==2{print int($4/1024/1024)}')"
  if [ -f /usr/local/lib/aarch64-linux-gnu/libvulkan_freedreno.so ] \
     && [ -f /usr/local/share/vulkan/icd.d/ternux_freedreno_icd.json ]; then
    _p guest.turnip managed
  elif [ -f /usr/share/vulkan/icd.d/freedreno_icd.aarch64.json ]; then
    _p guest.turnip fragile
  else
    _p guest.turnip missing
  fi
  for e in "$root"/*; do
    [ -d "$e" ] || continue
    name="${e##*/}"
    case "$name" in .*) continue ;; esac
    _p "ext.$name.present" yes
    manifest="$e/build-manifest.json"
    if [ -f "$manifest" ]; then
      artifact="$(sed -n 's/.*"artifact": *"\([^"]*\)".*/\1/p' "$manifest" | head -1)"
      _p "ext.$name.artifact" "${artifact:-unknown}"
    fi
    case "$name" in
      llama-vulkan|llama-htp-experimental)
        if [ -x "$e/bin/llama-cli" ]; then
          libs="$(ldd "$e/bin/llama-cli" 2>/dev/null | grep -c 'not found')"
          _p "ext.$name.missing_libs" "${libs:-0}"
          if [ "$name" = llama-vulkan ] && [ -f "$e/env.sh" ]; then
            out="$( ( . "$e/env.sh" >/dev/null 2>&1; timeout 15 llama-cli --version 2>&1 | head -2 ) )"
            _p "ext.$name.version" "$out"
          fi
        else
          _p "ext.$name.binary" missing
        fi
        if [ "$name" = llama-htp-experimental ]; then
          if [ -x "$e/bin/htp-run" ] && [ -f "$e/libexec/htp-broker.py" ]; then _p "ext.$name.broker" yes; else _p "ext.$name.broker" no; fi
        fi
        ;;
      wine-hangover)
        if [ -x "$e/bin/wine" ]; then
          out="$( ( . "$e/env.sh" >/dev/null 2>&1; timeout 30 "$e/bin/wine" --version 2>&1 | head -1 ) )"
          _p "ext.$name.version" "$out"
          libs="$(ldd "$e/lib/wine/aarch64-unix/ntdll.so" 2>/dev/null | grep -c 'not found')"
          _p "ext.$name.missing_libs" "${libs:-0}"
        else
          _p "ext.$name.binary" missing
        fi
        if [ -f "$e/lib/wine/aarch64-windows/libwow64fex.dll" ] || [ -f "$e/lib/wine/aarch64-windows/wowbox64.dll" ]; then
          _p "ext.$name.x86_32" yes
        else
          _p "ext.$name.x86_32" no
        fi
        if [ -f "$e/lib/wine/aarch64-windows/libarm64ecfex.dll" ]; then _p "ext.$name.x86_64" yes; else _p "ext.$name.x86_64" no; fi
        _p "ext.$name.gpu" "$( ( . "$e/env.sh" >/dev/null 2>&1; printf '%s' "${GALLIUM_DRIVER:-}" ) )"
        if [ -f "${WINEPREFIX:-$HOME/.wine}/system.reg" ]; then _p "ext.$name.prefix" yes; else _p "ext.$name.prefix" no; fi
        ;;
    esac
  done
  return 0
}

_tnx_dr_collect_guest() {
  local out line user
  user="${TERNUX_USER:-ternux}"
  out="$(
    {
      declare -f _tnx_doctor_guest_probe
      printf '_tnx_doctor_guest_probe\n'
    } | tnx_guest_login --shared-tmp --user "$user" -- bash -s 2>/dev/null
  )" || out=""
  while IFS= read -r line; do
    case "$line" in
      guest.*=*|ext.*=*) _TNX_DR_GUEST["${line%%=*}"]="${line#*=}" ;;
    esac
  done <<< "$out"
  [ ${#_TNX_DR_GUEST[@]} -gt 0 ]
}

_tnx_dr_system() {
  local arch storage ram avail swap sdk zone temp t name
  arch="$(tnx_detect_arch)"
  case "$arch" in
    aarch64|arm64) _tnx_dr_add ok system architecture "Architecture: $arch" ;;
    *) _tnx_dr_add fail system unsupported_architecture "Architecture: $arch" "Ternux targets ARM64 (aarch64) Android devices" "Use an ARM64 Android device" ;;
  esac
  sdk="$(tnx_detect_android_sdk)"
  _tnx_dr_add info system android "Android $(tnx_detect_android_version) (SDK ${sdk:-?})"

  storage="$(tnx_detect_storage_gb)"
  if [ "$storage" != "?" ] && [ "$storage" -lt 2 ] 2>/dev/null; then
    _tnx_dr_add warn system low_storage "Storage: ~${storage} GB free" "The desktop, GPU driver and extensions need several GB" "Free up storage space"
  else
    _tnx_dr_add ok system storage "Storage: ~${storage} GB free"
  fi

  ram="$(tnx_detect_ram_gb)"
  avail="$(awk '/MemAvailable/{printf "%d", $2/1024}' /proc/meminfo 2>/dev/null)"
  swap="$(awk '/SwapTotal/{printf "%d", $2/1024}' /proc/meminfo 2>/dev/null)"
  if [ -n "$avail" ] && [ "$avail" -lt 800 ] 2>/dev/null; then
    _tnx_dr_add warn system low_memory "Memory: ${avail} MB available of ~${ram} GB (swap ${swap:-0} MB)" "Android may kill background processes such as the desktop session" "Close other apps before starting the desktop or an emulator workload"
  else
    _tnx_dr_add ok system memory "Memory: ${avail:-?} MB available of ~${ram} GB (swap ${swap:-0} MB)"
  fi

  for zone in /sys/class/thermal/thermal_zone*; do
    [ -r "$zone/type" ] && [ -r "$zone/temp" ] || continue
    name="$(cat "$zone/type" 2>/dev/null)"
    case "$name" in *battery*) ;; *) continue ;; esac
    t="$(cat "$zone/temp" 2>/dev/null)"
    case "$t" in ''|*[!0-9-]*) continue ;; esac
    [ "$t" -gt 1000 ] 2>/dev/null && t=$((t / 1000))
    temp="$t"
    break
  done
  if [ -n "${temp:-}" ]; then
    if [ "$temp" -ge 43 ] 2>/dev/null; then
      _tnx_dr_add warn system battery_hot "Battery temperature: ${temp} °C" "Sustained heavy work at this temperature is throttled by Android" "Pause heavy builds, rendering or inference until the device cools"
    else
      _tnx_dr_add ok system battery_temp "Battery temperature: ${temp} °C"
    fi
  fi

  local sdir="${TERNUX_STATE_DIR:-$HOME/.local/share/ternux}"
  if [ -d "$sdir" ] && [ ! -w "$sdir" ]; then
    _tnx_dr_add fail system state_unwritable "State directory is not writable: $sdir" "Ternux cannot record installation progress" "Fix ownership: chmod u+w \"$sdir\""
  fi
}

_tnx_dr_host() {
  if tnx_has_cmd proot-distro; then
    _tnx_dr_add ok host proot_distro "proot-distro installed"
    if tnx_debian_installed; then
      _tnx_dr_add ok host debian "Debian container installed"
    else
      _tnx_dr_add warn host debian_not_installed "Debian container missing" "" "Run: ternux install"
    fi
  else
    _tnx_dr_add warn host proot_distro_missing "proot-distro missing" "" "pkg install proot-distro"
  fi
  if tnx_has_cmd termux-x11; then _tnx_dr_add ok host termux_x11 "termux-x11 installed"
  else _tnx_dr_add warn host termux_x11_missing "termux-x11 missing" "" "pkg install termux-x11-nightly"; fi
  if tnx_has_cmd pulseaudio; then _tnx_dr_add ok host pulseaudio "PulseAudio installed"
  else _tnx_dr_add warn host pulseaudio_missing "PulseAudio missing" "" "pkg install pulseaudio"; fi
  if tnx_has_cmd curl; then
    if curl --version >/dev/null 2>&1; then _tnx_dr_add ok host curl "curl runs"
    else _tnx_dr_add warn host curl_broken "curl fails to start (OpenSSL/library mismatch)" "Downloads, updates and extensions depend on it" "Run: ternux repair"; fi
  else
    _tnx_dr_add warn host curl_missing "curl missing" "" "pkg install curl"
  fi
  local phantom
  phantom="$(tnx_detect_phantom_killer)"
  case "$phantom" in
    enabled) _tnx_dr_add warn host phantom_process_killer_enabled "Android child-process monitoring appears ENABLED" "" "Review Android process restrictions and other Signal 9 causes (see docs)" ;;
    disabled) _tnx_dr_add ok host phantom_process_killer "Android child-process monitoring appears disabled" ;;
  esac
}

_tnx_dr_guest() {
  local k v glibc_minor
  if ! tnx_debian_installed; then
    _tnx_dr_add info guest guest_absent "Guest checks skipped: Debian container is not installed"
    return 0
  fi
  if [ "${_TNX_DR_QUICK:-0}" = 1 ]; then
    _tnx_dr_add info guest guest_skipped "Guest checks skipped (--quick)"
    return 0
  fi
  if [ ${#_TNX_DR_GUEST[@]} -eq 0 ]; then
    _tnx_dr_add info guest guest_probe_unavailable "Could not query the Debian guest" "The probe could not log in; this is not necessarily a fault" "Try: ternux start, then rerun doctor"
    return 0
  fi
  _tnx_dr_add ok guest guest_os "Guest: ${_TNX_DR_GUEST[guest.os]:-unknown} (${_TNX_DR_GUEST[guest.arch]:-?})"
  v="${_TNX_DR_GUEST[guest.glibc]:-}"
  glibc_minor="${v#2.}"
  if [[ "$v" =~ ^2\.([0-9]+)$ ]]; then
    if [ "${BASH_REMATCH[1]}" -lt 38 ]; then
      _tnx_dr_add warn guest glibc_old "glibc $v in the guest" "Release extensions need glibc 2.38 or newer" "Use the verified Debian 13 (trixie) guest"
    else
      _tnx_dr_add ok guest glibc "glibc $v (extensions need 2.38+)"
    fi
  else
    _tnx_dr_add info guest glibc "glibc version unknown"
  fi
  if [ "${_TNX_DR_GUEST[guest.sudo]:-no}" = yes ]; then _tnx_dr_add ok guest sudo "Passwordless sudo works"
  else _tnx_dr_add warn guest sudo_missing "Passwordless sudo does not work" "Package installs inside the guest will ask for a password" "Run: ternux repair"; fi
  for k in startxfce4 glxinfo xdpyinfo pactl; do
    if [ "${_TNX_DR_GUEST[guest.cmd.$k]:-no}" = yes ]; then _tnx_dr_add ok guest "cmd_$k" "$k present"
    else _tnx_dr_add warn guest "guest_cmd_${k}_missing" "$k missing in the guest" "" "Run: ternux install --resume"; fi
  done
  v="${_TNX_DR_GUEST[guest.dpkg_audit]:-0}"
  if [ "$v" -gt 0 ] 2>/dev/null; then
    _tnx_dr_add warn guest dpkg_broken "dpkg reports unfinished or broken packages" "Interrupted upgrades leave the package database inconsistent" "In Debian run: sudo dpkg --configure -a && sudo apt -f install"
  else
    _tnx_dr_add ok guest dpkg "Package database consistent"
  fi
  v="${_TNX_DR_GUEST[guest.disk_free_gb]:-}"
  if [ -n "$v" ] && [ "$v" -lt 2 ] 2>/dev/null; then
    _tnx_dr_add warn guest guest_low_disk "Guest home has ~${v} GB free" "" "Free up storage space"
  elif [ -n "$v" ]; then
    _tnx_dr_add ok guest guest_disk "Guest home has ~${v} GB free"
  fi
}

_tnx_dr_graphics() {
  local vulkan gpu backend configured_backend renderer="" current_backend kgsl
  vulkan="$(tnx_detect_vulkan)"
  case "$vulkan" in
    yes*|"yes (Adreno)") _tnx_dr_add ok graphics vulkan "Vulkan: $vulkan" ;;
    *) _tnx_dr_add warn graphics vulkan_unavailable "Vulkan: ${vulkan:-no}" "" "Install Vulkan loader" ;;
  esac
  gpu="$(tnx_detect_gpu)"
  configured_backend="$(tnx_canonical_backend "$(tnx_state_get "backend")")"
  backend="$(tnx_detect_backend)"
  _DR_GPU="$gpu"; _DR_BACKEND_RECOMMENDED="$backend"; _DR_BACKEND_CONFIGURED="$configured_backend"; _DR_VULKAN="$vulkan"
  _tnx_dr_add ok graphics gpu "GPU: $gpu"
  _tnx_dr_add ok graphics backend_recommended "Recommended backend: $backend"
  if [ -n "$configured_backend" ]; then
    _tnx_dr_add ok graphics backend_configured "Configured: $configured_backend"
    if [ "$configured_backend" != "$backend" ]; then
      _tnx_dr_add warn graphics backend_mismatch "Configured backend ($configured_backend) differs from the recommended one ($backend)" "" "If unintended: ternux backend set auto && ternux repair"
    fi
  else
    _tnx_dr_add warn graphics backend_not_configured "GPU backend is not configured" "" "Run: ternux backend set auto && ternux repair"
  fi

  kgsl="${TERNUX_KGSL_DEVICE:-/dev/kgsl-3d0}"
  if [ "$configured_backend" = zink ]; then
    if [ -e "$kgsl" ]; then _tnx_dr_add ok graphics kgsl "Adreno KGSL node visible ($kgsl)"
    else _tnx_dr_add warn graphics kgsl_missing "Zink is configured but $kgsl is not visible" "Zink/Turnip cannot reach the GPU without it" "ternux backend set virgl && ternux repair"; fi
    case "${_TNX_DR_GUEST[guest.turnip]:-}" in
      managed) _tnx_dr_add ok graphics turnip "Turnip driver present (apt-safe layout)" ;;
      fragile) _tnx_dr_add warn graphics turnip_fragile "Turnip is on a dpkg-owned path" "A mesa upgrade will revert it (docs/GRAPHICS-PERSISTENCE.md)" "Run: ternux repair" ;;
      missing) _tnx_dr_add warn graphics turnip_missing "Turnip driver files missing" "" "Run: ternux repair" ;;
    esac
  fi

  if tnx_debian_installed; then
    renderer="$(tnx_detect_renderer)"
    if [ -n "$renderer" ] && [ "$renderer" != "unknown" ]; then
      case "$renderer" in
        *llvmpipe*) _tnx_dr_add warn graphics software_rendering "Renderer: $renderer" "CPU rendering is much slower than the GPU path" "Reinstall GPU driver: ternux repair" ;;
        *) _tnx_dr_add ok graphics renderer "Renderer: $renderer" ;;
      esac
      tnx_state_set "renderer" "$renderer"
    fi
  fi
  _DR_RENDERER="$renderer"

  if [ -f "$HOME/x.sh" ]; then _tnx_dr_add ok graphics launcher "Launcher exists"
  else _tnx_dr_add warn graphics launcher_missing "Launcher missing" "" "Run: ternux install"; fi

  current_backend="$configured_backend"
  if [ "$current_backend" = virgl ] || [ -z "$current_backend" ]; then
    if tnx_has_cmd virgl_test_server_android; then _tnx_dr_add ok graphics virgl "VirGL present"
    else _tnx_dr_add warn graphics virgl_missing "VirGL not installed" "" "pkg install virglrenderer-android"; fi
  fi
}

_tnx_dr_extensions() {
  local name p v art
  if ! tnx_debian_installed; then
    _tnx_dr_add info extensions extensions_absent "Extension checks skipped: Debian container is not installed"
    return 0
  fi
  if [ "${_TNX_DR_QUICK:-0}" = 1 ]; then
    _tnx_dr_add info extensions extensions_skipped "Extension checks skipped (--quick)"
    return 0
  fi
  if [ ${#_TNX_DR_GUEST[@]} -eq 0 ]; then
    _tnx_dr_add info extensions extensions_probe_unavailable "Extension checks need the Debian guest, which could not be queried"
    return 0
  fi
  for name in $TNX_DOCTOR_EXTENSIONS; do
    p="ext.$name"
    if [ "${_TNX_DR_GUEST[$p.present]:-no}" != yes ]; then
      _tnx_dr_add info extensions "ext_$name" "$name: not installed" "" "ternux extension install $name"
      continue
    fi
    art="${_TNX_DR_GUEST[$p.artifact]:-}"
    if [ -z "$art" ]; then
      _tnx_dr_add warn extensions "ext_${name}_manifest" "$name: build-manifest.json missing or unreadable" "The installation looks incomplete" "Inspect, then remove the exact directory and reinstall: ternux extension install $name"
      continue
    fi
    case "$name" in
      llama-vulkan|llama-htp-experimental)
        if [ "${_TNX_DR_GUEST[$p.binary]:-}" = missing ]; then
          _tnx_dr_add warn extensions "ext_${name}_binary" "$name: bin/llama-cli missing" "" "Reinstall: ternux extension install $name"
        elif [ "${_TNX_DR_GUEST[$p.missing_libs]:-0}" -gt 0 ] 2>/dev/null; then
          _tnx_dr_add warn extensions "ext_${name}_libs" "$name: ${_TNX_DR_GUEST[$p.missing_libs]} shared librar(ies) not found" "" "In Debian: sudo apt install libgomp1 libvulkan1 libssl3t64 (HTP: libgbinder1 libglibutil1 libfastrpc1)"
        else
          v="${_TNX_DR_GUEST[$p.version]:-}"
          _tnx_dr_add ok extensions "ext_$name" "$name: $art${v:+ — ${v%%$'\n'*}}"
        fi
        if [ "$name" = llama-htp-experimental ]; then
          if [ "${_TNX_DR_GUEST[$p.broker]:-no}" = yes ]; then _tnx_dr_add ok extensions ext_htp_broker "HTP launcher and broker present (experimental)"
          else _tnx_dr_add warn extensions ext_htp_broker_missing "HTP launcher or broker missing" "" "Reinstall: ternux extension install llama-htp-experimental"; fi
        fi
        ;;
      wine-hangover)
        if [ "${_TNX_DR_GUEST[$p.binary]:-}" = missing ]; then
          _tnx_dr_add warn extensions ext_wine_binary "wine-hangover: bin/wine missing" "" "Reinstall: ternux extension install wine-hangover"
        else
          v="${_TNX_DR_GUEST[$p.version]:-}"
          case "$v" in
            wine-*) _tnx_dr_add ok extensions ext_wine_hangover "wine-hangover: $v ($art)" ;;
            *) _tnx_dr_add warn extensions ext_wine_run "wine-hangover: wine did not report a version" "${v:-no output}" "Run: ternux doctor extensions --json, then see guides/wine-hangover-extension.md" ;;
          esac
          if [ "${_TNX_DR_GUEST[$p.missing_libs]:-0}" -gt 0 ] 2>/dev/null; then
            _tnx_dr_add warn extensions ext_wine_libs "wine-hangover: ${_TNX_DR_GUEST[$p.missing_libs]} runtime librar(ies) not found" "" "Rerun: ternux extension install wine-hangover (it lists the apt packages to add)"
          fi
          if [ "${_TNX_DR_GUEST[$p.x86_32]:-no}" = yes ]; then _tnx_dr_add ok extensions ext_wine_x86 "x86 (32-bit) emulation DLL present"
          else _tnx_dr_add warn extensions ext_wine_x86_missing "x86 (32-bit) emulation DLL missing" "32-bit Windows programs cannot run" "Reinstall: ternux extension install wine-hangover"; fi
          if [ "${_TNX_DR_GUEST[$p.x86_64]:-no}" = yes ]; then _tnx_dr_add ok extensions ext_wine_x64 "x86-64 emulation DLL present"
          else _tnx_dr_add info extensions ext_wine_x64_missing "x86-64 emulation DLL missing" "64-bit Windows programs cannot run through this path"; fi
          case "${_TNX_DR_GUEST[$p.gpu]:-}" in
            zink) _tnx_dr_add ok extensions ext_wine_gpu "Wine graphics: GPU through Zink/Turnip" ;;
            virpipe) _tnx_dr_add ok extensions ext_wine_gpu "Wine graphics: VirGL (host-accelerated)" ;;
            "") _tnx_dr_add info extensions ext_wine_gpu "Wine graphics: CPU fallback (llvmpipe)" "No GPU driver is selected outside the desktop session: no Adreno KGSL node is visible here. In the Ternux desktop session the session driver (zink or VirGL) is inherited." ;;
            *) _tnx_dr_add info extensions ext_wine_gpu "Wine graphics: GALLIUM_DRIVER=${_TNX_DR_GUEST[$p.gpu]}" ;;
          esac
          if [ "${_TNX_DR_GUEST[$p.prefix]:-no}" = yes ]; then _tnx_dr_add ok extensions ext_wine_prefix "Wine prefix initialised"
          else _tnx_dr_add info extensions ext_wine_prefix "Wine prefix not created yet" "" "source the extension env.sh, then run: wineboot -i"; fi
        fi
        ;;
    esac
  done
}

tnx_cmd_doctor() {
  local strict=0 quick=0 arg c valid
  _TNX_DR_ROWS=(); _TNX_DR_FILTER=(); _TNX_DR_GUEST=(); _TNX_DR_QUICK=0
  _DR_GPU=""; _DR_BACKEND_RECOMMENDED=""; _DR_BACKEND_CONFIGURED=""; _DR_VULKAN=""; _DR_RENDERER=""
  for arg in "$@"; do
    case "$arg" in
      --strict) strict=1 ;;
      --quick) quick=1 ;;
      -*) tnx_fail "Unknown doctor option: $arg"; echo "Usage: ternux doctor [CATEGORY...] [--quick] [--strict] [--json]" >&2; return 2 ;;
      *)
        valid=0
        for c in $TNX_DOCTOR_CATEGORIES; do [ "$c" = "$arg" ] && valid=1; done
        if [ "$valid" -ne 1 ]; then
          tnx_fail "Unknown doctor category: $arg (choose from: $TNX_DOCTOR_CATEGORIES)"
          return 2
        fi
        _TNX_DR_FILTER+=("$arg")
        ;;
    esac
  done
  _TNX_DR_QUICK="$quick"

  tnx_step "Running diagnostics..."
  tnx_require_termux

  if { _tnx_dr_want guest || _tnx_dr_want graphics || _tnx_dr_want extensions; } &&
     [ "$quick" -eq 0 ] && tnx_debian_installed; then
    _tnx_dr_collect_guest || true
  fi
  _tnx_dr_want system && _tnx_dr_system
  _tnx_dr_want host && _tnx_dr_host
  _tnx_dr_want guest && _tnx_dr_guest
  _tnx_dr_want graphics && _tnx_dr_graphics
  _tnx_dr_want extensions && _tnx_dr_extensions

  local status="ok" n_ok=0 n_warn=0 n_fail=0 n_info=0
  local -a issues=() actions=()
  local row st cat id title detail fix
  for row in "${_TNX_DR_ROWS[@]}"; do
    IFS="$_TNX_DR_US" read -r st cat id title detail fix <<< "$row"
    case "$st" in
      ok) n_ok=$((n_ok + 1)) ;;
      info) n_info=$((n_info + 1)) ;;
      warn) n_warn=$((n_warn + 1)); issues+=("$id"); actions+=("$fix"); [ "$status" = "ok" ] && status="warning" ;;
      fail) n_fail=$((n_fail + 1)); issues+=("$id"); actions+=("$fix"); status="error" ;;
    esac
  done

  local rc=0
  if [ "$strict" -eq 1 ]; then
    case "$status" in warning) rc=1 ;; error) rc=2 ;; esac
  fi

  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    local checks_json="" first=1
    for row in "${_TNX_DR_ROWS[@]}"; do
      IFS="$_TNX_DR_US" read -r st cat id title detail fix <<< "$row"
      [ "$first" -eq 0 ] && checks_json+=","
      first=0
      checks_json+="{\"id\":\"$(_tnx_dr_jesc "$id")\",\"category\":\"$cat\",\"status\":\"$st\",\"title\":\"$(_tnx_dr_jesc "$title")\",\"detail\":\"$(_tnx_dr_jesc "$detail")\",\"fix\":\"$(_tnx_dr_jesc "$fix")\"}"
    done
    tnx_json_init
    tnx_json_add "command" "doctor"
    tnx_json_add "status" "$status"
    tnx_json_add "timestamp" "$(__tnx_ts)"
    tnx_json_add "version" "$TERNUX_VERSION"
    tnx_json_add "android_version" "$(tnx_detect_android_version)"
    tnx_json_add "architecture" "$(tnx_detect_arch)"
    tnx_json_add "gpu" "$_DR_GPU"
    tnx_json_add "backend" "${_DR_BACKEND_CONFIGURED:-$_DR_BACKEND_RECOMMENDED}"
    tnx_json_add "renderer" "${_DR_RENDERER:-unknown}"
    tnx_json_add "vulkan" "$_DR_VULKAN"
    tnx_json_add_raw "schema_version" "2"
    tnx_json_add_raw "summary" "{\"ok\":$n_ok,\"warn\":$n_warn,\"fail\":$n_fail,\"info\":$n_info}"
    tnx_json_add_raw "checks" "[$checks_json]"
    tnx_json_add_array "issues" "${issues[@]}"
    tnx_json_add_array "recommended_actions" "${actions[@]}"
    tnx_json_end
    return "$rc"
  fi

  # --- Human output ---
  local last_cat=""
  for row in "${_TNX_DR_ROWS[@]}"; do
    IFS="$_TNX_DR_US" read -r st cat id title detail fix <<< "$row"
    if [ "$cat" != "$last_cat" ]; then
      tnx_header "$(printf '%s' "$cat" | sed 's/./\U&/')"
      last_cat="$cat"
    fi
    case "$st" in
      ok) tnx_ok "$title" ;;
      warn) tnx_warn "$title" ;;
      fail) tnx_fail "$title" ;;
      info) tnx_info "$title" ;;
    esac
    if [ "$st" = warn ] || [ "$st" = fail ] || [ "$st" = info ]; then
      [ -n "$detail" ] && [ "${TERNUX_QUIET:-0}" != "1" ] && printf "         ${TNX_CD}%s${TNX_C0}\n" "$detail"
      [ -n "$fix" ] && [ "${TERNUX_QUIET:-0}" != "1" ] && printf "         → ${TNX_CD}%s${TNX_C0}\n" "$fix"
    fi
  done
  echo ""

  tnx_header "Diagnostic Summary"
  printf "  ${TNX_CY}Status:${TNX_C0} ${TNX_CW}%s${TNX_C0}   ok %d · warn %d · fail %d · info %d\n" "$status" "$n_ok" "$n_warn" "$n_fail" "$n_info"
  if [ ${#issues[@]} -eq 0 ]; then
    printf "  ${TNX_CG}✓ All checks passed${TNX_C0}\n"
    tnx_info "Your installation looks healthy."
  else
    printf "  ${TNX_CY}Issues:${TNX_C0} ${#issues[@]}\n\n"
    local i
    for ((i=0; i<${#issues[@]}; i++)); do
      printf "  ${TNX_CR}✗${TNX_C0} ${TNX_CW}%s${TNX_C0}\n" "${issues[$i]}"
      [ -n "${actions[$i]}" ] && printf "    → ${TNX_CD}%s${TNX_C0}\n" "${actions[$i]}"
    done
  fi
  echo ""
  return "$rc"
}

# ---------------------------------------------------------------------------
# tnx_cmd_verify — installation completeness check
# ---------------------------------------------------------------------------
tnx_cmd_verify() {
  tnx_step "Verifying installation..."

  # Verification is safe to run anywhere: outside Termux the normal checks
  # report missing components instead of replacing structured output with a
  # fatal environment error.
  local rc=0
  local -a checks=()
  clear_line() { printf "\r\033[K"; }

  # Check binaries
  for b in termux-x11 proot-distro pulseaudio; do
    if tnx_has_cmd "$b"; then
      checks+=("${b}:installed")
      [ "${TERNUX_JSON:-0}" != "1" ] && tnx_ok "$b found"
    else
      checks+=("${b}:missing")
      [ "${TERNUX_JSON:-0}" != "1" ] && tnx_fail "$b missing"
      rc=1
    fi
  done

  # Launcher
  if [ -x "$HOME/x.sh" ]; then
    checks+=("launcher:present")
    [ "${TERNUX_JSON:-0}" != "1" ] && tnx_ok "Launcher executable"
  else
    checks+=("launcher:missing"); rc=1
    [ "${TERNUX_JSON:-0}" != "1" ] && tnx_fail "Launcher missing"
  fi

  # Debian container
  if tnx_debian_installed; then
    checks+=("debian:installed")
    if tnx_guest_login --user "${TERNUX_USER:-ternux}" -- bash -c 'command -v startxfce4 >/dev/null && command -v pactl >/dev/null && sudo -n true >/dev/null' 2>/dev/null; then
      checks+=("debian_services:ok")
      [ "${TERNUX_JSON:-0}" != "1" ] && tnx_ok "Debian services verified"
    else
      checks+=("debian_services:failed"); rc=1
      [ "${TERNUX_JSON:-0}" != "1" ] && tnx_fail "Debian desktop services or passwordless sudo are incomplete"
    fi
  else
    checks+=("debian:not_installed"); rc=1
    [ "${TERNUX_JSON:-0}" != "1" ] && tnx_warn "Debian not installed"
  fi

  # GPU driver
  local backend
  backend="$(tnx_canonical_backend "$(tnx_state_get "backend")")"
  if [ "$backend" = "zink" ]; then
    # A Turnip newer than Debian's is what makes the Adreno visible to Vulkan at
    # all, so where it lives decides whether apt can take it away. The managed
    # layout keeps it under /usr/local, outside dpkg's reach; the fragile layout
    # overwrites a dpkg-owned path and is reverted by any mesa upgrade. See
    # docs/GRAPHICS-PERSISTENCE.md.
    local turnip_layout="unknown"
    if tnx_has_cmd proot-distro; then
      turnip_layout="$(tnx_guest_login -- bash -c '
        if [ -f /usr/local/lib/aarch64-linux-gnu/libvulkan_freedreno.so ] \
           && [ -f /usr/local/share/vulkan/icd.d/ternux_freedreno_icd.json ]; then
          echo managed
        elif [ -f /usr/share/vulkan/icd.d/freedreno_icd.aarch64.json ]; then
          echo fragile
        else
          echo missing
        fi' 2>/dev/null)"
    fi
    case "$turnip_layout" in
      managed)
        checks+=("turnip:present")
        [ "${TERNUX_JSON:-0}" != "1" ] && tnx_ok "Turnip driver present (apt-safe layout)"
        ;;
      fragile)
        checks+=("turnip:fragile"); rc=1
        [ "${TERNUX_JSON:-0}" != "1" ] && tnx_warn "Turnip driver is on a dpkg-owned path; a mesa upgrade will revert it. See docs/GRAPHICS-PERSISTENCE.md"
        ;;
      *)
        checks+=("turnip:missing"); rc=1
        [ "${TERNUX_JSON:-0}" != "1" ] && tnx_warn "Turnip files missing"
        ;;
    esac
  elif [ "$backend" = "virgl" ]; then
    if tnx_has_cmd virgl_test_server_android; then
      checks+=("virgl:present")
    else
      checks+=("virgl:missing"); rc=1
      [ "${TERNUX_JSON:-0}" != "1" ] && tnx_warn "VirGL host renderer missing"
    fi
  else
    checks+=("backend:not_configured"); rc=1
    [ "${TERNUX_JSON:-0}" != "1" ] && tnx_warn "GPU backend is not configured"
  fi

  # JSON output
  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    local all_checks=""
    for c in "${checks[@]}"; do
      [ -n "$all_checks" ] && all_checks+=","
      all_checks+="$c"
    done
    tnx_json_object "verify" "$([ $rc -eq 0 ] && echo "passed" || echo "failed")" \
      "android_version" "$(tnx_detect_android_version)" \
      "gpu" "$(tnx_detect_gpu)" \
      "checks" "$all_checks"
    return "$rc"
  fi

  echo ""
  [ "$rc" -eq 0 ] && tnx_ok "Verification passed." || tnx_warn "Verification found issues. Run 'ternux doctor' for details."
  return "$rc"
}