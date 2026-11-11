---
title: "ব্যবহার"
description: "ternux-এর দৈনন্দিন ব্যবহার: লঞ্চ নিয়ন্ত্রণ, স্টোরেজ বিন্যাস, বাস্তব ওয়ার্কলোড (Blender, লোকাল AI, ডেভেলপমেন্ট, সিকিউরিটি ল্যাব) ও ব্যাকআপ।"
lang: "bn"
alt_url: "/docs/USAGE.html"

---

পকেটে Linux ডেস্কটপ নিয়ে দৈনন্দিন জীবনযাপনের সবকিছু।

---

## ব্যাকগ্রাউন্ড ডেস্কটপ সেশন

`tx` হলো `ternux`-এর ছোট alias। একাধিক guest থাকলে `xgo` installed guest-গুলোর তালিকা দেখিয়ে GUI বাছতে বলে। `db`/`dbr`, `ub`/`ubr`, `alp`/`alpr`, `archx`/`archroot`, `fed`/`fedr`, `suse`/`suser`, `vsh`/`vroot`, `kal`/`kalr` user/root shell shortcut। অন্য guest-এ `tx distro shell NAME` ব্যবহার করুন।

`tx start` desktop-কে managed background session হিসেবে চালু করে এবং নিজের X11
window ready হলে prompt-এ ফিরে আসে। প্রতিটি configured guest আলাদা tagged display ব্যবহার করে, তাই একাধিক profile পাশাপাশি
চলতে পারে। Startup output `~/.local/share/ternux/session/desktop.log`-এ থাকে;
1 MiB হলে আগের log rotate হয়। `tx status`, `tx stop` বা `tx logs desktop tail`
দিয়ে session দেখুন, বেছে বন্ধ করুন বা log পড়ুন। `tx stop --all` সব বন্ধ করে। Android memory pressure-এ background process বন্ধ
করতে পারে; এমন হলে Termux:X11 আবার খুলুন।

### Termux:X11-এ কিবোর্ড ইনপুট

Android soft keyboard থেকে terminal ও অন্য X11 app-এ text পাঠাতে Ternux desktop শুরুর আগে Termux:X11-এর `enforceCharBasedInput` চালু করে। `~/x.sh` সরাসরি চালালেও setting-টি apply হয়। Upgrade-এর পরও input না এলে একবার `ternux restart` দিন, যাতে নতুন setting-সহ X11 server শুরু হয়।

## দৈনিক নিয়ন্ত্রণ

| কমান্ড | কী করে |
|---|---|
| `x` | `ternux start` দিয়ে ডেস্কটপ শুরু করে Termux:X11 সামনে আনে (অডিও → ডিসপ্লে → Debian → Xfce4) |
| `xgo` | Installed guest দেখিয়ে Ternux desktop বাছতে দেয় |
| `killx` | চলমান desktop থেকে একটি বা একাধিক বেছে বন্ধ |
| `db` / `dbr` | Debian user / root shell |
| `ub` / `ubr` | Ubuntu user / root shell |
| `alp` / `alpr` | Alpine user / root shell |
| `tx` | `ternux` CLI-র ছোট alias |
| `sysmon` | CPU/RAM/GPU-নোডের দ্রুত চিত্র |
| `clean-mesa` | শেডার ক্যাশ পরিষ্কার (ড্রাইভার বদলের পর) |

**স্বাস্থ্যকর শুরু-শেষ রুটিন:**

1. `xgo` দিয়ে শুরু করুন (বা আগে Termux:X11 খুলে তারপর `x`)।
2. ডেস্কটপে অ্যাপগুলো স্বাভাবিকভাবে বন্ধ করুন।
3. শেষে: Xfce4 থেকে লগ আউট করুন (Applications → Log Out), বা Termux পাশ
   থেকে `killx` চালান। এতে সকেট পরিষ্কার হয়, পরের শুরু নিখুঁত হয়।

