# =============================================================================
#  ternux — installation phases library
#  All 11 installation phases, modular and self-contained.
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah)
#  Licensed under the Apache License, Version 2.0.
#  https://github.com/soobujmiah/ternux
# =============================================================================

# shellcheck source=lib/core.sh
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"

# ---------------------------------------------------------------------------
# UI fallback stubs (overridden by lib/ui.sh when available)
# ---------------------------------------------------------------------------
tnx_banner()       { true; }
tnx_phase_header() { tnx_info "$3"; }
tnx_celebrate()    { tnx_ok "Installation complete."; }
tnx_summary_box()  { true; }
tnx_next_steps()   { local s=("$@"); echo ""; echo "  Next steps:"; for i in "${!s[@]}"; do echo "  $((i+1)). ${s[$i]}"; done; }
tnx_spin_run()     { local l="$1"; shift; tnx_debug "$l"; "$@" 2>&1; return $?; }
tnx_frame_open()   { _TNX_FRAME_ACTIVE=0; export _TNX_FRAME_ACTIVE; }
tnx_frame_phase()  { tnx_phase_header "$@"; }
tnx_frame_stream() { cat; }
tnx_frame_close()  { true; }
tnx_frame_restore_terminal() { true; }

# Load the full installer UI when it travels beside this module (repository or
# one-click bootstrap). Its definitions deliberately replace the fallbacks.
_TNX_UI_PATH="$(dirname "${BASH_SOURCE[0]}")/ui.sh"
if [ -f "$_TNX_UI_PATH" ]; then
  # shellcheck source=lib/ui.sh
  . "$_TNX_UI_PATH"
fi
unset _TNX_UI_PATH

# ---------------------------------------------------------------------------
# Phase 1 — preflight checks
# ---------------------------------------------------------------------------
tnx_optional_storage_mb() {
  local item total=0
  for item in "$@"; do
    case "$item" in
      dev) total=$((total + 1500)) ;;       # compiler, Python and Node stack
      llm) total=$((total + 3500)) ;;       # pinned source + Vulkan build tree
      network) total=$((total + 100)) ;;
      media) total=$((total + 1300)) ;;
      git) total=$((total + 100)) ;;
      python) total=$((total + 250)) ;;
      node) total=$((total + 250)) ;;
      build) total=$((total + 800)) ;;
      rust) total=$((total + 700)) ;;
      java) total=$((total + 500)) ;;
      golang) total=$((total + 600)) ;;
      php) total=$((total + 150)) ;;
      sqlite3) total=$((total + 20)) ;;
      ripgrep) total=$((total + 10)) ;;
      jq) total=$((total + 10)) ;;
      htop|tree) total=$((total + 10)) ;;
      godot) total=$((total + 350)) ;;
      geany) total=$((total + 150)) ;;
      neovim) total=$((total + 120)) ;;
      micro) total=$((total + 30)) ;;
      thonny) total=$((total + 150)) ;;
      gh) total=$((total + 100)) ;;
      adt-build-tools|adt-platform-tools) total=$((total + 60)) ;;
      adt-ndk|adt-cmake) total=$((total + 20)) ;;
      adt-cmdline) total=$((total + 250)) ;;
      adt-platform) total=$((total + 500)) ;;
      llama-vulkan) total=$((total + 150)) ;;
      stable-diffusion) total=$((total + 250)) ;;
      llama-htp-experimental) total=$((total + 120)) ;;
      nmap) total=$((total + 80)) ;;
      tmux) total=$((total + 10)) ;;
      ffmpeg) total=$((total + 300)) ;;
      mpv) total=$((total + 250)) ;;
      gimp) total=$((total + 600)) ;;
      krita) total=$((total + 800)) ;;
      inkscape) total=$((total + 500)) ;;
      audacity) total=$((total + 300)) ;;
      imagemagick) total=$((total + 100)) ;;
      libreoffice-writer) total=$((total + 900)) ;;
      libreoffice-calc) total=$((total + 400)) ;;
      libreoffice-draw) total=$((total + 900)) ;;
      evolution) total=$((total + 450)) ;;
      celestia) total=$((total + 700)) ;;
      blender) total=$((total + 600)) ;;
      claude|codex) total=$((total + 350)) ;;
      openai-cli) total=$((total + 150)) ;;
      hermes) total=$((total + 1800)) ;;
      openclaw) total=$((total + 500)) ;;
    esac
  done
  printf '%s\n' "$total"
}

tnx_storage_estimate() {
  local optional_mb installed_mb peak_mb
  optional_mb="$(tnx_optional_storage_mb "$@")"
  installed_mb=$((4575 + optional_mb))
  peak_mb=$((installed_mb + 2048))
  awk -v installed="$installed_mb" -v peak="$peak_mb" 'BEGIN {
    printf "about %.1f GB installed; keep about %.1f GB free during downloads and setup (rough estimate)", installed/1024, peak/1024
  }'
}

tnx_phase_preflight() {
  local rc=0
  tnx_require_termux

  local arch; arch="$(uname -m)"
  case "$arch" in
    aarch64|arm64) tnx_ok "CPU architecture: $arch" ;;
    *) tnx_fail "CPU architecture is $arch — ternux needs a 64-bit ARM device."; rc=1 ;;
  esac

  TNX_DEV_ARCH="$arch"
  TNX_DEV_ANDROID="$(getprop ro.build.version.release 2>/dev/null || echo '?')"
  TNX_DEV_MODEL="$(getprop ro.product.model 2>/dev/null || echo '?')"
  TNX_DEV_RAM="$(awk '/MemTotal/{printf "%d", ($2/1048576)+0.5}' /proc/meminfo 2>/dev/null)"
  [ -n "$TNX_DEV_RAM" ] || TNX_DEV_RAM="?"

  local rel sdk
  rel="$(getprop ro.build.version.release 2>/dev/null || echo unknown)"
  sdk="$(getprop ro.build.version.sdk 2>/dev/null || echo 0)"
  if [ "$sdk" -ge 29 ] 2>/dev/null; then
    tnx_ok "Android version: $rel (SDK $sdk)"
  else
    tnx_warn "Android $rel is older than the Android 10 baseline; expect issues."
  fi

  if [ "$sdk" -ge 31 ] 2>/dev/null; then
    case "$(tnx_detect_phantom_killer)" in
      enabled)  tnx_warn "Android child-process monitoring is reported as enabled." ;;
      disabled) tnx_ok "Android child-process monitoring is reported as disabled." ;;
      *)        tnx_warn "Android 12+ detected; the child-process setting could not be read on this device." ;;
    esac
  fi

  local free target_free=6 profile="${TERNUX_INSTALL_PROFILE:-base}" size_label="~4–4.6 GB"
  local -a selected_extras=()
  if [ -n "${TERNUX_SELECTED_EXTRAS:-}" ]; then IFS=',' read -r -a selected_extras <<< "$TERNUX_SELECTED_EXTRAS"; fi
  local optional_mb estimate
  optional_mb="$(tnx_optional_storage_mb "${selected_extras[@]}")"
  target_free=$(((4575 + optional_mb + 2048 + 1023) / 1024))
  if [ "$profile" = "full" ] && [ "$target_free" -lt 14 ]; then target_free=14; fi
  estimate="$(tnx_storage_estimate "${selected_extras[@]}")"
  size_label="$estimate"
  free="$(df -Pk "$HOME" 2>/dev/null | awk 'NR==2{print int($4/1024/1024)}')"
  tnx_info "Installed-size baseline: base desktop ~4–4.6 GB; complete --all profile ~10.5–12.5 GB."
  tnx_info "Selected install estimate: $estimate. Includes the base desktop, chosen optional items and temporary setup headroom."
  if [ -n "$free" ] && [ "$free" -lt "$target_free" ]; then
    tnx_warn "Only ~${free} GB free. The ${profile} profile uses ${size_label}; keep ~${target_free} GB free before installation for downloads and package-cache headroom."
  elif [ -n "$free" ]; then
    tnx_ok "Storage: ~${free} GB free (${profile} profile; installed use ${size_label})"
  else
    tnx_warn "Could not measure free storage; base uses ~4–4.6 GB and the complete profile ~10.5–12.5 GB."
  fi

  if tnx_has_cmd curl && curl -s --max-time 5 https://1.1.1.1 >/dev/null 2>&1; then
    tnx_ok "Network: reachable (curl)"
  elif tnx_has_cmd wget && wget -q --timeout=5 -O- https://1.1.1.1 >/dev/null 2>&1; then
    tnx_ok "Network: reachable (wget)"
  else
    tnx_warn "No internet connection detected."
  fi

  [ "$rc" -eq 0 ] || { tnx_fail "Preflight failed."; return 1; }
  return 0
}

# Switch to an active, reliable fallback mirror if the user's current mirror
# returns 404 or fails during package download.
_tnx_switch_mirror() {
  local sfile="${PREFIX:-/data/data/com.termux/files/usr}/etc/apt/sources.list"
  [ -f "$sfile" ] || return 1

  local mirrors=(
    "https://packages.termux.dev/apt/termux-main"
    "https://grimler.se/termux/termux-main"
    "https://mirror.karneval.cz/pub/linux/termux/termux-main"
  )

  local current
  current="$(grep -E '^deb[[:space:]]+https?://' "$sfile" 2>/dev/null | awk '{print $2}' || true)"

  for m in "${mirrors[@]}"; do
    if [ "$current" != "$m" ]; then
      sed -i -E "s|^(deb[[:space:]]+)https?://[^[:space:]]+|\1$m|g" "$sfile"
      return 0
    fi
  done
  return 1
}

# Helper to install core Termux tools with automatic mirror fallback
# if the current mirror yields 404 or missing package archives.
_tnx_install_core_packages() {
  local apt_force="$1"
  local pkgs="pulseaudio proot-distro virglrenderer-android util-linux zsh git curl wget nano tar termux-api"

  tnx_termux_pkg install -y $apt_force $pkgs && return 0

  # Retry with refresh and fix-missing on the current repository first
  LD_LIBRARY_PATH= apt-get update -y && tnx_termux_pkg install -y --fix-missing $apt_force $pkgs && return 0

  # Automatic mirror fallback: switch to verified alternate mirrors if 404 occurs
  if _tnx_switch_mirror; then
    tnx_warn "Repository mirror failed; switched to an alternate mirror and retrying..."
    tnx_termux_pkg update -y $apt_force && tnx_termux_pkg install -y $apt_force $pkgs && return 0
  fi

  return 1
}

_tnx_host_download_tools_smoke() {
  local tool
  for tool in curl wget; do
    command -v "$tool" >/dev/null 2>&1 || { tnx_fail "Required Termux download tool is missing: $tool"; return 1; }
    "$tool" --version >/dev/null 2>&1 || { tnx_fail "Termux $tool cannot start; its linked libraries need repair."; return 1; }
  done
  return 0
}

# ---------------------------------------------------------------------------
# Phase 2 — base Termux packages
# ---------------------------------------------------------------------------
tnx_phase_packages() {
  local rc=0
  local APT_FORCE="-o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef -o APT::Color=1 -o Dpkg::Progress-Fancy=1"
  local TERMUX_PKG_NO_MIRROR_SELECT=1

  # Never launch termux-change-repo inside the persistent frame: it owns the
  # full terminal, clears the screen, and an "all mirrors" choice can trigger a
  # large availability sweep. Keep the user's current apt source for this phase;
  # if it is unreachable, the normal failure tells them to change it and resume.
  export TERMUX_PKG_NO_MIRROR_SELECT=1
  tnx_info "Using the currently configured Termux repository (automatic mirror sweep disabled)."

  # Android shared storage permission is requested only when the user runs
  # `ternux storage grant DIRECTORY`; setup itself does not expose user files.

  if ! tnx_spin_run "Refresh Termux repositories" tnx_termux_pkg update -y $APT_FORCE; then
    tnx_warn "pkg update failed; retrying the configured Termux source through apt-get."
    tnx_spin_run "Refresh Termux repositories with apt-get" tnx_termux_apt_get update -y $APT_FORCE || rc=1
  fi
  if ! tnx_spin_run "Upgrade installed Termux packages" tnx_termux_pkg upgrade -y $APT_FORCE; then
    tnx_warn "pkg upgrade failed; repairing the complete Termux package set with apt-get full-upgrade."
    if ! tnx_spin_run "Repair Termux packages with full-upgrade" tnx_termux_apt_get full-upgrade -y $APT_FORCE; then
      tnx_warn "apt-get full-upgrade failed; repairing interrupted dpkg configuration and retrying once."
      tnx_spin_run "Repair interrupted dpkg configuration" dpkg --configure -a --force-confold --force-confdef || true
      tnx_spin_run "Retry Termux full-upgrade" tnx_termux_apt_get full-upgrade -y $APT_FORCE || rc=1
    fi
  fi
  tnx_spin_run "Enable X11 and TUR repositories" tnx_termux_pkg install -y $APT_FORCE x11-repo tur-repo || rc=1
  tnx_spin_run "Install the Termux:X11 client" bash -c "LD_LIBRARY_PATH= pkg install -y $APT_FORCE termux-x11-nightly || LD_LIBRARY_PATH= pkg install -y $APT_FORCE termux-x11" || rc=1
  tnx_spin_run "Install PulseAudio, PRoot, VirGL and core tools" _tnx_install_core_packages "$APT_FORCE" || rc=1
  if ! tnx_spin_run "Verify Termux download tools" _tnx_host_download_tools_smoke; then
    tnx_warn "A Termux download tool still fails to start; running apt-get full-upgrade to repair library versions."
    if tnx_spin_run "Refresh Termux repositories with apt-get" tnx_termux_apt_get update -y $APT_FORCE &&
       tnx_spin_run "Repair Termux packages with full-upgrade" tnx_termux_apt_get full-upgrade -y $APT_FORCE; then
      tnx_spin_run "Recheck Termux download tools" _tnx_host_download_tools_smoke || rc=1
    else
      rc=1
    fi
  fi

  local backend="${1:-auto}"
  if [ "$backend" = "zink" ] || { [ "$backend" = "auto" ] && [ "$(tnx_distro)" = debian ] && [ -e "${TERNUX_KGSL_DEVICE:-/dev/kgsl-3d0}" ]; }; then
    tnx_spin_run "Install the Freedreno Vulkan ICD" tnx_termux_pkg install -y $APT_FORCE mesa-vulkan-icd-freedreno || \
      tnx_warn "Freedreno ICD unavailable"
  fi

  local missing=""
  for b in proot-distro termux-x11 pulseaudio setsid; do
    command -v "$b" >/dev/null 2>&1 || missing="$missing $b"
  done
  if [ -n "$missing" ]; then
    tnx_fail "Still missing after install:$missing"
    return 1
  fi

  [ "$rc" -eq 0 ] || return 1
  tnx_ok "Base packages installed and verified."
}

# ---------------------------------------------------------------------------
# Debian-side companion CLI
# ---------------------------------------------------------------------------
# The Android lifecycle CLI cannot safely be run from inside its own PRoot
# guest: doing so would inherit the guest HOME/PATH and attempt a nested PRoot
# login. Install a small guest-aware companion instead. It provides local
# status/verification and explicitly redirects host-only operations to Termux.
tnx_install_guest_cli() {
  local user_name="${1:-ternux}" guest_src="" cleanup=0 try=""
  local source_commit="${TERNUX_SOURCE_COMMIT:-}" guest_sha256="${TERNUX_GUEST_CLI_SHA256:-}"
  if [ -n "${_TNX_SRC:-}" ] && [ -f "$_TNX_SRC/bin/ternux-guest" ]; then
    guest_src="$_TNX_SRC/bin/ternux-guest"
  else
    for try in "$(dirname "${BASH_SOURCE[0]}")/../bin/ternux-guest" \
               "$(dirname "$0")/bin/ternux-guest"; do
      [ -f "$try" ] && { guest_src="$try"; break; }
    done
  fi

  if [ -z "$guest_src" ]; then
    guest_src="${TMPDIR:-/tmp}/ternux-guest.$$"
    cleanup=1
    if [[ ! "$source_commit" =~ ^[a-f0-9]{40}$ || ! "$guest_sha256" =~ ^[a-f0-9]{64}$ ]]; then
      tnx_fail "Pinned Debian guest companion identity is missing or invalid."
      rm -f "$guest_src"
      return 1
    fi
    tnx_has_cmd sha256sum || {
      tnx_fail "sha256sum is required to verify the Debian guest companion."
      rm -f "$guest_src"
      return 1
    }
    tnx_info "Downloading pinned Debian guest companion ($source_commit)..."
    tnx_download "https://raw.githubusercontent.com/soobujmiah/ternux/$source_commit/bin/ternux-guest" "$guest_src" || {
      tnx_fail "Could not download the Debian guest companion."
      rm -f "$guest_src"
      return 1
    }
    if ! printf "%s  %s\n" "$guest_sha256" "$guest_src" | sha256sum --check --status; then
      tnx_fail "Downloaded Debian guest companion failed its pinned SHA-256 check."
      rm -f "$guest_src"
      return 1
    fi
  fi

  if ! bash -n "$guest_src" 2>/dev/null; then
    tnx_fail "Debian guest companion failed shell syntax validation."
    [ "$cleanup" -eq 1 ] && rm -f "$guest_src"
    return 1
  fi

  if ! tnx_guest_login -- bash -c '
    set -e
    tmp=/usr/local/bin/.ternux.new
    umask 022
    cat > "$tmp"
    chmod 0755 "$tmp"
    mv -f "$tmp" /usr/local/bin/ternux
  ' < "$guest_src"; then
    tnx_fail "Could not install /usr/local/bin/ternux inside guest '$(tnx_distro)'."
    [ "$cleanup" -eq 1 ] && rm -f "$guest_src"
    return 1
  fi
  [ "$cleanup" -eq 1 ] && rm -f "$guest_src"

  local guest_version=""
  guest_version="$(tnx_guest_login --user "$user_name" -- bash -lc \
    'command -v ternux >/dev/null && ternux --version' 2>/dev/null)" || {
    tnx_fail "Guest companion was written but could not execute for '$user_name': ${guest_version:-unknown error}"
    return 1
  }
  case "$guest_version" in
    "ternux guest v${TERNUX_VERSION}"|"ternux guest v${TERNUX_VERSION}"$'\n'*) ;;
    *)
      tnx_fail "Guest companion returned an unexpected version response: $guest_version"
      return 1
      ;;
  esac
  tnx_ok "Guest companion installed and verified for '$(tnx_distro)': /usr/local/bin/ternux"
  tnx_state_set "guest_cli_installed" "yes"
  return 0
}

# ---------------------------------------------------------------------------
# Phase 4 — selected guest + Xfce4 + user
# ---------------------------------------------------------------------------
tnx_phase_debian() {
  local user_name="${1:-ternux}" package_family input_engine=ibus-avro
  [ "$(tnx_distro)" != alpine ] || input_engine=m17n:bn:avro-phonetic
  local resource_dir="${BASH_SOURCE[0]%/*}"
  local welcome_b64 welcome_gui_b64 window_fit_b64 camera_gui_b64 recorder_gui_b64 flashlight_gui_b64 panel_shortcuts_b64 ternux_assets_b64 proot_bwrap_b64 gtk3_user_css_b64 gtk4_user_css_b64 firefox_installer_b64 resource
  for resource in ternux-welcome.sh ternux-welcome-gui.py ternux-window-fit.lua ternux-camera.py ternux-recorder.py ternux-flashlight.py ternux-panel-shortcuts.sh ternux-assets/bin/ternux-proot-bwrap ternux-assets/bin/ternux-rasterize-icons ternux-assets/bin/ternux-ibus-session-init ternux-assets/bin/ternux-ibus-next-engine ternux-assets/bin/ternux-window-fit-x11 ternux-assets/bin/ternux-session-bus; do
    if [ ! -s "$resource_dir/$resource" ] || [ ! -r "$resource_dir/$resource" ]; then
      tnx_fail "Required Ternux desktop resource is missing or unreadable: $resource_dir/$resource"
      return 1
    fi
  done
  if [ ! -d "$resource_dir/ternux-assets/icons/Ternux" ] || [ ! -d "$resource_dir/ternux-assets/wallpapers" ] || [ ! -d "$resource_dir/ternux-assets/themes/Ternux" ] || [ ! -d "$resource_dir/ternux-assets/input-methods" ] || [ ! -x "$resource_dir/ternux-assets/bin/ternux-install-avro-m17n" ] || [ ! -s "$resource_dir/ternux-assets/bin/ternux-proot-faccessat-arm64.so" ] || [ ! -s "$resource_dir/ternux-assets/bin/ternux-proot-faccessat.c" ]; then
    tnx_fail "Required Ternux desktop branding assets are missing under $resource_dir/ternux-assets"
    return 1
  fi
  welcome_b64="$(set -o pipefail; base64 < "$resource_dir/ternux-welcome.sh" | tr -d '\n')" || return 1
  welcome_gui_b64="$(set -o pipefail; base64 < "$resource_dir/ternux-welcome-gui.py" | tr -d '\n')" || return 1
  window_fit_b64="$(set -o pipefail; base64 < "$resource_dir/ternux-window-fit.lua" | tr -d '\n')" || return 1
  camera_gui_b64="$(set -o pipefail; base64 < "$resource_dir/ternux-camera.py" | tr -d '\n')" || return 1
  recorder_gui_b64="$(set -o pipefail; base64 < "$resource_dir/ternux-recorder.py" | tr -d '\n')" || return 1
  flashlight_gui_b64="$(set -o pipefail; base64 < "$resource_dir/ternux-flashlight.py" | tr -d '\n')" || return 1
  panel_shortcuts_b64="$(set -o pipefail; base64 < "$resource_dir/ternux-panel-shortcuts.sh" | tr -d '\n')" || return 1
  ternux_assets_b64="$(set -o pipefail; tar -czf - -C "$resource_dir/ternux-assets" icons wallpapers themes applications bin input-methods | base64 | tr -d '\n')" || return 1
  proot_bwrap_b64="$(set -o pipefail; base64 < "$resource_dir/ternux-assets/bin/ternux-proot-bwrap" | tr -d '\n')" || return 1
  gtk3_user_css_b64="$(set -o pipefail; base64 < "$resource_dir/ternux-assets/themes/Ternux/gtk-3.0/gtk-user.css" | tr -d '\n')" || return 1
  gtk4_user_css_b64="$(set -o pipefail; base64 < "$resource_dir/ternux-assets/themes/Ternux/gtk-4.0/gtk-user.css" | tr -d '\n')" || return 1
  firefox_installer_b64="$(set -o pipefail; base64 < "$resource_dir/ternux-install-firefox-esr.sh" | tr -d '\n')" || return 1

  if tnx_debian_installed; then
    tnx_warn "Guest '$(tnx_distro)' already installed; reusing it."
  else
    proot-distro install "$(tnx_distro)" || { tnx_fail "Guest '$(tnx_distro)' install failed."; return 1; }
  fi

  tnx_distro_profile "$(tnx_distro)" || { tnx_fail "No package recipe for guest '$(tnx_distro)'."; return 2; }
  package_family="$TNX_DP_FAMILY"
  # Minimal Alpine images provide POSIX sh but not Bash. This first package
  # bootstrap installs Bash itself, so it must run through sh.
  tnx_guest_login --shared-tmp -- sh -c "
    set -e
    FAMILY='$package_family'
    BWRAP_SHIM_B64='$proot_bwrap_b64'
    export DEBIAN_FRONTEND=noninteractive
    install_proot_bwrap_shim() {
      install -d -m 0755 /usr/local/bin
      printf '%s' "\$BWRAP_SHIM_B64" | base64 -d > /usr/local/bin/.ternux-bwrap.new
      chmod 0755 /usr/local/bin/.ternux-bwrap.new
      mv -f /usr/local/bin/.ternux-bwrap.new /usr/local/bin/bwrap
    }
    pkg_retry() {
      attempt=1
      while ! "\$@"; do
        if [ "\$attempt" -ge 3 ]; then return 1; fi
        echo \"[WARN] Package command failed; retrying (\$((attempt + 1))/3): \$*\" >&2
        sleep "\$attempt"
        attempt=\$((attempt + 1))
      done
    }
    DPKG_FORCE=\"-o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef -o APT::Color=1 -o Dpkg::Progress-Fancy=1 -o Acquire::Retries=3\"
    case \"\$FAMILY\" in
      apt)
        apt update -o APT::Color=1 -o Acquire::Retries=3
        dpkg --configure -a --force-confold --force-confdef || true
        install_proot_bwrap_shim
        if [ '$(tnx_distro)' = ubuntu ]; then
          install -d -m 0755 /etc/apt/preferences.d
          printf 'Package: snapd\nPin: version *\nPin-Priority: -1\n' > /etc/apt/preferences.d/ternux-no-snapd
          apt-mark hold snapd >/dev/null 2>&1 || true
        fi
        apt install -y -o APT::Install-Recommends=false \$DPKG_FORCE sudo nano ca-certificates mousepad galculator evince fonts-noto-core python3-gi python3-xlib gir1.2-gtk-3.0 ibus ibus-avro devilspie2 dbus-x11 pulseaudio pulseaudio-utils pavucontrol x11-utils x11-xkb-utils mesa-utils libgl1-mesa-dri libvulkan1 mesa-vulkan-drivers vulkan-tools adwaita-icon-theme xfce4 xfce4-taskmanager xfce4-terminal zenity vlc ffmpeg ristretto qt5-gtk-platformtheme colord xdg-utils desktop-file-utils util-linux libglib2.0-bin gsettings-desktop-schemas xfconf
        apt install -y \$DPKG_FORCE --no-install-recommends synaptic
        if [ '$(tnx_distro)' = ubuntu ]; then apt-mark hold snapd >/dev/null 2>&1 || true; fi
        apt remove -y \$DPKG_FORCE guvcview >/dev/null 2>&1 || true
        ;;
      apk)
        pkg_retry apk update
        if [ '$(tnx_distro)' = alpine ]; then install_proot_bwrap_shim; fi
        pkg_retry apk add sudo bash shadow musl-utils nano mousepad galculator evince font-noto python3 py3-xlib py3-gobject3 gtk+3.0 glib ibus dbus-x11 pulseaudio pulseaudio-utils pavucontrol mesa mesa-dri-gallium mesa-utils vulkan-loader vulkan-tools desktop-file-utils xdg-utils xdpyinfo setxkbmap util-linux fontconfig gsettings-desktop-schemas xfconf adwaita-icon-theme xfce4 xfce4-taskmanager xfce4-terminal zenity vlc ffmpeg ristretto qt5-qtbase colord
        if [ "$(tnx_distro)" = alpine ]; then
          pkg_retry apk add vlc-qt m17n-lib m17n-db font-noto-bengali rsvg-convert xrdb
        fi
        if [ "$(tnx_distro)" = chimera ]; then pkg_retry apk add mesa-vulkan; elif [ "$(tnx_distro)" = alpine ]; then pkg_retry apk add mesa-vulkan-freedreno; fi
        ;;
      pacman)
        pacman -Syu --noconfirm --needed
        install_proot_bwrap_shim
        pacman -S --noconfirm --needed sudo bash nano mousepad galculator evince noto-fonts python-gobject gtk3 glib2 ibus devilspie2 xorg-xhost xorg-setxkbmap pulseaudio pavucontrol mesa mesa-utils vulkan-icd-loader vulkan-freedreno vulkan-tools xorg-xdpyinfo xdg-utils desktop-file-utils util-linux fontconfig gsettings-desktop-schemas xfconf adwaita-icon-theme xfce4 xfce4-goodies xfce4-terminal zenity vlc ffmpeg ristretto qt5ct colord
        ;;
      dnf)
        install_proot_bwrap_shim
        dnf install -y sudo bash nano mousepad galculator evince google-noto-sans-fonts python3-gobject gtk3 glib2 ibus devilspie2 dbus-x11 pulseaudio pulseaudio-utils pavucontrol mesa-dri-drivers mesa-vulkan-drivers vulkan-loader vulkan-tools glx-utils xorg-x11-utils setxkbmap xdg-utils desktop-file-utils util-linux fontconfig gsettings-desktop-schemas xfconf adwaita-icon-theme xfce4-panel xfce4-session xfce4-settings xfce4-terminal xfce4-taskmanager zenity vlc ffmpeg ristretto qt5-qtbase colord
        ;;
      zypper)
        zypper --non-interactive refresh
        install_proot_bwrap_shim
        zypper --non-interactive install -y sudo bash nano mousepad galculator evince google-noto-sans-fonts python3-gobject gtk3 glib2-tools ibus dbus-1-x11 pulseaudio pulseaudio-utils pavucontrol Mesa-dri Mesa-demo-x libvulkan1 libvulkan_freedreno vulkan-tools xorg-x11-utils setxkbmap xdg-utils desktop-file-utils util-linux fontconfig gsettings-desktop-schemas xfconf adwaita-icon-theme xfce4-panel xfce4-session xfce4-settings xfce4-terminal xfce4-taskmanager zenity vlc ffmpeg ristretto libqt5-qtbase colord
        ;;
      xbps)
        xbps-install -Suy
        install_proot_bwrap_shim
        xbps-install -Sy sudo bash nano mousepad galculator evince noto-fonts-ttf python3-gobject gtk+3 glib ibus dbus pulseaudio pulseaudio-utils pavucontrol mesa-dri mesa-demos vulkan-loader mesa-vulkan-freedreno vulkan-tools setxkbmap xdg-utils desktop-file-utils util-linux fontconfig gsettings-desktop-schemas xfconf adwaita-icon-theme xfce4 xfce4-terminal xfce4-taskmanager zenity vlc ffmpeg ristretto qt5-base colord
        ;;
      *) echo \"Unsupported package manager family: \$FAMILY\" >&2; exit 2 ;;
    esac
    rm -f /usr/local/share/applications/guvcview.desktop
    asset_stage=\$(mktemp -d /tmp/ternux-assets.XXXXXX)
    printf '%s' '$ternux_assets_b64' | base64 -d | tar -xz -C "\$asset_stage"
    find "\$asset_stage" -type d -exec chmod 0755 {} +
    find "\$asset_stage" -type f -exec chmod 0644 {} +
    install -d -m 0755 /usr/share/icons /usr/share/themes/Ternux /usr/share/backgrounds/ternux
    # Replace the managed theme as one staged tree. Overlay copies leave old
    # icon aliases behind when an asset moves between contexts or is retired.
    icon_stage=\$(mktemp -d /usr/share/icons/.Ternux-stage.XXXXXX)
    icon_backup="/usr/share/icons/.Ternux-backup.\$\$"
    if ! cp -a "\$asset_stage/icons/Ternux/." "\$icon_stage/"; then
      rm -rf "\$icon_stage"
      exit 1
    fi
    chmod 0755 "\$icon_stage"
    if [ -e "\$icon_backup" ]; then
      rm -rf "\$icon_stage"
      printf '%s\\n' 'A Ternux icon rollback directory already exists; refusing to replace the theme.' >&2
      exit 1
    fi
    if [ -e /usr/share/icons/Ternux ]; then
      mv -T /usr/share/icons/Ternux "\$icon_backup"
    fi
    if mv -T "\$icon_stage" /usr/share/icons/Ternux; then
      [ ! -e "\$icon_backup" ] || rm -rf "\$icon_backup"
    else
      [ ! -e "\$icon_backup" ] || mv -T "\$icon_backup" /usr/share/icons/Ternux
      exit 1
    fi
    cp -a "\$asset_stage/themes/Ternux/." /usr/share/themes/Ternux/
    install -m 0755 "\$asset_stage/bin/ternux-open-url" /usr/local/bin/ternux-open-url
    if [ "\$FAMILY" = apt ]; then
      install -m 0755 "\$asset_stage/bin/ternux-app-center" /usr/local/bin/ternux-app-center
    else
      rm -f /usr/local/bin/ternux-app-center
    fi
    install -m 0755 "\$asset_stage/bin/evolution" /usr/local/bin/evolution
    install -m 0755 "\$asset_stage/bin/ternux-install-celestia" /usr/local/bin/ternux-install-celestia
    install -d -m 0755 /usr/local/share/applications
    if [ -f /usr/share/applications/org.gnome.Evolution.desktop ]; then
      sed 's#^Exec=evolution#Exec=/usr/local/bin/evolution#' /usr/share/applications/org.gnome.Evolution.desktop > /usr/local/share/applications/org.gnome.Evolution.desktop
      chmod 0644 /usr/local/share/applications/org.gnome.Evolution.desktop
    fi
    if [ "\$FAMILY" = apt ]; then
      install -m 0644 "\$asset_stage/applications/synaptic.desktop" /usr/local/share/applications/synaptic.desktop
    else
      rm -f /usr/local/share/applications/ternux-app-center.desktop /usr/local/share/applications/synaptic.desktop
    fi
    install -m 0644 "\$asset_stage/applications/ternux-sdcard.desktop" /usr/share/applications/ternux-sdcard.desktop
    install -m 0644 "\$asset_stage/applications/ternux-flashlight.desktop" /usr/share/applications/ternux-flashlight.desktop
    for panel_entry in ternux-file-manager.desktop ternux-terminal.desktop ternux-web-browser.desktop ternux-appfinder.desktop; do
      install -m 0644 "\$asset_stage/applications/\$panel_entry" "/usr/share/applications/\$panel_entry"
    done
    rm -f /usr/share/backgrounds/ternux/aurora.svg
    cp -a "\$asset_stage/wallpapers/." /usr/share/backgrounds/ternux/
    if [ "\$FAMILY" = apk ] && [ "$(tnx_distro)" = alpine ]; then sh "\$asset_stage/bin/ternux-install-avro-m17n" "\$asset_stage/input-methods"; fi
    if [ "$(tnx_distro)" = alpine ]; then
      install -d -m 0755 /usr/local/share/applications
      cat > /usr/local/share/applications/vlc.desktop <<'VLC_DESKTOP'
