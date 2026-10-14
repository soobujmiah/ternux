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
| Separate QNN SD1.5 runner | **Measured:** same-seed 20-step 512×512 output repeated exactly; visual review found a coherent landscape with a small cyan artifact. | Not `stable-diffusion.cpp`; independent stage-tensor correctness remains unverified. |

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

## Detailed records

- [Full device benchmark evidence, reproduction steps, and dated measurements](https://github.com/soobujmiah/ternux/blob/main/guides/device-benchmark-evidence.md) — repository-only.
- [EEVEE GPU-offload render procedure](https://github.com/soobujmiah/ternux/blob/main/experiments/cartoon-pipeline/README.md) — repository workflow and tested headless command.
- [CPU/Vulkan package installation and qualification](https://github.com/soobujmiah/ternux/blob/main/guides/llama-vulkan-extension.md#device-qualification-record) — repository-only.
- [Experimental HTP extension installation and limits](https://github.com/soobujmiah/ternux/blob/main/guides/llama-htp-experimental.md) — repository-only.
- [Current accelerator gates](ACCELERATOR-RELEASE-PLAN.html).
- [Separate QNN SD1.5 implementation and evidence](https://github.com/soobujmiah/ternux/blob/main/experiments/qnn-native/README.md) — repository-only; kept separate from `stable-diffusion.cpp`.
