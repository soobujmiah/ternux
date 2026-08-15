# =============================================================================
#  ternux — desktop lifecycle library (start, stop, restart)
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah) — MIT License
#  https://github.com/soobujmiah/ternux
# =============================================================================

# shellcheck source=lib/core.sh
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"
# shellcheck source=lib/detect.sh
. "$(dirname "${BASH_SOURCE[0]}")/detect.sh"

# ---------------------------------------------------------------------------
# Desktop lifecycle
# ---------------------------------------------------------------------------

tnx_desktop_start() {
  if [ "${TERNUX_JSON:-0}" != "1" ]; then
    tnx_step "Starting ternux desktop..."
  fi

  # Check if launcher exists
  if [ ! -f "$HOME/x.sh" ]; then
    tnx_fail "Launcher ~/x.sh not found. Run 'ternux install' first."
    if [ "${TERNUX_JSON:-0}" = "1" ]; then
      tnx_json_object "start" "error" "reason" "launcher_not_found"
    fi
    return 1
  fi

  if [ ! -x "$HOME/x.sh" ]; then
    chmod +x "$HOME/x.sh"
  fi

  # Check for existing session
  if pgrep -f "termux-x11" >/dev/null 2>&1; then
    tnx_warn "Termux:X11 is already running."
    if [ "${TERNUX_JSON:-0}" = "1" ]; then
      tnx_json_object "start" "warning" "reason" "already_running"
    fi
    if ! tnx_confirm "Start a new session anyway?"; then
      tnx_info "Cancelled."
      return 0
    fi
  fi

  tnx_info "Starting desktop (GPU backend: $(tnx_state_get "backend" || tnx_detect_backend))..."
  tnx_info "Opening Termux:X11 display..."
  echo ""

  # Execute the launcher
  bash "$HOME/x.sh"
  local rc=$?

  if [ "$rc" -eq 0 ]; then
    if [ "${TERNUX_JSON:-0}" = "1" ]; then
      tnx_json_object "start" "ok" "backend" "$(tnx_state_get "backend" || tnx_detect_backend)"
    else
      tnx_ok "Desktop session ended."
    fi
  else
    if [ "${TERNUX_JSON:-0}" = "1" ]; then
      tnx_json_object "start" "error" "exit_code" "$rc" "backend" "$(tnx_state_get "backend" || tnx_detect_backend)"
    else
      tnx_warn "Desktop exited with code $rc"
    fi
  fi
  return "$rc"
}

tnx_desktop_stop() {
  if [ "${TERNUX_JSON:-0}" != "1" ]; then
    tnx_step "Stopping ternux desktop..."
  fi

  local found=0

  # Kill X11
  if pgrep -f "termux-x11" >/dev/null 2>&1; then
    pkill -9 -f "termux-x11" 2>/dev/null || true
    [ "${TERNUX_JSON:-0}" != "1" ] && tnx_ok "Termux:X11 stopped"
    found=1
  fi

  # Kill PulseAudio
  if pgrep -f "pulseaudio" >/dev/null 2>&1; then
    pulseaudio --kill 2>/dev/null || pkill -9 -f "pulseaudio" 2>/dev/null || true
    [ "${TERNUX_JSON:-0}" != "1" ] && tnx_ok "PulseAudio stopped"
    found=1
  fi

  # Kill VirGL
  if pgrep -f "virgl_test_server" >/dev/null 2>&1; then
    pkill -9 -f "virgl_test_server" 2>/dev/null || true
    [ "${TERNUX_JSON:-0}" != "1" ] && tnx_ok "VirGL server stopped"
    found=1
  fi

  # Kill dbus
  if pgrep -f "dbus-daemon" >/dev/null 2>&1; then
    pkill -9 -f "dbus-daemon" 2>/dev/null || true
    pkill -9 -f "dbus-launch" 2>/dev/null || true
    found=1
  fi

  # Clean up sockets
  local TMP="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
  rm -f "$TMP/.X11-unix/X"* "$TMP/.X"*"-lock" "$TMP/pulse-socket" 2>/dev/null || true

  # Wake unlock
  if tnx_has_cmd termux-wake-unlock; then
    termux-wake-unlock 2>/dev/null || true
  fi

  if [ "$found" -eq 1 ]; then
    if [ "${TERNUX_JSON:-0}" = "1" ]; then
      tnx_json_object "stop" "ok"
    else
      tnx_ok "Desktop session stopped and sockets cleaned."
    fi
  else
    if [ "${TERNUX_JSON:-0}" = "1" ]; then
      tnx_json_object "stop" "ok" "info" "no_active_session"
    else
      tnx_info "No active desktop session found."
    fi
  fi
}

tnx_desktop_restart() {
  tnx_desktop_stop
  sleep 1
  tnx_desktop_start
}

tnx_desktop_status() {
  local x11_running=0 pa_running=0 virgl_running=0

  pgrep -f "termux-x11" >/dev/null 2>&1 && x11_running=1
  pgrep -f "pulseaudio" >/dev/null 2>&1 && pa_running=1
  pgrep -f "virgl_test_server" >/dev/null 2>&1 && virgl_running=1

  local overall="stopped"
  [ "$x11_running" -eq 1 ] && overall="running"

  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    tnx_json_object "status" "$overall" \
      "x11_running" "$([ $x11_running -eq 1 ] && echo 'yes' || echo 'no')" \
      "pulseaudio_running" "$([ $pa_running -eq 1 ] && echo 'yes' || echo 'no')" \
      "virgl_running" "$([ $virgl_running -eq 1 ] && echo 'yes' || echo 'no')" \
      "launcher" "$([ -f "$HOME/x.sh" ] && echo 'present' || echo 'missing')" \
      "backend" "$(tnx_state_get "backend" || tnx_detect_backend)"
    return 0
  fi

  tnx_header "Desktop Status"
  printf "  ${TNX_CW}%-20s${TNX_C0} " "Overall:" 
  if [ "$overall" = "running" ]; then
    printf "${TNX_CG}${overall}${TNX_C0}\n"
  else
    printf "${TNX_CD}${overall}${TNX_C0}\n"
  fi
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Termux:X11:" "$([ $x11_running -eq 1 ] && echo 'running' || echo 'stopped')"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "PulseAudio:" "$([ $pa_running -eq 1 ] && echo 'running' || echo 'stopped')"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "VirGL server:" "$([ $virgl_running -eq 1 ] && echo 'running' || echo 'stopped')"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Launcher:" "$([ -f "$HOME/x.sh" ] && echo 'present' || echo 'missing')"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Backend:" "$(tnx_state_get "backend" || tnx_detect_backend)"
  echo ""
}