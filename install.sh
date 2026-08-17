#!/data/data/com.termux/files/usr/bin/bash
# =============================================================================
#  ternux — standalone bootstrapper
#  Linux desktop for Android with Zink and VirGL graphics routes. No root required.
#
#  Two modes:
#    1. Repository:  bash install.sh        (lib/*.sh are local)
#    2. Standalone:  curl ... | bash         (libs downloaded from GitHub)
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah) — MIT License
#  https://github.com/soobujmiah/ternux
#
#  Usage
#    curl -fsSL https://soobujmiah.github.io/ternux/install.sh | bash
#    bash install.sh [options]
#
#  Options
#    --yes                           run with sensible defaults, no questions
#    --user NAME                     Debian user (default: ternux)
#    --locale LANG                   locale inside Debian (default: en_US.UTF-8)
#    --backend auto|zink|virgl       graphics route (default: auto)
#    --with-dev  --with-llm  --with-network  --with-media  --with-blender
#    --all                           all optional workloads
#    --zsh                           use zsh instead of bash
#    --resume                        continue an interrupted install
#    --no-anim                       disable animations
#    --version | --help
# =============================================================================
set -u

# ---------------------------------------------------------------------------
# Bootstrap: locate or download library modules
# ---------------------------------------------------------------------------
_TNX_SRC="$(cd "$(dirname "$0")" && pwd 2>/dev/null || echo "$PWD")"

_tnx_load_local() {
  [ -f "$_TNX_SRC/lib/core.sh" ] && [ -f "$_TNX_SRC/lib/phases.sh" ] && [ -f "$_TNX_SRC/lib/ui.sh" ] || return 1
  . "$_TNX_SRC/lib/core.sh" && . "$_TNX_SRC/lib/phases.sh" && . "$_TNX_SRC/lib/ui.sh"
}

_tnx_load_remote() {
  local base="https://raw.githubusercontent.com/soobujmiah/ternux/main"
  local libs="core.sh phases.sh detect.sh ui.sh"
  local tmpdir="${TMPDIR:-/tmp}/ternux-libs.$$"
  mkdir -p "$tmpdir"

  for lib in $libs; do
    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
      echo "[FATAL] Neither curl nor wget available. Cannot download ternux libraries." >&2
      exit 1
    fi
    if command -v curl >/dev/null 2>&1; then
      curl -fsSL --max-time 15 "$base/lib/$lib" -o "$tmpdir/$lib" 2>/dev/null || {
        echo "[FATAL] Failed to download $lib from GitHub." >&2; rm -rf "$tmpdir"; exit 1; }
    else
      wget -q --timeout=15 "$base/lib/$lib" -O "$tmpdir/$lib" 2>/dev/null || {
        echo "[FATAL] Failed to download $lib from GitHub." >&2; rm -rf "$tmpdir"; exit 1; }
    fi
  done

  local downloaded_lib
  for downloaded_lib in "$tmpdir/"*.sh; do
    if ! bash -n "$downloaded_lib" 2>/dev/null; then
      echo "[FATAL] Downloaded ternux library failed shell syntax validation: $(basename "$downloaded_lib")" >&2
      rm -rf "$tmpdir"
      exit 1
    fi
  done

  . "$tmpdir/core.sh" && . "$tmpdir/phases.sh" && . "$tmpdir/detect.sh" && . "$tmpdir/ui.sh" || {
    echo "[FATAL] Failed to load downloaded libraries." >&2; rm -rf "$tmpdir"; exit 1; }
  rm -rf "$tmpdir"
  return 0
}

if ! _tnx_load_local; then
  echo "[INFO] Loading ternux libraries from GitHub..."
  _tnx_load_remote || exit 1
fi
# _TNX_SRC kept for action dispatch below

