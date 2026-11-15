# Android permission helpers exposed through the shared tx/ternux command core.
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"

tnx_permission_result() {
  local command="$1" status="$2" message="$3"
  if [ "${TERNUX_JSON:-0}" = 1 ]; then
    tnx_json_init
    tnx_json_add "command" "$command"
    tnx_json_add "status" "$status"
    tnx_json_add "message" "$message"
    tnx_json_add "timestamp" "$(__tnx_ts)"
    tnx_json_add "version" "$TERNUX_VERSION"
    tnx_json_end
  else
    case "$status" in
      granted) tnx_ok "$message" ;;
      prompted) tnx_info "$message" ;;
      *) tnx_fail "$message" ;;
    esac
  fi
}

tnx_request_host_mic_permission() {
  local sources source rc=1
  tnx_has_cmd pactl && tnx_has_cmd parec && tnx_has_cmd timeout || return 1
  sources="$(pactl list sources short 2>/dev/null)" || return 1
  source="$(printf '%s\n' "$sources" | awk '$2 == "Ternux_Microphone" {print $2; exit}')"
  [ -n "$source" ] || return 1
  tnx_info "Termux:API is unavailable. Opening the built-in desktop microphone for up to 3 seconds; audio is discarded. Allow Android's Termux microphone prompt if it appears."
  timeout 3 parec --device "$source" --file-format=raw /dev/null >/dev/null 2>&1 && rc=0 || rc=$?
  case "$rc" in
    0|124) return 0 ;;
    *) return 1 ;;
  esac
}

tnx_permissions_load_phase_helpers() {
  if ! declare -F tnx_termux_api_app_installed >/dev/null 2>&1 ||
     ! declare -F tnx_request_microphone_permission >/dev/null 2>&1 ||
     ! declare -F tnx_request_camera_permission >/dev/null 2>&1; then
    . "$(dirname "${BASH_SOURCE[0]}")/phases.sh"
  fi
}

tnx_cmd_mic() {
  [ "$#" -eq 0 ] || { tnx_fail "Usage: tx mic"; return 2; }
  tnx_permissions_load_phase_helpers
  if tnx_termux_api_app_installed && tnx_has_cmd termux-microphone-record; then
    tnx_request_microphone_permission >&2
    case "${_TNX_MIC_PERMISSION_RESULT:-unavailable}" in
      granted)
        tnx_permission_result mic granted "Termux:API microphone permission is available. The maximum one-second check recording was stopped and removed."; return 0 ;;
      busy)
        tnx_permission_result mic busy "Termux:API is already recording; the existing recording was left untouched."; return 2 ;;
      *)
        tnx_permission_result mic denied "Termux:API microphone permission was not confirmed. Allow Microphone for Termux:API, then run tx mic again."; return 1 ;;
    esac
  fi
  if tnx_request_host_mic_permission; then
    tnx_permission_result mic prompted "Termux:API is not available; the built-in OpenSL microphone path was opened briefly. Allow Termux's Android microphone prompt if shown, then use the desktop mic normally."; return 0
  fi
  tnx_permission_result mic unavailable "No Termux:API recorder or active OpenSL microphone source was found. Desktop audio and GUI still work; install the Termux:API companion plus pkg package for API recording, or start the desktop and allow Termux microphone access when a guest app first captures."; return 1
}

tnx_cmd_cam() {
  [ "$#" -eq 0 ] || { tnx_fail "Usage: tx cam"; return 2; }
  tnx_permissions_load_phase_helpers
  if ! tnx_termux_api_app_installed || ! tnx_has_cmd termux-camera-photo; then
    tnx_permission_result cam unavailable "Termux:API camera is unavailable. Install the Termux:API companion and pkg package to request camera permission; without it, use Android Camera and open the photo from the guest file manager. The Ternux desktop remains usable."; return 1
  fi
  tnx_request_camera_permission 1 >&2
  case "${_TNX_CAMERA_PERMISSION_RESULT:-unavailable}" in
    granted)
      tnx_permission_result cam granted "Termux:API camera permission is available. One temporary rear-camera photo was deleted."; return 0 ;;
    interactive_required)
      tnx_permission_result cam interactive_required "Run tx cam in an interactive Termux terminal to handle Android's camera permission prompt."; return 2 ;;
    *)
      tnx_permission_result cam denied "Termux:API camera permission was not confirmed. Allow Camera for Termux:API, then run tx cam again."; return 1 ;;
  esac
}
