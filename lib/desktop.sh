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
  [ -n "$user" ] || user="$(tnx_distro_state_get "$(tnx_distro)" user 2>/dev/null || tnx_state_get "user" 2>/dev/null || true)"
  user="${user:-ternux}"
  local display="${TERNUX_DISPLAY:-:$(tnx_distro_display)}"
  tnx_guest_login --_tnx-timeout-seconds 5 --shared-x11 --user "$user" -- \
    env DISPLAY="$display" xdpyinfo -display "$display" >/dev/null 2>&1
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
  local display display_num
  display="${TERNUX_DISPLAY:-:$(tnx_distro_display)}"
  display_num="${display#:}"
  [ -S "$tmp/.X11-unix/X$display_num" ] || return 1
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
  local tag="${1:-}" distro="$(tnx_distro)" mode_file=""
  mode_file="$(tnx_distro_session_dir "$distro")/x11-display-mode"
  command -v am >/dev/null 2>&1 || return 0
  if [ -n "$tag" ] && [ "$(cat "$mode_file" 2>/dev/null || true)" != shared ]; then
    am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity -d "$tag" >/dev/null 2>&1 || true
  else
    am start -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1 || true
    if [ "$(cat "$mode_file" 2>/dev/null || true)" = shared ] &&
       declare -F _tnx_running_guest_sessions >/dev/null 2>&1; then
      local -a active_sessions=()
      mapfile -t active_sessions < <(_tnx_running_guest_sessions)
      if [ "${#active_sessions[@]}" -gt 1 ]; then
        tnx_warn "Multiple desktops are using one shared Termux:X11 window; this app cannot switch the visible guest. Install the Termux:X11 nightly app, then restart each desktop to enable per-guest windows."
      fi
    fi
  fi
}

# Find live managed desktop sessions by their independent state, PID identity and X socket.
_tnx_running_guest_sessions() {
  local distro session pid identity_pid identity_start identity_pgid current_start recorded_distro
  for distro in $TERNUX_DISTRO_KNOWN; do
    session="$(tnx_distro_session_dir "$distro")"
    # The supervisor identity is authoritative for ownership. Older Ternux
    # launchers may not have a READY marker or a live X socket after Android
    # reclaimed Termux:X11; they still need to be stoppable safely.
    pid="$(cat "$session/desktop.pid" 2>/dev/null || true)"
    identity_pid=""; identity_start=""; identity_pgid=""; current_start=""
    [ -r "$session/desktop.pid.identity" ] && read -r identity_pid identity_start identity_pgid < "$session/desktop.pid.identity" || true
    [[ "$pid" =~ ^[0-9]+$ && "$pid" = "$identity_pid" && "$identity_pgid" = "$pid" ]] || continue
    current_start="$(tnx_process_start_identity "$pid" 2>/dev/null || true)"
    [ -n "$identity_start" ] && [ "$current_start" = "$identity_start" ] && tnx_process_is_live "$pid" || continue
    recorded_distro="$(cat "$session/distro" 2>/dev/null || true)"
    [ -z "$recorded_distro" ] || [ "$recorded_distro" = "$distro" ] || continue
    printf '%s\n' "$distro"
  done
}

