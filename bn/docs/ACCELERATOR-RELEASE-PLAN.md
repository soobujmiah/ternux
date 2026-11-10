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
| ২ | বিদ্যমান QNN picture model | CLIP CPU, UNet/VAE HTP graph execution এবং fixed-seed SD1.5 generation SM8735-এ হয়েছে। 25-image soak 25/25 সফল; median/mean 29.76/31.12 s/image, UNet median/mean 15.96/17.03 s/20 step। তিনটি instrumented follow-up 30.797–31.122 s নিয়েছে। একটি profile-এ 880,827,736-byte UNet archive member memfd-এ stream/hash/seal করতে 7.275 s এবং ৪০টি serial HTP request-এ 17.015 s লেগেছে। Device-এর `/sdcard/Llms/AbsoluteReality_qnn2.28_8gen2.zip` model archive উপস্থিত; এর SHA-256 soak report-এর সঙ্গে মেলে। একই seed repeat হয়েছে। ২০২৬-১১-০৮ তারিখে standard-library CLIP tokenizer archive known answer `a cat` → `[320, 2368]` মেলায়; দুইবার তৈরি ৭৭×৭৬৮ input tensor-এর SHA-256 একই `c224f03dbd0fb9abed0dd6747f8607d1059da847e74bf6fab02c34c65c59ccb3`। Native MNN 3.6.1 CPU দুই default prompt-এর finite, exact-repeat CLIP hidden state দিয়েছে। Seed 20261014-এ ২০-step native-CLIP + QNN HTP UNet/VAE rerun 34.21 s-এ শেষ হয়েছে এবং image SHA-256 `1a13957f5cb65132d98fc212756bdcf8d8b959d69feba84902a9314036764fc3` আগের output-এর সঙ্গে হুবহু মেলে; ছবিতে আগের চিহ্নিত ছোট cyan/black পানির দাগটি এখনও আছে। এটি একবারের repeatability/visual check—independent stage-tensor oracle বা speed improvement নয়; stage correctness এখনও **UNVERIFIED**। ২০২৬-১১-০৬ তারিখে image 02–25 প্রতিটি 512×512 resolution-এ দেখা হয়েছে: সামগ্রিকভাবে দৃশ্যগুলো coherent; image 19-এর ওপরের প্রান্তে ক্ষুদ্র কালো দাগ আছে। Image 01-এ আগে দেখা পানির ওপরের ছোট cyan/black দাগও আছে। Independent stage-tensor correctness UNVERIFIED। | CLIP/UNet/VAE stage tensor স্বাধীন expected value-র সঙ্গে তুলনা এবং measured performance gap তদন্ত ও optimize; model বা runner বদলালে image 01 ও 19 আবার দেখা |
| ৩ | Debian llama.cpp CPU/GPU/HTP | CPU/Vulkan known-answer pass। ২০২৬-১১-০৭-এ installed managed llama.cpp b11582 extension-এ আগে থেকে থাকা `/sdcard/Llms/qwen2.5-0.5b-instruct-q4_0.gguf` দিয়ে CPU ও Adreno 825 Vulkan—দুই route-এ `2 + 2 = 4` pass করেছে; verbose Vulkan log-এ 25/25 layer offload দেখা গেছে। একই binary-তে তিন repetition (pp128/tg64, দুই thread) মেপেছে CPU 133.09 ± 1.39 / 13.15 ± 0.08 tok/s এবং Vulkan 360.96 ± 5.53 / 33.94 ± 0.52 tok/s। `llama-bench` এই file-কে `qwen2 1B Q4_0`, 630.17M parameter হিসেবে শনাক্ত করে, filename-এর 0.5B label সত্ত্বেও। এই check exact installed artifact ও model-এর evidence; দীর্ঘস্থায়ী বা পূর্ণ quality qualification নয়। পূর্ণ log: [device benchmark evidence](../../guides/device-benchmark-evidence.md#2026-11-07-managed-extension-cpuvulkan-known-answer-check-qwen-gguf)। HVX-only `MUL_MAT` operator suite 1,389/1,389 pass; HMX `MUL_MAT`-এ 529টি `inf` failure। আগের default attention selection-এ HVX matmul-সহ `FLASH_ATTN_EXT` 120 s-এ timeout হওয়ার আগে 1,848 `inf` failure ও 112 pass দেখায়। পরে `GGML_HEXAGON_MM_SELECT=1` ও `GGML_HEXAGON_FA_SELECT=1` দিয়ে suite সম্পন্ন: 5,332 unique case-এর 2,593 pass, 2,732 unsupported, 7 finite numerical-error failure; filtered rerun-এ সাতটিই reproduce হয়েছে। Flash attention launcher-এ বন্ধই আছে। One-token test-এ HVX-only + flash attention off expected `4`; default attention selection-সহ আগের test ভুল token দিয়েছে। Exact-package known-answer, 31/31 layer assignment ও clean cancellation pass। ২০২৬-১১-০৬-এ Vulkan draft-সহ speculative decoding Qwen2.5 1.5B HTP generation rate 19.5 tok/s থেকে কমিয়ে 9.1/7.1 tok/s করেছে (draft window 2/4); তাই এটি গ্রহণ করা হয়নি। ২০২৬-১১-০৭-এর একই prompt-এর ছোট probe-এ default HTP power mode 19.6 tok/s, burst 19.0, Vulkan 17.6 এবং HTP Q4_K_M 15.9 tok/s মেপেছে; প্রতিটি setting-এ একবারের run। Qwen2.5 0.5B Q4_0 নামের file-এর আলাদা তিন-run-per-backend probe-এ HTP median 40.8 tok/s (24/24 layer assign) এবং Vulkan 27.9 tok/s দিয়েছে। llama.cpp GGUF name `qwen2.5-0.5b-instruct` বললেও runtime model type 1B/630.17M parameter দেখায়; তাই result generalize করার আগে model provenance-এর সঙ্গে nominal size মিলিয়ে নিতে হবে। পরের matched তিন-backend test-এ (এক prompt/settings, চার thread, তিনটি interleaved run) median ছিল CPU 8.0, Vulkan 24.8 এবং HTP 46.2 tok/s; সব HTP broker session clean close হয়েছে। ২০২৬-১১-০৭-এ একই Qwen2.5 0.5B label-যুক্ত GGUF file, চার thread, pp128/tg64 ও প্রতি setting-এ তিন repetition দিয়ে same-binary llama-bench repeat-এ CPU (`-ngl 0`) prompt 145.11 ± 12.42 ও generation 12.73 ± 0.75 tok/s; Adreno 825 Vulkan (`-ngl 99`) prompt 360.55 ± 2.12 ও generation 33.73 ± 0.59 tok/s মেপেছে। এটি আগের matched generation run থেকে আলাদা ছোট benchmark method। পূর্ণ log ও command: [device benchmark evidence](../../guides/device-benchmark-evidence.md#2026-11-07-same-build-cpuvulkan-throughput-repeat-qwen25-05b-q4_0)। ২০২৬-১১-০৭-এ আগে থেকে থাকা Qwen2.5 1.5B Q4_K_M model (`/sdcard/LAI/models/qwen2.5-1.5b-instruct-q4_k_m.gguf`; SHA-256 `6a1a2eb6d15622bf3c96857206351ba97e1af16c30d7a74ee38970e434e9407e`)-এ আলাদা CPU/Vulkan benchmark-এ তিন-run generation mean CPU-তে 6.11 ± 0.87 এবং Adreno Vulkan-এ 17.32 ± 0.26 tok/s (চার thread, 128 prompt token, 64 generated token) ছিল। Deterministic arithmetic known-answer test-এ দুটো route-ই `4` দিয়েছে। বিস্তারিত [device benchmark evidence](../../guides/device-benchmark-evidence.md#2026-11-07-qwen25-15b-q4_k_m-cpuvulkan-benchmark)। একই আগে থেকে থাকা Qwen2.5 1.5B Q4_K_M model-এ interleaved CPU/Vulkan/HTP তিন round-এই answer 4 এসেছে: median generation CPU 7.6, Adreno 825 Vulkan 18.2 এবং managed HTP 18.9 tok/s। CPU/Vulkan b11582 একই binary, HTP আলাদা build। প্রতিটি HTP session clean close হয়েছে। এটি সীমিত workload comparison—same-binary, thermal, energy বা বিস্তৃত quality result নয়; command ও detail [matched benchmark record](../../guides/device-benchmark-evidence.md#2026-11-07-matched-qwen25-15b-cpuvulkanhtp-generation)-এ। একই 1.5B model-এ তিন HTP run করে generation thread 1/2/4 (batch thread 4 স্থির) অনুযায়ী median 18.9/18.2/18.4 tok/s মাপা হয়েছে; run order স্থির ও CPU use মাপা হয়নি, তাই ফল নিশ্চিত নয় এবং default বদলানোর সুপারিশ নয়। [Thread-scaling evidence](../../guides/device-benchmark-evidence.md#2026-11-07-htp-cpu-thread-scaling)। Installed production HTP HVX route-এ দুই আগে থেকে থাকা Qwen model দিয়ে দশ-chunk Wikitext-2 PPL screen pass: CPU বনাম HTP Q4_0-তে 19.0657 বনাম 19.0715 (relative difference 0.03%), আর 1.5B Q4_K_M-এ 12.1464 বনাম 12.1015 (0.37%)। এটি শুধু এই exact দুই screening workload-এর model-level numerical agreement সমর্থন করে; operator, sustained ও বিস্তৃত quality gate খোলা। [Production HTP PPL evidence](../../guides/device-benchmark-evidence.md#2026-11-07-installed-htp-hvx-perplexity-screen)। অতিরিক্তভাবে unmerged llama.cpp PR #29740 (commit `08c83734f9c5c3b497e98b96f1a380f5a6084468`; SHA-256 `52877aad044c6da3f701d0230fde86520ce26066a412118bfb93e1a6f238de0a`) থেকে disposable CI artifact নিয়ে isolated Debian guest-এ পরীক্ষা হয়েছে। SM8735 HTP V73 probe FP16 HMX পায়নি এবং integer HMX বেছে নিয়েছে; Qwen2.5 0.5B নামের Q4_0 model-এ 25/25 layer HTP0-তে দিয়ে উত্তর তৈরি করেছে। একই setting-এর তিনটি cold-start run-এ 48.5/47.3/49.7 tok/s (median 48.5) এবং প্রতিবার CDSP session clean close হয়েছে। `MUL_MAT` 1,588/1,588 এবং `GATED_DELTA_NET` 43/43 pass করেছে; সম্পূর্ণ ও supported-size `FLASH_ATTN_EXT` test দুটোই DSP `INTERNAL-ERROR` দিয়ে abort করেছে (child signal 6), যদিও broker প্রতিটি session clean close করেছে। Artifact-টি production extension বদলায়নি। ২০২৬-১১-০৭-এ একই SM8735 candidate ও আগে থেকে থাকা Qwen GGUF-এ CPU reference-এর সঙ্গে perplexity screen-এ 630.17M-parameter Q4_0 file-এ CPU বনাম integer-HMX PPL 19.1083 বনাম 19.0430 (relative difference 0.34%), এবং Qwen 1.5B Q4_K_M file-এ 12.1935 বনাম 12.1015 (0.75%) মাপা হয়েছে; প্রতিটিতে Wikitext-2-এর দশটি 512-token chunk ব্যবহার করা হয়, HTP session clean close হয়েছে। এটি শুধু এই exact screening workload-গুলোর numerical agreement সমর্থন করে। Qwen2.5 1.5B Q4_K_M model-এ candidate-এর আলাদা run `2 + 2`-এর জন্য `4` দিয়েছে, 18.7 tok/s-এ; CDSP clean close হয়েছে। Candidate unmerged, SM8735-তে এর `FLASH_ATTN_EXT` abort করেছে, এবং release-qualified নয়. পূর্ণ পদ্ধতি ও ফল: [device benchmark evidence](../../guides/device-benchmark-evidence.md#2026-11-07-sm8735-integer-hmx-model-perplexity-screen)। বিস্তারিত [device benchmark evidence](../../guides/device-benchmark-evidence.md#2026-11-07-sm8735-integer-hmx-candidate-probe)। এগুলো এক device-এর short throughput result; quality/energy/sustained-use result নয়। এগুলো bounded GGUF/llama.cpp result; সব HTP operator qualify বা supported route নয়। | HMX/attention numerical error তদন্ত; অন্য HTP operator, failure/restart ও sustained stability qualify |
| ৪ | Repeat ও sustained device qualification | SM8735-এ thermal status 0-সহ 600টি 720p/16-sample EEVEE frame; packaged CPU/Vulkan-এ তিনটি করে live-generation SIGINT clean-exit ও restart check pass। Exact HTP artifact bounded SIGINT-এ child থেমে `closeSession [0, 0]` দিয়েছে। আলাদা QNN SD1.5 mixed CPU/HTP pipeline 25/25 image-এর 17m36s soak সম্পন্ন করেছে; এটি নির্দিষ্ট experimental workload, সাধারণ NPU stability প্রমাণ নয়। ২০২৬-১১-০৭-এ আগে থেকে থাকা Qwen2.5 1.5B Q4_K_M model-এ তিনটি independent cold-start HTP run-এই `4` এসেছে (22.0–22.3 tok/s); সব broker child exit 0 এবং CDSP session `[0, 0]` দিয়ে close হয়েছে। Qwen2.5 0.5B-named Q4_0 file-এ আরও পাঁচটি cold-start check-ও `4` এবং clean close দিয়েছে। এই নির্দিষ্ট short reopen check pass। ২০২৬-১১-০৭-এর follow-up-এ Qwen2.5 1.5B দিয়ে আরও পাঁচটি independent HTP cold start হয়েছে (প্রতিটিতে প্রথম answer 4, 19.6–19.9 tok/s, child/CDSP clean close); একটি continuous 2,048-token HTP session-ও 136 s-এ শেষ হয়েছে (15.5 tok/s, clean close)। এটি একটি model-এর bounded session evidence, thermal soak বা বিস্তৃত CPU/NPU stability qualification নয়। Qwen2.5 1.5B HTP-তে 4,096-token cap দিয়ে আরেকটি run battery temperature 43.0 °C হলে ইচ্ছাকৃতভাবে SIGINT-এ থামানো হয়েছে (থামার পরপর 43.3 °C); আংশিক output 12.9 tok/s, cancel signal 2-তে broker child exit 0 এবং CDSP close `[0, 0]`। পুনরাবৃত্তিমূলক ও তথ্যগতভাবে ভুল text-কে quality evidence ধরা হয়নি; system thermal zone-গুলো hardware অনুযায়ী শনাক্ত করা হয়নি। একটি controlled cancel-এর পর reopen check-এ `4` এসেছে (16.7 tok/s, child exit 0, CDSP `[0, 0]`)। Single-turn chat-format France-capital prompt CPU/Vulkan/HTP-তে `Paris` দিয়েছে; 3.3/16.6/15.5 tok/s হলো ছোট no-warmup spot check, backend ranking বা বিস্তৃত quality result নয়। এই clean path-গুলোর বাইরে failure recovery এবং বিস্তৃত sustained CPU/NPU qualification এখনও বাকি। Automatic CPU fallback নেই। | supported path জুড়ে failure/restart ও sustained CPU/NPU আচরণ qualify |
| ৫ | পুনর্ব্যবহারযোগ্য GitHub artifact | CPU/Vulkan ARM64 build ও ABI audit run `38521164812`-এ pass; exact archive isolated install ও CPU/Adreno Vulkan known-answer-ও pass। HTP run `38560288558` checksum, safe-path, isolated install, HTP0 known-answer ও cancellation pass। Metadata-corrected HTP run `38562008524` pass; checksum-verified archive-এ tested runtime payload অপরিবর্তিত, শুধু README/manifest metadata বদলেছে এবং `libcdsprpc.so` / `libfastrpc-dev` dependency যুক্ত হয়েছে। ২০২৬-১১-০৭-এ upstream Mesa 27.0.0 Debian Trixie ARM64 archive-এর checksum release page-এর সঙ্গে মেলে; staged driver `ldd -r`, Vulkan ও Zink GLX Adreno 825-এ pass করেছে। তিনটি interleaved Qwen2.5 0.5B Vulkan run-এ staged 27.0 median 27.2 tok/s, installed 26.3 median 26.6। একই দিনে exact GPU installer phase আলাদা clean Debian 13 PRoot guest-এ pinned archive extract করেছে; loader diversion, Mesa package hold, driver ABI, Adreno 825 Vulkan enumeration ও X11 Zink GLX pass। Active Debian guest ও state অপরিবর্তিত ছিল। Exact source-tag-এর checksum-pinned license bundle package-এ যোগ হয়েছে এবং live Debian updater Turnip 27.0.0-এর পাশে notice-গুলো install ও hash-verify করেছে (`Mesa 27.0.0-devel`, git `6f90e92dfdacc4759d8e9ccb328805d0f0b4439b`; driver SHA-256 `c9333136d9818fa91244d506ac17635988199e337485bd0fff4b0f1aeda6c895`)। HTP experimental। | llama.cpp CPU/Vulkan artifact workflow-এ tracked upstream LICENSE/LICENCE, COPYING, NOTICE, COPYRIGHT, AUTHORS, PATENTS ও UNLICENSE-এর ১১টি text index ও প্রতি-file SHA-256 manifest-সহ bundle হয়। Run `42410053376`-এ ARM64 build ও ৬৯টি ELF-এর ABI audit pass করেছে; সব package dependency resolve হয়েছে, সর্বোচ্চ GLIBC requirement 2.38। Audit notice path, hash ও archive membership যাচাই করেছে। Public CPU/Vulkan prerelease archive refresh করে আবার download করা হয়েছে; SHA-256 `bf5e80362620c52e43837949953c00aee6d80be5d87fc45f44911d8624cc3871`। এখন `COMPONENTS.json` generator প্রতিটি file-এর hash, upstream source module, সুনির্দিষ্ট llama.cpp/Ternux commit, build option, runtime dependency ও bundled notice inventory ধরে। Recorded upstream commit দিয়ে বর্তমান published archive-এর ১১৫টি file map করে যাচাই হয়েছে; public archive-এ নতুন map এখনো প্রকাশ করা হয়নি। PR candidate run [42433612276](https://github.com/soobujmiah/ternux/actions/runs/42433612276) read-only repository access-এ শেষ হয়েছে এবং নির্দিষ্ট ARM64 archive upload করেছে (SHA-256 `b72413d6a1ac928c6fb7a89062673e76e2ec6a19c1a72c14fc58c8ad3c319aa8`)। `COMPONENTS.json`-এ packaged ১১৫টি file-এর hash ও source mapping আছে; download করা archive-এর ABI/license audit-এ ৬৯টি AArch64 ELF, সব dependency resolve, সর্বোচ্চ GLIBC 2.38 এবং `$ORIGIN/../lib` RUNPATH pass করেছে। আলাদা public publisher job skip হয়েছে; public prerelease বদলায়নি। PR candidate build/upload read-only access-এ হয়। Public release update-এর জন্য `main` থেকে workflow-dispatch explicit opt-in লাগে এবং release-write permission শুধু publisher job পায়। এই candidate public release asset নয়। Correctness ও compatibility gate আলাদা রাখা |
| ৬ | Extension install ও guide | PARTIAL: CPU + Vulkan এবং experimental HTP llama.cpp extension আছে; HTP SM8735/V73-specific ও unsupported। Merged PR `#59` pinned stable-diffusion.cpp CPU/Vulkan extension, fresh-install optional selection/runtime dependency, doctor check, ABI/license audit এবং দুই ভাষার guide যোগ করেছে। ARM64 build/ABI audit run `42295461009`-এ pass। Latest branch build `42425110113`-ও ARM64 build/ABI audit এবং ১১টি license notice check-এ পাস করেছে; CI artifact `ternux-stable-diffusion-vulkan-linux-arm64-master-1053-candidate.zip` 27,026,209 byte (Actions artifact ID `13595256940`, archive SHA-256 `82a71359c611625ba68546f7cb06f3691ea37a053810eba28723e2f56e0b3fd8`)। এটি Actions candidate, published release asset নয়। Adreno 825-এ VAE tiling-সহ 512×512/10-step image 101.9s-এ হয়েছে। Tiling ছাড়া VAE-তে device-lost হয়েছে। CPU 256×256/20-step output-ও 391.7s পরে blocky/artifacted, তাই CPU image quality qualify হয়নি; এটি Vulkan route-এর release blocker নয়। Workflow run `42303285336`-এ public prerelease publish হয়েছে; archive SHA-256 `64a2761e680f0791eba476a24f476533c9ae35989d4ab6bbe2ecda26d0d9f336`। `ternux extension install stable-diffusion` checksum verify করে `/home/ternux/.local/opt/ternux-extensions/stable-diffusion`-এ install করেছে; doctor extension-কে OK দেখিয়েছে। Installed binary user model সরাসরি read করে tiled Vulkan VAE-তে 512×512/10-step coherent image 92.91s-এ তৈরি করেছে। CPU image quality unqualified; CPU support claim নয়। Existing Debian guest-এ real `tnx_phase_extras ternux stable-diffusion` optional workload phase শেষ হয়েছে; doctor-এ extension OK (30 OK, 0 fail, আগের experimental HTP warning একটি) ছিল। ২০২৬-১১-০৭-এ একই actual optional phase আলাদা clean Debian 13 Trixie PRoot guest-এ চালানো হয়েছে, যেখানে `libgomp1`/`libvulkan1` অনুপস্থিত ছিল। Phase dependency-গুলো install করেছে, public pinned archive checksum-verify করে install করেছে, clean guest doctor extension check 1 OK/0 warning/0 fail দিয়েছে; `sd-cli --help` চলে এবং `ldd -r` সব dependency resolve করেছে। এরপর exact GPU phase pinned Turnip archive ও notices install করেছে; Vulkan Adreno 825-কে GPU0 হিসেবে দেখেছে, আর আগে থেকে থাকা Q8_0 model দিয়ে tiled Vulkan-এ 512×512/10-step image 91.18s-এ তৈরি হয়েছে। PNG valid, এবং SHA-256 আগের reviewed same-seed output-এর সঙ্গে মেলে। এই নির্দিষ্ট clean-guest GPU workload pass; fresh X11 desktop বা install menu নয়। QNN SD1.5 research route। বিস্তারিত [SD CPU/Vulkan handoff](../../handoffs/stable-diffusion-cpu-vulkan-qualification-2026-11-07.md)। | Active Debian guest-এ managed install, repair, remove, reinstall, checksum, doctor detection ও actual optional workload phase pass; model weight extension path-এর বাইরে অক্ষত। Fresh-install menu selection, clean-guest X11 desktop, cancellation/restart, sustained-use এবং আরও device/model coverage verify; CPU image quality claim নয় |
| ৭ | CLI ও install screen polish | আগের PR head `8c2798df58b0d63ff10626c27e3a1ae5b7c51e03`-এর required PR check pass করেছিল: focused shell/behavior/docs (122/122), repository-state contract, knowledge sync, Termux APT package inspection, llama.cpp CPU/Vulkan build, Stable Diffusion CPU/Vulkan build এবং SM8735 HTP candidate build। Run: [Validate 42486551774](https://github.com/soobujmiah/ternux/actions/runs/42486551774), [APT package 42486551766](https://github.com/soobujmiah/ternux/actions/runs/42486551766), [llama.cpp 42486551788](https://github.com/soobujmiah/ternux/actions/runs/42486551788), [Stable Diffusion 42486551833](https://github.com/soobujmiah/ternux/actions/runs/42486551833), [HTP candidate 42486551768](https://github.com/soobujmiah/ternux/actions/runs/42486551768); optional preview publish skip হয়েছে। Code-bearing commit `b49378574f65b37becfe34c4e3d2071096e123bb`-এ সব required check pass: [Validate 42489951685](https://github.com/soobujmiah/ternux/actions/runs/42489951685), [APT package 42489951723](https://github.com/soobujmiah/ternux/actions/runs/42489951723), [llama.cpp CPU/Vulkan 42489951725](https://github.com/soobujmiah/ternux/actions/runs/42489951725), [Stable Diffusion 42489951743](https://github.com/soobujmiah/ternux/actions/runs/42489951743), [HTP candidate 42489951714](https://github.com/soobujmiah/ternux/actions/runs/42489951714), [repository contract 42489951643](https://github.com/soobujmiah/ternux/actions/runs/42489951643) এবং [knowledge sync 42489951732](https://github.com/soobujmiah/ternux/actions/runs/42489951732)। CI candidate artifact হলো APT `ternux-apt-unsigned-ci-c9dbad961869962bfd22cf8151f22a6055d59d16` (metadata ID `13620503151`), Stable Diffusion `ternux-stable-diffusion-vulkan-linux-arm64-master-1053-candidate` (`13621820236`) এবং HTP `ternux-llama-htp-sm8735-integer-hmx-v73-candidate` (`13621313756`)। এগুলো শুধু build/package evidence, device qualification নয়; exact-artifact install-এর জন্য owner-mediated handoff বাকি। HTP result build/package evidence, device qualification নয়। ফোনে বর্তমান checkout-এর `bin/ternux doctor --json` 31 OK, 0 warning/fail; graphics doctor 8/8 এবং Adreno 825 Turnip renderer পায়। Doctor এখন `ldd` probe-এ managed extension-এর `lib/` directory যোগ করে, ফলে bundled HTP library-কে ভুল করে missing দেখায় না। Workflow run [42339235853](https://github.com/soobujmiah/ternux/actions/runs/42339235853)-এর unsigned CI package, project commit `b3a0f894d5f531bf625500894de87160980596c4`, SHA-256 `30541cddf114a201f66c5e67ff121e4d8cdb1bb2c830275241980bc99f07f9de`। Isolated extraction-এ `--version`, `guides` ও packaged shell script-গুলোর `bash -n` pass; live phone/guest-এ ওই artifact-এর `doctor --json` 31 OK, 0 warning, 0 failure দিয়েছে। এটি APT দিয়ে install বা ওই package থেকে GUI reopen-এর বিকল্প নয়। `--shared-tmp` renderer probe Debian-কে Termux:X11 socket দেখায়। ২০২৬-১১-০৭-এ `gtk-launch org.pulseaudio.pavucontrol` দিয়ে desktop entry চালিয়ে global dark theme, Playback controls এবং OpenSL ES input-সহ Input Devices দেখা হয়েছে। Xfce process-এ `MESA_LOADER_DRIVER_OVERRIDE=zink` ছিল, global `GALLIUM_DRIVER` ছিল না। Live X11 capture-এ VLC playback controls-ও visible। Exact main CI Ternux package install-এর পর active 752×1155 Termux:X11 display-এ Xfce Applications → Multimedia menu থেকে Volume Control তিনটি আলাদা open/close cycle-এ চালিয়েছি। প্রতিবার dark theme ও OpenSL ES Output control 500×400 window-এ readable ছিল এবং পুরো window screen-এর মধ্যে fit করেছে; তৃতীয়বার Input Devices tab-এ OpenSL ES Input source-ও দেখা গেছে। শুধু আমার প্রতিটি test instance বন্ধ করেছি; শেষবার বন্ধ করার পর PulseAudio OpenSL sink ও microphone source IDLE হয়েছে, Xfce, Termux:X11 ও PulseAudio চালু থেকেছে। এটি বিদ্যমান desktop-এ repeated menu launch যাচাই করে; upgraded Ternux launcher দিয়ে desktop restart এবং owner review এখনও বাকি। ২০২৬-১১-০৭-এ main commit `550bdf8e02424d76f8c32a88b463477ef6bb4645`-এর exact CI package (workflow run [42344799168](https://github.com/soobujmiah/ternux/actions/runs/42344799168), SHA-256 `00be22a9fe00bae3b96ef6fbe228fd315101abc3c40ad9a092c177eaffb5c2aa`) local CI `.deb` দিয়ে Termux `apt-get`-এ আগে থাকা 2.0.0 package-এর ওপর install হয়েছে। `ternux --version`, `ternux guides` এবং live `ternux doctor --json` pass; doctor-এ Adreno 825 / Zink / Turnip-সহ 31 OK, 0 warning/failure। এটি local artifact apt upgrade, hosted signed repository থেকে install নয়। ২০২৬-১১-০৭-এ live X11 visual check-এ 752×1630 display-র 500×400 Volume Control window capture করেছি: dark-theme Output Devices-এ OpenSL ES Output এবং Input Devices-এ OpenSL ES Input পরিষ্কার দেখা গেছে। শুধু test process বন্ধ করার পর কোনো source-output stream ছিল না; PulseAudio input/output IDLE-তে ফিরেছে, Xfce, Termux:X11 ও PulseAudio চালু থেকেছে। এটি বিদ্যমান desktop-এর check; upgraded launcher দিয়ে restart verify করে না। ২০২৬-১১-০৮-এ GTK 4 theme-এর ভুল Adwaita resource import-কে bundled Default dark stylesheet দিয়ে বদলেছি; live pavucontrol launch-এ theme parser error আসেনি এবং capture করা X11 view-তে Output Devices controls দেখা গেছে। এটি সরাসরি launch check; Xfce menu থেকে বারবার চালানো ও owner review এখনও বাকি। ২০২৬-১১-০৮-এ active Xfce D-Bus settings-এ 752×1630-এর একটি `builtin` monitor-এ Ternux GTK, icon ও Xfwm theme এবং compositor off দেখা গেছে। Live asset hash checkout-এর ১৯৫টি icon file, ৫৫টি theme file ও ১৫টি wallpaper-এর সঙ্গে মিলে (guest-এ একটি generated icon cache অতিরিক্ত)। Active `05-quantum-grid.svg` wallpaper অপরিবর্তিত রেখেছি; inactive monitor1-এর broken wallpaper path valid Aurora artwork-এ দিয়েছি। Launcher v15 এখন fresh setup-এ `monitorbuiltin` target করে এবং শুধু খালি, missing বা Debian-stock wallpaper migrate করে; readable custom wallpaper অক্ষত রাখে। চলমান desktop restart করিনি। ২০২৬-১১-০৮-এ বর্তমান source থেকে local Termux package build করে `apt-get --reinstall` দিয়ে install করেছি; package SHA-256 `9df2a201ac410d1fce8810753f354115c7e319369bac0f6ba31675ef79c12807`, আর installed CLI hash archive-এর সঙ্গে মিলে। `ternux --version`, `ternux guides`, `doctor --json` (২৯ OK, ০ warning, ০ failure) এবং `verify --json` pass; live desktop চলমান ছিল। এটি source-built package evidence—exact CI artifact বা hosted repository install নয়। পরের live-source `ternux info --json` check-এ Termux `0.119.0-beta.3` ও Adreno 825/Turnip ৩.০ সেকেন্ডে ফিরেছে; renderer probe-এ পাঁচ সেকেন্ডের সীমা ও ICD-file fallback আছে। Termux version আগে Android app metadata থেকে resolve হয়। Updated focused test ১২২/১২২ pass; docs-এ ৩,০০৭ assertion, ৩০৯ internal link ও ১৯টি bilingual pair pass। বর্তমান source-built 2.0.0 APT package-ও Termux APT দিয়ে local reinstall করেছি (package SHA-256 `0cb55b9cefe187c733ad82f205ecc134c1f99e18c7e654b1426382db95f4b68d`); installed CLI hash archive-এর সঙ্গে মিলে, `info --json` সঠিক Termux ও Adreno/Turnip data দিয়েছে, `verify --json` pass করেছে, desktop চলমান ছিল। Exact-package GUI reopen, typing/welcome/error state ও owner visual review এখনও বাকি। | Exact CI package install/reopen করে typing, welcome, error-state ও owner review নথিভুক্ত করা |
| ৮ | Signed Termux APT distribution (`pkg install ternux`) | Local package ও signed-index fixture check pass; প্রকাশিত website APT endpoint-এ v2 InRelease নেই। ফোনে Termux ও Termux:API—দুই app-এই RECORD_AUDIO granted। সীমিত এক-সেকেন্ড Termux:API Opus recording থেকে valid 16 kHz mono Ogg file তৈরি হয়েছে, পরে temporary file মুছে গেছে। আলাদাভাবে Debian guest PulseAudio `Ternux_Microphone` OpenSL source থেকে 119,972 byte audio পেয়েছে (16 kHz mono; peak 1,144, RMS 84.2); client বন্ধ হলে source আবার SUSPENDED। Volume Control input meter খোলা থাকলে source-output তৈরি হয়; app বন্ধ করলে source-output চলে যায় এবং `Ternux_Microphone` IDLE হয়। Idle desktop mic stream খোলা রাখে না। এটি PulseAudio দিয়ে on-demand desktop input যাচাই করে, live Termux:API-to-guest stream নয়। Signing-only workflow run [42311346876](https://github.com/soobujmiah/ternux/actions/runs/42311346876)-এ exact `ternux` 2.0.0 package ও signed repository তৈরি হয় এবং `InRelease` fingerprint `E5527F4D5B83037FF77B65AE5E894BBB81168B1D` দিয়ে verify হয়; publish job skip ছিল। সর্বশেষ non-publishing check [run 42489816303](https://github.com/soobujmiah/ternux/actions/runs/42489816303)-এও protected APT key দিয়ে 2.0.0 package build এবং signed repository verify pass হয়েছে; deployment skip করা হয়েছে। Termux dpkg-তে 2.0.0 installed দেখায়, কিন্তু host-এ Ternux APT source নেই; তাই এটি signed repository থেকে `pkg install` হওয়ার প্রমাণ নয়। Signed v2 repository এখনও প্রকাশিত নয়; hosted clean install/upgrade যাচাই হয়নি। | API ও OpenSL-এর সীমা স্পষ্ট রাখা; owner-visible mic control ও exact installed artifact qualify; অন্য সব gate বন্ধ হলে signed workflow-এ publish করে hosted clean install/upgrade verify

| ৯ | Model/accelerator artifact coverage ও optional install | OPEN। llama.cpp CPU/Vulkan ও experimental SM8735/V73 HTP artifact আছে। Public HTP archive-এ manager-এর প্রয়োজনীয় broker/launcher layout নেই; সর্বশেষ PR candidate সরাসরি stage করে সীমিত SM8735 known-answer এবং interrupt/reopen check pass করেছে, কিন্তু public asset এখনো প্রকাশিত নয়। Merged PR `#59`-এর CPU/Vulkan Stable Diffusion extension build/ABI ও public prerelease pass; Ternux manager checksum verify করে install করেছে এবং doctor OK দেখায়। Installed package Adreno 825-এ tiled Vulkan দিয়ে 512×512/10-step image 92.91s-এ করেছে। CPU image quality unqualified, CPU capability claim নয়। Active guest-এ managed repair/remove/reinstall model অক্ষত রেখে pass। Clean guest-এ dependency provisioning ও pinned artifact installation pass; doctor extension OK, binary help ও `ldd -r` pass। আরেকটি isolated Debian 13 guest-এ বাস্তব desktop phase-এর পর GPU phase চালানো হয়েছে; guest doctor-এ ১০টি OK, ০ warning, ০ failure এসেছে এবং XFCE, terminal, task manager, Mousepad, pavucontrol ও VLC executable ছিল। Private 1280×720 Xvfb session-এ XFCE চালু হয়েছে এবং terminal ও pavucontrol window খুলেছে; configured audio server না থাকায় pavucontrol 1×1 window দিয়েছে। তাই এটি শুধু startup যাচাই—readable control, audio বা physical Termux:X11 rendering নয়। Interactive checklist থেকে PTY regression test-এ Stable Diffusion নির্বাচন ও `stable-diffusion` workload ID ফেরত যাচাই হয়েছে; fresh-install-এর সম্পূর্ণ managed flow ও physical X11 visual review বাকি। Cancellation/restart ও sustained/device coverage-ও বাকি। User-provided model external ও অপরিবর্তিত আছে: GGUF file `/sdcard/LAI/models` ও `/sdcard/Llms`-এ; এর মধ্যে Qwen 1.5B/0.5B, SD1.5 Q8_0 এবং QNN archive আছে। User-provided SD1.5 Q8_0 GGUF `/sdcard/Llms/ternux-v2-validation/stable-diffusion-v1-5-pruned-emaonly-Q8_0.gguf`-এ আছে (1,763,578,176 byte; SHA-256 `d0555243938c62faeefb4ac93f6c7a053ad373a4290c5256bce229aeb193bf94`)। QNN SD1.5 runner/helper packaged নয়; independent stage-tensor correctness, quality ও performance বাকি। User-provided `/sdcard/Llms/gemma4-e2b-sm7635.qnn` হলো SM7635 (Hexagon v73/Int16)-এর জন্য convert করা; target SM8735-এর জন্য নয়। [Ailia-র QNN guide](https://docs.ailia.ai/en/llm/qnn.html) exact SoC-এর model বাধ্যতামূলক বলেছে, SM8735 model তালিকায় নেই, এবং matching QAIRT version-সহ proprietary ailia LLM runtime লাগে। তাই এই file Ternux text-NPU inference qualify করতে পারে না; সঠিক SM8735 conversion ও license-compatible runtime এখনও বাকি। | প্রতিটি intended CPU/GPU/NPU LLM ও Stable Diffusion route-এর versioned, checksummed, licensed tool artifact, fresh-install menu selection, clean-guest GPU workload verified; fresh X11 desktop, post-install repair/remove, cancellation/restart ও sustained target-device workload যাচাই; model weights external রেখে evidence limit স্পষ্ট রাখা |
| ১০ | Ternux version release সম্পূর্ণ করা | HELD। Release criteria এখনও খোলা: independent QNN model-stage correctness ও performance target, HTP numerical failure/operator coverage, বিস্তৃত sustained/failure-restart qualification, dependency-license review, model/accelerator artifact coverage, owner visual review এবং hosted signed APT install/upgrade। Unqualified HTP/QNN route-কে stable support claim-এর বাইরে রাখতে হবে। | আগের প্রতিটি gate বন্ধ ও পুনর্মূল্যায়ন করে installed artifact, public repository, website ও documentation-এর final audit করা

### PR #97-এর বর্তমান CI ও distribution snapshot — ২০২৬-১১-০৮

Source head `a2c3c67c7763e04d1259c1b558f29a1f32eff7fd`-এ সাতটি workflow-ই pass করেছে: Validate `42499196599`, APT package `42499196408`, llama.cpp CPU/Vulkan `42499196415`, Stable Diffusion CPU/Vulkan `42499196575`, HTP candidate `42499196468`, repository contract `42499196565`, এবং knowledge sync `42499196430`। APT candidate artifact `13624359615` (263,679 byte); llama Vulkan `13624424898` (21,326,390 byte); HTP `13625047288` (15,530,589 byte); Stable Diffusion `13625151469` (27,029,970 byte)। শুধু artifact metadata দেখা হয়েছে; exact artifact download বা install হয়নি। Owner handoff-এর folder `artifacts/{ternux-apt,htp-qualification,ternux-extensions}/incoming/` প্রস্তুত; শেষবার যাচাইয়ে খালি ছিল। Base desktop-এ upstream app name **Synaptic Package Manager** অক্ষুণ্ণ রেখে Ternux icon/theme আছে। Benchmark source-এ matched 1.5B CPU/Vulkan/HTP result এবং verified tiled-Vulkan image workload আছে। Public site এখনো আগের main-branch build দিচ্ছে; signed APT endpoint `apt/dists/stable/InRelease` ও `apt/bootstrap.sh` HTTP 404, hosted signed repository unpublished। PR #97 draft-ই আছে। আগের সব gate বন্ধ না হওয়া পর্যন্ত release gate ১০ held থাকবে.

আগের PR head `8d332484dce4b48d2fe385694d3397682b380da9`-এ সব প্রয়োজনীয় check আবার pass করেছে: Validate `42503534731`, Termux APT package `42503534742`, CPU/Vulkan llama.cpp `42503534757`, Stable Diffusion `42503534870`, HTP candidate `42503534721`, repository contract `42503534682`, এবং knowledge sync `42503534687`। Protected APT signing setup-এর non-publishing `verify-signing` run `42504581740`-ও pass করেছে; এতে configured key দিয়ে signed repository build ও verify হয়, কিন্তু publish হয়নি। সরাসরি check-এ hosted APT endpoint দুটিই এখনো HTTP 404, তাই public `pkg install ternux` এখনো verify হয়নি। Handoff folder-গুলোও খালি ছিল। Local focused test ১২২/১২২ এবং documentation check-এ ৩,০১৭টি assertion, ৩১০টি internal link ও ১৯টি bilingual page pair pass করেছে। PR #97 এখনো draft এবং release gate ১০ held.

### প্রকাশিত accelerator prerelease audit — ২০২৬-১১-০৯

Public GitHub Releases-এ এখন accelerator-এর চারটি prerelease আছে; এগুলো stable
Ternux v1.4.0 থেকে আলাদা। llama.cpp CPU/Vulkan archive optional `llama-vulkan`
extension। Stable Diffusion CPU/Vulkan archive optional `stable-diffusion`
extension; এতে model weights নেই। SM8735 llama.cpp HTP V73 archive শুধু
`llama-htp-experimental` হিসেবে install হয়; release note-এই deterministic
`2 + 2` known-answer test-এর malformed output লেখা আছে, তাই এটি correctness
বা stable-support claim নয়। Android/Bionic QNN native probe archive কেবল
diagnostic: এতে model, Qualcomm runtime, firmware বা broker নেই এবং model output
correctness-ও প্রমাণ করে না। বর্তমান link: [llama CPU/Vulkan](https://github.com/soobujmiah/ternux/releases/tag/ternux-llama-vulkan-linux-arm64-b11582),
[Stable Diffusion CPU/Vulkan](https://github.com/soobujmiah/ternux/releases/tag/ternux-stable-diffusion-vulkan-linux-arm64-master-1053),
[experimental SM8735 HTP](https://github.com/soobujmiah/ternux/releases/tag/ternux-llama-htp-sm8735-b11582),
এবং [SM8735 QNN probe](https://github.com/soobujmiah/ternux/releases/tag/ternux-qnn-native-probe-sm8735-2026-10-14)। Current PR head `4f300b4f1e6dafe7e15892d7b074a89bd104d10a`-এ সাতটি check-ই pass করেছে: Validate `42511329995`, APT artifact `42511330003`, llama CPU/Vulkan `42511330016`, Stable Diffusion CPU/Vulkan `42511330080`, HTP candidate build `42511329996`, repository contract `42511330008`, এবং knowledge sync `42511330055`। এই CI source validation ও artifact build নিশ্চিত করে; HTP/QNN inference, device-এ দীর্ঘস্থায়ী কাজ, বা public signed APT install qualify করে না। Device testing-এর জন্য কোনো Actions artifact download করা হয়নি। PR #97 draft-ই আছে এবং signed APT hosting endpoint এখনও 404 দেয়।

### বর্তমান candidate build ও HTP notice audit — ২০২৬-১১-০৯

PR head `bf71a994993bc072aa878f177a604a2651cef591`-এ রিপোর্ট করা আটটি
check-ই pass করেছে: Validate `42512876206`, APT package `42512876326`,
repository contract `42512876203`, knowledge sync `42512876191`, llama
CPU/Vulkan `42512876192`, Stable Diffusion CPU/Vulkan `42512876202`,
production HTP `42512876240`, এবং integer-HMX HTP candidate `42512876199`।
Local `bash tests/focused.sh` ১২৩/১২৩ pass করেছে;
`python3 tests/docs_check.py`-তে ৩,০১৭ assertion, ৩১০ internal link এবং ১৯টি
bilingual page pair pass করেছে। Production HTP workflow এখন root `AUTHORS`-সহ
LICENSE/LICENCE, COPYING, NOTICE, COPYRIGHT, PATENTS ও UNLICENSE-জাতীয়
upstream notice file bundle-এ রাখে, প্রতিটি file-এর SHA-256 তৈরি করে, এবং
archive membership পরীক্ষা করে। Run `42512876240`-এ এই check-গুলো pass হয়েছে
এবং Actions artifact `13630760600` upload হয়েছে; artifact download বা device
test করা হয়নি। Public HTP prerelease-এ আগের asset ও malformed known-answer
output-ই আছে, তাই workflow fix HTP inference qualify করে না বা public release
update করে না। বাকি তিনটি accelerator prerelease-ও v2 থেকে আলাদা। PR #97
draft-ই আছে; hosted signed APT endpoint এখনো 404 দেয় এবং release gate ১০ held।

### HTP prerelease install ও SM8735 known-answer check — ২০২৬-১১-০৯

প্রকাশিত HTP archive-এর SHA-256 sidecar মেলে (`dffcf83fa969f3ccfad238217b4ca7f3d47040e5e5b2fa834ebd3f123d144ea5`), কিন্তু archive-টি বর্তমান extension-manager contract-এর আগের: এতে `llama-cli` ও provenance manifest আছে, কিন্তু `bin/htp-run`, `libexec/htp-broker.py` বা `lib/libternux-htp-broker.so` নেই। `ternux extension install llama-htp-experimental` প্রয়োজনীয় Debian runtime package বসায়, archive hash যাচাই করে, এরপর stale public archive-টি সঠিকভাবেই reject করে; extension-এর কোনো file install হয়নি।

সর্বশেষ PR build artifact run `42520478911` (artifact `13633283508`, source head `637c31d`)-এর SHA-256 `89e0f8f4ae232352d4949e989c5e7b435f815f286d5dbe58381a082b05da025d`; এতে launcher, broker, shim ও matching manifest আছে। Sidecar verify করে ওই exact archive device qualification-এর জন্য সক্রিয় Debian user-এর managed extension directory-তে stage করেছি। `ternux doctor extensions --json`-এ চারটি check-ই OK; extension library directory set করলে `ldd -r` resolve করে। `htp-run --version` CDSP service পেয়েছে এবং broker session `[0, 0]` দিয়ে বন্ধ করেছে। SM8735-এ থাকা `/sdcard/Llms/qwen2.5-0.5b-instruct-q4_0.gguf` দিয়ে তিনটি independent চার-token known-answer launch-এই `4.00` এসেছে এবং প্রতিবার `closeSession [0, 0]` হয়েছে। এটি ওই exact model/prompt ও candidate-এ repeatability যাচাই করে; বিস্তৃত model quality, sustained use বা performance নয়। আলাদা পাঁচ-সেকেন্ডের bounded SIGINT run exit 130-তে শেষ হয়েছে; broker child exit 0, `cancel_signal: 2` এবং `closeSession [0, 0]` জানিয়েছে। সঙ্গে সঙ্গে নতুন HTP session-এ আবার `4.00` এসেছে এবং `[0, 0]` দিয়ে বন্ধ হয়েছে—এই candidate-এর interrupt/reopen path একবার যাচাই হলো। Local extension-টি PR artifact সরাসরি stage করে বসানো; managed downloader দিয়ে install করা হয়নি। `ternux extension repair` stale public archive reject করেও বর্তমান candidate অক্ষত রেখেছে: manifest ও launcher SHA-256 একই আছে, staging directory পড়ে নেই, আর `ternux doctor extensions --json`-এ ৪টি OK রয়ে গেছে। Release gate পূরণ হলে শুধু main-only HTP publisher দিয়েই public prerelease refresh করতে হবে, এরপর একই public asset দিয়ে managed install/repair/remove ও failure/restart test পুনরায় চালাতে হবে।

### Webfont attribution ও license-file audit — ২০২৬-১১-০৯

পাঁচটি self-hosted webfont-এর embedded name-table copyright metadata পরীক্ষা
করে `NOTICE`-এ Noto Sans Bengali ও JetBrains Mono-এর stale attribution, আর
Caveat ও Atma-এর attribution অনুপস্থিত পেয়েছি। `NOTICE` ও
`assets/fonts/LICENSES.md`-এ এখন Atma, Caveat, JetBrains Mono, Noto Sans
Bengali এবং Space Grotesk-এর embedded attribution আছে। Noto Sans Bengali-এর
OFL text `notofonts/bengali` source commit
`85d80394cbbbb798ca0a41c983902e6cf77be3a3` থেকে copy করে SHA-256 দিয়ে pin
করা হয়েছে; Atma-র embedded ২০১৫ metadata এবং upstream OFL-এর ২০১০ copyright
দুটিই রাখা হয়েছে। Astro site finalizer প্রকাশিত site-এ `assets/fonts/`
copy করে; নতুন focused regression test asset inventory, NOTICE attribution
ও license hash পরীক্ষা করে। Local check pass: `bash tests/focused.sh` ১২৪/১২৪,
`python3 tests/docs_check.py`-তে ৩,০১৮ assertion, ৩১২ internal link এবং ১৯টি
bilingual page pair। Self-hosted webfont inventory gate বন্ধ হয়েছে; wider
binary dependency-license review এখনো বাকি। Mesa binary-র exact static
component/source mapping ও transitive third-party inventory এখনো open, তাই
release gate ১০ held থাকবে।

### Optional mail client — ২০২৬-১১-০৮/০৯

Owner-এর সর্বশেষ নির্দেশে base desktop-এ কোনো mail client বা mail default থাকবে না; Evolution optional workload। Evolution ও GNOME Online Accounts GTK install করে Ternux-managed launcher বসানোর source code `b64d3f7` ও `89d0fe9` commit-এ push হয়েছে। নতুন regression test-এ Evolution launcher branch আগে no-op case-এ আটকে থাকার bug ধরা পড়ে; সেটি ঠিক করা হয়েছে। Live guest-এ exact optional phase চালিয়ে package current রাখা ও `/usr/local/bin/evolution`-এ Exec-সহ desktop entry বসানো হয়েছে; `desktop-file-validate` pass, installed wrapper hash source asset-এর সঙ্গে মিলে। Evolution চলমান ছিল; Thunderbird purge হয়েছে; দুই profile directory অক্ষত। XFCE `MailReader` default নেই, Firefox `WebBrowser` helper আছে, APT ও dpkg clean। Focused tests ১২৩/১২৩ pass; 89d0fe9-এর Validate, APT, CPU/Vulkan, Stable Diffusion, HTP, repository contract ও knowledge sync CI-ও pass। Optional Evolution থাকলে GIO desktop MIME metadata থেকে সেটিকে recommend করতে পারে; fresh base install-এ Evolution থাকে না। Public release করা হয়নি।

### Desktop icon coverage audit — ২০২৬-১১-০৮

আগের ৪৩-entry desktop audit-এ XFCE menu category ও panel plugin-এর কিছু icon ID Papirus fallback-এ পড়েছিল। এখন Ternux theme-এ menu category এবং Applications, Show Desktop ও directory panel plugin-এর নিজস্ব icon আছে। আগের guvcview package ও desktop override সরানো হয়েছে; Android still-photo camera flow-ই সমর্থিত integration। আগের entry/icon সংখ্যা historical, নতুন icon set-এর count নয়। Panel-size পর্যালোচনায় application, category, device, status, MIME type এবং folder নয় এমন place icon থেকে একই enclosing badge সরানো হয়েছে। Glyph-গুলো Ternux-এর রং রাখে, কিন্তু এখন আলাদা silhouette-এ দেখা যায়; folder icon ও Ternux brand mark-এর নিজস্ব shape রাখা হয়েছে। বর্তমান live Debian desktop-entry audit-এ “Create Launcher on the panel” (`application-x-executable`)-এর জন্য একটি generic fallback পাওয়া গেছে। ওই ID-র জন্যও এখন নিজস্ব square-window Ternux launcher icon আছে। Fresh install-এ shipped theme application, settings, category, device, MIME এবং Thunar-action icon-এ Ternux artwork resolve করবে; পরে install করা software-এর জন্য Adwaita neutral fallback থাকবে। ২০২৬-১১-০৮-এ live Debian guest-কে staged directory swap দিয়ে canonical Ternux asset tree থেকে দুইবার sync করা হয়েছে; এখন icon pack-এ ১৯৩টি SVG আছে এবং stale alias নেই। শেষ live GTK3 `Gtk.IconTheme` check-এ active theme `Ternux`; desktop ও panel-এর ৫৬টি icon ID-ই resolve করে। এই pass-এ যোগ করা ছয়টি XFCE panel plugin icon, Evince, mail reader এবং Thunar-ও এর মধ্যে আছে। Thunar-এর প্রচলিত edit/navigation action-গুলোও resolve করেছে। GTK theme refresh করতে XFCE IPC দিয়ে শুধু panel restart করা হয়েছে; `xfce4-session` ও `xfwm4` চলেছে, user-এর app বন্ধ করা হয়নি। Base desktop-এ কোনো mail app বা mail default নেই; Evolution optional, এবং উপরে উল্লেখ অনুযায়ী live guest থেকে Thunderbird সরানো হয়েছে। Base PDF default এখন Evince; live guest-এ Evince installed, PDF MIME default `org.gnome.Evince.desktop`, এবং তৈরি করা এক-পৃষ্ঠার PDF ৭৫২×১১৫৫ display-তে ৬১০×৬১০ dark-themed controls-সহ readable অবস্থায় render হয়েছে। PDF page edit/export-এর জন্য LibreOffice Draw optional। Panel-এর active/checked button এখন upstream rounded pill-এর বদলে compact square Ternux state পায়। ৭৫২×১১৫৫-এর live X11 root capture server-এর ২৪-bit BGR row layout ধরে decode করে সরাসরি দেখা হয়েছে: Ternux graphite/emerald desktop ও panel, Application Finder এবং Thunar home window পড়তে সুবিধা হয়েছে এবং screen-এর ভেতরেই ছিল; sidebar place ও আলাদা folder type-এ Ternux artwork আছে, panel/window control-এ oval icon backplate নেই। শুধু test-এর Thunar process বন্ধ করেছি, desktop session নয়। Phone-এ Android Chrome foreground-এ ছিল, তাই capture-টি agent-এর visual evidence—owner-এর review নয়; release gate খোলা থাকবে।

### বর্তমান live portrait desktop capture — ২০২৬-১১-০৯

৭৫২×১৬৩০ Termux:X11 root-এর read-only capture-এ graphite/emerald Ternux wallpaper, নিজস্ব Home/File System/Trash/SD Card icon এবং নিচের panel portrait display-এর ভেতরে দেখা গেছে। Xfce desktop চলমান ছিল; capture-এর জন্য কোনো window বা application খোলা হয়নি। এটি desktop background, icon ও panel geometry-এর agent visual check মাত্র। কোনো application window দেখা যায়নি, তাই Volume Control rendering যাচাই হয়নি এবং owner-এর final visual review-ও এর বিকল্প নয়।

### Volume Control launcher reopen review — ২০২৬-১১-০৯

চলমান ৭৫২×১১৫৫ Termux:X11 session-এ exact XFCE desktop-entry launch
(`gtk-launch org.pulseaudio.pavucontrol`) তিনবার চালানো হয়েছে; session-এর D-Bus
ও PulseAudio environment ব্যবহার করেছি। প্রথম দুই সেকেন্ডের capture-এ window কালো/
loading ছিল; সাত সেকেন্ডে তিনবারই Output Devices-এর controls readable হয়েছে।
Input Devices tab-এ `OpenSL ES Input` দেখা গেছে। শেষ test window বন্ধ হলে Ternux
microphone source `SUSPENDED` হয়েছে; `xfce4-session` ও `xfce4-panel` চলেছে,
আগে থেকে খোলা VLC/Thunar process untouched ছিল। Black/loading startup transition
reproduce ও সাত সেকেন্ডে recovery তিনবার verify হয়েছে; owner-এর দীর্ঘস্থায়ী black
screen report সমাধান হয়েছে—এমন প্রমাণ এটি নয়। Owner visual review ও startup
latency তদন্ত এখনও বাকি।

### Volume Control window-targeted visual follow-up — ২০২৬-১১-০৯

পরেরবার exact desktop entry দিয়ে app খুলে guessed root-screen crop-এর বদলে
pavucontrol X11 window-এর window ID ধরে 500×400 capture করেছি। Output Devices
tab-এ `OpenSL ES Output` slider ও controls এবং Input Devices tab-এ `OpenSL ES
Input` ও controls স্পষ্ট ছিল। এই run-এ black window দেখা যায়নি। শুধু test-এর
pavucontrol process বন্ধ করেছি; PulseAudio sink ও microphone source আবার
`SUSPENDED` হয়েছে, detached XFCE desktop চলেছে। এটি দুই tab-এর বর্তমান agent
visual check; আগের দীর্ঘস্থায়ী black view আর হয় না—owner-এর এমন confirmation
নয়।

### Audio output path check — ২০২৬-১১-০৯

Test-এর আগে PulseAudio-তে কোনো sink input চলছিল না। `paplay` দিয়ে এক-সেকেন্ডের
660 Hz WAV `OpenSL_ES_sink`-এ পাঠিয়েছি; একই সময়ে `OpenSL_ES_sink.monitor`
থেকে capture করা non-silent PCM ছিল 286,640 byte, peak 5,999/32,767। Test শেষে
PulseAudio sink IDLE ছিল। এতে Termux OpenSL ES PulseAudio route-এ audio delivery
ও digital monitor যাচাই হয়েছে; ফোনের speaker থেকে বাস্তবে শোনা গেছে তা প্রমাণ
হয়নি। Audible playback gate খোলা রাখুন।

### Desktop camera gate — ২০২৬-১১-০৮

Debian FFmpeg 7.1.5 দিয়ে দুই-সেকেন্ডের generated tone-কে MP3-তে convert করে পরীক্ষা করা হয়েছে; `ffprobe` codec `mp3`, ২.০৪-সেকেন্ড duration এবং ৩৩,০৬৮-বাইট output নিশ্চিত করেছে। Live guest-এ install করা Ternux 2.0.0 CLI package-এর recorder file checkout-এর source-এর byte-identical (SHA-256 `2607ebcc40a8687c9e048074e309f278d99a06ee346e633adf6b5c6ae0eb528d`)। ২০২৬-১১-০৮-এ live X11 session-এ exact-source Ternux Sound Recorder খুলে Start/Stop ব্যবহার করেছি; `ffprobe`-এ সেভ হওয়া ৭৮,৮৫৪-বাইট M4A-তে AAC codec ও ৫০.১৭৬-সেকেন্ড duration মিলেছে। UI Saved path দেখিয়েছে, আর app বন্ধের পরে Android microphone API idle ছিল। শুধু এই test recording মুছে দিয়েছি; আগের দুইটি user recording অক্ষত আছে। এতে interactive AAC GUI save path verify হয়েছে। Audible playback ও GUI-র MP3 নির্বাচন/export এখনো verify হয়নি।

Termux:API camera ID `0`-কে rear এবং `1`-কে front হিসেবে দেখিয়েছে। `termux-camera-photo -c 0` দিয়ে সরাসরি rear-camera test-এ valid 4096×3072 JPEG পাওয়া গেছে। Ternux Camera UI এখন rear camera default select করে, Termux app-private storage-এ capture stage ও validate করে Debian user-এর `~/Pictures/Ternux`-এ atomically save করে। Hidden GTK flow check-এ rear-ID selection, capture-এর পর image preview, PRoot destination এবং temporary file cleanup যাচাই হয়েছে। Preview EXIF orientation অনুসরণ করে এবং capture control compact দুই-row layout-এ থাকে। Theme-এ ১৫টি portrait-first wallpaper asset এবং বড়, বেশি contrast-যুক্ত Xfwm titlebar control আছে; landscape mode-এ aspect ratio ঠিক রেখে zoomed display হয়। ১৫টি wallpaper portrait ও landscape contact sheet-এ দেখা হয়েছে; live desktop capture-এ বড়, high-contrast titlebar control দেখা যায়। প্রতিটি PNG decoration-এর সঙ্গে generated, valid XPM geometry base আছে; maximized window-এর জন্য restore-state artwork-ও যোগ হয়েছে। Package manifest-এ asset-গুলো আছে, আর focused test প্রতিটি XPM-এর header ও row dimension যাচাই করে। Live maximize ও restore click সফল হয়েছে; minimize ও close interaction এখনো verify করা হয়নি। Default Sound Recorder শুধু Start চাপলে record করে এবং AAC/M4A ও FFmpeg দিয়ে local MP3 export দেয়। ২০২৬-১১-০৮ তারিখে owner-authorized ১০-সেকেন্ড Termux:API AAC capture নিজে থেকে stop হয়ে ১৬,৭০৪-বাইট M4A তৈরি করে; MP4 media header-এ ১০.২৪ সেকেন্ড duration মেলে। metadata দেখার পর temporary sample মুছে ফেলা হয়েছে। এতে Android mic/API path verify হয়েছে, GTK app save flow ও audible playback নয়; ওই app-level check বাকি। ২০২৬-১১-০৮ তারিখে owner GUI থেকে recording save করেছেন বলে জানিয়েছেন, কিন্তু ৩৬,৭৩৭-বাইট M4A-তে `moov` atom না থাকায় `ffprobe` পড়তে পারেনি। ফাইলটি অক্ষত রাখা হয়েছে। ব্যর্থ capture-টি আগের implementation থেকে এসেছে, যা MP4 finalization-এর আগে success জানাত। বর্তমান fix valid AAC stream ও positive duration যাচাই করে এবং অসম্পূর্ণ capture recovery-র জন্য রাখে। Debian guest-এ helper smoke test generated AAC/M4A (1.00s) ও MP3 (1.04s) গ্রহণ করেছে এবং truncated M4A প্রত্যাখ্যান করেছে। পরের live GUI run-এ Start/Stop দিয়ে সেভ হওয়া ৭৮,৮৫৪-বাইট M4A-তে `ffprobe` AAC codec ও ৫০.১৭৬-সেকেন্ড duration পেয়েছে; UI Saved path দেখিয়েছে এবং API microphone idle-তে ফিরেছে। শুধু test file মুছে আগের দুইটি user recording অক্ষত রেখেছি। Interactive AAC save path verified। একই live GUI-তে MP3 select করে Start/Stop-এ ৩৪৬,৭৯৬-বাইট MP3 তৈরি হয়েছে; `ffprobe` MP3 codec ও ৪৩.২০০-সেকেন্ড duration নিশ্চিত করেছে। শুধু test file মুছে API microphone idle নিশ্চিত করেছি। AAC এবং GUI MP3—দুই format-এর save path verified; audible playback এখনও যাচাই বাকি। Preview এখন EXIF orientation অনুসরণ করে; capture action compact দুই-row layout-এ থাকে। Installed still-photo interface Android live stream দেয় না; upstream [camera-video API](https://github.com/termux/termux-api/pull/904) ও [streaming client](https://github.com/termux/termux-api-package/pull/242) পরিবর্তন এখনো open। Window-এর ভেতরে live preview-এর অনুরোধ এখনও বাকি; release-এর আগে সমাধান ও visual check দরকার।


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

২০২৬-১১-০৭-এ ফোনে দুইটি image ও দুইটি denoising step-এর QNN batch run একই seed-এর
আলাদা single-image control-এর সঙ্গে মিলে গেছে। Batch-এ একটি UNet ও একটি decoder
QNN context load হয়েছে, সময় লেগেছে 20.321 s; control-এর সময় 14.275 s ও
12.197 s। এরপর ২০-step, দুই-image batch আগের ২৫-image soak-এর প্রথম দুই image-এর
সঙ্গে হুবহু মিলে গেছে: seed 20261014 SHA-256
1a13957f5cb65132d98fc212756bdcf8d8b959d69feba84902a9314036764fc3 এবং seed
20261015 SHA-256 d20bf183909928236e02c8a1f7fe869e5883eb7931e3f5fe5eb65c0f74ee5aec।
Batch-এ একটি UNet ও একটি decoder context load হয়েছে; প্রতিটি verified model
member একবার stream হয়েছে; মোট সময় 49.923 s। প্রতি-image UNet/decode-PNG সময়
14.815/0.850 s ও 16.129/0.824 s। আগের soak-এ image দুটির আলাদা সময় 28.233 s ও
28.911 s (মোট 57.144 s); দুই session-এর এই non-interleaved মাপ controlled speedup
প্রমাণ করে না। Battery 40.7–40.9°C মাপা হয়েছে; NPU-specific thermal sensor
শনাক্ত হয়নি। অপরিবর্তিত archive-এর SHA-256
f479f3221fb90d31de1e695577f5aec9a5afb5fb7e076cfac40f00e039b22977। একই output
hash repeat হওয়া independent stage correctness প্রমাণ করে না। Owner-এর 3–5
second target এখনো বাকি।

২০২৬-১১-০৭-এ একই দিনে ২০-step-এর তিনটি paired sequence হয়েছে; এর দুটিতে
single→batch→single এবং একটিতে batch→single→single order ছিল। Batch total ছিল
47.825, 46.946 ও 45.931 s (mean 46.901; range 45.931–47.825); paired single
control-এর যোগফল 60.429, 57.145 ও 60.012 s (mean 59.195)। এই তিনটি ছোট sample-এ
batch mean 20.8% কম। ছয়টি batch/control PNG-র hash হুবহু মিলে গেছে। পরীক্ষা
randomized বা statistical power-সহ নয়; release guarantee নয়। দুই নতুন run-এর
আগে/পরে battery 36.5–37.1°C ছিল; NPU-specific thermal sensor শনাক্ত হয়নি।
অপরিবর্তিত archive-এর SHA-256
f479f3221fb90d31de1e695577f5aec9a5afb5fb7e076cfac40f00e039b22977। Independent
stage correctness ও 3–5 second target এখনো বাকি। Seed, hash, command ও প্রতি-run
ফল [device benchmark record](../../guides/device-benchmark-evidence.md#2026-11-07-qnn-batch-setup-reuse-repeat)-এ আছে।

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

### SM8735 no-FP16 integer-HMX candidate — ২০২৬-১১-০৮

Ternux-এর pinned llama.cpp commit `af50f2f248b475d9760f8e67503d01c0f194f5f4`-এর
উপর MIT-licensed `karusrus/llama.cpp`-এর `hexagon-int-hmx` implementation port করে
একটি disposable candidate তৈরি করেছি। Patch-এ runtime HMX-FP16 probe, integer-HMX
Q4_0 matmul/attention এবং HVX Gated Delta Net path আছে। Production extension ও
তার HVX-only launcher অপরিবর্তিত আছে। Exact patch, license text, test launcher
এবং manual build workflow
[`experiments/htp-integer-hmx-candidate/`](../../experiments/htp-integer-hmx-candidate/README.md)-এ
রয়েছে।

Pinned Linux ARM64 candidate build ও package inspection workflow
[42476961710](https://github.com/soobujmiah/ternux/actions/runs/42476961710)-এ
Ternux commit `c7539f6ca98b53dd2fd267aacbd0a02a8f11643b` থেকে pass করেছে। CI patch
apply, HTP V73 package file, ARM64 ELF target, launcher/test wrapper ও bundled
license notice যাচাই করে 14,211,453-byte
`ternux-llama-htp-sm8735-integer-hmx-v73-candidate` artifact (metadata ID
`13617163756`) upload করেছে; agent artifact download করেনি। এটি শুধু
build/package evidence; SM8735-এ candidate inference বা operator test হয়নি।
Device-side HMX capability, CPU reference correctness, supported operator suite,
failure/restart ও সীমিত sustained test pass না হওয়া পর্যন্ত production HTP
extension অপরিবর্তিত থাকবে। ২০২৬-১১-০৮ তারিখে `6aaa41cfc2bd75fc2cb95de025b6e4f27373be23` head-এ PR-এর সাতটি check pass করেছে: Validate `42494970578`, APT package `42494970656`, CPU/Vulkan llama.cpp `42494970581`, Stable Diffusion `42494970714`, HTP candidate `42494970777`, repository contract `42494970670` এবং knowledge sync `42494970688`। `738b1cbb68b27d166eeee85d6dca045a607daa02` head-এর HTP build প্রথমে fail করেছিল, কারণ upstream SM8735 V73-এর পাশাপাশি এমন V85 skeleton-ও build করছিল যার নতুন intrinsic pinned toolchain-এ নেই। Candidate workflow এখন V75/V79/V81-এর সঙ্গে V85-ও বাদ দিয়ে শুধু SM8735 V73 target build করে। সংশোধিত run pass করে `ternux-llama-htp-sm8735-integer-hmx-v73-candidate` artifact upload করেছে (১৫,৫৩০,৬২৩ byte; metadata ID `13622933656`)। CPU/Vulkan ও Stable Diffusion candidate artifact-ও upload হয়েছে (ID `13622533883` এবং `13622369733`)। CI artifact ডাউনলোড বা install করা হয়নি; তিনটি incoming handoff directory-ই খালি, তাই exact-artifact install ও device validation এখনো বাকি। Public APT `InRelease` ও bootstrap endpoint এখনো HTTP 404 দেয়। PR #97 এখনও draft; এই evidence release gate বন্ধ করে না।

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

### Exact-current-head CI artifact inventory — ২০২৬-১১-০৯

PR #97-এর head `96c30aa1325bc14850d14b7a4dcd4528b5aab5da`-এ আটটি required
check pass করেছে: Validate `42535686912`, unsigned Termux APT package
`42535686925`, repository contract `42535686910`, knowledge sync `42535686911`,
CPU/Vulkan llama `42535686914`, Stable Diffusion CPU/Vulkan `42535686917`,
production HTP `42535686924`, এবং integer-HMX V73 candidate `42535686919`। PR
draft হওয়ায় preview/publication job skip হয়েছে। Actions artifact archive metadata:

| Artifact | Actions artifact ID | Bytes | SHA-256 |
|---|---:|---:|---|
| `ternux-apt-unsigned-ci-af450cc891fd2120cea9e5697e0159c61a7a35d3` | `13638992164` | 268,620 | `94fc4252b41faceb60d021d5f1982cf23f81f69eb9a9e0e3e5c3cf94f7587101` |
| `ternux-llama-vulkan-linux-arm64-b11582-candidate` | `13639198127` | 21,327,935 | `60c84df443bbf996b64c5c46076253d4a89b8ca5fdefaf5439919d0a3605bbc8` |
| `ternux-stable-diffusion-vulkan-linux-arm64-master-1053-candidate` | `13639660775` | 27,030,299 | `b40238efee496b813572a9a13d84624bc2693efb502e4b07ae7a56a89aa5544c` |
| `ternux-llama-htp-sm8735-b11582` | `13639273191` | 15,637,038 | `bdf22e7d17769bd3289c8596fb48631ea269295240aa05ff0d06dae085c94eee` |
| `ternux-llama-htp-sm8735-integer-hmx-v73-candidate` | `13639198836` | 15,530,741 | `1d8010b25656d5ec70806c9544e1af4576aa5bc1f53e2839f78aac7dbdb572e4` |

এগুলো GitHub Actions archive digest এবং CI build/inspection evidence। Exact
archive-গুলো project incoming folder-এ নেই এবং এই run থেকে install করা হয়নি।
CPU/Vulkan ও Stable Diffusion যাবে `artifacts/ternux-extensions/incoming/`-এ;
দুটি HTP archive যাবে `artifacts/htp-qualification/incoming/`-এ; unsigned APT
artifact যাবে `artifacts/ternux-apt/incoming/`-এ। Exact-artifact fresh install
ও device check, independent QNN model-stage correctness, HTP operator failure,
owner visual review, wider dependency-license review, এবং public signed APT
install/upgrade ও release publication এখনো খোলা gate। নতুন CI evidence ওই
release gate-গুলো বন্ধ করে না। Live HTTP check-এ
`https://soobujmiah.github.io/ternux/apt/dists/stable/InRelease` ও
`https://soobujmiah.github.io/ternux/apt/bootstrap.sh`—দুটিই 404 দিয়েছে;
signed publish workflow শুধু main branch-এ চলে এবং release-এর জন্য এখনো dispatch হয়নি।

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

### PR #97-এর exact current-head artifact audit — ২০২৬-১১-০৯

`ccc9b94ff49db5c05a534ede26e607cfcc0e415b` head-এ Validate, unsigned
Termux APT package, repository contract, knowledge sync, llama CPU/Vulkan,
Stable Diffusion CPU/Vulkan, production HTP এবং integer-HMX candidate build
check pass করেছে। Exact Actions artifact download করে প্রতিটি archive-এর
sidecar checksum মিলিয়েছি। Run `42523800363`-এর llama CPU/Vulkan archive
(artifact `13634048426`; archive SHA-256
`1ff7d8ec2187ccbe6e5940cd5e02bde40283044727ea19e6befe7f5b8e57eaa5`) local
ABI/source-map/license audit pass করেছে: ৬৯টি AArch64 ELF file, সর্বোচ্চ GLIBC
2.38, সব dependency resolve হয়েছে, আর
`$ORIGIN/../lib` RUNPATH আছে। Run `42523800211`-এর Stable Diffusion archive
(artifact `13634521936`; archive SHA-256
`7430e9092f26f9d155b639c8ffe14c59acae69a2157a9c54e0d5fce227c3ac8d`) local
ABI ও ১১টি notice license audit pass করেছে।
Run `42523800207`-এর production HTP archive (artifact `13634444182`; archive SHA-256
`10997fba5cf5aec6d15beb5ef5557c44c1d3cdb405758eb085062afaaea0aa34`) sidecar,
নিরাপদ extraction, broker ও launcher-এর layout এবং upstream notice-এর সব hash
check pass করেছে। আলাদা integer-HMX candidate run
`42523800189` (artifact `13634897369`; archive SHA-256
`b8408d93396f445c45e1c8d1e833d2e8baa36e513e8a781d92bb36150efa5d94`) sidecar,
নিরাপদ extraction, manifest এবং প্রয়োজনীয় file check pass করেছে. এগুলো exact current-head build ও static
package check; এই pass-এ downloaded artifact install বা device test করা হয়নি।
ফোনে ৪৬ °C দেখানোয় device inference ও graphics stress স্থগিত রেখেছি। Public
HTP release asset এবং hosted signed APT endpoint বদলায়নি; দুই hosted APT URL
এখনো HTTP 404 দেয়। PR #97 draft-ই আছে। এই check-গুলো live-device,
correctness, sustained-use, license-scope বা hosted install gate বন্ধ করে না।

### PR #97-এর সর্বশেষ CI snapshot ও live install check — ২০২৬-১১-০৯

PR head `6f58393a32fe90fe81a10554b41115d3b6972b13`-এ আটটি workflow-ই
সফলভাবে শেষ হয়েছে: APT package `42527094159`, repository contract
`42527094177`, Validate `42527094180`, knowledge sync `42527094186`, llama
CPU/Vulkan `42527094171`, Stable Diffusion CPU/Vulkan `42527094154`, integer-HMX
candidate `42527094161`, এবং production HTP `42527094173`। Actions metadata-তে
CPU/Vulkan candidate artifact `13635469668` (২১,৩২৭,৩৩৩ byte), Stable Diffusion
`13635803194` (২৭,০২৯,২০৩ byte), integer-HMX `13636525224` (১৫,৫৩০,৭৫৮ byte),
production HTP `13635773588` (১৫,৬৩৭,১৫৮ byte), এবং unsigned APT CI package
`13635891822` (২৬৮,৬২৮ byte) দেখা যাচ্ছে। Exact build artifact-গুলো project-এর
handoff folder-এ নেই; local install বা device test-ও হয়নি। Integer-HMX candidate
`artifacts/htp-qualification/incoming/`-এ, তিনটি extension archive
`artifacts/ternux-extensions/incoming/`-এ, আর APT package
`artifacts/ternux-apt/incoming/`-এ দিতে হবে। CI pass build/validation evidence;
device qualification নয়। Active Termux installation-এ `ternux verify --json`
pass করেছে এবং `ternux doctor --json`-এ ৩১টি OK, ০ warning, ০ failure এসেছে;
desktop status-এ X11 ও PulseAudio running ছিল। Exact artifact install,
device check, release publication এবং clean public APT install এখনো বাকি। দুই
hosted signed APT endpoint এখনো HTTP 404 দেয়। PR #97 open, clean এবং draft।

### সর্বশেষ CI artifact সংগ্রহ — ২০২৬-১১-০৯

PR head `c0e2c1785dd35c1a51916b569bcca184509ea5e2`-এ আটটি required workflow
pass করেছে: Validate `42536592457`, unsigned APT package `42536592422`, repository
contract `42536592415`, knowledge sync `42536592409`, CPU/Vulkan llama.cpp
`42536592402`, Stable Diffusion `42536592357`, production HTP `42536592386`,
এবং integer-HMX candidate `42536592385`। PR #97 draft হওয়ায় preview/publication
skip হয়েছে। তৈরি হওয়া artifact ও GitHub Actions ZIP digest:

| Artifact | Actions artifact ID | Byte | ZIP SHA-256 |
|---|---:|---:|---|
| `ternux-apt-unsigned-ci-99de5071b7ed1d598ae29f067b52191b3fc8f00a` | `13639159392` | 268,630 | `ebf8a2bbce030bea10a462f4cfcfb833855fbf52afe1c1240eed4a67a06379fd` |
| `ternux-llama-vulkan-linux-arm64-b11582-candidate` | `13639896523` | 21,330,602 | `cdb648e53b740c9997f2b5e6a8c8266a662945a8c712a816672e777d9ee5a344` |
| `ternux-stable-diffusion-vulkan-linux-arm64-master-1053-candidate` | `13640110682` | 27,034,110 | `1bf2eb3d040abad14116b862aa4db5653b87bddfbce0a341a64d2762fa7ec111` |
| `ternux-llama-htp-sm8735-b11582` | `13640265652` | 15,636,542 | `e67d4428a0781771c3bb0337cdaf8cbbf4cd02d2cc08f4b01dd5ae7b1289d942` |
| `ternux-llama-htp-sm8735-integer-hmx-v73-candidate` | `13640420118` | 15,530,593 | `9454f8f280b17cb2e6dc866afaa123f1f2fc8b483aafeb21353005102f995f86` |

এগুলো GitHub Actions ZIP digest; extracted package checksum নয়। Artifact-গুলো এখনো
`artifacts/{ternux-apt,ternux-extensions,htp-qualification}/incoming/`-এ নেই;
এই run-এর কোনো archive local-এ install বা device-test করা হয়নি। Exact archive
যাচাইয়ের input হিসেবে owner-mediated handoff folder-গুলোই রাখা হয়েছে। Build pass
accelerator correctness, release publication, বা hosted APT install/upgrade gate
বন্ধ করে না।

### সর্বশেষ PR #97 artifact সংগ্রহ — source head `0f2d9f5` — ২০২৬-১১-০৯

Local source-built `ternux_2.0.0_all.deb` এখনো install আছে: 129,352 byte, SHA-256 `363f906c1644408d86bd332eff7f5fd6964004b07180de0d855efd3210963f7c`; `ternux verify --json` pass করেছে। PR source head `0f2d9f5492d2964e2efbaa13efec3eff768d57a9`-এ আটটি required workflow pass করেছে। PR #97 draft হওয়ায় preview/publication workflow skip হয়েছে। Actions artifact metadata:

| Artifact | ID | Byte | Archive SHA-256 |
|---|---:|---:|---|
| `ternux-apt-unsigned-ci-195d094bd7999a684995665d03767d192c3fbbf9` | `13641307456` | 268,664 | `a08dcb995c4888c783c4bcae4c8292c88b9fe15b50aadee1c00e9321d4b30ec6` |
| `ternux-llama-vulkan-linux-arm64-b11582-candidate` | `13641273491` | 21,326,091 | `c373af05488f25a9348b6434342c3eedb8a17a9320f5d50e21c0903800ed0b91` |
| `ternux-stable-diffusion-vulkan-linux-arm64-master-1053-candidate` | `13640903441` | 27,033,643 | `dbcb7d0f44771313f74b10b405fb8f9289f6530e0820e9809138400c028e6a4c` |
| `ternux-llama-htp-sm8735-integer-hmx-v73-candidate` | `13641249471` | 15,530,439 | `8fe85c0c8674be52ea98fb013b0b84b9c10f553f76dd1e619021aad0eb84fbe9` |
| `ternux-llama-htp-sm8735-b11582` | `13641971275` | 15,636,123 | `9a17d2937b6387b1ece19f3a8d3af1edd972cd3fd56307cd6d53b73f0a936708` |

এগুলো Actions archive digest, extracted package checksum নয়। Owner-mediated handoff policy অনুযায়ী archive download করা হয়নি; `artifacts/ternux-apt/incoming/`, `artifacts/ternux-extensions/incoming/` এবং `artifacts/htp-qualification/incoming/` directory এখনো খালি। তাই exact CI archive install/device qualification বাকি। এই build-গুলোতে local verified package-এর একই product source আছে; এই inventory commit শুধু release documentation বদলেছে।

### Local signed Termux APT client check — ২০২৬-১১-০৯

বর্তমান local `ternux_2.0.0_all.deb` থেকে temporary directory-তে fresh repository
তৈরি করে isolated, স্বল্পমেয়াদি test key দিয়ে `InRelease` sign করেছি। Package-এর
SHA-256 `0cb55b9cefe187c733ad82f205ecc134c1f99e18c7e654b1426382db95f4b68d`।
Official Termux main source-সহ Termux APT client signed index গ্রহণ করেছে,
`apt-cache policy ternux` local repository থেকে 2.0.0 candidate দেখিয়েছে, এবং
`apt-get --simulate install ternux` pass করেছে। Download-only
`apt-get download ternux=2.0.0`-এর `.deb`-এর SHA-256 local package-এর সঙ্গে হুবহু
মিলেছে। Active installation বদলানো হয়নি। এই test local package/index/client path
যাচাই করে; protected release key, hosted signed repository, অথবা public clean
install/upgrade যাচাই করে না।

### Local `pkg install` source-build verification — ২০২৬-১১-০৯

Checkout-এর Ternux source থেকে `ternux_2.0.0_all.deb` rebuild করেছি CI workflow-তে
pinned Termux package-builder script দিয়ে (source SHA-256
`dd1acf8cb6eb48a3b6fc50c56a6a1f20426112a458e342980a5955a788494650`) এবং pinned
APT repository-builder script দিয়ে (SHA-256
`d5768791086f3ad1f12e95d59a54ccaf582f3ba43908c452d722ee2b96b49db1`)। Package SHA-256
`363f906c1644408d86bd332eff7f5fd6964004b07180de0d855efd3210963f7c`। Fresh
temporary repository বানিয়ে isolated স্বল্পমেয়াদি test key দিয়ে sign করেছি;
Termux APT client index গ্রহণ করেছে এবং download করা package-এর hash মিলে গেছে।
এরপর `pkg install -y --reinstall ternux` দিয়ে ওই signed local source থেকে package
reinstall করেছি; `ternux verify --json` pass এবং installed CLI package payload-এর
sঙ্গে byte-for-byte মিলে গেছে। Temporary APT source সরিয়ে ফেলা হয়েছে। এটি test
key দিয়ে একই version-এর in-place install; protected release key বা hosted public
repository দিয়ে clean-prefix install নয়।


### সংক্ষিপ্ত audio output ও microphone loopback check — ২০২৬-১১-০৯

Live PulseAudio server-এ `OpenSL_ES_sink` এবং `Ternux_Microphone` দেখা গেছে। তিন সেকেন্ডের Termux:API Opus capture চলার সময় low-level 440 Hz, 0.65-second test tone সক্রিয় sink-এ `paplay` গ্রহণ করেছে। Capture নিজে থেমেছে (`isRecording: false`); 440 Hz band-pass-এ RMS `-42.61 dBFS` মাপা হয়েছে। অস্থায়ী recording ও tone মুছে ফেলা হয়েছে। এই ছোট পরীক্ষায় output submission এবং mic path-এ acoustic signal পাওয়া যাচাই হয়েছে; owner-এর নিজের কানে শোনা বা দীর্ঘক্ষণ playback/music controls যাচাইয়ের বিকল্প নয়।

### বর্তমান head যাচাই ও package notice audit — ২০২৬-১১-০৯

PR #97 head `135609006b867c2ed32b71038a0501eab5185d4a`-এ আটটি required check
pass করেছে: Validate `42542637255`, APT package `42542637286`, repository
contract `42542637246`, knowledge sync `42542637225`, CPU/Vulkan
`42542637226`, Stable Diffusion `42542637243`, production HTP `42542637261`,
এবং SM8735 integer-HMX candidate `42542637212`। PR draft থাকায় preview ও
publication job skip হয়েছে। বর্তমান Actions artifact metadata:

| Artifact | ID | Byte | Archive SHA-256 |
|---|---:|---:|---|
| `ternux-apt-unsigned-ci-0266ac109af0a6670ce50ea1faeb993042d7ba16` | `13642061334` | 268,693 | `0ff6c7bd826a0efc06bbb02355a5f866472dc240528701ce7a59a6cb30735fc0` |
| `ternux-llama-vulkan-linux-arm64-b11582-candidate` | `13641857606` | 21,320,298 | `b2458ac76a1fdef842cf80ca8b4698f6ec02c16de327217ef1c48d99dc501e81` |
| `ternux-stable-diffusion-vulkan-linux-arm64-master-1053-candidate` | `13642167554` | 27,023,984 | `8550c75e77a5711186b900cd0c825a932d24b343f339098424e02e1edefe9a3b` |
| `ternux-llama-htp-sm8735-b11582` | `13641389194` | 15,637,166 | `8e8b10db4df6b88528ad52d01e99c9f615a93a57d38b965be368ad6d9ef7533e` |
| `ternux-llama-htp-sm8735-integer-hmx-v73-candidate` | `13642277117` | 15,530,759 | `4f068dc849a7aabfc8b281898ad3a0f7ceb0875f5f4b7a2d4c8e094948316d68` |

এগুলো GitHub Actions ZIP digest, extracted package checksum নয়। Archive-গুলো
নির্ধারিত incoming directory-তে নেই এবং install করা হয়নি; exact-artifact
qualification বাকি। Local source-built `ternux_2.0.0_all.deb` 129,352 byte,
SHA-256 `363f906c1644408d86bd332eff7f5fd6964004b07180de0d855efd3210963f7c`।
এর archive-এ Mesa source-tag notice bundle আছে; extract করে `SHA256SUMS` চালিয়ে
সব bundled license text যাচাই করেছি। এতে local `.deb`-এ notice inclusion প্রমাণ
হয়; upstream Turnip archive-এ বা অনুপস্থিত exact-current-head APT artifact-এ
নয়। Static Mesa component mapping ও বিস্তৃত transitive-license review বাকি।

এই head-এ local verification pass করেছে: `tests/focused.sh` (129/129),
`tests/smoke.bats` (72/72), installer UI render (33/33), QNN CLIP/tokenizer
unit test (7/7), repo-knowledge unit test (43), documentation check (3,018
assertion), Termux APT bootstrap, formatting, shell syntax, এবং
`ternux verify --json`। `ternux doctor --json`-এ 30 OK, 0 failure, 1
informational check এবং battery 46 °C warning এসেছে। Desktop বন্ধ ছিল এবং বন্ধই
রাখা হয়েছে। Termux-এর Android Node binding দিয়ে local website build চালানো
যায়নি; pinned Linux build-সহ Validate workflow pass করেছে। Exact-artifact
qualification, owner visual review, camera live-preview support, accelerator
correctness/sustained-use gate, public signed APT availability, এবং release
publication এখনো release আটকে রেখেছে।

### বর্তমান PR head artifact ও signing follow-up — ২০২৬-১১-০৯

PR #97 head `99b94413e8f8a2263b8baa245edaf2100236eef0`-এ Validate
`42553378033`, unsigned APT package `42553378059`, repository contract
`42553378055`, knowledge sync `42553378006`, CPU/Vulkan llama.cpp
`42553378100`, Stable Diffusion `42553378034`, এবং integer-HMX candidate
`42553378136` সফলভাবে শেষ হয়েছে। এই inventory লেখার সময় production HTP build
`42553378026` চলছিল। পাওয়া Actions artifact metadata:

| Artifact | ID | Byte | Archive SHA-256 |
|---|---:|---:|---|
| `ternux-apt-unsigned-ci-f3526479a0c9b1ff62a73e0d9a25b3fed30a79a6` | `13646616051` | 268,620 | `157d4b69f9712eab45548e0d8a75b0e49b8b7bc4362f4545401d810e14c92cd1` |
| `ternux-llama-vulkan-linux-arm64-b11582-candidate` | `13645828954` | 21,326,902 | `c4d1789c29e68231b4ee411cf00d58b0dec70081674ba080442a183a79f97a07` |
| `ternux-stable-diffusion-vulkan-linux-arm64-master-1053-candidate` | `13646249363` | 27,031,950 | `eae0bfe9ca5d6580d9addb8fed278cb55fa286eccb25b3aed8a33c3ccc7b208e` |
| `ternux-llama-htp-sm8735-integer-hmx-v73-candidate` | `13647070267` | 15,530,994 | `0c343bf01ef6ecff87a0c14f35616f718f452192b2b25a5e1a1a53989a500037` |

এগুলো GitHub Actions ZIP digest, extracted payload checksum নয়। Exact archive
নির্ধারিত incoming directory-তে রাখা বা device-এ install করা হয়নি, তাই এগুলো
সেই artifact-গুলোর qualification নয়। আলাদাভাবে, main branch-এর commit
`8e24062589e81c20095c875fa4d19dd5cb928554`-এ non-publishing
`verify-signing` mode সফল হয়েছে (run `42554187198`): protected APT key দিয়ে
signed repository build ও verify হয়েছে। এতে signing configuration যাচাই হয়,
public deployment নয়। Hosted APT endpoint দুটিই এখনো 404 দেয়; release gate
খোলা থাকায় publish mode চালানো হয়নি।

### বর্তমান head-এর সম্পূর্ণ CI artifact inventory — ২০২৬-১১-০৯

PR #97 head `0978fba5c46993640acf1b0b7d7986bcf290f666`-এ আটটি validation ও
package-build workflow pass করেছে: Validate `42554550884`, APT `42554550728`,
repository contract `42554550768`, knowledge sync `42554550962`, llama
CPU/Vulkan `42554550807`, Stable Diffusion CPU/Vulkan `42554550879`, production
HTP `42554550670`, এবং integer-HMX candidate `42554550722`। PR draft থাকায়
preview/release publication job skip হয়েছে। বর্তমান Actions artifact metadata:

| Artifact | ID | Byte | Archive SHA-256 |
|---|---:|---:|---|
| `ternux-apt-unsigned-ci-478caf84f5b306f3b2173e6d8d114f10b3b900e5` | `13646663061` | 268,678 | `1c7989ff9fece0288502c4db06186c42c2908c0287699850c83f21661345a4a5` |
| `ternux-llama-vulkan-linux-arm64-b11582-candidate` | `13647211389` | 21,327,346 | `34b897b2951de89dd9e09dbed17e0a624d50c9f295eb266409036e2981d34e19` |
| `ternux-stable-diffusion-vulkan-linux-arm64-master-1053-candidate` | `13646683907` | 27,027,336 | `9579a3d7d5c4e6d0736482fe9eb1ea3c500f5804063f3a0554174fd1e1a030a4` |
| `ternux-llama-htp-sm8735-b11582` | `13647510166` | 15,636,380 | `4d95b279fb296b02583980c99d070f63d592a47433e18618c532729c38b23f0a` |
| `ternux-llama-htp-sm8735-integer-hmx-v73-candidate` | `13646692551` | 15,529,809 | `273fd9f04b4f4281618cf996dd507bbe46ac5a3c8c47adc6f8c19ca0ca4c2aee` |

এগুলো Actions ZIP digest, extracted payload checksum নয়। Exact archive-গুলো
নির্ধারিত incoming directory-তে নেই এবং install বা device test করা হয়নি। তাই
সফল workflow-গুলো pinned build ও static package inspection প্রমাণ করে; CPU/GPU/NPU
runtime, QNN model correctness, sustained use বা device compatibility qualify
করে না। Signed APT key-এর non-publishing verification আলাদা run `42554187198`-এ
pass করেছে, কিন্তু public APT endpoint এখনো 404 দেয়। PR #97 draft এবং release
publication সম্পন্ন হয়নি।

### বর্তমান Node 24 CI artifact inventory — ২০২৬-১১-০৯

PR #97 head `b7bb3850ecc3d21666eff65acd2d67b974c329ba`-এ আটটি build ও
validation workflow pass করেছে: APT `42556143394`, repository contract
`42556143358`, Validate `42556143370`, knowledge sync `42556143419`, llama
CPU/Vulkan `42556143328`, Stable Diffusion `42556143441`, production HTP
`42556143514`, এবং integer-HMX candidate `42556143349`। PR draft থাকায় preview
ও publication job skip হয়েছে। Node 24-compatible workflow update-ও pass করেছে।
Actions artifact inventory:

| Artifact | ID | Byte | Archive SHA-256 |
|---|---:|---:|---|
| `ternux-apt-unsigned-ci-fcac15570a4a3459922276b301d119c8f2610b07` | `13646914880` | 268,611 | `b4730d815992f87a3cc40901d39d5884fa9da8dd65294b0bfd4fcf45b06dcced` |
| `ternux-llama-vulkan-linux-arm64-b11582-candidate` | `13647194909` | 21,329,406 | `289cc0082483ebaa355960d74f772477421ae322f72a4eebb04a92780c759a18` |
| `ternux-stable-diffusion-vulkan-linux-arm64-master-1053-candidate` | `13647907176` | 27,029,814 | `29a84606fcd483f2afc42f3d911be37edb20fa7c28ecdea61b12463eb3d1a65f` |
| `ternux-llama-htp-sm8735-b11582` | `13647314688` | 15,633,028 | `017c22226e22ef3321eafe1aa6a8d9033a1b432d366c25d356ffafe7d96583c0` |
| `ternux-llama-htp-sm8735-integer-hmx-v73-candidate` | `13648120716` | 15,532,991 | `2903df15c67048c85d6909fe1de8bfa36b6cce7f1cef865fb24e8b82aef85a6f` |

এগুলো Actions ZIP digest, extracted payload checksum নয়। Archive-গুলো নির্ধারিত
incoming directory-তে নেই এবং install বা device qualification করা হয়নি। সফল
job-গুলো pinned build ও static packaging প্রমাণ করে। Runtime, numerical
correctness, sustained-use, clean-install, owner visual, camera live-preview,
public signed APT, এবং publication gate এখনো খোলা। PR #97 draft আছে।

### বর্তমান head-এর সম্পূর্ণ CI artifact inventory — ২০২৬-১১-০৯

PR #97 head `c0b7de99673c0a7618514d30f8471f23c0431420`-এ আটটি build ও
validation workflow pass করেছে: APT `42557310299`, repository contract
`42557310329`, Validate `42557310363`, knowledge sync `42557310330`, llama
CPU/Vulkan `42557310347`, Stable Diffusion `42557310304`, production HTP
`42557310507`, এবং integer-HMX candidate `42557310332`। PR draft থাকায় preview
ও publication job skip হয়েছে। Actions artifact metadata:

| Artifact | ID | Byte | Archive SHA-256 |
|---|---:|---:|---|
| `ternux-apt-unsigned-ci-2aafb646e1bb30a9ee66cc8b0e9a4c195167296b` | `13646994621` | 268,622 | `256f2d7e71001b19b387832bbb6efda016cfa87731a1df2c4440fb982aaf6244` |
| `ternux-llama-vulkan-linux-arm64-b11582-candidate` | `13648121485` | 21,321,152 | `458b9dfc92f0e3a404e2050378e173595b1cb2cefaae1e5913cdaa9137969af5` |
| `ternux-stable-diffusion-vulkan-linux-arm64-master-1053-candidate` | `13647719068` | 27,028,493 | `4bf92744b0a4aedf380f8d2b30aa6cd2ba9a3b54cd4d8036972804535fd36995` |
| `ternux-llama-htp-sm8735-b11582` | `13648505570` | 15,632,903 | `0bed70ecddb9873116d094b4d7932c8cf40a0912ad5ebb1b79958ca52698032d` |
| `ternux-llama-htp-sm8735-integer-hmx-v73-candidate` | `13648406193` | 15,534,201 | `80747d62304dae39592bd796d4ba7a5c1288f3a8d494408f6a7cd0e147c87d6b` |

এই SHA-256 মানগুলো GitHub Actions ZIP archive-এর, extract করা payload-এর checksum
নয়। Archive-গুলো নির্ধারিত incoming directory-তে নেই এবং install বা device
qualification করা হয়নি। সফল CI শুধু pinned build ও static packaging প্রমাণ
করে; runtime correctness, numerical behavior, sustained use, clean-install
behavior এবং device compatibility এখনো যাচাই বাকি। এই source head-এ working tree
পরিষ্কার ছিল। নতুন non-GUI `ternux doctor --json` check-এ 30 OK, 0 failure, একটি
informational item এবং battery 44 °C warning এসেছে; desktop বন্ধই ছিল।

### PR #97 CI artifact-এর সম্পূর্ণ তালিকা — source head `19a25eb` — ২০২৬-১১-০৯

PR head `19a25eb42d447717fb80509afb1dd766ee275d3c`-এ আটটি প্রয়োজনীয় check
pass করেছে: Validate `42558158091`, APT `42558158092`, repository contract
`42558158082`, knowledge sync `42558158087`, llama CPU/Vulkan `42558158068`,
Stable Diffusion CPU/Vulkan `42558158114`, production HTP `42558158086`, এবং
integer-HMX candidate `42558158118`। PR #97 draft থাকায় preview/publication job
skip হয়েছে। GitHub Actions artifact metadata:

| Artifact | ID | Byte | Archive SHA-256 |
|---|---:|---:|---|
| `ternux-apt-unsigned-ci-a2013dd8256b511cf90785b42d1d14bf54d3a36c` | `13647553701` | 268,663 | `ed13d138d7ab23db91f1c46c2dd1e813d98f2727632eca610b981e477c114f54` |
| `ternux-llama-vulkan-linux-arm64-b11582-candidate` | `13648218569` | 21,321,978 | `a5c7f563a49223eee9d0ccb38ef731005422766035041de926ce2e7d6049876c` |
| `ternux-stable-diffusion-vulkan-linux-arm64-master-1053-candidate` | `13648666221` | 27,029,887 | `2eec4e2f7744f5ec2378709dc83baa32463f7227adba944e621f3218e733196f` |
| `ternux-llama-htp-sm8735-b11582` | `13648259251` | 15,633,069 | `27db701243e509885a96b6419b440198e44acb6ca6404119df3b4d7222b1e612` |
| `ternux-llama-htp-sm8735-integer-hmx-v73-candidate` | `13648442714` | 15,533,267 | `78ba8a6743e2f97bdb8956622dc53459d0366994f3f3d7ae54124734bfa5188b` |

এগুলো archive digest, extract করা payload-এর checksum নয়। কোনো archive আনা বা
install করা হয়নি; তাই এই build-গুলো exact-artifact device qualification দেয় না।
Artifact যাচাইয়ের জন্য নির্ধারিত owner-handoff directory-ই intake হিসেবে থাকবে।
Package/runtime correctness, clean install, sustained use এবং release publication-এর
সব দাবি উপরের খোলা gate অনুযায়ী যাচাই হবে। পরের documentation-only inventory
update build হওয়া product source বদলায় না।

### PR #97-এর বর্তমান source-head ও live release audit — ২০২৬-১১-০৯

Source head `cd7df4307b9c55ddce76aafecd5a11790a42412a`-এ PR-এর আটটি প্রয়োজনীয়
workflow pass করেছে: unsigned Termux APT package `42593962372`, CPU/Vulkan
llama.cpp `42593962410`, Stable Diffusion `42593962517`, production HTP
`42593962427`, integer-HMX candidate `42593962461`, Validate `42593962422`,
repository contract `42593962492`, এবং knowledge sync `42593962457`। PR #97 draft
থাকায় preview ও public-release job skip হয়েছে। GitHub Actions candidate archive-এর
metadata:

| Artifact | Actions artifact ID | Byte | ZIP SHA-256 |
|---|---:|---:|---|
| `ternux-apt-unsigned-ci-9fe12e9915bcb6821314e60b7301d2614af0f2e0` | `13661918119` | 268,116 | `38d97f8502faf2ace2ac9f963484ae102490b7f1fa97b14ef2761fe8a81a87aa` |
| `ternux-llama-vulkan-linux-arm64-b11582-candidate` | `13662713136` | 21,323,560 | `c2e73acc3f8963e3abf6eaeeb30763fa97643e35555d214753fb930aa2cd9a70` |
| `ternux-stable-diffusion-vulkan-linux-arm64-master-1053-candidate` | `13662364167` | 27,027,607 | `3910614a64e30e0cc00fa9f0ae8a5442bfb747a45bcf913ecdb9190448ac072a` |
| `ternux-llama-htp-sm8735-b11582` | `13663720894` | 15,633,114 | `da36db57e5b631023dab2bba8dd0424eb1a5e19f5b9032c4a7a817c99fbb830e` |
| `ternux-llama-htp-sm8735-integer-hmx-v73-candidate` | `13663990153` | 15,535,173 | `07f543821d1333444b1c7cb6b0e2318f4dec6852b6a8a347fec23841e888139e` |

Digest-গুলো Actions ZIP archive-এর। নির্ধারিত incoming directory-তে exact
current-head archive স্থানান্তর বা install করা হয়নি; তাই এই build-গুলো exact
artifact device qualification সম্পন্ন করে না। এই source head-এ
`tests/focused.sh`-এ 129/129 এবং `tests/docs_check.py`-এ 3,018 assertion, 312টি
internal link ও 19টি bilingual page pair pass করেছে। Installed Ternux 2.0.0
package-এর `ternux verify --json` pass করেছে; `ternux doctor --json`-এ 31 OK,
0 warning, 0 failure এবং 1টি informational item এসেছে। এর মধ্যে Adreno 825
Zink/Turnip Vulkan এবং installed llama Vulkan, Stable Diffusion ও experimental
HTP extension health আছে। সংশোধিত desktop launcher XFCE process চালু হওয়ার
পরেই readiness দেখায়। সর্বশেষ live check-এ detached desktop (PID 16987), X11
এবং PulseAudio running ছিল; desktop restart না করে Termux:X11 foreground-এ আনা
হয়েছে। এগুলো process/runtime evidence, owner-এর visual review নয়।

Hosted signed APT-এর URL (`apt/bootstrap.sh`, `apt/ternux-archive-key.asc`,
`apt/dists/stable/InRelease`) HTTP 404 দিয়েছে। Termux camera-video API PR
[#904](https://github.com/termux/termux-api/pull/904) এবং client PR
[#242](https://github.com/termux/termux-api-package/pull/242) এখনো open; installed
Termux:API-তে in-window live preview-এর camera stream নেই। Exact artifact/device
qualification, QNN stage correctness ও image performance, HTP numerical/operator
qualification, sustained/failure-restart coverage, বিস্তৃত dependency-license
review, camera live preview, owner visual review এবং hosted signed APT clean
install/upgrade বাকি থাকায় release gate 10 এখনো held।

### Desktop start recovery follow-up — ২০২৬-১১-০৯

Product commit `46227886bb6c142d48b2b363fae39fab005f36e0`-এ XFCE ready হলে
`ternux start` Termux:X11 activity সামনে আনে। Start এখন shared X11 socket এবং
চলমান Termux:X11, XFCE session, window manager ও desktop process মিলিয়ে live
session শনাক্ত করে। তাই supervisor marker হারালেও প্রথম session বন্ধ করে আরেকটি
session শুরু করে না। ফোনে `ternux start` PID `16987`-এর জন্য “already running”
জানিয়েছে; `ternux status --json`-এ `running` এসেছে এবং start-এর আগে-পরে একই
PRoot/XFCE PID ছিল। Android জানিয়েছে চলমান Termux:X11 task সামনে আনা হয়েছে;
X11/XFCE restart হয়নি।

এই product head-এর workflow-dispatch pass করেছে: Validate
[42599397496](https://github.com/soobujmiah/ternux/actions/runs/42599397496),
Termux APT package [42599397259](https://github.com/soobujmiah/ternux/actions/runs/42599397259),
এবং Repository State Contract
[42599397452](https://github.com/soobujmiah/ternux/actions/runs/42599397452)। Local
`tests/focused.sh` 130/130 pass করেছে; নতুন test stale marker-সহ live XFCE
session reuse এবং Termux:X11 সামনে আনা যাচাই করে। `tests/docs_check.py`-এ 3,018
assertion, 312 internal link ও 19 bilingual page pair pass করেছে। এই check-গুলো
উপরের খোলা release gate বন্ধ করে না।

### লাইভ ডেস্কটপের দৃশ্যমানতা যাচাই — ২০২৬-১১-০৯

চলমান ডেস্কটপ বন্ধ না করে `ternux start` দিয়ে existing session নিশ্চিত করার
পর Termux:X11 display-তে 752×1155 screenshot নেওয়া হয়। দেখা স্ক্রিনে Ternux
ব্র্যান্ডের XFCE wallpaper, পড়া যায় এমন Home, File System, Trash ও SD Card
desktop icon এবং panel ছিল; display কালো বা ফাঁকা ছিল না। Active X11 session-এর
`DISPLAY=:0` সাড়া দিয়েছে এবং screenshot দেখা হয়েছে। পরিদর্শনের পর অস্থায়ী
screenshot মুছে ফেলা হয়েছে। এতে এই session-এর agent-side live-display rendering
check সম্পন্ন হয়েছে; owner-এর final visual review বা প্রতিটি app/window যাচাই
সম্পন্ন হয়েছে এমন প্রমাণ নয়।

### PR #97-এর বর্তমান release audit — implementation head `d7af3fd` — ২০২৬-১১-০৯

Implementation head `d7af3fd8201df02c44d6e45be2b4a148d6b86328`-এ আটটি প্রয়োজনীয় workflow-ই pass করেছে: [Validate 42611647484](https://github.com/soobujmiah/ternux/actions/runs/42611647484), [Termux APT 42611647218](https://github.com/soobujmiah/ternux/actions/runs/42611647218), [repository contract 42611647274](https://github.com/soobujmiah/ternux/actions/runs/42611647274), [repo knowledge sync 42611647220](https://github.com/soobujmiah/ternux/actions/runs/42611647220), [CPU/Vulkan llama.cpp 42611647462](https://github.com/soobujmiah/ternux/actions/runs/42611647462), [Stable Diffusion CPU/Vulkan 42611647460](https://github.com/soobujmiah/ternux/actions/runs/42611647460), [production HTP 42611647288](https://github.com/soobujmiah/ternux/actions/runs/42611647288), এবং [integer-HMX candidate 42611647459](https://github.com/soobujmiah/ternux/actions/runs/42611647459)। PR #97 এখনো draft বলে preview ও release-publish job skip হয়েছে।

এই implementation-এর local check-গুলো pass করেছে: `tests/focused.sh` ১৩০/১৩০; `tests/docs_check.py`-এ ৩,০১৮ assertion, ৩১২টি internal link ও ১৯টি bilingual pair; এবং `git diff --check`। Termux APT package local-এ rebuild ও reinstall করা হয়েছে। Package-এর ৩৩৪টি asset file source-এর সঙ্গে byte-for-byte মিলে; `ternux verify --json` pass করেছে এবং `ternux doctor --json`-এ ৩১ OK, ০ warning, ০ failure ও ১ informational এসেছে। XFCE/X11 ও PulseAudio চলমান ছিল (desktop PID 16987)। এগুলো package ও বর্তমান runtime-এর evidence; clean-device install বা owner-এর visual approval নয়।

Release gate ১০ এখনো **HELD**। Exact current-head CI archive নির্ধারিত incoming folder-এ স্থানান্তর বা device-এ install হয়নি। Independent QNN stage correctness ও image-generation target বাকি; HTP-তে নথিবদ্ধ numerical/operator failure আছে এবং বিস্তৃত sustained/restart qualification হয়নি; transitive license review-ও অসম্পূর্ণ। Camera-video API/client PR [#904](https://github.com/termux/termux-api/pull/904) ও [#242](https://github.com/termux/termux-api-package/pull/242) এখনো open। Owner-এর final visual review এবং hosted signed APT clean install/upgrade-ও বাকি; এই audit-এ hosted bootstrap, key ও `InRelease` endpoint HTTP 404 দিয়েছে। Release plan-এর প্রযোজ্য gate pass না করা পর্যন্ত v2 publish বা stable HTP/QNN support claim করা যাবে না।

### Stable Diffusion extension component-license audit — ২০২৬-১১-০৯

Exact upstream source pin `5a1ba5d895bec4e07deab80d6d791721cd59d9c2`; এর `ggml` gitlink `135ce1e0e3f2b0693d3de93d4f6b5fa0a1947820`। CMake review-এ এই build-এর জন্য `FetchContent` বা `ExternalProject` dependency download পাওয়া যায়নি। `sd-cli` pinned GGML submodule, Oniguruma 6.9.10, utf8proc, darts-clone tokenizer data, miniz, nlohmann JSON এবং stb image load/write/resize header staticভাবে যুক্ত করে। Exact component ও license-source map `packaging/stable-diffusion/components.json`-এ; workflow GGML pin যাচাই করে, Oniguruma/utf8proc/darts/GGML/upstream ও Ternux notice বাধ্যতামূলক করে, এবং embedded header notice `source-notices/`-এ অক্ষত রাখে। Optional CMake `_deps` tree কেবল থাকলে scan হয়; তার উপস্থিতি metadata-তে লেখা হয়—তাই directory না থাকলে bundle fail করে না বা অনুপস্থিত tree-কে খালি উপস্থিত directory বলে না। Bundle index ও SHA-256 তালিকা প্রতিটি notice, source header ও component manifest entry-র checksum ধরে। Local regression check অনুপস্থিত optional tree, missing component license, duplicate এবং source-tree escape symlink যাচাই করে। Local source/bundle audit pass করেছে; updated implementation `f4bb945` commit-এর ARM64 CI run `42773827441`-এ pass করেছে। এই audit শুধু pinned Stable Diffusion build configuration cover করে; Mesa ও অন্য release artifact-এর বিস্তৃত transitive-license review এখনো বাকি।


### Artifact rebuild বন্ধ ও আগের build reuse — ২০২৬-১১-১০

ARM64/Vulkan, Stable Diffusion ARM64, HTP ARM64 এবং integer-HMX candidate
workflow এখন pull request event-এ build করে না। আগের `pull_request` trigger-এর
default event-এর মধ্যে `synchronize` ছিল। GitHub path filter পুরো PR diff দেখে;
তাই PR #97-এ workflow বা package input আগে থেকেই থাকলে পরের documentation-only
push-ও সেই heavy build আবার চালাত। Head `9016bf9`-এ duplicate build শনাক্তের পর
`42774732346` (llama Vulkan), `42774732436` (Stable Diffusion),
`42774732564` (HTP) এবং `42774732544` (HMX candidate) cancel করা হয়। এখন heavy
candidate build শুধু manual workflow dispatch-এ চলে।

তিনটি publishable workflow এবং HMX candidate workflow-তে ঐচ্ছিক successful `source_run_id` দেওয়া যায়। এটি দিলে compile job skip হয়; workflow/repository, run success, artifact
name ও expiry যাচাই করা হয়; পাশাপাশি build-job definition এবং package input
একই আছে কি না মিলিয়ে তারপর আগের run থেকে artifact download হয়। ID খালি রাখলে
নতুন candidate build হয়। নতুন upload ৯০ দিন রাখা হবে। আলাদা explicit workflow
input ছাড়া publication হয় না; publisher শুধু `main`-এ চলে। এই পরিবর্তনে কোনো
asset publish করা হয়নি।

GitHub Actions-এর read-only metadata এবং verifier দিয়ে নিশ্চিত হয়েছে যে আগে
built `f4bb945576f03a9d8979d7d89553660471dafbaf`-এর artifact পুনরায় compile ছাড়া
ব্যবহার করা যাবে: run `42773827384` (llama Vulkan), `42773827441` (Stable
Diffusion), এবং `42773827791` (HTP)। Artifact ID যথাক্রমে `13743217082`,
`13743396792`, `13742783760`। Vulkan artifact ২০২৭-০২-০৮-এ expire হবে; Stable
Diffusion ও HTP ২০২৬-১১-২৪-এ। HMX candidate run `42773827449`, artifact
`13743875024`, ২০২৬-১১-২৪ পর্যন্ত আছে। HMX workflow আগের যাচাইকৃত candidate compile না করে আবার upload করে ৯০ দিনের Actions retention দিতে পারে। Workflow-এর retention setting আগে upload
হওয়া artifact-এর expiry বদলায় না। এগুলো সাময়িক Actions artifact, স্থায়ী
GitHub Release asset নয়; merge-এর পর distribution দরকার হলে owner-কে publisher
স্পষ্টভাবে dispatch করতে হবে। এই audit-এ artifact-এর ভেতরের ফাইল download করা
হয়নি।


Artifact-reuse workflow commit `89802f73408a1638221c0b3f62c26d212385b2ea` Validate `42779265831`, Termux APT `42779265743`, Repository State Contract `42779266172`, এবং Repo Knowledge Sync `42779266194` pass করেছে। ওই PR update-এ accelerator build চলেনি।


Public HTP prerelease-এ এখনো পুরোনো ২০২৬-১০-১৩ archive আছে: SHA-256
`dffcf83fa969f3ccfad238217b4ca7f3d47040e5e5b2fa834ebd3f123d144ea5`, ১৫,৫১৯,৬৩১
byte। Retained latest candidate Actions run `42783356495`, artifact `13747701121`,
২০২৭-০২-০৮ পর্যন্ত আছে; downloaded archive-এর sidecar যাচাইয়ে SHA-256
`a139a6248356a44e89348ddbe1334edaad33f81a9efbe8f5b8fe3c5733dcf3de` এবং size
১৫,৬৯১,৩২৩ byte মেলে। PR #97 integrate হওয়ার পর main-only publisher এই run ID
নিয়ে existing prerelease-এ latest archive দিতে পারবে, rebuild লাগবে না। এই experimental prerelease refresh stable HTP qualification বা v2.0.0 gate বন্ধ করে না;
পরিচিত failure release note-এ স্পষ্ট থাকবে।


এই requested update শুধু experimental HTP prerelease-এর জন্য; এটি stable HTP
support বা v2.0.0 publication দাবি করে না। Current PR head-এ exact publisher provenance
verifier run `42783356495`-এর ancestry, unchanged build definition/package input,
run/artifact provenance ও expiry pass করেছে। PR #97 owner/CODEOWNERS review পেয়ে
`main`-এ integrate হলেই retained run `42783356495` পুনর্ব্যবহার করে existing
prerelease asset rebuild ছাড়া update করা যাবে। Release note-এ HMX/attention-এর
পরিচিত failure ও experimental status রাখতে হবে। Archive-এর checksum ও inventory
যাচাই হয়েছে, কিন্তু এটি device-এ চালানো হয়নি।
