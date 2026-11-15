---
title: "CLI Reference"
description: "Reference for ternux commands, subcommands, flags, and the commands that emit structured JSON."
lang: "en"
alt_url: "/bn/docs/CLI.html"
---

The host package installs both `tx` and `ternux` in `$PREFIX/bin`; either runs
the same management CLI for installation, diagnostics, repair, benchmarking,
desktop lifecycle, and system information. `tx` is an executable wrapper, so it
works in fresh shells and scripts without relying on a startup-file alias. Use it
for install/resume, distro management, desktop lifecycle, diagnostics, repair,
logs, update, and scoped removal.

This reference uses the primary **Termux host** command `$PREFIX/bin/tx`
(`$PREFIX/bin/ternux` remains a compatibility name). The Debian/Xfce terminal has a separate guest-aware
`/usr/local/bin/ternux` companion with only `status`, `info`, `doctor` (`verify`
is an alias), `env`, `--version`, and help. It rejects host lifecycle commands instead of nesting a
second PRoot session. Switch to Termux for every host command documented below.

Both commands are executed and version-checked during installation; file
presence by itself is not considered a successful CLI installation.

## Usage

```bash
tx <command> [options] [subcommand]
```

## Global flags

| Flag | Description |
|------|-------------|
| `--help`, `-h` | Show help for any command |
| `--json` | Request structured output; only commands documented with JSON below promise a JSON object |
| `--verbose` | Enable debug messages where a command provides them |
| `--quiet` | Suppress shared informational/status messages; child-program output may remain |
| `--version`, `-V` | Show version information |

The dispatcher recognizes these flags before loading a command, so they may
appear before or after the command name. Recognition is not a promise that
every command has a machine-readable implementation. Do not pass `--json` to
`install`, the live `logs tail` stream, or `uninstall` and expect a JSON schema;
use it only where this page explicitly shows structured output. Shared
dispatch/environment failures use `command: "error"`, `status: "fatal"`, and a
`message` field; an unknown command also includes `requested_command`. A failure
before `lib/core.sh` can load is necessarily plain stderr, not JSON.

## Commands

### `tx -h` and `tx mic` / `tx cam`

`tx -h` presents the centered Ternux name, “Workstation In Your Pocket”
tagline, version, color-coded command tree, grouped aliases, global options and
examples. `ternux -h` prints the same reference; use `tx COMMAND -h` for
command-specific details. The built-in `tx guides` gives a formatted quick-start
path, guest user/root shell shortcuts, and links to the longer guides.

`xgo` opens the installed guest desktop picker; `killx` stops selected desktop sessions; `sysmon` summarizes CPU, memory and GPU information. The guest-only `clean-mesa` shortcut clears the current guest’s Mesa shader cache. There is no one-letter `x` command.

For example, Debian accepts `db` for a user shell and `dbr` or `dbroot` for a
root shell; Ubuntu accepts `ub`/`ubr`/`ubroot`, Kali accepts
`kali`/`kalir`/`kaliroot`, and Alpine accepts `alp`/`alpr`/`alproot`.

`tx mic` checks Termux:API microphone access with a bounded temporary recording
and removes the file. Without Termux:API it can briefly open the built-in
OpenSL input if that source is active; captured audio is discarded. `tx cam`
requests Termux:API camera access using one temporary rear-camera photo, then
deletes it. These commands require the `termux-api` package and the companion
Android app from Termux's same installation source. Without the companion,
desktop mic remains available through Termux's OpenSL bridge and Android Camera
is the camera fallback. Termux and Termux:API have separate Android permissions.

### `tx manager`

Read the Native Termux manager snapshot without starting a service or guest.
The read-only commands report installed PRoot guests, known desktop profiles,
and current/planned display assignments. `displays` reports socket/lock/server
occupancy and flags when a v2 display migration is needed. It never edits an
assignment or moves a live session. The schemas are documented under
`docs/v3/schemas/manager-*.schema.json`. For a local Unix-socket API, run
`tx manager serve`; it stays in the foreground until Ctrl-C, uses a private
socket and exposes no TCP listener. Python 3 is optional for this command.

