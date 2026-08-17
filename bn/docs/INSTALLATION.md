---
title: "ইনস্টলেশন"
description: "সম্পূর্ণ ternux ইনস্টলেশন গাইড: প্রয়োজনীয়তা, এক-কমান্ড ইনস্টলার, প্রতিটি ধাপ কী করে ও কেন, সব অপশন, এবং পরিষ্কার অপসারণ।"
lang: "bn"
alt_url: "/docs/INSTALLATION.html"

---

এটি সম্পূর্ণ গাইড। সংক্ষিপ্ত পথ চাইলে শুরু করুন
[দ্রুত শুরু](QUICK-START.html) থেকে।

> **প্রতিটি কমান্ড নিজ হাতে চালাতে চান?** সম্পূর্ণ হাতে-কলমে নির্দেশিকা —
> প্রতিটি কমান্ড, দুই GPU পথ, পুরো লঞ্চার ফাইল — আছে
> [ম্যানুয়াল ইনস্টলেশন](MANUAL.html) পাতায়। নিচের এক-কমান্ড ইনস্টলারটি
> সেই একই পাতাই, স্ক্রিপ্ট আকারে।

---

<h2 id="requirements">প্রয়োজনীয়তা</h2>

| | প্রস্তাবিত বেসলাইন | কেন জরুরি |
|---|---|---|
| **Android** | ১০ বা নতুন | পুরনো বিল্ডে Termux/X11-এর দরকারি API নেই |
| **CPU** | `aarch64` (৬৪-বিট ARM) | PRoot নেটিভ বাইনারি চালায়; ৩২-বিট ARM আপস্ট্রিমে অসমর্থিত |
| **স্টোরেজ** | Installed footprint: বেস ~৩–৪ GB; `--all`-সহ ~১০–১২ GB | Download, package cache, build tree, model ও project-এর জন্য অতিরিক্ত ফাঁকা জায়গা দিয়ে শুরু করুন |
| **RAM** | ন্যূনতম ৪ GB, ৬–৮ GB ভালো | ডেস্কটপ আর Android একই মেমরি ভাগ করে; কম RAM = বেশি প্রসেস-কিল |
| **গ্রাফিক্স** | Adreno হলে Zink/Turnip; অন্য ক্ষেত্রে VirGL candidate | Adreno route-টি মাপা; VirGL compatibility ও গতি device/Android build অনুযায়ী যাচাই করতে হবে |
| **অ্যাপ** | Termux (F-Droid/GitHub) + Termux:X11 | মূল release line ব্যবহার করুন, Termux/plugin একই source-এ রাখুন; Google Play line আলাদা ও পরীক্ষামূলক |

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
VirGL সামঞ্জস্য পথ। এর acceleration, feature coverage ও গতি ডিভাইসভেদে যাচাই করতে হবে।

উপরের storage সংখ্যা আনুমানিক **installed footprint**, temporary headroom-এর
minimum নয়। Package version ও filesystem accounting বদলায়। Clean run-এর জন্য
installer base-এ প্রায় **৬ GB free** এবং `--all`-এ **১৪ GB free** target করে,
যাতে download, cache, extraction ও build-এর জায়গা থাকে; finished installation
যথাক্রমে প্রায় **৩–৪ GB** ও **১০–১২ GB**।

---

## পদ্ধতি ১ — এক কমান্ড (প্রস্তাবিত)

```bash
curl -fsSL https://soobujmiah.github.io/ternux/install.sh | bash
```

এটি HTTPS-এ ইনস্টলার নামিয়ে চালায়। এই রিপোজিটরির সেই একই স্ক্রিপ্ট —
লুকানো কিছু নেই, কম্পাইলড কিছু নেই।

Custom installation dashboard শুরু থেকে final summary পর্যন্ত screen-এ থাকে:
live device panel, fixed step progress bar, framed scrolling log এবং animated
**Sobuj Miah** footer। আসল package output spinner-এর আড়ালে না রেখে এক লাইন করে
দেখায়, আর frame terminal-এ auto-fit হয় — font/zoom পরিবর্তন ও on-screen
keyboard-এ আবার আঁকা হয়। Capable TTY-তে persistent dashboard; redirected output,
`TERM=dumb` বা সীমিত color terminal-এ static readable frame। দুই mode-ই logging,
phase exit status, noninteractive operation ও `--resume` state অক্ষুণ্ণ রাখে।
Standalone loader bounded retry-সহ একটি validated source snapshot নামায়, তারপর
আলাদা করে প্রতিটি module request না করে bootstrap library, Termux host CLI ও
Debian guest companion-এর জন্য একই snapshot reuse করে। Package setup বর্তমান apt
source-ই রাখে এবং frame-এর ভেতর `termux-change-repo` খোলে না; source unreachable
হলে নিজে mirror বেছে `--resume` দিয়ে আবার চালান।

