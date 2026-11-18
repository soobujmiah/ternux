---
title: "Ternux release status"
description: "Withdrawn v2.0.0 history and unpublished local v2.0.1 candidate."
lang: "bn"
alt_url: "/docs/project/RELEASE-STATUS.html"
---

## বর্তমান অবস্থা — 2026-11-18

- **সর্বশেষ প্রকাশিত version:** v1.4.0। Tag `3e6c07e2afcb5f1e65ecd57af19b0382a948835a`;
  release-এ binary asset নেই। ঐতিহাসিক source archive-এর install guide স্থানীয়ভাবে
  তৈরি ও যাচাই হয়েছে; public release page সম্পাদিত হয়নি।
- **v2.0.0:** source tag `9106b04fc8627ae98b1d63c9912a28c8a4677441` provenance-এর জন্য
  রাখা আছে। GitHub Release object 2026-11-14-এ সরানো হয়েছে, stable APT-ও প্রত্যাহৃত;
  tag সরানো/পুনর্ব্যবহার করা যাবে না.
- **v2.0.1:** unused local candidate. Tag, final release commit, artifact, checksum
  বা public release page নেই; working tree local review-এ.
- **Stable APT:** withdrawn; v2.0.1 install method নয়। APT feasibility আলাদা v3 কাজ।
- **Owner-confirmed v2 desktop baseline:** Debian, Ubuntu, Kali Linux ও Alpine।
  Kali-র clean-container install/browser CI এই matrix-এ নেই; evidence সীমা
  [feature matrix](../../../docs/audit/FEATURE-MATRIX.md)-এ আছে।

## Historical v2.0.0

Ternux v2.0.0 2026-11-13-এ প্রকাশিত হয়েছিল এবং 2026-11-14-এ প্রত্যাহার করা হয়।
Tag এবং release-time artifact তথ্য
[release report](../../../docs/release/V2-RELEASE-REPORT.md)-এ অপরিবর্তিতভাবে আছে। ওই
প্রকাশনার Debian, Ubuntu, Alpine scope বর্তমান পরবর্তী v2 release-এর owner-confirmed
চার distro baseline-এর সঙ্গে গুলিয়ে ফেলবেন না।

## Version 2 release policy

v2 বর্তমান implementation-এ frozen থাকবে। নতুন distro, architecture, APT বা অন্য
capability যোগ নয়। v2.0.1 প্রকাশের আগে approved exact commit, green exact-commit
checks, artifact integrity, version-specific installation guide এবং সৎ limitation
record লাগবে। Public GitHub Release Page যাচাই না হওয়া পর্যন্ত release complete নয়।

## Version 3 আলাদা রাখা

Future v3 architecture ও distro roadmap `docs/v3/README.md`-এ। v2.0.1 প্রকাশ ও
install guide যাচাই হওয়ার পরেই v3 implementation শুরু হবে। বর্তমান source-এ partial
Manager বা Control Center code থাকলেও সম্পূর্ণ v3 platform তৈরি হয়েছে—এমন নয়।
