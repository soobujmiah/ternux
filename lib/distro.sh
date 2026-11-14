# =============================================================================
# Ternux named guest management (desktop profiles and generic OCI guests)
# =============================================================================
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"

_tnx_distro_installed() { tnx_proot_container_installed "$1"; }

tnx_cmd_distro() {
  local action="${1:-list}" name installed marker user
  case "$action" in
    list|ls)
      [ "$#" -le 1 ] || { tnx_fail "Usage: ternux distro list"; return 2; }
      printf 'Installed PRoot guests (each Ternux desktop uses its own tagged X11 display):\n'
      local found=0
      while IFS= read -r name; do
        [ -n "$name" ] || continue
        found=1
        if tnx_distro_known "$name"; then
          if tnx_distro_desktop_ready "$name"; then
            if tnx_distro_verified "$name"; then
              if [ "$name" = alpine ]; then marker='Ternux v2-qualified; Ctrl+Space event caveat'; else marker='Ternux v2-qualified; device evidence recorded'; fi
            else marker='Ternux desktop ready; not device verified'; fi
          else marker='Ternux recipe available; run tx install --distro NAME'; fi
        else
          marker='shell/image only; no Ternux desktop recipe'
        fi
        printf '  %-24s %s\n' "$name" "$marker"
      done < <(proot-distro list --quiet 2>/dev/null || true)
      [ "$found" -eq 1 ] || printf '  (none)\n'
      printf "\nTernux desktop: tx install --distro NAME | tx install --distros debian,ubuntu\nFind images:    tx distro search QUERY\nGeneric image:  tx distro image-install IMAGE[:TAG] [NAME]\nShell:          tx distro shell NAME | tx distro root NAME | tx distro exec NAME -- COMMAND\nShortcuts:      db/dbr/dbroot, ub/ubr/ubroot, alp/alpr/alproot (user/root)\n"
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
      tnx_distro_known "$name" || { tnx_fail "No Ternux desktop recipe for '$name'. Use 'tx distro image-install IMAGE[:TAG] [NAME]' for a generic PRoot guest."; return 2; }
      if ! declare -F tnx_install >/dev/null 2>&1; then . "$(dirname "${BASH_SOURCE[0]}")/phases.sh"; fi
      tnx_install --distro "$name"
      ;;
    uninstall|remove)
      [ "$#" -ge 2 ] && [ "$#" -le 3 ] || { tnx_fail "Usage: tx distro uninstall NAME [--yes]"; return 2; }
      name="$2"
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