*কেন এত কসরত?* পড়ে থাকা X11 সকেট বা জম্বি PulseAudio প্রসেস পরের সেশনকে
মৃত সার্ভিসের ওপর "শুরু" করিয়ে দেয় — ডেস্কটপ আসে, কিন্তু অডিও বা ডিসপ্লে
অদ্ভুত আচরণ করে। `x` প্রতিটি শুরুতে এগুলো পরিষ্কার করে, তাই পরিষ্কার শেষ
করার আসল লাভ ব্যাটারি বাঁচানো।

### Android microphone input

Desktop-এ PulseAudio-এর OpenSL ES source দিয়ে Android mic guest app-এ পাওয়া
যায়। Guest app প্রথম capture চাইলে Android Termux-এর microphone permission
চাইতে পারে; দরকার হলে **Settings → Apps → Termux → Permissions → Microphone**
অনুমতি দিন। Idle অবস্থায় কোনো recording শুরু হয় না; guest app capture চাইলে
source ব্যবহৃত হয়। Volume Control খোলা থাকলে live input meter দেখানোর জন্য
সেটিও source পড়ে; app বন্ধ করলে stream ছেড়ে দেয় এবং source আবার idle হয়। Idle
desktop mic record করতে থাকে না। Termux:API-এর `termux-microphone-record` কেবল
file-এ record করে, live PulseAudio input stream দেয় না—তাই desktop-এর mic source
সেটি নয়। Capture চলার সময় Android-এর microphone privacy indicator দেখা যায়। Default Ternux Sound Recorder Start চাপার পরই capture করে; AAC/M4A default, চাইলে Debian-এর FFmpeg দিয়ে local MP3 export করে। File `~/Music/Ternux`-এ থাকে।

Install-এর সময় Android Termux:API app-এর microphone permission চাওয়ার জন্য
একবার private temporary file-এ সর্বোচ্চ এক সেকেন্ডের probe চলে; শেষে probe থেমে
file মুছে যায়। এটি Termux:API app-এর permission—Termux app-এর OpenSL ES source
permission আলাদা। Desktop-এর live input এখনও on-demand OpenSL ES source-ই ব্যবহার
করে; Termux:API command live PulseAudio stream দেয় না।

Xfce-এর **About → System** page CPU model name পড়ে `/proc/cpuinfo` থেকে।
Android সেখানে শুধু ARM part ID দিলে Ternux launcher live `lscpu` থেকে চেনা
model name যোগ করে এবং Android SoC identifier দেখায়। অচেনা model অনুমান না করে
unavailable হিসেবে দেখানো হয়।

### অডিও ও VLC কন্ট্রোল

Fresh install-এ Xfce জুড়ে Ternux-এর graphite-emerald GTK 2/3/4 ও Xfwm theme এবং Qt 5 GTK platform theme, neutral Adwaita fallback-সহ branded app, folder, Thunar action, category ও panel icon, Ternux panel এবং wallpaper default apply হয়। Firefox ESR, Blender, GIMP, Krita, Inkscape, Audacity, Geany ও LibreOffice-এর মতো optional GUI app-এর branded icon alias আছে; base Evince PDF reader-এরও নিজস্ব icon আছে। Common Thunar action-গুলো নিজস্ব icon context-এ থাকে। পনেরোটি portrait-first wallpaper landscape-এ aspect ratio ঠিক রাখে। অন্য toolkit ব্যবহার করা app নিজস্ব styling রাখতে পারে। PulseAudio Volume Control Debian-এর packaged application entry ও একই desktop session ব্যবহার করে। Termux:X11 session-এ Xfwm compositing বন্ধ থাকে, কারণ এটি চালু থাকলে পুরো desktop black হতে পারে। VLC ডিফল্টে full interface চালায়, তাই playback control দেখা যায়। Android storage default-এ mount হয় না। `ternux storage grant /sdcard/Folder` দিয়ে একটি folder অনুমতি দিন; তারপর desktop shortcut শুধু অনুমোদিত folder-গুলো খুলবে।

## XFCE Task Manager-এর performance

কম resource-এর Android device-এ process scan কমাতে Task Manager শুরুতে বর্তমান user-এর process list, flat view এবং এক সেকেন্ডের refresh interval ব্যবহার করে। System বা অন্য user-এর process দেখতে **Show all processes** চালু করুন। এই default একবারই apply হয়; পরের preference overwrite করে না।

