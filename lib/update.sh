# =============================================================================
#  ternux — self-update
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah)
#  Licensed under the Apache License, Version 2.0.
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
    run|--run)     _tnx_update_run ;;
    check|--check) _tnx_update_check ;;
    --help|-h)     tnx_help_update ;;
    *) tnx_fail "Usage: ternux update [check]"; return 1 ;;
  esac
}

_tnx_is_apt_managed() {
  command -v dpkg-query >/dev/null 2>&1 || return 1
  [ "$(dpkg-query -W -f='${Status}' ternux 2>/dev/null || true)" = "install ok installed" ]
}

_tnx_update_parse_version() {
  local version="${1#v}"
  [[ "$version" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]] || return 1
  printf '%s %s %s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}"
}

_tnx_update_version_gt() {
  local left_text="" right_text=""
  local -a left=() right=()
  left_text="$(_tnx_update_parse_version "$1")" || return 1
  right_text="$(_tnx_update_parse_version "$2")" || return 1
  read -r -a left <<<"$left_text"
  read -r -a right <<<"$right_text"
  (( left[0] > right[0] )) && return 0
  (( left[0] < right[0] )) && return 1
  (( left[1] > right[1] )) && return 0
  (( left[1] < right[1] )) && return 1
  (( left[2] > right[2] ))
}

_tnx_update_latest_tag() {
  local api="${TERNUX_UPDATE_RELEASE_API:-https://api.github.com/repos/soobujmiah/ternux/releases/latest}"
  local data="" tag=""
  if command -v curl >/dev/null 2>&1; then
    data="$(curl -fsSL --max-time 20 "$api" 2>/dev/null || true)"
  fi
  if [ -z "$data" ] && command -v wget >/dev/null 2>&1; then
    data="$(wget -q --timeout=20 -O- "$api" 2>/dev/null || true)"
  fi
  [ -n "$data" ] || return 1
  tag="$(printf '%s\n' "$data" | sed -nE 's/.*"tag_name"[[:space:]]*:[[:space:]]*"(v?(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*))".*/\1/p' | head -n 1)"
  [ -n "$tag" ] || return 1
  _tnx_update_parse_version "$tag" >/dev/null || return 1
  printf '%s\n' "${tag#v}"
}

_tnx_update_latest_version() {
  local latest=""
  latest="$(_tnx_update_latest_tag)" || {
    [ "${TERNUX_JSON:-0}" = 1 ] && tnx_json_object "update" "unknown" "current" "$TERNUX_VERSION" "error" "release_metadata_unavailable"
    [ "${TERNUX_JSON:-0}" != 1 ] && tnx_warn "Could not read the latest stable release metadata."
    return 1
  }
  printf '%s\n' "$latest"
}

_tnx_update_check() {
  tnx_step "Checking for updates..."

  if _tnx_is_apt_managed; then
    local policy installed candidate
    policy="$(tnx_termux_apt_cache policy ternux 2>/dev/null || true)"
    installed="$(printf '%s\n' "$policy" | awk '/^[[:space:]]*Installed:/{print $2; exit}')"
    candidate="$(printf '%s\n' "$policy" | awk '/^[[:space:]]*Candidate:/{print $2; exit}')"
    if [ -z "$installed" ] || [ -z "$candidate" ] || [ "$candidate" = "(none)" ]; then
      [ "${TERNUX_JSON:-0}" = 1 ] && tnx_json_object "update" "unknown" "current" "$TERNUX_VERSION" "error" "apt_candidate_unavailable"
      [ "${TERNUX_JSON:-0}" != 1 ] && tnx_warn "APT package source is unavailable. Run pkg update and check your configured repository."
      return 1
    fi
    if dpkg --compare-versions "$candidate" gt "$installed"; then
      [ "${TERNUX_JSON:-0}" = 1 ] && tnx_json_object "update" "available" "current" "$installed" "latest" "$candidate"
      [ "${TERNUX_JSON:-0}" != 1 ] && tnx_warn "APT update available: $installed → $candidate" && tnx_info "Run: pkg upgrade ternux"
    else
      [ "${TERNUX_JSON:-0}" = 1 ] && tnx_json_object "update" "current" "version" "$installed"
      [ "${TERNUX_JSON:-0}" != 1 ] && tnx_ok "You're up to date ($installed)."
    fi
    return 0
  fi

  local latest=""
  latest="$(_tnx_update_latest_version)" || return 1
  if _tnx_update_version_gt "$latest" "$TERNUX_VERSION"; then
    [ "${TERNUX_JSON:-0}" = 1 ] && tnx_json_object "update" "available" "current" "$TERNUX_VERSION" "latest" "$latest"
    [ "${TERNUX_JSON:-0}" != 1 ] && tnx_warn "Stable update available: $TERNUX_VERSION → $latest" && tnx_info "Run: ternux update"
  else
    [ "${TERNUX_JSON:-0}" = 1 ] && tnx_json_object "update" "current" "version" "$TERNUX_VERSION" "latest_stable" "$latest"
    [ "${TERNUX_JSON:-0}" != 1 ] && tnx_ok "No newer stable release is available (installed: $TERNUX_VERSION; latest stable: $latest)."
  fi
  return 0
}

