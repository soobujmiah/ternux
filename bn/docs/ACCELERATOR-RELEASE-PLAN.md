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
| ২ | বিদ্যমান QNN picture model | CLIP CPU, UNet/VAE HTP graph execution এবং fixed-seed SD1.5 generation SM8735-এ হয়েছে। একই seed-এর 20-step output repeat হয়েছে; 25-image soak 25/25 সফল। Runner median/mean 29.76/31.12 s/image; UNet median/mean 15.96/17.03 s/20 step। Thermal peak: battery 41.9°C, `quiet_therm` 47.9°C, sampled GPU zone 64.2°C; NPU sensor শনাক্ত হয়নি। ২৫টি image-ই visual screen হয়েছে: image 01 full resolution-এ, বাকি ২৪টি contact sheet-এ। সবগুলো coherent landscape variation; image 01-এ ছোট cyan/black artifact, অন্যগুলোতে contact-sheet size-এ অনুরূপ স্পষ্ট defect দেখা যায়নি। এটি detailed full-resolution review নয়। Independent QNN tensor correctness UNVERIFIED। | CLIP/UNet/VAE stage tensor স্বাধীন expected value-র সঙ্গে তুলনা এবং supported configuration qualify |
| ৩ | Debian llama.cpp CPU/GPU/HTP | CPU/Vulkan known-answer pass। HVX-only `MUL_MAT` operator suite 1,389/1,389 pass; HMX-selected `MUL_MAT`-এ 529টি `inf` failure। HVX matmul-এ `FLASH_ATTN_EXT` run 120 s-এ timeout হওয়ার আগে 1,848 numerical error ও 112 pass দেখিয়েছে; suite incomplete। One-token test-এ HVX-only + flash attention off expected `4`; HMX matmul ও HVX + flash attention on ভুল token দিয়েছে। Exact-package known-answer, 31/31 layer assignment ও clean cancellation pass। 2,955-token prompt/511-token long test recall key `KITE-8042` রেখেছে, তবে HTP Vulkan-এর চেয়ে ধীর। এগুলো bounded GGUF/llama.cpp result; সব HTP operator qualify বা supported route নয়। | HMX ও flash-attention failure কারণ খোঁজা; অন্য HVX operator, fallback/restart ও sustained stability qualify |
| ৪ | Repeat ও sustained device qualification | SM8735-এ thermal status 0-সহ 600টি 720p/16-sample EEVEE frame; packaged CPU/Vulkan-এ তিনটি করে live-generation SIGINT clean-exit ও restart check pass। Exact HTP artifact bounded SIGINT-এ child থেমে `closeSession [0, 0]` দিয়েছে। আলাদা QNN SD1.5 mixed CPU/HTP pipeline 25/25 image-এর 17m36s soak সম্পন্ন করেছে; এটি নির্দিষ্ট experimental workload, সাধারণ NPU stability প্রমাণ নয়। failure/restart ও বিস্তৃত sustained CPU/NPU qualification বাকি। Automatic CPU fallback নেই। | supported path জুড়ে failure/restart ও sustained CPU/NPU আচরণ qualify |
| ৫ | পুনর্ব্যবহারযোগ্য GitHub artifact | CPU/Vulkan ARM64 build ও ABI audit run `38521164812`-এ pass; exact archive isolated install ও CPU/Adreno Vulkan known-answer-ও pass। HTP run `38560288558` checksum, safe-path, isolated install, HTP0 known-answer ও cancellation pass। Metadata-corrected HTP run `38562008524` pass; checksum-verified archive-এ tested runtime payload অপরিবর্তিত, শুধু README/manifest metadata বদলেছে এবং `libcdsprpc.so` / `libfastrpc-dev` dependency যুক্ত হয়েছে। HTP experimental। | clean-driver install ও transitive license review; correctness ও compatibility gate খোলা রাখা |
| ৬ | Extension install ও guide | CPU + Vulkan prerelease-এর install, SHA-256, archive check, atomic/no-overwrite ও known-answer pass। HTP run `38560288558` exact package isolated HOME-এ installer fixture দিয়ে install; path/manifest/launcher check pass। Metadata-corrected `38562008524`-ও checksum ও isolated installer fixture pass করেছে; README/manifest বদলেছে, runtime file একই। HTP experimental ও unpublished। | Experimental HTP support ও release gate আলাদা রাখা |
| ৭ | CLI ও installation screen polish | Renderer suite portrait/landscape/resize-এ 24/24 pass; human visual/usability check phone-এ বাকি। | পরিষ্কার mobile layout, অর্থপূর্ণ error/status, interactive ও unattended path, owner usability review |
| ৮ | Ternux stable release | HELD | আগের gate, accurate support matrix, required CI, installed-artifact device test ও final docs শেষ |

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

`GGML_HEXAGON_MM_SELECT=1` দিয়ে HVX matmul বেছে নিয়ে আলাদা
`FLASH_ATTN_EXT` operator run ১২০ সেকেন্ডের সীমায় থামানো হয়েছে। ৪,৬৬০টি
case-output line-এর মধ্যে ১,৮৪৮টিতে numerical error (`inf`) এবং ১১২টি pass দেখা
গেছে; timeout exit 124। Suite শেষ হয়নি, তাই এটি observed failure signal এবং
অসম্পূর্ণ run—পূর্ণ suite result নয়। Brokered child থামানো হয়েছে এবং CDSP
session cleanly close হয়েছে। Launcher-এ flash attention বন্ধই আছে; এই operator
correctness এখনও qualify হয়নি।

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
