#!/bin/sh
set -eu

browser="$1"
Xvfb :99 -screen 0 1280x768x24 -nolisten tcp >/tmp/ternux-xvfb.log 2>&1 &
xvfb_pid=$!
trap 'kill "$xvfb_pid" 2>/dev/null || true' EXIT

for attempt in 1 2 3 4 5 6 7 8 9 10; do
  [ -S /tmp/.X11-unix/X99 ] && break
  sleep 0.2
done
[ -S /tmp/.X11-unix/X99 ] || { cat /tmp/ternux-xvfb.log >&2; exit 1; }

export DISPLAY=:99 HOME=/tmp/firefox-home XDG_RUNTIME_DIR=/tmp/firefox-run
dbus-run-session -- timeout 90 "$browser" --no-remote --screenshot /out/firefox.png about:blank
