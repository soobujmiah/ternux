#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

env TERNUX_STATE_DIR="$TMP/state" HOME="$TMP/home" bash -c '
  . "$1/lib/permissions.sh"
  tnx_termux_api_app_installed(){ return 0; }
  tnx_has_cmd(){ [[ "$1" == termux-microphone-record || "$1" == termux-camera-photo ]]; }
  tnx_request_microphone_permission(){ _TNX_MIC_PERMISSION_RESULT=granted; }
  tnx_request_camera_permission(){ _TNX_CAMERA_PERMISSION_RESULT=granted; }
  TERNUX_JSON=1
  mic="$(tnx_cmd_mic)"
  cam="$(tnx_cmd_cam)"
  grep -Fq "\"command\":\"mic\"" <<<"$mic"
  grep -Fq "\"status\":\"granted\"" <<<"$mic"
  grep -Fq "\"command\":\"cam\"" <<<"$cam"
  grep -Fq "\"status\":\"granted\"" <<<"$cam"
' _ "$ROOT"

env TERNUX_STATE_DIR="$TMP/state-no-api" HOME="$TMP/home-no-api" bash -c '
  . "$1/lib/permissions.sh"
  tnx_termux_api_app_installed(){ return 1; }
  tnx_request_host_mic_permission(){ return 1; }
  tnx_request_microphone_permission(){ _TNX_MIC_PERMISSION_RESULT=unavailable; }
  tnx_request_camera_permission(){ _TNX_CAMERA_PERMISSION_RESULT=unavailable; }
  tnx_has_cmd(){ return 1; }
  TERNUX_JSON=1
  mic="$(tnx_cmd_mic)" && exit 1
  cam="$(tnx_cmd_cam)" && exit 1
  grep -Fq "\"status\":\"unavailable\"" <<<"$mic"
  grep -Fq "\"status\":\"unavailable\"" <<<"$cam"
  grep -Fiq "desktop" <<<"$mic"
  grep -Fq "Android Camera" <<<"$cam"
' _ "$ROOT"

printf 'permission CLI checks passed\n'
