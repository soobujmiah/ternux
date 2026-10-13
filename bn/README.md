---
title: "ternux"
description: "একটি কমান্ডে ARM64 ফোনেই সত্যিকারের Linux ওয়ার্কস্টেশন — Debian, Xfce4 ও যাচাইযোগ্য গ্রাফিক্স পথ। PC ছাড়া, root ছাড়া, Apache-2.0 লাইসেন্স।"
lang: "bn"
alt_url: "/README.html"
---

<div align="center">

# ternux

### একটি ARM64 ফোনেই সত্যিকারের Linux ওয়ার্কস্টেশন — PC ছাড়া, root ছাড়া, যাচাইযোগ্য গ্রাফিক্স পথ

[![সংস্করণ](https://img.shields.io/badge/version-1.4.0-00e5a0?style=flat-square)](https://github.com/soobujmiah/ternux/releases)
[![প্ল্যাটফর্ম](https://img.shields.io/badge/platform-Android%20arm64-38bdf8?style=flat-square)](https://github.com/soobujmiah/ternux)
[![লাইসেন্স](https://img.shields.io/badge/license-Apache--2.0-22c55e?style=flat-square)](../LICENSE)

[ডকুমেন্টেশন](../docs/README.md) · [দ্রুত শুরু](../docs/QUICK-START.md) · [ম্যানুয়াল ইনস্টল](../docs/MANUAL.md) · [বেঞ্চমার্ক](../docs/BENCHMARKS.md) · [সমস্যা সমাধান](../docs/TROUBLESHOOTING.md) · [কমান্ড নির্দেশিকা](../docs/CLI.md) · [ইংরেজি](../README.md)

</div>

---

**ternux** Termux ও PRoot-এর মাধ্যমে একটি ARM64 Android ফোনকে Debian + Xfce4 Linux কর্মপরিবেশে রূপান্তর করে। এতে Termux:X11 প্রদর্শন, PulseAudio, স্থায়ী `ternux` নিয়ন্ত্রণ কমান্ড এবং সমর্থিত Adreno ডিভাইসে **Zink → Turnip**, অথবা বিকল্প হিসেবে **VirGL** গ্রাফিক্স পথ থাকে।

**Android root প্রয়োজন নেই।** Debian বিদ্যমান Android kernel ব্যবহার করে; PRoot ব্যবহারকারীর স্তরে Linux পরিবেশ তৈরি করে। এটি Android-এর দ্বিতীয় kernel বা প্রচলিত ভার্চুয়াল মেশিন নয়।

![ternux স্থাপত্য](../docs/assets/ternux-overview.svg)

## শুরু করুন

| আপনার প্রয়োজন | কোথা থেকে শুরু করবেন |
|---|---|
| দ্রুত ইনস্টল | [দ্রুত শুরু](../docs/QUICK-START.md) |
| সব ধাপ নিজের নিয়ন্ত্রণে | [ম্যানুয়াল ইনস্টল](../docs/MANUAL.md) |
| ইনস্টলার কীভাবে কাজ করে | [ইনস্টলেশন](../docs/INSTALLATION.md) |
| সমস্যা সমাধান | [সমস্যা সমাধান](../docs/TROUBLESHOOTING.md) |
| কমান্ডের পূর্ণ তালিকা | [কমান্ড নির্দেশিকা](../docs/CLI.md) |
| গ্রাফিক্সের ফলাফল | [বেঞ্চমার্ক](../docs/BENCHMARKS.md) |

## কী পাবেন

- Android-এ পূর্ণাঙ্গ Debian + Xfce4 ডেস্কটপ
- Termux:X11-এর মাধ্যমে প্রদর্শন
- PulseAudio-এর মাধ্যমে অডিও
- Adreno-তে Zink → Turnip গ্রাফিক্স পথ
- অন্যান্য সমর্থিত GPU-তে VirGL সামঞ্জস্য পথ
- `ternux` CLI দিয়ে শুরু, বন্ধ, যাচাই, মেরামত, তথ্য ও লগ ব্যবস্থাপনা
- উন্নয়ন, স্থানীয় AI, মিডিয়া, নেটওয়ার্ক ও Blender-এর ঐচ্ছিক কর্মপরিবেশ

সম্পূর্ণ স্থাপত্য, তথ্যপ্রবাহ ও প্যাকেজ আচরণ [স্থাপত্য](../docs/ARCHITECTURE.md) ও [ইনস্টলেশন](../docs/INSTALLATION.md)-এ রাখা আছে।

---

## ternux + ADT

ternux হলো **Linux ডেস্কটপ/কর্মপরিবেশ স্তর**। [ADT](https://github.com/soobujmiah/adt) হলো **Android বিল্ড ও টুলচেইন স্তর**—Linux ARM64-এর জন্য বিল্ড-টুলস, প্ল্যাটফর্ম-টুলস, ADB, APK স্বাক্ষর ও ডিভাইসে ইনস্টলেশনের সরঞ্জাম।

![ternux ও ADT](../docs/assets/ternux-adt.svg)

Ternux ধীরে ধীরে mobile PRoot Linux ecosystem-এর workspace ও discovery point হচ্ছে। প্রতিটি প্রকল্পের release নিজস্ব repo-তেই রাখুন: [Ternux Releases](https://github.com/soobujmiah/ternux/releases)-এ desktop/environment ও Ternux-এর নিজস্ব artifact; [ADT Releases](https://github.com/soobujmiah/adt/releases)-এ SDK toolchain version ও তার build record। Ternux বসাতে [দ্রুত শুরু](../docs/QUICK-START.md) অথবা [পূর্ণ ইনস্টলেশন নির্দেশিকা](../docs/INSTALLATION.md) অনুসরণ করুন; ADT বসাতে Debian-এর ভেতরে তাদের [setup guide](https://github.com/soobujmiah/adt#quick-start) অনুসরণ করুন।

দুটিই একই Termux + PRoot Debian ভিত্তির সঙ্গে পাশাপাশি ব্যবহার করা যায়। তবে দুই প্রকল্পের সমন্বিত কর্মপ্রবাহ আনুষ্ঠানিকভাবে পরীক্ষা ও পরিমাপ না হওয়া পর্যন্ত **পরীক্ষামূলক**। Ternux Releases-এর পরীক্ষামূলক HTP artifact environment installer নয়; prerequisite ও অবস্থা [ইনস্টলেশন নির্দেশিকা](../docs/INSTALLATION.md#choose-the-right-project-release)-তে আছে।

---

## প্রয়োজনীয়তা

- ARM64 / aarch64 Android ডিভাইস
- ternux-এর জন্য Android 10 বা পরবর্তী সংস্করণ
- ন্যূনতম ৪ GB RAM; ডেস্কটপ + উন্নয়ন/ছোট স্থানীয় মডেলের জন্য ৬–৮ GB সুপারিশ করা হয়
- বেস ইনস্টলের জন্য প্রায় ৩–৪ GB; `--all` ব্যবহার করলে প্রায় ১০–১২ GB, এর বাইরে কাজের অতিরিক্ত স্থান
- root প্রয়োজন নেই
- ইনস্টলের সময় স্থিতিশীল নেটওয়ার্ক
- সমর্থিত Adreno ডিভাইসে নির্ধারিত Zink/Turnip পথের জন্য `/dev/kgsl-3d0` ব্যবহারযোগ্য থাকা প্রয়োজন

---

## ইনস্টল

### ১. Android অ্যাপ ইনস্টল করুন

প্রথমে **Termux** ও **Termux:X11** ইনস্টল করুন। Termux ও এর প্লাগইনের জন্য একই বিশ্বস্ত উৎস ব্যবহার করুন। বিস্তারিত উৎস ও সংস্করণ নির্দেশনা [দ্রুত শুরু](../docs/QUICK-START.md)-এ আছে।

### ২. স্বয়ংক্রিয় ইনস্টল — সবচেয়ে দ্রুত

Termux-এর ভেতরে চালান:

```bash
curl -fsSL https://soobujmiah.github.io/ternux/install.sh | bash
```

`curl` না থাকলে বা আংশিক আপগ্রেডের পর নষ্ট হলে:

```bash
wget -qO- https://soobujmiah.github.io/ternux/install.sh | bash
```

ডিফল্টভাবে ইনস্টলারটি ব্যবহারকারীর অতিরিক্ত প্রশ্ন ছাড়াই চলে: Debian ব্যবহারকারী `ternux`, লোকেল `en_US.UTF-8` এবং স্বয়ংক্রিয় ব্যাকএন্ড নির্বাচন করে। এটি ডিভাইস পরীক্ষা করে, হোস্ট ও Debian উপাদান ইনস্টল করে, গ্রাফিক্স/অডিও সাজায়, লঞ্চার তৈরি করে এবং ফলাফল যাচাই করে।

### ঐচ্ছিক: লোকাল CPU + Vulkan LLM

**Termux**-এ প্রকাশিত ARM64 prerelease install করুন:

```bash
ternux extension install llama-vulkan
```

Debian-এ extension চালু করে আগে থেকে থাকা GGUF model চালান (CPU উদাহরণ):

```bash
source "$HOME/.local/opt/ternux-extensions/llama-vulkan/env.sh"
llama-cli -m /path/to/model.gguf -ngl 0 -p 'What is 2 + 2?' -n 8
```

Vulkan command, checksum, manual install ও সমস্যা সমাধানের জন্য
[repository extension guide](https://github.com/soobujmiah/ternux/blob/main/bn/guides/llama-vulkan-extension.md) দেখুন। Website-এর
[সহজ guide](../docs/QUICK-START.md#optional-local-cpu--vulkan-language-model)-এও
সংক্ষিপ্ত setup আছে।

### ৩. চালানোর আগে পর্যালোচনা করুন

এক-কমান্ড পদ্ধতিটি বর্তমান দূরবর্তী সংস্করণ সরাসরি চালায়। সম্পূর্ণ পর্যালোচনার জন্য repository clone করুন, যাতে মূল entry script এবং ব্যবহৃত প্রতিটি module দেখা যায়:

```bash
pkg update -y && pkg install git -y
git clone https://github.com/soobujmiah/ternux.git
cd ternux
git log -1 --oneline
(set -e; for f in install.sh uninstall.sh bin/ternux bin/ternux-guest lib/*.sh; do bash -n "$f"; done)
less install.sh bin/ternux bin/ternux-guest lib/*.sh
bash install.sh
```

নির্দিষ্ট release-এ আটকে রাখতে:

```bash
git fetch --tags
git checkout <release-tag>
git status --short
(set -e; for f in install.sh uninstall.sh bin/ternux bin/ternux-guest lib/*.sh; do bash -n "$f"; done)
bash install.sh
```

### ইনস্টলারের বিকল্প

```bash
bash install.sh --backend zink --user myuser --locale en_US.UTF-8
bash install.sh --with-dev --with-llm --with-blender
bash install.sh --with-network
bash install.sh --with-media
bash install.sh --all
bash install.sh --resume
```

সমর্থিত বিকল্পের মধ্যে আরও আছে `--backend auto|zink|virgl`, `--user`, `--locale`, `--zsh`, `--with-dev`, `--with-llm`, `--with-network`, `--with-media`, `--with-blender`, `--all`, `--resume`, `--ui auto|dashboard|plain|off`, `--plain` এবং `--no-anim`।

**ইনস্টলারের সম্পূর্ণ আচরণ, ধাপ, প্রোফাইল, ইন্টারফেস, resume, update ও removal:** [ইনস্টলেশন](../docs/INSTALLATION.md)।

---

## ম্যানুয়াল ইনস্টল

প্রতিটি setup ধাপ হাতে চালাতে চাইলে repository-র রক্ষণাবেক্ষণ করা
[ম্যানুয়াল ইনস্টলেশন গাইড](../docs/MANUAL.md) দেখুন। এতে Termux, Debian, দুই
graphics route, audio, locale/font, launcher, যাচাই ও recovery বিস্তারিত আছে।

---

## প্রথম চালু ও যাচাই

```bash
source ~/.bashrc
```

```bash
x
```

অথবা:

```bash
xgo
```

Termux:X11 অ্যাপ খুলুন, তারপর প্রকৃত renderer যাচাই করুন:

```bash
glxinfo -B
```

```bash
vulkaninfo --summary
```

```bash
pactl info
```

সম্ভাব্য গ্রাফিক্স ফলাফল:

```text
OpenGL renderer string: zink ... Adreno ... MESA_TURNIP
```

অথবা:

```text
virgl / virpipe
```

`llvmpipe` মানে CPU-ভিত্তিক সফটওয়্যার রেন্ডারিং। বেঞ্চমার্কের আগে [সমস্যা সমাধান](../docs/TROUBLESHOOTING.md) দেখে কারণ নির্ণয় করুন।

দৈনন্দিন শর্টকাট:

```text
x       ডেস্কটপ চালু
xgo     Termux:X11 খুলে ডেস্কটপ চালু
killx   ডিসপ্লে/অডিও বন্ধ ও পুরোনো session ফাইল পরিষ্কার
db      নিয়মিত ব্যবহারকারী হিসেবে Debian শেল
droot   root হিসেবে Debian শেল
```

প্রধান নিয়ন্ত্রণ কমান্ড:

```bash
ternux start
ternux stop
ternux restart
ternux verify
ternux doctor
ternux repair
ternux info
ternux logs
```

Debian guest-এর companion command guest-এর ভেতরের কাজ দেয় এবং nested PRoot তৈরি করতে পারে এমন host lifecycle command প্রত্যাখ্যান করে। [কমান্ড নির্দেশিকা](../docs/CLI.md)-তে বিস্তারিত আছে।

---

## ভেতরে কী আছে?

| স্তর | কাজ |
|---|---|
| Termux + PRoot | Android host ও Debian userspace |
| Debian ARM64 | GNU/Linux ভিত্তি |
| Xfce4 + Termux:X11 | ডেস্কটপ ও প্রদর্শন |
| PulseAudio | Android অডিও সেতু |
| Zink → Turnip → KGSL | Adreno OpenGL/Vulkan গ্রাফিক্স পথ |
| VirGL | সামঞ্জস্যপূর্ণ গ্রাফিক্স পথ |
| `ternux` CLI + `~/x.sh` | lifecycle, diagnostics, repair ও benchmark |

ভিত্তিগত অ্যাপের মধ্যে Xfce Terminal, VLC, archive tools, Mesa utilities ও Vulkan tools রয়েছে। উন্নয়ন, LLM, media, network ও Blender কর্মপরিবেশ ঐচ্ছিক।

সম্পূর্ণ স্থাপত্য ও প্যাকেজ আচরণের জন্য [স্থাপত্য](../docs/ARCHITECTURE.md) এবং [ইনস্টলেশন](../docs/INSTALLATION.md) দেখুন।

---

## প্রমাণ

গ্রাফিক্স benchmark snapshot একটি **Redmi Turbo 4 Pro / Snapdragon 8s Gen 4 / Adreno 825** ডিভাইসের; সেখানে renderer দেখা গিয়েছিল:

```text
zink Vulkan 1.4(Adreno (TM) 825 (MESA_TURNIP))
```

প্রাপ্ত ফলাফলের মধ্যে আছে:

- `glmark2`: **140** aggregate score; রিপোর্ট করা scene range **45–164 FPS**
- `glmark2-es2 --off-screen`: **364** aggregate score; রিপোর্ট করা scene range **53–465 FPS**, DRI3 warning-সহ
- Blender 4.3.2: Zink/Turnip OpenGL viewport পথ পর্যবেক্ষিত; Cycles GPU rendering প্রতিষ্ঠিত নয়
- llama.cpp ARM64 b11582 prerelease: একই model/prompt-এ CPU ও Adreno Vulkan known-answer pass; Vulkan-এ ২৯/২৯ layer assign হয়েছে। এতে HTP correctness, clean-device driver setup বা দীর্ঘ সময়ের performance প্রতিষ্ঠিত হয় না। তারিখসহ [accelerator release plan](../docs/ACCELERATOR-RELEASE-PLAN.md) দেখুন।
- stable-diffusion.cpp: Vulkan build path রিপোর্ট করা হয়েছে; prompt-to-image runtime এখনও unverified।

এগুলো নির্দিষ্ট ডিভাইসের প্রমাণ, সর্বজনীন performance guarantee নয়। দুই ধরনের glmark2 ফলাফলকে speed ratio হিসেবে তুলনা করা উচিত নয়। সম্পূর্ণ scene value, পদ্ধতি, caveat ও বাকি measurement [বেঞ্চমার্ক](../docs/BENCHMARKS.md)-এ আছে।

---

## সীমাবদ্ধতা ও নিরাপত্তা

- PRoot ভার্চুয়াল মেশিন নয়; Debian Android-এর kernel ভাগ করে ব্যবহার করে।
- Guest root, Android root নয়; kernel module, বাস্তব systemd boot ও unrestricted hardware access পাওয়া যায় না।
- GPU support ডিভাইসভেদে বদলায়; VirGL সমান performance-এর নিশ্চয়তা নয়।
- OpenGL renderer দেখা গেলেই Blender Cycles, llama.cpp বা diffusion GPU offload প্রমাণ হয় না।
- দীর্ঘ সময় build/inference/rendering করলে তাপ, throttling, battery drain বা Android process management হতে পারে।
- ধ্বংসাত্মক কাজের আগে গুরুত্বপূর্ণ data backup নিন: `proot-distro backup debian --output ~/debian.tar.gz`।
- প্রমাণিত authentication ছাড়া স্থানীয় development/AI service `127.0.0.1`-এর বাইরে প্রকাশ করবেন না।

আরও বিস্তারিত নিরাপত্তা, গ্রাফিক্স, storage, heat ও troubleshooting নির্দেশনা [সাধারণ প্রশ্ন](../docs/FAQ.md), [কনফিগারেশন](../docs/CONFIGURATION.md), [স্থাপত্য](../docs/ARCHITECTURE.md) ও [সমস্যা সমাধান](../docs/TROUBLESHOOTING.md)-এ রয়েছে।

---

## আনইনস্টল

```bash
ternux uninstall
```

অথবা clone করা repository থেকে:

```bash
bash uninstall.sh
```

প্রথমে Debian backup নিন। নথিভুক্ত `all` removal ternux session/container, launcher/alias এবং ternux state/logs লক্ষ্য করে; সম্পর্কহীন Termux package, repository/storage নির্বাচন ও Termux PulseAudio configuration ইচ্ছাকৃতভাবে রেখে দেয়। সঠিক আচরণ ও বিকল্পের জন্য [ইনস্টলেশন নির্দেশিকা](../docs/INSTALLATION.md) এবং `uninstall.sh` দেখুন।

---

## ডকুমেন্টেশন মানচিত্র

- [ডকুমেন্টেশন পরিচিতি](../docs/README.md)
- [দ্রুত শুরু](../docs/QUICK-START.md)
- [ইনস্টলেশন](../docs/INSTALLATION.md)
- [ম্যানুয়াল ইনস্টলেশন](../docs/MANUAL.md)
- [ব্যবহার](../docs/USAGE.md)
- [কনফিগারেশন](../docs/CONFIGURATION.md)
- [সমস্যা সমাধান](../docs/TROUBLESHOOTING.md)
- [স্থাপত্য](../docs/ARCHITECTURE.md)
- [বেঞ্চমার্ক](../docs/BENCHMARKS.md)
- [সাধারণ প্রশ্ন](../docs/FAQ.md)
- [কমান্ড নির্দেশিকা](../docs/CLI.md)
- [অবদান](../CONTRIBUTING.md)
- [নিরাপত্তা](../SECURITY.md)

Termux, Termux:X11, PRoot, Mesa/Zink, glmark2, Blender, llama.cpp ও stable-diffusion.cpp-এর গভীর কারিগরি রেফারেন্সগুলো ডকুমেন্টেশন ও upstream-reference অংশে সংরক্ষিত আছে।

---

## লাইসেন্স

[Apache-2.0](../LICENSE) © 2026 [Sobuj Miah (@soobujmiah)](https://github.com/soobujmiah)
