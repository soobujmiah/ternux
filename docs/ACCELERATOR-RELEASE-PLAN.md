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
| 2 | Existing QNN picture model, kept in place | CLIP CPU, UNet/VAE HTP graph execution and fixed-seed SD1.5 generation ran on SM8735. The 25-image soak completed 25/25 (17m36s outer wall); median/mean was 29.76/31.12 s per image and HTP UNet median/mean 15.96/17.03 s per 20 steps. Three instrumented follow-up images took 30.797–31.122 s. One 30.797 s profile measured 7.275 s to stream/hash/seal the 880,827,736-byte UNet member to memfd and 17.015 s across 40 serial HTP requests. CLIP ran on CPU and UNet/VAE on QNN HTP. The model archive `/sdcard/Llms/AbsoluteReality_qnn2.28_8gen2.zip` is present and its SHA-256 matches the recorded soak report. Same-seed output repeated exactly. On 2026-11-08, a new standard-library CLIP tokenizer matched the archive known answer `a cat` → `[320, 2368]`; two 77×768 input tensors had identical SHA-256 `c224f03dbd0fb9abed0dd6747f8607d1059da847e74bf6fab02c34c65c59ccb3`. Native MNN 3.6.1 CPU execution produced finite, exact-repeat CLIP hidden states for both default prompts. Re-running the 20-step native-CLIP + QNN HTP UNet/VAE path with seed 20261014 completed in 34.21 s and exactly reproduced image SHA-256 `1a13957f5cb65132d98fc212756bdcf8d8b959d69feba84902a9314036764fc3`; visual review shows the previously known small cyan/black water spot remains. This is one repeatability/visual run, not an independent stage-tensor oracle or a performance improvement; stage correctness remains **UNVERIFIED**. On 2026-11-06, images 02–25 were reviewed individually at 512×512: coherent scenes overall, with a tiny dark mark at the top edge of image 19; image 01 retains the previously noted small cyan/black water spot. Independent stage-tensor correctness remains **UNVERIFIED**. | Compare CLIP/UNet/VAE stage tensors with independent expected values and investigate/optimize the measured performance gap; revisit images 01 and 19 if the model or runner changes |
| 3 | Main Debian llama.cpp CPU/GPU/HTP qualification | CPU/Vulkan known-answer pass. On 2026-11-07, the installed managed llama.cpp b11582 extension also passed `2 + 2 = 4` on CPU and Adreno 825 Vulkan with the existing `/sdcard/Llms/qwen2.5-0.5b-instruct-q4_0.gguf`; verbose Vulkan logs confirmed 25/25 layers offloaded. Three-repeat same-binary benchmarking (pp128/tg64, two threads) measured CPU 133.09 ± 1.39 / 13.15 ± 0.08 tok/s and Vulkan 360.96 ± 5.53 / 33.94 ± 0.52 tok/s. `llama-bench` identifies this file as `qwen2 1B Q4_0`, 630.17M parameters, despite its filename. These checks add exact installed-artifact/model evidence, not sustained or broad quality qualification. Full capture: [device benchmark evidence](../guides/device-benchmark-evidence.md#2026-11-07-managed-extension-cpuvulkan-known-answer-check-qwen-gguf). One-token greedy Qwen2.5 1.5B tests still show a wrong token with HMX matmul and with flash attention enabled under the prior default selection; HVX-only matmul with flash attention off returns `4`. Exact HVX `MUL_MAT` operator run completed **1,389/1,389 tests successfully**. HMX-selected `MUL_MAT` has 529 infinite-error failures. Explicit `GGML_HEXAGON_FA_SELECT=1` (HVX attention) plus `GGML_HEXAGON_MM_SELECT=1` completed the `FLASH_ATTN_EXT` suite: 5,332 unique cases, 2,593 passed, 2,732 unsupported, and 7 finite numerical-error failures; a filtered rerun reproduced all seven. The earlier default-attention-selection run had 1,848 `inf` failures in its 120 s partial log. HTP remains experimental; flash attention stays disabled in the launcher. Exact package run `38560288558` was isolated-installed; SmolLM2-135M returned `2 + 2 = 4`, 31/31 layers were on HTP0, and bounded cancellation closed the session cleanly. Metadata-corrected build `38562008524` passed; runtime files match the tested archive. On 2026-11-06, speculative decoding with a Vulkan draft reduced the tested Qwen2.5 1.5B HTP generation rate from 19.5 tok/s to 9.1/7.1 tok/s (draft windows 2/4), so it was not adopted. A same-prompt short probe on 2026-11-07 measured 19.6 tok/s with default HTP power mode, 19.0 with burst, 17.6 on Vulkan, and 15.9 for HTP Q4_K_M. This is only one run per setting. A separate three-run-per-backend probe of the file named Qwen2.5 0.5B Q4_0 measured median 40.8 tok/s on HTP (24/24 layers assigned) versus 27.9 on Vulkan. llama.cpp reports GGUF name `qwen2.5-0.5b-instruct` but runtime model type 1B/630.17M parameters, so reconcile nominal size with model provenance before generalizing the result. A later matched three-backend test (same prompt/settings, four threads, three interleaved runs) measured medians of 8.0 tok/s CPU, 24.8 Vulkan, and 46.2 HTP; all HTP broker sessions closed cleanly. A same-binary llama-bench repeat on 2026-11-07, with the same Qwen2.5 0.5B-named GGUF file, four threads, pp128/tg64, and three repetitions per setting, measured CPU (`-ngl 0`) at 145.11 ± 12.42 prompt tok/s and 12.73 ± 0.75 generation tok/s; Adreno 825 Vulkan (`-ngl 99`) measured 360.55 ± 2.12 prompt tok/s and 33.73 ± 0.59 generation tok/s. This is a separate short benchmark method from the matched generation runs above. Full capture and commands: [device benchmark evidence](../guides/device-benchmark-evidence.md#2026-11-07-same-build-cpuvulkan-throughput-repeat-qwen25-05b-q4_0). A separate 2026-11-07 CPU/Vulkan benchmark on the existing Qwen2.5 1.5B Q4_K_M model (`/sdcard/LAI/models/qwen2.5-1.5b-instruct-q4_k_m.gguf`; SHA-256 `6a1a2eb6d15622bf3c96857206351ba97e1af16c30d7a74ee38970e434e9407e`) measured three-run means of 6.11 ± 0.87 generation tok/s on CPU and 17.32 ± 0.26 tok/s on Adreno Vulkan (four threads, 128 prompt tokens, 64 generated tokens). Both routes returned `4` in a deterministic arithmetic known-answer run. Detailed results: [device benchmark evidence](../guides/device-benchmark-evidence.md#2026-11-07-qwen25-15b-q4_k_m-cpuvulkan-benchmark). A separate matched workload on the same existing Qwen2.5 1.5B Q4_K_M model returned answer 4 across three interleaved CPU/Vulkan/HTP rounds: median generation was 7.6 tok/s CPU, 18.2 tok/s Adreno 825 Vulkan, and 18.9 tok/s managed HTP. CPU/Vulkan shared b11582; HTP used a separate build. Each HTP session closed cleanly. This is a bounded workload comparison, not a same-binary, thermal, energy or broad quality result; details and commands are in the [matched benchmark record](../guides/device-benchmark-evidence.md#2026-11-07-matched-qwen25-15b-cpuvulkanhtp-generation). A three-run HTP thread screen for the same 1.5B model measured medians 18.9/18.2/18.4 tok/s at generation thread counts 1/2/4 with batch threads fixed at 4; fixed sample order and no CPU-use measurement make this inconclusive, so no default recommendation is made. [Thread-scaling evidence](../guides/device-benchmark-evidence.md#2026-11-07-htp-cpu-thread-scaling). The installed production HTP HVX route also completed a ten-chunk Wikitext-2 PPL screen on both existing Qwen models: CPU vs HTP was 19.0657 vs 19.0715 for Q4_0 (0.03% relative difference) and 12.1464 vs 12.1015 for 1.5B Q4_K_M (0.37%). This supports model-level numerical agreement only for these two exact screening workloads; operator, sustained and broader quality gates remain open. [Production HTP PPL evidence](../guides/device-benchmark-evidence.md#2026-11-07-installed-htp-hvx-perplexity-screen). A separate, disposable CI artifact from unmerged llama.cpp PR #29740 (commit `08c83734f9c5c3b497e98b96f1a380f5a6084468`, SHA-256 `52877aad044c6da3f701d0230fde86520ce26066a412118bfb93e1a6f238de0a`) was tested in the isolated Debian guest. The SM8735 HTP V73 probe detected no FP16 HMX and selected integer HMX; Qwen2.5 0.5B-named Q4_0 produced a response with all 25/25 layers on HTP0. Three matched cold-start runs measured 48.5/47.3/49.7 tok/s (median 48.5) and each CDSP session closed cleanly. `MUL_MAT` passed 1,588/1,588 and `GATED_DELTA_NET` 43/43; the full and a supported-size `FLASH_ATTN_EXT` test both aborted with DSP `INTERNAL-ERROR` (child signal 6), although the broker closed each session cleanly. The artifact did not change the production extension. A 2026-11-07 CPU-reference perplexity screen on the same SM8735 candidate and existing Qwen GGUFs measured CPU vs integer-HMX PPL of 19.1083 vs 19.0430 for the 630.17M-parameter Q4_0 file (0.34% relative difference) and 12.1935 vs 12.1015 for the Qwen 1.5B Q4_K_M file (0.75%); each used ten 512-token Wikitext-2 chunks, and both HTP sessions closed cleanly. This supports numerical agreement for those exact screening workloads only. A separate candidate run on the Qwen2.5 1.5B Q4_K_M model returned `4` for `2 + 2` at 18.7 tok/s and closed CDSP cleanly. The candidate remains unmerged, its `FLASH_ATTN_EXT` path aborted on SM8735, and it is not release-qualified. Full method/results: [device benchmark evidence](../guides/device-benchmark-evidence.md#2026-11-07-sm8735-integer-hmx-model-perplexity-screen). Full record: [device benchmark evidence](../guides/device-benchmark-evidence.md#2026-11-07-sm8735-integer-hmx-candidate-probe). These remain short single-device throughput results, not quality/energy/sustained-use results. They are bounded GGUF/llama.cpp results, not complete operator coverage, a QNN-compiled text model, or a supported route. | Investigate remaining HMX/attention numerical errors; test other HTP operators, failure/restart, and sustained operation before considering support |
| 4 | Repeat and sustained device qualification | 600 consecutive 720p/16-sample EEVEE frames completed on SM8735 with thermal status 0 (2026-10-14); packaged CPU and Vulkan extensions each passed three live-generation SIGINT/clean-exit samples and fresh known-answer restarts. Exact HTP package run `38560288558` passed bounded SIGINT and clean `closeSession [0, 0]`. Separate QNN SD1.5 image soak completed 25/25 generations in 17m36s, with a 29.76 s median runner time and recorded thermal samples; this is one experimental mixed CPU/HTP image workload, not a general NPU stability qualification. On 2026-11-07, three independent cold-start HTP runs with the existing Qwen2.5 1.5B Q4_K_M model each returned `4` at 22.0–22.3 tok/s; all broker children exited 0 and all CDSP sessions closed with `[0, 0]`. Five additional cold-start checks on the existing Qwen2.5 0.5B-named Q4_0 file also returned `4` and closed cleanly. These short reopen checks pass for those exact workloads. A separate 2026-11-07 follow-up added five independent Qwen2.5 1.5B HTP cold starts (all began with answer 4, 19.6–19.9 tok/s, clean child/CDSP close) and one continuous 2,048-token HTP session (136 s, 15.5 tok/s, clean close). This is bounded one-model session evidence, not a thermal soak or broad CPU/NPU stability qualification. A further Qwen2.5 1.5B HTP run requested 4,096 tokens but was intentionally SIGINT-stopped when battery temperature reached 43.0 °C (43.3 °C immediately after stop); partial output measured 12.9 tok/s, broker child exited 0 on cancel signal 2, and CDSP closed `[0, 0]`. Its repetitive, factually wrong text was excluded from quality evidence, and system thermal zones were not identified by hardware. One controlled cancel-then-reopen sequence then returned `4` at 16.7 tok/s with child exit 0 and CDSP `[0, 0]`. A single-turn chat-format France-capital prompt returned `Paris` on CPU/Vulkan/HTP; its 3.3/16.6/15.5 tok/s readings are a short no-warmup spot check, not a backend ranking or broad quality result. Failure recovery beyond these clean paths and broad sustained CPU/NPU stability remain open. No automatic CPU fallback is configured. | Qualify failure/restart behavior and sustained CPU/NPU behavior across supported paths |
| 5 | Reusable GitHub artifacts | Fresh ARM64 Vulkan build and ABI audit passed in run `38521164812`; its exact archive passed isolated install and CPU/Adreno Vulkan known-answer checks. HTP artifact run `38560288558` passed checksum, safe-path inspection, isolated installation, known-answer HTP0 execution, and bounded cancellation. Metadata-corrected build `38562008524` passed; its checksum-verified archive differs from the device-tested runtime payload only in README/manifest metadata, adding `libcdsprpc.so` and `libfastrpc-dev` dependency inventory. On 2026-11-07, upstream Mesa 27.0.0 Debian Trixie ARM64 archive SHA-256 matched the release page; staged driver `ldd -r` resolved, and Vulkan enumeration plus Zink GLX succeeded on Adreno 825. Three interleaved Qwen2.5 0.5B Vulkan runs measured a 27.2 tok/s median with staged 27.0 versus 26.6 with installed 26.3. On 2026-11-07, the exact GPU installer phase then extracted the pinned archive in a separate clean Debian 13 PRoot guest; its loader diversion, Mesa package holds, driver ABI, Adreno 825 Vulkan enumeration and X11 Zink GLX all passed. The guest and state were isolated from the active Debian installation. The exact source-tag license bundle is now checksum-pinned in the package and the live Debian updater installed and verified it beside Turnip 27.0.0 (`Mesa 27.0.0-devel`, git `6f90e92dfdacc4759d8e9ccb328805d0f0b4439b`; driver SHA-256 `c9333136d9818fa91244d506ac17635988199e337485bd0fff4b0f1aeda6c895`). HTP remains experimental. | The llama.cpp CPU/Vulkan artifact workflow now bundles 11 tracked upstream LICENSE/LICENCE, COPYING, NOTICE, COPYRIGHT, AUTHORS, PATENTS, and UNLICENSE texts with an index and per-file SHA-256 manifest. Run `42410053376` passed the ARM64 build and ABI audit for 69 ELF files; all package dependencies resolved and GLIBC 2.38 remained the maximum. The audit verified notice paths, hashes, and archive membership. The public CPU/Vulkan prerelease archive was refreshed and downloaded again; its SHA-256 is `bf5e80362620c52e43837949953c00aee6d80be5d87fc45f44911d8624cc3871`. A file-by-file `COMPONENTS.json` generator now records hashes, upstream source modules, exact llama.cpp/Ternux commits, build options, runtime dependencies, and the bundled notice inventory. It mapped all 115 files in the current published archive when checked against its recorded upstream commit; the existing public archive has not yet been refreshed with this map. PR candidate run [42433612276](https://github.com/soobujmiah/ternux/actions/runs/42433612276) completed with read-only repository access and uploaded the exact ARM64 archive (SHA-256 `b72413d6a1ac928c6fb7a89062673e76e2ec6a19c1a72c14fc58c8ad3c319aa8`). Its `COMPONENTS.json` maps and hashes all 115 packaged files; the downloaded archive passed the ABI/license audit for 69 AArch64 ELF files, all dependencies resolved, maximum GLIBC 2.38, and `$ORIGIN/../lib` RUNPATH. The separate public publisher job was skipped; the public prerelease remains unchanged. PRs build/upload candidates using read-only repository access. Public release updates require explicit workflow-dispatch opt-in on `main` and only that separate job receives release-write permission. This candidate is not a public release asset. Keep correctness and compatibility gates separate |
| 6 | Extension installation and complete guides | PARTIAL: the published CPU + Vulkan and experimental SM8735/V73 HTP llama.cpp prerelease assets exist, but the public HTP archive is missing the broker/launcher files required by the current manager and cannot be installed through it. The latest PR candidate passes a bounded SM8735 known-answer and interrupt/reopen check after direct staging; it has not replaced the public asset. HTP remains experimental and unsupported. Merged PR #59 adds the pinned stable-diffusion.cpp CPU/Vulkan extension, fresh-install selection/runtime packages, doctor checks, ABI/license audit and bilingual guides. ARM64 build/ABI audit passed in run `42295461009` (11 notice hashes). Latest branch build `42425110113` also passed its ARM64 build/ABI audit and verified all 11 license notices; CI artifact `ternux-stable-diffusion-vulkan-linux-arm64-master-1053-candidate.zip` is 27,026,209 bytes (Actions artifact ID `13595256940`, archive SHA-256 `82a71359c611625ba68546f7cb06f3691ea37a053810eba28723e2f56e0b3fd8`). This is an Actions candidate artifact, not a published release asset. On Adreno 825, tiled Vulkan 512×512/10-step generation completed in 101.9s; untiled 512×512 lost the device during VAE decode. CPU 256×256 output remained severely blocky after 20 steps (391.7s), so CPU image quality is unqualified and is not a release blocker for the Vulkan route. Public prerelease was published by workflow run `42303285336`; archive SHA-256 is `64a2761e680f0791eba476a24f476533c9ae35989d4ab6bbe2ecda26d0d9f336`. `ternux extension install stable-diffusion` checksum-verified and installed it under `/home/ternux/.local/opt/ternux-extensions/stable-diffusion`; doctor reports the extension OK. The installed binary generated a coherent 512×512/10-step image directly from the user model in 92.91s with tiled Vulkan VAE. CPU image quality remains unqualified and is not claimed as supported. The real `tnx_phase_extras ternux stable-diffusion` optional workload phase then completed in the existing Debian guest and doctor still reported the extension OK (30 OK, 0 failed, one pre-existing experimental HTP warning); the same actual optional phase was then run in a separate clean Debian 13 Trixie PRoot guest with those dependencies absent. It installed `libgomp1`/`libvulkan1`, checksum-verified and installed the public artifact, and the clean-guest doctor extension check returned 1 OK, 0 warnings, 0 failures; `sd-cli --help` ran and `ldd -r` resolved all dependencies. The exact GPU phase then installed the pinned Turnip archive/notices; Vulkan enumerated Adreno 825 as GPU0, and the existing Q8_0 model produced a valid 512×512/10-step tiled-Vulkan image in 91.18s. Its SHA-256 exactly matches the previously reviewed same-seed output. This closes the clean-guest GPU workload gate for this model/device, but not fresh X11 desktop or menu selection. QNN SD1.5 remains a research route. Details and checksums: [SD CPU/Vulkan handoff](../handoffs/stable-diffusion-cpu-vulkan-qualification-2026-11-07.md). | Live managed install, repair, removal, reinstall, checksum verification, doctor detection, and the actual optional workload phase pass on the existing Debian guest; model weights stayed outside the extension path. Verify fresh-install menu selection, clean-guest X11 desktop, cancellation/restart, sustained use, and broader device/model coverage; do not claim CPU image quality |
| 7 | CLI and installation screen polish | On the earlier code head `8c2798df58b0d63ff10626c27e3a1ae5b7c51e03`, the required PR checks passed; those historical run IDs are retained below. Runs: [Validate 42486551774](https://github.com/soobujmiah/ternux/actions/runs/42486551774), [APT package 42486551766](https://github.com/soobujmiah/ternux/actions/runs/42486551766), [llama.cpp 42486551788](https://github.com/soobujmiah/ternux/actions/runs/42486551788), [Stable Diffusion 42486551833](https://github.com/soobujmiah/ternux/actions/runs/42486551833), and [HTP candidate 42486551768](https://github.com/soobujmiah/ternux/actions/runs/42486551768); optional preview publication was skipped. The code-bearing commit `b49378574f65b37becfe34c4e3d2071096e123bb` passed all required checks: [Validate 42489951685](https://github.com/soobujmiah/ternux/actions/runs/42489951685), [APT package 42489951723](https://github.com/soobujmiah/ternux/actions/runs/42489951723), [llama.cpp CPU/Vulkan 42489951725](https://github.com/soobujmiah/ternux/actions/runs/42489951725), [Stable Diffusion 42489951743](https://github.com/soobujmiah/ternux/actions/runs/42489951743), [HTP candidate 42489951714](https://github.com/soobujmiah/ternux/actions/runs/42489951714), [repository contract 42489951643](https://github.com/soobujmiah/ternux/actions/runs/42489951643), and [knowledge sync 42489951732](https://github.com/soobujmiah/ternux/actions/runs/42489951732). The CI-only candidate artifacts are APT `ternux-apt-unsigned-ci-c9dbad961869962bfd22cf8151f22a6055d59d16` (metadata ID `13620503151`), Stable Diffusion `ternux-stable-diffusion-vulkan-linux-arm64-master-1053-candidate` (`13621820236`), and HTP `ternux-llama-htp-sm8735-integer-hmx-v73-candidate` (`13621313756`). These are build/package evidence only, not device qualification; exact-artifact installation still needs owner-mediated handoff. The HTP result is build/package evidence, not device qualification. On the connected 25053RT47C phone, current-checkout `bin/ternux doctor --json` reports 31 OK, 0 warnings/failures, including `zink Vulkan 1.4 (Adreno 825, MESA_TURNIP)`; graphics doctor reports 8/8 checks. The doctor now includes the managed extension `lib/` directory in its `ldd` probe, avoiding false missing-library warnings for bundled HTP libraries. The unsigned CI package from [workflow run 42339235853](https://github.com/soobujmiah/ternux/actions/runs/42339235853), project commit `b3a0f894d5f531bf625500894de87160980596c4`, has SHA-256 `30541cddf114a201f66c5e67ff121e4d8cdb1bb2c830275241980bc99f07f9de`. Isolated extraction passed `--version`, `guides`, and `bash -n` for packaged shell scripts; its `doctor --json` ran against the live phone/guest and reported 31 OK, 0 warnings, 0 failures. This does not replace installing through APT or reopening the GUI from that package. A source fix passes `--shared-tmp` so Debian can see the Termux:X11 socket. On 2026-11-07, the actual `org.pulseaudio.pavucontrol.desktop` entry was launched with `gtk-launch`: the global dark theme rendered, Playback controls populated, and Input Devices showed the OpenSL ES input. The Xfce process environment had `MESA_LOADER_DRIVER_OVERRIDE=zink` and no global `GALLIUM_DRIVER`. The installed VLC player also rendered its playback controls in the live X11 capture. After installing the exact main CI Ternux package, I selected Volume Control through Xfce Applications → Multimedia for three separate open/close cycles on the active 752×1155 Termux:X11 display. All three runs rendered the dark theme and OpenSL ES Output controls legibly in a 500×400 window fully within the screen; the third run also showed the OpenSL ES Input source in the Input Devices tab. I closed only each test instance; the PulseAudio OpenSL sink and microphone source returned to IDLE after the last close, while Xfce, Termux:X11 and PulseAudio remained running. This verifies repeated menu launches on the existing desktop; restarting the desktop through the upgraded Ternux launcher and owner review remain open. On 2026-11-07, the exact main-branch CI package from commit `550bdf8e02424d76f8c32a88b463477ef6bb4645` (workflow run [42344799168](https://github.com/soobujmiah/ternux/actions/runs/42344799168), SHA-256 `00be22a9fe00bae3b96ef6fbe228fd315101abc3c40ad9a092c177eaffb5c2aa`) was installed over the existing 2.0.0 package with Termux `apt-get` using the local CI `.deb`. `ternux --version`, `ternux guides`, and live `ternux doctor --json` passed; doctor reported 31 OK, 0 warnings, 0 failures, including Adreno 825 / Zink / Turnip. This is a local-artifact apt upgrade, not an install from the hosted signed repository. On 2026-11-07, a live X11 visual check captured the 500×400 Volume Control window on the 752×1630 display: dark-theme Output Devices showed OpenSL ES Output and Input Devices showed OpenSL ES Input, both legibly. After closing only the test process, there were no source-output streams and PulseAudio input/output returned to IDLE; Xfce, Termux:X11 and PulseAudio remained active. This used the existing desktop and does not verify restart through the upgraded launcher. On 2026-11-08, the GTK 4 theme's invalid Adwaita resource import was replaced with the bundled Default dark stylesheet; the live pavucontrol launch emitted no theme parser error and its Output Devices controls rendered in the captured X11 view. This was a direct launch check; repeated Xfce menu-launch behavior and owner review remain open. On 2026-11-08, the active Xfce D-Bus settings reported Ternux GTK, icon and Xfwm themes with compositing off on one 752×1630 `builtin` monitor. Live asset hashes matched the checkout for 195 icon files, 55 theme files and all 15 wallpapers (the guest also has a generated icon cache). The active `05-quantum-grid.svg` selection stayed in place; the broken inactive monitor1 wallpaper path was changed to valid Aurora artwork. Launcher v15 now targets `monitorbuiltin` on fresh setup and migrates only an empty, missing or Debian-stock wallpaper while preserving readable custom wallpapers. The running desktop was not restarted. On 2026-11-08, I built the current source as the local Termux package and reinstalled it with `apt-get --reinstall`; package SHA-256 is `9df2a201ac410d1fce8810753f354115c7e319369bac0f6ba31675ef79c12807`, and the installed CLI hash matches the archive. `ternux --version`, `ternux guides`, `doctor --json` (29 OK, 0 warnings, 0 failures), and `verify --json` passed; the live desktop stayed running. This is source-built package evidence, not the exact CI artifact or hosted-repository install. A subsequent live-source `ternux info --json` returned Termux `0.119.0-beta.3` and Adreno 825/Turnip in 3.0 seconds; renderer probing now has a five-second bound and an ICD-based fallback. Termux version detection prefers Android app metadata before package-database lookup. Updated focused tests passed 122/122; docs passed 3,007 assertions, 309 internal links, and 19 bilingual pairs. The current source-built 2.0.0 APT package was also reinstalled locally with Termux APT (package SHA-256 `0cb55b9cefe187c733ad82f205ecc134c1f99e18c7e654b1426382db95f4b68d`); the installed CLI hash matched the archive, `info --json` returned the expected Termux and Adreno/Turnip data, `verify --json` passed, and the desktop stayed running. Exact-package GUI reopen, typing/welcome/error states, and owner visual review remain open. | Install/reopen the exact current CI package after the owner-mediated artifact handoff; verify launcher v15 startup and owner-review typing, welcome, and error states |
| 8 | Signed Termux APT distribution (`pkg install ternux`) | Local package and signed-index fixture checks pass; latest published website APT endpoint still has no v2 InRelease. On the phone, Termux and Termux:API both have RECORD_AUDIO granted. A bounded one-second Termux:API Opus recording produced a valid 16 kHz mono Ogg file, then the temporary file was removed. Separately, the Debian guest received 119,972 bytes from the PulseAudio `Ternux_Microphone` OpenSL source (16 kHz mono; peak 1,144, RMS 84.2); after the client exited the source returned to SUSPENDED. The Volume Control input meter opens a source-output while its window is open; closing it removes all source-outputs and returns `Ternux_Microphone` to IDLE. The idle desktop does not keep this input stream open. This verifies on-demand desktop input over PulseAudio, not a live Termux:API-to-guest stream. Signing-only workflow run [42311346876](https://github.com/soobujmiah/ternux/actions/runs/42311346876) built the exact `ternux` 2.0.0 package and signed repository, then verified `InRelease` against fingerprint `E5527F4D5B83037FF77B65AE5E894BBB81168B1D`; publish jobs were skipped. The latest non-publishing check, [run 42489816303](https://github.com/soobujmiah/ternux/actions/runs/42489816303), again built the 2.0.0 package and signed/verified the repository with the protected APT key; deployment was skipped. Termux records package version 2.0.0 as installed, but the host has no Ternux APT source configured, so this is not evidence that `pkg install` used the signed repository. The signed v2 repository is still unpublished; hosted clean install/upgrade are unverified. | Keep the API-vs-OpenSL boundary explicit; qualify owner-visible microphone controls and exact installed artifact; after all other gates close, publish only through the signed release workflow and verify hosted clean install/upgrade
| 9 | Model/accelerator artifact coverage and optional installation | OPEN. Current prerelease assets cover CPU + Vulkan llama.cpp and experimental SM8735/V73 HTP llama.cpp. The public HTP archive is stale and fails the current manager’s broker/launcher layout check; the latest PR artifact was manually staged and passed a bounded SM8735 known-answer plus interrupt/reopen check, but is not published. Merged PR #59 adds the CPU/Vulkan Stable Diffusion extension. Its public prerelease is build/ABI checked and checksum-verified by the real Ternux extension manager; doctor detects it. The installed binary generated a coherent Adreno 825 512×512/10-step tiled-Vulkan image in 92.91s. CPU image quality is explicitly unqualified and is not a blocker for the Vulkan route. The actual optional workload phase (`tnx_phase_extras ternux stable-diffusion`) completed on the existing Debian guest, followed by a doctor pass (30 OK, 0 failed, one pre-existing experimental HTP warning); clean-guest dependency provisioning and artifact install now pass: the real optional phase installed `libgomp1`/`libvulkan1` and the pinned artifact in a pristine Debian 13 Trixie guest; doctor reported the extension OK, `sd-cli --help` ran, and `ldd -r` resolved. The exact GPU phase installed the pinned Turnip archive/notices; Vulkan enumerated Adreno 825, and the user-provided Q8_0 model completed a 512×512/10-step tiled-Vulkan run in 91.18s with the same output hash as the reviewed same-seed run. A second isolated Debian 13 guest completed the real desktop phase before the GPU phase; guest doctor reported 10 OK, 0 warnings, 0 failures, and XFCE, terminal, task manager, Mousepad, pavucontrol and VLC executables were present. A private 1280×720 Xvfb session started XFCE and opened the terminal and pavucontrol windows; pavucontrol had no configured audio server and reported a 1×1 window, so this verifies startup only, not readable controls, audio, or physical Termux:X11 rendering. On 2026-11-07, an owner-authorized full managed uninstall followed by a default Zink/dashboard reinstall completed all 11/11 phases on a fresh Debian 13 guest; the separately rebuilt local `ternux` 2.0.0 `.deb` was removed/reinstalled via Termux APT without touching Codex or user models. `ternux verify --json` passed; after starting the detached desktop, status reported X11 and PulseAudio running and doctor reported 29 OK, 0 warnings, 0 failures, 2 informational checks. The owner visually confirmed the fresh first-run welcome and desktop were readable. XFCE Task Manager, Mousepad, pavucontrol and VLC are installed; fresh VLC config selects `vout=xcb_x11`; Firefox remains optional. Both managed optional extensions were installed through `ternux extension install`; the installed llama Vulkan artifact returned the known answer 4 with the existing Qwen GGUF, and the fresh Stable Diffusion Vulkan artifact completed the user-provided 512×512/10-step Q8_0 workload in 105.38s, reproducing the previously reviewed same-seed output hash. PulseAudio exposed the OpenSL ES sink and on-demand microphone source, both idle/suspended when unused. After the owner stopped and restarted Ternux, status again reported the detached desktop running (X11 and PulseAudio) and doctor remained 29 OK, 0 warnings, 0 failures, 2 informational checks; the desktop log contained only GVFS/Android bus warnings in the captured tail. An isolated PTY regression selects Stable Diffusion from the optional checklist and verifies the returned workload ID. These close the fresh managed base install, owner visual welcome/desktop check, optional manager installs and exact-artifact smoke workloads; they do not close interactive fresh-install workload selection, cancellation/restart qualification, pavucontrol's owner-visible launcher rendering, audio playback through the physical speaker, broad sustained/device coverage, or accelerator gates in orders 1–4. The available user-provided models remain external and unmodified: GGUF files are in `/sdcard/LAI/models` and `/sdcard/Llms`, including the Qwen 1.5B/0.5B models, SD1.5 Q8_0 model and QNN archive. Managed repair/remove/reinstall pass on the active guest without changing model files. Fresh-install menu selection, clean X11 desktop, cancellation/restart, and broader sustained/device coverage remain open. The SD1.5 Q8_0 GGUF test model is user-provided at `/sdcard/Llms/ternux-v2-validation/stable-diffusion-v1-5-pruned-emaonly-Q8_0.gguf` (1,763,578,176 bytes; SHA-256 `d0555243938c62faeefb4ac93f6c7a053ad373a4290c5256bce229aeb193bf94`). The QNN SD1.5 runner/helper are not packaged; independent stage-tensor correctness, quality and performance remain open. The user-provided `/sdcard/Llms/gemma4-e2b-sm7635.qnn` is converted for SM7635 (Hexagon v73/Int16), not this SM8735 target. [Ailia's QNN guide](https://docs.ailia.ai/en/llm/qnn.html) requires a model built for the exact SoC, lists no SM8735 model, and requires its proprietary ailia LLM runtime with the matching QAIRT version. This file therefore cannot qualify Ternux text-NPU inference; a correctly converted SM8735 model and a license-compatible runtime remain open. | For every CPU/GPU/NPU LLM and Stable Diffusion route intended for v2, provide a versioned, checksummed, licensed tool artifact; install it through `ternux extension install` or an opt-in installer step; verify fresh-install menu selection and X11 desktop, post-install install/remove/repair, and a real target-device workload. Keep model weights and proprietary runtimes external unless redistribution is explicitly licensed; document user-provided paths and evidence limits |
| 10 | Complete Ternux version release | HELD until all prior gates close. Release criteria include independent QNN model-stage correctness and performance target, HTP numerical failures/operator coverage, broad sustained/failure-restart qualification, dependency-license review, model/accelerator artifact coverage and fresh-install selection, owner visual review, plus hosted signed APT install/upgrade. Stable support claims must exclude unqualified HTP/QNN routes. | Close and re-evaluate every preceding gate, then repeat installed-artifact, public repository, website and documentation audits |

### Current PR #97 CI and distribution snapshot — 2026-11-08

At source head `a2c3c67c7763e04d1259c1b558f29a1f32eff7fd`, all seven workflows passed: Validate `42499196599`, APT package `42499196408`, llama.cpp CPU/Vulkan `42499196415`, Stable Diffusion CPU/Vulkan `42499196575`, HTP candidate `42499196468`, repository contract `42499196565`, and knowledge sync `42499196430`. The APT candidate artifact is `13624359615` (263,679 bytes); llama Vulkan is `13624424898` (21,326,390 bytes); HTP is `13625047288` (15,530,589 bytes); Stable Diffusion is `13625151469` (27,029,970 bytes). Artifact metadata only has been inspected; exact artifacts have not been downloaded or installed. Owner handoff folders are ready at `artifacts/{ternux-apt,htp-qualification,ternux-extensions}/incoming/`, and were empty when checked. The base desktop includes **Synaptic Package Manager**, retaining the upstream app name with a Ternux icon/theme. The benchmark source records the matched 1.5B CPU/Vulkan/HTP result and verified tiled-Vulkan image workload. The public site still serves the previous main-branch build, the signed APT endpoints `apt/dists/stable/InRelease` and `apt/bootstrap.sh` return HTTP 404, and the hosted signed repository is unpublished. PR #97 remains a draft. Release gate 10 is held until every preceding gate closes.

At the preceding PR head `8d332484dce4b48d2fe385694d3397682b380da9`, all required checks passed again: Validate `42503534731`, Termux APT package `42503534742`, CPU/Vulkan llama.cpp `42503534757`, Stable Diffusion `42503534870`, HTP candidate `42503534721`, repository contract `42503534682`, and knowledge sync `42503534687`. The protected APT signing setup also passed the non-publishing `verify-signing` run `42504581740`; this confirms the configured key can build and verify the signed repository, but it does not publish it. Direct checks still return HTTP 404 for both hosted APT endpoints, so public `pkg install ternux` remains unverified. The handoff folders were still empty. Local focused tests passed 122/122 and documentation checks passed 3,017 assertions, 310 internal links, and 19 bilingual page pairs. PR #97 remains draft and release gate 10 remains held.

### Published accelerator prerelease audit — 2026-11-09

The public GitHub Releases page currently has four accelerator prereleases, all
separate from stable Ternux v1.4.0. The llama.cpp CPU/Vulkan archive is the
optional `llama-vulkan` extension; the Stable Diffusion CPU/Vulkan archive is
the optional `stable-diffusion` extension and ships no model weights. The
SM8735 llama.cpp HTP V73 archive is installable only as
`llama-htp-experimental`; its own release notes record malformed output for
the deterministic `2 + 2` known-answer test, so it is not a correctness or
stable-support claim. The Android/Bionic QNN native probe archive is diagnostic
only: it has no model, Qualcomm runtime, firmware, or broker and does not
establish model-output correctness. Current links: [llama CPU/Vulkan](https://github.com/soobujmiah/ternux/releases/tag/ternux-llama-vulkan-linux-arm64-b11582), [Stable Diffusion CPU/Vulkan](https://github.com/soobujmiah/ternux/releases/tag/ternux-stable-diffusion-vulkan-linux-arm64-master-1053), [experimental SM8735 HTP](https://github.com/soobujmiah/ternux/releases/tag/ternux-llama-htp-sm8735-b11582), and [SM8735 QNN probe](https://github.com/soobujmiah/ternux/releases/tag/ternux-qnn-native-probe-sm8735-2026-10-14). At current PR head `4f300b4f1e6dafe7e15892d7b074a89bd104d10a`, all seven checks passed: Validate `42511329995`, APT artifact `42511330003`, llama CPU/Vulkan `42511330016`, Stable Diffusion CPU/Vulkan `42511330080`, HTP candidate build `42511329996`, repository contract `42511330008`, and knowledge sync `42511330055`. These CI results confirm source validation and artifact builds; they do not qualify HTP/QNN inference, sustained device operation, or a public signed APT install. No Actions artifact was downloaded for device testing. PR #97 remains draft and the signed APT hosting endpoints still return 404.

### Current candidate build and HTP notice audit — 2026-11-09

At PR head `bf71a994993bc072aa878f177a604a2651cef591`, all eight reported PR
checks passed: Validate `42512876206`, APT package `42512876326`, repository
contract `42512876203`, knowledge sync `42512876191`, llama CPU/Vulkan
`42512876192`, Stable Diffusion CPU/Vulkan `42512876202`, production HTP
`42512876240`, and integer-HMX HTP candidate `42512876199`. Local
`bash tests/focused.sh` passed 123/123 and `python3 tests/docs_check.py`
passed 3,017 assertions, 310 internal links, and 19 bilingual page pairs.
The production HTP workflow now puts root `AUTHORS` and LICENSE/LICENCE,
COPYING, NOTICE, COPYRIGHT, PATENTS, and UNLICENSE variants in the upstream
notice bundle, generates per-file SHA-256 checksums, and checks archive
membership. Run `42512876240` passed these checks and uploaded Actions
artifact `13630760600`; the artifact was not downloaded or device-tested.
The public HTP prerelease still has its earlier asset and malformed
known-answer output, so the workflow fix does not qualify HTP inference or
update that public release. The other three public accelerator prereleases
also remain separate from v2. PR #97 remains a draft; hosted signed APT
endpoints still return 404, and release gate 10 remains held.

### HTP prerelease install and SM8735 known-answer check — 2026-11-09

The published HTP asset SHA-256 sidecar is valid (`dffcf83fa969f3ccfad238217b4ca7f3d47040e5e5b2fa834ebd3f123d144ea5`), but its archive predates the current extension-manager contract: it has `llama-cli` and a provenance manifest, but no `bin/htp-run`, `libexec/htp-broker.py`, or `lib/libternux-htp-broker.so`. Running `ternux extension install llama-htp-experimental` provisioned the documented Debian runtime packages, verified the archive hash, then correctly rejected this stale public archive before installing extension files.

The current PR build artifact from run `42520478911` (artifact `13633283508`, source head `637c31d`) has SHA-256 `89e0f8f4ae232352d4949e989c5e7b435f815f286d5dbe58381a082b05da025d` and includes the launcher, broker, shim and matching manifest. After verifying its sidecar, I staged that exact archive into the active Debian user's managed extension directory for device qualification. `ternux doctor extensions --json` reports all four checks OK; `ldd -r` resolves when the extension library directory is set. `htp-run --version` found the CDSP service and closed its broker session with `[0, 0]`. Three independent four-token SM8735 known-answer launches with the existing `/sdcard/Llms/qwen2.5-0.5b-instruct-q4_0.gguf` each returned `4.00` and ended with `closeSession [0, 0]`. This verifies repeatability for that exact model/prompt and candidate, not broad model quality, sustained use, or performance. A separate five-second bounded SIGINT run exited 130; the broker reported child exit 0, `cancel_signal: 2`, and `closeSession [0, 0]`. An immediate fresh HTP session returned `4.00` again and closed with `[0, 0]`, verifying this candidate's interrupt/reopen path once. The local extension is the PR artifact staged directly, not one installed by the managed downloader. `ternux extension repair` also rejected the stale public archive while preserving the current candidate: the manifest and launcher SHA-256 values were unchanged, no install staging directory remained, and `ternux doctor extensions --json` stayed at 4 OK. Refresh the public prerelease only through the main-only HTP publisher after its release gate, then repeat install/repair/remove and failure/restart checks with that exact public asset.

### Webfont attribution and license-file audit — 2026-11-09

I inspected the embedded name-table copyright metadata in all five self-hosted
webfonts. This found stale Noto Sans Bengali and JetBrains Mono attribution in
`NOTICE`, plus missing Caveat and Atma entries. `NOTICE` and
`assets/fonts/LICENSES.md` now list the embedded attributions for Atma, Caveat,
JetBrains Mono, Noto Sans Bengali, and Space Grotesk. The Noto Sans Bengali OFL
text was copied from `notofonts/bengali` source commit
`85d80394cbbbb798ca0a41c983902e6cf77be3a3` and pinned by SHA-256; Atma's
embedded 2015 metadata and upstream OFL's 2010 copyright are both recorded.
The Astro site finalizer copies `assets/fonts/` into the published site, and a
focused regression test verifies the asset inventory, notice names, and license
hashes. Local checks passed: `bash tests/focused.sh` 124/124 and
`python3 tests/docs_check.py` 3,018 assertions, 312 internal links, and 19
bilingual page pairs. This closes the inventory for the self-hosted webfonts;
it does not close the broader binary dependency-license review. Mesa's exact
static component/source mapping and transitive third-party inventory remain
open, so release gate 10 remains held.

### Optional mail client — 2026-11-08/09

On owner direction, the base desktop has no mail client and sets no mail handler; Evolution Mail is an optional workload. The optional installer adds Evolution and GNOME Online Accounts GTK and creates a Ternux-managed launcher; it does not run an explicit mail-default assignment command. When Evolution is the only registered mail app, GIO may still recommend it from its desktop MIME metadata. On 2026-11-08, the live Debian guest was updated to Evolution 3.56.2-0+deb13u1 and GNOME Online Accounts GTK 3.50.6-1, and Thunderbird 1:153.6.0esr-1~deb13u1 was removed. The Thunderbird and Evolution profile directories were preserved, and the existing Evolution process was left running. Thunderbird mail defaults and XFCE `MailReader` entries were removed; the Firefox `WebBrowser` helper remains. Evolution is present in the live desktop MIME cache when installed, so a clean fresh-base install and a post-optional-install default-handler check remain separate validation points. `apt-get check` and `dpkg --audit` are clean. The optional package mapping, Ternux launcher, branded icons, bilingual guides, and focused regression test are committed and pushed in `b64d3f7` and `89d0fe9`. The added test exposed an unreachable Evolution launcher branch (the ID was consumed by a no-op case); the branch is now reachable. Running the exact optional phase against the live guest kept both Evolution packages current and installed the managed desktop entry with `Exec=/usr/local/bin/evolution`; `desktop-file-validate` passed and the installed wrapper hash matches the repository asset. Evolution remained running, Thunderbird is purged, both profile directories remain, and APT/dpkg checks are clean. The new commit CI passed Validate, APT package, CPU/Vulkan llama, Stable Diffusion, HTP candidate, repository contract and knowledge sync. The live Ternux guest has Evolution because it is an explicitly installed optional app; GIO may recommend it from its MIME metadata, while fresh base installs contain no mail app. No public release was made.

### Desktop icon coverage audit — 2026-11-08

The earlier 43-entry desktop audit found missing category and panel-plugin icon IDs that fell back to Papirus. Ternux now includes original icons for XFCE menu categories and the Applications, Show Desktop, and directory panel plugins. The earlier guvcview package and desktop override are removed; its still-photo camera flow remains the supported Android integration. The prior entry/icon count is historical and does not describe the new icon set. A follow-up panel-size review removed the repeated enclosing badge frame from application, category, device, status, MIME-type, and non-folder place icons. Their glyphs retain Ternux colors and now have distinct silhouettes; folder icons and the standalone Ternux brand marks keep their own shapes. The current live Debian desktop-entry audit found one remaining generic fallback on “Create Launcher on the panel” (`application-x-executable`). Ternux now provides an original square-window launcher icon for that ID as well. On a fresh install, the shipped theme resolves application, settings, category, device, MIME, and Thunar-action icons to Ternux artwork; Adwaita remains the neutral fallback for software added later. On 2026-11-08, the live Debian guest was synchronized twice from the canonical Ternux asset tree using staged directory swaps, bringing the icon pack to 193 SVGs with zero stale aliases. The final live GTK3 `Gtk.IconTheme` check reports active theme `Ternux`; all 56 desktop and panel icon IDs resolve, including all six XFCE panel plugin IDs added during this pass, Evince, the mail reader, and Thunar. Common Thunar edit/navigation actions also resolve. The panel was restarted through XFCE IPC to load the current GTK theme; `xfce4-session` and `xfwm4` stayed running and no user apps were closed. The base desktop installs no mail app or mail default; Evolution is optional, and Thunderbird was removed from the live guest as recorded above. The base PDF default is now Evince; the live guest has Evince installed, its PDF MIME default points to `org.gnome.Evince.desktop`, and a generated one-page PDF rendered with readable dark-themed controls in a 610×610 window on the 752×1155 display. LibreOffice Draw remains optional for PDF page editing/export. Active/checked panel buttons now explicitly use a compact square Ternux state instead of the upstream rounded pill. A direct live X11 root capture at 752×1155 was also decoded using the server’s 24-bit BGR row layout and visually reviewed: the Ternux graphite/emerald desktop and panel, Application Finder, and a real Thunar home window rendered legibly within the screen; sidebar places and distinct folder types use Ternux artwork, and the panel/window controls have no oval icon backplates. The test Thunar process was closed without stopping the desktop session. Android Chrome remained the phone foreground app, so the capture provides agent visual evidence but not the owner’s visual review; keep that release gate open.

### Current live portrait desktop capture — 2026-11-09

A read-only Termux:X11 root capture at 752×1630 shows the graphite/emerald Ternux wallpaper, branded Home/File System/Trash/SD Card icons, and the bottom panel within the portrait display. The Xfce desktop remained running; no window or application was launched for this capture. This is an agent visual check of the desktop background, icons and panel geometry only. No application window was visible, so it does not verify the Volume Control rendering or replace the owner's final visual review.

### Volume Control launcher reopen review — 2026-11-09

The exact XFCE desktop-entry launch (`gtk-launch org.pulseaudio.pavucontrol`) was
repeated three times on the active 752×1155 Termux:X11 session with the session
D-Bus and PulseAudio server environment. Each window had the black/loading view
in the first two-second capture; all three displayed readable Output Devices
controls by seven seconds. Input Devices showed `OpenSL ES Input`. After the
last test window exited, the Ternux microphone source returned to `SUSPENDED`;
`xfce4-session` and `xfce4-panel` remained alive, and existing VLC/Thunar
processes were left untouched. This reproduces the brief black/loading startup
state and verifies recovery on three opens; it does not establish that the
owner's longer black-screen report is resolved. Keep the owner visual review and
startup-delay investigation open.

### Volume Control window-targeted visual follow-up — 2026-11-09

A later repeat used the exact desktop entry and captured the pavucontrol X11
window by its window ID (500×400), rather than cropping guessed root-screen
coordinates. The Output Devices tab immediately showed the `OpenSL ES Output`
slider and controls; the Input Devices tab showed `OpenSL ES Input` and its
controls. No black window was reproduced in this run. I closed only the
pavucontrol test process; the PulseAudio sink and microphone source returned to
`SUSPENDED`, and the detached XFCE desktop stayed running. This is a current
agent visual check of both tabs, not owner confirmation that the earlier
longer-lasting black view is resolved.

### Audio output path check — 2026-11-09

No PulseAudio sink input was active before the check. A one-second 660 Hz WAV
was sent to `OpenSL_ES_sink` with `paplay`; a concurrent capture from
`OpenSL_ES_sink.monitor` contained 286,640 bytes of non-silent PCM (peak 5,999
of 32,767). PulseAudio reported the sink IDLE afterward. This verifies delivery
to the Termux OpenSL ES PulseAudio route and digital monitor; it does not prove
that sound was physically audible from the phone speaker. Keep audible playback
verification open.

### Desktop camera gate — 2026-11-08

The MP3 export command was exercised on a two-second generated tone using Debian FFmpeg 7.1.5; `ffprobe` identified codec `mp3`, duration 2.04 seconds, and a 33,068-byte output. The Ternux 2.0.0 CLI package installed in the live guest contains a recorder file byte-identical to the checked-out source (SHA-256 `2607ebcc40a8687c9e048074e309f278d99a06ee346e633adf6b5c6ae0eb528d`). On 2026-11-08, an owner-operated GUI recording was reported saved, but its 36,737-byte M4A failed `ffprobe` with a missing `moov` atom. The file was preserved. The failed capture came from the earlier implementation, which reported success before MP4 finalization. The current fix waits for a readable AAC stream and positive duration and preserves incomplete captures for recovery. A Debian guest helper smoke test accepted generated AAC/M4A (1.00s) and MP3 (1.04s), and rejected a truncated M4A. On 2026-11-08, I opened the exact-source Ternux Sound Recorder in the live X11 session, used Start and Stop, and verified the saved 78,854-byte M4A with `ffprobe`: AAC codec, 50.176-second duration. The UI showed its Saved path; the Android microphone API returned idle after close. I deleted only this test recording; the two earlier user recordings remain untouched. This closes the interactive AAC GUI save path. In the same live GUI, I selected MP3 and used Start/Stop; the app saved a 346,796-byte MP3 that `ffprobe` identified as MP3 with 43.200-second duration. I removed only that test file and confirmed the Android mic was idle. Both GUI save formats are now verified; audible playback remains unverified.

Termux:API reported camera ID `0` as rear and `1` as front. A direct rear-camera test with `termux-camera-photo -c 0` produced a valid 4096×3072 JPEG. The Ternux Camera UI now selects the rear camera by default, stages captures in Termux app-private storage, validates them, and atomically saves them to the Debian user’s `~/Pictures/Ternux`. A hidden GTK flow check verified rear-ID selection, post-capture image preview, PRoot destination, and cleanup of temporary files. The preview applies embedded EXIF orientation, and capture controls use a compact two-row layout. Fifteen distinct portrait-first wallpapers and enlarged, higher-contrast Xfwm titlebar controls ship with the theme; landscape mode uses zoomed aspect-preserving display. All 15 wallpapers were reviewed in portrait and landscape contact sheets; a live desktop capture confirms the larger, high-contrast titlebar controls are visible. Each PNG decoration now ships with a generated, valid XPM geometry base, and maximized windows have explicit restore-state artwork. The package manifest includes these assets, and focused tests validate each XPM header and row dimensions. Live maximize and restore clicks succeeded; minimize and close interactions remain unverified. The live GUI save path for AAC/M4A and MP3 is verified above; audible playback remains unverified. An Android live stream is not exposed by the installed still-photo interface: upstream [camera-video API](https://github.com/termux/termux-api/pull/904) and [streaming client](https://github.com/termux/termux-api-package/pull/242) changes remain open. The in-window live-preview request is therefore still open and must be resolved and visually checked before release.


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

On 2026-11-07, a 2-image, 2-step phone batch matched separate single-image
controls for seeds 20261014 and 20261015. It loaded one UNet and one decoder
QNN context and took 20.321 s; controls took 14.275 s and 12.197 s.
A subsequent 20-step, 2-image batch matched the first two images from the
earlier 25-image soak exactly: seed 20261014 SHA-256
1a13957f5cb65132d98fc212756bdcf8d8b959d69feba84902a9314036764fc3 and seed
20261015 SHA-256 d20bf183909928236e02c8a1f7fe869e5883eb7931e3f5fe5eb65c0f74ee5aec.
It loaded one UNet and one decoder context, streamed each verified model member
once, and took 49.923 s total. Per-image UNet/decode-and-PNG time was
14.815/0.850 s and 16.129/0.824 s. The earlier soak measured those images at
28.233 s and 28.911 s separately (57.144 s combined); this non-interleaved
cross-session sample is not a controlled speedup. Battery sampled at
40.7–40.9°C; no NPU-specific thermal sensor was identified. The unchanged
archive SHA-256 is f479f3221fb90d31de1e695577f5aec9a5afb5fb7e076cfac40f00e039b22977.
Repeatable image hashes do not establish independent stage correctness. The
owner's 3–5 second target remains open.

Three same-day, 20-step paired sequences on 2026-11-07 used both single→batch→single
(two runs) and batch→single→single (one run) order. Batch totals were 47.825,
46.946 and 45.931 s (mean 46.901; range 45.931–47.825); paired single controls
totaled 60.429, 57.145 and 60.012 s (mean 59.195). The batch mean was 20.8%
lower in these three short samples. All six batch/control PNG hashes matched
exactly. This is not randomized or statistically powered, and does not establish
a release guarantee. Battery sampled 36.5–37.1°C before/after the two new runs;
no NPU-specific thermal sensor was identified. The unchanged archive SHA-256 is
f479f3221fb90d31de1e695577f5aec9a5afb5fb7e076cfac40f00e039b22977. Independent
stage correctness and the 3–5 second target remain open; detailed seeds, hashes,
commands and per-run values are in the [device benchmark record](../guides/device-benchmark-evidence.md#2026-11-07-qnn-batch-setup-reuse-repeat).

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

### SM8735 no-FP16 integer-HMX candidate — 2026-11-08

A disposable candidate now ports the MIT-licensed `karusrus/llama.cpp`
`hexagon-int-hmx` implementation onto Ternux's pinned llama.cpp commit
`af50f2f248b475d9760f8e67503d01c0f194f5f4`. The patch adds runtime HMX-FP16
probing, integer-HMX Q4_0 matmul/attention paths, and an HVX Gated Delta Net
path. It keeps the production extension and its HVX-only launcher unchanged.
The exact patch, license text, test launchers, and manual build workflow are in
[`experiments/htp-integer-hmx-candidate/`](../experiments/htp-integer-hmx-candidate/README.md).

The pinned Linux ARM64 candidate build and package inspection passed in workflow
[42480362351](https://github.com/soobujmiah/ternux/actions/runs/42480362351), at
Ternux commit `b14da669a551dd5fcde0f508a8843a0b60743ef1`. CI verified the patch
application, HTP V73 package files, ARM64 ELF targets, launcher/test wrapper,
and bundled license notices; it uploaded the 14,211,453-byte
`ternux-llama-htp-sm8735-integer-hmx-v73-candidate` artifact (metadata ID
`13617163756`; the agent has not retrieved it). This is build and
packaging evidence only. No candidate inference or operator test has run on
SM8735. Keep the production HTP extension unchanged until device-side HMX
capability, CPU-reference correctness, supported operator suites,
failure/restart, and bounded sustained tests pass. On 2026-11-08, all seven PR checks passed at head `6aaa41cfc2bd75fc2cb95de025b6e4f27373be23`: Validate `42494970578`, APT package `42494970656`, CPU/Vulkan llama.cpp `42494970581`, Stable Diffusion `42494970714`, HTP candidate `42494970777`, repository contract `42494970670`, and knowledge sync `42494970688`. The HTP build initially failed at head `738b1cbb68b27d166eeee85d6dca045a607daa02` because upstream also built the V85 skeleton with a toolchain that lacks its newer intrinsics. The candidate workflow now excludes V85 alongside V75/V79/V81 and builds only the SM8735 V73 target. The corrected run passed and uploaded artifact `ternux-llama-htp-sm8735-integer-hmx-v73-candidate` (15,530,623 bytes; metadata ID `13622933656`). CPU/Vulkan and Stable Diffusion candidate artifacts were also uploaded (IDs `13622533883` and `13622369733`). These CI artifacts have not been downloaded or installed; the three incoming handoff directories remain empty, so exact-artifact install and device validation are open. The public APT `InRelease` and bootstrap endpoints still return HTTP 404. PR #97 remains a draft; this evidence does not close the release gate.

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
live Debian updater installed Mesa 27.0.0 and verified every notice hash. A pinned-binary
inspection now records the installed ICD binary SHA-256, ELF build ID, upstream build
configuration, and direct runtime imports mapped to Debian package owners with installed
copyright-file hashes in the [Mesa notice bundle](../lib/licenses/mesa-27.0.0-devel-20261025/README.md).
Exact mapping of statically linked source components to file-level SPDX terms and the
wider transitive third-party license inventory remain open; the bundle does not claim
every source-tree license applies to the extracted binary.

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

### Exact-current-head CI artifact inventory — 2026-11-09

At PR #97 head `96c30aa1325bc14850d14b7a4dcd4528b5aab5da`, all eight required
checks passed: Validate `42535686912`, unsigned Termux APT package `42535686925`,
repository contract `42535686910`, knowledge sync `42535686911`, CPU/Vulkan llama
`42535686914`, Stable Diffusion CPU/Vulkan `42535686917`, production HTP
`42535686924`, and integer-HMX V73 candidate `42535686919`. Preview/publication
jobs were skipped because this is a draft PR. Actions artifact archive metadata:

| Artifact | Actions artifact ID | Bytes | SHA-256 |
|---|---:|---:|---|
| `ternux-apt-unsigned-ci-af450cc891fd2120cea9e5697e0159c61a7a35d3` | `13638992164` | 268,620 | `94fc4252b41faceb60d021d5f1982cf23f81f69eb9a9e0e3e5c3cf94f7587101` |
| `ternux-llama-vulkan-linux-arm64-b11582-candidate` | `13639198127` | 21,327,935 | `60c84df443bbf996b64c5c46076253d4a89b8ca5fdefaf5439919d0a3605bbc8` |
| `ternux-stable-diffusion-vulkan-linux-arm64-master-1053-candidate` | `13639660775` | 27,030,299 | `b40238efee496b813572a9a13d84624bc2693efb502e4b07ae7a56a89aa5544c` |
| `ternux-llama-htp-sm8735-b11582` | `13639273191` | 15,637,038 | `bdf22e7d17769bd3289c8596fb48631ea269295240aa05ff0d06dae085c94eee` |
| `ternux-llama-htp-sm8735-integer-hmx-v73-candidate` | `13639198836` | 15,530,741 | `1d8010b25656d5ec70806c9544e1af4576aa5bc1f53e2839f78aac7dbdb572e4` |

These are GitHub Actions archive digests and CI build/inspection evidence. The
exact archives are not in the project incoming directories and have not been
installed from this run. CPU/Vulkan and Stable Diffusion belong in
`artifacts/ternux-extensions/incoming/`; both HTP archives belong in
`artifacts/htp-qualification/incoming/`; the unsigned APT artifact belongs in
`artifacts/ternux-apt/incoming/`. Exact-artifact fresh install/device checks,
independent QNN model-stage correctness, the known HTP operator failures,
owner visual review, wider dependency-license review, and public signed APT
install/upgrade and release publication remain open. The new CI evidence does
not close those release gates. A live HTTP check at
`https://soobujmiah.github.io/ternux/apt/dists/stable/InRelease` and
`https://soobujmiah.github.io/ternux/apt/bootstrap.sh` returned 404; the
signed publish workflow is main-only and has not been dispatched for release.

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

### PR #97 exact current-head artifact audit — 2026-11-09

At head `ccc9b94ff49db5c05a534ede26e607cfcc0e415b`, the Validate, unsigned
Termux APT package, repository-contract, knowledge-sync, llama CPU/Vulkan,
Stable Diffusion CPU/Vulkan, production HTP, and integer-HMX candidate build
checks passed. I downloaded the exact Actions artifacts and verified each
archive against its sidecar checksum. The llama CPU/Vulkan archive from run
`42523800363` (artifact `13634048426`; archive SHA-256
`1ff7d8ec2187ccbe6e5940cd5e02bde40283044727ea19e6befe7f5b8e57eaa5`) passed
the local ABI/source-map/license audit: 69 AArch64 ELF files, maximum GLIBC 2.38, all dependencies resolved,
and `$ORIGIN/../lib` RUNPATH. The Stable Diffusion archive from run
`42523800211` (artifact `13634521936`; archive SHA-256
`7430e9092f26f9d155b639c8ffe14c59acae69a2157a9c54e0d5fce227c3ac8d`) passed
its local ABI and 11-notice license audit. The production HTP archive from run `42523800207` (artifact
`13634444182`; archive SHA-256
`10997fba5cf5aec6d15beb5ef5557c44c1d3cdb405758eb085062afaaea0aa34`) passed
its sidecar check, safe extraction, expected broker and launcher layout checks,
and every upstream-notice hash. The separate integer-
HMX candidate from run `42523800189` (artifact `13634897369`; archive SHA-256
`b8408d93396f445c45e1c8d1e833d2e8baa36e513e8a781d92bb36150efa5d94`) passed
its sidecar check, safe extraction, manifest and required-file checks. These are
exact-current-head build and static package checks; the downloaded artifacts
were not installed or device-tested in this pass. The phone reported 46 °C, so
device inference and graphics stress were deferred. The public HTP release
asset and hosted signed APT endpoints remain unchanged; both hosted APT URLs
still return HTTP 404. PR #97 remains a draft, and these checks do not close
the live-device, correctness, sustained-use, license-scope, or hosted install
gates.

### Latest PR #97 CI snapshot and live install check — 2026-11-09

At PR head `6f58393a32fe90fe81a10554b41115d3b6972b13`, all eight workflows
completed successfully: APT package `42527094159`, repository contract
`42527094177`, Validate `42527094180`, knowledge sync `42527094186`, llama
CPU/Vulkan `42527094171`, Stable Diffusion CPU/Vulkan `42527094154`, integer-HMX
candidate `42527094161`, and production HTP `42527094173`. Actions metadata
reports the CPU/Vulkan candidate as artifact `13635469668` (21,327,333 bytes),
Stable Diffusion as `13635803194` (27,029,203 bytes), integer-HMX as
`13636525224` (15,530,758 bytes), production HTP as `13635773588`
(15,637,158 bytes), and the unsigned APT CI package as `13635891822`
(268,628 bytes). These exact build artifacts are not in their project handoff
directories and have not been locally installed or device-tested. The integer-
HMX candidate belongs in `artifacts/htp-qualification/incoming/`; the three
extension archives in `artifacts/ternux-extensions/incoming/`; and the APT
package in `artifacts/ternux-apt/incoming/`. CI success is build/validation
evidence, not device qualification. On the active Termux installation,
`ternux verify --json` passed and `ternux doctor --json` reported 31 OK,
0 warnings, and 0 failures; desktop status reported X11 and PulseAudio running.
Fresh artifact install, exact-artifact device checks, release publication, and
clean public APT install remain open. Both hosted signed APT endpoints still
return HTTP 404. PR #97 is open, clean, and draft.

### Latest CI artifact collection — 2026-11-09

At PR head `c0e2c1785dd35c1a51916b569bcca184509ea5e2`, all eight required
workflows passed: Validate `42536592457`, unsigned APT package `42536592422`,
repository contract `42536592415`, knowledge sync `42536592409`, CPU/Vulkan
llama.cpp `42536592402`, Stable Diffusion `42536592357`, production HTP
`42536592386`, and integer-HMX candidate `42536592385`. Preview/publication was
skipped because PR #97 is draft. The completed artifacts and GitHub Actions
artifact ZIP digests are:

| Artifact | Actions artifact ID | Bytes | ZIP SHA-256 |
|---|---:|---:|---|
| `ternux-apt-unsigned-ci-99de5071b7ed1d598ae29f067b52191b3fc8f00a` | `13639159392` | 268,630 | `ebf8a2bbce030bea10a462f4cfcfb833855fbf52afe1c1240eed4a67a06379fd` |
| `ternux-llama-vulkan-linux-arm64-b11582-candidate` | `13639896523` | 21,330,602 | `cdb648e53b740c9997f2b5e6a8c8266a662945a8c712a816672e777d9ee5a344` |
| `ternux-stable-diffusion-vulkan-linux-arm64-master-1053-candidate` | `13640110682` | 27,034,110 | `1bf2eb3d040abad14116b862aa4db5653b87bddfbce0a341a64d2762fa7ec111` |
| `ternux-llama-htp-sm8735-b11582` | `13640265652` | 15,636,542 | `e67d4428a0781771c3bb0337cdaf8cbbf4cd02d2cc08f4b01dd5ae7b1289d942` |
| `ternux-llama-htp-sm8735-integer-hmx-v73-candidate` | `13640420118` | 15,530,593 | `9454f8f280b17cb2e6dc866afaa123f1f2fc8b483aafeb21353005102f995f86` |

These are the GitHub Actions ZIP digests, not extracted package checksums. The
archives are still absent from `artifacts/{ternux-apt,ternux-extensions,htp-qualification}/incoming/`;
none has been locally installed or device-tested from this run. The owner-mediated
handoff folders remain the input for exact-archive verification. The build pass
does not close accelerator correctness, release publication, or hosted APT
install/upgrade gates.

### Latest PR #97 artifact collection — source head `0f2d9f5` — 2026-11-09

The local source-built `ternux_2.0.0_all.deb` remains installed: 129,352 bytes, SHA-256 `363f906c1644408d86bd332eff7f5fd6964004b07180de0d855efd3210963f7c`; `ternux verify --json` passes. At PR source head `0f2d9f5492d2964e2efbaa13efec3eff768d57a9`, all eight required workflows passed. Preview/publication workflows were skipped because PR #97 is draft. Collected Actions artifact metadata:

| Artifact | ID | Bytes | Archive SHA-256 |
|---|---:|---:|---|
| `ternux-apt-unsigned-ci-195d094bd7999a684995665d03767d192c3fbbf9` | `13641307456` | 268,664 | `a08dcb995c4888c783c4bcae4c8292c88b9fe15b50aadee1c00e9321d4b30ec6` |
| `ternux-llama-vulkan-linux-arm64-b11582-candidate` | `13641273491` | 21,326,091 | `c373af05488f25a9348b6434342c3eedb8a17a9320f5d50e21c0903800ed0b91` |
| `ternux-stable-diffusion-vulkan-linux-arm64-master-1053-candidate` | `13640903441` | 27,033,643 | `dbcb7d0f44771313f74b10b405fb8f9289f6530e0820e9809138400c028e6a4c` |
| `ternux-llama-htp-sm8735-integer-hmx-v73-candidate` | `13641249471` | 15,530,439 | `8fe85c0c8674be52ea98fb013b0b84b9c10f553f76dd1e619021aad0eb84fbe9` |
| `ternux-llama-htp-sm8735-b11582` | `13641971275` | 15,636,123 | `9a17d2937b6387b1ece19f3a8d3af1edd972cd3fd56307cd6d53b73f0a936708` |

These are Actions archive digests, not extracted package checksums. Under the owner-mediated handoff policy, the archives were not downloaded; the `artifacts/ternux-apt/incoming/`, `artifacts/ternux-extensions/incoming/`, and `artifacts/htp-qualification/incoming/` directories remain empty. Exact CI-archive installation/device qualification remains open. These builds use the same product source as the locally verified package; this collection commit changes release documentation only.

### Local signed Termux APT client check — 2026-11-09

Built a fresh repository in a temporary directory from the current local
`ternux_2.0.0_all.deb` (SHA-256
`0cb55b9cefe187c733ad82f205ecc134c1f99e18c7e654b1426382db95f4b68d`) and
signed its `InRelease` with an isolated, short-lived test key. With the official
Termux main source also enabled, the installed Termux APT client accepted the
signed index, `apt-cache policy ternux` selected version 2.0.0 from the local
repository, and `apt-get --simulate install ternux` completed. A download-only
`apt-get download ternux=2.0.0` produced a `.deb` whose SHA-256 exactly matched
the local package. The active installation was not changed. This validates the
local package/index/client path with a test key; it does not validate the
protected release key, hosted signed repository, or public clean install/upgrade.

### Local `pkg install` source-build verification — 2026-11-09

Rebuilt `ternux_2.0.0_all.deb` from the checked-out Ternux source using the exact
Termux package-builder script pinned by the CI workflow (source SHA-256
`dd1acf8cb6eb48a3b6fc50c56a6a1f20426112a458e342980a5955a788494650`) and the
pinned APT repository-builder script (SHA-256
`d5768791086f3ad1f12e95d59a54ccaf582f3ba43908c452d722ee2b96b49db1`). The
package SHA-256 is
`363f906c1644408d86bd332eff7f5fd6964004b07180de0d855efd3210963f7c`. Built a
fresh temporary repository, signed it with an isolated short-lived test key,
and confirmed the Termux APT client accepted the index and downloaded the exact
package hash. `pkg install -y --reinstall ternux` then reinstalled the package
from that signed local source; `ternux verify --json` passed, and the installed
CLI matched the package payload byte-for-byte. The temporary apt source was
removed afterward. This is an in-place same-version installation using a test
key, not a clean-prefix install with the protected release key or hosted public
repository.


### Short audio output and microphone loopback check — 2026-11-09

The live PulseAudio server reports `OpenSL_ES_sink` and `Ternux_Microphone`. A low-level 440 Hz, 0.65-second test tone was accepted by `paplay` on the active sink while a three-second Termux:API Opus capture ran. The capture auto-stopped (`isRecording: false`); a 440 Hz band-pass measured RMS `-42.61 dBFS`. The disposable recording and tone were deleted. This verifies the output submission and an acoustic signal in the mic path for this short test; it does not replace an owner audibility check or verify sustained playback/music controls.

### Current-head validation and package notice audit — 2026-11-09

At PR #97 head `135609006b867c2ed32b71038a0501eab5185d4a`, all eight required
checks passed: Validate `42542637255`, APT package `42542637286`, repository
contract `42542637246`, knowledge sync `42542637225`, CPU/Vulkan
`42542637226`, Stable Diffusion `42542637243`, production HTP `42542637261`,
and SM8735 integer-HMX candidate `42542637212`. Preview and publication jobs
were skipped because the PR is draft. The current Actions archive metadata is:

| Artifact | ID | Bytes | Archive SHA-256 |
|---|---:|---:|---|
| `ternux-apt-unsigned-ci-0266ac109af0a6670ce50ea1faeb993042d7ba16` | `13642061334` | 268,693 | `0ff6c7bd826a0efc06bbb02355a5f866472dc240528701ce7a59a6cb30735fc0` |
| `ternux-llama-vulkan-linux-arm64-b11582-candidate` | `13641857606` | 21,320,298 | `b2458ac76a1fdef842cf80ca8b4698f6ec02c16de327217ef1c48d99dc501e81` |
| `ternux-stable-diffusion-vulkan-linux-arm64-master-1053-candidate` | `13642167554` | 27,023,984 | `8550c75e77a5711186b900cd0c825a932d24b343f339098424e02e1edefe9a3b` |
| `ternux-llama-htp-sm8735-b11582` | `13641389194` | 15,637,166 | `8e8b10db4df6b88528ad52d01e99c9f615a93a57d38b965be368ad6d9ef7533e` |
| `ternux-llama-htp-sm8735-integer-hmx-v73-candidate` | `13642277117` | 15,530,759 | `4f068dc849a7aabfc8b281898ad3a0f7ceb0875f5f4b7a2d4c8e094948316d68` |

These are GitHub Actions ZIP digests, not extracted package checksums. The
archives are absent from the designated incoming directories and remain
uninstalled; exact-artifact qualification is open. The local source-built
`ternux_2.0.0_all.deb` is 129,352 bytes with SHA-256
`363f906c1644408d86bd332eff7f5fd6964004b07180de0d855efd3210963f7c`. Its
archive contains the Mesa source-tag notice bundle; extracting it and checking
`SHA256SUMS` verified every bundled license text. This closes notice inclusion
for the local `.deb`, not for the upstream Turnip archive itself or the
unavailable exact-current-head APT artifact. Static Mesa component mapping and
the wider transitive-license review remain open.

On this head, local verification passed: `tests/focused.sh` (129/129),
`tests/smoke.bats` (72/72), installer UI render (33/33), QNN CLIP/tokenizer
unit tests (7/7), repo-knowledge unit tests (43), documentation checks
(3,018 assertions), Termux APT bootstrap, formatting, shell syntax, and
`ternux verify --json`. `ternux doctor --json` reported 30 OK, 0 failures,
one informational check, and a 46 °C battery warning. The desktop was stopped
and left stopped. The local website build could not use Termux's Android Node
binding; the required Validate workflow passed its pinned Linux build. The
release remains held on exact-artifact qualification, owner visual review,
camera live-preview support, accelerator correctness/sustained-use gates,
public signed APT availability, and release publication.

### Current PR head artifact and signing follow-up — 2026-11-09

At PR #97 head `99b94413e8f8a2263b8baa245edaf2100236eef0`, Validate
`42553378033`, unsigned APT package `42553378059`, repository contract
`42553378055`, knowledge sync `42553378006`, CPU/Vulkan llama.cpp
`42553378100`, Stable Diffusion `42553378034`, and integer-HMX candidate
`42553378136` completed successfully. The production HTP build `42553378026`
was still running when this inventory was recorded. Available Actions artifact
metadata:

| Artifact | ID | Bytes | Archive SHA-256 |
|---|---:|---:|---|
| `ternux-apt-unsigned-ci-f3526479a0c9b1ff62a73e0d9a25b3fed30a79a6` | `13646616051` | 268,620 | `157d4b69f9712eab45548e0d8a75b0e49b8b7bc4362f4545401d810e14c92cd1` |
| `ternux-llama-vulkan-linux-arm64-b11582-candidate` | `13645828954` | 21,326,902 | `c4d1789c29e68231b4ee411cf00d58b0dec70081674ba080442a183a79f97a07` |
| `ternux-stable-diffusion-vulkan-linux-arm64-master-1053-candidate` | `13646249363` | 27,031,950 | `eae0bfe9ca5d6580d9addb8fed278cb55fa286eccb25b3aed8a33c3ccc7b208e` |
| `ternux-llama-htp-sm8735-integer-hmx-v73-candidate` | `13647070267` | 15,530,994 | `0c343bf01ef6ecff87a0c14f35616f718f452192b2b25a5e1a1a53989a500037` |

These are GitHub Actions ZIP digests, not extracted payload checksums. Exact
archives have not been placed in the designated incoming directories or
installed on-device, so they do not qualify those artifacts. Separately, the
non-publishing `verify-signing` mode completed successfully on main at commit
`8e24062589e81c20095c875fa4d19dd5cb928554` (run `42554187198`): the protected
APT key built and verified a signed repository. This validates signing
configuration, not public deployment. Both hosted APT endpoints still return
404; publish mode remains unrun while release gates are open.

### Complete current-head CI artifact inventory — 2026-11-09

At PR #97 head `0978fba5c46993640acf1b0b7d7986bcf290f666`, all eight
validation and package-build workflows passed: Validate `42554550884`, APT
`42554550728`, repository contract `42554550768`, knowledge sync `42554550962`,
llama CPU/Vulkan `42554550807`, Stable Diffusion CPU/Vulkan `42554550879`,
production HTP `42554550670`, and the integer-HMX candidate `42554550722`.
Preview/release publication jobs were skipped because the PR remains draft.
Current Actions artifact metadata:

| Artifact | ID | Bytes | Archive SHA-256 |
|---|---:|---:|---|
| `ternux-apt-unsigned-ci-478caf84f5b306f3b2173e6d8d114f10b3b900e5` | `13646663061` | 268,678 | `1c7989ff9fece0288502c4db06186c42c2908c0287699850c83f21661345a4a5` |
| `ternux-llama-vulkan-linux-arm64-b11582-candidate` | `13647211389` | 21,327,346 | `34b897b2951de89dd9e09dbed17e0a624d50c9f295eb266409036e2981d34e19` |
| `ternux-stable-diffusion-vulkan-linux-arm64-master-1053-candidate` | `13646683907` | 27,027,336 | `9579a3d7d5c4e6d0736482fe9eb1ea3c500f5804063f3a0554174fd1e1a030a4` |
| `ternux-llama-htp-sm8735-b11582` | `13647510166` | 15,636,380 | `4d95b279fb296b02583980c99d070f63d592a47433e18618c532729c38b23f0a` |
| `ternux-llama-htp-sm8735-integer-hmx-v73-candidate` | `13646692551` | 15,529,809 | `273fd9f04b4f4281618cf996dd507bbe46ac5a3c8c47adc6f8c19ca0ca4c2aee` |

These are Actions ZIP digests, not extracted payload checksums. The exact
archives are not in their designated incoming directories and have not been
installed or device-tested. Therefore these successful workflows prove pinned
build and static package inspection only; they do not qualify CPU/GPU/NPU
runtime behavior, QNN model correctness, sustained use, or device compatibility.
The signed APT key's non-publishing verification passed separately in run
`42554187198`, but the public APT endpoints still return 404. PR #97 remains
draft, and release publication is not complete.

### Current Node 24 CI artifact inventory — 2026-11-09

At PR #97 head `b7bb3850ecc3d21666eff65acd2d67b974c329ba`, all eight build and
validation workflows passed: APT `42556143394`, repository contract
`42556143358`, Validate `42556143370`, knowledge sync `42556143419`, llama
CPU/Vulkan `42556143328`, Stable Diffusion `42556143441`, production HTP
`42556143514`, and the integer-HMX candidate `42556143349`. Preview and
publication jobs skipped because the PR remains draft. The Node 24-compatible
workflow updates also passed. Actions artifact inventory:

| Artifact | ID | Bytes | Archive SHA-256 |
|---|---:|---:|---|
| `ternux-apt-unsigned-ci-fcac15570a4a3459922276b301d119c8f2610b07` | `13646914880` | 268,611 | `b4730d815992f87a3cc40901d39d5884fa9da8dd65294b0bfd4fcf45b06dcced` |
| `ternux-llama-vulkan-linux-arm64-b11582-candidate` | `13647194909` | 21,329,406 | `289cc0082483ebaa355960d74f772477421ae322f72a4eebb04a92780c759a18` |
| `ternux-stable-diffusion-vulkan-linux-arm64-master-1053-candidate` | `13647907176` | 27,029,814 | `29a84606fcd483f2afc42f3d911be37edb20fa7c28ecdea61b12463eb3d1a65f` |
| `ternux-llama-htp-sm8735-b11582` | `13647314688` | 15,633,028 | `017c22226e22ef3321eafe1aa6a8d9033a1b432d366c25d356ffafe7d96583c0` |
| `ternux-llama-htp-sm8735-integer-hmx-v73-candidate` | `13648120716` | 15,532,991 | `2903df15c67048c85d6909fe1de8bfa36b6cce7f1cef865fb24e8b82aef85a6f` |

These are Actions ZIP digests, not extracted payload checksums. The archives
remain absent from the designated incoming directories and are not installed or
device-qualified. The successful jobs prove pinned builds and static packaging
only. Runtime, numerical correctness, sustained-use, clean-install, owner
visual, camera live-preview, public signed APT and publication gates remain
open. PR #97 remains draft.

### Complete current-head CI artifact inventory — 2026-11-09

At PR #97 head `c0b7de99673c0a7618514d30f8471f23c0431420`, all eight build
and validation workflows passed: APT `42557310299`, repository contract
`42557310329`, Validate `42557310363`, knowledge sync `42557310330`, llama
CPU/Vulkan `42557310347`, Stable Diffusion `42557310304`, production HTP
`42557310507`, and integer-HMX candidate `42557310332`. Preview and publication
jobs were skipped because PR #97 remains draft. Actions artifact metadata:

| Artifact | ID | Bytes | Archive SHA-256 |
|---|---:|---:|---|
| `ternux-apt-unsigned-ci-2aafb646e1bb30a9ee66cc8b0e9a4c195167296b` | `13646994621` | 268,622 | `256f2d7e71001b19b387832bbb6efda016cfa87731a1df2c4440fb982aaf6244` |
| `ternux-llama-vulkan-linux-arm64-b11582-candidate` | `13648121485` | 21,321,152 | `458b9dfc92f0e3a404e2050378e173595b1cb2cefaae1e5913cdaa9137969af5` |
| `ternux-stable-diffusion-vulkan-linux-arm64-master-1053-candidate` | `13647719068` | 27,028,493 | `4bf92744b0a4aedf380f8d2b30aa6cd2ba9a3b54cd4d8036972804535fd36995` |
| `ternux-llama-htp-sm8735-b11582` | `13648505570` | 15,632,903 | `0bed70ecddb9873116d094b4d7932c8cf40a0912ad5ebb1b79958ca52698032d` |
| `ternux-llama-htp-sm8735-integer-hmx-v73-candidate` | `13648406193` | 15,534,201 | `80747d62304dae39592bd796d4ba7a5c1288f3a8d494408f6a7cd0e147c87d6b` |

These SHA-256 values identify GitHub Actions ZIP archives, not extracted
payloads. The archives remain absent from the designated incoming directories
and have not been installed or device-qualified. Successful CI proves pinned
builds and static packaging only; runtime correctness, numerical behavior,
sustained use, clean-install behavior, and device compatibility remain open.
The working tree was clean at this source head. A fresh non-GUI `ternux doctor
--json` check reported 30 OK, 0 failures, one informational item, and a 44 °C
battery warning; the desktop remained stopped.

### Complete PR #97 CI artifact inventory — source head `19a25eb` — 2026-11-09

All eight required checks passed at PR head `19a25eb42d447717fb80509afb1dd766ee275d3c`: Validate `42558158091`, APT `42558158092`, repository contract `42558158082`, knowledge sync `42558158087`, llama CPU/Vulkan `42558158068`, Stable Diffusion CPU/Vulkan `42558158114`, production HTP `42558158086`, and integer-HMX candidate `42558158118`. Preview/publication jobs were skipped because PR #97 remains draft. GitHub Actions artifact metadata:

| Artifact | ID | Bytes | Archive SHA-256 |
|---|---:|---:|---|
| `ternux-apt-unsigned-ci-a2013dd8256b511cf90785b42d1d14bf54d3a36c` | `13647553701` | 268,663 | `ed13d138d7ab23db91f1c46c2dd1e813d98f2727632eca610b981e477c114f54` |
| `ternux-llama-vulkan-linux-arm64-b11582-candidate` | `13648218569` | 21,321,978 | `a5c7f563a49223eee9d0ccb38ef731005422766035041de926ce2e7d6049876c` |
| `ternux-stable-diffusion-vulkan-linux-arm64-master-1053-candidate` | `13648666221` | 27,029,887 | `2eec4e2f7744f5ec2378709dc83baa32463f7227adba944e621f3218e733196f` |
| `ternux-llama-htp-sm8735-b11582` | `13648259251` | 15,633,069 | `27db701243e509885a96b6419b440198e44acb6ca6404119df3b4d7222b1e612` |
| `ternux-llama-htp-sm8735-integer-hmx-v73-candidate` | `13648442714` | 15,533,267 | `78ba8a6743e2f97bdb8956622dc53459d0366994f3f3d7ae54124734bfa5188b` |

These are archive digests, not extracted payload checksums. No archive was
retrieved or installed, so these builds do not provide exact-artifact device
qualification. The designated owner-handoff directories remain the required
intake for artifact validation. All package/runtime correctness, clean-install,
sustained-use and release publication claims remain governed by the open gates
above. The following documentation-only inventory update does not alter the
built product sources.

### Current PR #97 source-head and live release audit — 2026-11-09

At source head `cd7df4307b9c55ddce76aafecd5a11790a42412a`, all eight required
PR workflows passed: unsigned Termux APT package `42593962372`, CPU/Vulkan
llama.cpp `42593962410`, Stable Diffusion `42593962517`, production HTP
`42593962427`, integer-HMX candidate `42593962461`, Validate `42593962422`,
repository contract `42593962492`, and knowledge sync `42593962457`. Preview
and public-release jobs were skipped because PR #97 remains draft. GitHub
Actions reports these candidate archive metadata values:

| Artifact | Actions artifact ID | Bytes | ZIP SHA-256 |
|---|---:|---:|---|
| `ternux-apt-unsigned-ci-9fe12e9915bcb6821314e60b7301d2614af0f2e0` | `13661918119` | 268,116 | `38d97f8502faf2ace2ac9f963484ae102490b7f1fa97b14ef2761fe8a81a87aa` |
| `ternux-llama-vulkan-linux-arm64-b11582-candidate` | `13662713136` | 21,323,560 | `c2e73acc3f8963e3abf6eaeeb30763fa97643e35555d214753fb930aa2cd9a70` |
| `ternux-stable-diffusion-vulkan-linux-arm64-master-1053-candidate` | `13662364167` | 27,027,607 | `3910614a64e30e0cc00fa9f0ae8a5442bfb747a45bcf913ecdb9190448ac072a` |
| `ternux-llama-htp-sm8735-b11582` | `13663720894` | 15,633,114 | `da36db57e5b631023dab2bba8dd0424eb1a5e19f5b9032c4a7a817c99fbb830e` |
| `ternux-llama-htp-sm8735-integer-hmx-v73-candidate` | `13663990153` | 15,535,173 | `07f543821d1333444b1c7cb6b0e2318f4dec6852b6a8a347fec23841e888139e` |

The digests identify Actions ZIP archives. The exact current-head archives were
not transferred to the designated incoming directories or installed, so these
builds do not close exact-artifact device qualification. On this source head,
`tests/focused.sh` passed 129/129 and `tests/docs_check.py` passed 3,018
assertions, 312 internal links, and 19 bilingual page pairs. The installed
Ternux 2.0.0 package passed `ternux verify --json`; `ternux doctor --json`
reported 31 OK, 0 warnings, 0 failures, and 1 informational item, including
Adreno 825 Zink/Turnip Vulkan and the installed llama Vulkan, Stable Diffusion,
and experimental HTP extensions. The fixed desktop launcher reports readiness
only after XFCE processes are alive. At the latest live check the detached
desktop remained running (PID 16987), X11 was available, and PulseAudio was
running; Termux:X11 was brought to the foreground without restarting the
desktop. This is process/runtime evidence, not an owner visual review.

The hosted signed APT endpoints (`apt/bootstrap.sh`,
`apt/ternux-archive-key.asc`, and `apt/dists/stable/InRelease`) returned HTTP
404. Termux camera-video API PR [#904](https://github.com/termux/termux-api/pull/904)
and client PR [#242](https://github.com/termux/termux-api-package/pull/242)
remain open, so installed Termux:API still provides no camera stream for the
in-window live preview. Release gate 10 remains held for exact artifact/device
qualification, QNN stage correctness and image performance, HTP numerical and
operator qualification, sustained/failure-restart coverage, the wider
dependency-license review, camera live preview, owner visual review, and hosted
signed APT clean install/upgrade.

### Desktop start recovery follow-up — 2026-11-09

Product commit `46227886bb6c142d48b2b363fae39fab005f36e0` brings the
Termux:X11 activity forward after `ternux start` reaches XFCE readiness. Start
now recognizes the shared X11 socket plus the live Termux:X11, XFCE session,
window manager, and desktop processes, so a missing/stale supervisor marker does
not launch a second session and tear down the first one. On the active phone,
`ternux start` returned “already running” for PID `16987`; `ternux status --json`
reported `running`, with the same PRoot/XFCE PIDs before and after. Android
reported that the existing Termux:X11 task was brought to the foreground; no
X11/XFCE restart occurred.

Current-product-head workflow-dispatch runs all passed: Validate
[42599397496](https://github.com/soobujmiah/ternux/actions/runs/42599397496),
Termux APT package [42599397259](https://github.com/soobujmiah/ternux/actions/runs/42599397259),
and Repository State Contract
[42599397452](https://github.com/soobujmiah/ternux/actions/runs/42599397452).
Local `tests/focused.sh` passed 130/130, including the new stale-marker/live-XFCE
recovery and activity-foreground regression; `tests/docs_check.py` passed 3,018
assertions, 312 internal links, and 19 bilingual page pairs. These checks do not
close the open release gates listed above.

### Live desktop visual check — 2026-11-09

With the existing desktop left running, the Termux:X11 display was captured at
752×1155 after `ternux start` confirmed it was already running. The visible
screen showed the Ternux-branded XFCE wallpaper, readable desktop icons (Home,
File System, Trash, SD Card), and the panel; the display was not blank or black.
`DISPLAY=:0` responded and the screenshot was inspected from the active X11
session. The temporary screenshot was deleted after inspection. This closes the
agent's live-display rendering check for this session only; it does not replace
the owner's final visual review or validate every application/window.

### Current PR #97 release audit — implementation head `d7af3fd` — 2026-11-09

All eight required workflows passed for implementation head `d7af3fd8201df02c44d6e45be2b4a148d6b86328`: [Validate 42611647484](https://github.com/soobujmiah/ternux/actions/runs/42611647484), [Termux APT 42611647218](https://github.com/soobujmiah/ternux/actions/runs/42611647218), [repository contract 42611647274](https://github.com/soobujmiah/ternux/actions/runs/42611647274), [repo knowledge sync 42611647220](https://github.com/soobujmiah/ternux/actions/runs/42611647220), [CPU/Vulkan llama.cpp 42611647462](https://github.com/soobujmiah/ternux/actions/runs/42611647462), [Stable Diffusion CPU/Vulkan 42611647460](https://github.com/soobujmiah/ternux/actions/runs/42611647460), [production HTP 42611647288](https://github.com/soobujmiah/ternux/actions/runs/42611647288), and [integer-HMX candidate 42611647459](https://github.com/soobujmiah/ternux/actions/runs/42611647459). Preview and release-publish jobs were skipped because PR #97 remains draft.

Local checks on this implementation passed: `tests/focused.sh` 130/130; `tests/docs_check.py` 3,018 assertions, 312 internal links, and 19 bilingual pairs; and `git diff --check`. The Termux APT package was rebuilt and reinstalled locally. All 334 packaged asset files matched the source byte-for-byte; `ternux verify --json` passed and `ternux doctor --json` reported 31 OK, 0 warnings, 0 failures, and 1 informational item. XFCE/X11 and PulseAudio remained running (desktop PID 16987). This is package and current-runtime evidence, not clean-device install or owner visual approval.

Release gate 10 remains **HELD**. Exact current-head CI archives have not been transferred to the designated incoming folders or installed on-device. Independent QNN stage correctness and its image-generation target remain open; HTP has documented numerical/operator failures and lacks broad sustained/restart qualification; the wider transitive-license review is incomplete. Camera-video API/client PRs [#904](https://github.com/termux/termux-api/pull/904) and [#242](https://github.com/termux/termux-api-package/pull/242) are still open. Owner final visual review and hosted signed APT clean install/upgrade are also open; the hosted bootstrap, key, and `InRelease` endpoints returned HTTP 404 on this audit. Do not publish v2 or claim stable HTP/QNN support until the release plan's applicable gates pass.

### Stable Diffusion extension component-license audit — 2026-11-09

The exact upstream source pin is `5a1ba5d895bec4e07deab80d6d791721cd59d9c2`; its `ggml` gitlink resolves to `135ce1e0e3f2b0693d3de93d4f6b5fa0a1947820`. CMake inspection found no `FetchContent` or `ExternalProject` dependency acquisition for this build. The `sd-cli` statically includes the pinned GGML submodule, Oniguruma 6.9.10, utf8proc, darts-clone tokenizer data, miniz, nlohmann JSON, and the stb image load/write/resize headers. The exact component and license-source map now lives in `packaging/stable-diffusion/components.json`; the workflow checks the GGML pin, requires Oniguruma/utf8proc/darts/GGML/upstream and Ternux notices, and preserves embedded header notices under `source-notices/`. The optional CMake `_deps` tree is scanned only when present; its presence is recorded, so a missing directory cannot break bundling or be misreported as an existing empty dependency tree. Bundle index and SHA-256 inventory cover every copied notice, source header, and component manifest entry. Local regression checks include absent optional trees, missing component licenses, duplicates, and escaping symlinks. The source/bundle audit passes locally; the updated implementation passed ARM64 CI run `42773827441` on commit `f4bb945`. This audit covers the pinned Stable Diffusion build configuration; the wider Mesa and other release-artifact transitive-license review remains open.


### Artifact rebuild prevention and reuse — 2026-11-10

The ARM64/Vulkan, Stable Diffusion ARM64, HTP ARM64, and integer-HMX candidate
workflows no longer build on pull-request events. Their former `pull_request`
triggers also included `synchronize`; GitHub evaluates path filters against the
whole PR diff, so later documentation-only pushes still matched workflow or
package-input files already present in PR #97. On head `9016bf9`, runs
`42774732346` (llama Vulkan), `42774732436` (Stable Diffusion),
`42774732564` (HTP), and `42774732544` (HMX candidate) were therefore canceled
after the duplicate builds were detected. Heavy candidate builds are now manual
workflow-dispatch operations.

The three publishable workflows and the HMX candidate workflow accept an optional successful
`source_run_id`. Supplying it skips compilation, checks run/workflow/repository,
artifact name and expiry, and compares the build-job definition and package
inputs against the selected build before cross-run artifact download. Leaving it
empty builds a fresh candidate. New candidate uploads retain for 90 days.
Publishing remains a separate explicit workflow input restricted to `main`;
this change has not published any asset.

Read-only Actions metadata and the verifier confirmed that the already-built
`f4bb945576f03a9d8979d7d89553660471dafbaf` artifacts can be reused from runs
`42773827384` (llama Vulkan), `42773827441` (Stable Diffusion), and
`42773827791` (HTP), with no compilation. Their artifact IDs are respectively
`13743217082`, `13743396792`, and `13742783760`. The Vulkan artifact expires
2027-02-08; Stable Diffusion and HTP expire 2026-11-24. HMX candidate run
`42773827449`, artifact `13743875024`, also remains available until
2026-11-24. The HMX workflow can re-upload its exact verified candidate without compiling and renew its 90-day Actions retention. Workflow retention changes do not extend already-uploaded artifacts.
These Actions artifacts are temporary CI copies. A permanent public HTP
prerelease asset already exists, but it is older than this candidate: the
`ternux-llama-htp-sm8735-b11582` release currently serves the 2026-10-13 archive
with SHA-256 `dffcf83fa969f3ccfad238217b4ca7f3d47040e5e5b2fa834ebd3f123d144ea5`
(15,519,631 bytes). The retained 2026-11-10 HTP candidate is Actions run
`42783356495`, artifact `13747701121`, expiring 2027-02-08. Downloading that
retained artifact and checking its sidecar verified archive SHA-256
`a139a6248356a44e89348ddbe1334edaad33f81a9efbe8f5b8fe3c5733dcf3de`
(15,691,323 bytes). Its refresh validated the original successful build run and
archive checksum, then re-uploaded the same archive without compiling. After
PR #97 is merged, the main-only publisher
can reuse run `42783356495` with `publish=true` to replace the existing
prerelease asset without rebuilding; its provenance check requires the source
commit to be an ancestor of `main` and the package inputs/build definition to
remain unchanged. Do not refresh the public asset until exact-artifact device
qualification and the applicable release gate are satisfied. The latest archive
was downloaded only for sidecar/hash verification; it was not extracted or run.


The artifact-reuse workflow commit `89802f73408a1638221c0b3f62c26d212385b2ea` passed Validate `42779265831`, Termux APT `42779265743`, Repository State Contract `42779266172`, and Repo Knowledge Sync `42779266194`. No accelerator build ran on that PR update.
