---
title: "Ternux প্রকল্পের roadmap"
description: "বর্তমান প্রকল্পের অবস্থা ও প্রস্তাবনাভিত্তিক পরবর্তী সংস্করণ পরিকল্পনা।"
lang: "bn"
alt_url: "/docs/project/PROJECT-ROADMAP.html"
---

## বর্তমান দিকনির্দেশ

বর্তমান source ও user-facing support claim যেন প্রমাণভিত্তিক থাকে। ভবিষ্যৎ major
version-এর নম্বর বা বাস্তবায়িত নয় এমন নকশাকে release হিসেবে দেখাবেন না। ভবিষ্যৎ
স্থাপত্য ও feature proposal **Next Version / পরবর্তী সংস্করণ** অংশে থাকবে।

### বর্তমান তথ্য

- v1.4.0 release artifact ও documentation অপরিবর্তিত থাকবে।
- পরবর্তী source tag Git-এ provenance-এর জন্য রাখা আছে; তার GitHub Release entry
  সরিয়ে ফেলা হয়েছে।
- Termux APT/package channel অনুপলভ্য; `pkg install ternux` এখন কাজ করে না।
  [Installation guide](../INSTALLATION.html)-এ থাকা pinned source route ব্যবহার করুন।
- Debian, Ubuntu, Kali Linux ও Alpine হলো নাম-উল্লেখিত desktop setup target।
  recipe থাকা এবং physical device-এ qualification আলাদা করে জানান।
- APT timeout/dpkg recovery আচরণ ও test সংরক্ষণ করুন।

### পরবর্তী সংস্করণের পরিকল্পনা

দ্বিভাষিক [পরবর্তী সংস্করণের সূচি](../next/README.html)-তে proposal, architecture
note ও acceptance gate আছে। এগুলো কোনো release, package channel বা device
support-এর প্রতিশ্রুতি নয়। আরও দেখুন
[implementation status](IMPLEMENTATION-STATUS.html),
[known limitations](KNOWN-LIMITATIONS.html), এবং
[release status](RELEASE-STATUS.html)।

তারিখসহ ঐতিহাসিক evidence ও source-tag provenance
[release archive](../release/README.html)-এ রাখা হয়েছে।
