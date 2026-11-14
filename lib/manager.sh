# =============================================================================
# Ternux native manager read-only API payloads
#
# Copyright (c) 2026 Sobuj Miah (@soobujmiah)
# Licensed under the Apache License, Version 2.0.
# =============================================================================
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"
. "$(dirname "${BASH_SOURCE[0]}")/desktop.sh"

TNX_MANAGER_GUESTS=()

declare -Ag TNX_MANAGER_OPERATION_HANDLER=(
  [manager.capabilities]=tnx_manager_capabilities
  [manager.displays]=tnx_manager_displays
  [manager.guests]=tnx_manager_guests
  [manager.status]=tnx_manager_status
)
declare -Ag TNX_MANAGER_OPERATION_DESCRIPTION=(
  [manager.capabilities]="List implemented manager operations."
  [manager.displays]="Read current and planned workspace display assignments."
  [manager.guests]="List installed PRoot guests and their desktop profiles."
  [manager.status]="Read Native Termux manager and desktop status."
)

tnx_manager_load_guests() {
  local listing="" name
  tnx_has_cmd proot-distro || return 69
  listing="$(proot-distro list --quiet 2>/dev/null)" || return 1
  TNX_MANAGER_GUESTS=()
  while IFS= read -r name; do
    [[ "$name" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]] || continue
    TNX_MANAGER_GUESTS+=("$name")
  done < <(printf '%s\n' "$listing" | LC_ALL=C sort -u)
}

tnx_manager_guest_json() {
  local name="$1" profile=false display=null qualification="no-desktop-profile"
  if tnx_distro_known "$name"; then
    profile=true
    display="$(tnx_distro_display "$name" 2>/dev/null || true)"
    [[ "$display" =~ ^[0-9]{1,2}$ ]] || display=null
    if tnx_distro_verified "$name"; then qualification="device-qualified"; else qualification="not-device-qualified"; fi
  fi
  printf '{"name":"%s","state":"installed","desktop_profile":%s,"display":%s,"qualification":"%s"}' \
    "$name" "$profile" "$display" "$qualification"
}

tnx_manager_display_entry_json() {
  local name="$1" current target socket_present=false lock_present=false server_running=false running=false
  local target_conflict=false migration_required=false occupied=false target_owner=null target_owner_kind=unoccupied
  local registry_display=null registry_lifecycle=unregistered registry_rc=0
  local -n running_guest_ref="$2"
  current="$(tnx_distro_state_get "$name" display 2>/dev/null || true)"
  [[ "$current" =~ ^[0-9]{1,2}$ ]] || current=null
  local registry_value
  if registry_value="$(tnx_workspace_registry_get "$name" display 2>/dev/null)"; then
    [[ "$registry_value" =~ ^[0-9]{1,2}$ ]] && registry_display="$registry_value"
    registry_lifecycle="$(tnx_workspace_registry_get "$name" lifecycle 2>/dev/null || echo invalid)"
  else
    registry_rc=$?
    [ "$registry_rc" -eq 2 ] && registry_lifecycle=invalid
  fi
  target="$(tnx_distro_target_display "$name" 2>/dev/null || true)"
  [[ "$target" =~ ^[0-9]{1,2}$ ]] || return 1
  [ "${running_guest_ref[$name]:-0}" = 1 ] && running=true
  if [[ -e "${TMPDIR:-/data/data/com.termux/files/usr/tmp}/.X11-unix/X$target" || -L "${TMPDIR:-/data/data/com.termux/files/usr/tmp}/.X11-unix/X$target" ]]; then
    socket_present=true; occupied=true
  fi
  if [[ -e "${TMPDIR:-/data/data/com.termux/files/usr/tmp}/.X$target-lock" || -L "${TMPDIR:-/data/data/com.termux/files/usr/tmp}/.X$target-lock" ]]; then
    lock_present=true; occupied=true
  fi
  if tnx_x11_server_running_on_display "$target"; then server_running=true; occupied=true; fi
  if [ "$current" != null ] && [ "$current" != "$target" ]; then migration_required=true; fi
  if [ "$occupied" = true ] && ! { [ "$current" = "$target" ] && [ "$running" = true ] && [ "$server_running" = true ]; }; then target_conflict=true; fi
  if [ "$occupied" = true ]; then
    local candidate candidate_display owner_count=0
    local -a owners=()
    for candidate in "${!running_guest_ref[@]}"; do
      candidate_display="$(tnx_distro_state_get "$candidate" display 2>/dev/null || true)"
      [ "$candidate_display" = "$target" ] && owners+=("$candidate")
    done
    owner_count="${#owners[@]}"
    if [ "$owner_count" -gt 1 ]; then target_conflict=true; fi
    if [ "$owner_count" -eq 1 ]; then
      target_owner="\"${owners[0]}\""
      target_owner_kind=active-guest-assignment
    elif [ "$target" = "$TERNUX_NATIVE_DISPLAY" ]; then
      # The reservation is known; this does not claim the native UI owns it.
      target_owner_kind=reserved-native-slot
    else
      target_owner_kind=unidentified
    fi
  fi
  printf '{"name":"%s","current_display":%s,"target_display":%s,"registry_display":%s,"registry_lifecycle":"%s","running":%s,"target_socket_present":%s,"target_lock_present":%s,"target_server_running":%s,"target_conflict":%s,"migration_required":%s,"target_owner":%s,"target_owner_kind":"%s"}' \
    "$name" "$current" "$target" "$registry_display" "$registry_lifecycle" "$running" "$socket_present" "$lock_present" "$server_running" "$target_conflict" "$migration_required" "$target_owner" "$target_owner_kind"
}

