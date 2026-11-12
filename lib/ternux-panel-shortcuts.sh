#!/bin/sh
# Build a useful branded dock and migrate away from empty placeholder launchers.
set -u
home="${HOME:-/home/ternux}"
marker="$home/.config/ternux/panel-shortcuts-v6"
[ -e "$marker" ] && exit 0
command -v xfconf-query >/dev/null 2>&1 || exit 0
install -d -m 0755 "$home/.config/xfce4/panel" "$home/.config/ternux"

plugin_ids="$(xfconf-query -c xfce4-panel -l 2>/dev/null | sed -n 's#^/plugins/plugin-\([0-9][0-9]*\)\(/.*\)\{0,1\}$#\1#p' | sort -nu)"
remove_panel_plugin() {
  id="$1"
  for panel in 1 2; do
    path="/panels/panel-$panel/plugin-ids"
    ids="$(xfconf-query -c xfce4-panel -p "$path" 2>/dev/null | sed -n '/^[0-9][0-9]*$/p')"
    found=0; set --
    for item in $ids; do
      if [ "$item" = "$id" ]; then found=1; else set -- "$@" -t int -s "$item"; fi
    done
    if [ "$found" -eq 1 ]; then
      if [ "$#" -gt 0 ]; then
        xfconf-query -c xfce4-panel -p "$path" "$@" --force-array >/dev/null 2>&1 || return 1
      else
        xfconf-query -c xfce4-panel -p "$path" -r >/dev/null 2>&1 || return 1
      fi
    fi
  done
  xfconf-query -c xfce4-panel -p "/plugins/plugin-$id" -r -R >/dev/null 2>&1 || true
}

remove_keyboard_launcher() {
  for id in $plugin_ids; do
    items="$(xfconf-query -c xfce4-panel -p "/plugins/plugin-$id/items" 2>/dev/null || true)"
    printf '%s\n' "$items" | grep -Fxq ternux-input-method.desktop || continue
    remove_panel_plugin "$id"
    rm -f "$home/.config/xfce4/panel/launcher-$id/ternux-input-method.desktop"
    rmdir "$home/.config/xfce4/panel/launcher-$id" 2>/dev/null || true
  done
}

remove_empty_launchers() {
  for id in $plugin_ids; do
    kind="$(xfconf-query -c xfce4-panel -p "/plugins/plugin-$id" 2>/dev/null || true)"
    [ "$kind" = launcher ] || continue
    items="$(xfconf-query -c xfce4-panel -p "/plugins/plugin-$id/items" 2>/dev/null || true)"
    case "$items" in *'array with 0 items'*) items="" ;; esac
    items="$(printf '%s\n' "$items" | sed '/^[[:space:]]*$/d; /^Value is an array with [0-9][0-9]* items:$/d')"
    [ -z "$items" ] || continue
    remove_panel_plugin "$id"
    rmdir "$home/.config/xfce4/panel/launcher-$id" 2>/dev/null || true
  done
}

remove_keyboard_launcher
remove_empty_launchers
plugin_ids="$(xfconf-query -c xfce4-panel -l 2>/dev/null | sed -n 's#^/plugins/plugin-\([0-9][0-9]*\)\(/.*\)\{0,1\}$#\1#p' | sort -nu)"
max=0
for id in $plugin_ids; do [ "$id" -gt "$max" ] && max="$id"; done
if xfconf-query -c xfce4-panel -p /panels/panel-2/plugin-ids >/dev/null 2>&1; then panel=2; else panel=1; fi
plugin_list="/panels/panel-$panel/plugin-ids"

attach_plugin() {
  id="$1"
  ids="$(xfconf-query -c xfce4-panel -p "$plugin_list" 2>/dev/null | sed -n '/^[0-9][0-9]*$/p')"
  printf '%s\n' "$ids" | grep -Fxq "$id" && return 0
  set --
  for item in $ids; do set -- "$@" -t int -s "$item"; done
  set -- "$@" -t int -s "$id"
  xfconf-query -c xfce4-panel -p "$plugin_list" "$@" --force-array
}

add_shortcut() {
  desktop="$1"
  [ -r "/usr/share/applications/$desktop" ] || return 0
  existing=""
  for id in $plugin_ids; do
    items="$(xfconf-query -c xfce4-panel -p "/plugins/plugin-$id/items" 2>/dev/null || true)"
    if printf '%s\n' "$items" | grep -Fxq "$desktop"; then existing="$id"; break; fi
  done
  if [ -n "$existing" ]; then attach_plugin "$existing"; return $?; fi

  max=$((max + 1)); id="$max"
  dir="$home/.config/xfce4/panel/launcher-$id"; mkdir -p "$dir"
  cp "/usr/share/applications/$desktop" "$dir/$desktop" || return 1
  xfconf-query -c xfce4-panel -p "/plugins/plugin-$id" --create -t string -s launcher || return 1
  xfconf-query -c xfce4-panel -p "/plugins/plugin-$id/items" --create -t string -s "$desktop" --force-array || return 1
  plugin_ids="$plugin_ids $id"
  attach_plugin "$id"
}

# These apps are part of the base desktop. Every .desktop Icon name resolves
# through the same Ternux icon theme, so the dock stays consistent.
for desktop in thunar.desktop xfce4-terminal.desktop vlc.desktop org.xfce.ristretto.desktop ternux-camera.desktop ternux-photos.desktop ternux-recorder.desktop; do
  add_shortcut "$desktop" || exit 1
done
: > "$marker"
xfce4-panel --restart >/dev/null 2>&1 || true
