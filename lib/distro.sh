# =============================================================================
# Ternux named guest management (desktop profiles and generic OCI guests)
# =============================================================================
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"

_tnx_distro_installed() { tnx_proot_container_installed "$1"; }

tnx_cmd_distro() {
  local action="${1:-list}" name installed marker
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
            if tnx_distro_verified "$name"; then marker='Ternux desktop ready; device verified'; else marker='Ternux desktop ready; not device verified'; fi
          else marker='Ternux recipe available; run tx install --distro NAME'; fi
        else
          marker='shell/image only; no Ternux desktop recipe'
        fi
        printf '  %-24s %s\n' "$name" "$marker"
      done < <(proot-distro list --quiet 2>/dev/null || true)
      [ "$found" -eq 1 ] || printf '  (none)\n'
      printf "\nTernux desktop: tx install --distro NAME | tx install --distros debian,ubuntu\nFind images:    tx distro search QUERY\nGeneric image:  tx distro image-install IMAGE[:TAG] [NAME]\nShell:          tx distro shell NAME | tx distro exec NAME -- COMMAND\n"
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
    image-install)
      [ "$#" -ge 2 ] && [ "$#" -le 3 ] || { tnx_fail "Usage: ternux distro image-install IMAGE[:TAG] [NAME]"; return 2; }
      local image="$2" alias_name="${3:-}"
      [[ "$image" =~ ^[a-zA-Z0-9._:/@-]+$ ]] || { tnx_fail "Image reference contains unsupported characters."; return 2; }
      if [ -n "$alias_name" ]; then
        [[ "$alias_name" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]] || { tnx_fail "Guest name must start with a letter or number and use only letters, numbers, dot, underscore or hyphen."; return 2; }
        proot-distro install --name "$alias_name" "$image"
      else
        proot-distro install "$image"
      fi
      ;;
    shell|exec)
      [ "$#" -ge 2 ] || { tnx_fail "Usage: ternux distro $action NAME [-- COMMAND ...]"; return 2; }
      name="$2"; shift 2
      [[ "$name" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]] || { tnx_fail "Invalid guest name '$name'."; return 2; }
      _tnx_distro_installed "$name" || { tnx_fail "Guest '$name' is not installed."; return 1; }
      unset _TNX_DISTRO
      export TERNUX_DISTRO="$name"
      if [ "$action" = shell ]; then
        [ "$#" -eq 0 ] || { tnx_fail "Usage: ternux distro shell NAME"; return 2; }
        tnx_guest_login
      else
        [ "${1:-}" = -- ] && shift || { tnx_fail "Use '--' before a command."; return 2; }
        [ "$#" -gt 0 ] || { tnx_fail "Usage: ternux distro exec NAME -- COMMAND [ARG ...]"; return 2; }
        tnx_guest_login -- "$@"
      fi
      ;;
    *)
      tnx_fail "Usage: tx distro [list|search QUERY|install NAME|image-install IMAGE [NAME]|shell NAME|exec NAME -- COMMAND]"; return 2 ;;
  esac
}
