---
title: Accelerator and ecosystem release completion plan
description: Pending accelerator, package distribution and artifact installation gates before the next Ternux release.
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
describe shipped capabilities. Owner request, 2026-11-06: prepare a signed Termux
APT distribution channel for `pkg install ternux`; this new distribution gate
does not waive the accelerator qualification gates.

| Order | Work | Current status | Completion evidence |
|---|---|---|---|
| 1 | Our standalone Android/Bionic QNN helper, callable from PRoot | Runtime/provider, backend/device, VAE context load/free and encoder graph execution VERIFIED; generic HTP Add known-answer VERIFIED; model output correctness UNVERIFIED | Matching execution headers, tensor metadata, request/response, known-output accelerator test |
| 2 | Existing QNN picture model, kept in place | CLIP CPU, UNet/VAE HTP graph execution and fixed-seed SD1.5 generation ran on SM8735. The 25-image soak completed 25/25 (17m36s outer wall); median/mean was 29.76/31.12 s per image and HTP UNet median/mean 15.96/17.03 s per 20 steps. Three instrumented follow-up images took 30.797–31.122 s. One 30.797 s profile measured 7.275 s to stream/hash/seal the 880,827,736-byte UNet member to memfd and 17.015 s across 40 serial HTP requests. CLIP ran on CPU and UNet/VAE on QNN HTP. Same-seed output repeated exactly; 25 images had an initial visual screen, with a small cyan/black spot in image 01. Independent stage-tensor correctness and full-resolution review of 24 images remain **UNVERIFIED**. | Compare CLIP/UNet/VAE stage tensors with independent expected values, review remaining images, and investigate/optimize the measured performance gap |
| 3 | Main Debian llama.cpp CPU/GPU/HTP qualification | CPU/Vulkan known-answer pass. One-token greedy Qwen2.5 1.5B tests still show a wrong token with HMX matmul and with flash attention enabled under the prior default selection; HVX-only matmul with flash attention off returns `4`. Exact HVX `MUL_MAT` operator run completed **1,389/1,389 tests successfully**. HMX-selected `MUL_MAT` has 529 infinite-error failures. Explicit `GGML_HEXAGON_FA_SELECT=1` (HVX attention) plus `GGML_HEXAGON_MM_SELECT=1` completed the `FLASH_ATTN_EXT` suite: 5,332 unique cases, 2,593 passed, 2,732 unsupported, and 7 finite numerical-error failures; a filtered rerun reproduced all seven. The earlier default-attention-selection run had 1,848 `inf` failures in its 120 s partial log. HTP remains experimental; flash attention stays disabled in the launcher. Exact package run `38560288558` was isolated-installed; SmolLM2-135M returned `2 + 2 = 4`, 31/31 layers were on HTP0, and bounded cancellation closed the session cleanly. Metadata-corrected build `38562008524` passed; runtime files match the tested archive. These are bounded GGUF/llama.cpp results, not complete operator coverage, a QNN-compiled text model, or a supported route. | Investigate remaining HMX/attention numerical errors; test other HTP operators, failure/restart, and sustained operation before considering support |
| 4 | Repeat and sustained device qualification | 600 consecutive 720p/16-sample EEVEE frames completed on SM8735 with thermal status 0 (2026-10-14); packaged CPU and Vulkan extensions each passed three live-generation SIGINT/clean-exit samples and fresh known-answer restarts. Exact HTP package run `38560288558` passed bounded SIGINT and clean `closeSession [0, 0]`. Separate QNN SD1.5 image soak completed 25/25 generations in 17m36s, with a 29.76 s median runner time and recorded thermal samples; this is one experimental mixed CPU/HTP image workload, not a general NPU stability qualification. Failure/restart behavior and broad sustained CPU/NPU stability remain open. No automatic CPU fallback is configured. | Qualify failure/restart behavior and sustained CPU/NPU behavior across supported paths |
| 5 | Reusable GitHub artifacts | Fresh ARM64 Vulkan build and ABI audit passed in run `38521164812`; its exact archive passed isolated install and CPU/Adreno Vulkan known-answer checks. HTP artifact run `38560288558` passed checksum, safe-path inspection, isolated installation, known-answer HTP0 execution, and bounded cancellation. Metadata-corrected build `38562008524` passed; its checksum-verified archive differs from the device-tested runtime payload only in README/manifest metadata, adding `libcdsprpc.so` and `libfastrpc-dev` dependency inventory. HTP remains experimental. | Finish clean-driver installation and broader transitive-license review; retain separate correctness and compatibility gates |
| 6 | Extension installation and complete guides | COMPLETE for the published CPU + Vulkan prerelease. HTP run `38560288558` installed through the extension installer into an isolated HOME using archive/checksum fixtures; path/manifest/launcher checks passed. The metadata-corrected run `38562008524` also passed checksum and isolated installer-fixture ingestion with the corrected README/manifest. Runtime package files match the tested archive; HTP remains experimental and unpublished. | Keep experimental HTP support and release gates separate |
| 7 | CLI and installation screen polish | The welcome dialog height is capped at 400 px for the current portrait display; a fresh 752×1155 screenshot showed all guide content and actions fitting. Xfce wallpaper setup now writes monitor and per-workspace properties and reloads xfdesktop. PR #48 added managed PID/status/log lifecycle and the Termux:X11 character-input workaround. This session rebuilt 2.0.0 and reinstalled it through local APT; the generated launcher refreshed and an initial status check correctly detected the real Android Termux:X11 process name. A subsequent bounded observation showed the managed session process and X11 process exit after startup, so sustained background-session behavior is not verified here. Owner phone typing and visual/usability review also remain open. | Diagnose and verify sustained desktop lifetime in the owner's normal Termux session; review phone typing, screenshot, welcome layout, status/error text and interactive/unattended paths |
| 8 | Signed Termux APT distribution (`pkg install ternux`) | Package 2.0.0 was rebuilt and reinstalled/upgraded through local APT; the installed `lib/ternux/desktop.sh` SHA-256 matches source. Previously recorded `ternux doctor --json`, `ternux verify --json`, accelerated Adreno Zink, guest PulseAudio playback, Avro switching and Bengali font checks passed. Current source loads `module-sles-source` as `Ternux_Microphone`; a live Termux API microphone path is not implemented. The Termux API microphone command records to a file rather than exposing a live PulseAudio source. Package/repository builders verify package identity/SHA-256 and primary-key signature; PR #47 adds pinned-tools CI and a manual v2 publisher. GitHub `apt-release` signing environment/key/fingerprint and an independent fingerprint channel/hosted repository are absent, so signed `pkg install ternux` clean install and upgrade remain unverified. | Close accelerator and owner visual gates; resolve microphone capture design and permission timing; configure protected signing key/fingerprint and independent verification channel; qualify signed clean install and upgrade |
| 9 | Complete Ternux version release | HELD | Not release-ready: gates 1–5 still include unverified QNN model/stage correctness, HTP numerical failures, broad sustained-device qualification, and clean-driver/transitive-license review. Gate 7 still needs owner visual/usability review. Gate 8 has no protected signing environment/key/fingerprint publication channel or hosted repository, and signed clean install/upgrade is unqualified. | Close every preceding gate and repeat the final installed-artifact and documentation audit |

