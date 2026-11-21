---
title: "পরবর্তী সংস্করণের বাস্তবায়ন পরিকল্পনা"
description: "প্রস্তাবিত ভবিষ্যৎ কাজের প্রমাণনির্ভর ধাপ।"
lang: "bn"
alt_url: "/docs/next/IMPLEMENTATION-ROADMAP.html"
---

এটি পরিকল্পনার সহায়ক নথি—সময়সূচি বা release প্রতিশ্রুতি নয়। বর্তমান সমর্থন,
ঐতিহাসিক release evidence এবং ভবিষ্যৎ প্রস্তাব আলাদা রাখতে হবে। Repository
অপ্রাপ্য থাকা অবস্থায় package channel ব্যবহারযোগ্য বলা যাবে না।

## ধাপ ও সম্পন্ন হওয়ার প্রমাণ

১. **ভিত্তির অবস্থা নথিবদ্ধ করুন।** English ও বাংলা status এক রাখুন; তারিখযুক্ত
source/device evidence অক্ষত রাখুন এবং অনিশ্চয়তা স্পষ্ট করুন।

২. **নির্ভরযোগ্যতার কাজ শেষ করুন।** Update-lock ও recovery-journal regression
পরীক্ষা সম্পন্ন করুন; APT timeout এবং dpkg recovery tests অক্ষত রাখুন। পরিবর্তনে
recovery আচরণ ভাঙা চলবে না।

৩. **বিতরণের পথ যাচাই করুন।** Signing, key rotation, repository availability,
install/upgrade/remove ও rollback-এর শর্ত নির্ধারণ করুন। Clean-device install ও
upgrade যাচাই না হওয়া পর্যন্ত কোনো channel-কে ব্যবহারযোগ্য বলা যাবে না।

৪. **Desktop profile যাচাই করুন।** Debian, Ubuntu, Kali Linux ও Alpine-এর
যন্ত্রভিত্তিক পরীক্ষা চালিয়ে যান। Recipe-কে পরীক্ষিত support থেকে আলাদা দেখান;
যন্ত্র ও workload অনুযায়ী সীমা প্রকাশ করুন।

৫. **ঐচ্ছিক extension prototype করুন।** CPU, Vulkan/GPU ও যন্ত্র-নির্দিষ্ট NPU
কাজ opt-in রাখুন। Artifact provenance, hash, license, resource use, correctness,
cleanup ও recovery evidence নথিবদ্ধ করুন।

৬. **গোপনীয়তা-সংবেদনশীল সংযোগ পর্যালোচনা করুন।** Camera ও microphone access
permission-নির্ভর এবং প্রয়োজনমতো চালু হওয়া উচিত। সাধারণভাবে উপলভ্য বলার আগে
লক্ষ্যযন্ত্রে lifecycle ও data handling যাচাই করুন।

প্রতিটি ধাপে নির্দিষ্ট owner, পর্যালোচনাযোগ্য পরিবর্তন, দ্বিভাষিক নথি, পুনরুৎপাদনযোগ্য
পরীক্ষা এবং স্পষ্ট go/no-go প্রমাণ লাগবে। এই পরিকল্পনায় release date বা
প্রতিশ্রুতি নেই।
