---
title: "ADR-0003: প্রত্যাখ্যাত external-product adapter প্রস্তাব"
description: "Owner-এর প্রত্যাখ্যাত ঐতিহাসিক প্রস্তাব; unrelated product Ternux scope-এর বাইরে।"
lang: "bn"
alt_url: "/docs/v3/ADR/0003-lai-adapter.html"
---

## ADR-0003: প্রত্যাখ্যাত external-product adapter প্রস্তাব

- **অবস্থা:** Owner-এর 2026-11-19 scope directive-এ প্রত্যাখ্যাত ও superseded; implementation নেই।
- **তারিখ:** 2026-11-13।
- **সিদ্ধান্তের মালিক:** Ternux project owner।

## প্রেক্ষাপট

আগের একটি প্রস্তাবে সম্পর্কহীন AI product integration বিবেচনা করা হয়েছিল। Owner পরে নির্দেশ দেন LAI ও সব unrelated repository/product Ternux scope-এর বাইরে থাকবে।

## সিদ্ধান্ত

Ternux LAI integration করবে না এবং তার API, service, private app data বা model store-এর উপর নির্ভর করবে না। Ternux নিজের repository-তে নিজস্ব AI tool, workload, inference utility ও integration রক্ষণাবেক্ষণ করতে পারে। Future scope change-এ explicit owner decision লাগবে।

## ফলাফল

এই ঐতিহাসিক প্রস্তাব কোনো implementation requirement বা dependency তৈরি করে না। পুরনো ADR link স্থির রাখতে ID রাখা হয়েছে।
