---
title: "Installation"
description: "The complete ternux installation guide: requirements, the one-command installer, what each of the 11 phases does, every option, and clean removal."
lang: "en"
alt_url: "/bn/docs/INSTALLATION.html"
---

# Installation

The complete guide. For the ten-minute version, see
[Quick start](QUICK-START.html).

> **Prefer to run every command yourself?** The command-by-command
> walkthrough — both GPU routes, the full launcher file — is the
> [Manual installation](MANUAL.html) page. The one-command installer below
> is that same page, scripted.

---

## Requirements

| | Recommended baseline | Why it matters |
|---|---|---|
| **Android** | 10 or newer | Older builds lack the APIs Termux/X11 rely on |
| **CPU** | `aarch64` (64-bit ARM) | PRoot runs native binaries; 32-bit ARM is unsupported upstream |
| **Storage** | ~12 GB free | ~6 GB base rootfs + packages; models and projects add more |
| **RAM** | 4 GB min, 6–8 GB preferred | The desktop + Android share memory; less RAM = more killing |
| **Graphics** | Adreno (best) or any GPU | Adreno gets Zink/Turnip; everything else uses VirGL |
| **Apps** | Termux (F-Droid/GitHub) + Termux:X11 | The Play Store Termux build is abandoned |

Check your device first (read-only, changes nothing):

```bash
uname -m                              # expect: aarch64
getprop ro.product.manufacturer       # e.g. Qualcomm
getprop ro.product.model
getprop ro.build.version.release      # e.g. 14
df -h "$HOME"                         # free space
ls -l /dev/kgsl-3d0 2>&1              # exists → Adreno → Zink/Turnip path
```

`/dev/kgsl-3d0` present means the installer picks the fast Zink/Turnip route.
Missing means VirGL — still hardware-backed, just a different route.

---

## Method 1 — One command (recommended)

```bash
curl -fsSL https://soobujmiah.github.io/ternux/install.sh | bash
```

This downloads the installer over HTTPS and runs it. It is the same script
that lives in this repository — nothing hidden, nothing compiled.

**curl broken after an upgrade?** A partial upgrade can leave curl and
openssl out of sync. Use wget — same installer, and the script repairs curl
for you:

```bash
wget -qO- https://soobujmiah.github.io/ternux/install.sh | bash
```

### Why we also document Method 2

Piping `curl` into `bash` is convenient, but for a script that touches your
device it's good practice to **read it first**. Method 2 takes ten seconds
longer:

```bash
curl -fsSL https://soobujmiah.github.io/ternux/install.sh -o install.sh
less install.sh     # skim it — it is one file, organised in phases
bash install.sh
```

Both methods behave identically. If the download is interrupted, run it again
— every phase is idempotent, and `--resume` skips completed work.

### Method 3 — fully manual

For total control — or to debug the installer itself — the
[Manual installation](MANUAL.html) page walks through every single command:
base packages, the container, the GPU driver for both routes, the complete
`~/x.sh` launcher file, and verification. Methods 1 and 2 run those same
steps for you.

---

## What the installer does (and why, phase by phase)

The installer runs as **11 verified phases**. Each phase checks its own work
before the next one starts — a failed phase stops the install with a clear
message instead of producing a half-broken desktop.

| # | Phase | What it does | Why |
|---|---|---|---|
| 1 | **Preflight** | Checks Termux, architecture, Android version, storage, network | Fail here and you waste no downloads; every later phase depends on these facts |
| 2 | **Base packages** | Installs `x11-repo`, `termux-x11`, `pulseaudio`, `proot-distro`, `virglrenderer-android`, tools; requests storage permission | These are the host-side services the container needs: display, sound, and the container engine |
| 3 | **CLI installation** | Installs the `ternux` command and libraries to `$PREFIX/bin/` | The `ternux` command becomes available for diagnostics, repair, and desktop management |
| 4 | **Debian + Xfce4** | Installs the Debian rootfs, desktop packages, creates your user with passwordless sudo | The desktop you actually use; sudo is validated so a typo can never lock the container |
| 5 | **GPU driver** | Adreno: downloads the Turnip driver, validates the archive, installs it, pins Mesa packages. Other: confirms the VirGL host renderer | Without this every GL app renders on the CPU (`llvmpipe`). Pinning prevents a routine `apt upgrade` from silently reverting the GPU path |
| 6 | **Audio, locale, fonts** | Bridges PulseAudio loopback-only, generates your locale, installs emoji/powerline/Nerd fonts | Sound crosses the container boundary over TCP — loopback only. Fonts avoid tofu boxes in the terminal |
| 7 | **Launcher** | Writes `~/x.sh` tuned to your GPU route, syntax-checks it | One command (`x`) must reliably start audio → display → desktop in the right order |
| 8 | **Shortcuts** | Installs `x`, `killx`, `db`, `droot`, `xgo`, `ai`, `sysmon`, `clean-mesa` | Daily operation should be muscle memory, not archaeology |
| 9 | **Optional extras** | Dev tools, llama.cpp, network tools, media tools, Blender — only what you asked for | Keep the base install lean; each profile has different storage/thermal costs |
| 10 | **Phantom-killer check** | Detects Android 12+ background-process restrictions, prints the exact fix | The #1 silent killer of long desktop sessions — know it exists *before* it eats your build |
| 11 | **Verification** | Confirms every critical binary, file and permission actually landed | Trust, but verify — `apt` succeeding is not proof the desktop will launch |

