---
title: "Benchmarks and device evidence"
description: "A concise, measured snapshot of Ternux graphics and accelerator workloads, with explicit evidence boundaries."
lang: "en"
alt_url: "/bn/docs/BENCHMARKS.html"
evidence_through: "2026-11-07"
---

This page summarizes measured workloads and their limits on one configured
Redmi Turbo 4 Pro / SM8735 / Adreno 825 device. It is not a compatibility or
performance guarantee for other devices.

## Evidence classes

| Class | Meaning |
|---|---|
| **Measured** | A completed workload produced a numeric result. |
| **Observed** | A build, launch, or renderer/backend identification was recorded. |
| **Verified** | A bounded functional check returned its expected result. |
| **Untested** | No qualifying workload has been run. |

## Current results

| Workload | Evidence | Boundary |
|---|---|---|
| `glmark2` OpenGL | **Measured:** score 140. | One 800×600 configured session; not desktop or game FPS. |
| `glmark2-es2 --off-screen` | **Measured:** score 364, caveated. | DRI3 warning and a windowed header appeared despite the off-screen command. |
| Blender EEVEE Next | **Measured:** 600 frames at 1.49 s/frame mean; 648-frame short at 1.126 s/frame; 1,440-frame narrative at 1.944 s/frame. | Adreno GPU offload through Zink/Turnip, including headless Xvfb. Bounded renders; no multi-hour thermal claim. |
| MPFB2 human-character build | **Measured:** `create_human` 0.4 s; full rigged rebuild 3.9 s; 540×960 frame 3.8 s; 120-frame, 5 s shot about 7.5 min. | MPFB2 2.0.18 / Blender 4.3.2, EEVEE Next on Adreno 825 through Zink. One device run; no sustained thermal claim. |
| Blender viewport | **Observed:** Zink/Turnip on Adreno 825. | Renderer detection is separate from EEVEE render timing. Cycles GPU is **not established**. |
| llama.cpp CPU + Vulkan | **Verified:** both returned `4` on the bounded known-answer prompt; Vulkan assigned 29/29 layers to Adreno 825. **Measured:** clean-idle long run below. | Qwen2.5 1.5B Q4_0, one device and one workload. |
| llama.cpp Hexagon HTP | **Experimental:** on a matched three-run Qwen2.5 0.5B-named Q4_0 GGUF (llama.cpp identifies Qwen2 1B / 630.17M parameters), HTP measured a 46.2 tok/s median, Vulkan 24.8, and four-thread CPU 8.0. A separate matched Qwen2.5 1.5B Q4_K_M workload measured medians of 7.6 CPU, 18.2 Vulkan, and 18.9 HTP tok/s across three interleaved rounds; all routes returned `4`. | One device and short workloads; no quality, energy, or sustained-use claim. HTP operator failures and broader qualification remain open; HTP remains unsupported. HMX and attention correctness are unqualified. |
| `stable-diffusion.cpp` Vulkan | **Verified:** the managed extension generated a valid 512×512 image in 92.91 s at 10 steps with tiled Vulkan VAE; the output hash matched a second clean-guest run. | Redmi Turbo 4 Pro / SM8735 / Adreno 825, user-provided SD1.5 Q8_0 model, seed 42. One model/device/workload; CPU image quality remains unqualified. |
| Separate QNN SD1.5 runner | **Measured:** 25 consecutive 20-step 512×512 images; median 29.76 s/image, mean 31.12 s/image. Median HTP UNet time was 15.96 s for 20 denoising steps. | CLIP runs on CPU; UNet and VAE decoder run on HTP. One SM8735 device; no same-model CPU/GPU comparison. Not `stable-diffusion.cpp`; independent stage-tensor correctness remains unverified. |

### Clean-idle llama.cpp throughput

Prompt processing and generation rates from one sequential Qwen2.5 1.5B Q4_0
run on the configured device:

| Backend | Prompt processing | Generation | Total |
|---|---:|---:|---:|
| CPU | 59.04 tok/s | 2.38 tok/s | 264.39 s |
| Adreno 825 Vulkan | 92.19 tok/s | 13.27 tok/s | 71.30 s |
| Hexagon HTP, HVX / flash attention off | 34.20 tok/s | 12.02 tok/s | 129.46 s |

This is a bounded single-device comparison. HTP used the conservative
configuration that passed its known-answer checks and was slower than Vulkan.
It does not establish sustained performance, power use, or cross-device results.

