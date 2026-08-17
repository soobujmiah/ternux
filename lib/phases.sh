# =============================================================================
#  ternux — installation phases library
#  All 11 installation phases, modular and self-contained.
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah) — MIT License
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
tnx_spin_run()     { local l="$1"; shift; tnx_debug "$l"; "$@" 2>/dev/null; return $?; }

# ---------------------------------------------------------------------------
# Phase 1 — preflight checks
# ---------------------------------------------------------------------------
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

  local free
  free="$(df -Pk "$HOME" 2>/dev/null | awk 'NR==2{print int($4/1024/1024)}')"
  if [ -n "$free" ] && [ "$free" -lt 12 ]; then
    tnx_warn "Only ~${free} GB free — the base install wants ~12 GB."
  else
    tnx_ok "Storage: ~${free} GB free"
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

# ---------------------------------------------------------------------------
# Phase 2 — base Termux packages
# ---------------------------------------------------------------------------
tnx_phase_packages() {
  local rc=0
  local APT_FORCE="-o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef"

  # Auto-select mirror if none configured
  if [ ! -f "${PREFIX:-/data/data/com.termux/files/usr}/etc/termux/chosen_mirrors" ]; then
    tnx_info "Selecting fastest Termux mirror..."
    yes "" | termux-change-repo 2>/dev/null || true
    sleep 1
  fi

  termux-setup-storage 2>/dev/null || tnx_warn "termux-setup-storage: continuing."
  sleep 1

  tnx_spin_run "Updating repositories" pkg update -y $APT_FORCE || rc=1
  tnx_spin_run "Upgrading packages" pkg upgrade -y $APT_FORCE 2>/dev/null || {
    tnx_warn "pkg upgrade incomplete — repairing."
    tnx_spin_run "Repairing dpkg" dpkg --configure -a --force-confold --force-confdef 2>/dev/null || true
  }
  tnx_spin_run "Adding x11-repo" pkg install -y $APT_FORCE x11-repo tur-repo 2>/dev/null || rc=1
  tnx_spin_run "Installing termux-x11" bash -c "pkg install -y $APT_FORCE termux-x11-nightly 2>/dev/null || pkg install -y $APT_FORCE termux-x11" 2>/dev/null || rc=1
  tnx_spin_run "Installing core services" pkg install -y $APT_FORCE pulseaudio proot-distro virglrenderer-android zsh git curl wget nano tar termux-api 2>/dev/null || rc=1

  local backend="${1:-auto}"
  if [ "$backend" = "zink" ] || { [ "$backend" = "auto" ] && [ -e /dev/kgsl-3d0 ]; }; then
    pkg install -y $APT_FORCE mesa-vulkan-icd-freedreno 2>/dev/null || tnx_warn "Freedreno ICD unavailable"
  fi

  local missing=""
  for b in proot-distro termux-x11 pulseaudio; do
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
# Phase 4 — Debian container + Xfce4 + user
# ---------------------------------------------------------------------------
tnx_phase_debian() {
  local user_name="${1:-ternux}"

  if proot-distro list 2>/dev/null | grep -q "debian.*installed"; then
    tnx_warn "Debian already installed; reusing."
  else
    proot-distro install debian 2>/dev/null || { tnx_fail "Debian install failed."; return 1; }
  fi

  proot-distro login debian --shared-tmp -- bash -c "
    set -e
    export DEBIAN_FRONTEND=noninteractive
    DPKG_FORCE=\"-o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef\"
    apt update
    dpkg --configure -a --force-confold --force-confdef || true
    apt install -y \$DPKG_FORCE sudo nano dbus-x11 pulseaudio pulseaudio-utils x11-utils mesa-utils libgl1-mesa-dri xfce4 xfce4-terminal vlc pm-utils colord
    apt install -y \$DPKG_FORCE polkitd || apt install -y \$DPKG_FORCE policykit-1 || true
    apt install -y \$DPKG_FORCE libvulkan1 vulkan-tools || true
    apt install -y \$DPKG_FORCE zip unzip xarchiver unrar-free || true
    apt install -y \$DPKG_FORCE 7zip || apt install -y \$DPKG_FORCE p7zip-full || true
  " 2>/dev/null || { tnx_fail "Desktop package installation failed."; return 1; }

  proot-distro login debian --shared-tmp -- bash -c "
    set -e
    U='${user_name}'
    if ! id -u \"\$U\" >/dev/null 2>&1; then adduser --disabled-password --gecos '' \"\$U\"; fi
    for grp in sudo video render audio; do getent group \"\$grp\" >/dev/null 2>&1 && usermod -aG \"\$grp\" \"\$U\" || true; done
    F=/etc/sudoers.d/ternux; T=\"\$(mktemp)\"
    printf '%s ALL=(ALL) NOPASSWD: ALL\n' \"\$U\" > \"\$T\"
    if visudo -cf \"\$T\" >/dev/null 2>&1; then install -m 0440 -o root -g root \"\$T\" \"\$F\"; else rm -f \"\$T\"; exit 1; fi
    rm -f \"\$T\"
  " 2>/dev/null || { tnx_fail "User setup failed."; return 1; }

  if proot-distro login debian --shared-tmp --user "$user_name" -- sudo -n true >/dev/null 2>&1; then
    tnx_ok "Debian + Xfce4 + user '$user_name' ready (passwordless sudo)."
  else
    tnx_fail "Passwordless sudo not working for '$user_name'."
    return 1
  fi
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
  local backend="${1:-auto}"

  # Keep the phase safe when called directly (for example by the legacy
  # install.sh doctor route), not only through the main orchestrator.
  [ "$backend" = "zink-turnip" ] && backend="zink"
  if [ "$backend" = "auto" ]; then
    [ -e /dev/kgsl-3d0 ] && backend="zink" || backend="virgl"
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

  [ -e /dev/kgsl-3d0 ] || { tnx_fail "Zink needs /dev/kgsl-3d0 (Adreno GPU)."; return 1; }

  local guest_codename
  guest_codename="$(proot-distro login debian -- bash -c '. /etc/os-release; printf "%s" "${VERSION_CODENAME:-}"' 2>/dev/null || true)"
  [ "$guest_codename" = "trixie" ] || {
    tnx_fail "The validated Turnip asset targets Debian Trixie; guest reports '${guest_codename:-unknown}'."
    return 1
  }

  local url
  url="$(tnx_resolve_freedreno_asset)"
  [ -n "$url" ] || { tnx_fail "Could not resolve Freedreno driver asset."; return 1; }

  local tarball="${TMPDIR:-/data/data/com.termux/files/usr/tmp}/mesa-freedreno.tar.gz"
  rm -f "$tarball"
  tnx_download "$url" "$tarball" || { tnx_fail "Failed to download Freedreno driver."; return 1; }

  if ! tnx_validate_turnip_archive "$tarball"; then
    tnx_fail "Archive must have safe paths and exactly one regular driver and ICD target."
    rm -f "$tarball"
    return 1
  fi

  local sha
  sha="$(sha256sum "$tarball" | cut -d' ' -f1)"
  tnx_state_set "freedreno_sha" "$sha"
  tnx_state_set "freedreno_url" "$url"

  proot-distro login debian --shared-tmp -- bash -c "
    set -e
    stage=/tmp/ternux-driver-stage; rm -rf \"\$stage\"; mkdir -p \"\$stage\"
    trap 'rm -rf \"\$stage\"' EXIT
    export DEBIAN_FRONTEND=noninteractive
    apt install -y libvulkan1 >/dev/null 2>&1 || true
    tar -xzf /tmp/mesa-freedreno.tar.gz -C \"\$stage\" --wildcards \
      \"*/usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so\" \
      \"*/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json\"
    driver=\"\$(find \"\$stage\" -type f -path '*/usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so' -print -quit)\"
    icd=\"\$(find \"\$stage\" -type f -path '*/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json' -print -quit)\"
    [ -n \"\$driver\" ] && [ -n \"\$icd\" ] || exit 1
    install -m 0755 \"\$driver\" /usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so
    mkdir -p /usr/share/vulkan/icd.d
    install -m 0644 \"\$icd\" /usr/share/vulkan/icd.d/freedreno_icd.aarch64.json
    ldconfig
    apt-mark hold mesa-vulkan-drivers libgl1-mesa-dri libglx-mesa0 libgbm1 libegl-mesa0 >/dev/null 2>&1 || true
  " 2>/dev/null || { tnx_fail "Driver installation failed."; rm -f "$tarball"; return 1; }
  rm -f "$tarball"

  if proot-distro login debian --shared-tmp -- bash -c '
    [ -f /usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so ] &&
    [ -f /usr/share/vulkan/icd.d/freedreno_icd.aarch64.json ]
  ' >/dev/null 2>&1; then
    local driver_sha icd_sha
    driver_sha="$(proot-distro login debian -- sha256sum /usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so 2>/dev/null | awk '{print $1}')"
    icd_sha="$(proot-distro login debian -- sha256sum /usr/share/vulkan/icd.d/freedreno_icd.aarch64.json 2>/dev/null | awk '{print $1}')"
    [ -n "$driver_sha" ] && tnx_state_set "freedreno_driver_sha" "$driver_sha"
    [ -n "$icd_sha" ] && tnx_state_set "freedreno_icd_sha" "$icd_sha"
    tnx_ok "Turnip driver + ICD installed, hashed and pinned."
  else
    tnx_fail "Turnip driver files missing after extraction."; return 1
  fi
}

tnx_resolve_freedreno_asset() {
  local api="https://api.github.com/repos/lfdevs/mesa-for-android-container/releases/latest"
  local body=""
  tnx_has_cmd curl && body="$(curl -fsSL --max-time 30 "$api" 2>/dev/null)"
  [ -z "$body" ] && tnx_has_cmd wget && body="$(wget -q --timeout=30 -O- "$api" 2>/dev/null)"
  printf '%s' "$body" | grep -o '"browser_download_url": *"[^"]*debian[^"]*trixie[^"]*arm64\.tar\.gz"' | head -1 | sed 's/.*"browser_download_url": *"//; s/"$//'
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

tnx_phase_audio_fonts() {
  local user_name="${1:-ternux}" locale="${2:-en_US.UTF-8}"

  local PA_CONF="${PREFIX:-/data/data/com.termux/files/usr}/etc/pulse/default.pa"
  _tnx_configure_pulse_bridge "$PA_CONF" || return 1
  [ "$_TNX_PULSE_CHANGED" = "1" ] && tnx_ok "PulseAudio TCP bridge bound to loopback."

  proot-distro login debian --shared-tmp --user "$user_name" -- bash -c "
    set -e
    DPKG_FORCE=\"-o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef\"
    sudo apt update
    sudo DEBIAN_FRONTEND=noninteractive apt install -y \$DPKG_FORCE locales
    grep -qxF \"${locale} UTF-8\" /etc/locale.gen 2>/dev/null || echo \"${locale} UTF-8\" | sudo tee -a /etc/locale.gen >/dev/null
    sudo locale-gen \"${locale}\"
    grep -q \"export LANG='${locale}'\" ~/.bashrc 2>/dev/null || echo \"export LANG='${locale}'\" >> ~/.bashrc
    grep -q \"export LC_ALL='${locale}'\" ~/.bashrc 2>/dev/null || echo \"export LC_ALL='${locale}'\" >> ~/.bashrc
    sudo apt install -y \$DPKG_FORCE fonts-symbola fonts-noto-color-emoji fonts-font-awesome fonts-powerline
    mkdir -p ~/.config/pulse && echo 'default-server = tcp:127.0.0.1:4713' > ~/.config/pulse/client.conf
    mkdir -p ~/.local/share/fonts
    if [ ! -f ~/.local/share/fonts/.ternux-nerdfont-installed ]; then
      wget -q -O /tmp/font.zip \"https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip\" \
        && unzip -oq /tmp/font.zip -d ~/.local/share/fonts/ \
        && touch ~/.local/share/fonts/.ternux-nerdfont-installed \
        && fc-cache -f >/dev/null 2>&1 || true
      rm -f /tmp/font.zip
    fi
  " 2>/dev/null || { tnx_fail "Locale/font setup failed."; return 1; }
  tnx_ok "Locale '$locale', PulseAudio client and fonts configured."
}

# ---------------------------------------------------------------------------
# Phase 7 — desktop launcher ~/x.sh
# ---------------------------------------------------------------------------
tnx_phase_launcher() {
  local user_name="${1:-ternux}" backend="${2:-auto}" locale="${3:-en_US.UTF-8}"
  local LAUNCHER="$HOME/x.sh"

  [[ "$user_name" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] || {
    tnx_fail "Launcher user name is invalid."; return 2;
  }
  [[ "$locale" =~ ^[A-Za-z0-9_.@-]+$ ]] || {
    tnx_fail "Launcher locale is invalid."; return 2;
  }

  # Resolve backend
  case "$backend" in
    zink|zink-turnip) backend="zink" ;;
    virgl) backend="virgl" ;;
    auto) [ -e /dev/kgsl-3d0 ] && backend="zink" || backend="virgl" ;;
    *) tnx_fail "Launcher backend must be auto, zink or virgl."; return 2 ;;
  esac

  # Write launcher
  cat > "$LAUNCHER" << 'LAUNCHEOF'
#!/data/data/com.termux/files/usr/bin/bash
set -u
TMPDIR="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
cleanup() {
  pkill -9 -f termux-x11 2>/dev/null || true
  pkill -9 -f virgl_test_server 2>/dev/null || true
  pulseaudio --kill 2>/dev/null || pkill -KILL -x pulseaudio 2>/dev/null || true
  rm -f "$TMPDIR"/.X11-unix/X* "$TMPDIR"/.X*-lock "$TMPDIR"/pulse-socket "$TMPDIR"/.pulse-*/native 2>/dev/null || true
  termux-wake-unlock 2>/dev/null || true
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
# Cleanup any previous session
pkill -9 -f termux-x11 2>/dev/null || true
pkill -9 -f virgl_test_server 2>/dev/null || true
pulseaudio --kill 2>/dev/null || pkill -KILL -x pulseaudio 2>/dev/null || true
rm -f "$TMPDIR"/.X11-unix/X* "$TMPDIR"/.X*-lock "$TMPDIR"/pulse-socket "$TMPDIR"/.pulse-*/native 2>/dev/null || true
# Wake lock
termux-wake-lock 2>/dev/null || true
# Audio
unset PULSE_SERVER; pulseaudio --start --exit-idle-time=-1 --daemonize 2>/dev/null || true
sleep 0.3; pactl load-module module-native-protocol-tcp listen=127.0.0.1 auth-ip-acl=127.0.0.1 auth-anonymous=1 port=4713 >/dev/null 2>&1 || true
# Display
termux-x11 :0 -ac &
X11_PID=$!
echo "Waiting for Termux-X11..."
WAITED=0
while [ ! -e "$TMPDIR/.X11-unix/X0" ]; do
  if ! kill -0 "$X11_PID" 2>/dev/null; then echo "ERROR: termux-x11 exited."; exit 1; fi
  if [ "$WAITED" -ge 300 ]; then echo "ERROR: timed out."; exit 1; fi
  WAITED=$((WAITED+1)); sleep 0.1
done
echo "Display :0 ready."
LAUNCHEOF

  # Backend-specific launcher additions
  if [ "$backend" = "zink" ]; then
    # Zink talks to Turnip/KGSL directly; the VirGL host server belongs only
    # to the fallback route below.
    cat >> "$LAUNCHER" << EOF
proot-distro login debian --shared-tmp --bind /dev/kgsl-3d0:/dev/kgsl --bind /dev/dri --user $user_name \\
  --env DISPLAY=:0 --env PULSE_SERVER=tcp:127.0.0.1:4713 \\
  --env MESA_LOADER_DRIVER_OVERRIDE=zink --env GALLIUM_DRIVER=zink \\
  --env TU_DEBUG=sysmem,noconform --env MESA_VK_WSI_DEBUG=sw \\
  --env MESA_DISK_CACHE_SINGLE_FILE=1 --env MESA_SHADER_CACHE_MAX_SIZE=2048M \\
  --env QT_X11_NO_MITSHM=1 --env XDG_RUNTIME_DIR=/home/$user_name/.runtime \\
  --env LANG=$locale --env LC_ALL=$locale \\
  -- bash -c '
    set -u
    mkdir -p ~/.runtime /tmp/mesa_cache
    chmod 700 ~/.runtime /tmp/mesa_cache
    until xdpyinfo -display :0 >/dev/null 2>&1; do sleep 0.1; done
    sudo -n mkdir -p /var/run/dbus /run/dbus /run/user/\$(id -u) 2>/dev/null || true
    sudo -n dbus-uuidgen --ensure >/dev/null 2>&1 || true
    sudo -n rm -f /etc/xdg/autostart/light-locker.desktop 2>/dev/null || true
    xfconf-query -c xfwm4 -p /general/use_compositing -s false >/dev/null 2>&1 || true
    exec dbus-launch --exit-with-session startxfce4
  '
EOF
  else
    cat >> "$LAUNCHER" << 'VIRGLEOF'
virgl_test_server_android >/dev/null 2>&1 &
VIRGL_PID=$!
sleep 1
if ! kill -0 "$VIRGL_PID" 2>/dev/null; then
  echo "WARNING: virgl_test_server_android failed to start; check for llvmpipe."
fi
VIRGLEOF
    cat >> "$LAUNCHER" << EOF
proot-distro login debian --shared-tmp --user $user_name \\
  --env DISPLAY=:0 --env PULSE_SERVER=tcp:127.0.0.1:4713 \\
  --env GALLIUM_DRIVER=virpipe --env MESA_GL_VERSION_OVERRIDE=4.3COMPAT \\
  --env QT_X11_NO_MITSHM=1 --env XDG_RUNTIME_DIR=/home/$user_name/.runtime \\
  --env LANG=$locale --env LC_ALL=$locale \\
  -- bash -c '
    set -u
    mkdir -p ~/.runtime /tmp/mesa_cache
    chmod 700 ~/.runtime /tmp/mesa_cache
    until xdpyinfo -display :0 >/dev/null 2>&1; do sleep 0.1; done
    sudo -n mkdir -p /var/run/dbus /run/dbus /run/user/\$(id -u) 2>/dev/null || true
    sudo -n dbus-uuidgen --ensure >/dev/null 2>&1 || true
    xfconf-query -c xfwm4 -p /general/use_compositing -s false >/dev/null 2>&1 || true
    exec dbus-launch --exit-with-session startxfce4
  '
EOF
  fi

  # The EXIT trap defined near the top performs teardown on success, failure,
  # Ctrl+C, or termination.

  chmod +x "$LAUNCHER"
  if bash -n "$LAUNCHER" 2>/dev/null; then
    tnx_ok "Launcher written: $LAUNCHER"
    tnx_state_set "backend" "$backend"
  else
    tnx_fail "Launcher has a syntax error."; rm -f "$LAUNCHER"; return 1
  fi
}

# ---------------------------------------------------------------------------
# Phase 8 — shell aliases
# ---------------------------------------------------------------------------
tnx_phase_aliases() {
  local user_name="${1:-ternux}" shell_choice="${2:-bash}"
  local RC_FILE="$HOME/.bashrc"
  if [ "$shell_choice" = "zsh" ]; then
    tnx_has_cmd zsh || pkg install zsh -y 2>/dev/null || true
    RC_FILE="$HOME/.zshrc"; touch "$RC_FILE"
    tnx_has_cmd chsh && chsh -s zsh 2>/dev/null || true
  fi

  grep -q "TERNUX ALIASES" "$RC_FILE" 2>/dev/null && { tnx_warn "Aliases already present."; return 0; }

  cat >> "$RC_FILE" << ALIASEOF

# ==== TERNUX ALIASES ====
alias x='~/x.sh'
alias killx='pkill -f termux-x11 || true; pulseaudio --kill 2>/dev/null || pkill -KILL -x pulseaudio 2>/dev/null || true; rm -f \$TMPDIR/.X11-unix/X* \$TMPDIR/.X*-lock \$TMPDIR/.pulse-*/native'
alias db='proot-distro login debian --shared-tmp --user $user_name'
alias droot='proot-distro login debian --shared-tmp'
alias xgo='am start -n com.termux.x11/com.termux.x11.MainActivity 2>/dev/null; sleep 1; ~/x.sh'
clean-mesa() { proot-distro login debian --user $user_name -- bash -c 'rm -rf ~/.cache/mesa/*'; echo "Mesa cache cleared."; }
sysmon() { echo "--- CPU & Memory ---"; free -h; echo ""; echo "--- GPU / KGSL ---"; ls -l /dev/kgsl-3d0 /dev/dri 2>/dev/null || echo "No GPU nodes."; }
# ==== END TERNUX ALIASES ====
ALIASEOF
  tnx_ok "Aliases installed for Debian user '$user_name': x, killx, db, droot, xgo, clean-mesa, sysmon"
}

# ---------------------------------------------------------------------------
# Phase 9 — optional workloads
# ---------------------------------------------------------------------------
tnx_phase_extras() {
  local user_name="${1:-ternux}"; shift
  local rc=0
  local APT="sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt install -y"

  for opt in "$@"; do
    case "$opt" in
      dev)
        if proot-distro login debian --shared-tmp --user "$user_name" -- bash -c "$APT git curl wget nodejs npm python3 python3-pip python3-venv build-essential ca-certificates" 2>/dev/null; then
          tnx_ok "Dev tools installed"
        else
          tnx_warn "Dev tools failed."
          rc=1
        fi
        ;;
      llm)
        local cores jobs
        cores="$(nproc 2>/dev/null || echo 4)"
        jobs=$((cores / 2)); [ "$jobs" -lt 1 ] && jobs=1; [ "$jobs" -gt 4 ] && jobs=4
        if proot-distro login debian --shared-tmp --user "$user_name" -- bash -c "
          sudo apt update
          sudo DEBIAN_FRONTEND=noninteractive apt install -y build-essential cmake git pkg-config libvulkan-dev vulkan-tools clinfo glslang-dev glslang-tools libshaderc-dev glslc
          if [ ! -d ~/llama.cpp/.git ]; then rm -rf ~/llama.cpp; git clone --depth 1 https://github.com/ggml-org/llama.cpp.git ~/llama.cpp; fi
          cd ~/llama.cpp
          cmake -S . -B build -DGGML_VULKAN=ON -DCMAKE_BUILD_TYPE=Release
          cmake --build build --config Release -j$jobs
          mkdir -p models
        " 2>/dev/null; then
          tnx_ok "llama.cpp built with Vulkan"
        else
          tnx_warn "llama.cpp build failed."
          rc=1
        fi
        ;;
      network)
        if proot-distro login debian --shared-tmp --user "$user_name" -- bash -c "$APT nmap tmux" 2>/dev/null; then
          tnx_ok "Network tools installed"
        else
          tnx_warn "Network tools failed."
          rc=1
        fi
        ;;
      media)
        if proot-distro login debian --shared-tmp --user "$user_name" -- bash -c "$APT ffmpeg gimp audacity imagemagick" 2>/dev/null; then
          tnx_ok "Media tools installed"
        else
          tnx_warn "Media tools failed."
          rc=1
        fi
        ;;
      blender)
        if proot-distro login debian --shared-tmp --user "$user_name" -- bash -c "$APT blender" 2>/dev/null; then
          tnx_ok "Blender installed"
        else
          tnx_warn "Blender install failed."
          rc=1
        fi
        ;;
    esac
  done
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

  tnx_has_cmd termux-x11  && tnx_ok "termux-x11 found"  || { tnx_fail "termux-x11 missing"; rc=1; }
  tnx_has_cmd proot-distro && tnx_ok "proot-distro found" || { tnx_fail "proot-distro missing"; rc=1; }
  tnx_has_cmd pulseaudio  && tnx_ok "pulseaudio found"  || { tnx_fail "pulseaudio missing"; rc=1; }
  [ -x "$HOME/x.sh" ] && tnx_ok "Launcher executable" || { tnx_fail "Launcher missing"; rc=1; }
  tnx_has_cmd ternux >/dev/null 2>&1 && tnx_ok "ternux CLI in PATH" || tnx_warn "ternux CLI not in PATH (run: source ~/.bashrc)"

  if proot-distro login debian --user "$user_name" -- bash -c 'command -v startxfce4 && command -v glxinfo && command -v pactl && sudo -n true' >/dev/null 2>&1; then
    tnx_ok "Debian core OK"
  else tnx_fail "Debian core failed"; rc=1; fi

  if [ "$backend" = "zink" ]; then
    if proot-distro login debian -- bash -c 'test -f /usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so && test -f /usr/share/vulkan/icd.d/freedreno_icd.aarch64.json' >/dev/null 2>&1; then
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
  local cli_src=""

  for try in "$(dirname "${BASH_SOURCE[0]}")/../bin/ternux" \
              "$(dirname "$0")/bin/ternux"; do
    [ -f "$try" ] && { cli_src="$try"; break; }
  done

  if [ -z "$cli_src" ]; then
    tnx_info "Downloading ternux CLI from GitHub..."
    local base="https://raw.githubusercontent.com/soobujmiah/ternux/main"
    local tmp_dir="${TMPDIR:-/tmp}/ternux-cli-install.$$" lib=""
    local libs="core.sh help.sh detect.sh desktop.sh doctor.sh info.sh backend.sh profile.sh benchmark.sh repair.sh logs.sh update.sh state.sh uninstall.sh phases.sh ui.sh"
    mkdir -p "$tmp_dir/lib" "$bin_dir" "$lib_dir" || return 1
    if tnx_has_cmd curl; then
      curl -fsSL --max-time 15 "$base/bin/ternux" -o "$tmp_dir/ternux" 2>/dev/null || { tnx_fail "CLI download failed"; rm -rf "$tmp_dir"; return 1; }
      for lib in $libs; do
        curl -fsSL --max-time 15 "$base/lib/$lib" -o "$tmp_dir/lib/$lib" 2>/dev/null || {
          tnx_fail "Failed to download $lib"; rm -rf "$tmp_dir"; return 1;
        }
      done
    elif tnx_has_cmd wget; then
      wget -q --timeout=15 "$base/bin/ternux" -O "$tmp_dir/ternux" 2>/dev/null || { tnx_fail "CLI download failed"; rm -rf "$tmp_dir"; return 1; }
      for lib in $libs; do
        wget -q --timeout=15 "$base/lib/$lib" -O "$tmp_dir/lib/$lib" 2>/dev/null || {
          tnx_fail "Failed to download $lib"; rm -rf "$tmp_dir"; return 1;
        }
      done
    else
      tnx_fail "Neither curl nor wget is available."
      rm -rf "$tmp_dir"
      return 1
    fi

    if ! bash -n "$tmp_dir/ternux" 2>/dev/null; then
      tnx_fail "Downloaded CLI failed shell syntax validation."
      rm -rf "$tmp_dir"
      return 1
    fi
    for lib in $libs; do
      if ! bash -n "$tmp_dir/lib/$lib" 2>/dev/null; then
        tnx_fail "Downloaded library failed shell syntax validation: $lib"
        rm -rf "$tmp_dir"
        return 1
      fi
    done
    for lib in $libs; do
      install -m 644 "$tmp_dir/lib/$lib" "$lib_dir/$lib" 2>/dev/null || {
        tnx_fail "Could not install $lib"; rm -rf "$tmp_dir"; return 1;
      }
    done
    install -m 755 "$tmp_dir/ternux" "$bin_dir/ternux" 2>/dev/null || { tnx_fail "Install failed"; rm -rf "$tmp_dir"; return 1; }
    rm -rf "$tmp_dir"
  else
    local local_lib
    mkdir -p "$bin_dir" "$lib_dir"
    bash -n "$cli_src" 2>/dev/null || {
      tnx_fail "Local CLI failed shell syntax validation."; return 1;
    }
    for local_lib in "$(dirname "$cli_src")/../lib/"*.sh; do
      bash -n "$local_lib" 2>/dev/null || {
        tnx_fail "Local library failed shell syntax validation: $(basename "$local_lib")"
        return 1
      }
    done
    cp "$(dirname "$cli_src")/../lib/"*.sh "$lib_dir/" 2>/dev/null || {
      tnx_fail "Failed to copy CLI libraries"; return 1;
    }
    install -m 755 "$cli_src" "$bin_dir/ternux" 2>/dev/null || { tnx_fail "Install failed"; return 1; }
  fi

  if command -v ternux >/dev/null 2>&1 || [ -x "$bin_dir/ternux" ]; then
    tnx_ok "ternux CLI installed to $bin_dir/ternux"
    tnx_state_set "cli_installed" "yes"
    return 0
  fi
  tnx_fail "CLI installation failed."; return 1
}

