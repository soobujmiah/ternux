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
| 2 | Existing QNN picture model, kept in place | CLIP CPU, UNet/VAE HTP graph execution and fixed-seed 20-step SD1.5 generation ran on SM8735. The first output was noise; the runner mixed sigma-space latents with the DPM++ VP-space equations. After correcting the solver and model input, visual review found a coherent landscape with one small cyan artifact. Two same-seed 512×512 runs matched exactly (SHA-256 `1a13957f…6764fc3`; 30.641 s and 36.828 s). Image generation and repeatability now **PASS** for this bounded setup; independent QNN tensor correctness remains **UNVERIFIED**. | Compare CLIP/UNet/VAE stage tensors with independent expected values; assess the localized cyan artifact and qualify a supported image/runtime configuration |
| 3 | Main Debian llama.cpp CPU/GPU/HTP qualification | CPU/Vulkan known-answer pass. On SM8735, one-token greedy Qwen2.5 1.5B checks isolate two independent failing configurations: HMX-selected matmul with flash attention off returned a wrong token; HVX-selected matmul with flash attention on also returned a wrong token. HVX-only matmul with flash attention off returned `4`. The route also passed a short CPU/HTP A/B known-answer smoke on a local SmolLM2-135M Q4_0 model (2026-10-14); both returned `2 + 2 = 4`, the HTP child exited 0, and its broker session closed cleanly. These checks used GGUF weights through llama.cpp Hexagon HTP; they are bounded results, not broad operator qualification. PR #16 merged the experimental broker/launcher. Pinned artifact build and Actions upload passed in run `38533135922`; the downloaded archive remains untested on device. This is an experimental build, not a supported end-user HTP route. The HVX-only/flash-attention-off route completed a sequential 2,955-token prompt/511-token generation and a clean-idle repeat with recall key `KITE-8042`; all 29 layers were assigned to HTP0. Clean-idle throughput was CPU 59.04/2.38 tok/s prompt/generation (264.39 s), Vulkan 92.19/13.27 (71.30 s), HTP 34.20/12.02 (129.46 s); HTP was slower than Vulkan. This is llama.cpp Hexagon execution of GGUF weights, not a QNN-compiled text model or supported end-user route. | Determine which individual HMX/attention operators cause the two wrong-token results; device-test the exact experimental HTP artifact; qualify optimized-path correctness/performance, HTP cancellation and fallback, then qualify a pinned supported configuration |
| 4 | Repeat and sustained device qualification | 600 consecutive 720p/16-sample EEVEE frames completed on SM8735 with thermal status 0 (2026-10-14); packaged extension CPU and Vulkan each passed three live-generation SIGINT/clean-exit samples, followed by fresh per-backend known-answer processes returning `4` with exit 0. This is bounded repeat evidence, not sustained stability. On 2026-10-14, SIGINT to the local HTP inference child did not complete within 20 seconds; the harness killed the process group without a recorded broker `closeSession`. PR #16 merged supervised signal forwarding, escalation, and closeSession reporting, but the implementation has not been device-retested; cancellation remains UNVERIFIED. A fresh HTP known-answer run passed after forced termination and closed a new session cleanly; HTP fallback remains UNVERIFIED. | Device-test the new supervised HTP cancellation and deterministic cleanup; retest fallback; sustained CPU/NPU stability |
| 5 | Reusable GitHub artifacts | Fresh ARM64 Vulkan build and ABI audit passed in workflow run `38521164812` on main commit `6097aec`: 69 AArch64 ELF files, all dependencies resolved, maximum GLIBC 2.38, `$ORIGIN/../lib`; upstream MIT license present. CI refreshed the published prerelease assets. The exact archive installed into an isolated home through the current working-tree extension installer; CPU and Adreno Vulkan known-answer smoke passed on SM8735. The installer now resolves `ldconfig` under `/sbin` even when that directory is absent from PATH. The initial HTP archive from run `38533135922` omitted separate upstream third-party license texts. The corrected PR artifact from run `38540202351` has SHA-256 `7211af2cbfc63e7cf07671fe968b76a1259f3975d6bc36fdac023b48160180cd`; 192 archive entries were checked for traversal, the source manifest pin was verified, all nine tracked upstream license/copying texts were present, and all 14 symlink targets stayed within the package. It contains 103 regular AArch64 ELF64 files plus 14 AArch64 symlink aliases and four Hexagon ELF32 files. These are package checks, not exact-archive device validation; HTP remains experimental. | Clean-driver installation, broader transitive-license review, device-test the exact HTP artifact, and repeated/sustained device qualification |
| 6 | Extension installation and complete guides | COMPLETE for the published CPU + Vulkan prerelease: `ternux extension list/install llama-vulkan` host delegation, guest install, SHA-256, archive paths, atomic destination, and no-overwrite behavior are verified; CPU and Vulkan known-answer pass. Website quick guide links to repository-only detailed automatic/manual guides; installation policy and ADT ownership are documented. | The HTP installer is merged and its PR artifact package built successfully, but exact archive installation and device validation remain open. Future extensions need their own release and validation gates; this row does not qualify HTP or the next stable Ternux release. |
| 7 | CLI and installation screen polish | Repository UI renderer suite passes 24/24 portrait, landscape and resize checks; generated CLI guide links now expose the CPU/Vulkan quick and deep guides. Human visual/usability validation on the phone remains pending. | Clear mobile layout, meaningful status/error text, interactive/unattended paths and owner visual/usability validation |
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
