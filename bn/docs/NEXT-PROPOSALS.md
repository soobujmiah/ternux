---
title: "পরবর্তী সংস্করণের প্রস্তাব"
description: "ভবিষ্যতে বিবেচ্য ধারণা; release commitment নয়।"
lang: "bn"
alt_url: "/docs/NEXT-PROPOSALS.html"
---

এই পাতায় ভবিষ্যৎ review-এর জন্য কিছু ধারণা আছে। এগুলো প্রস্তাব—বর্তমান support
claim বা release gate নয়। [পরবর্তী সংস্করণের স্থাপত্য](NEXT-ARCHITECTURE.html)
ও [বাস্তবায়ন পরিকল্পনা](next/IMPLEMENTATION-ROADMAP.html)-তে পর্যালোচনার
সম্ভাব্য পদ্ধতি আছে।

## সম্ভাব্য প্রস্তাব

### ১. বিশ্বাসযোগ্য package বিতরণ

Key rotation, পুনরুৎপাদনযোগ্য metadata, নিরাপদ upgrade/rollback ও repository
health page-সহ signed Termux package channel বিবেচনা করা। বর্তমানে package
repository অপ্রাপ্য। Prototype-এর জন্য আলাদা feasibility review ও owner approval
দরকার।

### ২. আরও distro-র যোগ্যতা যাচাই

Debian, Ubuntu, Kali Linux ও Alpine-এর রক্ষণাবেক্ষণ করা desktop setup নির্ভরযোগ্য
রাখুন। নতুন profile বিবেচনায় clean-install evidence আবশ্যক। Desktop startup,
graphics, audio, keyboard input, storage isolation, browser ও removal পরীক্ষা
করুন। Recipe-কে device-verified support ভেবে ভুল এড়াতে distro ও device অনুযায়ী
ফল প্রকাশ করুন।

### ৩. ঐচ্ছিক accelerator ও model pack

Text ও image workload-এর জন্য পৃথক CPU, Vulkan/GPU এবং device-specific NPU pack
বিবেচনা করা। প্রতিটি pack-এ hardware/runtime requirement, artifact provenance ও
hash যাচাই, মাপা memory/performance এবং base desktop না বদলে uninstall-এর পথ
থাকবে। Correctness ও recovery test না হওয়া পর্যন্ত experimental route আলাদা
রাখুন।

### ৪. Android camera ও microphone সংযোগ

Termux API দিয়ে permission-aware camera streaming এবং প্রয়োজনে microphone access
নিয়ে গবেষণা করুন। Capture শুরু হলেই permission চাওয়া, device state দেখানো এবং
যাচাইকৃত media নির্বাচিত guest-এ রাখা উচিত। Android/Termux capability এবং
device-specific privacy/lifecycle পরীক্ষা করুন।

### ৫. কম-সম্পদ desktop profile

ঐচ্ছিক service, সীমাবদ্ধ background startup এবং ছোট default app set-সহ profile
বিবেচনা করুন। নির্দিষ্ট যন্ত্রে idle ও interactive RAM/CPU মাপ প্রকাশ করুন এবং
পূর্ণ desktop option অক্ষত রাখুন।

কোনো প্রস্তাবের নির্দিষ্ট সময়সীমা নেই। [প্রকল্পের পরিকল্পনা](project/PROJECT-ROADMAP.html)
বর্তমান কাজ দেখায়; [accelerator পরিকল্পনা](ACCELERATOR-RELEASE-PLAN.html)-তে
বিদ্যমান প্রমাণ ও সীমা আছে।
