# Handoff: llama.cpp Hexagon HTP qualification

**Status:** open; experimental launcher keeps flash attention disabled.
**Last updated:** 2026-11-07
**Canonical status:** [`docs/ACCELERATOR-RELEASE-PLAN.md`](../docs/ACCELERATOR-RELEASE-PLAN.md)

## Goal

Resolve the SM8735 HTP numerical failures and incomplete operator coverage
without weakening the passing HVX-only/flash-attention-off baseline. This is
llama.cpp GGUF text inference, separate from the standalone QNN SD1.5 route.

## Evidence

- Exact package run `38560288558`: isolated install, `2 + 2 = 4`, 31/31 layers
  on HTP0, bounded SIGINT, and clean `closeSession [0, 0]`.
- HVX-only `MUL_MAT` with `GGML_HEXAGON_MM_SELECT=1`: 1,389/1,389 passed.
- Default HMX-selected `MUL_MAT`: 529 numerical failures with infinite error.
- Explicit HVX matmul + HVX flash attention: 5,332 unique `FLASH_ATTN_EXT`
  cases; 2,593 passed, 2,732 unsupported, 7 finite numerical-error failures.
  A filtered rerun reproduced all seven. Flash attention remains disabled.
- Broad HVX-selected operator suite: 3,520 pass lines, 45 numerical failures,
  4,874 unsupported cases, then abort `dspqueue_read failed: 0x0000002e`
  (exit -6). It is incomplete; cause unknown.
- Short same-prompt Qwen2.5 1.5B Q4_0 generation probe (2026-11-07): 19.6 tok/s
  on HTP with default power mode and 17.6 tok/s on Vulkan; HTP Q4_K_M was
  15.9 tok/s. One run per setting; no sustained speed advantage established.
- Matched Qwen2.5 0.5B Q4_0 CPU/Vulkan/HTP comparison (2026-11-07): same prompt,
  64-token output cap, context 2048, batch/ubatch 128, seed 42, temperature 0,
  four threads; three interleaved runs per backend. Generation rates: CPU
  7.2/8.0/8.1 (median 8.0), Vulkan 24.1/24.8/26.3 (median 24.8), HTP
  46.9/46.2/43.9 tok/s (median 46.2). All three HTP broker sessions closed
  cleanly. This is short single-device throughput evidence only; quality, energy,
  thermal stability, sustained use, and HTP correctness remain unqualified.
  Speculative decoding with a Vulkan Qwen2.5 0.5B draft reduced HTP's 19.5 tok/s
  baseline to 9.1/7.1 tok/s for draft windows 2/4.
- Official upstream llama.cpp b12177 Snapdragon Linux ARM64 build (commit
  `6c01da6`, SHA-256
  `b3d2503821a6688ec5c500d43b7e57d96fad893a206bbefe208b07ee647d85e7`) failed
  to start its HTP session (`0x8000040e`) through the current Ternux broker
  before inference. Broker cleanup still returned `closeSession [0, 0]`; no
  performance result. The installed b11582 extension was not changed.

## Next work

1. Keep the launcher on the verified HVX-only matmul / flash-attention-off
   settings while failures remain.
2. Minimize and isolate the seven flash-attention cases and HMX matmul failures;
   check the SM8735 HMX FP16 capability separately before attributing a cause.
3. Reproduce the broad-suite abort with bounded operator groups, preserving
   broker cleanup evidence and distinguishing unsupported cases from failures.
4. Add targeted operator correctness and failure/restart checks; do not infer
   general HTP support from known-answer or one passing operator.
5. Keep package licensing, clean-device runtime install, fallback/restart, and
   sustained use as separate release gates.

## Evidence locations

- Current status and device commands:
  [`docs/ACCELERATOR-RELEASE-PLAN.md`](../docs/ACCELERATOR-RELEASE-PLAN.md)
- Experimental package usage and detailed operator evidence:
  [`guides/llama-htp-experimental.md`](../guides/llama-htp-experimental.md)
- Raw operator logs:
  `/home/sbj/npu-probe-2026-10-13/htp-op-qualification-38567329752/`
- Failed selected-FA suite: `flash-attn-hvx-select1-180s.log`; targeted
  reproduction: `flash-attn-hvx-select1-targeted-all.log`.

Never label a bounded or aborted suite as a pass. Keep the experimental feature
out of the stable support matrix until the roadmap gates are met.
