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
pkg update -y && pkg upgrade -y && pkg install -y curl && bash -o pipefail -c 'curl -fsSL https://raw.githubusercontent.com/soobujmiah/ternux/main/install.sh | bash'
```

আপগ্রেডের পর curl ভেঙে গেছে? wget দিয়েও একই কাজ:

```bash
pkg update -y && pkg upgrade -y && pkg install -y wget && bash -o pipefail -c 'wget -qO- https://raw.githubusercontent.com/soobujmiah/ternux/main/install.sh | bash'
```

আংশিক upgrade-এ `pkg` বা curl চালু না হলে `apt update && apt full-upgrade -y`
চালিয়ে Termux repair করে আবার চেষ্টা করুন। Stable signed APT repository বন্ধ,
তাই `pkg install ternux` এখন পাওয়া যাচ্ছে না; RC package channel শুধু candidate
test-এর জন্য এবং hosted availability এখন যাচাই করা যায়নি।

Interactive terminal-এ প্রথমে checklist থেকে এক বা একাধিক named guest profile বাছুন: Up/Down বা `j`/`k` দিয়ে চলুন, Space বা profile number দিয়ে selection toggle করুন, তারপর Enter চাপুন। Debian সুপারিশ করা default। **Ternux v2 শুধু Debian, Ubuntu ও Alpine support করে।** একটি Adreno 825 device-এ এই তিনটির desktop, graphics, audio routing, IBus setup ও theme evidence আছে; clean Firefox install exact-main CI-তে pass করেছে। Alpine-এর synthetic Ctrl+Space event-এ অমিল আছে এবং এই evidence সব app qualify করে না। অন্য ১২টি recipe আছে, কিন্তু v2-supported নয়। পরের checklist-এ optional workload বাছুন; base desktop-এর জন্য Enter বা `0` চাপুন, অথবা দেখানো number দিন। Non-interactive run-এ `--yes` Debian base profile রাখে। [সব guest profile ও package-family recipe](INSTALLATION.html#guest-distribution-বাছাই) দেখুন।

ইনস্টলার:

1. ডিভাইস পরীক্ষা করে (আর্কিটেকচার, Android ভার্সন, স্টোরেজ, নেটওয়ার্ক);
2. Termux প্যাকেজ ইনস্টল করে (X11, PulseAudio, PRoot);
3. নির্বাচিত guest profile + Xfce4 তার PRoot কন্টেইনারে ইনস্টল করে (ডিফল্ট Debian);
4. guest profile অনুযায়ী graphics route বেছে নেয়
   (**Debian Trixie + Adreno/KGSL → Zink/Turnip** · অন্য সব named profile → **VirGL**);
5. অডিও, ফন্ট ও লোকেল কনফিগার করে;
6. লঞ্চার ও শেল শর্টকাট লিখে দেয়;
7. সবকিছু ঠিকমতো বসেছে কিনা যাচাই করে।

Installed size base-এ প্রায় **৪–৪.৫ GB**, আর `--all`-এ **১০.৫–১২.৫ GB**; download ও
cache-এর জন্য অতিরিক্ত temporary space রাখুন। একটিমাত্র স্থায়ী স্ক্রিন শেষ status
পর্যন্ত device panel, step progress ও live log window দেখায়; যে terminal সেটি
চালাতে পারে না, সেখানে plain framed log আসে। দুটিতেই পুরো আউটপুট রেকর্ড হয় —
দেখুন [ইনস্টলার স্ক্রিন](INSTALLATION.html#the-installer-screen)।

নন-ইন্টারঅ্যাক্টিভ মোডে এটি নিজেই নথিভুক্ত default ব্যবহার করে; local clone
থেকে একই default স্পষ্টভাবে নিতে `--yes` যোগ করুন। চালানোর আগে সব code দেখতে
চাইলে repository clone করুন—শুধু bootstrap পড়া যথেষ্ট নয়, কারণ standalone
route runtime-এ library module download করে।

```bash
apt update && apt full-upgrade -y && apt install git -y
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
```

```bash
tx start
```

`tx start` ধারাবাহিকভাবে চালু করে: অডিও ব্রিজ → ডিসপ্লে (`Termux:X11`) →
নির্বাচিত guest → **Xfce4**। Termux:X11 অ্যাপে যান — আপনার ডেস্কটপ সেখানেই।

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
tx start ডেস্কটপ চালু          killx  নির্বাচিত desktop session বন্ধ
tx       ternux CLI-র সংক্ষিপ্ত কমান্ড      xgo    installed GUI বাছুন
db/dbr/dbroot Debian user/root shell  ub/ubr/ubroot Ubuntu user/root shell
alp/alpr/alproot Alpine user/root shell
sysmon   ডিভাইসের সারসংক্ষেপ   clean-mesa  শেডার ক্যাশ পরিষ্কার
```

