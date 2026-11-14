# =============================================================================
# Ternux native manager snapshots and staged display migration
#
# Copyright (c) 2026 Sobuj Miah (@soobujmiah)
# Licensed under the Apache License, Version 2.0.
# =============================================================================
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"
. "$(dirname "${BASH_SOURCE[0]}")/desktop.sh"

TNX_MANAGER_GUESTS=()
TNX_MANAGER_DISPLAY_ENTRY_JSON=""
TNX_MANAGER_PLAN_INPUT=""
TNX_MANAGER_PLAN_ID=""
TNX_MANAGER_MOVE_NAMES=()
TNX_MANAGER_BLOCKED_NAMES=()
TNX_MANAGER_PLAN_BLOCKED=false
declare -Ag TNX_MANAGER_MOVE_TO=()

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
  local migration_action=initialize migration_blockers="[" blocker_first=1 blocker other_active=0 candidate
  local -a blockers=()
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
  if [ "$current" = null ]; then migration_action=initialize
  elif [ "$current" = "$target" ]; then migration_action=keep
  else migration_action=move; migration_required=true; fi
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
  for candidate in "${!running_guest_ref[@]}"; do
    if [ "$candidate" != "$name" ]; then other_active=1; break; fi
  done
  if [ "$migration_action" = move ]; then
    if [ "$running" = true ]; then blockers+=("active-session")
    elif [ "$other_active" -eq 1 ]; then blockers+=("other-active-session"); fi
    if [ "$target_conflict" = true ]; then blockers+=("target-conflict"); fi
    if [ "$registry_lifecycle" = invalid ]; then blockers+=("invalid-registry")
    elif [ "$registry_display" != null ] && [ "$registry_display" != "$current" ]; then blockers+=("registry-mismatch"); fi
    if [ "$registry_lifecycle" != unregistered ] && [ "$registry_lifecycle" != STOPPED ] && [ "$registry_lifecycle" != invalid ]; then blockers+=("lifecycle-not-stopped"); fi
  fi
  for blocker in "${blockers[@]}"; do
    [ "$blocker_first" -eq 1 ] || migration_blockers+=","; blocker_first=0
    migration_blockers+="\"$blocker\""
  done
  migration_blockers+="]"
  TNX_MANAGER_PLAN_INPUT+="$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$name" "$current" "$target" "$registry_display" "$registry_lifecycle" "$running" "$target_conflict" "$socket_present" "$lock_present" "$server_running")"
  if [ "$migration_action" = move ]; then
    TNX_MANAGER_MOVE_NAMES+=("$name")
    TNX_MANAGER_MOVE_TO["$name"]="$target"
    [ "${#blockers[@]}" -eq 0 ] || { TNX_MANAGER_BLOCKED_NAMES+=("$name"); TNX_MANAGER_PLAN_BLOCKED=true; }
  fi
  TNX_MANAGER_DISPLAY_ENTRY_JSON="$(printf '{"name":"%s","current_display":%s,"target_display":%s,"registry_display":%s,"registry_lifecycle":"%s","running":%s,"target_socket_present":%s,"target_lock_present":%s,"target_server_running":%s,"target_conflict":%s,"migration_required":%s,"target_owner":%s,"target_owner_kind":"%s","migration_action":"%s","migration_blockers":%s}' \
    "$name" "$current" "$target" "$registry_display" "$registry_lifecycle" "$running" "$socket_present" "$lock_present" "$server_running" "$target_conflict" "$migration_required" "$target_owner" "$target_owner_kind" "$migration_action" "$migration_blockers")"
}