tnx_manager_displays_json() {
  local name first=1 native_socket=false native_lock=false native_server=false native_occupied=false count=0
  local guests_json="["
  local -a running_names=()
  local -A running_map=()
  mapfile -t running_names < <(_tnx_running_guest_sessions)
  for name in "${running_names[@]}"; do [[ "$name" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]] && running_map["$name"]=1; done
  for name in "${TNX_MANAGER_GUESTS[@]}"; do
    tnx_distro_known "$name" || continue
    [ "$first" -eq 1 ] || guests_json+=","; first=0
    guests_json+="$(tnx_manager_display_entry_json "$name" running_map)" || return 1
    count=$((count+1))
  done
  guests_json+="]"
  if [[ -e "${TMPDIR:-/data/data/com.termux/files/usr/tmp}/.X11-unix/X$TERNUX_NATIVE_DISPLAY" || -L "${TMPDIR:-/data/data/com.termux/files/usr/tmp}/.X11-unix/X$TERNUX_NATIVE_DISPLAY" ]]; then native_socket=true; native_occupied=true; fi
  if [[ -e "${TMPDIR:-/data/data/com.termux/files/usr/tmp}/.X$TERNUX_NATIVE_DISPLAY-lock" || -L "${TMPDIR:-/data/data/com.termux/files/usr/tmp}/.X$TERNUX_NATIVE_DISPLAY-lock" ]]; then native_lock=true; native_occupied=true; fi
  if tnx_x11_server_running_on_display "$TERNUX_NATIVE_DISPLAY"; then native_server=true; native_occupied=true; fi
  tnx_json_init
  tnx_json_add "schema_version" "1.2.0"
  tnx_json_add "command" "manager.displays"
  tnx_json_add "status" "ok"
  tnx_json_add "timestamp" "$( __tnx_ts )"
  tnx_json_add_raw "native_display" "$TERNUX_NATIVE_DISPLAY"
  tnx_json_add_raw "native_socket_present" "$native_socket"
  tnx_json_add_raw "native_lock_present" "$native_lock"
  tnx_json_add_raw "native_server_running" "$native_server"
  tnx_json_add_raw "native_occupied" "$native_occupied"
  tnx_json_add_raw "count" "$count"
  tnx_json_add_raw "guests" "$guests_json"
  tnx_json_end
}

