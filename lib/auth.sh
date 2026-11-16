#!/usr/bin/env bash

tnx_cmd_auth() {
  local action="${1:-}" file="$HOME/.config/ternux/startup-password"
  [ "$action" = startup ] || { tnx_fail "Usage: tx auth startup"; return 2; }
  if [ ! -r "$file" ]; then
    tnx_info "Startup password is not configured. Run: tx password startup"
    return 0
  fi
  local salt expected entered actual tty_fd=""
  if { exec 3<>/dev/tty; } 2>/dev/null; then tty_fd=3
  elif [ -t 0 ]; then tty_fd=0
  else tnx_fail "Startup password authentication needs an interactive terminal."; return 1
  fi
  IFS=' ' read -r salt expected < "$file" || return 1
  [[ "$salt" =~ ^[0-9a-f]{32}$ && "$expected" =~ ^[0-9a-f]{64}$ ]] || { tnx_fail "Startup password file is invalid."; return 1; }
  printf 'Ternux startup password: ' >&2
  IFS= read -r -s -u "$tty_fd" entered || { printf '\n' >&2; [ "$tty_fd" = 3 ] && exec 3>&-; return 1; }
  printf '\n' >&2
  [ "$tty_fd" = 3 ] && exec 3>&-
  actual="$(printf '%s:%s' "$salt" "$entered" | sha256sum | awk '{print $1}')"
  unset entered
  [ "$actual" = "$expected" ] || { tnx_fail "Startup password is incorrect."; return 1; }
}
