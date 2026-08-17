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
does. Run each block in Termux unless a step says otherwise. The commands use
`ternux` as the Debian account name; if you choose another valid lowercase
name in Step 5, replace every later literal `ternux` with that same name.

**If anything fails mid-way:** stop at the failing command and diagnose it
before continuing. Read each block before re-running it: checks are included
where practical, but manual package, user and file operations are not promised
to be universally idempotent.

---

## Step 1 — Install the two apps

- **Termux** from [GitHub releases](https://github.com/termux/termux-app/releases)
  or [F-Droid](https://f-droid.org/en/packages/com.termux/).
  The Google Play build is a separate experimental Android 11+ line with
  known missing functionality/bugs; this guide follows the main F-Droid/GitHub
  release line. Install Termux:API and other plugins from the **same source**
  as Termux so their signing keys match.
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

*Why PRoot?* It provides a root-like Debian userland in userspace without
unlocking the bootloader or granting Android root. It is not a security
boundary: Termux-accessible or explicitly bound paths remain reachable. The
container rootfs is stored under Termux, so back it up before destructive work.

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

# Create the user if absent (the desktop account needs no login password).
id -u "$USER_NAME" >/dev/null 2>&1 \
  || adduser --disabled-password --gecos "" "$USER_NAME"

# Graphics and audio groups.
usermod -aG sudo "$USER_NAME"
usermod -aG video "$USER_NAME"
usermod -aG render "$USER_NAME"
usermod -aG audio "$USER_NAME"

# Passwordless sudo via a VALIDATED drop-in file. Never append straight to
# /etc/sudoers: one typo can break sudo for this account. PRoot Distro can
# still open a guest-root recovery shell; that is not Android root.
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

<a id="zink-turnip-adreno"></a>
### 6a — Zink + Turnip (Adreno)

Download the Debian/arm64 driver asset from
[lfdevs/mesa-for-android-container → Releases](https://github.com/lfdevs/mesa-for-android-container/releases/latest).
Use GitHub's release API to resolve the current **Debian Trixie ARM64** asset,
then save it under the fixed name expected through PRoot's shared `/tmp` mapping.
Do not substitute the Fedora, Ubuntu, Alpine or Arch archive. First confirm that
the guest and archive distribution match:

```bash
proot-distro login debian -- bash -c '. /etc/os-release; echo "$VERSION_CODENAME"'
# This documented asset path expects: trixie
```

If it does not print `trixie`, stop rather than overwriting a different
distribution's Mesa files.

```bash
DRIVER_API=https://api.github.com/repos/lfdevs/mesa-for-android-container/releases/latest
DRIVER_TARBALL="$TMPDIR/mesa-freedreno.tar.gz"

DRIVER_URL="$(curl -fsSL "$DRIVER_API" \
  | grep -o '"browser_download_url": *"[^"]*debian[^"]*trixie[^"]*arm64\.tar\.gz"' \
  | head -n 1 \
  | sed 's/.*"browser_download_url": *"//; s/"$//')"

[ -n "$DRIVER_URL" ] || { echo "No Debian ARM64 release asset found"; exit 1; }
printf 'Resolved: %s\n' "$DRIVER_URL"
curl -fL --retry 3 "$DRIVER_URL" -o "$DRIVER_TARBALL"
```

If curl cannot link after a partial upgrade, replace the last line with:

```bash
wget -O "$DRIVER_TARBALL" "$DRIVER_URL"
```

Validate before extracting — a truncated download or an HTML error page must
never be unpacked as root:

```bash
# 1. It must be a real gzip tarball:
tar -tzf "$DRIVER_TARBALL" >/dev/null && echo "valid tarball"

# 2. No absolute paths, no path traversal:
tar -tzf "$DRIVER_TARBALL" \
  | grep -E '^/|(^|/)\.\.(/|$)' \
  && { echo "UNSAFE - STOP"; exit 1; } \
  || echo "paths ok"

# 3. The two members we will extract must exist exactly once as regular files.
#    Other Mesa members may legitimately be symlinks; they are not extracted.
tar -tvzf "$DRIVER_TARBALL" | awk '
  /\/usr\/lib\/aarch64-linux-gnu\/libvulkan_freedreno[.]so$/ {
    if (substr($1,1,1) != "-") bad=1
    driver++
  }
  /\/usr\/share\/vulkan\/icd[.]d\/freedreno_icd[.]aarch64[.]json$/ {
    if (substr($1,1,1) != "-") bad=1
    icd++
  }
  END { if (bad || driver != 1 || icd != 1) exit 1 }
' && echo "one regular driver and one regular ICD found" \
  || { echo "unexpected archive layout"; exit 1; }

# 4. Record this release artifact for troubleshooting/reproduction:
sha256sum "$DRIVER_TARBALL"
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

driver="$(find "$stage" -type f \
  -path '*/usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so' -print -quit)"
icd="$(find "$stage" -type f \
  -path '*/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json' -print -quit)"
[ -n "$driver" ] && [ -n "$icd" ] \
  || { echo "Turnip target files missing after staged extraction"; exit 1; }

install -m 0755 "$driver" /usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so
mkdir -p /usr/share/vulkan/icd.d
install -m 0644 "$icd" \
  /usr/share/vulkan/icd.d/freedreno_icd.aarch64.json
ldconfig

# Hold the Debian Mesa packages that are paired with this staged driver.
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

Add the loopback-only TCP bridge to PulseAudio's config once:

```bash
PA_CONF="$PREFIX/etc/pulse/default.pa"
OLD='load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 port=4713'
NEW='load-module module-native-protocol-tcp listen=127.0.0.1 auth-ip-acl=127.0.0.1 auth-anonymous=1 port=4713'
SINK='load-module module-opensles-sink sink_name=Speaker'
DEFAULT='set-default-sink Speaker'
mkdir -p "$(dirname "$PA_CONF")"
if [ -L "$PA_CONF" ] || { [ -e "$PA_CONF" ] && [ ! -f "$PA_CONF" ]; }; then
  echo "PulseAudio config path is not a regular, non-symlink file: $PA_CONF" >&2
  false
else
  INPUT=/dev/null
  [ ! -f "$PA_CONF" ] || INPUT="$PA_CONF"
  if grep -E '^[[:space:]]*load-module[[:space:]]+module-native-protocol-tcp([[:space:]]|$)' "$INPUT" \
     | grep -Fvx -e "$OLD" -e "$NEW" | grep -q .; then
    echo "Custom PulseAudio TCP module found; review it instead of overwriting it." >&2
    false
  elif TMP="$(mktemp "${PA_CONF}.ternux.XXXXXX")"; then
    awk -v old="$OLD" -v new="$NEW" '
      $0 == old || $0 == new { if (!seen) print new; seen=1; next }
      { print }
      END { if (!seen) print new }
    ' "$INPUT" > "$TMP" &&
    { grep -qxF "$SINK" "$TMP" || printf '%s\n' "$SINK" >> "$TMP"; } &&
    { grep -qxF "$DEFAULT" "$TMP" || printf '%s\n' "$DEFAULT" >> "$TMP"; } &&
    { [ ! -f "$PA_CONF" ] || chmod --reference="$PA_CONF" "$TMP" 2>/dev/null || true; } &&
    mv -f "$TMP" "$PA_CONF" || { rm -f "$TMP"; false; }
  else
    echo "Could not create a PulseAudio staging file." >&2
    false
  fi
fi
```

*Why loopback-only?* The guest uses an anonymous TCP connection to cross the
PRoot boundary. Explicit `listen=127.0.0.1` keeps the service off the LAN, but
other same-device clients can still reach it; do not remove the bind address.

### 7b — Locale and fonts (inside Debian)

```bash
proot-distro login debian --user ternux
```

```bash
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt install -y locales
grep -qxF 'en_US.UTF-8 UTF-8' /etc/locale.gen \
  || echo 'en_US.UTF-8 UTF-8' | sudo tee -a /etc/locale.gen >/dev/null
sudo locale-gen en_US.UTF-8
grep -qxF 'export LANG=en_US.UTF-8' ~/.bashrc \
  || echo 'export LANG=en_US.UTF-8' >> ~/.bashrc
grep -qxF 'export LC_ALL=en_US.UTF-8' ~/.bashrc \
  || echo 'export LC_ALL=en_US.UTF-8' >> ~/.bashrc

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

<a id="create-launcher"></a>
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

# Clean up any previous session
pkill -9 -f termux-x11 2>/dev/null || true
pkill -9 -f virgl_test_server 2>/dev/null || true
pulseaudio --kill 2>/dev/null || pkill -KILL -x pulseaudio 2>/dev/null || true
rm -f "$TMPDIR"/.X11-unix/X* "$TMPDIR"/.X*-lock "$TMPDIR"/pulse-socket "$TMPDIR"/.pulse-*/native 2>/dev/null || true

# Keep Android from suspending the session
termux-wake-lock 2>/dev/null || true

# Audio
unset PULSE_SERVER
pulseaudio --start --exit-idle-time=-1 --daemonize 2>/dev/null || true
sleep 0.3
pactl load-module module-native-protocol-tcp listen=127.0.0.1 auth-ip-acl=127.0.0.1 auth-anonymous=1 port=4713 \
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
  --user ternux \
  --env DISPLAY=:0 \
  --env PULSE_SERVER=tcp:127.0.0.1:4713 \
  --env MESA_LOADER_DRIVER_OVERRIDE=zink \
  --env GALLIUM_DRIVER=zink \
  --env TU_DEBUG=sysmem,noconform \
  --env MESA_VK_WSI_DEBUG=sw \
  --env MESA_DISK_CACHE_SINGLE_FILE=1 \
  --env MESA_SHADER_CACHE_MAX_SIZE=2048M \
  --env QT_X11_NO_MITSHM=1 \
  --env XDG_RUNTIME_DIR=/home/ternux/.runtime \
  --env LANG=en_US.UTF-8 \
  --env LC_ALL=en_US.UTF-8 \
  -- bash -c '
    set -u
    mkdir -p ~/.runtime /tmp/mesa_cache
    chmod 700 ~/.runtime /tmp/mesa_cache

    until xdpyinfo -display :0 >/dev/null 2>&1; do sleep 0.1; done

    sudo -n mkdir -p /var/run/dbus /run/dbus /run/user/$(id -u) 2>/dev/null || true
    sudo -n dbus-uuidgen --ensure >/dev/null 2>&1 || true
    sudo -n rm -f /etc/xdg/autostart/light-locker.desktop 2>/dev/null || true

    xfconf-query -c xfwm4 -p /general/use_compositing -s false >/dev/null 2>&1 || true
    exec dbus-launch --exit-with-session startxfce4
  '

# The EXIT trap performs teardown on success, failure, Ctrl+C or termination.
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

2. Remove the two `--bind` lines and replace the argument block through the
`-- bash -c` separator with:

```bash
  --user ternux \
  --env DISPLAY=:0 \
  --env PULSE_SERVER=tcp:127.0.0.1:4713 \
  --env GALLIUM_DRIVER=virpipe \
  --env MESA_GL_VERSION_OVERRIDE=4.3COMPAT \
  --env QT_X11_NO_MITSHM=1 \
  --env XDG_RUNTIME_DIR=/home/ternux/.runtime \
  --env LANG=en_US.UTF-8 \
  --env LC_ALL=en_US.UTF-8 \
  -- bash -c '
```

`--env` is intentionally repeated: PRoot-Distro defines it as a repeatable
single `VAR=VALUE` option.

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
alias killx='pkill -f termux-x11 || true; pulseaudio --kill 2>/dev/null || \
  pkill -KILL -x pulseaudio || true; rm -f $TMPDIR/.X11-unix/X* \
  $TMPDIR/.X*-lock $TMPDIR/.pulse-*/native'
alias db='proot-distro login debian --shared-tmp --user ternux'
alias droot='proot-distro login debian --shared-tmp'
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

On SDK **31 or higher**, `false`/`0` means the readable global monitor is
disabled, `true`/`1` means enabled, and a blank or unknown value is
inconclusive. Signal 9 can also come from memory pressure or OEM battery
management. First set Termux and Termux:X11 battery use to **Unrestricted** and
reduce build parallelism. If child-process restrictions remain the supported
explanation, review the system-wide trade-off and use the control exposed by
your release:

- **Android 14+:** Settings → Developer options may provide **Disable child
  process restrictions**; OEM wording and availability vary. Reboot after a
  change.
- **Android 12L/13:** `adb shell settings put global settings_enable_monitor_phantom_procs false`
- **Android 12 exactly:** also review the `device_config` controls in
  [Troubleshooting](TROUBLESHOOTING.html#the-desktop-dies-silently).
- **Rooted:** `su -c "settings put global settings_enable_monitor_phantom_procs false"`

Record the original value and reverse the change if it causes abnormal battery
drain or instability.

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

| Observation | Interpretation |
|---|---|
| `zink … (MESA_TURNIP)` | tested Adreno Zink/Turnip route detected |
| `virgl` / `virpipe` | compatibility route detected; verify host acceleration and the workload separately |
| `llvmpipe` | CPU software rendering |
| blank/error | diagnose the display or GL stack first |

---

## Uninstalling

Use the scoped route so the target and confirmation are explicit:

```bash
ternux uninstall                 # interactive component choice
ternux uninstall container       # confirms before deleting Debian data
ternux uninstall all             # four scoped targets; back up first
```

`container` and `all` destroy every file inside Debian. `all` still leaves
Termux packages, the ternux CLI/libraries, repository/storage choices and the
Termux PulseAudio configuration. In automation, pass `--yes` only as an explicit
acknowledgement of irreversible container deletion.

---

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · MIT*
