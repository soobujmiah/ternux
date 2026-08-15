# =============================================================================
#  ternux — benchmarking library
#  Run glmark2, vkmark, and renderer verification.
#
#  Copyright (c) 2026 Sobuj Miah (@soobujmiah) — MIT License
#  https://github.com/soobujmiah/ternux
# =============================================================================

# shellcheck source=lib/core.sh
. "$(dirname "${BASH_SOURCE[0]}")/core.sh"
# shellcheck source=lib/detect.sh
. "$(dirname "${BASH_SOURCE[0]}")/detect.sh"

# ---------------------------------------------------------------------------
# Benchmark runner
# ---------------------------------------------------------------------------

tnx_benchmark_run() {
  tnx_step "Running benchmarks..."

  local glmark2_score="" vkmark_score="" renderer="" backend
  local -a bench_results=()
  local rc=0

  backend="$(tnx_state_get "backend" || tnx_detect_backend)"

  if [ "${TERNUX_JSON:-0}" != "1" ]; then
    tnx_header "Benchmark Configuration"
    printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "GPU:" "$(tnx_detect_gpu)"
    printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Backend:" "$backend"
    printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Vulkan:" "$(tnx_detect_vulkan)"
    echo ""
    tnx_info "Note: Benchmarks run inside the Debian container."
    tnx_info "The desktop must be running for GL/VK benchmarks."
    echo ""
  fi

  # --- glmark2 (OpenGL 2.0 benchmark) ---
  tnx_header "1/3  glmark2 (OpenGL 2.0)"
  if tnx_has_cmd proot-distro; then
    if proot-distro login debian --shared-tmp --user "${TERNUX_USER:-ternux}" -- bash -c '
      if command -v glmark2 >/dev/null 2>&1; then
        glmark2 --fullscreen --annotate 2>/dev/null || glmark2 2>/dev/null
      elif command -v glmark2-es2 >/dev/null 2>&1; then
        glmark2-es2 2>/dev/null
      else
        echo "NOT_INSTALLED"
      fi
    ' 2>/dev/null > /tmp/ternux-glmark2.out; then
      glmark2_score="$(grep -oP 'glmark2 Score: \K[0-9]+' /tmp/ternux-glmark2.out 2>/dev/null || echo "unknown")"
      if [ "$glmark2_score" != "unknown" ] && [ -n "$glmark2_score" ]; then
        tnx_ok "glmark2 Score: $glmark2_score"
        bench_results+=("glmark2:${glmark2_score}")
      else
        tnx_warn "glmark2 ran but score not detected"
        cat /tmp/ternux-glmark2.out | tail -5 | while IFS= read -r line; do printf "  ${TNX_CD}%s${TNX_C0}\n" "$line"; done
      fi
    else
      if grep -q "NOT_INSTALLED" /tmp/ternux-glmark2.out 2>/dev/null; then
        tnx_warn "glmark2 not installed in Debian container"
        tnx_info "Install: sudo apt install glmark2 -y"
      else
        # Check if display is available
        tnx_info "glmark2 needs a running X display. The desktop may not be active."
      fi
    fi
  else
    tnx_warn "PRoot Debian not available; cannot run GL benchmarks"
    rc=1
  fi
  rm -f /tmp/ternux-glmark2.out

  # --- vkmark (Vulkan benchmark) ---
  tnx_header "2/3  vkmark (Vulkan)"
  if tnx_has_cmd proot-distro; then
    if proot-distro login debian --shared-tmp --user "${TERNUX_USER:-ternux}" -- bash -c '
      if command -v vkmark >/dev/null 2>&1; then
        vkmark 2>/dev/null
      elif [ -f /usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so ]; then
        echo "VULKAN_DRIVER_PRESENT_NO_VKMARK"
      else
        echo "NO_VULKAN"
      fi
    ' 2>/dev/null > /tmp/ternux-vkmark.out; then
      if grep -q "VULKAN_DRIVER_PRESENT_NO_VKMARK" /tmp/ternux-vkmark.out; then
        tnx_info "Vulkan driver present but vkmark not installed"
        tnx_info "Install: sudo apt install vkmark -y"
        bench_results+=("vkmark:not_installed")
      elif grep -q "NO_VULKAN" /tmp/ternux-vkmark.out; then
        tnx_warn "No Vulkan support detected"
        bench_results+=("vkmark:no_vulkan")
      else
        vkmark_score="$(grep -oP 'Score: \K[0-9.]+' /tmp/ternux-vkmark.out 2>/dev/null || \
                        grep -oP 'average framerate: \K[0-9.]+' /tmp/ternux-vkmark.out 2>/dev/null || \
                        echo "unknown")"
        tnx_ok "vkmark Score: $vkmark_score"
        bench_results+=("vkmark:${vkmark_score}")
      fi
    else
      tnx_warn "vkmark failed to run (display may not be available)"
    fi
  fi
  rm -f /tmp/ternux-vkmark.out

  # --- Renderer Verification ---
  tnx_header "3/3  Renderer verification"
  renderer="$(tnx_detect_renderer)"
  if [ -n "$renderer" ] && [ "$renderer" != "unknown" ]; then
    tnx_ok "Current renderer: $renderer"
    bench_results+=("renderer:${renderer}")

    # Check for software rendering
    case "$renderer" in
      *llvmpipe*)
        tnx_warn "Software rendering detected (llvmpipe)"
        bench_results+=("warning:software_rendering")
        ;;
      *zink*)
        tnx_ok "Hardware-accelerated rendering via Zink"
        bench_results+=("status:hardware_accelerated")
        ;;
      *virgl*)
        tnx_ok "Hardware-backed rendering via VirGL"
        bench_results+=("status:hardware_accelerated_virgl")
        ;;
    esac
  else
    tnx_warn "Could not determine renderer"
  fi

  echo ""

  # Log benchmark results
  mkdir -p "$TERNUX_STATE_DIR"
  {
    echo "$(__tnx_ts) glmark2=${glmark2_score:-unknown} vkmark=${vkmark_score:-unknown} renderer=${renderer:-unknown}"
  } >> "$TERNUX_STATE_DIR/benchmarks"

  # Output
  if [ "${TERNUX_JSON:-0}" = "1" ]; then
    local bench_str=""
    for b in "${bench_results[@]}"; do
      [ -n "$bench_str" ] && bench_str+=","
      bench_str+="$b"
    done
    tnx_json_object "benchmark" "$([ $rc -eq 0 ] && echo "complete" || echo "partial")" \
      "glmark2_score" "${glmark2_score:-unknown}" \
      "vkmark_score" "${vkmark_score:-unknown}" \
      "renderer" "${renderer:-unknown}" \
      "gpu" "$(tnx_detect_gpu)" \
      "backend" "$backend" \
      "vulkan" "$(tnx_detect_vulkan)" \
      "results" "$bench_str"
    return 0
  fi

  tnx_header "Benchmark Summary"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "glmark2 score:" "${glmark2_score:-N/A}"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "vkmark score:" "${vkmark_score:-N/A}"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Renderer:" "${renderer:-unknown}"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "GPU:" "$(tnx_detect_gpu)"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Backend:" "$backend"
  printf "  ${TNX_CW}%-20s${TNX_C0} %s\n" "Vulkan:" "$(tnx_detect_vulkan)"
  echo ""
}