### HTP speculative decoding probe (2026-11-06)

An exploratory llama.cpp `draft-simple` run used the Qwen2.5 1.5B Q4_0 main
model on HTP0 and the matching-family Qwen2.5 0.5B Q4_0 draft model on
Adreno 825 Vulkan0. The same short prompt, seed, context, and 128-token output
limit were used for the baseline and draft runs. Generation measured 19.5
tok/s without speculation, 9.1 tok/s with a two-token draft window, and 7.1
tok/s with a four-token window. All three brokered runs exited cleanly and the
HTP session closed successfully. This route made text generation slower, so it
was not adopted. It is a short exploratory result, not a controlled sustained
benchmark or a QNN-compiled text-model test.

### Same-prompt HTP quantization probe (2026-11-07)

A short run on the same device used the Qwen2.5 1.5B Q4_0 model, the same
prompt, seed, context, and 64-token output cap. HTP measured 19.6 generated
tok/s with the launcher's default power mode and 19.0 tok/s with the `burst`
power mode; Adreno Vulkan measured 17.6 tok/s. A same-settings HTP run with
the Q4_K_M model measured 15.9 tok/s. Each HTP session closed successfully.
This is one short run per setting, not a sustained or statistically controlled
comparison; it does not show a large NPU advantage.

### Earlier repeated small-model HTP/Vulkan throughput (2026-11-07)

Qwen2.5 0.5B Instruct Q4_0 was run three times per backend with the same
64-token prompt, seed, context, and batch settings. HTP generation rates were
42.8, 40.1, and 40.8 tok/s (median 40.8); Vulkan rates were 27.9, 28.1, and
27.9 tok/s (median 27.9). A separate verbose HTP known-answer run returned `4`
and assigned all 24 transformer layers to HTP0; all three throughput sessions
closed cleanly. This is about 46% higher generation throughput for this small
model in this bounded test. It is a separate earlier run set, not directly
comparable with the CPU-inclusive trial below, and does not establish the same
gain for larger models, model quality, or sustained use.

### Matched small-model CPU/Vulkan/HTP throughput (2026-11-07)

The same Qwen2.5 0.5B Instruct Q4_0 model, prompt, 64-token generation cap,
context (2048), batch/ubatch (128), seed (42), temperature (0), and four-thread
setting were run three times on each backend, interleaved CPU → Vulkan → HTP.
Generation rates were CPU 7.2/8.0/8.1 tok/s (median 8.0), Vulkan
24.1/24.8/26.3 tok/s (median 24.8), and HTP 46.9/46.2/43.9 tok/s (median
46.2). This bounded run measured HTP at about 1.86× Vulkan and 5.78× CPU
generation throughput. All three HTP broker sessions closed cleanly. A separate
known-answer run returned `4` and assigned all 24 layers to HTP0. This remains
a single-device, small-model throughput comparison: it does not establish
response quality, energy efficiency, thermal stability, or sustained
performance, and it does not resolve the open HTP operator-correctness gates.

### Matched Qwen2.5 1.5B CPU/Vulkan/HTP generation

