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
  wine-hangover  Windows x86/x86-64 programs via Hangover Wine 11.16 (experimental)

Install with: ternux extension install llama-vulkan
Experimental HTP: ternux extension install llama-htp-experimental
Experimental Windows apps: ternux extension install wine-hangover
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
    wine-hangover)
      _tnx_extension_install_hangover
      return $?
      ;;
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

# ---------------------------------------------------------------------------
# wine-hangover — upstream Hangover release, pinned by SHA-256
#
# Unlike the llama packages this is not a Ternux-built archive: it is the
# upstream AndreRH/hangover release for Debian 13 ARM64. The tarball digest is
# pinned below (it matches the digest GitHub publishes for the release asset),
# the .deb files are unpacked into the user's home with dpkg-deb --fsys-tarfile
# (no root, no dpkg database change, no maintainer scripts), and the result is
# smoke-tested with `wine --version` before it is moved into place.
# ---------------------------------------------------------------------------
TNX_HANGOVER_VERSION="11.16"
TNX_HANGOVER_TAG="hangover-11.16"
TNX_HANGOVER_ASSET="hangover_11.16_debian13_trixie_arm64.tar"
TNX_HANGOVER_SHA256="b5493f5903ab3c05f78bf4c03b06ac0005eb26f732437748c1592fefa45e861a"
TNX_HANGOVER_ARTIFACT="ternux-wine-hangover-11.16-debian13-arm64"
TNX_HANGOVER_DEBS="hangover-wine_11.16~trixie_arm64.deb hangover-libwow64fex_11.16_arm64.deb hangover-libarm64ecfex_11.16_arm64.deb hangover-wowbox64_11.16_arm64.deb"
TNX_HANGOVER_DXVK="dxvk-v2.7.1.tar.gz"
# Runtime packages taken from hangover-wine's Depends, plus the Recommends
# that Wine needs for fonts, input and basic graphics to work at all.
TNX_HANGOVER_PACKAGES="libasound2t64 libavcodec61 libavformat61 libavutil59 libglib2.0-0t64 libgphoto2-6t64 libgphoto2-port12t64 libgstreamer-plugins-base1.0-0 libgstreamer1.0-0 libpulse0 libsane1 libudev1 libusb-1.0-0 libwayland-client0 libwayland-egl1 libx11-6 libxext6 libxkbcommon0 libxkbregistry0 libncurses6 libfreetype6 libfontconfig1 libxrender1 libxrandr2 libxcursor1 libxi6 libxcomposite1 libxfixes3 libxinerama1 libxxf86vm1 libgnutls30t64"

