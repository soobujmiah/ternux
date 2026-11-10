#!/usr/bin/env bash
# =============================================================================
#  ternux — release-based optional Linux extensions
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah)
#  Licensed under the Apache License, Version 2.0.
#  https://github.com/soobujmiah/ternux
# =============================================================================

tnx_cmd_extension() {
  local subcmd="${1:-list}"
  shift 2>/dev/null || true
  local module="${BASH_SOURCE[0]}" module_dir user guest_rc host_profile=""
  module_dir="$(CDPATH= cd -- "$(dirname -- "$module")" 2>/dev/null && pwd -P)" || return 1
  _tnx_extension_load_registry "$module_dir" || return 1
  if ! getconf GNU_LIBC_VERSION >/dev/null 2>&1; then
    user="$(tnx_state_get user)"
    [ -n "$user" ] || { _tnx_extension_fail "Install Ternux before installing extensions."; return 1; }
    . "$module_dir/phases.sh"
    if [[ "$subcmd" == install || "$subcmd" == repair ]]; then
      local requested_availability
      requested_availability="$(tnx_workload_get "${1:-}" availability 2>/dev/null || true)"
      if [ "$requested_availability" = blocked ]; then
        _tnx_extension_fail "$(tnx_workload_get "${1:-}" availability_note)"
        return 1
      fi
      host_profile="$(tnx_workload_get "${1:-}" host_dependency_profile 2>/dev/null || true)"
      case "$host_profile" in
        htp-runtime)
          tnx_phase_extras "$user" "$host_profile" || {
            _tnx_extension_fail "Could not provision the Debian HTP runtime dependencies; the extension was not changed."
            return 1
          }
          ;;
        "") ;;
        *) _tnx_extension_fail "Unknown workload host dependency profile '$host_profile'."; return 1 ;;
      esac
    fi
    {
      cat "$module" || exit 1
      cat "$module_dir/workload-registry.sh" || exit 1
      printf '\n_tnx_extension_guest_dispatch "$@"\n'
    } | tnx_guest_login --shared-tmp --user "$user" -- bash -s -- "$subcmd" "$@"
    guest_rc="${PIPESTATUS[1]:-1}"
    return "$guest_rc"
  fi
  _tnx_extension_guest_dispatch "$subcmd" "$@"
}

_tnx_extension_load_registry() {
  local module_dir="${1:-}"
  [ -n "$module_dir" ] || module_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)"
  if [ ! -r "$module_dir/workload-registry.sh" ]; then
    _tnx_extension_fail "Workload registry is missing beside the extension manager: $module_dir/workload-registry.sh"
    return 1
  fi
  . "$module_dir/workload-registry.sh"
}

_tnx_extension_guest_dispatch() {
  local subcmd="${1:-list}"
  shift 2>/dev/null || true
  case "$subcmd" in
    list|ls) _tnx_extension_list ;;
    install) _tnx_extension_install "${1:-}" install ;;
    repair) _tnx_extension_install "${1:-}" repair ;;
    remove|uninstall) _tnx_extension_remove "${1:-}" ;;
    --help|-h|help) tnx_help_extension ;;
    *) _tnx_extension_fail "Usage: ternux extension [list|install|repair|remove NAME]"; return 2 ;;
  esac
}

_tnx_extension_list() {
  local workload label backends status availability note
  printf 'Ternux extensions:\n'
  for workload in "${TNX_WORKLOAD_IDS[@]}"; do
    label="$(tnx_workload_get "$workload" display_name)"
    backends="$(tnx_workload_get "$workload" backends)"
    status="$(tnx_workload_get "$workload" support_status)"
    availability="$(tnx_workload_get "$workload" availability)"
    printf '  %-28s %s (%s; %s)\n' "$workload" "$label" "$backends" "$status"
    if [ "$availability" = blocked ]; then
      note="$(tnx_workload_get "$workload" availability_note)"
      printf '    Unavailable: %s\n' "$note"
    fi
  done
  printf '\nInstall with: ternux extension install NAME\n'
  printf 'Repair an existing managed install: ternux extension repair NAME\n'
  printf 'Remove one managed extension: ternux extension remove NAME\n'
  printf 'Removal preserves model weights and other files outside the extension directory.\n'
  printf 'ADT releases are managed by ADT; see ternux guides.\n'
}

_tnx_extension_fail() { printf '[FAIL] %s\n' "$*" >&2; }
_tnx_extension_ok() { printf '[ OK ] %s\n' "$*"; }

