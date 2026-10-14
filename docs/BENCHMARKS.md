---
title: "Benchmarks and device evidence"
description: "A concise, measured snapshot of Ternux graphics and accelerator workloads, with explicit evidence boundaries."
lang: "en"
alt_url: "/bn/docs/BENCHMARKS.html"
evidence_through: "2026-10-14"
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
| Blender viewport | **Observed:** Zink/Turnip on Adreno 825. | Renderer detection is separate from EEVEE render timing. Cycles GPU is **not established**. |
| llama.cpp CPU + Vulkan | **Verified:** both returned `4` on the bounded known-answer prompt; Vulkan assigned 29/29 layers to Adreno 825. **Measured:** clean-idle long run below. | Qwen2.5 1.5B Q4_0, one device and one workload. |
| llama.cpp Hexagon HTP | **Experimental:** HVX matmul with flash attention off passed bounded known-answer and long recall-key checks. | HMX-selected matmul + flash attention off and HVX matmul + flash attention on returned wrong answers. HTP is not a supported route. |
| `stable-diffusion.cpp` Vulkan | **Observed:** Vulkan-enabled build reported. | Inference, image output, and seconds/image are **untested**. |
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

## Detailed records

- [Full device benchmark evidence, reproduction steps, and dated measurements](https://github.com/soobujmiah/ternux/blob/main/guides/device-benchmark-evidence.md) — repository-only.
- [EEVEE GPU-offload render procedure](https://github.com/soobujmiah/ternux/blob/main/experiments/cartoon-pipeline/README.md) — repository workflow and tested headless command.
- [CPU/Vulkan package installation and qualification](https://github.com/soobujmiah/ternux/blob/main/guides/llama-vulkan-extension.md#device-qualification-record) — repository-only.
- [Experimental HTP extension installation and limits](https://github.com/soobujmiah/ternux/blob/main/guides/llama-htp-experimental.md) — repository-only.
- [Current accelerator gates](ACCELERATOR-RELEASE-PLAN.html).
- [Separate QNN SD1.5 implementation and evidence](https://github.com/soobujmiah/ternux/blob/main/experiments/qnn-native/README.md) — repository-only; kept separate from `stable-diffusion.cpp`.
