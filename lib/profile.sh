# =============================================================================
#  ternux — device profile management (show / save / load / list / compare)
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah) — MIT License
#  https://github.com/soobujmiah/ternux
# =============================================================================

# shellcheck source=lib/core.sh
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"
# shellcheck source=lib/detect.sh
. "$(dirname "${BASH_SOURCE[0]}")/detect.sh"

# ---------------------------------------------------------------------------
# tnx_cmd_profile
# ---------------------------------------------------------------------------
tnx_cmd_profile() {
  local subcmd="${1:-show}"
  shift 2>/dev/null || true

  case "$subcmd" in
    show|--show)     _tnx_profile_show ;;
    save|--save)     _tnx_profile_save "${1:-default}" ;;
    load|--load)     _tnx_profile_load "${1:-default}" ;;
    list|--list)     _tnx_profile_list ;;
    compare|--compare) _tnx_profile_compare "${1:-default}" "${2:-current}" ;;
    --help|-h)       tnx_help_profile ;;
    *) tnx_fail "Usage: ternux profile [show|save|list|load|compare] [name]"; return 1 ;;
  esac
}

# Profile names become filenames below. Keep every operation inside the
# profiles directory and reject separators, dot-paths and control characters.
_tnx_profile_path() {
  local name="$1"
  if [[ ! "$name" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$ ]]; then
    tnx_fail "Invalid profile name. Use 1-64 letters, numbers, dots, underscores or hyphens; start with a letter or number."
    return 2
  fi
  _TNX_PROFILE_PATH="$TERNUX_STATE_DIR/profiles/$name"
}

_tnx_profile_show() {
  # Gather all device info
  local android_ver arch model manuf ram storage termux_ver gpu vulkan backend phantom

  android_ver="$(tnx_detect_android_version)"
  arch="$(tnx_detect_arch)"
  model="$(tnx_detect_model)"
  manuf="$(tnx_detect_manufacturer)"
  ram="$(tnx_detect_ram_gb)"
  storage="$(tnx_detect_storage_gb)"
  termux_ver="$(tnx_detect_termux_version)"
  gpu="$(tnx_detect_gpu)"
  vulkan="$(tnx_detect_vulkan)"
  backend="$(tnx_detect_backend)"
  phantom="$(tnx_detect_phantom_killer)"

  # Export to env for other commands
  export TNX_ANDROID="$android_ver" TNX_ARCH="$arch" TNX_MODEL="$model" TNX_GPU="$gpu" TNX_BACKEND="$backend"

  [ "${TERNUX_JSON:-0}" = "1" ] && {
    tnx_json_object "profile" "complete" \
      "android_version" "$android_ver" "architecture" "$arch" \
      "model" "$model" "manufacturer" "$manuf" \
      "ram_gb" "$ram" "storage_gb" "$storage" \
      "termux_version" "$termux_ver" \
      "gpu" "$gpu" "vulkan" "$vulkan" "backend" "$backend" \
      "phantom_process_killer" "$phantom"
    return 0
  }

  tnx_header "Device Profile"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Android:" "$android_ver"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Architecture:" "$arch"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s %s\n" "Model:" "$manuf" "$model"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s GB\n" "RAM:" "$ram"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s GB free\n" "Storage:" "$storage"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Termux:" "$termux_ver"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "GPU:" "$gpu"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Vulkan:" "$vulkan"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Backend:" "$backend"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Phantom:" "$phantom"
  echo ""
}

_tnx_profile_save() {
  local name="${1:-default}" f
  _tnx_profile_path "$name" || return $?
  f="$_TNX_PROFILE_PATH"
  mkdir -p "$(dirname "$f")"

  cat > "$f" << PROFILEEOF
# ternux profile: ${name}
# Saved: $(__tnx_ts)
android_version=$(tnx_detect_android_version)
architecture=$(tnx_detect_arch)
model=$(tnx_detect_model)
manufacturer=$(tnx_detect_manufacturer)
ram_gb=$(tnx_detect_ram_gb)
storage_gb=$(tnx_detect_storage_gb)
termux_version=$(tnx_detect_termux_version)
gpu=$(tnx_detect_gpu)
vulkan=$(tnx_detect_vulkan)
backend=$(tnx_detect_backend)
phantom_killer=$(tnx_detect_phantom_killer)
PROFILEEOF

  [ "${TERNUX_JSON:-0}" = "1" ] && { tnx_json_object "profile" "saved" "name" "$name"; return 0; }
  tnx_ok "Profile saved: $name"
}