The existing Qwen2.5 1.5B Q4_K_M model was run in three interleaved CPU → Vulkan → HTP rounds with four threads, the same arithmetic prompt, 64-token output cap, context 2048, batch/ubatch 128, temperature 0 and seed 42. All nine runs produced the expected answer `4`. Median generation rates were 7.6 tok/s CPU, 18.2 Vulkan and 18.9 HTP. The HTP build is separate from the CPU/Vulkan binary. This bounded result is a small HTP-over-Vulkan margin on one device; it does not establish sustained speed or HTP correctness. See the [full device record](https://github.com/soobujmiah/ternux/blob/main/guides/device-benchmark-evidence.md#2026-11-07-matched-qwen25-15b-cpuvulkanhtp-generation).

### QNN SD1.5 image generation soak

On 2026-10-14, the separate QNN runner generated 25 consecutive 512×512 images
from the existing `/sdcard/Llms/AbsoluteReality_qnn2.28_8gen2.zip`, with 20
DPM++ steps per image. All 25 completed. Runner-reported image time had a
29.76 s median and 31.12 s mean (28.23–55.80 s); the 20 HTP UNet steps had a
15.96 s median and 17.03 s mean (15.87–41.59 s). One generation contained a
single 26.24 s UNet-step outlier. CLIP prompt encoding ran on CPU; UNet
denoising and VAE decoding ran through Qualcomm QNN HTP. The 17m36s batch wall
time includes monitoring/poll intervals and process transitions, so use the
per-run measurements above for image throughput.

The HTP attribution comes from the runner's QNN HTP backend/device and graph
execution records. PRoot itself does not provide an accelerator: this path
reaches the Android QNN runtime through the existing FastRPC/Binder bridge.
GPU-labelled thermal readings are sensor measurements only and do not show
that the GPU ran this workload. The run was not a same-model GPU comparison.
For context, the device's separate Local Dream NPU route generated a 512×512
image in 5.7 s at 20 steps. The Ternux runner's 29.76 s median is about 5.2×
longer under the same device, resolution, and step count. The model and runtime
differ, so this is a substantial optimization gap, not a controlled A/B result
or evidence against the QNN DSP execution records. [Local Dream device evidence](https://github.com/soobujmiah/skb/blob/main/devices/redmi-turbo-4-pro/accelerator-access-audit.md).
In the Ternux run, the per-image median outside the UNet timing was 13.85 s;
that residual includes CLIP, helper/context startup, VAE decode, and PNG output.
The runner also makes separate unconditional and conditional UNet graph calls
for each step (40 calls for 20 steps), so context reuse and CFG execution are
the next profiling targets.

Battery temperature peaked at 41.9°C, `quiet_therm` at 47.9°C, and the sampled
GPU zones at 64.2°C; no NPU-specific thermal sensor was identified. All 25
images were visually screened: image 01 was checked at full resolution, and
images 02–25 were checked in two contact sheets. They show coherent landscape
variations; image 01 has a small cyan/black spot on the water, and no comparable
obvious defect stood out in the other 24 at contact-sheet size. This is a visual
screen, not detailed full-resolution artifact review. It is an experimental
single-device mixed CPU/HTP image pipeline, not a CPU/GPU comparison using the
same model, not an HTP-only end-to-end measurement, and not independent proof of
QNN tensor correctness or supported compatibility.
The 25 images and machine-readable run/thermal summary are on the device at
`/sdcard/sdgen/`; detailed implementation and historical evidence are in the
[QNN runner record](https://github.com/soobujmiah/ternux/blob/main/experiments/qnn-native/README.md)
and [device benchmark log](https://github.com/soobujmiah/ternux/blob/main/guides/device-benchmark-evidence.md).

### QNN batch setup-reuse check (2026-11-07)

Three same-day, 20-step paired batches measured 47.825, 46.946 and 45.931 s
(mean 46.901; 22.97–23.91 s/image). Their same-seed single controls totaled
60.429, 57.145 and 60.012 s (mean 59.195). Batch mean wall time was 20.8% lower
across these three short samples; order was single→batch→single twice and
batch→single→single once. All six batch/control PNG hashes matched. This is not
randomized or statistically powered, and is not a performance guarantee. Runs
used the existing archive without writing model members to disk. Independent
CLIP/UNet/VAE stage-tensor correctness remains unverified; the QNN runner is not
a managed extension, and the owner's 3–5 second target remains unmet. See the
[full per-run device record](https://github.com/soobujmiah/ternux/blob/main/guides/device-benchmark-evidence.md#2026-11-07-qnn-batch-setup-reuse-repeat).

## Detailed records

- [Full device benchmark evidence, reproduction steps, and dated measurements](https://github.com/soobujmiah/ternux/blob/main/guides/device-benchmark-evidence.md) — repository-only.
- [EEVEE GPU-offload render procedure](https://github.com/soobujmiah/ternux/blob/main/experiments/cartoon-pipeline/README.md) — repository workflow and tested headless command.
- [MPFB2 character-build measurements](https://github.com/soobujmiah/ternux/blob/main/guides/device-benchmark-evidence.md#mpfb2-human-character-build) — one device-side character build and render run.
- [CPU/Vulkan package installation and qualification](https://github.com/soobujmiah/ternux/blob/main/guides/llama-vulkan-extension.md#device-qualification-record) — repository-only.
- [Experimental HTP extension installation and limits](https://github.com/soobujmiah/ternux/blob/main/guides/llama-htp-experimental.md) — repository-only.
- [Current accelerator gates](ACCELERATOR-RELEASE-PLAN.html).
- [Separate QNN SD1.5 implementation and evidence](https://github.com/soobujmiah/ternux/blob/main/experiments/qnn-native/README.md) — repository-only; kept separate from `stable-diffusion.cpp`.
