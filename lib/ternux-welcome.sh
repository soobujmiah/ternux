#!/bin/sh
set -eu
SITE=https://soobujmiah.github.io/ternux/
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/ternux/welcome-seen"

# Run this welcome flow once per guest user. This always runs inside a
# live XFCE session (started from ~/.config/autostart), so the native GTK
# Welcome Center is the primary first-run experience, not a browser tab —
# falling back to the website, then a plain text dialog, only if GTK/
# python3-gi itself cannot start.
[ ! -e "$STATE" ] || exit 0
mkdir -p "$(dirname "$STATE")"
# Record before launching so a slow or still-running app cannot repeat the
# welcome flow on the next desktop login.
: > "$STATE"

if [ -x /usr/local/libexec/ternux-welcome-gui.py ] && /usr/local/libexec/ternux-welcome-gui.py; then
    exit 0
fi

if command -v firefox-esr >/dev/null 2>&1; then
    exec firefox-esr --new-window "$SITE"
fi

# Last-resort text dialog for a damaged GTK3 Python install.
if command -v zenity >/dev/null 2>&1; then
    GSK_RENDERER=cairo zenity --info --title='Welcome to Ternux' --width=420 --text='Ternux is maintained by Sobuj Miah.\n\nProject: soobujmiah.github.io/ternux\nGuest commands: ternux info, status, doctor\nBangla Avro: Ctrl+Space\nGPU benchmark (Termux host): ternux benchmark'
fi