tnx_manager_running_json() {
  local name first=1 output="["
  local -a running=()
  while IFS= read -r name; do
    [[ "$name" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]] && running+=("$name")
  done < <(_tnx_running_guest_sessions)
  for name in "${running[@]}"; do
    [ "$first" -eq 1 ] || output+=","; first=0
    output+="\"$name\""
  done
  output+="]"
  printf '%s' "$output"
}

_tnx_manager_action() {
  local action="${1:-}" name guests_json="[" first=1 rc count guest_manager=true running_json
  [ "$#" -ge 1 ] || { tnx_fail "Usage: tx manager status|guests|displays|capabilities [--json]"; return 2; }
  shift
  [ "$#" -eq 0 ] || { tnx_fail "Usage: tx manager status|guests|displays|capabilities [--json]"; return 2; }
  case "$action" in
    status)
      rc=0
      tnx_manager_load_guests || rc=$?
      if [ "$rc" -eq 69 ]; then guest_manager=false; count=null
      elif [ "$rc" -ne 0 ]; then
        if [ "${TERNUX_JSON:-0}" = 1 ]; then
          tnx_json_init
          tnx_json_add "schema_version" "1.0.0"
          tnx_json_add "command" "manager.status"
          tnx_json_add "status" "error"
          tnx_json_add "timestamp" "$( __tnx_ts )"
          tnx_json_add "code" "GUEST_LIST_FAILED"
          tnx_json_add "message" "Could not read the installed PRoot guest list."
          tnx_json_end
        else tnx_fail "Could not read the installed PRoot guest list."; fi
        return 1
      else count="${#TNX_MANAGER_GUESTS[@]}"; fi
      running_json="$(tnx_manager_running_json)"
      if [ "${TERNUX_JSON:-0}" = 1 ]; then
        tnx_json_init
        tnx_json_add "schema_version" "1.0.0"
        tnx_json_add "command" "manager.status"
        tnx_json_add "status" "available"
        tnx_json_add "timestamp" "$( __tnx_ts )"
        tnx_json_add "version" "$TERNUX_VERSION"
        tnx_json_add "runtime" "termux"
        tnx_json_add "management_mode" "direct-cli"
        tnx_json_add_raw "guest_manager_available" "$guest_manager"
        tnx_json_add_raw "installed_guest_count" "$count"
        tnx_json_add_raw "running_desktops" "$running_json"
        tnx_json_end
      else
        tnx_header "Native Manager"
        printf '  CLI: available (direct mode)\n  Guest manager: %s\n  Installed guests: %s\n  Running desktops:' \
          "$([ "$guest_manager" = true ] && echo available || echo unavailable)" "$count"
        local -a running=()
        while IFS= read -r name; do [[ "$name" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]] && running+=("$name"); done < <(_tnx_running_guest_sessions)
        if [ "${#running[@]}" -eq 0 ]; then printf ' none\n'; else printf ' %s\n' "${running[*]}"; fi
      fi
      ;;
    guests)
      tnx_manager_load_guests || {
        rc=$?
        if [ "${TERNUX_JSON:-0}" = 1 ]; then
          tnx_json_init
          tnx_json_add "schema_version" "1.0.0"
          tnx_json_add "command" "manager.guests"
          tnx_json_add "status" "error"
          tnx_json_add "timestamp" "$( __tnx_ts )"
          if [ "$rc" -eq 69 ]; then
            tnx_json_add "code" "GUEST_MANAGER_UNAVAILABLE"
            tnx_json_add "message" "proot-distro is not installed."
          else
            tnx_json_add "code" "GUEST_LIST_FAILED"
            tnx_json_add "message" "Could not read the installed PRoot guest list."
          fi
          tnx_json_end
        elif [ "$rc" -eq 69 ]; then tnx_fail "proot-distro is not installed."; else tnx_fail "Could not read the installed PRoot guest list."; fi
        return 1
      }
      for name in "${TNX_MANAGER_GUESTS[@]}"; do
        [ "$first" -eq 1 ] || guests_json+=","; first=0
        guests_json+="$(tnx_manager_guest_json "$name")"
      done
      guests_json+="]"
      if [ "${TERNUX_JSON:-0}" = 1 ]; then
        tnx_json_init
        tnx_json_add "schema_version" "1.0.0"
        tnx_json_add "command" "manager.guests"
        tnx_json_add "status" "ok"
        tnx_json_add "timestamp" "$( __tnx_ts )"
        tnx_json_add_raw "count" "${#TNX_MANAGER_GUESTS[@]}"
        tnx_json_add_raw "guests" "$guests_json"
        tnx_json_end
      else
        tnx_header "Installed Guests"
        if [ "${#TNX_MANAGER_GUESTS[@]}" -eq 0 ]; then printf '  No PRoot guests installed.\n'
        else
          for name in "${TNX_MANAGER_GUESTS[@]}"; do
            printf '  %-20s ' "$name"
            if tnx_distro_known "$name"; then printf 'desktop profile, display :%s\n' "$(tnx_distro_display "$name")"
            else printf 'shell guest\n'; fi
          done
        fi
      fi
      ;;
    displays)
      tnx_manager_load_guests || {
        rc=$?
        if [ "${TERNUX_JSON:-0}" = 1 ]; then
          tnx_json_init
          tnx_json_add "schema_version" "1.0.0"
          tnx_json_add "command" "manager.displays"
          tnx_json_add "status" "error"
          tnx_json_add "timestamp" "$( __tnx_ts )"
          if [ "$rc" -eq 69 ]; then
            tnx_json_add "code" "GUEST_MANAGER_UNAVAILABLE"
            tnx_json_add "message" "proot-distro is not installed."
          else
            tnx_json_add "code" "GUEST_LIST_FAILED"
            tnx_json_add "message" "Could not read the installed PRoot guest list."
          fi
          tnx_json_end
        elif [ "$rc" -eq 69 ]; then tnx_fail "proot-distro is not installed."; else tnx_fail "Could not read the installed PRoot guest list."; fi
        return 1
      }
      if [ "${TERNUX_JSON:-0}" = 1 ]; then
        tnx_manager_displays_json
      else
        tnx_header "Workspace Displays"
        printf '  Native Termux workspace: :%s (reserved; %s)\n' "$TERNUX_NATIVE_DISPLAY" \
          "$(if tnx_x11_server_running_on_display "$TERNUX_NATIVE_DISPLAY" || [[ -e "${TMPDIR:-/data/data/com.termux/files/usr/tmp}/.X11-unix/X$TERNUX_NATIVE_DISPLAY" ]]; then printf occupied; else printf available; fi)"
        printf '  %-12s %-9s %-9s %-10s %-18s\n' Guest Current Target State
        for name in "${TNX_MANAGER_GUESTS[@]}"; do
          tnx_distro_known "$name" || continue
          local current target status
          current="$(tnx_distro_state_get "$name" display 2>/dev/null || true)"; [[ "$current" =~ ^[0-9]{1,2}$ ]] || current=unset
          target="$(tnx_distro_target_display "$name")"
          status=ready
          if [ "$current" != unset ] && [ "$current" != "$target" ]; then status=migration-required; fi
          if { tnx_x11_server_running_on_display "$target" || [[ -e "${TMPDIR:-/data/data/com.termux/files/usr/tmp}/.X11-unix/X$target" || -e "${TMPDIR:-/data/data/com.termux/files/usr/tmp}/.X$target-lock" ]]; } && [ "$current" != "$target" ]; then status=target-occupied; fi
          printf '  %-12s :%-8s :%-8s %-18s\n' "$name" "$current" "$target" "$status"
        done
      fi
      ;;
    *) tnx_fail "Usage: tx manager status|guests|displays|capabilities [--json]"; return 2 ;;
  esac
}

