# =============================================================================
#  ternux — scoped component removal
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah) — MIT License
#  https://github.com/soobujmiah/ternux
# =============================================================================

# shellcheck source=lib/core.sh
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"

_tnx_uninstall_usage() {
  cat <<'EOF'
Usage: ternux uninstall [session|launcher|state|container|all] [--yes]

  session    Stop desktop services and remove stale sockets
  launcher   Remove ~/x.sh and ternux shell aliases
  state      Remove ternux logs and state (not the Debian container)
  container  Delete the Debian PRoot container
  all        Perform all four scoped actions above

Numeric aliases 1..5 select the same actions in that order.
'all' does not remove Termux packages or the installed ternux CLI/libraries.
Container and all require confirmation unless --yes is explicit.
EOF
}

_tnx_uninstall_confirm() {
  local prompt="$1" answer=""
  [ "${TERNUX_YES:-0}" = "1" ] && return 0
  if [ -r /dev/tty ]; then
    printf "${TNX_CY}?${TNX_C0} %s [y/N]: " "$prompt" >/dev/tty
    IFS= read -r answer </dev/tty || return 1
    case "$answer" in [Yy]|[Yy][Ee][Ss]) return 0 ;; esac
  fi
  return 1
}

_tnx_uninstall_stop() {
  # Stop only ternux session processes. In particular, do not broadly kill
  # D-Bus daemons that may belong to another PRoot session.
  pkill -f termux-x11 2>/dev/null || true
  pkill -f virgl_test_server_android 2>/dev/null || true
  pkill -f virgl_test_server 2>/dev/null || true
  if tnx_has_cmd pulseaudio; then
    pulseaudio --kill 2>/dev/null || pkill -KILL -x pulseaudio 2>/dev/null || true
  fi
  local tmp="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
  rm -f "$tmp/.X11-unix/X"* "$tmp/.X"*"-lock" "$tmp/pulse-socket" \
        "$tmp"/.pulse-*/native 2>/dev/null || true
  tnx_has_cmd termux-wake-unlock && termux-wake-unlock 2>/dev/null || true
  tnx_ok "Desktop services stopped and stale sockets removed"
}

_tnx_uninstall_launcher() {
  rm -f "$HOME/x.sh"
  local rc_file tmp_file starts ends rc=0
  for rc_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -L "$rc_file" ] || { [ -e "$rc_file" ] && [ ! -f "$rc_file" ]; }; then
      tnx_fail "Refusing to replace symlink or non-regular startup file: $rc_file"
      rc=1
      continue
    fi
    [ -f "$rc_file" ] || continue
    starts="$(grep -cxF '# ==== TERNUX ALIASES ====' "$rc_file" 2>/dev/null || true)"
    ends="$(grep -cxF '# ==== END TERNUX ALIASES ====' "$rc_file" 2>/dev/null || true)"
    if [ "$starts" != "$ends" ] || [ "$starts" -gt 1 ] 2>/dev/null; then
      tnx_fail "Refusing to rewrite malformed alias markers in $rc_file"
      rc=1
      continue
    fi
    [ "$starts" -gt 0 ] 2>/dev/null || continue
    if ! awk '
      /^# ==== TERNUX ALIASES ====$/ {
        if (inside || seen_start) bad=1
        inside=1; seen_start=1; next
      }
      /^# ==== END TERNUX ALIASES ====$/ {
        if (!inside || seen_end) bad=1
        inside=0; seen_end=1; next
      }
      END { exit(bad || inside || !seen_start || !seen_end) }
    ' "$rc_file" >/dev/null; then
      tnx_fail "Refusing to rewrite malformed alias marker order in $rc_file"
      rc=1
      continue
    fi

    tmp_file="$(mktemp "${rc_file}.ternux-uninstall.XXXXXX")" || { rc=1; continue; }
    if awk '
      /^# ==== TERNUX ALIASES ====$/ { skip=1; next }
      /^# ==== END TERNUX ALIASES ====$/ { skip=0; next }
      !skip { print }
    ' "$rc_file" > "$tmp_file" &&
       { chmod --reference="$rc_file" "$tmp_file" 2>/dev/null || true; } &&
       mv -f "$tmp_file" "$rc_file"; then
      :
    else
      rm -f "$tmp_file"
      tnx_fail "Could not update $rc_file"
      rc=1
    fi
  done
  [ "$rc" -eq 0 ] && tnx_ok "Launcher and ternux alias blocks removed"
  return "$rc"
}

_tnx_uninstall_state() {
  rm -rf "$TERNUX_STATE_DIR"
  rm -f "$HOME/.ternux-state"
  tnx_ok "ternux state and logs removed"
}

_tnx_uninstall_container() {
  if ! tnx_has_cmd proot-distro; then
    tnx_info "proot-distro is not installed; no Debian container was removed"
    return 0
  fi
  if ! tnx_debian_installed; then
    tnx_info "No installed Debian container found"
    return 0
  fi
  if ! _tnx_uninstall_confirm "Permanently delete the Debian container and its files?"; then
    tnx_warn "Container removal cancelled"
    return 1
  fi
  proot-distro remove debian || { tnx_fail "Could not remove the Debian container"; return 1; }
  tnx_ok "Debian container removed"
}

tnx_cmd_uninstall() {
  local action="" arg=""
  for arg in "$@"; do
    case "$arg" in
      --yes|-y) TERNUX_YES=1 ;;
      --help|-h) _tnx_uninstall_usage; return 0 ;;
      *) [ -z "$action" ] && action="$arg" || { tnx_fail "Unexpected argument: $arg"; return 2; } ;;
    esac
  done

  if [ -z "$action" ]; then
    if [ -r /dev/tty ]; then
      cat >/dev/tty <<'EOF'

ternux uninstall
  1) Stop desktop services
  2) Remove launcher and aliases
  3) Remove state and logs
  4) Delete Debian container
  5) Remove all ternux-managed components above
  0) Cancel
EOF
      printf "Selection: " >/dev/tty
      IFS= read -r action </dev/tty || return 1
    else
      _tnx_uninstall_usage
      tnx_fail "Choose an action explicitly in a non-interactive shell."
      return 2
    fi
  fi

  case "$action" in
    0|cancel) tnx_info "Cancelled" ;;
    1|session) _tnx_uninstall_stop ;;
    2|launcher) _tnx_uninstall_launcher ;;
    3|state) _tnx_uninstall_state ;;
    4|container) _tnx_uninstall_stop; _tnx_uninstall_container ;;
    5|all)
      if ! _tnx_uninstall_confirm "Remove the session, launcher, state, and Debian container?"; then
        tnx_warn "Removal cancelled"
        return 1
      fi
      # The outer confirmation covers the destructive container step. Keep
      # attempting independent scopes, but do not hide a partial failure.
      TERNUX_YES=1
      local rc=0
      _tnx_uninstall_stop || rc=1
      _tnx_uninstall_launcher || rc=1
      _tnx_uninstall_container || rc=1
      _tnx_uninstall_state || rc=1
      return "$rc"
      ;;
    *) _tnx_uninstall_usage; tnx_fail "Unknown uninstall action: $action"; return 2 ;;
  esac
}
