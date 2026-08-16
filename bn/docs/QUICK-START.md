---
title: "দ্রুত শুরু"
description: "একটি খালি Android ফোন থেকে যাচাইকৃত, GPU-accelerated ternux ডেস্কটপ পর্যন্ত দ্রুততম পথ — মোটামুটি দশ মিনিট।"
lang: "bn"
alt_url: "/docs/QUICK-START.html"

---

# দ্রুত শুরু

দশ মিনিট, তিনটি ধাপ, একটি ডেস্কটপ। এই পাতাটি ধরে নেয় আপনার কাছে একটি
চালু Android ফোন ছাড়া আর কিছুই নেই।

---

## ধাপ ০ — দুটি অ্যাপ ইনস্টল করুন (২ মিনিট)

1. **Termux** — হোস্ট টার্মিনাল।
   [GitHub releases](https://github.com/termux/termux-app/releases) থেকে APK
   নামান বা [F-Droid](https://f-droid.org/en/packages/com.termux/) দিয়ে
   ইনস্টল করুন।
   *কেন Play Store নয়? সেই বিল্ডটি বছর আগে পরিত্যক্ত — এর প্যাকেজ
   রিপোজিটরি মৃত, কিছুই ইনস্টল হয় না।*
2. **Termux:X11** — ডেস্কটপ দেখানো অ্যাপটি।
   [GitHub releases](https://github.com/termux/termux-x11/releases) থেকে
   নামান। **একবার** খুলুন যাতে Android এটি নিবন্ধন করে, তারপর রেখে দিন।

## ধাপ ১ — একটি কমান্ড চালান (৫–১৫ মিনিট)

Termux খুলে পেস্ট করুন:

```bash
curl -fsSL https://soobujmiah.github.io/ternux/install.sh | bash
```

আপগ্রেডের পর curl ভেঙে গেছে? wget দিয়েও একই কাজ:

```bash
wget -qO- https://soobujmiah.github.io/ternux/install.sh | bash
```

ইনস্টলার:

1. ডিভাইস পরীক্ষা করে (আর্কিটেকচার, Android ভার্সন, স্টোরেজ, নেটওয়ার্ক);
2. Termux প্যাকেজ ইনস্টল করে (X11, PulseAudio, PRoot);
3. PRoot কন্টেইনারে **Debian + Xfce4** ইনস্টল করে;
4. GPU শনাক্ত করে সঠিক ড্রাইভার বসায়
   (**Adreno → Zink/Turnip** · অন্যান্য → **VirGL**);
5. অডিও, ফন্ট ও লোকেল কনফিগার করে;
6. লঞ্চার ও শেল শর্টকাট লিখে দেয়;
7. সবকিছু ঠিকমতো বসেছে কিনা যাচাই করে।

নন-ইন্টারঅ্যাক্টিভ মোডে এটি নিজেই যুক্তিসঙ্গত ডিফল্টে প্রশ্নের উত্তর দেয়;
স্পষ্টভাবে ডিফল্ট চাইলে `--yes` যোগ করুন। আগে পড়ে নিতে চান?

```bash
curl -fsSL https://soobujmiah.github.io/ternux/install.sh -o install.sh && less install.sh
bash install.sh
```

## ধাপ ২ — ডেস্কটপ চালু করুন (৩০ সেকেন্ড)

```bash
source ~/.bashrc
x
```

`x` শর্টকাট ধারাবাহিকভাবে চালু করে: অডিও ব্রিজ → ডিসপ্লে (`Termux:X11`) →
Debian → **Xfce4**। Termux:X11 অ্যাপে যান — আপনার ডেস্কটপ সেখানেই।

## ধাপ ৩ — প্রমাণ করুন GPU আসল (৩০ সেকেন্ড)

ডেস্কটপের ভেতরে একটি টার্মিনাল খুলুন (রাইট-ক্লিক → *Open Terminal Here*)
এবং চালান:

```bash
glxinfo | grep "renderer string"
```

| যা দেখবেন | অর্থ |
|---|---|
| `zink Vulkan (Adreno (TM) … (MESA_TURNIP))` | ✅ হার্ডওয়্যার GPU পথ (Adreno) |
| `virgl` | ✅ হার্ডওয়্যার GPU পথ (সামঞ্জস্য) |
| `llvmpipe` | ❌ সফটওয়্যার রেন্ডারিং — ঠিক করুন, মেনে নেবেন না |

`llvmpipe` দেখলে ডেস্কটপ চলবেই, কিন্তু গ্রাফিক্স শুধুই সফটওয়্যার।
দেখুন [সমস্যা সমাধান → llvmpipe](TROUBLESHOOTING.html#renderer-says-llvmpipe)।

---

## এখন আপনার যা আছে

### পুরনো শেল শর্টকাট

```text
x        ডেস্কটপ চালু          killx  সব পরিষ্কারভাবে বন্ধ
db       Debian শেল (ইউজার)    droot  রুট শেল
xgo      Termux:X11 + x একসাথে  ai     লোকাল মডেলে চ্যাট
sysmon   ডিভাইসের সারসংক্ষেপ   clean-mesa  শেডার ক্যাশ পরিষ্কার
```

### ternux CLI — ব্যবস্থাপনা ইন্টারফেস

ইনস্টলের পর `ternux` কমান্ড আপনার স্থায়ী নিয়ন্ত্রণ কেন্দ্র:

```bash
ternux doctor           # সিস্টেম ডায়াগনস্টিক
ternux doctor --json    # AI-পাঠযোগ্য আউটপুট
ternux start            # ডেস্কটপ চালু
ternux stop             # ডেস্কটপ বন্ধ
ternux repair           # সাধারণ সমস্যা সমাধান
ternux verify           # ইনস্টলেশন যাচাই
ternux benchmark        # GPU বেঞ্চমার্ক
ternux backend set virgl  # GPU ব্যাকএন্ড পরিবর্তন
ternux info             # সিস্টেম তথ্য
ternux state            # ইনস্টলেশন অবস্থা
ternux logs             # লগ ফাইল দেখা
ternux update           # আপডেট
ternux uninstall        # কম্পোনেন্ট অপসারণ
```

প্রত্যেক কমান্ড `--help`, `--json`, `--verbose` ও `--quiet` সমর্থন করে।
সম্পূর্ণ রেফারেন্স: [CLI রেফারেন্স](CLI.md)।

- কন্টেইনারে একটি পূর্ণাঙ্গ **Debian ডেস্কটপ** — এমুলেটেড নয়, ইনস্টলড।
- OpenGL অ্যাপে **হার্ডওয়্যার-অ্যাক্সিলারেটেড গ্রাফিক্স** (Blender, GL টুলস)।
- ফোনের স্পিকার/হেডফোনে **শব্দ** ব্রিজড।
- Android ও Debian-এর মধ্যে **শেয়ার্ড স্টোরেজ** (Termux-এ `~/storage` ↔
  কন্টেইনারে `/sdcard`)।

## Android 12+? একটি জরুরি নোট

Android-এর **ফ্যান্টম প্রসেস কিলার** নিঃশব্দে ব্যাকগ্রাউন্ড প্রসেস মেরে
ফেলে — কোনো এরর ছাড়াই ডেস্কটপ সেশন শেষ হয়ে যেতে পারে। ইনস্টলার শেষে
সঠিক সমাধান দেখায় — Android 14+-এ একটি ডেভেলপার-অপশন টগল
(*Disable child process restrictions*)। বিস্তারিত:
[সমস্যা সমাধান](TROUBLESHOOTING.html#the-desktop-dies-silently)।

## এরপর

- [ম্যানুয়াল ইনস্টলেশন](MANUAL.html) — প্রতিটি কমান্ড হাতে-কলমে, দুই GPU পথ
- [ইনস্টলেশন](INSTALLATION.html) — প্রতিটি ধাপের ব্যাখ্যা, সব অপশন, আনইনস্টল
- [ব্যবহার](USAGE.html) — Blender, লোকাল AI, ডেভেলপমেন্ট, ব্যাকআপ
- [সাধারণ প্রশ্ন](FAQ.html) — নিরাপত্তা, স্টোরেজ, ব্যাটারি, গেমিং

---

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · MIT*
