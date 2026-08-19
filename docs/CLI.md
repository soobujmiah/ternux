---
title: "CLI Reference"
description: "Reference for ternux commands, subcommands, flags, and the commands that emit structured JSON."
lang: "en"
alt_url: "/bn/docs/CLI.html"
---

The `ternux` CLI is the permanent management interface for installation,
diagnostics, repair, benchmarking, desktop lifecycle, and system information.

This reference describes the full **Termux host** command installed at
`$PREFIX/bin/ternux`. The Debian/Xfce terminal has a separate guest-aware
`/usr/local/bin/ternux` companion with only `status`, `info`, `doctor` (`verify`
is an alias), `env`, `--version`, and help. It rejects host lifecycle commands instead of nesting a
second PRoot session. Switch to Termux for every host command documented below.

Both commands are executed and version-checked during installation; file
presence by itself is not considered a successful CLI installation.

## Usage

```bash
ternux <command> [options] [subcommand]
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

### `ternux install`

Install or reinstall the full ternux desktop environment.

```bash
ternux install [options]
```

| Option | Description |
|--------|-------------|
| `--yes` | Defaults, no questions |
| `--user NAME` | Debian user name (default: `ternux`) |
| `--locale LANG` | Locale (default: `en_US.UTF-8`) |
| `--backend auto\|zink\|virgl` | GPU backend (default: auto) |
| `--zsh` | Use zsh instead of bash |
| `--with-dev` | Install development tools |
| `--with-llm` | Build llama.cpp with Vulkan |
| `--with-network` | Install network tools |
| `--with-media` | Install media tools |
| `--with-blender` | Install Blender |
| `--all` | Install all optional workloads |
| `--resume` | Skip completed phases and restore the interrupted run’s saved optional workload set |
| `--ui MODE` | Installer renderer: `auto` (default), `dashboard`, `plain` or `off` |
| `--plain` | Shorthand for `--ui plain`: plain scrolling output instead of the dashboard |
| `--no-anim` | Freeze the spinner and colour cycling |

### `ternux start`

Start the Xfce4 desktop session. Runs the launcher (`~/x.sh`) which:
1. Cleans up any previous session
2. Starts PulseAudio with TCP bridge
3. Launches Termux:X11 display
4. Starts the VirGL server if needed
5. Enters the PRoot Debian container and starts Xfce4

```bash
ternux start
```

### `ternux stop`

Stop the desktop session and clean up sockets.

```bash
ternux stop
```

Kills: termux-x11, pulseaudio, virgl_test_server, dbus.
Removes: stale X11 sockets, pulse socket.
Releases: wake-lock.

### `ternux restart`

Restart the desktop session (stop + 1 second delay + start).

```bash
ternux restart
```

### `ternux doctor`

Run comprehensive system diagnostics. Checks 11 categories:
Termux environment, storage, PRoot/Debian, Termux:X11, PulseAudio,
Vulkan, GPU/backend, renderer, Android child-process setting, launcher, VirGL.

```bash
ternux doctor [--json]
```

**JSON output example:**
```json
{
  "command": "doctor",
  "status": "warning",
  "gpu": "Adreno (730)",
  "backend": "zink",
  "renderer": "zink Vulkan (Adreno ... (MESA_TURNIP))",
  "vulkan": "yes",
  "issues": ["phantom_process_killer_enabled"],
  "recommended_actions": ["review Android process restrictions and other Signal 9 causes"]
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

### `ternux update`

Self-update ternux CLI from GitHub.

```bash
ternux update [check]
```

| Subcommand | Description |
|------------|-------------|
| *(none)* | Fetch and install latest version |
| `check` | Check for updates without installing |

### `ternux uninstall`

Scoped removal of ternux components. With no action, an interactive menu is
shown. In a non-interactive shell, name the action explicitly.

```bash
ternux uninstall [session|launcher|state|container|all] [--yes]
```

Options menu:
- 1 / `session` — stop the desktop and remove stale sockets
- 2 / `launcher` — remove `~/x.sh` and the delimited shell-alias blocks
- 3 / `state` — remove ternux state and logs (not the container)
- 4 / `container` — delete the Debian container and everything inside it
- 5 / `all` — perform all four actions above
- 0 — cancel

`all` does not uninstall Termux packages or the ternux CLI/libraries, revoke
storage access, reset mirrors, or revert the Termux PulseAudio configuration.
Container deletion requires confirmation. `--yes` is intended only for a
caller that deliberately accepts irreversible data loss.

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

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · MIT*