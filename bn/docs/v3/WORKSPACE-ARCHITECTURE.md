---
title: "টার্নাক্স v3 Workspace architecture"
description: "পৃথক Linux guest workspace-এর shell, display ও lifecycle।"
lang: "bn"
alt_url: "/docs/v3/WORKSPACE-ARCHITECTURE.html"
---

## Workspace architecture

**অবস্থা: নকশা সম্পন্ন।** Workspace হলো নিবন্ধিত একটি PRoot-Distro guest, সঙ্গে তার Ternux profile, user mapping, package, display assignment, mount, desktop state ও log। Owner-confirmed v2 baseline Debian, Ubuntu, Kali Linux ও Alpine; distro ভেদে evidence-এর পরিমাণ আলাদা। [v2 distro ও release reconciliation](/docs/release/V2-RELEASE-RECONCILIATION.html) দেখুন। অন্য distro নিজস্ব acceptance evidence না পাওয়া পর্যন্ত experimental।

## পরিচয় ও command

প্রতিটি guest-এর immutable internal ID ও আলাদা পড়ার উপযোগী নাম থাকবে। স্থির alias (`db`, `ub`, `kali`, `alp` ও পূর্ণ নাম) একটি guest-এ resolve হবে; shell alias configured unprivileged user-এ ঢুকবে এবং আলাদা `root` alias root-এ ঢুকবে। `tx start [guest]` নির্বাচিত desktop চালায়। একাধিক উপযুক্ত guest থাকলে এবং নির্বাচন না থাকলে CLI একরূপ multi-choice prompt দেখায়। কোন display চলছে তার ভিত্তিতে default guest নীরবে বদলাবে না।

`tx stop [guest...]` নির্বাচিত guest-এ প্রয়োগ হয়। Argument ছাড়া interactive stop-এ active session তালিকা ও একাধিক নির্বাচন থাকে। v3-তে native Termux workspace/Control Center-এর জন্য `:0` সংরক্ষিত। নতুন guest-এর default: Debian `:1`, Ubuntu `:2`, Kali `:3`, Alpine `:4`; পরের named profile serial ক্রমে পাবে। Startup target X11 socket ও matching Termux:X11 server দেখে, দখল করা path প্রত্যাখ্যান করে এবং lock PID/process check দিয়ে stale প্রমাণিত socket-ই শুধু সরায়। Display number guest profile-এ সংরক্ষিত থাকে। বর্তমান v2 device-এর Debian `:0`, Ubuntu `:1`, Alpine `:2` assignment এই code নিজে বদলায় না। Read-only report সম্ভব হলে দখল করা target-কে এক চলমান guest-এর saved assignment-এর সঙ্গে মেলায়; এতে OS-level socket ownership প্রমাণ হয় না। না মিললে reserved native slot বা অজ্ঞাত owner বলে। Persistent registry workspace identity, saved/target display, শেষ lifecycle ও update time রাখে; socket-owner detail runtime probe, persisted claim নয়। Explicit staged migration-এর আগে প্রতিটি target validate করে সব session নিরাপদে সরানো সম্ভব কি না নিশ্চিত করতে হবে।

## প্রতি-guest recipe

Distro recipe-তে package-family operation, user/sudo setup, graphics/audio integration, Ternux theme asset, keyboard/input setup, browser, app, storage policy, health probe ও removal ownership থাকবে। প্রতিটি recipe unsupported operation স্পষ্ট করবে; সব package manager apt-এর মতো আচরণ করে ধরে নেবে না। Shared asset versioned এবং একই যাচাইকৃত source bundle থেকে install হবে।

## Isolation ও persistence

প্রতিটি guest কেবল ঘোষিত bind পাবে: `/dev`, প্রয়োজনীয় `/proc` ও `/sys` view, Termux:X11 socket, PulseAudio route, Termux-এর permission আগে থেকে থাকলে Android shared storage `/sdcard`, এবং user-granted extra subdirectory। Host `$PREFIX` ও Termux home ডিফল্টে প্রকাশ হবে না। Ternux CLI update-এ guest package ও home data থাকবে। Guest deletion আলাদা destructive action; explicit confirmation-এর আগে সুনির্দিষ্ট rootfs ও state দেখাবে।

## GUI compatibility

Desktop setup GTK, icon, window-manager theme, ব্যবহারযোগ্য titlebar control, phone viewport fitting, IBus, font ও launcher configure করে। Claim toolkit-নির্দিষ্ট: XFWM decoration server-decorated window-এর জন্য; client-side decoration ও অন্য toolkit আলাদা test চায়। Ternux theme inherited fallback icon দেবে; অচেনা app icon-কে সম্পর্কহীন brand mark দিয়ে বদলাবে না।
