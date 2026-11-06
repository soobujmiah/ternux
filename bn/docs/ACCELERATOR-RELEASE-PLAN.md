---
title: Accelerator ও ecosystem release completion plan
description: পরবর্তী Ternux release-এর আগে accelerator, package বিতরণ ও artifact installation gate।
lang: bn
alt_url: /docs/ACCELERATOR-RELEASE-PLAN.html
---

Owner direction, ২০২৬-১০-১৪: পরবর্তী stable Ternux release-এর আগে CPU, GPU ও
NPU qualification এবং release preparation শেষ করতে হবে। মূল HTP কাজের পাশাপাশি
standalone QNN image route-টি আলাদা gate হিসেবে থাকবে। অন্য device-এ Ubuntu
install স্থগিত; এটি release blocker নয়। এই plan pending কাজ নথিভুক্ত করে,
shipped capability দাবি করে না। Owner request, ২০২৬-১১-০৬: `pkg install ternux`-এর
জন্য signed Termux APT distribution channel প্রস্তুত করতে হবে; এই নতুন gate
accelerator qualification gate-গুলোর বিকল্প নয়।

| ক্রম | কাজ | বর্তমান অবস্থা | Completion evidence |
|---|---|---|---|
| ১ | PRoot থেকে callable Android/Bionic QNN helper | Runtime/provider, backend/device, VAE context load/free ও encoder graph execution VERIFIED; generic HTP Add known-answer VERIFIED; model output correctness UNVERIFIED | Matching execution headers, tensor metadata, request/response ও known-output accelerator test |
| ২ | বিদ্যমান QNN picture model | CLIP CPU, UNet/VAE HTP graph execution এবং fixed-seed SD1.5 generation SM8735-এ হয়েছে। 25-image soak 25/25 সফল; median/mean 29.76/31.12 s/image, UNet median/mean 15.96/17.03 s/20 step। তিনটি instrumented follow-up 30.797–31.122 s নিয়েছে। একটি profile-এ 880,827,736-byte UNet archive member memfd-এ stream/hash/seal করতে 7.275 s এবং ৪০টি serial HTP request-এ 17.015 s লেগেছে। Device-এর `/sdcard/Llms/AbsoluteReality_qnn2.28_8gen2.zip` model archive উপস্থিত; এর SHA-256 soak report-এর সঙ্গে মেলে। একই seed repeat হয়েছে। ২০২৬-১১-০৬ তারিখে image 02–25 প্রতিটি 512×512 resolution-এ দেখা হয়েছে: সামগ্রিকভাবে দৃশ্যগুলো coherent; image 19-এর ওপরের প্রান্তে ক্ষুদ্র কালো দাগ আছে। Image 01-এ আগে দেখা পানির ওপরের ছোট cyan/black দাগও আছে। Independent stage-tensor correctness UNVERIFIED। | CLIP/UNet/VAE stage tensor স্বাধীন expected value-র সঙ্গে তুলনা এবং measured performance gap তদন্ত ও optimize; model বা runner বদলালে image 01 ও 19 আবার দেখা |
| ৩ | Debian llama.cpp CPU/GPU/HTP | CPU/Vulkan known-answer pass। HVX-only `MUL_MAT` operator suite 1,389/1,389 pass; HMX `MUL_MAT`-এ 529টি `inf` failure। আগের default attention selection-এ HVX matmul-সহ `FLASH_ATTN_EXT` 120 s-এ timeout হওয়ার আগে 1,848 `inf` failure ও 112 pass দেখায়। পরে `GGML_HEXAGON_MM_SELECT=1` ও `GGML_HEXAGON_FA_SELECT=1` দিয়ে suite সম্পন্ন: 5,332 unique case-এর 2,593 pass, 2,732 unsupported, 7 finite numerical-error failure; filtered rerun-এ সাতটিই reproduce হয়েছে। Flash attention launcher-এ বন্ধই আছে। One-token test-এ HVX-only + flash attention off expected `4`; default attention selection-সহ আগের test ভুল token দিয়েছে। Exact-package known-answer, 31/31 layer assignment ও clean cancellation pass। ২০২৬-১১-০৬-এ Vulkan draft-সহ speculative decoding Qwen2.5 1.5B HTP generation rate 19.5 tok/s থেকে কমিয়ে 9.1/7.1 tok/s করেছে (draft window 2/4); তাই এটি গ্রহণ করা হয়নি। ২০২৬-১১-০৭-এর একই prompt-এর ছোট probe-এ default HTP power mode 19.6 tok/s, burst 19.0, Vulkan 17.6 এবং HTP Q4_K_M 15.9 tok/s মেপেছে; প্রতিটি setting-এ একবারের run। Qwen2.5 0.5B Q4_0 নামের file-এর আলাদা তিন-run-per-backend probe-এ HTP median 40.8 tok/s (24/24 layer assign) এবং Vulkan 27.9 tok/s দিয়েছে। llama.cpp GGUF name `qwen2.5-0.5b-instruct` বললেও runtime model type 1B/630.17M parameter দেখায়; তাই result generalize করার আগে model provenance-এর সঙ্গে nominal size মিলিয়ে নিতে হবে। পরের matched তিন-backend test-এ (এক prompt/settings, চার thread, তিনটি interleaved run) median ছিল CPU 8.0, Vulkan 24.8 এবং HTP 46.2 tok/s; সব HTP broker session clean close হয়েছে। ২০২৬-১১-০৭-এ একই Qwen2.5 0.5B label-যুক্ত GGUF file, চার thread, pp128/tg64 ও প্রতি setting-এ তিন repetition দিয়ে same-binary llama-bench repeat-এ CPU (`-ngl 0`) prompt 145.11 ± 12.42 ও generation 12.73 ± 0.75 tok/s; Adreno 825 Vulkan (`-ngl 99`) prompt 360.55 ± 2.12 ও generation 33.73 ± 0.59 tok/s মেপেছে। এটি আগের matched generation run থেকে আলাদা ছোট benchmark method। পূর্ণ log ও command: [device benchmark evidence](../../guides/device-benchmark-evidence.md#2026-11-07-same-build-cpuvulkan-throughput-repeat-qwen25-05b-q4_0)। ২০২৬-১১-০৭-এ আগে থেকে থাকা Qwen2.5 1.5B Q4_K_M model (`/sdcard/LAI/models/qwen2.5-1.5b-instruct-q4_k_m.gguf`; SHA-256 `6a1a2eb6d15622bf3c96857206351ba97e1af16c30d7a74ee38970e434e9407e`)-এ আলাদা CPU/Vulkan benchmark-এ তিন-run generation mean CPU-তে 6.11 ± 0.87 এবং Adreno Vulkan-এ 17.32 ± 0.26 tok/s (চার thread, 128 prompt token, 64 generated token) ছিল। Deterministic arithmetic known-answer test-এ দুটো route-ই `4` দিয়েছে। বিস্তারিত [device benchmark evidence](../../guides/device-benchmark-evidence.md#2026-11-07-qwen25-15b-q4_k_m-cpuvulkan-benchmark)। এগুলো এক device-এর short throughput result; quality/energy/sustained-use result নয়। এগুলো bounded GGUF/llama.cpp result; সব HTP operator qualify বা supported route নয়। | HMX/attention numerical error তদন্ত; অন্য HTP operator, failure/restart ও sustained stability qualify |
| ৪ | Repeat ও sustained device qualification | SM8735-এ thermal status 0-সহ 600টি 720p/16-sample EEVEE frame; packaged CPU/Vulkan-এ তিনটি করে live-generation SIGINT clean-exit ও restart check pass। Exact HTP artifact bounded SIGINT-এ child থেমে `closeSession [0, 0]` দিয়েছে। আলাদা QNN SD1.5 mixed CPU/HTP pipeline 25/25 image-এর 17m36s soak সম্পন্ন করেছে; এটি নির্দিষ্ট experimental workload, সাধারণ NPU stability প্রমাণ নয়। failure/restart ও বিস্তৃত sustained CPU/NPU qualification বাকি। Automatic CPU fallback নেই। | supported path জুড়ে failure/restart ও sustained CPU/NPU আচরণ qualify |
| ৫ | পুনর্ব্যবহারযোগ্য GitHub artifact | CPU/Vulkan ARM64 build ও ABI audit run `38521164812`-এ pass; exact archive isolated install ও CPU/Adreno Vulkan known-answer-ও pass। HTP run `38560288558` checksum, safe-path, isolated install, HTP0 known-answer ও cancellation pass। Metadata-corrected HTP run `38562008524` pass; checksum-verified archive-এ tested runtime payload অপরিবর্তিত, শুধু README/manifest metadata বদলেছে এবং `libcdsprpc.so` / `libfastrpc-dev` dependency যুক্ত হয়েছে। ২০২৬-১১-০৭-এ upstream Mesa 27.0.0 Debian Trixie ARM64 archive-এর checksum release page-এর সঙ্গে মেলে; staged driver `ldd -r`, Vulkan ও Zink GLX Adreno 825-এ pass করেছে। তিনটি interleaved Qwen2.5 0.5B Vulkan run-এ staged 27.0 median 27.2 tok/s, installed 26.3 median 26.6। একই দিনে exact GPU installer phase আলাদা clean Debian 13 PRoot guest-এ pinned archive extract করেছে; loader diversion, Mesa package hold, driver ABI, Adreno 825 Vulkan enumeration ও X11 Zink GLX pass। Active Debian guest ও state অপরিবর্তিত ছিল। Exact source-tag-এর checksum-pinned license bundle package-এ যোগ হয়েছে এবং live Debian updater Turnip 27.0.0-এর পাশে notice-গুলো install ও hash-verify করেছে (`Mesa 27.0.0-devel`, git `6f90e92dfdacc4759d8e9ccb328805d0f0b4439b`; driver SHA-256 `c9333136d9818fa91244d506ac17635988199e337485bd0fff4b0f1aeda6c895`)। HTP experimental। | Binary-to-source component mapping ও বিস্তৃত transitive-license review এখনও বাকি। Correctness ও compatibility gate আলাদা রাখা |
| ৬ | Extension install ও guide | PARTIAL: CPU + Vulkan এবং experimental HTP llama.cpp extension আছে; HTP SM8735/V73-specific ও unsupported। Merged PR `#59` pinned stable-diffusion.cpp CPU/Vulkan extension, fresh-install optional selection/runtime dependency, doctor check, ABI/license audit এবং দুই ভাষার guide যোগ করেছে। ARM64 build/ABI audit run `42295461009`-এ pass; Adreno 825-এ VAE tiling-সহ 512×512/10-step image 101.9s-এ হয়েছে। Tiling ছাড়া VAE-তে device-lost হয়েছে। CPU 256×256/20-step output-ও 391.7s পরে blocky/artifacted, তাই CPU image quality qualify হয়নি; এটি Vulkan route-এর release blocker নয়। Workflow run `42303285336`-এ public prerelease publish হয়েছে; archive SHA-256 `64a2761e680f0791eba476a24f476533c9ae35989d4ab6bbe2ecda26d0d9f336`। `ternux extension install stable-diffusion` checksum verify করে `/home/ternux/.local/opt/ternux-extensions/stable-diffusion`-এ install করেছে; doctor extension-কে OK দেখিয়েছে। Installed binary user model সরাসরি read করে tiled Vulkan VAE-তে 512×512/10-step coherent image 92.91s-এ তৈরি করেছে। CPU image quality unqualified; CPU support claim নয়। Existing Debian guest-এ real `tnx_phase_extras ternux stable-diffusion` optional workload phase শেষ হয়েছে; doctor-এ extension OK (30 OK, 0 fail, আগের experimental HTP warning একটি) ছিল। `libgomp1` ও `libvulkan1` আগে থেকেই current ছিল, তাই clean guest-এ dependency install প্রমাণ হয়নি। QNN SD1.5 research route। বিস্তারিত [SD CPU/Vulkan handoff](../../handoffs/stable-diffusion-cpu-vulkan-qualification-2026-11-07.md)। | Active Debian guest-এ managed install, repair, remove, reinstall, checksum, doctor detection ও actual optional workload phase pass; model weight extension path-এর বাইরে অক্ষত। Clean fresh-install selection/dependency provisioning, cancellation/restart, sustained-use এবং আরও device/model coverage verify; CPU image quality claim নয় |
| ৭ | CLI ও install screen polish | বর্তমান checkout-এ focused test 107/107, Bats 72/72, installer UI render 33/33 pass। ফোনে installed `ternux doctor --json` 27 OK, 0 warning/fail; graphics doctor 8/8 এবং Adreno 825 Turnip renderer পায়। `--shared-tmp` renderer probe Debian-কে Termux:X11 socket দেখায়। ২০২৬-১১-০৭-এ `gtk-launch org.pulseaudio.pavucontrol` দিয়ে desktop entry চালিয়ে global dark theme, Playback controls এবং OpenSL ES input-সহ Input Devices দেখা হয়েছে। Xfce process-এ `MESA_LOADER_DRIVER_OVERRIDE=zink` ছিল, global `GALLIUM_DRIVER` ছিল না। Live X11 capture-এ VLC playback controls-ও visible। Exact upgraded package, typing/welcome/error state ও owner usability review বাকি। | Exact CI package install/reopen করে typing, welcome, error-state ও owner review নথিভুক্ত করা |
| ৮ | Signed Termux APT distribution (`pkg install ternux`) | Local package ও signed-index fixture check pass; প্রকাশিত website APT endpoint-এ v2 InRelease নেই। ফোনে Termux ও Termux:API—দুই app-এই RECORD_AUDIO granted। সীমিত এক-সেকেন্ড Termux:API Opus recording থেকে valid 16 kHz mono Ogg file তৈরি হয়েছে, পরে temporary file মুছে গেছে। আলাদাভাবে Debian guest PulseAudio `Ternux_Microphone` OpenSL source থেকে 119,972 byte audio পেয়েছে (16 kHz mono; peak 1,144, RMS 84.2); client বন্ধ হলে source আবার SUSPENDED। Volume Control input meter খোলা থাকলে source-output তৈরি হয়; app বন্ধ করলে source-output চলে যায় এবং `Ternux_Microphone` IDLE হয়। Idle desktop mic stream খোলা রাখে না। এটি PulseAudio দিয়ে on-demand desktop input যাচাই করে, live Termux:API-to-guest stream নয়। Signing-only workflow run [42311346876](https://github.com/soobujmiah/ternux/actions/runs/42311346876)-এ exact `ternux` 2.0.0 package ও signed repository তৈরি হয় এবং `InRelease` fingerprint `E5527F4D5B83037FF77B65AE5E894BBB81168B1D` দিয়ে verify হয়; publish job skip ছিল। Signed v2 repository এখনও প্রকাশিত নয়; hosted clean install/upgrade যাচাই হয়নি। | API ও OpenSL-এর সীমা স্পষ্ট রাখা; owner-visible mic control ও exact installed artifact qualify; অন্য সব gate বন্ধ হলে signed workflow-এ publish করে hosted clean install/upgrade verify

| ৯ | Model/accelerator artifact coverage ও optional install | OPEN। llama.cpp CPU/Vulkan ও experimental SM8735/V73 HTP artifact আছে। Merged PR `#59`-এর CPU/Vulkan Stable Diffusion extension build/ABI ও public optional prerelease pass; Ternux manager checksum verify করে install করেছে এবং doctor OK দেখায়। Installed package Adreno 825-এ tiled Vulkan দিয়ে 512×512/10-step image 92.91s-এ করেছে। CPU image quality unqualified, CPU capability claim নয়। Active guest-এ managed repair/remove/reinstall model অক্ষত রেখে pass। Fresh-install selection, cancellation/restart ও sustained/device coverage বাকি। User-provided SD1.5 Q8_0 GGUF `/sdcard/Llms/ternux-v2-validation/stable-diffusion-v1-5-pruned-emaonly-Q8_0.gguf`-এ আছে (1,763,578,176 byte; SHA-256 `d0555243938c62faeefb4ac93f6c7a053ad373a4290c5256bce229aeb193bf94`)। QNN SD1.5 runner/helper packaged নয়; independent stage-tensor correctness, quality ও performance বাকি। | প্রতিটি intended CPU/GPU/NPU LLM ও Stable Diffusion route-এর versioned, checksummed, licensed tool artifact, fresh/post-install optional selection, runtime dependency ও target-device workload যাচাই; model weights external রেখে evidence limit স্পষ্ট রাখা |
| ১০ | Ternux version release সম্পূর্ণ করা | HELD। Release criteria এখনও খোলা: independent QNN model-stage correctness ও performance target, HTP numerical failure/operator coverage, বিস্তৃত sustained/failure-restart qualification, dependency-license review, model/accelerator artifact coverage, owner visual review এবং hosted signed APT install/upgrade। Unqualified HTP/QNN route-কে stable support claim-এর বাইরে রাখতে হবে। | আগের প্রতিটি gate বন্ধ ও পুনর্মূল্যায়ন করে installed artifact, public repository, website ও documentation-এর final audit করা

SD1.5 performance gap এখনো qualification item: Ternux QNN runner-এর median
29.76 s/image; একই device-এর আলাদা Local Dream route-এ 512×512, ২০ step-এর মাপ
5.7 s। Ternux result প্রায় 5.2× দীর্ঘ; model ও runtime আলাদা, তাই এটি controlled
A/B test নয়। তিনটি instrumented follow-up image 30.797–31.122 s নিয়েছে। একটি
30.797 s profile-এ 880,827,736-byte UNet member memfd-এ stream/hash/seal করতে
7.275 s এবং ৪০টি serial HTP request-এ 17.015 s লেগেছে। Owner-এর প্রত্যাশা
512×512 image প্রায় 3–5 s-এ তৈরি হওয়া; এটি তদন্তের target, প্রমাণিত capability
বা guarantee নয়। Stable Diffusion এখনো Ternux extension নয়; owner extension
packaging পরে করার সিদ্ধান্ত দিয়েছেন। [QNN performance handoff](../../handoffs/qnn-sd15-performance.md),
[QNN correctness ও image review handoff](../../handoffs/qnn-sd15-correctness.md),
এবং [HTP qualification handoff](../../handoffs/llama-htp-qualification.md) দেখুন।
এই তিনটি repository-only continuation note; এটিই একমাত্র canonical
accelerator/release roadmap, দ্বিতীয় roadmap তৈরি করবেন না।
[Local Dream device evidence](https://github.com/soobujmiah/skb/blob/main/devices/redmi-turbo-4-pro/accelerator-access-audit.md)।

### HTP operator diagnostic (২০২৬-১০-১৪)

Workflow run `38567329752`-এর exact Linux ARM64 artifact Ternux Binder/FastRPC
broker দিয়ে SM8735 device-এ test করা হয়েছে। Default HMX selection-এ
`test-backend-ops -b HTP0 -o MUL_MAT`-এ **৫২৯টি case fail** করেছে; প্রতিটিতে
infinite error এসেছে। Device report-এ Hexagon v73, HMX উপস্থিতি এবং 8 MB VTCM
দেখিয়েছে। `GGML_HEXAGON_MM_SELECT=1` দিয়ে HVX-only `MUL_MAT` suite পরে বড়
time bound-এ আবার চালিয়ে **1,389/1,389 HTP test pass** হয়েছে। CPU backend skip;
HTP backend OK দিয়েছে এবং broker session `closeSession [0, 0]` দিয়ে cleanly
বন্ধ হয়েছে। এটি পরীক্ষিত HVX `MUL_MAT` case qualify করে, সব HTP operator নয়।

এতে এই device-এ HMX `MUL_MAT` correctness failure আলাদা হয়েছে, তবে hardware বা
kernel cause শনাক্ত হয়নি। Upstream-এর v73 report-এ ভিন্ন SM7750 device-এ FP16
HMX না থাকার সঙ্গে একই ধরনের failure নথিভুক্ত; এটি diagnostic lead, SM8735-এ একই
capability নেই—তার প্রমাণ নয়। আলাদা upstream v75 report HMX flash-attention race
নথিভুক্ত করেছে। দেখুন [SM7750 HMX report](https://github.com/ggml-org/llama.cpp/issues/29473)
এবং [SM8650 flash-attention report](https://github.com/ggml-org/llama.cpp/issues/26759)।
পরের gate: SM8735-এ HMX FP16 capability probe, অন্য HVX operator coverage এবং
flash attention ঠিক করে আবার পরীক্ষা। Command ও artifact provenance আছে
[experimental HTP guide](../guides/llama-htp-experimental.md#সর্বশেষ-operator-check)-এ।

প্রথম `FLASH_ATTN_EXT` run-এ `GGML_HEXAGON_MM_SELECT=1` দিয়ে HVX matmul হলেও
flash-attention selection default-এ ছিল। ১২০ সেকেন্ডে timeout হওয়ার আগে ৪,৬৬০টি
output line-এ ১,৮৪৮টি `inf` error ও ১১২টি pass ছিল; run অসম্পূর্ণ। পরে
`GGML_HEXAGON_MM_SELECT=1 GGML_HEXAGON_FA_SELECT=1` দিয়ে matmul ও attention
দুটোই HVX নির্বাচন করে suite শেষ করা হয়েছে: ৫,৩৩২ unique case-এর ২,৫৯৩ pass,
২,৭৩২ unsupported, এবং tolerance-এর বেশি finite numerical error-সহ ৭টি failure।
Filtered rerun-এ সাতটি failed parameter case-ই আবার reproduce হয়েছে। ওই failure
এর জন্য test exit 1 দিয়েছে; broker CDSP session cleanly close করেছে। এতে আগের
error pattern সীমিত হয়েছে, কিন্তু flash attention qualify হয়নি; launcher-এ এটি
এখনও বন্ধ। Raw log আছে
`/home/sbj/npu-probe-2026-10-13/htp-op-qualification-38567329752/`-এ।

HVX matmul ও ছোট queue setting (`OPBATCH=128`, `OPQUEUE=2`) দিয়ে broad
`test-backend-ops -b HTP0` run চালিয়ে abort-এর আগে 3,520টি passing case line,
`DIV`, `GET_ROWS`, `SWIGLU_CLAMP`, `ADD` ও `SUB`-এ ৪৫টি numerical-error failure,
এবং ৪,৮৭৪টি unsupported case দেখা গেছে। পরে
`dspqueue_read failed: 0x0000002e` দিয়ে child exit -6 করেছে; broker CDSP session
cleanly close করেছে। এটি **অসম্পূর্ণ**, সব operator-এর result নয়। আলাদা
`MUL_MAT_W4A4` check 1/1 pass হয়েছে; broad-run abort-এর কারণ অজানা।

QNN archive-এর graph CPU/GPU support প্রমাণ করে না; প্রতিটি backend-এর compatible
weight/backend pair আলাদা। HTP-এর জন্য compiled `.bin` context CPU/GPU-তে নিজে
থেকে portable নয়। Valid prerequisite না থাকলে BLOCKED লিখুন; না-চালানো test-কে
PASS বা FAILED বলবেন না। Optional 1.58-bit/Q8 experiment correctness gate-এর
বাইরে।

## Vulkan evidence-এর Turnip নির্ভরতা

Vulkan known-answer ফল Debian-এর Mesa-র উপর নির্ভর করে না। ২০২৬-১০-১৩-এ Adreno
825-এ `mesa-vulkan-drivers 25.0.7-2+deb13u1` কোনো Adreno device enumerate করেনি;
শুধু CPU-type `llvmpipe` দেখা গেছে। Software GL জোর করে চালালে ধীর render নয়,
`SIGILL` হয়েছে। তাই Vulkan result Turnip-নির্ভর। Ternux GPU phase upstream
Debian Trixie ARM64 archive-এর pinned `mesa-27.0.0-devel-20261025` ব্যবহার করে
এবং install-এর আগে SHA-256
`b711d1d9ab5537ee9085da8896dfe2115e791b33aa317fe37538f276c967d687` যাচাই করে। ২০২৬-১১-০৭-এ
exact archive-এর staged Vulkan ও Zink GLX test Adreno 825-এ pass করেছে; clean guest-এ
installer extraction-ও যাচাই হয়েছে। এটি upstream binary dependency, Ternux-built
artifact নয়; ফলের সঙ্গে এই তথ্য উল্লেখ করতে হবে। Checksum-verified archive-এ
`COPYING`, `LICENSE`, `NOTICE` বা Debian copyright member নেই। Ternux matching Mesa
source commit-এর license overview ও সব license text
`lib/licenses/mesa-27.0.0-devel-20261025/`-এ সংরক্ষণ করেছে; GPU phase এগুলো
`/usr/local/share/doc/ternux/mesa-27.0.0-devel-20261025/`-এ install ও checksum verify
করে। ২০২৬-১১-০৭-এ live Debian updater Mesa 27.0.0 এবং notice bundle install করে সব
hash verify করেছে। Binary-to-source component mapping এবং broader transitive license
inventory এখনও বাকি; source tree-এর প্রতিটি license binary-তে প্রযোজ্য—এমন দাবি এই
bundle করে না।

Clean device-এ driver অনুপস্থিত থাকলে clean-device Vulkan install pass করা যাবে
না। Pinned input mutable download সমস্যা কমায়; exact upstream notice সংরক্ষণ ও verify
করা হয়েছে, তবে broader transitive review বাকি। [Graphics persistence](GRAPHICS-PERSISTENCE.html)-এ
apt-safe driver layout আছে; এটি clean-device qualification-এর বিকল্প নয়।

২০২৬-১১-০৭-এ X11 visual check-এ দেখা গেছে accelerated Zink `glxgears` full-screen-এ
পরিষ্কার render করে, কিন্তু 300×300 window-তে ডান পাশের স্থির অবস্থানে red geometry
fragment বারবার থেকে যায়—Mesa 27.0.0 Turnip update-এর পরও। একই live display-তে Adreno
825 Vulkan `vkcube` পরিষ্কার render করেছে। এটি windowed GLX-এর observed artifact; এর কারণ
এবং অন্য application-এ প্রভাব এখনও qualified নয়।

## পৃথক QNN experiment ও পরের gate

[QNN standalone experiment](../../experiments/qnn-native/README.md)-এ implementation
ও reproduction command আছে। Solver-space mismatch ঠিক করার পর fixed-seed image
repeat হয় এবং coherent দেখায়, তবে cyan artifact আছে। এটি independent QNN
stage-tensor correctness প্রমাণ করে না।

[Benchmark summary](BENCHMARKS.html) সংক্ষিপ্ত ফল দেয়।
[Repository-only device evidence](https://github.com/soobujmiah/ternux/blob/main/bn/guides/device-benchmark-evidence.md)-এ
HTP failure matrix ও conditional HVX result আছে। Experimental HTP package-এর
install ও সীমা [repository HTP guide](https://github.com/soobujmiah/ternux/blob/main/bn/guides/llama-htp-experimental.md)-এ
আছে। LAI-এর evidence তার নিজস্ব Android research note-এ থাকবে; এই plan LAI
runtime বা device gate বদলায় না।
