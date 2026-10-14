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
| ২ | বিদ্যমান QNN picture model | CLIP CPU, UNet/VAE HTP graph execution এবং fixed-seed 20-step SD1.5 image generation SM8735-এ চলেছে। DPM++ solver-এর sigma/VP-space ভুল ঠিক করার পর একই seed-এ 512×512 image একই SHA-256-এ repeat হয়েছে; image coherent, তবে ছোট cyan artifact আছে। Independent QNN tensor correctness UNVERIFIED। | CLIP/UNet/VAE stage tensor তুলনা; artifact review; সমর্থিত image/runtime configuration qualify |
| ৩ | Debian llama.cpp CPU/GPU/HTP | CPU/Vulkan known-answer pass। Qwen2.5 1.5B-এর HMX-selected matmul + flash attention off এবং HVX matmul + flash attention on—দুই configuration-ই ভুল token দিয়েছে; HVX-only + flash attention off expected `4` দিয়েছে। SmolLM2-135M CPU/HTP A/B smoke দুটিই `2 + 2 = 4` দিয়েছে; child exit 0, broker session clean close। একই long recall workload-এ 2,955-token prompt / 511-token generation এবং 29/29 HTP0 layer pass; clean-idle throughput CPU 59.04/2.38, Vulkan 92.19/13.27, HTP 34.20/12.02 tok/s—HTP Vulkan-এর চেয়ে ধীর। PR #16-এ experimental broker/launcher merge হয়েছে। Pinned artifact build ও Actions upload run `38533135922`-এ pass; download করা archive এখনো device-এ test হয়নি। এটি GGUF-এর llama.cpp HTP execution, QNN-compiled text model নয়; এখনো supported route নয়। | HMX/attention failure-এর কারণ আলাদা করা; exact experimental HTP artifact device-test; optimized correctness/performance, cancellation ও fallback qualify; তারপর pinned supported configuration |
| ৪ | Repeat ও sustained device qualification | SM8735-এ thermal status 0-সহ 600টি 720p/16-sample EEVEE frame সম্পন্ন। Packaged CPU/Vulkan extension-এ তিনবার করে SIGINT clean-exit এবং পরের known-answer restart pass। ২০২৬-১০-১৪-এর HTP cancellation probe 20 সেকেন্ডেও শেষ হয়নি; harness process group kill করায় `closeSession` রেকর্ড হয়নি। PR #16-এ signal forwarding, bounded escalation ও closeSession reporting merge হয়েছে, তবে device retest বাকি; cancellation UNVERIFIED। HTP fallback-ও UNVERIFIED। | নতুন supervised HTP cancellation/cleanup device-test; fallback ও restart retest; sustained CPU/NPU stability |
| ৫ | পুনর্ব্যবহারযোগ্য GitHub artifact | CPU/Vulkan ARM64 package-এর fresh build ও ABI audit run `38521164812`-এ pass: 69 AArch64 ELF, dependencies resolve, GLIBC সর্বোচ্চ 2.38, `$ORIGIN/../lib`; upstream MIT license আছে। Exact archive isolated home-এ install করে SM8735-এ CPU ও Adreno Vulkan known-answer pass। প্রথম HTP archive run `38533135922`-এ আলাদা upstream third-party license text বাদ পড়েছিল। সংশোধিত PR artifact run `38540202351`-এর SHA-256 `7211af2cbfc63e7cf07671fe968b76a1259f3975d6bc36fdac023b48160180cd`; 192টি archive entry-তে traversal নেই, source manifest pin মিলে, upstream-এর 9টি tracked license/copying text সব আছে, এবং 14টি symlink-এর target package-এর ভেতরে। এতে 103টি regular AArch64 ELF64, আরও 14টি AArch64 symlink alias এবং 4টি Hexagon ELF32 file আছে। এগুলো package check; exact archive-এর device validation নয়। HTP experimental। | Clean-driver install, transitive license review, exact HTP artifact device test, repeated/sustained qualification |
| ৬ | Extension install ও guide | CPU + Vulkan prerelease-এর `ternux extension list/install llama-vulkan`, checksum, archive validation, atomic install ও no-overwrite pass। HTP CLI extension merge হয়েছে এবং PR artifact build pass করেছে; exact archive install ও device validation এখনো বাকি। | HTP exact archive install ও device test; সব warning, dependency ও guide মিলিয়ে নেওয়া |
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
