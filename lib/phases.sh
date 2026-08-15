# =============================================================================
#  ternux — installation phases library
#  All 9 installation phases extracted from install.sh for modular reuse.
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah) — MIT License
#  https://github.com/soobujmiah/ternux
# =============================================================================

# shellcheck source=lib/core.sh
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"

# ---------------------------------------------------------------------------
# Phase 0 — preflight checks
# ---------------------------------------------------------------------------
tnx_phase_preflight() {
  tnx_step "0/9 — Preflight checks"
  local rc=0

  tnx_require_termux

  local arch; arch="$(uname -m)"
  case "$arch" in
    aarch64|arm64) tnx_ok "CPU architecture: $arch" ;;
    *) tnx_fail "CPU architecture is $arch — ternux needs a 64-bit ARM device."; rc=1 ;;
  esac

  # Export device facts for the HUD
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
    tnx_warn "Android 12+ detected: the 'phantom process killer' is active by default."
  fi

  local free
  free="$(df -Pk "$HOME" 2>/dev/null | awk 'NR==2{print int($4/1024/1024)}')"
  if [ -n "$free" ] && [ "$free" -lt 12 ]; then
    tnx_warn "Only ~${free} GB free — the base install wants ~12 GB."
  else
    tnx_ok "Storage: ~${free} GB free"
  fi

  # Internet connectivity
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
# Phase 1 — base Termux packages
# ---------------------------------------------------------------------------
tnx_phase_packages() {
  tnx_step "1/9 — Base Termux packages (X11, PulseAudio, PRoot)"
  local rc=0
  local APT_FORCE="-o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef"

  termux-setup-storage 2>/dev/null || tnx_warn "termux-setup-storage did not complete; continuing."
  sleep 1

  pkg update -y 2>/dev/null || rc=1
  pkg upgrade -y $APT_FORCE 2>/dev/null || {
    tnx_warn "pkg upgrade did not complete cleanly — repairing and continuing."
    dpkg --configure -a --force-confold --force-confdef 2>/dev/null || true
  }

  pkg install -y $APT_FORCE x11-repo tur-repo 2>/dev/null || rc=1
  pkg install -y $APT_FORCE termux-x11-nightly 2>/dev/null || \
    pkg install -y $APT_FORCE termux-x11 2>/dev/null || rc=1
  pkg install -y $APT_FORCE pulseaudio proot-distro virglrenderer-android zsh git curl wget nano tar termux-api 2>/dev/null || rc=1

  local backend="${1:-auto}"
  if [ "$backend" = "zink" ] || [ "$backend" = "auto" ] && [ -e /dev/kgsl-3d0 ]; then
    pkg install -y $APT_FORCE mesa-vulkan-icd-freedreno 2>/dev/null || tnx_warn "Freedreno ICD unavailable"
  fi

  # Verify critical binaries landed
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
# Phase 2 — Debian container + Xfce4 + user
# ---------------------------------------------------------------------------
tnx_phase_debian() {
  local user_name="${1:-ternux}"
  tnx_step "2/9 — PRoot Debian + Xfce4 desktop"

  if proot-distro list 2>/dev/null | grep -q "debian.*installed"; then
    tnx_warn "Debian is already installed; reusing the existing container."
  else
    proot-distro install debian 2>/dev/null || { tnx_fail "Debian install failed."; return 1; }
  fi

  # Install desktop packages
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

  # Create user with passwordless sudo
  proot-distro login debian --shared-tmp -- bash -c "
    set -e
    U='${user_name}'
    if ! id -u \"\$U\" >/dev/null 2>&1; then
      adduser --disabled-password --gecos '' \"\$U\"
    fi
    for grp in sudo video render audio; do
      getent group \"\$grp\" >/dev/null 2>&1 && usermod -aG \"\$grp\" \"\$U\" || true
    done
    F=/etc/sudoers.d/ternux
    T=\"\$(mktemp)\"
    printf '%s ALL=(ALL) NOPASSWD: ALL\n' \"\$U\" > \"\$T\"
    if visudo -cf \"\$T\" >/dev/null 2>&1; then
      install -m 0440 -o root -g root \"\$T\" \"\$F\"
    else
      rm -f \"\$T\"; echo 'Malformed sudoers file — refusing to install.' >&2; exit 1
    fi
    rm -f \"\$T\"
  " 2>/dev/null || { tnx_fail "User setup failed."; return 1; }

  # Verify sudo
  if proot-distro login debian --shared-tmp --user "$user_name" -- sudo -n true >/dev/null 2>&1; then
    tnx_ok "Debian + Xfce4 + user '$user_name' ready (passwordless sudo verified)."
  else
    tnx_fail "Passwordless sudo is not working for '$user_name'."
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Phase 3 — GPU driver (Zink/Turnip or VirGL)
# ---------------------------------------------------------------------------
tnx_phase_gpu() {
  local backend="${1:-auto}"
  tnx_step "3/9 — GPU driver setup ($backend)"

  if [ "$backend" = "virgl" ]; then
    tnx_has_cmd virgl_test_server_android || { tnx_fail "VirGL selected but virgl_test_server_android is missing."; return 1; }
    tnx_info "VirGL: rendering goes through the host-side virgl_test_server_android."
    return 0
  fi

  [ -e /dev/kgsl-3d0 ] || { tnx_fail "Zink needs an Adreno GPU (/dev/kgsl-3d0 is missing)."; return 1; }

  # Resolve Freedreno driver asset from GitHub
  local url
  url="$(tnx_resolve_freedreno_asset)"
  [ -n "$url" ] || { tnx_fail "Could not resolve a Freedreno driver asset."; return 1; }

  local tarball="${TMPDIR:-/data/data/com.termux/files/usr/tmp}/mesa-freedreno.tar.gz"
  rm -f "$tarball"
  tnx_download "$url" "$tarball" || { tnx_fail "Failed to download the Freedreno driver."; return 1; }

  tar -tzf "$tarball" >/dev/null 2>&1 || { tnx_fail "Download is not a valid gzip tarball."; rm -f "$tarball"; return 1; }

  # Validate archive safety
  if tar -tzf "$tarball" | grep -qE '^/|(^|/)\.\.(/|$)'; then
    tnx_fail "Archive contains unsafe paths. Refusing to extract."
    rm -f "$tarball"; return 1
  fi

  local sha
  sha="$(sha256sum "$tarball" | cut -d' ' -f1)"
  tnx_state_set "freedreno_sha" "$sha"
  tnx_debug "Driver SHA-256: ${sha:0:16}…"

  # Install driver into the Debian container
  proot-distro login debian --shared-tmp -- bash -c "
    set -e
    stage=/tmp/ternux-driver-stage
    rm -rf \"\$stage\"; mkdir -p \"\$stage\"
    trap 'rm -rf \$stage' EXIT
    export DEBIAN_FRONTEND=noninteractive
    apt install -y libvulkan1 >/dev/null 2>&1 || true
    tar -xzf /tmp/mesa-freedreno.tar.gz -C \"\$stage\" \
      --wildcards \"*/usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so\" \
                   \"*/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json\"
    base=\"\$(find \"\$stage\" -mindepth 1 -maxdepth 1 -type d | head -n1)\"
    [ -n \"\$base\" ] || { echo 'Driver files missing from archive.' >&2; exit 1; }
    cp -a \"\$base/usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so\" /usr/lib/aarch64-linux-gnu/
    mkdir -p /usr/share/vulkan/icd.d
    cp -a \"\$base/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json\" /usr/share/vulkan/icd.d/
    ldconfig
    apt-mark hold mesa-vulkan-drivers libgl1-mesa-dri libglx-mesa0 libgbm1 libegl-mesa0 >/dev/null 2>&1 || true
  " 2>/dev/null || { tnx_fail "Driver staging/installation failed."; rm -f "$tarball"; return 1; }

  rm -f "$tarball"

  if proot-distro login debian --shared-tmp -- bash -c '
    [ -f /usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so ] &&
    [ -f /usr/share/vulkan/icd.d/freedreno_icd.aarch64.json ]
  ' >/dev/null 2>&1; then
    tnx_ok "Turnip (libvulkan_freedreno.so) + Freedreno ICD installed and pinned."
  else
    tnx_fail "Turnip driver files are missing after extraction."; return 1
  fi
}

tnx_resolve_freedreno_asset() {
  local api="https://api.github.com/repos/lfdevs/mesa-for-android-container/releases/latest"
  local body=""
  tnx_has_cmd curl && body="$(curl -fsSL --max-time 30 "$api" 2>/dev/null)"
  [ -z "$body" ] && tnx_has_cmd wget && body="$(wget -q --timeout=30 -O- "$api" 2>/dev/null)"
  printf '%s' "$body" \
    | grep -o '"browser_download_url": *"[^"]*debian[^"]*arm64\.tar\.gz"' \
    | head -n 1 | sed 's/.*"browser_download_url": *"//; s/"$//'
}

# ---------------------------------------------------------------------------
# Phase 4 — audio, locale, fonts
# ---------------------------------------------------------------------------
tnx_phase_audio_fonts() {
  local user_name="${1:-ternux}" locale="${2:-en_US.UTF-8}"
  tnx_step "4/9 — Audio routing, locale and fonts"

  local PA_CONF="${PREFIX:-/data/data/com.termux/files/usr}/etc/pulse/default.pa"
  if grep -q "module-native-protocol-tcp" "$PA_CONF" 2>/dev/null; then
    tnx_warn "PulseAudio TCP module already configured; skipping."
  else
    {
      echo "load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 port=4713"
      echo "load-module module-opensles-sink sink_name=Speaker"
      echo "set-default-sink Speaker"
    } >> "$PA_CONF"
    tnx_ok "PulseAudio TCP bridge configured (loopback only)."
  fi

  proot-distro login debian --shared-tmp --user "$user_name" -- bash -c "
    set -e
    DPKG_FORCE=\"-o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef\"
    sudo apt update
    sudo DEBIAN_FRONTEND=noninteractive apt install -y \$DPKG_FORCE locales
    grep -qxF \"'${locale}' UTF-8\" /etc/locale.gen 2>/dev/null || echo \"'${locale}' UTF-8\" | sudo tee -a /etc/locale.gen >/dev/null
    sudo locale-gen \"${locale}\" || true
    grep -q \"export LANG='${locale}'\" ~/.bashrc 2>/dev/null || echo \"export LANG='${locale}'\" >> ~/.bashrc
    grep -q \"export LC_ALL='${locale}'\" ~/.bashrc 2>/dev/null || echo \"export LC_ALL='${locale}'\" >> ~/.bashrc

    sudo apt install -y \$DPKG_FORCE fonts-symbola fonts-noto-color-emoji fonts-font-awesome fonts-powerline

    mkdir -p ~/.config/pulse
    echo 'default-server = tcp:127.0.0.1:4713' > ~/.config/pulse/client.conf

    mkdir -p ~/.local/share/fonts
    if [ ! -f ~/.local/share/fonts/.ternux-nerdfont-installed ]; then
      if wget -q -O /tmp/font.zip \"https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip\" \
         && unzip -oq /tmp/font.zip -d ~/.local/share/fonts/; then
        touch ~/.local/share/fonts/.ternux-nerdfont-installed
        fc-cache -f >/dev/null 2>&1 || true
      fi
      rm -f /tmp/font.zip
    fi
  " 2>/dev/null || { tnx_fail "Locale/font setup failed."; return 1; }
  tnx_ok "Locale '$locale', PulseAudio client and fonts configured."
}

# ---------------------------------------------------------------------------
# Phase 5 — desktop launcher ~/x.sh
# ---------------------------------------------------------------------------
tnx_phase_launcher() {
  local user_name="${1:-ternux}" backend="${2:-auto}" locale="${3:-en_US.UTF-8}"
  tnx_step "5/9 — Desktop launcher (~/x.sh)"

  local LAUNCHER="$HOME/x.sh"
  local VIRGL_START="" GPU_ENV=""

  if [ "$backend" = "zink" ] || { [ "$backend" = "auto" ] && [ -e /dev/kgsl-3d0 ]; }; then
    backend="zink"
    GPU_ENV="  --bind /dev/kgsl-3d0:/dev/kgsl \\
  --bind /dev/dri \\
  --user $user_name -- env \\
  DISPLAY=:0 \\
  PULSE_SERVER=tcp:127.0.0.1:4713 \\
  AUDIODRIVER=pulse \\
  MESA_LOADER_DRIVER_OVERRIDE=zink \\
  GALLIUM_DRIVER=zink \\
  TU_DEBUG=sysmem,noconform \\
  MESA_VK_WSI_DEBUG=sw \\
  MESA_DISK_CACHE_SINGLE_FILE=1 \\
  MESA_SHADER_CACHE_MAX_SIZE=2048M \\
  MESA_SHADER_CACHE_DIR=/tmp/mesa_cache \\
  QT_X11_NO_MITSHM=1 \\
  _X11_NO_MITSHM=1 \\
  XDG_RUNTIME_DIR=/home/$user_name/.runtime \\
  LANG=$locale LC_ALL=$locale \\"
  else
    backend="virgl"
    VIRGL_START='virgl_test_server_android >/dev/null 2>&1 &
VIRGL_PID=$!
sleep 1
if ! kill -0 "$VIRGL_PID" 2>/dev/null; then
  echo "WARNING: virgl_test_server_android failed to start."
  echo "         Rendering will fall back to software (llvmpipe)."
  echo "         Install it with: pkg install virglrenderer-android -y"
fi'
    GPU_ENV="  --user $user_name -- env \\
  DISPLAY=:0 \\
  PULSE_SERVER=tcp:127.0.0.1:4713 \\
  AUDIODRIVER=pulse \\
  GALLIUM_DRIVER=virpipe \\
  MESA_GL_VERSION_OVERRIDE=4.3COMPAT \\
  MESA_GLES_VERSION_OVERRIDE=3.2 \\
  QT_X11_NO_MITSHM=1 \\
  _X11_NO_MITSHM=1 \\
  XDG_RUNTIME_DIR=/home/$user_name/.runtime \\
  LANG=$locale LC_ALL=$locale \\"
  fi

  cat > "$LAUNCHER" << LAUNCHEOF
#!/data/data/com.termux/files/usr/bin/bash
# Auto-generated by ternux — GPU backend: ${backend}
# https://github.com/soobujmiah/ternux — MIT
set -u

if [ -t 1 ] && [ -z "\${NO_COLOR:-}" ]; then
  printf '\033[1;32m'
  echo "  >_ ternux — starting desktop (${backend})"
  printf '\033[0m\n'
fi

TMPDIR="\${TMPDIR:-/data/data/com.termux/files/usr/tmp}"

# --- Clean up any previous session ---
pkill -9 -f termux-x11             2>/dev/null || true
pkill -9 -f virgl_test_server      2>/dev/null || true
pkill -9 -f dbus-daemon            2>/dev/null || true
pkill -9 -f dbus-launch            2>/dev/null || true
pulseaudio --kill                  2>/dev/null || true
pkill -9 -f pulseaudio             2>/dev/null || true
rm -f "\$TMPDIR"/.X11-unix/X* "\$TMPDIR"/.X*-lock "\$TMPDIR"/pulse-socket 2>/dev/null || true

# --- Keep Android from suspending the session ---
termux-wake-lock 2>/dev/null || true

# --- Audio ---
unset PULSE_SERVER
pulseaudio --start --exit-idle-time=-1 --daemonize 2>/dev/null || true
sleep 0.3
pactl load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 port=4713 >/dev/null 2>&1 || true

# --- Display ---
termux-x11 :0 -ac &
X11_PID=\$!

echo "Waiting for Termux-X11 display socket..."
WAITED=0
while [ ! -e "\$TMPDIR/.X11-unix/X0" ]; do
  if ! kill -0 "\$X11_PID" 2>/dev/null; then
    echo "ERROR: termux-x11 exited before creating its socket."
    echo "       Open the Termux:X11 app once, then run this again."
    exit 1
  fi
  if [ "\$WAITED" -ge 300 ]; then
    echo "ERROR: timed out after 30s waiting for display :0."
    exit 1
  fi
  WAITED=\$((WAITED + 1))
  sleep 0.1
done
echo "Display :0 ready."

${VIRGL_START}

# --- Desktop ---
proot-distro login debian --shared-tmp \\
${GPU_ENV}
  bash -c '
    set -u
    mkdir -p ~/.runtime && chmod 700 ~/.runtime
    mkdir -p /tmp/mesa_cache && chmod 700 /tmp/mesa_cache
    until xdpyinfo -display :0 >/dev/null 2>&1; do sleep 0.1; done
    sudo -n mkdir -p /var/run/dbus /run/dbus 2>/dev/null || true
    sudo -n mkdir -p /run/user/$(id -u) 2>/dev/null || true
    sudo -n dbus-uuidgen --ensure >/dev/null 2>&1 || true
    sudo -n rm -f /etc/xdg/autostart/light-locker.desktop 2>/dev/null || true
    mkdir -p ~/.config/pulse
    echo "default-server = tcp:127.0.0.1:4713" > ~/.config/pulse/client.conf
    xfconf-query -c xfwm4 -p /general/use_compositing -s false >/dev/null 2>&1 || true
    xfconf-query -c xfwm4 -p /general/vblank_mode -s off >/dev/null 2>&1 || true
    exec dbus-launch --exit-with-session startxfce4
  '

# --- Teardown ---
pkill -9 -f termux-x11        2>/dev/null || true
pkill -9 -f virgl_test_server 2>/dev/null || true
termux-wake-unlock 2>/dev/null || true
LAUNCHEOF

  chmod +x "$LAUNCHER"
  if bash -n "$LAUNCHER" 2>/dev/null; then
    tnx_ok "Launcher written and syntax-checked: $LAUNCHER"
    tnx_state_set "launcher" "$LAUNCHER"
    tnx_state_set "backend" "$backend"
  else
    tnx_fail "Launcher has a syntax error."
    rm -f "$LAUNCHER"
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Phase 6 — shell aliases
# ---------------------------------------------------------------------------
tnx_phase_aliases() {
  local user_name="${1:-ternux}" shell_choice="${2:-bash}"
  tnx_step "6/9 — Shell shortcuts"

  local RC_FILE="$HOME/.bashrc"
  if [ "$shell_choice" = "zsh" ]; then
    tnx_has_cmd zsh || pkg install zsh -y 2>/dev/null || true
    RC_FILE="$HOME/.zshrc"
    touch "$RC_FILE"
    tnx_has_cmd chsh && chsh -s zsh 2>/dev/null || true
  fi

  if grep -q "TERNUX ALIASES" "$RC_FILE" 2>/dev/null; then
    tnx_warn "Aliases already present in $RC_FILE; skipping."
    return 0
  fi

  cat >> "$RC_FILE" << 'ALIASEOF'

# ==== TERNUX ALIASES (installed by ternux) ====
alias x='~/x.sh'
alias killx='pkill -f termux-x11; pkill -f pulseaudio; pkill -f dbus; rm -rf $TMPDIR/.X11-unix/X* $TMPDIR/.X*-lock'
alias db='proot-distro login debian --user ternux'
alias droot='proot-distro login debian'
alias xgo='am start -n com.termux.x11/com.termux.x11.MainActivity 2>/dev/null; sleep 1; ~/x.sh'
alias ternux-info='ternux info'
alias ternux-doctor='ternux doctor'
clean-mesa() {
  proot-distro login debian --user ternux -- bash -c 'rm -rf ~/.cache/mesa/*'
  echo "Mesa cache cleared."
}
sysmon() {
  echo "--- CPU & Memory ---"; free -h
  echo ""; echo "--- GPU / KGSL Nodes ---"
  ls -l /dev/kgsl-3d0 /dev/dri 2>/dev/null || echo "Direct GPU nodes not available."
}
# ==== END TERNUX ALIASES ====
ALIASEOF

  tnx_ok "Aliases installed in $RC_FILE: x, killx, db, droot, xgo, clean-mesa, sysmon, ternux-info, ternux-doctor"
}

# ---------------------------------------------------------------------------
# Phase 7 — optional workloads
# ---------------------------------------------------------------------------
tnx_phase_extras() {
  local user_name="${1:-ternux}"
  shift
  tnx_step "7/9 — Optional workload profiles"

  local rc=0
  local APT="sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt install -y"

  for opt in "$@"; do
    case "$opt" in
      dev)
        proot-distro login debian --shared-tmp --user "$user_name" -- bash -c "
          $APT git curl wget nodejs npm python3 python3-pip python3-venv build-essential ca-certificates
        " 2>/dev/null || { tnx_warn "Development tools failed."; rc=1; }
        tnx_ok "Development tools installed"
        ;;
      llm)
        local cores jobs
        cores="$(nproc 2>/dev/null || echo 4)"
        jobs=$(( cores / 2 )); [ "$jobs" -lt 1 ] && jobs=1; [ "$jobs" -gt 4 ] && jobs=4
        tnx_warn "Building llama.cpp with -j$jobs. Keep the phone powered and cool."
        proot-distro login debian --shared-tmp --user "$user_name" -- bash -c "
          sudo apt update
          sudo DEBIAN_FRONTEND=noninteractive apt install -y build-essential cmake git pkg-config libvulkan-dev vulkan-tools clinfo glslang-dev glslang-tools libshaderc-dev glslc
          if [ ! -d ~/llama.cpp/.git ]; then
            rm -rf ~/llama.cpp
            git clone --depth 1 https://github.com/ggml-org/llama.cpp.git ~/llama.cpp
          fi
          cd ~/llama.cpp
          cmake -S . -B build -DGGML_VULKAN=ON -DCMAKE_BUILD_TYPE=Release
          cmake --build build --config Release -j$jobs
          mkdir -p models
        " 2>/dev/null || { tnx_warn "llama.cpp build failed."; rc=1; }
        tnx_ok "llama.cpp built with Vulkan backend"
        ;;
      network)
        proot-distro login debian --shared-tmp --user "$user_name" -- bash -c "
          $APT nmap tmux
        " 2>/dev/null || { tnx_warn "Network tools failed."; rc=1; }
        tnx_ok "Network tools installed"
        ;;
      media)
        proot-distro login debian --shared-tmp --user "$user_name" -- bash -c "
          $APT ffmpeg gimp audacity imagemagick
        " 2>/dev/null || { tnx_warn "Media tools failed."; rc=1; }
        tnx_ok "Media tools installed"
        ;;
      blender)
        proot-distro login debian --shared-tmp --user "$user_name" -- bash -c "
          $APT blender
        " 2>/dev/null || { tnx_warn "Blender install failed."; rc=1; }
        tnx_ok "Blender installed"
        ;;
    esac
  done

  return "$rc"
}

