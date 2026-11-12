#!/bin/sh
set -eu
SITE=https://soobujmiah.github.io/ternux/
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/ternux/welcome-seen"

# Run this welcome flow once per guest user, with the base desktop browser.
[ ! -e "$STATE" ] || exit 0
mkdir -p "$(dirname "$STATE")"
# Record before launching so a slow or still-running browser cannot repeat the
# welcome URL on the next desktop login.
: > "$STATE"

if command -v firefox-esr >/dev/null 2>&1; then
    exec firefox-esr --new-window "$SITE"
fi

# Show the responsive first-run guide when no graphical session is available.
if [ -x /usr/local/libexec/ternux-welcome-gui.py ]; then
    exec /usr/local/libexec/ternux-welcome-gui.py
fi

# Last-resort text dialog for a damaged GTK3 Python install.
if command -v zenity >/dev/null 2>&1; then
    GSK_RENDERER=cairo zenity --info --title='Welcome to Ternux' --width=420 --text='Ternux is maintained by Sobuj Miah.\n\nProject: soobujmiah.github.io/ternux\nGuest commands: ternux info, status, doctor\nBangla Avro: Ctrl+Space\nGPU benchmark (Termux host): ternux benchmark'
fi