# If several independent displays run, accept one or many indexes/names.
_tnx_stop_select() {
  local force_all="${1:-}" input token selected_name canonical_name rc=0 i duplicate existing
  local -a running=() selected=()
  while IFS= read -r selected_name; do [ -n "$selected_name" ] && running+=("$selected_name"); done < <(_tnx_running_guest_sessions)
  if [ "${#running[@]}" -eq 0 ]; then tnx_info "No active managed desktop sessions found."; return 0; fi
  if [ "$force_all" = all ]; then
    selected=("${running[@]}")
  else
    printf 'Running Ternux desktops (separate X11 displays):\n'
    for i in "${!running[@]}"; do
      case "${running[$i]}" in
        debian) token=db ;; ubuntu) token=ub ;; alpine) token=alp ;;
        archlinux) token=archx ;; fedora) token=fed ;; opensuse) token=suse ;;
        void) token=vsh ;; kali) token=kal ;; *) token="${running[$i]}" ;;
      esac
      printf '  %d) %-10s (%s)  Display :%s\n' "$((i+1))" "${running[$i]}" "$token" "$(tnx_distro_display "${running[$i]}")"
    done
    printf 'Select one or more numbers/names (comma or space separated), all, or 0 to cancel: '
    IFS= read -r input || input=0
    input="${input//,/ }"
    [ -n "${input//[[:space:]]/}" ] || input=0
    [ "$input" != 0 ] || { tnx_info "Cancelled."; return 0; }
    if [ "$input" = all ]; then selected=("${running[@]}"); else
      for token in $input; do
        selected_name=""
        if [[ "$token" =~ ^[0-9]+$ ]] && [ "$token" -ge 1 ] && [ "$token" -le "${#running[@]}" ]; then
          selected_name="${running[$((token-1))]}"
        else
          canonical_name="$(tnx_distro_canonical "$token")"
          for existing in "${running[@]}"; do [ "$existing" = "$token" ] && selected_name="$existing"; done
          for existing in "${running[@]}"; do [ "$existing" = "$canonical_name" ] && selected_name="$existing"; done
        fi
        [ -n "$selected_name" ] || { tnx_warn "Unknown selection '$token'; no desktops were stopped."; return 2; }
        duplicate=0
        for existing in "${selected[@]}"; do [ "$existing" != "$selected_name" ] || duplicate=1; done
        [ "$duplicate" -eq 1 ] || selected+=("$selected_name")
      done
    fi
  fi
  [ "${#selected[@]}" -gt 0 ] || { tnx_info "No sessions selected."; return 0; }
  for selected_name in "${selected[@]}"; do tnx_cmd_stop "$selected_name" || rc=1; done
  return "$rc"
}

# Remove only a provably stale display socket left behind after the X11
# server died. Unknown/unowned sockets and any live server are left untouched.
tnx_remove_stale_x11_socket() {
  local display_num="${1:-}" tmpdir="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
  local socket lock server_pid
  [[ "$display_num" =~ ^[0-9]{1,2}$ ]] || return 1
  socket="$tmpdir/.X11-unix/X$display_num"
  lock="$tmpdir/.X$display_num-lock"
  [ -S "$socket" ] && [ ! -L "$socket" ] && [ -f "$lock" ] && [ ! -L "$lock" ] || return 1
  IFS= read -r server_pid < "$lock" || return 1
  server_pid="${server_pid//[[:space:]]/}"
  [[ "$server_pid" =~ ^[0-9]+$ ]] || return 1
  kill -0 "$server_pid" 2>/dev/null && return 1
  # Other Ternux guests may have their own live X server. Only preserve the
  # socket when its matching display server is alive; a global process check
  # makes one stale display block every later distro in a multi-GUI setup.
  pgrep -f "^termux-x11 com\\.termux\\.x11 :${display_num}([[:space:]]|$)" >/dev/null 2>&1 && return 1
  rm -f -- "$socket" "$lock"
}