---

## ternux CLI — স্থায়ী ইন্টারফেস

ternux ইনস্টল হলে `ternux` কমান্ডই আপনার একমাত্র প্রবেশপথ — ইনস্টল,
ডায়াগনস্টিক, মেরামত, বেঞ্চমার্ক ও দৈনিক ডেস্কটপ ব্যবস্থাপনার জন্য।

```bash
tx distro list         # সব installed guest ও desktop recipe status
tx distro search alpine # OCI image খুঁজুন
ternux install --distros debian,ubuntu  # দুটো আলাদা guest install
tx start                 # saved guest চালু
tx start ubuntu         # Ubuntu চালু
tx stop ubuntu           # Ubuntu বন্ধ
tx restart               # ডেস্কটপ পুনরায় চালু
ternux doctor           # সিস্টেম ডায়াগনস্টিক
ternux doctor --json    # machine-readable diagnostic
ternux repair           # সাধারণ সমস্যা সমাধান
ternux verify           # ইনস্টলেশন যাচাই
ternux benchmark        # সংক্ষিপ্ত installation health/renderer check
ternux profile          # ডিভাইস প্রোফাইল
ternux profile save     # বর্তমান কনফিগ সেভ
ternux backend          # GPU ব্যাকএন্ড দেখা/বদলানো
ternux backend set virgl    # VirGL-এ স্যুইচ
ternux gpu update           # যাচাইকৃত Debian Turnip driver refresh
ternux update           # সর্বশেষ stable release tag থেকে CLI আপডেট
ternux logs             # লগ ফাইল দেখা
ternux info             # সিস্টেম তথ্য
ternux info --json      # machine-readable তথ্য
ternux state            # ইনস্টলেশন অবস্থা
ternux uninstall        # কম্পোনেন্ট অপসারণ
```

ডিসপ্যাচার global flag শনাক্ত করে, তবে সব command JSON output দেয় না।
নথিভুক্ত schema-এর জন্য [CLI reference](CLI.html) দেখুন।

### Structured JSON output

গুরুত্বপূর্ণ কমান্ডগুলো AI অ্যাসিস্ট্যান্ট ও অটোমেশনের জন্য JSON আউটপুট দেয়:

```bash
ternux doctor --json | jq '.issues[]'
ternux info --json | jq '.gpu, .backend, .renderer'
ternux benchmark --json | jq '.glmark2_score, .vkmark_score'
```

---

## কোথায় কী থাকে (এবং কেন)

```text
Termux হোস্ট                         PRoot Debian
────────────                         ────────────
~/x.sh             লঞ্চার            /home/<user>     আপনার হোম
~/.ternux-state    ইনস্টল স্টেট      /root            রুটের হোম
~/storage/shared   Android স্টোরেজ   /sdcard          একই স্টোরেজ; guest access opt-in
```

- **Debian হোম** কন্টেইনারের ভেতরে — `proot-distro backup`-এর সাথে যায়,
  কন্টেইনার ডিলিট হলে মুছে যায়।
- **`~/storage/shared`** (Termux) আর **`/sdcard`** (Debian) Android shared
  storage-কে বোঝায়। Ternux default-এ এটি mount করে না। নির্দিষ্ট folder-এর জন্য
  `ternux storage grant /sdcard/Folder` চালান; revoke করতে
  `ternux storage revoke /sdcard/Folder` ব্যবহার করুন।
- **দামি সোর্স কোড** Git রিমোটেও রাখুন। ফোন হারানো সহজ, কন্টেইনার ডিলিট
  করা সহজ — GitHub নয়।

---

## ওয়ার্কলোড

### দৈনন্দিন ডেস্কটপ

ব্রাউজার, ফাইল ম্যানেজার, টার্মিনাল, এডিটর, আর্কাইভ, অফিস ডক — ডিফল্ট
Xfce4-তে সবই আছে। আরও চাইলে `sudo apt install <pkg>`।

*টিপস:* Xfce4 → Settings → Appearance-এ ডার্ক থিম আর প্যানেল অটো-হাইড করুন —
ফোনের স্ক্রিন ছোট, আর (AMOLED-এ) ডার্ক থিম ব্যাটারি বাঁচায়।

