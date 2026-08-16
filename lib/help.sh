# =============================================================================
#  ternux — help system and command registry
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah) — MIT License
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
  ${TNX_CG}start${TNX_C0}      Start the desktop session
  ${TNX_CG}stop${TNX_C0}       Stop the desktop session
  ${TNX_CG}restart${TNX_C0}    Restart the desktop session
  ${TNX_CG}doctor${TNX_C0}     Run system diagnostics  ${TNX_CD}[--json]${TNX_C0}
  ${TNX_CG}repair${TNX_C0}     Auto-fix common issues
  ${TNX_CG}verify${TNX_C0}     Verify installation      ${TNX_CD}[--json]${TNX_C0}
  ${TNX_CG}benchmark${TNX_C0}  Run GPU benchmarks       ${TNX_CD}[--json]${TNX_C0}
  ${TNX_CG}profile${TNX_C0}    Device hardware profile  ${TNX_CD}[--json]${TNX_C0}
  ${TNX_CG}backend${TNX_C0}    GPU backend management   ${TNX_CD}[--json]${TNX_C0}
  ${TNX_CG}info${TNX_C0}       System information       ${TNX_CD}[--json]${TNX_C0}
  ${TNX_CG}state${TNX_C0}      Installation state       ${TNX_CD}[--json]${TNX_C0}
  ${TNX_CG}logs${TNX_C0}       View/manage log files
  ${TNX_CG}update${TNX_C0}     Self-update ternux CLI
  ${TNX_CG}uninstall${TNX_C0}  Remove ternux components

${TNX_CW}Global options:${TNX_C0}
  --help, -h    Show help for any command
  --json        Machine-readable JSON output (AI-native)
  --verbose     Show detailed debug output
  --quiet       Suppress non-critical messages

${TNX_CW}Examples:${TNX_C0}
  ternux doctor --json     ${TNX_CD}AI-readable diagnostics${TNX_C0}
  ternux start             ${TNX_CD}Launch the desktop${TNX_C0}
  ternux backend set zink  ${TNX_CD}Switch GPU backend${TNX_C0}
  ternux profile save      ${TNX_CD}Snapshot device config${TNX_C0}

${TNX_CD}Run 'ternux <command> --help' for detailed help.${TNX_C0}
HELPEOF
}

# --- Command-specific help -------------------------------------------------
tnx_help_install() {
  cat << HELP
Usage: ternux install [options]

Install or reinstall the full ternux desktop environment.

Options:
  --yes                Defaults, no questions
  --user NAME          Debian user name (default: ternux)
  --locale LANG        Locale (default: en_US.UTF-8)
  --backend zink|virgl|auto  GPU backend (default: auto)
  --zsh                Use zsh instead of bash
  --with-dev           Install development tools
  --with-llm           Build llama.cpp with Vulkan
  --with-network       Install network tools
  --with-media         Install media tools
  --with-blender       Install Blender
  --all                Install all optional workloads
  --resume             Continue an interrupted install
HELP
}

tnx_help_start()     { echo "Usage: ternux start"; echo "Start the Xfce4 desktop session."; }
tnx_help_stop()      { echo "Usage: ternux stop"; echo "Stop the desktop session and clean up."; }
tnx_help_restart()   { echo "Usage: ternux restart"; echo "Restart the desktop session."; }
tnx_help_doctor()    { echo "Usage: ternux doctor [--json]"; echo "Run comprehensive system diagnostics. Supports --json for AI-readable output."; }
tnx_help_repair()    { echo "Usage: ternux repair"; echo "Auto-fix common issues: broken curl, missing X11, backend mismatch, stale cache."; }
tnx_help_verify()    { echo "Usage: ternux verify [--json]"; echo "Verify installation completeness. Checks binaries, launcher, container, GPU driver."; }
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
  clear        Clear the log file
  list         List available log files
HELP
}

tnx_help_update()    { echo "Usage: ternux update [check]"; echo "check — check for updates without installing. Otherwise, self-update ternux CLI from GitHub."; }
tnx_help_uninstall() { echo "Usage: ternux uninstall"; echo "Interactive removal of ternux components (launcher, state, container)."; }