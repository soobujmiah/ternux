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
| ৪ | Repeat ও sustained device qualification | SM8735-এ thermal status 0-সহ পরপর ৬০০টি 720p/16-sample EEVEE frame সম্পন্ন (2026-10-14); CPU/Vulkan same-model arithmetic known-answer pass; sustained CPU/NPU, cancel/restart ও fallback UNVERIFIED | Matched run, memory/thermal/power availability, stability, cancel/restart/cleanup, safe fallback |
| ৫ | পুনর্ব্যবহারযোগ্য GitHub artifact | Pinned Vulkan ARM64 package native runner-এ build; checksum, ELF, RUNPATH, dependency ও bundled license check করা। Prerelease হিসেবে প্রকাশিত ও SM8735-এ install হয়েছে; CPU ও Adreno Vulkan known-answer pass. HTP experimental. | Clean-device Mesa/Turnip install, বিস্তৃত license/ABI review এবং পুনরাবৃত্ত/দীর্ঘ device qualification |
| ৬ | Extension install ও সম্পূর্ণ guide | প্রকাশিত prerelease `ternux extension list/install llama-vulkan` দিয়ে install হয়; host delegation, guest install, SHA-256, archive path ও atomic destination যাচাই করা। CPU ও Vulkan known-answer pass। Reinstall-এ আগের install অক্ষত থাকে; in-place updater নেই। ADT তার নিজস্ব installer-এ থাকে। | Model/backend ও পূর্ণ auto/manual guide শেষ করা; no-overwrite/update নীতি নথিভুক্ত করা |
| ৭ | CLI ও installation screen polish | Release phase-এ pending | পরিষ্কার mobile layout, অর্থপূর্ণ status/error, interactive/unattended path ও usability validation |
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
চালালে ধীর render নয়, `SIGILL` হয়েছে। অর্থাৎ Vulkan row-টি স্থানীয়ভাবে build করা একটি
Turnip-এর উপর নির্ভরশীল, যা ternux নিজে সরবরাহও করে না, pin-ও করে না; আর যে কোনো
package operation ওই driver ফিরিয়ে দিলে row-এর প্রমাণ কিছু না জানিয়েই অকার্যকর হয়ে
যায়। এই নির্ভরতা ফলাফলের সঙ্গেই লিপিবদ্ধ থাকবে, আলাদা করে নয়।

এর একটি পরিণতি ক্রম ৫-এর উপর। যে driver দরকার সেটি clean device-এ না থাকলে Vulkan
path-এর clean-device install verification পাস করতে পারে না। হয় Turnip build ক্রম ৫-এর
নিজের শর্তেই একটি release artifact হবে — pinned input, ABI/ELF check, checksum,
license পর্যালোচনা, release manifest — নয়তো Vulkan ফলাফলটিকে device-local হিসেবে
লিপিবদ্ধ করে clean-device gate-এর বাইরে ঘোষণা করতে হবে। যেমন আছে তেমন থেকে একইসঙ্গে
ক্রম ৫-এ গণ্য হতে পারবে না।

[গ্রাফিক্স স্থায়িত্ব](GRAPHICS-PERSISTENCE.html) চালু একটি install-কে ওই driver হারানো
থেকে বাঁচায় এবং package রি-ইনস্টলের বিপরীতে যাচাই করা, কিন্তু সেটি নিজে কোনো driver দেয়
না এবং কোনো gate বন্ধ করে না।

## পরের কাজ

[Standalone discovery experiment](../../experiments/qnn-native/README.md)-এ
নিজস্ব source, measured runtime identity, reproduction command ও inference
prerequisite আছে। Image pipeline implement করার আগে verified graph execution-এর independent
known-output tensor যাচাই করব। Existing QNN archive ও GGUF path অপরিবর্তিত
রাখতে হবে।

[Benchmark report](BENCHMARKS.md)-এ CPU/GPU ফল ও HTP failure আছে। LAI-এর জন্য
প্রযোজ্য finding তার native Android research note-এ থাকবে; এই plan LAI runtime
বা device gate পরিবর্তন করে না।