# ---------------------------------------------------------------------------
# Phase 8 — phantom process killer advisory
# ---------------------------------------------------------------------------
tnx_phase_phantom() {
  tnx_step "8/9 — Android background-process check"
  local sdk
  sdk="$(getprop ro.build.version.sdk 2>/dev/null || echo 0)"
  [ "$sdk" -lt 31 ] 2>/dev/null && {
    tnx_ok "Android version predates the phantom process killer. Nothing to do."
    return 0
  }

  local cur="unknown"
  tnx_has_cmd settings && cur="$(settings get global settings_enable_monitor_phantom_procs 2>/dev/null || echo unknown)"

  tnx_warn "Android 12+ 'phantom process killer' is active (setting: $cur)."
  echo ""
  echo "  Fix (pick one):"
  echo ""
  echo "  Android 14+  : Settings → Developer options → enable"
  echo "                 'Disable child process restrictions', then reboot."
  echo ""
  echo "  Android 12-13: from a PC with ADB:"
  echo "      adb shell settings put global settings_enable_monitor_phantom_procs false"
  echo ""
  echo "  Rooted device:"
  echo "      su -c \"settings put global settings_enable_monitor_phantom_procs false\""
  echo ""
}

# ---------------------------------------------------------------------------
# Phase 9 — verification
# ---------------------------------------------------------------------------
tnx_phase_verify() {
  local user_name="${1:-ternux}" backend="${2:-auto}"
  tnx_step "9/9 — Verification"
  local rc=0

  tnx_has_cmd termux-x11  && tnx_ok "termux-x11 found"  || { tnx_fail "termux-x11 missing"; rc=1; }
  tnx_has_cmd proot-distro && tnx_ok "proot-distro found" || { tnx_fail "proot-distro missing"; rc=1; }
  tnx_has_cmd pulseaudio  && tnx_ok "pulseaudio found"  || { tnx_fail "pulseaudio missing"; rc=1; }
  [ -x "$HOME/x.sh" ] && tnx_ok "Launcher ~/x.sh is executable" || { tnx_fail "Launcher missing"; rc=1; }

  if proot-distro login debian --user "$user_name" -- bash -c '
    command -v startxfce4 >/dev/null && command -v glxinfo >/dev/null && command -v pactl >/dev/null && sudo -n true >/dev/null
  ' >/dev/null 2>&1; then
    tnx_ok "Debian core OK (Xfce4, glxinfo, pactl, passwordless sudo)"
  else
    tnx_fail "Debian core check failed"; rc=1
  fi

  if [ "$backend" = "zink" ]; then
    if proot-distro login debian -- bash -c '
      test -f /usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so &&
      test -f /usr/share/vulkan/icd.d/freedreno_icd.aarch64.json
    ' >/dev/null 2>&1; then
      tnx_ok "Turnip driver and ICD present"
    else
      tnx_fail "Zink driver checks failed"; rc=1
    fi
  else
    tnx_has_cmd virgl_test_server_android && tnx_ok "VirGL host renderer present" || { tnx_fail "VirGL missing"; rc=1; }
  fi

  return "$rc"
}

