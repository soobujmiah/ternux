---
title: "Installation"
description: "The complete ternux installation guide: requirements, the one-command installer, what each of the 11 phases does, every option, and clean removal."
lang: "en"
alt_url: "/bn/docs/INSTALLATION.html"
---

Detailed installation walkthrough. For the concise path, see
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

The installer draws one persistent screen — device panel, step progress, live
log window, elapsed time — and keeps it until the final status. Package output
is shown as it happens rather than hidden behind a spinner, and every line is
written to the log file whatever the terminal can render. See
[The installer screen](#the-installer-screen) for the renderer modes and how to
override them.

The standalone loader fetches one validated source snapshot with bounded
retries, then reuses it for the bootstrap libraries, the Termux host CLI and the
Debian guest companion instead of requesting every module separately. Package
setup keeps the current apt source and never opens `termux-change-repo` inside
the frame; if that source is unreachable, select a mirror manually and re-run
with `--resume`.

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

## Choose the right project release

During installation, the completion screen points to `ternux guides`. After installation, run `ternux guides` in either Termux or the Debian/Xfce terminal. It prints direct links for the environment installer, manual setup, ecosystem tool installs, and daily use. It opens no browser and installs nothing.

Install the Ternux environment using the [Quick start](QUICK-START.html) or
this full [Installation guide](INSTALLATION.html); the command-by-command
alternative is [Manual installation](MANUAL.html). The canonical Ternux
release history is on the [Ternux Releases page](https://github.com/soobujmiah/ternux/releases).

The experimental llama.cpp HTP release is an optional Linux ARM64 artifact,
not a Ternux installer or a Debian root filesystem. Set up Ternux first. The
artifact also needs the separately established Android Binder/FastRPC broker;
it is not included in the archive. Its known-output test currently fails, as
recorded in [Benchmarks](BENCHMARKS.html#experimental-llamacpp-hexagon-htp-artifact-for-sm8735).

ADT's Android SDK tools have their own versions, build records and canonical
downloads. Get them from [ADT Releases](https://github.com/soobujmiah/adt/releases)
and follow [ADT's setup guide](https://github.com/soobujmiah/adt#quick-start)
inside Debian. Ternux does not duplicate ADT release files. The two projects
can coexist on the same Termux + PRoot Debian base, but the combined desktop
workflow remains experimental; see [ADT's Ternux relationship notes](https://github.com/soobujmiah/adt/blob/main/docs/TERNUX_RELATIONSHIP.md).

Install the download tools inside Debian first if they are missing:

```bash
sudo apt update && sudo apt install -y ca-certificates curl tar gzip
```

### Install ADT tools inside the Ternux Debian guest

From the Termux host, enter Debian with `db` (or open an Xfce terminal), then
run the ADT-owned installer as your normal Debian user:

```bash
curl -fsSL https://raw.githubusercontent.com/soobujmiah/adt/main/install.sh | bash
source ~/.bashrc
cd ~/adt
./setup.sh doctor
```

To install only selected versions, use ADT's release-aware commands instead of
copying assets into Ternux:

```bash
./setup.sh list-versions
BUILD_TOOLS_VERSION=37.0.0
./setup.sh install-build-tools "$BUILD_TOOLS_VERSION"
./setup.sh install-platform-tools "$BUILD_TOOLS_VERSION"
./setup.sh doctor
```

The ADT repository remains the source of truth for supported versions and
asset checksums. See [ADT's command guide](https://github.com/soobujmiah/adt/blob/main/COMMANDS.md).

The standalone llama.cpp steps below use the same download tools. The archive
extracts into your Debian home; no `sudo` is needed for the extraction or run.

### Install the CPU + Vulkan llama.cpp extension

From the Termux host, list and install the published ARM64 extension release:

```bash
ternux extension list
ternux extension install llama-vulkan
```

The installer enters the selected Debian guest, verifies the release SHA-256,
checks archive paths and package metadata, then installs atomically under
`~/.local/opt/ternux-extensions/llama-vulkan`. It does not copy or manage model
weights. The pinned b11582 package is published as a prerelease. An existing
destination is left untouched and reported; there is no in-place updater.
Inspect and deliberately remove an old install before installing again.

Inside Debian, load the tools and select the backend explicitly:

```bash
source "$HOME/.local/opt/ternux-extensions/llama-vulkan/env.sh"
llama-cli --list-devices
llama-cli -m /path/to/your/model.gguf -ngl 0 -p 'What is 2 + 2?' -n 8
llama-cli -m /path/to/your/model.gguf -ngl 99 -p 'What is 2 + 2?' -n 8
```

CPU is the fallback. Vulkan requires a working system Vulkan ICD and a listed
Adreno device; check `vulkaninfo --summary` first. This package contains CPU and
Vulkan backends only. ADT remains installed and updated through ADT's own
release-aware commands above.

---

### Install the experimental llama.cpp HTP artifact

Do this inside the Debian guest. It installs under your Debian user's home and
does not modify the Termux host or require `sudo`:

```bash
ARTIFACT_DIR="$HOME/.cache/ternux-artifacts"
mkdir -p "$ARTIFACT_DIR" "$HOME/.local/opt"
cd "$ARTIFACT_DIR"
curl -fL --retry 3 \
  -o ternux-llama-htp-sm8735-b11582.tar.gz \
  https://github.com/soobujmiah/ternux/releases/download/ternux-llama-htp-sm8735-b11582/ternux-llama-htp-sm8735-b11582.tar.gz
curl -fL --retry 3 \
  -o ternux-llama-htp-sm8735-b11582.tar.gz.sha256 \
  https://github.com/soobujmiah/ternux/releases/download/ternux-llama-htp-sm8735-b11582/ternux-llama-htp-sm8735-b11582.tar.gz.sha256
sha256sum -c ternux-llama-htp-sm8735-b11582.tar.gz.sha256
tar -xzf ternux-llama-htp-sm8735-b11582.tar.gz -C "$HOME/.local/opt"
```

Point llama.cpp at the extracted libraries and run a CPU baseline first. Replace
the model path with a GGUF model you already have:

```bash
export LLAMA_HTP_HOME="$HOME/.local/opt/ternux-llama-htp-sm8735-b11582"
export LD_LIBRARY_PATH="$LLAMA_HTP_HOME/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
"$LLAMA_HTP_HOME/bin/llama-cli" \
  -m "$HOME/models/model.gguf" -ngl 0 \
  -p 'What is 2 + 2? Reply with only the number.' -n 8
```

This archive is Linux aarch64 and includes the HTP V73 backend, but it does not
include Qualcomm vendor runtime libraries, firmware or a Binder/FastRPC broker.
HTP execution requires a compatible `libcdsprpc.so` and an authorized CDSP file
descriptor supplied through an Android-side broker. The demonstrated SM8735
setup currently uses a separate experimental probe; there is no self-contained
HTP launcher in this release. Do not change `/dev/fastrpc-cdsp` permissions.
Even with the broker, the known-answer test on this exact build returned
incorrect text. Standalone `ADD` and F32 `MUL_MAT` checks passed, but a
Q4_0×F32 matrix test differed from the same-build CPU result; details are in
[the benchmark record](BENCHMARKS.html). Read it before attempting HTP; this is
not a correct or production-ready inference package.

To remove the extracted artifact, close any `llama.cpp` processes, then run:

```bash
rm -rf "$HOME/.local/opt/ternux-llama-htp-sm8735-b11582"
```

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
| 8 | **Shortcuts** | Installs `x`, `killx`, `db`, `droot`, `xgo`, `sysmon`, `clean-mesa` for the selected Debian user | Sets up quick shortcuts so everyday operations need only a single command |
| 9 | **Optional extras** | Dev tools, llama.cpp, network tools, media tools, Blender — only what you asked for | Keep the base install lean; each profile has different storage/thermal costs |
| 10 | **Android safeguard check** | Reads the Android child-process setting when available and prints version-aware guidance | Signal 9 can also come from memory pressure or OEM battery policy; collect evidence before changing a system-wide safeguard |
| 11 | **Verification** | Confirms every critical binary, file and permission actually landed | Confirms the environment is runnable — `apt` completing without errors does not guarantee the desktop will launch |

---

## Installer options

```bash
bash install.sh                     # local terminal — one confirmation before changes
bash install.sh --yes               # accept all defaults, no questions
bash install.sh --user soobuj       # Debian user name (default: ternux)
bash install.sh --locale bn_BD.UTF-8
bash install.sh --backend zink      # force Zink/Turnip (Adreno only)
bash install.sh --backend virgl     # force the compatibility fallback
bash install.sh --zsh               # Termux shell -> zsh, with powerlevel10k
bash install.sh --shell bash        # choose without being asked
bash install.sh --no-theme          # zsh without powerlevel10k
bash install.sh --distro ubuntu      # guest distribution (debian is the verified one)
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

[Workloads](WORKLOADS.html) lists exactly what each `--with-*` flag installs,
and gives the manual equivalent of every one of them — useful before you let an
installer run, and the way to finish a workload that failed.

After installation, use the `ternux` CLI for diagnostics and management:

```bash
ternux doctor           # diagnose
ternux repair           # diagnose and fix
ternux state            # what is done, what is pending
ternux uninstall        # interactive removal
ternux update           # self-update the CLI
```

### Choosing a guest distribution

Everything ternux installs lives inside one PRoot-Distro container. `--distro`
selects it, and the choice is recorded so `--resume` and `ternux repair` keep
using it.

| Guest | Status | Notes |
|---|---|---|
| `debian` | **verified on a device** | The default, and the only one with measured results in [Evidence & benchmarks](BENCHMARKS.html) |
| `ubuntu` | profile written, **not device-verified** | Same apt/dpkg tooling, so holds and diversions work identically. `snapd` is additionally held: it cannot work without systemd inside a container, and packages that exist only as snaps cannot be installed there at all |

An interactive install asks which guest to use when `--distro` was not given,
alongside the user name and shell prompts, and names which one is verified.
Unattended runs take the default.

Any other name is refused rather than attempted. Selecting a guest without a
verified result prints a warning and does not change what the installer claims:
treat the result as unverified until it is measured on your own device.

### Choosing a GPU backend

| Your GPU | Backend | Expectation |
|---|---|---|
| Qualcomm Adreno | `auto` → **zink** | Measured route on the supplied Adreno setup: OpenGL → Zink → Vulkan → Turnip; verify your renderer and workload |
| Mali / Xclipse / PowerVR / other | `auto` → **virgl** | Compatibility route via the host renderer; device support and speed vary |
| Adreno, but the driver route fails | `--backend virgl` | Alternate path to test; verify that it does not fall back to `llvmpipe` |

Forcing `zink` on a device without `/dev/kgsl-3d0` fails loudly at the GPU phase
before the launcher is created, rather than producing a silently-software
desktop. That failure is intentional.

On the Zink route the Vulkan driver is the foundation the whole OpenGL path
stands on, and on recent Adreno hardware it has to be newer than the one Debian
ships. Read [Graphics persistence](GRAPHICS-PERSISTENCE.html) before your first
`apt upgrade`: it explains where to keep that driver so a package update cannot
remove it, and how to tell whether yours is already at risk.

---

## The installer screen

One screen serves the whole run. The log window holds the live tail of the
current phase; the complete stream is always appended to the log file.

```text
+=========================================================+
|           ternux v1.4.0 - ONE-CLICK INSTALLER           |
| by Sobuj Miah  -  base ~3-4 GB  -  complete ~10-12 GB   |
+=========================================================+
| Device    Redmi Turbo 4 Pro - Android 15 (SDK 35)       |
| Graphics  Adreno 825 - backend zink - Vulkan 1.4        |
| Memory    12 GB RAM - 84 GB free - aarch64              |
| STEPS 4/11  ######------------  Debian container        |
+=========================================================+
| Get:14 http://deb.debian.org bookworm/main arm64        |
| Unpacking xfce4-session (4.18.3-1) ...                  |
|     ... +201 more lines (full log: ternux.log)          |
| [ OK ] Base packages installed                          |
+=========================================================+
| (c) 2026 Sobuj Miah - github.com/soobujmiah  03:12 /    |
+=========================================================+
```

| Region | What it reports |
|---|---|
| Device panel | Model, Android release and SDK, GPU, selected backend, Vulkan, RAM, free storage, architecture |
| Step bar | Phase number, total phases, and the title of the running phase |
| Log window | Live tail of the running phase, coloured by severity |
| Footer | Elapsed time and a spinner that keeps moving while a phase is quiet |

### Renderer modes

| Mode | Chosen when | Behaviour |
|---|---|---|
| `dashboard` | Interactive terminal with colour, at least 39 usable columns and 13 rows | The persistent screen shown above |
| `plain` | Everything else: pipes, `curl \| bash` without a TTY, `TERM=dumb`, `NO_COLOR`, a very small window | Framed lines appended in order, no cursor control |
| `off` | `--ui off`, `--quiet`, or `--json` | Raw command output with no framing |

Selection is automatic; override it when you prefer a different result:

```bash
bash install.sh --plain          # scrolling log, no full-screen dashboard
bash install.sh --no-anim        # dashboard without spinner or colour cycling
TERNUX_UI=off bash install.sh    # raw output, e.g. to capture a transcript
```

### Reading the log window

- Carriage-return progress from apt, dpkg, proot-distro and curl updates a single
  row in place instead of scrolling the window away.
- When a phase prints faster than the screen can be read, the newest lines are
  kept and the count of the rest is stated as `... +201 more lines`. Errors,
  warnings and phase markers are never summarised.
- Changing font size, rotating the device, or opening the on-screen keyboard
  re-fits the frame once and redraws the visible log.
- `Ctrl-C` restores the terminal and preserves recorded state, so
  `bash install.sh --resume` continues from the last completed phase.

The renderer never decides what is recorded:

```bash
ternux logs tail     # follow the live install log
ternux logs show     # read the whole log
ternux logs list     # log files and sizes
```

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

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · Apache-2.0*
