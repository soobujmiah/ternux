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
Usage: tx uninstall [session|launcher|state|container|host-cli|all] [--yes]
       tx distro uninstall NAME [--yes]
       ternux uninstall [session|launcher|state|container|host-cli|all] [--yes]

  session    Stop the Ternux-owned desktop session and remove its state markers
  launcher   Remove ~/x.sh and ternux shell aliases
  state      Remove Ternux state, logs and stopped manager socket state
  container  Delete the selected registered Ternux guest
  host-cli   Remove the APT-managed or source-installed Termux CLI
  all        Remove Ternux-managed guests, desktop, state, caches and host CLI

Numeric aliases 1..6 select the same actions in that order.
Termux itself, shared Termux packages, Android shared storage and unregistered
PRoot guests are kept. Container and all require confirmation unless --yes.
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
  tnx_cmd_stop --all
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

_tnx_uninstall_stale_asset_stages() {
  local prefix="${PREFIX:-/data/data/com.termux/files/usr}"
  local temp_root="${TMPDIR:-$prefix/tmp}" stage removed=0
  [ -d "$temp_root" ] && [ ! -L "$temp_root" ] || return 0
  for stage in "$temp_root"/ternux-assets.*; do
    [ -d "$stage" ] && [ ! -L "$stage" ] || continue
    [ -d "$stage/icons/Ternux" ] && [ -d "$stage/themes/Ternux" ] && [ -d "$stage/wallpapers" ] || continue
    rm -rf -- "$stage" || return 1
    removed=$((removed + 1))
  done
  [ "$removed" -eq 0 ] || tnx_ok "Removed $removed stale Ternux asset staging director(y/ies)"
}

_tnx_uninstall_manager_runtime() {
  local prefix="${PREFIX:-/data/data/com.termux/files/usr}"
  local control="$prefix/var/lib/ternux/control"
  [ -e "$control" ] || [ -L "$control" ] || return 0
  if ! command -v python3 >/dev/null 2>&1; then
    tnx_warn "Preserving manager socket state because python3 is unavailable: $control"
    return 1
  fi
  if ! python3 - "$control" "$prefix" <<'PY'
import errno
import fcntl
import os
import socket
import stat
import sys
from pathlib import Path

control = Path(sys.argv[1])
prefix = Path(sys.argv[2])
expected = prefix / "var/lib/ternux/control"
if control != expected or control.is_symlink() or not control.is_dir():
    raise SystemExit("refusing an unexpected or symlinked manager state directory")
if control.stat().st_uid != os.getuid():
    raise SystemExit("manager state directory is not owned by this Termux user")

lock_path = control / "manager.lock"
socket_path = control / "manager.sock"
lock_fd = None
try:
    if lock_path.is_symlink():
        raise SystemExit("preserving a symlinked manager lock")
    if lock_path.exists():
        lock_fd = os.open(lock_path, os.O_RDWR | getattr(os, "O_NOFOLLOW", 0))
        lock_stat = os.fstat(lock_fd)
        if not stat.S_ISREG(lock_stat.st_mode) or lock_stat.st_uid != os.getuid():
            raise SystemExit("preserving an unexpected manager lock file")
        try:
            fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise SystemExit("manager service is still running; stop it before uninstall")

    if socket_path.is_symlink():
        raise SystemExit("preserving a symlinked manager socket path")
    if socket_path.exists():
        socket_stat = socket_path.lstat()
        if not stat.S_ISSOCK(socket_stat.st_mode):
            raise SystemExit("preserving a non-socket manager path")
        probe = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        try:
            probe.settimeout(0.25)
            probe.connect(str(socket_path))
        except OSError as exc:
            if exc.errno not in (errno.ECONNREFUSED, errno.ENOENT):
                raise SystemExit("cannot prove manager socket is stale; preserving it")
            current = socket_path.lstat()
            if (current.st_dev, current.st_ino) != (socket_stat.st_dev, socket_stat.st_ino):
                raise SystemExit("manager socket changed during uninstall; preserving it")
            socket_path.unlink()
        else:
            raise SystemExit("manager service is still accepting connections; stop it before uninstall")
        finally:
            probe.close()

    if lock_fd is not None:
        current_lock = lock_path.lstat()
        if (current_lock.st_dev, current_lock.st_ino) != (lock_stat.st_dev, lock_stat.st_ino):
            raise SystemExit("manager lock changed during uninstall; preserving it")
        lock_path.unlink()
    try:
        control.rmdir()
    except OSError:
        if any(control.iterdir()):
            raise SystemExit("preserving unrelated files in manager state directory")
        raise
finally:
    if lock_fd is not None:
        os.close(lock_fd)
PY
  then
    tnx_warn "Could not safely remove Ternux manager runtime state at $control"
    return 1
  fi
  return 0
}