tnx_manager_error() {
  local code="$1" message="$2" status="${3:-2}"
  if [ "${TERNUX_JSON:-0}" = 1 ]; then
    tnx_json_init
    tnx_json_add "schema_version" "1.0.0"
    tnx_json_add "command" "manager.error"
    tnx_json_add "status" "error"
    tnx_json_add "timestamp" "$( __tnx_ts )"
    tnx_json_add "code" "$code"
    tnx_json_add "message" "$message"
    tnx_json_end
  else
    tnx_fail "$message"
  fi
  return "$status"
}

tnx_manager_status() { _tnx_manager_action status; }
tnx_manager_guests() { _tnx_manager_action guests; }
tnx_manager_displays() { _tnx_manager_action displays; }

tnx_manager_capabilities() {
  local operation first=1 operations="["
  local -a ids=()
  mapfile -t ids < <(printf '%s\n' "${!TNX_MANAGER_OPERATION_HANDLER[@]}" | LC_ALL=C sort)
  for operation in "${ids[@]}"; do
    [ "$first" -eq 1 ] || operations+=","; first=0
    operations+="{\"id\":\"$operation\",\"access\":\"read-only\",\"argument_count\":0,\"description\":\"${TNX_MANAGER_OPERATION_DESCRIPTION[$operation]}\"}"
  done
  operations+="]"
  if [ "${TERNUX_JSON:-0}" = 1 ]; then
    tnx_json_init
    tnx_json_add "schema_version" "1.0.0"
    tnx_json_add "command" "manager.capabilities"
    tnx_json_add "status" "ok"
    tnx_json_add "timestamp" "$( __tnx_ts )"
    tnx_json_add_raw "count" "${#ids[@]}"
    tnx_json_add_raw "operations" "$operations"
    tnx_json_end
  else
    tnx_header "Native Manager Operations"
    for operation in "${ids[@]}"; do printf '  %-24s %s\n' "$operation" "${TNX_MANAGER_OPERATION_DESCRIPTION[$operation]}"; done
  fi
}

