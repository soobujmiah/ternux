---
title: "ইনস্টলেশন"
description: "সম্পূর্ণ ternux ইনস্টলেশন গাইড: প্রয়োজনীয়তা, এক-কমান্ড ইনস্টলার, প্রতিটি ধাপ কী করে ও কেন, সব অপশন, এবং পরিষ্কার অপসারণ।"
lang: "bn"
alt_url: "/docs/INSTALLATION.html"

---

# ইনস্টলেশন

এটি সম্পূর্ণ গাইড। দশ মিনিটের সংস্করণ চাইলে শুরু করুন
[দ্রুত শুরু](QUICK-START.html) থেকে।

> **প্রতিটি কমান্ড নিজ হাতে চালাতে চান?** সম্পূর্ণ হাতে-কলমে নির্দেশিকা —
> প্রতিটি কমান্ড, দুই GPU পথ, পুরো লঞ্চার ফাইল — আছে
> [ম্যানুয়াল ইনস্টলেশন](MANUAL.html) পাতায়। নিচের এক-কমান্ড ইনস্টলারটি
> সেই একই পাতাই, স্ক্রিপ্ট আকারে।

---

## প্রয়োজনীয়তা {#requirements}

| | প্রস্তাবিত বেসলাইন | কেন জরুরি |
|---|---|---|
| **Android** | ১০ বা নতুন | পুরনো বিল্ডে Termux/X11-এর দরকারি API নেই |
| **CPU** | `aarch64` (৬৪-বিট ARM) | PRoot নেটিভ বাইনারি চালায়; ৩২-বিট ARM আপস্ট্রিমে অসমর্থিত |
| **স্টোরেজ** | ~১২ GB ফাঁকা | ~৬ GB বেস রুটফস + প্যাকেজ; মডেল-প্রজেক্টে আরও |
| **RAM** | ন্যূনতম ৪ GB, ৬–৮ GB ভালো | ডেস্কটপ আর Android একই মেমরি ভাগ করে; কম RAM = বেশি প্রসেস-কিল |
| **গ্রাফিক্স** | Adreno (সেরা) বা যেকোনো GPU | Adreno-তে Zink/Turnip; বাকিতে VirGL |
| **অ্যাপ** | Termux (F-Droid/GitHub) + Termux:X11 | Play Store-এর Termux বিল্ড পরিত্যক্ত |

শুরু করার আগে ডিভাইস পরীক্ষা করুন (শুধু পড়ে, কিছুই বদলায় না):

```bash
uname -m                              # আশা: aarch64
getprop ro.product.manufacturer       # যেমন Qualcomm
getprop ro.product.model
getprop ro.build.version.release      # যেমন 14
df -h "$HOME"                         # ফাঁকা জায়গা
ls -l /dev/kgsl-3d0 2>&1              # থাকলে → Adreno → Zink/Turnip পথ
```

`/dev/kgsl-3d0` থাকলে ইনস্টলার দ্রুত Zink/Turnip পথ বেছে নেবে। না থাকলে
VirGL — হার্ডওয়্যার-ব্যাকডই, শুধু ভিন্ন পথ।

---

## পদ্ধতি ১ — এক কমান্ড (প্রস্তাবিত)

```bash
curl -fsSL https://soobujmiah.github.io/ternux/install.sh | bash
```

এটি HTTPS-এ ইনস্টলার নামিয়ে চালায়। এই রিপোজিটরির সেই একই স্ক্রিপ্ট —
লুকানো কিছু নেই, কম্পাইলড কিছু নেই।

**আপগ্রেডের পর curl ভেঙে গেছে?** (`CANNOT LINK … SSL_set_quic_tls_transport_params`)
আংশিক আপগ্রেডে curl ও openssl সামঞ্জস্য হারিয়েছে। wget ব্যবহার করুন — একই
ইনস্টলার, আর স্ক্রিপ্ট আপনার curl নিজেই মেরামত করে দেবে:

```bash
wget -qO- https://soobujmiah.github.io/ternux/install.sh | bash
```

### কেন পদ্ধতি ২-ও দেখানো হলো

`curl`-এর আউটপুট সরাসরি `bash`-এ পাঠানো সুবিধাজনক, কিন্তু ডিভাইসে চলবে এমন
যেকোনো স্ক্রিপ্টের ভালো অভ্যাস হলো **আগে পড়া**। পদ্ধতি ২-তে দশ সেকেন্ড বেশি লাগে:

