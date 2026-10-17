#!/usr/bin/env bash
# =============================================================================
#  ternux — wine-hangover benchmarks
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah)
#  Licensed under the Apache License, Version 2.0.
#  https://github.com/soobujmiah/ternux
#
#  Runs inside the Debian ARM64 guest after:  ternux extension install wine-hangover
#  Measures two real Windows programs under the installed Wine, each download
#  checked against a pinned SHA-256:
#    * 7-Zip 23.01 `b` (CPU benchmark): native arm64 7-Zip vs Wine x86-64 (FEX),
#      x86 on Box64 and x86 on FEX. Needs the Debian `7zip` package for the
#      native baseline and for unpacking the benchmark below.
#    * ChimbaBenchXPL A3 "Simple Test" (OpenGL 2.1): CPU path (llvmpipe) vs GPU
#      path (Zink/Turnip, when the KGSL node is visible), 32-bit and 64-bit.
#      The GUI is driven with xdotool on a private Xvfb display.
#
#  Usage:  bash benchmark.sh [--runs N] [--keep] [SCRATCH_DIR]
#    --runs N     passes per cell (default 3)
#    --keep       keep the scratch directory
#    SCRATCH_DIR  new or empty directory (default: a fresh mktemp -d)
#
#  Limits to read with the numbers: this machine's thermal state changes the
#  results between passes (print the battery temperature), the Zink window is
#  not visible on Xvfb so GPU-run image correctness is not checked, and the
#  benchmark's score is the project's own (its database labels it FPS).
# =============================================================================
set -u

RUNS=3; KEEP=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --runs) RUNS="${2:-}"; shift 2 ;;
    --keep) KEEP=1; shift ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
    *) break ;;
  esac
done
case "$RUNS" in ''|*[!0-9]*|0) echo "--runs needs a positive number" >&2; exit 2 ;; esac
ROOT="$HOME/.local/opt/ternux-extensions/wine-hangover"
[ -f "$ROOT/env.sh" ] || { echo "wine-hangover is not installed: ternux extension install wine-hangover" >&2; exit 2; }
for c in curl sha256sum Xvfb python3 timeout 7z xdotool; do
  command -v "$c" >/dev/null 2>&1 || { echo "missing command: $c (sudo apt install xvfb python3 curl 7zip xdotool)" >&2; exit 2; }
done

WORK="${1:-$(mktemp -d)}"
if [ -e "$WORK" ] && [ -n "$(ls -A "$WORK" 2>/dev/null)" ]; then echo "SCRATCH_DIR must be new or empty: $WORK" >&2; exit 2; fi
mkdir -p "$WORK/dl" "$WORK/chimba" "$WORK/logs" || exit 2
[ "$KEEP" -eq 1 ] || trap 'pkill -x "ChimbaBenchXPL-" >/dev/null 2>&1; wineserver -k >/dev/null 2>&1; kill "${XPID:-0}" >/dev/null 2>&1; rm -rf "$WORK"' EXIT

fail=0
die() { echo "FAIL: $*" >&2; fail=1; }

PROGRAMS='
7z2301.exe|https://www.7-zip.org/a/7z2301.exe|9b6682255bed2e415bfa2ef75e7e0888158d1aaf79370defaa2e2a5f2b003a59
7z2301-x64.exe|https://www.7-zip.org/a/7z2301-x64.exe|26cb6e9f56333682122fafe79dbcdfd51e9f47cc7217dccd29ac6fc33b5598cd
ChimbaBenchXPL-A3.7z|https://github.com/Shedou/ChimbaBenchXPL/releases/download/CBXPL-A3/ChimbaBenchXPL-A3.7z|81321e4ca138c1e26c76281c501791acc7f914029b20c40542d4cc833a4fb803
'
while IFS='|' read -r name url sha; do
  [ -n "$name" ] || continue
  if ! curl -fsSL --retry 3 -m 300 -o "$WORK/dl/$name" "$url" ||
     [ "$(sha256sum "$WORK/dl/$name" | cut -d' ' -f1)" != "$sha" ]; then
    echo "download or SHA-256 failed: $name" >&2; exit 1
  fi
done <<< "$PROGRAMS"
echo "# downloads verified"

( cd "$WORK/chimba" && 7z x -y "$WORK/dl/ChimbaBenchXPL-A3.7z" >/dev/null ) || { echo "cannot unpack the benchmark" >&2; exit 1; }
CB="$WORK/chimba/ChimbaBenchXPL-A3"
[ -f "$CB/ChimbaBenchXPL-x32.exe" ] && [ -f "$CB/ChimbaBenchXPL-x64.exe" ] || { echo "benchmark layout changed" >&2; exit 1; }

