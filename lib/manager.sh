# =============================================================================
# Ternux native manager read-only API payloads
#
# Copyright (c) 2026 Sobuj Miah (@soobujmiah)
# Licensed under the Apache License, Version 2.0.
# =============================================================================
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"
. "$(dirname "${BASH_SOURCE[0]}")/desktop.sh"

TNX_MANAGER_GUESTS=()

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

tnx_cmd_manager() {
  local action="${1:-}" name guests_json="[" first=1 rc count guest_manager=true running_json
  [ "$#" -ge 1 ] || { tnx_fail "Usage: tx manager status|guests [--json]"; return 2; }
  shift
  [ "$#" -eq 0 ] || { tnx_fail "Usage: tx manager status|guests [--json]"; return 2; }
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
    *) tnx_fail "Usage: tx manager status|guests [--json]"; return 2 ;;
  esac
}