[Desktop Entry]
Name=VLC media player
Comment=Play movies and music
Exec=/usr/bin/vlc --started-from-file %U
Icon=vlc
Terminal=false
Type=Application
Categories=AudioVideo;Player;
MimeType=audio/mpeg;audio/ogg;audio/flac;video/mp4;video/mpeg;video/quicktime;video/x-matroska;
StartupNotify=true
VLC_DESKTOP
      chmod 0644 /usr/local/share/applications/vlc.desktop
      update-desktop-database /usr/local/share/applications >/dev/null 2>&1 || true
    fi
    if [ "\$FAMILY" = apk ] && [ "$(tnx_distro)" = alpine ]; then
      install -m 0755 "\$asset_stage/bin/ternux-rasterize-icons" /usr/local/bin/ternux-rasterize-icons
      /usr/local/bin/ternux-rasterize-icons /usr/share/icons/Ternux
      install -d -m 0755 /usr/local/lib/ternux
      install -m 0644 "\$asset_stage/bin/ternux-proot-faccessat-arm64.so" /usr/local/lib/ternux/libternux-faccessat.so
    fi
    install -m 0755 "\$asset_stage/bin/ternux-ibus-session-init" /usr/local/bin/ternux-ibus-session-init
    install -m 0755 "\$asset_stage/bin/ternux-ibus-next-engine" /usr/local/bin/ternux-ibus-next-engine
    install -m 0755 "\$asset_stage/bin/ternux-session-bus" /usr/local/bin/ternux-session-bus
    install -m 0755 "\$asset_stage/bin/ternux-window-fit-x11" /usr/local/bin/ternux-window-fit-x11
    rm -rf "\$asset_stage"
    gtk-update-icon-cache -f /usr/share/icons/Ternux >/dev/null 2>&1 || true
    for icon_pair in \
      'ibus-setup-ibus-avro.desktop ternux-avro' \
      'python3.13.desktop ternux-python' \
      'im-config.desktop ternux-keyboard' \
      'panel-desktop-handler.desktop ternux-launcher' \
      'xfce4-web-browser.desktop org.xfce.webbrowser'; do
      set -- \${icon_pair% *} \${icon_pair#* }
      source_entry="/usr/share/applications/\$1"
      if [ -r "\$source_entry" ]; then
        sed "s#^Icon=.*#Icon=\$2#" "\$source_entry" > "/usr/local/share/applications/\$1"
        if [ "\$1" = xfce4-web-browser.desktop ]; then
          sed -i 's#^Exec=.*#Exec=/usr/local/bin/ternux-open-url %u#' "/usr/local/share/applications/\$1"
        fi
        chmod 0644 "/usr/local/share/applications/\$1"
      fi
    done
    if [ "\$FAMILY" = apt ]; then
      apt install -y \$DPKG_FORCE polkitd || apt install -y \$DPKG_FORCE policykit-1 || true
      apt install -y \$DPKG_FORCE libvulkan1 vulkan-tools || true
      apt install -y \$DPKG_FORCE zip unzip xarchiver unrar-free || true
      apt install -y \$DPKG_FORCE 7zip || apt install -y \$DPKG_FORCE p7zip-full || true
    fi
    # Every fresh profile gets one usable browser. Ubuntu's archive package is
    # a Snap bridge, so use Mozilla ESR there while Snap remains disabled.
    case "\$FAMILY" in
      apt)
        if [ '$(tnx_distro)' = ubuntu ]; then
          apt install -y \$DPKG_FORCE curl
          printf '%s' '$firefox_installer_b64' | base64 -d | bash
        else
          browser_installed=0
          for browser_package in firefox-esr firefox; do
            browser_candidate=\"\$(apt-cache policy \"\$browser_package\" 2>/dev/null | awk '/^[[:space:]]*Candidate:/ {print \$2; exit}')\"
            if [ -n "\$browser_candidate" ] && [ "\$browser_candidate" != '(none)' ] && apt install -y \$DPKG_FORCE "\$browser_package"; then browser_installed=1; break; fi
          done
          [ "\$browser_installed" -eq 1 ] || { echo 'No usable Firefox package candidate is available in this APT guest.' >&2; exit 1; }
        fi
        ;;
      apk) pkg_retry apk add firefox-esr || pkg_retry apk add firefox ;;
      pacman) pkg_retry pacman -S --noconfirm --needed firefox ;;
      dnf) pkg_retry dnf install -y firefox ;;
      zypper) pkg_retry zypper --non-interactive install -y MozillaFirefox ;;
      xbps) pkg_retry xbps-install -Sy firefox ;;
    esac
  " || { tnx_fail "Desktop package installation failed."; return 1; }

  tnx_guest_login --shared-tmp -- bash -c "
    set -e
    U='${user_name}'
    FAMILY='${package_family}'
    if ! id -u \"\$U\" >/dev/null 2>&1; then
      if [ \"\$FAMILY\" = apk ]; then adduser -D \"\$U\"; else useradd -m -s /bin/bash \"\$U\"; fi
    fi
    case \"\$FAMILY\" in pacman|dnf|zypper|xbps) ADMIN_GROUP=wheel ;; *) ADMIN_GROUP=sudo ;; esac
    for grp in \"\$ADMIN_GROUP\" video render audio; do getent group \"\$grp\" >/dev/null 2>&1 && usermod -aG \"\$grp\" \"\$U\" || true; done
    install -d -m 0750 /etc/sudoers.d
    F=/etc/sudoers.d/ternux; T=\"\$(mktemp /tmp/ternux-sudoers.XXXXXX)\"
    if grep -Eq '^[[:space:]]*[@#]includedir[[:space:]]+/etc/sudoers[.]d([[:space:]]|$)' /etc/sudoers; then
      printf '%s ALL=(ALL) NOPASSWD: ALL\n' \"\$U\" > \"\$T\"
      if visudo -cf \"\$T\" >/dev/null 2>&1; then install -m 0440 -o root -g root \"\$T\" \"\$F\"; else rm -f \"\$T\"; exit 1; fi
    else
      cat /etc/sudoers > \"\$T\"
      printf '\n%s ALL=(ALL) NOPASSWD: ALL\n' \"\$U\" >> \"\$T\"
      if visudo -cf \"\$T\" >/dev/null 2>&1; then install -m 0440 -o root -g root \"\$T\" /etc/sudoers; else rm -f \"\$T\"; exit 1; fi
    fi
    rm -f \"\$T\"
    H=\"\$(getent passwd \"\$U\" | cut -d: -f6)\"
    gtk_theme_install_override() {
      gtk_theme_version=\"\$1\"
      gtk_theme_payload=\"\$2\"
      gtk_theme_dir=\"\$H/.config/gtk-\$gtk_theme_version\"
      gtk_theme_file=\"\$gtk_theme_dir/gtk.css\"
      [ ! -L \"\$gtk_theme_dir\" ] && [ ! -L \"\$gtk_theme_file\" ] || { echo \"Refusing symlinked GTK theme config for user \$U\" >&2; return 1; }
      install -d -o \"\$U\" -g \"\$U\" -m 0755 \"\$gtk_theme_dir\"
      gtk_theme_tmp=\"\$(mktemp \"\$gtk_theme_dir/.ternux-gtk.css.XXXXXX\")\"
      if [ -f \"\$gtk_theme_file\" ]; then
        sed '/^\/\* TERNUX MANAGED GTK OVERRIDE BEGIN \*\/$/,/^\/\* TERNUX MANAGED GTK OVERRIDE END \*\/$/d' \"\$gtk_theme_file\" > \"\$gtk_theme_tmp\"
      fi
      printf '%s\n' '/* TERNUX MANAGED GTK OVERRIDE BEGIN */' >> \"\$gtk_theme_tmp\"
      printf '%s' \"\$gtk_theme_payload\" | base64 -d >> \"\$gtk_theme_tmp\"
      printf '\n%s\n' '/* TERNUX MANAGED GTK OVERRIDE END */' >> \"\$gtk_theme_tmp\"
      install -o \"\$U\" -g \"\$U\" -m 0644 \"\$gtk_theme_tmp\" \"\$gtk_theme_file\"
      rm -f \"\$gtk_theme_tmp\"
    }
    # Prepare the per-user IBus runtime and cache paths.
    install -d -o "\$U" -g "\$U" -m 0700 "\$H/.cache" "\$H/.cache/ibus" "\$H/.config/ibus"
    gtk_theme_install_override 3.0 '${gtk3_user_css_b64}'
    gtk_theme_install_override 4.0 '${gtk4_user_css_b64}'
    install -d -o \"\$U\" -g \"\$U\" -m 0755 \"\$H/.config/gtk-3.0\"
    bookmarks=\"\$H/.config/gtk-3.0/bookmarks\"
    touch \"\$bookmarks\"
    grep -Fxq 'file:///sdcard SD Card' \"\$bookmarks\" || printf '%s\n' 'file:///sdcard SD Card' >> \"\$bookmarks\"
    chown \"\$U:\$U\" \"\$bookmarks\"
    chmod 0644 \"\$bookmarks\"
    install -d -o \"\$U\" -g \"\$U\" -m 0755 \"\$H/Pictures\"
    if [ -L \"\$H/Pictures/Ternux\" ] && [ \"\$(readlink \"\$H/Pictures/Ternux\")\" = /sdcard/Pictures/Ternux ]; then
      rm \"\$H/Pictures/Ternux\"
    fi
    install -d -o \"\$U\" -g \"\$U\" -m 0755 \"\$H/Pictures/Ternux\"
    install -d -o \"\$U\" -g \"\$U\" -m 0755 \"\$H/Music/Ternux\"
    install -d -o \"\$U\" -g \"\$U\" -m 0755 \"\$H/.config/xfce4/terminal\"
    if [ ! -e \"\$H/.config/xfce4/terminal/terminalrc\" ]; then
      cat > \"\$H/.config/xfce4/terminal/terminalrc\" <<'TERMINAL'
[Configuration]
ColorForeground=#e4f3eb
ColorBackground=#101816
ColorCursor=#39e68c
ColorSelection=#08784c
ColorPalette=#26332d;#ff5c57;#5af78e;#f3f99d;#57c7ff;#ff6ac1;#9aedfe;#e4f3eb;#4b5b52;#ff5c57;#5af78e;#f3f99d;#57c7ff;#ff6ac1;#9aedfe;#ffffff
BackgroundMode=TERMINAL_BACKGROUND_SOLID
BackgroundDarkness=0.97
FontName=Monospace 10
MiscBell=FALSE
TERMINAL
      chown \"\$U:\$U\" \"\$H/.config/xfce4/terminal/terminalrc\"
      chmod 0644 \"\$H/.config/xfce4/terminal/terminalrc\"
    fi
    install -d -o \"\$U\" -g \"\$U\" -m 0755 \"\$H/.config/vlc\"
    touch \"\$H/.config/vlc/vlcrc\"
    sed -i '/^[[:space:]]*vout=/d' \"\$H/.config/vlc/vlcrc\"
    printf '%s\n' 'vout=xcb_x11' >> \"\$H/.config/vlc/vlcrc\"
    sed -i '/^[[:space:]]*avcodec-hw=/d' \"\$H/.config/vlc/vlcrc\"
    printf '%s\n' 'avcodec-hw=none' >> \"\$H/.config/vlc/vlcrc\"
    sed -i '/^[[:space:]]*qt-minimal-view=/d' \"\$H/.config/vlc/vlcrc\"
    printf '%s\n' 'qt-minimal-view=0' >> \"\$H/.config/vlc/vlcrc\"
    sed -i '/^[[:space:]]*qt-video-autoresize=/d' \"\$H/.config/vlc/vlcrc\"
    printf '%s\n' 'qt-video-autoresize=0' >> \"\$H/.config/vlc/vlcrc\"
    sed -i '/^[[:space:]]*qt-system-tray=/d' \"\$H/.config/vlc/vlcrc\"
    printf '%s\n' 'qt-system-tray=0' >> \"\$H/.config/vlc/vlcrc\"
    # Keep local video startup quiet and skip online metadata lookups.
    sed -i '/^[[:space:]]*metadata-network-access=/d' "\$H/.config/vlc/vlcrc"
    printf '%s\n' 'metadata-network-access=0' >> "\$H/.config/vlc/vlcrc"
    sed -i '/^[[:space:]]*qt-privacy-ask=/d' "\$H/.config/vlc/vlcrc"
    printf '%s\n' 'qt-privacy-ask=0' >> "\$H/.config/vlc/vlcrc"
    # Use Debian's stock application entry and process so menu launches
    # inherit the same global Xfce theme and environment as other GTK apps.
    rm -f /usr/local/bin/ternux-volume-control /usr/local/bin/pavucontrol \
      /usr/local/share/applications/org.pulseaudio.pavucontrol.desktop
    install -d -o \"\$U\" -g \"\$U\" -m 0755 \"\$H/.config/devilspie2\"
    printf '%s' '${window_fit_b64}' | base64 -d > \"\$H/.config/devilspie2/window-fit.lua\"
    chown \"\$U:\$U\" \"\$H/.config/devilspie2/window-fit.lua\"
    chmod 0644 \"\$H/.config/devilspie2/window-fit.lua\"
    runuser -u \"\$U\" -- env HOME=\"\$H\" dbus-run-session -- gsettings set org.freedesktop.ibus.general preload-engines \"['xkb:us::eng', '$input_engine']\"
    runuser -u \"\$U\" -- env HOME=\"\$H\" dbus-run-session -- gsettings set org.freedesktop.ibus.general engines-order \"['xkb:us::eng', '$input_engine']\"
    # Keep Ctrl+Space visible as IBus's Next input method key. XFCE also
    # routes it globally for apps that do not register an IBus input context.
    runuser -u \"\$U\" -- env HOME=\"\$H\" dbus-run-session -- gsettings set org.freedesktop.ibus.general.hotkey triggers \"[]\"
    runuser -u \"\$U\" -- env HOME=\"\$H\" dbus-run-session -- sh -c 'gsettings writable org.freedesktop.ibus.general.hotkey trigger >/dev/null 2>&1 && gsettings set org.freedesktop.ibus.general.hotkey trigger "[]" || true'
    runuser -u \"\$U\" -- env HOME=\"\$H\" dbus-run-session -- gsettings set org.freedesktop.ibus.general.hotkey next-engine \"['Control+space']\"
    runuser -u \"\$U\" -- env HOME=\"\$H\" dbus-run-session -- gsettings set org.freedesktop.ibus.general.hotkey next-engine-in-menu \"[]\"
    runuser -u \"\$U\" -- env HOME=\"\$H\" dbus-run-session -- gsettings set org.gnome.desktop.interface gtk-theme Ternux
    install -d -o \"\$U\" -g \"\$U\" -m 0755 \"\$H/.config/autostart\"
    install -d -o root -g root -m 0755 /usr/local/bin
    printf '%s' '${camera_gui_b64}' | base64 -d > /usr/local/bin/ternux-camera
    chown root:root /usr/local/bin/ternux-camera
    chmod 0755 /usr/local/bin/ternux-camera
    printf '%s' '${recorder_gui_b64}' | base64 -d > /usr/local/bin/ternux-recorder
    chown root:root /usr/local/bin/ternux-recorder
    chmod 0755 /usr/local/bin/ternux-recorder
    printf '%s' '${flashlight_gui_b64}' | base64 -d > /usr/local/bin/ternux-flashlight
    chown root:root /usr/local/bin/ternux-flashlight
    chmod 0755 /usr/local/bin/ternux-flashlight
    printf '%s' '${panel_shortcuts_b64}' | base64 -d > /usr/local/bin/ternux-panel-shortcuts
    chown root:root /usr/local/bin/ternux-panel-shortcuts
    chmod 0755 /usr/local/bin/ternux-panel-shortcuts
    cat > /usr/share/applications/ternux-camera.desktop <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Ternux Camera
Comment=Capture photos with the Android front or rear camera
Exec=/usr/local/bin/ternux-camera
Icon=ternux-camera
Terminal=false
Categories=AudioVideo;Photography;
StartupNotify=true
DESKTOP
    chmod 0644 /usr/share/applications/ternux-camera.desktop
    cat > /usr/share/applications/ternux-recorder.desktop <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Ternux Sound Recorder
Comment=Record on demand from the Android microphone
Exec=/usr/local/bin/ternux-recorder
Icon=ternux-recorder
Terminal=false
Categories=AudioVideo;Audio;Recorder;
StartupNotify=true
DESKTOP
    chmod 0644 /usr/share/applications/ternux-recorder.desktop
    cat > /usr/share/applications/ternux-photos.desktop <<DESKTOP
[Desktop Entry]
Type=Application
Name=Ternux Photos
Comment=Browse captured photos in the Ternux Pictures folder
Exec=ristretto /home/${user_name}/Pictures/Ternux
Icon=org.xfce.ristretto
Terminal=false
Categories=Graphics;Photography;
StartupNotify=true
DESKTOP
    chmod 0644 /usr/share/applications/ternux-photos.desktop
    install -d -m 0755 /usr/local/share/applications
    for vlc_entry in /usr/share/applications/vlc*.desktop; do
      [ -f "\$vlc_entry" ] || continue
      sed 's#^Exec=#Exec=env QT_QPA_PLATFORMTHEME=gtk3 #' "\$vlc_entry" > "/usr/local/share/applications/\${vlc_entry##*/}"
      chmod 0644 "/usr/local/share/applications/\${vlc_entry##*/}"
    done
    update-desktop-database /usr/local/share/applications >/dev/null 2>&1 || true
    install -d -o "\$U" -g "\$U" -m 0755 "\$H/Desktop"
    cp /usr/share/applications/ternux-camera.desktop "\$H/Desktop/Ternux-Camera.desktop"
    cp /usr/share/applications/ternux-photos.desktop "\$H/Desktop/Ternux-Photos.desktop"
    cp /usr/share/applications/ternux-flashlight.desktop "\$H/Desktop/Ternux-Flashlight.desktop"
    chown "\$U:\$U" "\$H/Desktop/Ternux-Camera.desktop" "\$H/Desktop/Ternux-Photos.desktop" "\$H/Desktop/Ternux-Flashlight.desktop"
    chmod 0755 "\$H/Desktop/Ternux-Camera.desktop" "\$H/Desktop/Ternux-Photos.desktop" "\$H/Desktop/Ternux-Flashlight.desktop"
    if [ ! -e "\$H/Desktop/SD-Card.desktop" ]; then
      cp /usr/share/applications/ternux-sdcard.desktop "\$H/Desktop/SD-Card.desktop"
      chown "\$U:\$U" "\$H/Desktop/SD-Card.desktop"
      chmod 0755 "\$H/Desktop/SD-Card.desktop"
    fi
    for mime in image/jpeg image/png image/gif image/webp image/tiff image/bmp; do
      runuser -u "\$U" -- env HOME="\$H" xdg-mime default org.xfce.ristretto.desktop "\$mime" || true
    done
    runuser -u "\$U" -- env HOME="\$H" xdg-mime default org.gnome.Evince.desktop application/pdf || true
    runuser -u "\$U" -- env HOME="\$H" xdg-mime default xfce4-web-browser.desktop x-scheme-handler/http || true
    runuser -u "\$U" -- env HOME="\$H" xdg-mime default xfce4-web-browser.desktop x-scheme-handler/https || true
    cat > /usr/bin/pm-is-supported <<'PM'
#!/bin/sh
# PRoot has no permission to suspend or hibernate the Android host.
exit 1
PM
    chown root:root /usr/bin/pm-is-supported
    chmod 0755 /usr/bin/pm-is-supported
    printf '%s' '${welcome_b64}' | base64 -d > /usr/local/bin/ternux-welcome
    chown root:root /usr/local/bin/ternux-welcome
    chmod 0755 /usr/local/bin/ternux-welcome
    install -d -o root -g root -m 0755 /usr/share/backgrounds/ternux
    chmod 0644 /usr/share/backgrounds/ternux/*.svg
    window_fit_exec=\"devilspie2 --folder=/home/$user_name/.config/devilspie2\"
    if python3 -c 'import Xlib' >/dev/null 2>&1; then
      window_fit_exec=/usr/local/bin/ternux-window-fit-x11
    elif ! command -v devilspie2 >/dev/null 2>&1; then
      window_fit_exec=\"\"
    fi
    if [ -n \"\$window_fit_exec\" ]; then
    cat > \"\$H/.config/autostart/ternux-window-fit.desktop\" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Ternux Window Fit
Comment=Keep application windows inside the current X11 screen
Exec=\$window_fit_exec
Terminal=false
OnlyShowIn=XFCE;
X-GNOME-Autostart-enabled=true
DESKTOP
    chown \"\$U:\$U\" \"\$H/.config/autostart/ternux-window-fit.desktop\"
    chmod 0644 \"\$H/.config/autostart/ternux-window-fit.desktop\"
    else
      rm -f \"\$H/.config/autostart/ternux-window-fit.desktop\"
    fi
    cat > \"\$H/.config/autostart/xiccd.desktop\" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Xiccd color daemon
Hidden=true
DESKTOP
    chown \"\$U:\$U\" \"\$H/.config/autostart/xiccd.desktop\"
    chmod 0644 \"\$H/.config/autostart/xiccd.desktop\"
    cat > \"\$H/.config/autostart/polkit-mate-authentication-agent-1.desktop\" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=polkit-mate-authentication-agent-1.desktop
Hidden=true
DESKTOP
    chown \"\$U:\$U\" \"\$H/.config/autostart/polkit-mate-authentication-agent-1.desktop\"
    chmod 0644 \"\$H/.config/autostart/polkit-mate-authentication-agent-1.desktop\"
    cat > \"\$H/.config/autostart/polkit-ukui-authentication-agent-1.desktop\" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=polkit-ukui-authentication-agent-1.desktop
Hidden=true
DESKTOP
    chown \"\$U:\$U\" \"\$H/.config/autostart/polkit-ukui-authentication-agent-1.desktop\"
    chmod 0644 \"\$H/.config/autostart/polkit-ukui-authentication-agent-1.desktop\"
    cat > \"\$H/.config/autostart/ternux-welcome.desktop\" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Ternux Welcome
Icon=ternux-welcome
Comment=Show the Ternux first-run guide or open the project website
Exec=/usr/local/bin/ternux-welcome
Terminal=false
OnlyShowIn=XFCE;
X-GNOME-Autostart-enabled=true
DESKTOP
    chown \"\$U:\$U\" \"\$H/.config/autostart/ternux-welcome.desktop\"
    chmod 0644 \"\$H/.config/autostart/ternux-welcome.desktop\"
    install -d -o root -g root -m 0755 /usr/local/libexec
    printf '%s' '${welcome_gui_b64}' | base64 -d > /usr/local/libexec/ternux-welcome-gui.py
    chown root:root /usr/local/libexec/ternux-welcome-gui.py
    chmod 0755 /usr/local/libexec/ternux-welcome-gui.py
    sh -n /usr/local/bin/ternux-welcome
  " || { tnx_fail "User setup failed."; return 1; }

  if tnx_guest_login --shared-tmp --user "$user_name" -- sudo -n true >/dev/null 2>&1; then
    tnx_ok "Guest '$(tnx_distro)' + Xfce4 + user '$user_name' ready (passwordless sudo)."
  else
    tnx_fail "Passwordless sudo not working for '$user_name'."
    return 1
  fi

  tnx_install_guest_cli "$user_name" || return $?
}

# ---------------------------------------------------------------------------
# Phase 5 — GPU driver (Zink/Turnip or VirGL)
# ---------------------------------------------------------------------------
tnx_validate_turnip_archive() {
  local tarball="$1"

  tar -tzf "$tarball" >/dev/null 2>&1 || return 1
  if tar -tzf "$tarball" | grep -qE '^/|(^|/)\.\.(/|$)'; then
    return 1
  fi

  # Upstream legitimately ships Mesa symlinks. They are safe to leave in the
  # archive because extraction selects only the two targets below; those two
  # must each occur exactly once and must each be a regular file.
  tar -tvzf "$tarball" 2>/dev/null | awk '
    /\/usr\/lib\/aarch64-linux-gnu\/libvulkan_freedreno[.]so$/ {
      if (substr($1,1,1) != "-") bad=1
      driver++
    }
    /\/usr\/share\/vulkan\/icd[.]d\/freedreno_icd[.]aarch64[.]json$/ {
      if (substr($1,1,1) != "-") bad=1
      icd++
    }
    END { if (bad || driver != 1 || icd != 1) exit 1 }
  '
}

tnx_phase_gpu() {
  local backend="${1:-auto}" distro="$(tnx_distro)"

  # Keep the phase safe when called directly (for example by the legacy
  # install.sh doctor route), not only through the main orchestrator.
  [ "$backend" = "zink-turnip" ] && backend="zink"
  if [ "$backend" = "auto" ]; then
    backend="$(tnx_gpu_backend_auto "$distro")"
  fi
  case "$backend" in
    zink|virgl) ;;
    *) tnx_fail "GPU backend must be auto, zink or virgl."; return 2 ;;
  esac

  if [ "$backend" = "virgl" ]; then
    tnx_has_cmd virgl_test_server_android || { tnx_fail "VirGL selected but virgl_test_server_android missing."; return 1; }
    tnx_info "VirGL: rendering goes through host-side virgl_test_server_android."
    return 0
  fi

  [ -e "${TERNUX_KGSL_DEVICE:-/dev/kgsl-3d0}" ] || { tnx_fail "Zink needs /dev/kgsl-3d0 (Adreno GPU)."; return 1; }

  local guest_os release_url="" asset_name="" asset_kind="" guest_id="" guest_version="" guest_codename=""
  guest_os="$(tnx_guest_login -- bash -c '. /etc/os-release; printf "%s\t%s\t%s\n" "${ID:-}" "${VERSION_ID:-}" "${VERSION_CODENAME:-}"' 2>/dev/null || true)"
  IFS=$'\t' read -r guest_id guest_version guest_codename <<< "$guest_os"
  asset_name="$(tnx_freedreno_asset_name "$distro" "$guest_id" "$guest_version" "$guest_codename" 2>/dev/null || true)"
  if [ -z "$asset_name" ]; then
    if tnx_guest_login -- bash -c '
      find /usr -name zink_dri.so -print -quit 2>/dev/null | grep -q . &&
      find /usr -name "*freedreno*.json" -print -quit 2>/dev/null | grep -q . &&
      find /usr -name "libvulkan_freedreno.so*" -print -quit 2>/dev/null | grep -q .
    ' >/dev/null 2>&1; then
      tnx_info "Using $distro native Mesa Zink/Freedreno package stack; runtime renderer still needs display verification."
      return 0
    fi
    tnx_fail "No upstream Turnip asset matches '$distro' ($guest_id ${guest_version:-unknown} ${guest_codename:-}). Install a supported distro Mesa/Freedreno stack or select VirGL."
    return 1
  fi
  release_url="$(tnx_resolve_freedreno_asset "$asset_name")"
  [ -n "$release_url" ] || { tnx_fail "Could not resolve Freedreno asset '$asset_name'."; return 1; }
  case "$asset_name" in *.tar) asset_kind=arch ;; *) asset_kind=root ;; esac
  if [ "$distro" = debian ]; then
    [ "$guest_codename" = trixie ] || {
      tnx_fail "The validated Debian Turnip asset targets Trixie; guest reports '${guest_codename:-unknown}'."
      return 1
    }
    asset_kind=debian
  fi

  tnx_distro_profile
  local tar_suffix="tar.gz"
  [ "$asset_kind" = arch ] && tar_suffix="tar"
  local tarball="${TMPDIR:-/data/data/com.termux/files/usr/tmp}/mesa-freedreno.${tar_suffix}"
  rm -f "$tarball"
  tnx_download "$release_url" "$tarball" || { tnx_fail "Failed to download Freedreno driver."; return 1; }

  local sha expected_sha module_dir notice_source notice_tarball
  sha="$(sha256sum "$tarball" | cut -d' ' -f1)"
  expected_sha="$(tnx_expected_freedreno_sha "$asset_name")"
  if [ -z "$expected_sha" ] || [ "$sha" != "$expected_sha" ]; then
    tnx_fail "Freedreno archive SHA-256 mismatch or missing pin for '$asset_name'."
    rm -f "$tarball"
    return 1
  fi
  if [ "$asset_kind" = debian ] && ! tnx_validate_turnip_archive "$tarball"; then
    tnx_fail "Debian driver archive must have safe paths and exactly one regular driver and ICD target."
    rm -f "$tarball"
    return 1
  elif [ "$asset_kind" = root ] && ! tnx_validate_full_mesa_archive "$tarball"; then
    tnx_fail "Distro Mesa archive has unsafe paths or is missing Zink/Freedreno driver files."
    rm -f "$tarball"
    return 1
  elif [ "$asset_kind" = arch ] && ! tnx_validate_arch_mesa_archive "$tarball"; then
    tnx_fail "Arch Mesa archive is invalid or does not contain the pinned Mesa/Freedreno packages."
    rm -f "$tarball"
    return 1
  fi
  module_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
  notice_source="$module_dir/licenses/mesa-27.0.0-devel-20261025"
  notice_tarball="${TMPDIR:-/data/data/com.termux/files/usr/tmp}/ternux-mesa-notices.tar.gz"
  if [ ! -s "$notice_source/README.md" ] || [ ! -s "$notice_source/SHA256SUMS" ] ||
     ! (cd "$notice_source" && sha256sum -c SHA256SUMS >/dev/null 2>&1); then
    tnx_fail "Pinned Mesa license notice bundle is missing or failed its checksum manifest."
    rm -f "$tarball" "$notice_tarball"
    return 1
  fi
  rm -f "$notice_tarball"
  if ! tar -czf "$notice_tarball" -C "$notice_source" .; then
    tnx_fail "Could not package the pinned Mesa license notices."
    rm -f "$tarball" "$notice_tarball"
    return 1
  fi

  tnx_state_set "freedreno_sha" "$sha"
  tnx_state_set "freedreno_url" "$release_url"
  tnx_state_set "freedreno_asset" "$asset_name"
  tnx_state_set "freedreno_asset_kind" "$asset_kind"

  if [ "$asset_kind" != debian ]; then
    local release_notice_dir="mesa-27.0.0-devel-20261025-r2"
    tnx_guest_login --shared-tmp -- bash -c "
      set -e
      stage=/tmp/ternux-mesa-stage; rm -rf "\$stage"; mkdir -p "\$stage"
      trap 'rm -rf \"\$stage\"' EXIT
      notice_dest=/usr/local/share/doc/ternux/$release_notice_dir
      mkdir -p "\$notice_dest"
      tar -xzf /tmp/ternux-mesa-notices.tar.gz -C "\$notice_dest"
      (cd "\$notice_dest" && sha256sum -c SHA256SUMS)
      if [ '$asset_kind' = arch ]; then
        tar -xf /tmp/mesa-freedreno.tar -C "\$stage"
        set -- "\$stage"/*.pkg.tar.xz
        [ -f "\$1" ]
        pacman -U --noconfirm --needed "\$@"
      else
        tar -xzf /tmp/mesa-freedreno.tar.gz -C "\$stage"
        overlay=/usr/local/lib/ternux/mesa-27.0.0-devel-20261025-r2-$distro-$guest_codename
        mkdir -p "\$overlay"
        tar -xzf /tmp/mesa-freedreno.tar.gz -C "\$overlay" --strip-components=2 --no-same-owner
        libdir="\$overlay/lib/aarch64-linux-gnu"
        [ -d "\$libdir" ] || libdir="\$overlay/lib"
        driver="\$libdir/libvulkan_freedreno.so"
        source_icd="\$overlay/share/vulkan/icd.d/freedreno_icd.aarch64.json"
        runtime_icd="\$overlay/share/vulkan/icd.d/ternux_freedreno_icd.json"
        [ -f "\$driver" ] && [ -f "\$source_icd" ] && [ -f "\$libdir/dri/zink_dri.so" ] && [ -f "\$libdir/libgallium-27.0.0-devel.so" ]
        printf '{\\n  \\042ICD\\042: {\\n    \\042api_version\\042: \\0421.4.0\\042,\\n    \\042library_arch\\042: \\04264\\042,\\n    \\042library_path\\042: \\042%s\\042\\n  },\\n  \\042file_format_version\\042: \\0421.0.1\\042\\n}\\n' \\
          "\$driver" > "\$runtime_icd"
        chmod 0644 "\$runtime_icd"
        mkdir -p /etc/ternux
        printf '%s\\n' "\$overlay" > /etc/ternux/mesa-overlay
        printf '%s\\n' "\$libdir" > /etc/ternux/mesa-overlay-libdir
      fi
      find "\$stage" -mindepth 1 -delete 2>/dev/null || true
      if [ '$asset_kind' = arch ]; then
        find /usr -name zink_dri.so -print -quit 2>/dev/null | grep -q .
        find /usr -name kgsl_dri.so -print -quit 2>/dev/null | grep -q .
        find /usr -name '*freedreno*.json' -print -quit 2>/dev/null | grep -q .
        find /usr -name 'libvulkan_freedreno.so*' -print -quit 2>/dev/null | grep -q .
      else
        [ -s /etc/ternux/mesa-overlay ]
        overlay=\$(cat /etc/ternux/mesa-overlay)
        overlay_libdir=\$(cat /etc/ternux/mesa-overlay-libdir)
        case "\$overlay_libdir" in "\$overlay"/*) ;; *) exit 1 ;; esac
        [ -f "\$overlay_libdir/dri/zink_dri.so" ]
        [ -f "\$overlay_libdir/dri/kgsl_dri.so" ]
        [ -f "\$overlay/share/vulkan/icd.d/ternux_freedreno_icd.json" ]
        [ -f "\$overlay_libdir/libvulkan_freedreno.so" ]
        python3 -m json.tool "\$overlay/share/vulkan/icd.d/ternux_freedreno_icd.json" >/dev/null
        grep -F "\$overlay_libdir/libvulkan_freedreno.so" "\$overlay/share/vulkan/icd.d/ternux_freedreno_icd.json" >/dev/null
      fi
    " || { tnx_fail "Could not install or verify the matching $distro Mesa/Turnip asset."; rm -f "$tarball" "$notice_tarball"; return 1; }
    rm -f "$tarball" "$notice_tarball"
    if [ "$asset_kind" != arch ]; then
      local overlay_driver_sha overlay_icd_sha
      overlay_driver_sha="$(tnx_guest_login -- bash -c 'overlay="$(cat /etc/ternux/mesa-overlay 2>/dev/null || true)"; libdir="$(cat /etc/ternux/mesa-overlay-libdir 2>/dev/null || true)"; [ -n "$overlay" ] && [ "${libdir#"$overlay"/}" != "$libdir" ] && sha256sum "$libdir/libvulkan_freedreno.so" "$overlay/share/vulkan/icd.d/ternux_freedreno_icd.json" 2>/dev/null' | awk 'NR==1{print $1}')"
      overlay_icd_sha="$(tnx_guest_login -- bash -c 'overlay="$(cat /etc/ternux/mesa-overlay 2>/dev/null || true)"; [ -n "$overlay" ] && sha256sum "$overlay/share/vulkan/icd.d/ternux_freedreno_icd.json" 2>/dev/null' | awk 'NR==1{print $1}')"
      [ -n "$overlay_driver_sha" ] && tnx_state_set "freedreno_driver_sha" "$overlay_driver_sha"
      [ -n "$overlay_icd_sha" ] && tnx_state_set "freedreno_icd_sha" "$overlay_icd_sha"
    fi
    tnx_ok "Distro-matched Mesa Zink/Turnip asset installed, checksummed and license-noticed ($asset_name)."
    return 0
  fi

  tnx_guest_login --shared-tmp -- bash -c "
    set -e
    stage=/tmp/ternux-driver-stage; rm -rf \"\$stage\"; mkdir -p \"\$stage\"
    trap 'rm -rf \"\$stage\"' EXIT
    export DEBIAN_FRONTEND=noninteractive
    notice_dest=/usr/local/share/doc/ternux/mesa-27.0.0-devel-20261025
    mkdir -p "\$notice_dest"
    tar -xzf /tmp/ternux-mesa-notices.tar.gz -C "\$notice_dest"
    (cd "\$notice_dest" && sha256sum -c SHA256SUMS)
    find "\$notice_dest" -type d -exec chmod 0755 {} +
    find "\$notice_dest" -type f -exec chmod 0644 {} +
    apt install -y -o APT::Color=1 -o Dpkg::Progress-Fancy=1 libvulkan1 || true
    tar -xzf /tmp/mesa-freedreno.tar.gz -C \"\$stage\" --wildcards \
      \"*/usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so\" \
      \"*/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json\"
    driver=\"\$(find \"\$stage\" -type f -path '*/usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so' -print -quit)\"
    icd=\"\$(find \"\$stage\" -type f -path '*/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json' -print -quit)\"
    [ -n \"\$driver\" ] && [ -n \"\$icd\" ] || exit 1
    install -D -m 0755 \"\$driver\" /usr/local/lib/aarch64-linux-gnu/libvulkan_freedreno.so
    mkdir -p /usr/local/share/vulkan/icd.d
    api=\"\$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))[\"api_version\"])' \"\$icd\" 2>/dev/null || true)\"
    [ -n \"\$api\" ] || api=1.4.0
    printf '{\\n    \"ICD\": {\\n        \"api_version\": \"%s\",\\n        \"library_arch\": \"64\",\\n        \"library_path\": \"%s\"\\n    },\\n    \"file_format_version\": \"1.0.1\"\\n}\\n' \
      \"\$api\" /usr/local/lib/aarch64-linux-gnu/libvulkan_freedreno.so \
      > /usr/local/share/vulkan/icd.d/ternux_freedreno_icd.json
    dpkg-divert --add --rename \
      --divert /usr/share/vulkan/icd.d/freedreno_icd.json.distrib \
      /usr/share/vulkan/icd.d/freedreno_icd.json >/dev/null 2>&1 || true
    rm -f /usr/share/vulkan/icd.d/freedreno_icd.aarch64.json
    ldconfig
    apt-mark hold $TNX_DP_MESA_HOLD $TNX_DP_EXTRA_HOLD || true
  " || { tnx_fail "Driver or license notice installation failed."; rm -f "$tarball" "$notice_tarball"; return 1; }
  rm -f "$tarball" "$notice_tarball"

  if tnx_guest_login --shared-tmp -- bash -c '
    [ -f /usr/local/lib/aarch64-linux-gnu/libvulkan_freedreno.so ] &&
    [ -f /usr/local/share/vulkan/icd.d/ternux_freedreno_icd.json ] &&
    [ -s /usr/local/share/doc/ternux/mesa-27.0.0-devel-20261025/README.md ] &&
    (cd /usr/local/share/doc/ternux/mesa-27.0.0-devel-20261025 && sha256sum -c SHA256SUMS >/dev/null)
  ' >/dev/null 2>&1; then
    local driver_sha icd_sha
    driver_sha="$(tnx_guest_login -- sha256sum /usr/local/lib/aarch64-linux-gnu/libvulkan_freedreno.so 2>/dev/null | awk '{print $1}')"
    icd_sha="$(tnx_guest_login -- sha256sum /usr/local/share/vulkan/icd.d/ternux_freedreno_icd.json 2>/dev/null | awk '{print $1}')"
    [ -n "$driver_sha" ] && tnx_state_set "freedreno_driver_sha" "$driver_sha"
    [ -n "$icd_sha" ] && tnx_state_set "freedreno_icd_sha" "$icd_sha"
    tnx_ok "Turnip driver, ICD and upstream license notices installed and verified."
  else
    tnx_fail "Turnip driver files missing after extraction."; return 1
  fi
}

tnx_freedreno_asset_name() {
  local distro="${1:-$(tnx_distro)}" id="${2:-}" version="${3:-}" codename="${4:-}" asset=""
  case "$distro:$id:$codename" in
    debian:debian:trixie) asset='mesa-for-android-container_27.0.0-devel-20261025-r2_debian_trixie_arm64.tar.gz' ;;
    debian:debian:*) [ "$codename" = testing ] && asset='mesa-for-android-container_27.0.0-devel-20261025-r2_debian_testing_arm64.tar.gz' ;;
    ubuntu:ubuntu:noble) asset='mesa-for-android-container_27.0.0-devel-20261025-r2_ubuntu_noble_arm64.tar.gz' ;;
    ubuntu:ubuntu:questing) asset='mesa-for-android-container_27.0.0-devel-20261025-r2_ubuntu_questing_arm64.tar.gz' ;;
    ubuntu:ubuntu:resolute) asset='mesa-for-android-container_27.0.0-devel-20261025-r2_ubuntu_resolute_arm64.tar.gz' ;;
    ubuntu:ubuntu:rolling) asset='mesa-for-android-container_27.0.0-devel-20261025-r2_ubuntu_rolling_arm64.tar.gz' ;;
    alpine:alpine:*) case "$version" in 3.24*) asset='mesa-for-android-container_27.0.0-devel-20261025-r2_alpine_3.24_arm64.tar.gz' ;; esac ;;
    archlinux:arch:*) asset='mesa-for-android-container_27.0.0-devel-20261025-r2_archlinux_arm64.tar' ;;
    fedora:fedora:*) case "$version" in 43|44|45) asset="mesa-for-android-container_27.0.0-devel-20261025-r2_fedora_${version}_arm64.tar.gz" ;; esac ;;
    opensuse:opensuse-tumbleweed:*) asset='mesa-for-android-container_27.0.0-devel-20261025-r2_opensuse_tumbleweed_arm64.tar.gz' ;;
    void:void:*) asset='mesa-for-android-container_27.0.0-devel-20261025-r2_void_arm64.tar.gz' ;;
    deepin:deepin:*) case "$codename:$version" in crimson:*|*:25*) asset='mesa-for-android-container_27.0.0-devel-20261025-r2_deepin_crimson_arm64.tar.gz' ;; esac ;;
  esac
  [ -n "$asset" ] || return 1
  printf '%s\n' "$asset"
}

