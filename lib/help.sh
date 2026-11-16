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
      echo "Run 'tx --help' for command list."
    fi
    return 0
  fi

  tnx_print_centered 'Ternux' "$TNX_CG"
  tnx_print_centered 'Workstation In Your Pocket' "$TNX_CG"
  tnx_print_centered 'Linux desktop for Android with Zink and VirGL graphics routes' "$TNX_CG"
  tnx_print_centered "v${TERNUX_VERSION} · ${TERNUX_REPO}" "$TNX_CG"
  printf '\n%sUsage:%s\n' "$TNX_CW" "$TNX_C0"
  tnx_print_two_col 'tx' '<command> [options] [subcommand]' "$TNX_CC"

  printf '\n%sComplete command tree:%s\n' "$TNX_CW" "$TNX_C0"
  tnx_print_centered '(use "tx COMMAND -h" for flags and details)' "$TNX_CD"
  tnx_help_tree_row install '[--distro NAME|--distros LIST|--resume|--yes|--all|--with-*]'
  tnx_help_tree_row distro '[list|search|find|install|uninstall|remove|image-install|shell|root|exec]'
  tnx_help_tree_row manager '[status|guests|displays|capabilities|migrate --apply PLAN|migrate --recover|serve]'
  tnx_help_tree_row control '[--no-open]'
  tnx_help_tree_row extension '[list|ls|install NAME|repair NAME|remove NAME|uninstall NAME]'
  tnx_help_tree_row storage '[list|grant DIRECTORY|revoke DIRECTORY]'
  tnx_print_two_col guides '[alias: guide]'
  tnx_print_two_col start '[DISTRO ...]'
  tnx_print_two_col stop '[DISTRO ...|--all]'
  tnx_print_two_col restart '[DISTRO]'
  tnx_print_two_col status '[DISTRO]'
  tnx_help_tree_row logs '[show|tail|clear|list|desktop [show|tail]|session [show|tail]]'
  tnx_help_tree_row doctor '[CATEGORY|DISTRO ...|--quick|--strict]'
  tnx_print_two_col repair 'Apply safe repairs for detected host or guest problems'
  tnx_print_two_col verify '[DISTRO]'
  tnx_print_two_col benchmark '[--json]'
  tnx_print_two_col profile '[show|save|load|list|compare]'
  tnx_print_two_col info '[--json]'
  tnx_print_two_col state '[--json]'
  tnx_help_tree_row backend '[show|set|detect|update]'
  tnx_help_tree_row gpu '[show|update]'
  tnx_print_two_col mic 'Request Android microphone permission'
  tnx_print_two_col cam 'Request Android camera permission'
  tnx_print_two_col update '[run|check]'
  tnx_help_tree_row uninstall '[session|launcher|state|container|host-cli|all] [--yes]'

  printf '\n%sCommand aliases:%s\n' "$TNX_CW" "$TNX_C0"
  tnx_print_two_col 'Command names' 'mng/manage → manager · guide → guides · ext → extension · doc → doctor' "$TNX_CD"
  tnx_print_two_col 'Distro names' 'db → debian · ub → ubuntu · alp → alpine · archx → archlinux · fed → fedora · suse → opensuse · vsh → void · art → artix · chim → chimera · deep → deepin · manj → manjaro · par → pardus · rock → rockylinux · adel → adelie' "$TNX_CD"
  tnx_print_two_col 'Guest shells' 'db/dbr/dbroot · ub/ubr/ubroot · kali/kalir/kaliroot · alp/alpr/alproot' "$TNX_CD"
  tnx_print_two_col 'Other shells' 'archx/archroot · fed/fedr · suse/suser · vsh/vroot' "$TNX_CD"
  tnx_print_two_col 'Full catalog' 'tx distro list'
  tnx_print_two_col 'Ternux host tools' 'xgo (choose desktops) · killx (stop desktop sessions) · sysmon (CPU/memory/GPU)'
  tnx_print_two_col 'Guest utility' 'clean-mesa (clear the selected guest Mesa shader cache)'
  tnx_print_two_col 'Standalone summary' 'terfetch [--json|--version|--help]'

  printf '\n%sGlobal options:%s\n' "$TNX_CW" "$TNX_C0"
  tnx_print_two_col '--help, -h' 'Show help for any command' "$TNX_CC"
  tnx_print_two_col '--version, -V' 'Show version information' "$TNX_CC"
  tnx_print_two_col '--json' 'Machine-readable JSON output' "$TNX_CC"
  tnx_print_two_col '--verbose' 'Show detailed debug output' "$TNX_CC"
  tnx_print_two_col '--quiet' 'Suppress non-critical messages' "$TNX_CC"

  printf '\n%sExamples:%s\n' "$TNX_CW" "$TNX_C0"
  tnx_print_two_col 'tx doctor --json' 'Machine-readable diagnostics' "$TNX_CC"
  tnx_print_two_col 'tx start db ub kali alp' 'Launch several guest desktops' "$TNX_CC"
  tnx_print_two_col 'db / dbr / dbroot' 'Open Debian user or root shell' "$TNX_CC"
  tnx_print_two_col 'ub / ubr / ubroot' 'Open Ubuntu user or root shell' "$TNX_CC"
  tnx_print_two_col 'tx backend set zink' 'Switch GPU backend' "$TNX_CC"
  printf '\n'
  tnx_print_centered "Run 'tx <command> -h' for detailed help." "$TNX_CD"
  tnx_print_centered "The compatibility command 'ternux' accepts the same commands, aliases and options." "$TNX_CD"
}

