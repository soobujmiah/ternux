---
title: "Installation"
description: "The complete ternux installation guide: requirements, the one-command installer, what each of the 11 phases does, every option, and clean removal."
lang: "en"
alt_url: "/bn/docs/INSTALLATION.html"
---

The complete guide. For the concise path, see
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
| **Storage** | Installed: ~3–4 GB base; ~10–12 GB with `--all` | Begin with additional free space for downloads, package caches, build trees, models and projects |
| **RAM** | 4 GB min, 6–8 GB preferred | The desktop + Android share memory; less RAM = more killing |
| **Graphics** | Adreno preferred; VirGL fallback otherwise | Zink/Turnip requires the Qualcomm KGSL path; VirGL compatibility varies by device/Android build |
| **Apps** | Termux (F-Droid/GitHub) + Termux:X11 | Keep Termux and all plugins from the same source; the Google Play line is experimental and differs from the main releases |

Check your device first (read-only, changes nothing):

```bash
uname -m                              # expect: aarch64
getprop ro.product.manufacturer       # e.g. Qualcomm
getprop ro.product.model
getprop ro.build.version.release      # e.g. 14
df -h "$HOME"                         # free space
ls -l /dev/kgsl-3d0 2>&1              # exists → Adreno → Zink/Turnip path
```

`/dev/kgsl-3d0` present means the installer selects the direct Zink/Turnip
route. Missing means it selects VirGL, a compatibility path through a
host-side renderer. Verify either route with `glxinfo -B`; a desktop that opens
with `llvmpipe` is using CPU rendering, not proof of GPU acceleration.

The storage figures above are the approximate **installed footprint**, not the
minimum temporary headroom. Package versions and filesystem accounting vary.
For a clean run, the installer targets roughly **6 GB free** for base and
**14 GB free** for `--all`, allowing downloads, caches, extraction, and builds;
the finished installation itself is approximately **3–4 GB** or **10–12 GB**.

---

## Method 1 — One command (recommended)

```bash
curl -fsSL https://soobujmiah.github.io/ternux/install.sh | bash
```

This downloads the installer over HTTPS and runs it. Because piped standard
input is not a terminal, this route runs unattended with the documented
defaults. Read the output: a required-phase failure stops its dependants, while
an optional/advisory failure is reported and leaves a nonzero final status.

The installation frame remains on screen from startup through the final summary,
keeps **Sobuj Miah** visible in its identity header, and streams real package
output one line at a time. It does not replace logs with a spinner. A capable TTY
gets the persistent dashboard; redirected output, `TERM=dumb`, and reduced-color
terminals get a static readable frame. Both modes preserve logging, phase exit
statuses, noninteractive operation, and `--resume` state. The standalone loader
fetches one validated source snapshot with bounded retries, then reuses it for the
bootstrap libraries, Termux host CLI and Debian guest companion instead of
requesting every module separately. Package setup also keeps the current apt
source and does not open `termux-change-repo` inside the frame; if that source is
unreachable, choose a mirror manually and run with `--resume`.

**curl broken after an upgrade?** A partial upgrade can leave curl and
openssl out of sync. Use wget — same installer, and the script repairs curl
for you:

```bash
wget -qO- https://soobujmiah.github.io/ternux/install.sh | bash
```

### Method 2 — download, review, then run

Piping `curl` into `bash` is convenient, but for a script that changes your
device it is better to review **the entry point and the libraries it sources**.
Clone the repository instead of inspecting only a standalone `install.sh`, which
would still download and source one complete repository snapshot when it starts:

```bash
pkg update -y && pkg install git -y
git clone https://github.com/soobujmiah/ternux.git
cd ternux
git log -1 --oneline                 # record the exact commit
(set -e; for f in install.sh uninstall.sh bin/ternux bin/ternux-guest lib/*.sh; do bash -n "$f"; done)
less install.sh lib/core.sh lib/phases.sh lib/detect.sh lib/ui.sh
# In less, use :n for the next file and q when finished.
bash install.sh
```

For a reproducible review, run `git fetch --tags`, check out a release tag, and
confirm `git status --short` is empty before inspection. The installed result is
intended to be the same, but this local-terminal route asks for one confirmation.
Add `--yes` only after review when you deliberately want no prompt. If interrupted,
use `bash install.sh --resume`; successful phases are skipped and the interrupted
run’s saved optional workload set is restored.

### Method 3 — fully manual

For total control — or to debug the installer itself — the
[Manual installation](MANUAL.html) page walks through every single command:
base packages, the container, the GPU driver for both routes, the complete
`~/x.sh` launcher file, and verification. Methods 1 and 2 run those same
steps for you.

---

## ternux CLI — host control and guest diagnostics

Installation makes `ternux` discoverable in both terminal environments, but the
two entry points deliberately have different responsibilities:

| Environment | Installed entry point | Supported role |
|---|---|---|
| **Termux host** | `$PREFIX/bin/ternux` with modules in `$PREFIX/lib/ternux/` | Full diagnostics, repair, desktop lifecycle, profiles, backends, update, and uninstall |
| **Debian/Xfce guest** | `/usr/local/bin/ternux` | Guest-local `status`, `info`, `doctor`, and `env` without launching another PRoot session |

Use the full control plane from the **Termux host terminal**:

```bash
command -v ternux       # $PREFIX/bin/ternux
ternux --version        # ternux vX.Y.Z
ternux doctor           # system diagnostics
ternux doctor --json    # machine-readable diagnostics
ternux start            # start the desktop
ternux stop             # stop the desktop
ternux restart          # restart the desktop
ternux repair           # repair common problems
ternux verify           # verify the installation
ternux benchmark        # installation health and renderer check
ternux profile          # manage the device profile
ternux backend          # inspect or change the graphics backend
ternux info             # system information
ternux info --json      # machine-readable information
ternux logs             # inspect logs
ternux state            # installation state
ternux update           # update the CLI
ternux uninstall        # remove selected components
```