tnx_resolve_freedreno_asset() {
  local asset="${1:-}"
  [ -n "$asset" ] || return 1
  [[ "$asset" =~ ^mesa-for-android-container_[A-Za-z0-9._-]+_arm64[.]tar([.]gz)?$ ]] || return 2
  case "$asset" in
    *)
      printf '%s\n' "https://github.com/lfdevs/mesa-for-android-container/releases/download/mesa-27.0.0-devel-20261025-r2/$asset" ;;
  esac
}

tnx_expected_freedreno_sha() {
  case "${1:-}" in
    mesa-for-android-container_27.0.0-devel-20261025-r2_debian_trixie_arm64.tar.gz) printf '%s\n' 79e1aaf5a49e204fae68a5c87c76248701ba723f4349bda87d310f456c5705cf ;;
    mesa-for-android-container_27.0.0-devel-20261025-r2_alpine_3.24_arm64.tar.gz) printf '%s\n' 452bc884459dc74e8ba7ac72232628be03b0870a5904bafb8a0a14ee154d2fd4 ;;
    mesa-for-android-container_27.0.0-devel-20261025-r2_archlinux_arm64.tar) printf '%s\n' 62c58f5ba71aa8a010adc750870c3ff555f2d58cf7d39723e340a6f5a8d83da9 ;;
    mesa-for-android-container_27.0.0-devel-20261025-r2_debian_testing_arm64.tar.gz) printf '%s\n' 25a05d624bb215b656b8446d1b559e36af24e8f7d9c1529445fe97f6f777dc73 ;;
    mesa-for-android-container_27.0.0-devel-20261025-r2_deepin_crimson_arm64.tar.gz) printf '%s\n' 6b51771ed4a9f6baf8d352d3ecf211fa8fffc97c3fd973d1debc05db98f13a4c ;;
    mesa-for-android-container_27.0.0-devel-20261025-r2_fedora_43_arm64.tar.gz) printf '%s\n' e6d381bf2b88aaf30364d07e65d08db45d4b3b232cbcf03fb42204be5b4f7ca2 ;;
    mesa-for-android-container_27.0.0-devel-20261025-r2_fedora_44_arm64.tar.gz) printf '%s\n' 3dac82afea18d843dc827f455a8fe251c4ce0541dc8a7b3910b5fd10577be910 ;;
    mesa-for-android-container_27.0.0-devel-20261025-r2_fedora_45_arm64.tar.gz) printf '%s\n' b98f251b3f03b77ac68e230865bcddc6c35de7aa26a7aac650ea5adf8f13f6f1 ;;
    mesa-for-android-container_27.0.0-devel-20261025-r2_opensuse_tumbleweed_arm64.tar.gz) printf '%s\n' c62c13ccc7829d259f864b7172d85a465e02a868fd8b7dfaa6b1b7de99adc9fd ;;
    mesa-for-android-container_27.0.0-devel-20261025-r2_ubuntu_noble_arm64.tar.gz) printf '%s\n' 6c456733fe9d3ef7a7a2d6c5519a42d55023f634842c16b48a8b9a817927f846 ;;
    mesa-for-android-container_27.0.0-devel-20261025-r2_ubuntu_questing_arm64.tar.gz) printf '%s\n' f0a18561df2ffb2a15a5a18f9c37d28263c7aaa61a28a4f67af52e1d32169f08 ;;
    mesa-for-android-container_27.0.0-devel-20261025-r2_ubuntu_resolute_arm64.tar.gz) printf '%s\n' 4798c8e3b6063142b6d484b85cb91e30b97eff8833efde32655f9a6e0e8a929c ;;
    mesa-for-android-container_27.0.0-devel-20261025-r2_ubuntu_rolling_arm64.tar.gz) printf '%s\n' f3c6e4ab786b885868967cf9e63ed894d84a2a63d264ba0c26887de1f1a30bf8 ;;
    mesa-for-android-container_27.0.0-devel-20261025-r2_void_arm64.tar.gz) printf '%s\n' e72db7385cebcde133fb0aaa983db17aff0c5417ab4748ab7162fefcfd1c6d0e ;;
    *) return 1 ;;
  esac
}

tnx_validate_full_mesa_archive() {
  local archive="$1" listing=""
  listing="$(tar -tzf "$archive" 2>/dev/null)" || return 1
  printf '%s\n' "$listing" | awk '
    /^\// || /(^|\/)\.\.($|\/)/ { bad=1 }
    END { if (bad) exit 1 }
  ' || return 1
  printf '%s\n' "$listing" | grep -Eq '(^|/)dri/zink_dri[.]so$' &&
    printf '%s\n' "$listing" | grep -Eq '(^|/)dri/kgsl_dri[.]so$' &&
    printf '%s\n' "$listing" | grep -Eq '(^|/)libvulkan_freedreno[.]so$' &&
    printf '%s\n' "$listing" | grep -Eq '(^|/)vulkan/icd[.]d/freedreno_icd[.]aarch64[.]json$'
}

tnx_validate_arch_mesa_archive() {
  local archive="$1" listing=""
  listing="$(tar -tf "$archive" 2>/dev/null)" || return 1
  printf '%s\n' "$listing" | awk '/^\// || /(^|\/)\.\.($|\/)/ { bad=1 } END { if (bad) exit 1 }' || return 1
  printf '%s\n' "$listing" | grep -q '^mesa-.*-aarch64[.]pkg[.]tar[.]xz$' &&
    printf '%s\n' "$listing" | grep -q '^vulkan-freedreno-.*-aarch64[.]pkg[.]tar[.]xz$'
}

# ---------------------------------------------------------------------------
# Phase 6 — audio, locale, fonts
# ---------------------------------------------------------------------------
_TNX_PULSE_CHANGED=0
_tnx_configure_pulse_bridge() {
  local pa_conf="$1" tmp="" input=/dev/null
  local legacy_line="load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 port=4713"
  local bridge_line="load-module module-native-protocol-tcp listen=127.0.0.1 auth-ip-acl=127.0.0.1 auth-anonymous=1 port=4713"
  local sink_line="load-module module-opensles-sink sink_name=Speaker"
  local source_line="load-module module-sles-source source_name=Ternux_Microphone"
  local default_line="set-default-sink Speaker"
  _TNX_PULSE_CHANGED=0

  mkdir -p "$(dirname "$pa_conf")" || return 1
  # Do not follow a pre-existing symlink or replace a non-regular object.
  [ ! -L "$pa_conf" ] || return 1
  [ ! -e "$pa_conf" ] || [ -f "$pa_conf" ] || return 1
  [ -f "$pa_conf" ] && input="$pa_conf"

  # Only the exact old ternux line and the exact secure line are owned by this
  # helper. Refuse to merge with any other active TCP listener, including an
  # indented one or one placed beside a recognized ternux line.
  if grep -E '^[[:space:]]*load-module[[:space:]]+module-native-protocol-tcp([[:space:]]|$)' "$input" 2>/dev/null |
     grep -Fvx -e "$legacy_line" -e "$bridge_line" | grep -q .; then
    tnx_fail "Custom PulseAudio TCP module found; review it instead of overwriting it."
    return 1
  fi

  # Build the complete replacement before touching the original. This also
  # collapses duplicate legacy/secure ternux lines to one canonical listener.
  # mktemp creates the staging file in the destination directory, so the final
  # rename is both unpredictable and confined to one filesystem.
  tmp="$(mktemp "${pa_conf}.ternux.XXXXXX")" || return 1
  awk -v old="$legacy_line" -v new="$bridge_line" '
    $0 == old || $0 == new {
      if (!seen) print new
      seen=1
      next
    }
    { print }
    END { if (!seen) print new }
  ' "$input" > "$tmp" || { rm -f "$tmp"; return 1; }

  grep -qxF "$sink_line" "$tmp" || printf '%s\n' "$sink_line" >> "$tmp" || {
    rm -f "$tmp"; return 1;
  }
  grep -qxF "$source_line" "$tmp" || printf '%s\n' "$source_line" >> "$tmp" || {
    rm -f "$tmp"; return 1;
  }
  grep -qxF "$default_line" "$tmp" || printf '%s\n' "$default_line" >> "$tmp" || {
    rm -f "$tmp"; return 1;
  }

  if [ -f "$pa_conf" ] && cmp -s "$pa_conf" "$tmp"; then
    rm -f "$tmp"
    return 0
  fi

  [ ! -f "$pa_conf" ] || chmod --reference="$pa_conf" "$tmp" 2>/dev/null || true
  mv -f "$tmp" "$pa_conf" || { rm -f "$tmp"; return 1; }
  _TNX_PULSE_CHANGED=1
  return 0
}

tnx_request_microphone_permission() {
  local recorder="termux-microphone-record"
  local tmpdir="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
  local probe_dir probe info="" active=0 attempt output_file record_rc=1

  if ! tnx_has_cmd "$recorder"; then
    tnx_warn "Termux:API microphone recorder is unavailable; Android microphone permission was not requested."
    return 0
  fi
  if ! tnx_has_cmd timeout; then
    tnx_warn "The timeout utility is unavailable; skipping the optional microphone permission request."
    return 0
  fi

  info="$("$recorder" -i 2>/dev/null || true)"
  if printf '%s' "$info" | grep -Eq '"isRecording"[[:space:]]*:[[:space:]]*true'; then
    tnx_info "Termux:API is already recording; leaving the existing recording untouched."
    return 0
  fi

  probe_dir="$(mktemp -d "$tmpdir/ternux-mic-permission.XXXXXX" 2>/dev/null)" || {
    tnx_warn "Could not create a private microphone permission probe directory."
    return 0
  }
  probe="$probe_dir/permission.m4a"

  # Termux:API requests RECORD_AUDIO by starting its recorder service. Keep
  # this permission-only probe private and bounded; never stop a recording
  # unless the API confirms that its output path is this probe's unique file.
  timeout 10 "$recorder" -f "$probe" -l 1 >/dev/null 2>&1 && record_rc=0 || true
  for ((attempt=0; attempt<25; attempt++)); do
    info="$("$recorder" -i 2>/dev/null || true)"
    output_file="$(printf '%s\n' "$info" | sed -n 's/.*"outputFile"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
    if printf '%s' "$info" | grep -Eq '"isRecording"[[:space:]]*:[[:space:]]*true' &&
       [ "$output_file" = "$probe" ]; then
      active=1
      break
    fi
    sleep 0.2
  done

  if [ "$active" -eq 1 ]; then
    if "$recorder" -q >/dev/null 2>&1; then
      tnx_ok "Termux:API microphone permission is available; the permission probe was stopped."
    else
      tnx_warn "Microphone permission was confirmed, but the temporary API recording did not stop cleanly."
    fi
  else
    # A one-second API recording may complete before the first status poll.
    # If it is still active, stop it only after matching our unique output path.
    info="$("$recorder" -i 2>/dev/null || true)"
    output_file="$(printf '%s\n' "$info" | sed -n 's/.*"outputFile"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
    if printf '%s' "$info" | grep -Eq '"isRecording"[[:space:]]*:[[:space:]]*true' &&
       [ "$output_file" = "$probe" ]; then
      "$recorder" -q >/dev/null 2>&1 || true
      active=1
    fi
    if [ "$active" -eq 1 ]; then
      tnx_ok "Termux:API microphone permission is available; the permission probe was stopped."
    elif [ "$record_rc" -eq 0 ] && [ -s "$probe" ]; then
      # A one-second capture can finish before the first status poll. A non-empty
      # file at this unique path confirms our bounded probe completed.
      tnx_ok "Termux:API microphone permission is available; the bounded probe completed."
    else
      tnx_warn "Termux:API microphone permission was not confirmed; installation continues without API microphone access."
    fi
  fi

  rm -f -- "$probe" 2>/dev/null || true
  rmdir -- "$probe_dir" 2>/dev/null || true
  return 0
}