# ---------------------------------------------------------------------------
# Legacy forward-compatibility: map install.sh functions to tnx_* equivalents
# ---------------------------------------------------------------------------
VERSION="$TERNUX_VERSION"
info()  { tnx_info "$1"; }
ok()    { tnx_ok "$1"; }
warn()  { tnx_warn "$1"; }
fail()  { tnx_fail "$1"; }
step()  { tnx_step "$1"; }
ask()   { tnx_confirm "$1"; }
run()   { local l="$1"; shift; tnx_debug "Running: $*"; "$@"; }
state_done()  { tnx_state_done "phase_$1"; }
state_mark()  { tnx_state_mark "phase_$1"; }
state_clear() { tnx_state_clear; }

detect_backend() { [ -e /dev/kgsl-3d0 ] && echo "zink" || echo "virgl"; }
require_termux() { tnx_require_termux; }

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
ACTION="install"
YES=0
USER_NAME="ternux"
LOCALE="en_US.UTF-8"
BACKEND="auto"
SHELL_CHOICE="bash"
WITH_DEV=0; WITH_LLM=0; WITH_NETWORK=0; WITH_MEDIA=0; WITH_BLENDER=0
FIX="no"

while [ $# -gt 0 ]; do
  case "$1" in
    --yes) YES=1; export TERNUX_YES=1 ;;
    --user|--locale)
      opt="$1"
      if [ $# -lt 2 ] || [ -z "$2" ] || [[ "$2" == --* ]]; then
        echo "[FAIL] $opt needs a value" >&2
        exit 2
      fi
      if [ "$opt" = "--user" ]; then USER_NAME="$2"; else LOCALE="$2"; fi
      shift
      ;;
    --backend)
      if [ $# -lt 2 ] || [ -z "$2" ] || [[ "$2" == --* ]]; then
        echo "[FAIL] --backend needs a value" >&2
        exit 2
      fi
      case "$2" in
        auto|zink|virgl) BACKEND="$2"; shift ;;
        *) echo "[FAIL] --backend must be auto, zink or virgl" >&2; exit 2 ;;
      esac
      ;;
    --zsh) SHELL_CHOICE="zsh" ;;
    --with-dev) WITH_DEV=1 ;;
    --with-llm) WITH_LLM=1 ;;
    --with-network) WITH_NETWORK=1 ;;
    --with-media) WITH_MEDIA=1 ;;
    --with-blender) WITH_BLENDER=1 ;;
    --all) WITH_DEV=1; WITH_LLM=1; WITH_NETWORK=1; WITH_MEDIA=1; WITH_BLENDER=1 ;;
    --doctor) ACTION="doctor"; [ "${2:-}" = "--fix" ] && { FIX="yes"; shift; } ;;
    --fix) FIX="yes" ;;
    --no-anim) export TERNUX_NO_ANIM=1 ;;
    --resume) ACTION="resume" ;;
    --status) ACTION="status" ;;
    --uninstall) ACTION="uninstall" ;;
    --version) echo "ternux installer v${TERNUX_VERSION:-1.3.0} — https://github.com/soobujmiah/ternux"; exit 0 ;;
    -h|--help) sed -n '/^#  Usage/,/^# =====/p' "$0" | sed 's/^# \?//p' | head -n -1; exit 0 ;;
    *) echo "[FAIL] Unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

