# =============================================================================
#  ternux — GPU benchmarking (glmark2, vkmark)
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah) — MIT License
#  https://github.com/soobujmiah/ternux
# =============================================================================

# shellcheck source=lib/core.sh
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"
# shellcheck source=lib/detect.sh
. "$(dirname "${BASH_SOURCE[0]}")/detect.sh"

# ---------------------------------------------------------------------------
# tnx_cmd_benchmark
# ---------------------------------------------------------------------------
tnx_cmd_benchmark() {
  tnx_step "Running benchmarks..."
  tnx_require_termux

  local glmark2_score="" vkmark_score="" renderer="" backend
  local -a results=()
  local rc=0

  backend="$(tnx_canonical_backend "$(tnx_state_get "backend" || tnx_detect_backend)")"

  if [ "${TERNUX_JSON:-0}" != "1" ]; then
    tnx_header "Configuration"
    printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "GPU:" "$(tnx_detect_gpu)"
    printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Backend:" "$backend"
    printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Vulkan:" "$(tnx_detect_vulkan)"
    echo ""
    tnx_info "Benchmarks run inside the Debian container (desktop must be active)."
    echo ""
  fi

  # --- glmark2 ---
  tnx_header "1/3  glmark2 (OpenGL 2.0)"
  _tnx_bench_run_glmark2
  glmark2_score="$_TNX_BENCH_GLMARK2"
  [ -n "$glmark2_score" ] && [ "$glmark2_score" != "unknown" ] && results+=("glmark2:${glmark2_score}")

  # --- vkmark ---
  tnx_header "2/3  vkmark (Vulkan)"
  _tnx_bench_run_vkmark
  vkmark_score="$_TNX_BENCH_VKMARK"
  [ -n "$vkmark_score" ] && [ "$vkmark_score" != "unknown" ] && results+=("vkmark:${vkmark_score}")

  # --- Renderer verification ---
  tnx_header "3/3  Renderer verification"
  renderer="$(tnx_detect_renderer)"
  if [ -n "$renderer" ] && [ "$renderer" != "unknown" ]; then
    tnx_ok "Current renderer: $renderer"
    results+=("renderer:${renderer}")
    case "$renderer" in
      *llvmpipe*)
        results+=("status:software_rendering")
        tnx_warn "Software rendering detected"
        ;;
      *zink*Turnip*|*zink*MESA_TURNIP*)
        results+=("status:zink_turnip_route_detected")
        tnx_ok "Zink/Turnip GPU route detected"
        ;;
      *zink*)
        results+=("status:zink_renderer_detected")
        tnx_warn "Zink detected; verify the Vulkan device/driver before claiming acceleration"
        ;;
      *virgl*|*virpipe*)
        results+=("status:virgl_route_detected")
        tnx_warn "VirGL/virpipe detected; host acceleration and performance are device-dependent"
        ;;
    esac
  fi

  [ "${TERNUX_JSON:-0}" != "1" ] && echo ""
  _tnx_bench_save_results "$glmark2_score" "$vkmark_score" "$renderer"

  # JSON output
  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    local results_str=""
    for r in "${results[@]}"; do
      [ -n "$results_str" ] && results_str+=","
      results_str+="$r"
    done
    tnx_json_object "benchmark" "complete" \
      "glmark2_score" "${glmark2_score:-unknown}" \
      "vkmark_score" "${vkmark_score:-unknown}" \
      "renderer" "${renderer:-unknown}" \
      "gpu" "$(tnx_detect_gpu)" \
      "backend" "$backend" \
      "vulkan" "$(tnx_detect_vulkan)" \
      "results" "$results_str"
    return 0
  fi

  tnx_header "Benchmark Summary"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "glmark2:" "${glmark2_score:-N/A}"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "vkmark:" "${vkmark_score:-N/A}"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Renderer:" "${renderer:-unknown}"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "GPU:" "$(tnx_detect_gpu)"
  echo ""
}

# --- Internal helpers ---
_TNX_BENCH_GLMARK2=""
_TNX_BENCH_VKMARK=""

_tnx_bench_run_glmark2() {
  _TNX_BENCH_GLMARK2=""
  tnx_has_cmd proot-distro || return
  local out
  out="$(proot-distro login debian --shared-tmp --user "${TERNUX_USER:-ternux}" -- bash -c '
    if command -v glmark2 >/dev/null 2>&1; then
      timeout 60 glmark2 --fullscreen --annotate 2>/dev/null || timeout 60 glmark2 2>/dev/null
    elif command -v glmark2-es2 >/dev/null 2>&1; then
      timeout 60 glmark2-es2 2>/dev/null
    else
      echo "NOT_INSTALLED"
    fi
  ' 2>/dev/null)" || true

  if echo "$out" | grep -q "NOT_INSTALLED"; then
    tnx_warn "glmark2 not installed. Install: sudo apt install glmark2 -y"
    return
  fi
  _TNX_BENCH_GLMARK2="$(echo "$out" | grep -oP 'glmark2 Score: \K[0-9]+' | head -1 || echo "unknown")"
  [ "$_TNX_BENCH_GLMARK2" = "unknown" ] && tnx_info "glmark2 ran but score not parsed (display may not be active)" || tnx_ok "glmark2 Score: $_TNX_BENCH_GLMARK2"
}

_tnx_bench_run_vkmark() {
  _TNX_BENCH_VKMARK=""
  tnx_has_cmd proot-distro || return
  local out
  out="$(proot-distro login debian --shared-tmp --user "${TERNUX_USER:-ternux}" -- bash -c '
    if command -v vkmark >/dev/null 2>&1; then
      timeout 60 vkmark 2>/dev/null
    elif [ -f /usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so ]; then
      echo "DRIVER_PRESENT"
    else
      echo "NO_VULKAN"
    fi
  ' 2>/dev/null)" || true

  case "$out" in
    *NO_VULKAN*) tnx_warn "No Vulkan support detected" ;;
    *DRIVER_PRESENT*) tnx_info "Vulkan driver present, vkmark not installed (sudo apt install vkmark)" ;;
    *)
      _TNX_BENCH_VKMARK="$(echo "$out" | grep -oP 'Score: \K[0-9.]+' | head -1 || echo "unknown")"
      [ "$_TNX_BENCH_VKMARK" = "unknown" ] && tnx_info "vkmark ran but score not parsed" || tnx_ok "vkmark: $_TNX_BENCH_VKMARK"
      ;;
  esac
}

_tnx_bench_save_results() {
  local gl="$1" vk="$2" renderer="$3"
  mkdir -p "$TERNUX_STATE_DIR"
  echo "$(__tnx_ts) glmark2=${gl:-unknown} vkmark=${vk:-unknown} renderer=${renderer:-unknown}" >> "$TERNUX_STATE_DIR/benchmarks"
}