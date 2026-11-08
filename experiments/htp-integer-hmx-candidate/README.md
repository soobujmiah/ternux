# SM8735 integer-HMX validation candidate

**Status: unqualified research candidate.** This patch is not part of Ternux's
installed HTP extension and is not a release feature. It exists to test whether
integer-HMX kernels can fix the known no-FP16 HMX correctness gap on the
Qualcomm SM8735 / Hexagon V73 device while improving Q4_0 inference throughput.

## Source provenance

- Base: official `ggml-org/llama.cpp` commit
  `af50f2f248b475d9760f8e67503d01c0f194f5f4` (the Ternux HTP build pin).
- Candidate implementation: [`karusrus/llama.cpp` branch
  `hexagon-int-hmx`](https://github.com/karusrus/llama.cpp/tree/hexagon-int-hmx),
  based on commit `86a24a182bd3c6c877aaf3734d99f9a1820f8cbd` and ending at
  `ea11b8fd41da2c3716b7a83d006a7d4261cd72e7`.
- The four candidate commits add FP16-HMX capability probing, integer-HMX
  Q4_0 matmul and attention paths, and an HVX Gated Delta Net path. The source
  branch is MIT licensed; the exact matching license text is preserved in
  [`LLAMA-CPP-MIT-LICENSE`](LLAMA-CPP-MIT-LICENSE).
- Candidate commits: `76074e0cd08da129be7610c67b76b6a2b512a06b`,
  `4aa1a98d2c0f6c7a7a9630c1e41c8bdf8310191a`,
  `0f69bd61da08` and `ea11b8fd41da2c3716b7a83d006a7d4261cd72e7`.
- Ternux rebases those changes onto the pinned official source. The single
  merge conflict in `ggml-hexagon.cpp` was resolved while retaining the pinned
  source's memory-buffer parsing and tiled dimensions, then gating HMX kernels
  on the runtime FP16 probe or Q4_0 weights.
- Patch SHA-256:
  `ecf351cbf43889090998400bbe0fa65a2efd210da81997463fd02f85c682f512`.

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
