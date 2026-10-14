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
| 2 | Existing QNN picture model, kept in place | CLIP CPU, UNet/VAE HTP graph execution and fixed-seed SD1.5 generation ran on SM8735. After correcting the scheduler, same-seed 20-step 512×512 runs repeated exactly (`1a13957f…6764fc3`); one was visually reviewed as a coherent landscape with a small cyan artifact. A 25-image 20-step soak then completed 25/25 (17m36s batch wall including monitoring/poll intervals). Runner time was median 29.76 s and mean 31.12 s per image; HTP UNet 20-step time was median 15.96 s and mean 17.03 s, with one 26.24 s single-step outlier. CLIP ran on CPU and UNet/VAE on QNN HTP. Battery peak was 41.9°C, `quiet_therm` 47.9°C, sampled GPU zone 64.2°C; no NPU-specific thermal sensor was identified. Only one image was visually reviewed. Independent QNN tensor correctness remains **UNVERIFIED**. | Compare CLIP/UNet/VAE stage tensors with independent expected values; review the remaining generated images and qualify a supported image/runtime configuration |
| 3 | Main Debian llama.cpp CPU/GPU/HTP qualification | CPU/Vulkan known-answer pass. On SM8735, one-token greedy Qwen2.5 1.5B checks isolate two independent failing configurations: HMX-selected matmul with flash attention off returned a wrong token; HVX-selected matmul with flash attention on also returned a wrong token. HVX-only matmul with flash attention off returned `4`. Exact package run `38560288558` (SHA-256 `9d5d2793a9a83d2d688b1df84494f1ef46f3f9fc91cb622ee2a0f1ebc26a1462`) was installed into an isolated home; SmolLM2-135M returned `2 + 2 = 4`, all 31/31 layers were assigned to HTP0, and `closeSession [0, 0]` succeeded. Its bounded SIGINT check also stopped the child and closed the session cleanly (broker exit 130). Metadata-corrected build `38562008524` completed successfully; its archive SHA-256 is `229f8026084d83d2853be89319cef23fb0909101edb0be916b33cc1bd441f845`. Direct archive inventories confirm the only changed members are `README.txt` and `build-manifest.json`; all runtime files and symlinks are identical to the tested archive. The HVX-only route also completed a 2,955-token prompt/511-token generation and clean-idle repeat with recall key `KITE-8042`; HTP was slower than Vulkan. These are bounded GGUF/llama.cpp results, not broad operator qualification, a QNN-compiled text model, or a supported route. | Identify the two HMX/attention wrong-token causes; qualify optimized-path correctness/performance and broader sustained stability before considering support |
| 4 | Repeat and sustained device qualification | 600 consecutive 720p/16-sample EEVEE frames completed on SM8735 with thermal status 0 (2026-10-14); packaged CPU and Vulkan extensions each passed three live-generation SIGINT/clean-exit samples and fresh known-answer restarts. Exact HTP package run `38560288558` passed bounded SIGINT and clean `closeSession [0, 0]`. Separate QNN SD1.5 image soak completed 25/25 generations in 17m36s, with a 29.76 s median runner time and recorded thermal samples; this is one experimental mixed CPU/HTP image workload, not a general NPU stability qualification. Failure/restart behavior and broad sustained CPU/NPU stability remain open. No automatic CPU fallback is configured. | Qualify failure/restart behavior and sustained CPU/NPU behavior across supported paths |
| 5 | Reusable GitHub artifacts | Fresh ARM64 Vulkan build and ABI audit passed in run `38521164812`; its exact archive passed isolated install and CPU/Adreno Vulkan known-answer checks. HTP artifact run `38560288558` passed checksum, safe-path inspection, isolated installation, known-answer HTP0 execution, and bounded cancellation. Metadata-corrected build `38562008524` passed; its checksum-verified archive differs from the device-tested runtime payload only in README/manifest metadata, adding `libcdsprpc.so` and `libfastrpc-dev` dependency inventory. HTP remains experimental. | Finish clean-driver installation and broader transitive-license review; retain separate correctness and compatibility gates |
| 6 | Extension installation and complete guides | COMPLETE for the published CPU + Vulkan prerelease. HTP run `38560288558` installed through the extension installer into an isolated HOME using archive/checksum fixtures; path/manifest/launcher checks passed. The metadata-corrected run `38562008524` also passed checksum and isolated installer-fixture ingestion with the corrected README/manifest. Runtime package files match the tested archive; HTP remains experimental and unpublished. | Keep experimental HTP support and release gates separate |
| 7 | CLI and installation screen polish | Repository UI renderer suite passes 24/24 portrait, landscape and resize checks; generated CLI guide links now expose the CPU/Vulkan quick and deep guides. Human visual/usability validation on the phone remains pending. | Clear mobile layout, meaningful status/error text, interactive/unattended paths and owner visual/usability validation |
| 8 | Complete Ternux version release | HELD | All prior gates satisfied, accurate support matrix, required CI, installed-artifact device tests and final documentation |

### HTP operator diagnostics (2026-10-14)

The exact Linux ARM64 artifact from workflow run `38567329752` was tested
through the Ternux Binder/FastRPC broker on the SM8735 device. With default
HMX selection, `test-backend-ops -b HTP0 -o MUL_MAT` completed with **529
failing cases**, each reporting an infinite error; the device reported Hexagon
v73, HMX present, and 8 MB VTCM. With `GGML_HEXAGON_MM_SELECT=1`, the HVX-only
`MUL_MAT` suite ran for a bounded 180 seconds and recorded 2,389 case outputs
without an error before the timeout. That partial run is **incomplete**, not a
suite pass. Both broker sessions closed with `closeSession [0, 0]`.

This isolates a real HMX `MUL_MAT` correctness failure on this device, but does
not identify its hardware or kernel cause. An upstream v73 report documents a
similar HMX failure on a different SM7750 device with no FP16 HMX; that is a
diagnostic lead, not proof that SM8735 has the same capability. A separate
upstream v75 report describes a race in HMX flash attention. See the
[SM7750 HMX report](https://github.com/ggml-org/llama.cpp/issues/29473) and
[SM8650 flash-attention report](https://github.com/ggml-org/llama.cpp/issues/26759).
The next HTP gates are an SM8735 HMX FP16 capability probe, a complete HVX
operator run, and separate flash-attention operator checks. Full commands and
artifact provenance are in the
[experimental HTP guide](../guides/llama-htp-experimental.md#latest-operator-checks).

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
contains implementation details and reproduction commands. This plan is the
single current status record for both accelerator gates. The SD1.5 DPM++ solver
space mismatch has been corrected; the same-seed output now repeats exactly and
is visually coherent, with a small cyan artifact. This does not establish
independent QNN tensor correctness. Preserve the existing QNN archive and GGUF
model paths.

The published [benchmark summary](BENCHMARKS.html) links to the repository-only
[detailed device benchmark record](https://github.com/soobujmiah/ternux/blob/main/guides/device-benchmark-evidence.md),
which preserves the HTP failure matrix and later conditional HVX result.
The experimental HTP package install and operating limits are in the separate
[repository HTP guide](https://github.com/soobujmiah/ternux/blob/main/guides/llama-htp-experimental.md).
Existing LAI findings are recorded in LAI's native Android research
note for later work; this plan does not alter LAI's runtime or device gates.
