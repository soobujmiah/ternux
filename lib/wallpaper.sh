# =============================================================================
#  ternux — Wallpaper Apply Manager
#
#  Deliberately separate from the Wallpaper Generator (tools/generate_
#  wallpapers.py, which only produces source art + processed assets at
#  build time). This module's job is narrow: read the manifest, detect
#  the active theme, select the matching preprocessed colorway, and
#  write a handful of xfconf properties — no image processing happens
#  here, every asset was already generated and shipped at install time.
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah)
#  Licensed under the Apache License, Version 2.0.
#  https://github.com/soobujmiah/ternux
# =============================================================================

# shellcheck source=lib/core.sh
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"

# ---------------------------------------------------------------------------
# tnx_cmd_wallpaper
# ---------------------------------------------------------------------------
tnx_cmd_wallpaper() {
  local subcmd="${1:-list}"
  shift 2>/dev/null || true
  case "$subcmd" in
    list|--list|gallery) _tnx_wallpaper_list ;;
    current|--current)   _tnx_wallpaper_current "${1:-}" ;;
    set|--set)            _tnx_wallpaper_set "${1:-}" "${2:-}" ;;
    refresh|--refresh)    _tnx_wallpaper_refresh "${1:-}" ;;
    --help|-h)            tnx_help_wallpaper ;;
    *) tnx_fail "Usage: ternux wallpaper [list|current|set <id>|refresh] [DISTRO]"; return 1 ;;
  esac
}

_tnx_wallpaper_assets_dir() {
  local dir="${BASH_SOURCE[0]%/*}/ternux-assets/wallpapers-v3"
  if [ ! -f "$dir/manifest.json" ]; then
    tnx_fail "Wallpaper manifest not found under $dir. Reinstall or run: ternux install --resume"
    return 1
  fi
  printf '%s\n' "$dir"
}

_tnx_wallpaper_target_distro() {
  local distro="${1:-}"
  [ -n "$distro" ] || distro="$(tnx_distro)"
  distro="$(tnx_distro_canonical "$distro")"
  tnx_distro_known "$distro" || { tnx_fail "Unknown managed guest: $distro"; return 2; }
  printf '%s\n' "$distro"
}

# Reads the live xfsettings theme when the desktop session is reachable
# (bounded, read-only, never blocks); falls back to the last value this
# module recorded, then the shipped default. Never fails the caller.
_tnx_wallpaper_active_theme() {
  local distro="$1" user="" theme=""
  user="$(tnx_distro_user "$distro" 2>/dev/null || true)"
  [ -n "$user" ] || user=ternux
  theme="$(tnx_guest_login --_tnx-timeout-seconds 5 --user "$user" -- \
    xfconf-query -c xsettings -p /Net/ThemeName 2>/dev/null)" || theme=""
  [ -n "$theme" ] || theme="$(tnx_state_get wallpaper_theme 2>/dev/null || true)"
  [ -n "$theme" ] || theme="Green"
  printf '%s\n' "$theme"
}

_tnx_wallpaper_colorway_for_theme() {
  case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
    crimson) printf 'crimson\n' ;;
    *)       printf 'green\n' ;;
  esac
}

_tnx_wallpaper_list() {
  local assets_dir; assets_dir="$(_tnx_wallpaper_assets_dir)" || return 1
  local current_id; current_id="$(tnx_state_get wallpaper_id 2>/dev/null || true)"

  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    python3 - "$assets_dir/manifest.json" "$current_id" <<'PY'
import json, sys
manifest, current = sys.argv[1], sys.argv[2]
data = json.load(open(manifest))
for w in data["wallpapers"]:
    w["active"] = (w["id"] == current)
print(json.dumps({"command": "wallpaper", "status": "ok", "wallpapers": data["wallpapers"]}))
PY
    return 0
  fi

  tnx_header "Wallpaper Gallery"
  python3 - "$assets_dir/manifest.json" "$current_id" <<'PY'
import json, sys
manifest, current = sys.argv[1], sys.argv[2]
data = json.load(open(manifest))
for w in data["wallpapers"]:
    mark = "*" if w["id"] == current else " "
    colorways = ", ".join(sorted(w["colorways"]))
    print(f"  [{mark}] {w['id']:<28} {w['concept']}")
    print(f"        {w['description']}")
    print(f"        colorways: {colorways}")
PY
  echo ""
  printf "  Apply: %sternux wallpaper set <id>%s · Current: %sternux wallpaper current%s\n" \
    "$TNX_CC" "$TNX_C0" "$TNX_CC" "$TNX_C0"
  echo ""
}

_tnx_wallpaper_current() {
  local distro; distro="$(_tnx_wallpaper_target_distro "$1")" || return $?
  local current_id theme colorway
  current_id="$(tnx_state_get wallpaper_id 2>/dev/null || true)"
  theme="$(_tnx_wallpaper_active_theme "$distro")"
  colorway="$(_tnx_wallpaper_colorway_for_theme "$theme")"

  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    tnx_json_object "wallpaper" "ok" "wallpaper_id" "${current_id:-none}" "theme" "$theme" "colorway" "$colorway"
    return 0
  fi

  tnx_header "Current Wallpaper"
  tnx_print_field 'Selection:' "${current_id:-none (install default)}"
  tnx_print_field 'Active theme:' "$theme"
  tnx_print_field 'Colorway:' "$colorway"
  echo ""
}

