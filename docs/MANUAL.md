---
title: "Manual installation"
description: "Every ternux step done by hand, command by command — the complete walkthrough for readers who want full control or need to debug the installer itself."
lang: "en"
alt_url: "/bn/docs/MANUAL.html"

---

# Manual installation

The one-command installer is this page, scripted. Here is the same journey
done **by hand, command by command** — for people who want to see and control
every step, work around a failing network, or simply learn what the installer
does. Run each block in Termux unless a step says otherwise.

**If anything fails mid-way:** every step below is independent and safe to
re-run. A re-run skips nothing automatically — that is the point of doing it
by hand — but nothing breaks by running a step twice.

---

## Step 1 — Install the two apps

- **Termux** from [GitHub releases](https://github.com/termux/termux-app/releases)
  or [F-Droid](https://f-droid.org/en/packages/com.termux/).
  *Why not the Play Store?* That build is abandoned; its package repositories
  are dead, so `pkg install` fails on everything.
- **Termux:X11** from [GitHub releases](https://github.com/termux/termux-x11/releases).
  Open it **once**, then leave it — Android only grants the display service
  after the first launch.

---

## Step 2 — Termux base packages

```bash
# Android will show a storage-permission dialog — approve it.
termux-setup-storage

# Refresh the package index and upgrade what's there.
pkg update -y
pkg upgrade -y

# Repositories that carry the X11 and graphics packages.
pkg install x11-repo tur-repo -y

# The display app service, audio, and the container engine.
pkg install termux-x11-nightly -y
pkg install pulseaudio proot-distro -y

# Host-side VirGL renderer (the compatibility GPU path — install it even on
# Adreno; it costs little and makes switching paths painless).
pkg install virglrenderer-android -y

# Shell and download tools used later in this guide.
pkg install zsh git curl wget nano tar -y

# Wake-lock support so the desktop can hold the screen awake.
pkg install termux-api -y
```

Adreno devices only (Qualcomm GPU — check with `ls -l /dev/kgsl-3d0`):

```bash
pkg install mesa-vulkan-icd-freedreno -y
```

> If `/dev/kgsl-3d0` does not exist, skip the Freedreno ICD: your device will
> use the VirGL path, where this package does nothing.

Verify the three critical binaries actually landed:

```bash
command -v proot-distro && command -v termux-x11 && command -v pulseaudio
```

---

## Step 3 — Install Debian

```bash
proot-distro install debian
```

*Why PRoot?* It provides a root-like Debian userland in userspace — no
unlocked bootloader, no root, no risk to Android. The "container" is just a
folder inside Termux's storage.

---

## Step 4 — Desktop packages inside Debian

Enter the container as root and install Xfce4 plus the GL/audio plumbing:

```bash
proot-distro login debian
```

```bash
export DEBIAN_FRONTEND=noninteractive
apt update

# Core desktop + GL/audio plumbing. Must succeed.
apt install -y sudo nano dbus-x11 pulseaudio pulseaudio-utils x11-utils \
  mesa-utils libgl1-mesa-dri xfce4 xfce4-terminal vlc pm-utils colord

# PolicyKit: polkitd = trixie+, policykit-1 = bookworm. Best effort.
apt install -y polkitd || apt install -y policykit-1 || true

# Explicit Vulkan loader (Zink dlopen()s libvulkan.so.1 at runtime) + tools.
apt install -y libvulkan1 vulkan-tools || true

# Archive tools. Best effort — rar/p7zip-rar live in Debian non-free.
apt install -y zip unzip xarchiver unrar-free || true
apt install -y 7zip || apt install -y p7zip-full || true

exit
```

---

## Step 5 — Create your user (with safe sudo)

```bash
proot-distro login debian
```

```bash
USER_NAME=ternux

# Create the user (skip the prompts — the desktop needs no password).
adduser --disabled-password --gecos "" "$USER_NAME"

# Graphics and audio groups.
usermod -aG sudo "$USER_NAME"
usermod -aG video "$USER_NAME"
usermod -aG render "$USER_NAME"
usermod -aG audio "$USER_NAME"

# Passwordless sudo via a VALIDATED drop-in file. Never append straight to
# /etc/sudoers: one typo there can lock sudo permanently in a container that
# has no other root path.
TMP_SUDOERS="$(mktemp)"
printf '%s ALL=(ALL) NOPASSWD: ALL\n' "$USER_NAME" > "$TMP_SUDOERS"
visudo -cf "$TMP_SUDOERS" \
  && install -m 0440 -o root -g root "$TMP_SUDOERS" /etc/sudoers.d/ternux
rm -f "$TMP_SUDOERS"

exit
```

Verify it works (this is the failure that silently hangs the launcher later):

```bash
proot-distro login debian --user ternux -- sudo -n true
```

---

## Step 6 — GPU driver

### Detect your route

```bash
ls -l /dev/kgsl-3d0
```

- **File exists** → Adreno → continue with *6a — Zink/Turnip*.
- **Missing** → Mali/Xclipse/PowerVR → skip to *6b — VirGL*.

### 6a — Zink + Turnip (Adreno)

Download the Debian/arm64 driver asset from
[lfdevs/mesa-for-android-container → Releases](https://github.com/lfdevs/mesa-for-android-container/releases/latest).
On the release page, copy the URL of the asset whose name contains
`debian` and `arm64.tar.gz` — never the Fedora or Alpine tarballs.

```bash
cd ~
curl -fLO "https://github.com/lfdevs/mesa-for-android-container/releases/latest/download/<ASSET-NAME>.tar.gz"
```

If curl cannot link after an upgrade, wget works the same:

```bash
wget -q "https://github.com/lfdevs/mesa-for-android-container/releases/latest/download/<ASSET-NAME>.tar.gz"
```

> Alternatively let the API resolve it:
> `curl -fsSL https://api.github.com/repos/lfdevs/mesa-for-android-container/releases/latest`
> and look for the `debian…arm64.tar.gz` `browser_download_url`.

Validate before extracting — a truncated download or an HTML error page must
never be unpacked as root:

```bash
# 1. It must be a real gzip tarball:
tar -tzf mesa-freedreno.tar.gz >/dev/null && echo "valid tarball"

# 2. No absolute paths, no path traversal:
tar -tzf mesa-freedreno.tar.gz | grep -E '^/|(^|/)\.\.(/|$)' && echo "UNSAFE - STOP" || echo "paths ok"

# 3. No links or special files (first column must be - or d):
tar -tvzf mesa-freedreno.tar.gz | awk '{t=substr($1,1,1); if (t!="-" && t!="d") exit 1}' && echo "entries ok"

# 4. Record the SHA-256 for your own records:
sha256sum mesa-freedreno.tar.gz
```

Extract **only the two files ternux needs** — the Turnip driver and its ICD
manifest — then install them and hold Mesa so a routine `apt upgrade` cannot
silently revert the GPU path:

```bash
proot-distro login debian --shared-tmp
```

```bash
set -e
stage=/tmp/ternux-driver-stage
rm -rf "$stage"; mkdir -p "$stage"
trap 'rm -rf "$stage"' EXIT

tar -xzf /tmp/mesa-freedreno.tar.gz -C "$stage" \
  --wildcards "*/usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so" \
               "*/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json"

base="$(find "$stage" -mindepth 1 -maxdepth 1 -type d | head -n1)"
[ -f "$base/usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so" ] \
  || { echo "driver missing from archive"; exit 1; }

cp -a "$base/usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so" \
      /usr/lib/aarch64-linux-gnu/
mkdir -p /usr/share/vulkan/icd.d
cp -a "$base/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json" \
      /usr/share/vulkan/icd.d/
ldconfig

# Pin Mesa: the #1 "renderer went back to llvmpipe" cause is an upgrade.
apt-mark hold mesa-vulkan-drivers libgl1-mesa-dri libglx-mesa0 \
             libgbm1 libegl-mesa0

exit
```

Confirm the files landed:

```bash
proot-distro login debian -- bash -c '
  test -f /usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so &&
  test -f /usr/share/vulkan/icd.d/freedreno_icd.aarch64.json &&
  echo "Turnip installed"'
```

### 6b — VirGL (other GPUs)

Nothing to install — only verify the host renderer exists:

```bash
command -v virgl_test_server_android && echo "VirGL ready"
```

---

## Step 7 — Audio, locale, fonts

### 7a — Audio bridge (Termux side)

Append the loopback-only TCP bridge to PulseAudio's config:

```bash
cat >> "$PREFIX/etc/pulse/default.pa" << 'EOF'
load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 port=4713
load-module module-opensles-sink sink_name=Speaker
set-default-sink Speaker
EOF
```

*Why loopback-only?* Sound crosses the container boundary over TCP, so an
anonymous ACL is needed — `127.0.0.1` keeps the microphone off the network.

### 7b — Locale and fonts (inside Debian)

```bash
proot-distro login debian --user ternux
```

```bash
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt install -y locales
echo 'en_US.UTF-8 UTF-8' | sudo tee -a /etc/locale.gen >/dev/null
sudo locale-gen en_US.UTF-8
echo "export LANG=en_US.UTF-8" >> ~/.bashrc
echo "export LC_ALL=en_US.UTF-8" >> ~/.bashrc

sudo apt install -y fonts-symbola fonts-noto-color-emoji \
  fonts-font-awesome fonts-powerline

# Point the desktop's PulseAudio client at the loopback bridge.
mkdir -p ~/.config/pulse
echo 'default-server = tcp:127.0.0.1:4713' > ~/.config/pulse/client.conf

# Nerd Font for terminal icon glyphs (best-effort).
mkdir -p ~/.local/share/fonts
wget -q -O /tmp/font.zip \
  https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip \
  && unzip -oq /tmp/font.zip -d ~/.local/share/fonts/ \
  && fc-cache -f
rm -f /tmp/font.zip

exit
```

---

## Step 8 — The launcher (`~/x.sh`)

This is the file the installer generates. Create it by hand:

```bash
nano ~/x.sh
```

Paste the content for your route, save, then:

```bash
chmod +x ~/x.sh
```

### 8a — Zink (Adreno) launcher

```bash
#!/data/data/com.termux/files/usr/bin/bash
# ternux launcher — Zink/Turnip route (Adreno)
set -u

TMPDIR="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"

# Clean up any previous session
pkill -9 -f termux-x11 2>/dev/null || true
pkill -9 -f virgl_test_server 2>/dev/null || true
pkill -9 -f dbus-daemon 2>/dev/null || true
pkill -9 -f dbus-launch 2>/dev/null || true
pulseaudio --kill 2>/dev/null || true
pkill -9 -f pulseaudio 2>/dev/null || true
rm -rf $TMPDIR/.X11-unix/X* $TMPDIR/.X*-lock $TMPDIR/pulse-socket 2>/dev/null || true

# Keep Android from suspending the session
termux-wake-lock 2>/dev/null || true

# Audio
unset PULSE_SERVER
pulseaudio --start --exit-idle-time=-1 --daemonize 2>/dev/null || true
sleep 0.3
pactl load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 port=4713 \
  >/dev/null 2>&1 || true

# Display
termux-x11 :0 -ac &
X11_PID=$!
echo "Waiting for Termux-X11 display socket..."
WAITED=0
while [ ! -e "$TMPDIR/.X11-unix/X0" ]; do
  if ! kill -0 "$X11_PID" 2>/dev/null; then
    echo "ERROR: termux-x11 exited before creating its socket."
    echo "       Open the Termux:X11 app once, then run this again."
    exit 1
  fi
  if [ "$WAITED" -ge 300 ]; then
    echo "ERROR: timed out after 30s waiting for display :0."
    exit 1
  fi
  WAITED=$((WAITED + 1))
  sleep 0.1
done
echo "Display :0 ready."

# Desktop
proot-distro login debian --shared-tmp \
  --bind /dev/kgsl-3d0:/dev/kgsl \
  --bind /dev/dri \
  --user ternux -- env \
  DISPLAY=:0 \
  PULSE_SERVER=tcp:127.0.0.1:4713 \
  AUDIODRIVER=pulse \
  MESA_LOADER_DRIVER_OVERRIDE=zink \
  GALLIUM_DRIVER=zink \
  TU_DEBUG=sysmem,noconform \
  MESA_VK_WSI_DEBUG=sw \
  MESA_DISK_CACHE_SINGLE_FILE=1 \
  MESA_SHADER_CACHE_MAX_SIZE=2048M \
  MESA_SHADER_CACHE_DIR=/tmp/mesa_cache \
  QT_X11_NO_MITSHM=1 \
  _X11_NO_MITSHM=1 \
  XDG_RUNTIME_DIR=/home/ternux/.runtime \
  LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
  bash -c '
    set -u
    mkdir -p ~/.runtime && chmod 700 ~/.runtime
    mkdir -p /tmp/mesa_cache && chmod 700 /tmp/mesa_cache

    until xdpyinfo -display :0 >/dev/null 2>&1; do sleep 0.1; done

    sudo -n mkdir -p /var/run/dbus /run/dbus 2>/dev/null || true
    sudo -n dbus-uuidgen --ensure >/dev/null 2>&1 || true
    sudo -n dbus-daemon --system --fork >/dev/null 2>&1 || true
    sudo -n rm -f /etc/xdg/autostart/light-locker.desktop 2>/dev/null || true

    mkdir -p ~/.config/pulse
    echo "default-server = tcp:127.0.0.1:4713" > ~/.config/pulse/client.conf

    xfconf-query -c xfwm4 -p /general/use_compositing -s false >/dev/null 2>&1 || true
    xfconf-query -c xfwm4 -p /general/vblank_mode -s off      >/dev/null 2>&1 || true

    exec dbus-launch --exit-with-session startxfce4
  '

# Teardown
pkill -9 -f termux-x11 2>/dev/null || true
pkill -9 -f virgl_test_server 2>/dev/null || true
termux-wake-unlock 2>/dev/null || true
```

### 8b — VirGL variant: two changes only

Start from the file above and make **two edits**:

1. Insert this block between `echo "Display :0 ready."` and `# Desktop`:

```bash
virgl_test_server_android >/dev/null 2>&1 &
VIRGL_PID=$!
sleep 1
if ! kill -0 "$VIRGL_PID" 2>/dev/null; then
  echo "WARNING: virgl_test_server_android failed to start."
  echo "         Rendering will fall back to software (llvmpipe)."
fi
```

2. Replace the whole `--bind … LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8` argument
block with:

```bash
  --user ternux -- env \
  DISPLAY=:0 \
  PULSE_SERVER=tcp:127.0.0.1:4713 \
  AUDIODRIVER=pulse \
  GALLIUM_DRIVER=virpipe \
  MESA_GL_VERSION_OVERRIDE=4.3COMPAT \
  MESA_GLES_VERSION_OVERRIDE=3.2 \
  QT_X11_NO_MITSHM=1 \
  _X11_NO_MITSHM=1 \
  XDG_RUNTIME_DIR=/home/ternux/.runtime \
  LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
```

Syntax-check the finished file:

```bash
bash -n ~/x.sh && echo "launcher ok"
```

---

## Step 9 — Shell shortcuts

```bash
cat >> ~/.bashrc << 'EOF'

# ==== TERNUX ALIASES ====
alias x='~/x.sh'
alias killx='pkill -f termux-x11; pkill -f pulseaudio; pkill -f dbus; \
  rm -rf $TMPDIR/.X11-unix/X* $TMPDIR/.X*-lock'
alias db='proot-distro login debian --user ternux'
alias droot='proot-distro login debian'
alias xgo='am start -n com.termux.x11/com.termux.x11.MainActivity 2>/dev/null; sleep 1; ~/x.sh'
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
EOF
```

Reload and start:

```bash
source ~/.bashrc
x
```

---

## Step 10 — Android 12+ phantom-killer check

```bash
getprop ro.build.version.sdk
settings get global settings_enable_monitor_phantom_procs
```

If the SDK is **31 or higher** and the setting is anything but `false`,
Android can silently SIGKILL your desktop. Fix per version:

- **Android 14+:** Settings → Developer options → **Disable child process
  restrictions** → reboot.
- **Android 12L/13:** `adb shell settings put global settings_enable_monitor_phantom_procs false`
- **Rooted:** `su -c "settings put global settings_enable_monitor_phantom_procs false"`

---

## Step 11 — Verify the whole stack

```bash
# Termux side
command -v termux-x11 proot-distro pulseaudio virgl_test_server_android
[ -x ~/x.sh ] && echo "launcher executable"

# Debian side
proot-distro login debian --user ternux -- bash -c '
  command -v startxfce4 && command -v glxinfo && command -v pactl &&
  sudo -n true && echo "Debian core OK"'
```

With the desktop running (after `x`), prove the GPU from a desktop terminal:

```bash
glxinfo | grep "renderer string"
```

| Good | Bad |
|---|---|
| `zink Vulkan (Adreno (TM) … (MESA_TURNIP))` | `llvmpipe` — software rendering |
| `virgl` (compatibility route) | a blank answer |

---

## Uninstalling by hand

```bash
killx
rm -f ~/x.sh ~/.ternux-state
sed -i '/# ==== TERNUX ALIASES/,/# ==== END TERNUX ALIASES/d' ~/.bashrc
proot-distro remove debian        # DESTROYS ALL DATA inside the container
```

---

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · MIT*
