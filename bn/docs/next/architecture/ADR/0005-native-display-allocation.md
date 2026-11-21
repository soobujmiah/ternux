---
title: "ADR-0005: Native-first display allocation"
description: "প্রথম X11 display native Termux workspace-এ রেখে পরে guest display বরাদ্দ।"
lang: "bn"
alt_url: "/docs/next/architecture/ADR/0005-native-display-allocation.html"
---

## ADR-0005: Native-first display allocation

- **অবস্থা:** গৃহীত; default, startup collision guard, lifecycle registry, read-only preview ও journaled explicit migration executor source-এ আছে; device-এ প্রয়োগ এখনো যাচাই হয়নি।
- **তারিখ:** 2026-11-13।
- **সিদ্ধান্তের মালিক:** Ternux project owner।

## প্রেক্ষাপট

Linux guest desktop-এর পাশাপাশি Ternux native Termux manager। Manager ও guest যেন একই সময়ে চলতে পারে এবং অন্য workspace-এর X11 display দখল/পুনর্ব্যবহার না করে—তার জন্য display ownership নির্ধারিত হতে হবে।

## সিদ্ধান্ত

Native Termux workspace ও Control Center-এর জন্য `:0` সংরক্ষণ। Guest স্থির ক্রমে: Debian `:1`, Ubuntu `:2`, Kali `:3`, Alpine `:4`; পরের installed distro পরের free serial display পাবে। Registry workspace identity, display number, socket owner ও lifecycle record রাখে। Allocation registry এবং live X socket/process দুটোই যাচাই করে; server নেই প্রমাণ হলেই stale record reclaim করা যাবে।

Reference device-এর saved mapping (সর্বশেষ source snapshot-এ Debian `:0`, Ubuntu `:2`, Alpine `:3`) operator ready state-bound plan apply না করা পর্যন্ত অক্ষত। Migration সব target/session পরীক্ষা করে exact profile ও registry backup private journal-এ রাখে; write failure/interruption হলে restore করে।

## বিকল্প

- Guest Debian-কে `:0`-তে রাখা: আগের layout-এ native Termux GUI-র reserved display থাকত না এবং default guest-এর সঙ্গে conflict হতে পারত, তাই প্রত্যাখ্যাত।
- প্রতি start-এ যেকোনো free display দেওয়া: restart-এ পরিচয় অনিশ্চিতভাবে বদলায়, তাই প্রত্যাখ্যাত।
- শুধু installed guest order থেকে display number: distro যোগ/সরালে চলমান workspace সরে যেতে পারে, তাই প্রত্যাখ্যাত।

## ফলাফল

Persistent collision-checked display registry ও migration path দরকার। Install order বদলালেও guest display ID স্থির। অচেনা বা অন্য process দখল করা display clear allocation error দেবে; process terminate/reuse নয়।

বর্তমান implementation নতুন profile-এ stable default দেয় এবং পুরনো saved display রাখে। Versioned, lock-protected registry workspace ID, current/target display, শেষ lifecycle state ও update time atomicভাবে রাখে। Socket path, lock, server process ও inferred owner class live observation; registry OS-level ownership দাবি করে না। Startup occupied socket, X lock বা matching server process দেখে conflict হলে reuse প্রত্যাখ্যান করে। Read-only `tx manager displays` current/target assignment, occupied path, blocker ও state-bound plan ID দেখায়। Schema `1.3.0` explicit executor প্রস্তুত কি না জানায়। `tx manager migrate --apply sha256:PLAN_ID` migration lock ধরে exact snapshot আবার যাচাই করে; guest stop/restart করে না, active session, occupied target, invalid/mismatched registry বা চলমান lifecycle-এ reject করে। Write-এর আগে profile/registry backup হয়; ব্যর্থ write দুটোই restore করে। Interrupted write-এ guest startup বন্ধ থাকে, যতক্ষণ না `tx manager migrate --recover` journal restore করে। Live mapping স্বয়ংক্রিয়ভাবে বদলায় না।