tnx_phase_audio_fonts() {
  local user_name="${1:-ternux}" locale="${2:-en_US.UTF-8}" family=""

  tnx_distro_profile || return 2
  family="$TNX_DP_FAMILY"
  tnx_request_microphone_permission
  local PA_CONF="${PREFIX:-/data/data/com.termux/files/usr}/etc/pulse/default.pa"
  _tnx_configure_pulse_bridge "$PA_CONF" || return 1
  [ "$_TNX_PULSE_CHANGED" = "1" ] && tnx_ok "PulseAudio TCP bridge bound to loopback."

  tnx_guest_login --shared-tmp --user "$user_name" -- bash -c "
    set -e
    FAMILY='${family}'
    case \"\$FAMILY\" in
      apt)
        DPKG_FORCE=\"-o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef\"
        sudo apt update
        sudo DEBIAN_FRONTEND=noninteractive apt install -y \$DPKG_FORCE locales wget fonts-symbola fonts-noto-color-emoji fonts-font-awesome fonts-powerline
        grep -qxF \"${locale} UTF-8\" /etc/locale.gen 2>/dev/null || echo \"${locale} UTF-8\" | sudo tee -a /etc/locale.gen >/dev/null
        sudo locale-gen \"${locale}\"
        ;;
      apk)
        sudo apk add musl-locales musl-locales-lang wget font-noto font-noto-emoji font-awesome
        ;;
      pacman)
        sudo pacman -S --noconfirm --needed glibc wget noto-fonts noto-fonts-emoji ttf-font-awesome
        ;;
      dnf)
        sudo dnf install -y glibc-langpack-en wget google-noto-sans-fonts google-noto-emoji-fonts fontawesome-fonts
        ;;
      zypper)
        sudo zypper --non-interactive install -y glibc-locale wget google-noto-sans-fonts google-noto-emoji-fonts fontawesome-fonts
        ;;
      xbps)
        sudo xbps-install -Sy glibc-locales wget noto-fonts-ttf font-awesome
        ;;
    esac
    grep -q \"export LANG='${locale}'\" ~/.bashrc 2>/dev/null || echo \"export LANG='${locale}'\" >> ~/.bashrc
    grep -q \"export LC_ALL='${locale}'\" ~/.bashrc 2>/dev/null || echo \"export LC_ALL='${locale}'\" >> ~/.bashrc
    # The launcher exports the live loopback PulseAudio endpoint for desktop apps.
    mkdir -p ~/.local/share/fonts
    if [ ! -f ~/.local/share/fonts/.ternux-nerdfont-v3.5.1-installed ]; then
      font_archive=\"\$(mktemp /tmp/ternux-jetbrainsmono.XXXXXX)\"
      if wget -q -O \"\$font_archive\" \"https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/JetBrainsMono.tar.xz\" \
        && echo \"04d5e8f903693f9dd13e16f867e994834e681eb3c72c0d337a770dcda09010cf  \$font_archive\" | sha256sum -c - >/dev/null \
        && tar -xJf \"\$font_archive\" -C ~/.local/share/fonts/; then
        touch ~/.local/share/fonts/.ternux-nerdfont-v3.5.1-installed
        fc-cache -f >/dev/null 2>&1 || true
      else
        echo \"JetBrainsMono Nerd Font download or checksum verification failed; continuing without it.\" >&2
      fi
      rm -f \"\$font_archive\"
    fi
  " || { tnx_fail "Locale/font setup failed."; return 1; }
  tnx_ok "Locale '$locale', PulseAudio client and fonts configured."
}

# ---------------------------------------------------------------------------
# Phase 7 — desktop launcher ~/x.sh
# ---------------------------------------------------------------------------
tnx_phase_launcher() {
  local user_name="${1:-ternux}" backend="${2:-auto}" locale="${3:-en_US.UTF-8}"
  local distro; distro="$(tnx_distro)"
  local distro_state_dir LAUNCHER display_num display tag session_pid_rel
  distro_state_dir="$(tnx_distro_state_dir "$distro")" || return 2
  display_num="$(tnx_distro_display "$distro")" || { tnx_fail "No X11 display is assigned to guest '$distro'."; return 2; }
  display=":$display_num"; tag="$(tnx_distro_tag "$distro")" || return 2
  if [ "$distro" = debian ]; then session_pid_rel="session/desktop.pid"; else session_pid_rel="distros/$distro/session/desktop.pid"; fi
  LAUNCHER="$distro_state_dir/launcher.sh"
  mkdir -p "$distro_state_dir" || return 1

  [[ "$user_name" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] || { tnx_fail "Launcher user name is invalid."; return 2; }
  [[ "$locale" =~ ^[A-Za-z0-9_.@-]+$ ]] || { tnx_fail "Launcher locale is invalid."; return 2; }
  case "$backend" in
    zink|zink-turnip) backend="zink" ;;
    virgl) backend="virgl" ;;
    auto) backend="$(tnx_gpu_backend_auto "$distro")" ;;
    *) tnx_fail "Launcher backend must be auto, zink or virgl."; return 2 ;;
  esac

  # The guest desktop lives in a standalone script. Keeping it out of nested
  # `bash -c`/`sh -c` quoting prevents theme values such as `|HMC` from
  # truncating the command and triggering teardown before XFCE starts.
  cat > "$LAUNCHER" <<'LAUNCHEOF'
#!/data/data/com.termux/files/usr/bin/bash
# TERNUX_DESKTOP_LAUNCHER=21
set -u
TMPDIR="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
TERMUX_HOST_HOME="/data/data/com.termux/files/home"
TNX_DISPLAY="__TNX_DISPLAY__"
TNX_TAG="__TNX_TAG__"
TNX_PID_FILE="${TNX_PID_FILE:-$HOME/.local/share/ternux/__TNX_SESSION_PID__}"
TNX_IDENTITY_FILE="${TNX_PID_FILE}.identity"
TNX_READY_FILE="${TNX_PID_FILE}.ready"
proc_start_identity() { awk '{ sub(/^.*\) /, ""); print $20 }' "/proc/$1/stat" 2>/dev/null; }
TNX_START_ID="$(proc_start_identity "$$")"
TNX_PGID="$(ps -o pgid= -p "$$" 2>/dev/null | tr -d '[:space:]')"
printf '%s\n' "$$" > "$TNX_PID_FILE" 2>/dev/null || true
if [ -n "$TNX_START_ID" ] && [ "$TNX_PGID" = "$$" ]; then
  printf '%s %s %s\n' "$$" "$TNX_START_ID" "$TNX_PGID" > "${TNX_IDENTITY_FILE}.tmp" && mv -f "${TNX_IDENTITY_FILE}.tmp" "$TNX_IDENTITY_FILE" 2>/dev/null || true