```bash
curl -fsSL https://soobujmiah.github.io/ternux/install.sh -o install.sh
less install.sh     # চোখ বুলিয়ে নিন — একটি ফাইল, ধাপে ধাপে সাজানো
bash install.sh
```

curl চালুই না হলে wget দিয়ে:

```bash
wget -q https://soobujmiah.github.io/ternux/install.sh -O install.sh
less install.sh
bash install.sh
```

দুটো পদ্ধতিই একই আচরণ করে। ডাউনলোড বিঘ্নিত হলে আবার চালান — প্রতিটি ধাপ
আইডেমপোটেন্ট, আর `--resume` শেষ হওয়া কাজ বাদ দিয়ে বাকিটা চালায়।

### পদ্ধতি ৩ — সম্পূর্ণ ম্যানুয়াল, কমান্ডে কমান্ডে

সম্পূর্ণ নিয়ন্ত্রণ চাইলে — বা ইনস্টলার নিজেই ডিবাগ করতে হলে —
[ম্যানুয়াল ইনস্টলেশন](MANUAL.html) পাতায় প্রতিটি কমান্ড খোলাসা করে আছে:
বেস প্যাকেজ, কন্টেইনার, দুই পথের GPU ড্রাইভার, সম্পূর্ণ `~/x.sh` লঞ্চার
ফাইল ও যাচাইকরণ। পদ্ধতি ১ ও ২ আপনার জন্য সেই একই ধাপগুলোই চালায়।

---

## ternux CLI — ব্যবস্থাপনা ইন্টারফেস

ইনস্টলের পর `ternux` CLI আপনার একমাত্র প্রবেশপথ ডায়াগনস্টিক, মেরামত,
ডেস্কটপ ব্যবস্থাপনা ও আপডেটের জন্য:

```bash
ternux doctor           # সিস্টেম ডায়াগনস্টিক
ternux doctor --json    # AI-পাঠযোগ্য আউটপুট
ternux start            # ডেস্কটপ চালু
ternux stop             # ডেস্কটপ বন্ধ
ternux restart          # ডেস্কটপ পুনরায় চালু
ternux repair           # সাধারণ সমস্যা সমাধান
ternux verify           # ইনস্টলেশন যাচাই
ternux benchmark        # GPU বেঞ্চমার্ক
ternux profile          # ডিভাইস প্রোফাইল
ternux backend          # GPU ব্যাকএন্ড ব্যবস্থাপনা
ternux info             # সিস্টেম তথ্য
ternux info --json      # AI-পাঠযোগ্য তথ্য
ternux logs             # লগ দেখা
ternux state            # ইনস্টলেশন অবস্থা
ternux update           # CLI আপডেট
ternux uninstall        # কম্পোনেন্ট অপসারণ
```

প্রত্যেক কমান্ড `--help`, `--json`, `--verbose` ও `--quiet` সমর্থন করে।

---

## ইনস্টলার যা করে (এবং কেন, ধাপে ধাপে) {#what-the-installer-does-and-why-phase-by-phase}

ইনস্টলার **নয়টি যাচাইকৃত ধাপে** সাজানো। প্রতিটি ধাপ পরেরটি শুরুর আগে নিজের
কাজ যাচাই করে — ব্যর্থ ধাপ স্পষ্ট বার্তায় ইনস্টল থামিয়ে দেয়, "প্রায় চলে"
এমন অর্ধভাঙা ডেস্কটপ রেখে যায় না।