**আপগ্রেডের পর curl ভেঙে গেছে?** (`CANNOT LINK … SSL_set_quic_tls_transport_params`)
আংশিক আপগ্রেডে curl ও openssl সামঞ্জস্য হারিয়েছে। wget ব্যবহার করুন — একই
ইনস্টলার, আর স্ক্রিপ্ট আপনার curl নিজেই মেরামত করে দেবে:

```bash
wget -qO- https://soobujmiah.github.io/ternux/install.sh | bash
```

### পদ্ধতি ২ — সব executable অংশ পড়ুন, তারপর চালান

শুধু standalone `install.sh` পড়া পূর্ণ review নয়—চালু হলে সেটি সম্পূর্ণ repository
snapshot নামিয়ে source করে। তাই entry point ও source-করা library-গুলো একসঙ্গে
clone করে দেখুন:

```bash
pkg update -y && pkg install git -y
git clone https://github.com/soobujmiah/ternux.git
cd ternux
git log -1 --oneline                 # exact commit লিখে রাখুন
(set -e; for f in install.sh uninstall.sh bin/ternux bin/ternux-guest lib/*.sh; do bash -n "$f"; done)
less install.sh lib/core.sh lib/phases.sh lib/detect.sh lib/ui.sh
# less-এ :n দিলে পরের file, q দিলে review শেষ হবে।
bash install.sh
```

Reproducible review-এর জন্য `git fetch --tags` চালিয়ে release tag checkout করুন
এবং inspection-এর আগে `git status --short` ফাঁকা আছে কি না দেখুন। Installed result
একই হওয়ার কথা; local review route একবার confirmation চাইতে পারে। Review-এর পর
prompt না চাইলে সচেতনভাবে `--yes` দিন। বিঘ্নিত হলে `bash install.sh --resume`
চালান; successful হিসেবে recorded phase বাদ যাবে এবং interrupted run-এর saved
optional workload set restore হবে।

### পদ্ধতি ৩ — সম্পূর্ণ ম্যানুয়াল, কমান্ডে কমান্ডে

সম্পূর্ণ নিয়ন্ত্রণ চাইলে — বা ইনস্টলার নিজেই ডিবাগ করতে হলে —
[ম্যানুয়াল ইনস্টলেশন](MANUAL.html) পাতায় প্রতিটি কমান্ড খোলাসা করে আছে:
বেস প্যাকেজ, কন্টেইনার, দুই পথের GPU ড্রাইভার, সম্পূর্ণ `~/x.sh` লঞ্চার
ফাইল ও যাচাইকরণ। পদ্ধতি ১ ও ২ আপনার জন্য সেই একই ধাপগুলোই চালায়।

---

## ternux CLI — host control ও guest diagnostics

ইনস্টলের পর দুই terminal environment-এই `ternux` পাওয়া যায়, তবে entry point
দুটির দায়িত্ব ইচ্ছাকৃতভাবে আলাদা:

| Environment | Installed entry point | ভূমিকা |
|---|---|---|
| **Termux host** | `$PREFIX/bin/ternux`; module `$PREFIX/lib/ternux/`-এ | পূর্ণ diagnostics, repair, desktop lifecycle, profile, backend, update ও uninstall |
| **Debian/Xfce guest** | `/usr/local/bin/ternux` | আরেকটি PRoot না খুলে guest-local `status`, `info`, `doctor` ও `env` |

পূর্ণ control plane **Termux host terminal**-এ ব্যবহার করুন:

```bash
command -v ternux       # $PREFIX/bin/ternux
ternux --version        # ternux vX.Y.Z
ternux doctor           # সিস্টেম ডায়াগনস্টিক
ternux doctor --json    # machine-readable output
ternux start            # ডেস্কটপ চালু
ternux stop             # ডেস্কটপ বন্ধ
ternux restart          # ডেস্কটপ পুনরায় চালু
ternux repair           # সাধারণ সমস্যা সমাধান
ternux verify           # ইনস্টলেশন যাচাই
ternux benchmark        # GPU বেঞ্চমার্ক
ternux profile          # ডিভাইস প্রোফাইল
ternux backend          # GPU ব্যাকএন্ড ব্যবস্থাপনা
ternux info             # সিস্টেম তথ্য
ternux info --json      # machine-readable তথ্য
ternux logs             # লগ দেখা
ternux state            # ইনস্টলেশন অবস্থা
ternux update           # CLI আপডেট
ternux uninstall        # কম্পোনেন্ট অপসারণ
```