# ---------------------------------------------------------------------------
# tnx_cmd_start
# ---------------------------------------------------------------------------
tnx_cmd_start() {
  local distro="" launcher_dir launcher_path
  local display_num display tag
  [ "$#" -le 1 ] || { tnx_fail "Usage: ternux start [DISTRO]"; return 2; }
  if [ "$#" -eq 0 ]; then
    if tnx_proot_container_installed debian; then distro=debian
    else distro="$(tnx_distro)"; fi
  else
    distro="$(tnx_distro_canonical "$1")"
  fi
  tnx_distro_known "$distro" || { tnx_fail "Unsupported Ternux desktop profile '$distro'. Supported profiles: $TERNUX_DISTRO_KNOWN"; return 2; }
  tnx_proot_container_installed "$distro" || { tnx_fail "Guest '$distro' is not installed. Run: ternux install --distro $distro"; return 1; }
  unset _TNX_DISTRO
  export TERNUX_DISTRO="$distro"
  display_num="$(tnx_distro_display "$distro")" || { tnx_fail "No X11 display is assigned to guest '$distro'."; return 2; }
  display=":$display_num"; tag="$(tnx_distro_tag "$distro")"
  export TERNUX_DISPLAY="$display"
  launcher_dir="$(tnx_distro_state_dir "$distro")"
  launcher_path="$launcher_dir/launcher.sh"
  # Upgrade the former single-Debian launcher in place on first use.
  if [ "$distro" = debian ] && [ ! -f "$launcher_path" ] &&
     [ -f "$HOME/x.sh" ] && grep -q '^# TERNUX_DESKTOP_LAUNCHER=20$' "$HOME/x.sh"; then
    mkdir -p "$launcher_dir" && cp -p "$HOME/x.sh" "$launcher_path" || return 1
  fi
  if [ "${TERNUX_JSON:-0}" != "1" ]; then
    tnx_step "Starting ternux desktop..."
  fi

  if [ ! -f "$launcher_path" ] || ! grep -q '^# TERNUX_DESKTOP_LAUNCHER=20$' "$launcher_path"; then
    # CLI package upgrades must refresh the generated launcher too. It carries
    # process matching, audio routing and narrowed guest bind behavior.
    if ! declare -F tnx_phase_launcher >/dev/null 2>&1; then
      . "$(dirname "${BASH_SOURCE[0]}")/phases.sh"
    fi
    local launcher_user launcher_locale launcher_backend
    launcher_user="$(tnx_distro_state_get "$distro" user 2>/dev/null || tnx_state_get "user" || echo "ternux")"
    launcher_locale="$(tnx_distro_state_get "$distro" locale 2>/dev/null || tnx_state_get "locale" || echo "en_US.UTF-8")"
    launcher_backend="$(tnx_canonical_backend "$(tnx_distro_state_get "$distro" backend 2>/dev/null || tnx_state_get "backend" || echo "auto")")"
    launcher_user="${launcher_user:-ternux}"
    launcher_locale="${launcher_locale:-en_US.UTF-8}"
    launcher_backend="${launcher_backend:-auto}"
    tnx_info "Refreshing the generated desktop launcher..."
    tnx_phase_launcher "$launcher_user" "$launcher_backend" "$launcher_locale" || return 1
    if [ ! -f "$launcher_path" ] && [ "$distro" = debian ] &&
       [ -f "$HOME/x.sh" ] && grep -q '^# TERNUX_DESKTOP_LAUNCHER=20$' "$HOME/x.sh"; then
      mkdir -p "$launcher_dir" && cp -p "$HOME/x.sh" "$launcher_path" || return 1
    fi
  fi
  chmod +x "$launcher_path" 2>/dev/null || true

  local session_dir; session_dir="$(tnx_distro_session_dir "$distro")"
  local pid_file="$session_dir/desktop.pid" ready_file="$session_dir/desktop.pid.ready"
  local state_file="$session_dir/desktop.state"
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
      tnx_show_x11_activity "$tag"
      tnx_info "Desktop is already running on $display (PID $old_pid). Use 'ternux status' or 'ternux logs desktop tail'."
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
    tnx_show_x11_activity "$tag"
    tnx_info "Desktop is already active on $display${active_pid:+ (PID $active_pid)}. Use 'ternux status' or 'ternux logs desktop tail'."
    [ "${TERNUX_JSON:-0}" = "1" ] && tnx_json_object "start" "already_running" "pid" "${active_pid:-unknown}"
    exec 9>&-
    return 0
  fi
  rm -f "$pid_file" "$ready_file"

  # A different tagged display can run concurrently. Refuse only when this
  # guest's own X socket is occupied but its managed desktop is not ready.
  if [ -S "${TMPDIR:-/data/data/com.termux/files/usr/tmp}/.X11-unix/X$display_num" ]; then
    if tnx_remove_stale_x11_socket "$display_num"; then
      tnx_info "Removed the stale socket and lock for unused display $display."
    else
    if [ "${TERNUX_JSON:-0}" = "1" ]; then
      tnx_fail "Display $display is occupied but the Ternux readiness probe failed; refusing to replace it."
      tnx_json_object "start" "error" "reason" "unresponsive_existing_x11"
      exec 9>&-
      return 1
    fi
    tnx_fail "Display $display is already occupied but did not pass Ternux readiness; refusing to replace it."
    exec 9>&-
    return 1
    fi
  fi

  local configured_backend
  configured_backend="$(tnx_canonical_backend "$(tnx_distro_state_get "$distro" backend 2>/dev/null || tnx_state_get "backend" || echo "auto")")"
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
  tnx_info "Starting $distro desktop on $display (backend: $configured_backend)..."
  setsid env LD_LIBRARY_PATH= TNX_PID_FILE="$pid_file" nohup bash "$launcher_path" >>"$desktop_log" 2>&1 </dev/null 9>&- &
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
    if [ -S "${TMPDIR:-/data/data/com.termux/files/usr/tmp}/.X11-unix/X$display_num" ] &&
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
  printf '%s\n' "$distro" > "$session_dir/distro"
  exec 9>&-
  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    tnx_show_x11_activity "$tag"
    tnx_json_object "start" "ok" "backend" "$configured_backend" "pid" "$pid" "audio_route" "$audio_route" "log" "$desktop_log"
    return 0
  fi
  tnx_show_x11_activity "$tag"
  tnx_ok "Desktop is running in the background on $display (PID $pid)."
  [ "$audio_route" = "ready" ] && tnx_info "Desktop audio route is ready." || true
  tnx_info "Startup output: ternux logs desktop tail"
  return 0
}

