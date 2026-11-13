# =============================================================================
#  ternux — help system and command registry
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah)
#  Licensed under the Apache License, Version 2.0.
#  https://github.com/soobujmiah/ternux
# =============================================================================

# shellcheck source=lib/core.sh
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"

# ---------------------------------------------------------------------------
# Help text registry: each command provides its own sub-function.
# Adding a new command = add a tnx_cmd_<name> function + tnx_help_<name>().
# ---------------------------------------------------------------------------

tnx_help() {
  local cmd="${1:-}"

  if [ -n "$cmd" ]; then
    if declare -F "tnx_help_${cmd}" >/dev/null 2>&1; then
      "tnx_help_${cmd}"
    else
      echo "No help available for '${cmd}'."
      echo "Run 'ternux --help' for command list."
    fi
    return 0
  fi

  cat << HELPEOF
${TNX_CG}ternux${TNX_C0} — ${TERNUX_DESC}
${TNX_CD}v${TERNUX_VERSION} · ${TERNUX_REPO}${TNX_C0}

${TNX_CW}Usage:${TNX_C0}
  ternux <command> [options] [subcommand]

${TNX_CW}Commands:${TNX_C0}
  ${TNX_CG}install${TNX_C0}    Install full desktop environment
  ${TNX_CG}distro${TNX_C0}     List installed guests, open shells, install images
  ${TNX_CG}manager${TNX_C0}    Read host status, guests and manager capabilities
  ${TNX_CG}extension${TNX_C0}  Manage checksum-verified guest extensions
  ${TNX_CG}storage${TNX_C0}    Grant or revoke scoped Android storage access
  ${TNX_CG}guides${TNX_C0}     Installation and ecosystem help links
  ${TNX_CG}start${TNX_C0}      Start the desktop session
  ${TNX_CG}stop${TNX_C0}       Stop the desktop session
  ${TNX_CG}restart${TNX_C0}    Restart the desktop session
  ${TNX_CG}doctor${TNX_C0}     Run system diagnostics  ${TNX_CD}[--json]${TNX_C0}
  ${TNX_CG}repair${TNX_C0}     Auto-fix common issues
  ${TNX_CG}verify${TNX_C0}     Verify installation      ${TNX_CD}[--json]${TNX_C0}
  ${TNX_CG}benchmark${TNX_C0}  Run GPU benchmarks       ${TNX_CD}[--json]${TNX_C0}
  ${TNX_CG}profile${TNX_C0}    Device hardware profile  ${TNX_CD}[--json]${TNX_C0}
  ${TNX_CG}backend${TNX_C0}    GPU backend management   ${TNX_CD}[--json]${TNX_C0}
  ${TNX_CG}gpu${TNX_C0}        GPU driver status/update
  ${TNX_CG}info${TNX_C0}       System information       ${TNX_CD}[--json]${TNX_C0}
  ${TNX_CG}state${TNX_C0}      Installation state       ${TNX_CD}[--json]${TNX_C0}
  ${TNX_CG}logs${TNX_C0}       View/manage log files
  ${TNX_CG}update${TNX_C0}     Update Ternux through its install source
  ${TNX_CG}uninstall${TNX_C0}  Remove ternux components

${TNX_CW}Global options:${TNX_C0}
  --help, -h    Show help for any command
  --version, -V Show version information
  --json        Machine-readable JSON output
  --verbose     Show detailed debug output
  --quiet       Suppress non-critical messages

${TNX_CW}Examples:${TNX_C0}
  ternux doctor --json     ${TNX_CD}machine-readable diagnostics${TNX_C0}
  tx start                 ${TNX_CD}Launch the desktop${TNX_C0}
  alp                       ${TNX_CD}Alpine user shell; alpr or alproot opens root${TNX_C0}
  db / dbr / dbroot         ${TNX_CD}Debian user / root shell${TNX_C0}
  ub / ubr / ubroot         ${TNX_CD}Ubuntu user / root shell${TNX_C0}
  ternux backend set zink  ${TNX_CD}Switch GPU backend${TNX_C0}
  ternux profile save      ${TNX_CD}Snapshot device config${TNX_C0}

${TNX_CD}Run 'ternux <command> --help' for detailed help.${TNX_C0}
HELPEOF
}

