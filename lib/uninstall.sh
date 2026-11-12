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
       ternux uninstall [session|launcher|state|container|host-cli|all] [--yes]

  session    Stop the Ternux-owned desktop session and remove its state markers
  launcher   Remove ~/x.sh and ternux shell aliases
  state      Remove Ternux state and its logs (not guest containers)
  container  Delete the selected Ternux desktop guest
  host-cli   Remove the APT-managed or source-installed Termux CLI
  all        Remove Ternux-managed guests, desktop, state, caches and host CLI

Numeric aliases 1..6 select the same actions in that order.
Termux itself, shared Termux packages, Android shared storage and unrelated
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
  local bin="$prefix/bin/ternux" tx="$prefix/bin/tx" lib="$prefix/lib/ternux"
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
  if ! tnx_proot_container_installed "$name"; then
    _tnx_uninstall_prune_guest_sessions "$name"
    tnx_info "Managed guest '$name' is already absent"
    return 0
  fi
  if proot-distro remove "$name"; then
    _tnx_uninstall_prune_guest_sessions "$name"
    tnx_ok "Managed guest '$name' removed"
    return 0
  fi
  tnx_fail "Could not remove managed guest '$name'"
  return 1
}

# PRoot-Distro keeps per-login JSON under its shared data directory. A forced
# desktop stop or Android process kill can leave those records after a Ternux
# guest is deleted. Prune only regular records for that exact guest, and only
# when the recorded PID is gone or has clearly been reused since the session
# timestamp. Keep live session records and all unrelated distro records.
_tnx_uninstall_prune_guest_sessions() {
  local name="$1" prefix="${PREFIX:-/data/data/com.termux/files/usr}"
  local session_dir="$prefix/var/lib/proot-distro/sessions" file session_guest pid started now age elapsed removed=0
  [[ "$name" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]] || return 1
  [ -d "$session_dir" ] && [ ! -L "$session_dir" ] || return 0
  now="$(date +%s 2>/dev/null || true)"
  [[ "$now" =~ ^[0-9]+$ ]] || return 0
  for file in "$session_dir"/*.json; do
    [ -f "$file" ] && [ ! -L "$file" ] || continue
    session_guest="$(sed -n 's/.*"container"[[:space:]]*:[[:space:]]*"\([A-Za-z0-9._-]*\)".*/\1/p' "$file" | head -n 1)"
    [ "$session_guest" = "$name" ] || continue
    pid="$(sed -n 's/.*"pid"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p' "$file" | head -n 1)"
    started="$(sed -n 's/.*"start_time"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\)\(\.[0-9][0-9]*\)\{0,1\}.*/\1/p' "$file" | head -n 1)"
    [[ "$pid" =~ ^[0-9]+$ && "$started" =~ ^[0-9]+$ ]] || continue
    if kill -0 "$pid" 2>/dev/null; then
      elapsed="$(ps -o etimes= -p "$pid" 2>/dev/null | tr -d '[:space:]')"
      [[ "$elapsed" =~ ^[0-9]+$ ]] || continue
      age=$((now - started))
      [ "$age" -ge 0 ] || age=0
      # A currently live process can be retained only if it predates or
      # plausibly belongs to the recorded PRoot session (60 s startup margin).
      [ $((elapsed + 60)) -lt "$age" ] || continue
    fi
    if rm -f -- "$file"; then removed=$((removed + 1)); fi
  done
  [ "$removed" -gt 0 ] && tnx_info "Removed $removed stale PRoot session record(s) for managed guest '$name'"
  return 0
}

_tnx_uninstall_container() {
  local target="${1:-$(tnx_distro)}"
  if ! tnx_has_cmd proot-distro; then
    tnx_info "proot-distro is not installed; no guest container was removed"
    return 0
  fi
  if ! tnx_proot_container_installed "$target"; then
    tnx_info "Guest '$target' is not installed"
    return 0
  fi
  if ! _tnx_uninstall_confirm "Permanently delete the Ternux guest '$target' and its files?"; then
    tnx_warn "Guest removal cancelled"
    return 1
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
    4|container) _tnx_uninstall_stop; _tnx_uninstall_container ;;
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