# ---------------------------------------------------------------------------
# tnx_cmd_stop
# ---------------------------------------------------------------------------
tnx_cmd_stop() {
  local distro="${1:-$(cat "$TERNUX_STATE_DIR/session/distro" 2>/dev/null || tnx_distro)}"
  [ "$#" -le 1 ] || { tnx_fail "Usage: ternux stop [DISTRO|--all]"; return 2; }
  distro="$(tnx_distro_canonical "$distro")"
  if [ "${1:-}" = "--all" ] || { [ "$#" -eq 0 ] && [ "${TERNUX_JSON:-0}" != 1 ]; }; then
    _tnx_stop_select "$([ "${1:-}" = --all ] && echo all || true)"
    return $?
  fi
  tnx_distro_known "$distro" || { tnx_fail "Unsupported Ternux desktop profile '$distro'."; return 2; }
  unset _TNX_DISTRO
  export TERNUX_DISTRO="$distro"
  if [ "${TERNUX_JSON:-0}" != "1" ]; then
    tnx_step "Stopping ternux desktop..."
  fi

  local session_dir; session_dir="$(tnx_distro_session_dir "$distro")"
  local pid_file="$session_dir/desktop.pid"
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
       [[ "$legacy_cmdline" == *"$HOME/x.sh"* || "$legacy_cmdline" == *"$(tnx_distro_state_dir "$distro")/launcher.sh"* ]] && [ -n "$legacy_state" ] &&
       [ "$(tnx_process_start_identity "$legacy_pid" 2>/dev/null || true)" = "$legacy_start" ] &&
       tnx_process_is_live "$legacy_pid"; then
      tnx_signal_process_group KILL "$legacy_pgid" || true
      found=1
    fi
  fi

  # Remove only Ternux's own session markers. X11/Pulse sockets and daemons may
  # be shared with other Termux sessions; their owners clean them up themselves.
  rm -f "$pid_file" "${pid_file}.ready" "$identity_file" "$session_dir/distro"
  # Once the verified process-group stop (if any) is complete, the owned
  # markers above are gone. Normalize stale FAILED/RECOVERING states too, so a
  # later status/start does not keep reporting a dead session indefinitely.
  printf '%s\n' STOPPED > "$session_dir/desktop.state"
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
  local distro="${1:-$(cat "$TERNUX_STATE_DIR/session/distro" 2>/dev/null || tnx_distro)}"
  distro="$(tnx_distro_canonical "$distro")"
  tnx_cmd_stop "$distro" || {
    tnx_warn "Restart aborted because the existing desktop could not be stopped safely."
    return 1
  }
  sleep 1
  tnx_cmd_start "$distro"
}