# ---------------------------------------------------------------------------
# Full installation orchestrator
# ---------------------------------------------------------------------------
tnx_install() {
  local user_name="ternux" locale="en_US.UTF-8" backend="auto" shell_choice="bash"
  local extras=() yes=0 resume=0

  # Parse args
  while [ $# -gt 0 ]; do
    case "$1" in
      --yes) yes=1 ;;
      --user) user_name="${2:-ternux}"; shift ;;
      --locale) locale="${2:-en_US.UTF-8}"; shift ;;
      --backend) backend="${2:-auto}"; shift ;;
      --zsh) shell_choice="zsh" ;;
      --with-dev) extras+=("dev") ;;
      --with-llm) extras+=("llm") ;;
      --with-network) extras+=("network") ;;
      --with-media) extras+=("media") ;;
      --with-blender) extras+=("blender") ;;
      --all) extras+=("dev" "llm" "network" "media" "blender") ;;
      --resume) resume=1 ;;
    esac
    shift
  done

  tnx_require_termux

  # Resolve backend
  if [ "$backend" = "auto" ]; then
    [ -e /dev/kgsl-3d0 ] && backend="zink" || backend="virgl"
  fi

  local phases="preflight packages debian gpu audio_fonts launcher aliases extras phantom verify"
  local rc=0

  for phase in $phases; do
    if [ "$resume" -eq 1 ] && tnx_state_done "phase_${phase}"; then
      tnx_info "Skipping ${phase} (already completed)"
      continue
    fi
    tnx_debug "Running phase: ${phase}"

    case "$phase" in
      preflight)
        tnx_phase_preflight || rc=1
        ;;
      packages)
        tnx_phase_packages "$backend" || rc=1
        ;;
      debian)
        tnx_phase_debian "$user_name" || rc=1
        ;;
      gpu)
        tnx_phase_gpu "$backend" || rc=1
        ;;
      audio_fonts)
        tnx_phase_audio_fonts "$user_name" "$locale" || rc=1
        ;;
      launcher)
        tnx_phase_launcher "$user_name" "$backend" "$locale" || rc=1
        ;;
      aliases)
        tnx_phase_aliases "$user_name" "$shell_choice" || rc=1
        ;;
      extras)
        [ ${#extras[@]} -gt 0 ] && tnx_phase_extras "$user_name" "${extras[@]}" || tnx_info "No optional profiles selected."
        ;;
      phantom)
        tnx_phase_phantom || true
        ;;
      verify)
        tnx_phase_verify "$user_name" "$backend" || rc=1
        ;;
    esac

    if [ "$phase" != "extras" ] && [ "$phase" != "phantom" ]; then
      if [ "$rc" -eq 0 ] || [ "$phase" = "preflight" ]; then
        tnx_state_mark "phase_${phase}"
      fi
    fi
  done

  if [ "$rc" -eq 0 ]; then
    tnx_ok "Installation complete. Welcome to ternux."
    echo ""
    echo "  Next steps:"
    echo "  1. Open the Termux:X11 app once and leave it running."
    echo "  2. Start the desktop:  x"
    echo "  3. Verify the GPU:     glxinfo | grep 'renderer string'"
  else
    tnx_warn "Installation finished with issues. Run 'ternux doctor' for details."
  fi

  return "$rc"
}
# ---------------------------------------------------------------------------
# tnx_cmd_install — CLI command that delegates to tnx_install
# ---------------------------------------------------------------------------
tnx_cmd_install() {
  tnx_install "$@"
}