---

## Installer options

```bash
bash install.sh                     # interactive — asks before each big step
bash install.sh --yes               # accept all defaults, no questions
bash install.sh --user soobuj       # Debian user name (default: ternux)
bash install.sh --locale bn_BD.UTF-8
bash install.sh --backend zink      # force Zink/Turnip (Adreno only)
bash install.sh --backend virgl     # force the universal compatibility path
bash install.sh --zsh               # also switch the Termux shell to zsh
bash install.sh --with-dev          # Git, Node.js, Python, build tools
bash install.sh --with-llm          # llama.cpp + Vulkan (local AI)
bash install.sh --with-network      # nmap, tmux (authorised testing only)
bash install.sh --with-media        # ffmpeg, GIMP, Audacity, ImageMagick
bash install.sh --with-blender      # Blender (lightweight scenes)
bash install.sh --all               # every optional profile
bash install.sh --resume            # continue after an interruption
bash install.sh --version           # show version
bash install.sh --help              # show help
```

After installation, use the `ternux` CLI for diagnostics and management:

```bash
ternux doctor           # diagnose
ternux repair           # diagnose and fix
ternux state            # what is done, what is pending
ternux uninstall        # interactive removal
ternux update           # self-update the CLI
```

### Choosing a GPU backend

| Your GPU | Backend | Expectation |
|---|---|---|
| Qualcomm Adreno | `auto` → **zink** | Fastest — OpenGL apps run through Zink → Vulkan → Turnip |
| Mali / Xclipse / PowerVR / other | `auto` → **virgl** | Hardware-backed via the host renderer; slower than Turnip |
| Adreno, but the driver download fails | `--backend virgl` | Reliable fallback |

Forcing `zink` on a non-Adreno device fails loudly in preflight rather than
producing a silently-software desktop. That failure is intentional.

---

## After the install

```text
1. Open Termux:X11 once and leave it running.
2. source ~/.bashrc
3. x                 ← starts the desktop
```

Run a full diagnostic:

```bash
ternux doctor
ternux doctor --json    # AI-readable output
```

Then verify the graphics path from a desktop terminal:

```bash
glxinfo | grep "renderer string"
vulkaninfo --summary | grep -i driverName     # Adreno: expect "Turnip"
```

Back up the working state before adding large models or experimental
packages:

```bash
proot-distro backup debian --output ~/debian-backup.tar.gz
```

---

## Updating

- **The ternux CLI:** `ternux update` fetches the latest version from GitHub.
- **The installer itself:** re-download and re-run. Every phase is idempotent,
  and `--resume` skips completed phases. Your container and files are kept.
- **Debian packages:** `sudo apt update && sudo apt upgrade` inside the
  desktop. Mesa packages are held (`apt-mark hold`) on the Zink route on
  purpose — upgrading them can silently switch you back to software
  rendering. Unhold deliberately, not accidentally:
  `sudo apt-mark unhold mesa-vulkan-drivers libgl1-mesa-dri libglx-mesa0 libgbm1 libegl-mesa0`.

---

## Uninstalling

```bash
ternux uninstall                    # preferred — interactive removal
# or
curl -fsSL https://soobujmiah.github.io/ternux/uninstall.sh | bash
# or
bash install.sh --uninstall
```

Options include stopping the session, removing the launcher/shortcuts, and
deleting the container. **Everything ternux owns lives inside Termux's
storage** — Android's files are never touched. Deleting Termux's app data is
the nuclear option that removes everything at once.

---

## Troubleshooting

Desktop won't start? Renderer says `llvmpipe`? No audio?
See [Troubleshooting](TROUBLESHOOTING.html) — every symptom maps to a cause
and a fix.

---

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · MIT*