fi
TNX_GUEST_SESSION_SCRIPT="$TMPDIR/ternux-desktop-session-$$.sh"
TNX_CPUINFO_FILE="$TMPDIR/ternux-cpuinfo-$$"
TNX_CPU_MODEL_MAP="$TMPDIR/ternux-cpu-models-$$"
write_cpuinfo_with_model_names() {
  local soc tmp="$TNX_CPUINFO_FILE.tmp"
  soc="$(getprop ro.soc.model 2>/dev/null || true)"
  lscpu -p=CPU,MODELNAME 2>/dev/null | awk -F, '!/^#/ && NF >= 2 && $2 != "" { print $1 "\t" $2 }' > "$TNX_CPU_MODEL_MAP" || :
  awk -F: -v models="$TNX_CPU_MODEL_MAP" -v soc="$soc" '
    function add_model() {
      if (!has_model) {
        model = model_by_cpu[processor]
        if (model == "") {
          if (part == "0xd81") model = "Cortex-A720"
          else if (part == "0xd82") model = "Cortex-X4"
          else if (part != "") model = "ARM CPU (part " part ")"
          else model = "ARM CPU model unavailable"
        }
        if (soc != "") model = model " (SoC " soc ")"
        print "model name\t: " model
      }
      has_model = 0; part = ""
    }
    FILENAME == models { if ($0 !~ /^#/) { split($0, fields, "\t"); model_by_cpu[fields[1]] = fields[2] }; next }
    /^processor[[:space:]]*:/ { if (have_processor) add_model(); processor = $2; gsub(/[[:space:]]/, "", processor); have_processor = 1; print; next }
    /^(model name|cpu|Model Name|Processor)[[:space:]]*:/ { has_model = 1 }
    /^CPU part[[:space:]]*:/ { part = $2; gsub(/[[:space:]]/, "", part) }
    /^$/ { if (have_processor) { add_model(); have_processor = 0 }; print; next }
    { print }
    END { if (have_processor) add_model() }
  ' "$TNX_CPU_MODEL_MAP" /proc/cpuinfo > "$tmp" && [ -s "$tmp" ] && mv -f "$tmp" "$TNX_CPUINFO_FILE" || { cp /proc/cpuinfo "$TNX_CPUINFO_FILE" 2>/dev/null || :; rm -f "$tmp"; }
  rm -f "$TNX_CPU_MODEL_MAP"
}
guest_login_isolated() {
  local distro="${1:?missing PRoot distribution}"; shift
  local prefix="${PREFIX:-/data/data/com.termux/files/usr}"
  local host_home="${TERMUX_HOST_HOME:-/data/data/com.termux/files/home}"
  local -a login_args=(--isolated --shared-x11)
  local -a android_env=() env_args=()
  local key pair bind_path
  local -a keys=(ANDROID_ART_ROOT ANDROID_ASSETS ANDROID_DATA ANDROID_I18N_ROOT ANDROID_ROOT ANDROID_STORAGE ANDROID_TZDATA_ROOT ANDROID__BUILD_VERSION_SDK ASEC_MOUNTPOINT BOOTCLASSPATH DEX2OATBOOTCLASSPATH EXTERNAL_STORAGE SYSTEMSERVERCLASSPATH TERMUX_APP__PACKAGE_NAME TERMUX__UID TERMUX__USER_ID TERMUX__HOME TERMUX__PREFIX)
  local -a host_bind_paths=(/apex /system /system_ext /vendor /odm /product /linkerconfig/ld.config.txt /linkerconfig/com.android.art/ld.config.txt)
  local -a api_cache_paths=("$host_home/.cache/ternux-camera" "$host_home/.cache/ternux-recorder")

  local storage_allowlist="$HOME/.local/share/ternux/storage-allowlist"
  local storage_root storage_host storage_guest storage_real storage_expected storage_extra
  # Expose Android storage at the documented /sdcard path in every managed
  # desktop. The Termux app must already have Android storage permission.
  storage_root="$(realpath -e /sdcard 2>/dev/null || true)"
  if [ -n "$storage_root" ] && [ -d "$storage_root" ]; then login_args+=(--bind "$storage_root:/sdcard"); fi
  if [ -e "$storage_allowlist" ]; then
    [ ! -L "$storage_allowlist" ] && [ -f "$storage_allowlist" ] || { echo "Unsafe Ternux storage allowlist; refusing storage mounts." >&2; return 1; }
    [ -n "$storage_root" ] && [ -d "$storage_root" ] || { echo "Granted Android storage is unavailable." >&2; return 1; }
    while IFS=$'\t' read -r storage_host storage_guest storage_extra; do
      [ -n "$storage_host" ] || continue
      storage_expected="/sdcard/${storage_host#"$storage_root"/}"
      [ -z "$storage_extra" ] && [[ "$storage_host" == "$storage_root"/* && "$storage_host" != *:* && "$storage_guest" == "$storage_expected" && "$storage_guest" != *:* ]] || { echo "Out-of-scope Ternux storage grant." >&2; return 1; }
      storage_real="$(realpath -e -- "$storage_host" 2>/dev/null)" || return 1
      [ "$storage_real" = "$storage_host" ] && [ -d "$storage_host" ] || return 1
      if [ "$storage_guest" != /sdcard ] || [ -z "$storage_root" ]; then login_args+=(--bind "$storage_host:$storage_guest"); fi
    done < "$storage_allowlist"
  fi
  login_args+=(--bind "$prefix:$prefix")
  for bind_path in "${host_bind_paths[@]}"; do
    [ -e "$bind_path" ] && login_args+=(--bind "$bind_path:$bind_path")
  done
  [ ! -L "$host_home" ] && [ ! -L "$host_home/.cache" ] || { echo "Refusing symlinked Termux home/cache path." >&2; return 1; }
  mkdir -p -- "$host_home/.cache" || return 1
  for bind_path in "${api_cache_paths[@]}"; do
    [ ! -L "$bind_path" ] || { echo "Refusing symlinked Termux API staging directory: $bind_path" >&2; return 1; }
    mkdir -p -- "$bind_path" || return 1
    login_args+=(--bind "$bind_path:$bind_path")
  done
  if [ -r "$prefix/etc/termux/termux.env" ]; then
    while IFS= read -r -d '' pair; do android_env+=("$pair"); done < <(
      (
        . "$prefix/etc/termux/termux.env"
        for key in "${keys[@]}"; do
          [ -n "${!key-}" ] && printf '%s=%s\0' "$key" "${!key}"
        done
      )
    )
  fi
  for pair in "${android_env[@]}"; do env_args+=(--env "$pair"); done
  proot-distro login "${login_args[@]}" "${env_args[@]}" "$distro" "$@"
}
kill_owned_child() {
  local child_pid="${1:-}" child_start="${2:-}" current_start=""
  [[ "$child_pid" =~ ^[0-9]+$ ]] && [ -n "$child_start" ] || return 0
  current_start="$(proc_start_identity "$child_pid")"
  [ "$current_start" = "$child_start" ] || return 0
  kill -TERM "$child_pid" 2>/dev/null || true
  local attempt=0
  while [ "$attempt" -lt 20 ] && kill -0 "$child_pid" 2>/dev/null; do
    current_start="$(proc_start_identity "$child_pid")"
    [ "$current_start" = "$child_start" ] || return 0
    sleep 0.1; attempt=$((attempt+1))
  done
  current_start="$(proc_start_identity "$child_pid")"
  [ "$current_start" = "$child_start" ] && kill -KILL "$child_pid" 2>/dev/null || true
}
cleanup() {
  kill_owned_child "${X11_PID:-}" "${X11_START_ID:-}"
  kill_owned_child "${VIRGL_PID:-}" "${VIRGL_START_ID:-}"
  if [[ "${PULSE_MODULE_ID:-}" =~ ^[0-9]+$ ]]; then pactl unload-module "$PULSE_MODULE_ID" >/dev/null 2>&1 || true; fi
  rm -f "$TNX_CPUINFO_FILE" "$TNX_CPU_MODEL_MAP" "$TNX_CPUINFO_FILE.tmp" "$TNX_GUEST_SESSION_SCRIPT" "$TNX_READY_FILE" "${TNX_IDENTITY_FILE}.tmp" 2>/dev/null || true
  termux-wake-unlock 2>/dev/null || true
  if [ -n "$TNX_PID_FILE" ] && [ "$(cat "$TNX_PID_FILE" 2>/dev/null || true)" = "$$" ]; then
    rm -f "$TNX_PID_FILE" "$TNX_IDENTITY_FILE"
  fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
termux-wake-lock 2>/dev/null || true
write_cpuinfo_with_model_names
unset PULSE_SERVER; pulseaudio --start --exit-idle-time=-1 --daemonize 2>/dev/null || true
sleep 0.3
PULSE_PORT=""
PULSE_MODULE_ID=""
for ((candidate=4713; candidate<=4722; candidate++)); do
  if PULSE_MODULE_ID="$(pactl load-module module-native-protocol-tcp listen=127.0.0.1 auth-ip-acl=127.0.0.1 auth-anonymous=1 port="$candidate" 2>/dev/null)"; then PULSE_PORT="$candidate"; break; fi
  PULSE_MODULE_ID=""
done
if [ -z "$PULSE_PORT" ]; then echo "ERROR: Could not open the loopback PulseAudio bridge on ports 4713-4722."; exit 1; fi
echo "PulseAudio bridge ready on 127.0.0.1:$PULSE_PORT."
# Display: tagged windows need a matching recent Termux:X11 Android APK.
# Older installed APKs reject -tag even when the Termux nightly companion is
# present, so retry on the same display in its shared-window compatibility mode.
TNX_TAGGED_DISPLAY=1
termux-x11 "$TNX_DISPLAY" -tag "$TNX_TAG" -legacy-drawing -ac &
X11_PID=$!
X11_START_ID="$(proc_start_identity "$X11_PID")"
TAGGED_WAITED=0
while [ ! -S "$TMPDIR/.X11-unix/X${TNX_DISPLAY#:}" ] && [ "$TAGGED_WAITED" -lt 50 ]; do
  if ! kill -0 "$X11_PID" 2>/dev/null; then break; fi
  TAGGED_WAITED=$((TAGGED_WAITED+1)); sleep 0.1
done
if [ ! -S "$TMPDIR/.X11-unix/X${TNX_DISPLAY#:}" ]; then
  kill_owned_child "$X11_PID" "$X11_START_ID"
  TNX_TAGGED_DISPLAY=0
  echo "WARNING: Termux:X11 APK did not create the tagged display; retrying shared-window mode."
  termux-x11 "$TNX_DISPLAY" -legacy-drawing -ac &
  X11_PID=$!
  X11_START_ID="$(proc_start_identity "$X11_PID")"
fi
echo "Waiting for Termux-X11..."
WAITED=0
while [ ! -S "$TMPDIR/.X11-unix/X${TNX_DISPLAY#:}" ]; do
  if ! kill -0 "$X11_PID" 2>/dev/null; then echo "ERROR: termux-x11 exited."; exit 1; fi
  if [ "$WAITED" -ge 300 ]; then echo "ERROR: timed out waiting for Termux:X11."; exit 1; fi
  WAITED=$((WAITED+1)); sleep 0.1
done
if [ "$TNX_TAGGED_DISPLAY" = 1 ]; then
  echo "Display $TNX_DISPLAY ready ($TNX_TAG)."
  mkdir -p "$(dirname "$TNX_PID_FILE")"
  printf 'tagged\n' > "$(dirname "$TNX_PID_FILE")/x11-display-mode"
  am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity -d "$TNX_TAG" >/dev/null 2>&1 || true
else
  echo "Display $TNX_DISPLAY ready (shared Termux:X11 window; install the matching nightly APK for separate guest windows)."
  mkdir -p "$(dirname "$TNX_PID_FILE")"
  printf 'shared\n' > "$(dirname "$TNX_PID_FILE")/x11-display-mode"
  am start -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1 || true
fi
# The preference service is provided by the live Termux:X11 app. Calling it
# before starting that app waits until timeout and silently leaves soft-keyboard
# input disabled, so apply the preference only after the display is ready.
if command -v termux-x11-preference >/dev/null 2>&1; then
  termux-x11-preference enforceCharBasedInput:true >/dev/null 2>&1 ||
    echo "WARNING: could not enable Termux:X11 character-based keyboard input."
fi
cat > "$TNX_GUEST_SESSION_SCRIPT" <<'TERNUX_GUEST_EOF'
#!/usr/bin/env bash
set -u
export HOME="/home/${TERNUX_GUEST_USER:-ternux}"
export GTK_IM_MODULE=ibus QT_IM_MODULE=ibus QT_QPA_PLATFORMTHEME=gtk3 XMODIFIERS=@im=ibus
export GTK_THEME=Ternux
if [ -r /etc/ternux/mesa-overlay ]; then
  read -r ternux_mesa_overlay < /etc/ternux/mesa-overlay || ternux_mesa_overlay=
  case "$ternux_mesa_overlay" in
    /usr/local/lib/ternux/*)
      if [ -r /etc/ternux/mesa-overlay-libdir ]; then
        read -r ternux_mesa_lib < /etc/ternux/mesa-overlay-libdir || ternux_mesa_lib=
      else
        ternux_mesa_lib="$ternux_mesa_overlay/lib/aarch64-linux-gnu"
      fi
      ternux_mesa_icd="$ternux_mesa_overlay/share/vulkan/icd.d/ternux_freedreno_icd.json"
      case "$ternux_mesa_lib" in "$ternux_mesa_overlay"/*)
      if [ -d "$ternux_mesa_lib/dri" ] && [ -r "$ternux_mesa_icd" ]; then
        export LD_LIBRARY_PATH="$ternux_mesa_lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
        export LIBGL_DRIVERS_PATH="$ternux_mesa_lib/dri"
        export VK_DRIVER_FILES="$ternux_mesa_icd" VK_ICD_FILENAMES="$ternux_mesa_icd"
      else
        echo "WARNING: Ternux Mesa overlay is incomplete; GPU acceleration may be unavailable." >&2
      fi
      ;;
      *) echo "WARNING: Ignoring an invalid Ternux Mesa library path." >&2 ;;
      esac
      ;;
    *) echo "WARNING: Ignoring an invalid Ternux Mesa overlay path." >&2 ;;
  esac
fi
if grep -q '^ID=alpine$' /etc/os-release 2>/dev/null && [ "$(uname -m)" = aarch64 ] && [ -r /usr/local/lib/ternux/libternux-faccessat.so ]; then
  if [ -n "${LD_PRELOAD:-}" ]; then LD_PRELOAD="/usr/local/lib/ternux/libternux-faccessat.so:$LD_PRELOAD"; else LD_PRELOAD=/usr/local/lib/ternux/libternux-faccessat.so; fi
  export LD_PRELOAD
fi
ibus_display_key=$(printf '%s' "$DISPLAY" | sed 's/[^A-Za-z0-9_.-]/_/g')
IBUS_ADDRESS="unix:path=/data/data/com.termux/files/usr/var/lib/ternux/runtime/ibus-${ibus_display_key}.sock"
export IBUS_ADDRESS
mkdir -p "$HOME/.runtime"
chmod 700 "$HOME/.runtime"
# Repair legacy root-owned cache paths before IBus binds its private socket.
sudo -n install -d -o "$(id -u)" -g "$(id -g)" -m 0700 "$HOME/.cache" "$HOME/.cache/ibus" "$HOME/.config/ibus" 2>/dev/null || true
sudo -n chown "$(id -u):$(id -g)" "$HOME/.cache" "$HOME/.cache/ibus" "$HOME/.config/ibus" 2>/dev/null || true
sudo -n mkdir -p /var/run/dbus /run/dbus "/run/user/$(id -u)" 2>/dev/null || true
sudo -n dbus-uuidgen --ensure >/dev/null 2>&1 || true
sudo -n rm -f /etc/xdg/autostart/light-locker.desktop 2>/dev/null || true
exec /usr/local/bin/ternux-session-bus bash -c '
  set -u
  until xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; do sleep 0.1; done
  # --replace targets the selected account session bus; process-wide pkill would
  # disrupt other PRoot desktops sharing the guest process namespace.
  /usr/local/bin/ternux-ibus-session-init || echo "WARNING: IBus session setup failed; Ctrl+Space may not work." >&2
  startxfce4 &
  session_pid=$!
  tries=0
  until { xfconf-query -c xsettings -l >/dev/null 2>&1 && pgrep -x xfdesktop >/dev/null 2>&1 && pgrep -x xfwm4 >/dev/null 2>&1; } || [ "$tries" -ge 100 ] || ! kill -0 "$session_pid" 2>/dev/null; do tries=$((tries + 1)); sleep 0.2; done
  if ! kill -0 "$session_pid" 2>/dev/null || ! pgrep -x xfdesktop >/dev/null 2>&1 || ! pgrep -x xfwm4 >/dev/null 2>&1; then echo "ERROR: XFCE session, window manager, or desktop did not become ready."; exit 1; fi
  shortcut_path="/commands/custom/<Primary>space"
  shortcut_ready=0
  shortcut_attempt=0
  while [ "$shortcut_attempt" -lt 10 ]; do
    xfconf-query -c xfce4-keyboard-shortcuts -p "$shortcut_path" --create -t string -s /usr/local/bin/ternux-ibus-next-engine >/dev/null 2>&1 || true
    if [ "$(xfconf-query -c xfce4-keyboard-shortcuts -p "$shortcut_path" 2>/dev/null || true)" = /usr/local/bin/ternux-ibus-next-engine ]; then shortcut_ready=1; break; fi
    shortcut_attempt=$((shortcut_attempt + 1))
    sleep 0.2
  done
  [ "$shortcut_ready" -eq 1 ] || echo "WARNING: Could not register the global Ctrl+Space IBus switch shortcut." >&2
  defaults_marker="$HOME/.config/ternux/desktop-defaults-v1"
  if [ ! -e "$defaults_marker" ]; then
    xfconf-query -c xsettings -p /Net/ThemeName --create -t string -s Ternux
    xfconf-query -c xsettings -p /Net/IconThemeName --create -t string -s Ternux
    xfconf-query -c xfwm4 -p /general/theme --create -t string -s Ternux
    xfconf-query -c xsettings -p /Gtk/CursorThemeName --create -t string -s Adwaita
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path --create -t string -s /usr/share/backgrounds/ternux/05-quantum-grid.svg
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/last-image --create -t string -s /usr/share/backgrounds/ternux/05-quantum-grid.svg
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-show --create -t bool -s true
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-style --create -t int -s 4
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image --create -t string -s /usr/share/backgrounds/ternux/05-quantum-grid.svg
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/image-style --create -t int -s 4
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor1/image-path --create -t string -s /usr/share/backgrounds/ternux/05-quantum-grid.svg >/dev/null 2>&1 || true
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor1/last-image --create -t string -s /usr/share/backgrounds/ternux/05-quantum-grid.svg >/dev/null 2>&1 || true
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor1/image-show --create -t bool -s true >/dev/null 2>&1 || true
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor1/image-style --create -t int -s 4 >/dev/null 2>&1 || true
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor1/workspace0/last-image --create -t string -s /usr/share/backgrounds/ternux/05-quantum-grid.svg >/dev/null 2>&1 || true
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor1/workspace0/image-style --create -t int -s 4 >/dev/null 2>&1 || true
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitorbuiltin/workspace0/last-image --create -t string -s /usr/share/backgrounds/ternux/05-quantum-grid.svg
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitorbuiltin/workspace0/image-style --create -t int -s 5
    xfconf-query -c xfwm4 -p /general/button_layout --create -t string -s "|HMC"
    for panel_id in $(xfconf-query -c xfce4-panel -l 2>/dev/null | sed -n "s#^/panels/\(panel-[0-9][0-9]*\)/.*#\1#p" | sort -u); do xfconf-query -c xfce4-panel -p "/panels/$panel_id/background-style" --create -t int -s 0 >/dev/null 2>&1 || true; done
    xfconf-query -c xfwm4 -p /general/use_compositing -s false >/dev/null 2>&1 || true
    xfdesktop --reload >/dev/null 2>&1 || true
    install -d -m 0755 "$HOME/.config/ternux"
    : > "$defaults_marker"
  fi
  wallpaper_migration_marker="$HOME/.config/ternux/monitorbuiltin-wallpaper-v1"
  if [ ! -e "$wallpaper_migration_marker" ]; then
    current_wallpaper=$(xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitorbuiltin/workspace0/last-image 2>/dev/null || true)
    if [ -z "$current_wallpaper" ] || [ ! -r "$current_wallpaper" ] || [ "$current_wallpaper" = /usr/share/images/desktop-base/default ]; then
      xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitorbuiltin/workspace0/last-image --create -t string -s /usr/share/backgrounds/ternux/05-quantum-grid.svg
      xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitorbuiltin/workspace0/image-style --create -t int -s 5
      xfdesktop --reload >/dev/null 2>&1 || true
    fi
    install -d -m 0755 "$HOME/.config/ternux"; : > "$wallpaper_migration_marker"
  fi
  wallpaper_readability_marker="$HOME/.config/ternux/readable-wallpaper-v1"
  if [ ! -e "$wallpaper_readability_marker" ]; then
    fallback_wallpaper=/usr/share/backgrounds/ternux/05-quantum-grid.svg
    for monitor in monitor0 monitor1 monitorbuiltin; do
      monitor_path="/backdrop/screen0/$monitor"
      for wallpaper_property in image-path last-image workspace0/last-image; do
        property_path="$monitor_path/$wallpaper_property"
        current_wallpaper=$(xfconf-query -c xfce4-desktop -p "$property_path" 2>/dev/null || true)
        if [ -z "$current_wallpaper" ] || [ ! -r "$current_wallpaper" ]; then
          xfconf-query -c xfce4-desktop -p "$property_path" --create -t string -s "$fallback_wallpaper" >/dev/null 2>&1 || true
        fi
      done
      xfconf-query -c xfce4-desktop -p "$monitor_path/image-show" --create -t bool -s true >/dev/null 2>&1 || true
    done
    xfdesktop --reload >/dev/null 2>&1 || true
    install -d -m 0755 "$HOME/.config/ternux"; : > "$wallpaper_readability_marker"
  fi
  icon_migration_marker="$HOME/.config/ternux/desktop-icons-v2"
  if [ ! -e "$icon_migration_marker" ]; then
    current_icon_theme=$(xfconf-query -c xsettings -p /Net/IconThemeName 2>/dev/null || true)
    if [ "$current_icon_theme" = Adwaita ]; then xfconf-query -c xsettings -p /Net/IconThemeName --create -t string -s Ternux; fi
    install -d -m 0755 "$HOME/.config/ternux"; : > "$icon_migration_marker"
  fi
  wm_controls_marker="$HOME/.config/ternux/window-controls-v2"
  if [ ! -e "$wm_controls_marker" ]; then xfconf-query -c xfwm4 -p /general/button_layout --create -t string -s "|HMC" >/dev/null 2>&1 || true; install -d -m 0755 "$HOME/.config/ternux"; : > "$wm_controls_marker"; fi
  taskmanager_marker="$HOME/.config/ternux/taskmanager-performance-v1"
  if [ ! -e "$taskmanager_marker" ]; then
    xfconf-query -c xfce4-taskmanager -p /interface/show-all-processes --create -t bool -s false >/dev/null 2>&1 || true
    xfconf-query -c xfce4-taskmanager -p /interface/process-tree --create -t bool -s false >/dev/null 2>&1 || true
    xfconf-query -c xfce4-taskmanager -p /interface/refresh-rate --create -t int -s 1000 >/dev/null 2>&1 || true
    install -d -m 0755 "$HOME/.config/ternux"; : > "$taskmanager_marker"
  fi
  /usr/local/bin/ternux-panel-shortcuts >/dev/null 2>&1 || true
  printf "READY\n" > "$TERNUX_READY_FILE"
  wait "$session_pid"
'
TERNUX_GUEST_EOF
chmod 700 "$TNX_GUEST_SESSION_SCRIPT"
LAUNCHEOF

  if [ "$backend" = "zink" ]; then
    cat >> "$LAUNCHER" << EOF
 : > "\$TNX_READY_FILE"
chmod 666 "\$TNX_READY_FILE"
guest_login_isolated $distro --bind /dev/kgsl-3d0:/dev/kgsl-3d0 --bind /dev/kgsl-3d0:/dev/kgsl --bind /dev/dri --bind "\$TNX_CPUINFO_FILE:/proc/cpuinfo" --bind "\$TNX_GUEST_SESSION_SCRIPT:/tmp/ternux-desktop-session.sh" --bind "\$TNX_READY_FILE:/tmp/ternux-desktop-ready" --user $user_name \\
  --env DISPLAY=__TNX_DISPLAY__ --env PULSE_SERVER="tcp:127.0.0.1:\$PULSE_PORT" \\
  --env TERNUX_GUEST_USER=$user_name --env TERNUX_READY_FILE=/tmp/ternux-desktop-ready \\
  --env MESA_LOADER_DRIVER_OVERRIDE=zink --env TU_DEBUG=noconform --env MESA_VK_WSI_DEBUG=sw \\
  --env MESA_DISK_CACHE_SINGLE_FILE=1 --env MESA_SHADER_CACHE_MAX_SIZE=2048M \\
  --env QT_X11_NO_MITSHM=1 --env XDG_RUNTIME_DIR=/home/$user_name/.runtime \\
  --env LANG=$locale --env LC_ALL=$locale \\
  -- /tmp/ternux-desktop-session.sh
EOF
  else
    cat >> "$LAUNCHER" << 'VIRGLEOF'
virgl_test_server_android >/dev/null 2>&1 &
VIRGL_PID=$!
VIRGL_START_ID="$(proc_start_identity "$VIRGL_PID")"
sleep 1
if ! kill -0 "$VIRGL_PID" 2>/dev/null; then echo "WARNING: virgl_test_server_android failed to start; check for llvmpipe."; fi
VIRGLEOF
    cat >> "$LAUNCHER" << EOF
 : > "\$TNX_READY_FILE"
chmod 666 "\$TNX_READY_FILE"
guest_login_isolated $distro --bind "\$TNX_CPUINFO_FILE:/proc/cpuinfo" --bind "\$TNX_GUEST_SESSION_SCRIPT:/tmp/ternux-desktop-session.sh" --bind "\$TNX_READY_FILE:/tmp/ternux-desktop-ready" --user $user_name \\
  --env DISPLAY=__TNX_DISPLAY__ --env PULSE_SERVER="tcp:127.0.0.1:\$PULSE_PORT" \\
  --env TERNUX_GUEST_USER=$user_name --env TERNUX_READY_FILE=/tmp/ternux-desktop-ready \\
  --env GALLIUM_DRIVER=virpipe --env MESA_GL_VERSION_OVERRIDE=4.3COMPAT \\
  --env QT_X11_NO_MITSHM=1 --env XDG_RUNTIME_DIR=/home/$user_name/.runtime \\
  --env LANG=$locale --env LC_ALL=$locale \\
  -- /tmp/ternux-desktop-session.sh
EOF
  fi

  # Replace only fixed, validated display/tag placeholders after composing both
  # renderer variants, so guest names cannot alter the generated shell syntax.
  sed -i "s|__TNX_DISPLAY__|$display|g; s|__TNX_TAG__|$tag|g; s|__TNX_SESSION_PID__|$session_pid_rel|g" "$LAUNCHER" || return 1
  chmod +x "$LAUNCHER"
  if bash -n "$LAUNCHER" 2>/dev/null; then
    local link_tmp="$HOME/.x.sh.ternux-tmp.$$"
    ln -s "$LAUNCHER" "$link_tmp" && mv -f "$link_tmp" "$HOME/x.sh" || { rm -f "$link_tmp"; return 1; }
    tnx_ok "Launcher written for $distro: $LAUNCHER"
    tnx_state_set "backend" "$backend"
    tnx_distro_state_set "$distro" backend "$backend"
    tnx_distro_state_set "$distro" display "$display_num"
  else
    tnx_fail "Launcher has a syntax error."; rm -f "$LAUNCHER"; return 1
  fi
}

# ---------------------------------------------------------------------------
# Phase 8 — shell aliases
# ---------------------------------------------------------------------------
# Powerlevel10k for the Termux host shell. The configuration wizard is disabled
# so an unattended install never stops at a prompt — `p10k configure` runs it
# later by choice. No network, no git or an incomplete clone leaves zsh working
# without the theme rather than failing the phase.
_tnx_setup_p10k() {
  local dir="$HOME/.local/share/ternux/powerlevel10k"
  if [ ! -r "$dir/powerlevel10k.zsh-theme" ]; then
    tnx_has_cmd git || { tnx_warn "git is missing; zsh installed without a theme."; return 0; }
    mkdir -p "$(dirname "$dir")"
    tnx_spin_run "Fetch powerlevel10k" git clone --depth=1 --quiet \
      https://github.com/romkatv/powerlevel10k "$dir" || {
        tnx_warn "powerlevel10k could not be fetched; zsh installed without a theme."
        return 0
      }
  fi
  [ -r "$dir/powerlevel10k.zsh-theme" ] || {
    tnx_warn "powerlevel10k files are incomplete; zsh installed without a theme."
    return 0
  }
  if ! grep -q "TERNUX ZSH THEME" "$HOME/.zshrc" 2>/dev/null; then
    cat >> "$HOME/.zshrc" << P10KEOF

# ==== TERNUX ZSH THEME ====
# Glyphs need a Nerd Font in the terminal; run 'p10k configure' to restyle.
POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
_tnx_p10k="\$HOME/.local/share/ternux/powerlevel10k/powerlevel10k.zsh-theme"
[ -r "\$_tnx_p10k" ] && source "\$_tnx_p10k"
unset _tnx_p10k
[ -r ~/.p10k.zsh ] && source ~/.p10k.zsh
# ==== END TERNUX ZSH THEME ====
P10KEOF
  fi
  tnx_ok "zsh theme installed (powerlevel10k)"
}

tnx_phase_aliases() {
  local user_name="${1:-ternux}" shell_choice="${2:-bash}"
  local distro; distro="$(tnx_distro)"
  local RC_FILE="$HOME/.bashrc"
  if [ "$shell_choice" = "zsh" ]; then
    tnx_has_cmd zsh || tnx_spin_run "Install zsh" tnx_termux_pkg install zsh -y \
      -o APT::Color=1 -o Dpkg::Progress-Fancy=1 || true
    RC_FILE="$HOME/.zshrc"; touch "$RC_FILE"
    # </dev/null so a chsh that wants a password cannot stall the install.
    tnx_has_cmd chsh && chsh -s zsh </dev/null >/dev/null 2>&1 || true
    [ "${TERNUX_THEME:-p10k}" = "none" ] || _tnx_setup_p10k
  fi

  [ -e "$RC_FILE" ] || touch "$RC_FILE"
  RC_FILE="$(realpath -e -- "$RC_FILE" 2>/dev/null)" || { tnx_fail "Cannot resolve shell configuration path."; return 1; }
  if grep -q '^# ==== TERNUX ALIASES ====$' "$RC_FILE" 2>/dev/null; then
    local aliases_tmp aliases_mode
    aliases_mode="$(stat -c '%a' "$RC_FILE" 2>/dev/null || echo 600)"
    [[ "$aliases_mode" =~ ^[0-7]{3,4}$ ]] || { tnx_fail "Shell configuration permissions are invalid."; return 1; }
    aliases_tmp="$(umask 077; mktemp "${RC_FILE}.ternux-tmp.XXXXXX")" || return 1
    if ! awk '
      $0 == "# ==== TERNUX ALIASES ====" { if (skip) exit 2; skip=1; next }
      $0 == "# ==== END TERNUX ALIASES ====" && skip { skip=0; next }
      !skip { print }
      END { if (skip) exit 2 }
    ' "$RC_FILE" > "$aliases_tmp"; then
      rm -f -- "$aliases_tmp"
      tnx_fail "Existing Ternux alias block is malformed; preserving $RC_FILE."
      return 1
    fi
    chmod "$aliases_mode" "$aliases_tmp" && mv -f -- "$aliases_tmp" "$RC_FILE" || { rm -f -- "$aliases_tmp"; return 1; }
  fi

  local gui_profiles="${TERNUX_DISTRO_KNOWN:-debian ubuntu}"
  cat >> "$RC_FILE" << ALIASEOF

# ==== TERNUX ALIASES ====
alias tx='ternux'
alias x='ternux start'
alias killx='ternux stop'
_ternux_guest_login() {
  [ -z "\${ZSH_VERSION:-}" ] || emulate -L bash
  local distro="\$1"; shift
  local -a login_args=(--isolated)
  local allowlist="\$HOME/.local/share/ternux/storage-allowlist" root host guest resolved expected extra
  while [ "\$#" -gt 0 ]; do
    case "\$1" in
      --shared-tmp|--shared-x11) login_args+=("\$1"); shift ;;
      --user|--bind|--env)
        [ "\$#" -ge 2 ] || { printf 'Missing value for %s\n' "\$1" >&2; return 2; }
        login_args+=("\$1" "\$2"); shift 2 ;;
      *) break ;;
    esac
  done
  if [ -e "\$allowlist" ]; then
    [ ! -L "\$allowlist" ] && [ -f "\$allowlist" ] || return 1
    root="\$(realpath -e /sdcard 2>/dev/null)" || return 1
    while IFS=$'\t' read -r host guest extra; do
      [ -n "\$host" ] || continue
      expected="/sdcard/\${host#"\$root"/}"
      [ -z "\$extra" ] && [[ "\$host" == "\$root"/* && "\$host" != *:* && "\$guest" == "\$expected" && "\$guest" != *:* ]] || return 1
      resolved="\$(realpath -e -- "\$host" 2>/dev/null)" || return 1
      [ "\$resolved" = "\$host" ] && [ -d "\$host" ] || return 1
      login_args+=(--bind "\$host:\$guest")
    done < "\$allowlist"
  fi
  proot-distro login "\${login_args[@]}" "\$distro" "\$@"
}
_ternux_guest_user() {
  local profile="\$HOME/.local/share/ternux/distros/\$1/profile" user
  user="\$(sed -n 's/^user=//p' "\$profile" 2>/dev/null | head -n 1)"
  printf '%s\n' "\${user:-ternux}"
}
db() { _ternux_guest_login debian --shared-tmp --user "\$(_ternux_guest_user debian)" "\$@"; }
dbroot() { _ternux_guest_login debian --shared-tmp "\$@"; }
dbr() { dbroot "\$@"; }
droot() { dbroot "\$@"; }
ub() { _ternux_guest_login ubuntu --shared-tmp --user "\$(_ternux_guest_user ubuntu)" "\$@"; }
ubroot() { _ternux_guest_login ubuntu --shared-tmp "\$@"; }
ubr() { ubroot "\$@"; }
alp() { _ternux_guest_login alpine --shared-tmp --user "\$(_ternux_guest_user alpine)" "\$@"; }
alproot() { _ternux_guest_login alpine --shared-tmp "\$@"; }
alpr() { alproot "\$@"; }
archx() { _ternux_guest_login archlinux --shared-tmp --user "\$(_ternux_guest_user archlinux)" "\$@"; }
archroot() { _ternux_guest_login archlinux --shared-tmp "\$@"; }
fed() { _ternux_guest_login fedora --shared-tmp --user "\$(_ternux_guest_user fedora)" "\$@"; }
fedr() { _ternux_guest_login fedora --shared-tmp "\$@"; }
suse() { _ternux_guest_login opensuse --shared-tmp --user "\$(_ternux_guest_user opensuse)" "\$@"; }
suser() { _ternux_guest_login opensuse --shared-tmp "\$@"; }
vsh() { _ternux_guest_login void --shared-tmp --user "\$(_ternux_guest_user void)" "\$@"; }
vroot() { _ternux_guest_login void --shared-tmp "\$@"; }
kal() { _ternux_guest_login kali --shared-tmp --user "\$(_ternux_guest_user kali)" "\$@"; }
kalr() { _ternux_guest_login kali --shared-tmp "\$@"; }
_ternux_xgo() {
  [ -z "\${ZSH_VERSION:-}" ] || emulate -L bash
  local -a installed=() selectable=()
  local distro choice label i=0
  while IFS= read -r distro; do
    [ -n "\$distro" ] || continue
    installed+=("\$distro")
    case " ${gui_profiles} " in
      *" \$distro "*)
        if grep -qx 'status=ready' "\$HOME/.local/share/ternux/distros/\$distro/profile" 2>/dev/null ||
           { [ "\$distro" = debian ] && grep -qx 'distro=debian' "\$HOME/.local/share/ternux/state" 2>/dev/null && grep -qx 'phase_verify' "\$HOME/.local/share/ternux/phases" 2>/dev/null; }; then
          selectable+=("\$distro")
        fi ;;
    esac
  done < <(proot-distro list --quiet 2>/dev/null)
  if [ \${#installed[@]} -eq 0 ]; then
    printf 'No Ternux guest is installed. Run: tx install\n' >&2; return 1
  fi
  if [ \${#selectable[@]} -eq 0 ]; then
    printf 'Installed guests: %s\n' "\${installed[*]}" >&2
    printf 'None has a Ternux desktop profile yet; use tx distro shell NAME.\n' >&2; return 1
  fi
  if [ \${#installed[@]} -eq 1 ]; then
    choice="\${installed[0]}"
  else
    printf 'Installed PRoot guests:\n'
    for distro in "\${installed[@]}"; do
      case " ${gui_profiles} " in
        *" \$distro "*)
          if [[ " ${selectable[*]} " == *" \$distro "* ]]; then label='Ternux desktop ready'; else label='recipe available; not configured'; fi
          i=\$((i+1)); printf '  %d) %s — %s\n' "\$i" "\$distro" "\$label" ;;
        *) i=\$((i+1)); printf '  %d) %s — shell/image only\n' "\$i" "\$distro" ;;
      esac
    done
    printf 'Choose a guest for the GUI (shell-only images cannot start a desktop):\n'
    while :; do
      printf 'Selection [1-%d]: ' "\${#installed[@]}"
      IFS= read -r choice || return 1
      case "\$choice" in
        ''|*[!0-9]*) printf 'Enter a number from 1 to %d.\n' "\${#installed[@]}" >&2 ;;
        *) if [ "\$choice" -ge 1 ] && [ "\$choice" -le \${#installed[@]} ]; then choice="\${installed[choice-1]}"; break; fi
           printf 'Enter a number from 1 to %d.\n' "\${#installed[@]}" >&2 ;;
      esac
    done
  fi
  case " ${gui_profiles} " in
    *" \$choice "*) ternux start "\$choice" ;;
    *) printf "Guest '%s' is installed, but Ternux has no desktop recipe for it yet. Open a shell with: tx distro shell %s\n" "\$choice" "\$choice" >&2; return 1 ;;
  esac
}
xgo() { _ternux_xgo; }
clean-mesa() { _ternux_guest_login "\$distro" --user "\$user_name" -- bash -c 'rm -rf -- ~/.cache/mesa ~/.cache/mesa_shader_cache ~/.cache/mesa_shader_cache_db ~/.cache/mesa_shader_cache_sf'; echo "Mesa cache cleared."; }
sysmon() { echo "--- CPU & Memory ---"; free -h; echo ""; echo "--- GPU / KGSL ---"; ls -l /dev/kgsl-3d0 /dev/dri 2>/dev/null || echo "No GPU nodes."; }
# ==== END TERNUX ALIASES ====
ALIASEOF
  tnx_ok "Aliases installed: tx, x, xgo, killx, distro user/root shells (including dbroot/ubroot/alproot), sysmon"
}

# ---------------------------------------------------------------------------
# Phase 9 — optional workloads
# ---------------------------------------------------------------------------
# Optional third-party installer scripts are pinned by content digest and
# product version. Fail closed when an upstream URL changes until Ternux
# reviews and updates the pin.
tnx_run_pinned_optional_installer() {
  local user_name="${1:?missing Debian user}" url="${2:?missing installer URL}"
  local sha256="${3:?missing installer SHA-256}"
  shift 3
  [[ "$sha256" =~ ^[0-9a-f]{64}$ ]] || { tnx_warn "Optional installer has no valid pinned SHA-256."; return 2; }
  case "$url" in
    https://hermes-agent.nousresearch.com/install.sh|https://openclaw.ai/install.sh) ;;
    *) tnx_warn "Refusing an unapproved optional installer source: $url"; return 2 ;;
  esac

  tnx_guest_login --shared-tmp --user "$user_name" -- bash -lc '
    set -euo pipefail
    url="$1"; expected_sha256="$2"; shift 2
    installer="$(mktemp "${TMPDIR:-/tmp}/ternux-optional-installer.XXXXXX")"
    trap "rm -f -- \"$installer\"" EXIT
    curl -fsSL --proto "=https" --tlsv1.2 --connect-timeout 15 --max-time 180 --max-filesize 2000000 \
      --retry 2 --retry-delay 2 --output "$installer" "$url"
    if ! printf "%s  %s\n" "$expected_sha256" "$installer" | sha256sum --check --status; then
      echo "Optional installer SHA-256 mismatch; refusing to execute it." >&2
      exit 1
    fi
    bash -n "$installer"
    bash "$installer" "$@"
  ' _ "$url" "$sha256" "$@"
}

tnx_phase_extras() {
  local user_name="${1:-ternux}"; shift
  local rc=0 opt selected node_selected=0 go_version="" cores jobs htp_selected=0 adt_selected=0 celestia_selected=0
  local -a apt_packages=() unique_packages=() install_opts=()
  local APT="sudo apt update -o APT::Color=1 && sudo DEBIAN_FRONTEND=noninteractive apt install -y -o APT::Color=1 -o Dpkg::Progress-Fancy=1"

  tnx_distro_profile || { tnx_warn "No package recipe for guest '$(tnx_distro)'."; return 2; }
  if [ "$TNX_DP_FAMILY" != apt ] && [ "$#" -gt 0 ]; then
    tnx_warn "Optional workload recipes currently require an APT guest; '$TNX_DP_FAMILY' desktop base remains usable."
    return 2
  fi

  # Resolve individual software choices and install apt packages in one pass.
  for opt in "$@"; do
    case "$opt" in
      dev) apt_packages+=(git curl wget nodejs npm python3 python3-pip python3-venv build-essential ca-certificates); node_selected=1 ;;
      llm) apt_packages+=(build-essential cmake git pkg-config libvulkan-dev vulkan-tools clinfo glslang-dev glslang-tools libshaderc-dev glslc) ;;
      network) apt_packages+=(nmap tmux) ;;
      media) apt_packages+=(ffmpeg gimp audacity imagemagick) ;;
      git) apt_packages+=(git curl wget ca-certificates) ;;
      python) apt_packages+=(python3 python3-venv python3-pip) ;;
      node|claude|codex) apt_packages+=(nodejs npm); node_selected=1 ;;
      build) apt_packages+=(build-essential cmake ninja-build pkg-config) ;;
      rust) apt_packages+=(rustc cargo) ;;
      java) apt_packages+=(default-jdk-headless) ;;
      golang) apt_packages+=(golang-go) ;;
      php) apt_packages+=(php-cli) ;;
      sqlite3) apt_packages+=(sqlite3) ;;
      ripgrep) apt_packages+=(ripgrep) ;;
      jq) apt_packages+=(jq) ;;
      htop) apt_packages+=(htop) ;;
      tree) apt_packages+=(tree) ;;
      godot) apt_packages+=(godot) ;;
      geany) apt_packages+=(geany) ;;
      neovim) apt_packages+=(neovim) ;;
      micro) apt_packages+=(micro) ;;
      thonny) apt_packages+=(thonny) ;;
      gh) apt_packages+=(gh) ;;
      evolution) apt_packages+=(evolution gnome-online-accounts-gtk) ;;
      celestia) celestia_selected=1; apt_packages+=(python3 gnupg ca-certificates) ;;
      adt-build-tools|adt-platform-tools|adt-ndk|adt-cmake) apt_packages+=(git curl ca-certificates) ;;
      adt-cmdline|adt-platform) apt_packages+=(git curl ca-certificates default-jdk-headless unzip) ;;
      llama-htp-experimental|htp-runtime)
        htp_selected=1
        apt_packages+=(libgbinder1 libglibutil1 libfastrpc1 libfastrpc-dev)
        ;;
      nmap) apt_packages+=(nmap) ;;
      tmux) apt_packages+=(tmux) ;;
      ffmpeg) apt_packages+=(ffmpeg) ;;
      vlc) apt_packages+=(vlc) ;;
      mpv) apt_packages+=(mpv) ;;
      gimp) apt_packages+=(gimp) ;;
      krita) apt_packages+=(krita) ;;
      inkscape) apt_packages+=(inkscape) ;;
      audacity) apt_packages+=(audacity) ;;
      imagemagick) apt_packages+=(imagemagick) ;;
      libreoffice-writer) apt_packages+=(libreoffice-writer) ;;
      libreoffice-calc) apt_packages+=(libreoffice-calc) ;;
      libreoffice-draw) apt_packages+=(libreoffice-draw) ;;
      blender) apt_packages+=(blender xvfb) ;;
    esac
  done
  for opt in "${apt_packages[@]}"; do
    case " ${unique_packages[*]} " in *" $opt "*) ;; *) unique_packages+=("$opt") ;; esac
  done
  if [ "$htp_selected" -eq 1 ]; then
    if [ "$(tnx_distro)" != debian ]; then
      tnx_warn "The experimental HTP extension dependency setup currently supports the Debian guest only."
      rc=1
    elif ! tnx_guest_login --shared-tmp -- bash -c '
      set -e
      source_file=/etc/apt/sources.list.d/ternux-htp-backports.list
      source_line="deb https://deb.debian.org/debian trixie-backports main contrib"
      if [ -e "$source_file" ]; then
        [ "$(cat "$source_file")" = "$source_line" ] || { echo "Refusing to replace existing $source_file" >&2; exit 2; }
      else
        printf "%s\n" "$source_line" > "$source_file"
      fi
    '; then
      tnx_warn "Could not configure the official Debian Trixie Backports source for HTP dependencies."
      rc=1
    fi
  fi
  if [ ${#unique_packages[@]} -gt 0 ]; then
    # Resolve package availability first, then install each selected package in
    # its own transaction. A distro-specific missing package must not prevent
    # unrelated selected tools from being installed.
    if ! tnx_guest_login --shared-tmp --user "$user_name" -- bash -s -- "${unique_packages[@]}" <<'TNX_APT_OPTIONAL_INSTALL'
set -u
export DEBIAN_FRONTEND=noninteractive
sudo apt update -o APT::Color=1 || exit 1
failed=0
for package in "$@"; do
  candidate="$(apt-cache policy "$package" 2>/dev/null | awk '/^[[:space:]]*Candidate:/ {print $2; exit}')"
  if [ -z "$candidate" ] || [ "$candidate" = '(none)' ]; then
    printf 'Ternux: no repository candidate for optional package %s; continuing with the remaining selections.\n' "$package" >&2
    failed=1
    continue
  fi
  if ! sudo DEBIAN_FRONTEND=noninteractive apt install -y -o APT::Color=1 -o Dpkg::Progress-Fancy=1 "$package"; then
    printf 'Ternux: optional package %s failed; continuing with the remaining selections.\n' "$package" >&2
    failed=1
  fi
done
exit "$failed"
TNX_APT_OPTIONAL_INSTALL
    then tnx_warn "One or more selected packages were unavailable or failed; other selected packages were still attempted."; rc=1; fi
  fi
  if [ "$celestia_selected" -eq 1 ]; then
    if [ "$(tnx_distro)" != debian ]; then
      tnx_warn "Celestia optional install currently supports the Debian guest only."
      rc=1
    elif ! tnx_guest_login --shared-tmp --user "$user_name" -- bash -lc 'sudo /usr/local/bin/ternux-install-celestia'; then
      tnx_warn "Celestia could not be installed; its repository signature/package checks failed, or a dependency failed."
      rc=1
    fi
  fi

  if [ "$node_selected" = 1 ]; then
    tnx_guest_login --shared-tmp --user "$user_name" -- bash -lc '
      set -e
      mkdir -p "$HOME/.local/bin"
      npm config set prefix "$HOME/.local"
      for profile in "$HOME/.profile" "$HOME/.bashrc" "$HOME/.zshrc"; do
        [ -e "$profile" ] || : > "$profile"
        if ! grep -qF "# Ternux optional tool path" "$profile"; then
          printf "\\n%s\\n%s\\n" "# Ternux optional tool path" "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$profile"
        fi
      done
    ' || { tnx_warn "Could not configure the user-local npm path."; rc=1; }
  fi

  # ADT needs its command-line tools (which provide sdkmanager) before it can
  # resolve and install versioned SDK components. Preserve the selected set but
  # run those dependencies first, regardless of the menu's display order.
  for selected in "$@"; do
    case "$selected" in
      adt-build-tools|adt-platform-tools|adt-ndk|adt-cmake|adt-cmdline|adt-platform) adt_selected=1 ;;
    esac
  done
  if [ "$adt_selected" -eq 1 ]; then install_opts+=(adt-cmdline); fi
  for opt in adt-platform adt-build-tools adt-platform-tools adt-ndk adt-cmake; do
    for selected in "$@"; do
      if [ "$selected" = "$opt" ]; then install_opts+=("$opt"); break; fi
    done
  done
  for opt in "$@"; do
    case "$opt" in
      adt-build-tools|adt-platform-tools|adt-ndk|adt-cmake|adt-cmdline|adt-platform) ;;
      *) install_opts+=("$opt") ;;
    esac
  done
  for opt in "${install_opts[@]}"; do
    case "$opt" in
      dev|llm|network|media|git|python|node|build|rust|java|golang|php|sqlite3|ripgrep|jq|htop|tree|godot|geany|neovim|micro|thonny|gh|nmap|tmux|ffmpeg|vlc|mpv|gimp|krita|inkscape|audacity|imagemagick|libreoffice-writer|libreoffice-calc|libreoffice-draw|blender) ;;
      adt-build-tools|adt-platform-tools|adt-ndk|adt-cmake|adt-cmdline|adt-platform)
        if tnx_guest_login --shared-tmp --user "$user_name" -- bash -lc '
          set -e
          export ANDROID_HOME="${ANDROID_HOME:-$HOME/android-sdk}"
          export ANDROID_SDK_ROOT="$ANDROID_HOME"
          mkdir -p "$ANDROID_HOME"
          repo="$HOME/.local/share/ternux/adt"
          mkdir -p "$(dirname "$repo")"
          if [ -e "$repo" ]; then
            [ -d "$repo/.git" ] || { echo "Refusing to overwrite unexpected ADT path: $repo" >&2; exit 2; }
            remote="$(git -C "$repo" remote get-url origin 2>/dev/null || true)"
            case "$remote" in https://github.com/soobujmiah/adt.git|git@github.com:soobujmiah/adt.git) ;;
              *) echo "Refusing to use ADT checkout with unexpected origin: ${remote:-none}" >&2; exit 2 ;;
            esac
          else git clone --depth 1 https://github.com/soobujmiah/adt.git "$repo"; fi
          case "$1" in
            adt-build-tools) component=build-tools; command=install-build-tools ;;
            adt-platform-tools) component=platform-tools; command=install-platform-tools ;;
            adt-ndk) component=ndk; command=install-ndk ;;
            adt-cmake) component=cmake; command=install-cmake ;;
            adt-cmdline) component=cmdline-tools; command=install-cmd-tools ;;
            adt-platform) component=platform; command=install-platforms ;;
          esac
          case "$component" in
            platform) bash "$repo/setup.sh" "$command" android-36 ;;
            cmdline-tools) bash "$repo/setup.sh" "$command" ;;
            cmake) bash "$repo/setup.sh" "$command" ;;
            ndk) version="$(bash -c '\''cd "$(dirname "$1")"; ADT_SOURCE_ONLY=1 source "$1"; get_bootstrap_ndk'\'' _ "$repo/setup.sh")"; bash "$repo/setup.sh" "$command" "$version" ;;
            *) version="$(bash -c '\''cd "$(dirname "$1")"; ADT_SOURCE_ONLY=1 source "$1"; get_bootstrap_version "$2"'\'' _ "$repo/setup.sh" "$component")"; [ -n "$version" ] || { echo "ADT has no verified $component version." >&2; exit 1; }; bash "$repo/setup.sh" "$command" "$version" ;;
          esac
        ' _ "$opt"; then
          tnx_ok "$opt installed through the ADT repository"
        else tnx_warn "$opt could not be installed through ADT; check the ADT output."; rc=1; fi
        ;;
      stable-diffusion)
        if ! tnx_guest_login --shared-tmp --user "$user_name" -- bash -lc \
          'sudo apt update -o APT::Color=1 && sudo DEBIAN_FRONTEND=noninteractive apt install -y -o Dpkg::Progress-Fancy=1 libgomp1 libvulkan1'; then
          tnx_warn "Stable Diffusion runtime dependencies could not be installed."; rc=1
        elif [ -f "${_TNX_SRC:-}/lib/extension.sh" ] && ( . "${_TNX_SRC}/lib/extension.sh"; tnx_cmd_extension install "$opt" ); then
          tnx_ok "stable-diffusion release installed and validated"
        else tnx_warn "stable-diffusion release could not be installed; check device/runtime support and the extension guide."; rc=1; fi
        ;;
      htp-runtime) : ;; # Internal dependency-only path used by the managed extension command.
      llama-vulkan|llama-htp-experimental)
        if [ -f "${_TNX_SRC:-}/lib/extension.sh" ] && ( . "${_TNX_SRC}/lib/extension.sh"; tnx_cmd_extension install "$opt" ); then
          tnx_ok "$opt release installed and validated"
        else tnx_warn "$opt release could not be installed; check device/runtime support and the extension guide."; rc=1; fi
        ;;
      claude)
        if tnx_guest_login --shared-tmp --user "$user_name" -- bash -lc '
          set -e
          node_major="$(node --version 2>/dev/null | cut -d. -f1 | tr -d v || true)"
          if ! [[ "$node_major" =~ ^[0-9]+$ ]] || [ "$node_major" -lt 22 ]; then
            npm install --global node@22
          fi
          node_major="$(node --version | cut -d. -f1 | tr -d v)"
          [ "$node_major" -ge 22 ] || { echo "Node.js 22+ required; found $node_major" >&2; exit 1; }
          npm install --global @anthropic-ai/claude-code
        '; then
          tnx_ok "Claude Code installed with Node.js 22+; run claude to sign in when ready"
        else tnx_warn "Claude Code install failed while provisioning its Node.js 22+ runtime; no credentials were requested or stored."; rc=1; fi
        ;;
      codex)
        if tnx_guest_login --shared-tmp --user "$user_name" -- bash -lc 'npm install -g @openai/codex@latest'; then
          tnx_ok "OpenAI Codex CLI installed; run codex to sign in when ready"
        else tnx_warn "OpenAI Codex CLI installation failed."; rc=1; fi
        ;;
      openai-cli)
        go_version="$(tnx_guest_login --user "$user_name" -- bash -lc 'go version 2>/dev/null | sed -E "s/^go([0-9]+\\.[0-9]+).*/\\1/"' 2>/dev/null || true)"
        if [[ "$go_version" =~ ^[0-9]+\.[0-9]+$ ]] && awk -v v="$go_version" 'BEGIN{split(v,a,"."); exit !((a[1]>1)||(a[1]==1&&a[2]>=26))}' && tnx_guest_login --shared-tmp --user "$user_name" -- bash -lc 'mkdir -p "$HOME/.local/bin"; GOBIN="$HOME/.local/bin" go install github.com/openai/openai-cli/cmd/openai@latest'; then
          tnx_ok "OpenAI API CLI installed; it needs an API key when used"
        else tnx_warn "OpenAI API CLI needs Go 1.26 or newer; install a supported Go toolchain, then run go install github.com/openai/openai-cli/cmd/openai@latest."; rc=1; fi
        ;;
      hermes)
        if tnx_run_pinned_optional_installer "$user_name" \
          https://hermes-agent.nousresearch.com/install.sh \
          abf338605dae6dd28d101673ac6aed7995c955745db46d47676bc591a7957209 \
          --commit 3b421578588243f920886e6fe79a6faa87ea026e --non-interactive; then
          tnx_ok "Hermes Agent v0.23.1 installed from its pinned upstream commit; run hermes setup when ready"
        else tnx_warn "Hermes Agent installer failed verification or installation; see the network error and retry after updating Ternux."; rc=1; fi
        ;;
      evolution)
        if tnx_guest_login --shared-tmp -- bash -c '
          set -e
          entry=/usr/share/applications/org.gnome.Evolution.desktop
          [ -x /usr/bin/evolution ] && [ -x /usr/local/bin/evolution ] && [ -r "$entry" ]
          install -d -m 0755 /usr/local/share/applications
          sed "s#^Exec=evolution#Exec=/usr/local/bin/evolution#" "$entry" > /usr/local/share/applications/org.gnome.Evolution.desktop
          chmod 0644 /usr/local/share/applications/org.gnome.Evolution.desktop
          update-desktop-database /usr/local/share/applications >/dev/null 2>&1 || true
        '; then
          tnx_ok "Evolution Mail installed as an optional app; choose your own mail defaults"
        else tnx_warn "Evolution Mail package installed, but its managed launcher could not be configured."; rc=1; fi
        ;;
      celestia) tnx_ok "Celestia installed as an optional astronomy app" ;;
      openclaw)
        if tnx_run_pinned_optional_installer "$user_name" \
          https://openclaw.ai/install.sh \
          5b46a876404005229ee62fc2615ddeb1c3f510a434ced47dbbed06b93849c704 \
          --version v2026.11.2 --no-onboard --verify; then
          tnx_ok "OpenClaw v2026.11.2 installed from its pinned upstream installer; run openclaw onboard when ready"
        else tnx_warn "OpenClaw installer failed verification or installation; see the network error and retry after updating Ternux."; rc=1; fi
        ;;
      # Backward-compatible grouped flags remain supported for scripts and --all.
      blender) : ;;
      *) tnx_warn "Unknown optional software choice '$opt'; skipping it."; rc=1 ;;
    esac
  done

  # The legacy llama workload compiles from the pinned upstream revision.
  if [[ " $* " == *" llm "* ]]; then
    cores="$(nproc 2>/dev/null || echo 4)"; jobs=$((cores / 2)); (( jobs < 1 )) && jobs=1; (( jobs > 4 )) && jobs=4
    if tnx_guest_login --shared-tmp --user "$user_name" -- bash -c '
      set -e
      src="$HOME/llama.cpp-b11582"; pin=af50f2f248b475d9760f8e67503d01c0f194f5f4
      if [ -e "$src" ]; then [ -d "$src/.git" ] && [ "$(git -C "$src" rev-parse HEAD 2>/dev/null)" = "$pin" ] || { echo "Refusing to modify existing non-pinned source at $src" >&2; exit 1; }
      else git clone --depth 1 --branch b11582 https://github.com/ggml-org/llama.cpp.git "$src"; test "$(git -C "$src" rev-parse HEAD)" = "$pin"; fi
      cd "$src"; cmake -S . -B build -DGGML_VULKAN=ON -DGGML_HEXAGON=OFF -DCMAKE_BUILD_TYPE=Release; cmake --build build --config Release -j"$1"; mkdir -p models
    ' _ "$jobs"; then tnx_ok "llama.cpp built with Vulkan"; else tnx_warn "llama.cpp build failed."; rc=1; fi
  fi
  return "$rc"
}