| # | ধাপ | কী করে | কেন |
|---|---|---|---|
| ০ | **প্রিফ্লাইট** | Termux, আর্কিটেকচার, Android ভার্সন, স্টোরেজ, নেটওয়ার্ক পরীক্ষা | এখানে ব্যর্থ হলে ডাউনলোডও নষ্ট হয় না; পরের সব ধাপ এই তথ্যের ওপর নির্ভর করে |
| ১ | **বেস প্যাকেজ** | `x11-repo`, `termux-x11-nightly`, `pulseaudio`, `proot-distro`, `virglrenderer-android`, টুলস ইনস্টল; স্টোরেজ অনুমতি | কন্টেইনারের দরকারি হোস্ট-সাইড সার্ভিস: ডিসপ্লে, শব্দ ও কন্টেইনার ইঞ্জিন |
| ২ | **Debian + Xfce4** | Debian রুটফস, ডেস্কটপ প্যাকেজ, পাসওয়ার্ডবিহীন sudo সহ আপনার ইউজার | আপনি যে ডেস্কটপ ব্যবহার করবেন; `visudo` দিয়ে sudo যাচাই, যাতে টাইপো কখনো কন্টেইনার লক না করে |
| ৩ | **GPU ড্রাইভার** | Adreno: Turnip ড্রাইভার ডাউনলোড, আর্কাইভ যাচাই, ইনস্টল, Mesa প্যাকেজ পিন। অন্যান্য: VirGL হোস্ট রেন্ডারার নিশ্চিত | এটি ছাড়া সব GL অ্যাপ CPU-তে চলে (`llvmpipe`)। পিন করা থাকলে সাধারণ `apt upgrade` নিঃশব্দে GPU পথ বদলে দিতে পারে না |
| ৪ | **অডিও, লোকেল, ফন্ট** | PulseAudio ব্রিজ (শুধু লুপব্যাক), লোকেল তৈরি, ইমোজি/পাওয়ারলাইন/নার্ড ফন্ট | শব্দ TCP দিয়ে কন্টেইনার সীমানা পাড়ি দেয় — লুপব্যাকেই সীমাবদ্ধ, নেটওয়ার্কে খোলা নয়; ফন্ট টার্মিনালে "টোফু বক্স" ঠেকায় |
| ৫ | **লঞ্চার** | GPU পথ অনুযায়ী `~/x.sh` লেখা ও সিনট্যাক্স-চেক | এক কমান্ডে (`x`) অডিও → ডিসপ্লে → ডেস্কটপ নির্ভরযোগ্য ক্রমে শুরু হতেই হবে |
| ৬ | **শর্টকাট** | `x`, `killx`, `db`, `droot`, `xgo`, `ai`, `sysmon`, `clean-mesa` | দৈনিক কাজ হওয়া উচিত অভ্যাস, প্রত্নতত্ত্ব নয় |
| ৭ | **ঐচ্ছিক এক্সট্রা** | ডেভ টুলস, llama.cpp, নেটওয়ার্ক টুলস, মিডিয়া টুলস, Blender — শুধু যা চেয়েছেন | বেস ইনস্টল হালকা থাকুক; প্রতিটি প্রোফাইলের স্টোরেজ/তাপের খরচ আলাদা |
| ৮ | **ফ্যান্টম-কিলার চেক** | Android 12+-এর ব্যাকগ্রাউন্ড সীমাবদ্ধতা শনাক্ত ও সঠিক সমাধান দেখানো | দীর্ঘ ডেস্কটপ সেশনের এক নম্বর নিঃশব্দ হত্যাকারী — বিল্ড খাওয়ার *আগে* জেনে রাখুন |
| ৯ | **যাচাইকরণ** | প্রতিটি গুরুত্বপূর্ণ বাইনারি, ফাইল ও অনুমতি সত্যিই আছে কিনা নিশ্চিত করা | বিশ্বাস নয়, যাচাই — `apt` সফল হওয়া প্রমাণ নয় যে ডেস্কটপ চালু হবে |

---

## ইনস্টলার অপশন

```bash
bash install.sh                     # ইন্টারঅ্যাক্টিভ — বড় ধাপের আগে প্রশ্ন করে
bash install.sh --yes               # সব ডিফল্ট মেনে নেয়, প্রশ্ন নেই
bash install.sh --user soobuj       # Debian ইউজারনাম (ডিফল্ট: ternux)
bash install.sh --locale bn_BD.UTF-8
bash install.sh --backend zink      # Zink/Turnip বাধ্যতামূলক (শুধু Adreno)
bash install.sh --backend virgl     # সর্বজনীন সামঞ্জস্য পথ বাধ্যতামূলক
bash install.sh --zsh               # Termux শেলও zsh-এ বদলান
bash install.sh --with-dev          # Git, Node.js, Python, বিল্ড টুলস
bash install.sh --with-llm          # llama.cpp + Vulkan (লোকাল AI)
bash install.sh --with-network      # nmap, tmux (শুধু অনুমোদিত পরীক্ষা)
bash install.sh --with-media        # ffmpeg, GIMP, Audacity, ImageMagick
bash install.sh --with-blender      # Blender (হালকা সিন)
bash install.sh --all               # সব ঐচ্ছিক প্রোফাইল
bash install.sh --resume            # বিঘ্নের পর আবার চালু
bash install.sh --version | --help
```

ইনস্টলের পর `ternux` CLI ব্যবহার করুন ডায়াগনস্টিক ও ব্যবস্থাপনার জন্য:

