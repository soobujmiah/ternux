# =============================================================================
#  ternux — repair (auto-fix common issues)
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah) — MIT License
#  https://github.com/soobujmiah/ternux
# =============================================================================

# shellcheck source=lib/core.sh
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"
# shellcheck source=lib/detect.sh
. "$(dirname "${BASH_SOURCE[0]}")/detect.sh"
# Reuse the same validated GPU and launcher implementations as installation.
# shellcheck source=lib/phases.sh
. "$(dirname "${BASH_SOURCE[0]}")/phases.sh"

# Helpers set this to 1 only when they actually change the installation.
_TNX_REPAIR_CHANGED=0

# Kept as a helper so the hardware boundary can be isolated in tests without
# creating anything under /dev.
_tnx_repair_kgsl_available() { [ -e /dev/kgsl-3d0 ]; }

# ---------------------------------------------------------------------------
# tnx_cmd_repair
# ---------------------------------------------------------------------------
tnx_cmd_repair() {
  tnx_step "Running repairs..."
  tnx_require_termux
  local rc=0
  local -a repairs_done=()

  # Each helper reports success even when its component is already healthy.
  # The changed flag keeps the summary from calling a health check a repair.
  tnx_header "1/6  curl/OpenSSL"
  _TNX_REPAIR_CHANGED=0
  _tnx_repair_curl || rc=1
  [ "$_TNX_REPAIR_CHANGED" = "1" ] && repairs_done+=("curl_fixed")

  tnx_header "2/6  Termux:X11"
  _TNX_REPAIR_CHANGED=0
  _tnx_repair_x11 || rc=1
  [ "$_TNX_REPAIR_CHANGED" = "1" ] && repairs_done+=("x11_fixed")

  tnx_header "3/6  GPU backend"
  _TNX_REPAIR_CHANGED=0
  _tnx_repair_backend || rc=1
  [ "$_TNX_REPAIR_CHANGED" = "1" ] && repairs_done+=("backend_applied")

  tnx_header "4/6  Launcher"
  _TNX_REPAIR_CHANGED=0
  _tnx_repair_launcher || rc=1
  [ "$_TNX_REPAIR_CHANGED" = "1" ] && repairs_done+=("launcher_regenerated")

  tnx_header "5/6  Mesa cache"
  _TNX_REPAIR_CHANGED=0
  _tnx_repair_mesa_cache || rc=1
  [ "$_TNX_REPAIR_CHANGED" = "1" ] && repairs_done+=("cache_cleared")

  tnx_header "6/6  PulseAudio"
  _TNX_REPAIR_CHANGED=0
  _tnx_repair_pulseaudio || rc=1
  [ "$_TNX_REPAIR_CHANGED" = "1" ] && repairs_done+=("pulseaudio_fixed")

  [ "${TERNUX_JSON:-0}" != "1" ] && echo ""

  mkdir -p "$TERNUX_STATE_DIR"
  local r
  for r in "${repairs_done[@]}"; do
    echo "$(__tnx_ts) $r" >> "$TERNUX_STATE_DIR/repairs"
  done

  [ "${TERNUX_JSON:-0}" = "1" ] && {
    tnx_json_object "repair" "$([ $rc -eq 0 ] && echo "ok" || echo "partial")" \
      "repairs_performed" "$(IFS=,; echo "${repairs_done[*]}")"
    return "$rc"
  }

  tnx_header "Repair Summary"
  if [ ${#repairs_done[@]} -eq 0 ]; then
    [ "$rc" -eq 0 ] && tnx_ok "No repairs needed." || tnx_warn "No repair completed; review the errors above."
  else
    tnx_ok "${#repairs_done[@]} repair(s) performed:"
    for r in "${repairs_done[@]}"; do
      printf "  ${TNX_CG}✓${TNX_C0}  ${TNX_CD}%s${TNX_C0}\n" "$r"
    done
    echo ""
    tnx_info "Run 'ternux doctor' and verify the renderer after restarting the desktop."
  fi
  return "$rc"
}

_tnx_repair_curl() {
  if ! tnx_has_cmd curl; then
    pkg install -y curl 2>/dev/null || { tnx_fail "Could not install curl"; return 1; }
    _TNX_REPAIR_CHANGED=1
    tnx_ok "curl installed"
    return 0
  fi
  curl --version >/dev/null 2>&1 && { tnx_ok "curl working"; return 0; }
  tnx_warn "curl broken — repairing..."
  pkg install -y curl openssl openssl-tool libngtcp2 libnghttp3 2>/dev/null || true
  if curl --version >/dev/null 2>&1; then
    _TNX_REPAIR_CHANGED=1
    tnx_ok "curl repaired"
    return 0
  fi
  tnx_warn "curl still broken; wget can be used as a temporary fallback"
  return 1
}

_tnx_repair_x11() {
  tnx_has_cmd termux-x11 && { tnx_ok "termux-x11 installed"; return 0; }
  tnx_warn "Installing Termux:X11 package..."
  pkg install -y x11-repo 2>/dev/null || true
  pkg install -y termux-x11-nightly 2>/dev/null || pkg install -y termux-x11 2>/dev/null || true
  if tnx_has_cmd termux-x11; then
    _TNX_REPAIR_CHANGED=1
    tnx_ok "termux-x11 installed"
    return 0
  fi
  tnx_fail "Could not install termux-x11-nightly or termux-x11"
  return 1
}

_tnx_repair_backend() {
  local backend user_name locale launcher_ok=0 driver_ok=0
  backend="$(tnx_state_get "backend")"
  [ -z "$backend" ] && backend="$(tnx_detect_backend)"
  [ "$backend" = "zink-turnip" ] && backend="zink"

  case "$backend" in
    zink)
      _tnx_repair_kgsl_available || { tnx_fail "Zink/Turnip requires /dev/kgsl-3d0."; return 1; }
      local expected_driver_sha="" expected_icd_sha="" current_driver_sha="" current_icd_sha=""
      expected_driver_sha="$(tnx_state_get "freedreno_driver_sha")"
      expected_icd_sha="$(tnx_state_get "freedreno_icd_sha")"
      if tnx_has_cmd proot-distro; then
        current_driver_sha="$(proot-distro login debian -- sha256sum /usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so 2>/dev/null | awk '{print $1}')"
        current_icd_sha="$(proot-distro login debian -- sha256sum /usr/share/vulkan/icd.d/freedreno_icd.aarch64.json 2>/dev/null | awk '{print $1}')"
      fi
      if [ -n "$expected_driver_sha" ] && [ -n "$expected_icd_sha" ] && \
         [ "$current_driver_sha" = "$expected_driver_sha" ] && \
         [ "$current_icd_sha" = "$expected_icd_sha" ]; then
        driver_ok=1
      fi
      if [ "$driver_ok" -eq 0 ]; then
        tnx_warn "Turnip files are missing or incomplete — reinstalling the validated targets..."
        tnx_phase_gpu zink || return 1
        _TNX_REPAIR_CHANGED=1
      fi
      ;;
    virgl)
      if ! tnx_has_cmd virgl_test_server_android; then
        tnx_warn "Installing the VirGL host renderer..."
        pkg install -y virglrenderer-android 2>/dev/null || {
          tnx_fail "Could not install virglrenderer-android"
          return 1
        }
        _TNX_REPAIR_CHANGED=1
      fi
      ;;
    *)
      tnx_fail "Stored backend '$backend' is invalid. Run: ternux backend set auto"
      return 1
      ;;
  esac

  user_name="$(tnx_state_get "user")"
  locale="$(tnx_state_get "locale")"
  user_name="${user_name:-ternux}"
  locale="${locale:-en_US.UTF-8}"

  if [ -f "$HOME/x.sh" ] && bash -n "$HOME/x.sh" 2>/dev/null && \
     grep -q -- "--user $user_name" "$HOME/x.sh"; then
    case "$backend" in
      zink) grep -q "MESA_LOADER_DRIVER_OVERRIDE=zink" "$HOME/x.sh" && launcher_ok=1 ;;
      virgl) grep -q "GALLIUM_DRIVER=virpipe" "$HOME/x.sh" && launcher_ok=1 ;;
    esac
  fi

  if [ "$launcher_ok" -eq 0 ]; then
    tnx_warn "Regenerating launcher for backend '$backend'..."
    tnx_phase_launcher "$user_name" "$backend" "$locale" || return 1
    _TNX_REPAIR_CHANGED=1
  fi

  tnx_state_set "backend" "$backend"
  tnx_ok "Backend applied: $backend"
  return 0
}

