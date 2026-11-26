# =============================================================================
#  ternux — Theme switching (Green / Crimson)
#
#  Live-switches the installed system theme (xsettings ThemeName, xfwm4
#  decorations), refreshes the per-user GTK managed override with the
#  newly selected theme's content, and re-applies the active wallpaper's
#  matching colorway. The icon theme is never touched here — it is
#  intentionally theme-independent (see lib/wallpaper.sh and the V3
#  design plan for why).
#
#  What updates live vs. needs a smaller refresh:
#    - xsettings ThemeName / xfwm4 general/theme: live, standard XFCE
#      xsettings broadcast — no restart needed.
#    - The per-user ~/.config/gtk-{3,4}.0/gtk.css managed override: GTK
#      only reads this at process startup, so already-running apps keep
#      their old override styling until reopened. This is a GTK
#      limitation, not something Ternux can work around without patching
#      GTK itself; reopening the affected app is the "smallest necessary
#      refresh" the design brief asks for, not a full session restart.
#    - Wallpaper: re-applies via the Wallpaper Apply Manager's existing
#      refresh logic, so the active selection's colorway follows the
#      new theme automatically (only if a selection was made through
#      `ternux wallpaper set`; an install default or custom image is
#      left alone, same rule as the wallpaper module itself).
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah)
#  Licensed under the Apache License, Version 2.0.
#  https://github.com/soobujmiah/ternux
# =============================================================================

# shellcheck source=lib/core.sh
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"
# shellcheck source=lib/wallpaper.sh
. "$(dirname "${BASH_SOURCE[0]}")/wallpaper.sh"

TNX_THEMES="Green Crimson"

# ---------------------------------------------------------------------------
# tnx_cmd_theme
# ---------------------------------------------------------------------------
tnx_cmd_theme() {
  local subcmd="${1:-show}"
  shift 2>/dev/null || true
  case "$subcmd" in
    show|--show) _tnx_theme_show "${1:-}" ;;
    list|--list) _tnx_theme_list "${1:-}" ;;
    set|--set)   _tnx_theme_set "${1:-}" "${2:-}" ;;
    --help|-h)   tnx_help_theme ;;
    *) tnx_fail "Usage: ternux theme [show|list|set <Green|Crimson>] [DISTRO]"; return 1 ;;
  esac
}

_tnx_theme_canonical() {
  case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
    green)   printf 'Green\n' ;;
    crimson) printf 'Crimson\n' ;;
    *)       return 1 ;;
  esac
}

_tnx_theme_target_distro() {
  local distro="${1:-}"
  [ -n "$distro" ] || distro="$(tnx_distro)"
  distro="$(tnx_distro_canonical "$distro")"
  tnx_distro_known "$distro" || { tnx_fail "Unknown managed guest: $distro"; return 2; }
  printf '%s\n' "$distro"
}

_tnx_theme_active() {
  local distro="$1" user="" theme=""
  user="$(tnx_distro_user "$distro" 2>/dev/null || echo ternux)"
  unset _TNX_DISTRO; export TERNUX_DISTRO="$distro"
  theme="$(tnx_guest_login --_tnx-timeout-seconds 5 --user "$user" -- \
    xfconf-query -c xsettings -p /Net/ThemeName 2>/dev/null)" || theme=""
  [ -n "$theme" ] || theme="$(tnx_distro_state_get "$distro" theme_name 2>/dev/null || true)"
  [ -n "$theme" ] || theme="Green"
  _tnx_theme_canonical "$theme" 2>/dev/null || printf 'Green\n'
}

_tnx_theme_list() {
  local distro; distro="$(_tnx_theme_target_distro "$1")" 2>/dev/null || distro=""
  local active=""
  [ -n "$distro" ] && active="$(_tnx_theme_active "$distro")"

  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    tnx_json_object "theme" "ok" "themes" "$TNX_THEMES" "active" "${active:-unknown}"
    return 0
  fi

  tnx_header "Ternux Themes"
  local name
  for name in $TNX_THEMES; do
    local mark=" "
    [ "$name" = "$active" ] && mark="*"
    printf "  [%s] %s\n" "$mark" "$name"
  done
  echo ""
  printf "  Switch: %sternux theme set <name>%s\n" "$TNX_CC" "$TNX_C0"
  echo ""
}

