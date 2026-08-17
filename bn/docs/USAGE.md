---
title: "ব্যবহার"
description: "ternux-এর দৈনন্দিন ব্যবহার: লঞ্চ নিয়ন্ত্রণ, স্টোরেজ বিন্যাস, বাস্তব ওয়ার্কলোড (Blender, লোকাল AI, ডেভেলপমেন্ট, সিকিউরিটি ল্যাব) ও ব্যাকআপ।"
lang: "bn"
alt_url: "/docs/USAGE.html"

---

# ব্যবহার

## ternux CLI — স্থায়ী ইন্টারফেস


ternux ইনস্টল হলে `ternux` কমান্ডই আপনার একমাত্র প্রবেশপথ — ইনস্টল,
ডায়াগনস্টিক, মেরামত, বেঞ্চমার্ক ও দৈনিক ডেস্কটপ ব্যবস্থাপনার জন্য।

```bash
ternux install          # সম্পূর্ণ ইনস্টলেশন
ternux start            # ডেস্কটপ চালু
ternux stop             # ডেস্কটপ বন্ধ
ternux restart          # ডেস্কটপ পুনরায় চালু
ternux doctor           # সিস্টেম ডায়াগনস্টিক
ternux doctor --json    # machine-readable diagnostic
ternux repair           # সাধারণ সমস্যা সমাধান
ternux verify           # ইনস্টলেশন যাচাই
ternux benchmark        # সংক্ষিপ্ত installation health/renderer check
ternux profile          # ডিভাইস প্রোফাইল
ternux profile save     # বর্তমান কনফিগ সেভ
ternux backend          # GPU ব্যাকএন্ড দেখা/বদলানো
ternux backend set virgl    # VirGL-এ স্যুইচ
ternux update           # ternux CLI আপডেট
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

পকেটে Linux ডেস্কটপ নিয়ে দৈনন্দিন জীবনযাপনের সবকিছু।

---

## দৈনিক নিয়ন্ত্রণ

| কমান্ড | কী করে |
|---|---|
| `x` | ডেস্কটপ শুরু (অডিও → ডিসপ্লে → Debian → Xfce4) |
| `xgo` | Termux:X11 অ্যাপ স্বয়ংক্রিয় খুলে ডেস্কটপ শুরু |
| `killx` | সেশন পরিষ্কারভাবে বন্ধ + পুরনো সকেট মুছে ফেলা |
| `db` | আপনার ইউজার হিসেবে Debian শেল |
| `droot` | রুট হিসেবে Debian শেল — সাবধানে |
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

---

## কোথায় কী থাকে (এবং কেন)

```text
Termux হোস্ট                         PRoot Debian
────────────                         ────────────
~/x.sh             লঞ্চার            /home/<user>     আপনার হোম
~/.ternux-state    ইনস্টল স্টেট      /root            রুটের হোম
~/storage/shared   Android স্টোরেজ   /sdcard          একই ফাইল, সিমলিংক
```

- **Debian হোম** কন্টেইনারের ভেতরে — `proot-distro backup`-এর সাথে যায়,
  কন্টেইনার ডিলিট হলে মুছে যায়।
- **`~/storage/shared`** (Termux) আর **`/sdcard`** (Debian) *একই* Android
  স্টোরেজ। অন্য অ্যাপে (গ্যালারি, Drive, WhatsApp) দেখা লাগবে এমন ফাইল এখানে
  রাখুন। *কেন:* কন্টেইনার Android অ্যাপের কাছে অদৃশ্য; শেয়ার্ড স্টোরেজই
  হাতবদলের জায়গা।
- **দামি সোর্স কোড** Git রিমোটেও রাখুন। ফোন হারানো সহজ, কন্টেইনার ডিলিট
  করা সহজ — GitHub নয়।

---

## ওয়ার্কলোড

### দৈনন্দিন ডেস্কটপ

ব্রাউজার, ফাইল ম্যানেজার, টার্মিনাল, এডিটর, আর্কাইভ, অফিস ডক — ডিফল্ট
Xfce4-তে সবই আছে। আরও চাইলে `sudo apt install <pkg>`।

*টিপস:* Xfce4 → Settings → Appearance-এ ডার্ক থিম আর প্যানেল অটো-হাইড করুন —
ফোনের স্ক্রিন ছোট, আর (AMOLED-এ) ডার্ক থিম ব্যাটারি বাঁচায়।

<a id="lightweight-blender"></a>
### Blender viewport কাজ

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

<a id="local-ai-with-vulkan"></a>
### Vulkan-সহ llama.cpp

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

<a id="development"></a>
### ডেভেলপমেন্ট

`--with-dev` Git, Node.js, Python (`venv` সহ) ও বিল্ড টুলস ইনস্টল করে।
কন্টেইনারে টার্মিনাল-ভিত্তিক কোডিং অ্যাসিস্ট্যান্ট চলে; অ্যাকাউন্ট ও
লাইসেন্স শর্ত আপনার আর প্রোভাইডারের মধ্যে।

*টিপস:* কন্টেইনারে (`db`) `git` চালান, তবে যেখান থেকে সুবিধা সেখানে পুশ
করুন — `/sdcard`-এ ক্লোন করলে দুই পাশই একই ফাইল দেখে।

<a id="authorised-security-lab"></a>
### অনুমোদিত সিকিউরিটি ল্যাব

`--with-network` nmap ও tmux যোগ করে। **শুধু নিজের মালিকানাধীন বা লিখিত
অনুমতিপ্রাপ্ত সিস্টেম, অ্যাপ ও নেটওয়ার্কে ব্যবহার করুন।**

*সীমা জানুন:* PRoot Debian ইউজারস্পেস দেয়, সীমাহীন ওয়্যারলেস নয়।
মনিটর মোড, প্যাকেট ইনজেকশন ও র USB অ্যাক্সেস Android-এর কার্নেল নিয়মের
আড়ালেই থাকে — নকশা অনুযায়ী।

---

<a id="backups"></a>
## ব্যাকআপ

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

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · MIT*
