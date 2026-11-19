---
title: "টার্নাক্স v3 AI runtime architecture"
description: "Ternux-এর ঐচ্ছিক CPU, GPU ও NPU workload এবং artifact/model ownership।"
lang: "bn"
alt_url: "/docs/v3/AI-RUNTIME-ARCHITECTURE.html"
---

## AI runtime architecture

**অবস্থা: নকশা সম্পন্ন।** AI ঐচ্ছিক Ternux workload ক্ষেত্র। Base install model download করে না বা inference service resident রাখে না। Ternux নিজের runtime integration ও workload lifecycle-এর মালিক। সম্পর্কহীন product-এর API, private app data ও model store Ternux-এর scope-এর বাইরে।

## Workload manifest

প্রতিটি workload-এ task (`text`, `image` বা স্পষ্টভাবে সমর্থিত অন্য task), model architecture/format, quantization, runtime/API version, supported CPU/GPU/NPU device, minimum RAM/storage, permission, source URL, license, cryptographic digest, correctness fixture, cancellation আচরণ ও uninstall ownership থাকবে। Model file extension একা accelerator compatibility প্রমাণ নয়।

## Model খোঁজা ও ownership

অনুমোদিত generic model location যেমন `/sdcard/Llms` read-only ভাবে খোঁজা যেতে পারে; path, size, format ও সম্ভাব্য runtime compatibility দেখাবে। অন্য product-এর private store-এর মালিকানা অনুমান করবে না। Ternux workload-এ copy/import আলাদা user action; এর আগে free-space ও hash check হবে।

## Job lifecycle

`QUEUED → VALIDATING → LOADING → RUNNING → SUCCEEDED|FAILED|CANCELLED`। প্রতিটি job-এ model পরিচয়/hash, backend, runtime, privacy অনুমতি দিলে prompt/input hash, সময়, memory peak, output path ও exit condition থাকবে। Prompt ও generated media ডিফল্টে local থাকবে। Cancel করলে job process বন্ধ হবে এবং শুধু তার temporary file পরিষ্কার হবে।

## Correctness ও performance

Text output শুধু সাধারণ arithmetic দিয়ে নয়, task-specific evaluation-এ যাচাই হবে। Image output decode, dimension, color health ও স্থির workload metric দিয়ে পরীক্ষা হবে। Warm-up ও প্রথম-run compilation আলাদা report হবে। CPU, Vulkan ও NPU ফল একই prompt/input, model digest, output correctness check ও repeat policy ব্যবহার করবে। Latency, tokens/s বা images/s, peak memory, temperature context এবং failure একসঙ্গে প্রকাশ হবে। HTP/QNN/অন্য experimental path নির্দিষ্ট hardware ও release gate পাস না করা পর্যন্ত experimental থাকবে।
