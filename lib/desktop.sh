# =============================================================================
#  ternux — desktop lifecycle (start / stop / restart / status)
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah)
#  Licensed under the Apache License, Version 2.0.
#  https://github.com/soobujmiah/ternux
# =============================================================================

# shellcheck source=lib/core.sh
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"

# Ternuxx was uninstalled, but its standalone PulseAudio daemon can outlive
# the app removal and keep an audio sink open. Match only that legacy config.
tnx_stop_legacy_ternuxx_audio() {
  local stale_pid pids=""
  pids="$(ps -A -o pid=,args= 2>/dev/null | awk '$2 ~ /pulseaudio$/ && /\/.local\/share\/ternuxx\/audio\/default\.pa/ {print $1}')"
  for stale_pid in $pids; do
    [ -n "$stale_pid" ] || continue
    kill -TERM "$stale_pid" 2>/dev/null || true
  done
}

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

  if ! grep -q '^# TERNUX_DESKTOP_LAUNCHER=10$' "$HOME/x.sh"; then
    # CLI package upgrades must refresh the generated launcher too. It carries
    # process matching, audio routing and session supervision behavior.
    if ! declare -F tnx_phase_launcher >/dev/null 2>&1; then
      . "$(dirname "${BASH_SOURCE[0]}")/phases.sh"
    fi
    local launcher_user launcher_locale launcher_backend
    launcher_user="$(tnx_state_get "user" || echo "ternux")"
    launcher_locale="$(tnx_state_get "locale" || echo "en_US.UTF-8")"
    launcher_backend="$(tnx_canonical_backend "$(tnx_state_get "backend" || echo "auto")")"
    launcher_user="${launcher_user:-ternux}"
    launcher_locale="${launcher_locale:-en_US.UTF-8}"
    launcher_backend="${launcher_backend:-auto}"
    tnx_info "Refreshing the generated desktop launcher..."
    tnx_phase_launcher "$launcher_user" "$launcher_backend" "$launcher_locale" || return 1
  fi
  chmod +x "$HOME/x.sh" 2>/dev/null || true

  # Termux:X11 expects key:value arguments (not key=value). Character-based
  # input lets Android IMEs deliver committed text to X11 clients that do not
  # receive corresponding hardware key events.
  if tnx_has_cmd termux-x11-preference; then
    if ! timeout 3 termux-x11-preference enforceCharBasedInput:true >/dev/null 2>&1; then
      tnx_warn "Could not enable Termux:X11 character-based keyboard input."
    fi
  fi

  local session_dir="$TERNUX_STATE_DIR/session" pid_file="$TERNUX_STATE_DIR/session/desktop.pid"
  mkdir -p "$session_dir" || { tnx_fail "Could not create desktop state directory."; return 1; }
  if [ -r "$pid_file" ]; then
    local old_pid
    old_pid="$(cat "$pid_file" 2>/dev/null || true)"
    if [[ "$old_pid" =~ ^[0-9]+$ ]] && kill -0 "$old_pid" 2>/dev/null; then
      tnx_info "Desktop is already running (PID $old_pid). Use 'ternux status' or 'ternux logs desktop tail'."
      [ "${TERNUX_JSON:-0}" = "1" ] && tnx_json_object "start" "already_running" "pid" "$old_pid"
      return 0
    fi
    rm -f "$pid_file"
  fi

  # Check for an unmanaged/legacy session before starting another display.
  # Android truncates the configured nice-name to this 15-character comm.
  if pgrep -f "^termux-x11 com\.termux\.x11([[:space:]]|$)" >/dev/null 2>&1; then
    if [ "${TERNUX_JSON:-0}" != "1" ]; then
      tnx_warn "Termux:X11 already running."
      if ! tnx_confirm "Start another session?"; then
        tnx_info "Cancelled."
        return 0
      fi
    fi
  fi

  local configured_backend
  configured_backend="$(tnx_canonical_backend "$(tnx_state_get "backend" || echo "auto")")"
  local desktop_log="$session_dir/desktop.log"
  if [ -f "$desktop_log" ] && [ "$(wc -c < "$desktop_log" 2>/dev/null || echo 0)" -ge 1048576 ]; then
    mv -f "$desktop_log" "$desktop_log.1" || { tnx_fail "Could not rotate desktop log."; return 1; }
  fi
  : >> "$desktop_log" || { tnx_fail "Could not write desktop log: $desktop_log"; return 1; }
  if ! tnx_has_cmd setsid; then
    tnx_fail "Session detachment tool 'setsid' is missing. Install it with 'pkg install util-linux' and retry."
    return 1
  fi
  tnx_info "Starting desktop in background (backend: $configured_backend)..."
  setsid env LD_LIBRARY_PATH= TNX_PID_FILE="$pid_file" nohup bash "$HOME/x.sh" >>"$desktop_log" 2>&1 </dev/null &
  local pid=$!
  printf '%s\n' "$pid" > "$pid_file" || { kill "$pid" 2>/dev/null || true; tnx_fail "Could not save desktop PID."; return 1; }
  local ready=0 i
  for ((i=0; i<100; i++)); do
    if [ -e "${TMPDIR:-/data/data/com.termux/files/usr/tmp}/.X11-unix/X0" ]; then ready=1; break; fi
    if ! kill -0 "$pid" 2>/dev/null; then break; fi
    sleep 0.1
  done
  if [ "$ready" -ne 1 ]; then
    local rc=1
    kill -TERM "$pid" 2>/dev/null || true
    local waited=0
    while kill -0 "$pid" 2>/dev/null && [ "$waited" -lt 20 ]; do sleep 0.1; waited=$((waited+1)); done
    kill -KILL "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || rc=$?
    rm -f "$pid_file"
    tnx_fail "Desktop did not reach display :0. See 'ternux logs show' for details."
    [ "${TERNUX_JSON:-0}" = "1" ] && tnx_json_object "start" "error" "backend" "$configured_backend" "log" "$desktop_log"
    return "$rc"
  fi

  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    tnx_json_object "start" "ok" "backend" "$configured_backend" "pid" "$pid" "log" "$desktop_log"
    return 0
  fi
  tnx_ok "Desktop is running in the background (PID $pid)."
  tnx_info "Startup output: ternux logs desktop tail"
  return 0
}

