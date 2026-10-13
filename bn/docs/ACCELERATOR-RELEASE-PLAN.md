---
title: Accelerator ও ecosystem release completion plan
description: পরবর্তী Ternux release-এর আগে standalone QNN, qualification ও artifact installation gate।
lang: bn
alt_url: /docs/ACCELERATOR-RELEASE-PLAN.html
---

২০২৬-১০-১৩-এর owner direction: আগে নিজস্ব standalone QNN image path সম্পূর্ণ
করব; তারপর Ternux NPU support-এর মূল কাজে ফিরব। পরবর্তী Ternux version release-এর
আগে প্রতিটি gate শেষ করতে হবে। এটি pending কাজের plan, shipped capability নয়।

| ক্রম | কাজ | বর্তমান status | Completion evidence |
|---|---|---|---|
| ১ | PRoot থেকে callable নিজস্ব Android/Bionic QNN helper | Runtime/provider, backend/device ও VAE context load/free and encoder graph execution VERIFIED; generic HTP Add known-answer VERIFIED; model output correctness UNVERIFIED | Matching execution headers, tensor metadata, request/response, known-output accelerator test |
| ২ | Existing QNN picture model একই জায়গায় রেখে ব্যবহার | No-copy VAE/UNet fixed-input graph execution VERIFIED; prompt-to-image inference UNVERIFIED | CLIP/UNet/VAE pipeline, graph execution, stage attribution, fixed-seed image test ও reviewed output |
| ৩ | মূল Debian llama.cpp CPU/GPU/HTP qualification | CPU/Vulkan known-answer pass; HTP known-answer FAILED | Q4 mismatch diagnosis, operator validation, intended backend-এ correct model answer reproduce |
| ৪ | Repeat ও sustained device qualification | তিনটি short CPU/GPU benchmark; sustained test UNVERIFIED | Matched run, memory/thermal/power availability, stability, cancel/restart/cleanup, safe fallback |
| ৫ | পুনর্ব্যবহারযোগ্য GitHub artifact | HTP experimental prerelease আছে; Vulkan package local; standalone helper NDK CI artifact device graph test pass; release install package pending | Pinned input, ABI/ELF check, checksum, license, manifest ও clean-device install verification |
| ৬ | Extension install ও সম্পূর্ণ guide | বর্তমান LLM installer source থেকে build করে | Release-based selectable ADT/llama.cpp/extension, auto/manual step, model path, backend selection, upgrade/resume/error handling |
| ৭ | CLI ও installation screen polish | Release phase-এ pending | পরিষ্কার mobile layout, অর্থপূর্ণ status/error, interactive/unattended path ও usability validation |
| ৮ | Complete Ternux version release | HELD | সব আগের gate, accurate support matrix, required CI, installed-artifact device test ও final documentation |

দ্বিতীয় ধাপের QNN archive দিয়ে CPU/GPU execution প্রমাণ হবে না: প্রতিটি path-এর
compatible weights/backend pair লাগবে। HTP-এর জন্য compiled `.bin` context
CPU/GPU backend-এ নিজে থেকে portable নয়। Prerequisite-এর জন্য valid test করা
না গেলে BLOCKED লিখব; unrun test-কে FAILED বা PASS বলব না। Optional 1.58-bit/Q8
experiment current correctness gate-এর বাইরে থাকবে।

## পরের কাজ

[Standalone discovery experiment](../../experiments/qnn-native/README.md)-এ
নিজস্ব source, measured runtime identity, reproduction command ও inference
prerequisite আছে। Image pipeline implement করার আগে verified graph execution-এর independent
known-output tensor যাচাই করব। Existing QNN archive ও GGUF path অপরিবর্তিত
রাখতে হবে।

[Benchmark report](BENCHMARKS.md)-এ CPU/GPU ফল ও HTP failure আছে। LAI-এর জন্য
প্রযোজ্য finding তার native Android research note-এ থাকবে; এই plan LAI runtime
বা device gate পরিবর্তন করে না।
