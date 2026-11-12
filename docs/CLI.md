---
title: "CLI Reference"
description: "Reference for ternux commands, subcommands, flags, and the commands that emit structured JSON."
lang: "en"
alt_url: "/bn/docs/CLI.html"
---

The host package installs both `tx` and `ternux` in `$PREFIX/bin`; either runs
the same management CLI for installation, diagnostics, repair, benchmarking,
desktop lifecycle, and system information. `tx` is an executable wrapper, so it
works in fresh shells and scripts without relying on a startup-file alias.

This reference describes the full **Termux host** command installed at
`$PREFIX/bin/ternux`. The Debian/Xfce terminal has a separate guest-aware
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

### `ternux guides`

Run `ternux guides` in the Termux host or Debian/Xfce guest to print direct installation, workload, ecosystem tool, graphics-persistence, and daily-use links. It performs no install or browser action.

### `ternux storage`

Android shared storage is mounted at `/sdcard` for managed guest commands and desktop sessions when Termux has Android storage permission. Run `termux-setup-storage` once if it is unavailable. The `storage grant` command remains available for legacy scoped mounts; an already-running desktop keeps its current mounts until that session exits.

```bash
ternux storage list
ternux storage grant /sdcard/Llms
ternux storage revoke /sdcard/Llms
```

### `ternux install`

Install or reinstall the full ternux desktop environment.

```bash
ternux install [options]
```

| Option | Description |
|--------|-------------|
| `--yes` | Defaults, no questions |
| `--user NAME` | Linux guest user name (default: `ternux`) |
| `--distro NAME` | Select one of 15 named package-family profiles; Debian, Ubuntu, and Alpine have partial integration evidence on one device. |
| `--distros LIST` | Install multiple independent guests in sequence, e.g. `debian,ubuntu,alpine`. |
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

