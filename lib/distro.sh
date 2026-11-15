# =============================================================================
# Ternux named guest management (desktop profiles and generic OCI guests)
# =============================================================================
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"

_tnx_distro_installed() { tnx_proot_container_installed "$1"; }

_tnx_distro_short_name() {
  case "$1" in
    debian) echo db ;; ubuntu) echo ub ;; kali) echo kali ;; alpine) echo alp ;;
    archlinux) echo archx ;; fedora) echo fed ;; opensuse) echo suse ;; void) echo vsh ;;
    artix) echo art ;; chimera) echo chim ;; deepin) echo deep ;; manjaro) echo manj ;;
    pardus) echo par ;; rockylinux) echo rock ;; adelie) echo adel ;;
    *) echo - ;;
  esac
}

_tnx_distro_package_family() {
  tnx_distro_profile "$1" >/dev/null 2>&1 || { echo unknown; return; }
  printf '%s' "$TNX_DP_FAMILY"
}

_tnx_distro_overview() {
  [ "$#" -eq 0 ] || { tnx_fail "Usage: tx distro"; return 2; }
  local count=0 ready=0 name
  for name in $TERNUX_DISTRO_KNOWN; do
    count=$((count + 1))
  done
  local -a installed_guests=()
  if tnx_has_cmd proot-distro; then
    while IFS= read -r name; do [ -n "$name" ] && installed_guests+=("$name"); done < <(proot-distro list --quiet 2>/dev/null || true)
  fi
  for name in "${installed_guests[@]}"; do tnx_distro_known "$name" && ready=$((ready + 1)); done
  tnx_header "Ternux Distro Management"
  printf '  Managed desktop profiles: %s\n  Installed named profiles: %s\n\n' "$count" "$ready"
  printf '  tx distro list                         Show all managed profiles and install state\n'
  printf '  tx distro search QUERY                 Search available PRoot images\n'
  printf '  tx distro install NAME                 Install a managed desktop profile\n'
  printf '  tx distro uninstall NAME [--yes]       Remove a managed guest\n'
  printf '  tx distro image-install IMAGE [NAME]   Add a shell-only OCI guest\n'
  printf '  tx distro shell|root NAME [-- COMMAND] Open a guest shell or run a command\n'
  printf '  tx distro exec NAME -- COMMAND         Run one command in a guest\n\n'
  printf '  Desktop lifecycle: tx start NAME... | tx stop NAME | tx restart NAME\n'
  printf '  Default display order: Debian :1, Ubuntu :2, Kali :3, Alpine :4, then :5–:15.\n'
  printf '  GPU route is selected per device; software rendering is reported by tx info.\n'
  printf '  Catalog: %s\n' "$(printf '%s\n' "$TERNUX_DISTRO_KNOWN" | tr ' ' ',')"
  printf '  Details: tx distro list | tx -h | tx guides\n'
}

_tnx_distro_catalog() {
  [ "$#" -eq 0 ] || { tnx_fail "Usage: tx distro list"; return 2; }
  local name short family backend state saved_backend installed_count=0 profile_count=0
  local -a installed_guests=()
  if tnx_has_cmd proot-distro; then
    while IFS= read -r name; do [ -n "$name" ] && installed_guests+=("$name"); done < <(proot-distro list --quiet 2>/dev/null || true)
  fi
  tnx_header "Managed Distro Catalog"
  printf '  %-13s %-6s %-4s %-7s %-7s %s\n' "PROFILE" "SHORT" "X11" "PACKAGE" "GPU" "INSTALL STATE"
  printf '  %-13s %-6s %-4s %-7s %-7s %s\n' '-------------' '------' '----' '-------' '-------' '---------------------'
  for name in $TERNUX_DISTRO_KNOWN; do
    profile_count=$((profile_count + 1))
    short="$(_tnx_distro_short_name "$name")"
    family="$(_tnx_distro_package_family "$name")"
    backend="$(tnx_gpu_backend_auto "$name")"
    state='not installed'
    for saved_backend in "${installed_guests[@]}"; do
      if [ "$saved_backend" = "$name" ]; then
        installed_count=$((installed_count + 1))
        if tnx_distro_desktop_ready "$name"; then state='installed · ready'; else state='installed · setup needed'; fi
        break
      fi
    done
    tnx_distro_verified "$name" && state="$state · qualified"
    printf '  %-13s %-6s :%-3s %-7s %-7s %s\n' "$name" "$short" "$(tnx_distro_target_display "$name")" "${family^^}" "$backend" "$state"
  done
  printf '\n  Profiles: %s · installed: %s · device-qualified: %s\n' "$profile_count" "$installed_count" "${TERNUX_DISTRO_VERIFIED// /, }"
  printf '  Install: tx install --distro NAME | tx install --distros debian,ubuntu,kali,alpine\n'
  printf '  Short names work with tx start, tx stop, tx distro shell, and related commands.\n'
  printf '  Generic OCI guests are listed separately below; they do not get a desktop recipe.\n'
  local generic_count=0
  for name in "${installed_guests[@]}"; do tnx_distro_known "$name" || generic_count=$((generic_count + 1)); done
  if [ "$generic_count" -gt 0 ]; then
    printf '\n  Other installed OCI guests (shell/image only):\n'
    for name in "${installed_guests[@]}"; do tnx_distro_known "$name" || printf '    %s\n' "$name"; done
  fi
}

