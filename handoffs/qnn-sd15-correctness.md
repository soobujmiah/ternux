# Handoff: SD1.5 QNN correctness and image review

**Status:** open; repeatable image generation is not independent numerical proof.
**Last updated:** 2026-10-14
**Canonical status:** [`docs/ACCELERATOR-RELEASE-PLAN.md`](../docs/ACCELERATOR-RELEASE-PLAN.md)

## Goal

Establish whether the standalone SD1.5 pipeline's CLIP, UNet, and VAE tensors
match independent expected values, then complete full-resolution review of the
25-image soak. Keep this QNN image route separate from llama.cpp HTP text tests.

## Evidence

- Corrected DPM++ sample-space handling; a fixed-seed 20-step 512×512 result
  repeated with the same SHA-256 (`1a13957f…6764fc3`). This proves repeatability,
  not correctness against an independent implementation.
- The 25-image soak completed 25/25. Image 01 received full-resolution review
  and showed a small cyan/black spot on water. Images 02–25 were only screened
  in contact sheets; no similar obvious defect was seen at that scale.
- The three later performance-profile outputs are additional samples, not a
  replacement for stage-tensor checks.
- The image-runner reports `image_oracle: visual_review_and_seed_repeat_only`.

## Next work

1. Reproduce the exact fixed-seed prompt, scheduler, model archive, and stage
   inputs in an independent trusted implementation where compatible artifacts
   are available.
2. Compare tokenizer IDs, CLIP hidden output, each denoising-stage latent/
   epsilon, and decoded tensor before PNG conversion. Record tolerances and
   hashes; distinguish expected quantization error from a mismatch.
3. Inspect images 02–25 at full resolution; preserve the existing outputs and
   note image index, defect, and review disposition.
4. Re-run same-seed output and relevant tensor comparisons after any runner or
   model-path change.

## Evidence locations

- Runner and available probes: `experiments/qnn-native/`
- Baseline outputs/report: `/sdcard/sdgen/` and
  `/home/sbj/npu-probe-2026-10-13/sd15-npu-soak-20261014-182316/`
- Later profile outputs: `/sdcard/Llms/ternux-profile-20261014-01.png` through
  `-03.png`
- Original archive SHA-256:
  `f479f3221fb90d31de1e695577f5aec9a5afb5fb7e076cfac40f00e039b22977`

Do not claim independent correctness from HTP backend logs, coherent visuals, or
same-seed hashes alone.
