# =============================================================================
#  ternux — bash completion
#  Source this file in ~/.bashrc:  source /path/to/ternux-completion.bash
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah) — MIT License
#  https://github.com/soobujmiah/ternux
# =============================================================================

_ternux_completions() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prev="${COMP_WORDS[COMP_CWORD-1]}"
  local cmds="install start stop restart doctor repair verify benchmark profile backend info state logs update uninstall"
  local global_opts="--help -h --json --verbose --quiet --version -V"

  # Top-level: suggest commands and global options
  if [ "$COMP_CWORD" -eq 1 ]; then
    COMPREPLY=($(compgen -W "$cmds $global_opts" -- "$cur"))
    return 0
  fi

  local cmd="${COMP_WORDS[1]}"

  # Command-specific completions
  case "$cmd" in
    profile)
      if [ "$COMP_CWORD" -eq 2 ]; then
        COMPREPLY=($(compgen -W "show save load list compare --json --help" -- "$cur"))
      elif [ "$COMP_CWORD" -eq 3 ]; then
        case "${COMP_WORDS[2]}" in
          save|load)
            # Suggest saved profile names
            local profiles_dir="${TERNUX_STATE_DIR:-$HOME/.local/share/ternux}/profiles"
            [ -d "$profiles_dir" ] && COMPREPLY=($(compgen -W "$(ls "$profiles_dir" 2>/dev/null)" -- "$cur"))
            ;;
        esac
      fi
      ;;
    backend)
      if [ "$COMP_CWORD" -eq 2 ]; then
        COMPREPLY=($(compgen -W "show set detect --json --help" -- "$cur"))
      elif [ "$COMP_CWORD" -eq 3 ] && [ "${COMP_WORDS[2]}" = "set" ]; then
        COMPREPLY=($(compgen -W "auto zink virgl" -- "$cur"))
      fi
      ;;
    logs)
      if [ "$COMP_CWORD" -eq 2 ]; then
        COMPREPLY=($(compgen -W "show tail clear list --help" -- "$cur"))
      fi
      ;;
    update)
      if [ "$COMP_CWORD" -eq 2 ]; then
        COMPREPLY=($(compgen -W "check --help" -- "$cur"))
      fi
      ;;
    install)
      if [ "$COMP_CWORD" -eq 2 ]; then
        COMPREPLY=($(compgen -W "--yes --user --locale --backend --zsh --with-dev --with-llm --with-network --with-media --with-blender --all --resume --help" -- "$cur"))
      fi
      ;;
    doctor|verify|info|state)
      COMPREPLY=($(compgen -W "--json --help" -- "$cur"))
      ;;
    start|stop|restart|repair|uninstall)
      COMPREPLY=($(compgen -W "--help" -- "$cur"))
      ;;
  esac
}

complete -F _ternux_completions ternux