_tnx_extension_install_hangover() {
  local name=wine-hangover base dest tmp stage asset="$TNX_HANGOVER_ASSET" url actual glibc listing pkg deb want got
  local missing_packages="" free_kb member

  if [ "$(uname -s 2>/dev/null)" != Linux ] || [ "$(uname -m 2>/dev/null)" != aarch64 ] ||
     ! getconf GNU_LIBC_VERSION >/dev/null 2>&1; then
    _tnx_extension_fail "Run this inside the Linux ARM64 glibc guest, not the Termux host."
    return 1
  fi
  glibc="$(getconf GNU_LIBC_VERSION 2>/dev/null)"
  if [[ ! "$glibc" =~ ^glibc[[:space:]]+2\.([0-9]+)$ ]] || [ "${BASH_REMATCH[1]}" -lt 38 ]; then
    _tnx_extension_fail "$name requires glibc 2.38 or newer; found ${glibc:-unknown}. No files were installed."
    return 1
  fi
  if ! ( . "${TERNUX_OS_RELEASE:-/etc/os-release}" 2>/dev/null && [ "${ID:-}" = debian ] && [ "${VERSION_ID:-}" = 13 ] ); then
    _tnx_extension_fail "$name is built for Debian 13 (trixie); this guest is different. No files were installed."
    return 1
  fi
  for cmd in curl sha256sum tar mktemp dpkg-deb dpkg-query timeout; do
    command -v "$cmd" >/dev/null 2>&1 || { _tnx_extension_fail "Missing required command: $cmd"; return 1; }
  done

  base="$HOME/.local/opt/ternux-extensions"
  dest="$base/$name"
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    _tnx_extension_fail "Extension path already exists; inspect or remove it before reinstalling: $dest"
    return 1
  fi
  free_kb="$(df -Pk "$HOME" 2>/dev/null | awk 'NR==2{print $4}')"
  if [ -n "$free_kb" ] && [ "$free_kb" -lt 4194304 ] 2>/dev/null; then
    _tnx_extension_fail "$name needs about 4 GB free for the download and unpacking; only $((free_kb / 1024)) MB available. No files were installed."
    return 1
  fi

  for pkg in $TNX_HANGOVER_PACKAGES; do
    dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q 'install ok installed' ||
      missing_packages="${missing_packages:+$missing_packages }$pkg"
  done
  if [ -n "$missing_packages" ]; then
    _tnx_extension_fail "Missing Debian runtime packages: $missing_packages"
    printf '  Install them, then rerun: sudo apt install %s\n' "$missing_packages" >&2
    return 1
  fi

  mkdir -p "$base" || { _tnx_extension_fail "Cannot create extension directory: $base"; return 1; }
  tmp="$(mktemp -d "$base/.${name}.install.XXXXXX")" || { _tnx_extension_fail "Cannot create temporary install directory."; return 1; }
  url="https://github.com/AndreRH/hangover/releases/download/$TNX_HANGOVER_TAG/$asset"
  printf '[INFO] Downloading %s (about 293 MB)...\n' "$asset"
  if ! curl -fL --retry 3 --max-time 3600 -o "$tmp/$asset" "$url"; then
    rm -rf "$tmp"
    _tnx_extension_fail "The Hangover release could not be downloaded."
    return 1
  fi
  actual="$(sha256sum "$tmp/$asset" | awk '{print $1}')"
  if [ "${actual,,}" != "$TNX_HANGOVER_SHA256" ]; then
    rm -rf "$tmp"
    _tnx_extension_fail "Hangover archive SHA-256 mismatch; nothing was installed."
    return 1
  fi

  # The outer tar must contain exactly the expected flat files.
  mkdir -p "$tmp/dl" "$tmp/root"
  if ! tar -tf "$tmp/$asset" > "$tmp/contents.txt"; then
    rm -rf "$tmp"; _tnx_extension_fail "Cannot read the Hangover archive."; return 1
  fi
  while IFS= read -r member; do
    case " $TNX_HANGOVER_DEBS $TNX_HANGOVER_DXVK " in
      *" $member "*) ;;
      *) rm -rf "$tmp"; _tnx_extension_fail "Unexpected member in the Hangover archive: $member"; return 1 ;;
    esac
  done < "$tmp/contents.txt"
  if ! tar --no-same-owner -xf "$tmp/$asset" -C "$tmp/dl"; then
    rm -rf "$tmp"; _tnx_extension_fail "Cannot unpack the Hangover archive."; return 1
  fi
  rm -f "$tmp/$asset"

  for deb in $TNX_HANGOVER_DEBS; do
    if [ ! -f "$tmp/dl/$deb" ]; then
      rm -rf "$tmp"; _tnx_extension_fail "Hangover archive is missing $deb."; return 1
    fi
    want="${deb%%_*}"
    got="$(dpkg-deb -f "$tmp/dl/$deb" Package 2>/dev/null)"
    if [ "$got" != "$want" ]; then
      rm -rf "$tmp"; _tnx_extension_fail "$deb does not contain package $want."; return 1
    fi
    if ! dpkg-deb --fsys-tarfile "$tmp/dl/$deb" | tar -tv > "$tmp/listing.txt" 2>/dev/null ||
       ! awk '
         substr($1, 1, 1) == "h" { bad=1 }
         { path=$6 }
         path ~ /^\// || path ~ /(^|\/)\.\.(\/|$)/ { bad=1 }
         substr($1, 1, 1) == "l" { target=$NF; if (target ~ /^\// || target ~ /(^|\/)\.\.(\/|$)/) bad=1 }
         END { if (bad) exit 1 }
       ' "$tmp/listing.txt"; then
      rm -rf "$tmp"; _tnx_extension_fail "Unsafe path or link in $deb; nothing was installed."; return 1
    fi
    if ! dpkg-deb --fsys-tarfile "$tmp/dl/$deb" |
         tar --no-same-owner -x -C "$tmp/root" --exclude='./usr/include' --exclude='./usr/share/man'; then
      rm -rf "$tmp"; _tnx_extension_fail "Cannot unpack $deb."; return 1
    fi
  done

  stage="$tmp/pkg"
  mkdir -p "$stage/share/ternux"
  if ! mv "$tmp/root/usr/bin" "$stage/bin" || ! mv "$tmp/root/usr/lib" "$stage/lib" ||
     ! mv "$tmp/root/usr/share/wine" "$stage/share/wine"; then
    rm -rf "$tmp"; _tnx_extension_fail "Unexpected package layout; nothing was installed."; return 1
  fi
  [ -d "$tmp/root/usr/share/doc" ] && mv "$tmp/root/usr/share/doc" "$stage/share/doc"
  [ -f "$tmp/dl/$TNX_HANGOVER_DXVK" ] && mv "$tmp/dl/$TNX_HANGOVER_DXVK" "$stage/share/ternux/$TNX_HANGOVER_DXVK"

  cat > "$stage/env.sh" <<'ENVEOF'
# Ternux wine-hangover environment. Source this file; it only sets variables.
_tnx_wine_root="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
export PATH="$_tnx_wine_root/bin:$PATH"
export WINEPREFIX="${WINEPREFIX:-$HOME/.wine}"
export WINEDEBUG="${WINEDEBUG:--all}"
# GPU first, CPU fallback, following Ternux's own backend rule. A GALLIUM_DRIVER
# already in the environment wins: the Ternux desktop session exports zink on
# Adreno and virpipe (VirGL, served by the Termux host) on other GPUs, and a
# terminal inside it inherits that. Outside a session, use Zink on the Adreno
# when its KGSL node is visible (the host's /dev/kgsl-3d0, which Ternux binds
# into the guest as /dev/kgsl); otherwise leave Mesa on its CPU renderer
# (llvmpipe). GALLIUM_DRIVER=llvmpipe forces the CPU path.
if [ -z "${GALLIUM_DRIVER+x}" ]; then
  if [ -e "${TERNUX_KGSL_DEVICE:-/dev/kgsl-3d0}" ] ||
     { [ -z "${TERNUX_KGSL_DEVICE:-}" ] && [ -e /dev/kgsl ]; }; then
    export GALLIUM_DRIVER=zink
  fi
fi
unset _tnx_wine_root
ENVEOF
  cat > "$stage/build-manifest.json" <<MANIFEST
{
  "artifact": "$TNX_HANGOVER_ARTIFACT",
  "source": "https://github.com/AndreRH/hangover/releases/tag/$TNX_HANGOVER_TAG",
  "upstream_asset": "$asset",
  "upstream_sha256": "$TNX_HANGOVER_SHA256",
  "wine": "$TNX_HANGOVER_VERSION",
  "x86_64_default": "libarm64ecfex.dll (FEX)",
  "i386_default": "wowbox64.dll (Box64)",
  "status": "experimental"
}
MANIFEST

  if ! listing="$( . "$stage/env.sh" >/dev/null 2>&1; timeout 120 "$stage/bin/wine" --version 2>&1 | head -1 )" ||
     [[ "$listing" != wine-* ]]; then
    rm -rf "$tmp"
    _tnx_extension_fail "The unpacked Wine did not report a version (${listing:-no output}); nothing was installed."
    return 1
  fi

  if ! mv -T "$stage" "$dest"; then
    rm -rf "$tmp"; _tnx_extension_fail "Could not atomically install extension at $dest"; return 1
  fi
  rm -rf "$tmp"
  _tnx_extension_ok "Installed $name ($listing) at $dest"
  printf '  Experimental: not a qualified release feature. Needs a display (Termux:X11 or Xvfb).\n'
  printf '  Environment: source %s/env.sh\n' "$dest"
  printf '  First run:   WINEDLLOVERRIDES="mscoree=d;winemenubuilder.exe=d" wine wineboot -u   (about 3-4 minutes; the prefix takes about 2.3 GB)\n'
  printf '  .NET programs need wine-mono, which this extension does not install (see the guide).\n'
  printf '  Run a program: wine your_program.exe   (x86-64 default: FEX; 32-bit default: Box64)\n'
  printf '  Graphics: the Ternux session driver if set (zink or virpipe), else Zink/Turnip when a KGSL node is visible, else CPU (llvmpipe); override with GALLIUM_DRIVER.\n'
}
