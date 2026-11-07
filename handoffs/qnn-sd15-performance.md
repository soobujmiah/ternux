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
- A bounded --count 2..8 mode now reuses each loaded helper context and streams
  the UNet/decoder members only once per invocation. Its host-side mocked tests
  pass. On 2026-11-07, a two-image/two-step phone batch matched separate
  single-image PNG hashes for seeds 20261014 and 20261015, loaded one context
  for each QNN member, and took 20.321 s total. A subsequent 20-step batch
  matched those seeds to images 01/02 from the earlier 25-image soak exactly:
  1a13957f5cb65132d98fc212756bdcf8d8b959d69feba84902a9314036764fc3 and
  d20bf183909928236e02c8a1f7fe869e5883eb7931e3f5fe5eb65c0f74ee5aec. It took 49.923 s; per-image
  UNet and decode/PNG were 14.815/0.850 s and 16.129/0.824 s. The older soak
  recorded 28.233 and 28.911 s separately (57.144 s combined). The difference
  is a non-interleaved cross-session observation, not a controlled speedup.
  Battery samples were 40.7–40.9°C; no NPU-specific sensor was identified.
  Hash matches show repeatability for those exact outputs, not independent
  tensor correctness. Batch mode still makes 40 serial HTP UNet requests per
  20-step image.

- A same-day interleaved 20-step sequence then measured seed 20261016 single at
  30.945 s, seeds 20261016/17 batch at 47.825 s, and seed 20261017 single at
  29.484 s. Batch hashes matched both single controls exactly:
  `d93d395a437f57c92b81827bfd08e1347d6926eaf1534cb990af0a8ef504a977` and
  `cee7951bcd73ca0f677be9f8e2feed4151c42ba931adfb2929532fb71449cde0`.
  Controls totaled 60.429 s, 20.9% longer than the batch in this one sequence.
  This is a short observation without randomized repeats or confidence bounds,
  not a performance guarantee; batch battery sample was 40.3°C.

## Next work

1. Repeat randomized/interleaved one-image controls and two-image batches at
   20 steps to estimate setup reuse with confidence bounds; distinguish CLIP,
   acquisition, context startup, HTP requests, VAE decode, and output.
2. Check numerical image quality against an independent stage oracle,
   preserving the source archive.
3. Profile the two serial CFG requests per step and test graph-level alternatives
   only when compatible with the fixed QNN context.
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
