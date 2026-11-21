---
title: "Ternux release ও package-এর অবস্থা"
description: "বর্তমান release record এবং অনুপলভ্য package channel-এর তথ্য।"
lang: "bn"
alt_url: "/docs/project/RELEASE-STATUS.html"
---

## বর্তমান অবস্থা

- **সর্বশেষ GitHub Release:** v1.4.0। এর release artifact ও documentation
  অপরিবর্তিত রাখুন।
- **পরবর্তী source provenance:** পরবর্তী একটি source tag Git-এ provenance-এর
  জন্য রাখা আছে। তার GitHub Release entry সরানো হয়েছে; এটিকে উপলভ্য GitHub
  Release হিসেবে দেখাবেন না।
- **APT/package channel:** অনুপলভ্য। `pkg install ternux` কার্যকর install পথ নয়।
  [Package channel-এর অবস্থা](../TERMUX-APT.html) দেখুন।
- **রক্ষিত desktop setup:** Debian, Ubuntu, Kali Linux ও Alpine। setup recipe
  এবং device-verification evidence এক বিষয় নয়; [feature matrix](../../../docs/audit/FEATURE-MATRIX.md)
  ও [device verification record](../../../docs/audit/DEVICE-VERIFICATION.md) দেখুন।
- **বর্তমান install নির্দেশনা:** [installation guide](../INSTALLATION.html)-এর
  pinned source route ব্যবহার করুন।

ঐতিহাসিক release report-এ তারিখসহ evidence ও provenance রাখা হয়েছে। সেগুলো
বর্তমান install বা package availability-এর নির্দেশনা নয়:
[release archive](../release/README.html)।
