---
title: Accelerator and ecosystem release completion plan
description: Pending validation, standalone QNN and artifact installation gates before the next Ternux release.
lang: en
alt_url: /bn/docs/ACCELERATOR-RELEASE-PLAN.html
---

Owner direction, 2026-10-13: finish the standalone QNN image route first, then
return to the main Ternux NPU support work. Complete every release gate before
the next Ternux version is released. This plan tracks pending work explicitly;
it does not describe shipped capabilities.

| Order | Work | Current status | Completion evidence |
|---|---|---|---|
| 1 | Our standalone Android/Bionic QNN helper, callable from PRoot | Runtime/provider, backend/device, VAE context load/free and encoder graph execution VERIFIED; generic HTP Add known-answer VERIFIED; model output correctness UNVERIFIED | Matching execution headers, tensor metadata, request/response, known-output accelerator test |
| 2 | Existing QNN picture model, kept in place | No-copy VAE/UNet fixed-input graph execution VERIFIED; prompt-to-image inference UNVERIFIED | CLIP/UNet/VAE pipeline, graph execution, stage attribution, fixed-seed image test and reviewed output |
| 3 | Main Debian llama.cpp CPU/GPU/HTP qualification | CPU/Vulkan known-answer pass; HTP known-answer FAILED | Diagnose Q4 mismatch, validate operators, reproduce correct model answers on intended backend |
| 4 | Repeat and sustained device qualification | Three short CPU/GPU benchmarks; sustained testing UNVERIFIED | Matched runs, memory/thermal/power availability recorded, stability, cancellation/restart/cleanup, safe fallback |
| 5 | Reusable GitHub artifacts | HTP experimental prerelease exists; Vulkan package local; standalone helper NDK CI artifact passed device graph test; no released install package | Pinned build inputs, ABI/ELF checks, checksums, licenses, release manifest and clean-device install verification |
| 6 | Extension installation and complete guides | Current LLM installer builds from source | Release-based selectable ADT/llama.cpp/extensions, automatic/manual steps, model paths, backend selection, upgrade/resume/failure handling |
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
depends on a locally built Turnip that ternux neither provisions nor pins, and
any package operation that reverts that driver invalidates the row's evidence
without reporting anything. Record that dependency with the result, not
separately from it.

This has a consequence for order 5. Clean-device install verification of the
Vulkan path cannot pass while the driver it needs is absent from a clean device.
Either the Turnip build becomes a release artifact under order 5's own terms —
pinned inputs, ABI/ELF checks, checksums, licence review, release manifest — or
the Vulkan result is recorded as device-local and declared out of scope for the
clean-device gate. It cannot stay as it is and also count toward order 5.

[Graphics persistence](GRAPHICS-PERSISTENCE.html) keeps an existing install from
losing that driver and is verified against a package reinstall, but it supplies
no driver of its own and does not close either gate.

## Immediate handoff

The [standalone discovery experiment](../experiments/qnn-native/README.md)
contains independently written source, measured runtime identity, reproduction
commands and inference prerequisites. The no-copy ZIP-to-memfd path, VAE contexts and fixed-input encoder graph
execution work with a licensed Qualcomm 2.29 V73 runtime in scratch. The generic Add graph now has a known-output CDSP pass; establish an independent
expected VAE/UNet tensor before qualifying the image pipeline. Preserve the
existing QNN archive and the existing GGUF model paths.

The [benchmark report](BENCHMARKS.md) preserves CPU/GPU results and the HTP
failure. Existing LAI findings are recorded in LAI's native Android research
note for later work; this plan does not alter LAI's runtime or device gates.