_tnx_repair_launcher() {
  [ -x "$HOME/x.sh" ] && bash -n "$HOME/x.sh" 2>/dev/null && { tnx_ok "Launcher OK"; return 0; }

  local backend user_name locale
  backend="$(tnx_state_get "backend")"
  user_name="$(tnx_state_get "user")"
  locale="$(tnx_state_get "locale")"
  backend="${backend:-$(tnx_detect_backend)}"
  [ "$backend" = "zink-turnip" ] && backend="zink"
  user_name="${user_name:-ternux}"
  locale="${locale:-en_US.UTF-8}"

  tnx_warn "Launcher missing or broken — regenerating..."
  tnx_phase_launcher "$user_name" "$backend" "$locale" || return 1
  _TNX_REPAIR_CHANGED=1
  return 0
}

_tnx_repair_mesa_cache() {
  local out=""
  if tnx_has_cmd proot-distro; then
    out="$(proot-distro login debian --user "${TERNUX_USER:-ternux}" -- bash -c '
      if [ -d ~/.cache/mesa ] && [ "$(ls -A ~/.cache/mesa 2>/dev/null)" ]; then
        rm -rf ~/.cache/mesa/* 2>/dev/null && echo CLEARED
      fi
    ' 2>/dev/null || true)"
  fi
  if printf '%s' "$out" | grep -q "CLEARED"; then
    _TNX_REPAIR_CHANGED=1
    tnx_ok "Mesa cache cleared"
  else
    tnx_ok "No stale cache"
  fi
  return 0
}

_tnx_repair_pulseaudio() {
  local pa_conf="${PREFIX:-/data/data/com.termux/files/usr}/etc/pulse/default.pa"
  [ ! -f "$pa_conf" ] && { tnx_warn "PulseAudio config not found"; return 1; }
  _tnx_configure_pulse_bridge "$pa_conf" || return 1
  if [ "$_TNX_PULSE_CHANGED" = "1" ]; then
    _TNX_REPAIR_CHANGED=1
    tnx_ok "PulseAudio bridge repaired and bound to loopback"
  else
    tnx_ok "PulseAudio bridge configured"
  fi
  return 0
}