### প্রথম GUI চালু, browser ও video

Fresh install-এর পর প্রতিটি fresh install-এ base desktop-এই Firefox থাকবে; প্রথম GUI session-এ এটি দিয়ে Ternux project page খুলবে। project/developer link, guest command ও host benchmark-সহ welcome guide প্রতি guest user-এর জন্য একবারই দেখায়; পরের boot-এ website redirect হয় না। Ubuntu-তে Mozilla-র official ESR build বসে, কারণ Ubuntu archive-এর Firefox Snap চায় এবং Ternux PRoot-এ Snap বন্ধ রাখে।

নটো বাংলা ফন্ট ও আভ্রো ধ্বনিভিত্তিক কিবোর্ড ডেবিয়ান ও উবুন্টুতে আগে থেকেই থাকে; আল্পাইনে থাকে আভ্রো-সামঞ্জস্যপূর্ণ মটুন ইঞ্জিন। আইবাসের **পরের ইনপুট পদ্ধতি** শর্টকাট **কন্ট্রোল+স্পেস** দিয়ে ইংরেজি ও বাংলা লেখার পদ্ধতি বদলানো যায়। আল্পাইনের জন্য আলাদা আইবাস-আভ্রো প্যাকেজ না থাকায় চেকসাম-যাচাইকৃত উৎস থেকে মটুন ইঞ্জিন বসে; অতিরিক্ত প্যানেল বোতাম লাগে না। এক্স-ইলেভেন উইন্ডো-ফিট ব্যবস্থা বড় উইন্ডোকে পর্দার ব্যবহারযোগ্য জায়গার মাপে ছোট করে এবং নতুন উইন্ডোকে মাঝখানে রাখে। ফায়ারফক্স ব্রাউজার, ভিএলসি, পালসঅডিও ভলিউম নিয়ন্ত্রণ, এক্সএফসিই কাজের তালিকা, মাউসপ্যাড, ক্যালকুলেটর, এভিন্স পিডিএফ পাঠক, টার্নাক্স ক্যামেরা, টার্নাক্স শব্দ-রেকর্ডার, রিস্ট্রেটো ছবি-দর্শক ও **সিন্যাপটিক প্যাকেজ ব্যবস্থাপক** মূল ডেস্কটপে থাকে। অ্যাপ্লিকেশন তালিকা থেকে সিন্যাপটিক খুলে ডেবিয়ান প্যাকেজ খোঁজা, বসানো, হালনাগাদ বা সরানো যায়। পিডিএফ ডিফল্টভাবে এভিন্সে খোলে; ঐচ্ছিক লিব্রেঅফিস ড্র দিয়ে পিডিএফ পাতা সম্পাদনা ও অন্য ধরনে রপ্তানি করা যায়। কোনো ডাক-অ্যাপ ডিফল্টভাবে বসে না; দরকার হলে ঐচ্ছিক কাজের তালিকা থেকে ইভল্যুশন মেইল বেছে নিন। এতে জনপ্রিয় সেবার জন্য ওঅথ এবং হাতে আইএমএপি/পিওপি সংযোগের ব্যবস্থা আছে; ওঅথে ফায়ারফক্স ইএসআর অথবা টার্নাক্সের মাধ্যমে অ্যান্ড্রয়েডের ডিফল্ট ব্রাউজার খোলে। ডেবিয়ান, উবুন্টু ও আল্পাইনের এক্সএফসিই নিচের প্যানেলে একই আটটি চালু করার বোতাম থাকে: টার্মিনাল, ফাইল ব্যবস্থাপক, ওয়েব ব্রাউজার, অ্যাপ্লিকেশন খোঁজার সরঞ্জাম, ভিএলসি, ক্যামেরা, ছবি ও শব্দ-রেকর্ডার। ক্যামেরা, ছবি ও শব্দ-রেকর্ডারের ডেস্কটপ শর্টকাটও থাকে; টার্নাক্স ফ্ল্যাশলাইটের শর্টকাট অ্যান্ড্রয়েডের টর্চ চালু বা বন্ধ করে। সিস্টেমজুড়ে টার্নাক্সের গ্রাফাইট-এমেরাল্ড জিটিকে ২/৩/৪ নকশা, কিউটি ৫ অ্যাপের জিটিকে প্ল্যাটফর্ম নকশা, এক্সএফডব্লিউএম
window frame, GTK app-এর নিজস্ব titlebar button-এর Ternux styling, Xfce panel ও Ternux icon theme default। Base app, folder, Thunar action, category ও panel-এর জন্য original Ternux icon থাকে।
Uncommon বা পরে install করা app-এর neutral fallback হিসেবে Adwaita ব্যবহৃত হয়;
Papirus inheritance নেই। Xfce Desktop settings থেকে বেছে নেওয়ার জন্য ১৫টি portrait-first Ternux wallpaper থাকে; landscape করলেও aspect ratio ঠিক থাকে;
05 Quantum Grid default। Ternux Camera Termux:API দিয়ে Android-এর front/rear camera থেকে photo তোলে এবং capture-এর পর EXIF orientation ঠিক রেখে app-এ preview দেখায়; নিচের capture control-গুলো ছোট ও গোছানো থাকে। Termux:API app-কে Camera permission দিতে হবে। ছবি Debian PRoot-এর `~/Pictures/Ternux`-এ থাকে। Termux:API-তে সাময়িকভাবে capture তৈরি করে যাচাইয়ের পর PRoot-এ কপি করা হয়; Android Gallery-তে scan করা হয় না। Ristretto ছবিগুলো খোলে। Termux:API still photo দেয়, continuous camera stream দেয় না; তাই capture-এর আগে live feed দেখানো হয় না। Sound Recorder-এ Start চাপার আগে mic চালু হয় না; প্রথমবার Android permission চাইতে পারে। AAC/M4A (default) অথবা MP3 বেছে নিয়ে Stop and save চাপুন; MP3 Debian-এর FFmpeg দিয়ে local-এ encode হয়। Recording `~/Music/Ternux`-এ সেভ হয়। ছোট X11 screen-এ welcome guide scrollable layout ও Cairo renderer ব্যবহার করে।
PRoot-এ VAAPI/VDPAU না থাকায় VLC-তে X11 `xcb_x11` output ও software decoding
default; ছোট screen-এ compact player view ব্যবহার করে। এতে অনুপস্থিত host decoder বেছে নিয়ে video blank হওয়া এড়ায়।

