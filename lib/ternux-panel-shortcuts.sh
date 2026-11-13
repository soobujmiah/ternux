#!/bin/sh
# Keep the Ternux lower panel's launcher set consistent across guest distros.
set -u
home="${HOME:-/home/ternux}"
marker="$home/.config/ternux/panel-shortcuts-v7"
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
  rm -f "$home/.config/xfce4/panel/launcher-$id"/*.desktop
  rmdir "$home/.config/xfce4/panel/launcher-$id" 2>/dev/null || true
}

remove_keyboard_launcher() {
  for id in $plugin_ids; do
    items="$(xfconf-query -c xfce4-panel -p "/plugins/plugin-$id/items" 2>/dev/null || true)"
    printf '%s\n' "$items" | grep -Fxq ternux-input-method.desktop || continue
    remove_panel_plugin "$id"
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

aliases_for() {
  case "$1" in
    ternux-file-manager.desktop) printf '%s\n' 'File Manager|Thunar' ;;
    ternux-terminal.desktop) printf '%s\n' 'Terminal Emulator|Xfce Terminal|Xfce Terminal Emulator' ;;
    ternux-web-browser.desktop) printf '%s\n' 'Web Browser|Firefox' ;;
    ternux-appfinder.desktop) printf '%s\n' 'Application Finder|Application Finder (Run Program...)' ;;
    vlc.desktop) printf '%s\n' 'VLC media player|VLC' ;;
    ternux-camera.desktop) printf '%s\n' 'Ternux Camera' ;;
    ternux-photos.desktop) printf '%s\n' 'Ternux Photos' ;;
    ternux-recorder.desktop) printf '%s\n' 'Ternux Sound Recorder' ;;
  esac
}

find_existing_shortcut() {
  expected="$1"
  aliases="|$(aliases_for "$expected")|"
  for id in $plugin_ids; do
    kind="$(xfconf-query -c xfce4-panel -p "/plugins/plugin-$id" 2>/dev/null || true)"
    [ "$kind" = launcher ] || continue
    for shortcut_file in "$home"/.config/xfce4/panel/launcher-"$id"/*.desktop; do
      [ -f "$shortcut_file" ] || continue
      name="$(sed -n 's/^Name=//p' "$shortcut_file" | head -n 1)"
      case "$aliases" in *"|$name|"*) printf '%s\n' "$id"; return 0 ;; esac
    done
    items="$(xfconf-query -c xfce4-panel -p "/plugins/plugin-$id/items" 2>/dev/null || true)"
    printf '%s\n' "$items" | grep -Fxq "$expected" && { printf '%s\n' "$id"; return 0; }
  done
  return 1
}

add_shortcut() {
  desktop="$1"
  [ -r "/usr/share/applications/$desktop" ] || return 0
  existing="$(find_existing_shortcut "$desktop" || true)"
  if [ -n "$existing" ]; then attach_plugin "$existing"; return $?; fi
  max=$((max + 1)); id="$max"
  dir="$home/.config/xfce4/panel/launcher-$id"; mkdir -p "$dir"
  cp "/usr/share/applications/$desktop" "$dir/$desktop" || return 1
  xfconf-query -c xfce4-panel -p "/plugins/plugin-$id" --create -t string -s launcher || return 1
  xfconf-query -c xfce4-panel -p "/plugins/plugin-$id/items" --create -t string -s "$desktop" --force-array || return 1
  plugin_ids="$plugin_ids $id"
  attach_plugin "$id"
}

# Remove the old standalone image-viewer item; Photos now serves that purpose.
for id in $plugin_ids; do
  items="$(xfconf-query -c xfce4-panel -p "/plugins/plugin-$id/items" 2>/dev/null || true)"
  printf '%s\n' "$items" | grep -Fxq org.xfce.ristretto.desktop && remove_panel_plugin "$id"
done

# Preserve the visible Debian dock set, using stable Ternux desktop entries.
for desktop in ternux-terminal.desktop ternux-file-manager.desktop ternux-web-browser.desktop ternux-appfinder.desktop vlc.desktop ternux-camera.desktop ternux-photos.desktop ternux-recorder.desktop; do
  add_shortcut "$desktop" || exit 1
done
: > "$marker"
xfce4-panel --restart >/dev/null 2>&1 || true