# ---------------------------------------------------------------------------
# Phase 10 — phantom process killer advisory
# ---------------------------------------------------------------------------
tnx_phase_phantom() {
  local sdk state
  sdk="$(getprop ro.build.version.sdk 2>/dev/null || echo 0)"
  [ "$sdk" -lt 31 ] 2>/dev/null && { tnx_ok "Pre-Android 12 — no phantom-process setting applies."; return 0; }

  state="$(tnx_detect_phantom_killer)"
  case "$state" in
    disabled)
      tnx_ok "Android child-process monitoring is reported as disabled."
      return 0
      ;;
    enabled)
      tnx_warn "Android child-process monitoring is reported as enabled."
      ;;
    *)
      tnx_warn "Could not read Android's child-process setting; do not assume it is enabled or disabled."
      ;;
  esac

  echo ""
  case "$sdk" in
    31) echo "  Android 12 controls can require both global and device_config settings; see troubleshooting." ;;
    32|33) echo "  Android 12L/13: review the documented ADB setting and its system-wide trade-off." ;;
    *) echo "  Android 14+: Developer options may expose 'Disable child process restrictions'." ;;
  esac
  echo "  Signal 9 can also mean memory pressure or OEM battery management."
  echo "  Guide: docs/TROUBLESHOOTING.md#the-desktop-dies-silently"
  echo ""
}

# ---------------------------------------------------------------------------
# Phase 11 — verification
# ---------------------------------------------------------------------------
tnx_phase_verify() {
  local user_name="${1:-ternux}" backend="${2:-auto}"
  local rc=0
  [ "$backend" = auto ] && backend="$(tnx_gpu_backend_auto "$(tnx_distro)")"

  tnx_has_cmd termux-x11  && tnx_ok "termux-x11 found"  || { tnx_fail "termux-x11 missing"; rc=1; }
  tnx_has_cmd proot-distro && tnx_ok "proot-distro found" || { tnx_fail "proot-distro missing"; rc=1; }
  tnx_has_cmd pulseaudio  && tnx_ok "pulseaudio found"  || { tnx_fail "pulseaudio missing"; rc=1; }
  tnx_has_cmd setsid && tnx_ok "setsid found for detached desktop service" || { tnx_fail "setsid missing; install util-linux"; rc=1; }
  [ -x "$HOME/x.sh" ] && tnx_ok "Launcher executable" || { tnx_fail "Launcher missing"; rc=1; }

  local host_cli="${PREFIX:-/data/data/com.termux/files/usr}/bin/ternux"
  local host_version="" guest_version=""
  if [ -x "$host_cli" ]; then
    host_version="$("$host_cli" --version 2>&1)" || true
  fi
  case "$host_version" in
    "ternux v${TERNUX_VERSION}"|"ternux v${TERNUX_VERSION}"$'\n'*) tnx_ok "Termux host CLI loads its installed libraries" ;;
    *) tnx_fail "Termux host CLI is missing, cannot load its libraries, or returned an unexpected version"; rc=1 ;;
  esac

  guest_version="$(tnx_guest_login --user "$user_name" -- bash -lc \
    'command -v ternux >/dev/null && ternux --version' 2>/dev/null)" || true
  case "$guest_version" in
    "ternux guest v${TERNUX_VERSION}"|"ternux guest v${TERNUX_VERSION}"$'\n'*) tnx_ok "Guest/Xfce terminal companion is in PATH and version-verified" ;;
    *) tnx_fail "Guest/Xfce terminal companion is missing, cannot execute, or returned an unexpected version"; rc=1 ;;
  esac

  if tnx_guest_login --user "$user_name" -- bash -c 'command -v startxfce4 && command -v glxinfo && command -v pactl && sudo -n true' >/dev/null 2>&1; then
    tnx_ok "Guest desktop core OK"
  else tnx_fail "Guest desktop core failed"; rc=1; fi

  if [ "$backend" = "zink" ]; then
    if tnx_guest_login -- bash -c '
      overlay="$(cat /etc/ternux/mesa-overlay 2>/dev/null || true)"
      [ -n "$overlay" ] && [ "${overlay#/usr/local/lib/ternux/}" != "$overlay" ] &&
      overlay_libdir="$(cat /etc/ternux/mesa-overlay-libdir 2>/dev/null || true)" &&
      [ "${overlay_libdir#"$overlay"/}" != "$overlay_libdir" ] &&
      [ -f "$overlay_libdir/dri/zink_dri.so" ] &&
      [ -f "$overlay_libdir/libvulkan_freedreno.so" ] &&
      [ -f "$overlay/share/vulkan/icd.d/ternux_freedreno_icd.json" ]
    ' >/dev/null 2>&1; then
      tnx_ok "Managed isolated Mesa Zink/Turnip overlay present"
    elif [ "$(tnx_distro)" != debian ] && tnx_guest_login -- bash -c '
      find /usr -name zink_dri.so -print -quit 2>/dev/null | grep -q . &&
      find /usr -name "libvulkan_freedreno.so*" -print -quit 2>/dev/null | grep -q .
    ' >/dev/null 2>&1; then
      tnx_ok "Native Mesa Zink/Freedreno driver packages present"
    elif tnx_guest_login -- bash -c '
      { [ -f /usr/local/lib/aarch64-linux-gnu/libvulkan_freedreno.so ] &&
        [ -f /usr/local/share/vulkan/icd.d/ternux_freedreno_icd.json ]; } ||
      { [ -f /usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so ] &&
        [ -f /usr/share/vulkan/icd.d/freedreno_icd.aarch64.json ]; }
    ' >/dev/null 2>&1; then
      tnx_ok "Turnip driver present"
    else tnx_fail "Zink checks failed"; rc=1; fi
  else
    tnx_has_cmd virgl_test_server_android && tnx_ok "VirGL present" || { tnx_fail "VirGL missing"; rc=1; }
  fi
  return "$rc"
}

# ---------------------------------------------------------------------------
# Phase 3 — CLI installation
# ---------------------------------------------------------------------------
tnx_phase_cli() {
  local prefix="${PREFIX:-/data/data/com.termux/files/usr}"
  local bin_dir="$prefix/bin" lib_dir="$prefix/lib/ternux"
  local cli_src="" tx_src="" try="" try_tx="" cleanup_dir="" archive="" listing=""
  local root_name="" source_root="" resource_root="" source_lib_dir="" local_lib="" shortcut_src="" shortcut="" shortcut_tmp=""
  local source_commit="${TERNUX_SOURCE_COMMIT:-}" source_sha256="${TERNUX_SOURCE_SHA256:-}"

  # APT owns the packaged CLI files. Keep dpkg's file inventory consistent;
  # package upgrades are handled by the configured APT repository.
  if command -v dpkg-query >/dev/null 2>&1 &&
     [ "$(dpkg-query -W -f='${Status}' ternux 2>/dev/null || true)" = "install ok installed" ]; then
    local managed_version=""
    managed_version="$("$bin_dir/ternux" --version 2>&1)" || {
      tnx_fail "APT-managed Ternux CLI cannot load its installed libraries. Repair the package with: pkg reinstall ternux"
      return 1
    }
    case "$managed_version" in
      "ternux v${TERNUX_VERSION}"|"ternux v${TERNUX_VERSION}"$'\n'*)
        if [ ! -x "$bin_dir/tx" ] || [ "$("$bin_dir/tx" --version 2>&1)" != "$managed_version" ]; then
          tnx_fail "APT-managed short command is missing or stale. Repair with: pkg reinstall ternux"
          return 1
        fi
        for shortcut in db dbr dbroot ub ubr ubroot alp alpr alproot; do
          if [ ! -x "$bin_dir/$shortcut" ] ||
             ! grep -qx '# TERNUX_GUEST_SHELL_SHORTCUT=1' "$bin_dir/$shortcut" 2>/dev/null; then
            tnx_fail "APT-managed guest shell shortcut '$shortcut' is missing or stale. Repair with: pkg reinstall ternux"
            return 1
          fi
        done
        tnx_ok "APT-managed Ternux CLI and tx command are installed and version-verified: ${TERNUX_VERSION}"
        return 0 ;;
      *)
        tnx_fail "APT-managed CLI version mismatch (${managed_version}). Upgrade or reinstall with: pkg upgrade ternux"
        return 1 ;;
    esac
  fi

  if [ -n "${_TNX_SRC:-}" ] && [ -f "$_TNX_SRC/bin/ternux" ]; then
    cli_src="$_TNX_SRC/bin/ternux"
  else
    for try in "$(dirname "${BASH_SOURCE[0]}")/../bin/ternux" \
                "$(dirname "$0")/bin/ternux"; do
      [ -f "$try" ] && { cli_src="$try"; break; }
    done
  fi

  if [ -n "${_TNX_SRC:-}" ] && [ -f "$_TNX_SRC/bin/tx" ]; then
    tx_src="$_TNX_SRC/bin/tx"
  else
    for try_tx in "$(dirname "${BASH_SOURCE[0]}")/../bin/tx" \
                  "$(dirname "$0")/bin/tx"; do
      [ -f "$try_tx" ] && { tx_src="$try_tx"; break; }
    done
  fi
  # A normal one-click run reaches this branch with the already-extracted
  # bootstrap snapshot beside phases.sh, so phase 3 performs no network work.
  # If the module is invoked without that snapshot, fetch one retryable archive
  # rather than 18 independent raw-GitHub files.
  if [ -z "$cli_src" ]; then
    cleanup_dir="${TMPDIR:-/tmp}/ternux-cli-install.$$"
    archive="$cleanup_dir/ternux.tar.gz"
    listing="$cleanup_dir/archive.list"
    mkdir -p "$cleanup_dir" || return 1
    if [[ ! "$source_commit" =~ ^[a-f0-9]{40}$ || ! "$source_sha256" =~ ^[a-f0-9]{64}$ ]]; then
      tnx_fail "Pinned CLI source identity is missing or invalid."
      rm -rf "$cleanup_dir"
      return 1
    fi
    tnx_has_cmd sha256sum || {
      tnx_fail "sha256sum is required to verify the CLI source bundle."
      rm -rf "$cleanup_dir"
      return 1
    }
    tnx_info "Downloading pinned ternux CLI source bundle ($source_commit)..."
    if ! tnx_download \
      "https://codeload.github.com/soobujmiah/ternux/tar.gz/$source_commit" \
      "$archive"; then
      tnx_fail "CLI source bundle download failed after retries."
      rm -rf "$cleanup_dir"
      return 1
    fi
    if ! printf "%s  %s\n" "$source_sha256" "$archive" | sha256sum --check --status; then
      tnx_fail "Downloaded CLI source bundle failed its pinned SHA-256 check."
      rm -rf "$cleanup_dir"
      return 1
    fi
    if ! tar -tzf "$archive" > "$listing" 2>/dev/null ||
       grep -qE '^/|(^|/)\.\.(/|$)' "$listing"; then
      tnx_fail "Downloaded CLI source bundle is invalid or unsafe."
      rm -rf "$cleanup_dir"
      return 1
    fi
    root_name="$(sed -n '1{s#/.*##;p;}' "$listing")"
    case "$root_name" in ternux-*) ;; *) root_name="" ;; esac
    if [ -z "$root_name" ] || grep -qv "^${root_name}/" "$listing" ||
       ! tar -xzf "$archive" -C "$cleanup_dir"; then
      tnx_fail "Could not validate or unpack the CLI source bundle."
      rm -rf "$cleanup_dir"
      return 1
    fi
    source_root="$cleanup_dir/$root_name"
    cli_src="$source_root/bin/ternux"
    tx_src="$source_root/bin/tx"
    # Older pinned source snapshots predate the tx entry point. Keep the
    # archive immutable and synthesize the tiny dispatcher beside it so the
    # same verified ternux CLI can still be installed under the short command.
    if [ ! -f "$tx_src" ] && [ -f "$cli_src" ]; then
      tx_src="$cleanup_dir/tx"
      cat > "$tx_src" <<'TX_WRAPPER'
#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
exec bash "$script_dir/ternux" "$@"
TX_WRAPPER
      chmod 0755 "$tx_src" || {
        tnx_fail "Could not create the short Ternux command wrapper."
        rm -rf "$cleanup_dir"
        return 1
      }
    fi
  fi

  shortcut_src="$(dirname -- "$cli_src")/ternux-shell-shortcut"
  if [ ! -s "$shortcut_src" ]; then
    tnx_fail "Guest shell command helper is missing from the verified CLI source snapshot."
    [ -n "$cleanup_dir" ] && rm -rf "$cleanup_dir"
    return 1
  fi

  source_lib_dir="$(dirname "$cli_src")/../lib"
  resource_root="$(cd "$source_lib_dir" 2>/dev/null && pwd -P)"
  local source_libs=("$source_lib_dir/"*.sh)
  mkdir -p "$bin_dir" "$lib_dir" || {
    tnx_fail "Could not create the host CLI directories."
    [ -n "$cleanup_dir" ] && rm -rf "$cleanup_dir"
    return 1
  }
  if [ ! -f "$cli_src" ] || [ ! -f "$tx_src" ] || [ ! -e "${source_libs[0]}" ] ||
     ! bash -n "$cli_src" 2>/dev/null || ! bash -n "$tx_src" 2>/dev/null; then
    tnx_fail "CLI source snapshot is incomplete or failed shell syntax validation."
    [ -n "$cleanup_dir" ] && rm -rf "$cleanup_dir"
    return 1
  fi
  for local_lib in "${source_libs[@]}"; do
    if ! bash -n "$local_lib" 2>/dev/null; then
      tnx_fail "CLI library failed shell syntax validation: $(basename "$local_lib")"
      [ -n "$cleanup_dir" ] && rm -rf "$cleanup_dir"
      return 1
    fi
  done
  for local_lib in "${source_libs[@]}"; do
    if ! install -m 644 "$local_lib" "$lib_dir/$(basename "$local_lib")" 2>/dev/null; then
      tnx_fail "Could not install CLI library: $(basename "$local_lib")"
      [ -n "$cleanup_dir" ] && rm -rf "$cleanup_dir"
      return 1
    fi
  done
  # The guest phase consumes these immutable source resources after the CLI
  # has been installed. Keep them beside the host modules so `tx install`
  # works the same way as the standalone bootstrap, whose source tree is
  # available for the whole run.
  for local_lib in ternux-welcome.sh ternux-welcome-gui.py ternux-window-fit.lua \
                   ternux-camera.py ternux-recorder.py ternux-panel-shortcuts.sh \
                   ternux-install-firefox-esr.sh; do
    if [ -s "$resource_root/$local_lib" ]; then
      install -m 0644 "$resource_root/$local_lib" "$lib_dir/$local_lib" || {
        tnx_fail "Could not install required desktop resource: $local_lib"
        [ -n "$cleanup_dir" ] && rm -rf "$cleanup_dir"
        return 1
      }
    fi
  done
  if [ -d "$resource_root/ternux-assets" ]; then
    mkdir -p "$lib_dir/ternux-assets" &&
      cp -a "$resource_root/ternux-assets/." "$lib_dir/ternux-assets/" || {
        tnx_fail "Could not install required Ternux branding assets."
        [ -n "$cleanup_dir" ] && rm -rf "$cleanup_dir"
        return 1
      }
  fi
  if [ -d "$resource_root/licenses" ]; then
    mkdir -p "$lib_dir/licenses" &&
      cp -a "$resource_root/licenses/." "$lib_dir/licenses/" || {
        tnx_fail "Could not install pinned upstream license notices."
        [ -n "$cleanup_dir" ] && rm -rf "$cleanup_dir"
        return 1
      }
  fi
  if ! install -m 755 "$cli_src" "$bin_dir/ternux" 2>/dev/null; then
    tnx_fail "Could not install the host CLI."
    [ -n "$cleanup_dir" ] && rm -rf "$cleanup_dir"
    return 1
  fi
  if ! install -m 755 "$tx_src" "$bin_dir/tx" 2>/dev/null; then
    tnx_fail "Could not install the short Ternux command."
    [ -n "$cleanup_dir" ] && rm -rf "$cleanup_dir"
    return 1
  fi
  if [ -s "$shortcut_src" ]; then
    for shortcut in db dbr dbroot ub ubr ubroot alp alpr alproot; do
      if [ -e "$bin_dir/$shortcut" ] || [ -L "$bin_dir/$shortcut" ]; then
        if [ -L "$bin_dir/$shortcut" ] || [ ! -f "$bin_dir/$shortcut" ] ||
           ! grep -qx '# TERNUX_GUEST_SHELL_SHORTCUT=1' "$bin_dir/$shortcut"; then
          tnx_warn "Preserving the existing command at $bin_dir/$shortcut; use the shell shortcut from a newly opened Termux shell."
          continue
        fi
      fi
      shortcut_tmp="$(umask 077; mktemp "$bin_dir/.ternux-shell-shortcut.XXXXXX")" || {
        tnx_fail "Could not stage guest shell shortcut '$shortcut'."
        return 1
      }
      if ! install -m 755 "$shortcut_src" "$shortcut_tmp" || ! mv -f -- "$shortcut_tmp" "$bin_dir/$shortcut"; then
        rm -f -- "$shortcut_tmp"
        tnx_fail "Could not install guest shell shortcut '$shortcut'."
        return 1
      fi
    done
  fi
  [ -n "$cleanup_dir" ] && rm -rf "$cleanup_dir"

  # File existence is not enough: execute the exact installed path so the
  # dispatcher must discover and load the installed flat module directory.
  local installed_version=""
  if [ -x "$bin_dir/ternux" ]; then
    installed_version="$("$bin_dir/ternux" --version 2>&1)" || {
      tnx_fail "Installed CLI cannot load its libraries: ${installed_version:-unknown error}"
      return 1
    }
  else
    tnx_fail "CLI installation failed: $bin_dir/ternux is not executable."
    return 1
  fi

  case "$installed_version" in
    "ternux v${TERNUX_VERSION}"|"ternux v${TERNUX_VERSION}"$'\n'*) ;;
    *)
      tnx_fail "Installed CLI returned an unexpected version response: $installed_version"
      return 1
      ;;
  esac
  local tx_version=""
  tx_version="$("$bin_dir/tx" --version 2>&1)" || {
    tnx_fail "Installed tx command cannot load its Ternux CLI: ${tx_version:-unknown error}"
    return 1
  }
  [ "$tx_version" = "$installed_version" ] || {
    tnx_fail "Installed tx command returned an unexpected version response: $tx_version"
    return 1
  }
  tnx_ok "Termux host CLI loaded its installed libraries: $bin_dir/ternux"
  tnx_state_set "cli_installed" "yes"
  return 0
}