tnx_manager_dispatch() {
  local operation="$1" handler="${TNX_MANAGER_OPERATION_HANDLER[${1:-}]:-}"
  shift || true
  [ -n "$handler" ] || { tnx_manager_error "UNKNOWN_OPERATION" "Unsupported manager operation '${operation:-}'."; return $?; }
  [ "$#" -eq 0 ] || { tnx_manager_error "INVALID_ARGUMENTS" "Manager operation '$operation' accepts no arguments."; return $?; }
  "$handler"
}

tnx_cmd_control() {
  local script="${_TNX_LIB_DIR}/control_center.py"
  [ "$#" -le 1 ] || { tnx_fail "Usage: tx control [--no-open]"; return 2; }
  [ "$#" -eq 0 ] || [ "$1" = "--no-open" ] || { tnx_fail "Usage: tx control [--no-open]"; return 2; }
  [ -f "$script" ] || { tnx_fail "Control Center is missing: $script"; return 69; }
  if ! command -v python3 >/dev/null 2>&1; then
    tnx_fail "The Control Center needs Python 3. Install it with: pkg install python"
    return 69
  fi
  exec python3 "$script" "$@"
}

tnx_cmd_manager() {
  local action="${1:-}"
  [ -n "$action" ] || { tnx_fail "Usage: tx manager status|guests|displays|capabilities [--json]"; return 2; }
  shift
  if [ "$action" = serve ]; then
    [ "$#" -eq 0 ] || { tnx_fail "Usage: tx manager serve"; return 2; }
    local daemon="${_TNX_LIB_DIR}/managerd.py"
    [ -f "$daemon" ] || { tnx_fail "Manager service is missing: $daemon"; return 69; }
    if ! command -v python3 >/dev/null 2>&1; then
      tnx_fail "The optional manager service needs Python 3. Install it with: pkg install python"
      return 69
    fi
    exec python3 "$daemon" serve
  fi
  tnx_manager_dispatch "manager.$action" "$@"
}