# Re-applies the already-selected wallpaper using whatever colorway matches
# the theme right now. Safe no-op if nothing has been selected through this
# module yet (install defaults and any user-chosen custom image are left
# alone — this never guesses at what a user wants).
_tnx_wallpaper_refresh() {
  local distro; distro="$(_tnx_wallpaper_target_distro "$1")" || return $?
  local current_id; current_id="$(tnx_state_get wallpaper_id 2>/dev/null || true)"
  if [ -z "$current_id" ]; then
    tnx_info "No Ternux-managed wallpaper selection to refresh. Run: ternux wallpaper set <id>"
    [ "${TERNUX_JSON:-0}" = "1" ] && tnx_json_object "wallpaper" "unchanged" "reason" "no_selection"
    return 0
  fi
  _tnx_wallpaper_set "$current_id" "$distro"
}

_tnx_wallpaper_set() {
  local id="$1" distro
  [ -n "$id" ] || { tnx_fail "Usage: ternux wallpaper set <id> [DISTRO]"; return 1; }
  distro="$(_tnx_wallpaper_target_distro "$2")" || return $?

  local assets_dir; assets_dir="$(_tnx_wallpaper_assets_dir)" || return 1
  local theme colorway rel_path
  theme="$(_tnx_wallpaper_active_theme "$distro")"
  colorway="$(_tnx_wallpaper_colorway_for_theme "$theme")"

  rel_path="$(python3 - "$assets_dir/manifest.json" "$id" "$colorway" <<'PY'
import json, sys
manifest, wid, colorway = sys.argv[1:]
data = json.load(open(manifest))
match = next((w for w in data["wallpapers"] if w["id"] == wid), None)
if match is None:
    sys.exit(1)
entry = match["colorways"].get(colorway)
if entry is None:
    sys.exit(2)
print(entry["asset_path"])
PY
  )"
  case $? in
    0) ;;
    1) tnx_fail "Unknown wallpaper id: $id. Run: ternux wallpaper list"; return 1 ;;
    *) tnx_fail "Wallpaper '$id' has no '$colorway' colorway in the manifest."; return 1 ;;
    esac

  # manifest paths are repo-relative (lib/ternux-assets/wallpapers-v3/<id>/...);
  # the installed guest copy lives under /usr/share/backgrounds/ternux-v3/<id>/...
  local guest_path="/usr/share/backgrounds/ternux-v3/${rel_path#lib/ternux-assets/wallpapers-v3/}"
  local user; user="$(tnx_distro_user "$distro" 2>/dev/null || true)"
  [ -n "$user" ] || user=ternux

  if ! tnx_guest_login --_tnx-timeout-seconds 20 --user "$user" -- bash -c "
    set -e
    path='$guest_path'
    [ -r \"\$path\" ] || { echo \"Wallpaper asset missing in guest: \$path\" >&2; exit 1; }
    for monitor in monitor0 monitor1 monitorbuiltin; do
      style=4
      [ \"\$monitor\" = monitorbuiltin ] && style=5
      xfconf-query -c xfce4-desktop -p \"/backdrop/screen0/\$monitor/image-path\" --create -t string -s \"\$path\" >/dev/null 2>&1 || true
      xfconf-query -c xfce4-desktop -p \"/backdrop/screen0/\$monitor/last-image\" --create -t string -s \"\$path\" >/dev/null 2>&1 || true
      xfconf-query -c xfce4-desktop -p \"/backdrop/screen0/\$monitor/workspace0/last-image\" --create -t string -s \"\$path\" >/dev/null 2>&1 || true
      xfconf-query -c xfce4-desktop -p \"/backdrop/screen0/\$monitor/image-style\" --create -t int -s \"\$style\" >/dev/null 2>&1 || true
      xfconf-query -c xfce4-desktop -p \"/backdrop/screen0/\$monitor/image-show\" --create -t bool -s true >/dev/null 2>&1 || true
    done
    xfdesktop --reload >/dev/null 2>&1 || true
  "; then
    tnx_fail "Could not apply wallpaper '$id'. Is the $distro desktop session running? Try: ternux start $distro"
    [ "${TERNUX_JSON:-0}" = "1" ] && tnx_json_object "wallpaper" "error" "wallpaper_id" "$id" "reason" "guest_apply_failed"
    return 1
  fi

  tnx_state_set "wallpaper_id" "$id"
  tnx_state_set "wallpaper_theme" "$theme"
  tnx_ok "Wallpaper set: $id ($colorway)"
  [ "${TERNUX_JSON:-0}" = "1" ] && tnx_json_object "wallpaper" "updated" "wallpaper_id" "$id" "theme" "$theme" "colorway" "$colorway"
  return 0
}
