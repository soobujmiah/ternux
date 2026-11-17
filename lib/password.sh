#!/usr/bin/env bash

_tnx_password_read_new() {
  local label="$1" first="" second=""
  [ -t 0 ] || { tnx_fail "Password changes need an interactive terminal."; return 1; }
  printf '%s: ' "$label" >&2
  IFS= read -r -s first || { printf '\n' >&2; return 1; }
  printf '\nConfirm %s: ' "$label" >&2
  IFS= read -r -s second || { printf '\n' >&2; unset first second; return 1; }
  printf '\n' >&2
  if [ -z "$first" ] || [ "$first" != "$second" ]; then
    unset first second
    tnx_fail "Passwords must be non-empty and match."
    return 1
  fi
  TNX_NEW_PASSWORD="$first"
  unset first second
}

tnx_cmd_password() {
  local what="${1:-}" file="$HOME/.config/ternux/startup-password" config="$HOME/.config/ternux" tmp salt digest
  case "$what" in
    startup)
      _tnx_password_read_new "New startup password" || return 1
      mkdir -p -m 0700 "$config" || { unset TNX_NEW_PASSWORD; return 1; }
      [ ! -L "$config" ] && [ ! -L "$file" ] || { unset TNX_NEW_PASSWORD; tnx_fail "Unsafe startup password path."; return 1; }
      salt="$(od -An -N16 -tx1 /dev/urandom 2>/dev/null | tr -d ' \n')"
      digest="$(printf '%s:%s' "$salt" "$TNX_NEW_PASSWORD" | sha256sum | awk '{print $1}')"
      unset TNX_NEW_PASSWORD
      [[ "$salt" =~ ^[0-9a-f]{32}$ && "$digest" =~ ^[0-9a-f]{64}$ ]] || { tnx_fail "Could not hash the startup password."; return 1; }
      tmp="$(umask 077; mktemp "$config/.startup-password.XXXXXX")" || return 1
      printf '%s %s\n' "$salt" "$digest" > "$tmp" && chmod 0600 "$tmp" && mv -f "$tmp" "$file" || { rm -f "$tmp"; return 1; }
      tnx_ok "Startup password changed for native Termux and all managed guest shells."
      ;;
    sudo)
      local distro user password
      distro="$(tnx_state_get distro 2>/dev/null || true)"
      user="$(tnx_state_get user 2>/dev/null || true)"
      [ -n "$distro" ] && [ -n "$user" ] || { tnx_fail "No installed Ternux guest was found."; return 1; }
      _tnx_password_read_new "New guest sudo/root password" || return 1
      password="$TNX_NEW_PASSWORD"
      unset TNX_NEW_PASSWORD
      if ! (builtin printf '%s:%s\nroot:%s\n' "$user" "$password" "$password" | tnx_guest_login --user root -- chpasswd); then
        unset password
        tnx_fail "Could not change the sudo/root password for '$distro'."
        return 1
      fi
      unset password
      tnx_ok "Guest sudo and root passwords changed for '$distro'."
      ;;
    *)
      printf 'Usage: tx password startup | sudo\n' >&2
      return 2
      ;;
  esac
}
