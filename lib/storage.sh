#!/usr/bin/env bash
# Scoped Android shared-storage grants for PRoot guest sessions.

_tnx_storage_file() { printf '%s/storage-allowlist' "$TERNUX_STATE_DIR"; }

tnx_cmd_storage() {
  local action="${1:-list}" path root resolved relative file tmp host guest existing existing_guest extra existing_real
  case "$action" in
    list)
      shift || true
      [ "$#" -eq 0 ] || { tnx_help_storage; return 2; }
      file="$(_tnx_storage_file)"
      [ ! -L "$file" ] && { [ ! -e "$file" ] || [ -f "$file" ]; } || { echo "Unsafe Ternux storage allowlist; inspect $file." >&2; return 1; }
      if [ ! -s "$file" ]; then echo "No Android storage directories are granted."; return 0; fi
      while IFS=$'\t' read -r host guest; do [ -n "$guest" ] && printf '%s\n' "$guest"; done < "$file"
      ;;
    grant|revoke)
      shift
      [ "$#" -eq 1 ] && [ -n "$1" ] || { tnx_help_storage; return 2; }
      path="$1"
      case "$path" in *$'\n'*|*$'\r'*|*$'\t'*) echo "Storage path must be a single-line path." >&2; return 2 ;; esac
      case "$path" in /sdcard/*|/storage/emulated/0/*) ;; *) echo "Choose a directory below /sdcard; the storage root itself is never allowed." >&2; return 2 ;; esac
      case "$path" in *"/../"*|*"/./"*|*/..|*/.) echo "Storage path must not contain dot segments." >&2; return 2 ;; esac
      file="$(_tnx_storage_file)"
      if [ "$action" = revoke ]; then
        case "$path" in /sdcard/*) guest="$path" ;; /storage/emulated/0/*) guest="/sdcard/${path#/storage/emulated/0/}" ;; esac
        [ ! -L "$file" ] && { [ ! -e "$file" ] || [ -f "$file" ]; } || { echo "Unsafe Ternux storage allowlist; inspect $file." >&2; return 1; }
        [ -f "$file" ] || { echo "No matching storage grant: $guest"; return 0; }
        tmp="$(umask 077; mktemp "${file}.tmp.XXXXXX")" || return 1
        local revoked=0
        while IFS=$'\t' read -r existing existing_guest extra; do
          [ -n "$existing" ] || continue
          [ -z "$extra" ] || { rm -f -- "$tmp"; echo "Malformed Ternux storage grant; refusing to update it." >&2; return 1; }
          if [ "$existing_guest" = "$guest" ]; then revoked=1; continue; fi
          printf '%s\t%s\n' "$existing" "$existing_guest" >> "$tmp" || { rm -f -- "$tmp"; return 1; }
        done < "$file"
        chmod 0600 "$tmp" && mv -f -- "$tmp" "$file" || { rm -f -- "$tmp"; return 1; }
        [ -s "$file" ] || rm -f -- "$file"
        if [ "$revoked" = 1 ]; then echo "Revoked $guest. Existing guest sessions keep their current mount until they exit."; else echo "No matching storage grant: $guest"; fi
        return 0
      fi
      root="$(realpath -e /sdcard 2>/dev/null)" || root=""
      if [ -z "$root" ] && tnx_has_cmd termux-setup-storage; then
        termux-setup-storage || return 1
        root="$(realpath -e /sdcard 2>/dev/null)" || root=""
      fi
      [ -n "$root" ] || { echo "Android shared storage is unavailable. Complete Android storage permission, then retry." >&2; return 1; }
      resolved="$(realpath -e -- "$path" 2>/dev/null)" || { echo "Directory does not exist or is not accessible: $path" >&2; return 1; }
      [[ "$resolved" == "$root"/* ]] && [ -d "$resolved" ] || { echo "Directory must resolve to a subdirectory of Android shared storage." >&2; return 2; }
      case "$resolved" in *:*|*$'\n'*|*$'\r'*|*$'\t'*) echo "Storage paths with colon, tab or newline characters cannot be mounted safely." >&2; return 2 ;; esac
      relative="${resolved#"$root"/}"
      [ -n "$relative" ] || { echo "The shared storage root cannot be granted." >&2; return 2; }
      host="$resolved"; guest="/sdcard/$relative"
      [[ "$host" != *:* && "$guest" != *:* ]] || { echo "Storage paths containing ':' cannot be mounted safely." >&2; return 2; }
      install -d -m 0700 -- "$TERNUX_STATE_DIR" || return 1
      [ ! -L "$file" ] && { [ ! -e "$file" ] || [ -f "$file" ]; } || { echo "Unsafe Ternux storage allowlist; inspect $file." >&2; return 1; }
      tmp="$(umask 077; mktemp "${file}.tmp.XXXXXX")" || return 1
      if [ -f "$file" ]; then
        while IFS=$'\t' read -r existing existing_guest extra; do
          [ -n "$existing" ] || continue
          expected_guest="/sdcard/${existing#"$root"/}"
          [ -z "$extra" ] && [[ "$existing" == "$root"/* && "$existing" != *:* && "$existing_guest" == "$expected_guest" && "$existing_guest" != *:* ]] || { rm -f -- "$tmp"; echo "Malformed Ternux storage grant; refusing to update it." >&2; return 1; }
          existing_real="$(realpath -e -- "$existing" 2>/dev/null)" || { rm -f -- "$tmp"; echo "A previously granted directory is unavailable; refusing to update grants." >&2; return 1; }
          [ "$existing_real" = "$existing" ] && [ -d "$existing" ] || { rm -f -- "$tmp"; echo "A previously granted directory changed identity; refusing to update grants." >&2; return 1; }
          [ "$existing" = "$host" ] && [ "$action" = grant ] && { rm -f -- "$tmp"; echo "Already granted: $guest"; return 0; }
          [ "$existing" = "$host" ] && [ "$action" = revoke ] && continue
          printf '%s\t%s\n' "$existing" "$existing_guest" >> "$tmp" || { rm -f -- "$tmp"; return 1; }
        done < "$file"
      fi
      if [ "$action" = grant ]; then printf '%s\t%s\n' "$host" "$guest" >> "$tmp" || { rm -f -- "$tmp"; return 1; }; fi
      chmod 0600 "$tmp" && mv -f -- "$tmp" "$file" || { rm -f -- "$tmp"; return 1; }
      [ -s "$file" ] || rm -f -- "$file"
      if [ "$action" = grant ]; then echo "Granted $guest. Restart the desktop to apply this new mount."; else echo "Revoked $guest. Existing guest sessions keep their current mount until they exit."; fi
      ;;
    *) tnx_help_storage; return 2 ;;
  esac
}
