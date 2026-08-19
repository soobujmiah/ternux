---
title: "দ্রুত শুরু"
description: "একটি Android ফোন থেকে ternux desktop, প্রথম launch ও renderer verification পর্যন্ত সংক্ষিপ্ত পথ।"
lang: "bn"
alt_url: "/docs/QUICK-START.html"

---

চার ধাপে Android app থেকে installed desktop ও renderer check। সময় device,
mirror এবং network অনুযায়ী বদলাবে।

---

## ধাপ ১ — দুটি অ্যাপ ইনস্টল করুন

1. **Termux** — হোস্ট টার্মিনাল।
   [GitHub releases](https://github.com/termux/termux-app/releases) থেকে APK
   নামান বা [F-Droid](https://f-droid.org/en/packages/com.termux/) দিয়ে
   ইনস্টল করুন।
   *এই গাইড মূল F-Droid/GitHub release line ব্যবহার করে। Google Play line
   আলাদা পরীক্ষামূলক Android 11+ branch; Termux ও plugin একই source থেকে রাখুন।*
2. **Termux:X11** — ডেস্কটপ দেখানো অ্যাপটি।
   [GitHub releases](https://github.com/termux/termux-x11/releases) থেকে
   নামান। **একবার** খুলুন যাতে Android এটি নিবন্ধন করে, তারপর রেখে দিন।

## ধাপ ২ — একটি কমান্ড চালান

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

Installed size base-এ প্রায় **৩–৪ GB**, আর `--all`-এ **১০–১২ GB**; download ও
cache-এর জন্য অতিরিক্ত temporary space রাখুন। একটিমাত্র স্থায়ী স্ক্রিন শেষ status
পর্যন্ত device panel, step progress ও live log window দেখায়; যে terminal সেটি
চালাতে পারে না, সেখানে plain framed log আসে। দুটিতেই পুরো আউটপুট রেকর্ড হয় —
দেখুন [ইনস্টলার স্ক্রিন](INSTALLATION.html#the-installer-screen)।

নন-ইন্টারঅ্যাক্টিভ মোডে এটি নিজেই নথিভুক্ত default ব্যবহার করে; local clone
থেকে একই default স্পষ্টভাবে নিতে `--yes` যোগ করুন। চালানোর আগে সব code দেখতে
চাইলে repository clone করুন—শুধু bootstrap পড়া যথেষ্ট নয়, কারণ standalone
route runtime-এ library module download করে।

```bash
pkg install git -y
git clone https://github.com/soobujmiah/ternux.git
cd ternux
git log -1 --oneline
(set -e; for f in install.sh uninstall.sh bin/ternux bin/ternux-guest lib/*.sh; do bash -n "$f"; done)
less install.sh bin/ternux bin/ternux-guest lib/*.sh
bash install.sh
```

## ধাপ ৩ — ডেস্কটপ চালু করুন

```bash
source ~/.bashrc
x
```

`x` শর্টকাট ধারাবাহিকভাবে চালু করে: অডিও ব্রিজ → ডিসপ্লে (`Termux:X11`) →
Debian → **Xfce4**। Termux:X11 অ্যাপে যান — আপনার ডেস্কটপ সেখানেই।

## ধাপ ৪ — renderer যাচাই করুন

ডেস্কটপের ভেতরে একটি টার্মিনাল খুলুন (রাইট-ক্লিক → *Open Terminal Here*)
এবং চালান:

```bash
glxinfo | grep "renderer string"
```

| যা দেখবেন | অর্থ |
|---|---|
| `zink Vulkan (Adreno (TM) … (MESA_TURNIP))` | ✅ হার্ডওয়্যার GPU পথ (Adreno) |
| `virgl` / `virpipe` | ⚠️ VirGL সামঞ্জস্য পথ; host acceleration আলাদাভাবে যাচাই করুন |
| `llvmpipe` | ❌ সফটওয়্যার রেন্ডারিং — ঠিক করুন, মেনে নেবেন না |

`llvmpipe` দেখলে ডেস্কটপ চলবেই, কিন্তু গ্রাফিক্স শুধুই সফটওয়্যার।
দেখুন [সমস্যা সমাধান → llvmpipe](TROUBLESHOOTING.html#renderer-says-llvmpipe)।

---

## এখন আপনার যা আছে

### পুরনো শেল শর্টকাট

```text
x        ডেস্কটপ চালু          killx  সব পরিষ্কারভাবে বন্ধ
db       Debian শেল (ইউজার)    droot  রুট শেল
xgo      Termux:X11 + x একসাথে
sysmon   ডিভাইসের সারসংক্ষেপ   clean-mesa  শেডার ক্যাশ পরিষ্কার
```

### ternux CLI — ব্যবস্থাপনা ইন্টারফেস

ইনস্টলের পর `ternux` কমান্ড আপনার স্থায়ী নিয়ন্ত্রণ কেন্দ্র। নিচের পূর্ণ command
**Termux**-এ (`$PREFIX/bin/ternux`) চালান:

```bash
ternux doctor           # সিস্টেম ডায়াগনস্টিক
ternux doctor --json    # machine-readable output
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

Debian/Xfce terminal-এ `/usr/local/bin/ternux` guest-local `status`, `info`,
`doctor` ও `env` দেয়। Nested PRoot ঠেকাতে host lifecycle command প্রত্যাখ্যান
করে; `start`, `stop`, `repair` বা `update`-এর জন্য Termux-এ ফিরে যান।

ডিসপ্যাচার global flag শনাক্ত করে; JSON output শুধু নথিভুক্ত command-এ নিশ্চিত।
সম্পূর্ণ রেফারেন্স: [CLI রেফারেন্স](CLI.html)।

- কন্টেইনারে একটি পূর্ণাঙ্গ **Debian ডেস্কটপ** — এমুলেটেড নয়, ইনস্টলড।
- নির্বাচিত **OpenGL route** যাচাইয়ের tool; tested Adreno evidence Zink/Turnip দেখায়।
- ফোনের স্পিকার/হেডফোনে **শব্দ** ব্রিজড।
- Android ও Debian-এর মধ্যে **শেয়ার্ড স্টোরেজ** (Termux-এ `~/storage` ↔
  কন্টেইনারে `/sdcard`)।

## Android 12+? একটি জরুরি নোট

Android 12+ child-process policy PRoot process বন্ধ করতে পারে; memory pressure
ও OEM battery policy-তেও একই লক্ষণ হয়। ইনস্টলার readable setting ও
version-aware guidance দেখায়; safeguard বদলানোর আগে trade-off পড়ুন। বিস্তারিত:
[সমস্যা সমাধান](TROUBLESHOOTING.html#the-desktop-dies-silently)।

## এরপর

- [ম্যানুয়াল ইনস্টলেশন](MANUAL.html) — প্রতিটি কমান্ড হাতে-কলমে, দুই GPU পথ
- [ইনস্টলেশন](INSTALLATION.html) — প্রতিটি ধাপের ব্যাখ্যা, সব অপশন, আনইনস্টল
- [ব্যবহার](USAGE.html) — Blender, লোকাল AI, ডেভেলপমেন্ট, ব্যাকআপ
- [সাধারণ প্রশ্ন](FAQ.html) — নিরাপত্তা, স্টোরেজ, ব্যাটারি, গেমিং

---

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · MIT*