Xvfb :77 -screen 0 1024x768x24 +extension GLX +render -noreset >"$WORK/logs/xvfb.log" 2>&1 &
XPID=$!
sleep 2
export DISPLAY=:77 WINEPREFIX="$WORK/prefix" WINEDLLOVERRIDES="mscoree=d;winemenubuilder.exe=d"
unset GALLIUM_DRIVER
. "$ROOT/env.sh"
GPU_DRIVER="${GALLIUM_DRIVER:-}"      # what env.sh selected: zink with a KGSL node, empty otherwise
export WINEDEBUG=-all
timeout 900 wine wineboot -u >"$WORK/logs/wineboot.log" 2>&1 && [ -f "$WINEPREFIX/system.reg" ] || { echo "cannot create a prefix" >&2; exit 1; }
for arch in x86 x64; do
  inst="$WORK/dl/$([ $arch = x64 ] && echo 7z2301-x64.exe || echo 7z2301.exe)"
  timeout 300 wine "$inst" /S "/D=C:\\7zip$arch" >/dev/null 2>&1
done

battery() { local z; for z in /sys/class/thermal/thermal_zone*; do
  [ "$(cat "$z/type" 2>/dev/null)" = battery ] && { cat "$z/temp" 2>/dev/null; return; }; done; echo unknown; }
total() { awk '/^Tot:/{print $NF}' | head -1; }

echo "# 7-Zip b -mmt8 total rating (higher is faster); battery zone in millidegrees C"
for pass in $(seq 1 "$RUNS"); do
  t0="$(battery)"
  n="$(timeout 300 7z b -mmt8 2>&1 | total)"
  f64="$(timeout 300 wine 'C:\7zipx64\7z.exe' b -mmt8 2>/dev/null | tr -d '\r' | total)"
  b32="$(HODLL=wowbox64.dll timeout 300 wine 'C:\7zipx86\7z.exe' b -mmt8 2>/dev/null | tr -d '\r' | total)"
  f32="$(HODLL=libwow64fex.dll timeout 300 wine 'C:\7zipx86\7z.exe' b -mmt8 2>/dev/null | tr -d '\r' | total)"
  for v in "$n" "$f64" "$b32" "$f32"; do case "$v" in ''|*[!0-9]*) die "7-Zip pass $pass produced no rating" ;; esac; done
  printf '7zip\tpass=%s\tnative=%s\twine_x64_fex=%s\twine_x86_box64=%s\twine_x86_fex=%s\tbattery_start=%s\tbattery_end=%s\n' \
    "$pass" "$n" "$f64" "$b32" "$f32" "$t0" "$(battery)"
done

chimba_score() { # exe(x32|x64) mode(cpu|gpu) -> prints the score or nothing
  local exe="$1" mode="$2" result="$CB/Benchmark-Result.txt" wid geo gx gy gw gh
  pkill -x "ChimbaBenchXPL-" >/dev/null 2>&1; sleep 3
  : > "$result"
  if [ "$mode" = cpu ]; then export GALLIUM_DRIVER=llvmpipe
  elif [ -n "$GPU_DRIVER" ]; then export GALLIUM_DRIVER="$GPU_DRIVER"
  else return 1; fi
  ( cd "$CB" && wine "./ChimbaBenchXPL-$exe.exe" >"$WORK/logs/chimba_${exe}_${mode}.log" 2>&1 & )
  sleep 40
  wid="$(xdotool search --name ChimbaBenchXPL 2>/dev/null | head -1)"
  [ -n "$wid" ] || return 1
  eval "$(xdotool getwindowgeometry --shell "$wid" 2>/dev/null)"   # sets X Y WIDTH HEIGHT
  # The "Benchmark" button sits at the same place in the 640x360 window: 474 px right, 344 px down.
  xdotool mousemove "$((X + 474))" "$((Y + 344))" click 1
  local end=$((SECONDS + 300))
  while [ $SECONDS -lt $end ] && [ ! -s "$result" ]; do sleep 5; done
  pkill -x "ChimbaBenchXPL-" >/dev/null 2>&1
  tr -d '\r' < "$result" | sed -n 's/^Result: \([0-9][0-9]*\).*/\1/p' | head -1
}

echo "# ChimbaBenchXPL A3 Simple Test 640x360: score per run (the project's database labels it FPS)"
for exe in x32 x64; do
  for mode in cpu gpu; do
    [ "$mode" = gpu ] && [ -z "$GPU_DRIVER" ] && { echo "# no KGSL node visible: GPU cells skipped"; continue; }
    scores=""
    for run in $(seq 1 "$RUNS"); do
      s="$(chimba_score "$exe" "$mode")"
      case "$s" in ''|*[!0-9]*) die "no score for $exe $mode run $run"; s=NA ;; esac
      scores="${scores:+$scores }$s"
    done
    printf 'chimba\t%s\t%s\t%s\n' "$exe" "$mode" "$scores"
  done
done
[ "$KEEP" -eq 1 ] && echo "# kept: $WORK"
[ "$fail" -eq 0 ]