_tnx_extension_find_ldconfig() {
  local found candidate
  found="$(command -v ldconfig 2>/dev/null || true)"
  if [ -n "$found" ]; then
    printf '%s\n' "$found"
    return 0
  fi
  for candidate in /sbin/ldconfig /usr/sbin/ldconfig; do
    if [ -x "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

_tnx_extension_install() {
  local name="${1:-}" mode="${2:-install}" tag artifact asset base tmp backup expected listed actual member top dest glibc version_major version_minor required_major required_minor library ldconfig_bin missing_libraries="" minimum_glibc binary expected_archive_sha256 expected_sidecar_sha256 dependency_hint manifest_path environment_file note availability
  local -a runtime_libraries required_executables required_files required_directories post_install_notes
  [ -n "$name" ] || { _tnx_extension_fail "Choose an extension: ternux extension list"; return 2; }
  case "$mode" in install|repair) ;; *) _tnx_extension_fail "Unknown extension operation '$mode'."; return 2 ;; esac
  _tnx_extension_load_registry || return 1
  if ! tnx_workload_get "$name" display_name >/dev/null 2>&1; then
    _tnx_extension_fail "Unknown extension '$name'. Run: ternux extension list"
    return 2
  fi
  availability="$(tnx_workload_get "$name" availability)"
  if [ "$availability" = blocked ]; then
    _tnx_extension_fail "$(tnx_workload_get "$name" availability_note)"
    return 1
  fi
  tag="$(tnx_workload_get "$name" release_tag)"
  artifact="$tag"
  asset="$(tnx_workload_get "$name" asset)"
  minimum_glibc="$(tnx_workload_get "$name" minimum_glibc)"
  binary="$(tnx_workload_get "$name" primary_binary)"
  expected_archive_sha256="$(tnx_workload_get "$name" archive_sha256)"
  expected_sidecar_sha256="$(tnx_workload_get "$name" sidecar_sha256)"
  dependency_hint="$(tnx_workload_get "$name" dependency_hint)"
  manifest_path="$(tnx_workload_get "$name" manifest_path)"
  environment_file="$(tnx_workload_get "$name" environment_file)"
  mapfile -t runtime_libraries < <(tnx_workload_get "$name" runtime_libraries)
  mapfile -t required_executables < <(tnx_workload_get "$name" required_executables)
  mapfile -t required_files < <(tnx_workload_get "$name" required_files)
  mapfile -t required_directories < <(tnx_workload_get "$name" required_directories)

  if [ "$(uname -s 2>/dev/null)" != Linux ] || [ "$(uname -m 2>/dev/null)" != aarch64 ] ||
     ! getconf GNU_LIBC_VERSION >/dev/null 2>&1; then
    _tnx_extension_fail "Run this inside the Linux ARM64 glibc guest, not the Termux host."
    return 1
  fi
  glibc="$(getconf GNU_LIBC_VERSION 2>/dev/null)"
  if [[ ! "$glibc" =~ ^glibc[[:space:]]+([0-9]+)\.([0-9]+)$ ]]; then
    _tnx_extension_fail "Cannot determine the guest's glibc version; $name requires glibc $minimum_glibc or newer."
    return 1
  fi
  version_major="${BASH_REMATCH[1]}"
  version_minor="${BASH_REMATCH[2]}"
  required_major="${minimum_glibc%%.*}"
  required_minor="${minimum_glibc#*.}"
  if (( version_major < required_major || (version_major == required_major && version_minor < required_minor) )); then
    _tnx_extension_fail "$name requires glibc $minimum_glibc or newer; found $glibc. No files were installed."
    return 1
  fi
  for cmd in curl sha256sum tar mktemp; do
    command -v "$cmd" >/dev/null 2>&1 || { _tnx_extension_fail "Missing required command: $cmd"; return 1; }
  done
  ldconfig_bin="$(_tnx_extension_find_ldconfig)" || { _tnx_extension_fail "Missing required command: ldconfig"; return 1; }
  for library in "${runtime_libraries[@]}"; do
    available=false
    if "$ldconfig_bin" -p 2>/dev/null | awk '{print $1}' | grep -qxF "$library"; then
      available=true
    else
      local -a library_dirs
      IFS=: read -r -a library_dirs <<< "${LD_LIBRARY_PATH:-}:${ADSP_LIBRARY_PATH:-}"
      if [ "$library" = libcdsprpc.so ]; then
        library_dirs+=(/lib/aarch64-linux-gnu /usr/lib/aarch64-linux-gnu)
      fi
      for dir in "${library_dirs[@]}"; do
        if [ -n "$dir" ] && { [ -e "$dir/$library" ] || [ -L "$dir/$library" ]; }; then
          available=true
          break
        fi
      done
    fi
    if [ "$available" != true ]; then
      missing_libraries="${missing_libraries:+$missing_libraries, }$library"
    fi
  done
  if [ -n "$missing_libraries" ]; then
    _tnx_extension_fail "Missing runtime libraries: $missing_libraries. $dependency_hint"
    return 1
  fi

  base="$HOME/.local/opt/ternux-extensions"
  dest="$base/$name"
  mkdir -p "$base" || { _tnx_extension_fail "Cannot create extension directory: $base"; return 1; }
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    if [ "$mode" != repair ]; then
      _tnx_extension_fail "Extension path already exists; inspect it or use 'ternux extension repair $name': $dest"
      return 1
    fi
    if [ -L "$dest" ] || [ ! -d "$dest" ] ||
       ! grep -Fq '"artifact": "'"$artifact"'"' "$dest/build-manifest.json" 2>/dev/null; then
      _tnx_extension_fail "Refusing to replace an unrecognized extension path: $dest"
      return 1
    fi
    backup="$base/.${name}.repair-backup.$$.${RANDOM}"
    if [ -e "$backup" ] || [ -L "$backup" ]; then
      _tnx_extension_fail "Repair backup path already exists: $backup"
      return 1
    fi
  elif [ "$mode" = repair ]; then
    _tnx_extension_fail "Cannot repair $name because no managed installation exists at $dest"
    return 1
  fi
  tmp="$(mktemp -d "$base/.${name}.install.XXXXXX")" || { _tnx_extension_fail "Cannot create temporary install directory."; return 1; }

  local release_repository
  release_repository="$(tnx_workload_get "$name" release_repository)"
  local release="$release_repository/releases/download/$tag"
  if ! curl -fL --retry 3 --max-time 180 -o "$tmp/$asset" "$release/$asset" ||
     ! curl -fL --retry 3 --max-time 30 -o "$tmp/$asset.sha256" "$release/$asset.sha256"; then
    rm -rf "$tmp"
    _tnx_extension_fail "The extension release is not published or its assets could not be downloaded."
    return 1
  fi

  actual="$(sha256sum "$tmp/$asset.sha256" | awk '{print $1}')"
  if [ "${actual,,}" != "${expected_sidecar_sha256,,}" ]; then
    rm -rf "$tmp"
    _tnx_extension_fail "Release checksum sidecar SHA-256 mismatch; nothing was installed."
    return 1
  fi
  read -r expected listed < "$tmp/$asset.sha256"
  listed="${listed#\*}"
  case "$expected" in
    ''|*[!0123456789abcdefABCDEF]*) rm -rf "$tmp"; _tnx_extension_fail "Invalid SHA-256 sidecar."; return 1 ;;
  esac
  if [ "${#expected}" -ne 64 ] || [ "$listed" != "$asset" ]; then
    rm -rf "$tmp"
    _tnx_extension_fail "SHA-256 sidecar does not identify the expected archive."
    return 1
  fi
  actual="$(sha256sum "$tmp/$asset" | awk '{print $1}')"
  if [ "${actual,,}" != "${expected,,}" ] || [ "${actual,,}" != "${expected_archive_sha256,,}" ]; then
    rm -rf "$tmp"
    _tnx_extension_fail "Extension archive SHA-256 mismatch against its pinned release digest; nothing was installed."
    return 1
  fi

  top="$tag"
  if ! tar -tzf "$tmp/$asset" > "$tmp/contents.txt"; then
    rm -rf "$tmp"
    _tnx_extension_fail "Cannot read extension archive."
    return 1
  fi
  while IFS= read -r member; do
    member="${member%/}"
    case "$member" in
      /*|..|../*|*/../*|*/..) rm -rf "$tmp"; _tnx_extension_fail "Unsafe path in extension archive."; return 1 ;;
      "$top"|"$top"/*) ;;
      *) rm -rf "$tmp"; _tnx_extension_fail "Unexpected top-level path in extension archive."; return 1 ;;
    esac
  done < "$tmp/contents.txt"

  if ! tar -tvzf "$tmp/$asset" > "$tmp/details.txt" || ! awk '
    substr($1, 1, 1) == "h" { bad=1 }
    substr($1, 1, 1) == "l" {
      target=$NF
      if (target ~ /^\// || target ~ /(^|\/)\.\.(\/|$)/) bad=1
    }
    END { if (bad) exit 1 }
  ' "$tmp/details.txt"; then
    rm -rf "$tmp"
    _tnx_extension_fail "Unsafe link in extension archive."
    return 1
  fi

  if ! tar --no-same-owner -xzf "$tmp/$asset" -C "$tmp"; then
    rm -rf "$tmp"
    _tnx_extension_fail "Cannot extract extension archive; nothing was installed."
    return 1
  fi
  local required_path
  for required_path in "${required_executables[@]}"; do
    [ -x "$tmp/$top/$required_path" ] || {
      rm -rf "$tmp"; _tnx_extension_fail "Extension archive is missing required executable: $required_path"; return 1;
    }
  done
  for required_path in "${required_files[@]}"; do
    [ -f "$tmp/$top/$required_path" ] || {
      rm -rf "$tmp"; _tnx_extension_fail "Extension archive is missing required file: $required_path"; return 1;
    }
  done
  for required_path in "${required_directories[@]}"; do
    [ -d "$tmp/$top/$required_path" ] || {
      rm -rf "$tmp"; _tnx_extension_fail "Extension archive is missing required directory: $required_path"; return 1;
    }
  done
  if [ -n "$environment_file" ] && [ ! -f "$tmp/$top/$environment_file" ]; then
    rm -rf "$tmp"
    _tnx_extension_fail "Extension archive is missing its environment file: $environment_file"
    return 1
  fi
  if ! grep -Fq '"artifact": "'"$tag"'"' "$tmp/$top/$manifest_path"; then
    rm -rf "$tmp"
    _tnx_extension_fail "Extension manifest does not identify the selected release artifact."
    return 1
  fi

  if [ "$mode" = repair ]; then
    if ! mv -T "$dest" "$backup"; then
      rm -rf "$tmp"
      _tnx_extension_fail "Could not move the managed installation into a temporary repair backup."
      return 1
    fi
    if ! mv -T "$tmp/$top" "$dest"; then
      if ! mv -T "$backup" "$dest"; then
        _tnx_extension_fail "Replacement failed and rollback failed; the previous installation is preserved at $backup"
      else
        rm -rf "$tmp"
        _tnx_extension_fail "Replacement failed; the previous installation was restored."
      fi
      return 1
    fi
    if ! rm -rf "$backup"; then
      printf '[WARN] New installation is active; stale repair backup remains at %s\n' "$backup" >&2
    fi
  elif ! mv -T "$tmp/$top" "$dest"; then
    rm -rf "$tmp"
    _tnx_extension_fail "Could not atomically install extension at $dest"
    return 1
  fi
  rm -rf "$tmp"
  if [ "$mode" = repair ]; then
    _tnx_extension_ok "Repaired $name at $dest"
  else
    _tnx_extension_ok "Installed $name at $dest"
  fi
  for note in "${post_install_notes[@]}"; do
    printf '  %s\n' "$note"
  done
  if [ -n "$environment_file" ]; then
    printf '  Source its environment with: source %s/%s\n' "$dest" "$environment_file"
  fi
  printf '  Model weights remain wherever you keep them.\n'
}

_tnx_extension_remove() {
  local name="${1:-}" artifact base dest
  [ -n "$name" ] || { _tnx_extension_fail "Choose an extension: ternux extension list"; return 2; }
  _tnx_extension_load_registry || return 1
  artifact="$(tnx_workload_get "$name" release_tag 2>/dev/null)" || {
    _tnx_extension_fail "Unknown extension '$name'. Run: ternux extension list"; return 2;
  }
  if [ "$(uname -s 2>/dev/null)" != Linux ] || ! getconf GNU_LIBC_VERSION >/dev/null 2>&1; then
    _tnx_extension_fail "Run this inside the Linux glibc guest, not the Termux host."
    return 1
  fi
  base="$HOME/.local/opt/ternux-extensions"
  dest="$base/$name"
  if [ ! -e "$dest" ] && [ ! -L "$dest" ]; then
    _tnx_extension_ok "$name is already absent"
    return 0
  fi
  if [ -L "$dest" ] || [ ! -d "$dest" ] ||
     ! grep -Fq '"artifact": "'"$artifact"'"' "$dest/build-manifest.json" 2>/dev/null; then
    _tnx_extension_fail "Refusing to remove an unrecognized path: $dest"
    return 1
  fi
  if ! rm -rf -- "$dest"; then
    _tnx_extension_fail "Could not remove managed extension directory: $dest"
    return 1
  fi
  _tnx_extension_ok "Removed $name; model weights and files outside $dest were preserved"
}
