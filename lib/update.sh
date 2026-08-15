# =============================================================================
#  ternux — self-update library
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah) — MIT License
#  https://github.com/soobujmiah/ternux
# =============================================================================

# shellcheck source=lib/core.sh
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"

# ---------------------------------------------------------------------------
# Self-update
# ---------------------------------------------------------------------------

tnx_update_check() {
  if [ "${TERNUX_JSON:-0}" != "1" ]; then
    tnx_step "Checking for updates..."
  fi

  local current_version="$TERNUX_VERSION"
  local remote_version=""
  local update_url="${TERNUX_UPDATE_URL:-https://api.github.com/repos/soobujmiah/ternux/releases/latest}"

  # Fetch latest release info from GitHub
  local release_data=""
  if tnx_has_cmd curl; then
    release_data="$(curl -fsSL --max-time 15 "$update_url" 2>/dev/null)"
  fi
  if [ -z "$release_data" ] && tnx_has_cmd wget; then
    release_data="$(wget -q --timeout=15 -O- "$update_url" 2>/dev/null)"
  fi

  if [ -n "$release_data" ]; then
    remote_version="$(echo "$release_data" | grep -oP '"tag_name":\s*"v?\K[^"]+' | head -1)"
  fi

  if [ -z "$remote_version" ]; then
    if [ "${TERNUX_JSON:-0}" = "1" ]; then
      tnx_json_object "update" "unknown" "current_version" "$current_version" "error" "could_not_fetch_remote"
    else
      tnx_warn "Could not fetch latest version from GitHub."
      tnx_info "Visit $TERNUX_REPO to check manually."
    fi
    return 1
  fi

  if [ "${TERNUX_JSON:-0}" != "1" ]; then
    printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Current version:" "$current_version"
    printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Latest version:" "$remote_version"
    echo ""
  fi

  # Compare versions
  if [ "$current_version" = "$remote_version" ]; then
    if [ "${TERNUX_JSON:-0}" = "1" ]; then
      tnx_json_object "update" "current" "current_version" "$current_version" "latest_version" "$remote_version"
    else
      tnx_ok "You're on the latest version ($current_version)."
    fi
    return 0
  fi

  # New version available
  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    tnx_json_object "update" "available" "current_version" "$current_version" "latest_version" "$remote_version"
  else
    tnx_warn "Update available: $current_version → $remote_version"
    echo ""
    tnx_info "Run 'ternux update' to upgrade."
  fi
}

tnx_update_run() {
  tnx_step "Updating ternux..."

  local current_version="$TERNUX_VERSION"
  local repo_url="${TERNUX_REPO_URL:-https://github.com/soobujmiah/ternux.git}"
  local clone_dir="${TMPDIR:-/data/data/com.termux/files/usr/tmp}/ternux-update-$$"

  # Clean up any previous update attempt
  rm -rf "$clone_dir" 2>/dev/null || true

  tnx_info "Fetching latest version from $repo_url ..."

  if ! git clone --depth 1 "$repo_url" "$clone_dir" 2>/dev/null; then
    tnx_fail "Failed to clone repository. Check your internet connection."
    rm -rf "$clone_dir" 2>/dev/null || true

    if [ "${TERNUX_JSON:-0}" = "1" ]; then
      tnx_json_object "update" "error" "current_version" "$current_version" "reason" "clone_failed"
    fi
    return 1
  fi

  # Verify the clone has the expected structure
  if [ ! -f "$clone_dir/bin/ternux" ] && [ ! -f "$clone_dir/install.sh" ]; then
    tnx_fail "Downloaded repository does not contain a valid ternux installation."
    rm -rf "$clone_dir" 2>/dev/null || true

    if [ "${TERNUX_JSON:-0}" = "1" ]; then
      tnx_json_object "update" "error" "reason" "invalid_repository"
    fi
    return 1
  fi

  local new_version=""
  if [ -f "$clone_dir/lib/core.sh" ]; then
    new_version="$(grep '^TERNUX_VERSION=' "$clone_dir/lib/core.sh" | cut -d'"' -f2 2>/dev/null)"
  fi
  [ -z "$new_version" ] && new_version="unknown"

  tnx_info "Installing version ${new_version}..."

  # Install the CLI
  # Copy bin/ternux
  if [ -f "$clone_dir/bin/ternux" ]; then
    install -m 755 "$clone_dir/bin/ternux" "/data/data/com.termux/files/usr/bin/ternux" 2>/dev/null || \
    install -m 755 "$clone_dir/bin/ternux" "$PREFIX/bin/ternux" 2>/dev/null || {
      tnx_warn "Could not install ternux command to PATH"
      # Fallback: copy to home
      install -m 755 "$clone_dir/bin/ternux" "$HOME/.local/bin/ternux" 2>/dev/null || true
    }
  fi

  # Copy libraries
  if [ -d "$clone_dir/lib" ]; then
    mkdir -p "${TERNUX_STATE_DIR}/lib" 2>/dev/null || true
    cp -r "$clone_dir/lib/"* "${TERNUX_STATE_DIR}/lib/" 2>/dev/null || true
  fi

  # Copy docs if present
  if [ -d "$clone_dir/docs" ]; then
    mkdir -p "$HOME/ternux-docs" 2>/dev/null || true
    cp -r "$clone_dir/docs/"* "$HOME/ternux-docs/" 2>/dev/null || true
  fi

  # Update state
  tnx_state_set "version" "$new_version"
  tnx_state_set "updated_at" "$(__tnx_ts)"

  rm -rf "$clone_dir" 2>/dev/null || true

  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    tnx_json_object "update" "complete" "previous_version" "$current_version" "new_version" "$new_version"
  else
    tnx_ok "Updated: $current_version → $new_version"
    tnx_info "You may need to restart your shell to use the new version."
    echo ""
    tnx_info "Changes: https://github.com/soobujmiah/ternux/releases"
  fi
}