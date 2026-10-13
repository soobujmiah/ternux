---
title: Accelerator ও ecosystem release completion plan
description: পরবর্তী Ternux release-এর আগে standalone QNN, qualification ও artifact installation gate।
lang: bn
alt_url: /docs/ACCELERATOR-RELEASE-PLAN.html
---

২০২৬-১০-১৩-এর owner direction: আগে নিজস্ব standalone QNN image path সম্পূর্ণ
করব; তারপর Ternux NPU support-এর মূল কাজে ফিরব। পরবর্তী Ternux version release-এর
২০২৬-১০-১৪-এর owner clarification: অন্য ডিভাইসে Ubuntu install এই release-এর
blocker বা বাকি কাজ নয়; এটি স্থগিত। Ubuntu profile এখনো device-এ যাচাই করা হয়নি।
পরবর্তী Ternux version-এর আগে scope-এর বাকি accelerator ও release gate শেষ করতে
হবে। এটি pending কাজের plan, shipped capability নয়।

| ক্রম | কাজ | বর্তমান status | Completion evidence |
|---|---|---|---|
| ১ | PRoot থেকে callable নিজস্ব Android/Bionic QNN helper | Runtime/provider, backend/device, VAE context load/free ও encoder graph execution VERIFIED; generic HTP Add known-answer VERIFIED; model output correctness UNVERIFIED | Matching execution headers, tensor metadata, request/response, known-output accelerator test |
| ২ | Existing QNN picture model একই জায়গায় রেখে ব্যবহার | No-copy VAE/UNet fixed-input graph execution VERIFIED; 2026-10-14-এ fixed-prompt CLIP CPU input/output repeatability VERIFIED; CLIP-to-UNet ও prompt-to-image UNVERIFIED | CLIP/UNet/VAE pipeline, graph execution, stage attribution, fixed-seed image test ও reviewed output |
| ৩ | মূল Debian llama.cpp CPU/GPU/HTP qualification | CPU/Vulkan known-answer pass; default HTP path FAILED; HVX matmul ও flash-attention-off-এ SM8735-এ Qwen2.5 1.5B ও Llama 3.2 3B-এর short answer pass (2026-10-14) | HMX/attention mismatch isolate, repeatability ও longer prompt qualify, তারপর pinned supported configuration qualify |
| ৪ | Repeat ও sustained device qualification | SM8735-এ thermal status 0-সহ পরপর ৬০০টি 720p/16-sample EEVEE frame সম্পন্ন (2026-10-14); packaged extension-এর CPU ও Vulkan-এ live generation চলাকালীন একবার করে SIGINT, clean exit ও restart-এর পর known-answer pass; পরে restart check ছাড়া আরেকটি CPU clean-cancel sample (2026-10-14)। Sustained CPU/NPU, repeated cancellation stress, NPU cancellation ও fallback এখনও UNVERIFIED | Matched run, memory/thermal/power availability, দীর্ঘ stability, repeat ও NPU load-এ cancel/restart/cleanup, safe fallback |
| ৫ | পুনর্ব্যবহারযোগ্য GitHub artifact | Pinned Vulkan ARM64 package native runner-এ build; checksum, ELF, RUNPATH, dependency ও bundled license check করা। Prerelease হিসেবে প্রকাশিত ও SM8735-এ install হয়েছে; CPU ও Adreno Vulkan known-answer pass. HTP experimental. | Clean-device Mesa/Turnip install, বিস্তৃত license/ABI review এবং পুনরাবৃত্ত/দীর্ঘ device qualification |
| ৬ | Extension install ও সম্পূর্ণ guide | প্রকাশিত CPU + Vulkan prerelease-এর জন্য COMPLETE: `ternux extension list/install llama-vulkan` host delegation, guest install, SHA-256, archive path, atomic destination ও no-overwrite যাচাই করা; CPU ও Vulkan known-answer pass। Website-এর সংক্ষিপ্ত guide repository-র বিস্তারিত automatic/manual guide-এ link করে; install নীতি ও ADT-র আলাদা ownership নথিভুক্ত। | ভবিষ্যৎ extension-এর নিজস্ব release ও validation gate লাগবে; এই ধাপ HTP বা পরের stable Ternux release qualify করে না। |
| ৭ | CLI ও installation screen polish | Repository UI renderer suite-এ portrait, landscape ও resize মিলিয়ে ২৪/২৪ pass; CLI guide-এ CPU/Vulkan-এর quick ও deep guide link যোগ হয়েছে। Phone-এ মানুষের visual/usability validation বাকি। | পরিষ্কার mobile layout, অর্থপূর্ণ status/error, interactive/unattended path ও owner-এর visual/usability validation |
| ৮ | Complete Ternux version release | HELD | সব আগের gate, accurate support matrix, required CI, installed-artifact device test ও final documentation |

