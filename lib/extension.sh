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
  if ! getconf GNU_LIBC_VERSION >/dev/null 2>&1; then
    local module="${BASH_SOURCE[0]}" user guest_rc
    user="$(tnx_state_get user)"
    [ -n "$user" ] || { printf '[FAIL] Install Ternux before installing extensions.\n' >&2; return 1; }
    . "$(dirname "$module")/phases.sh"
    if [[ "$subcmd" == install || "$subcmd" == repair ]] &&
       [[ "${1:-}" == llama-htp-experimental ]]; then
      tnx_phase_extras "$user" htp-runtime || {
        _tnx_extension_fail "Could not provision the Debian HTP runtime dependencies; the extension was not changed."
        return 1
      }
    fi
    {
      cat "$module" || exit 1
      printf '\n_tnx_extension_guest_dispatch "$@"\n'
    } | tnx_guest_login --shared-tmp --user "$user" -- bash -s -- "$subcmd" "$@"
    guest_rc="${PIPESTATUS[1]:-1}"
    return "$guest_rc"
  fi
  _tnx_extension_guest_dispatch "$subcmd" "$@"
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
  cat <<'LIST'
Ternux extensions:
  llama-vulkan  llama.cpp CPU + Vulkan, Linux ARM64, upstream b11582
  stable-diffusion  Vulkan image preview on Adreno; CPU quality is unqualified
  llama-htp-experimental  llama.cpp Hexagon HTP for SM8735 (experimental)