# ---------------------------------------------------------------------------
# tnx_cmd_status (helper — used internally)
# ---------------------------------------------------------------------------
tnx_cmd_status() {
  local distro="${1:-$(cat "$TERNUX_STATE_DIR/session/distro" 2>/dev/null || tnx_distro)}"
  local active_distro=""
  [ "$#" -le 1 ] || { tnx_fail "Usage: ternux status [DISTRO]"; return 2; }
  distro="$(tnx_distro_canonical "$distro")"
  tnx_distro_known "$distro" || { tnx_fail "Unsupported Ternux desktop profile '$distro'."; return 2; }
  active_distro="$(cat "$(tnx_distro_session_dir "$distro")/distro" 2>/dev/null || true)"
  unset _TNX_DISTRO; export TERNUX_DISTRO="$distro"
  export TERNUX_DISPLAY=":$(tnx_distro_display "$distro")"
  local x11=0 pa=0 pa_ready=0 virgl=0 desktop_pid="" lifecycle="STOPPED"
  local identity_pid="" identity_start="" identity_pgid="" observed_start="" session_ready=0
  local session_dir; session_dir="$(tnx_distro_session_dir "$distro")"
  [ -r "$session_dir/desktop.pid" ] && desktop_pid="$(cat "$session_dir/desktop.pid" 2>/dev/null || true)"
  if [ -r "$session_dir/desktop.pid.identity" ]; then
    read -r identity_pid identity_start identity_pgid < "$session_dir/desktop.pid.identity" || true
  fi
  if [[ "$desktop_pid" =~ ^[0-9]+$ ]] && [ "$desktop_pid" = "$identity_pid" ] &&
     [ "$identity_pgid" = "$identity_pid" ] && [ -n "$identity_start" ]; then
    observed_start="$(tnx_process_start_identity "$desktop_pid" 2>/dev/null || true)"
  fi
  if ! [[ "$desktop_pid" =~ ^[0-9]+$ ]] || [ -z "$observed_start" ] || [ "$observed_start" != "$identity_start" ] ||
     ! tnx_process_is_live "$desktop_pid" || ! grep -q '^READY$' "$session_dir/desktop.pid.ready" 2>/dev/null; then desktop_pid=""; fi
  if [ -S "${TMPDIR:-/data/data/com.termux/files/usr/tmp}/.X11-unix/X$(tnx_distro_display "$distro")" ] &&
     pgrep -f "^termux-x11 com\.termux\.x11([[:space:]]|$)" >/dev/null 2>&1; then x11=1; fi
  if tnx_desktop_session_live; then
    session_ready=1
    desktop_pid="${desktop_pid:-active}"
  fi
  lifecycle="$(cat "$session_dir/desktop.state" 2>/dev/null || echo STOPPED)"
  case "$lifecycle" in STARTING|READY|STOPPING|FAILED|RECOVERING|STOPPED) ;; *) lifecycle=FAILED ;; esac
  if [ "$session_ready" -eq 1 ] && [ -n "$active_distro" ] && [ "$active_distro" != "$distro" ]; then
    session_ready=0
    desktop_pid=""
    lifecycle=STOPPED
  elif [ "$session_ready" -eq 1 ]; then
    if [ "$lifecycle" != READY ]; then lifecycle=RECOVERING; fi
  elif [ "$lifecycle" = READY ]; then lifecycle=FAILED
  elif [ "$lifecycle" = STARTING ] && { [ -z "$desktop_pid" ] || ! kill -0 "$desktop_pid" 2>/dev/null; }; then lifecycle=FAILED
  elif [ "$x11" -eq 1 ] && [ "$lifecycle" = STOPPED ] &&
       { [ ! -e "$session_dir/desktop.state" ] || [ "$active_distro" = "$distro" ]; }; then lifecycle=RECOVERING
  fi
  pgrep -x pulseaudio >/dev/null 2>&1 && pa=1
  tnx_pulseaudio_ready && pa_ready=1
  pgrep -f '(^|/)virgl_test_server(_android)?([[:space:]]|$)' >/dev/null 2>&1 && virgl=1

  local overall="stopped"
  [ "$session_ready" -eq 1 ] && overall="running"

  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    tnx_json_object "status" "$overall" \
      "lifecycle" "$lifecycle" \
      "distro" "$distro" \
      "x11_running" "$([ $x11 -eq 1 ] && echo "yes" || echo "no")" \
      "pulseaudio" "$([ $pa -eq 1 ] && echo "running" || echo "stopped")" \
      "pulseaudio_ready" "$([ $pa_ready -eq 1 ] && echo "yes" || echo "no")" \
      "virgl" "$([ $virgl -eq 1 ] && echo "running" || echo "stopped")" \
      "launcher" "$([ -f "$(tnx_distro_state_dir "$distro")/launcher.sh" ] && echo "present" || echo "missing")" \
      "desktop_pid" "${desktop_pid:-none}"
    return 0
  fi

  tnx_header "Desktop Status"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Guest:" "$distro"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Lifecycle:" "$lifecycle"
  printf "  ${TNX_CW}%-20s${TNX_C0} " "Overall:"
  [ "$overall" = "running" ] && printf "${TNX_CG}%s${TNX_C0}\n" "$overall" || printf "${TNX_CD}%s${TNX_C0}\n" "$overall"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Termux:X11:" "$([ $x11 -eq 1 ] && echo "running" || echo "stopped")"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "PulseAudio:" "$([ $pa -eq 1 ] && echo "running" || echo "stopped")"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Desktop audio route:" "$([ $pa_ready -eq 1 ] && echo "ready" || echo "unavailable")"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "VirGL:" "$([ $virgl -eq 1 ] && echo "running" || echo "stopped")"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Display:" ":$(tnx_distro_display "$distro")"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Launcher:" "$([ -f "$(tnx_distro_state_dir "$distro")/launcher.sh" ] && echo "present" || echo "missing")"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Managed PID:" "${desktop_pid:-none}"
  echo ""
}