# Run one phase through a single call site so its complete stdout/stderr stream
# can be framed and logged without putting the phase itself in charge of UI.
_tnx_execute_install_phase() {
  local phase="$1" user_name="$2" backend="$3" locale="$4" shell_choice="$5"
  shift 5
  local phase_extras=("$@")
  case "$phase" in
    preflight)   tnx_phase_preflight ;;
    packages)    tnx_phase_packages "$backend" ;;
    cli)         tnx_phase_cli ;;
    debian)      tnx_phase_debian "$user_name" ;;
    gpu)         tnx_phase_gpu "$backend" ;;
    audio_fonts) tnx_phase_audio_fonts "$user_name" "$locale" ;;
    launcher)    tnx_phase_launcher "$user_name" "$backend" "$locale" ;;
    aliases)     tnx_phase_aliases "$user_name" "$shell_choice" ;;
    extras)
      if [ ${#phase_extras[@]} -gt 0 ]; then
        tnx_phase_extras "$user_name" "${phase_extras[@]}"
      else
        tnx_info "No optional profiles."
      fi
      ;;
    phantom)     tnx_phase_phantom ;;
    verify)      tnx_phase_verify "$user_name" "$backend" ;;
    *)           tnx_fail "Unknown installation phase: $phase"; return 2 ;;
  esac
}

# Prompt for the guest distribution when neither a flag nor saved state chose
# one. Same tty/deadline/default handling as the other prompts. The prompt names
# which profiles have device qualification, rather than implying every recipe does.
_TNX_SELECTED_DISTROS=()

_tnx_profile_toggle() {
  local distro="$1" i
  for i in "${!_TNX_SELECTED_DISTROS[@]}"; do
    if [ "${_TNX_SELECTED_DISTROS[$i]}" = "$distro" ]; then
      unset '_TNX_SELECTED_DISTROS[i]'
      _TNX_SELECTED_DISTROS=("${_TNX_SELECTED_DISTROS[@]}")
      return 0
    fi
  done
  _TNX_SELECTED_DISTROS+=("$distro")
}

_tnx_profile_menu_draw() {
  local cursor="$1" size="${2:-}" rows cols visible first last i distro family mark pointer color selected_count=0 info controls1 controls2 line summary_rows=0
  local -a profiles=() summary_lines=()
  read -r -a profiles <<< "$TERNUX_DISTRO_KNOWN"
  [ -n "$size" ] || size="$(stty size <&3 2>/dev/null || true)"
  read -r rows cols <<< "$size"
  [[ "$rows" =~ ^[0-9]+$ ]] || rows=24
  [[ "$cols" =~ ^[0-9]+$ ]] || cols=80
  (( cols > 200 )) && cols=200
  (( cols < 24 )) && cols=24
  selected_count=${#_TNX_SELECTED_DISTROS[@]}
  line='Selected:'
  for distro in "${_TNX_SELECTED_DISTROS[@]}"; do
    local separator=' '
    [ "$line" = 'Selected:' ] || separator=', '
    if [ "$line" != 'Selected:' ] && (( ${#line} + ${#separator} + ${#distro} > cols - 2 )); then
      summary_lines+=("$line"); line='         '; separator=''
    fi
    line+="$separator$distro"
  done
  summary_lines+=("$line"); summary_rows=${#summary_lines[@]}
  visible=$((rows - 10 - summary_rows)); (( visible < 1 )) && visible=1
  (( visible > 15 )) && visible=15
  (( visible > ${#profiles[@]} )) && visible=${#profiles[@]}
  first=0; (( cursor >= visible )) && first=$((cursor - visible + 1))
  last=$((first + visible)); (( last > ${#profiles[@]} )) && last=${#profiles[@]}

  printf '\033[?25l\033[r\033[H\033[2J%s+%s+%s\n' "$TNX_CM" "$(printf '%*s' "$((cols - 2))" '' | tr ' ' '=')" "$TNX_C0" >&2
  printf '%s%s%s\n' "$TNX_CG" "TERNUX DESKTOP PROFILES" "$TNX_C0" >&2
  printf '%s%s%s\n' "$TNX_CC" "${selected_count} selected  |  ${#profiles[@]} recipes" "$TNX_C0" >&2
  info='* selected | + v2-qualified | remaining recipes unverified'
  printf '%s%s%s\n' "$TNX_CD" "${info:0:cols-2}" "$TNX_C0" >&2
  for line in "${summary_lines[@]}"; do printf '%s%s%s\n' "$TNX_CG" "${line:0:cols-2}" "$TNX_C0" >&2; done
  printf '\n' >&2
  for ((i=first; i<last; i++)); do
    distro="${profiles[$i]}"
    tnx_distro_profile "$distro"; family="${TNX_DP_FAMILY^^}"
    mark='o'; color="$TNX_CD"
    [[ " ${_TNX_SELECTED_DISTROS[*]} " == *" $distro "* ]] && { mark='*'; color="$TNX_CG"; }
    pointer=' '; [ "$i" = "$cursor" ] && { pointer='>'; color="$TNX_CY"; }
    tnx_distro_verified "$distro" && family+='+'
    printf '%s%s%s %s%s%s %02d %-12.12s %s\n' \
      "$color" "$pointer" "$TNX_C0" "$color" "$mark" "$TNX_C0" "$((i + 1))" "$distro" "$family" >&2
  done
  if (( first > 0 || last < ${#profiles[@]} )); then
    printf '%sShowing %d-%d of %d%s\n' "$TNX_CD" "$((first + 1))" "$last" "${#profiles[@]}" "$TNX_C0" >&2
  fi
  if (( cols >= 44 )); then
    controls1='UP/DOWN or J/K move | SPACE/number toggle'
    controls2='ENTER continue | Q keeps default'
  else
    controls1='J/K move | Space toggle'
    controls2='Enter select | Q default'
  fi
  printf '\n%s%s%s\n%s%s%s\n' "$TNX_CY" "${controls1:0:cols-2}" "$TNX_C0" "$TNX_CY" "${controls2:0:cols-2}" "$TNX_C0" >&2
  printf '%s+%s+%s\n' "$TNX_CM" "$(printf '%*s' "$((cols - 2))" '' | tr ' ' '=')" "$TNX_C0" >&2
}

tnx_prompt_distro() {
  local default_distro="${1:-debian}" timeout="${2:-20}" tty_fd="" cursor=0 key seq number idx next pending_key="" old_stty="" menu_size="" size="" read_status
  local -a profiles=()
  read -r -a profiles <<< "$TERNUX_DISTRO_KNOWN"
  _TNX_SELECTED_DISTROS=("$default_distro")
  for idx in "${!profiles[@]}"; do [ "${profiles[$idx]}" = "$default_distro" ] && cursor=$idx; done

  if { exec 3<>/dev/tty; } 2>/dev/null; then tty_fd=3
  elif [ -t 0 ]; then tty_fd=0
  else printf '%s\n' "$default_distro"; return 0
  fi

  if [ "$tty_fd" = 3 ] && [ -t 3 ] && [ "${TERM:-}" != dumb ]; then
    old_stty="$(stty -g <&3 2>/dev/null || true)"
    menu_size="$(stty size <&3 2>/dev/null || true)"
    local menu_rows=0 menu_cols=0
    read -r menu_rows menu_cols <<< "$menu_size" || true
    [[ "$menu_rows" =~ ^[0-9]+$ && "$menu_cols" =~ ^[0-9]+$ ]] || old_stty=""
    (( ${menu_rows:-0} >= 14 && ${menu_cols:-0} >= 32 )) || old_stty=""
  fi
  if [ -n "$old_stty" ]; then
    menu_size="$(stty size <&3 2>/dev/null || true)"
    _tnx_profile_menu_draw "$cursor" "$menu_size"
    if ! stty -echo -icanon min 1 time 0 <&3 2>/dev/null; then
      stty "$old_stty" <&3 2>/dev/null || true
      old_stty=""
      printf '\033[?25h\033[H\033[2J' >&2
    fi
  fi
  if [ -n "$old_stty" ]; then
    trap 'stty "$old_stty" <&3 2>/dev/null || true; printf "\\033[?25h" >&2; exit 130' INT
    trap 'stty "$old_stty" <&3 2>/dev/null || true; printf "\\033[?25h" >&2; exit 143' TERM
    while :; do
      if [ -n "$pending_key" ]; then key="$pending_key"; pending_key=""
      elif IFS= read -r -s -n 1 -t 0.5 -u 3 key; then :
      else
        read_status=$?
        if (( read_status > 128 )); then
          size="$(stty size <&3 2>/dev/null || true)"
          if [ "$size" != "$menu_size" ]; then menu_size="$size"; _tnx_profile_menu_draw "$cursor" "$menu_size"; fi
          continue
        fi
        break
      fi
      case "$key" in
        $'\033') IFS= read -r -s -n 2 -t 1 -u 3 seq || seq=""; case "$seq" in '[A') (( cursor > 0 )) && cursor=$((cursor - 1)) ;; '[B') (( cursor + 1 < ${#profiles[@]} )) && cursor=$((cursor + 1)) ;; esac ;;
        k) (( cursor > 0 )) && cursor=$((cursor - 1)) ;;
        j) (( cursor + 1 < ${#profiles[@]} )) && cursor=$((cursor + 1)) ;;
        ' ') _tnx_profile_toggle "${profiles[$cursor]}" ;;
        [0-9])
          number="$key"
          while :; do
            next=""
            if IFS= read -r -s -n 1 -t 0.18 -u 3 next; then
              if [[ "$next" =~ ^[0-9]$ ]]; then number+="$next"
              else pending_key="${next:-$'\r'}"; break
              fi
            else break
            fi
          done
          number=$((10#$number)); idx=$((number - 1))
          (( idx >= 0 && idx < ${#profiles[@]} )) && _tnx_profile_toggle "${profiles[$idx]}"
          ;;
        ''|$'\r'|$'\n') break ;;
        q|Q) _TNX_SELECTED_DISTROS=("$default_distro"); break ;;
      esac
      size="$(stty size <&3 2>/dev/null || true)"
      [ -n "$size" ] && menu_size="$size"
      _tnx_profile_menu_draw "$cursor" "$menu_size"
    done
    [ -n "$old_stty" ] && stty "$old_stty" <&3 2>/dev/null || true
    trap - INT TERM
    printf '\033[?25h\033[H\033[2J' >&2
  else
    printf '\n%sGuest profiles%s (desktop recipes by package-manager family)\n' "$TNX_CW" "$TNX_C0" >&2
    for idx in "${!profiles[@]}"; do printf '  %2d) %s\n' "$((idx + 1))" "${profiles[$idx]}" >&2; done
    while :; do
      printf 'Choose numbers or names separated by commas [default: %s; q keeps default]: ' "$default_distro" >&2
      if ! IFS= read -r -u "$tty_fd" input; then break; fi
      [ -n "$input" ] || break
      case "${input,,}" in q) _TNX_SELECTED_DISTROS=("$default_distro"); break ;; esac
      local -a choices=() picked=()
      local bad=0 item seen=" "
      IFS=',' read -r -a choices <<< "$input"
      for item in "${choices[@]}"; do
        item="$(printf '%s' "$item" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')"
        if [[ "$item" =~ ^[0-9]+$ ]]; then
          item=$((10#$item)); (( item >= 1 && item <= ${#profiles[@]} )) || { bad=1; break; }
          item="${profiles[item-1]}"
        fi
        tnx_distro_known "$item" || { bad=1; break; }
        case "$seen" in *" $item "*) bad=1; break ;; esac
        seen+="$item "; picked+=("$item")
      done
      if [ "$bad" -eq 0 ] && [ "${#picked[@]}" -gt 0 ]; then _TNX_SELECTED_DISTROS=("${picked[@]}"); break; fi
      printf '%s[WARN]%s Select listed numbers or names; duplicate entries are not allowed.\n' "$TNX_CY" "$TNX_C0" >&2
    done
    [ "$tty_fd" = 3 ] && exec 3>&-
  fi
  local result="" distro
  for distro in "${_TNX_SELECTED_DISTROS[@]}"; do result+="${result:+,}$distro"; done
  printf '%s\n' "${result:-$default_distro}"
}

# Prompt for the Termux host shell when neither a flag nor saved state chose
# one. Mirrors tnx_prompt_username: a real tty, a deadline, and the default on
# timeout, empty input or a non-interactive run.
tnx_prompt_shell() {
  local default_shell="${1:-bash}"
  local timeout="${2:-20}"
  local tty_fd="" input=""

  if { exec 3<>/dev/tty; } 2>/dev/null; then
    tty_fd=3
  elif [ -t 0 ]; then
    tty_fd=0
  fi

  if [ -z "$tty_fd" ]; then
    printf '%s\n' "$default_shell"
    return 0
  fi

  printf "${TNX_CC}?${TNX_C0} Termux shell — bash or zsh? [default: %s] (${timeout}s): " "$default_shell" >&2
  if ! IFS= read -r -t "$timeout" -u "$tty_fd" input; then
    printf "\n${TNX_CY}[INFO]${TNX_C0} Shell prompt timed out; using '%s'.\n" "$default_shell" >&2
    printf '%s\n' "$default_shell"
    return 0
  fi

  input="$(printf '%s' "$input" | tr -d '\r\n' | tr '[:upper:]' '[:lower:]')"
  case "$input" in
    bash|zsh) printf '%s\n' "$input" ;;
    "")       printf '%s\n' "$default_shell" ;;
    *)        printf "${TNX_CY}[INFO]${TNX_C0} '%s' is not bash or zsh; using '%s'.\n" "$input" "$default_shell" >&2
              printf '%s\n' "$default_shell" ;;
  esac
}

# Prompt for a Debian username when none was explicitly supplied.
# Falls back to 'ternux' if the prompt times out, input is empty, input is
# invalid and not corrected before the deadline, or if running non-interactively.
tnx_prompt_username() {
  local default_user="${1:-ternux}"
  local timeout="${2:-30}"
  local guest_label="${3:-}"
  local tty_fd=""
  local chosen=""
  local start_time=0 now=0 elapsed=0 remaining=0

  if { exec 3<>/dev/tty; } 2>/dev/null; then
    tty_fd=3
  elif [ -t 0 ]; then
    tty_fd=0
  fi

  if [ -z "$tty_fd" ]; then
    printf '%s\n' "$default_user"
    return 0
  fi

  start_time=$SECONDS

  while true; do
    now=$SECONDS
    elapsed=$(( now - start_time ))
    remaining=$(( timeout - elapsed ))
    if [ "$remaining" -le 0 ]; then
      printf "\n${TNX_CY}[INFO]${TNX_C0} Username prompt timed out (${timeout}s); using default '%s'.\n" "$default_user" >&2
      chosen="$default_user"
      break
    fi

    if [ -n "$guest_label" ]; then
      printf "${TNX_CC}?${TNX_C0} Username for %s [default: %s] (${remaining}s remaining): " "$guest_label" "$default_user" >&2
    else
      printf "${TNX_CC}?${TNX_C0} Enter your TERNUX username [default: %s] (${remaining}s remaining): " "$default_user" >&2
    fi

    local input=""
    if ! IFS= read -r -t "$remaining" -u "$tty_fd" input; then
      printf "\n${TNX_CY}[INFO]${TNX_C0} Username prompt timed out (${timeout}s); using default '%s'.\n" "$default_user" >&2
      chosen="$default_user"
      break
    fi

    input="$(printf '%s' "$input" | tr -d '\r\n')"
    if [ -z "$input" ]; then
      chosen="$default_user"
      break
    fi

    if [[ "$input" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]; then
      chosen="$input"
      break
    fi

    printf "${TNX_CR}[WARN]${TNX_C0} Invalid username '%s'. Username must start with a-z or _, contain only a-z, 0-9, _, - and be at most 32 characters.\n" "$input" >&2
  done

  [ "$tty_fd" = "3" ] && exec 3>&-

  printf '%s\n' "$chosen"
}

# Item catalogue for the interactive optional-software checklist. Keep this
# list aligned with the case labels in tnx_phase_extras.
TNX_OPTIONAL_ITEMS=(git python node build rust java golang php ripgrep jq gh sqlite3 htop tree geany neovim micro thonny godot adt-build-tools adt-platform-tools adt-ndk adt-cmake adt-cmdline adt-platform llama-vulkan stable-diffusion llama-htp-experimental nmap tmux ffmpeg vlc mpv audacity gimp krita inkscape imagemagick libreoffice-writer libreoffice-calc libreoffice-draw evolution blender celestia claude codex openai-cli hermes openclaw)
TNX_OPTIONAL_GROUPS=(DEV DEV DEV DEV LANG LANG LANG LANG DEV DEV DEV DATA SYSTEM SYSTEM IDE IDE IDE IDE GAME ANDROID ANDROID ANDROID ANDROID ANDROID ANDROID AI AI AI NET NET MEDIA MEDIA MEDIA MEDIA DESIGN DESIGN DESIGN DESIGN OFFICE OFFICE OFFICE OFFICE 3D 3D AGENT AGENT AGENT AGENT AGENT)
TNX_OPTIONAL_LABELS=("Git" "Python" "Node.js" "C/C++ tools" "Rust" "Java JDK" "Go toolchain" "PHP CLI" "ripgrep" "jq" "GitHub CLI" "SQLite" "htop" "tree" "Geany" "Neovim" "Micro editor" "Thonny IDE" "Godot" "ADT Build Tools" "ADT Platform Tools / ADB" "ADT NDK" "ADT CMake" "SDK Manager" "Android API 36" "llama.cpp Vulkan" "Stable Diffusion CPU + Vulkan" "llama.cpp HTP (experimental)" "Nmap" "tmux" "FFmpeg" "VLC" "mpv" "Audacity" "GIMP" "Krita" "Inkscape" "ImageMagick" "LibreOffice Writer" "LibreOffice Calc" "LibreOffice Draw" "Evolution Mail" "Blender" "Celestia astronomy simulator" "Claude Code" "Codex CLI" "OpenAI API CLI" "Hermes" "OpenClaw")

# Parse number lists used when a TTY key-reading menu is unavailable.
tnx_parse_workload_selection() {
  local input="$1" item idx seen="" out=""
  input="${input//,/ }"
  local -a choices=()
  read -r -a choices <<< "$input"
  for item in "${choices[@]}"; do
    [[ "$item" =~ ^[0-9]+$ ]] || return 2
    (( item >= 1 && item <= ${#TNX_OPTIONAL_ITEMS[@]} )) || return 2
    idx=$((item - 1))
    case " $seen " in *" ${TNX_OPTIONAL_ITEMS[$idx]} "*) continue ;; esac
    seen+=" ${TNX_OPTIONAL_ITEMS[$idx]}"
    out+="${out:+,}${TNX_OPTIONAL_ITEMS[$idx]}"
  done
  printf '%s\n' "$out"
}

_tnx_optional_menu_draw() {
  local cursor="$1" selected_name i mark mark_color pointer pointer_color color size="${2:-}" rows cols visible first last count
  local group group_color label label_width hint controls title="TERNUX OPTIONAL SOFTWARE" status word remaining line maxw selected_lines item
  local -a chosen_labels=() summary_lines=()
  [ -n "$size" ] || size="$(stty size <&3 2>/dev/null || true)"
  read -r rows cols <<< "$size"
  [[ "$rows" =~ ^[0-9]+$ ]] || rows=24; [[ "$cols" =~ ^[0-9]+$ ]] || cols=80
  (( cols > 200 )) && cols=200; (( cols < 20 )) && cols=20
  count=${#_TNX_SELECTED_ITEMS[@]}
  selected_name=" ${_TNX_SELECTED_ITEMS[*]} "
  for item in "${_TNX_SELECTED_ITEMS[@]}"; do
    for i in "${!TNX_OPTIONAL_ITEMS[@]}"; do
      if [ "$item" = "${TNX_OPTIONAL_ITEMS[$i]}" ]; then chosen_labels+=("${TNX_OPTIONAL_LABELS[$i]}"); break; fi
    done
  done
  maxw=$((cols - 2)); (( maxw < 12 )) && maxw=12
  line='Selected: '
  if (( ${#chosen_labels[@]} == 0 )); then line='Selected: none yet'
  else
    for word in "${chosen_labels[@]}"; do
      if (( ${#line} + ${#word} + 2 > maxw )) && [ "$line" != 'Selected: ' ]; then
        summary_lines+=("${line},"); line="$word"
      else
        [ "$line" = 'Selected: ' ] || line+=', '
        line+="$word"
      fi
    done
  fi
  summary_lines+=("$line"); selected_lines=${#summary_lines[@]}
  visible=$((rows - 9 - selected_lines)); (( visible < 1 )) && visible=1
  (( visible > 12 )) && visible=12
  (( visible > ${#TNX_OPTIONAL_ITEMS[@]} )) && visible=${#TNX_OPTIONAL_ITEMS[@]}
  first=0; (( cursor >= visible )) && first=$((cursor - visible + 1))
  last=$((first + visible)); (( last > ${#TNX_OPTIONAL_ITEMS[@]} )) && last=${#TNX_OPTIONAL_ITEMS[@]}
  label_width=$((cols - 17)); (( label_width < 1 )) && label_width=1
  # Reset any scroll region left by a prior terminal UI before anchoring the
  # catalog at the top of the viewport.
  printf '\033[?25l\033[r\033[H\033[2J%s+%s+%s\n' "$TNX_CM" "$(printf '%*s' "$((cols - 2))" '' | tr ' ' '=')" "$TNX_C0" >&2
  printf '%s%s%s\n' "$TNX_CG" "${title:0:cols-2}" "$TNX_C0" >&2
  status="OPTIONAL SOFTWARE  |  ${count} selected  |  ${#TNX_OPTIONAL_ITEMS[@]} available"
  printf '%s%s%s\n' "$TNX_CC" "${status:0:cols-2}" "$TNX_C0" >&2
  hint="Debian packages use latest versions from configured repositories."
  printf '%s%s%s\n\n' "$TNX_CD" "${hint:0:cols-2}" "$TNX_C0" >&2
  for ((i=first; i<last; i++)); do
    mark='o'; mark_color="$TNX_CD"
    if [[ "$selected_name" == *" ${TNX_OPTIONAL_ITEMS[$i]} "* ]]; then mark='*'; mark_color="$TNX_CG"; fi
    pointer=' '; pointer_color="$TNX_CD"; color="$TNX_CW"
    if (( i == cursor )); then pointer='>'; pointer_color="$TNX_CY"; color="$TNX_CW"; fi
    group="${TNX_OPTIONAL_GROUPS[$i]}"
    case "$group" in
      ANDROID|WEB|AGENT) group_color="$TNX_CM" ;;
      AI|DESIGN|3D) group_color="$TNX_CY" ;;
      MEDIA|OFFICE) group_color="$TNX_CG" ;;
      *) group_color="$TNX_CC" ;;
    esac
    label="${TNX_OPTIONAL_LABELS[$i]}"; (( ${#label} > label_width )) && label="${label:0:label_width}"
    printf '%s%s%s %s%s%s %s%d%s %s%-7s%s %s%s%s\n' \
      "$pointer_color" "$pointer" "$TNX_C0" "$mark_color" "$mark" "$TNX_C0" "$TNX_CD" "$((i + 1))" "$TNX_C0" \
      "$group_color" "$group" "$TNX_C0" "$color" "$label" "$TNX_C0" >&2
  done
  printf '\n' >&2
  for line in "${summary_lines[@]}"; do printf '%s%s%s\n' "$TNX_CG" "$line" "$TNX_C0" >&2; done
  if (( first > 0 || last < ${#TNX_OPTIONAL_ITEMS[@]} )); then
    printf '%sShowing %d-%d of %d%s\n' "$TNX_CD" "$((first + 1))" "$last" "${#TNX_OPTIONAL_ITEMS[@]}" "$TNX_C0" >&2
  fi
  controls="UP/DOWN or J/K move | SPACE/number toggle | ENTER review | Q base"
  printf '%s%s%s\n' "$TNX_CY" "${controls:0:cols-2}" "$TNX_C0" >&2
  printf '%s+%s+%s\n' "$TNX_CM" "$(printf '%*s' "$((cols - 2))" '' | tr ' ' '=')" "$TNX_C0" >&2
}

_tnx_checklist_toggle() {
  local item="$1" i
  for i in "${!_TNX_SELECTED_ITEMS[@]}"; do
    if [[ "${_TNX_SELECTED_ITEMS[$i]}" == "$item" ]]; then
      unset '_TNX_SELECTED_ITEMS[i]'
      _TNX_SELECTED_ITEMS=("${_TNX_SELECTED_ITEMS[@]}")
      return 0
    fi
  done
  _TNX_SELECTED_ITEMS+=("$item")
}

# Interactive selector supports arrow keys (or j/k), Space, number toggles and
# Enter. When no controlling TTY exists, retain a simple number-list fallback.
tnx_prompt_workloads() {
  local backend="${1:-virgl}" tty_fd="" input="" cursor=0 key seq idx number next pending_key=""
  _TNX_SELECTED_ITEMS=()
  if { exec 3<>/dev/tty; } 2>/dev/null; then tty_fd=3
  elif [ -t 0 ]; then tty_fd=0
  else printf '\n'; return 0; fi

  if [ "$tty_fd" = 3 ] && [ -t 3 ]; then
  local old_stty menu_size read_status size
    old_stty="$(stty -g <&3 2>/dev/null || true)"
    tnx_detect_ram_gb >/dev/null 2>&1 || true
    printf '%sDetected route:%s %s  |  %sRAM/storage suggestions are advisory only.%s\n' "$TNX_CC" "$TNX_C0" "$backend" "$TNX_CD" "$TNX_C0" >&2
    menu_size="$(stty size <&3 2>/dev/null || true)"
    _tnx_optional_menu_draw "$cursor" "$menu_size"
    stty -echo -icanon min 1 time 0 <&3 2>/dev/null || true
    trap 'stty "$old_stty" <&3 2>/dev/null || true; exit 130' INT
    trap 'stty "$old_stty" <&3 2>/dev/null || true; exit 143' TERM
    while true; do
      if [ -n "$pending_key" ]; then key="$pending_key"; pending_key=""
      elif IFS= read -r -s -n 1 -t 0.5 -u 3 key; then :
      else
        read_status=$?
        if (( read_status > 128 )); then
          size="$(stty size <&3 2>/dev/null || true)"
          if [ "$size" != "$menu_size" ]; then
            menu_size="$size"
            _tnx_optional_menu_draw "$cursor" "$menu_size"
          fi
          continue
        fi
        break
      fi
      case "$key" in
        $'\033') IFS= read -r -s -n 2 -t 1 -u 3 seq || seq=""; case "$seq" in '[A') (( cursor > 0 )) && cursor=$((cursor - 1)) ;; '[B') (( cursor + 1 < ${#TNX_OPTIONAL_ITEMS[@]} )) && cursor=$((cursor + 1)) ;; esac ;;
        k) (( cursor > 0 )) && cursor=$((cursor - 1)) ;;
        j) (( cursor + 1 < ${#TNX_OPTIONAL_ITEMS[@]} )) && cursor=$((cursor + 1)) ;;
        ' ') _tnx_checklist_toggle "${TNX_OPTIONAL_ITEMS[$cursor]}" ;;
        [0-9])
          number="$key"
          while :; do
            next=""
            if IFS= read -r -s -n 1 -t 0.18 -u 3 next; then
              if [[ "$next" =~ ^[0-9]$ ]]; then number+="$next"
              else pending_key="${next:-$'\r'}"; break
              fi
            else break
            fi
          done
          idx=$((10#$number - 1))
          (( idx >= 0 && idx < ${#TNX_OPTIONAL_ITEMS[@]} )) && _tnx_checklist_toggle "${TNX_OPTIONAL_ITEMS[$idx]}"
          ;;
        ''|$'\r'|$'\n') break ;;
        q|Q) _TNX_SELECTED_ITEMS=(); break ;;
      esac
      size="$(stty size <&3 2>/dev/null || true)"
      [ -n "$size" ] && menu_size="$size"
      _tnx_optional_menu_draw "$cursor" "$menu_size"
    done
    [ -n "$old_stty" ] && stty "$old_stty" <&3 2>/dev/null || true
    trap - INT TERM
    printf '\033[?25h\033[H\033[2J' >&2
  else
    printf '\n%sOptional software%s (choose numbers separated by spaces or commas)\n' "$TNX_CW" "$TNX_C0" >&2
    for idx in "${!TNX_OPTIONAL_ITEMS[@]}"; do printf '  %2d) %s\n' "$((idx + 1))" "${TNX_OPTIONAL_LABELS[$idx]}" >&2; done
    while true; do
      printf 'Choose items [default: none]: ' >&2
      if ! IFS= read -r -u "$tty_fd" input; then break; fi
      if input="$(tnx_parse_workload_selection "$input")"; then
        IFS=',' read -r -a _TNX_SELECTED_ITEMS <<< "$input"
        [[ -z "$input" ]] && _TNX_SELECTED_ITEMS=()
        break
      fi
      printf '%s[WARN]%s Enter valid item numbers, e.g. 1 3 14.\n' "$TNX_CY" "$TNX_C0" >&2
    done
  fi
  [ "$tty_fd" = 3 ] && exec 3>&-
  local result=""
  for key in "${_TNX_SELECTED_ITEMS[@]}"; do result+="${result:+,}$key"; done
  printf '%s\n' "$result"
}

# ---------------------------------------------------------------------------
# Full installation orchestrator
# ---------------------------------------------------------------------------
tnx_install_auto_resume_distro() {
  local requested="${1:-}" explicit="${2:-0}" saved status
  saved="$(tnx_state_get distro 2>/dev/null || true)"
  [ -n "$saved" ] || return 1
  status="$(tnx_distro_state_get "$saved" status 2>/dev/null || true)"
  case "$status" in incomplete|installing) ;; *) return 1 ;; esac
  if [ "$explicit" -eq 1 ] && [ "$requested" != "$saved" ]; then return 1; fi
  printf '%s' "$saved"
}

tnx_install_single() {
  local user_name="ternux" locale="en_US.UTF-8" backend="auto" shell_choice="bash"
  local distro_choice="debian" distro_explicit=0
  local extras=() yes=0 resume=0 full=0 profile="base"
  local user_explicit=0 locale_explicit=0 backend_explicit=0 shell_explicit=0
  local workloads_explicit=0 batch_confirmed=0 workload_csv=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --yes) yes=1 ;;
      --user|--locale|--backend)
        local option="$1"
        [ $# -ge 2 ] || { tnx_fail "$option needs a value."; return 2; }
        case "$option" in
          --user) user_name="$2"; user_explicit=1 ;;
          --locale) locale="$2"; locale_explicit=1 ;;
          --backend) backend="$2"; backend_explicit=1 ;;
        esac
        shift
        ;;
      --zsh) shell_choice="zsh"; shell_explicit=1 ;;
      --shell) shell_choice="${2:-}"; shell_explicit=1; shift ;;
      --workloads)
        [ $# -ge 2 ] || { tnx_fail "--workloads needs a comma-separated list or 'none'."; return 2; }
        workload_csv="$2"; workloads_explicit=1; shift ;;
      --batch-confirmed) batch_confirmed=1 ;;
      --no-theme) export TERNUX_THEME=none ;;
      --distro)
        [ $# -ge 2 ] || { tnx_fail "--distro needs a value."; return 2; }
        distro_choice="$2"; distro_explicit=1; shift ;;
      --with-dev) extras+=("dev") ;;
      --with-llm) extras+=("llm") ;;
      --with-network) extras+=("network") ;;
      --with-media) extras+=("media") ;;
      --with-blender) extras+=("blender") ;;
      --all) extras+=("dev" "llm" "network" "media" "blender"); full=1 ;;
      --resume) resume=1 ;;
      --ui)
        [ $# -ge 2 ] || { tnx_fail "--ui needs a value."; return 2; }
        case "$2" in
          auto|dashboard|plain|off) export TERNUX_UI="$2" ;;
          *) tnx_fail "--ui must be auto, dashboard, plain or off."; return 2 ;;
        esac
        shift
        ;;
      --plain) export TERNUX_UI=plain ;;
      --no-anim) export TERNUX_NO_ANIM=1 ;;
      *) tnx_fail "Unknown install option: $1"; return 2 ;;
    esac; shift
  done

  if [ "$workloads_explicit" -eq 1 ]; then
    extras=()
    if [ "$workload_csv" != none ] && [ -n "$workload_csv" ]; then
      local workload_item known_workload duplicate_workload known
      local -a parsed_workloads=()
      IFS=',' read -r -a parsed_workloads <<< "$workload_csv"
      for workload_item in "${parsed_workloads[@]}"; do
        known_workload=0; duplicate_workload=0
        for known in "${TNX_OPTIONAL_ITEMS[@]}"; do [ "$known" = "$workload_item" ] && { known_workload=1; break; }; done
        [ "$known_workload" -eq 1 ] || { tnx_fail "Unknown optional workload '$workload_item'."; return 2; }
        for known in "${extras[@]}"; do [ "$known" = "$workload_item" ] && duplicate_workload=1; done
        [ "$duplicate_workload" -eq 0 ] || { tnx_fail "Duplicate optional workload '$workload_item'."; return 2; }
        extras+=("$workload_item")
      done
    fi
  fi

  # Re-running the normal one-command installer resumes an interrupted guest
  # automatically. A different explicitly selected guest starts independently.
  if [ "$resume" -eq 0 ]; then
    local auto_resume_distro=""
    auto_resume_distro="$(tnx_install_auto_resume_distro "$distro_choice" "$distro_explicit" || true)"
    if [ -n "$auto_resume_distro" ]; then
      resume=1
      distro_choice="$auto_resume_distro"
      tnx_info "An incomplete '$distro_choice' install was found; resuming saved choices automatically."
    fi
  fi

  # A bare `--resume` continues with the interrupted run’s saved choices.
  # Every explicitly supplied option takes precedence over its saved value.
  if [ "$resume" -eq 1 ]; then
    local saved_user="" saved_locale="" saved_backend="" saved_shell="" saved_distro=""
    local saved_extras="" saved_profile=""
    saved_user="$(tnx_state_get user 2>/dev/null || true)"
    saved_locale="$(tnx_state_get locale 2>/dev/null || true)"
    saved_backend="$(tnx_state_get install_backend 2>/dev/null || true)"
    saved_shell="$(tnx_state_get install_shell 2>/dev/null || true)"
    [ "$user_explicit" -eq 1 ] || [ -z "$saved_user" ] || user_name="$saved_user"
    [ "$locale_explicit" -eq 1 ] || [ -z "$saved_locale" ] || locale="$saved_locale"
    [ "$backend_explicit" -eq 1 ] || [ -z "$saved_backend" ] || backend="$saved_backend"
    [ "$shell_explicit" -eq 1 ] || [ -z "$saved_shell" ] || shell_choice="$saved_shell"
    saved_distro="$(tnx_state_get distro 2>/dev/null || true)"
    [ "$distro_explicit" -eq 1 ] || [ -z "$saved_distro" ] || distro_choice="$saved_distro"

    if [ ${#extras[@]} -eq 0 ]; then
      saved_extras="$(tnx_state_get install_extras 2>/dev/null || true)"
      saved_profile="$(tnx_state_get install_profile 2>/dev/null || true)"
      if [ -n "$saved_extras" ]; then
        IFS=',' read -r -a extras <<< "$saved_extras"
      fi
      [ "$saved_profile" = "full" ] && full=1
    fi
  else
    if [ "$yes" -eq 0 ]; then
      if [ "$user_explicit" -eq 0 ]; then
        user_name="$(tnx_prompt_username "$user_name" 300)"
      fi
      if [ "$shell_explicit" -eq 0 ]; then
        shell_choice="$(tnx_prompt_shell "$shell_choice" 300)"
      fi
      if [ "$distro_explicit" -eq 0 ]; then
        distro_choice="$(tnx_prompt_distro "$distro_choice" 300)"
      fi
    fi
  fi

  [[ "$user_name" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] || {
    tnx_fail "--user must start with a-z or _, use only a-z, 0-9, _ or -, and be at most 32 characters."
    return 2
  }
  [[ "$locale" =~ ^[A-Za-z0-9_.@-]+$ ]] || { tnx_fail "--locale contains unsupported characters."; return 2; }
  case "$backend" in auto|zink|virgl) ;; *) tnx_fail "--backend must be auto, zink or virgl."; return 2 ;; esac
  case "$shell_choice" in bash|zsh) ;; *) tnx_fail "Saved shell choice must be bash or zsh."; return 2 ;; esac
  tnx_distro_known "$distro_choice" && tnx_distro_profile "$distro_choice" || {
    tnx_fail "--distro must be one of: $TERNUX_DISTRO_KNOWN."
    return 2
  }
  if [ "$TNX_DP_FAMILY" != apt ] && [ "${#extras[@]}" -gt 0 ]; then
    tnx_fail "Optional software workloads currently require an APT guest; '$distro_choice' supports the family-matched base desktop only."
    return 2
  fi
  # tnx_distro caches its answer, so clear it before changing the environment.
  unset _TNX_DISTRO
  export TERNUX_DISTRO="$distro_choice"
  tnx_distro_verified "$distro_choice" || tnx_warn \
    "Guest '$distro_choice' has no device-verified result on record; treat this install as unverified."

  [ "$yes" -eq 1 ] && export TERNUX_YES=1
  tnx_require_termux

  # phases.sh loads ui.sh when available; retain the fallback for separately
  # packaged modules that omit it.
  if [ "${_TNX_UI_LOADED:-0}" != "1" ] && [ -f "$(dirname "${BASH_SOURCE[0]}")/ui.sh" ]; then
    . "$(dirname "${BASH_SOURCE[0]}")/ui.sh"
  fi


  if [ "$resume" -eq 0 ] && [ "$yes" -eq 0 ] && [ "$workloads_explicit" -eq 0 ] && [ "${#extras[@]}" -eq 0 ]; then
    if [ "$TNX_DP_FAMILY" = apt ]; then
      local workload_selection=""
      workload_selection="$(tnx_prompt_workloads "$backend")"
      if [ -n "$workload_selection" ]; then
        IFS=',' read -r -a extras <<< "$workload_selection"
        [ "$workload_selection" = "dev,llm,network,media,blender" ] && full=1
      fi
    else
      tnx_info "Optional workload installer is currently available for APT-family guests only."
    fi
  fi

  if [ "$full" -eq 1 ]; then
    profile="full"
  elif [ ${#extras[@]} -gt 0 ]; then
    profile="custom"
  fi
  TERNUX_INSTALL_PROFILE="$profile"
  export TERNUX_INSTALL_PROFILE

  tnx_banner

  local -a plan_summary=("Guest" "$distro_choice + Xfce4" "GPU route" "$backend" "User" "$user_name" "Profile" "$profile")
  local workload workload_label workload_number=0
  if [ "${#extras[@]}" -eq 0 ]; then
    plan_summary+=("Optional" "Base desktop only")
  else
    for workload in "${extras[@]}"; do
      workload_number=$((workload_number + 1))
      case "$workload" in
        git) workload_label="Git + curl/wget" ;;
        python) workload_label="Python + venv" ;;
        node) workload_label="Node.js + npm" ;;
        build) workload_label="C/C++ build tools" ;;
        golang) workload_label="Go toolchain" ;;
        php) workload_label="PHP CLI" ;;
        sqlite3) workload_label="SQLite" ;;
        ripgrep|jq|htop|tree|micro|thonny) workload_label="$workload" ;;
        libreoffice-writer) workload_label="LibreOffice Writer" ;;
        libreoffice-calc) workload_label="LibreOffice Calc" ;;
        libreoffice-draw) workload_label="LibreOffice Draw (PDF editing and export)" ;;
        evolution) workload_label="Evolution Mail (optional; no mail default)" ;;
        celestia) workload_label="Celestia astronomy simulator" ;;
        llama-vulkan) workload_label="llama.cpp Vulkan release" ;;
        stable-diffusion) workload_label="Stable Diffusion CPU + Vulkan image generator" ;;
        llama-htp-experimental) workload_label="llama.cpp HTP experimental release" ;;
        neovim) workload_label="Neovim editor" ;;
        gh) workload_label="GitHub CLI" ;;
        nmap|tmux|ffmpeg|vlc|gimp|audacity|imagemagick) workload_label="$workload" ;;
        blender) workload_label="Blender + Xvfb" ;;
        claude) workload_label="Claude Code" ;;
        codex) workload_label="OpenAI Codex CLI" ;;
        openai-cli) workload_label="OpenAI API CLI" ;;
        hermes) workload_label="Hermes Agent" ;;
        openclaw) workload_label="OpenClaw" ;;
        *) workload_label="$workload" ;;
      esac
      plan_summary+=("Workload $workload_number" "$workload_label")
    done
  fi
  local storage_estimate
  storage_estimate="$(tnx_storage_estimate "${extras[@]}")"
  plan_summary+=("Storage estimate" "$storage_estimate")
  TERNUX_SELECTED_EXTRAS="$(IFS=,; printf '%s' "${extras[*]}")"
  export TERNUX_SELECTED_EXTRAS
  tnx_summary_box "Install Plan" "${plan_summary[@]}"

  if [ "$batch_confirmed" -eq 0 ] && ! tnx_confirm "Plan ready. Press Enter to install, or type n to cancel (backend '$backend', user '$user_name')?" yes; then
    tnx_info "Installation cancelled; no phase was started."
    return 0
  fi

  local phases="preflight packages cli debian gpu audio_fonts launcher aliases extras phantom verify"
  local total=11 rc=0 current=0 phase_rc=0 required_failed=0 failed_phase="" failed_current=0 phase="" title=""
  local -a warning_phases=()

  tnx_frame_open "$total" "$backend" "$user_name" "$profile"
  # The standalone loader may own one extracted source snapshot. Preserve its
  # cleanup when this installer installs frame/signal traps of its own.
  trap 'tnx_frame_restore_terminal; if type _tnx_bootstrap_cleanup >/dev/null 2>&1; then _tnx_bootstrap_cleanup; fi' EXIT
  trap 'tnx_frame_restore_terminal; exit 130' INT
  trap 'tnx_frame_restore_terminal; exit 143' TERM

  local extras_csv=""
  if [ ${#extras[@]} -gt 0 ]; then
    extras_csv="$(IFS=','; printf '%s' "${extras[*]}")"
  fi
  tnx_state_set "user" "$user_name"
  tnx_state_set "locale" "$locale"
  tnx_state_set "install_backend" "$backend"
  tnx_state_set "install_shell" "$shell_choice"
  tnx_state_set "distro" "$distro_choice"
  tnx_distro_state_set "$distro_choice" status installing
  tnx_distro_state_set "$distro_choice" user "$user_name"
  tnx_distro_state_set "$distro_choice" locale "$locale"
  tnx_distro_state_set "$distro_choice" backend "$backend"
  tnx_distro_state_set "$distro_choice" install_profile "$profile"
  tnx_state_set "install_profile" "$profile"
  tnx_state_set "install_extras" "$extras_csv"

  for phase in $phases; do
    current=$((current + 1))
    title="$(tnx_phase_title "$phase")"
    tnx_frame_phase "$current" "$total" "$title"
    export _TNX_PHASE_CUR=$current _TNX_PHASE_TOT=$total

    if [ "$resume" -eq 1 ] && tnx_install_phase_done "$phase" "$distro_choice"; then
      if [ "${_TNX_FRAME_ACTIVE:-0}" = "1" ]; then
        printf '[SKIP] %s already completed\n' "$title" | tnx_frame_stream
      else
        tnx_info "Skipping $phase (done)"
      fi
      continue
    fi

    phase_rc=0
    if [ "${_TNX_FRAME_ACTIVE:-0}" = "1" ]; then
      _tnx_execute_install_phase "$phase" "$user_name" "$backend" "$locale" "$shell_choice" "${extras[@]}" \
        2>&1 | tnx_frame_stream
      phase_rc=${PIPESTATUS[0]}
    else
      _tnx_execute_install_phase "$phase" "$user_name" "$backend" "$locale" "$shell_choice" "${extras[@]}" || phase_rc=$?
    fi

    if [ "$phase_rc" -eq 0 ]; then
      tnx_install_phase_mark "$phase" "$distro_choice"
      continue
    fi

    tnx_log_error "Installation phase '$phase' failed with status $phase_rc"

    if [ "$phase" = "extras" ] || [ "$phase" = "phantom" ]; then
      rc="$phase_rc"
      warning_phases+=("$phase")
      if [ "${_TNX_FRAME_ACTIVE:-0}" = "1" ]; then
        printf '[WARN] Optional/advisory phase %s had issues; continuing to verification.\n' "$phase" | tnx_frame_stream
      else
        tnx_warn "Optional/advisory phase '$phase' had issues; continuing to verification."
      fi
      continue
    fi

    rc="$phase_rc"
    required_failed=1
    failed_phase="$phase"
    failed_current="$current"
    if [ "${_TNX_FRAME_ACTIVE:-0}" = "1" ]; then
      printf '[FAIL] Required phase %s failed; stopping before dependent phases.\n' "$phase" | tnx_frame_stream
    else
      tnx_fail "Required phase '$phase' failed; stopping before dependent phases."
    fi
    break
  done

  if [ "$required_failed" -eq 0 ]; then
    tnx_distro_state_set "$distro_choice" status ready || tnx_warn "Could not save the ready state for guest '$distro_choice'."
    local install_status="success" optional_summary=""
    local -a install_summary=("Version" "$TERNUX_VERSION" "Backend" "$backend" "User" "$user_name" "Profile" "$profile")
    if [ "${#warning_phases[@]}" -gt 0 ]; then
      install_status="warning"
      optional_summary="$(IFS=', '; printf '%s' "${warning_phases[*]}")"
      install_summary+=("Optional setup" "$optional_summary")
    fi
    if [ "${_TNX_FRAME_ACTIVE:-0}" = "1" ]; then
      {
        if [ "$install_status" = "warning" ]; then
          tnx_celebrate warning
          tnx_warn "Base desktop is ready; optional setup needs attention: $optional_summary."
        else
          tnx_celebrate
        fi
        install_summary+=("Device" "$(getprop ro.product.model 2>/dev/null || echo '?')" "Android" "$(getprop ro.build.version.release 2>/dev/null || echo '?')" "Host CLI" "${PREFIX:-/data/data/com.termux/files/usr}/bin/ternux" "Guest CLI" "/usr/local/bin/ternux")
        tnx_summary_box "Install Complete" "${install_summary[@]}"
        if [ "$install_status" = "warning" ]; then
          tnx_next_steps \
            "Base desktop is ready; retry optional setup with: ternux install --resume" \
            "Full installer log: $TERNUX_LOG_FILE" \
            "Start the desktop with: ternux start"
        else
          tnx_next_steps \
            "Open the Termux:X11 app once and leave it running" \
            "Start from Termux: ternux start  (or: x)" \
            "In Xfce Terminal:  ternux status" \
            "Host diagnostics: ternux doctor" \
            "Install tool help: ternux guides  (also inside Debian)"
        fi
      } 2>&1 | tnx_frame_stream
      tnx_frame_close "$install_status" "$current" "Optional setup needs attention"
    else
      if [ "$install_status" = "warning" ]; then
        tnx_celebrate warning
        tnx_warn "Base desktop is ready; optional setup needs attention: $optional_summary."
      else
        tnx_celebrate
      fi
      install_summary+=("Host CLI" "${PREFIX:-/data/data/com.termux/files/usr}/bin/ternux" "Guest CLI" "/usr/local/bin/ternux")
      tnx_summary_box "Install Complete" "${install_summary[@]}"
      if [ "$install_status" = "warning" ]; then
        tnx_next_steps \
          "Base desktop is ready; retry optional setup with: ternux install --resume" \
          "Full installer log: $TERNUX_LOG_FILE" \
          "Start the desktop with: ternux start"
      else
        tnx_next_steps \
          "Open the Termux:X11 app once and leave it running" \
          "Start from Termux: ternux start  (or: x)" \
          "In Xfce Terminal:  ternux status" \
          "Host diagnostics: ternux doctor" \
          "Install tool help: ternux guides  (also inside Debian)"
      fi
    fi
  else
    tnx_distro_state_set "$distro_choice" status incomplete || true
    if [ "${_TNX_FRAME_ACTIVE:-0}" = "1" ]; then
      {
        if [ -n "$failed_phase" ]; then
          tnx_warn "Installation did not complete cleanly (phase: $failed_phase)."
        else
          tnx_warn "Installation did not complete cleanly."
        fi
        tnx_info "Full log: $TERNUX_LOG_FILE"
        tnx_info "Fix the reported error, then run 'ternux install --resume' or the Termux-host 'ternux doctor'."
      } 2>&1 | tnx_frame_stream
      tnx_frame_close failed "$failed_current" "$(tnx_phase_title "$failed_phase")"
    else
      if [ -n "$failed_phase" ]; then
        tnx_warn "Installation did not complete cleanly (phase: $failed_phase)."
      else
        tnx_warn "Installation did not complete cleanly."
      fi
      tnx_info "Fix the reported error, then run 'ternux install --resume' or 'ternux doctor'."
    fi
  fi
  return "$rc"
}

tnx_phase_title() {
  case "$1" in
    preflight)   echo "Preflight checks" ;;
    packages)    echo "Base packages (X11, PulseAudio, PRoot)" ;;
    cli)         echo "Installing ternux CLI" ;;
    debian)      echo "Selected guest + Xfce4" ;;
    gpu)         echo "GPU driver setup" ;;
    audio_fonts) echo "Audio, locale, fonts" ;;
    launcher)    echo "Desktop launcher (~/x.sh)" ;;
    aliases)     echo "Shell shortcuts" ;;
    extras)      echo "Optional workloads" ;;
    phantom)     echo "Android background-process check" ;;
    verify)      echo "Verification" ;;
    *)           echo "$1" ;;
  esac
}


