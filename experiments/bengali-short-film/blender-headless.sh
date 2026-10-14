#!/bin/sh
# Run Blender on the GPU without the Termux:X11 app.
#
# Blender's EEVEE needs a GL context, and with no DISPLAY it falls back to EGL
# and fails with EGL_BAD_MATCH. A virtual X server is enough: the GPU still does
# the work through zink and Turnip. GALLIUM_DRIVER=zink is required, because on
# a virtual display Mesa otherwise picks llvmpipe, which dies with SIGILL here.
#
#   ./blender-headless.sh -b --factory-startup --python render.py -- --shot 1
set -eu
: "${HEADLESS_DISPLAY:=:9}"
if ! DISPLAY=$HEADLESS_DISPLAY xdpyinfo >/dev/null 2>&1; then
    Xvfb "$HEADLESS_DISPLAY" -screen 0 1280x720x24 >/tmp/xvfb-blender.log 2>&1 &
    i=0
    while ! DISPLAY=$HEADLESS_DISPLAY xdpyinfo >/dev/null 2>&1; do
        i=$((i + 1))
        [ "$i" -gt 50 ] && { echo "Xvfb did not start; see /tmp/xvfb-blender.log" >&2; exit 1; }
        sleep 0.2
    done
fi
exec env DISPLAY="$HEADLESS_DISPLAY" GALLIUM_DRIVER=zink blender "$@"