**Debian-এর Xfce terminal** থেকে guest-local inspection চালান:

```bash
command -v ternux       # /usr/local/bin/ternux
ternux --version        # ternux guest vX.Y.Z
ternux status
ternux info
ternux doctor
ternux env
```

Guest companion `start`, `stop`, `repair`, `update`, `uninstall`-এর মতো host-only
lifecycle command-এ usage error দিয়ে Termux-এ চালাতে বলে; এতে accidental nested
PRoot session হয় না। Installer exact installed host ও guest command execute করে
version response যাচাই করে—শুধু executable file থাকা success নয়।

Host dispatcher global flag শনাক্ত করে, কিন্তু সব command JSON schema দেয় না।
Structured output শুধু [CLI reference](CLI.html)-এ নথিভুক্ত command-এ ব্যবহার করুন।

---

<h2 id="what-the-installer-does-and-why-phase-by-phase">ইনস্টলার যা করে (এবং কেন, ধাপে ধাপে)</h2>

ইনস্টলার **এগারোটি যাচাইকৃত ধাপে** সাজানো। প্রতিটি ধাপ পরেরটি শুরুর আগে নিজের
কাজ যাচাই করে — ব্যর্থ ধাপ স্পষ্ট বার্তায় ইনস্টল থামিয়ে দেয়, "প্রায় চলে"
এমন অর্ধভাঙা ডেস্কটপ রেখে যায় না।

| # | ধাপ | কী করে | কেন |
|---|---|---|---|
| ১ | **প্রিফ্লাইট** | Termux, আর্কিটেকচার, Android ভার্সন, স্টোরেজ, নেটওয়ার্ক পরীক্ষা | এখানে ব্যর্থ হলে ডাউনলোডও নষ্ট হয় না; পরের সব ধাপ এই তথ্যের ওপর নির্ভর করে |
| ২ | **বেস প্যাকেজ** | `x11-repo`, `termux-x11-nightly`, `pulseaudio`, `proot-distro`, `virglrenderer-android`, টুলস ইনস্টল; স্টোরেজ অনুমতি | কন্টেইনারের দরকারি হোস্ট-সাইড সার্ভিস: ডিসপ্লে, শব্দ ও কন্টেইনার ইঞ্জিন |
| ৩ | **Host CLI ইনস্টলেশন** | `$PREFIX/bin/ternux` ও `$PREFIX/lib/ternux/`-এর module install করে, তারপর exact path execute করে version যাচাই | Library missing থাকলেও file থাকতে পারে; সফল execution-ই আসল host-side check |
| ৪ | **Debian + Xfce4** | Debian rootfs/desktop package ও passwordless sudo-সহ user তৈরি, `/usr/local/bin/ternux` install ও guest companion execute | Nested PRoot ছাড়াই desktop-এ safe local diagnostics; sudo ও guest command দুটোই যাচাই হয় |
| ৫ | **GPU ড্রাইভার** | Adreno: Turnip ড্রাইভার ডাউনলোড, আর্কাইভ যাচাই, ইনস্টল, Mesa প্যাকেজ পিন। অন্যান্য: VirGL হোস্ট রেন্ডারার নিশ্চিত | এটি ছাড়া সব GL অ্যাপ CPU-তে চলে (`llvmpipe`)। পিন করা থাকলে সাধারণ `apt upgrade` নিঃশব্দে GPU পথ বদলে দিতে পারে না |
| ৬ | **অডিও, লোকেল, ফন্ট** | PulseAudio ব্রিজ (শুধু লুপব্যাক), লোকেল তৈরি, ইমোজি/পাওয়ারলাইন/নার্ড ফন্ট | শব্দ TCP দিয়ে কন্টেইনার সীমানা পাড়ি দেয় — লুপব্যাকেই সীমাবদ্ধ, নেটওয়ার্কে খোলা নয়; ফন্ট টার্মিনালে "টোফু বক্স" ঠেকায় |
| ৭ | **লঞ্চার** | GPU পথ অনুযায়ী `~/x.sh` লেখা ও সিনট্যাক্স-চেক | এক কমান্ডে (`x`) অডিও → ডিসপ্লে → ডেস্কটপ নির্ভরযোগ্য ক্রমে শুরু হতেই হবে |
| ৮ | **শর্টকাট** | `x`, `killx`, `db`, `droot`, `xgo`, `sysmon`, `clean-mesa` | দৈনিক কাজ হওয়া উচিত অভ্যাস, প্রত্নতত্ত্ব নয় |
| ৯ | **ঐচ্ছিক এক্সট্রা** | ডেভ টুলস, llama.cpp, নেটওয়ার্ক টুলস, মিডিয়া টুলস, Blender — শুধু যা চেয়েছেন | বেস ইনস্টল হালকা থাকুক; প্রতিটি প্রোফাইলের স্টোরেজ/তাপের খরচ আলাদা |
| ১০ | **Android safeguard check** | readable child-process setting পরীক্ষা ও version-aware guidance | signal 9 memory pressure বা OEM battery policy-ও হতে পারে; system-wide safeguard বদলানোর আগে evidence নিন |
| ১১ | **যাচাইকরণ** | প্রতিটি গুরুত্বপূর্ণ বাইনারি, ফাইল ও অনুমতি সত্যিই আছে কিনা নিশ্চিত করা | বিশ্বাস নয়, যাচাই — `apt` সফল হওয়া প্রমাণ নয় যে ডেস্কটপ চালু হবে |

