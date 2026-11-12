#!/bin/sh
set -eu

browser="$1"
display_number="${TNX_XVFB_DISPLAY:-99}"
Xvfb ":$display_number" -screen 0 1280x768x24 -nolisten tcp >/tmp/ternux-firefox-xvfb.log 2>&1 &
xvfb_pid=$!
wm_pid=
browser_pid=
cleanup() {
  [ -z "$browser_pid" ] || kill "$browser_pid" 2>/dev/null || true
  kill "$wm_pid" "$xvfb_pid" 2>/dev/null || true
  [ -z "$browser_pid" ] || wait "$browser_pid" 2>/dev/null || true
  wait "$wm_pid" "$xvfb_pid" 2>/dev/null || true
}
trap cleanup EXIT HUP INT TERM

attempt=0
while [ "$attempt" -lt 50 ]; do
  [ -S "/tmp/.X11-unix/X$display_number" ] && break
  attempt=$((attempt + 1))
  sleep 0.1
done
[ -S "/tmp/.X11-unix/X$display_number" ] || {
  cat /tmp/ternux-firefox-xvfb.log >&2
  echo 'Xvfb did not become ready' >&2
  exit 1
}

export DISPLAY=":$display_number"
openbox >/tmp/ternux-firefox-wm.log 2>&1 &
wm_pid=$!
export HOME=/tmp/firefox-home
export XDG_RUNTIME_DIR=/tmp/firefox-run
# GitHub's container runner blocks unprivileged user namespaces (clone returns
# EPERM), so Firefox cannot create its content sandbox there. Keep the browser
# test in a disposable, network-isolated CI container and disable only that
# sandbox layer for this probe. Real guest installations retain Firefox's
# normal sandbox settings.
export MOZ_DISABLE_CONTENT_SANDBOX=1
mkdir -p "$HOME" "$XDG_RUNTIME_DIR"
chmod 0700 "$XDG_RUNTIME_DIR"
cat >/tmp/ternux-browser-probe.html <<'HTML'
<!doctype html><meta charset="utf-8"><title>Ternux Browser Probe</title>
<h1>Firefox desktop startup probe</h1><p>local page rendered</p>
HTML

dbus-run-session -- "$browser" --no-remote --new-instance \
  file:///tmp/ternux-browser-probe.html >/tmp/ternux-firefox.log 2>&1 &
browser_pid=$!

attempt=0
window_id=
while [ "$attempt" -lt 300 ]; do
  window_id="$(xdotool search --onlyvisible --name 'Ternux Browser Probe' 2>/dev/null | head -n 1 || true)"
  if [ -n "$window_id" ]; then
    break
  fi
  if ! kill -0 "$browser_pid" 2>/dev/null; then
    cat /tmp/ternux-firefox.log >&2
    echo 'Firefox exited before rendering the local probe page' >&2
    exit 1
  fi
  attempt=$((attempt + 1))
  sleep 0.2
done

[ -n "$window_id" ] &&
  case "$(xdotool getwindowname "$window_id" 2>/dev/null || true)" in
    *'Ternux Browser Probe'*) ;;
    *) false ;;
  esac || {
    cat /tmp/ternux-firefox.log >&2
    echo 'Firefox did not render the expected local page title within 60 seconds' >&2
    exit 1
  }
kill -0 "$browser_pid"
echo 'PASS: Firefox mapped a visible GTK window and rendered the local probe page'