# ---------------------------------------------------------------------------
# tnx_cmd_stop
# ---------------------------------------------------------------------------
tnx_cmd_stop() {
  if [ "${TERNUX_JSON:-0}" != "1" ]; then
    tnx_step "Stopping ternux desktop..."
  fi

  local found=0 pid_file="$TERNUX_STATE_DIR/session/desktop.pid" managed_pid=""
  [ -r "$pid_file" ] && managed_pid="$(cat "$pid_file" 2>/dev/null || true)"
  tnx_stop_legacy_ternuxx_audio
  # Stop only the managed guest desktop session before closing the host X
  # server. Otherwise its PRoot process can survive uninstall/reinstall and
  # leave duplicate XFCE sessions attached to the next display.
  if tnx_has_cmd proot-distro; then
    # Stop IBus daemon and helpers with the desktop. The launcher runs its
    # private bus under dbus-run-session so the bus is reaped with XFCE.
    tnx_guest_login --user root -- sh -c '
      pkill -TERM -x ibus-daemon 2>/dev/null || true
      pkill -TERM -x ibus-ui-gtk3 2>/dev/null || true
      pkill -TERM -x ibus-extension-gtk3 2>/dev/null || true
      pkill -TERM -x ibus-memconf 2>/dev/null || true
      pkill -TERM -x ibus-x11 2>/dev/null || true
      pkill -TERM -x ibus-portal 2>/dev/null || true
      pkill -TERM -x ibus-engine-simple 2>/dev/null || true
      pkill -TERM -f "[/]usr/share/ibus-avro/main-gjs.js" 2>/dev/null || true
    ' >/dev/null 2>&1 || true
    if tnx_guest_login --user root -- pkill -TERM -x xfce4-session >/dev/null 2>&1; then
      found=1
    fi
  fi
  # Android truncates the configured nice-name to this 15-character comm.
  if pgrep -f "^termux-x11 com\.termux\.x11([[:space:]]|$)" >/dev/null 2>&1; then
    pkill -f "^termux-x11 com\.termux\.x11([[:space:]]|$)" 2>/dev/null || true
    found=1
  fi
  if pgrep -f '(^|/)virgl_test_server(_android)?([[:space:]]|$)' >/dev/null 2>&1; then
    pkill -f '(^|/)virgl_test_server(_android)?([[:space:]]|$)' 2>/dev/null || true
    found=1
  fi
  if pgrep -x pulseaudio >/dev/null 2>&1; then
    pulseaudio --kill 2>/dev/null || pkill -KILL -x pulseaudio 2>/dev/null || true
    found=1
  fi

  if [[ "$managed_pid" =~ ^[0-9]+$ ]] && kill -0 "$managed_pid" 2>/dev/null; then
    kill -TERM "$managed_pid" 2>/dev/null || true
    found=1
    local waited=0
    while kill -0 "$managed_pid" 2>/dev/null && [ "$waited" -lt 30 ]; do sleep 0.1; waited=$((waited+1)); done
    kill -KILL "$managed_pid" 2>/dev/null || true
  fi
  rm -f "$pid_file"

  # Do not kill every D-Bus daemon owned by the Termux app. Closing the display
  # lets the launcher's guest dbus-run-session unwind without disrupting other
  # independent Termux sessions.
  local TMP="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
  rm -f "$TMP/.X11-unix/X"* "$TMP/.X"*"-lock" \
    "$TMP/pulse-socket" "$TMP"/.pulse-*/native 2>/dev/null || true
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
  local x11=0 pa=0 virgl=0 desktop_pid=""
  [ -r "$TERNUX_STATE_DIR/session/desktop.pid" ] && desktop_pid="$(cat "$TERNUX_STATE_DIR/session/desktop.pid" 2>/dev/null || true)"
  [[ "$desktop_pid" =~ ^[0-9]+$ ]] && kill -0 "$desktop_pid" 2>/dev/null || desktop_pid=""
  pgrep -f "^termux-x11 com\.termux\.x11([[:space:]]|$)" >/dev/null 2>&1 && x11=1
  pgrep -x pulseaudio >/dev/null 2>&1 && pa=1
  pgrep -f '(^|/)virgl_test_server(_android)?([[:space:]]|$)' >/dev/null 2>&1 && virgl=1

  local overall="stopped"
  [ "$x11" -eq 1 ] && overall="running"

  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    tnx_json_object "status" "$overall" \
      "x11_running" "$([ $x11 -eq 1 ] && echo "yes" || echo "no")" \
      "pulseaudio" "$([ $pa -eq 1 ] && echo "running" || echo "stopped")" \
      "virgl" "$([ $virgl -eq 1 ] && echo "running" || echo "stopped")" \
      "launcher" "$([ -f "$HOME/x.sh" ] && echo "present" || echo "missing")" \
      "desktop_pid" "${desktop_pid:-none}"
    return 0
  fi

  tnx_header "Desktop Status"
  printf "  ${TNX_CW}%-20s${TNX_C0} " "Overall:"
  [ "$overall" = "running" ] && printf "${TNX_CG}%s${TNX_C0}\n" "$overall" || printf "${TNX_CD}%s${TNX_C0}\n" "$overall"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Termux:X11:" "$([ $x11 -eq 1 ] && echo "running" || echo "stopped")"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "PulseAudio:" "$([ $pa -eq 1 ] && echo "running" || echo "stopped")"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "VirGL:" "$([ $virgl -eq 1 ] && echo "running" || echo "stopped")"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Launcher:" "$([ -f "$HOME/x.sh" ] && echo "present" || echo "missing")"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Managed PID:" "${desktop_pid:-none}"
  echo ""
}