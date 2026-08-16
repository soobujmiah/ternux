---
title: "CLI Reference"
description: "Complete reference for the ternux command-line interface — every command, subcommand, flag, and JSON output schema."
lang: "en"
alt_url: "/bn/docs/CLI.html"
---

# Ternux CLI Reference

The `ternux` CLI is the permanent management interface for installation,
diagnostics, repair, benchmarking, desktop lifecycle, and system information.

## Usage

```bash
ternux <command> [options] [subcommand]
```

## Global flags

| Flag | Description |
|------|-------------|
| `--help`, `-h` | Show help for any command |
| `--json` | Machine-readable JSON output (AI-native) |
| `--verbose` | Show detailed debug output |
| `--quiet` | Suppress non-critical messages |
| `--version`, `-V` | Show version information |

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
| `--resume` | Continue an interrupted install |

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
Vulkan, GPU/backend, renderer, phantom process killer, launcher, VirGL.

```bash
ternux doctor [--json]
```

**JSON output example:**
```json
{
  "command": "doctor",
  "status": "warning",
  "gpu": "Adreno (730)",
  "backend": "zink-turnip",
  "renderer": "zink Vulkan (Adreno ... (MESA_TURNIP))",
  "vulkan": "yes",
  "issues": ["phantom_process_killer_enabled"],
  "recommended_actions": ["disable phantom process killer"]
}
```

### `ternux repair`

Auto-fix common issues in 6 steps:
1. Broken curl/OpenSSL toolchain
2. Missing Termux:X11 package
3. Incorrect GPU backend
4. Missing or broken launcher
5. Stale Mesa shader cache
6. Missing PulseAudio TCP bridge

```bash
ternux repair
```

### `ternux verify`

Verify installation completeness. Checks binaries, launcher, Debian
container, and GPU driver files.

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
- **Renderer verification** — confirms hardware acceleration

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
  "backend": "zink-turnip",
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
  "backend": "zink-turnip",
  "renderer": "zink Vulkan (Adreno ... (MESA_TURNIP))",
  "vulkan": "yes (Adreno)",
  "available_backends": "zink-turnip,virgl"
}
```

### `ternux info`

Show system information summary: device model, Android version, GPU,
backend, renderer, Vulkan status, phantom killer state.

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

Interactive removal of ternux components (launcher, state, container).

```bash
ternux uninstall
```

Options menu:
- 1 — Stop running desktop session
- 2 — Remove launcher + shell aliases
- 3 — Remove installer state
- 4 — Delete Debian container (all data inside)
- 0 — Cancel

## Shell completion

Bash completion is available in `share/ternux-completion.bash`:

```bash
source share/ternux-completion.bash
```

This provides tab-completion for all commands, subcommands, flags,
and saved profile names.

## Architecture

```
bin/ternux          ← Thin dispatcher (82 lines)
lib/core.sh         ← Shared I/O, JSON builder, state, logging
lib/help.sh         ← Central help system
lib/detect.sh       ← Device detection (GPU, Vulkan, Android, etc.)
lib/desktop.sh      ← Desktop lifecycle (start, stop, restart)
lib/doctor.sh       ← Diagnostics + verification
lib/info.sh         ← System information
lib/backend.sh      ← GPU backend management
lib/profile.sh      ← Device profiling
lib/benchmark.sh    ← GPU benchmarks
lib/repair.sh       ← Auto-fix engine
lib/logs.sh         ← Log management
lib/update.sh       ← Self-update
lib/state.sh        ← Installation state
lib/phases.sh       ← Installation phases (9 verified phases)
```

Adding a new command:
1. Create `lib/<name>.sh` with a `tnx_cmd_<name>()` function
2. Add help in `lib/help.sh` with `tnx_help_<name>()`
3. Done — auto-discovered by the dispatcher

---

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · MIT*