**Availability:** the read-only commands and socket service are in current
source; they are not in the withdrawn v2.0.0 APT package. JSON payloads use
`schema_version` and `command` for compatibility. The display JSON uses schema
`1.3.0`; a reported active guest assignment is not OS-level socket-owner
proof.

```bash
tx manager status [--json]
tx manager guests [--json]
tx manager displays [--json]
tx manager capabilities [--json]
tx manager migrate --apply sha256:PLAN_ID
tx manager migrate --recover
```

`tx manager displays --json` includes a per-guest migration preview. It labels
assignments as `initialize`, `keep`, or `move` and reports active-session, other-active-session,
target-conflict, invalid-registry, or registry-mismatch blockers. The preview itself is read-only and includes a state-bound `plan_id`. Apply only
a ready plan copied from the current snapshot with `tx manager migrate --apply
sha256:PLAN_ID`. Apply refuses stale plans, active sessions, occupied targets,
malformed or mismatched registries, and guests whose lifecycle is not stopped.
Profile and registry files are journaled before the write; a failed write rolls
both back. If the process is interrupted, guest starts are blocked until
`tx manager migrate --recover` restores the prior files. No desktop is stopped
or restarted by migration.

### `tx control`

Open the mobile-first Control Center in a browser on this device. It shows
manager health, installed guests, active desktops, display conflicts, a display
migration preview, and copyable host commands. For installed Ternux desktop
guests, it can request start or stop through a state-bound plan, explicit browser
confirmation, and a durable local job record. It does not manage generic OCI
images or perform install/uninstall. The loopback-only server uses a one-hour
in-memory bearer token, same-origin and CSRF checks for actions, and fixed typed
CLI arguments. Press Ctrl-C in Termux to stop it; unfinished jobs are marked for
status reconciliation on the next launch. Python 3 is optional: `pkg install
python`. Use `--no-open` to print the local link without launching a browser.

```bash
tx control
tx control --no-open
```

The dashboard and manager commands are source-only until the next stable v2-major
release; they are not part of the withdrawn v2.0.0 package.

### `tx guides`

Run `tx guides` in the Termux host or a guest for a color-organized quick start, common command examples, guest shell shortcuts, and direct installation, workload, graphics-persistence, and daily-use links. It performs no install or browser action.

### `tx storage`

Android shared storage is mounted at `/sdcard` for managed guest commands and desktop sessions when Termux has Android storage permission. Run `termux-setup-storage` once if it is unavailable. The `storage grant` command remains available for legacy scoped mounts; an already-running desktop keeps its current mounts until that session exits.

```bash
ternux storage list
ternux storage grant /sdcard/Llms
ternux storage revoke /sdcard/Llms
```

### `tx install`

Install or reinstall the full ternux desktop environment.

```bash
tx install [options]
```

| Option | Description |
|--------|-------------|
| `--yes` | Defaults, no questions |
| `--user NAME` | Linux guest user name (default: `ternux`) |
| `--distro NAME` | Select one of 15 named recipes. Ternux v2 support is limited to Debian, Ubuntu, and Alpine; Kali is qualified on the documented reference device. |
| `--distros LIST` | Install multiple independent guests in sequence, e.g. `debian,ubuntu,kali,alpine`. |
| `--locale LANG` | Locale (default: `en_US.UTF-8`) |
| `--backend auto\|zink\|virgl` | GPU backend (default: auto) |
| `--zsh` | Use zsh instead of bash |
| `--with-dev` | Install development tools |
| `--with-llm` | Build llama.cpp with Vulkan |
| `--with-network` | Install network tools |
| `--with-media` | Install media tools |
| `--with-blender` | Install Blender and Xvfb for headless GPU rendering |
| `--all` | Install all optional workloads |
| `--resume` | Skip completed phases and restore the interrupted run’s saved optional workload set |
| `--ui MODE` | Installer renderer: `auto` (default), `dashboard`, `plain` or `off` |
| `--plain` | Shorthand for `--ui plain`: plain scrolling output instead of the dashboard |
| `--no-anim` | Freeze the spinner and colour cycling |