tnx_manager_displays_json_impl() {
  local name first=1 native_socket=false native_lock=false native_server=false native_occupied=false count=0
  local guests_json="[" plan_hash=""
  local -a running_names=()
  local -A running_map=()
  mapfile -t running_names < <(_tnx_running_guest_sessions)
  for name in "${running_names[@]}"; do [[ "$name" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]] && running_map["$name"]=1; done
  TNX_MANAGER_PLAN_INPUT="$(printf 'ternux-display-migration-plan-v1\n')"
  TNX_MANAGER_PLAN_ID=""
  TNX_MANAGER_MOVE_NAMES=()
  TNX_MANAGER_BLOCKED_NAMES=()
  TNX_MANAGER_PLAN_BLOCKED=false
    TNX_MANAGER_MOVE_TO=()
  for name in "${TNX_MANAGER_GUESTS[@]}"; do
    tnx_distro_known "$name" || continue
    [ "$first" -eq 1 ] || guests_json+=","; first=0
    tnx_manager_display_entry_json "$name" running_map || return 1
    guests_json+="$TNX_MANAGER_DISPLAY_ENTRY_JSON"
    count=$((count+1))
  done
  guests_json+="]"
  if ! command -v sha256sum >/dev/null 2>&1; then return 1; fi
  plan_hash="$(printf '%s' "$TNX_MANAGER_PLAN_INPUT" | sha256sum | awk '{print $1}')" || return 1
  [[ "$plan_hash" =~ ^[a-f0-9]{64}$ ]] || return 1
  TNX_MANAGER_PLAN_ID="$plan_hash"
  if [[ -e "${TMPDIR:-/data/data/com.termux/files/usr/tmp}/.X11-unix/X$TERNUX_NATIVE_DISPLAY" || -L "${TMPDIR:-/data/data/com.termux/files/usr/tmp}/.X11-unix/X$TERNUX_NATIVE_DISPLAY" ]]; then native_socket=true; native_occupied=true; fi
  if [[ -e "${TMPDIR:-/data/data/com.termux/files/usr/tmp}/.X$TERNUX_NATIVE_DISPLAY-lock" || -L "${TMPDIR:-/data/data/com.termux/files/usr/tmp}/.X$TERNUX_NATIVE_DISPLAY-lock" ]]; then native_lock=true; native_occupied=true; fi
  if tnx_x11_server_running_on_display "$TERNUX_NATIVE_DISPLAY"; then native_server=true; native_occupied=true; fi
  tnx_json_init
  tnx_json_add "schema_version" "1.3.0"
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
  local plan_ready=false
  [ "${#TNX_MANAGER_MOVE_NAMES[@]}" -gt 0 ] && [ "$TNX_MANAGER_PLAN_BLOCKED" = false ] && plan_ready=true
  tnx_json_add_raw "migration_preview" "{\"status\":\"preview-only\",\"executor_implemented\":true,\"ready_to_execute\":$plan_ready,\"plan_id\":\"sha256:$plan_hash\"}"
  tnx_json_end
}


tnx_manager_displays_json() {
  tnx_display_migration_shared_call tnx_manager_displays_json_impl "$@"
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
tnx_manager_displays() { tnx_display_migration_shared_call _tnx_manager_action displays; }

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
  if [ "$action" = migrate ]; then
    if [ "$#" -eq 1 ] && [ "$1" = --recover ]; then
      tnx_manager_migration_recover_locked
      return $?
    fi
    [ "$#" -eq 2 ] && [ "$1" = --apply ] || { tnx_fail "Usage: tx manager migrate --apply sha256:PLAN_ID | --recover"; return 2; }
    shift
    tnx_manager_migration_apply "$1"
    return $?
  fi
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

# Journal phase changes use atomic replacement so recovery never observes a
# truncated marker between preparing, applying, and committed.
tnx_manager_journal_status() {
  local journal="$1" status="$2" temp="$1/.status.tmp.$$"
  case "$status" in preparing|applying|committed) ;; *) return 2 ;; esac
  printf '%s\n' "$status" > "$temp" && chmod 0600 "$temp" && mv -f "$temp" "$journal/status" || { rm -f "$temp"; return 1; }
}

