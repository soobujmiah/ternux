#!/bin/sh
# Add branded one-click Camera, Photos and Sound Recorder buttons to Xfce.
set -u
home="${HOME:-/home/ternux}"
marker="$home/.config/ternux/panel-shortcuts-v2"
[ -e "$marker" ] && exit 0
command -v xfconf-query >/dev/null 2>&1 || exit 0
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
config_dir="$home/.config/xfce4/panel"
install -d -m 0755 "$config_dir" "$home/.config/ternux"
new_ids=""
for desktop in ternux-camera.desktop ternux-photos.desktop ternux-recorder.desktop; do
  [ -r "/usr/share/applications/$desktop" ] || continue
  found=0
  plugin_ids="$(xfconf-query -c xfce4-panel -l 2>/dev/null | sed -n 's#^/plugins/plugin-\([0-9][0-9]*\)\(/.*\)\{0,1\}$#\1#p' | sort -nu)"
  for id in $plugin_ids; do
    items="$(xfconf-query -c xfce4-panel -p "/plugins/plugin-$id/items" 2>/dev/null || true)"
    printf '%s\n' "$items" | grep -Fxq "$desktop" && { found=1; break; }
  done
  [ "$found" -eq 0 ] || continue
  max=$((max + 1))
  mkdir -p "$config_dir/launcher-$max"
  cp "/usr/share/applications/$desktop" "$config_dir/launcher-$max/$desktop"
  xfconf-query -c xfce4-panel -p "/plugins/plugin-$max" --create -t string -s launcher || exit 1
  xfconf-query -c xfce4-panel -p "/plugins/plugin-$max/items" --create -t string -s "$desktop" --force-array || exit 1
  new_ids="$new_ids $max"
done
set --
for id in $old_ids; do set -- "$@" -t int -s "$id"; done
for id in $new_ids; do set -- "$@" -t int -s "$id"; done
if [ -n "$new_ids" ]; then
  xfconf-query -c xfce4-panel -p "$plugin_list" "$@" --force-array || exit 1
fi
: > "$marker"
