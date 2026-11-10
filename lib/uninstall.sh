# =============================================================================
#  ternux — scoped component removal
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah)
#  Licensed under the Apache License, Version 2.0.
#  https://github.com/soobujmiah/ternux
# =============================================================================

# shellcheck source=lib/core.sh
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"
# shellcheck source=lib/desktop.sh
. "$(dirname "${BASH_SOURCE[0]}")/desktop.sh"

_tnx_uninstall_usage() {
  cat <<'EOF'
Usage: ternux uninstall [session|launcher|state|container|host-cli|all] [--yes]

  session    Stop the Ternux-owned desktop session and remove its state markers
  launcher   Remove ~/x.sh and ternux shell aliases
  state      Remove Ternux state and its logs (not the Debian container)
  container  Delete the selected Debian PRoot container
  host-cli   Remove the APT-managed or source-installed Termux CLI
  all        Remove Ternux desktop, guest, state, caches and host CLI

Numeric aliases 1..6 select the same actions in that order.
Termux itself and shared Termux packages are kept. Container and all require
confirmation unless --yes is explicit.
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
  # Reuse the ownership-checked lifecycle path. Shared Termux:X11 and PulseAudio
  # processes/sockets are not terminated or removed during uninstall.
  tnx_cmd_stop
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
  local prefix="${PREFIX:-/data/data/com.termux/files/usr}"
  local log_dir="${TERNUX_LOG_DIR:-${TMPDIR:-$prefix/tmp}/ternux}"
  local state_dir="${TERNUX_STATE_DIR:-$HOME/.local/share/ternux}"
  # The override is useful for tests and relocated installs, but never let a
  # malformed environment variable turn uninstall into an arbitrary rm -rf.
  case "$state_dir" in
    "$HOME/.local/share/ternux"|"$HOME/.local/share/ternux-"*)
      if [ -L "$state_dir" ]; then
        tnx_warn "Preserving symlink at Ternux state path: $state_dir"
      else
        rm -rf "$state_dir"
      fi
      ;;
    *) tnx_warn "Preserving custom Ternux state path outside the managed home locations: $state_dir" ;;
  esac
  rm -f "$HOME/.ternux-state"
  # Remove only the two log files Ternux owns. If the configured log directory
  # contains user files, keep it and leave those files untouched.
  if [ -d "$log_dir" ] && [ ! -L "$log_dir" ]; then
    rm -f "$log_dir/ternux.log" "$log_dir/install-stream.log"
    rmdir "$log_dir" 2>/dev/null || true
  fi
  # The camera and recorder use these host staging directories. Remove them
  # only when empty; an unfinished capture is user content and must survive.
  rmdir "$HOME/.cache/ternux-camera" "$HOME/.cache/ternux-recorder" 2>/dev/null || true
  tnx_ok "Ternux state and logs removed"
}

_tnx_uninstall_host_cli() {
  local prefix="${PREFIX:-/data/data/com.termux/files/usr}"
  local bin="$prefix/bin/ternux" lib="$prefix/lib/ternux"
  local completion="$prefix/share/bash-completion/completions/ternux"
  local docs="$prefix/share/doc/ternux"
  local status=""

  _tnx_uninstall_update_residue() {
    local path
    for path in "$prefix/lib/ternux-update-backups" "$prefix/lib/.ternux-update-journal" "$prefix/lib/.ternux-update-lock"; do
      [ -e "$path" ] || [ -L "$path" ] || continue
      if [ -L "$path" ]; then
        tnx_warn "Preserving symlink at Ternux update cleanup path: $path"
      elif [ -d "$path" ]; then
        rm -rf "$path"
      elif [ -f "$path" ]; then
        rm -f "$path"
      fi
    done
  }

  if command -v dpkg-query >/dev/null 2>&1; then
    status="$(dpkg-query -W -f='${Status}' ternux 2>/dev/null || true)"
  fi
  if [ "$status" = "install ok installed" ]; then
    if ! command -v dpkg >/dev/null 2>&1 || ! dpkg --remove ternux; then
      tnx_fail "Could not remove the APT-managed ternux package; inspect dpkg status."
      return 1
    fi
    _tnx_uninstall_update_residue
    tnx_ok "APT-managed ternux CLI and its package files removed"
    return 0
  fi

  # Compatibility with source-installed v1/v2 setups. Refuse symlinks and
  # only remove a module tree whose own core identifies it as Ternux.
  if [ -e "$bin" ] || [ -L "$bin" ]; then
    if [ -L "$bin" ] || [ ! -f "$bin" ] || ! grep -q 'https://github.com/soobujmiah/ternux' "$bin"; then
      tnx_fail "Refusing to remove an unrecognized host CLI at $bin"
      return 1
    fi
    rm -f "$bin"
  fi
  if [ -e "$lib" ] || [ -L "$lib" ]; then
    if [ -L "$lib" ] || [ ! -f "$lib/core.sh" ] || ! grep -q '^TERNUX_VERSION=' "$lib/core.sh"; then
      tnx_fail "Refusing to remove an unrecognized module tree at $lib"
      return 1
    fi
    rm -rf "$lib"
  fi
  if [ -f "$completion" ] && [ ! -L "$completion" ] && grep -q 'ternux' "$completion"; then rm -f "$completion"; fi
  if [ -d "$docs" ] && [ ! -L "$docs" ]; then rm -rf "$docs"; fi
  _tnx_uninstall_update_residue
  tnx_ok "Source-installed ternux CLI and recognized files removed"
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
  proot-distro remove "$(tnx_distro)" || { tnx_fail "Could not remove the Debian container"; return 1; }
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
  5) Remove all Ternux-managed components, including its CLI
  6) Remove only the Termux host CLI
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
      if ! _tnx_uninstall_confirm "Remove Ternux, its Termux CLI, state, caches, and Debian container?"; then
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
      _tnx_uninstall_host_cli || rc=1
      return "$rc"
      ;;
    6|host-cli) _tnx_uninstall_host_cli ;;
    *) _tnx_uninstall_usage; tnx_fail "Unknown uninstall action: $action"; return 2 ;;
  esac
}