_tnx_uninstall_state() {
  local prefix="${PREFIX:-/data/data/com.termux/files/usr}"
  local log_dir="${TERNUX_LOG_DIR:-${TMPDIR:-$prefix/tmp}/ternux}"
  local state_dir="${TERNUX_STATE_DIR:-$HOME/.local/share/ternux}"
  local rc=0
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
  _tnx_uninstall_manager_runtime || rc=1
  if [ "$rc" -eq 0 ]; then tnx_ok "Ternux state and logs removed"
  else tnx_warn "Some Ternux runtime state was preserved for safety"; fi
  return "$rc"
}

_tnx_uninstall_host_cli() {
  local prefix="${PREFIX:-/data/data/com.termux/files/usr}"
  local bin="$prefix/bin/ternux" tx="$prefix/bin/tx" lib="$prefix/lib/ternux"
  local completion="$prefix/share/bash-completion/completions/ternux"
  local docs="$prefix/share/doc/ternux"
  local status="" shortcut

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

  for shortcut in db dbr dbroot ub ubr ubroot alp alpr alproot; do
    if [ -e "$prefix/bin/$shortcut" ] || [ -L "$prefix/bin/$shortcut" ]; then
      if [ -L "$prefix/bin/$shortcut" ] || [ ! -f "$prefix/bin/$shortcut" ] ||
         ! grep -qx '# TERNUX_GUEST_SHELL_SHORTCUT=1' "$prefix/bin/$shortcut"; then
        tnx_warn "Preserving unrecognized guest shell command: $prefix/bin/$shortcut"
      else
        rm -f -- "$prefix/bin/$shortcut"
      fi
    fi
  done

  # Compatibility with source-installed v1/v2 setups. Refuse symlinks and
  # only remove a module tree whose own core identifies it as Ternux.
  if [ -e "$bin" ] || [ -L "$bin" ]; then
    if [ -L "$bin" ] || [ ! -f "$bin" ] || ! grep -q 'https://github.com/soobujmiah/ternux' "$bin"; then
      tnx_fail "Refusing to remove an unrecognized host CLI at $bin"
      return 1
    fi
    rm -f "$bin"
  fi
  if [ -e "$tx" ] || [ -L "$tx" ]; then
    if [ -L "$tx" ] || [ ! -f "$tx" ] || ! grep -q '^# Ternux short command entrypoint\.' "$tx"; then
      tnx_fail "Refusing to remove an unrecognized short command at $tx"
      return 1
    fi
    rm -f "$tx"
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

_tnx_uninstall_remove_guest() {
  local name="$1"
  [[ "$name" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]] || { tnx_warn "Skipping invalid managed guest name: $name"; return 1; }
  local state_dir="${TERNUX_STATE_DIR:-$HOME/.local/share/ternux}" marker_dir marker
  marker_dir="$state_dir/managed-guests"
  marker="$marker_dir/$name"
  if ! tnx_proot_container_installed "$name"; then
    if [ -e "$marker" ] || [ -L "$marker" ]; then
      [ ! -L "$state_dir" ] && [ ! -L "$marker_dir" ] && [ ! -L "$marker" ] && [ -f "$marker" ] || { tnx_fail "Refusing unsafe Ternux guest registry path for '$name'."; return 1; }
      rm -f -- "$marker" || { tnx_fail "Could not clear the stale registry entry for '$name'."; return 1; }
    fi
    _tnx_uninstall_reap_stale_sessions
    tnx_info "Managed guest '$name' is already absent"
    return 0
  fi
  if proot-distro remove "$name"; then
    if [ -e "$marker" ] || [ -L "$marker" ]; then
      [ ! -L "$state_dir" ] && [ ! -L "$marker_dir" ] && [ ! -L "$marker" ] && [ -f "$marker" ] || { tnx_fail "Guest '$name' was removed, but its registry path is unsafe and needs manual review."; return 1; }
      rm -f -- "$marker" || { tnx_fail "Guest '$name' was removed, but its registry entry could not be cleared."; return 1; }
    fi
    _tnx_uninstall_reap_stale_sessions
    tnx_ok "Managed guest '$name' removed"
    return 0
  fi
  tnx_fail "Could not remove managed guest '$name'"
  return 1
}

# PRoot-Distro owns the shared login-session registry. Its `ps` command checks
# the session's inherited file lock (rather than trusting a recyclable PID) and
# prunes only sessions that no process still holds. Keep that lifecycle logic
# with PRoot-Distro instead of editing its shared metadata directly.
_tnx_uninstall_reap_stale_sessions() {
  tnx_has_cmd proot-distro || return 0
  proot-distro ps >/dev/null 2>&1 || true
  return 0
}

_tnx_uninstall_guest_is_registered() {
  local target="$1" state_dir="${TERNUX_STATE_DIR:-$HOME/.local/share/ternux}"
  local profile="$state_dir/distros/$target/profile" marker_dir="$state_dir/managed-guests" marker="$state_dir/managed-guests/$target"
  if tnx_distro_known "$target" && [ ! -L "$state_dir" ] && [ ! -L "$state_dir/distros" ] && [ ! -L "$profile" ] && [ -f "$profile" ] && grep -Eq '^status=(installing|incomplete|ready)$' "$profile"; then
    return 0
  fi
  [ ! -L "$state_dir" ] && [ ! -L "$marker_dir" ] && [ ! -L "$marker" ] && [ -f "$marker" ] || return 1
  local image
  IFS= read -r image < "$marker" || return 1
  [[ "$image" =~ ^[a-zA-Z0-9._:/@-]+$ ]]
}

_tnx_uninstall_container() {
  local target="${1:-$(tnx_distro)}"
  [[ "$target" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]] || { tnx_fail "Invalid guest name '$target'."; return 2; }
  if ! tnx_has_cmd proot-distro; then
    tnx_info "proot-distro is not installed; no guest container was removed"
    return 0
  fi
  if ! tnx_proot_container_installed "$target"; then
    if _tnx_uninstall_guest_is_registered "$target"; then
      _tnx_uninstall_remove_guest "$target"
      return $?
    fi
    tnx_info "Guest '$target' is not installed"
    return 0
  fi
  if ! _tnx_uninstall_guest_is_registered "$target"; then
    tnx_fail "Refusing to remove unregistered PRoot guest '$target'. Use Ternux-managed install/uninstall so ownership can be verified."
    return 1
  fi
  if ! _tnx_uninstall_confirm "Permanently delete the registered Ternux guest '$target' and its files?"; then
    tnx_warn "Guest removal cancelled"
    return 1
  fi
  if tnx_distro_known "$target"; then
    tnx_cmd_stop "$target" || { tnx_fail "Could not stop the selected Ternux desktop '$target'; guest files were preserved."; return 1; }
  fi
  _tnx_uninstall_remove_guest "$target"
}

_tnx_uninstall_all_managed_guests() {
  local name rc=0 marker_dir="${TERNUX_STATE_DIR:-$HOME/.local/share/ternux}/managed-guests"
  local -a guests=()
  local known
  for known in $TERNUX_DISTRO_KNOWN; do
    [ -f "$(tnx_distro_state_dir "$known")/profile" ] && guests+=("$known")
  done
  # Include the old single-profile install only when Ternux's persistent
  # installation state explicitly names that distro (or carries its legacy
  # state file). Never treat the default distro name alone as ownership.
  known="$(tnx_state_get distro 2>/dev/null || true)"
  if [ -n "$known" ] && { [ -f "$TERNUX_STATE_DIR/state" ] || [ -f "$HOME/.ternux-state" ]; } && tnx_proot_container_installed "$known"; then
    case " ${guests[*]} " in *" $known "*) ;; *) guests+=("$known") ;; esac
  fi
  # Generic OCI guests are managed only when Ternux recorded their explicit
  # image-install marker. This avoids deleting unrelated proot-distro guests.
  if [ -d "$marker_dir" ] && [ ! -L "$marker_dir" ]; then
    while IFS= read -r -d '' marker; do
      name="${marker##*/}"
      case " ${guests[*]} " in *" $name "*) ;; *) guests+=("$name") ;; esac
    done < <(find "$marker_dir" -mindepth 1 -maxdepth 1 -type f -print0 2>/dev/null)
  fi
  if [ "${#guests[@]}" -eq 0 ]; then
    tnx_info "No Ternux-managed guest containers are installed"
    return 0
  fi
  for name in "${guests[@]}"; do _tnx_uninstall_remove_guest "$name" || rc=1; done
  return "$rc"
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
  4) Delete selected Ternux guest
  5) Remove all Ternux-managed components and guests, including its CLI
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
    4|container) _tnx_uninstall_container ;;
    5|all)
      if ! _tnx_uninstall_confirm "Remove Ternux, its Termux CLI, state, caches, and all Ternux-managed guest containers?"; then
        tnx_warn "Removal cancelled"
        return 1
      fi
      # The outer confirmation covers the destructive container step. Keep
      # attempting independent scopes, but do not hide a partial failure.
      TERNUX_YES=1
      local rc=0
      _tnx_uninstall_stop || rc=1
      _tnx_uninstall_launcher || rc=1
      if _tnx_uninstall_all_managed_guests; then
        _tnx_uninstall_stale_asset_stages || rc=1
        _tnx_uninstall_state || rc=1
        _tnx_uninstall_host_cli || rc=1
      else
        tnx_fail "Some managed guests remain; preserving Ternux state and CLI so cleanup can be retried."
        rc=1
      fi
      return "$rc"
      ;;
    6|host-cli) _tnx_uninstall_host_cli ;;
    *) _tnx_uninstall_usage; tnx_fail "Unknown uninstall action: $action"; return 2 ;;
  esac
}
