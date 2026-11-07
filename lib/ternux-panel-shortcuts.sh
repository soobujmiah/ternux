#!/bin/sh
# Add branded, one-click Camera and Photos buttons to the Xfce dock once.
set -u

home="${HOME:-/home/ternux}"
marker="$home/.config/ternux/panel-shortcuts-v1"
[ -e "$marker" ] && exit 0
command -v xfconf-query >/dev/null 2>&1 || exit 0
[ -r /usr/share/applications/ternux-camera.desktop ] || exit 0
[ -r /usr/share/applications/ternux-photos.desktop ] || exit 0

panel=2
if ! xfconf-query -c xfce4-panel -p /panels/panel-2/plugin-ids >/dev/null 2>&1; then
  panel=1
  xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids >/dev/null 2>&1 || exit 0
fi
plugin_list="/panels/panel-$panel/plugin-ids"
old_ids="$(xfconf-query -c xfce4-panel -p "$plugin_list" 2>/dev/null | sed -n '/^[0-9][0-9]*$/p')"
[ -n "$old_ids" ] || exit 0

max=0
all_plugins="$(xfconf-query -c xfce4-panel -l 2>/dev/null | sed -n 's#^/plugins/plugin-\([0-9][0-9]*\)\(/.*\)\{0,1\}$#\1#p' | sort -n | tail -1)"
case "$all_plugins" in ''|*[!0-9]*) ;; *) max="$all_plugins" ;; esac
camera_id=$((max + 1))
photos_id=$((max + 2))
config_dir="$home/.config/xfce4/panel"
install -d -m 0755 "$config_dir/launcher-$camera_id" "$config_dir/launcher-$photos_id" "$home/.config/ternux"
cp /usr/share/applications/ternux-camera.desktop "$config_dir/launcher-$camera_id/ternux-camera.desktop"
cp /usr/share/applications/ternux-photos.desktop "$config_dir/launcher-$photos_id/ternux-photos.desktop"

xfconf-query -c xfce4-panel -p "/plugins/plugin-$camera_id" --create -t string -s launcher || exit 1
xfconf-query -c xfce4-panel -p "/plugins/plugin-$camera_id/items" --create -t string -s ternux-camera.desktop --force-array || exit 1
xfconf-query -c xfce4-panel -p "/plugins/plugin-$photos_id" --create -t string -s launcher || exit 1
xfconf-query -c xfce4-panel -p "/plugins/plugin-$photos_id/items" --create -t string -s ternux-photos.desktop --force-array || exit 1

# Rebuild the typed integer array, retaining every existing panel item.
set --
for id in $old_ids; do
  set -- "$@" -t int -s "$id"
done
set -- "$@" -t int -s "$camera_id" -t int -s "$photos_id"
if xfconf-query -c xfce4-panel -p "$plugin_list" "$@" --force-array; then
  : > "$marker"
else
  exit 1
fi
