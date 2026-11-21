---
title: "Ternux-এর পরবর্তী কাজ"
description: "রক্ষণাবেক্ষণ, evidence এবং proposal review-এর অগ্রাধিকার।"
lang: "bn"
alt_url: "/docs/project/NEXT-ACTIONS.html"
---

## অগ্রাধিকার

1. Release, installation ও package channel-এর বক্তব্য উপলভ্য evidence-এর সঙ্গে
   মিলিয়ে রাখুন। বর্তমান APT/package channel অনুপলভ্য; `pkg install ternux`
   প্রচার করবেন না।
2. APT timeout/dpkg recovery আচরণ অক্ষত রাখুন এবং regression test চালিয়ে যান।
3. Debian, Ubuntu, Kali Linux ও Alpine setup recipe নথিভুক্ত রাখুন; physical
   device qualification থেকে recipe-কে স্পষ্টভাবে আলাদা করুন।
4. পরবর্তী সংস্করণের proposal ছোট, পরীক্ষাযোগ্য ধাপে পর্যালোচনা করুন; proposal-কে
   বাস্তবায়িত feature বা release commitment বলবেন না।
5. English ও বাংলা user guidance মিলিয়ে রাখুন; documentation edit-এর পর link ও
   build পরীক্ষা করুন।

বর্তমান অবস্থা: [release status](RELEASE-STATUS.html),
[implementation status](IMPLEMENTATION-STATUS.html), এবং
[known limitations](KNOWN-LIMITATIONS.html)। তারিখসহ release evidence
[release archive](../release/README.html)-এ অক্ষত রাখুন।
