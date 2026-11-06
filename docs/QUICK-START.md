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

**curl broken after an upgrade?** Use wget — same installer:

```bash
wget -qO- https://raw.githubusercontent.com/soobujmiah/ternux/main/install.sh | bash
```

With a controlling terminal, the one-command installer also offers a numbered optional-workload chooser. Press Enter for the base desktop, enter a comma-separated selection such as `1,5`, or choose `6` for all optional workloads. In a non-interactive run, use `--yes` to keep the base profile.

The installer:

1. checks the device (architecture, Android version, storage, network);
2. installs the Termux packages (X11, PulseAudio, PRoot);
3. installs **Debian + Xfce4** inside a PRoot container;
4. detects your GPU and picks the right driver
   (**Adreno → Zink/Turnip** · other → **VirGL**);
5. configures audio, fonts and locale;
6. writes the `x` launcher and shell shortcuts;
7. verifies everything landed.

Expect about **4–4.5 GB installed** for base or **10.5–12.5 GB** with `--all`; keep
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

The `x` shortcut launches: audio bridge → display (`Termux:X11`) → Debian →
**Xfce4**. Switch to the Termux:X11 app — your desktop is there.

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
db         shell inside Debian (user) droot   shell as root
xgo        auto-open Termux:X11 + x   sysmon  device resource overview
clean-mesa clear the Mesa shader cache
```

### First GUI run, browser and video

After a fresh install, the first GUI session opens the Ternux project page in
Firefox ESR if it is installed. Without a browser, it shows a one-time welcome
guide with project/developer links, guest commands and the host benchmark
command. This happens once per guest user; later desktop boots do not redirect
to the website. Firefox remains optional; choose it from the installer’s
optional software list.

Noto Bengali fonts and the Avro IBus phonetic keyboard are installed by default;
press **Ctrl+Space** to switch between English and Bangla. VLC, PulseAudio Volume Control, the Xfce Task
Manager, and Mousepad text editor are included in the base desktop. The global Adwaita Dark GTK theme and lightweight stock Adwaita icons are selected by
default for a modern, high-contrast desktop, with a custom Aurora wallpaper. The first-run guide adapts to the available screen and uses a reliable software renderer. VLC defaults to a compact mobile view, X11 `xcb_x11` output and software decoding because PRoot does not provide VAAPI/VDPAU; this
avoids blank video caused by selecting unavailable host decoder paths.

### Ternux CLI — the management interface

After installation, the `ternux` command is your permanent control centre. Run
the full commands below in **Termux** (`$PREFIX/bin/ternux`):

```bash
ternux doctor           # system diagnostics
ternux start            # start the desktop
ternux stop             # stop the desktop
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
- **Shared storage** between Android and Debian (`~/storage` in Termux ↔
  `/sdcard` inside the container).

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

Then in Debian, use the model directly from `/sdcard/Llms` on CPU or Adreno Vulkan:

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
The tiled 512×512/10-step run saved a complete image in 101.9s. The CPU
256×256/10-step output saved but was blocky; CPU image quality is not qualified.
The extension does not bundle models or GPU drivers; see the [extension guide](https://github.com/soobujmiah/ternux/blob/main/guides/stable-diffusion-vulkan-extension.md) for limits.

### Experimental Hexagon HTP on SM8735

Ternux also lists a separate experimental HTP extension for the Redmi Turbo 4
Pro / SM8735. It is not a supported release feature. Install from Termux with
`ternux extension install llama-htp-experimental`; the Debian guest needs
`libgbinder1`, `libglibutil1`, `libfastrpc1`, and `libfastrpc-dev`. Selecting HTP
in the installer provisions these packages from Debian Trixie Backports. Its
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
