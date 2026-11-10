# =============================================================================
#  ternux — desktop lifecycle (start / stop / restart / status)
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah)
#  Licensed under the Apache License, Version 2.0.
#  https://github.com/soobujmiah/ternux
# =============================================================================

# shellcheck source=lib/core.sh
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"

# Linux /proc start time protects the managed PID from reuse after a crash.
tnx_process_start_identity() {
  local pid="${1:-}"
  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  [ -r "/proc/$pid/stat" ] || return 1
  awk '{ sub(/^.*\) /, ""); print $20 }' "/proc/$pid/stat" 2>/dev/null
}

tnx_process_is_live() { kill -0 "${1:-}" 2>/dev/null; }
tnx_process_group_id() { ps -o pgid= -p "${1:-}" 2>/dev/null | tr -d '[:space:]'; }
tnx_signal_process_group() { kill -"$1" -- "-$2" 2>/dev/null; }

# A valid PID file is not enough to prove the desktop is usable: Android may
# have killed/recreated the X11 app, and old PIDs can be reused. Check the
# actual guest session and shared X11 socket before accepting a start request.
tnx_x11_functional() {
  local user="${TERNUX_USER:-}"
  [ -n "$user" ] || user="$(tnx_state_get "user" 2>/dev/null || true)"
  user="${user:-ternux}"
  tnx_guest_login --_tnx-timeout-seconds 5 --shared-x11 --user "$user" -- \
    env DISPLAY=:0 xdpyinfo -display :0 >/dev/null 2>&1
}

tnx_pulseaudio_ready() {
  tnx_has_cmd pactl || return 1
  pgrep -x pulseaudio >/dev/null 2>&1 || return 1
  local modules line port
  modules="$(env -u PULSE_SERVER timeout 3 pactl list short modules 2>/dev/null)" || return 1
  while IFS= read -r line; do
    [[ "$line" == *module-native-protocol-tcp* && "$line" == *listen=127.0.0.1* ]] || continue
    port="$(printf '%s\n' "$line" | grep -oE 'port=[0-9]+' | head -n 1 | cut -d= -f2)"
    [[ "$port" =~ ^47(1[3-9]|2[0-2])$ ]] || continue
    if env PULSE_SERVER="tcp:127.0.0.1:$port" timeout 2 pactl info >/dev/null 2>&1; then
      return 0
    fi
  done <<< "$modules"
  return 1
}

# A socket and live processes can outlast an unusable X server. Confirm that
# the guest can complete an X11 query before reusing or reporting the session.
tnx_desktop_session_live() {
  local tmp="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
  [ -S "$tmp/.X11-unix/X0" ] || return 1
  pgrep -f "^termux-x11 com\.termux\.x11([[:space:]]|$)" >/dev/null 2>&1 || return 1
  pgrep -x xfce4-session >/dev/null 2>&1 || return 1
  pgrep -x xfwm4 >/dev/null 2>&1 || return 1
  pgrep -x xfdesktop >/dev/null 2>&1 || return 1
  tnx_x11_functional
}

# The generated launcher writes its READY marker after XFCE startup, but the
# host also verifies the real guest processes and a bounded X11 round-trip
# before reporting success. A short retry absorbs startup races without
# repeatedly probing every 100 ms during the long launcher wait.
tnx_wait_for_desktop_ready() {
  local attempt
  for ((attempt=0; attempt<3; attempt++)); do
    tnx_desktop_session_live && return 0
    [ "$attempt" -eq 2 ] || sleep 1
  done
  return 1
}