```bash
ternux doctor           # ডায়াগনস্টিক (bash install.sh --doctor এর বদলে)
ternux repair           # ডায়াগনস্টিক ও মেরামত (--doctor --fix এর বদলে)
ternux state            # কী হয়েছে, কী বাকি (--status এর বদলে)
ternux uninstall        # অপসারণ (--uninstall এর বদলে)
ternux update           # CLI আপডেট
```

### GPU ব্যাকএন্ড বাছাই

| আপনার GPU | ব্যাকএন্ড | প্রত্যাশা |
|---|---|---|
| Qualcomm Adreno | `auto` → **zink** | দ্রুততম — OpenGL অ্যাপ Zink → Vulkan → Turnip দিয়ে চলে |
| Mali / Xclipse / PowerVR / অন্যান্য | `auto` → **virgl** | হোস্ট রেন্ডারারের মাধ্যমে হার্ডওয়্যার-ব্যাকড; Turnip-এর চেয়ে ধীর |
| Adreno, কিন্তু ড্রাইভার ডাউনলোড ব্যর্থ | `--backend virgl` | নির্ভরযোগ্য বিকল্প |

নন-Adreno ডিভাইসে `zink` জোর করলে প্রিফ্লাইট জোরে ব্যর্থ হয় — নিঃশব্দে
সফটওয়্যার ডেস্কটপ বানায় না। এই ব্যর্থতা ইচ্ছাকৃত।

---

## ইনস্টলের পর

```text
1. Termux:X11 একবার খুলে চালু রাখুন।
2. source ~/.bashrc
3. x                 ← ডেস্কটপ চালু হয়
```

সম্পূর্ণ ডায়াগনস্টিক চালান:

```bash
ternux doctor
ternux doctor --json    # AI-পাঠযোগ্য আউটপুট
```

তারপর ডেস্কটপের টার্মিনাল থেকে গ্রাফিক্স পথ যাচাই করুন:

```bash
glxinfo | grep "renderer string"
vulkaninfo --summary | grep -i driverName     # Adreno: আশা "Turnip"
```

বড় মডেল বা পরীক্ষামূলক প্যাকেজ যোগের আগে চালু অবস্থার ব্যাকআপ নিন:

```bash
proot-distro backup debian --output ~/debian-backup.tar.gz
```

---

## আপডেট

- **ternux CLI:** `ternux update` GitHub থেকে সর্বশেষ ভার্সন নিয়ে আসে।
- **ইনস্টলার নিজে:** আবার ডাউনলোড করে চালান। প্রতিটি ধাপ আইডেমপোটেন্ট, আর
  `--resume` শেষ ধাপগুলো বাদ দেয়। কন্টেইনার ও ফাইল অক্ষত থাকে।
- **Debian প্যাকেজ:** ডেস্কটপে `sudo apt update && sudo apt upgrade`।
  Zink পথে Mesa প্যাকেজ ইচ্ছাকৃতভাবে হোল্ড করা (`apt-mark hold`) — আপগ্রেডে
  নিঃশব্দে সফটওয়্যার রেন্ডারিংয়ে ফিরে যাওয়া ঠেকাতে। ইচ্ছা করে আনহোল্ড করুন:
  `sudo apt-mark unhold mesa-vulkan-drivers libgl1-mesa-dri libglx-mesa0 libgbm1 libegl-mesa0`।

---

## আনইনস্টল

```bash
ternux uninstall                    # প্রস্তাবিত — ইন্টারঅ্যাক্টিভ অপসারণ
# বা
curl -fsSL https://soobujmiah.github.io/ternux/uninstall.sh | bash
# বা
bash install.sh --uninstall
```

অপশনে আছে সেশন থামানো, লঞ্চার/শর্টকাট মুছে ফেলা, কন্টেইনার ডিলিট করা।
**ternux-এর সবকিছু Termux-এর স্টোরেজের ভেতরে থাকে** — Android-এর ফাইল কখনোই
ছোঁয়া হয় না। Termux-এর অ্যাপ ডেটা মুছলে সবকিছু একসাথে চলে যায়।

---

## সমস্যা?

ডেস্কটপ চালু হচ্ছে না? রেন্ডারার `llvmpipe`? শব্দ নেই?
দেখুন [সমস্যা সমাধান](TROUBLESHOOTING.html) — প্রতিটি লক্ষণের সাথে কারণ ও
সমাধান আছে।

---

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · MIT*