_tnx_update_proc_start() {
  local pid="${1:-}" state="" start=""
  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  [ -r "/proc/$pid/stat" ] || return 1
  read -r state start < <(awk '{ sub(/^.*\) /, ""); print $1, $20 }' "/proc/$pid/stat" 2>/dev/null) || return 1
  [[ "$pid" =~ ^[0-9]+$ && "$state" != Z && "$state" != X && "$start" =~ ^[0-9]+$ ]] || return 1
  printf '%s\n' "$start"
}

_tnx_update_acquire_lock() {
  local prefix="$1" owner_pid="$2" owner_start="$3"
  local lock="$prefix/lib/.ternux-update-lock" old_pid="" old_start="" observed_start=""
  if mkdir "$lock" 2>/dev/null; then
    if ! printf '%s %s\n' "$owner_pid" "$owner_start" > "$lock/owner"; then
      rmdir "$lock" 2>/dev/null || true
      return 1
    fi
    return 0
  fi
  if [ -L "$lock" ]; then
    tnx_fail "The Ternux update lock is a symlink; preserve it for inspection: $lock"
    return 1
  fi
  if [ -f "$lock/owner" ] && [ ! -L "$lock/owner" ]; then
    read -r old_pid old_start < "$lock/owner" || true
    observed_start="$(_tnx_update_proc_start "$old_pid" 2>/dev/null || true)"
    if [ -n "$observed_start" ] && [ "$observed_start" = "$old_start" ]; then
      tnx_warn "Another Ternux update is still running (PID $old_pid)."
      return 1
    fi
    if [ -e "$prefix/lib/.ternux-update-journal" ]; then
      "$prefix/bin/ternux" --__ternux-recover-update >/dev/null 2>&1 || {
        tnx_fail "A previous update needs recovery; the saved backup was preserved."
        return 1
      }
      return _tnx_update_acquire_lock "$prefix" "$owner_pid" "$owner_start"
    fi
    rm -f "$lock/owner" || return 1
    rmdir "$lock" 2>/dev/null || return 1
    return _tnx_update_acquire_lock "$prefix" "$owner_pid" "$owner_start"
  fi
  tnx_warn "An update lock exists without valid owner metadata; preserve it for inspection: $lock"
  return 1
}

_tnx_update_release_lock() {
  local prefix="$1"
  rm -f "$prefix/lib/.ternux-update-lock/owner" "$prefix/lib/.ternux-update-journal" 2>/dev/null || true
  rmdir "$prefix/lib/.ternux-update-lock" 2>/dev/null || true
}

_tnx_update_restore_previous() {
  local prefix="$1" owner_pid="$2" owner_start="$3"
  TERNUX_UPDATE_OWNER_PID="$owner_pid" TERNUX_UPDATE_OWNER_START="$owner_start" \
    TERNUX_UPDATE_FORCE_RECOVERY=1 "$prefix/bin/ternux" --__ternux-recover-update
}

_tnx_update_fail_and_restore() {
  local prefix="$1" owner_pid="$2" owner_start="$3" message="$4"
  tnx_fail "$message"
  if [ -e "$prefix/lib/.ternux-update-journal" ]; then
    if ! _tnx_update_restore_previous "$prefix" "$owner_pid" "$owner_start"; then
      tnx_fail "Automatic rollback did not finish. The recovery journal and backup were preserved."
      return 70
    fi
  else
    _tnx_update_release_lock "$prefix"
  fi
  return 1
}