# The X server runs as a background service, but Android only displays its
# desktop when Termux:X11's activity is in the foreground.
tnx_show_x11_activity() {
  command -v am >/dev/null 2>&1 || return 0
  am start -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1 || true
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

  if ! grep -q '^# TERNUX_DESKTOP_LAUNCHER=20$' "$HOME/x.sh"; then
    # CLI package upgrades must refresh the generated launcher too. It carries
    # process matching, audio routing and narrowed guest bind behavior.
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

  local session_dir="$TERNUX_STATE_DIR/session" pid_file="$TERNUX_STATE_DIR/session/desktop.pid" ready_file="$TERNUX_STATE_DIR/session/desktop.pid.ready"
  local state_file="$TERNUX_STATE_DIR/session/desktop.state"
  mkdir -p "$session_dir" || { tnx_fail "Could not create desktop state directory."; return 1; }
  if ! tnx_has_cmd flock; then
    tnx_fail "Desktop lifecycle lock is unavailable. Install util-linux and retry."
    return 1
  fi
  exec 9>"$session_dir/start.lock" || { tnx_fail "Could not open the desktop startup lock."; return 1; }
  if ! flock -n 9; then
    tnx_info "Desktop startup is already in progress. Check 'ternux status' or 'ternux logs desktop tail'."
    [ "${TERNUX_JSON:-0}" = "1" ] && tnx_json_object "start" "starting" "log" "$session_dir/desktop.log"
    exec 9>&-
    return 0
  fi
  if [ -r "$pid_file" ]; then
    local old_pid old_identity_pid old_start old_pgid
    old_pid="$(cat "$pid_file" 2>/dev/null || true)"
    old_identity_pid=""; old_start=""; old_pgid=""
    [ -r "$pid_file.identity" ] && read -r old_identity_pid old_start old_pgid < "$pid_file.identity" || true
    if [[ "$old_pid" =~ ^[0-9]+$ ]] && [ "$old_identity_pid" = "$old_pid" ] && [ "$old_pgid" = "$old_pid" ] &&
       [ -n "$old_start" ] && tnx_process_is_live "$old_pid" &&
       [ "$(tnx_process_start_identity "$old_pid" 2>/dev/null || true)" = "$old_start" ] &&
       grep -q '^READY$' "$ready_file" 2>/dev/null && tnx_desktop_session_live; then
      printf '%s\n' READY > "$session_dir/desktop.state"
      tnx_show_x11_activity
      tnx_info "Desktop is already running (PID $old_pid). Use 'ternux status' or 'ternux logs desktop tail'."
      [ "${TERNUX_JSON:-0}" = "1" ] && tnx_json_object "start" "already_running" "pid" "$old_pid"
      exec 9>&-
      return 0
    fi
  fi

  # Recover cleanly when the supervisor marker was lost but the actual desktop
  # survived. Do not run another launcher: it would tear down the live X server.
  if tnx_desktop_session_live; then
    local active_pid="$(cat "$pid_file" 2>/dev/null || true)"
    printf '%s\n' READY > "$state_file"
    tnx_show_x11_activity
    tnx_info "Desktop is already active${active_pid:+ (PID $active_pid)}. Use 'ternux status' or 'ternux logs desktop tail'."
    [ "${TERNUX_JSON:-0}" = "1" ] && tnx_json_object "start" "already_running" "pid" "${active_pid:-unknown}"
    exec 9>&-
    return 0
  fi
  rm -f "$pid_file" "$ready_file"

  # Check for an unmanaged/legacy session before starting another display.
  # Android truncates the configured nice-name to this 15-character comm.
  if pgrep -f "^termux-x11 com\.termux\.x11([[:space:]]|$)" >/dev/null 2>&1; then
    if [ "${TERNUX_JSON:-0}" = "1" ]; then
      tnx_fail "Termux:X11 is active but the guest X11 readiness probe failed; refusing to start a duplicate desktop."
      tnx_json_object "start" "error" "reason" "unresponsive_existing_x11"
      exec 9>&-
      return 1
    fi
    tnx_warn "Termux:X11 is already active, but the managed desktop did not pass its readiness checks."
    if ! tnx_confirm "Start another session anyway?"; then
      tnx_info "Cancelled."
      return 0
    fi
  fi

  local configured_backend
  configured_backend="$(tnx_canonical_backend "$(tnx_state_get "backend" || echo "auto")")"
  local desktop_log="$session_dir/desktop.log"
  if [ -f "$desktop_log" ] && [ "$(wc -c < "$desktop_log" 2>/dev/null || echo 0)" -ge 1048576 ]; then
    mv -f "$desktop_log" "$desktop_log.1" || { tnx_fail "Could not rotate desktop log."; return 1; }
  fi
  : >> "$desktop_log" || { tnx_fail "Could not write desktop log: $desktop_log"; return 1; }
  rm -f "$ready_file"
  if ! tnx_has_cmd setsid; then
    tnx_fail "Session detachment tool 'setsid' is missing. Install it with 'pkg install util-linux' and retry."
    return 1
  fi
  printf '%s\n' STARTING > "$state_file" || { tnx_fail "Could not record desktop startup state."; exec 9>&-; return 1; }
  tnx_info "Starting desktop in background (backend: $configured_backend)..."
  setsid env LD_LIBRARY_PATH= TNX_PID_FILE="$pid_file" nohup bash "$HOME/x.sh" >>"$desktop_log" 2>&1 </dev/null 9>&- &
  local spawn_pid=$! pid="$!"
  local ready=0 i pid_wait=0
  tnx_info "Waiting for the XFCE desktop to finish starting..."
  for ((i=0; i<1200; i++)); do
    local recorded_pid
    recorded_pid="$(cat "$pid_file" 2>/dev/null || true)"
    [[ "$recorded_pid" =~ ^[0-9]+$ ]] && pid="$recorded_pid"
    local identity_pid="" identity_start="" identity_pgid="" current_identity=""
    if [ -r "$pid_file.identity" ]; then read -r identity_pid identity_start identity_pgid < "$pid_file.identity" || true; fi
    if [[ "$pid" =~ ^[0-9]+$ ]] && [ "$identity_pid" = "$pid" ] && [ "$identity_pgid" = "$pid" ] &&
       [ -n "$identity_start" ]; then current_identity="$(tnx_process_start_identity "$pid" 2>/dev/null || true)"; fi
    if [ -e "${TMPDIR:-/data/data/com.termux/files/usr/tmp}/.X11-unix/X0" ] &&
       [ "$current_identity" = "$identity_start" ] && tnx_process_is_live "$pid" && grep -q '^READY$' "$ready_file" 2>/dev/null; then ready=1; break; fi
    if ! tnx_process_is_live "$pid"; then
      if [[ ! "$recorded_pid" =~ ^[0-9]+$ ]] && [ "$pid_wait" -lt 50 ]; then pid_wait=$((pid_wait+1)); sleep 0.1; continue; fi
      break
    fi
    sleep 0.1
  done
  if [ "$ready" -eq 1 ] && ! tnx_wait_for_desktop_ready; then
    tnx_warn "The launcher signaled ready, but XFCE processes or the bounded X11 query did not pass."
    ready=0
  fi
  if [ "$ready" -ne 1 ]; then
    local rc=1 failed_identity_pid="" failed_start="" failed_pgid="" failed_current=""
    if [ -r "$pid_file.identity" ]; then read -r failed_identity_pid failed_start failed_pgid < "$pid_file.identity" || true; fi
    if [ "$failed_identity_pid" = "$pid" ] && [ "$failed_pgid" = "$pid" ] && [ -n "$failed_start" ]; then
      failed_current="$(tnx_process_start_identity "$pid" 2>/dev/null || true)"
      if [ "$failed_current" = "$failed_start" ] && tnx_process_is_live "$pid"; then tnx_signal_process_group TERM "$failed_pgid" || true; fi
    elif tnx_process_is_live "$spawn_pid"; then
      kill -TERM "$spawn_pid" 2>/dev/null || true
    fi
    local waited=0
    while tnx_process_is_live "$pid" && [ "$waited" -lt 50 ]; do sleep 0.1; waited=$((waited+1)); done
    failed_current="$(tnx_process_start_identity "$pid" 2>/dev/null || true)"
    if [ "$failed_current" = "$failed_start" ] && tnx_process_is_live "$pid"; then tnx_signal_process_group KILL "$failed_pgid" || true; fi
    wait "$spawn_pid" 2>/dev/null || rc=$?
    rm -f "$pid_file" "$pid_file.identity"
    printf '%s\n' FAILED > "$state_file"
    exec 9>&-
    tnx_fail "Desktop did not complete XFCE startup. See 'ternux logs show' for details."
    [ "${TERNUX_JSON:-0}" = "1" ] && tnx_json_object "start" "error" "backend" "$configured_backend" "log" "$desktop_log"
    return "$rc"
  fi

  local audio_route="unavailable"
  if tnx_pulseaudio_ready; then
    audio_route="ready"
  else
    tnx_warn "XFCE is ready, but the Termux PulseAudio route did not answer. Desktop is running; check 'ternux status'."
  fi
  printf '%s\n' READY > "$state_file"
  exec 9>&-
  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    tnx_show_x11_activity
    tnx_json_object "start" "ok" "backend" "$configured_backend" "pid" "$pid" "audio_route" "$audio_route" "log" "$desktop_log"
    return 0
  fi
  tnx_show_x11_activity
  tnx_ok "Desktop is running in the background (PID $pid)."
  [ "$audio_route" = "ready" ] && tnx_info "Desktop audio route is ready." || true
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

  local session_dir="$TERNUX_STATE_DIR/session" pid_file="$TERNUX_STATE_DIR/session/desktop.pid"
  local identity_file="${pid_file}.identity" managed_pid="" recorded_pid="" start_id="" pgid=""
  local found=0 waited=0 actual_start=""
  mkdir -p "$session_dir" || { tnx_fail "Could not access desktop state directory."; return 1; }
  exec 8>"$session_dir/start.lock" || { tnx_fail "Could not open the desktop lifecycle lock."; return 1; }
  if ! flock -n 8; then
    if [ "${TERNUX_JSON:-0}" = "1" ]; then
      tnx_json_object "stop" "error" "reason" "desktop_start_in_progress"
    else
      tnx_warn "Desktop is still starting; stop was not sent. Check 'ternux status' or 'ternux logs desktop tail'."
    fi
    exec 8>&-
    return 1
  fi
  if [ -r "$identity_file" ]; then
    read -r recorded_pid start_id pgid < "$identity_file" || true
  fi
  if [ -e "$pid_file" ] || [ -e "$identity_file" ]; then printf '%s\n' STOPPING > "$session_dir/desktop.state"; fi
  if [[ "$recorded_pid" =~ ^[0-9]+$ ]] && [ "$recorded_pid" = "$(cat "$pid_file" 2>/dev/null || true)" ] &&
     [[ "$pgid" =~ ^[0-9]+$ ]] && [ "$pgid" = "$recorded_pid" ] && [ -n "$start_id" ]; then
    actual_start="$(tnx_process_start_identity "$recorded_pid" 2>/dev/null || true)"
    if [ -n "$actual_start" ] && [ "$actual_start" = "$start_id" ] && tnx_process_is_live "$recorded_pid"; then
      managed_pid="$recorded_pid"
      tnx_signal_process_group TERM "$pgid" || true
      found=1
      while [ "$waited" -lt 30 ] && tnx_process_is_live "$managed_pid"; do
        actual_start="$(tnx_process_start_identity "$managed_pid" 2>/dev/null || true)"
        [ "$actual_start" = "$start_id" ] || break
        sleep 0.1
        waited=$((waited+1))
      done
      actual_start="$(tnx_process_start_identity "$managed_pid" 2>/dev/null || true)"
      if [ "$actual_start" = "$start_id" ] && tnx_process_is_live "$managed_pid"; then
        tnx_signal_process_group KILL "$pgid" || true
      fi
    fi
  elif [[ "$(cat "$pid_file" 2>/dev/null || true)" =~ ^[0-9]+$ ]]; then
    # Pre-identity launchers have a global cleanup trap. Verify their PID,
    # process group, command path, and inherited state path, then SIGKILL only
    # that session group so the obsolete trap cannot kill shared Termux services.
    local legacy_pid legacy_pgid legacy_start legacy_cmdline legacy_state
    legacy_pid="$(cat "$pid_file" 2>/dev/null || true)"
    legacy_pgid="$(tnx_process_group_id "$legacy_pid")"
    legacy_start="$(tnx_process_start_identity "$legacy_pid" 2>/dev/null || true)"
    legacy_cmdline="$(tr '\0' ' ' < "/proc/$legacy_pid/cmdline" 2>/dev/null || true)"
    legacy_state="$(tr '\0' '\n' < "/proc/$legacy_pid/environ" 2>/dev/null | grep -F -x "TNX_PID_FILE=$pid_file" || true)"
    if [ "$legacy_pgid" = "$legacy_pid" ] && [ -n "$legacy_start" ] &&
       [[ "$legacy_cmdline" == *"$HOME/x.sh"* ]] && [ -n "$legacy_state" ] &&
       [ "$(tnx_process_start_identity "$legacy_pid" 2>/dev/null || true)" = "$legacy_start" ] &&
       tnx_process_is_live "$legacy_pid"; then
      tnx_signal_process_group KILL "$legacy_pgid" || true
      found=1
    fi
  fi

  # Remove only Ternux's own session markers. X11/Pulse sockets and daemons may
  # be shared with other Termux sessions; their owners clean them up themselves.
  rm -f "$pid_file" "${pid_file}.ready" "$identity_file"
  if [ "$found" -eq 1 ] || [ "$(cat "$session_dir/desktop.state" 2>/dev/null || true)" = STOPPING ]; then
    printf '%s\n' STOPPED > "$session_dir/desktop.state"
  fi
  exec 8>&-

  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    tnx_json_object "stop" "ok" "cleaned" "$([ "$found" -eq 1 ] && echo yes || echo no)"
    return 0
  fi
  [ "$found" -eq 1 ] && tnx_ok "Managed desktop session stopped." || tnx_info "No active managed session found."
}