# ---------------------------------------------------------------------------
# Full installation orchestrator
# ---------------------------------------------------------------------------
tnx_install() {
  local user_name="ternux" locale="en_US.UTF-8" backend="auto" shell_choice="bash"
  local extras=() yes=0 resume=0

  while [ $# -gt 0 ]; do
    case "$1" in
      --yes) yes=1 ;;
      --user|--locale|--backend)
        local option="$1"
        [ $# -ge 2 ] || { tnx_fail "$option needs a value."; return 2; }
        case "$option" in
          --user) user_name="$2" ;;
          --locale) locale="$2" ;;
          --backend) backend="$2" ;;
        esac
        shift
        ;;
      --zsh) shell_choice="zsh" ;;
      --with-dev) extras+=("dev") ;;
      --with-llm) extras+=("llm") ;;
      --with-network) extras+=("network") ;;
      --with-media) extras+=("media") ;;
      --with-blender) extras+=("blender") ;;
      --all) extras+=("dev" "llm" "network" "media" "blender") ;;
      --resume) resume=1 ;;
      *) tnx_fail "Unknown install option: $1"; return 2 ;;
    esac; shift
  done

  [[ "$user_name" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] || {
    tnx_fail "--user must start with a-z or _, use only a-z, 0-9, _ or -, and be at most 32 characters."
    return 2
  }
  [[ "$locale" =~ ^[A-Za-z0-9_.@-]+$ ]] || { tnx_fail "--locale contains unsupported characters."; return 2; }
  case "$backend" in auto|zink|virgl) ;; *) tnx_fail "--backend must be auto, zink or virgl."; return 2 ;; esac

  [ "$yes" -eq 1 ] && export TERNUX_YES=1
  tnx_require_termux

  # Load UI library if available
  declare -F tnx_banner >/dev/null 2>&1 || \
    . "$(dirname "${BASH_SOURCE[0]}")/ui.sh" 2>/dev/null || true

  if [ "$backend" = "auto" ]; then
    [ -e /dev/kgsl-3d0 ] && backend="zink" || backend="virgl"
  fi

  tnx_banner

  if ! tnx_confirm "Install ternux with backend '$backend' and Debian user '$user_name'?"; then
    tnx_info "Installation cancelled; no phase was started."
    return 0
  fi

  tnx_state_set "user" "$user_name"
  tnx_state_set "locale" "$locale"

  local phases="preflight packages cli debian gpu audio_fonts launcher aliases extras phantom verify"
  local total=11 rc=0 current=0 phase_rc=0 failed_phase=""

  for phase in $phases; do
    current=$((current + 1))
    [ "$resume" -eq 1 ] && tnx_state_done "phase_${phase}" && { tnx_info "Skipping $phase (done)"; continue; }

    tnx_phase_header "$current" "$total" "$(tnx_phase_title "$phase")"
    export _TNX_PHASE_CUR=$current _TNX_PHASE_TOT=$total
    phase_rc=0

    case "$phase" in
      preflight)   tnx_phase_preflight || phase_rc=$? ;;
      packages)    tnx_phase_packages "$backend" || phase_rc=$? ;;
      cli)         tnx_phase_cli || phase_rc=$? ;;
      debian)      tnx_phase_debian "$user_name" || phase_rc=$? ;;
      gpu)         tnx_phase_gpu "$backend" || phase_rc=$? ;;
      audio_fonts) tnx_phase_audio_fonts "$user_name" "$locale" || phase_rc=$? ;;
      launcher)    tnx_phase_launcher "$user_name" "$backend" "$locale" || phase_rc=$? ;;
      aliases)     tnx_phase_aliases "$user_name" "$shell_choice" || phase_rc=$? ;;
      extras)
        if [ ${#extras[@]} -gt 0 ]; then
          tnx_phase_extras "$user_name" "${extras[@]}" || phase_rc=$?
        else
          tnx_info "No optional profiles."
        fi
        ;;
      phantom)     tnx_phase_phantom || phase_rc=$? ;;
      verify)      tnx_phase_verify "$user_name" "$backend" || phase_rc=$? ;;
    esac

    if [ "$phase_rc" -eq 0 ]; then
      tnx_state_mark "phase_${phase}"
      continue
    fi

    rc="$phase_rc"
    failed_phase="$phase"
    tnx_log_error "Installation phase '$phase' failed with status $phase_rc"

    if [ "$phase" = "extras" ] || [ "$phase" = "phantom" ]; then
      tnx_warn "Optional/advisory phase '$phase' had issues; continuing to verification."
      continue
    fi

    tnx_fail "Required phase '$phase' failed; stopping before dependent phases."
    break
  done

  echo ""
  if [ "$rc" -eq 0 ]; then
    tnx_celebrate
    tnx_summary_box "Install Complete" \
      "Version" "$TERNUX_VERSION" "Backend" "$backend" "User" "$user_name" \
      "Device" "$(getprop ro.product.model 2>/dev/null || echo '?')" \
      "Android" "$(getprop ro.build.version.release 2>/dev/null || echo '?')" \
      "Launcher" "~/x.sh"
    tnx_next_steps \
      "Open the Termux:X11 app once and leave it running" \
      "Start the desktop:  x" \
      "Verify the GPU:     glxinfo | grep 'renderer string'" \
      "Run diagnostics:    ternux doctor"
  else
    if [ -n "$failed_phase" ]; then
      tnx_warn "Installation did not complete cleanly (phase: $failed_phase)."
    else
      tnx_warn "Installation did not complete cleanly."
    fi
    tnx_info "Fix the reported error, then run 'bash install.sh --resume' or 'ternux doctor'."
  fi
  return "$rc"
}

tnx_phase_title() {
  case "$1" in
    preflight)   echo "Preflight checks" ;;
    packages)    echo "Base packages (X11, PulseAudio, PRoot)" ;;
    cli)         echo "Installing ternux CLI" ;;
    debian)      echo "Debian container + Xfce4" ;;
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

tnx_cmd_install() { tnx_install "$@"; }