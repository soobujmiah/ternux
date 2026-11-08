# SM8735 integer-HMX validation candidate

**Status: unqualified research candidate.** This patch is not part of Ternux's
installed HTP extension and is not a release feature. It exists to test whether
integer-HMX kernels can fix the known no-FP16 HMX correctness gap on the
Qualcomm SM8735 / Hexagon V73 device while improving Q4_0 inference throughput.

## Source provenance

- Upstream base: official ggml-org/llama.cpp commit
  5851a8e505f4d5fbb183f2847698eb6155d176b7 (November 4, 2026).
- Candidate implementation: karusrus/llama.cpp PR #29740, exact commit
  08c83734f9c5c3b497e98b96f1a380f5a6084468, with the base commit above as
  its parent. The candidate is MIT licensed; this repository preserves the
  exact license text in LLAMA-CPP-MIT-LICENSE.
- This revision includes later Q4_0 row-padding and dynamically allocated HMX
  scratch fixes, and gates FP16-HMX-specific paths on detected capability. The
  PR remains unmerged, so Ternux builds it only as an isolated, disposable
  research candidate. The workflow checks out this exact source commit; it no
  longer reapplies an older patch over the production llama.cpp pin.
- Upstream SM7750 results and the separate SM8735 candidate measurements are
  device-specific evidence, not general support claims. The SM8735 candidate
  still has a failing FLASH_ATTN_EXT path and is not release-qualified.

## Candidate artifact smoke commands

After installing the artifact's Debian runtime dependencies, test only the
specific operator suites needed for this candidate:

```bash
bin/htp-backend-ops -o MUL_MAT
bin/htp-backend-ops -o FLASH_ATTN_EXT
GGML_HEXAGON_MM_SELECT=1 bin/htp-backend-ops -o MUL_MAT  # HVX control
bin/htp-run -m /sdcard/Llms/qwen2.5-0.5b-instruct-q4_0.gguf \
  -p 'What is 2 + 2? Reply with only the number.' -n 8
```

`htp-run` defaults this candidate package to `GGML_HEXAGON_MM_SELECT=2`; set it
to `1` for the current HVX-only control. It leaves flash attention off during
model inference. `htp-backend-ops` exercises the candidate operator path,
including integer-HMX flash-attention cases. These are manual test commands,
not a claim that the current device has passed them.

## Qualification required

The candidate build workflow produces a disposable artifact and runs no device
inference by itself. Before considering promotion, verify on the exact SM8735:

1. HMX FP16 capability detection agrees with Qualcomm's runtime report.
2. `MUL_MAT` Q4_0 known-answer and the full supported operator suite pass; other
   quant types remain on HVX when HMX lacks FP16.
3. Integer-HMX `FLASH_ATTN_EXT` supported cases pass and unsupported cases fall
   back cleanly; compare logits/PPL and deterministic generated tokens to CPU.
4. Gated Delta Net prefill matches CPU for supported shapes and falls back for
   unsupported shapes.
5. Run cold starts, cancellation/restart, and a bounded sustained workload;
   record battery/thermal changes and compare throughput with the current HVX
   launcher and Vulkan using the same model and prompt.

The current Q4_0 model already on the device can be used for initial checks. Do
not change the production HTP default or publish this candidate until the device
evidence and release gates support it.
