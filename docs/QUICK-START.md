---
title: "Quick start"
description: "The shortest path from a bare Android phone to a ternux desktop, first launch, and renderer verification."
lang: "en"
alt_url: "/bn/docs/QUICK-START.html"
---

# Quick start

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
curl -fsSL https://soobujmiah.github.io/ternux/install.sh | bash
```

**curl broken after an upgrade?** Use wget — same installer:

```bash
wget -qO- https://soobujmiah.github.io/ternux/install.sh | bash
```

The installer:

1. checks the device (architecture, Android version, storage, network);
2. installs the Termux packages (X11, PulseAudio, PRoot);
3. installs **Debian + Xfce4** inside a PRoot container;
4. detects your GPU and picks the right driver
   (**Adreno → Zink/Turnip** · other → **VirGL**);
5. configures audio, fonts and locale;
6. writes the `x` launcher and shell shortcuts;
7. verifies everything landed.

Prefer to review all code before it runs? Clone the repository; reviewing only the bootstrap is incomplete because it otherwise downloads library modules at runtime.

```bash
pkg install git -y
git clone https://github.com/soobujmiah/ternux.git
cd ternux
git log -1 --oneline
(set -e; for f in install.sh uninstall.sh bin/ternux lib/*.sh; do bash -n "$f"; done)
less install.sh bin/ternux lib/*.sh
bash install.sh
```

## Step 3 — Start the desktop

```bash
source ~/.bashrc
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

### Ternux CLI — the management interface

After installation, the `ternux` command is your permanent control centre:

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

## Next

- [Installation](INSTALLATION.html) — every phase explained, all options, uninstall
- [Manual installation](MANUAL.html) — every command by hand, both GPU routes
- [Usage](USAGE.html) — Blender, local AI, development, backups
- [FAQ](FAQ.html) — safety, storage, battery, gaming

---

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · MIT*
