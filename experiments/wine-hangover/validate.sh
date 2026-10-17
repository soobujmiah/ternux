#!/usr/bin/env bash
# =============================================================================
#  ternux — wine-hangover device validation
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah)
#  Licensed under the Apache License, Version 2.0.
#  https://github.com/soobujmiah/ternux
#
#  Runs inside the Debian ARM64 guest after:  ternux extension install wine-hangover
#  Downloads three real, publicly distributed Windows programs into a new
#  scratch directory, checks each against the SHA-256 recorded when this test
#  was written, and runs them under the installed Wine. It prints TAP and exits
#  non-zero if any check fails. Nothing outside the scratch directory and the
#  chosen Wine prefix is modified.
#
#  Usage:  bash validate.sh [--keep] [SCRATCH_DIR]
#    --keep        keep the scratch directory (downloads, prefix, logs)
#    SCRATCH_DIR   new or empty directory (default: a fresh mktemp -d)
# =============================================================================
set -u

KEEP=0
[ "${1:-}" = "--keep" ] && { KEEP=1; shift; }
ROOT="$HOME/.local/opt/ternux-extensions/wine-hangover"
[ -f "$ROOT/env.sh" ] || { echo "wine-hangover is not installed: ternux extension install wine-hangover" >&2; exit 2; }
for c in curl sha256sum Xvfb python3 timeout od; do
  command -v "$c" >/dev/null 2>&1 || { echo "missing command: $c (sudo apt install xvfb python3 curl)" >&2; exit 2; }
done

WORK="${1:-$(mktemp -d)}"
if [ -e "$WORK" ] && [ -n "$(ls -A "$WORK" 2>/dev/null)" ]; then echo "SCRATCH_DIR must be new or empty: $WORK" >&2; exit 2; fi
mkdir -p "$WORK/dl" "$WORK/logs" || exit 2
[ "$KEEP" -eq 1 ] || trap 'wineserver -k >/dev/null 2>&1; kill "${XPID:-0}" >/dev/null 2>&1; rm -rf "$WORK"' EXIT

pass=0; fail=0
ok()     { pass=$((pass+1)); printf 'ok %d - %s\n' "$((pass+fail))" "$1"; }
not_ok() { fail=$((fail+1)); printf 'not ok %d - %s\n' "$((pass+fail))" "$1"; [ -n "${2:-}" ] && printf '  # %s\n' "$2"; }

# name | URL | sha256 recorded 2026-10-17
PROGRAMS='
glew-2.2.0-win32.zip|https://github.com/nigels-com/glew/releases/download/glew-2.2.0/glew-2.2.0-win32.zip|ea6b14a1c6c968d0034e61ff6cb242cff2ce0ede79267a0f2b47b1b0b652c164
python-3.13.1-embed-amd64.zip|https://www.python.org/ftp/python/3.13.1/python-3.13.1-embed-amd64.zip|7b7923ff0183a8b8fca90f6047184b419b108cb437f75fc1c002f9d2f8bcec16
python-3.13.1-embed-win32.zip|https://www.python.org/ftp/python/3.13.1/python-3.13.1-embed-win32.zip|6a90fc5a370a0ed47af233206ac04336fecc0e539b70d16c3b2e728fe5b040e3
7z2301.exe|https://www.7-zip.org/a/7z2301.exe|9b6682255bed2e415bfa2ef75e7e0888158d1aaf79370defaa2e2a5f2b003a59
7z2301-x64.exe|https://www.7-zip.org/a/7z2301-x64.exe|26cb6e9f56333682122fafe79dbcdfd51e9f47cc7217dccd29ac6fc33b5598cd
'
printf 'TAP version 13\n'
while IFS='|' read -r name url sha; do
  [ -n "$name" ] || continue
  if curl -fsSL --retry 3 -m 300 -o "$WORK/dl/$name" "$url" &&
     [ "$(sha256sum "$WORK/dl/$name" | cut -d' ' -f1)" = "$sha" ]; then
    ok "download and SHA-256: $name"
  else
    not_ok "download and SHA-256: $name"; printf '# cannot continue without %s\n' "$name"; exit 1
  fi
done <<< "$PROGRAMS"

python3 -I - "$WORK/dl" <<'PY' || { echo "unsafe archive member" >&2; exit 1; }
import sys, zipfile, os
d = sys.argv[1]
for z in ("glew-2.2.0-win32.zip", "python-3.13.1-embed-amd64.zip", "python-3.13.1-embed-win32.zip"):
    zf = zipfile.ZipFile(os.path.join(d, z))
    bad = [n for n in zf.namelist() if n.startswith("/") or ".." in n.split("/")]
    if bad: raise SystemExit(1)
    zf.extractall(os.path.join(d, z[:-4]))
PY

