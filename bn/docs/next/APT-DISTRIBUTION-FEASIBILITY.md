---
title: "Package বিতরণের সম্ভাব্যতা"
description: "সম্ভাব্য Termux package channel-এর শর্ত ও খোলা প্রশ্ন।"
lang: "bn"
alt_url: "/docs/next/APT-DISTRIBUTION-FEASIBILITY.html"
---

এটি মূল্যায়নের checklist, install source নয়। Termux package repository বর্তমানে
অপ্রাপ্য। GitHub source tag বা পুরোনো release evidence কোনো package channel-কে
ব্যবহারযোগ্য করে না।

Channel বিবেচনার আগে যাচাই করুন:

- repository hosting, endpoint health ও signed metadata;
- primary-key custody, rotation, revocation ও স্বাধীন fingerprint যাচাই;
- সমর্থিত Termux যন্ত্রে clean install, upgrade, interrupted upgrade, repair,
  removal ও rollback;
- artifact reproducibility, package identity, dependency closure ও checksum;
- withdrawal প্রক্রিয়া, যাতে পুরোনো client সরানো metadata-কে বর্তমান না ভাবে।

Owner-approved release process এবং সফল device evidence ছাড়া বর্তমান status
পরিবর্তন করা যাবে না। [Package-channel status](../TERMUX-APT.html) ও
[পরবর্তী সংস্করণের পরিকল্পনা](IMPLEMENTATION-ROADMAP.html) দেখুন।