if [[ ! "$USER_NAME" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]; then
  echo "[FAIL] --user must start with a-z or _, use only a-z, 0-9, _ or -, and be at most 32 characters."
  exit 1
fi
if [[ ! "$LOCALE" =~ ^[A-Za-z0-9_.@-]+$ ]]; then
  echo "[FAIL] --locale contains unsupported characters."
  exit 1
fi

# ---------------------------------------------------------------------------
# Action dispatch
# ---------------------------------------------------------------------------
case "${ACTION}" in
  doctor)
    DOCTOR_BACKEND="$BACKEND"
    if [ "$DOCTOR_BACKEND" = "auto" ]; then
      DOCTOR_BACKEND="$(detect_backend)"
    fi
    if [ "$FIX" = "yes" ]; then
      tnx_info "Running diagnosis + repair..."
      preflight_rc=0
      tnx_phase_preflight || preflight_rc=$?
      if [ "$preflight_rc" -ne 0 ]; then
        tnx_fail "Preflight failed; repair phases were not run."
        exit "$preflight_rc"
      fi
      repair_rc=0
      for pkg in packages debian gpu audio_fonts launcher aliases; do
        if ! tnx_state_done "phase_$pkg"; then
          tnx_warn "Phase '$pkg' not completed — re-running..."
          phase_rc=0
          case "$pkg" in
            packages)    tnx_phase_packages "$DOCTOR_BACKEND" || phase_rc=$? ;;
            debian)      tnx_phase_debian "$USER_NAME" || phase_rc=$? ;;
            gpu)         tnx_phase_gpu "$DOCTOR_BACKEND" || phase_rc=$? ;;
            audio_fonts) tnx_phase_audio_fonts "$USER_NAME" "$LOCALE" || phase_rc=$? ;;
            launcher)    tnx_phase_launcher "$USER_NAME" "$DOCTOR_BACKEND" "$LOCALE" || phase_rc=$? ;;
            aliases)     tnx_phase_aliases "$USER_NAME" "$SHELL_CHOICE" || phase_rc=$? ;;
          esac
          if [ "$phase_rc" -eq 0 ]; then
            tnx_state_mark "phase_$pkg"
          else
            repair_rc="$phase_rc"
            break
          fi
        fi
      done
      verify_rc=0
      tnx_phase_verify "$USER_NAME" "$DOCTOR_BACKEND" || verify_rc=$?
      [ "$repair_rc" -ne 0 ] && exit "$repair_rc"
      exit "$verify_rc"
    else
      tnx_info "Running diagnosis..."
      tnx_require_termux
      tnx_phase_preflight || true
      for pkg in packages debian gpu audio_fonts launcher aliases; do
        if tnx_state_done "phase_$pkg"; then tnx_ok "phase '$pkg' completed"
        else tnx_warn "phase '$pkg' not completed"; fi
      done
      tnx_phase_verify "$USER_NAME" "$DOCTOR_BACKEND"
    fi
    ;;
  status)
    echo "Installation status:"
    for pkg in packages cli debian gpu audio_fonts launcher aliases extras phantom verify; do
      if tnx_state_done "phase_$pkg"; then printf "  done    %s\n" "$pkg"
      else printf "  pending %s\n" "$pkg"; fi
    done
    echo ""
    [ -x "$HOME/x.sh" ] && echo "  Launcher: $HOME/x.sh" || echo "  Launcher: not created"
    ;;
  uninstall)
    # Delegate to CLI if installed, otherwise use the standalone uninstaller
    if [ -f "$_TNX_SRC/uninstall.sh" ]; then
      exec bash "$_TNX_SRC/uninstall.sh"
    fi
    echo "See: ternux uninstall  or  bash uninstall.sh"
    ;;
  resume|install)
    # Preserve argument boundaries and pass --yes only when the caller asked
    # for it. A local TTY run gets one confirmation; a curl|bash run has no
    # TTY and proceeds with the documented defaults.
    INSTALL_ARGS=(--user "$USER_NAME" --locale "$LOCALE" --backend "$BACKEND")
    [ "$YES" = "1" ] && INSTALL_ARGS+=(--yes)
    [ "$ACTION" = "resume" ] && INSTALL_ARGS+=(--resume)
    [ "$WITH_DEV" = "1" ] && INSTALL_ARGS+=(--with-dev)
    [ "$WITH_LLM" = "1" ] && INSTALL_ARGS+=(--with-llm)
    [ "$WITH_NETWORK" = "1" ] && INSTALL_ARGS+=(--with-network)
    [ "$WITH_MEDIA" = "1" ] && INSTALL_ARGS+=(--with-media)
    [ "$WITH_BLENDER" = "1" ] && INSTALL_ARGS+=(--with-blender)
    [ "$SHELL_CHOICE" = "zsh" ] && INSTALL_ARGS+=(--zsh)

    tnx_install "${INSTALL_ARGS[@]}"
    ;;
esac
