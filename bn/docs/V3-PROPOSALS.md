---
title: "Ternux v3-এর প্রস্তাবনা"
description: "মালিকের অনুরোধ থেকে তৈরি v2-পরবর্তী Ternux প্রস্তাবনা; এগুলো release commitment নয়।"
lang: "bn"
alt_url: "/docs/V3-PROPOSALS.html"
---

এই পাতাটি v2-পরবর্তী প্রাথমিক proposal-এর ইতিহাস ধরে রেখেছে। Owner-এর নির্দেশে
আগে v3-এর জন্য পরিকল্পিত required platform scope এখন পরের v2-major release-এ
অন্তর্ভুক্ত। বিস্তারিত [project roadmap](/bn/docs/project/PROJECT-ROADMAP.html),
[architecture overview](V3-ARCHITECTURE.html) ও
[implementation roadmap](../../docs/v3/IMPLEMENTATION-ROADMAP.html)-এ আছে।
নিচের proposal-গুলো ঐতিহাসিক প্রেক্ষাপট; canonical release scope নয়।

## প্রস্তাবিত কাজ

### ১. Trusted, zero-setup package distribution

বিশ্বস্ত package index বা অন্য signed distribution channel-এ সাধারণ Termux
পদ্ধতি (`pkg install ternux`) চালু করা; সঙ্গে key rotation, reproducible
metadata, upgrade/rollback এবং repository health page রাখা। v2-এর public APT
endpoint ও clean package lifecycle এখনো v2 release gate—এই প্রস্তাব সেগুলো
পাস করার পরের দীর্ঘমেয়াদি distribution resilience নিয়ে।

### ২. আরও distro-র qualification

বর্তমান distro profile-গুলো সহজে install করার পাশাপাশি clean guest-এ desktop
startup, graphics route, audio, keyboard input, storage isolation, browser এবং
removal-এর automated qualification যোগ করা। প্রতিটি distro ও architecture-এর
ফল আলাদা প্রকাশ করতে হবে, যেন recipe-কে device-tested release বলা না হয়।

### ৩. Optional accelerator ও model pack

Text এবং image workload-এর জন্য আলাদা CPU, Vulkan/GPU ও device-specific NPU
pack দেওয়া। প্রতিটি pack-এ supported hardware/runtime version, model source ও
hash যাচাই, মাপা memory ও speed range এবং base desktop না বদলে clean removal
থাকবে। Correctness ও recovery gate পাস না করা পর্যন্ত experimental path-গুলো
আলাদা করে চিহ্নিত থাকবে।

### ৪. Android camera ও microphone integration

Live preview ও webcam ব্যবহারের জন্য permission-aware camera streaming bridge
এবং Termux API দিয়ে প্রয়োজনমতো microphone access অনুসন্ধান করা। Capture বা
recording চালু করলে তবেই permission চাইবে, permission/device status দেখাবে এবং
যাচাইকৃত media নির্বাচিত guest-এ save করবে। এটি Android API ও Termux companion-এর
সক্ষমতার ওপর নির্ভরশীল; device-ভিত্তিক privacy ও lifecycle test দরকার।

### ৫. Low-resource desktop profile

Optional desktop service, সীমিত background startup এবং ছোট default application
set-সহ RAM-সাশ্রয়ী profile নির্ধারণ করা। নির্দিষ্ট device-এ idle ও interactive
RAM/CPU ব্যবহার মাপতে হবে, পাশাপাশি বর্তমান পূর্ণাঙ্গ XFCE option-ও রাখতে হবে।

## প্রস্তাবনার অবস্থা

নিচের পাঁচটি বিষয় ঐতিহাসিক proposal, পরের v2-major release-এর canonical scope নয়।
Required platform কাজ [project roadmap](/bn/docs/project/PROJECT-ROADMAP.html) ও
[acceptance criteria](../../docs/v3/ACCEPTANCE-CRITERIA.md)-তে tracked. Current
implementation ও সীমাবদ্ধতা [v2 release-readiness report](V2-RELEASE-READINESS.md),
[installation guide](INSTALLATION.md) এবং
[accelerator release plan](ACCELERATOR-RELEASE-PLAN.md)-এ আছে।