_tnx_theme_show() {
  local distro; distro="$(_tnx_theme_target_distro "$1")" || return $?
  local active; active="$(_tnx_theme_active "$distro")"

  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    tnx_json_object "theme" "ok" "active" "$active"
    return 0
  fi

  tnx_header "Current Theme"
  tnx_print_field 'Active:' "$active"
  echo ""
}

_tnx_theme_set() {
  local requested="$1" distro
  [ -n "$requested" ] || { tnx_fail "Usage: ternux theme set <Green|Crimson> [DISTRO]"; return 1; }
  local name; name="$(_tnx_theme_canonical "$requested")" || {
    tnx_fail "Unknown theme '$requested'. Valid: $TNX_THEMES"
    return 1
  }
  distro="$(_tnx_theme_target_distro "$2")" || return $?

  local resource_dir="${BASH_SOURCE[0]%/*}/ternux-assets/themes/$name"
  if [ ! -d "$resource_dir" ]; then
    tnx_fail "Theme assets not found under $resource_dir. Reinstall or run: ternux install --resume"
    return 1
  fi
  local gtk3_user_css_b64 gtk4_user_css_b64
  gtk3_user_css_b64="$(base64 < "$resource_dir/gtk-3.0/gtk-user.css" | tr -d '\n')" || return 1
  gtk4_user_css_b64="$(base64 < "$resource_dir/gtk-4.0/gtk-user.css" | tr -d '\n')" || return 1

  local user; user="$(tnx_distro_user "$distro" 2>/dev/null || echo ternux)"
  unset _TNX_DISTRO; export TERNUX_DISTRO="$distro"

  if ! tnx_guest_login --_tnx-timeout-seconds 20 --user "$user" -- bash -c "
    set -e
    name='$name'
    xfconf-query -c xsettings -p /Net/ThemeName --create -t string -s \"\$name\" >/dev/null 2>&1
    xfconf-query -c xfwm4 -p /general/theme --create -t string -s \"\$name\" >/dev/null 2>&1
    # Refresh the managed section of each per-user GTK override in place,
    # the same marker-delimited replace lib/phases.sh already uses at
    # install time — never touching anything a user added outside it.
    apply_gtk_override() {
      version=\"\$1\"; payload=\"\$2\"
      dir=\"\$HOME/.config/gtk-\$version\"; file=\"\$dir/gtk.css\"
      [ ! -L \"\$dir\" ] && [ ! -L \"\$file\" ] || { echo \"Refusing symlinked GTK theme config\" >&2; return 1; }
      mkdir -p \"\$dir\"
      tmp=\"\$(mktemp \"\$dir/.ternux-gtk.css.XXXXXX\")\"
      if [ -f \"\$file\" ]; then
        sed '/^\/\* TERNUX MANAGED GTK OVERRIDE BEGIN \*\/\$/,/^\/\* TERNUX MANAGED GTK OVERRIDE END \*\/\$/d' \"\$file\" > \"\$tmp\"
      fi
      printf '%s\n' '/* TERNUX MANAGED GTK OVERRIDE BEGIN */' >> \"\$tmp\"
      printf '%s' \"\$payload\" | base64 -d >> \"\$tmp\"
      printf '\n%s\n' '/* TERNUX MANAGED GTK OVERRIDE END */' >> \"\$tmp\"
      mv -f \"\$tmp\" \"\$file\"
    }
    apply_gtk_override 3.0 '$gtk3_user_css_b64'
    apply_gtk_override 4.0 '$gtk4_user_css_b64'
    xfdesktop --reload >/dev/null 2>&1 || true
  "; then
    tnx_fail "Could not switch theme to '$name'. Is the $distro desktop session running? Try: ternux start $distro"
    [ "${TERNUX_JSON:-0}" = "1" ] && tnx_json_object "theme" "error" "reason" "guest_apply_failed"
    return 1
  fi

  tnx_distro_state_set "$distro" "theme_name" "$name"
  # Follow the active wallpaper selection's colorway to the new theme; a
  # no-op if the user never selected one through `ternux wallpaper set`.
  _tnx_wallpaper_refresh "$distro" >/dev/null 2>&1 || true

  tnx_ok "Theme set: $name"
  tnx_info "Already-open apps keep their previous GTK override styling until reopened; the system theme and window decorations updated immediately."
  [ "${TERNUX_JSON:-0}" = "1" ] && tnx_json_object "theme" "updated" "theme" "$name"
  return 0
}