---

## ইনস্টলার অপশন

```bash
bash install.sh                     # ইন্টারঅ্যাক্টিভ — বড় ধাপের আগে প্রশ্ন করে
bash install.sh --yes               # সব ডিফল্ট মেনে নেয়, প্রশ্ন নেই
bash install.sh --user soobuj       # Debian ইউজারনাম (ডিফল্ট: ternux)
bash install.sh --locale bn_BD.UTF-8
bash install.sh --backend zink      # Zink/Turnip বাধ্যতামূলক (শুধু Adreno)
bash install.sh --backend virgl     # VirGL সামঞ্জস্য পথ বাধ্যতামূলক
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
| Qualcomm Adreno | `auto` → **zink** | Supplied Adreno setup-এ মাপা route: OpenGL → Zink → Vulkan → Turnip; নিজের renderer/workload যাচাই করুন |
| Mali / Xclipse / PowerVR / অন্যান্য | `auto` → **virgl** | সামঞ্জস্যের সম্ভাব্য পথ; renderer, acceleration ও workload ডিভাইসে যাচাই করুন |
| Adreno, কিন্তু driver route ব্যর্থ | `--backend virgl` | পরীক্ষা করার বিকল্প route; `llvmpipe` fallback হয়নি নিশ্চিত করুন |

`/dev/kgsl-3d0`-বিহীন ডিভাইসে `zink` জোর করলে GPU phase-এ launcher তৈরির
আগেই স্পষ্টভাবে ব্যর্থ হয়—নিঃশব্দে software desktop বানায় না। এই ব্যর্থতা
ইচ্ছাকৃত।

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
ternux doctor --json    # machine-readable output
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
- **Interrupted installer run:** একই reviewed script আবার download করে
  `--resume` দিন; শুধু successful হিসেবে recorded phase বাদ যাবে। এটি completed
  phase update/repair করে না—CLI-এর জন্য `ternux update`, managed artifact-এর
  জন্য `ternux repair` ব্যবহার করুন। গুরুত্বপূর্ণ data আগে backup নিন।
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

`all` মানে command-এ দেখানো চার scoped target: session বন্ধ, `~/x.sh` ও ternux
alias block অপসারণ, state/log অপসারণ এবং Debian container delete। এটি Termux
package বা installed `ternux` CLI/library uninstall করে না, shared-storage access
revocation বা repository/mirror choice restore করে না, এবং Termux `default.pa`-এর
loopback PulseAudio line ফিরিয়ে দেয় না—এগুলো আগে থেকেই থাকতে পারে বলে ইচ্ছাকৃতভাবে
রেখে দেওয়া হয়। Termux storage-এর বাইরের Android file delete হয় না। Termux app
data clear করা আলাদা nuclear option; তাতেই অবশিষ্ট Termux installation-ও মুছে যায়।

---

## সমস্যা?

ডেস্কটপ চালু হচ্ছে না? রেন্ডারার `llvmpipe`? শব্দ নেই?
দেখুন [সমস্যা সমাধান](TROUBLESHOOTING.html) — প্রতিটি লক্ষণের সাথে কারণ ও
সমাধান আছে।

---

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · MIT*
