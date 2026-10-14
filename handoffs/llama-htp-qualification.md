# Handoff: llama.cpp Hexagon HTP qualification

**Status:** open; experimental launcher keeps flash attention disabled.
**Last updated:** 2026-10-14
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
