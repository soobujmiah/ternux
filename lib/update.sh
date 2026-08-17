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

  # Validate and install the same layout used by the main installer. Older
  # updates wrote modules only under the state directory while the dispatcher
  # preferred $PREFIX/lib/ternux; that could update the executable but leave it
  # loading stale libraries.
  local prefix="${PREFIX:-/data/data/com.termux/files/usr}"
  local bin_target="$prefix/bin/ternux" lib_target="$prefix/lib/ternux"
  local module=""
  bash -n "$clone_dir/bin/ternux" 2>/dev/null || {
    tnx_fail "Downloaded CLI failed shell syntax validation."
    rm -rf "$clone_dir" 2>/dev/null || true
    return 1
  }
  if [ -f "$clone_dir/bin/ternux-guest" ]; then
    if ! bash -n "$clone_dir/bin/ternux-guest" 2>/dev/null; then
      tnx_fail "Downloaded Debian guest companion failed shell syntax validation."
      rm -rf "$clone_dir" 2>/dev/null || true
      return 1
    fi
    local downloaded_guest_version=""
    downloaded_guest_version="$(bash "$clone_dir/bin/ternux-guest" --version 2>&1)" || {
      tnx_fail "Downloaded Debian guest companion could not execute: ${downloaded_guest_version:-unknown error}"
      rm -rf "$clone_dir" 2>/dev/null || true
      return 1
    }
    case "$downloaded_guest_version" in
      "ternux guest v${new_version}"|"ternux guest v${new_version}"$'\n'*) ;;
      *)
        tnx_fail "Downloaded Debian guest companion does not match version ${new_version}: $downloaded_guest_version"
        rm -rf "$clone_dir" 2>/dev/null || true
        return 1
        ;;
    esac
  fi
  for module in "$clone_dir/lib/"*.sh; do
    bash -n "$module" 2>/dev/null || {
      tnx_fail "Downloaded module failed shell syntax validation: $(basename "$module")"
      rm -rf "$clone_dir" 2>/dev/null || true
      return 1
    }
  done

  mkdir -p "$prefix/bin" "$lib_target" || {
    tnx_fail "Could not create the CLI installation directories."
    rm -rf "$clone_dir" 2>/dev/null || true
    return 1
  }
  for module in "$clone_dir/lib/"*.sh; do
    install -m 0644 "$module" "$lib_target/$(basename "$module")" || {
      tnx_fail "Could not install module: $(basename "$module")"
      rm -rf "$clone_dir" 2>/dev/null || true
      return 1
    }
  done
  install -m 0755 "$clone_dir/bin/ternux" "$bin_target" || {
    tnx_fail "Could not install the updated CLI."
    rm -rf "$clone_dir" 2>/dev/null || true
    return 1
  }

  local version_output=""
  version_output="$("$bin_target" --version 2>&1)" || {
    tnx_fail "Updated CLI cannot load its installed libraries: ${version_output:-unknown error}"
    rm -rf "$clone_dir" 2>/dev/null || true
    return 1
  }
  case "$version_output" in
    "ternux v${new_version}"|"ternux v${new_version}"$'\n'*) ;;
    *)
      tnx_fail "Updated CLI returned an unexpected version response: $version_output"
      rm -rf "$clone_dir" 2>/dev/null || true
      return 1
      ;;
  esac

  # Keep the Debian/Xfce companion aligned when a guest already exists. It is
  # safe to skip this on hosts without an installed Debian container.
  if [ -f "$clone_dir/bin/ternux-guest" ] && tnx_has_cmd proot-distro &&
     proot-distro list 2>/dev/null | grep -q "debian.*installed"; then
    local guest_user="${TERNUX_USER:-ternux}" guest_version="" guest_ok=1
    if ! proot-distro login debian -- bash -c '
      set -e
      tmp=/usr/local/bin/.ternux.new
      cat > "$tmp"
      chmod 0755 "$tmp"
      mv -f "$tmp" /usr/local/bin/ternux
    ' < "$clone_dir/bin/ternux-guest"; then
      guest_ok=0
    else
      guest_version="$(proot-distro login debian --user "$guest_user" -- bash -lc \
        'command -v ternux >/dev/null && ternux --version' 2>&1)" || guest_ok=0
      case "$guest_version" in
        "ternux guest v${new_version}"|"ternux guest v${new_version}"$'\n'*) ;;
        *) guest_ok=0 ;;
      esac
    fi
    if [ "$guest_ok" -ne 1 ]; then
      tnx_warn "Host CLI updated, but the Debian guest companion could not be version-verified. Run: ternux install --resume"
    fi
  fi

  # Update state only after the installed command has loaded the new modules.
  tnx_state_set "version" "$new_version"
  tnx_state_set "updated_at" "$(__tnx_ts)"

  rm -rf "$clone_dir" 2>/dev/null || true

  [ "${TERNUX_JSON:-0}" = "1" ] && tnx_json_object "update" "complete" "previous" "$TERNUX_VERSION" "new" "$new_version"
  [ "${TERNUX_JSON:-0}" != "1" ] && tnx_ok "Updated: $TERNUX_VERSION → $new_version" && tnx_info "Restart your shell to use the new version."
}