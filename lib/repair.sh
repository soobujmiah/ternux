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

# ---------------------------------------------------------------------------
# tnx_cmd_repair
# ---------------------------------------------------------------------------
tnx_cmd_repair() {
  tnx_step "Running repairs..."
  tnx_require_termux
  local rc=0
  local -a repairs_done=()

  # 1. curl/openssl
  tnx_header "1/6  curl/OpenSSL"
  _tnx_repair_curl && repairs_done+=("curl_fixed")

  # 2. Termux:X11
  tnx_header "2/6  Termux:X11"
  _tnx_repair_x11 && repairs_done+=("x11_fixed")

  # 3. Backend
  tnx_header "3/6  GPU backend"
  _tnx_repair_backend && repairs_done+=("backend_fixed")

  # 4. Launcher
  tnx_header "4/6  Launcher"
  _tnx_repair_launcher && repairs_done+=("launcher_fixed")

  # 5. Mesa cache
  tnx_header "5/6  Mesa cache"
  _tnx_repair_mesa_cache && repairs_done+=("cache_cleared")

  # 6. PulseAudio
  tnx_header "6/6  PulseAudio"
  _tnx_repair_pulseaudio && repairs_done+=("pulseaudio_fixed")

  echo ""

  # Log repairs
  mkdir -p "$TERNUX_STATE_DIR"
  for r in "${repairs_done[@]}"; do
    echo "$(__tnx_ts) $r" >> "$TERNUX_STATE_DIR/repairs"
  done

  [ "${TERNUX_JSON:-0}" = "1" ] && {
    tnx_json_object "repair" "$([ $rc -eq 0 ] && echo "ok" || echo "partial")" \
      "repairs_performed" "$(IFS=,; echo "${repairs_done[*]}")"
    return 0
  }

  tnx_header "Repair Summary"
  [ ${#repairs_done[@]} -eq 0 ] && tnx_ok "No repairs needed." || {
    tnx_ok "${#repairs_done[@]} repair(s) performed:"
    for r in "${repairs_done[@]}"; do printf "  ${TNX_CG}✓${TNX_C0}  ${TNX_CD}%s${TNX_C0}\n" "$r"; done
    echo ""
    tnx_info "Run 'ternux doctor' to verify fixes."
  }
  return "$rc"
}

_tnx_repair_curl() {
  tnx_has_cmd curl || { pkg install -y curl 2>/dev/null && tnx_ok "curl installed"; return 0; }
  curl --version >/dev/null 2>&1 && { tnx_ok "curl working"; return 0; }
  tnx_warn "curl broken — repairing..."
  pkg install -y curl openssl openssl-tool libngtcp2 libnghttp3 2>/dev/null
  if curl --version >/dev/null 2>&1; then tnx_ok "curl repaired"; return 0; fi
  tnx_warn "curl still broken; wget will be used as fallback"
  return 1
}

_tnx_repair_x11() {
  tnx_has_cmd termux-x11 && { tnx_ok "termux-x11 installed"; return 0; }
  tnx_warn "Installing termux-x11..."
  pkg install -y x11-repo 2>/dev/null || true
  pkg install -y termux-x11-nightly 2>/dev/null || pkg install -y termux-x11 2>/dev/null
  tnx_has_cmd termux-x11 && { tnx_ok "termux-x11 installed"; return 0; }
  tnx_fail "Could not install termux-x11"
  return 1
}

_tnx_repair_backend() {
  local current_backend detected_backend
  current_backend="$(tnx_state_get "backend")"
  detected_backend="$(tnx_detect_backend)"

  [ "$current_backend" = "$detected_backend" ] && [ -n "$current_backend" ] && { tnx_ok "Backend correct: $current_backend"; return 0; }
  tnx_warn "Updating backend to: $detected_backend"
  tnx_state_set "backend" "$detected_backend"
  tnx_ok "Backend updated to '$detected_backend'"
  return 0
}

_tnx_repair_launcher() {
  [ -f "$HOME/x.sh" ] && bash -n "$HOME/x.sh" 2>/dev/null && { tnx_ok "Launcher OK"; return 0; }
  tnx_warn "Launcher missing or broken — run 'ternux install' to regenerate"
  return 1
}

_tnx_repair_mesa_cache() {
  tnx_has_cmd proot-distro && proot-distro login debian --user "${TERNUX_USER:-ternux}" -- bash -c '
    if [ -d ~/.cache/mesa ] && [ "$(ls -A ~/.cache/mesa 2>/dev/null)" ]; then
      rm -rf ~/.cache/mesa/* 2>/dev/null && echo "CLEARED"
    fi
  ' 2>/dev/null | grep -q "CLEARED" && { tnx_ok "Mesa cache cleared"; return 0; }
  tnx_ok "No stale cache"
  return 0
}

_tnx_repair_pulseaudio() {
  local PA_CONF="${PREFIX:-/data/data/com.termux/files/usr}/etc/pulse/default.pa"
  [ ! -f "$PA_CONF" ] && { tnx_warn "PulseAudio config not found"; return 1; }
  grep -q "module-native-protocol-tcp" "$PA_CONF" 2>/dev/null && { tnx_ok "PulseAudio bridge configured"; return 0; }
  {
    echo ""
    echo "# ternux: audio bridge for PRoot container"
    echo "load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 port=4713"
    echo "load-module module-opensles-sink sink_name=Speaker"
    echo "set-default-sink Speaker"
  } >> "$PA_CONF"
  tnx_ok "PulseAudio TCP bridge added"
  return 0
}