# Install more than one independently named guest profile in sequence.
# Each pass runs the same base profile and writes a distro-specific launcher;
# the single Termux:X11 display still runs one guest desktop at a time.
tnx_install() {
  local requested="" arg distro seen=" " has_distro=0 wants_yes=0 wants_resume=0
  local -a forwarded=() choices=() normalized=()
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --distros)
        [ -n "$requested" ] && { tnx_fail "Use --distros once."; return 2; }
        [ "$#" -ge 2 ] || { tnx_fail "--distros needs comma-separated names."; return 2; }
        requested="$2"; shift 2 ;;
      *)
        [ "$1" != --distro ] || has_distro=1
        [ "$1" != --yes ] || wants_yes=1
        [ "$1" != --resume ] || wants_resume=1
        forwarded+=("$1"); shift ;;
    esac
  done
  if [ -z "$requested" ] && [ "$has_distro" -eq 0 ] && [ "$wants_yes" -eq 0 ] && [ "$wants_resume" -eq 0 ]; then
    requested="$(tnx_prompt_distro debian 300)"
  fi
  if [ -z "$requested" ]; then tnx_install_single "${forwarded[@]}"; return $?; fi
  for arg in "${forwarded[@]}"; do
    [ "$arg" != --resume ] || { tnx_fail "--distros cannot resume multiple guests; resume each with --distro NAME --resume."; return 2; }
    [ "$arg" != --distro ] || { tnx_fail "Use either --distro NAME or --distros LIST, not both."; return 2; }
  done
  IFS=',' read -r -a choices <<< "$requested"
  [ ${#choices[@]} -gt 0 ] || { tnx_fail "--distros needs at least one name."; return 2; }
  for distro in "${choices[@]}"; do
    distro="$(printf '%s' "$distro" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
    tnx_distro_known "$distro" && tnx_distro_profile "$distro" || { tnx_fail "Unsupported Ternux profile '$distro'. Supported profiles: $TERNUX_DISTRO_KNOWN"; return 2; }
    case "$seen" in *" $distro "*) tnx_fail "Duplicate distro in --distros: $distro"; return 2 ;; esac
    seen+="$distro "
    normalized+=("$distro")
  done
  local has_optional=0 forwarded_arg
  for forwarded_arg in "${forwarded[@]}"; do case "$forwarded_arg" in --with-*|--all) has_optional=1 ;; esac; done
  if [ "$has_optional" -eq 1 ]; then
    for distro in "${normalized[@]}"; do
      tnx_distro_profile "$distro"
      [ "$TNX_DP_FAMILY" = apt ] || { tnx_fail "Optional workloads currently require an APT-family guest; '$distro' supports the base desktop profile."; return 2; }
    done
  fi
  # Collect the shared Termux shell and every guest username before the first
  # guest transaction. A selected incomplete profile keeps its saved account.
  local requested_user="" requested_shell="" requested_backend="auto" batch_shell="bash" saved_user="" status="" workload_csv=""
  local forwarded_index=0 forwarded_arg="" workload_flags=0
  local -a batch_users=() batch_workloads=() batch_summary=() batch_args=()
  for ((forwarded_index=0; forwarded_index<${#forwarded[@]}; forwarded_index++)); do
    forwarded_arg="${forwarded[forwarded_index]}"
    case "$forwarded_arg" in
      --user) (( forwarded_index + 1 < ${#forwarded[@]} )) && requested_user="${forwarded[forwarded_index+1]}" ;;
      --shell) (( forwarded_index + 1 < ${#forwarded[@]} )) && requested_shell="${forwarded[forwarded_index+1]}" ;;
      --backend) (( forwarded_index + 1 < ${#forwarded[@]} )) && requested_backend="${forwarded[forwarded_index+1]}" ;;
      --zsh) requested_shell=zsh ;;
      --with-*|--all) workload_flags=1 ;;
    esac
  done
  if [ -z "$requested_shell" ]; then
    requested_shell="$(tnx_state_get install_shell 2>/dev/null || true)"
    requested_shell="${requested_shell:-bash}"
  fi
  batch_shell="$requested_shell"
  if [ "$wants_yes" -eq 0 ] && ! printf '%s\n' "${forwarded[@]}" | grep -Eq -- '(^|[[:space:]])(--shell|--zsh)([[:space:]]|$)'; then
    batch_shell="$(tnx_prompt_shell "$requested_shell" 300)"
  fi

  for distro in "${normalized[@]}"; do
    status="$(tnx_distro_state_get "$distro" status 2>/dev/null || true)"
    saved_user="$(tnx_distro_state_get "$distro" user 2>/dev/null || true)"
    if [ -z "$saved_user" ] && [ "$distro" = "$(tnx_state_get distro 2>/dev/null || true)" ]; then
      saved_user="$(tnx_state_get user 2>/dev/null || true)"
    fi
    if [ -n "$requested_user" ]; then
      batch_users+=("$requested_user")
    elif [ -n "$saved_user" ] && { [ "$status" = incomplete ] || [ "$status" = installing ]; }; then
      batch_users+=("$saved_user")
    elif [ "$wants_yes" -eq 1 ]; then
      batch_users+=(ternux)
    else
      batch_users+=("$(tnx_prompt_username ternux 300 "$distro")")
    fi

    tnx_distro_profile "$distro"
    if [ "$workload_flags" -eq 1 ]; then
      batch_workloads+=(none)
    elif [ "$status" = incomplete ] || [ "$status" = installing ]; then
      saved_user="$(tnx_state_get install_extras 2>/dev/null || true)"
      batch_workloads+=("${saved_user:-none}")
    elif [ "$wants_yes" -eq 1 ] || [ "$TNX_DP_FAMILY" != apt ]; then
      batch_workloads+=(none)
    else
      tnx_info "Choose optional workloads for $distro before installation starts."
      workload_csv="$(tnx_prompt_workloads "$requested_backend")"
      batch_workloads+=("${workload_csv:-none}")
    fi
  done

  if [ "$wants_yes" -eq 0 ]; then
    batch_summary=("Termux shell" "$batch_shell")
    for forwarded_index in "${!normalized[@]}"; do
      if [ "${batch_workloads[forwarded_index]}" = none ]; then
        batch_summary+=("Guest $((forwarded_index + 1))" "${normalized[forwarded_index]} — user ${batch_users[forwarded_index]} — base desktop")
      else
        batch_summary+=("Guest $((forwarded_index + 1))" "${normalized[forwarded_index]} — user ${batch_users[forwarded_index]} — workloads ${batch_workloads[forwarded_index]}")
      fi
    done
    tnx_summary_box "Multi-guest install plan" "${batch_summary[@]}"
    if ! tnx_confirm "Start the complete multi-guest installation?" yes; then
      tnx_info "Installation cancelled; no guest installation was started."
      return 0
    fi
  fi

  for forwarded_index in "${!normalized[@]}"; do
    distro="${normalized[forwarded_index]}"
    tnx_step "Installing $distro profile"
    batch_args=("${forwarded[@]}" --distro "$distro" --user "${batch_users[forwarded_index]}" --shell "$batch_shell" --batch-confirmed)
    if [ "$workload_flags" -eq 0 ]; then batch_args+=(--workloads "${batch_workloads[forwarded_index]}"); fi
    tnx_install_single "${batch_args[@]}" || return $?
  done
}

tnx_cmd_install() { tnx_install "$@"; }