### ternux CLI — ব্যবস্থাপনা ইন্টারফেস

ইনস্টলের পর `ternux` কমান্ড আপনার স্থায়ী নিয়ন্ত্রণ কেন্দ্র। নিচের পূর্ণ command
**Termux**-এ (`$PREFIX/bin/ternux`) চালান:

```bash
ternux doctor           # সিস্টেম ডায়াগনস্টিক
ternux doctor --json    # machine-readable output
ternux start            # ডেস্কটপ চালু
tx stop                 # চলমান desktop দেখুন, একটি বা একাধিক বাছুন
tx stop db              # শুধু Debian বন্ধ
tx stop ub              # শুধু Ubuntu বন্ধ
tx stop alp             # শুধু Alpine বন্ধ
tx stop --all          # সব Ternux desktop বন্ধ
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
- ঐচ্ছিক **শেয়ার্ড স্টোরেজ**: `ternux storage grant /sdcard/Folder` দিয়ে
  একটি Android folder অনুমতি দিন; default-এ user file guest-এ প্রকাশ হয় না।

## Android 12+? একটি জরুরি নোট

Android 12+ child-process policy PRoot process বন্ধ করতে পারে; memory pressure
ও OEM battery policy-তেও একই লক্ষণ হয়। ইনস্টলার readable setting ও
version-aware guidance দেখায়; safeguard বদলানোর আগে trade-off পড়ুন। বিস্তারিত:
[সমস্যা সমাধান](TROUBLESHOOTING.html#the-desktop-dies-silently)।

## ঐচ্ছিক: লোকাল CPU + Vulkan language model

প্রকাশিত ARM64 llama.cpp extension-টি prerelease। **Termux**-এ install করুন:

```bash
ternux extension install llama-vulkan
```

Debian guest-এ glibc 2.38 বা নতুন এবং OpenSSL 3 (`libssl3` বা `libssl3t64`),
`libgomp1`, `libvulkan1` লাগবে; installer download-এর আগে এগুলো যাচাই করে।

এরপর `db` দিয়ে Debian-এ যান, extension চালু করুন এবং CPU বা Vulkan বেছে নিন:

```bash
source "$HOME/.local/opt/ternux-extensions/llama-vulkan/env.sh"
llama-cli --list-devices
llama-cli -m /path/to/model.gguf -ngl 0 -p 'What is 2 + 2?' -n 8
llama-cli -m /path/to/model.gguf -dev Vulkan0 -ngl 99 -p 'What is 2 + 2?' -n 8
```

আপনার GGUF model আগের জায়গাতেই রাখুন। Vulkan-এর জন্য system Vulkan driver
কাজ করতে হবে। হাতে install, checksum ও archive যাচাই, backend-এর বিস্তারিত এবং
সমস্যা সমাধানের জন্য [repository extension guide](https://github.com/soobujmiah/ternux/blob/main/bn/guides/llama-vulkan-extension.md) দেখুন।


## ঐচ্ছিক: Stable Diffusion CPU + Vulkan image generation

Termux theke pinned image-generation runtime install korun:

```bash
ternux extension install stable-diffusion
```

Termux theke model folder grant korun, tarpor notun guest shell ba desktop restart korun:

```bash
ternux storage grant /sdcard/Llms
```

Ebar Debian-e CPU ba Adreno Vulkan model use korun:

```bash
source "$HOME/.local/opt/ternux-extensions/stable-diffusion/env.sh"
MODEL=/sdcard/Llms/ternux-v2-validation/stable-diffusion-v1-5-pruned-emaonly-Q8_0.gguf

