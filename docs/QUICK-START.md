---
title: "Quick start"
description: "The shortest path from a bare Android phone to a ternux desktop, first launch, and renderer verification."
lang: "en"
alt_url: "/bn/docs/QUICK-START.html"
---

Four steps from Android apps to an installed desktop and renderer check. Download time varies with the device, mirrors and network.

---

## Step 1 — Install two apps

1. **Termux** — the host terminal.
   Download the APK from [GitHub releases](https://github.com/termux/termux-app/releases)
   or [F-Droid](https://f-droid.org/en/packages/com.termux/).
   This guide uses the main F-Droid/GitHub release line. The Google Play line
   is separate and experimental; do not mix Termux/plugin sources.
2. **Termux:X11** — the app that displays the desktop.
   Download from [GitHub releases](https://github.com/termux/termux-x11/releases).
   Open it **once** so Android registers it, then leave it.

## Step 2 — Run the installer

Open Termux and paste:

```bash
curl -fsSL https://raw.githubusercontent.com/soobujmiah/ternux/main/install.sh | bash
```

**curl broken after an upgrade?** Try wget directly; it runs the same installer:

```bash
wget -qO- https://raw.githubusercontent.com/soobujmiah/ternux/main/install.sh | bash
```

If neither downloader starts, run `apt update && apt full-upgrade` to finish
the Termux package upgrade, then retry. A partial upgrade can leave curl and
its OpenSSL libraries out of sync.

With a controlling terminal, first choose one or more named guest profiles in the checklist: move with Up/Down or `j`/`k`, press Space or a profile number to toggle a selection, then Enter to continue. Debian is the recommended default. **Ternux v2 supports Debian, Ubuntu, and Alpine only.** Those three have desktop, graphics, audio routing, IBus setup and theme evidence on one Adreno 825 device; clean Firefox installation passed exact-main CI. Alpine has an unresolved synthetic Ctrl+Space event discrepancy, and this does not qualify every app. The other 12 recipes remain available but are not v2-supported. The next checklist selects optional workloads; press Enter or `0` for the base desktop, or choose the displayed numbers. In a non-interactive run, `--yes` keeps the Debian base profile. See [all guest profiles and package-family recipes](INSTALLATION.html#choosing-a-guest-distribution).

The installer:

1. checks the device (architecture, Android version, storage, network);
2. installs the Termux packages (X11, PulseAudio, PRoot);
3. installs the selected guest profile + Xfce4 inside its PRoot container (Debian by default);
4. selects a graphics route for the guest profile
   (**Adreno/KGSL → native distro Zink/Freedreno where packaged** · Debian uses validated Turnip · VirGL compatibility route);
5. configures audio, fonts and locale;
6. writes the `x` launcher and shell shortcuts;
7. verifies everything landed.

Expect about **4–4.6 GB installed** for base or **10.5–12.5 GB** with `--all`; keep
additional temporary space for downloads and caches. One persistent screen shows
the device panel, step progress and a live log window until the final status; a
terminal that cannot host it gets a plain framed log instead. Both record the
complete output — see
[The installer screen](INSTALLATION.html#the-installer-screen).

Prefer to review all code before it runs? Clone the repository; reviewing only the bootstrap is incomplete because it otherwise downloads library modules at runtime.

```bash
pkg install git -y
git clone https://github.com/soobujmiah/ternux.git
cd ternux
git log -1 --oneline
(set -e; for f in install.sh uninstall.sh bin/ternux bin/ternux-guest lib/*.sh; do bash -n "$f"; done)
less install.sh bin/ternux bin/ternux-guest lib/*.sh
bash install.sh
```

## Step 3 — Start the desktop

```bash
source ~/.bashrc
```

```bash
x
```

The `x` shortcut launches: audio bridge → display (`Termux:X11`) → selected guest →
**Xfce4**. Switch to the Termux:X11 app — your selected guest desktop is there.

## Step 4 — Verify the renderer

Open a terminal inside the desktop (right-click → *Open Terminal Here*):

```bash
glxinfo | grep "renderer string"
```

| Expected | Meaning |
|---|---|
| `zink Vulkan (Adreno (TM) … (MESA_TURNIP))` | ✅ hardware GPU path (Adreno) |
| `virgl` / `virpipe` without `llvmpipe` | ✅ VirGL compatibility path is active; performance varies |
| `llvmpipe` | ❌ CPU software rendering — troubleshoot before benchmarking |

If you see `llvmpipe`, the desktop still works but graphics are software-only.
Jump to [Troubleshooting → renderer says llvmpipe](TROUBLESHOOTING.html#renderer-says-llvmpipe).

---

## What you now have

### Classic shell shortcuts

```text
x          start the desktop          killx   stop everything cleanly
tx         short alias for ternux     xgo     choose an installed GUI guest
db / dbr / dbroot  Debian user / root shell    ub / ubr / ubroot  Ubuntu user / root shell
alp/alpr/alproot Alpine user / root shell    sysmon  device resource overview
clean-mesa clear the Mesa shader cache
```

### First GUI run, browser and video

After a fresh install, the first GUI session opens the Ternux project page in the
included Firefox ESR. The one-time welcome also provides project/developer links,
guest commands and the host benchmark command. It appears once per guest user;
later desktop boots do not redirect to the website. Debian-family guests use their
native Firefox ESR package; Ubuntu uses Mozilla’s official Linux build because its
archive Firefox package depends on Snap, which Ternux disables in PRoot.

Noto Bengali fonts and Avro phonetic input are installed by default. The IBus **Next input method** shortcut is **Ctrl+Space**, cycling between English and Bangla. Ternux synchronizes IBus's engine order with its preload list and registers an XFCE fallback for apps without an IBus input context. Alpine installs the Avro-compatible m17n engine from a checksum-pinned upstream source because Alpine does not publish an IBus Avro package; Ctrl+Space is the keyboard switch, with no extra panel button. A shared X11 window-fit service keeps newly opened windows inside each guest's phone-sized work area. Firefox browser, VLC, PulseAudio Volume Control, Xfce Task Manager, Mousepad, Galculator, Evince PDF reader, Ternux Camera, Ternux Sound Recorder, Ristretto, and **Synaptic Package Manager** are included in the base desktop. Synaptic uses the Ternux icon and theme; open it from the Applications menu to browse, install, upgrade, or remove Debian packages. Evince opens PDFs by default; optional LibreOffice Draw provides PDF page editing and export to other formats. No mail client is installed or set as default. Evolution Mail is optional; choose it from the workload selector when needed. It supports common-provider OAuth and manual IMAP/POP setup, opening Firefox ESR or the Android default browser through Ternux for OAuth. The Xfce lower panel has the same eight launchers in Debian, Ubuntu, and Alpine: Terminal, File Manager, Web Browser, Application Finder, VLC, Camera, Photos, and Sound Recorder. Camera, Photos, and Sound Recorder also have desktop shortcuts; Ternux Flashlight has a desktop shortcut that toggles the Android torch.

The systemwide Ternux graphite-and-emerald GTK 2/3/4 theme styles applications, menus, and the Xfce panel; Qt 5 apps use the GTK platform theme; custom Ternux Xfwm frames style window borders and title bars; GTK client-side titlebar buttons use matching visible controls too. Original Ternux icons cover the base apps, folders, Thunar actions, categories, and panel. Adwaita supplies neutral fallback icons for uncommon or newly installed applications; Papirus is not inherited. Fifteen original portrait-first Ternux wallpapers are selectable in Xfce Desktop settings. Xfce keeps their aspect ratio in landscape; 05 Quantum Grid is the default.

Ternux Camera lists Android front and rear cameras and captures photos through Termux:API. Allow Camera permission to the Termux:API Android app when Android asks. Camera listing can succeed without capture permission; if capture reports a permission error, allow it under Android Settings → Apps → Termux:API → Permissions → Camera and retry. The Flashlight toggle uses Termux:API torch support on devices with a camera flash. It is a continuous torch, not a photo-flash mode; Ternux turns it off before capture because Termux:API still-photo capture has no flash setting. The app previews each photo with EXIF orientation corrected and saves it inside Debian at `~/Pictures/Ternux`; its capture is staged privately in Termux home and copied into PRoot. No Android Gallery scan is performed. Ristretto opens the photos. Termux:API provides still-photo capture, not a continuous camera stream, so the app does not show a live camera feed before capture. Ternux Sound Recorder requests microphone access only when you press Start (Android permission is requested during setup when the API is available; otherwise it prompts on first use). Choose AAC/M4A (default) or MP3, then press Stop and save; files stay at `~/Music/Ternux` inside Debian. MP3 export uses FFmpeg locally.

The first-run guide adapts to the available screen and uses a reliable software renderer. VLC defaults to a compact mobile view, X11 `xcb_x11` output, and software decoding because PRoot does not provide VAAPI/VDPAU; this avoids blank video caused by selecting unavailable host decoder paths.

### Ternux CLI — the management interface

After installation, the `ternux` command is your permanent control centre. Run
the full commands below in **Termux** (`$PREFIX/bin/ternux`):

```bash
ternux doctor           # system diagnostics
ternux start            # start the desktop
tx stop                 # list running desktops and choose one or more
tx stop db              # stop Debian only
tx stop ub              # stop Ubuntu only
tx stop alp             # stop Alpine only
tx stop --all          # stop every Ternux desktop
ternux repair           # auto-fix common issues
ternux verify           # verify installation
ternux benchmark        # GPU benchmarks
ternux info             # system information
ternux update           # self-update
ternux uninstall        # remove components
```

Inside the Debian/Xfce terminal, `/usr/local/bin/ternux` provides guest-local
`status`, `info`, `doctor`, and `env`. It rejects host lifecycle commands to
prevent nested PRoot; return to Termux for `start`, `stop`, `repair`, or `update`.

The dispatcher recognizes global flags including `--help`, `--json`, `--verbose`,
and `--quiet`, but structured output is command-specific. Use `--json` only where
it is documented in the [CLI Reference](CLI.html).

- A full **Debian desktop** in a PRoot userland on the phone's native ARM64 CPU.
- A configured **Zink/Turnip or VirGL graphics route** for OpenGL apps; verify
  the actual renderer rather than assuming acceleration.
- **Sound** bridged to the phone speakers/headphones.
- **Android shared storage** is available at `/sdcard` in each Ternux guest by
  default. If it is missing, grant Termux Android storage permission with
  `termux-setup-storage` and restart the guest.

## Android 12+? One important note

Android 12+ child-process policy can terminate PRoot processes, while memory
pressure and OEM battery management can look identical. The installer reports
readable settings and links version-aware guidance; review the system-wide
trade-off before changing a safeguard. Full details in
[Troubleshooting](TROUBLESHOOTING.html#the-desktop-dies-silently).

## Optional: local CPU + Vulkan language model

The published ARM64 llama.cpp extension is a prerelease. In **Termux**, install
it with:

```bash
ternux extension install llama-vulkan
```

The Debian guest needs glibc 2.38 or newer plus OpenSSL 3 (`libssl3` or
`libssl3t64`), `libgomp1`, and `libvulkan1`; the installer checks these before
downloading.

Then open Debian with `db`, load the extension, and choose CPU or Vulkan:

```bash
source "$HOME/.local/opt/ternux-extensions/llama-vulkan/env.sh"
llama-cli --list-devices
llama-cli -m /path/to/model.gguf -ngl 0 -p 'What is 2 + 2?' -n 8
llama-cli -m /path/to/model.gguf -dev Vulkan0 -ngl 99 -p 'What is 2 + 2?' -n 8
```

Keep your GGUF model wherever it already is. Vulkan needs a working system
Vulkan driver. For the manual install route, checksum and archive checks, backend
details, and recovery steps, see the [repository extension guide](https://github.com/soobujmiah/ternux/blob/main/guides/llama-vulkan-extension.md).

## Optional: Stable Diffusion CPU + Vulkan image generation

From Termux, install the pinned image-generation runtime:

```bash
ternux extension install stable-diffusion
```

Grant the model folder from Termux, then in Debian use it directly on CPU or Adreno Vulkan:

```bash
ternux storage grant /sdcard/Llms
```

Open a new guest shell or restart the desktop for the mount to appear:

```bash
source "$HOME/.local/opt/ternux-extensions/stable-diffusion/env.sh"
MODEL=/sdcard/Llms/ternux-v2-validation/stable-diffusion-v1-5-pruned-emaonly-Q8_0.gguf

# CPU low-resolution test; it can take several minutes
sd-cli --backend cpu --model "$MODEL" --prompt "a small red robot in a garden, clean illustration" \
  --threads 4 --output /tmp/ternux-sd-cpu.png --width 256 --height 256 --steps 20 --seed 42

# Adreno GPU: VAE tiling is needed at 512x512
sd-cli --backend vulkan0 --model "$MODEL" --prompt "a small red robot in a garden, clean illustration" \
  --threads 4 --output /tmp/ternux-sd-vulkan.png --width 512 --height 512 --steps 10 --seed 42 \
  --vae-tiling --vae-tile-size 256x256
```

On Adreno 825, an untiled 512×512 Vulkan run lost the device during VAE decode.
The extracted candidate saved a tiled 512×512/10-step image in 101.9s. After
public prerelease publication, the Ternux-managed install also generated a
coherent image from the same `/sdcard/Llms` model in 92.91s. CPU output remains
unqualified and is not claimed; see the [device handoff](../handoffs/stable-diffusion-cpu-vulkan-qualification-2026-11-07.md).
The extension does not bundle models or GPU drivers; see the [extension guide](https://github.com/soobujmiah/ternux/blob/main/guides/stable-diffusion-vulkan-extension.md) for limits.

### Experimental Hexagon HTP on SM8735

Ternux also lists a separate experimental HTP extension for the Redmi Turbo 4
Pro / SM8735. It is not a supported release feature. Install from Termux with
`ternux extension install llama-htp-experimental`; the managed command first
provisions `libgbinder1`, `libglibutil1`, `libfastrpc1`, and `libfastrpc-dev`
from Debian Trixie Backports, then verifies and installs the extension. Selecting
HTP in the installer uses the same dependency setup. Its
known-answer-safe settings,
current failures, and device qualification status are in the
[repository HTP guide](https://github.com/soobujmiah/ternux/blob/main/guides/llama-htp-experimental.md).

## Next

- [Installation](INSTALLATION.html) — every phase explained, all options, uninstall
- [Manual installation](MANUAL.html) — every command by hand, both GPU routes
- [Usage](USAGE.html) — Blender, local AI, development, backups
- [FAQ](FAQ.html) — safety, storage, battery, gaming

---

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · Apache-2.0*
