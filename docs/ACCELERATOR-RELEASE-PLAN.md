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
| 1 | Our standalone Android/Bionic QNN helper, callable from PRoot | Runtime/provider, backend/device, VAE context load/free and encoder graph execution VERIFIED; known-output correctness UNVERIFIED | Matching execution headers, tensor metadata, request/response, known-output accelerator test |
| 2 | Existing QNN picture model, kept in place | No-copy VAE/UNet context load and fixed-input VAE encoder execution VERIFIED; image inference UNVERIFIED | CLIP/UNet/VAE pipeline, graph execution, stage attribution, fixed-seed image test and reviewed output |
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

## Immediate handoff

The [standalone discovery experiment](../experiments/qnn-native/README.md)
contains independently written source, measured runtime identity, reproduction
commands and inference prerequisites. The no-copy ZIP-to-memfd path, VAE contexts and fixed-input encoder graph
execution work with a licensed Qualcomm 2.29 V73 runtime in scratch. Establish
independent known-output tensor correctness before implementing the image pipeline. Preserve the
existing QNN archive and the existing GGUF model paths.

The [benchmark report](BENCHMARKS.md) preserves CPU/GPU results and the HTP
failure. Existing LAI findings are recorded in LAI's native Android research
note for later work; this plan does not alter LAI's runtime or device gates.
