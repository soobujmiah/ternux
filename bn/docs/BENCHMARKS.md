---
title: "বেঞ্চমার্ক ও ডিভাইস প্রমাণ"
description: "Ternux graphics ও accelerator workload-এর পরিমাপ করা সংক্ষিপ্ত ফল এবং স্পষ্ট evidence boundary।"
lang: "bn"
alt_url: "/docs/BENCHMARKS.html"
evidence_through: "2026-10-14"
---

এই পৃষ্ঠায় একটি configured Redmi Turbo 4 Pro / SM8735 / Adreno 825 device-এর
মাপা workload ও তার সীমা সংক্ষেপে দেওয়া হয়েছে। অন্য device-এর compatibility
বা performance guarantee এটি নয়।

## Evidence class

| Class | অর্থ |
|---|---|
| **Measured** | সম্পন্ন workload থেকে সংখ্যাসহ ফল পাওয়া গেছে। |
| **Observed** | build, launch, বা renderer/backend শনাক্তকরণ রেকর্ড হয়েছে। |
| **Verified** | সীমাবদ্ধ functional check প্রত্যাশিত ফল দিয়েছে। |
| **Untested** | যোগ্য workload চালিয়ে দেখা হয়নি। |

## বর্তমান ফলাফল

| Workload | Evidence | সীমা |
|---|---|---|
| `glmark2` OpenGL | **Measured:** score 140। | একটি 800×600 configured session; desktop বা game FPS নয়। |
| `glmark2-es2 --off-screen` | **Measured:** score 364, caveat-সহ। | Off-screen command হলেও DRI3 warning ও windowed header এসেছিল। |
| Blender EEVEE Next | **Measured:** ৬০০ frame, গড়ে 1.49 s/frame; ৬৪৮-frame short, 1.126 s/frame; ১,৪৪০-frame গল্প, 1.944 s/frame। | Zink/Turnip দিয়ে Adreno GPU offload, headless Xvfb-সহ। সীমাবদ্ধ render; বহু ঘণ্টার thermal claim নয়। |
| Blender viewport | **Observed:** Adreno 825-তে Zink/Turnip। | Renderer শনাক্তকরণ EEVEE render time থেকে আলাদা। Cycles GPU **প্রমাণিত নয়**। |
| llama.cpp CPU + Vulkan | **Verified:** দুটো backend-ই সীমাবদ্ধ known-answer prompt-এ `4` দিয়েছে; Vulkan Adreno 825-এ 29/29 layer assign করেছে। **Measured:** নিচে clean-idle long run। | একটি device ও workload-এ Qwen2.5 1.5B Q4_0। |
| llama.cpp Hexagon HTP | **Experimental:** HVX matmul ও flash attention বন্ধ রেখে সীমাবদ্ধ known-answer ও long recall-key check pass করেছে। | HMX-selected matmul + flash attention off এবং HVX matmul + flash attention on-এ ভুল উত্তর এসেছে। HTP supported route নয়। |
| `stable-diffusion.cpp` Vulkan | **Observed:** Vulkan-enabled build-এর report আছে। | Inference, image output, ও seconds/image **Untested**। |
| আলাদা QNN SD1.5 runner | **Measured:** একই seed-এর ২০-step 512×512 output হুবহু repeat হয়েছে; visual review-তে coherent landscape ও ছোট cyan artifact দেখা গেছে। | এটি `stable-diffusion.cpp` নয়; independent stage-tensor correctness এখনো যাচাই হয়নি। |

### Clean-idle llama.cpp throughput

Configured device-এ পরপর চালানো একটি Qwen2.5 1.5B Q4_0 run-এর prompt
processing ও generation rate:

| Backend | Prompt processing | Generation | মোট সময় |
|---|---:|---:|---:|
| CPU | 59.04 tok/s | 2.38 tok/s | 264.39 s |
| Adreno 825 Vulkan | 92.19 tok/s | 13.27 tok/s | 71.30 s |
| Hexagon HTP, HVX / flash attention off | 34.20 tok/s | 12.02 tok/s | 129.46 s |

এটি একটি device-এর সীমিত তুলনা। HTP-তে known-answer pass-করা conservative
configuration ব্যবহার হয়েছে; সেটি Vulkan-এর চেয়ে ধীর ছিল। এটি sustained
performance, power use, বা একাধিক device-এর ফল প্রমাণ করে না।

## বিস্তারিত রেকর্ড

- [সম্পূর্ণ device benchmark evidence, পুনরুৎপাদন ধাপ ও dated measurement](https://github.com/soobujmiah/ternux/blob/main/bn/guides/device-benchmark-evidence.md) — শুধু repository-তে।
- [EEVEE GPU-offload render পদ্ধতি](https://github.com/soobujmiah/ternux/blob/main/experiments/cartoon-pipeline/README.md) — repository workflow ও পরীক্ষিত headless command।
- [CPU/Vulkan package install ও qualification](https://github.com/soobujmiah/ternux/blob/main/bn/guides/llama-vulkan-extension.md#device-qualification-record) — শুধু repository-তে।
- [পরীক্ষামূলক HTP extension install ও সীমা](https://github.com/soobujmiah/ternux/blob/main/bn/guides/llama-htp-experimental.md) — শুধু repository-তে।
- [বর্তমান accelerator gate](ACCELERATOR-RELEASE-PLAN.html)।
- [আলাদা QNN SD1.5 implementation ও evidence](https://github.com/soobujmiah/ternux/blob/main/experiments/qnn-native/README.md) — শুধু repository-তে; `stable-diffusion.cpp` থেকে পৃথক।