# CPU low-resolution test, slow hote pare
sd-cli --backend cpu --model "$MODEL" --prompt "a small red robot in a garden, clean illustration" \
  --threads 4 --output /tmp/ternux-sd-cpu.png --width 256 --height 256 --steps 20 --seed 42

# Adreno GPU: 512x512-e VAE tiling dorkar
sd-cli --backend vulkan0 --model "$MODEL" --prompt "a small red robot in a garden, clean illustration" \
  --threads 4 --output /tmp/ternux-sd-vulkan.png --width 512 --height 512 --steps 10 --seed 42 \
  --vae-tiling --vae-tile-size 256x256
```

Adreno 825-e VAE tiling chara 512x512 Vulkan device-lost hoyechilo. Tiled
Extracted candidate tiled 512x512/10-step image 101.9s-e save korechilo. Public
prerelease-er por Ternux-managed install eki `/sdcard/Llms` model diye coherent
image 92.91s-e baniyeche. CPU output unqualified, support claim noy; [device
handoff](../../handoffs/stable-diffusion-cpu-vulkan-qualification-2026-11-07.md) dekhun.
Extension model ba GPU driver bundle kore na; [extension guide](https://github.com/soobujmiah/ternux/blob/main/bn/guides/stable-diffusion-vulkan-extension.md)-e limits ache.

### SM8735-এ পরীক্ষামূলক Hexagon HTP

Ternux-এ Redmi Turbo 4 Pro / SM8735-এর জন্য আলাদা experimental HTP extension
আছে; এটি supported release feature নয়। Termux থেকে
`ternux extension install llama-htp-experimental` চালান। Debian guest-এ
`libgbinder1`, `libglibutil1`, `libfastrpc1` ও `libfastrpc-dev` লাগবে। Installer-এ
HTP বেছে নিলে Ternux Debian Trixie Backports থেকে এগুলো বসায়।
Known-answer-safe setting, বর্তমান failure ও device qualification-এর অবস্থা
[repository HTP guide](https://github.com/soobujmiah/ternux/blob/main/bn/guides/llama-htp-experimental.md)-এ আছে。

## এরপর

- [ম্যানুয়াল ইনস্টলেশন](MANUAL.html) — প্রতিটি কমান্ড হাতে-কলমে, দুই GPU পথ
- [ইনস্টলেশন](INSTALLATION.html) — প্রতিটি ধাপের ব্যাখ্যা, সব অপশন, আনইনস্টল
- [ব্যবহার](USAGE.html) — Blender, লোকাল AI, ডেভেলপমেন্ট, ব্যাকআপ
- [সাধারণ প্রশ্ন](FAQ.html) — নিরাপত্তা, স্টোরেজ, ব্যাটারি, গেমিং

---

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · Apache-2.0*