tnx_help_tree_row() {
  local right="${2:-}"
  right="${right//|/ | }"
  tnx_print_two_col "${1:-}" "$right"
}

tnx_help_control() {
  cat <<'HELP'
Usage: tx control [--no-open]

Open the local Ternux Control Center in a browser. It binds only to 127.0.0.1
and uses a temporary session key. It can start or stop installed Ternux desktop
guests after showing a state-bound plan and asking for confirmation. Jobs are
journaled locally; interrupted actions require a status check before retrying.
Press Ctrl-C in Termux to close it. Python 3 is optional and can be installed
with `pkg install python`.
Use --no-open to print the local URL without launching a browser.
HELP
}

tnx_help_manager() {
  cat <<'HELP'
Usage: tx manager status|guests|displays|capabilities [--json]
       tx manager migrate --apply sha256:PLAN_ID | --recover
       tx manager serve

Status, guest, display, and capability snapshots are read-only. Direct commands
work without the optional socket service. Migration apply is an explicit,
state-bound transaction that never starts or stops a desktop.

  tx manager status --json   Manager availability and active desktop names
  tx manager guests --json   Installed guests, desktop profile and display
  tx manager displays --json Current/target, conflicts, migration preview
  tx manager capabilities   List the operations implemented by this CLI core
  tx manager serve          Run the optional read-only local API in foreground

Status, guest, and capability payloads use schema version 1.0.0; display
payloads use schema version 1.3.0 and include a read-only migration preview.
Apply only a ready plan copied from the current snapshot; stale plans and active,
occupied, malformed, mismatched, or non-stopped guests are refused. Recover an
interrupted journal with --recover before starting guests.
A missing proot-distro command is
reported as unavailable, not as an empty guest list.
Unknown operations and arguments are rejected. The capability list is built
from the same operation registry used by dispatch.
The service listens only on a private Termux Unix socket and exits on Ctrl-C.
It needs the optional Termux Python package (`pkg install python`). It does not
auto-start, expose a network port, or mutate guests.
HELP
}

