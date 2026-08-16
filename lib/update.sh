# =============================================================================
#  ternux — self-update
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah) — MIT License
#  https://github.com/soobujmiah/ternux
# =============================================================================

# shellcheck source=lib/core.sh
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"

# ---------------------------------------------------------------------------
# tnx_cmd_update
# ---------------------------------------------------------------------------
tnx_cmd_update() {
  local subcmd="${1:-run}"
  shift 2>/dev/null || true

  case "$subcmd" in
    run|--run)   _tnx_update_run ;;
    check|--check) _tnx_update_check ;;
    --help|-h)   tnx_help_update ;;
    *) tnx_fail "Usage: ternux update [check]"; return 1 ;;
  esac
}

_tnx_update_check() {
  tnx_step "Checking for updates..."

  local current_version="$TERNUX_VERSION"
  local remote_version=""
  local api="https://api.github.com/repos/soobujmiah/ternux/releases/latest"
  local release_data=""

  tnx_has_cmd curl && release_data="$(curl -fsSL --max-time 15 "$api" 2>/dev/null)"
  [ -z "$release_data" ] && tnx_has_cmd wget && release_data="$(wget -q --timeout=15 -O- "$api" 2>/dev/null)"

  if [ -n "$release_data" ]; then
    remote_version="$(echo "$release_data" | grep -oP '"tag_name":\s*"v?\K[^"]+' | head -1)"
  fi

  if [ -z "$remote_version" ]; then
    [ "${TERNUX_JSON:-0}" = "1" ] && { tnx_json_object "update" "unknown" "current" "$current_version" "error" "fetch_failed"; return 1; }
    tnx_warn "Could not fetch latest version."
    tnx_info "Visit $TERNUX_REPO to check manually."
    return 1
  fi

  [ "${TERNUX_JSON:-0}" != "1" ] && printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Current:" "$current_version" \
    && printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Latest:" "$remote_version"

  if [ "$current_version" = "$remote_version" ]; then
    [ "${TERNUX_JSON:-0}" = "1" ] && tnx_json_object "update" "current" "version" "$current_version"
    [ "${TERNUX_JSON:-0}" != "1" ] && tnx_ok "You're up to date ($current_version)."
    return 0
  fi

  [ "${TERNUX_JSON:-0}" = "1" ] && tnx_json_object "update" "available" "current" "$current_version" "latest" "$remote_version"
  [ "${TERNUX_JSON:-0}" != "1" ] && tnx_warn "Update available: $current_version → $remote_version"
  return 0
}

_tnx_update_run() {
  tnx_step "Updating ternux..."

  local repo_url="${TERNUX_REPO_URL:-https://github.com/soobujmiah/ternux.git}"
  local clone_dir="${TMPDIR:-/data/data/com.termux/files/usr/tmp}/ternux-update-$$"

  rm -rf "$clone_dir" 2>/dev/null || true
  tnx_info "Fetching from $repo_url ..."

  if ! git clone --depth 1 "$repo_url" "$clone_dir" 2>/dev/null; then
    tnx_fail "Failed to clone repository. Check your connection."
    rm -rf "$clone_dir" 2>/dev/null || true
    [ "${TERNUX_JSON:-0}" = "1" ] && tnx_json_object "update" "error" "reason" "clone_failed"
    return 1
  fi

  if [ ! -f "$clone_dir/bin/ternux" ] && [ ! -f "$clone_dir/install.sh" ]; then
    tnx_fail "Downloaded repo is not a valid ternux installation."
    rm -rf "$clone_dir" 2>/dev/null || true
    return 1
  fi

  # Extract version
  local new_version=""
  [ -f "$clone_dir/lib/core.sh" ] && new_version="$(grep '^TERNUX_VERSION=' "$clone_dir/lib/core.sh" | head -1 | cut -d'"' -f2)"
  [ -z "$new_version" ] && new_version="unknown"

  tnx_info "Installing version ${new_version}..."

  # Install CLI
  if [ -f "$clone_dir/bin/ternux" ]; then
    install -m 755 "$clone_dir/bin/ternux" "${PREFIX:-/data/data/com.termux/files/usr}/bin/ternux" 2>/dev/null || \
    install -m 755 "$clone_dir/bin/ternux" "$HOME/.local/bin/ternux" 2>/dev/null || true
  fi

  # Install libraries
  if [ -d "$clone_dir/lib" ]; then
    mkdir -p "${TERNUX_STATE_DIR}/lib"
    cp -r "$clone_dir/lib/"* "${TERNUX_STATE_DIR}/lib/" 2>/dev/null || true
  fi

  # Update state
  tnx_state_set "version" "$new_version"
  tnx_state_set "updated_at" "$(__tnx_ts)"

  rm -rf "$clone_dir" 2>/dev/null || true

  [ "${TERNUX_JSON:-0}" = "1" ] && tnx_json_object "update" "complete" "previous" "$TERNUX_VERSION" "new" "$new_version"
  [ "${TERNUX_JSON:-0}" != "1" ] && tnx_ok "Updated: $TERNUX_VERSION → $new_version" && tnx_info "Restart your shell to use the new version."
}