From an **Xfce terminal inside Debian**, use guest-local inspection commands:

```bash
command -v ternux       # /usr/local/bin/ternux
ternux --version        # ternux guest vX.Y.Z
ternux status
ternux info
ternux doctor
ternux env
```

The guest companion returns a usage error for host-only lifecycle commands such
as `start`, `stop`, `repair`, `update`, and `uninstall`, and tells you to run them
in Termux. This prevents accidental nested PRoot sessions. During installation,
ternux executes the exact installed host and guest commands and validates their
version responses; executable-file presence alone does not count as success.

The host dispatcher recognizes global flags, but not every command implements a
JSON schema. Use structured output only for commands documented in the
[CLI reference](CLI.html).

---

## What the installer does (and why, phase by phase)

The installer runs as **11 verified phases**. Each phase checks its own work
before the next one starts — a failed phase stops the install with a clear
message instead of producing a half-broken desktop.

| # | Phase | What it does | Why |
|---|---|---|---|
| 1 | **Preflight** | Checks Termux, architecture, Android version, storage, network | Fail here and you waste no downloads; every later phase depends on these facts |
| 2 | **Base packages** | Installs `x11-repo`, `termux-x11`, `pulseaudio`, `proot-distro`, `virglrenderer-android`, tools; requests storage permission | These are the host-side services the container needs: display, sound, and the container engine |
| 3 | **Host CLI installation** | Installs `$PREFIX/bin/ternux` plus modules in `$PREFIX/lib/ternux/`, then executes its exact path and checks its version | A file can exist while its libraries are missing; successful execution is the real host-side check |
| 4 | **Debian + Xfce4** | Installs the Debian rootfs and desktop packages, creates your user with passwordless sudo, installs `/usr/local/bin/ternux`, and executes the guest companion | The desktop gets safe local diagnostics without nesting PRoot; sudo and the guest command are both validated |
| 5 | **GPU driver** | Adreno: resolves the current Debian ARM64 Turnip asset, rejects unsafe paths, validates the two target members as regular files, records URL/SHA-256, and installs only those members. Other: confirms the VirGL host renderer | Target-only extraction avoids executing archive layout assumptions. Pinning paired Mesa packages reduces the chance of a routine upgrade replacing the tested path |
| 6 | **Audio, locale, fonts** | Bridges PulseAudio loopback-only, generates your locale, installs emoji/powerline/Nerd fonts | Sound crosses the container boundary over TCP — loopback only. Fonts avoid tofu boxes in the terminal |
| 7 | **Launcher** | Writes `~/x.sh` tuned to your GPU route, syntax-checks it | One command (`x`) must reliably start audio → display → desktop in the right order |
| 8 | **Shortcuts** | Installs `x`, `killx`, `db`, `droot`, `xgo`, `sysmon`, `clean-mesa` for the selected Debian user | Daily operation should be muscle memory, not archaeology |
| 9 | **Optional extras** | Dev tools, llama.cpp, network tools, media tools, Blender — only what you asked for | Keep the base install lean; each profile has different storage/thermal costs |
| 10 | **Android safeguard check** | Reads the Android child-process setting when available and prints version-aware guidance | Signal 9 can also come from memory pressure or OEM battery policy; collect evidence before changing a system-wide safeguard |
| 11 | **Verification** | Confirms every critical binary, file and permission actually landed | Trust, but verify — `apt` succeeding is not proof the desktop will launch |

---

## Installer options

```bash
bash install.sh                     # local terminal — one confirmation before changes
bash install.sh --yes               # accept all defaults, no questions
bash install.sh --user soobuj       # Debian user name (default: ternux)
bash install.sh --locale bn_BD.UTF-8
bash install.sh --backend zink      # force Zink/Turnip (Adreno only)
bash install.sh --backend virgl     # force the compatibility fallback
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
| Qualcomm Adreno | `auto` → **zink** | Measured route on the supplied Adreno setup: OpenGL → Zink → Vulkan → Turnip; verify your renderer and workload |
| Mali / Xclipse / PowerVR / other | `auto` → **virgl** | Compatibility route via the host renderer; device support and speed vary |
| Adreno, but the driver route fails | `--backend virgl` | Alternate path to test; verify that it does not fall back to `llvmpipe` |

Forcing `zink` on a device without `/dev/kgsl-3d0` fails loudly at the GPU phase
before the launcher is created, rather than producing a silently-software
desktop. That failure is intentional.

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
ternux doctor --json    # machine-readable output
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
- **An interrupted installer run:** re-download the same reviewed script and use
  `--resume`; it skips only successfully recorded phases. This does **not**
  update or repair phases already complete—use `ternux update` for the CLI and
  `ternux repair` for managed artifacts. Back up before driver or distribution changes.
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

`all` means the four scoped targets shown by the command: stop the session,
remove `~/x.sh` and ternux alias blocks, remove ternux state/logs, and delete the
Debian container. It **does not** uninstall Termux packages, remove the installed
`ternux` CLI/libraries, revoke shared-storage access, restore repository/mirror
choices, or revert the loopback PulseAudio line in Termux's `default.pa`; those
may predate ternux and are deliberately left alone. Android files outside
Termux storage are never deleted. Clearing Termux app data is the separate
nuclear option that removes the remaining Termux installation too.

---

## Troubleshooting

Desktop won't start? Renderer says `llvmpipe`? No audio?
See [Troubleshooting](TROUBLESHOOTING.html) — every symptom maps to a cause
and a fix.

---

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · MIT*