দ্বিতীয় ধাপের QNN archive দিয়ে CPU/GPU execution প্রমাণ হবে না: প্রতিটি path-এর
compatible weights/backend pair লাগবে। HTP-এর জন্য compiled `.bin` context
CPU/GPU backend-এ নিজে থেকে portable নয়। Prerequisite-এর জন্য valid test করা
না গেলে BLOCKED লিখব; unrun test-কে FAILED বা PASS বলব না। Optional 1.58-bit/Q8
experiment current correctness gate-এর বাইরে থাকবে।

## Vulkan প্রমাণের graphics নির্ভরতা

ক্রম ৩-এ একটি Vulkan known-answer pass লিপিবদ্ধ আছে। সেই pass Debian-এর দেওয়া কোনো
কিছুর উপর দাঁড়িয়ে নেই। ২০২৬-১০-১৩-এ Adreno 825 ডিভাইসে মাপা: Debian-এর
`mesa-vulkan-drivers 25.0.7-2+deb13u1` **কোনো Adreno device-ই পায়নি** — শুধু
`llvmpipe`, CPU-type Vulkan device হিসেবে — এবং একই ডিভাইসে জোর করে software GL
চালালে ধীর render নয়, `SIGILL` হয়েছে। তাই Vulkan row-টি Turnip-এর উপর নির্ভরশীল।
Ternux GPU phase এখন upstream Debian Trixie ARM64 archive-এর pinned release
`mesa-26.3.0-devel-20260824` ব্যবহার করে এবং install-এর আগে SHA-256
`c014cf66bdbff96417ee30d34f006cf51df64ae04893d599711b0b6b73b52ccf` যাচাই করে।
এটি upstream binary dependency, Ternux-built artifact নয়; ফলাফলের সঙ্গে এই
নির্ভরতা উল্লেখ করতে হবে।

এর একটি পরিণতি ক্রম ৫-এর উপর। যে driver দরকার সেটি clean device-এ না থাকলে Vulkan
path-এর clean-device install verification পাস করতে পারে না। Pinned input mutable-download
gap বন্ধ করে; clean-device install, ABI ও license review এখনও ক্রম ৫-এর খোলা gate।

[গ্রাফিক্স স্থায়িত্ব](GRAPHICS-PERSISTENCE.html) চালু install-এ apt-safe driver layout
নথিভুক্ত করে। এটি clean-device qualification বা reusable artifact gate-এর বিকল্প নয়।

## পরের কাজ

[Standalone discovery experiment](../../experiments/qnn-native/README.md)-এ
নিজস্ব source, measured runtime identity, reproduction command ও inference
prerequisite আছে। Image pipeline implement করার আগে verified graph execution-এর independent
known-output tensor যাচাই করব। Existing QNN archive ও GGUF path অপরিবর্তিত
রাখতে হবে।

[Benchmark report](BENCHMARKS.md)-এ CPU/GPU ফল ও HTP failure আছে। LAI-এর জন্য
প্রযোজ্য finding তার native Android research note-এ থাকবে; এই plan LAI runtime
বা device gate পরিবর্তন করে না।