The 15 named desktop profiles are `debian`, `ubuntu`, `alpine`, `archlinux`, `fedora`, `opensuse`, `void`, `kali`, `artix`, `chimera`, `deepin`, `manjaro`, `pardus`, `rockylinux`, and `adelie`. The guest prompt lists these profiles with family-matched recipes. Debian is recommended. Debian, Ubuntu, and Alpine have partial integration evidence on one Adreno 825 device (desktop, Zink/Turnip, audio routing, IBus and theme setup); clean installation and full application qualification remain open. The other 12 profiles have no physical-device qualification. Use the checklist for interactive multi-select; for automation, pass comma-separated aliases to `--distros`. Each desktop profile gets independent state and a tagged Termux:X11 display. Separate Android windows require the [Termux:X11 nightly app](https://github.com/termux/termux-x11/releases/tag/nightly); older apps fall back to one shared window and cannot reliably switch between concurrently running guests. `xgo` lists installed guests and identifies shell-only images. The distro picker uses the same keyboard checklist as optional apps: Up/Down or `j`/`k` moves, Space or a number toggles, Enter confirms, and `q` keeps the current default profile. Multiple guests are selected in one pass; a numbered comma list is available when raw-key input is unavailable. Before changes, the installer shows the chosen guest, backend, user, workloads, and storage estimate for confirmation. If an optional workload fails after the base desktop verifies, the guest remains marked ready, the UI reports a warning, and `ternux install --resume` retries the unfinished phase while the command returns nonzero.

Use the installed `tx` command as the short interface; `ternux` remains available for compatibility. `tx distro list` shows all installed PRoot guests and marks which ones have a Ternux desktop recipe. `tx distro search QUERY` searches PRoot-Distro OCI images. `tx distro shell NAME` opens the configured regular user for Ternux profiles (generic images keep their image default); `tx distro exec NAME -- COMMAND` works with any installed guest. Root remains explicit through the distro root shortcuts such as `alproot`. Use `tx distro image-install IMAGE[:TAG] [NAME]` to install a generic OCI image; such an image is shell-ready. Named aliases map to APT (Debian, Ubuntu, Kali, Deepin, Pardus), APK (Alpine, Adelie, Chimera), pacman (Arch Linux, Artix, Manjaro), DNF (Fedora, Rocky Linux), Zypper (openSUSE), or XBPS (Void). Arbitrary OCI images are shell-ready but do not receive a desktop automatically. Optional software workloads currently target APT guests. Desktop management is `tx start [db|ub|alp|NAME]`, `tx stop [NAME|--all]`, `tx restart NAME`, and `tx status NAME`; bare `tx start` selects Debian when installed. The [Termux:X11 nightly app](https://github.com/termux/termux-x11/releases/tag/nightly) is required for separate tagged windows and reliable switching among concurrently running desktops. Interactive `tx stop` lists every running guest and display, then accepts one or more indexes, short names, or full names separated by spaces or commas; enter `0` to cancel. `tx stop --all` stops all Ternux desktop sessions. Explicit `tx stop db`, `tx stop ub`, and `tx stop alp` target only the named guest. The named distro aliases in `tx distro list` report which profiles have recipes; Debian, Ubuntu, and Alpine have partial integration evidence on one device, while the remaining 12 profiles lack physical-device qualification. Short shells: `db`/`dbr`/`dbroot` Debian, `ub`/`ubr`/`ubroot` Ubuntu, `alp`/`alpr`/`alproot` Alpine, `archx`/`archroot` Arch, `fed`/`fedr` Fedora, `suse`/`suser` openSUSE, `vsh`/`vroot` Void, and `kal`/`kalr` Kali; each pair opens user/root shells. The previous `ubroot` and `alproot` root aliases remain available. Desktop start accepts the same short guest names: `tx start ub` or `tx start alp`.

With no workload flags, an interactive install opens the categorized checklist.
Use Up/Down or `j`/`k` to move, Space or an item's number to select multiple
items, Enter to review the plan, and `q` for the base desktop. Individual
managed extension choices include llama.cpp CPU + Vulkan, the Stable Diffusion
CPU + Vulkan preview, and experimental SM8735/V73 HTP. The `--with-llm` flag
remains a separate llama.cpp source build. The suggestion uses the detected GPU
route and reports RAM and free storage limits. `--yes` skips the chooser and
keeps the base profile.

### `ternux start`

Start the Xfce4 desktop session in its own detached session so it survives the launching shell closing. The command returns only after Termux:X11 and the XFCE session, window manager, and desktop are ready, then brings the Termux:X11 app to the foreground. Re-running it focuses the existing desktop instead of starting a duplicate, including when its supervisor marker is missing but the live XFCE session remains. If startup fails, it returns an error and points to `~/.local/share/ternux/session/desktop.log`. Use `ternux status` or `ternux logs desktop tail` to inspect the session. Each guest has its own launcher under `~/.local/share/ternux/distros/NAME/launcher.sh`; `~/x.sh` remains a compatibility link for the most recently installed profile. After a CLI update, the selected launcher is refreshed when needed. The launcher:
1. Cleans up any previous session
2. Starts PulseAudio with TCP bridge
3. Launches Termux:X11 display
4. Starts the VirGL server if needed
5. Enters the selected PRoot guest and starts Xfce4

```bash
ternux start                 # saved guest profile
ternux start ubuntu          # explicitly start Ubuntu
```

### `ternux stop`

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

### `ternux status`

Report desktop lifecycle and host service state. `running` requires the guest
to complete a bounded X11 query; a stale socket and surviving process names do
not qualify. `pulseaudio` reports whether the host daemon process exists, while
`pulseaudio_ready` independently verifies the configured loopback TCP route
used by Debian applications.

```bash
ternux status [--json]
```

The JSON object includes `lifecycle`, `x11_running`, `pulseaudio`,
`pulseaudio_ready`, `virgl`, `launcher`, and `desktop_pid`.

### `ternux restart`

Restart the desktop session (stop + 1 second delay + start).

```bash
ternux restart
ternux restart ubuntu
```

### `ternux doctor`

Run categorised diagnostics. Each check is reported as `ok`, `warn`, `fail` or
`info` with a fix hint; `info` is context and never counts as an issue.

| Category | Checks |
|---|---|
| `system` | architecture, storage, memory, battery temperature, state directory |
| `host` | proot-distro, Debian container, Termux:X11, PulseAudio, curl, Android child-process setting |
| `guest` | Debian glibc, passwordless sudo, desktop commands, dpkg state, free space |
| `graphics` | Vulkan, GPU, backend, KGSL node, Turnip layout, renderer, launcher, VirGL |
| `extensions` | installed extensions: package present, version, runtime libraries and launcher files |

The `guest`, `graphics` (Turnip layout) and `extensions` checks come from one
read-only probe that runs inside the Debian guest. An unreachable guest is
reported as `info`, not as a fault.

```bash
ternux doctor [CATEGORY...] [--quick] [--strict] [--json]
```

| Option | Effect |
|---|---|
| `CATEGORY` | run only the named categories, for example `ternux doctor extensions` |
| `--quick` | skip the Debian guest probe |
| `--strict` | exit `1` when a warning exists and `2` when a check fails; the default exit status stays `0` |
| `--json` | machine-readable output |

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

### `ternux repair`

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

### `ternux verify`

Verify installation completeness. Checks binaries, launcher, Debian
container, and GPU driver files. A failed verification returns a nonzero exit
status in both human and `--json` modes.

```bash
ternux verify [--json]
```

### `ternux benchmark`

Run GPU benchmarks inside the Debian container (requires active desktop).

```bash
ternux benchmark [--json]
```

Benchmarks:
- **glmark2** — OpenGL 2.0 performance score
- **vkmark** — Vulkan performance score
- **Renderer inspection** — identifies Zink/Turnip, VirGL/virpipe, or software
  rendering; a VirGL name alone does not prove a hardware-backed path

### `ternux profile`

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

**JSON output** (`ternux profile --json`):
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

### `ternux backend`

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

**JSON output** (`ternux backend --json`):
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

### `ternux gpu`

Manage the guest GPU userspace driver. `update` refreshes Ternux's pinned,
SHA-256-validated Debian Turnip driver on the Zink route; restart the desktop
afterward. It does not update Android's vendor/kernel driver. On VirGL, `update`
reports that no guest Turnip driver is used.

```bash
ternux gpu show
ternux gpu update
ternux gpu update --json
```

`ternux backend update` remains an equivalent command.

### `ternux info`

Show system information summary: device model, Android version, GPU,
backend, renderer, Vulkan status, and the readable Android child-process setting.

```bash
ternux info [--json]
```

### `ternux state`

Show installation state: completed phases, configuration, benchmark
and repair history.

```bash
ternux state [--json]
```

### `ternux logs`

View and manage log files.

```bash
ternux logs <subcommand> [n]
```

| Subcommand | Description |
|------------|-------------|
| `show [n]` | Show last n log lines (default: 50) |
| `tail` | Follow log output in real time |
| `clear` | Clear the log file |
| `list` | List available log files |

### `ternux extension`

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

### `ternux update`

Update the CLI using its install source. APT-managed installations check and update through APT; other installations self-update from GitHub.

```bash
ternux update [check]
```

| Subcommand | Description |
|------------|-------------|
| *(none)* | Update from the configured APT repository when package-managed; otherwise fetch and install the latest GitHub version |
| `check` | Check for updates without installing; APT-managed installs use the configured package candidate |

### `ternux uninstall`

Scoped removal of ternux components. With no action, an interactive menu is
shown. In a non-interactive shell, name the action explicitly.

```bash
ternux uninstall [session|launcher|state|container|host-cli|all] [--yes]
```

Options menu:
- 1 / `session` — stop the desktop and remove stale sockets
- 2 / `launcher` — remove `~/x.sh` and the delimited shell-alias blocks
- 3 / `state` — remove ternux state and logs (not the container)
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
