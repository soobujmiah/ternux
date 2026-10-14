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
    install) _tnx_extension_install "${1:-}" ;;
    --help|-h|help) tnx_help_extension ;;
    *) _tnx_extension_fail "Usage: ternux extension [list|install NAME]"; return 2 ;;
  esac
}

_tnx_extension_list() {
  cat <<'LIST'
Ternux extensions:
  llama-vulkan  llama.cpp CPU + Vulkan, Linux ARM64, upstream b11582
  llama-htp-experimental  llama.cpp Hexagon HTP for SM8735 (experimental)

Install with: ternux extension install llama-vulkan
Experimental HTP: ternux extension install llama-htp-experimental
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
  local name="${1:-}" tag asset base tmp expected listed actual member top dest glibc version_major version_minor library ldconfig_bin missing_libraries="" min_glibc_minor package_kind
  local -a runtime_libraries
  [ -n "$name" ] || { _tnx_extension_fail "Choose an extension: ternux extension list"; return 2; }
  case "$name" in
    llama-vulkan)
      tag="ternux-llama-vulkan-linux-arm64-b11582"
      asset="${tag}.tar.gz"
      min_glibc_minor=38
      package_kind=vulkan
      runtime_libraries=(libssl.so.3 libcrypto.so.3 libgomp.so.1 libvulkan.so.1)
      ;;
    llama-htp-experimental)
      tag="ternux-llama-htp-sm8735-b11582"
      asset="${tag}.tar.gz"
      min_glibc_minor=38
      package_kind=htp
      runtime_libraries=(libgbinder.so.1 libglibutil.so.1 libcdsprpc.so.1)
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
    if ! "$ldconfig_bin" -p 2>/dev/null | awk '{print $1}' | grep -qxF "$library"; then
      missing_libraries="${missing_libraries:+$missing_libraries, }$library"
    fi
  done
  if [ -n "$missing_libraries" ]; then
    if [ "$package_kind" = htp ]; then
      _tnx_extension_fail "Missing HTP runtime libraries: $missing_libraries. Install libgbinder1, libglibutil1, and libfastrpc1 in Debian; enable trixie-backports main contrib if apt cannot find them."
    else
      _tnx_extension_fail "Missing runtime libraries: $missing_libraries. In Debian install libgomp1 and libvulkan1, plus the OpenSSL 3 runtime package (libssl3 or libssl3t64)."
    fi
    return 1
  fi

  base="$HOME/.local/opt/ternux-extensions"
  dest="$base/$name"
  mkdir -p "$base" || { _tnx_extension_fail "Cannot create extension directory: $base"; return 1; }
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    _tnx_extension_fail "Extension path already exists; inspect or remove it before reinstalling: $dest"
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
     [ ! -x "$tmp/$top/bin/llama-cli" ] ||
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
  elif [ ! -f "$tmp/$top/env.sh" ] ||
       ! grep -Fq '"artifact": "ternux-llama-vulkan-linux-arm64-b11582"' "$tmp/$top/build-manifest.json"; then
    rm -rf "$tmp"
    _tnx_extension_fail "Vulkan archive is missing its environment file or matching manifest."
    return 1
  fi

  if ! mv -T "$tmp/$top" "$dest"; then
    rm -rf "$tmp"
    _tnx_extension_fail "Could not atomically install extension at $dest"
    return 1
  fi
  rm -rf "$tmp"
  _tnx_extension_ok "Installed $name at $dest"
  if [ "$package_kind" = htp ]; then
    printf '  Experimental SM8735 route: %s/bin/htp-run\n' "$dest"
    printf '  HTP is not a supported release feature; no CPU/GPU fallback is configured.\n'
  else
    printf '  Source its environment with: source %s/env.sh\n' "$dest"
  fi
  printf '  Model weights remain wherever you keep them.\n'
}
