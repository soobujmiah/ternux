# =============================================================================
#  ternux — desktop lifecycle (start / stop / restart / status)
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah) — MIT License
#  https://github.com/soobujmiah/ternux
# =============================================================================

# shellcheck source=lib/core.sh
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"

# ---------------------------------------------------------------------------
# tnx_cmd_start
# ---------------------------------------------------------------------------
tnx_cmd_start() {
  if [ "${TERNUX_JSON:-0}" != "1" ]; then
    tnx_step "Starting ternux desktop..."
  fi

  if [ ! -f "$HOME/x.sh" ]; then
    tnx_fail "Launcher ~/x.sh not found. Run 'ternux install' first."
    [ "${TERNUX_JSON:-0}" = "1" ] && tnx_json_object "start" "error" "reason" "launcher_not_found"
    return 1
  fi

  chmod +x "$HOME/x.sh" 2>/dev/null || true

  # Check for existing session
  if pgrep -f "termux-x11" >/dev/null 2>&1; then
    if [ "${TERNUX_JSON:-0}" != "1" ]; then
      tnx_warn "Termux:X11 already running."
      if ! tnx_confirm "Start another session?"; then
        tnx_info "Cancelled."
        return 0
      fi
    fi
  fi

  tnx_info "Starting desktop (backend: $(tnx_state_get "backend" || echo "auto"))..."
  bash "$HOME/x.sh"
  local rc=$?

  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    tnx_json_object "start" "$([ $rc -eq 0 ] && echo "ok" || echo "error")" \
      "backend" "$(tnx_state_get "backend" || echo "auto")"
    return "$rc"
  fi
  [ "$rc" -eq 0 ] && tnx_ok "Desktop session ended." || tnx_warn "Desktop exited with code $rc"
  return "$rc"
}

# ---------------------------------------------------------------------------
# tnx_cmd_stop
# ---------------------------------------------------------------------------
tnx_cmd_stop() {
  if [ "${TERNUX_JSON:-0}" != "1" ]; then
    tnx_step "Stopping ternux desktop..."
  fi

  local found=0
  for svc in termux-x11 pulseaudio virgl_test_server dbus-daemon dbus-launch; do
    if pgrep -f "$svc" >/dev/null 2>&1; then
      pkill -9 -f "$svc" 2>/dev/null || true
      found=1
    fi
  done

  pulseaudio --kill 2>/dev/null || true

  local TMP="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
  rm -f "$TMP/.X11-unix/X"* "$TMP/.X"*"-lock" "$TMP/pulse-socket" 2>/dev/null || true
  tnx_has_cmd termux-wake-unlock && termux-wake-unlock 2>/dev/null || true

  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    tnx_json_object "stop" "ok" "cleaned" "$([ $found -eq 1 ] && echo "yes" || echo "no")"
    return 0
  fi
  [ "$found" -eq 1 ] && tnx_ok "Desktop stopped and sockets cleaned." || tnx_info "No active session found."
}

# ---------------------------------------------------------------------------
# tnx_cmd_restart
# ---------------------------------------------------------------------------
tnx_cmd_restart() {
  tnx_cmd_stop
  sleep 1
  tnx_cmd_start
}

# ---------------------------------------------------------------------------
# tnx_cmd_status (helper — used internally)
# ---------------------------------------------------------------------------
tnx_cmd_status() {
  local x11=0 pa=0 virgl=0
  pgrep -f "termux-x11" >/dev/null 2>&1 && x11=1
  pgrep -f "pulseaudio" >/dev/null 2>&1 && pa=1
  pgrep -f "virgl_test_server" >/dev/null 2>&1 && virgl=1

  local overall="stopped"
  [ "$x11" -eq 1 ] && overall="running"

  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    tnx_json_object "status" "$overall" \
      "x11_running" "$([ $x11 -eq 1 ] && echo "yes" || echo "no")" \
      "pulseaudio" "$([ $pa -eq 1 ] && echo "running" || echo "stopped")" \
      "virgl" "$([ $virgl -eq 1 ] && echo "running" || echo "stopped")" \
      "launcher" "$([ -f "$HOME/x.sh" ] && echo "present" || echo "missing")"
    return 0
  fi

  tnx_header "Desktop Status"
  printf "  ${TNX_CW}%-20s${TNX_C0} " "Overall:"
  [ "$overall" = "running" ] && printf "${TNX_CG}%s${TNX_C0}\n" "$overall" || printf "${TNX_CD}%s${TNX_C0}\n" "$overall"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Termux:X11:" "$([ $x11 -eq 1 ] && echo "running" || echo "stopped")"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "PulseAudio:" "$([ $pa -eq 1 ] && echo "running" || echo "stopped")"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "VirGL:" "$([ $virgl -eq 1 ] && echo "running" || echo "stopped")"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Launcher:" "$([ -f "$HOME/x.sh" ] && echo "present" || echo "missing")"
  echo ""
}