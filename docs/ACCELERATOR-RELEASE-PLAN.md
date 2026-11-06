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
| 2 | Existing QNN picture model, kept in place | CLIP CPU, UNet/VAE HTP graph execution and fixed-seed SD1.5 generation ran on SM8735. The 25-image soak completed 25/25 (17m36s outer wall); median/mean was 29.76/31.12 s per image and HTP UNet median/mean 15.96/17.03 s per 20 steps. Three instrumented follow-up images took 30.797–31.122 s. One 30.797 s profile measured 7.275 s to stream/hash/seal the 880,827,736-byte UNet member to memfd and 17.015 s across 40 serial HTP requests. CLIP ran on CPU and UNet/VAE on QNN HTP. The model archive `/sdcard/Llms/AbsoluteReality_qnn2.28_8gen2.zip` is present and its SHA-256 matches the recorded soak report. Same-seed output repeated exactly. On 2026-11-06, images 02–25 were reviewed individually at 512×512: coherent scenes overall, with a tiny dark mark at the top edge of image 19; image 01 retains the previously noted small cyan/black water spot. Independent stage-tensor correctness remains **UNVERIFIED**. | Compare CLIP/UNet/VAE stage tensors with independent expected values and investigate/optimize the measured performance gap; revisit images 01 and 19 if the model or runner changes |
| 3 | Main Debian llama.cpp CPU/GPU/HTP qualification | CPU/Vulkan known-answer pass. One-token greedy Qwen2.5 1.5B tests still show a wrong token with HMX matmul and with flash attention enabled under the prior default selection; HVX-only matmul with flash attention off returns `4`. Exact HVX `MUL_MAT` operator run completed **1,389/1,389 tests successfully**. HMX-selected `MUL_MAT` has 529 infinite-error failures. Explicit `GGML_HEXAGON_FA_SELECT=1` (HVX attention) plus `GGML_HEXAGON_MM_SELECT=1` completed the `FLASH_ATTN_EXT` suite: 5,332 unique cases, 2,593 passed, 2,732 unsupported, and 7 finite numerical-error failures; a filtered rerun reproduced all seven. The earlier default-attention-selection run had 1,848 `inf` failures in its 120 s partial log. HTP remains experimental; flash attention stays disabled in the launcher. Exact package run `38560288558` was isolated-installed; SmolLM2-135M returned `2 + 2 = 4`, 31/31 layers were on HTP0, and bounded cancellation closed the session cleanly. Metadata-corrected build `38562008524` passed; runtime files match the tested archive. On 2026-11-06, speculative decoding with a Vulkan draft reduced the tested Qwen2.5 1.5B HTP generation rate from 19.5 tok/s to 9.1/7.1 tok/s (draft windows 2/4), so it was not adopted. A same-prompt short probe on 2026-11-07 measured 19.6 tok/s with default HTP power mode, 19.0 with burst, 17.6 on Vulkan, and 15.9 for HTP Q4_K_M. This is only one run per setting. A separate three-run-per-backend Qwen2.5 0.5B Q4_0 probe measured median 40.8 tok/s on HTP (24/24 layers assigned) versus 27.9 on Vulkan. A later matched three-backend test (same prompt/settings, four threads, three interleaved runs) measured medians of 8.0 tok/s CPU, 24.8 Vulkan, and 46.2 HTP; all HTP broker sessions closed cleanly. This remains a short single-device small-model throughput result, not a quality/energy/sustained-use result, and does not generalize to 1.5B. These are bounded GGUF/llama.cpp results, not complete operator coverage, a QNN-compiled text model, or a supported route. | Investigate remaining HMX/attention numerical errors; test other HTP operators, failure/restart, and sustained operation before considering support |
| 4 | Repeat and sustained device qualification | 600 consecutive 720p/16-sample EEVEE frames completed on SM8735 with thermal status 0 (2026-10-14); packaged CPU and Vulkan extensions each passed three live-generation SIGINT/clean-exit samples and fresh known-answer restarts. Exact HTP package run `38560288558` passed bounded SIGINT and clean `closeSession [0, 0]`. Separate QNN SD1.5 image soak completed 25/25 generations in 17m36s, with a 29.76 s median runner time and recorded thermal samples; this is one experimental mixed CPU/HTP image workload, not a general NPU stability qualification. Failure/restart behavior and broad sustained CPU/NPU stability remain open. No automatic CPU fallback is configured. | Qualify failure/restart behavior and sustained CPU/NPU behavior across supported paths |
| 5 | Reusable GitHub artifacts | Fresh ARM64 Vulkan build and ABI audit passed in run `38521164812`; its exact archive passed isolated install and CPU/Adreno Vulkan known-answer checks. HTP artifact run `38560288558` passed checksum, safe-path inspection, isolated installation, known-answer HTP0 execution, and bounded cancellation. Metadata-corrected build `38562008524` passed; its checksum-verified archive differs from the device-tested runtime payload only in README/manifest metadata, adding `libcdsprpc.so` and `libfastrpc-dev` dependency inventory. On 2026-11-07, upstream Mesa 27.0.0 Debian Trixie ARM64 archive SHA-256 matched the release page; staged driver `ldd -r` resolved, and Vulkan enumeration plus Zink GLX succeeded on Adreno 825. Three interleaved Qwen2.5 0.5B Vulkan runs measured a 27.2 tok/s median with staged 27.0 versus 26.6 with installed 26.3. On 2026-11-07, the exact GPU installer phase then extracted the pinned archive in a separate clean Debian 13 PRoot guest; its loader diversion, Mesa package holds, driver ABI, Adreno 825 Vulkan enumeration and X11 Zink GLX all passed. The guest and state were isolated from the active Debian installation. The exact source-tag license bundle is now checksum-pinned in the package and the live Debian updater installed and verified it beside Turnip 27.0.0 (`Mesa 27.0.0-devel`, git `6f90e92dfdacc4759d8e9ccb328805d0f0b4439b`; driver SHA-256 `c9333136d9818fa91244d506ac17635988199e337485bd0fff4b0f1aeda6c895`). HTP remains experimental. | Broader transitive-license and exact binary-to-source component mapping review remain open. Keep correctness and compatibility gates separate |
| 6 | Extension installation and complete guides | PARTIAL: checksum-verified CPU + Vulkan and experimental HTP llama.cpp extensions remain available; HTP is SM8735/V73-specific and unsupported. Merged PR #59 adds the pinned stable-diffusion.cpp CPU/Vulkan extension, fresh-install selection/runtime packages, doctor checks, ABI/license audit and bilingual guides. ARM64 build/ABI audit passed in run `42295461009` (11 notice hashes). On Adreno 825, tiled Vulkan 512×512/10-step generation completed in 101.9s; untiled 512×512 lost the device during VAE decode. CPU 256×256 output remained severely blocky after 20 steps (391.7s), so CPU image quality is unqualified and is not a release blocker for the Vulkan route. Public prerelease was published by workflow run `42303285336`; archive SHA-256 is `64a2761e680f0791eba476a24f476533c9ae35989d4ab6bbe2ecda26d0d9f336`. `ternux extension install stable-diffusion` checksum-verified and installed it under `/home/ternux/.local/opt/ternux-extensions/stable-diffusion`; doctor reports the extension OK. The installed binary generated a coherent 512×512/10-step image directly from the user model in 92.91s with tiled Vulkan VAE. CPU image quality remains unqualified and is not claimed as supported. The real `tnx_phase_extras ternux stable-diffusion` optional workload phase then completed in the existing Debian guest and doctor still reported the extension OK (30 OK, 0 failed, one pre-existing experimental HTP warning); `libgomp1` and `libvulkan1` were already current, so this does not prove dependency provisioning on a clean guest. QNN SD1.5 remains a research route. Details and checksums: [SD CPU/Vulkan handoff](../handoffs/stable-diffusion-cpu-vulkan-qualification-2026-11-07.md). | Live managed install, repair, removal, reinstall, checksum verification, doctor detection, and the actual optional workload phase pass on the existing Debian guest; model weights stayed outside the extension path. Verify clean fresh-install selection/dependency provisioning, cancellation/restart, sustained use, and broader device/model coverage; do not claim CPU image quality |
| 7 | CLI and installation screen polish | Existing main CI reports for the latest source are green. The current feature branch passes focused tests 107/107, Bats 72/72, and installer UI rendering 33/33. On the connected 25053RT47C phone, installed `ternux doctor --json` reports 27 OK, 0 warnings/failures, including `zink Vulkan 1.4 (Adreno 825, MESA_TURNIP)`; graphics doctor reports 8/8 checks. A source fix passes `--shared-tmp` so Debian can see the Termux:X11 socket. On 2026-11-07, the actual `org.pulseaudio.pavucontrol.desktop` entry was launched with `gtk-launch`: the global dark theme rendered, Playback controls populated, and Input Devices showed the OpenSL ES input. The Xfce process environment had `MESA_LOADER_DRIVER_OVERRIDE=zink` and no global `GALLIUM_DRIVER`. The installed VLC player also rendered its playback controls in the live X11 capture. Exact upgraded-package test, typing/welcome/error states, and owner usability review remain open. | Re-run docs/site gates after current edits; install exact CI package and owner-review remaining typing, welcome, and error-state behavior |
| 8 | Signed Termux APT distribution (`pkg install ternux`) | Local package and signed-index fixture checks pass; latest published website APT endpoint still has no v2 InRelease. On the phone, Termux and Termux:API both have RECORD_AUDIO granted. A bounded one-second Termux:API Opus recording produced a valid 16 kHz mono Ogg file, then the temporary file was removed. Separately, the Debian guest received 119,972 bytes from the PulseAudio `Ternux_Microphone` OpenSL source (16 kHz mono; peak 1,144, RMS 84.2); after the client exited the source returned to SUSPENDED. The Volume Control input meter opens a source-output while its window is open; closing it removes all source-outputs and returns `Ternux_Microphone` to IDLE. The idle desktop does not keep this input stream open. This verifies on-demand desktop input over PulseAudio, not a live Termux:API-to-guest stream. The signed v2 repository is still unpublished; hosted clean install/upgrade are unverified. | Keep the API-vs-OpenSL boundary explicit; qualify owner-visible microphone controls and exact installed artifact; after all other gates close, publish only through the signed release workflow and verify hosted clean install/upgrade
| 9 | Model/accelerator artifact coverage and optional installation | OPEN. Current prerelease assets cover CPU + Vulkan llama.cpp and experimental SM8735/V73 HTP llama.cpp. Merged PR #59 adds the CPU/Vulkan Stable Diffusion extension. The public optional prerelease is build/ABI checked and checksum-verified by the real Ternux extension manager; doctor detects it. The installed binary generated a coherent Adreno 825 512×512/10-step tiled-Vulkan image in 92.91s. CPU image quality is explicitly unqualified and is not a blocker for the Vulkan route. The actual optional workload phase (`tnx_phase_extras ternux stable-diffusion`) completed on the existing Debian guest, followed by a doctor pass (30 OK, 0 failed, one pre-existing experimental HTP warning); its `libgomp1` and `libvulkan1` dependencies were already installed, so clean-guest dependency provisioning is still unverified. Managed repair/remove/reinstall pass on the active guest without changing model files. Fresh-install menu selection, clean dependency provisioning, cancellation/restart, and broader sustained/device coverage remain open. The SD1.5 Q8_0 GGUF test model is user-provided at `/sdcard/Llms/ternux-v2-validation/stable-diffusion-v1-5-pruned-emaonly-Q8_0.gguf` (1,763,578,176 bytes; SHA-256 `d0555243938c62faeefb4ac93f6c7a053ad373a4290c5256bce229aeb193bf94`). The QNN SD1.5 runner/helper are not packaged; independent stage-tensor correctness, quality and performance remain open. | For every CPU/GPU/NPU LLM and Stable Diffusion route intended for v2, provide a versioned, checksummed, licensed tool artifact; install it through `ternux extension install` or an opt-in installer step; verify clean fresh-install selection/dependency provisioning, post-install install/remove/repair, and a real target-device workload. Keep model weights and proprietary runtimes external unless redistribution is explicitly licensed; document user-provided paths and evidence limits |
| 10 | Complete Ternux version release | HELD until all prior gates close. Release criteria include independent QNN model-stage correctness and performance target, HTP numerical failures/operator coverage, broad sustained/failure-restart qualification, dependency-license review, model/accelerator artifact coverage and fresh-install selection, owner visual review, plus hosted signed APT install/upgrade. Stable support claims must exclude unqualified HTP/QNN routes. | Close and re-evaluate every preceding gate, then repeat installed-artifact, public repository, website and documentation audits |

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
`mesa-27.0.0-devel-20261025` and verifies archive SHA-256
`b711d1d9ab5537ee9085da8896dfe2115e791b33aa317fe37538f276c967d687` before
installation. On 2026-11-07, the exact archive passed staged Vulkan and Zink
checks on Adreno 825; its short Vulkan generation median was 27.2 tok/s versus
26.6 tok/s on the installed 26.3 driver. The driver remains an upstream binary
dependency rather than a Ternux-built artifact. On 2026-11-07, the actual `tnx_phase_gpu zink` installer phase extracted this exact pin
in a separate clean Debian 13 PRoot guest. Its dependency loader, dpkg diversion, Mesa
package holds, `ldd -r`, Adreno 825 Vulkan enumeration, and X11 Zink GLX all passed.
The original Termux Debian guest was not changed. The updater can rerun and refresh its
stored URL without a state-write error; that case is covered by the focused regression
test. Inspection of the checksum-verified archive found no `COPYING`, `LICENSE`,
`NOTICE`, or Debian copyright member. Ternux now includes the license overview and all
license texts from the exact matching Mesa source commit in
`lib/licenses/mesa-27.0.0-devel-20261025/`; the GPU phase installs and checksum-checks
them at `/usr/local/share/doc/ternux/mesa-27.0.0-devel-20261025/`. On 2026-11-07, the
live Debian updater installed Mesa 27.0.0 and verified every notice hash. The exact
binary-to-source component mapping and wider transitive license inventory remain open;
the bundle does not claim every source-tree license applies to the extracted binary.

This has a consequence for order 5. Clean-device install verification of the
Vulkan path cannot pass while the driver it needs is absent from a clean device.
The pinned input and clean-guest phase test close the mutable-download and extraction
checks for this dependency. The exact upstream notice files are now preserved and
verified; the wider transitive license review remains open. Order 5's Ternux release
artifact and install-package gates remain open.

[Graphics persistence](GRAPHICS-PERSISTENCE.html) documents the apt-safe install
layout. It does not replace clean-device qualification or the reusable artifact
gate.

On 2026-11-07, an X11 visual check found that accelerated Zink `glxgears` renders cleanly
full-screen, while its 300×300 window repeatedly retains red geometry fragments at a fixed
right-edge location, including after the Mesa 27.0.0 Turnip update. The same live display
rendered an Adreno 825 Vulkan `vkcube` cleanly. This is an observed windowed GLX artifact;
its cause and impact on other applications remain unqualified.

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
