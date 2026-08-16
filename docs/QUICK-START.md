---
title: "Quick start"
description: "The fastest path from a bare Android phone to a verified, GPU-accelerated ternux desktop — about ten minutes."
lang: "en"
alt_url: "/bn/docs/QUICK-START.html"

---

# Quick start

Ten minutes, three steps, one desktop. This page assumes nothing except a
working Android phone.

---

## Step 0 — Install two apps (2 minutes)

1. **Termux** — the host terminal.
   Download the APK from [GitHub releases](https://github.com/termux/termux-app/releases)
   or install via [F-Droid](https://f-droid.org/en/packages/com.termux/).
   *Why not the Play Store build? It was abandoned years ago — its package
   repositories are dead and nothing installs.*
2. **Termux:X11** — the app that displays the desktop.
   Download from [GitHub releases](https://github.com/termux/termux-x11/releases).
   Open it **once** so Android registers it, then leave it.

## Step 1 — Run one command (5–15 minutes)

Open Termux and paste:

```bash
curl -fsSL https://soobujmiah.github.io/ternux/install.sh | bash
```

curl broken after an upgrade? Same thing with wget:

```bash
wget -qO- https://soobujmiah.github.io/ternux/install.sh | bash
```

The installer:

1. checks the device (architecture, Android version, storage, network);
2. installs Termux packages (X11, PulseAudio, PRoot);
3. installs **Debian + Xfce4** inside a PRoot container;
4. detects your GPU and installs the right driver
   (**Adreno → Zink/Turnip** · other → **VirGL**);
5. configures audio, fonts and locale;
6. writes the launcher and shell shortcuts;
7. verifies everything landed.

It answers its own questions with sensible defaults in non-interactive mode;
add `--yes` to accept them explicitly. Prefer to read first?

```bash
curl -fsSL https://soobujmiah.github.io/ternux/install.sh -o install.sh && less install.sh
bash install.sh
```

## Step 2 — Start the desktop (30 seconds)

```bash
source ~/.bashrc
x
```

The `x` shortcut launches: audio bridge → display (`Termux:X11`) → Debian →
**Xfce4**. Switch to the Termux:X11 app — your desktop is there.

## Step 3 — Prove the GPU is real (30 seconds)

Open a terminal inside the desktop (right-click → *Open Terminal Here*) and
run:

```bash
glxinfo | grep "renderer string"
```

| Expected | Meaning |
|---|---|
| `zink Vulkan (Adreno (TM) … (MESA_TURNIP))` | ✅ hardware GPU path (Adreno) |
| `virgl` | ✅ hardware GPU path (compatibility) |
| `llvmpipe` | ❌ software rendering — fix it, don't live with it |

If you see `llvmpipe`, the desktop still works but graphics are software-only.
Jump to
[Troubleshooting → renderer says llvmpipe](TROUBLESHOOTING.html#renderer-says-llvmpipe).

---

## What you now have

### Classic shell shortcuts

```text
x        start the desktop          killx  stop everything cleanly
db       shell inside Debian (user) droot  shell as root
xgo      auto-open Termux:X11 + x   ai     chat with a local model
sysmon   device resource overview   clean-mesa  clear shader cache
```

### Ternux CLI — the management interface

After installation, the `ternux` command is your permanent control centre:

```bash
ternux doctor           # system diagnostics
ternux doctor --json    # AI-readable structured output
ternux start            # start the desktop
ternux stop             # stop the desktop
ternux repair           # auto-fix common issues
ternux verify           # verify installation
ternux benchmark        # GPU benchmarks
ternux backend set virgl  # switch GPU backend
ternux info             # system information
ternux state            # installation state
ternux logs             # view log files
ternux update           # self-update
ternux uninstall        # remove components
```

Every command supports `--help`, `--json`, `--verbose`, and `--quiet`.
For complete reference: [CLI Reference](CLI.md).

- A full **Debian desktop** in a container — installed, not emulated.
- **Hardware-accelerated graphics** for OpenGL apps (Blender, games, GL tools).
- **Sound** bridged to the phone speakers/headphones.
- **Shared storage** between Android and Debian (`~/storage` in Termux ↔
  `/sdcard` inside the container).

## Android 12+? One important note

Android's **phantom process killer** silently kills background processes and
can end your desktop session with no error. The installer prints the exact
fix at the end — on Android 14+ it's one Developer-Options toggle
(*Disable child process restrictions*). Full details in
[Troubleshooting](TROUBLESHOOTING.html#the-desktop-dies-silently).

## Next

- [Manual installation](MANUAL.html) — every command by hand, both GPU routes
- [Installation](INSTALLATION.html) — every phase explained, all options, uninstall
- [Usage](USAGE.html) — Blender, local AI, development, backups
- [FAQ](FAQ.html) — safety, storage, battery, gaming

---

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · MIT*