_tnx_profile_load() {
  local name="${1:-default}" f
  _tnx_profile_path "$name" || return $?
  f="$_TNX_PROFILE_PATH"
  [ ! -f "$f" ] && { tnx_fail "Profile not found: $name"; _tnx_profile_list; return 1; }

  [ "${TERNUX_JSON:-0}" = "1" ] && {
    local content
    content="$(cat "$f" | head -c 2000)"
    tnx_json_object "profile" "loaded" "name" "$name" "content" "$content"
    return 0
  }

  tnx_header "Profile: $name"
  cat "$f" | while IFS='=' read -r key val; do
    case "$key" in \#*) continue ;; esac
    printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "$key:" "$val"
  done
  echo ""
}

_tnx_profile_list() {
  local dir="$TERNUX_STATE_DIR/profiles"
  mkdir -p "$dir"

  [ "${TERNUX_JSON:-0}" = "1" ] && {
    local profiles
    profiles="$(ls -1 "$dir" 2>/dev/null | tr '\n' ',' | sed 's/,$//')"
    tnx_json_object "profile" "list" "profiles" "$profiles" "count" "$(ls -1 "$dir" 2>/dev/null | wc -l)"
    return 0
  }

  tnx_header "Saved Profiles"
  if [ -z "$(ls -A "$dir" 2>/dev/null)" ]; then
    tnx_info "No saved profiles."
  else
    for p in "$dir"/*; do
      local name date gpu backend
      name="$(basename "$p")"
      date="$(grep '^# Saved:' "$p" 2>/dev/null | sed 's/^# Saved: //')"
      gpu="$(grep '^gpu=' "$p" 2>/dev/null | cut -d= -f2)"
      backend="$(grep '^backend=' "$p" 2>/dev/null | cut -d= -f2)"
      printf "  ${TNX_CW}%-16s${TNX_C0} ${TNX_CD}%s  %s  %s${TNX_C0}\n" "$name" "$gpu" "$backend" "${date:--}"
    done
  fi
  echo ""
}

_tnx_profile_compare() {
  local name1="${1:-default}" name2="${2:-current}" f1
  _tnx_profile_path "$name1" || return $?
  f1="$_TNX_PROFILE_PATH"
  [ ! -f "$f1" ] && { tnx_fail "Profile not found: $name1"; return 1; }

  [ "${TERNUX_JSON:-0}" = "1" ] && { tnx_json_object "profile" "compared" "profile1" "$name1" "profile2" "$name2"; return 0; }

  tnx_header "Profile Comparison: $name1 vs $name2"
  printf "  ${TNX_CW}%-18s %-20s %-20s${TNX_C0}\n" "Property" "$name1" "current"
  printf -- "  %s\n" "---------------------------------------------"

  local keys="android_version architecture model gpu vulkan backend ram_gb storage_gb"
  for key in $keys; do
    local val1 val2
    val1="$(grep "^${key}=" "$f1" 2>/dev/null | cut -d= -f2)"
    case "$key" in
      android_version) val2="$(tnx_detect_android_version)" ;;
      architecture)    val2="$(tnx_detect_arch)" ;;
      model)           val2="$(tnx_detect_model)" ;;
      gpu)             val2="$(tnx_detect_gpu)" ;;
      vulkan)          val2="$(tnx_detect_vulkan)" ;;
      backend)         val2="$(tnx_detect_backend)" ;;
      ram_gb)          val2="$(tnx_detect_ram_gb)" ;;
      storage_gb)      val2="$(tnx_detect_storage_gb)" ;;
    esac
    local marker=" "
    [ "$val1" != "$val2" ] && marker="${TNX_CY}≠${TNX_C0}"
    printf "  ${TNX_CW}%-18s${TNX_C0} %-20s %-20s %s\n" "$key" "${val1:-?}" "${val2:-?}" "$marker"
  done
  echo ""
}