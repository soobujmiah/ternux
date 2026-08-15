# =============================================================================
#  ternux — diagnostics (doctor) library
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah) — MIT License
#  https://github.com/soobujmiah/ternux
# =============================================================================

# shellcheck source=lib/core.sh
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"
# shellcheck source=lib/detect.sh
. "$(dirname "${BASH_SOURCE[0]}")/detect.sh"

# ---------------------------------------------------------------------------
# Doctor — comprehensive system diagnostics
# ---------------------------------------------------------------------------

tnx_doctor_run() {
  tnx_step "Running diagnostics..."

  local status="ok"
  local -a issues=()
  local -a actions=()
  local -a detail_keys=()
  local -a detail_vals=()

  # 1. Termux environment
  if tnx_is_termux; then
    tnx_ok "Termux environment detected"
  else
    tnx_fail "Not running inside Termux"
    issues+=("not_in_termux")
    actions+=("Install Termux from F-Droid or GitHub releases")
    status="error"
  fi

  # 2. Storage
  local storage
  storage="$(tnx_detect_storage_gb)"
  tnx_ok "Storage: ~${storage} GB free"
  if [ "$storage" != "?" ] && [ "$storage" -lt 2 ] 2>/dev/null; then
    tnx_warn "Low storage space (~${storage} GB)"
    issues+=("low_storage")
    actions+=("Free up storage space; the base install needs ~12 GB")
    [ "$status" = "ok" ] && status="warning"
  fi

  # 3. PRoot
  if tnx_has_cmd proot-distro; then
    tnx_ok "proot-distro installed"
    if proot-distro list 2>/dev/null | grep -q "debian.*installed"; then
      tnx_ok "Debian container installed"
    else
      tnx_warn "Debian container not installed"
      issues+=("debian_not_installed")
      actions+=("Run: ternux install")
      [ "$status" = "ok" ] && status="warning"
    fi
  else
    tnx_warn "proot-distro not installed"
    issues+=("proot_distro_missing")
    actions+=("Install proot-distro: pkg install proot-distro -y")
    [ "$status" = "ok" ] && status="warning"
  fi

  # 4. Termux:X11
  if tnx_has_cmd termux-x11; then
    tnx_ok "termux-x11 installed"
  else
    tnx_warn "termux-x11 not installed"
    issues+=("termux_x11_missing")
    actions+=("Install termux-x11: pkg install termux-x11-nightly -y")
    [ "$status" = "ok" ] && status="warning"
  fi

  # 5. PulseAudio
  if tnx_has_cmd pulseaudio; then
    tnx_ok "PulseAudio installed"
  else
    tnx_warn "PulseAudio not installed"
    issues+=("pulseaudio_missing")
    actions+=("Install PulseAudio: pkg install pulseaudio -y")
    [ "$status" = "ok" ] && status="warning"
  fi

  # 6. Vulkan
  local vulkan
  vulkan="$(tnx_detect_vulkan)"
  case "$vulkan" in
    yes*) tnx_ok "Vulkan: $vulkan" ;;
    *)
      tnx_warn "Vulkan: $vulkan"
      issues+=("vulkan_unavailable")
      actions+=("Install Vulkan loader: pkg install mesa-vulkan-icd-freedreno -y")
      [ "$status" = "ok" ] && status="warning"
      ;;
  esac

  # 7. GPU and backend
  local gpu backend configured_backend
  gpu="$(tnx_detect_gpu)"
  configured_backend="$(tnx_state_get "backend")"
  backend="$(tnx_detect_backend)"
  tnx_ok "GPU: $gpu"
  tnx_ok "Recommended backend: $backend"
  if [ -n "$configured_backend" ]; then
    tnx_ok "Configured backend: $configured_backend"
    if [ "$configured_backend" != "$backend" ]; then
      tnx_warn "Configured backend ($configured_backend) differs from recommended ($backend)"
      issues+=("backend_mismatch")
      actions+=("Run: ternux backend detect")
      [ "$status" = "ok" ] && status="warning"
    fi
  else
    tnx_warn "No backend configured. Run: ternux backend detect"
    issues+=("backend_not_configured")
    actions+=("Run: ternux backend detect")
    [ "$status" = "ok" ] && status="warning"
  fi

  # 8. Mesa / renderer
  if tnx_has_cmd proot-distro; then
    local renderer
    renderer="$(tnx_detect_renderer)"
    if [ -n "$renderer" ] && [ "$renderer" != "unknown" ]; then
      tnx_ok "Renderer: $renderer"
      case "$renderer" in
        *llvmpipe*) 
          tnx_warn "Renderer is llvmpipe (software) — GPU acceleration not active"
          issues+=("software_rendering")
          actions+=("Reinstall GPU driver: ternux repair")
          [ "$status" = "ok" ] && status="warning"
          ;;
      esac
      tnx_state_set "renderer" "$renderer"
    else
      tnx_warn "Could not determine renderer (Debian container may not be running)"
      [ "$status" = "ok" ] && status="warning"
    fi
  fi

  # 9. Phantom process killer
  local phantom
  phantom="$(tnx_detect_phantom_killer)"
  case "$phantom" in
    enabled)
      tnx_warn "Android phantom process killer is ENABLED"
      tnx_warn "This can silently kill the desktop in the background"
      issues+=("phantom_process_killer_enabled")
      actions+=("Disable phantom process killer: see docs/TROUBLESHOOTING.md")
      [ "$status" = "ok" ] && status="warning"
      ;;
    disabled)
      tnx_ok "Phantom process killer is disabled"
      ;;
    *)
      tnx_info "Phantom process killer status: $phantom"
      ;;
  esac

  # 10. Launcher
  if [ -f "$HOME/x.sh" ]; then
    tnx_ok "Launcher ~/x.sh exists"
  else
    tnx_warn "Launcher ~/x.sh not found"
    issues+=("launcher_missing")
    actions+=("Run: ternux install (or ternux repair)")
    [ "$status" = "ok" ] && status="warning"
  fi

  # 11. VirGL (if relevant)
  local current_backend
  current_backend="$(tnx_state_get "backend")"
  if [ "$current_backend" = "virgl" ] || [ -z "$current_backend" ]; then
    if tnx_has_cmd virgl_test_server_android; then
      tnx_ok "VirGL host renderer present"
    else
      tnx_warn "VirGL host renderer not installed (recommended for virgl backend)"
      issues+=("virgl_missing")
      actions+=("Install VirGL renderer: pkg install virglrenderer-android -y")
      [ "$status" = "ok" ] && status="warning"
    fi
  fi

  echo ""

  # Summary
  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    tnx_json_init
    tnx_json_add "command" "doctor"
    tnx_json_add "status" "$status"
    tnx_json_add "timestamp" "$(__tnx_ts)"
    tnx_json_add "version" "$TERNUX_VERSION"
    tnx_json_add "android_version" "$(tnx_detect_android_version)"
    tnx_json_add "architecture" "$(tnx_detect_arch)"
    tnx_json_add "gpu" "$gpu"
    tnx_json_add "backend" "${configured_backend:-$(tnx_detect_backend)}"
    tnx_json_add "renderer" "$(tnx_detect_renderer)"
    tnx_json_add "vulkan" "$(tnx_detect_vulkan)"
    tnx_json_add_array "issues" "${issues[@]}"
    tnx_json_add_array "recommended_actions" "${actions[@]}"
    tnx_json_end
    return 0
  fi

  tnx_header "Diagnostic Summary"
  if [ ${#issues[@]} -eq 0 ]; then
    printf "  ${TNX_CG}✓ All checks passed${TNX_C0}\n"
    tnx_info "Your ternux installation looks healthy."
  else
    printf "  ${TNX_CY}Status: ${TNX_CW}${status}${TNX_C0}\n"
    printf "  ${TNX_CY}Issues found: ${#issues[@]}${TNX_C0}\n\n"
    for ((i=0; i<${#issues[@]}; i++)); do
      printf "  ${TNX_CR}✗${TNX_C0} ${TNX_CW}%s${TNX_C0}\n" "${issues[$i]}"
      printf "    → ${TNX_CD}%s${TNX_C0}\n" "${actions[$i]}"
    done
  fi
  echo ""
}

# ---------------------------------------------------------------------------
# Verify — check installation completeness
# ---------------------------------------------------------------------------
tnx_verify_run() {
  tnx_step "Verifying installation..."
  local rc=0
  local -a checks=()

  # Check critical binaries
  local bins="termux-x11 proot-distro pulseaudio"
  for b in $bins; do
    if tnx_has_cmd "$b"; then
      checks+=("${b}:installed")
      [ "${TERNUX_JSON:-0}" != "1" ] && tnx_ok "$b found"
    else
      checks+=("${b}:missing")
      [ "${TERNUX_JSON:-0}" != "1" ] && tnx_fail "$b missing"
      rc=1
    fi
  done

  # Check launcher
  if [ -x "$HOME/x.sh" ]; then
    checks+=("launcher:present")
    [ "${TERNUX_JSON:-0}" != "1" ] && tnx_ok "Launcher ~/x.sh is executable"
  else
    checks+=("launcher:missing")
    [ "${TERNUX_JSON:-0}" != "1" ] && tnx_fail "Launcher ~/x.sh missing or not executable"
    rc=1
  fi

  # Check Debian container
  if tnx_has_cmd proot-distro; then
    if proot-distro list 2>/dev/null | grep -q "debian.*installed"; then
      checks+=("debian:installed")
      [ "${TERNUX_JSON:-0}" != "1" ] && tnx_ok "Debian container installed"

      # Check Debian services
      if proot-distro login debian --user "${TERNUX_USER:-ternux}" -- bash -c '
        command -v startxfce4 >/dev/null && command -v pactl >/dev/null && sudo -n true >/dev/null
      ' >/dev/null 2>&1; then
        checks+=("debian_services:ok")
        [ "${TERNUX_JSON:-0}" != "1" ] && tnx_ok "Debian core services OK"
      else
        checks+=("debian_services:failed")
        [ "${TERNUX_JSON:-0}" != "1" ] && tnx_warn "Some Debian services not verified"
      fi
    else
      checks+=("debian:not_installed")
      [ "${TERNUX_JSON:-0}" != "1" ] && tnx_warn "Debian container not installed"
    fi
  fi

  # Check GPU backend
  if tnx_has_cmd proot-distro; then
    local backend
    backend="$(tnx_state_get "backend")"
    if [ "$backend" = "zink-turnip" ]; then
      if proot-distro login debian -- bash -c '
        test -f /usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so &&
        test -f /usr/share/vulkan/icd.d/freedreno_icd.aarch64.json
      ' >/dev/null 2>&1; then
        checks+=("turnip_driver:present")
        [ "${TERNUX_JSON:-0}" != "1" ] && tnx_ok "Turnip driver and ICD present"
      else
        checks+=("turnip_driver:missing")
        [ "${TERNUX_JSON:-0}" != "1" ] && tnx_warn "Turnip driver files missing"
      fi
    elif [ "$backend" = "virgl" ]; then
      if tnx_has_cmd virgl_test_server_android; then
        checks+=("virgl:present")
        [ "${TERNUX_JSON:-0}" != "1" ] && tnx_ok "VirGL host renderer present"
      fi
    fi
  fi

  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    local all_checks=""
    for c in "${checks[@]}"; do
      [ -n "$all_checks" ] && all_checks+=","
      all_checks+="$c"
    done
    tnx_json_object "verify" "$([ $rc -eq 0 ] && echo "passed" || echo "failed")" \
      "checks" "$all_checks" \
      "android_version" "$(tnx_detect_android_version)" \
      "gpu" "$(tnx_detect_gpu)"
    return 0
  fi

  echo ""
  if [ "$rc" -eq 0 ]; then
    tnx_ok "Verification passed — all checks OK."
  else
    tnx_warn "Verification found issues. Run 'ternux doctor' for details."
  fi
  return "$rc"
}