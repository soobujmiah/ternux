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
| **Storage** | Installed: ~4–4.6 GB base; ~10.5–12.6 GB with `--all` | Begin with additional free space for downloads, package caches, build trees, models and projects |
| **RAM** | 4 GB min, 6–8 GB preferred | The desktop + Android share memory; less RAM = more killing |
| **Graphics** | Adreno/KGSL prefers Zink with each guest distro’s own Mesa/Freedreno packages where available; VirGL is the compatibility route | The active renderer depends on the guest package set and Android host stack; verify with `glxinfo -B` |
| **Required apps** | [Termux](https://github.com/termux/termux-app/releases) + [Termux:X11](https://github.com/termux/termux-x11/releases) | Install both from compatible sources; open Termux:X11 once before starting Ternux |
| **X11 performance option** | [Termux:X11 nightly shared-UID debug APK](https://github.com/termux/termux-x11/releases/tag/nightly) (`termux-x11-universal-sharedUid-debug.apk`) | Shares Termux's Android UID so Android is less likely to background-throttle the Linux workload while X11 is foreground. Requires the GitHub-signed Termux app. F-Droid/Google Play Termux should use `termux-x11-universal-debug.apk` from the same release page. |
| **Optional companion apps** | [Termux:Boot](https://github.com/termux/termux-boot/releases), [Termux:API](https://github.com/termux/termux-api/releases), [Termux:Styling](https://github.com/termux/termux-styling/releases) | Boot can run configured startup scripts after reboot; API provides Android utilities and its matching `termux-api` package enables the install-time permission probe. Live desktop mic uses Termux's on-demand OpenSL ES source, not the API's file recorder. Styling provides terminal themes and fonts. Keep Termux and each add-on from the same source |

Check your device first (read-only, changes nothing):

```bash
uname -m                              # expect: aarch64
getprop ro.product.manufacturer       # e.g. Qualcomm
getprop ro.product.model
getprop ro.build.version.release      # e.g. 14
df -h "$HOME"                         # free space
ls -l /dev/kgsl-3d0 2>&1              # Debian + Adreno/KGSL → Zink/Turnip path
```

`/dev/kgsl-3d0` makes `auto` prefer Zink. Debian Trixie uses Ternux’s
validated Turnip payload; Ubuntu, Alpine, Arch, Fedora, openSUSE and Void use
their distro-native Mesa/Freedreno packages. Other profiles use their family
packages when available; Adélie currently selects VirGL. Verify the actual
renderer with `glxinfo -B`; `llvmpipe` means CPU rendering, not GPU acceleration.

The storage figures above are the approximate **installed footprint**, not the
minimum temporary headroom. Package versions and filesystem accounting vary.
For a clean run, the installer targets roughly **6 GB free** for base and
**14 GB free** for `--all`, allowing downloads, caches, extraction, and builds;
the finished installation itself is approximately **4–4.6 GB** or **10.5–12.5 GB**.

---

## Method 1 — One command (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/soobujmiah/ternux/main/install.sh | bash
```

This downloads the installer over HTTPS and runs it. With an attached terminal,
the installer reads prompts through `/dev/tty`, including the optional-workload
chooser, even though the script itself is piped. If no controlling terminal is
available, it installs the base profile. Add `--yes` for an explicitly
unattended base install. Read the output: a required-phase failure stops its dependants, while
an optional/advisory failure is reported and leaves a nonzero final status.

The installer draws one persistent screen — device panel, step progress, live
log window, elapsed time — and keeps it until the final status. Package output
is shown as it happens rather than hidden behind a spinner, and every line is
written to the log file whatever the terminal can render. See
[The installer screen](#the-installer-screen) for the renderer modes and how to
override them.

The standalone loader fetches one immutable source snapshot with bounded
retries and verifies its pinned SHA-256 before extracting or sourcing it. The
host CLI fallback uses that same commit and digest and rejects changed bytes
before extraction. The validated snapshot is reused for the bootstrap libraries,
the Termux host CLI and the Debian guest companion in the normal installer path.
If the guest companion is requested without that local snapshot, its fallback
fetches the file from the same immutable commit and verifies its own SHA-256. Package
setup keeps the current apt source and never opens `termux-change-repo` inside
the frame; if that source is unreachable, select a mirror manually and re-run
with `--resume`.

**curl broken after an upgrade?** A partial upgrade can leave curl and
openssl out of sync. Use wget — same installer, and the script repairs curl
for you:

```bash
wget -qO- https://raw.githubusercontent.com/soobujmiah/ternux/main/install.sh | bash
```

### Optional workload chooser

On an interactive install without workload flags, the installer suggests
items based on the detected GPU route, then opens a categorized keyboard
checklist. Use Up/Down or `j`/`k` to move, Space or an item's number to toggle
multiple choices, Enter to review the plan, and `q` to keep the base desktop.
`--yes` skips the chooser and keeps the base profile; `--with-*` flags select
workloads explicitly and `--all` selects every workload. Blender may be
suggested on the detected Adreno/Zink route; this is a fit suggestion, not a
guarantee that every device supports GPU rendering. The chooser also reports
detected RAM and free storage; the full profile targets about 14 GB free for
packages, downloads and build cache.

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
rerunning the same one-command installer automatically resumes the saved guest and
choices; `bash install.sh --resume` remains available when you want to request it
explicitly. Shared host setup phases are recorded once; desktop phases are kept
under each guest's state directory. Resume skips a guest phase only when that
same guest completed it, so a finished Debian phase cannot hide unfinished
Ubuntu or Alpine setup. Older installs without a guest phase ledger rerun the
guest phases safely instead of trusting aggregate legacy markers. Saved optional
workloads are restored.

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
it is not included in the archive. The default/HMX and flash-attention paths
returned wrong answers. HVX-only matmul with flash attention disabled passed
bounded known-answer and long recall-key checks on the tested device. Explicit
HVX flash attention still has seven reproducible numerical-error cases, so HTP
remains experimental and unsupported. See the [current release gate](ACCELERATOR-RELEASE-PLAN.html) and
[repository-only detailed evidence](https://github.com/soobujmiah/ternux/blob/main/guides/device-benchmark-evidence.md#experimental-llamacpp-hexagon-htp-artifact-for-sm8735).

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

The interactive Ternux installer can install selected ADT components. It runs
ADT's command-line tools first so `sdkmanager` is available before installing
versioned SDK components. For manual setup, enter Debian from the Termux host
with `db` (or open an Xfce terminal), then run the ADT-owned installer as your
normal Debian user:

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

### Optional CPU + Vulkan llama.cpp extension

The short install and run path is in [Quick start](QUICK-START.html#optional-local-cpu--vulkan-language-model).
For release details and both automatic and manual installation, use the
[repository extension guide](https://github.com/soobujmiah/ternux/blob/main/guides/llama-vulkan-extension.md).
The package is a prerelease; ADT remains installed and updated through ADT's own
release-aware commands above.

---

### Optional Stable Diffusion CPU + Vulkan extension

`ternux extension install stable-diffusion` installs the pinned Linux ARM64
`sd-cli` runtime. Model weights remain user-provided. To use weights under Android shared
storage, first run `ternux storage grant /sdcard/Llms`; only granted folders are
mounted in the guest. Vulkan requires a working Debian
Vulkan ICD. The artifact is in preview pending target-device image generation,
quality and performance qualification. See the
[Stable Diffusion extension guide](https://github.com/soobujmiah/ternux/blob/main/guides/stable-diffusion-vulkan-extension.md)
for installation, direct model paths, verification and removal.

---

### Experimental llama.cpp HTP extension

The experimental HTP package is installed from the Termux host with
`ternux extension install llama-htp-experimental`. It is limited to the
SM8735/V73 experiment and is not a supported Ternux feature. Review the
[repository HTP guide](https://github.com/soobujmiah/ternux/blob/main/guides/llama-htp-experimental.md)
for runtime dependencies, exact usage, known incorrect configurations,
cancellation status and removal. When selected in the installer, Ternux enables
the official Debian Trixie Backports `main` and `contrib` components and installs
the four Debian runtime packages before downloading the extension. These are
system runtime dependencies, so they are not bundled in the release archive. Do
not change FastRPC device permissions or copy model weights for this extension.

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
tx start                # start the saved desktop
tx start ubuntu        # start Ubuntu in its own Termux:X11 window
tx start ub             # same Ubuntu profile via its short name
tx start alp            # start Alpine via its short name
tx stop                # list running desktops; select one or more
tx stop db             # stop Debian only
tx stop ub             # stop Ubuntu only
tx stop alp            # stop Alpine only
tx stop --all          # stop all Ternux desktops
tx restart ubuntu     # restart Ubuntu
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
| 4 | **Selected guest + Xfce4** | Installs the selected distro rootfs and family-matched desktop packages, creates your user with passwordless sudo, installs `/usr/local/bin/ternux`, and executes the guest companion | Each named profile gets its own desktop recipe and local diagnostics without nesting PRoot |
| 5 | **GPU route** | Debian + Adreno/KGSL: validates and installs the pinned Turnip payload. Every other named profile: configures the shared VirGL host renderer with its guest Mesa `virpipe` driver | Each profile has a GPU route; inspect `glxinfo -B` to distinguish hardware rendering from a software fallback |
| 6 | **Audio, locale, fonts** | Configures the loopback-only PulseAudio bridge, OpenSL ES output and on-demand microphone source; runs a private one-second Termux:API permission probe; generates your locale and installs emoji/powerline/Nerd fonts | Guest playback and capture reach Android audio through PulseAudio. Live capture uses Termux's permission and OpenSL ES source; the separate Termux:API probe does not carry a live stream. Fonts avoid tofu boxes in the terminal |
| 7 | **Launcher** | Writes `~/x.sh` tuned to your GPU route, syntax-checks it | One command (`x`) must reliably start audio → display → desktop in the right order |
| 8 | **Shortcuts** | Installs `tx`, `x`, `killx`, `db`/`dbroot`, `ub`/`ubroot`, `alp`/`alproot`, `xgo`, `sysmon`, `clean-mesa` | Sets up quick shortcuts so everyday operations need only a single command |
| 9 | **Optional extras** | Dev tools, llama.cpp, network tools, media tools, Blender + Xvfb for headless EEVEE — only what you asked for | Keep the base install lean; each profile has different storage/thermal costs |
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
bash install.sh --distro ubuntu      # one named guest profile
bash install.sh --distros debian,ubuntu,alpine  # install several profiles
bash install.sh --with-dev          # Git, Node.js, Python, build tools
bash install.sh --with-llm          # llama.cpp + Vulkan (local AI)
bash install.sh --with-network      # nmap, tmux (authorised testing only)
bash install.sh --with-media        # ffmpeg, GIMP, Audacity, ImageMagick
bash install.sh --with-blender      # Blender + Xvfb for headless EEVEE rendering
bash install.sh --all               # every optional profile
bash install.sh --resume            # continue after an interruption
bash install.sh --version           # show version
bash install.sh --help              # show help
```

[Workloads](WORKLOADS.html) lists exactly what each `--with-*` flag installs,
and gives the manual equivalent of every one of them — useful before you let an
installer run, and the way to finish a workload that failed.

On the established Adreno workstation, `--with-blender` also installs Xvfb for
headless EEVEE Next rendering with GPU offload through Zink/Turnip. The
[Blender usage guide](USAGE.html) gives the required display variables and
tested command.

After installation, use the `ternux` CLI for diagnostics and management:

```bash
ternux doctor           # diagnose
ternux repair           # diagnose and fix
ternux state            # what is done, what is pending
ternux uninstall        # interactive removal
ternux update           # self-update the CLI
```

### Choosing a guest distribution

Each selected guest lives in its own PRoot-Distro container. `--distro`
selects one profile; `--distros` installs several independently. The choice is
recorded per guest so `--resume` and `ternux repair` keep using the right
profile.

| Package manager | Named desktop profiles |
|---|---|
| APT | Debian, Ubuntu, Kali, Deepin, Pardus |
| APK | Alpine, Adelie, Chimera |
| pacman | Arch Linux, Artix, Manjaro |
| DNF | Fedora, Rocky Linux |
| Zypper | openSUSE |
| XBPS | Void |

Debian is the recommended default. Debian, Ubuntu, and Alpine have partial
physical-device integration evidence on one Adreno 825 phone (desktop,
Zink/Turnip, audio routing, IBus and theme setup); this does not qualify clean
installation or every application. The remaining named profiles have
family-matched recipes but no physical-device qualification. Arbitrary PRoot-Distro OCI
images can be installed as shell guests; they do not receive an automatic
Ternux desktop recipe. Optional software workloads currently require an APT
guest.

When `--distro` or `--distros` is omitted, the interactive profile picker uses
the same checklist as optional workload selection: Up/Down or `j`/`k` moves,
Space or a profile number toggles selection, Enter confirms, and `q` keeps the
current default. Several guests can be selected in one pass. Limited terminals
get a comma-separated number/name prompt. Before installation, the dashboard
shows the chosen profiles and configuration for confirmation. Prompts wait up
to five minutes; unanswered prompts use their displayed defaults. Unattended
runs take defaults immediately.

A profile without device evidence prints a warning. Treat its result as
unverified until it is measured on your own device.

### Choosing a GPU backend

| Guest profile / host | Backend | Expectation |
|---|---|---|
| Adreno with KGSL and a native package profile | `auto` → **zink** | Debian uses the validated Turnip payload; other supported profiles install their own Mesa/Freedreno packages. Check the guest renderer and workload |
| Ubuntu and every other named desktop profile | `auto` → **virgl** | Shared host VirGL + guest Mesa `virpipe` path; it can use Android's GPU stack when the host renderer exposes hardware, but verify `glxinfo -B` because a software fallback is possible |
| Any profile where Zink is unavailable | `--backend virgl` | Cross-distro compatibility route; renderer and performance depend on the host graphics stack |

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
|           ternux v2.0.0 - ONE-CLICK INSTALLER           |
| by Sobuj Miah  -  base ~4-4.6 GB  -  complete ~10.5-12.5 GB   |
+=========================================================+
| Device    Redmi Turbo 4 Pro - Android 15 (SDK 35)       |
| Graphics  Adreno 825 - backend zink - Vulkan 1.4        |
| Memory    12 GB RAM - 84 GB free - aarch64              |
| STEPS 4/11  ######------------  Debian container        |
+=========================================================+
| Get:14 http://deb.debian.org trixie/main arm64          |
| Unpacking xfce4-session ...                             |
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

- **The ternux CLI:** `ternux update` uses the latest published stable release tag. It resolves and fetches that exact Git commit, validates a complete staged module tree, then switches the CLI and modules with a recovery journal. The previous version remains backed up; failed verification restores it. A newer development build is never downgraded to an older stable tag.
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

`all` stops the Ternux desktop, removes its launcher and shell aliases, state,
logs and empty capture-cache directories, deletes the selected Debian guest,
and removes the Ternux host CLI and its update backups. It preserves Termux
itself, shared Termux packages, other PRoot guests, Android files outside
Termux storage, and non-empty capture folders. It also does not revoke shared
storage access, restore repository/mirror choices, or revert the loopback
PulseAudio line in Termux's `default.pa`; these settings may predate Ternux.
Normal installation creates only the selected guest (default `debian`); it does
not create test aliases such as `ternux-clean-apt`. Clearing Termux app data is
a separate operation that removes the remaining Termux environment.

---

## Troubleshooting

Desktop won't start? Renderer says `llvmpipe`? No audio?
See [Troubleshooting](TROUBLESHOOTING.html) — every symptom maps to a cause
and a fix.

---

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · Apache-2.0*
