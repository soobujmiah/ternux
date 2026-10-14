# Handoff: SD1.5 QNN performance

**Status:** open; profiling is complete, optimization is not qualified.  
**Last updated:** 2026-10-14  
**Canonical status:** [`docs/ACCELERATOR-RELEASE-PLAN.md`](../docs/ACCELERATOR-RELEASE-PLAN.md)

## Goal

Explain and reduce the Ternux SD1.5 image-generation time on Redmi Turbo 4 Pro
(SM8735). The owner expects roughly 3–5 seconds for a 512×512 image; Local Dream
has a separate 5.7-second, 20-step observation on the same phone. Treat these as
targets/references, not a controlled A/B result or a guarantee for this model.
The owner deferred making this runner a Ternux extension.

## Evidence

- Existing Ternux run: 25/25 images, 20 steps, 512×512; median 29.758 s total
  and 15.962 s for 20 HTP UNet steps.
- Three instrumented follow-up images took 30.797–31.122 s.
- Representative instrumented run (30.797 s): CPU CLIP 3.482 s; stream, hash,
  and seal the 880,827,736-byte UNet member into memfd 7.275 s; 40 serial HTP
  UNet requests 17.015 s; two helper startups 1.209 s; decoder 0.791 s; PNG
  write 0.044 s. Decoder-member acquisition was 0.477 s.
- The run logs QNN HTP/DSP graph execution for UNet and VAE. This establishes
  HTP execution in this route; it does not establish why Local Dream is faster.

## Next work

1. Preserve the current archive and capture repeatable stage timings under the
   same resolution/step count; distinguish model acquisition, helper/context
   startup, CLIP, each HTP call, decoder, and output.
2. Inspect whether the archive can be opened once and the helper/context reused
   safely across images, without writing or changing the original model.
3. Profile the two serial CFG requests per step and test batching or graph-level
   alternatives only when compatible with the fixed QNN context.
4. Compare runtime/provider and model-graph choices with available Local Dream
   evidence. Do not attribute the gap without a measured comparison.
5. Recheck output correctness and thermal behavior after any change.

## Evidence locations

- Runner: `experiments/qnn-native/sd15_qnn_image.py`
- Baseline and full profile: [`experiments/qnn-native/README.md`](../experiments/qnn-native/README.md)
- Device images: `/sdcard/Llms/ternux-profile-20261014-01.png` through `-03.png`
- Detailed timing log: `/home/sbj/npu-probe-2026-10-13/sd15-profile-20261014-precise.log`
- Original archive SHA-256: `f479f3221fb90d31de1e695577f5aec9a5afb5fb7e076cfac40f00e039b22977`

Keep this work separate from llama.cpp HTP text-model qualification and from a
future extension-packaging task.