_tnx_distro_list_row() {
  local name="$1" marker
  if tnx_distro_desktop_ready "$name"; then
    if tnx_distro_verified "$name"; then
      if [ "$name" = alpine ]; then marker='Ternux v2-qualified; Ctrl+Space event caveat'; else marker='Ternux v2-qualified; device evidence recorded'; fi
    else marker='Ternux desktop ready; not device verified'; fi
  else marker='Ternux recipe available; run tx install --distro NAME'; fi
  printf '  %-24s %s\n' "$name" "$marker"
}

tnx_cmd_distro() {
  local action="${1:-overview}" name installed installed_name marker user found=0
  local -a installed_guests=()
  case "$action" in
    overview|info) _tnx_distro_overview "${@:2}" ;;
    list|ls)
      _tnx_distro_catalog "${@:2}"
      ;;
    search|find)
      [ "$#" -eq 2 ] && [ -n "$2" ] || { tnx_fail "Usage: tx distro search QUERY"; return 2; }
      tnx_has_cmd proot-distro || { tnx_fail "proot-distro is missing; install the Ternux host packages first."; return 1; }
      # PRoot-Distro requires a query; pass it as one argument, never eval it.
      proot-distro search "$2"
      ;;
    install)
      [ "$#" -eq 2 ] || { tnx_fail "Usage: ternux distro install NAME"; return 2; }
      name="$2"
      name="$(tnx_distro_canonical "$name")"
      tnx_distro_known "$name" || { tnx_fail "No Ternux desktop recipe for '$name'. Use 'tx distro image-install IMAGE[:TAG] [NAME]' for a generic PRoot guest."; return 2; }
      if ! declare -F tnx_install >/dev/null 2>&1; then . "$(dirname "${BASH_SOURCE[0]}")/phases.sh"; fi
      tnx_install --distro "$name"
      ;;
    uninstall|remove)
      [ "$#" -ge 2 ] && [ "$#" -le 3 ] || { tnx_fail "Usage: tx distro uninstall NAME [--yes]"; return 2; }
      name="$2"
      name="$(tnx_distro_canonical "$name")"
      [[ "$name" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]] || { tnx_fail "Invalid guest name '$name'."; return 2; }
      if [ "$#" -eq 3 ]; then
        [ "$3" = --yes ] || { tnx_fail "Unexpected argument: $3"; return 2; }
        TERNUX_YES=1
      fi
      if ! declare -F _tnx_uninstall_container >/dev/null 2>&1; then . "$(dirname "${BASH_SOURCE[0]}")/uninstall.sh"; fi
      _tnx_uninstall_container "$name"
      ;;
    image-install)
      [ "$#" -ge 2 ] && [ "$#" -le 3 ] || { tnx_fail "Usage: ternux distro image-install IMAGE[:TAG] [NAME]"; return 2; }
      local image="$2" alias_name="${3:-}" marker_dir marker
      [[ "$image" =~ ^[a-zA-Z0-9._:/@-]+$ ]] || { tnx_fail "Image reference contains unsupported characters."; return 2; }
      if [ -z "$alias_name" ]; then
        alias_name="${image##*/}"
        alias_name="${alias_name%%:*}"
        alias_name="$(printf '%s' "$alias_name" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9._-' '-')"
        alias_name="${alias_name#-}"; alias_name="${alias_name%-}"
      fi
      [[ "$alias_name" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]] || { tnx_fail "Guest name must start with a letter or number and use only letters, numbers, dot, underscore or hyphen."; return 2; }
      _tnx_distro_installed "$alias_name" && { tnx_fail "Guest '$alias_name' already exists; choose another name."; return 1; }
      marker_dir="${TERNUX_STATE_DIR:-$HOME/.local/share/ternux}/managed-guests"
      [ ! -L "$marker_dir" ] || { tnx_fail "Refusing symlinked Ternux guest registry."; return 1; }
      mkdir -p "$marker_dir" || { tnx_fail "Could not create the Ternux guest registry."; return 1; }
      marker="$marker_dir/$alias_name"
      [ ! -e "$marker" ] && [ ! -L "$marker" ] || { tnx_fail "A Ternux guest registry entry already exists for '$alias_name'."; return 1; }
      (umask 077; printf '%s\n' "$image" > "$marker") || { tnx_fail "Could not register guest '$alias_name' for uninstall."; return 1; }
      proot-distro install --name "$alias_name" "$image" || { tnx_warn "Guest install failed or was interrupted; its registry entry is kept so tx uninstall can clean up a partial container."; return 1; }
      tnx_ok "Generic guest '$alias_name' installed and registered for tx uninstall."
      ;;
    shell|root|exec)
      [ "$#" -ge 2 ] || { tnx_fail "Usage: ternux distro $action NAME [-- COMMAND ...]"; return 2; }
      name="$2"; shift 2
      name="$(tnx_distro_canonical "$name")"
      [[ "$name" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]] || { tnx_fail "Invalid guest name '$name'."; return 2; }
      _tnx_distro_installed "$name" || { tnx_fail "Guest '$name' is not installed."; return 1; }
      unset _TNX_DISTRO
      export TERNUX_DISTRO="$name"
      if [ "$action" = shell ]; then
        if [ "$#" -gt 0 ]; then
          [ "${1:-}" = -- ] && shift || { tnx_fail "Use '--' before a guest command."; return 2; }
          [ "$#" -gt 0 ] || { tnx_fail "Usage: ternux distro shell NAME [-- COMMAND ...]"; return 2; }
        fi
        # Desktop profiles create a named unprivileged account. Make the
        # generic interactive shell honor that account too.
        user="$(tnx_distro_state_get "$name" user 2>/dev/null || true)"
        if [ -n "$user" ]; then
          if [ "$#" -gt 0 ]; then tnx_guest_login --user "$user" -- "$@"; else tnx_guest_login --user "$user"; fi
        else
          if [ "$#" -gt 0 ]; then tnx_guest_login -- "$@"; else tnx_guest_login; fi
        fi
      elif [ "$action" = root ]; then
        if [ "$#" -gt 0 ]; then
          [ "${1:-}" = -- ] && shift || { tnx_fail "Use '--' before a guest command."; return 2; }
          [ "$#" -gt 0 ] || { tnx_fail "Usage: ternux distro root NAME [-- COMMAND ...]"; return 2; }
          tnx_guest_login -- "$@"
        else
          tnx_guest_login
        fi
      else
        [ "${1:-}" = -- ] && shift || { tnx_fail "Use '--' before a command."; return 2; }
        [ "$#" -gt 0 ] || { tnx_fail "Usage: ternux distro exec NAME -- COMMAND [ARG ...]"; return 2; }
        tnx_guest_login -- "$@"
      fi
      ;;
    *)
      tnx_fail "Usage: tx distro [list|search QUERY|install NAME|uninstall NAME [--yes]|image-install IMAGE [NAME]|shell NAME [-- COMMAND]|root NAME [-- COMMAND]|exec NAME -- COMMAND]"; return 2 ;;
  esac
}
