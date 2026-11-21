---
title: "Ternux-এর পরিচিত সীমাবদ্ধতা"
description: "বর্তমান support, package এবং device-verification-এর সীমা।"
lang: "bn"
alt_url: "/docs/project/KNOWN-LIMITATIONS.html"
---

## পরিচিত সীমাবদ্ধতা

- Termux APT/package channel অনুপলভ্য। `pkg install ternux` সমর্থিত বা কার্যকর
  install পদ্ধতি নয়; pinned source installer ব্যবহার করুন।
- Debian, Ubuntu, Kali Linux ও Alpine-এর setup recipe থাকা মানেই সমানভাবে
  physical device-এ যাচাই হয়েছে নয়। [Device evidence](../../../docs/audit/DEVICE-VERIFICATION.md)
  দেখুন।
- Android version, SoC, GPU বা vendor build ভেদে আচরণ বদলাতে পারে। যে device ও
  পরীক্ষা সত্যিই যাচাই হয়েছে শুধু সেটিই উল্লেখ করুন।
- Manager ও Control Center-এর কাজ আংশিক। Browser/device validation, supervision
  এবং অসম্পূর্ণ capability-কে পূর্ণ platform হিসেবে বর্ণনা করবেন না।
- ঐতিহাসিক release record সেই সময়ের artifact ও scope জানায়; বর্তমান package
  উপলভ্যতার প্রমাণ নয়। [Release archive](../release/README.html) দেখুন।

বর্তমান তথ্যের জন্য [implementation status](IMPLEMENTATION-STATUS.html) ও
[package-channel status](../TERMUX-APT.html) দেখুন।