Install with: ternux extension install llama-vulkan
Image generation: ternux extension install stable-diffusion
Experimental HTP: ternux extension install llama-htp-experimental
Repair an existing managed install: ternux extension repair NAME
Remove one managed extension: ternux extension remove NAME
Removal preserves model weights and other files outside the extension directory.
ADT releases are managed by ADT; see ternux guides.
LIST
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
  local name="${1:-}" mode="${2:-install}" tag artifact asset base tmp backup expected listed actual member top dest glibc version_major version_minor library ldconfig_bin missing_libraries="" min_glibc_minor package_kind binary
  local -a runtime_libraries
  [ -n "$name" ] || { _tnx_extension_fail "Choose an extension: ternux extension list"; return 2; }
  case "$mode" in install|repair) ;; *) _tnx_extension_fail "Unknown extension operation '$mode'."; return 2 ;; esac
  case "$name" in
    llama-vulkan)
      tag="ternux-llama-vulkan-linux-arm64-b11582"
      artifact="$tag"
      asset="${tag}.tar.gz"
      min_glibc_minor=38
      package_kind=vulkan
      binary=llama-cli
      runtime_libraries=(libssl.so.3 libcrypto.so.3 libgomp.so.1 libvulkan.so.1)
      ;;
    stable-diffusion)
      tag="ternux-stable-diffusion-vulkan-linux-arm64-master-1053"
      artifact="$tag"
      asset="${tag}.tar.gz"
      min_glibc_minor=39
      package_kind=stable-diffusion
      binary=sd-cli
      runtime_libraries=(libgomp.so.1 libvulkan.so.1)
      ;;
    llama-htp-experimental)
      tag="ternux-llama-htp-sm8735-b11582"
      artifact="$tag"
      asset="${tag}.tar.gz"
      min_glibc_minor=38
      package_kind=htp
      binary=llama-cli
      runtime_libraries=(libgbinder.so.1 libglibutil.so.1 libcdsprpc.so.1 libcdsprpc.so)
      ;;
    *) _tnx_extension_fail "Unknown extension '$name'. Run: ternux extension list"; return 2 ;;
  esac

  if [ "$(uname -s 2>/dev/null)" != Linux ] || [ "$(uname -m 2>/dev/null)" != aarch64 ] ||
     ! getconf GNU_LIBC_VERSION >/dev/null 2>&1; then
    _tnx_extension_fail "Run this inside the Linux ARM64 glibc guest, not the Termux host."
    return 1
  fi
  glibc="$(getconf GNU_LIBC_VERSION 2>/dev/null)"
  if [[ ! "$glibc" =~ ^glibc[[:space:]]+([0-9]+)\.([0-9]+)$ ]]; then
    _tnx_extension_fail "Cannot determine the guest's glibc version; $name requires glibc 2.$min_glibc_minor or newer."
    return 1
  fi
  version_major="${BASH_REMATCH[1]}"
  version_minor="${BASH_REMATCH[2]}"
  if (( version_major < 2 || (version_major == 2 && version_minor < min_glibc_minor) )); then
    _tnx_extension_fail "$name requires glibc 2.$min_glibc_minor or newer; found $glibc. No files were installed."
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
    if [ "$package_kind" = htp ]; then
      _tnx_extension_fail "Missing HTP runtime libraries: $missing_libraries. Install libgbinder1, libglibutil1, libfastrpc1, and libfastrpc-dev in Debian; enable trixie-backports main contrib if apt cannot find them."
    elif [ "$package_kind" = stable-diffusion ]; then
      _tnx_extension_fail "Missing runtime libraries: $missing_libraries. In Debian install libgomp1 and libvulkan1."
    else
      _tnx_extension_fail "Missing runtime libraries: $missing_libraries. In Debian install libgomp1 and libvulkan1, plus the OpenSSL 3 runtime package (libssl3 or libssl3t64)."
    fi
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

  local release="https://github.com/soobujmiah/ternux/releases/download/$tag"
  if ! curl -fL --retry 3 --max-time 180 -o "$tmp/$asset" "$release/$asset" ||
     ! curl -fL --retry 3 --max-time 30 -o "$tmp/$asset.sha256" "$release/$asset.sha256"; then
    rm -rf "$tmp"
    _tnx_extension_fail "The extension release is not published or its assets could not be downloaded."
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
  if [ "${actual,,}" != "${expected,,}" ]; then
    rm -rf "$tmp"
    _tnx_extension_fail "Extension archive SHA-256 mismatch; nothing was installed."
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

  if ! tar --no-same-owner -xzf "$tmp/$asset" -C "$tmp" ||
     [ ! -x "$tmp/$top/bin/$binary" ] ||
     [ ! -f "$tmp/$top/build-manifest.json" ]; then
    rm -rf "$tmp"
    _tnx_extension_fail "Extension archive failed its package layout checks; nothing was installed."
    return 1
  fi
  if [ "$package_kind" = htp ]; then
    if [ ! -x "$tmp/$top/bin/htp-run" ] ||
       [ ! -f "$tmp/$top/libexec/htp-broker.py" ] ||
       [ ! -f "$tmp/$top/lib/libternux-htp-broker.so" ] ||
       ! grep -Fq '"artifact": "ternux-llama-htp-sm8735-b11582"' "$tmp/$top/build-manifest.json"; then
      rm -rf "$tmp"
      _tnx_extension_fail "Experimental HTP archive is missing its broker, launcher, or matching manifest."
      return 1
    fi
  elif [ "$package_kind" = stable-diffusion ]; then
    if [ ! -f "$tmp/$top/env.sh" ] || [ ! -d "$tmp/$top/share/licenses" ] ||
       ! grep -Fq '"artifact": "ternux-stable-diffusion-vulkan-linux-arm64-master-1053"' "$tmp/$top/build-manifest.json"; then
      rm -rf "$tmp"
      _tnx_extension_fail "Stable Diffusion archive is missing its environment, license bundle, or matching manifest."
      return 1
    fi
  elif [ ! -f "$tmp/$top/env.sh" ] ||
       ! grep -Fq '"artifact": "ternux-llama-vulkan-linux-arm64-b11582"' "$tmp/$top/build-manifest.json"; then
    rm -rf "$tmp"
    _tnx_extension_fail "Vulkan archive is missing its environment file or matching manifest."
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
  if [ "$package_kind" = htp ]; then
    printf '  Experimental SM8735 route: %s/bin/htp-run\n' "$dest"
    printf '  HTP is not a supported release feature; no CPU/GPU fallback is configured.\n'
  elif [ "$package_kind" = stable-diffusion ]; then
    printf '  Image generator: %s/bin/sd-cli (CPU and Vulkan backends)\n' "$dest"
    printf '  CPU image quality is not qualified; use Vulkan for the tested Adreno route.\n'
    printf '  Source with: source %s/env.sh\n' "$dest"
  else
    printf '  Source its environment with: source %s/env.sh\n' "$dest"
  fi
  printf '  Model weights remain wherever you keep them.\n'
}

_tnx_extension_remove() {
  local name="${1:-}" artifact base dest
  [ -n "$name" ] || { _tnx_extension_fail "Choose an extension: ternux extension list"; return 2; }
  case "$name" in
    llama-vulkan) artifact="ternux-llama-vulkan-linux-arm64-b11582" ;;
    stable-diffusion) artifact="ternux-stable-diffusion-vulkan-linux-arm64-master-1053" ;;
    llama-htp-experimental) artifact="ternux-llama-htp-sm8735-b11582" ;;
    *) _tnx_extension_fail "Unknown extension '$name'. Run: ternux extension list"; return 2 ;;
  esac
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
