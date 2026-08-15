# =============================================================================
#  ternux — repair library
#  Auto-fix common issues: broken curl/openssl, missing X11, stale Mesa cache,
#  incorrect backend, renderer fallback.
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah) — MIT License
#  https://github.com/soobujmiah/ternux
# =============================================================================

# shellcheck source=lib/core.sh
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"
# shellcheck source=lib/detect.sh
. "$(dirname "${BASH_SOURCE[0]}")/detect.sh"
# shellcheck source=lib/doctor.sh
. "$(dirname "${BASH_SOURCE[0]}")/doctor.sh"

# ---------------------------------------------------------------------------
# Repair — diagnose and fix common problems
# ---------------------------------------------------------------------------

tnx_repair_run() {
  tnx_step "Running repairs..."
  local rc=0
  local -a repairs_done=()

  tnx_info "Repair mode will automatically fix common issues."
  echo ""

  # --- 1. Check and repair curl/openssl ---
  tnx_header "1/6  Checking curl/OpenSSL"
  if tnx_has_cmd curl; then
    if curl --version >/dev/null 2>&1; then
      tnx_ok "curl is working"
    else
      tnx_warn "curl is installed but cannot link — repairing..."
      if pkg install -y curl openssl openssl-tool libngtcp2 libnghttp3 2>/dev/null; then
        if curl --version >/dev/null 2>&1; then
          tnx_ok "curl repaired"
          tnx_log_info "Repair: curl/openssl toolchain fixed"
          repairs_done+=("curl_openssl_fixed")
        else
          tnx_warn "curl still not working after repair"
        fi
      else
        tnx_warn "Could not repair curl; continuing with wget fallback"
      fi
    fi
  else
    tnx_warn "curl not installed — installing..."
    pkg install -y curl 2>/dev/null && tnx_ok "curl installed"
  fi

  # --- 2. Check and repair Termux X11 ---
  tnx_header "2/6  Checking Termux:X11"
  if tnx_has_cmd termux-x11; then
    tnx_ok "termux-x11 installed"
  else
    tnx_warn "termux-x11 missing — installing..."
    if pkg install -y x11-repo 2>/dev/null; then
      if pkg install -y termux-x11-nightly 2>/dev/null; then
        tnx_ok "termux-x11-nightly installed"
        repairs_done+=("termux_x11_installed")
      elif pkg install -y termux-x11 2>/dev/null; then
        tnx_ok "termux-x11 installed (stable)"
        repairs_done+=("termux_x11_installed")
      else
        tnx_fail "Could not install termux-x11"
        rc=1
      fi
    else
      tnx_fail "Could not install x11-repo"
      rc=1
    fi
  fi

  # --- 3. Check and fix GPU backend ---
  tnx_header "3/6  Checking GPU backend"
  local current_backend
  current_backend="$(tnx_state_get "backend")"
  local detected_backend
  detected_backend="$(tnx_detect_backend)"

  if [ -z "$current_backend" ] || [ "$current_backend" != "$detected_backend" ]; then
    tnx_warn "Backend mismatch or not configured (configured: ${current_backend:-none}, detected: $detected_backend)"
    if tnx_confirm "Update backend to '$detected_backend'?"; then
      tnx_state_set "backend" "$detected_backend"
      tnx_ok "Backend set to '$detected_backend'"
      repairs_done+=("backend_updated_to_${detected_backend}")
    fi
  else
    tnx_ok "Backend matches: $current_backend"
  fi

  # --- 4. Rebuild launcher (~/x.sh) ---
  tnx_header "4/6  Checking launcher"
  if [ -f "$HOME/x.sh" ]; then
    if bash -n "$HOME/x.sh" 2>/dev/null; then
      tnx_ok "Launcher syntax OK"
    else
      tnx_warn "Launcher has syntax errors — regenerating..."
      rm -f "$HOME/x.sh"
      repairs_done+=("launcher_regenerated")
    fi
  fi

  if [ ! -f "$HOME/x.sh" ]; then
    tnx_warn "Launcher missing — run 'ternux install' to generate it"
    repairs_done+=("launcher_missing")
    rc=1
  fi

  # --- 5. Clear stale Mesa cache ---
  tnx_header "5/6  Checking Mesa cache"
  if tnx_has_cmd proot-distro; then
    if proot-distro login debian --user "${TERNUX_USER:-ternux}" -- bash -c '
      if [ -d ~/.cache/mesa ] && [ "$(ls -A ~/.cache/mesa 2>/dev/null)" ]; then
        rm -rf ~/.cache/mesa/* 2>/dev/null
        echo "cleared"
      fi
    ' 2>/dev/null | grep -q "cleared"; then
      tnx_ok "Stale Mesa cache cleared"
      repairs_done+=("mesa_cache_cleared")
    else
      tnx_ok "No Mesa cache to clear"
    fi
  fi

  # --- 6. Restore PulseAudio config ---
  tnx_header "6/6  Checking PulseAudio configuration"
  local PA_CONF="${PREFIX:-/data/data/com.termux/files/usr}/etc/pulse/default.pa"
  if [ -f "$PA_CONF" ]; then
    if grep -q "module-native-protocol-tcp" "$PA_CONF" 2>/dev/null; then
      tnx_ok "PulseAudio TCP bridge configured"
    else
      tnx_warn "PulseAudio TCP bridge missing — adding..."
      {
        echo ""
        echo "# ternux: audio bridge for PRoot container"
        echo "load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 port=4713"
        echo "load-module module-opensles-sink sink_name=Speaker"
        echo "set-default-sink Speaker"
      } >> "$PA_CONF"
      tnx_ok "PulseAudio TCP bridge added"
      repairs_done+=("pulseaudio_tcp_bridge_added")
    fi
  else
    tnx_warn "PulseAudio config not found at $PA_CONF"
  fi

  echo ""

  # Log repairs
  if [ ${#repairs_done[@]} -gt 0 ]; then
    mkdir -p "$TERNUX_STATE_DIR"
    for r in "${repairs_done[@]}"; do
      echo "$(__tnx_ts) $r" >> "$TERNUX_STATE_DIR/repairs"
    done
  fi

  # Summary
  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    tnx_json_init
    tnx_json_add "command" "repair"
    tnx_json_add "status" "$([ $rc -eq 0 ] && echo "ok" || echo "partial")"
    tnx_json_add_array "repairs_performed" "${repairs_done[@]}"
    tnx_json_add "gpu" "$(tnx_detect_gpu)"
    tnx_json_add "backend" "$(tnx_state_get "backend" || tnx_detect_backend)"
    tnx_json_end
    return 0
  fi

  tnx_header "Repair Summary"
  if [ ${#repairs_done[@]} -eq 0 ]; then
    tnx_ok "No repairs needed — everything looks good."
  else
    tnx_ok "${#repairs_done[@]} repair(s) performed:"
    for r in "${repairs_done[@]}"; do
      printf "  ${TNX_CG}✓${TNX_C0}  ${TNX_CD}%s${TNX_C0}\n" "$r"
    done
    echo ""
    tnx_info "Run 'ternux doctor' to verify the fixes."
  fi

  return "$rc"
}