# --- Command-specific help -------------------------------------------------
tnx_help_extension() {
  cat <<'HELP'
Usage: tx extension [list|install|repair|remove NAME]

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
Usage: tx install [options]

Install or reinstall the full ternux desktop environment.

Options:
  --yes                Defaults, no questions
  --user NAME          Guest user name (default: ternux)
  --locale LANG        Locale (default: en_US.UTF-8)
  --backend zink|virgl|auto  GPU backend (default: auto)
  --zsh                Use zsh instead of bash (installs powerlevel10k)
  --shell bash|zsh     Choose the Termux shell without being asked
  --no-theme           Skip powerlevel10k when zsh is chosen
  --distro NAME        One of 15 named profiles (Debian/Ubuntu/Kali/Alpine qualified on reference device)
  --distros LIST       Install multiple profiles, e.g. debian,ubuntu,kali,alpine
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

Interactive install first shows a keyboard checklist in this order: Debian,
Ubuntu, Kali, Alpine, Arch Linux, Fedora, openSUSE, Void, Artix, Chimera,
Deepin, Manjaro, Pardus, Rocky Linux, Adelie. Use a profile's documented short
name in non-interactive commands. Kali uses Kali's official rolling OCI image.
The checklist supports:
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

tnx_help_distro() {
  printf '%sUsage:%s tx distro [list|search|install|uninstall|image-install|shell|root|exec]\n\n' "$TNX_CW" "$TNX_C0"
  printf '%sGuest shell shortcuts:%s\n' "$TNX_CW" "$TNX_C0"
  tnx_print_two_col 'db / dbr / dbroot' 'Debian user / root shell' "$TNX_CC"
  tnx_print_two_col 'ub / ubr / ubroot' 'Ubuntu user / root shell' "$TNX_CC"
  tnx_print_two_col 'kali / kalir / kaliroot' 'Kali user / root shell' "$TNX_CC"
  tnx_print_two_col 'alp / alpr / alproot' 'Alpine user / root shell' "$TNX_CC"
  printf '\nFull managed catalog, short names, display IDs and install state: tx distro list\n'
}
tnx_help_start() {
  echo "Usage: tx start [DISTRO ...]"
  tnx_print_two_col Behavior 'Starts Debian when installed, otherwise the saved distro. Pass multiple full or short names to start several desktops.'
  tnx_print_two_col Catalog 'debian/db · ubuntu/ub · kali · alpine/alp · archlinux/archx · fedora/fed · opensuse/suse · void/vsh · artix/art · chimera/chim · deepin/deep · manjaro/manj · pardus/par · rockylinux/rock · adelie/adel'
  tnx_print_two_col Example 'tx start db ub kali alp' "$TNX_CC"
}
tnx_help_guides() {
  echo "Usage: tx guide | tx guides"
  tnx_print_two_col Purpose 'Print the quick guide and links to the complete documentation.'
}
tnx_help_mic() { cat <<'HELP'
Usage: tx mic

Request Android microphone access through Termux:API. The permission check
records for at most one second to a private temporary file, stops the recorder,
and deletes that file. If Termux:API is not installed, it briefly opens the
built-in OpenSL microphone path; audio is discarded and Android may ask for
Termux's microphone permission. A missing companion does not block desktop use.
Supports --json for a machine-readable result.
HELP
}
tnx_help_cam() { cat <<'HELP'
Usage: tx cam

Request Android camera access through Termux:API by taking one temporary
rear-camera photo in a private directory, then deleting it. Run from an
interactive Termux session so you can answer Android's permission prompt.
Without the Termux:API app and package, use Android Camera and browse its saved
photos from the guest file manager. The Ternux desktop remains usable.
Supports --json for a machine-readable result.
HELP
}
tnx_help_stop() {
  echo "Usage: tx stop [DISTRO|--all]"
  tnx_print_two_col Behavior 'Interactive mode lists running guests. Choose one or more by number or name, or 0 to cancel.'
  tnx_print_two_col '--all' 'Stop every Ternux desktop'
}
tnx_help_restart() {
  echo "Usage: tx restart [DISTRO]"
  tnx_print_two_col Behavior 'Restart the named guest desktop session.'
}
tnx_help_status() {
  echo "Usage: tx status [DISTRO] [--json]"
  tnx_print_two_col Behavior 'Without DISTRO, show lifecycle, display, audio and log location for every installed guest. Add a name to inspect one guest.'
}
tnx_help_doctor() {
  cat << HELP
Usage: tx doctor [CATEGORY|DISTRO ...] [--quick] [--strict] [--json]

Run categorised diagnostics. Every check is reported as ok, warn, fail or info
with a fix hint; info is context and never counts as an issue.

Categories (default: host, system, all installed guests and graphics):
  system       architecture, storage, memory, battery temperature, state directory
  host         proot-distro, Debian container, Termux:X11, PulseAudio, curl,
               Android child-process monitoring
  guest        Debian glibc, password-required sudo, desktop commands, dpkg state, disk
  graphics     Vulkan, GPU, backend, KGSL node, Turnip layout, renderer, launcher
  gpu          alias for graphics; checks the GPU route and renderer
  extensions   health of installed extensions (llama-vulkan, stable-diffusion, llama-htp-experimental)

Options:
  --quick      skip the Debian guest probe (guest and extension checks)
  --strict     exit 1 on warnings and 2 on failures (default exit status is 0)
  --json       machine-readable output (schema_version 2: summary and checks[]
               plus the original issues and recommended_actions arrays)

Examples:
  ternux doctor extensions         ${TNX_CD}only the extension checks${TNX_C0}
  ternux doctor graphics --json    ${TNX_CD}graphics checks for scripts${TNX_C0}
  tx doctor db                     ${TNX_CD}Debian guest and graphics checks${TNX_C0}
  tx doc kali                      ${TNX_CD}Kali guest and graphics checks${TNX_C0}
  tx doctor gpu                    ${TNX_CD}GPU diagnostics only${TNX_C0}
  ternux doctor --quick --strict   ${TNX_CD}fast host-only gate for automation${TNX_C0}
HELP
}
tnx_help_repair()    { echo "Usage: tx repair"; echo "Auto-fix common issues: broken curl, missing X11, backend mismatch, stale cache."; }
tnx_help_verify()    { echo "Usage: tx verify [DISTRO] [--json]"; echo "Verify the active guest by default, or select one with db, ub, kali, alp, or its distro name. Checks host binaries, launcher, guest services, and GPU driver."; }
tnx_help_benchmark() { echo "Usage: tx benchmark [--json]"; echo "Run GPU benchmarks (glmark2, vkmark) and renderer verification."; }

tnx_help_profile() {
  cat << HELP
Usage: tx profile <subcommand> [name]

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
Usage: tx backend <subcommand> [backend]

Subcommands:
  show             Display current backend configuration
  set auto|zink|virgl  Change GPU backend
  detect           Auto-detect the correct backend
  update           Refresh the validated Debian Turnip driver (Zink only)

Supports --json for machine-readable output.
HELP
}

tnx_help_info()      { echo "Usage: tx info [--json]"; echo "Show Android/Termux versions, device, CPU, memory/storage, GPU/Vulkan/backend, active renderer, and phantom-process setting readability."; }
tnx_help_state()     { echo "Usage: tx state [--json]"; echo "Show completed installer phases, saved configuration, installed managed profiles and displays, plus recent repair/benchmark history."; }

tnx_help_logs() {
  cat << HELP
Usage: tx logs <subcommand>

Subcommands:
  show [n]     Show last n log lines (default: 50)
  tail         Follow log output in real time
  clear        Clear the CLI/install log file
  list         List available log files
  desktop [show|tail] [DISTRO]  Read/follow one guest's desktop log
  session [show|tail] [DISTRO]  Alias for desktop logs
HELP
}

tnx_help_update()    { echo "Usage: tx update [check]"; echo "check — inspect the latest stable release without installing. APT installs use pkg upgrade; other installs fetch the exact stable tag commit, stage and verify all CLI modules, and preserve the previous version for rollback."; }
tnx_help_uninstall() {
  echo "Usage: tx uninstall [session|launcher|state|container|host-cli|all] [--yes]"
  echo "launcher removes ~/x.sh, marked shell aliases, and Terfetch startup hooks."
  echo "all removes registered guests and newly installed Termux packages recorded by Ternux; pre-existing packages are kept."
  echo "Interactive by default; destructive container removal requires confirmation."
}

tnx_help_gpu() {
  cat << HELP
Usage: tx gpu <subcommand>

Subcommands:
  show       Show GPU/backend status
  update     Refresh the validated Debian Turnip driver (Zink only)

This updates the guest userspace driver, not Android's vendor driver.
Supports --json for machine-readable output.
HELP
}


tnx_help_storage() {
  cat <<'HELP'
Usage: tx storage [list | grant DIRECTORY | revoke DIRECTORY]

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