<h3 id="lightweight-blender">Blender viewport কাজ</h3>

`bash install.sh --with-blender` দিয়ে install, desktop start, তারপর Debian
terminal-এ:

```bash
blender
```

Captured Blender 4.3.2 system report renderer হিসেবে
`zink Vulkan 1.4(Adreno (TM) 825 (MESA_TURNIP))` দেখেছে। এটি X11 **OpenGL
viewport route**-এর evidence; Cycles GPU result নয়। একই report-এ device type
`SOFTWARE` এবং কোনো Cycles GPU device ছিল না। Scene modest রাখুন, ঘনঘন save
করুন, archived glmark2 score থেকে render speed অনুমান করবেন না।

নিজের baseline record করুন:

```bash
glxinfo -B | tee ~/blender-gl-baseline.txt
blender --version | tee ~/blender-version.txt
```

### Adreno GPU-তে Blender render

প্রতিষ্ঠিত Termux/PRoot Redmi workstation-এ default render path হলো
**Zink/Turnip দিয়ে GPU offload-সহ EEVEE Next**। এই device-এ Cycles GPU
প্রমাণিত নয়। `--with-blender` Xvfb-ও install করে। Headless render-এ X11 GL
context দরকার: virtual display চালু করে Blender-এ দুইটি environment variable
দিন:

```bash
Xvfb :9 -screen 0 1280x720x24 &
DISPLAY=:9 GALLIUM_DRIVER=zink blender -b --factory-startup --python render.py
```

