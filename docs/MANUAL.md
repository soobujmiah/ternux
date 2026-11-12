---
title: "Manual installation"
description: "Every ternux step done by hand, command by command — the complete walkthrough for readers who want full control or need to debug the installer itself."
lang: "en"
alt_url: "/bn/docs/MANUAL.html"

---

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
# Refresh the package index and upgrade what's there.
pkg update -y
pkg upgrade -y

# Repositories that carry the X11 and graphics packages.
pkg install x11-repo tur-repo -y

# The display app service, audio, and the container engine.
pkg install termux-x11-nightly -y
pkg install pulseaudio proot-distro util-linux -y

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


Ternux Camera and Ternux Sound Recorder are included in the Debian desktop. For Android front/rear photo capture, install the **Termux:API Android app from the same source as Termux** and allow Camera permission to Termux:API when prompted. Ternux Camera stages a capture in Termux app-private storage, validates it, then saves it inside Debian at `/home/ternux/Pictures/Ternux` (or the selected guest user’s home). It does not add photos to Android Gallery. The in-app photo preview follows EXIF orientation and uses compact capture controls. Termux:API currently provides camera information and still photos, not a continuous camera stream; the app therefore does not show a live feed before capture. Ternux Sound Recorder uses the same Termux:API bridge only after the user presses Start; Android microphone permission is requested during installation when Termux:API is available; otherwise Android prompts on first use. Choose AAC/M4A (default) or MP3 before recording. Stop and save writes the selected format into the Debian user’s `~/Music/Ternux` folder. MP3 is encoded locally with FFmpeg; Android microphone capture itself is AAC.

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
apt install -y sudo nano mousepad fonts-noto-core python3-gi python3-xlib gir1.2-gtk-3.0 ibus ibus-avro devilspie2 dbus-x11 pulseaudio pulseaudio-utils pavucontrol x11-utils mesa-utils libgl1-mesa-dri adwaita-icon-theme xfce4 xfce4-taskmanager xfce4-terminal zenity vlc ristretto qt5-gtk-platformtheme arc-theme colord

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

<h3 id="zink-turnip-adreno">6a — Zink + Turnip (Adreno)</h3>

On Debian, Ternux selects and checksum-verifies the matching ARM64 Turnip
archive, records its upstream license notices, and installs it in the managed
`/usr/local` layout. Use the normal installer:

```bash
tx install --distro debian
```

Do not extract a Mesa bundle into `/usr` or overwrite files owned by the guest
package manager. For a manually repaired or older install, follow the
[apt-safe graphics migration guide](GRAPHICS-PERSISTENCE.html), which includes
checks for package integrity and the active Vulkan renderer.

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
SOURCE='load-module module-sles-source source_name=Ternux_Microphone'
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
    { grep -qxF "$SOURCE" "$TMP" || printf '%s\n' "$SOURCE" >> "$TMP"; } &&
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

Ternux also loads an on-demand Android OpenSL ES microphone source named
`Ternux_Microphone`. It stays suspended until a desktop audio client requests
capture. Android controls permission; if capture is denied, grant **Microphone**
permission to Termux in Android Settings, then retry. In Xfce, open
**PulseAudio Volume Control → Input Devices** and select `Ternux_Microphone`.
Android's microphone privacy indicator appears while capture is active. The
current Termux:API `termux-microphone-record` command records to a file; it does
not provide the live PulseAudio source used by desktop apps, so Ternux does not
claim to route live desktop capture through that API.

During installation, Ternux makes one bounded, private one-second
termux-microphone-record probe so Android can request the Termux:API app's
microphone permission. The temporary file is removed after the probe. This
permission belongs to Termux:API; it does not grant the separate Termux app
permission used by the desktop's OpenSL ES source, and it does not create a
live API-to-PulseAudio stream. Desktop microphone capture remains on-demand and
uses the OpenSL ES source above.

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
# The launcher exports the selected loopback PulseAudio endpoint to desktop apps.

# Nerd Font for terminal icon glyphs (best-effort).
mkdir -p ~/.local/share/fonts
font_archive=$(mktemp /tmp/ternux-jetbrainsmono.XXXXXX.tar.xz)
wget -q -O "$font_archive" \
  https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/JetBrainsMono.tar.xz \
  && echo "04d5e8f903693f9dd13e16f867e994834e681eb3c72c0d337a770dcda09010cf  $font_archive" | sha256sum -c - \
  && tar -xJf "$font_archive" -C ~/.local/share/fonts/ \
  && fc-cache -f
rm -f "$font_archive"

exit
```

---

<h2 id="create-launcher">Step 8 — Start the managed desktop</h2>

The installer creates and maintains `~/x.sh`. Start the desktop through the
Ternux lifecycle manager so it can validate readiness and refresh an older
launcher safely:

```bash
ternux start
```

The `x` shortcut runs the same command. Managed guests expose Android shared
storage at `/sdcard` by default when Termux has storage permission. Run
`termux-setup-storage` once if the path is missing, then restart the guest. Files
remain on Android shared storage and are not copied into the container. Do not copy older `proot-distro login
--shared-tmp` launcher examples into `~/x.sh`; those use PRoot-Distro's broader
host mounts. If `ternux start` says the launcher is missing, resume the Ternux
installer with `ternux install`.

---

## Step 9 — Shell shortcuts

The installer creates and maintains the `tx`, `x`, `killx`, `db`/`dbroot`, `ub`/`ubroot`, `alp`/`alproot`, `xgo`,
`clean-mesa` and `sysmon` shortcuts. The guest aliases use isolated PRoot
bindings, mount Android shared storage at `/sdcard`, and share `/tmp` only for
commands that need it. Run `ternux install` to create or refresh the generated aliases; do not
copy an older alias block from a previous guide.

Reload and start:

```bash
source ~/.bashrc
```

```bash
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

## Optional tools and release extensions

This command-by-command route sets up the Termux/PRoot desktop; it does not
install Ternux's managed host CLI. For Debian package workloads and their manual
commands, see [Workloads](WORKLOADS.html). For ADT, follow the
[ADT setup section](INSTALLATION.html#install-adt-tools-inside-the-ternux-debian-guest).

The CPU + Vulkan prerelease has a separate
[manual, checksum-verified installation guide](https://github.com/soobujmiah/ternux/blob/main/guides/llama-vulkan-extension.md).
The experimental HTP package uses `ternux extension install` from the Termux
host and is not part of this manual-only setup; read the
[HTP limits and installation guide](https://github.com/soobujmiah/ternux/blob/main/guides/llama-htp-experimental.md)
before using it. Stable Diffusion/QNN remains a standalone experiment, not an
installable Ternux extension.

---

## Uninstalling

If you used the one-command installer and have the Ternux CLI, use its scoped
uninstaller:

```bash
ternux uninstall                 # interactive component choice
ternux uninstall container       # confirms before deleting the selected guest
ternux uninstall all             # removes all Ternux-managed guests, CLI and state
```

`container` removes the selected guest; `all` removes every Ternux-managed
profile guest and generic image guest registered by Ternux. A failed guest removal
preserves the CLI/state so cleanup can be retried. Both preserve Termux itself,
shared Termux packages, unrelated PRoot guests, Android shared storage and user files. In automation, pass `--yes` only as an explicit
acknowledgement of irreversible container deletion.

The manual-only steps above do not install that CLI. To remove a manual setup,
run the scoped uninstaller from Termux:

```bash
curl -fsSL https://soobujmiah.github.io/ternux/uninstall.sh | bash
```

It prompts for the cleanup targets. Review each target before confirming.

---

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · Apache-2.0*
