---
title: "কনফিগারেশন"
description: "ternux-এর প্রতিটি সেটিংয়ের ব্যাখ্যা: লঞ্চার এনভায়রনমেন্ট ভ্যারিয়েবল, GPU পথ, অডিও ব্রিজ, লোকেল, ফন্ট এবং প্রতিটি ফাইল কোথায় থাকে।"
lang: "bn"
alt_url: "/docs/CONFIGURATION.html"

---

ternux যুক্তিসঙ্গত ডিফল্ট নিয়ে ইনস্টল হয়, আর সবকিছু টিউন করা যায়। এই
পাতায় প্রতিটি নব, তার অবস্থান, এবং *কেন* সেটি সেভাবে সেট করা — সব ব্যাখ্যা
আছে।

---

## ইনস্টল-সময়ের পছন্দ

| সেটিং | ডিফল্ট | নোট |
|---|---|---|
| `--user NAME` | `ternux` | কন্টেইনারে তৈরি Debian ইউজার |
| `--locale LANG` | `en_US.UTF-8` | ডেস্কটপ লোকেল (বাংলার জন্য নিচে দেখুন) |
| `--backend` | `auto` | `auto` Adreno শনাক্ত করে → `zink`, নয়তো `virgl` |
| `--zsh` | বন্ধ | Termux শেলও zsh-এ বদলায় |
| `--with-*` | কিছুই না | ঐচ্ছিক ওয়ার্কলোড প্রোফাইল |

ইনস্টলের পর user বা locale বদলাতে নতুন মান দিয়ে installer **`--resume` ছাড়া**
চালান, কারণ resume state-এ সফল phase বাদ দেয়:
`bash install.sh --user X --locale bn_BD.UTF-8 --yes`। আগে backup নিন; নতুন
user তৈরি হলেও পুরনো user-এর home স্বয়ংক্রিয় migrate হয় না।

### বাংলা লোকেল

```bash
bash install.sh --locale bn_BD.UTF-8
```

এটি Debian-এর ভেতরে `bn_BD.UTF-8` লোকেল তৈরি করে এবং Noto/Symbola ফন্ট
কভারেজ ইনস্টল করে — ডেস্কটপের টার্মিনাল ও অ্যাপে বাংলা ঠিকমতো দেখায়।

---

<h2 id="installer-output">ইনস্টলার আউটপুট</h2>

ইনস্টলারের রেন্ডারার কেবল প্রদর্শনের পছন্দ। স্ক্রিন যা-ই দেখাতে পারুক, প্রতিটি
ফেজের পুরো আউটপুট `$TERNUX_LOG_DIR/ternux.log`-এ যোগ হয়।

| ভেরিয়েবল | ডিফল্ট | কাজ |
|---|---|---|
| `TERNUX_UI` | `auto` | `auto`, `dashboard`, `plain` বা `off` — `--ui`-এর মতোই মান |
| `TERNUX_NO_ANIM` | নেই | `1` দিলে স্পিনার ও রঙ বদল থেমে যায়; ড্যাশবোর্ড তবু হালনাগাদ হয় |
| `TERNUX_QUIET` | `0` | সাধারণ status বার্তা বন্ধ করে এবং ফ্রেম নিষ্ক্রিয় করে |
| `TERNUX_JSON` | `0` | যেসব কমান্ডে নথিভুক্ত, সেখানে structured output চায়; ফ্রেম নিষ্ক্রিয় করে |
| `TERNUX_YES` | নেই | `1` দিলে `--yes`-এর মতো নথিভুক্ত default প্রশ্ন ছাড়াই নেওয়া হয় |
| `TERNUX_LOG_DIR` | `$TMPDIR/ternux` | `ternux.log` ও install stream log-এর ডিরেক্টরি |
| `TERNUX_STATE_DIR` | `~/.local/share/ternux` | ফেজ state, সংরক্ষিত install পছন্দ ও profile |
| `TERNUX_COLS`, `TERNUX_ROWS` | নেই | ফ্রেমের geometry ঠিক করে দেয়; পরীক্ষা ও পুনরুৎপাদনযোগ্য transcript-এর জন্য |

