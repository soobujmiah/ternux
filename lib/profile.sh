# =============================================================================
#  ternux — profile management library
#  Save, load, and compare device profiles for reproducibility.
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah) — MIT License
#  https://github.com/soobujmiah/ternux
# =============================================================================

# shellcheck source=lib/core.sh
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"
# shellcheck source=lib/detect.sh
. "$(dirname "${BASH_SOURCE[0]}")/detect.sh"

# ---------------------------------------------------------------------------
# Profile management
# ---------------------------------------------------------------------------

tnx_profile_show() {
  tnx_profile
}

tnx_profile_save() {
  local name="${1:-default}"
  local profile_file="$TERNUX_STATE_DIR/profiles/${name}"

  mkdir -p "$TERNUX_STATE_DIR/profiles"

  # Capture current device profile
  local android_ver arch model manufacturer ram storage termux_ver gpu vulkan backend phantom
  android_ver="$(tnx_detect_android_version)"
  arch="$(tnx_detect_arch)"
  model="$(tnx_detect_model)"
  manufacturer="$(tnx_detect_manufacturer)"
  ram="$(tnx_detect_ram_gb)"
  storage="$(tnx_detect_storage_gb)"
  termux_ver="$(tnx_detect_termux_version)"
  gpu="$(tnx_detect_gpu)"
  vulkan="$(tnx_detect_vulkan)"
  backend="$(tnx_detect_backend)"
  phantom="$(tnx_detect_phantom_killer)"

  # Write profile
  cat > "$profile_file" <<EOF
# ternux profile: ${name}
# Saved: $(__tnx_ts)
android_version=${android_ver}
architecture=${arch}
model=${model}
manufacturer=${manufacturer}
ram_gb=${ram}
storage_gb=${storage}
termux_version=${termux_ver}
gpu=${gpu}
vulkan=${vulkan}
backend=${backend}
phantom_killer=${phantom}
EOF

  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    tnx_json_object "profile" "saved" "name" "$name" "file" "$profile_file"
  else
    tnx_ok "Profile saved: ${name}"
    tnx_info "File: ${profile_file}"
  fi
}

tnx_profile_load() {
  local name="${1:-default}"
  local profile_file="$TERNUX_STATE_DIR/profiles/${name}"

  if [ ! -f "$profile_file" ]; then
    tnx_fail "Profile not found: ${name}"
    tnx_info "Available profiles:"
    tnx_profile_list
    return 1
  fi

  tnx_info "Loading profile: ${name}"

  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    local content
    content="$(cat "$profile_file" | head -c 2000)"
    content="${content//\\/\\\\}"
    content="${content//\"/\\\"}"
    content="${content//$'\n'/\\n}"
    tnx_json_object "profile" "loaded" "name" "$name" "content" "$content"
  else
    cat "$profile_file" | while IFS='=' read -r key val; do
      case "$key" in
        \#*) continue ;;
        android_version|architecture|model|gpu|backend|vulkan)
          printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "${key}:" "$val"
          ;;
      esac
    done
  fi
  echo ""
}

tnx_profile_list() {
  local profile_dir="$TERNUX_STATE_DIR/profiles"
  mkdir -p "$profile_dir"

  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    local profiles
    profiles="$(ls -1 "$profile_dir" 2>/dev/null | tr '\n' ',' | sed 's/,$//')"
    tnx_json_object "profile" "list" "profiles" "$profiles" "count" "$(ls -1 "$profile_dir" 2>/dev/null | wc -l)"
    return 0
  fi

  tnx_header "Saved Profiles"
  if [ -z "$(ls -A "$profile_dir" 2>/dev/null)" ]; then
    tnx_info "No saved profiles."
  else
    for p in "$profile_dir"/*; do
      local name
      name="$(basename "$p")"
      local date
      date="$(grep '^# Saved:' "$p" 2>/dev/null | sed 's/^# Saved: //')"
      local backend gpu
      backend="$(grep '^backend=' "$p" 2>/dev/null | cut -d= -f2)"
      gpu="$(grep '^gpu=' "$p" 2>/dev/null | cut -d= -f2)"
      printf "  ${TNX_CW}%-16s${TNX_C0} ${TNX_CD}%s  %s  %s${TNX_C0}\n" "$name" "$gpu" "$backend" "${date:--}"
    done
  fi
  echo ""
}

tnx_profile_compare() {
  local name1="${1:-default}"
  local name2="${2:-current}"

  local file1="$TERNUX_STATE_DIR/profiles/${name1}"

  if [ ! -f "$file1" ]; then
    tnx_fail "Profile not found: ${name1}"
    return 1
  fi

  # If name2 is "current", compare against live detection
  if [ "$name2" = "current" ]; then
    local live_profile
    live_profile="$(tnx_profile)"

    if [ "${TERNUX_JSON:-0}" = "1" ]; then
      tnx_json_object "profile" "compared" "profile1" "$name1" "profile2" "current"
    else
      tnx_header "Profile Comparison"
      printf "  ${TNX_CW}%-16s ${TNX_CW}%-20s ${TNX_CW}%-20s${TNX_C0}\n" "Key" "${name1}" "current"
      printf "  %s\n" "$(printf '%.0s─' $(seq 1 58))"

      local keys
      keys="android_version architecture model gpu vulkan backend ram_gb storage_gb phantom_killer"
      for key in $keys; do
        local val1 val2
        val1="$(grep "^${key}=" "$file1" 2>/dev/null | cut -d= -f2)"
        # For current, use live detection
        case "$key" in
          android_version) val2="$(tnx_detect_android_version)" ;;
          architecture)    val2="$(tnx_detect_arch)" ;;
          model)           val2="$(tnx_detect_model)" ;;
          gpu)             val2="$(tnx_detect_gpu)" ;;
          vulkan)          val2="$(tnx_detect_vulkan)" ;;
          backend)         val2="$(tnx_detect_backend)" ;;
          ram_gb)          val2="$(tnx_detect_ram_gb)" ;;
          storage_gb)      val2="$(tnx_detect_storage_gb)" ;;
          phantom_killer)  val2="$(tnx_detect_phantom_killer)" ;;
        esac

        local marker=" "
        [ "$val1" != "$val2" ] && marker="${TNX_CY}≠${TNX_C0}"

        printf "  ${TNX_CW}%-16s${TNX_C0} %-20s %-20s %s\n" "$key" "${val1:-?}" "${val2:-?}" "$marker"
      done
      echo ""
    fi
  else
    tnx_info "Comparing profiles: ${name1} vs ${name2} (TODO: two-file comparison)"
    tnx_profile_show
  fi
}