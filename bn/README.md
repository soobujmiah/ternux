---
title: "ternux"
description: "ternux-এর বাংলা README — এক কমান্ডে Android ফোনে GPU-accelerated Linux ডেস্কটপ। root ছাড়া, ফ্রি, MIT লাইসেন্স।"
lang: "bn"
alt_url: "/README.html"

---

<div align="center">

# ternux

**একটি কমান্ড। আপনার পকেটের ফোনেই পূর্ণাঙ্গ GPU-accelerated Linux ডেস্কটপ।**

Termux + PRoot Debian + Xfce4 — Adreno ডিভাইসে Zink/Turnip দিয়ে Vulkan,
আর বাকি সব ডিভাইসে VirGL সামঞ্জস্য পথ। **root লাগে না, PC লাগে না,
অপেক্ষাও লাগে না।**

[![site](https://img.shields.io/badge/site-live-00ff41?style=flat-square)](https://soobujmiah.github.io/ternux/)
[![licence](https://img.shields.io/badge/licence-MIT-00b32d?style=flat-square)](LICENSE)
[![platform](https://img.shields.io/badge/Android-10%2B%20aarch64-ffb000?style=flat-square)](docs/INSTALLATION.md#requirements)

**বাংলা** · [English](https://soobujmiah.github.io/ternux/) · [English README](../README.md)

[ওয়েবসাইট](https://soobujmiah.github.io/ternux/bn/) ·
[ইনস্টলেশন](docs/INSTALLATION.md) ·
[দ্রুত শুরু](docs/QUICK-START.md) ·
[সাধারণ প্রশ্ন](docs/FAQ.md)

</div>

---

## ইনস্টল

Android 10+ ফোনে [Termux](https://github.com/termux/termux-app/releases)
(F-Droid বা GitHub বিল্ড) খুলে এই কমান্ডটি চালান:

```bash
curl -fsSL https://soobujmiah.github.io/ternux/install.sh | bash
```

> **আপগ্রেডের পর curl ভেঙে গেছে?** আংশিক আপগ্রেডে curl লিংকই হতে পারে না
> (`SSL_set_quic_tls_transport_params`)। wget সরাসরি openssl-এর সাথে লিংক হয়,
> সাধারণত টিকে যায় — একই ইনস্টলার:
>
> ```bash
> wget -qO- https://soobujmiah.github.io/ternux/install.sh | bash
> ```
> ইনস্টলার এখন ভাঙা curl নিজেই শনাক্ত করে মেরামত করে (`curl`+`openssl`)।

ব্যস, শেষ। ইনস্টলার আপনার GPU শনাক্ত করে, বেস প্যাকেজ ইনস্টল করে,
Debian + Xfce4 পরিবেশ তৈরি করে, অ্যাক্সিলারেটেড গ্রাফিক্স পথ সাজিয়ে দেয়,
লঞ্চার লিখে দেয় — তারপর বলে দেয় পরের ধাপ কী:

```text
1. Termux:X11 অ্যাপটি একবার খুলে চালু রাখুন।
2. source ~/.bashrc
3. x
```

`x` চালালেই ডেস্কটপ শুরু। স্ক্রিপ্ট চালানোর আগে পড়ে নিতে চান?

```bash
curl -fsSL https://soobujmiah.github.io/ternux/install.sh -o install.sh
less install.sh && bash install.sh
```

প্রতিটি অপশনসহ সম্পূর্ণ গাইড: [docs/INSTALLATION.md](docs/INSTALLATION.md)।
প্রতিটি কমান্ড হাতে-কলমে: [docs/MANUAL.md](docs/MANUAL.md)।
সবচেয়ে দ্রুত পথ: [docs/QUICK-START.md](docs/QUICK-START.md)।

---

## এটি আসলে কী

ternux একটি সাধারণ Android ফোনকে **হার্ডওয়্যার-অ্যাক্সিলারেটেড গ্রাফিক্সসহ
ব্যবহারযোগ্য Debian ডেস্কটপে** রূপ দেয় — বুটলোডার আনলক ছাড়া, root ছাড়া,
আর আপনার ফোনের স্বাভাবিক Android জীবনকে ঝুঁকিতে না ফেলে।

```text
 Android
  └─ Termux (হোস্ট শেল)
      ├─ Termux:X11  ← পর্দা
      ├─ PulseAudio  ← স্পিকার
      └─ PRoot Debian (কন্টেইনার)
          └─ Xfce4 ডেস্কটপ
              └─ Mesa → Zink → Vulkan → Turnip (Adreno GPU)
                        └─ বা VirGL → Android গ্রাফিক্স (অন্যান্য GPU)
```

### যেভাবে কাজ করে, তার কারণ

- **কেন PRoot, কেন root নয়?** রুট করলে ওয়ারেন্টি যায়, ব্যাংকিং অ্যাপ ভাঙে,
  পুরো ডিভাইস উন্মুক্ত হয়ে পড়ে। PRoot *ইউজারস্পেসে* একটি রুট ফাইলসিস্টেম
  নকল করে — কন্টেইনার মনে করে সিস্টেম তার, কিন্তু Android-এর স্যান্ডবক্স
  অক্ষত থাকে। আনইনস্টল = একটি ফোল্ডার মুছে ফেলা। এতটুকুই ঝুঁকি।
- **কেন Zink + Turnip?** Adreno ফোনে Vulkan ড্রাইভার আছে, কিন্তু ডেস্কটপ
  OpenGL ড্রাইভার নেই। Zink OpenGL কলকে Vulkan-এ অনুবাদ করে; Turnip হলো
  Adreno-র জন্য Mesa-র Vulkan ড্রাইভার। দুজনে মিলে ডেস্কটপ অ্যাপকে সত্যিকারের
  GPU পথ দেয় — সফটওয়্যার রেন্ডারিং (`llvmpipe`) নয়।
- **কেন VirGL?** Mali, Xclipse ও PowerVR ডিভাইসে Turnip নেই। VirGL কন্টেইনারের
  OpenGL কমান্ড হোস্ট পাশের একটি রেন্ডারারে পাঠায়। একটু ধীর, কিন্তু সবখানে চলে।
- **কেন যাচাইকৃত ধাপ?** দৃশ্যমান ডেস্কটপ সাফল্যের প্রমাণ নয় — সফটওয়্যার
  রেন্ডারিং *দেখতে* ঠিকই লাগে, যতক্ষণ না Blender চালান। ইনস্টলার প্রতিটি ধাপ
  পরেরটির আগে যাচাই করে এবং ড্রাইভার ফাইল সত্যিই ইনস্টল হলো কি না নিশ্চিত করে।

### সৎ সীমাবদ্ধতা

এটি এখনও একটি ফোন। RAM, তাপ ও ব্যাটারিই আসল সীমা:

- ✅ দৈনন্দিন ডেস্কটপ: Xfce4, টার্মিনাল, Git, এডিটর, ব্রাউজিং
- ✅ হালকা Blender: লো-পলি মডেলিং ও ছোট সিন
- ✅ লোকাল AI: Vulkan llama.cpp, ১–২B Q4 GGUF মডেল
- ✅ ডেভেলপমেন্ট: Node.js, Python, কোডিং অ্যাসিস্ট্যান্ট
- ⚠️ ভারী রেন্ডার, বড় সিমুলেশন, বিশাল মডেল, মাইনিং — এসবের জন্য নয়

---

## প্রয়োজনীয়তা

| | প্রস্তাবিত বেসলাইন |
|---|---|
| **OS** | Android 10 বা তার নতুন |
| **CPU** | `aarch64` (৬৪-বিট ARM) |
| **স্টোরেজ** | বেস ইনস্টলের জন্য ~১২ GB ফাঁকা; মডেল/প্রজেক্টে আরও |
| **RAM** | বাস্তবে ন্যূনতম ৪ GB; ৬–৮ GB আরামদায়ক |
| **গ্রাফিক্স** | Adreno → Zink + Turnip (সেরা) · Mali/Xclipse/PowerVR → VirGL |
| **অ্যাপ** | [Termux](https://github.com/termux/termux-app/releases) (F-Droid/GitHub) + [Termux:X11](https://github.com/termux/termux-x11) |

> Play Store-এর পরিত্যক্ত Termux বিল্ড **সমর্থিত নয়** — এটি বছরের পর বছর
> পুরনো, আর এর প্যাকেজ রিপোজিটরি আর আপডেট পায় না।

---

## এক কমান্ড, অনেক অপশন

ইনস্টলার একটি পরীক্ষাযোগ্য ফাইল, যুক্তিসঙ্গত ডিফল্টসহ:

```bash
bash install.sh                     # ইন্টারঅ্যাক্টিভ
bash install.sh --yes               # ডিফল্টে, কোনো প্রশ্ন নেই
bash install.sh --user soobuj --locale en_US.UTF-8
bash install.sh --backend virgl     # যেকোনো ডিভাইসে VirGL বাধ্যতামূলক
bash install.sh --with-llm --with-dev
bash install.sh --doctor            # ইনস্টল পরীক্ষা
bash install.sh --doctor --fix      # পরীক্ষা ও মেরামত
bash install.sh --resume            # বিঘ্নিত ইনস্টল আবার চালু
bash install.sh --uninstall         # ইন্টারঅ্যাক্টিভ অপসারণ
```

ঐচ্ছিক ওয়ার্কলোড: `--with-dev` (Git/Node/Python) · `--with-llm` (llama.cpp,
Vulkan) · `--with-network` (nmap, tmux — শুধু অনুমোদিত পরীক্ষায়) ·
`--with-media` (ffmpeg, GIMP, Audacity) · `--with-blender` — বা `--all`।

> **Android 12+ নোট:** "ফ্যান্টম প্রসেস কিলার" নিঃশব্দে ব্যাকগ্রাউন্ড প্রসেস
> মেরে ফেলে — কোনো এরর ছাড়া ডেস্কটপ বন্ধ হয়ে যাওয়ার এক নম্বর কারণ।
> ইনস্টলার এটি শনাক্ত করে সঠিক সমাধান দেখিয়ে দেয় (Android 14+-এ একটি
> ডেভেলপার-অপশন টগল, 12–13-এ একটি ADB কমান্ড)।
> বিস্তারিত: [সমস্যা সমাধান](docs/TROUBLESHOOTING.md#the-desktop-dies-silently)।

---

## ডকুমেন্টেশন

প্রতিটি পৃষ্ঠা ইংরেজি ও বাংলায় আছে। ইংরেজি পৃষ্ঠাগুলো হেডারে বাংলা
মিররের লিংক দেয়।

| ডকুমেন্ট | উদ্দেশ্য |
|---|---|
| [দ্রুত শুরু](docs/QUICK-START.md) | অ্যাপ ইনস্টল থেকে যাচাইকৃত ডেস্কটপ পর্যন্ত দ্রুততম পথ |
| [ইনস্টলেশন](docs/INSTALLATION.md) | প্রয়োজনীয়তা, এক-কমান্ড ইনস্টল, প্রতিটি ধাপ কী করে *ও কেন*, ফ্ল্যাগ, আনইনস্টল |
| [ম্যানুয়াল ইনস্টলেশন](docs/MANUAL.md) | Every step by hand, command by command — full control, or debugging the installer |
| [ব্যবহার](docs/USAGE.md) | দৈনিক নিয়ন্ত্রণ, স্টোরেজ বিন্যাস, Blender, লোকাল AI, ডেভেলপমেন্ট, ব্যাকআপ |
| [কনফিগারেশন](docs/CONFIGURATION.md) | প্রতিটি সেটিং: লঞ্চার এনভায়রনমেন্ট, GPU পথ, অডিও, লোকেল, ফন্ট |
| [সমস্যা সমাধান](docs/TROUBLESHOOTING.md) | লক্ষণ → কারণ → সমাধান, ফ্যান্টম কিলার, `llvmpipe`, অডিও, নেটওয়ার্ক |
| [আর্কিটেকচার](docs/ARCHITECTURE.md) | স্ট্যাক কীভাবে জোড়া লাগে এবং কোথায় নিঃশব্দে ভাঙতে পারে |
| [সাধারণ প্রশ্ন](docs/FAQ.md) | root, নিরাপত্তা, Play Store Termux, স্টোরেজ, ব্যাটারি, গেমিং, প্রাইভেসি |

---

## GPU আসল কিনা যাচাই করুন

ডেস্কটপ চালু হওয়ার পর কন্টেইনারের টার্মিনালে চালান:

```bash
glxinfo | grep "renderer string"
```

| যা চাই | যা কখনোই মেনে নেবেন না |
|---|---|
| `zink Vulkan (Adreno (TM) … (MESA_TURNIP))` | `llvmpipe` (সফটওয়্যার রেন্ডারিং) |
| `virgl` (সামঞ্জস্য পথ) | ফাঁকা উত্তর |

`llvmpipe` মানে GPU পথ সক্রিয় নয় — ডেস্কটপ চলে, কিন্তু ধীরে।
দেখুন [সমস্যা সমাধান → llvmpipe](docs/TROUBLESHOOTING.md#renderer-says-llvmpipe)।

---

## নিরাপত্তা

- ternux **কখনোই** root চায় না, Android সিস্টেম ফাইল বদলায় না, বুটলোডার
  স্পর্শ করে না। সবকিছু Termux-এর প্রাইভেট স্টোরেজে থাকে।
- সার্ভিসগুলো (অডিও, লোকাল মডেল সার্ভার) ডিফল্টে **শুধু লুপব্যাকে** বাঁধা —
  নেটওয়ার্ক থেকে ধরাছোঁয়ার বাইরে।
- ইনস্টলার Turnip ড্রাইভার
  [lfdevs/mesa-for-android-container](https://github.com/lfdevs/mesa-for-android-container/releases)
  থেকে নামায়, আর্কাইভ যাচাই করে (লিংক নেই, পাথ-ট্রাভার্সাল নেই) এবং শুধু
  দরকারি দুটি ড্রাইভার ফাইল ইনস্টল করে। SHA-256 ইনস্টল স্টেটে রেকর্ড থাকে।

## আনইনস্টল

```bash
curl -fsSL https://soobujmiah.github.io/ternux/uninstall.sh | bash
# বা
bash install.sh --uninstall
```

সবকিছু (কন্টেইনার, লঞ্চার, শর্টকাট) Termux-এর ভেতরে থাকে। Termux-এর ডেটা
মুছে দিলেই ternux সম্পূর্ণভাবে চলে যায়।

---

## কনট্রিবিউশন

ডিভাইস-নির্দিষ্ট তথ্য, রেন্ডারার প্রমাণ ও অনুবাদ স্বাগত।
দেখুন [CONTRIBUTING.md](CONTRIBUTING.md)।

## লাইসেন্স

MIT — দেখুন [LICENSE](../LICENSE)। Termux, Debian, Xfce, Blender, Qualcomm
বা এখানে উল্লেখিত কোনো তৃতীয় পক্ষের প্রকল্পের সাথে সম্পর্কিত নয়।

---

<div align="center">

নির্মাতা: **Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah))**

Copyright © 2026 Sobuj Miah · MIT লাইসেন্স

</div>