The 15 named recipes follow this stable order: Debian (`debian`/`db`), Ubuntu (`ubuntu`/`ub`), Kali (`kali`), Alpine (`alpine`/`alp`), Arch Linux (`archlinux`/`archx`), Fedora (`fedora`/`fed`), openSUSE (`opensuse`/`suse`), Void (`void`/`vsh`), Artix (`artix`/`art`), Chimera (`chimera`/`chim`), Deepin (`deepin`/`deep`), Manjaro (`manjaro`/`manj`), Pardus (`pardus`/`par`), Rocky Linux (`rockylinux`/`rock`), and Adelie (`adelie`/`adel`). Kali uses the official `kalilinux/kali-rolling` OCI image because Termux's packaged PRoot-Distro does not include a Kali alias. The image is a weekly rolling snapshot; Ternux installs a curated command-line security set by default, while larger Kali metapackages remain an explicit user choice. **The v2 support promise remains Debian, Ubuntu, and Alpine.** On 2026-11-15, the existing Kali guest passed current reference-device checks for startup, doctor/verify, Zink/Turnip rendering, Firefox, Avro switching, PulseAudio loopback, security-tool presence, and window fitting; see the [device verification record](audit/DEVICE-VERIFICATION.md#2026-11-15-kali-reference-device-desktop-qualification). This qualifies that installed guest on the documented Adreno 825 device, but does not replace clean-install/browser CI or qualify other devices. Debian, Ubuntu, and Alpine have the full v2 support matrix. The owner reports physical keyboard input switching in all installed distros; a focused live Alpine Xfce Terminal check on 2026-11-16 also switched Avro with synthetic Ctrl+Space. The live checks do not qualify every application. Use the checklist for interactive multi-select; for automation, pass comma-separated aliases to `--distros`. Each desktop profile gets independent state and a tagged Termux:X11 display. Separate Android windows require the [Termux:X11 nightly app](https://github.com/termux/termux-x11/releases/tag/nightly); older apps fall back to one shared window and cannot reliably switch between concurrently running guests. `xgo` lists installed guests and identifies shell-only images. The distro picker uses the same keyboard checklist as optional apps: Up/Down or `j`/`k` moves, Space or a number toggles, Enter confirms, and `q` keeps the current default profile. Multiple guests are selected in one pass; a numbered comma list is available when raw-key input is unavailable. Before changes, the installer shows the chosen guest, backend, user, workloads, and storage estimate for confirmation. If an optional workload fails after the base desktop verifies, the guest remains marked ready, the UI reports a warning, and `tx install --resume` retries the unfinished phase while the command returns nonzero.

### `tx distro`

Bare `tx distro` prints the management overview and the supported operations.
`tx distro list` shows the complete managed desktop catalog in install order,
including short name, default X11 display, package family, recommended graphics
route, and whether each profile is installed and verified. Generic OCI guests
appear in a separate section because they do not receive a desktop recipe.

