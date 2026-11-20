---
title: "ADR-0002: Guest ও data ownership স্পষ্ট করা"
description: "Guest lifecycle-কে user model, Android file ও অন্য Termux data থেকে পৃথক করা।"
lang: "bn"
alt_url: "/docs/v3/ADR/0002-guest-data-ownership.html"
---

## ADR-0002: Guest ও data ownership স্পষ্ট করা

- **অবস্থা:** v3 design-এ গৃহীত; owner-scoped cleanup-এর foundation আছে, তবে পূর্ণ owner-ID registry ও legacy reconciliation path এখনও বাকি।
- **তারিখ:** 2026-11-13।
- **সিদ্ধান্তের মালিক:** Ternux project owner।

## প্রেক্ষাপট

Manager তৈরি করেনি, অথবা আলাদা নির্বাচিত workload/Android user directory-র মালিকানা—এমন data uninstall/repair-এ মুছে ফেলা যাবে না।

## সিদ্ধান্ত

প্রতিটি managed file, guest, runtime pack, model copy ও storage grant-এর owner ID ও lifecycle record থাকবে। Default guest uninstall শুধু নির্বাচিত rootfs ও স্পষ্ট Ternux-owned guest state সরাবে। Model/shared media সরাতে user-এর আলাদা selection লাগবে। Termux-এর Android shared-storage permission আগে থেকে থাকলে guest-এ `/sdcard` default mount হবে; এটি external user data, guest-owned নয় এবং uninstall-এ মুছবে না। Extra directory grant স্পষ্ট ও প্রত্যাহারযোগ্য থাকবে।

## ফলাফল

Registry ও uninstall UI ownership/disk use তালিকাভুক্ত করবে। পুরনো untracked file-এর report/reconciliation path দরকার; নীরবে disposable বলা যাবে না।
