---
title: "ADR-0001: Native Termux manager ও Control Center"
description: "Linux guest থেকে স্বাধীন host-native manager বেছে নেওয়া।"
lang: "bn"
alt_url: "/docs/next/architecture/ADR/0001-native-manager.html"
---

## ADR-0001: Native Termux manager ও Control Center

- **অবস্থা:** পরবর্তী সংস্করণ নকশার জন্য গৃহীত; native CLI, manager ও Control Center-এর আংশিক foundation আছে; পূর্ণ manager/Device Bridge architecture এখনও অসম্পূর্ণ।
- **তারিখ:** 2026-11-13।
- **সিদ্ধান্তের মালিক:** Ternux project owner।

## প্রেক্ষাপট

একটি guest-এর ভেতর থেকে guest পরিচালনা করলে guest-স্বাধীন status, install, repair ও বহু-distro lifecycle নির্ভরযোগ্য থাকে না। Guest-owned web server Android permission বা host package update নিরাপদে broker করতে পারে না।

## সিদ্ধান্ত

Manager core, `tx` CLI, Control Center service, Device Bridge ও workload registry native Termux-এ চলবে। Linux guest আলাদা workspace থাকবে। Service ঐচ্ছিক; CLI তা inspect ও recover করতে পারবে।

## বিকল্প

- Debian-এর ভেতরের manager: প্রত্যাখ্যাত—এক guest-এর সঙ্গে control জুড়ে যায়; guest না থাকলে/নষ্ট হলে ব্যর্থ।
- Guest-local web dashboard: প্রত্যাখ্যাত—guest privilege বাড়ায় এবং বহু distro-তে পরস্পরবিরোধী manager তৈরি করে।
- বাধ্যতামূলক always-on daemon: প্রত্যাখ্যাত—idle resource খরচ ও base CLI-কে service health-এর উপর নির্ভরশীল করে।

## ফলাফল

Host-side API-তে সতর্ক local authorization ও compatibility handling দরকার। বিনিময়ে guest একইভাবে manage করা যায় এবং service বন্ধ হলেও guest session চলে।