tnx_help_manager() {
  cat <<'HELP'
Usage: tx manager status|guests|capabilities [--json]

Read-only native Termux manager operations. This direct CLI path works without
the future Control Center service and does not start or modify guest sessions.

  tx manager status --json   Manager availability and active desktop names
  tx manager guests --json   Installed guests, desktop profile and display
  tx manager capabilities   List the operations implemented by this CLI core

JSON payloads use schema version 1.0.0. A missing proot-distro command is
reported as unavailable, not as an empty guest list.
Unknown operations and arguments are rejected. The capability list is built
from the same operation registry used by dispatch.
HELP
}

# --- Command-specific help -------------------------------------------------
tnx_help_extension() {
  cat <<'HELP'
Usage: ternux extension [list|install|repair|remove NAME]

Install or repair a checksum-verified Ternux Linux ARM64 extension release, or
remove one managed extension from your Debian user's
~/.local/opt/ternux-extensions directory.

Available names:
  llama-vulkan             llama.cpp CPU + Vulkan package (b11582)
  stable-diffusion         Stable Diffusion Vulkan preview; CPU quality unqualified
  llama-htp-experimental   llama.cpp Hexagon HTP for SM8735 (experimental)

Stable Diffusion models remain user-provided; install a compatible GGUF model
separately and pass its path to sd-cli.

Run it from the Termux host CLI; installation is delegated to the selected
Debian guest. Model weights are never downloaded. During fresh setup, selecting
Stable Diffusion provisions its Debian runtime libraries; the extension command
itself only installs extension files. Repair uses a verified same-artifact
manifest and rolls back if replacement fails. Remove deletes only a recognized
managed extension directory; model weights and other files are left alone. ADT
remains managed by its own installer.
HELP
}

tnx_help_install() {
  cat << HELP
Usage: ternux install [options]

Install or reinstall the full ternux desktop environment.

Options:
  --yes                Defaults, no questions
  --user NAME          Guest user name (default: ternux)
  --locale LANG        Locale (default: en_US.UTF-8)
  --backend zink|virgl|auto  GPU backend (default: auto)
  --zsh                Use zsh instead of bash (installs powerlevel10k)
  --shell bash|zsh     Choose the Termux shell without being asked
  --no-theme           Skip powerlevel10k when zsh is chosen
  --distro NAME        One of 15 named guest profiles (Debian/Ubuntu/Alpine qualified)
  --distros LIST       Install multiple profiles, e.g. debian,ubuntu,alpine
  --with-dev           Install development tools
  --with-llm           Build llama.cpp with Vulkan
  --with-network       Install network tools
  --with-media         Install media tools
  --with-blender       Install Blender and headless Xvfb support
  --all                Install all optional workloads
  --resume             Continue an interrupted install
  --ui MODE            Renderer: auto, dashboard, plain or off (default: auto)
  --plain              Plain scrolling output instead of the dashboard
  --no-anim            Freeze the spinner and colour cycling

Interactive install first shows a keyboard checklist of the 15 named profiles:
Up/Down or j/k moves, Space or a number toggles, Enter confirms; multiple
profiles can be selected in one pass. Debian is the recommended default; Debian,
Ubuntu, and Alpine have device qualification, with a documented Alpine keyboard
input limitation. The remaining profiles are not device-qualified. Arbitrary OCI images are
shell-only. Optional workload selection follows for APT-family guests only.
Workload checklist: Space or an item's number toggles; Enter reviews the plan;
q keeps the base desktop only. Use --yes for non-interactive defaults.
Run 'bash install.sh' for a fresh setup or 'ternux install' from the host CLI.
HELP
}

tnx_help_guides() { echo "Usage: ternux guides"; echo "Show installation, ecosystem tool, and daily-use guide links."; }