The SD1.5 performance gap remains a qualification item: the Ternux QNN runner
measured a 29.76 s/image median, while the separate Local Dream route measured
5.7 s for 512×512 at 20 steps on this device. The Ternux result is about 5.2×
longer; the models and runtimes differ, so this is not a controlled A/B test.
The Ternux run does record QNN HTP/DSP graph execution. Investigate and optimize
the gap before presenting the runner as a practical NPU image-generation path.
The measured 13.848 s median outside UNet includes CLIP, helper/context startup,
VAE decode, and PNG output; 20 CFG steps currently make 40 serial UNet graph
requests. The later profile measured UNet archive acquisition and request time
separately. The owner expects roughly 3–5 seconds for a 512×512 image; the
separate Local Dream observation is 5.7 seconds. This is a target to investigate,
not a demonstrated capability or guarantee. Stable Diffusion is not a Ternux
extension; the owner explicitly deferred packaging it until later. See the
[QNN performance handoff](../handoffs/qnn-sd15-performance.md),
[QNN correctness and review handoff](../handoffs/qnn-sd15-correctness.md), and
[HTP qualification handoff](../handoffs/llama-htp-qualification.md).
See the [Local Dream device evidence](https://github.com/soobujmiah/skb/blob/main/devices/redmi-turbo-4-pro/accelerator-access-audit.md).

These three handoffs are repository-only continuation notes. This file remains
the single canonical accelerator/release roadmap; do not create a second roadmap.

### HTP operator diagnostics (2026-10-14)

The exact Linux ARM64 artifact from workflow run `38567329752` was tested
through the Ternux Binder/FastRPC broker on the SM8735 device. With default
HMX selection, `test-backend-ops -b HTP0 -o MUL_MAT` completed with **529
failing cases**, each reporting an infinite error; the device reported Hexagon
v73, HMX present, and 8 MB VTCM. With `GGML_HEXAGON_MM_SELECT=1`, the HVX-only
`MUL_MAT` suite was rerun with a longer bound and completed **1,389/1,389 HTP
tests successfully**. The CPU backend was skipped; the HTP backend reported
OK, and the broker session closed with `closeSession [0, 0]`. This qualifies
the tested HVX `MUL_MAT` cases only, not all HTP operators.

This isolates a real HMX `MUL_MAT` correctness failure on this device, but does
not identify its hardware or kernel cause. An upstream v73 report documents a
similar HMX failure on a different SM7750 device with no FP16 HMX; that is a
diagnostic lead, not proof that SM8735 has the same capability. A separate
upstream v75 report describes a race in HMX flash attention. See the
[SM7750 HMX report](https://github.com/ggml-org/llama.cpp/issues/29473) and
[SM8650 flash-attention report](https://github.com/ggml-org/llama.cpp/issues/26759).
The next HTP gates are an SM8735 HMX FP16 capability probe, other HVX operator
coverage, and isolating the remaining flash-attention failures. Full commands and
artifact provenance are in the
[experimental HTP guide](../guides/llama-htp-experimental.md#latest-operator-checks).

A first `FLASH_ATTN_EXT` run selected HVX matmul but left attention selection
at its default. It hit a 120-second bound after 1,848 `inf` failures and 112
passes; that run was incomplete. A later run explicitly set both
`GGML_HEXAGON_MM_SELECT=1` and `GGML_HEXAGON_FA_SELECT=1` to select HVX matmul
and HVX flash attention. It completed 5,332 unique cases: 2,593 passed, 2,732
were unsupported, and 7 failed with finite numerical errors above tolerance.
A filtered rerun reproduced all 7 failing parameter cases. The test exited 1
because of those failures, and the broker closed the CDSP session cleanly. This
substantially narrows the earlier error pattern but does not qualify flash
attention; the launcher continues to keep it disabled. Logs are in
`/home/sbj/npu-probe-2026-10-13/htp-op-qualification-38567329752/`.

A broad `test-backend-ops -b HTP0` run with HVX matmul and reduced queue
settings (`OPBATCH=128`, `OPQUEUE=2`) recorded 3,520 passing case lines, 45
numerical-error failures across `DIV`, `GET_ROWS`, `SWIGLU_CLAMP`, `ADD`, and
`SUB`, and 4,874 unsupported cases before aborting with
`dspqueue_read failed: 0x0000002e` (child exit -6). The broker then closed the
CDSP session cleanly. This is **incomplete**, not an all-operator result. An
isolated `MUL_MAT_W4A4` check passed 1/1; the broad-run abort cause is unknown.

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
