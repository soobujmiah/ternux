---
title: Accelerator and ecosystem release completion plan
description: Pending validation, standalone QNN and artifact installation gates before the next Ternux release.
lang: en
alt_url: /bn/docs/ACCELERATOR-RELEASE-PLAN.html
---

Owner direction, 2026-10-13: finish the standalone QNN image route first, then
return to the main Ternux NPU support work. Owner clarification, 2026-10-14:
the primary objective is Ternux CPU, GPU and NPU support; continue the main
accelerator qualification while keeping the QNN image route as a separate
pending gate. Owner clarification, 2026-10-14: Ubuntu installation on another
device is deferred and is not a blocker or remaining task for this release;
the existing Ubuntu profile remains explicitly unverified. Complete the
remaining in-scope accelerator and release gates before the next Ternux
version is released. This plan tracks pending work explicitly; it does not
describe shipped capabilities.

| Order | Work | Current status | Completion evidence |
|---|---|---|---|
| 1 | Our standalone Android/Bionic QNN helper, callable from PRoot | Runtime/provider, backend/device, VAE context load/free and encoder graph execution VERIFIED; generic HTP Add known-answer VERIFIED; model output correctness UNVERIFIED | Matching execution headers, tensor metadata, request/response, known-output accelerator test |
| 2 | Existing QNN picture model, kept in place | No-copy VAE/UNet fixed-input graph execution VERIFIED; fixed-prompt CLIP CPU input and output repeatability VERIFIED on 2026-10-14; CLIP-to-UNet and prompt-to-image UNVERIFIED | CLIP/UNet/VAE pipeline, graph execution, stage attribution, fixed-seed image test and reviewed output |
| 3 | Main Debian llama.cpp CPU/GPU/HTP qualification | CPU/Vulkan known-answer pass; HTP default path FAILED; HVX matmul plus flash-attention-off passed short known-answer prompts on Qwen2.5 1.5B and Llama 3.2 3B on SM8735 (2026-10-14) | Isolate failing HMX/attention operators, qualify repeatability and longer prompts, then qualify a pinned supported configuration |
| 4 | Repeat and sustained device qualification | 600 consecutive 720p/16-sample EEVEE frames completed on SM8735 with thermal status 0 (2026-10-14); packaged extension CPU and Vulkan each passed one live-generation SIGINT/clean-exit/restart known-answer cycle (2026-10-14). Sustained CPU/NPU, repeated cancellation stress, NPU cancellation and fallback remain UNVERIFIED | Matched runs, memory/thermal/power availability recorded, sustained stability, cancellation/restart/cleanup under repeat and NPU load, safe fallback |
| 5 | Reusable GitHub artifacts | Pinned Vulkan ARM64 package built on a native runner; checksum, ELF, RUNPATH, dependencies, and bundled license checked. Published as a prerelease; installed on SM8735; CPU and Adreno Vulkan known-answer pass. HTP remains experimental. | Clean-device Mesa/Turnip installation, broader license/ABI review, and repeated/sustained device qualification |
| 6 | Extension installation and complete guides | COMPLETE for the published CPU + Vulkan prerelease: `ternux extension list/install llama-vulkan` host delegation, guest install, SHA-256, archive paths, atomic destination, and no-overwrite behavior are verified; CPU and Vulkan known-answer pass. Website quick guide links to repository-only detailed automatic/manual guides; installation policy and ADT ownership are documented. | Future extensions need their own release and validation gates; this row does not qualify HTP or the next stable Ternux release. |
| 7 | CLI and installation screen polish | Pending release phase | Clear mobile layout, meaningful status/error text, interactive/unattended paths and usability validation |
| 8 | Complete Ternux version release | HELD | All prior gates satisfied, accurate support matrix, required CI, installed-artifact device tests and final documentation |

For order 2, the existing QNN archive cannot establish CPU/GPU execution: those
paths need compatible weights/backend pairs of their own. A `.bin` context
compiled for HTP is not automatically portable to a CPU or GPU backend. Record
BLOCKED when an actual prerequisite prevents a valid test; never manufacture a
PASS or treat an unrun test as FAILED. Optional 1.58-bit/Q8 exploration remains
outside the current correctness gate.

## Graphics dependency of the Vulkan evidence

Order 3 records a Vulkan known-answer pass. That pass does not rest on anything
Debian ships. Measured on 2026-10-13 on the Adreno 825 device, Debian's
`mesa-vulkan-drivers 25.0.7-2+deb13u1` enumerated **no Adreno device at all** —
only `llvmpipe` as a CPU-type Vulkan device — and forcing software GL on the same
device ended in `SIGILL` rather than a slow render. The Vulkan row therefore
depends on Turnip. Ternux's GPU phase provisions the upstream Debian Trixie
arm64 archive into `/usr/local`; it now pins upstream release
`mesa-26.3.0-devel-20260824` and verifies archive SHA-256
`c014cf66bdbff96417ee30d34f006cf51df64ae04893d599711b0b6b73b52ccf` before
installation. The driver remains an upstream binary dependency rather than a
Ternux-built artifact. Record that dependency with the result, not separately
from it.

This has a consequence for order 5. Clean-device install verification of the
Vulkan path cannot pass while the driver it needs is absent from a clean device.
The pinned installer input closes the mutable-download gap, but clean-device
install verification still needs to prove that the phase installs this exact
archive and that its license and ABI are suitable. Order 5's Ternux release
artifact and install-package gates remain open.

[Graphics persistence](GRAPHICS-PERSISTENCE.html) documents the apt-safe install
layout. It does not replace clean-device qualification or the reusable artifact
gate.

## QNN experiment and next validation

The [standalone discovery experiment](../experiments/qnn-native/README.md)
contains independently written source, measured runtime identity, reproduction
commands and inference prerequisites. The no-copy ZIP-to-memfd path, VAE contexts and fixed-input encoder graph
execution work with a licensed Qualcomm 2.29 V73 runtime in scratch. The generic Add graph now has a known-output CDSP pass; establish an independent
expected VAE/UNet tensor before qualifying the image pipeline. Preserve the
existing QNN archive and the existing GGUF model paths.

The [benchmark report](BENCHMARKS.md) preserves CPU/GPU results and the HTP
failure plus the later conditional HVX result. Existing LAI findings are recorded in LAI's native Android research
note for later work; this plan does not alter LAI's runtime or device gates.
