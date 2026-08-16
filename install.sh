#!/data/data/com.termux/files/usr/bin/bash
# =============================================================================
#  ternux — standalone bootstrapper
#  GPU-accelerated Linux desktop for Android. No root required.
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
    --user) USER_NAME="${2:?--user needs a value}"; shift ;;
    --locale) LOCALE="${2:?--locale needs a value}"; shift ;;
    --backend)
      case "${2:-}" in auto|zink|virgl) BACKEND="$2"; shift ;; *) echo "[FAIL] --backend must be auto, zink or virgl"; exit 1 ;; esac ;;
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
    *) echo "[FAIL] Unknown option: $1"; exit 1 ;;
  esac
  shift
done

case "$USER_NAME" in ""|*[!a-z0-9_-]*) echo "[FAIL] --user may contain only a-z, 0-9, _ and -."; exit 1 ;; esac

# ---------------------------------------------------------------------------
# Action dispatch
# ---------------------------------------------------------------------------
case "${ACTION}" in
  doctor)
    if [ "$FIX" = "yes" ]; then
      tnx_info "Running diagnosis + repair..."
      tnx_phase_preflight || true
      for pkg in packages debian gpu audio_fonts launcher aliases; do
        if ! tnx_state_done "phase_$pkg"; then
          tnx_warn "Phase '$pkg' not completed — re-running..."
          "tnx_phase_$pkg" && tnx_state_mark "phase_$pkg"
        fi
      done
      tnx_phase_verify "$USER_NAME" "$BACKEND"
    else
      tnx_info "Running diagnosis..."
      tnx_require_termux
      tnx_phase_preflight || true
      for pkg in packages debian gpu audio_fonts launcher aliases; do
        if tnx_state_done "phase_$pkg"; then tnx_ok "phase '$pkg' completed"
        else tnx_warn "phase '$pkg' not completed"; fi
      done
      tnx_phase_verify "$USER_NAME" "$BACKEND"
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
  resume)
    tnx_install --yes --user "$USER_NAME" --locale "$LOCALE" --backend "$BACKEND" --resume
    ;;
  *)
    # Build extras list
    EXTRAS=""
    [ "$WITH_DEV" = "1" ] && EXTRAS="$EXTRAS --with-dev"
    [ "$WITH_LLM" = "1" ] && EXTRAS="$EXTRAS --with-llm"
    [ "$WITH_NETWORK" = "1" ] && EXTRAS="$EXTRAS --with-network"
    [ "$WITH_MEDIA" = "1" ] && EXTRAS="$EXTRAS --with-media"
    [ "$WITH_BLENDER" = "1" ] && EXTRAS="$EXTRAS --with-blender"
    [ "$SHELL_CHOICE" = "zsh" ] && EXTRAS="$EXTRAS --zsh"

    tnx_install --yes --user "$USER_NAME" --locale "$LOCALE" --backend "$BACKEND" $EXTRAS
    ;;
esac