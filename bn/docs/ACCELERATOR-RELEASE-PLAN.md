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
| ২ | বিদ্যমান QNN picture model | CLIP CPU, UNet/VAE HTP graph execution এবং fixed-seed SD1.5 generation SM8735-এ হয়েছে। DPM++ scheduler ঠিক করার পর একই seed-এর 20-step 512×512 output repeat হয়েছে (`1a13957f…6764fc3`); একটি coherent landscape-এ ছোট cyan artifact ছিল। এরপর 25-image, 20-step soak 25/25 সফল (17m36s batch wall; এর মধ্যে polling interval আছে)। Runner median 29.76 s, mean 31.12 s/image; HTP UNet median 15.96 s, mean 17.03 s/20 step। এক step 26.24 s outlier ছিল। CLIP CPU-তে, UNet/VAE QNN HTP-তে। Battery max 41.9°C, `quiet_therm` 47.9°C, sampled GPU-labelled zone 64.2°C; NPU-specific thermal sensor পাওয়া যায়নি। ২৫টির মধ্যে একটি visual review হয়েছে। Independent QNN tensor correctness UNVERIFIED। | CLIP/UNet/VAE stage tensor স্বাধীন expected value-র সঙ্গে তুলনা; বাকি image review ও supported configuration qualify |
| ৩ | Debian llama.cpp CPU/GPU/HTP | CPU/Vulkan known-answer pass। SM8735-এ Qwen2.5 1.5B-এর HMX-selected matmul + flash attention off এবং HVX matmul + flash attention on ভুল token দিয়েছে; HVX-only + flash attention off expected `4` দিয়েছে। Exact package run `38560288558` isolated home-এ install করে SmolLM2-135M `2 + 2 = 4` দিয়েছে; 31/31 layer HTP0-তে এবং `closeSession [0, 0]` সফল। Exact package-এ bounded SIGINT-ও child থামিয়ে session cleanly close করেছে (broker exit 130)। Metadata-corrected build `38562008524` pass; archive SHA-256 `229f8026084d83d2853be89319cef23fb0909101edb0be916b33cc1bd441f845`। Archive inventory-তে `README.txt` ও `build-manifest.json` ছাড়া সব runtime file/symlink tested archive-এর সঙ্গে অভিন্ন। HVX-only route-এ 2,955-token prompt/511-token generation ও clean-idle repeat recall key `KITE-8042` ঠিক রেখেছে; HTP Vulkan-এর চেয়ে ধীর। এগুলো bounded GGUF/llama.cpp result; broad operator qualification, QNN-compiled text model বা supported route নয়। | দুই HMX/attention wrong-token কারণ খোঁজা; optimized correctness/performance ও বিস্তৃত sustained stability qualify |
| ৪ | Repeat ও sustained device qualification | SM8735-এ thermal status 0-সহ 600টি 720p/16-sample EEVEE frame; packaged CPU/Vulkan-এ তিনটি করে live-generation SIGINT clean-exit ও restart check pass। Exact HTP artifact bounded SIGINT-এ child থেমে `closeSession [0, 0]` দিয়েছে। আলাদা QNN SD1.5 mixed CPU/HTP pipeline 25/25 image-এর 17m36s soak সম্পন্ন করেছে; এটি নির্দিষ্ট experimental workload, সাধারণ NPU stability প্রমাণ নয়। failure/restart ও বিস্তৃত sustained CPU/NPU qualification বাকি। Automatic CPU fallback নেই। | supported path জুড়ে failure/restart ও sustained CPU/NPU আচরণ qualify |
| ৫ | পুনর্ব্যবহারযোগ্য GitHub artifact | CPU/Vulkan ARM64 build ও ABI audit run `38521164812`-এ pass; exact archive isolated install ও CPU/Adreno Vulkan known-answer-ও pass। HTP run `38560288558` checksum, safe-path, isolated install, HTP0 known-answer ও cancellation pass। Metadata-corrected HTP run `38562008524` pass; checksum-verified archive-এ tested runtime payload অপরিবর্তিত, শুধু README/manifest metadata বদলেছে এবং `libcdsprpc.so` / `libfastrpc-dev` dependency যুক্ত হয়েছে। HTP experimental। | clean-driver install ও transitive license review; correctness ও compatibility gate খোলা রাখা |
| ৬ | Extension install ও guide | CPU + Vulkan prerelease-এর install, SHA-256, archive check, atomic/no-overwrite ও known-answer pass। HTP run `38560288558` exact package isolated HOME-এ installer fixture দিয়ে install; path/manifest/launcher check pass। Metadata-corrected `38562008524`-ও checksum ও isolated installer fixture pass করেছে; README/manifest বদলেছে, runtime file একই। HTP experimental ও unpublished। | Experimental HTP support ও release gate আলাদা রাখা |
| ৭ | CLI ও installation screen polish | Renderer suite portrait/landscape/resize-এ 24/24 pass; human visual/usability check phone-এ বাকি। | পরিষ্কার mobile layout, অর্থপূর্ণ error/status, interactive ও unattended path, owner usability review |
| ৮ | Ternux stable release | HELD | আগের gate, accurate support matrix, required CI, installed-artifact device test ও final docs শেষ |

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
