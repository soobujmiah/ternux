---
title: Accelerator ও ecosystem release completion plan
description: পরবর্তী Ternux release-এর আগে বাকি CPU/GPU/HTP qualification ও release gate।
lang: bn
alt_url: /docs/ACCELERATOR-RELEASE-PLAN.html
---

Owner direction, ২০২৬-১০-১৪: পরবর্তী stable Ternux release-এর আগে CPU, GPU ও
NPU qualification এবং release preparation শেষ করতে হবে। মূল HTP কাজের পাশাপাশি
standalone QNN image route-টি আলাদা gate হিসেবে থাকবে। অন্য device-এ Ubuntu
install স্থগিত; এটি release blocker নয়। এই plan pending কাজ নথিভুক্ত করে,
shipped capability দাবি করে না।

| ক্রম | কাজ | বর্তমান অবস্থা | Completion evidence |
|---|---|---|---|
| ১ | PRoot থেকে callable Android/Bionic QNN helper | Runtime/provider, backend/device, VAE context load/free ও encoder graph execution VERIFIED; generic HTP Add known-answer VERIFIED; model output correctness UNVERIFIED | Matching execution headers, tensor metadata, request/response ও known-output accelerator test |
| ২ | বিদ্যমান QNN picture model | CLIP CPU, UNet/VAE HTP graph execution এবং fixed-seed SD1.5 generation SM8735-এ হয়েছে। 25-image soak 25/25 সফল; median/mean 29.76/31.12 s/image, UNet median/mean 15.96/17.03 s/20 step। তিনটি instrumented follow-up 30.797–31.122 s নিয়েছে। একটি profile-এ 880,827,736-byte UNet archive member memfd-এ stream/hash/seal করতে 7.275 s এবং ৪০টি serial HTP request-এ 17.015 s লেগেছে। একই seed repeat হয়েছে; ২৫টি image initial visual screen পেয়েছে, image 01-এ ছোট cyan/black artifact। বাকি ২৪টির full-resolution review ও independent stage-tensor correctness UNVERIFIED। | CLIP/UNet/VAE stage tensor স্বাধীন expected value-র সঙ্গে তুলনা, বাকি image review, measured performance gap তদন্ত ও optimize |
| ৩ | Debian llama.cpp CPU/GPU/HTP | CPU/Vulkan known-answer pass। HVX-only `MUL_MAT` operator suite 1,389/1,389 pass; HMX `MUL_MAT`-এ 529টি `inf` failure। আগের default attention selection-এ HVX matmul-সহ `FLASH_ATTN_EXT` 120 s-এ timeout হওয়ার আগে 1,848 `inf` failure ও 112 pass দেখায়। পরে `GGML_HEXAGON_MM_SELECT=1` ও `GGML_HEXAGON_FA_SELECT=1` দিয়ে suite সম্পন্ন: 5,332 unique case-এর 2,593 pass, 2,732 unsupported, 7 finite numerical-error failure; filtered rerun-এ সাতটিই reproduce হয়েছে। Flash attention launcher-এ বন্ধই আছে। One-token test-এ HVX-only + flash attention off expected `4`; default attention selection-সহ আগের test ভুল token দিয়েছে। Exact-package known-answer, 31/31 layer assignment ও clean cancellation pass। এগুলো bounded GGUF/llama.cpp result; সব HTP operator qualify বা supported route নয়। | HMX/attention numerical error তদন্ত; অন্য HTP operator, failure/restart ও sustained stability qualify |
| ৪ | Repeat ও sustained device qualification | SM8735-এ thermal status 0-সহ 600টি 720p/16-sample EEVEE frame; packaged CPU/Vulkan-এ তিনটি করে live-generation SIGINT clean-exit ও restart check pass। Exact HTP artifact bounded SIGINT-এ child থেমে `closeSession [0, 0]` দিয়েছে। আলাদা QNN SD1.5 mixed CPU/HTP pipeline 25/25 image-এর 17m36s soak সম্পন্ন করেছে; এটি নির্দিষ্ট experimental workload, সাধারণ NPU stability প্রমাণ নয়। failure/restart ও বিস্তৃত sustained CPU/NPU qualification বাকি। Automatic CPU fallback নেই। | supported path জুড়ে failure/restart ও sustained CPU/NPU আচরণ qualify |
| ৫ | পুনর্ব্যবহারযোগ্য GitHub artifact | CPU/Vulkan ARM64 build ও ABI audit run `38521164812`-এ pass; exact archive isolated install ও CPU/Adreno Vulkan known-answer-ও pass। HTP run `38560288558` checksum, safe-path, isolated install, HTP0 known-answer ও cancellation pass। Metadata-corrected HTP run `38562008524` pass; checksum-verified archive-এ tested runtime payload অপরিবর্তিত, শুধু README/manifest metadata বদলেছে এবং `libcdsprpc.so` / `libfastrpc-dev` dependency যুক্ত হয়েছে। HTP experimental। | clean-driver install ও transitive license review; correctness ও compatibility gate খোলা রাখা |
| ৬ | Extension install ও guide | CPU + Vulkan prerelease-এর install, SHA-256, archive check, atomic/no-overwrite ও known-answer pass। HTP run `38560288558` exact package isolated HOME-এ installer fixture দিয়ে install; path/manifest/launcher check pass। Metadata-corrected `38562008524`-ও checksum ও isolated installer fixture pass করেছে; README/manifest বদলেছে, runtime file একই। HTP experimental ও unpublished। | Experimental HTP support ও release gate আলাদা রাখা |
| ৭ | CLI ও installation screen polish | Renderer suite portrait/landscape/resize-এ 24/24 pass; human visual/usability check phone-এ বাকি। | পরিষ্কার mobile layout, অর্থপূর্ণ error/status, interactive ও unattended path, owner usability review |
| ৮ | Ternux stable release | HELD | আগের gate, accurate support matrix, required CI, installed-artifact device test ও final docs শেষ |

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
Debian Trixie ARM64 archive-এর pinned `mesa-26.3.0-devel-20260824` ব্যবহার করে
এবং install-এর আগে SHA-256
`c014cf66bdbff96417ee30d34f006cf51df64ae04893d599711b0b6b73b52ccf` যাচাই করে।
এটি upstream binary dependency, Ternux-built artifact নয়; ফলের সঙ্গে এই তথ্য
উল্লেখ করতে হবে।

Clean device-এ driver অনুপস্থিত থাকলে clean-device Vulkan install pass করা যাবে
না। Pinned input mutable download সমস্যা কমায়; clean-device install, ABI ও
license gate এখনও বাকি। [Graphics persistence](GRAPHICS-PERSISTENCE.html)-এ
apt-safe driver layout আছে; এটি clean-device qualification-এর বিকল্প নয়।

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