`DISPLAY` বা `GALLIUM_DRIVER=zink` বাদ দেবেন না: মাপা setup-এ এই path ছাড়া
GPU render হয়নি। দীর্ঘ run-এর আগে `glxinfo -B`-তে Zink / Adreno / Turnip
renderer যাচাই করুন। সম্পূর্ণ reproducible workflow ও সীমা [cartoon pipeline
guide-এ](https://github.com/soobujmiah/ternux/blob/main/experiments/cartoon-pipeline/README.md)
আছে।
Agent দিয়ে local MCP-তে render চালানোর জন্য [Blender GPU MCP guide](BLENDER-MCP.html) দেখুন।

<h3 id="local-ai-with-vulkan">Vulkan-সহ llama.cpp</h3>

`--with-llm` Debian-এর ভেতরে llama.cpp Vulkan backend build করে। ব্যবহার করার
অধিকার আছে এমন GGUF model দিন, তারপর binary/device ও performance আলাদা করুন:

```bash
db
cd ~/llama.cpp
./build/bin/llama-cli --list-devices
./build/bin/llama-cli -m /path/to/model.gguf -ngl 99 \
  -p "Zink দুই বাক্যে ব্যাখ্যা করুন।" -n 128
./build/bin/llama-bench -m /path/to/model.gguf -ngl 99
```

Submitted note সফল Vulkan build/use report করে, reproducible token-rate table
নয়। `--list-devices` capability evidence; `llama-bench` performance evidence।
Exact model/quantisation, context, GPU layer, commit, prompt/prefill ও generation
rate, memory এবং temperature সংরক্ষণ করুন। কোনো model size সব ৬–৮ GB ফোনে
চলার guarantee নেই—Android, desktop, model weight, KV cache ও Vulkan allocation
একই RAM ভাগ করে।

### Vulkan-সহ stable-diffusion.cpp

এটি installer profile নয়, manual developer workload। Submitted note শুধু
Vulkan-enabled build সম্পন্ন হওয়া report করে:

```bash
db
sudo apt update
sudo apt install -y git cmake build-essential libvulkan-dev \
  glslang-tools glslang-dev

git clone --recursive https://github.com/leejet/stable-diffusion.cpp.git
cd stable-diffusion.cpp
cmake -S . -B build -DSD_VULKAN=ON -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release -j2
./build/bin/sd-cli --help
```

Successful build image generation বা speed প্রমাণ করে না। Defensible result-এর
জন্য exact model/commit, resolution, step, sampler, seed, command, elapsed time,
peak memory, temperature ও output image record করুন। Low resolution ও এক image
দিয়ে শুরু করুন; অস্বস্তিকর তাপ বা Android process reclaim হলে থামুন।

<h3 id="development">ডেভেলপমেন্ট</h3>

`--with-dev` Git, Node.js, Python (`venv` সহ) ও বিল্ড টুলস ইনস্টল করে।
কন্টেইনারে টার্মিনাল-ভিত্তিক কোডিং অ্যাসিস্ট্যান্ট চলে; অ্যাকাউন্ট ও
লাইসেন্স শর্ত আপনার আর প্রোভাইডারের মধ্যে।

*টিপস:* কন্টেইনারে (`db`) `git` চালান, তবে যেখান থেকে সুবিধা সেখানে পুশ
করুন। Guest-এ Android shared storage কেবল নির্দিষ্ট directory grant করার পর দেখা যায়।

<h3 id="authorised-security-lab">অনুমোদিত সিকিউরিটি ল্যাব</h3>

`--with-network` nmap ও tmux যোগ করে। **শুধু নিজের মালিকানাধীন বা লিখিত
অনুমতিপ্রাপ্ত সিস্টেম, অ্যাপ ও নেটওয়ার্কে ব্যবহার করুন।**

*সীমা জানুন:* PRoot Debian ইউজারস্পেস দেয়, সীমাহীন ওয়্যারলেস নয়।
মনিটর মোড, প্যাকেট ইনজেকশন ও র USB অ্যাক্সেস Android-এর কার্নেল নিয়মের
আড়ালেই থাকে — নকশা অনুযায়ী।

---

<h2 id="backups">ব্যাকআপ</h2>

```bash
# Termux-এ — পুরো কন্টেইনারের স্ন্যাপশট:
proot-distro backup debian --output ~/debian-backup.tar.gz

# রিস্টোর:
proot-distro restore debian ~/debian-backup.tar.gz

# Android-পাশের ফাইলও আলাদা রাখুন — এগুলো কন্টেইনার ব্যাকআপে থাকে না:
tar -czf ~/storage-backup.tar.gz -C ~/storage/shared .
```

*কখন ব্যাকআপ করবেন:* যাচাইকৃত ইনস্টলের পরপরই (আপনার পরিচিত-ভালো বেসলাইন),
বড় পরীক্ষার আগে, আর `apt dist-upgrade`-এর আগে।

---

## পাওয়ার, তাপ ও দীর্ঘায়ু

- Sustained compute-এর সঙ্গে fast charging দুইটি heat source যোগ করে। Charged
  battery দিয়ে শুরু করুন; দ্রুত গরম হলে charger খুলুন, heat-trapping case
  সরান, brightness কমান এবং খোলা বাতাসে ঠান্ডা হতে দিন। freezer/ice বা
  condensation-prone cooling ব্যবহার করবেন না।
- Bounded work বেছে নিন: `cmake --build build -j2`, একবারে এক image, modest
  Blender scene এবং benchmark repetition-এর মাঝে বিরতি। বেশি thread সময়
  কমাতে পারে, কিন্তু peak heat ও memory pressure বাড়ায়।
- Termux:API app/package থাকলে `termux-battery-status` battery-temperature field
  দেখাতে পারে; এটি SoC junction temperature নয়, শুধু একটি sensor। Android
  thermal warning, sudden clock/FPS drop, charging pause, instability বা ধরতে
  অস্বস্তিকর case—যেকোনোটি হলে workload থামিয়ে ঠান্ডা করুন।
- Android 12+-এ killed build মানেই phantom policy নয়। Memory pressure ও OEM
  battery restriction আগে দেখুন, তারপর [evidence-led troubleshooting](TROUBLESHOOTING.html#the-desktop-dies-silently)।
- Launcher desktop চলাকালে wake-lock ধরে ও exit-এ ছাড়ে। Idle হলে session শেষ
  করুন; wake-lock sleep আটকায় এবং battery খরচ করে।
- দীর্ঘ render/generation, বড় build এবং বিশেষত mining ফোনের খারাপ workload।
  Archived result sustained performance বা universally safe runtime প্রমাণ করে না।

---

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · Apache-2.0*