# Apply a display plan only when its exact snapshot remains current. Every
# changed file is backed up before the journal enters the applying state.
tnx_manager_migration_restore() {
  local journal="$1" registry name state_dir temp existed count=0
  local -A seen=()
  [ -d "$journal" ] && [ ! -L "$journal" ] || return 1
  if [ ! -e "$journal/status" ]; then
    [ ! -e "$journal/guests" ] && [ ! -e "$journal/registry_existed" ] || return 1
    rm -rf "$journal"
    return $?
  fi
  [ -f "$journal/status" ] && [ ! -L "$journal/status" ] || return 1
  case "$(cat "$journal/status" 2>/dev/null || true)" in
    committed|preparing) rm -rf "$journal"; return $? ;;
    *) ;;
  esac
  [ -f "$journal/guests" ] && [ ! -L "$journal/guests" ] || return 1
  [ -f "$journal/registry_existed" ] && [ ! -L "$journal/registry_existed" ] || return 1
  existed="$(cat "$journal/registry_existed" 2>/dev/null || true)"
  case "$existed" in yes) [ -f "$journal/workspaces.tsv" ] && [ ! -L "$journal/workspaces.tsv" ] || return 1 ;; no) ;; *) return 1 ;; esac
  while IFS= read -r name || [ -n "$name" ]; do
    [[ "$name" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || return 1
    [ -z "${seen[$name]:-}" ] || return 1
    seen["$name"]=1; count=$((count + 1))
    state_dir="$(tnx_distro_state_dir "$name")" || return 1
    [ -d "$state_dir" ] && [ ! -L "$state_dir" ] || return 1
    [ -f "$journal/$name.profile" ] && [ ! -L "$journal/$name.profile" ] || return 1
  done < "$journal/guests"
  [ "$count" -gt 0 ] || return 1
  registry="$(tnx_workspace_registry_path)"
  while IFS= read -r name || [ -n "$name" ]; do
    state_dir="$(tnx_distro_state_dir "$name")"
    temp="$state_dir/.profile.rollback.$$"
    cp -p "$journal/$name.profile" "$temp" && mv -f "$temp" "$state_dir/profile" || { rm -f "$temp"; return 1; }
  done < "$journal/guests"
  if [ "$existed" = yes ]; then
    temp="${registry}.rollback.$$"
    cp -p "$journal/workspaces.tsv" "$temp" && mv -f "$temp" "$registry" || { rm -f "$temp"; return 1; }
  else
    rm -f "$registry" || return 1
  fi
  rm -rf "$journal"
}

tnx_manager_migration_recover_locked() {
  local lock_fd
  [ ! -L "$TERNUX_STATE_DIR/migrations" ] || { tnx_fail "Migration journal path must not be a symlink."; return 1; }
  mkdir -p "$TERNUX_STATE_DIR/migrations" || return 1
  exec {lock_fd}<"$TERNUX_STATE_DIR" || return 1
  flock -xn "$lock_fd" || { exec {lock_fd}>&-; tnx_fail "A guest start/stop or another migration is in progress; retry recovery after it finishes."; return 1; }
  tnx_manager_migration_recover || { exec {lock_fd}>&-; tnx_fail "Display migration recovery could not restore the journal."; return 1; }
  exec {lock_fd}>&-
  tnx_ok "Interrupted display migration journals recovered. Review 'tx manager displays --json'."
}

tnx_manager_migration_recover() {
  local root="$TERNUX_STATE_DIR/migrations" item
  [ -e "$root" ] || return 0
  [ -d "$root" ] && [ ! -L "$root" ] || return 1
  for item in "$root"/*; do
    { [ -e "$item" ] || [ -L "$item" ]; } || continue
    tnx_manager_migration_restore "$item" || return 1
  done
}

tnx_manager_migration_pending() {
  local item
  [ -d "$TERNUX_STATE_DIR/migrations" ] || return 1
  for item in "$TERNUX_STATE_DIR"/migrations/*; do
    [ -e "$item" ] || continue
    case "$(cat "$item/status" 2>/dev/null || true)" in committed) ;; *) return 0 ;; esac
  done
  return 1
}

tnx_manager_migration_apply() {
  local expected="$1" lock_fd journal registry name state_dir rc=0 current_lifecycle
  local -a names=()
  [[ "$expected" =~ ^sha256:[a-f0-9]{64}$ ]] || { tnx_fail "Usage: tx manager migrate --apply sha256:PLAN_ID"; return 2; }
  tnx_has_cmd flock || { tnx_fail "Display migration needs flock; install util-linux."; return 69; }
  [ ! -L "$TERNUX_STATE_DIR/migrations" ] || { tnx_fail "Migration journal path must not be a symlink."; return 1; }
  mkdir -p "$TERNUX_STATE_DIR/migrations" || return 1
  exec {lock_fd}<"$TERNUX_STATE_DIR" || return 1
  flock -xn "$lock_fd" || { exec {lock_fd}>&-; tnx_fail "A guest start/stop or another migration is in progress; retry after it finishes."; return 1; }
  tnx_manager_migration_recover || { exec {lock_fd}>&-; tnx_fail "Interrupted migration recovery failed; no new migration was started."; return 1; }
  tnx_manager_load_guests || { rc=$?; exec {lock_fd}>&-; tnx_fail "Could not read installed guests (code $rc)."; return 1; }
  TERNUX_DISPLAY_MIGRATION_LOCK_HELD=1 tnx_manager_displays_json >/dev/null || { exec {lock_fd}>&-; tnx_fail "Could not compute the current migration plan."; return 1; }
  [ "sha256:$TNX_MANAGER_PLAN_ID" = "$expected" ] || { exec {lock_fd}>&-; tnx_fail "Migration plan is stale. Re-run 'tx manager displays --json' and review the new plan_id."; return 1; }
  [ "${#TNX_MANAGER_MOVE_NAMES[@]}" -gt 0 ] || { exec {lock_fd}>&-; tnx_fail "No saved display assignments need migration."; return 1; }
  [ "${#TNX_MANAGER_BLOCKED_NAMES[@]}" -eq 0 ] || { exec {lock_fd}>&-; tnx_fail "Migration is blocked for: ${TNX_MANAGER_BLOCKED_NAMES[*]}. Stop managed sessions and clear blockers before retrying."; return 1; }
  names=("${TNX_MANAGER_MOVE_NAMES[@]}")
  for name in "${names[@]}"; do
    current_lifecycle="$(tnx_workspace_registry_get "$name" lifecycle 2>/dev/null || true)"
    [ -z "$current_lifecycle" ] || [ "$current_lifecycle" = STOPPED ] || {
      exec {lock_fd}>&-
      tnx_fail "Guest '$name' registry lifecycle is '$current_lifecycle'; only STOPPED or unregistered guests can migrate."
      return 1
    }
  done
  journal="$TERNUX_STATE_DIR/migrations/applying-$(date -u '+%Y%m%dT%H%M%SZ')-$$"
  mkdir -m 700 "$journal" || { exec {lock_fd}>&-; return 1; }
  tnx_manager_journal_status "$journal" preparing || { rm -rf "$journal"; exec {lock_fd}>&-; return 1; }
  registry="$(tnx_workspace_registry_path)"
  if [ -f "$registry" ]; then
    cp -p "$registry" "$journal/workspaces.tsv" || { rm -rf "$journal"; exec {lock_fd}>&-; return 1; }
    printf yes > "$journal/registry_existed" || { rm -rf "$journal"; exec {lock_fd}>&-; return 1; }
  else
    printf no > "$journal/registry_existed" || { rm -rf "$journal"; exec {lock_fd}>&-; return 1; }
  fi
  printf '%s\n' "${names[@]}" > "$journal/guests" || { rm -rf "$journal"; exec {lock_fd}>&-; return 1; }
  for name in "${names[@]}"; do
    state_dir="$(tnx_distro_state_dir "$name")"
    [ -f "$state_dir/profile" ] && cp -p "$state_dir/profile" "$journal/$name.profile" || { rm -rf "$journal"; exec {lock_fd}>&-; return 1; }
  done
  tnx_manager_journal_status "$journal" applying || { rm -rf "$journal"; exec {lock_fd}>&-; return 1; }
  sync
  for name in "${names[@]}"; do
    TERNUX_DISPLAY_MIGRATION_LOCK_HELD=1 tnx_distro_state_set "$name" display "${TNX_MANAGER_MOVE_TO[$name]}" &&
      TERNUX_DISPLAY_MIGRATION_LOCK_HELD=1 tnx_workspace_registry_update "$name" STOPPED "${TNX_MANAGER_MOVE_TO[$name]}" || { rc=1; break; }
  done
  if [ "$rc" -ne 0 ]; then
    if tnx_manager_migration_restore "$journal"; then
      tnx_fail "Migration failed; original profile and registry files were restored."
    else
      tnx_fail "Migration failed and rollback is incomplete. Journal retained at $journal; guest starts must remain blocked until recovery."
    fi
    exec {lock_fd}>&-
    return 1
  fi
  tnx_manager_journal_status "$journal" committed && sync || {
    exec {lock_fd}>&-
    tnx_fail "Assignments were written but commit marker failed. Journal retained for recovery."
    return 1
  }
  rm -rf "$journal"
  exec {lock_fd}>&-
  tnx_ok "Migrated ${#names[@]} stopped guest assignment(s). Review with 'tx manager displays --json'."
}