# Display and Wine environment. GPU path first; the CPU path is run explicitly below.
Xvfb :77 -screen 0 1024x768x24 +extension GLX +render -noreset >"$WORK/logs/xvfb.log" 2>&1 &
XPID=$!
sleep 2
export DISPLAY=:77 WINEPREFIX="$WORK/prefix" WINEDLLOVERRIDES="mscoree=d;winemenubuilder.exe=d"
unset GALLIUM_DRIVER
. "$ROOT/env.sh"
export WINEDEBUG=-all

version="$(wine --version 2>/dev/null)"
case "$version" in wine-*) ok "wine reports a version: $version" ;; *) not_ok "wine reports a version" "$version" ;; esac

start=$(date +%s)
if timeout 600 wine wineboot -u >"$WORK/logs/wineboot.log" 2>&1 && [ -f "$WINEPREFIX/system.reg" ]; then
  ok "wineboot creates a prefix ($(( $(date +%s)-start )) s)"
else
  not_ok "wineboot creates a prefix" "see $WORK/logs/wineboot.log"; exit 1
fi

W="$WORK/dl"
for bits in 32 64; do
  d="$W/python-3.13.1-embed-$([ $bits = 32 ] && echo win32 || echo amd64)"
  out="$(cd "$d" && timeout 180 wine ./python.exe -c "import struct;print('PY',struct.calcsize('P')*8)" 2>/dev/null | tr -d '\r' | grep '^PY')"
  [ "$out" = "PY $bits" ] && ok "real $bits-bit x86 Python 3.13 runs" || not_ok "real $bits-bit x86 Python 3.13 runs" "got: ${out:-nothing}"
done

glew_renderer() { # dir mode
  local dir="$1" mode="$2"
  rm -f "$dir/glewinfo.txt"
  if [ "$mode" = cpu ]; then export GALLIUM_DRIVER=llvmpipe; fi
  (cd "$dir" && timeout 240 wine ./glewinfo.exe >/dev/null 2>&1)
  [ "$mode" = cpu ] && unset GALLIUM_DRIVER && . "$ROOT/env.sh"
  tr -d '\r' < "$dir/glewinfo.txt" 2>/dev/null | sed -n 's/^Running on a //p' | head -1
}
G="$W/glew-2.2.0-win32/glew-2.2.0/bin/Release"
kgsl=0; [ -e "${TERNUX_KGSL_DEVICE:-/dev/kgsl-3d0}" ] && kgsl=1
for arch in Win32 x64; do
  r="$(glew_renderer "$G/$arch" gpu)"
  if [ "$kgsl" = 1 ]; then
    case "$r" in zink*MESA_TURNIP*) ok "GLEW $arch uses Zink/Turnip: $r" ;; *) not_ok "GLEW $arch uses Zink/Turnip" "renderer: ${r:-none}" ;; esac
  else
    case "$r" in llvmpipe*) ok "GLEW $arch falls back to CPU (no KGSL node): $r" ;; *) not_ok "GLEW $arch CPU fallback" "renderer: ${r:-none}" ;; esac
  fi
  r="$(glew_renderer "$G/$arch" cpu)"
  case "$r" in llvmpipe*) ok "GLEW $arch CPU fallback (GALLIUM_DRIVER=llvmpipe): $r" ;; *) not_ok "GLEW $arch CPU fallback" "renderer: ${r:-none}" ;; esac
done

for arch in x86 x64; do
  inst="$W/$([ $arch = x64 ] && echo 7z2301-x64.exe || echo 7z2301.exe)"
  dir="C:\\7zip$arch"
  timeout 300 wine "$inst" /S "/D=$dir" >/dev/null 2>&1
  printf 'ternux hangover payload\n%.0s' $(seq 1 500) > "$W/payload.txt"
  made="$(timeout 180 wine "$dir\\7z.exe" a "Z:$W\\out_$arch.7z" "Z:$W\\payload.txt" 2>&1 | tr -d '\r' | grep -c 'Everything is Ok')"
  tested="$(timeout 180 wine "$dir\\7z.exe" t "Z:$W\\out_$arch.7z" 2>&1 | tr -d '\r' | grep -c 'Everything is Ok')"
  magic="$(head -c 6 "$W/out_$arch.7z" 2>/dev/null | od -An -tx1 | tr -d ' \n')"
  if [ "$made" = 1 ] && [ "$tested" = 1 ] && [ "$magic" = 377abcaf271c ]; then
    ok "7-Zip $arch installs silently and creates a valid archive"
  else
    not_ok "7-Zip $arch installs silently and creates a valid archive" "made=$made tested=$tested magic=$magic"
  fi
done

printf '1..%d\n# pass %d\n# fail %d\n' "$((pass+fail))" "$pass" "$fail"
[ "$KEEP" -eq 1 ] && printf '# kept: %s\n' "$WORK"
[ "$fail" -eq 0 ]