tnx_help_distro() { echo "Usage: tx distro [list|search QUERY|install NAME|image-install IMAGE [NAME]|shell NAME [-- COMMAND]|root NAME [-- COMMAND]|exec NAME -- COMMAND]"; echo "List guests, search OCI images, install a desktop profile or OCI image, or open a guest user/root shell."; }
tnx_help_start()     { echo "Usage: tx start [db|ub|alp|DISTRO]"; echo "Start Debian by default when installed; otherwise start the saved distro. Use db, ub, or alp to select Debian, Ubuntu, or Alpine."; }
tnx_help_stop()      { echo "Usage: tx stop [DISTRO|--all]"; echo "Interactive mode lists running guests; choose one or more by number or name (space/comma separated), or 0 to cancel. --all stops every Ternux desktop."; }
tnx_help_restart()   { echo "Usage: ternux restart [DISTRO]"; echo "Restart the named guest desktop session."; }
tnx_help_doctor() {
  cat << HELP
Usage: ternux doctor [CATEGORY...] [--quick] [--strict] [--json]

Run categorised diagnostics. Every check is reported as ok, warn, fail or info
with a fix hint; info is context and never counts as an issue.

Categories (default: all):
  system       architecture, storage, memory, battery temperature, state directory
  host         proot-distro, Debian container, Termux:X11, PulseAudio, curl,
               Android child-process monitoring
  guest        Debian glibc, passwordless sudo, desktop commands, dpkg state, disk
  graphics     Vulkan, GPU, backend, KGSL node, Turnip layout, renderer, launcher
  extensions   health of installed extensions (llama-vulkan, stable-diffusion, llama-htp-experimental)

Options:
  --quick      skip the Debian guest probe (guest and extension checks)
  --strict     exit 1 on warnings and 2 on failures (default exit status is 0)
  --json       machine-readable output (schema_version 2: summary and checks[]
               plus the original issues and recommended_actions arrays)

Examples:
  ternux doctor extensions         ${TNX_CD}only the extension checks${TNX_C0}
  ternux doctor graphics --json    ${TNX_CD}graphics checks for scripts${TNX_C0}
  ternux doctor --quick --strict   ${TNX_CD}fast host-only gate for automation${TNX_C0}
HELP
}
tnx_help_repair()    { echo "Usage: ternux repair"; echo "Auto-fix common issues: broken curl, missing X11, backend mismatch, stale cache."; }
tnx_help_verify()    { echo "Usage: ternux verify [DISTRO] [--json]"; echo "Verify the active guest by default, or select one with db, ub, alp, or its distro name. Checks host binaries, launcher, guest services, and GPU driver."; }
tnx_help_benchmark() { echo "Usage: ternux benchmark [--json]"; echo "Run GPU benchmarks (glmark2, vkmark) and renderer verification."; }

tnx_help_profile() {
  cat << HELP
Usage: ternux profile <subcommand> [name]

Subcommands:
  show          Display current device profile
  save [name]   Save current profile (default: 'default')
  load [name]   Load and display a saved profile
  list          List all saved profiles
  compare [a] [b]  Compare two profiles (b defaults to 'current')

Supports --json for machine-readable output.
HELP
}

tnx_help_backend() {
  cat << HELP
Usage: ternux backend <subcommand> [backend]

Subcommands:
  show             Display current backend configuration
  set auto|zink|virgl  Change GPU backend
  detect           Auto-detect the correct backend
  update           Refresh the validated Debian Turnip driver (Zink only)

Supports --json for machine-readable output.
HELP
}

tnx_help_info()      { echo "Usage: ternux info [--json]"; echo "Show system information summary: device, GPU, backend, renderer."; }
tnx_help_state()     { echo "Usage: ternux state [--json]"; echo "Show installation state: completed phases, configuration, history."; }

tnx_help_logs() {
  cat << HELP
Usage: ternux logs <subcommand>

Subcommands:
  show [n]     Show last n log lines (default: 50)
  tail         Follow log output in real time
  clear        Clear the CLI/install log file
  list         List available log files
  desktop [show|tail]  Read or follow the desktop session log
HELP
}

tnx_help_update()    { echo "Usage: ternux update [check]"; echo "check — inspect the latest stable release without installing. APT installs use pkg upgrade; other installs fetch the exact stable tag commit, stage and verify all CLI modules, and preserve the previous version for rollback."; }
tnx_help_uninstall() {
  echo "Usage: ternux uninstall [session|launcher|state|container|host-cli|all] [--yes]"
  echo "Interactive by default; destructive container removal requires confirmation."
}

tnx_help_gpu() {
  cat << HELP
Usage: ternux gpu <subcommand>

Subcommands:
  show       Show GPU/backend status
  update     Refresh the validated Debian Turnip driver (Zink only)

This updates the guest userspace driver, not Android's vendor driver.
Supports --json for machine-readable output.
HELP
}


tnx_help_storage() {
  cat <<'HELP'
Usage: ternux storage [list | grant DIRECTORY | revoke DIRECTORY]

Shared Android storage is not mounted by default. Grant an existing subdirectory
under /sdcard to expose only that directory to Ternux guest commands and desktop
sessions. The storage root itself cannot be granted. Granting may invoke
termux-setup-storage if Android storage permission is not configured.

Examples:
  ternux storage grant /sdcard/Documents
  ternux storage grant /sdcard/Llms
  ternux storage list
  ternux storage revoke /sdcard/Llms
HELP
}