# ---------------------------------------------------------------------------
# tnx_cmd_restart
# ---------------------------------------------------------------------------
tnx_cmd_restart() {
  tnx_cmd_stop || {
    tnx_warn "Restart aborted because the existing desktop could not be stopped safely."
    return 1
  }
  sleep 1
  tnx_cmd_start
}

# ---------------------------------------------------------------------------
# tnx_cmd_status (helper — used internally)
# ---------------------------------------------------------------------------
tnx_cmd_status() {
  local x11=0 pa=0 pa_ready=0 virgl=0 desktop_pid="" lifecycle="STOPPED"
  local identity_pid="" identity_start="" identity_pgid="" observed_start="" session_ready=0
  [ -r "$TERNUX_STATE_DIR/session/desktop.pid" ] && desktop_pid="$(cat "$TERNUX_STATE_DIR/session/desktop.pid" 2>/dev/null || true)"
  if [ -r "$TERNUX_STATE_DIR/session/desktop.pid.identity" ]; then
    read -r identity_pid identity_start identity_pgid < "$TERNUX_STATE_DIR/session/desktop.pid.identity" || true
  fi
  if [[ "$desktop_pid" =~ ^[0-9]+$ ]] && [ "$desktop_pid" = "$identity_pid" ] &&
     [ "$identity_pgid" = "$identity_pid" ] && [ -n "$identity_start" ]; then
    observed_start="$(tnx_process_start_identity "$desktop_pid" 2>/dev/null || true)"
  fi
  if ! [[ "$desktop_pid" =~ ^[0-9]+$ ]] || [ -z "$observed_start" ] || [ "$observed_start" != "$identity_start" ] ||
     ! tnx_process_is_live "$desktop_pid" || ! grep -q '^READY$' "$TERNUX_STATE_DIR/session/desktop.pid.ready" 2>/dev/null; then desktop_pid=""; fi
  pgrep -f "^termux-x11 com\.termux\.x11([[:space:]]|$)" >/dev/null 2>&1 && x11=1
  if tnx_desktop_session_live; then
    session_ready=1
    desktop_pid="${desktop_pid:-active}"
  fi
  lifecycle="$(cat "$TERNUX_STATE_DIR/session/desktop.state" 2>/dev/null || echo STOPPED)"
  case "$lifecycle" in STARTING|READY|STOPPING|FAILED|RECOVERING|STOPPED) ;; *) lifecycle=FAILED ;; esac
  if [ "$session_ready" -eq 1 ]; then
    if [ "$lifecycle" != READY ]; then lifecycle=RECOVERING; fi
  elif [ "$lifecycle" = READY ]; then lifecycle=FAILED
  elif [ "$lifecycle" = STARTING ] && { [ -z "$desktop_pid" ] || ! kill -0 "$desktop_pid" 2>/dev/null; }; then lifecycle=FAILED
  elif [ "$x11" -eq 1 ] && [ "$lifecycle" = STOPPED ]; then lifecycle=RECOVERING
  fi
  pgrep -x pulseaudio >/dev/null 2>&1 && pa=1
  tnx_pulseaudio_ready && pa_ready=1
  pgrep -f '(^|/)virgl_test_server(_android)?([[:space:]]|$)' >/dev/null 2>&1 && virgl=1

  local overall="stopped"
  [ "$session_ready" -eq 1 ] && overall="running"

  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    tnx_json_object "status" "$overall" \
      "lifecycle" "$lifecycle" \
      "x11_running" "$([ $x11 -eq 1 ] && echo "yes" || echo "no")" \
      "pulseaudio" "$([ $pa -eq 1 ] && echo "running" || echo "stopped")" \
      "pulseaudio_ready" "$([ $pa_ready -eq 1 ] && echo "yes" || echo "no")" \
      "virgl" "$([ $virgl -eq 1 ] && echo "running" || echo "stopped")" \
      "launcher" "$([ -f "$HOME/x.sh" ] && echo "present" || echo "missing")" \
      "desktop_pid" "${desktop_pid:-none}"
    return 0
  fi

  tnx_header "Desktop Status"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Lifecycle:" "$lifecycle"
  printf "  ${TNX_CW}%-20s${TNX_C0} " "Overall:"
  [ "$overall" = "running" ] && printf "${TNX_CG}%s${TNX_C0}\n" "$overall" || printf "${TNX_CD}%s${TNX_C0}\n" "$overall"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Termux:X11:" "$([ $x11 -eq 1 ] && echo "running" || echo "stopped")"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "PulseAudio:" "$([ $pa -eq 1 ] && echo "running" || echo "stopped")"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Desktop audio route:" "$([ $pa_ready -eq 1 ] && echo "ready" || echo "unavailable")"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "VirGL:" "$([ $virgl -eq 1 ] && echo "running" || echo "stopped")"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Launcher:" "$([ -f "$HOME/x.sh" ] && echo "present" || echo "missing")"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Managed PID:" "${desktop_pid:-none}"
  echo ""
}