রেন্ডারার কীভাবে বেছে নেওয়া হয় তা আছে
[ইনস্টলেশন → ইনস্টলার স্ক্রিন](INSTALLATION.html#the-installer-screen)-এ।

---

## লঞ্চার — `~/x.sh`

আপনার GPU পথ অনুযায়ী তৈরি হয় এবং ইনস্টলের সময় সিনট্যাক্স-চেক হয়। ইচ্ছামতো
এডিট করুন; রি-ইনস্টল করলে নতুন করে তৈরি হবে (আপনার এডিট মুছে যাবে)।

### Zink (Adreno) এনভায়রনমেন্ট

```text
MESA_LOADER_DRIVER_OVERRIDE=zink   Mesa-র Zink Gallium ড্রাইভার বাধ্যতামূলক
GALLIUM_DRIVER=zink                (একই উদ্দেশ্য, পুরনো বানান — দুটোই সেট)
TU_DEBUG=sysmem,noconform          সঠিক ডেস্কটপ GL-এর জন্য Turnip অপশন
MESA_VK_WSI_DEBUG=sw               সফটওয়্যার WSI — X11/Vulkan সারফেস সমস্যা এড়ায়
MESA_DISK_CACHE_SINGLE_FILE=1      শেডার ক্যাশ এক ফাইলে, দ্রুত ওয়ার্ম-স্টার্ট
MESA_SHADER_CACHE_MAX_SIZE=2048M   ক্যাপ — ক্যাশ যেন সব স্টোরেজ খেয়ে না নেয়
MESA_SHADER_CACHE_DIR=/tmp/mesa_cache  শেয়ার্ড tmp-তে ক্যাশ (RAM-ব্যাকড)
QT_X11_NO_MITSHM=1 / _X11_NO_MITSHM=1  MIT-SHM বন্ধ (এখানে X11-এ ভাঙা)
XDG_RUNTIME_DIR=~/.runtime         আধুনিক dbus/GTK অ্যাপের জন্য দরকারি
--bind /dev/kgsl-3d0               Adreno কার্নেল নোড কন্টেইনারে উন্মুক্ত
```

*কেন ক্যাশ টিউনিং?* ফোনের স্টোরেজ ধীর ফ্ল্যাশ; এক-ফাইল, সাইজ-ক্যাপড ক্যাশ
অ্যাপের ওয়ার্ম-স্টার্ট দ্রুত রাখে, আর Mesa-কে নিঃশব্দে গিগাবাইট গিলতে দেয় না।

### VirGL এনভায়রনমেন্ট

```text
GALLIUM_DRIVER=virpipe              GL VirGL পাইপে রুট
MESA_GL_VERSION_OVERRIDE=4.3COMPAT  অ্যাপকে আধুনিক GL ভার্সন দেখানো
MESA_GLES_VERSION_OVERRIDE=3.2
```

হোস্ট পাশের `virgl_test_server_android` কন্টেইনারের আগে শুরু হয়; ব্যর্থ হলে
লঞ্চার জোরে সতর্ক করে (নইলে সেশন নিঃশব্দে সফটওয়্যার রেন্ডারিংয়ে নামে)।

---

## অডিও

তিনটি অংশ একসাথে কাজ করে:

| কোথায় | কী |
|---|---|
| Termux `$PREFIX/etc/pulse/default.pa` | **127.0.0.1:4713**-এ TCP ব্রিজ মডিউল, OpenSL সিঙ্ক ডিফল্ট |
| লঞ্চার | কন্টেইনারের আগে `pulseaudio` শুরু, ব্রিজ লোড |
| Debian `~/.config/pulse/client.conf` | `default-server = tcp:127.0.0.1:4713` |

*কেন শুধু লুপব্যাক?* ব্রিজটি TCP দিয়ে কন্টেইনার সীমানা পাড়ি দেয়, তাই
অ্যানোনিমাস ACL দরকার — explicit `listen=127.0.0.1` service-টিকে LAN থেকে দূরে রাখে। একই ফোনের অন্য
client loopback listener-এ পৌঁছাতে পারে। Authentication ও firewall ছাড়া
listener `0.0.0.0` করবেন না।

ভিন্ন সিঙ্ক (Bluetooth, হেডফোন) চাইলে `default.pa`-র `set-default-sink`
লাইন বদলে সেশন রিস্টার্ট করুন (`killx`, তারপর `x`)।

---

## ফন্ট

Debian-এর ভেতরে ইনস্টল হয়:

- `fonts-noto-color-emoji` — ইমোজি
- `fonts-symbola`, `fonts-font-awesome`, `fonts-powerline` — সিম্বল কভারেজ
- **JetBrainsMono Nerd Font** — টার্মিনাল আইকন গ্লিফ; একবার ডাউনলোড হয়ে
  `~/.local/share/fonts`-এ যায় (সেন্টিনেল ফাইল পুনরায় ডাউনলোড ঠেকায়)

যেকোনো সময় আরও ফন্ট যোগ করুন: `~/.local/share/fonts`-এ ফাইল রেখে
`fc-cache -f` চালান।

---

## স্টেট ফাইল

| পথ | উদ্দেশ্য |
|---|---|
| `~/.ternux-state` | কোন ইনস্টলার ধাপ শেষ হয়েছে (`--resume`, `--status` এর ভিত্তি) |
| `~/.ternux-state`-এই আরও আছে | ডাউনলোড করা Turnip ড্রাইভারের SHA-256 |
| `$TMPDIR/ternux-install.log` | শেষ ইনস্টলার রানের পূর্ণ লগ |

`~/.ternux-state` মুছলে completion record হারায়। শুধু phase আবার চালাতে
`--resume` ব্যবহার করবেন না; সংশ্লিষ্ট `ternux repair` বা `--resume`-ছাড়া
installer route বেছে নিন এবং আগে backup রাখুন।

---

<h2 id="held-mesa-packages-zink-route">হোল্ড করা Mesa প্যাকেজ (Zink পথ)</h2>

```bash
db
sudo apt-mark showhold        # আশা: mesa-vulkan-drivers libgl1-mesa-dri ...
```

এগুলো হোল্ড করা যাতে সাধারণ `apt upgrade` Turnip-ব্যাকড পথকে স্টক Mesa দিয়ে
বদলে নিঃশব্দে `llvmpipe`-তে নামিয়ে না দেয়। ইচ্ছা করে আপগ্রেড করুন:

```bash
sudo apt-mark unhold mesa-vulkan-drivers libgl1-mesa-dri libglx-mesa0 libgbm1 libegl-mesa0
sudo apt upgrade
sudo apt-mark hold mesa-vulkan-drivers libgl1-mesa-dri libglx-mesa0 libgbm1 libegl-mesa0
```

…তারপর আবার রেন্ডারার স্ট্রিং যাচাই করুন (`glxinfo | grep renderer`)।

---

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · MIT*
