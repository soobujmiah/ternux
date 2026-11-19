---
title: "টার্নাক্স v3 UX ও design system"
description: "টার্নাক্স v3 terminal, dashboard, desktop ও accessibility-এর সামঞ্জস্যপূর্ণ নিয়ম।"
lang: "bn"
alt_url: "/docs/v3/UX-AND-DESIGN-SYSTEM.html"
---

## UX ও design system

**অবস্থা: নকশা সম্পন্ন।** Ternux একটি পরিচিত brand-সহ workstation, আলাদা আলাদা dialog-এর সমষ্টি নয়। Native Termux CLI, Control Center, XFCE default, icon ও documentation একই visual/language system ব্যবহার করবে এবং নিজ নিজ platform-এর রীতি মানবে।

## তথ্যের স্তর

প্রতিটি status view-তে **state**, **action** ও **evidence** আলাদা থাকবে। কোন guest/workload নির্বাচিত, কী বদলাবে, বর্তমান progress এবং log কোথায়—ব্যবহারকারী দেখতে পাবেন। Destructive action confirmation-এর আগে target ও data category জানাবে। Success-এর সঙ্গে পরবর্তী উপযোগী action থাকবে।

## CLI আচরণ

- Install, distro selection, uninstall, repair ও stop flow-তে একই keyboard নিয়ম: arrow দিয়ে চলা, Space দিয়ে multi-select, Enter-এ confirm, Escape-এ cancel; বিকল্প হিসেবে নম্বরও চলবে।
- Prompt-এ স্পষ্ট default, validation, timeout ও TTY সুবিধা না থাকলে plain-text fallback থাকবে।
- `--json`, deterministic exit code ও scriptability থাকবে; stdin/stdout TTY না হলে interactive prompt দেখাবে না।
- Foreground progress সংক্ষিপ্ত; `tx logs`-এ সীমাবদ্ধ log দেখা যাবে; background service terminal spam করবে না।

## Visual system

বিদ্যমান Ternux forest/teal palette, উচ্চ contrast, সংযত glow, সামঞ্জস্যপূর্ণ typography এবং text label-সহ আলাদা status color ব্যবহার হবে। ছোট আকারেও icon-এর অর্থ ও app identity চিনতে হবে। Folder type আলাদা হতে পারে, কিন্তু সম্পর্কহীন app একই generic emblem পাবে না। GTK, XFWM, panel, launcher, app icon ও wallpaper একটি versioned theme pack হবে।

## Accessibility ও localization

Keyboard-only operation, native UI-তে TalkBack-compatible label, scalable text, reduced motion, দৃশ্যমান focus এবং শুধু color-এর উপর নির্ভর করে না এমন status আবশ্যক। English ও Bangla documentation একসঙ্গে রক্ষণাবেক্ষণ হবে; CLI label-এ বিভ্রান্তিকর transliteration এড়ানো হবে। Terminal symbol-এর ASCII fallback থাকবে।

## Resource budget

Idle UI-তে CPU activity সীমিত থাকবে, periodic sensor polling হবে না। Dashboard বিস্তারিত log ও package inventory চাহিদার সময় load করবে। Animation reduced-motion মানবে এবং বন্ধ করা যাবে। Low-memory mode-এ usability বা status information বাদ দেওয়ার আগে decorative effect সরবে।