_tnx_update_resolve_tag_commit() {
  local repo_url="$1" tag="$2" refs="" sha="" name="" direct="" peeled=""
  refs="$(git ls-remote --tags "$repo_url" "refs/tags/$tag" "refs/tags/$tag^{}" 2>/dev/null)" || return 1
  while IFS="$(printf '\t')" read -r sha name; do
    case "$name" in
      "refs/tags/$tag") direct="$sha" ;;
      "refs/tags/$tag^{}") peeled="$sha" ;;
    esac
  done <<EOF_REFS
$refs
EOF_REFS
  sha="${peeled:-$direct}"
  [[ "$sha" =~ ^[0-9a-f]{40}$ ]] || return 1
  printf '%s\n' "$sha"
}

_tnx_update_cleanup_source() {
  local source_dir="${1:-}"
  case "$source_dir" in
    "${TMPDIR:-${PREFIX:-/data/data/com.termux/files/usr}/tmp}"/ternux-update.*)
      [ -d "$source_dir" ] && rm -rf -- "$source_dir"
      ;;
  esac
}

_tnx_update_run() {
  tnx_step "Updating ternux..."

  if _tnx_is_apt_managed; then
    tnx_info "This Ternux installation is managed by APT."
    tnx_info "Refreshing package lists and upgrading only ternux..."
    tnx_termux_pkg update && tnx_termux_pkg upgrade ternux || {
      tnx_fail "APT could not upgrade ternux. Check the repository configuration and retry: pkg upgrade ternux"
      return 1
    }
    return 0
  fi

  local prefix="${PREFIX:-/data/data/com.termux/files/usr}"
  local temp_root="" repo_url="${TERNUX_REPO_URL:-https://github.com/soobujmiah/ternux.git}"
  local latest="" tag="" expected_commit="" source_dir="" source_version="" resolved_commit=""
  local owner_pid="$$" owner_start="" lock="" backup_root=""
  local backup_id="" backup="" journal="" journal_tmp=""
  local bin_target="" lib_target="" candidate_lib="" candidate_bin=""
  local module="" had_lib=0 had_bin=0 old_version="$TERNUX_VERSION" version_output=""
  temp_root="${TMPDIR:-$prefix/tmp}"
  backup_root="$prefix/lib/ternux-update-backups"
  journal="$prefix/lib/.ternux-update-journal"
  bin_target="$prefix/bin/ternux"
  lib_target="$prefix/lib/ternux"

  latest="$(_tnx_update_latest_version)" || return 1
  if ! _tnx_update_version_gt "$latest" "$old_version"; then
    [ "${TERNUX_JSON:-0}" = 1 ] && tnx_json_object "update" "current" "version" "$old_version" "latest_stable" "$latest"
    [ "${TERNUX_JSON:-0}" != 1 ] && tnx_ok "No newer stable release is available (installed: $old_version; latest stable: $latest)."
    return 0
  fi
  source_version="$latest"
  tag="v$source_version"
  expected_commit="$(_tnx_update_resolve_tag_commit "$repo_url" "$tag")" || {
    tnx_fail "Could not resolve the exact published release tag $tag."
    return 1
  }
  if [ -L "$prefix" ] || [ -L "$prefix/bin" ] || [ -L "$prefix/lib" ]; then
    tnx_fail "Refusing to update through a symlinked prefix, bin, or lib path."
    return 1
  fi
  mkdir -p "$temp_root" "$prefix/bin" "$prefix/lib" || {
    tnx_fail "Could not prepare a private update staging location."
    return 1
  }
  source_dir="$(mktemp -d "$temp_root/ternux-update.XXXXXXXX")" || {
    tnx_fail "Could not create a unique update staging directory."
    return 1
  }
  if ! git init -q "$source_dir" 2>/dev/null ||
     ! git -C "$source_dir" remote add origin "$repo_url" 2>/dev/null ||
     ! git -C "$source_dir" fetch --quiet --depth 1 origin "refs/tags/$tag" 2>/dev/null; then
    _tnx_update_cleanup_source "$source_dir"
    tnx_fail "Could not fetch the published release source."
    return 1
  fi
  resolved_commit="$(git -C "$source_dir" rev-parse 'FETCH_HEAD^{commit}' 2>/dev/null || true)"
  if [ "$resolved_commit" != "$expected_commit" ] ||
     ! git -C "$source_dir" checkout --quiet --detach "$expected_commit" 2>/dev/null; then
    _tnx_update_cleanup_source "$source_dir"
    tnx_fail "The release tag changed during acquisition or did not resolve to its pinned commit."
    return 1
  fi
  if [ ! -f "$source_dir/bin/ternux" ] || [ ! -f "$source_dir/lib/core.sh" ] ||
     [ ! -d "$source_dir/lib" ] || [ -L "$source_dir/bin/ternux" ] ||
     [ -n "$(find "$source_dir/bin" "$source_dir/lib" -type l -print -quit 2>/dev/null)" ]; then
    _tnx_update_cleanup_source "$source_dir"
    tnx_fail "The pinned release has an incomplete or unsafe CLI/module layout."
    return 1
  fi
  source_version="$(sed -nE 's/^TERNUX_VERSION="([^"]+)"$/\1/p' "$source_dir/lib/core.sh" | head -n 1)"
  if [ "$source_version" != "$latest" ]; then
    _tnx_update_cleanup_source "$source_dir"
    tnx_fail "Release tag $tag declares version '${source_version:-missing}', expected $latest."
    return 1
  fi
  if ! bash -n "$source_dir/bin/ternux" 2>/dev/null; then
    _tnx_update_cleanup_source "$source_dir"
    tnx_fail "Pinned release CLI failed syntax validation."
    return 1
  fi
  if [ -f "$source_dir/bin/ternux-guest" ] && ! bash -n "$source_dir/bin/ternux-guest" 2>/dev/null; then
    _tnx_update_cleanup_source "$source_dir"
    tnx_fail "Pinned Debian guest companion failed syntax validation."
    return 1
  fi
  for module in "$source_dir/lib/"*.sh; do
    if [ ! -f "$module" ] || ! bash -n "$module" 2>/dev/null; then
      _tnx_update_cleanup_source "$source_dir"
      tnx_fail "Pinned release module failed syntax validation: $(basename "$module")"
      return 1
    fi
  done
  if [ -f "$source_dir/bin/ternux-guest" ]; then
    version_output="$(bash "$source_dir/bin/ternux-guest" --version 2>&1)" || {
      _tnx_update_cleanup_source "$source_dir"
      tnx_fail "Pinned guest companion could not execute: ${version_output:-unknown error}"
      return 1
    }
    case "$version_output" in
      "ternux guest v${source_version}"|"ternux guest v${source_version}"$'\n'*) ;;
      *)
        _tnx_update_cleanup_source "$source_dir"
        tnx_fail "Pinned guest companion version does not match $source_version."
        return 1
        ;;
    esac
  fi
  version_output="$(TERNUX_LIB_DIR="$source_dir/lib" bash "$source_dir/bin/ternux" --version 2>&1)" || {
    _tnx_update_cleanup_source "$source_dir"
    tnx_fail "Staged release CLI could not load its staged libraries: ${version_output:-unknown error}"
    return 1
  }
  case "$version_output" in
    "ternux v${source_version}"|"ternux v${source_version}"$'\n'*) ;;
    *)
      _tnx_update_cleanup_source "$source_dir"
      tnx_fail "Staged CLI returned an unexpected version response: $version_output"
      return 1
      ;;
  esac

  owner_start="$(_tnx_update_proc_start "$owner_pid" 2>/dev/null || true)"
  if [ -z "$owner_start" ]; then
    _tnx_update_cleanup_source "$source_dir"
    tnx_fail "Could not establish this update process identity; refusing to switch files."
    return 1
  fi
  _tnx_update_acquire_lock "$prefix" "$owner_pid" "$owner_start" || {
    _tnx_update_cleanup_source "$source_dir"
    return 1
  }
  backup_id="${expected_commit}-$(date +%s)-${owner_pid}"
  backup="$backup_root/$backup_id"
  candidate_lib="$prefix/lib/.ternux-candidate-$backup_id"
  candidate_bin="$prefix/bin/.ternux-candidate-$backup_id"
  if [ -L "$backup_root" ]; then
    _tnx_update_release_lock "$prefix"
    _tnx_update_cleanup_source "$source_dir"
    tnx_fail "Refusing to update through a symlinked library or backup path."
    return 1
  fi
  mkdir -p "$backup_root" || {
    _tnx_update_release_lock "$prefix"
    _tnx_update_cleanup_source "$source_dir"
    tnx_fail "Could not create the rollback backup root."
    return 1
  }
  if [ -e "$backup" ] || [ -L "$backup" ]; then
    _tnx_update_release_lock "$prefix"
    _tnx_update_cleanup_source "$source_dir"
    tnx_fail "The rollback backup identifier already exists; refusing to overwrite it."
    return 1
  fi
  mkdir "$backup" "$backup/bin" || {
    _tnx_update_release_lock "$prefix"
    _tnx_update_cleanup_source "$source_dir"
    tnx_fail "Could not create the rollback backup directory."
    return 1
  }
  if [ -L "$lib_target" ] || [ -L "$bin_target" ]; then
    _tnx_update_release_lock "$prefix"
    _tnx_update_cleanup_source "$source_dir"
    tnx_fail "Refusing to replace symlinked CLI installation paths."
    return 1
  fi
  if [ -d "$lib_target" ]; then
    had_lib=1
    cp -a "$lib_target" "$backup/lib" || {
      _tnx_update_release_lock "$prefix"
      _tnx_update_cleanup_source "$source_dir"
      tnx_fail "Could not preserve the current module tree."
      return 1
    }
  elif [ -e "$lib_target" ]; then
    _tnx_update_release_lock "$prefix"
    _tnx_update_cleanup_source "$source_dir"
    tnx_fail "The current module path is not a directory; refusing to replace it."
    return 1
  fi
  if [ -f "$bin_target" ]; then
    had_bin=1
    cp -p "$bin_target" "$backup/bin/ternux" || {
      _tnx_update_release_lock "$prefix"
      _tnx_update_cleanup_source "$source_dir"
      tnx_fail "Could not preserve the current CLI executable."
      return 1
    }
  elif [ -e "$bin_target" ]; then
    _tnx_update_release_lock "$prefix"
    _tnx_update_cleanup_source "$source_dir"
    tnx_fail "The current CLI path is not a regular file; refusing to replace it."
    return 1
  fi
  if [ -e "$candidate_lib" ] || [ -L "$candidate_lib" ] || [ -e "$candidate_bin" ] || [ -L "$candidate_bin" ]; then
    _tnx_update_release_lock "$prefix"
    _tnx_update_cleanup_source "$source_dir"
    tnx_fail "An update staging path already exists; preserved it for inspection."
    return 1
  fi
  cp -a "$source_dir/lib" "$candidate_lib" || {
    _tnx_update_release_lock "$prefix"
    _tnx_update_cleanup_source "$source_dir"
    tnx_fail "Could not stage the complete release module tree."
    return 1
  }
  install -m 0755 "$source_dir/bin/ternux" "$candidate_bin" || {
    rm -rf -- "$candidate_lib"
    _tnx_update_release_lock "$prefix"
    _tnx_update_cleanup_source "$source_dir"
    tnx_fail "Could not stage the release CLI executable."
    return 1
  }

  # Install the recovery-aware dispatcher first; its modules are still the old,
  # working version. From the journal onward, any next CLI call can roll back.
  if ! mv -f "$candidate_bin" "$bin_target"; then
    rm -rf -- "$candidate_lib"
    _tnx_update_release_lock "$prefix"
    _tnx_update_cleanup_source "$source_dir"
    tnx_fail "Could not atomically install the recovery-aware dispatcher."
    return 1
  fi
  journal_tmp="$prefix/lib/.ternux-update-journal.tmp-$owner_pid"
  if [ -e "$journal_tmp" ] || [ -L "$journal_tmp" ]; then
    cp -p "$backup/bin/ternux" "$prefix/bin/.ternux-rollback-$owner_pid" 2>/dev/null || true
    if [ "$had_bin" = 1 ]; then mv -f "$prefix/bin/.ternux-rollback-$owner_pid" "$bin_target" 2>/dev/null || true; else rm -f "$bin_target"; fi
    rm -rf -- "$candidate_lib"
    _tnx_update_release_lock "$prefix"
    _tnx_update_cleanup_source "$source_dir"
    tnx_fail "An update journal staging path already exists; preserve it for inspection."
    return 1
  fi
  if ! printf '%s %s %s %s %s\n' "$owner_pid" "$owner_start" "$backup_id" "$had_lib" "$had_bin" > "$journal_tmp" ||
     ! chmod 0600 "$journal_tmp" || ! mv -f "$journal_tmp" "$journal"; then
    cp -p "$backup/bin/ternux" "$prefix/bin/.ternux-rollback-$owner_pid" 2>/dev/null || true
    if [ "$had_bin" = 1 ]; then mv -f "$prefix/bin/.ternux-rollback-$owner_pid" "$bin_target" 2>/dev/null || true; else rm -f "$bin_target"; fi
    rm -f "$journal_tmp"
    rm -rf -- "$candidate_lib"
    _tnx_update_release_lock "$prefix"
    _tnx_update_cleanup_source "$source_dir"
    tnx_fail "Could not safely record the update transaction; the existing module tree was left untouched."
    return 1
  fi

  tnx_info "Applying verified release $source_version ($expected_commit)..."
  if [ "$had_lib" = 1 ]; then
    if ! mv "$lib_target" "$backup/active-before-update"; then
      _tnx_update_cleanup_source "$source_dir"
      _tnx_update_fail_and_restore "$prefix" "$owner_pid" "$owner_start" "Could not move the old module tree into the rollback area."
      return $?
    fi
  elif [ -e "$lib_target" ]; then
    _tnx_update_cleanup_source "$source_dir"
    _tnx_update_fail_and_restore "$prefix" "$owner_pid" "$owner_start" "The module path changed during update; rollback started."
    return $?
  fi
  if ! mv "$candidate_lib" "$lib_target"; then
    _tnx_update_cleanup_source "$source_dir"
    _tnx_update_fail_and_restore "$prefix" "$owner_pid" "$owner_start" "Could not switch to the staged module tree."
    return $?
  fi
  version_output="$(TERNUX_LIB_DIR= TERNUX_UPDATE_OWNER_PID="$owner_pid" TERNUX_UPDATE_OWNER_START="$owner_start" "$bin_target" --version 2>&1)" || {
    _tnx_update_cleanup_source "$source_dir"
    _tnx_update_fail_and_restore "$prefix" "$owner_pid" "$owner_start" "Updated CLI failed to load its installed libraries: ${version_output:-unknown error}"
    return $?
  }
  case "$version_output" in
    "ternux v${source_version}"|"ternux v${source_version}"$'\n'*) ;;
    *)
      _tnx_update_cleanup_source "$source_dir"
      _tnx_update_fail_and_restore "$prefix" "$owner_pid" "$owner_start" "Updated CLI returned an unexpected version response: $version_output"
      return $?
      ;;
  esac

  # The journal is the commit boundary. Backups remain available for manual
  # recovery; removing this marker means the candidate passed its installed check.
  rm -f "$journal" || {
    _tnx_update_cleanup_source "$source_dir"
    _tnx_update_fail_and_restore "$prefix" "$owner_pid" "$owner_start" "Could not commit the update journal; rollback started."
    return $?
  }
  rm -f "$prefix/lib/.ternux-update-lock/owner" 2>/dev/null || true
  rmdir "$prefix/lib/.ternux-update-lock" 2>/dev/null || true

  if [ -f "$source_dir/bin/ternux-guest" ] && tnx_debian_installed; then
    local guest_user="${TERNUX_USER:-ternux}" guest_version="" guest_ok=1
    if ! tnx_guest_login -- bash -c '
      set -e
      tmp=/usr/local/bin/.ternux.new
      cat > "$tmp"
      chmod 0755 "$tmp"
      mv -f "$tmp" /usr/local/bin/ternux
    ' < "$source_dir/bin/ternux-guest"; then
      guest_ok=0
    else
      guest_version="$(tnx_guest_login --user "$guest_user" -- bash -lc 'command -v ternux >/dev/null && ternux --version' 2>&1)" || guest_ok=0
      case "$guest_version" in
        "ternux guest v${source_version}"|"ternux guest v${source_version}"$'\n'*) ;;
        *) guest_ok=0 ;;
      esac
    fi
    if [ "$guest_ok" -ne 1 ]; then
      tnx_warn "Host CLI updated, but the Debian guest companion could not be version-verified. Run: ternux install --resume"
    fi
  fi

  tnx_state_set "version" "$source_version"
  tnx_state_set "updated_at" "$(__tnx_ts)"
  _tnx_update_cleanup_source "$source_dir"
  [ "${TERNUX_JSON:-0}" = 1 ] && tnx_json_object "update" "complete" "previous" "$old_version" "new" "$source_version" "commit" "$expected_commit"
  [ "${TERNUX_JSON:-0}" != 1 ] && tnx_ok "Updated: $old_version → $source_version" && tnx_info "Previous CLI and modules were retained at: $backup"
}
