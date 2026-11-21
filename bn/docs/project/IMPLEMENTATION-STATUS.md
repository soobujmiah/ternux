---
title: "Ternux বাস্তবায়নের অবস্থা"
description: "বর্তমান source, evidence-এর সীমা ও support-এর সীমাবদ্ধতা।"
lang: "bn"
alt_url: "/docs/project/IMPLEMENTATION-STATUS.html"
---

## বর্তমান অবস্থা

Source-এ কোনো অংশ থাকা মানেই সেটি release হয়েছে, package channel কাজ করছে, বা
device-এ যাচাই হয়েছে—এমন নয়। প্রতিটি দাবির সীমা সংশ্লিষ্ট evidence-এ দেখুন।

| ক্ষেত্র | অবস্থা | Evidence-এর সীমা |
| --- | --- | --- |
| Release | v1.4.0 artifact অপরিবর্তিত; পরবর্তী source tag provenance-এর জন্য রাখা, তবে তার GitHub Release entry সরানো হয়েছে | [Release status](RELEASE-STATUS.html) ও [historical release archive](../release/README.html) |
| Installation | Pinned source installer বর্তমান নির্দেশিত পথ | [Installation guide](../INSTALLATION.html) |
| APT/package channel | অনুপলভ্য; `pkg install ternux` কাজ করে না | [Channel status](../TERMUX-APT.html) |
| Desktop setup | Debian, Ubuntu, Kali Linux ও Alpine recipe রাখা আছে; evidence-এর গভীরতা আলাদা | [Feature matrix](../../../docs/audit/FEATURE-MATRIX.md) ও [device verification](../../../docs/audit/DEVICE-VERIFICATION.md) |
| Manager ও Control Center | Source-এ আংশিক বাস্তবায়ন; পূর্ণ platform বা release claim নয় | [পরবর্তী সংস্করণের পরিকল্পনা](../next/README.html) |
| Recovery | APT timeout/dpkg recovery path ও regression coverage রাখা আছে | Focused recovery test |

Device-নির্ভর তথ্য ও সীমাবদ্ধতা [known limitations](KNOWN-LIMITATIONS.html)-এ।
ঐতিহাসিক release evidence [release archive](../release/README.html)-এ।
