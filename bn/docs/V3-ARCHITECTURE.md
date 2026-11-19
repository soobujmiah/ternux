---
title: "টার্নাক্সের তৃতীয় সংস্করণের নকশা"
description: "টার্নাক্সের তৃতীয় সংস্করণ হিসেবে পরিকল্পিত ব্যবস্থাপনা, স্বতন্ত্র লিনাক্স কর্মপরিসর, গণনা-সরঞ্জাম ও অ্যান্ড্রয়েড যন্ত্র-সংযোগের নকশা ও বাস্তবায়নের অবস্থা।"
lang: "bn"
alt_url: "/docs/V3-ARCHITECTURE.html"
---

## ব্যবস্থার নকশার পরিচয়

এই নকশাটি Ternux v3-এর জন্য। 2026-11-14-এ আগের v3 platform scope-কে v2-তে
তোলার সিদ্ধান্ত 2026-11-18-এ owner প্রত্যাহার করেছেন। v2.0.1 প্রকাশনার gate
সম্পূর্ণ এবং v2 frozen। v3 foundation কাজ সক্রিয়; এই পাতার architecture ও
capability এখনও design বা partial implementation, v2 feature claim নয়। এতে Termux-এ
চলা নিজস্ব ব্যবস্থাপক, স্বতন্ত্র Linux
কর্মপরিসর, ঐচ্ছিক গণনা ও কৃত্রিম-বুদ্ধিমত্তার কাজ, অনুমতিনির্ভর অ্যান্ড্রয়েড
যন্ত্র-সংযোগ এবং স্থানীয় নিয়ন্ত্রণকেন্দ্রের নকশা রয়েছে। **নকশা করা মানেই
বাস্তবায়ন করা বা যন্ত্রে যাচাই করা নয়।**

## পণ্যের সীমানা

- ব্যবস্থাপক, কমান্ড-লাইন, নিয়ন্ত্রণকেন্দ্র, যন্ত্র-সংযোগ ও কাজের তালিকা টার্মাক্সে
  চলবে; কোনো প্রুট গেস্টের ভেতরে নয়।
- মালিক-নিশ্চিত v2 baseline হলো Debian, Ubuntu, Kali Linux ও Alpine; v3-তে নতুন
  profile যোগ হলে আলাদা qualification লাগবে।
- Ternux-এর বিদ্যমান AI tool ও workload Ternux-এরই থাকবে। LAI ও সব unrelated
  product/repository Ternux scope-এর বাইরে; নতুন explicit owner decision ছাড়া
  কোনো integration বা dependency থাকবে না।
- ক্যামেরা, মাইক্রোফোন, স্টোরেজ, গ্রাফিক্স ও এনপিইউর কাজ ঐচ্ছিক, অনুমতিনির্ভর
  এবং আলাদাভাবে যোগ্যতা যাচাই করা হবে।
- ব্যবহারকারীর ফাইল, গেস্টের ফাইল, কাজের সরঞ্জামের ফাইল ও মডেলের মালিকানা
  স্পষ্ট থাকবে। আনইনস্টল করলে কোনো তথ্য নীরবে মুছে ফেলা হবে না।

## v3-এর বর্তমান ভিত্তিকাজ

v2 প্রকাশনার gate সম্পূর্ণ। বর্তমান foundation নথিতে
[বাস্তবায়নের ধাপ](../../docs/v3/IMPLEMENTATION-ROADMAP.html),
[APT বিতরণের সুপারিশ](../../docs/v3/APT-DISTRIBUTION-FEASIBILITY.html),
[distro qualification matrix](../../docs/v3/DISTRIBUTION-ROADMAP.html),
[security কাজের অগ্রাধিকার](../../docs/v3/SECURITY-ROADMAP.html) এবং
[পরীক্ষার কৌশল](../../docs/v3/TESTING-STRATEGY.html) আছে। সুপারিশ হলো v3.0-এর
critical path-এ APT না রাখা এবং যাচাইকৃত source installer চালিয়ে যাওয়া।
প্রস্তাবিত distro ও architecture capability-গুলো নির্দিষ্ট gate পাস না করা পর্যন্ত
যাচাইকৃত নয়।

## প্রযুক্তিগত বিবরণ

- [সম্পূর্ণ নকশার সূচি](/docs/v3/README.html)
- [বাস্তবায়নের পরিকল্পনা](/docs/project/PROJECT-ROADMAP.html)
- [বর্তমান বাস্তবায়নের অবস্থা](/docs/project/IMPLEMENTATION-STATUS.html)
- [প্রকাশনার অবস্থা](/docs/project/RELEASE-STATUS.html)
- [যন্ত্রে যাচাই](/docs/project/DEVICE-VERIFICATION.html)
- [নকশাগত সিদ্ধান্ত](/docs/project/ARCHITECTURE-DECISIONS.html)
- [বকেয়া কাজ ও পরিচিত সীমা](/docs/project/TECHNICAL-DEBT.html)
- [পরবর্তী কাজ](/docs/project/NEXT-ACTIONS.html)

## নকশাগত সিদ্ধান্ত

নকশার নথিতে নিজস্ব ব্যবস্থাপক, গেস্ট ও তথ্যের স্পষ্ট মালিকানা এবং একটি
বহিরাগত product integration proposal প্রত্যাখ্যানের রেকর্ড রয়েছে। কারণ ও ফল জানতে
[নকশাগত সিদ্ধান্তের সূচি](/docs/v3/ADR/README.html) দেখুন। প্রত্যাহৃত টার্নাক্স
২.০.০-এর প্রমাণ [দ্বিতীয় সংস্করণের প্রকাশনা প্রতিবেদনে](V2-RELEASE-REPORT.html)
রয়েছে।
