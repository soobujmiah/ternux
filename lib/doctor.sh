# =============================================================================
#  ternux — diagnostics (doctor) and verify commands
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah) — MIT License
#  https://github.com/soobujmiah/ternux
# =============================================================================

# shellcheck source=lib/core.sh
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"
# shellcheck source=lib/detect.sh
. "$(dirname "${BASH_SOURCE[0]}")/detect.sh"

# ---------------------------------------------------------------------------
# tnx_cmd_doctor — comprehensive diagnostics with structured JSON
# ---------------------------------------------------------------------------
tnx_cmd_doctor() {
  tnx_step "Running diagnostics..."
  tnx_require_termux

  local status="ok"
  local -a issues=() actions=()

  # 1. Termux
  tnx_is_termux && tnx_ok "Termux environment detected" || { tnx_fail "Not in Termux"; issues+=("not_in_termux"); actions+=("Install Termux from F-Droid"); status="error"; }

  # 2. Storage
  local storage
  storage="$(tnx_detect_storage_gb)"
  tnx_ok "Storage: ~${storage} GB free"
  if [ "$storage" != "?" ] && [ "$storage" -lt 2 ] 2>/dev/null; then
    issues+=("low_storage"); actions+=("Free up storage space"); [ "$status" = "ok" ] && status="warning"
  fi

  # 3. PRoot + Debian
  if tnx_has_cmd proot-distro; then
    tnx_ok "proot-distro installed"
    if tnx_debian_installed; then
      tnx_ok "Debian container installed"
    else
      issues+=("debian_not_installed"); actions+=("Run: ternux install"); [ "$status" = "ok" ] && status="warning"
    fi
  else
    issues+=("proot_distro_missing"); actions+=("pkg install proot-distro"); [ "$status" = "ok" ] && status="warning"
  fi

  # 4. Termux:X11
  tnx_has_cmd termux-x11 && tnx_ok "termux-x11 installed" || { issues+=("termux_x11_missing"); actions+=("pkg install termux-x11-nightly"); [ "$status" = "ok" ] && status="warning"; }

  # 5. PulseAudio
  tnx_has_cmd pulseaudio && tnx_ok "PulseAudio installed" || { issues+=("pulseaudio_missing"); actions+=("pkg install pulseaudio"); [ "$status" = "ok" ] && status="warning"; }

  # 6. Vulkan
  local vulkan
  vulkan="$(tnx_detect_vulkan)"
  case "$vulkan" in yes*|"yes (Adreno)") tnx_ok "Vulkan: $vulkan" ;; *)
    issues+=("vulkan_unavailable"); actions+=("Install Vulkan loader"); [ "$status" = "ok" ] && status="warning" ;;
  esac

  # 7. GPU + backend
  local gpu backend configured_backend
  gpu="$(tnx_detect_gpu)"
  configured_backend="$(tnx_canonical_backend "$(tnx_state_get "backend")")"
  backend="$(tnx_detect_backend)"
  tnx_ok "GPU: $gpu"
  tnx_ok "Recommended backend: $backend"
  if [ -n "$configured_backend" ]; then
    tnx_ok "Configured: $configured_backend"
    [ "$configured_backend" != "$backend" ] && { issues+=("backend_mismatch"); actions+=("If unintended: ternux backend set auto && ternux repair"); [ "$status" = "ok" ] && status="warning"; }
  else
    issues+=("backend_not_configured"); actions+=("Run: ternux backend set auto && ternux repair"); [ "$status" = "ok" ] && status="warning"
  fi

  # 8. Renderer
  local renderer=""
  if tnx_debian_installed; then
    renderer="$(tnx_detect_renderer)"
    if [ -n "$renderer" ] && [ "$renderer" != "unknown" ]; then
      tnx_ok "Renderer: $renderer"
      case "$renderer" in *llvmpipe*) issues+=("software_rendering"); actions+=("Reinstall GPU driver: ternux repair"); [ "$status" = "ok" ] && status="warning" ;; esac
      tnx_state_set "renderer" "$renderer"
    fi
  fi

  # 9. Phantom killer
  local phantom
  phantom="$(tnx_detect_phantom_killer)"
  case "$phantom" in
    enabled) tnx_warn "Android child-process monitoring appears ENABLED" ; issues+=("phantom_process_killer_enabled"); actions+=("Review Android process restrictions and other Signal 9 causes (see docs)"); [ "$status" = "ok" ] && status="warning" ;;
    disabled) tnx_ok "Android child-process monitoring appears disabled" ;;
  esac

  # 10. Launcher
  [ -f "$HOME/x.sh" ] && tnx_ok "Launcher exists" || { issues+=("launcher_missing"); actions+=("Run: ternux install"); [ "$status" = "ok" ] && status="warning"; }

  # 11. VirGL check
  local current_backend
  current_backend="$(tnx_canonical_backend "$(tnx_state_get "backend")")"
  if [ "$current_backend" = "virgl" ] || [ -z "$current_backend" ]; then
    tnx_has_cmd virgl_test_server_android && tnx_ok "VirGL present" || { tnx_warn "VirGL not installed"; issues+=("virgl_missing"); actions+=("pkg install virglrenderer-android"); [ "$status" = "ok" ] && status="warning"; }
  fi

  [ "${TERNUX_JSON:-0}" != "1" ] && echo ""

  # --- JSON output ---
  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    tnx_json_init
    tnx_json_add "command" "doctor"
    tnx_json_add "status" "$status"
    tnx_json_add "timestamp" "$(__tnx_ts)"
    tnx_json_add "version" "$TERNUX_VERSION"
    tnx_json_add "android_version" "$(tnx_detect_android_version)"
    tnx_json_add "architecture" "$(tnx_detect_arch)"
    tnx_json_add "gpu" "$gpu"
    tnx_json_add "backend" "${configured_backend:-$backend}"
    tnx_json_add "renderer" "${renderer:-unknown}"
    tnx_json_add "vulkan" "$vulkan"
    tnx_json_add_array "issues" "${issues[@]}"
    tnx_json_add_array "recommended_actions" "${actions[@]}"
    tnx_json_end
    return 0
  fi

  # --- Human output ---
  tnx_header "Diagnostic Summary"
  if [ ${#issues[@]} -eq 0 ]; then
    printf "  ${TNX_CG}✓ All checks passed${TNX_C0}\n"
    tnx_info "Your installation looks healthy."
  else
    printf "  ${TNX_CY}Status:${TNX_C0} ${TNX_CW}${status}${TNX_C0}\n"
    printf "  ${TNX_CY}Issues:${TNX_C0} ${#issues[@]}\n\n"
    for ((i=0; i<${#issues[@]}; i++)); do
      printf "  ${TNX_CR}✗${TNX_C0} ${TNX_CW}%s${TNX_C0}\n" "${issues[$i]}"
      printf "    → ${TNX_CD}%s${TNX_C0}\n" "${actions[$i]}"
    done
  fi
  echo ""
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
    if proot-distro login debian --user "${TERNUX_USER:-ternux}" -- bash -c 'command -v startxfce4 >/dev/null && command -v pactl >/dev/null && sudo -n true >/dev/null' 2>/dev/null; then
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
    if tnx_has_cmd proot-distro && proot-distro login debian -- bash -c 'test -f /usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so && test -f /usr/share/vulkan/icd.d/freedreno_icd.aarch64.json' 2>/dev/null; then
      checks+=("turnip:present"); [ "${TERNUX_JSON:-0}" != "1" ] && tnx_ok "Turnip driver present"
    else
      checks+=("turnip:missing"); rc=1
      [ "${TERNUX_JSON:-0}" != "1" ] && tnx_warn "Turnip files missing"
    fi
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