Use the installed `tx` command as the short interface; `ternux` remains available for compatibility. `tx distro search QUERY` searches PRoot-Distro OCI images. `tx distro shell NAME` opens the configured regular user for Ternux profiles (generic images keep their image default); `tx distro exec NAME -- COMMAND` works with any installed guest. Root remains explicit through the distro root shortcuts such as `alproot`. Use `tx distro image-install IMAGE[:TAG] [NAME]` to install a generic OCI image; such an image is shell-ready. Remove a registered Ternux guest with `tx distro uninstall NAME [--yes]`; the command refuses unregistered PRoot guests and clears the OCI registry entry after removal. Named aliases map to APT (Debian, Ubuntu, Kali, Deepin, Pardus), APK (Alpine, Adelie, Chimera), pacman (Arch Linux, Artix, Manjaro), DNF (Fedora, Rocky Linux), Zypper (openSUSE), or XBPS (Void). Arbitrary OCI images are shell-ready but do not receive a desktop automatically. Optional software workloads currently target APT guests. Desktop management is `tx start [NAME ...]`, `tx stop [NAME|--all]`, `tx restart NAME`, and `tx status [NAME]`; bare `tx status` reports every installed managed desktop guest, while a name narrows it to one. Bare `tx start` selects Debian when installed. Pass multiple full or short names to start several desktops sequentially, for example `tx start debian ubuntu kali alpine` or `tx start ub db kali alp`. A failed guest does not prevent later requested guests from starting; the command returns nonzero and reports each result. With `--json`, multi-start returns one JSON object with the requested guests and per-guest outcomes. The [Termux:X11 nightly app](https://github.com/termux/termux-x11/releases/tag/nightly) is required for separate tagged windows and reliable switching among concurrently running desktops. Interactive `tx stop` lists every running guest and display, then accepts one or more indexes, short names, or full names separated by spaces or commas; enter `0` to cancel. `tx stop --all` stops all Ternux desktop sessions. Explicit `tx stop db`, `tx stop ub`, `tx stop kali`, and `tx stop alp` target only the named guest. Debian, Ubuntu, and Alpine are device-qualified v2 profiles on the documented reference device; Alpine has a documented keyboard-event limitation. The remaining 12 profiles lack physical-device qualification. Short shells: `db`/`dbr`/`dbroot` Debian, `ub`/`ubr`/`ubroot` Ubuntu, `kali` for a Kali user shell and `kalir`/`kaliroot` for root, `alp`/`alpr`/`alproot` Alpine, `archx`/`archroot` Arch, `fed`/`fedr` Fedora, `suse`/`suser` openSUSE, and `vsh`/`vroot` Void. The previous `ubroot` and `alproot` root aliases remain available.

With no workload flags, an interactive install opens the categorized checklist.
Use Up/Down or `j`/`k` to move, Space or an item's number to select multiple
items, Enter to review the plan, and `q` for the base desktop. Individual
managed extension choices include llama.cpp CPU + Vulkan, the Stable Diffusion
CPU + Vulkan preview, and experimental SM8735/V73 HTP. The `--with-llm` flag
remains a separate llama.cpp source build. The suggestion uses the detected GPU
route and reports RAM and free storage limits. `--yes` skips the chooser and
keeps the base profile.

### `tx start`

Start the Xfce4 desktop session in its own detached session so it survives the launching shell closing. The command returns only after Termux:X11 and the XFCE session, window manager, and desktop are ready, then brings the Termux:X11 app to the foreground. New profile defaults reserve `:0` for the future native Termux workspace, then assign Debian `:1`, Ubuntu `:2`, Kali `:3`, Alpine `:4`, and the remaining named profiles `:5` through `:15`. Existing profiles keep their saved display IDs until an explicit migration; use `tx manager displays` and its state-bound migration before starting a newly added profile if an old assignment overlaps. Startup refuses an occupied socket or matching Termux:X11 server and never removes an unproven socket. Re-running it focuses the existing desktop instead of starting a duplicate, including when its supervisor marker is missing but the live XFCE session remains. If startup fails, it returns an error and points to `~/.local/share/ternux/session/desktop.log`. Use `tx status` or `tx logs desktop tail` to inspect the session. Each guest has its own launcher under `~/.local/share/ternux/distros/NAME/launcher.sh`; `~/x.sh` remains a compatibility link for the most recently installed profile. After a CLI update, the selected launcher is refreshed when needed. The launcher:
1. Cleans up any previous session
2. Starts PulseAudio with TCP bridge
3. Launches Termux:X11 display
4. Starts the VirGL server if needed
5. Enters the selected PRoot guest and starts Xfce4

```bash
tx start                         # saved guest profile
tx start ubuntu                  # explicitly start Ubuntu
tx start debian ubuntu kali alpine # start all four sequentially
tx start ub db kali alp            # same, using short names
```

### `tx stop`

Interactive stop lists running guests and displays, then lets you choose one or
more by number or name. Separate choices with spaces or commas; enter `0` to
cancel. Use `--all` to close every managed Ternux desktop. Each stop targets
only that guest's launcher and tagged X11 window.

```bash
tx stop                      # choose one/many running sessions
tx stop --all               # stop every managed guest desktop
tx stop db                   # stop Debian only
tx stop ub                   # stop Ubuntu only
tx stop alp                  # stop Alpine only
```

The stop operation signals only the selected guest's verified launcher process
group and removes that guest's state markers. Other displays and shared audio
services remain available.

### `tx restart`

Restart the desktop session (stop + 1 second delay + start).

```bash
tx restart
tx restart ubuntu
```

### `tx doctor`

Run categorized diagnostics. Each check is reported as `ok`, `warn`, `fail` or
`info` with a fix hint. A bare command checks host/system state, every installed
managed guest, graphics and Debian extension health. Pass one guest name or
short name to scope guest and graphics checks, or pass `gpu` to run graphics
checks only.

| Category | Checks |
|---|---|
| `system` | architecture, storage, memory, battery temperature, state directory |
| `host` | proot-distro, installed guests, Termux:X11, PulseAudio, curl, Android child-process setting |
| `guest` | OS and architecture, glibc when available, sudo, desktop commands, package database, free space for each installed managed guest |
| `graphics` / `gpu` | Vulkan, GPU, per-guest backend, KGSL node, Turnip layout, renderer, launcher, VirGL |
| `extensions` | Debian extension packages, versions, runtime libraries and launcher files |

Guest checks run through a read-only probe in each guest. An unreachable guest
is reported as `info`, not as a fault. `gpu` is an alias for the `graphics`
category; `tx doctor db gpu` narrows it to Debian.

```bash
tx doctor [CATEGORY|DISTRO ...] [--quick] [--strict] [--json]
tx doc gpu
tx doctor kali
tx doctor db gpu
```

| Option | Effect |
|---|---|
| `CATEGORY` | run one or more categories, for example `tx doctor extensions` |
| `DISTRO` | inspect one guest by full name or short name, e.g. `kali`, `db`, or `ub` |
| `gpu` | run GPU and graphics checks only |
| `--quick` | skip guest login probes |
| `--strict` | exit `1` when a warning exists and `2` when a check fails; the default exit status stays `0` |
| `--json` | machine-readable output with one check row per guest |

**JSON output example** (abridged; `schema_version` 2 keeps the original
`issues` and `recommended_actions` arrays and adds `summary` and `checks`):
```json
{
  "command": "doctor",
  "status": "warning",
  "gpu": "Adreno (730)",
  "backend": "zink",
  "renderer": "zink Vulkan (Adreno ... (MESA_TURNIP))",
  "vulkan": "yes",
  "schema_version": 2,
  "summary": {"ok": 30, "warn": 1, "fail": 0, "info": 3},
  "checks": [
    {"id": "ext_llama-vulkan", "category": "extensions", "status": "ok",
     "title": "llama-vulkan: ternux-llama-vulkan-linux-arm64-b11582",
     "detail": "", "fix": ""}
  ],
  "issues": ["phantom_process_killer_enabled"],
  "recommended_actions": ["Review Android process restrictions and other Signal 9 causes (see docs)"]
}
```

### `tx repair`

Inspect and repair common issues in 6 steps:
1. Repair a broken curl/OpenSSL toolchain
2. Install a missing `termux-x11-nightly` host package
3. Validate/apply the configured GPU backend, reinstall missing validated
   Turnip targets when needed, and align the launcher with that backend
4. Regenerate a still-missing or syntactically broken launcher
5. Clear a populated Mesa shader cache
6. Add a missing PulseAudio TCP bridge

A successful health check is not counted as a performed repair. A partial
failure returns non-zero; restart the desktop and verify the renderer after a
backend or launcher repair.

```bash
ternux repair
```

### `tx verify`

Verify installation completeness for the active guest, or select a guest by
full name or its short command. Without an active guest, verification uses the
saved installed profile, then Debian, then another installed Ternux profile. It
checks host binaries, the selected launcher, guest services, and GPU driver
files. A failed verification returns a nonzero exit status in both human and
`--json` modes.

```bash
ternux verify [DISTRO] [--json]
tx verify db --json
tx verify ub --json
tx verify alp --json
```

### `tx benchmark`

Run GPU benchmarks inside the Debian container (requires active desktop).

```bash
ternux benchmark [--json]
```

Benchmarks:
- **glmark2** — OpenGL 2.0 performance score
- **vkmark** — Vulkan performance score
- **Renderer inspection** — identifies Zink/Turnip, VirGL/virpipe, or software
  rendering; a VirGL name alone does not prove a hardware-backed path

### `tx profile`

Device hardware profiling and management.

```bash
ternux profile <subcommand> [name]
```

| Subcommand | Description |
|------------|-------------|
| `show` | Display current device profile |
| `save [name]` | Save current profile (default: `default`) |
| `load [name]` | Load and display a saved profile |
| `list` | List all saved profiles |
| `compare [a] [b]` | Compare two profiles (b defaults to `current`) |

**JSON output** (`tx profile --json`):
```json
{
  "command": "profile",
  "status": "complete",
  "android_version": "14",
  "architecture": "aarch64",
  "gpu": "Adreno (730)",
  "backend": "zink",
  "vulkan": "yes (Adreno)"
}
```

### `tx backend`

GPU backend management.

```bash
ternux backend <subcommand> [backend]
```

| Subcommand | Description |
|------------|-------------|
| `show` | Display current backend configuration |
| `set auto\|zink\|virgl` | Change GPU backend |
| `detect` | Auto-detect the correct backend |
| `update` | Reinstall Ternux's checksum-validated Debian Turnip driver for the configured Zink route; restart the desktop afterward. It does not update Android's vendor driver. |

**JSON output** (`tx backend --json`):
```json
{
  "command": "backend",
  "status": "ok",
  "gpu": "Adreno (730)",
  "backend": "zink",
  "renderer": "zink Vulkan (Adreno ... (MESA_TURNIP))",
  "vulkan": "yes (Adreno)",
  "available_backends": "zink,virgl"
}
```

### `tx gpu`

Manage the guest GPU userspace driver. `update` refreshes Ternux's pinned,
SHA-256-validated Debian Turnip driver on the Zink route; restart the desktop
afterward. It does not update Android's vendor/kernel driver. On VirGL, `update`
reports that no guest Turnip driver is used.

```bash
ternux gpu show
ternux gpu update
ternux gpu update --json
```

`tx backend update` remains an equivalent command.

### `tx info`

Show Android SDK, device and CPU details, total and available memory, free
storage, load average when Android exposes it, GPU/backend, active OpenGL
renderer, Vulkan state, and whether the phantom process setting is readable.
`Renderer: not running` means Termux:X11 is stopped; `unknown` means a display
was available but the guest renderer query did not return a name. Graphics
state reports `DISPLAY_STOPPED` while no desktop display is active. On Android
builds that deny Termux access to the Settings provider, the phantom setting is
reported as unreadable rather than implying that it is enabled or disabled. Use
`tx status [DISTRO]` for the live desktop lifecycle and `tx doctor --quick` for
host readiness.

GPU detection uses Android graphics properties and available kernel interfaces.
Adreno devices with KGSL use Zink/Turnip only for profiles with pinned Mesa
assets: Debian, Ubuntu, Kali, Alpine, Arch Linux, Fedora, openSUSE, Void and
Deepin. Kali Rolling uses the pinned Debian Testing Mesa overlay. On
2026-11-15, Vulkan enumeration and Zink GLX were observed on all four installed
guests (Debian :1, Ubuntu :2, Kali :3, Alpine :4). Full profile qualification
remains limited to Debian, Ubuntu and Alpine. Other profiles and GPU families
select VirGL; when VirGL cannot render, the launcher selects llvmpipe as the
last software route.
The selected backend is configuration, not proof that the desktop is currently
using hardware acceleration: check the active renderer and `Graphics state`.

```bash
ternux info [--json]
```

### `tx state`

Show completed installer phases, saved user/distro/locale configuration,
installed managed profiles with their display IDs and setup state, plus recent
benchmark and repair history. JSON output includes `installed_profiles`.

```bash
ternux state [--json]
```

### `terfetch`

`terfetch` is a standalone system summary installed on the Termux host and in
each managed guest. Ternux suppresses Termux's stock login banner with the
supported `~/.hushlogin` switch; interactive Bash and Zsh shells then show
Terfetch instead. Alpine's Ash login shell uses its profile hook. The native
Termux host randomly selects from Android, Ternux Workstation, all 15 managed
distro logos, and Sobuj's monogram on each login. Other variants show a
centered `Presented by @soobujmiah` credit below the logo and system facts;
the special Sobuj monogram puts `Presented by` above the mark and has no second
credit. PRoot guests use a stable official ASCII logo for
their distro from Terfetch's built-in catalog, including the managed distro
profiles. Their creator credit is centered below the logo and facts. Daily-use
host commands or guest and distro package-manager commands appear as a separate
colorful footer below the credit. The logo and facts stay side by side: the logo
uses about one-third of the terminal width and facts use the rest. Each fact
stays on one row. Terfetch hides a fact when its complete label and value do not
fit, then shows it again after a wider resize and the next prompt refresh. Values
are never wrapped or shortened. Terfetch does
not require Fastfetch at runtime. It reports environment, architecture, user,
locale, init, privilege level, package manager and count, kernel, uptime, shell,
terminal, CPU/GPU model, memory and storage, plus device and display details
when available. Use
`TERFETCH_NO_AUTORUN=1` to hide the automatic summary in one shell.
Run `terfetch --json` for structured output, or `terfetch --help` for its
standalone options. The implementation lives in `share/terfetch/` so it can be
extracted into its own repository later.

```bash
terfetch
terfetch --json
```

### `tx status`

With no guest name, report every installed managed desktop guest in a single
workspace overview. Pass a full or short guest name for one session. `running`
requires the guest to complete a bounded X11 query; a stale socket and surviving
process names do not qualify. `pulseaudio` reports whether the host daemon process exists, while
`pulseaudio_ready` independently verifies the configured loopback TCP route
used by Debian applications.

```bash
tx status [--json]
tx status kali --json
```

A one-guest JSON object includes `lifecycle`, `x11_running`, `pulseaudio`,
`pulseaudio_ready`, `virgl`, `launcher`, `display`, `desktop_log`, and
`desktop_pid`. A bare multi-guest query returns `guest_count` and a `guests`
array with those per-guest objects.

### `tx logs`

View and manage installer, host, and per-guest desktop log files. `list` shows
their paths and sizes; `desktop show` and `desktop tail` select the active or
last saved guest. Add a distro name to inspect one guest directly, for example
`tx logs desktop show kali`.

```bash
ternux logs <subcommand> [n]
```

| Subcommand | Description |
|------------|-------------|
| `show [n]` | Show last n log lines (default: 50) |
| `tail` | Follow log output in real time |
| `clear` | Clear the log file |
| `list` | List available log files |

### `tx extension`

List, install, repair, or remove optional release-based Linux ARM64 extensions.
The host CLI delegates these operations to the selected Debian guest.

```bash
ternux extension list
ternux extension install llama-vulkan
ternux extension install stable-diffusion
ternux extension install llama-htp-experimental
ternux extension repair stable-diffusion
ternux extension remove stable-diffusion
```

`llama-vulkan` is the CPU + Vulkan prerelease. `stable-diffusion` installs a pinned `sd-cli` preview; Adreno Vulkan generation has a bounded device test, while CPU image quality is unqualified. Model weights remain user-provided. Repair checksum-verifies and atomically replaces a recognized install, restoring the prior copy if replacement fails. Remove deletes only the recognized managed extension directory and leaves model weights alone. `llama-htp-experimental` is an
experimental SM8735/V73 route with known configuration limits; it is not a
supported release feature and has no automatic CPU/GPU fallback. See the
[CPU/Vulkan guide](https://github.com/soobujmiah/ternux/blob/main/guides/llama-vulkan-extension.md)
[Stable Diffusion guide](https://github.com/soobujmiah/ternux/blob/main/guides/stable-diffusion-vulkan-extension.md), and [HTP guide](https://github.com/soobujmiah/ternux/blob/main/guides/llama-htp-experimental.md).

### `tx update`

Update the CLI using its install source. APT-managed installations check and update through APT; other installations self-update from GitHub.

```bash
ternux update [check]
```

| Subcommand | Description |
|------------|-------------|
| *(none)* | Update from the configured APT repository when package-managed; otherwise fetch and install the latest GitHub version |
| `check` | Check for updates without installing; APT-managed installs use the configured package candidate |

### `tx uninstall`

Scoped removal of ternux components. With no action, an interactive menu is
shown. In a non-interactive shell, name the action explicitly.

```bash
ternux uninstall [session|launcher|state|container|host-cli|all] [--yes]
```

Options menu:
- 1 / `session` — stop the desktop and remove stale sockets
- 2 / `launcher` — remove `~/x.sh` and the delimited shell-alias blocks
- 3 / `state` — remove Ternux state, logs and stopped manager socket data (not the containers)
- 4 / `container` — delete the Debian container and everything inside it
- 5 / `all` — remove Ternux components, including host CLI and its update backups
- 6 / `host-cli` — remove only the Termux-side Ternux CLI
- 0 — cancel

`all` removes the Ternux CLI and update backups but preserves Termux itself,
shared Termux packages, other PRoot guests and non-empty capture folders. It does
not revoke storage access, reset mirrors, or revert the Termux PulseAudio
configuration. Container deletion requires confirmation. `--yes` is intended
only for a caller that deliberately accepts irreversible data loss.

## Shell completion

Bash completion is available in `share/ternux-completion.bash`:

```bash
source share/ternux-completion.bash
```

This provides tab-completion for all commands, subcommands, flags,
and saved profile names.

## Environment variables

Every variable below is read at startup; command-line flags always win.

| Variable | Used by | Effect |
|---|---|---|
| `TERNUX_UI` | `install` | Renderer selection: `auto`, `dashboard`, `plain`, `off` |
| `TERNUX_NO_ANIM` | `install` | `1` freezes the spinner and colour cycling |
| `TERNUX_YES` | `install` | `1` accepts the documented defaults without prompting |
| `TERNUX_QUIET` | all | Suppresses shared informational messages |
| `TERNUX_JSON` | documented commands | Requests structured output |
| `TERNUX_VERBOSE` | all | Enables debug messages where a command provides them |
| `TERNUX_USER` | all | Debian account the CLI targets; normally read from saved state |
| `TERNUX_STATE_DIR` | all | Phase state and saved choices (default `~/.local/share/ternux`) |
| `TERNUX_LOG_DIR` | all | Log directory (default `$TMPDIR/ternux`) |

Full descriptions: [Configuration → Installer output](CONFIGURATION.html#installer-output).

---

## Architecture

```
bin/ternux          ← Thin command/flag dispatcher
lib/core.sh         ← Shared I/O, JSON builder, state, logging
lib/help.sh         ← Central help system
lib/detect.sh       ← Device detection (GPU, Vulkan, Android, etc.)
lib/desktop.sh      ← Desktop lifecycle (start, stop, restart)
lib/doctor.sh       ← Diagnostics + verification
lib/info.sh         ← System information
lib/backend.sh      ← GPU backend management
lib/profile.sh      ← Device profiling
lib/benchmark.sh    ← GPU benchmarks and renderer classification
lib/repair.sh       ← Repair engine using validated phase implementations
lib/logs.sh         ← Log management
lib/update.sh       ← Self-update
lib/state.sh        ← Installation state
lib/uninstall.sh    ← Scoped, confirmed component removal
lib/phases.sh       ← 11-phase installation implementation
lib/ui.sh           ← Installer renderer: dashboard, plain frame, log stream
```

Adding a new command:
1. Create `lib/<name>.sh` with a `tnx_cmd_<name>()` function
2. Add help in `lib/help.sh` with `tnx_help_<name>()`
3. Done — auto-discovered by the dispatcher

---

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · Apache-2.0*
