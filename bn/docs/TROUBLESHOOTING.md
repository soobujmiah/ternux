---
title: "সমস্যা সমাধান"
description: "ternux-এর প্রতিটি সাধারণ সমস্যা, লক্ষণ অনুযায়ী সাজানো, কারণ ও সঠিক সমাধানসহ — সফটওয়্যার রেন্ডারিং, সেশন মরে যাওয়া, অডিও, নেটওয়ার্ক।"
lang: "bn"
alt_url: "/docs/TROUBLESHOOTING.html"

---

# সমস্যা সমাধান

নিচের প্রতিটি লক্ষণ বাস্তবে দেখা গেছে। ওপর থেকে নিচে কাজ করুন: টেবিলে
লক্ষণ → সম্ভাব্য কারণ → সমাধান, আর সেকশনগুলোতে পূর্ণাঙ্গ চিত্র।

| লক্ষণ | সম্ভাব্য কারণ | সমাধান |
|---|---|---|
| ডেস্কটপ নিঃশব্দে মরে যায়, বা `[Process completed (signal 9)]` | Android ফ্যান্টম প্রসেস কিলার | [ডেস্কটপ নিঃশব্দে মরে যায়](#the-desktop-dies-silently) |
| Termux:X11-এ কালো/খালি উইন্ডো | X11 অ্যাপ খোলা হয়নি, বা পুরনো সকেট | [Termux:X11-এ কালো স্ক্রিন](#black-screen-in-termuxx11) |
| `renderer string: llvmpipe` | সফটওয়্যার ফলব্যাক — GPU পথ সক্রিয় নয় | [রেন্ডারার llvmpipe বলে](#renderer-says-llvmpipe) |
| ডেস্কটপে শব্দ নেই | PulseAudio ব্রিজ চলছে না | [অডিও নেই](#no-audio) |
| Debian-এ ইন্টারনেট নেই | PRoot-এ DNS আসেনি | [কন্টেইনারে নেটওয়ার্ক নেই](#no-network-in-the-container) |
| `Waiting for Termux-X11 display socket…` থেমে থাকে | Display :0 আসেনি | [ডিসপ্লে আসছে না](#display-never-appears) |
| কিছু প্যাকেজে `apt` ব্যর্থ | Debian non-free চালু নেই | [apt ব্যর্থতা](#apt-failures) |
| `pkg upgrade`-এ `openssl.cnf` এরর, তারপর **প্রতিটি** ইনস্টল ব্যর্থ | বন্ধ stdin-এ dpkg conffile প্রম্পট | [openssl.cnf conffile ক্যাসকেড](#opensslcnf-conffile-cascade) |
| ইনস্টল কমান্ড পেস্ট করলে `No command $ found` | কপি করা টেক্সটে ডিসপ্লে-শুধু `$` প্রম্পট ঢুকে গেছে | [পেস্ট করা কমান্ড $ দিয়ে শুরু](#pasted-command-starts-with) |
| `curl: CANNOT LINK … SSL_set_quic_tls_transport_params` | আংশিক আপগ্রেড — curl/libngtcp2 openssl-এর চেয়ে নতুন | [আপগ্রেডের পর curl লিংক হতে পারে না](#curl-cannot-link-after-an-upgrade) |
| আগে সব ঠিক ছিল, আপগ্রেডের পর ভেঙে গেছে | Mesa প্যাকেজ বদলে গেছে | [আপগ্রেডের পর GPU পথ হারিয়ে গেছে](#after-an-upgrade-the-gpu-path-is-gone) |

---

## ডেস্কটপ নিঃশব্দে মরে যায় {#the-desktop-dies-silently}

**লক্ষণ:** Xfce4 ঠিকই চলছিল, তারপর সেশন (বা দীর্ঘ বিল্ড) কোনো এরর মেসেজ ছাড়াই
মরে যায়। Termux-এ আসতে পারে `[Process completed (signal 9) - press Enter]`।

**কারণ:** Android 12+ **ফ্যান্টম প্রসেস কিলার** চালু রাখে: সিস্টেমজুড়ে ~৩২টি
ব্যাকগ্রাউন্ড চাইল্ড প্রসেস হলেই — বা কোনো একটি প্রসেস অতিরিক্ত CPU খেলেই —
Android নিঃশব্দে SIGKILL করে। PRoot ডেস্কটপে ডজনখানেক প্রসেস চলে
(Xfce4 + dbus + PulseAudio + proot), তাই সীমা সহজেই ছাড়িয়ে যায়।

**সমাধান — আপনার Android ভার্সন অনুযায়ী বেছে নিন:**

- **Android 14+ (PC লাগবে না):**
  Settings → About phone → *Build number*-এ ৭ বার ট্যাপ → Developer options →
  চালু করুন **"Disable child process restrictions"** → রিবুট।
- **Android 12L/13 (PC বা root লাগবে):**
  ```bash
  adb shell settings put global settings_enable_monitor_phantom_procs false
  ```
- **রুটেড:**
  ```bash
  su -c "settings put global settings_enable_monitor_phantom_procs false"
  ```
- **ঠিক Android 12**-এ আরও দরকার:
  ```bash
  adb shell "/system/bin/device_config set_sync_disabled_for_tests persistent"
  adb shell "/system/bin/device_config put activity_manager max_phantom_processes 2147483647"
  ```

*কেন এটি ডিভাইস-স্তরের সিদ্ধান্ত:* এই সীমা Android-কে সাধারণভাবে অসভ্য
ব্যাকগ্রাউন্ড অ্যাপ থেকে বাঁচায়। এটি বন্ধ করাই Termux কমিউনিটির এই
ওয়ার্কলোডের জন্য প্রস্তাবিত পথ; বেশিরভাগ মানুষের কোনো ক্ষতি দেখা যায় না।
`bash install.sh --doctor` যেকোনো সময় আবার চেক করে দেয়।

---

## Termux:X11-এ কালো স্ক্রিন {#black-screen-in-termuxx11}

**লক্ষণ:** `x` কমান্ড চলে, কিন্তু Termux:X11-এ কালো বা খালি উইন্ডো।

**কারণ (সম্ভাবনার ক্রমে):**

1. Termux:X11 **অ্যাপটি একবারও খোলা হয়নি** — ডিসপ্লে সার্ভিসের অনুমতি
   পেতে Android-এর সেই প্রথম লঞ্চ দরকার।
2. ক্র্যাশ হওয়া সেশনের **পুরনো সকেট** — `x` সাধারণত পরিষ্কার করে, কিন্তু
   হার্ড-কিল করলে থেকে যেতে পারে।
3. ডিসপ্লে চালুর পর Xfce4 ক্র্যাশ করেছে।

**সমাধান:**

```bash
killx
# Termux:X11 অ্যাপটি একবার খুলুন, তারপর:
x
```

তবু ব্যর্থ হলে `bash install.sh --doctor --fix` চালান — এটি ডিসপ্লে প্যাকেজ,
লঞ্চার ও কন্টেইনার কোর আবার পরীক্ষা করে।

---

## রেন্ডারার llvmpipe বলে {#renderer-says-llvmpipe}

**লক্ষণ:** ডেস্কটপ চলে, কিন্তু `glxinfo | grep "renderer string"`-এ আসে
`llvmpipe`।

**কারণ:** Mesa সফটওয়্যার রেন্ডারিংয়ে নেমে গেছে। অ্যাক্সিলারেটেড পথ নেই
বা বদলে গেছে:

1. **Zink পথ:** Turnip ড্রাইভার ফাইল ইনস্টলই হয়নি, মুছে গেছে, বা কোনো
   `apt upgrade` হোল্ড করা Mesa প্যাকেজ বদলে দিয়েছে।
2. **VirGL পথ:** `virgl_test_server_android` শুরু হয়নি (লঞ্চার ঠিক এই
   বিষয়টিতেই সতর্ক করে)।
3. `/dev/kgsl-3d0` নেই এমন ডিভাইসে জোর করা `--backend zink` — প্রিফ্লাইট এটি
   প্রত্যাখ্যান করে, তাই এতদূর এলে দেখুন ইনস্টল স্টেট হার্ডওয়্যারের সাথে
   মিলছে কিনা।

**সমাধান:**

```bash
# ১. GPU ধাপ আবার চালান (আবার রিজলভ, ডাউনলোড, যাচাই):
bash install.sh --resume

# ২. Zink পথে ফাইল ও হোল্ড নিশ্চিত করুন:
db
ls -l /usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so
sudo apt-mark showhold
exit

# ৩. সেশন রিস্টার্ট করে আবার দেখুন:
killx && x
#    ডেস্কটপে:  glxinfo | grep "renderer string"
```

ডাউনলোড ব্যর্থ হলে (আপনার নেটওয়ার্ক থেকে GitHub অগম্য) ইচ্ছা করে ফলব্যাকে
যান: `bash install.sh --backend virgl --resume`।

---

## অডিও নেই {#no-audio}

**লক্ষণ:** ডেস্কটপ চলে, কিন্তু শব্দ নেই। (বা: আপডেটের পর শব্দ বন্ধ।)

**সমাধান, ক্রমে:**

```bash
# ১. অডিও ব্রিজ রিস্টার্ট করুন — লঞ্চার প্রতিটি শুরুতে এটি আবার বানায়:
killx && x

# ২. তবু নীরব? Termux-এ হোস্ট-পাশের ডেমন চেক করুন:
pulseaudio --start --exit-idle-time=-1
pactl info | head -n 3

# ৩. Debian ক্লায়েন্ট কনফিগ দেখুন:
db
cat ~/.config/pulse/client.conf    # আশা: default-server = tcp:127.0.0.1:4713
pactl info                          # একই সার্ভার রিপোর্ট করা উচিত
```

*কেন ভাঙে:* ব্রিজ হলো কন্টেইনার আর হোস্টের মধ্যে একটি TCP সংযোগ। হোস্ট পাশের
PulseAudio মরে গেলে (কিল হয়েছে, বা ক্র্যাশের পর আর শুরু হয়নি) কন্টেইনারের
কনফিগ এমন একটি পোর্টের দিকে তাকিয়ে থাকে যেখানে কেউ শুনছে না।

---

## কন্টেইনারে নেটওয়ার্ক নেই {#no-network-in-the-container}

**লক্ষণ:** Termux-এ `apt update` চলে, কিন্তু Debian-এর ভেতরে ব্যর্থ।

**কারণ:** PRoot হোস্টের নেটওয়ার্ক নেয়, তবে রিজলভার কনফিগ সবসময় নয় —
DNS-ই সাধারণ বলি।

**সমাধান (কন্টেইনারের ভেতরে):**

```bash
db
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf >/dev/null
sudo apt update
```

DHCP/Android-এর রিজলভার চাইলে `1.1.1.1`-এর বদলে আপনার রাউটারের IP দিন
(সাধারণত `192.168.0.1` / `192.168.1.1`)।

---

## ডিসপ্লে আসছে না {#display-never-appears}

**লক্ষণ:** লঞ্চার `Waiting for Termux-X11 display socket…` দেখিয়ে ৩০
সেকেন্ডে টাইমআউট করে।

**কারণ:** `termux-x11` বাইনারি সকেট বানানোর আগেই বেরিয়ে গেছে — প্রায়
সবসময়ই Termux:X11 অ্যাপ কখনো খোলা হয়নি, বা Android ফোর্স-স্টপ করেছে।

**সমাধান:**

1. Termux:X11 অ্যাপ খুলুন, এক সেকেন্ড রেখে আবার Termux-এ ফিরুন।
2. `killx && x`
3. তবু আটকে? ডিসপ্লে প্যাকেজ রি-ইনস্টল করুন:
   `pkg reinstall termux-x11-nightly -y`

---

## পেস্ট করা কমান্ড $ দিয়ে শুরু {#pasted-command-starts-with}

**লক্ষণ:** ইনস্টল কমান্ড পেস্ট করলে শেল বলে
`No command $ found, did you mean: …` — পেস্টের শুরুতে একটি `$` আছে।

**কারণ:** সাইটের `$` হলো *দেখানোর জন্য* প্রম্পট। হাতে কমান্ড লাইন সিলেক্ট
করলে আগে সেটি (আর জ্বলজ্বলে কার্সর ব্লকটিও) কপিতে ঢুকে যেত। শেল তখন সত্যিই
`$` নামের একটি কমান্ড চালাতে চায়।

**সমাধান:** **কপি বাটন** ব্যবহার করুন (বা কমান্ড লাইনে ট্যাপ করুন) — v1.1.3
থেকে সাইট হুবহু কমান্ডটিই কপি করে, প্রম্পট CSS দিয়ে আঁকা বলে সেটি সিলেক্ট
হওয়াই অসম্ভব। তবু যদি `$` পেস্ট হয়ে যায়, শুধু প্রথম অক্ষরটি মুছে এন্টার
চাপুন।

---

## আপগ্রেডের পর curl লিংক হতে পারে না {#curl-cannot-link-after-an-upgrade}

**লক্ষণ:** curl চালালে আসে
`CANNOT LINK EXECUTABLE "curl": cannot locate symbol "SSL_set_quic_tls_transport_params" referenced by …/libngtcp2_crypto_ossl.so`।

**কারণ:** **আংশিক আপগ্রেড** — `libngtcp2`/curl আপগ্রেড হয়েছে, কিন্তু
`openssl` পুরনো থেকে গেছে (সাধারণত বিঘ্নিত আপগ্রেডের ঠিক পরে; পুরনো ইনস্টলার
ভার্সনে openssl-ই সেই প্যাকেজ যা ওপরের conffile প্রম্পটে আটকে যেত)। ফলে curl
এমন একটি সিম্বল চায় যা ইনস্টল করা openssl-এ নেই।

**সমাধান — দুটি পথ:**

```bash
# পথ ক: pkg-কেই আবার সামঞ্জস্যে আনতে দিন:
pkg upgrade -y -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef
pkg reinstall -y curl openssl openssl-tool libngtcp2 libnghttp3

# পথ খ: curl বাদ দিয়ে wget দিয়ে ইনস্টলার নামান
# (wget সরাসরি openssl-এর সাথে লিংক হয়, সাধারণত চলে):
wget -qO- https://soobujmiah.github.io/ternux/install.sh | bash
```

> **curl আপগ্রেড করেও STILL ব্যর্থ?** হারানো সিম্বলটি **openssl** দেয়, curl
> নয় — নতুন curl আর পুরনো openssl যতবারই curl রি-ইনস্টল করুন না কেন,
> ব্যর্থই থাকবে। পুরো চেইন একসাথে চলতে হবে: ওপরের `pkg reinstall` লাইন (বা
> শেষ পর্যন্ত `pkg upgrade -y` — আপনার আরও বিঘ্নিত আপগ্রেড থাকতে পারে) হলো
> নিশ্চিত সমাধান।

ইনস্টলার (v1.1.4+) প্রিফ্লাইটেই ভাঙা curl শনাক্ত করে পুরো চেইন
(`curl openssl openssl-tool libngtcp2 libnghttp3`) আপগ্রেড করে, তাই পথ খ-ই
শুরু করার জন্য যথেষ্ট।

---

## openssl.cnf conffile ক্যাসকেড

**লক্ষণ:** `pkg upgrade`-এর (বা পাইপ করা ইনস্টলের) সময় দেখবেন
`*** openssl.cnf (Y/I/N/O/D/Z) [default=N] ?` তারপর
`end of file on stdin at conffile prompt`, আর তারপর থেকে **প্রতিটি** `pkg
install` একই এররে ব্যর্থ হয় — অসম্পর্কিত প্যাকেজেও।

**কারণ:** stdin বন্ধ থাকায় dpkg conffile প্রম্পটের উত্তর দিতে পারেনি।
প্যাকেজটি কনফিগার না করেই থেকে যায় এবং প্যাকেজ সিস্টেম **ভাঙা** অবস্থায়
থাকে; পরের প্রতিটি apt/dpkg অপারেশন সেই বাকি থাকা কনফিগার আবার চেষ্টা করে
আবার ব্যর্থ হয়। (ঠিক এর পরপরই `termux-x11-nightly: unable to locate` দেখলে
সেটিও সাধারণত এই একই ক্যাসকেড — x11-repo প্যাকেজটি আসলে ইনস্টলই হয়নি।)

**সমাধান:**

```bash
# ১. ভাঙা অবস্থা মেরামত করুন — পুরনো conffile স্বয়ংক্রিয় রাখা, প্রম্পট নেই:
dpkg --configure -a --force-confold --force-confdef

# ২. পরিষ্কার কিনা যাচাই করুন (কিছু প্রিন্ট করা উচিত নয়):
dpkg --configure -a --force-confold --force-confdef

# ৩. ইনস্টলার আবার চালু করুন:
bash install.sh --resume
```

*কেন এমনটা ঘটে:* Android শেলে প্রায়ই পাইপ/নন-ইন্টারঅ্যাক্টিভ চলে, তাই
dpkg-র জিজ্ঞেস করার কোনো টার্মিনাল থাকে না। ternux ইনস্টলার (v1.1.0+) এখন
প্রতিটি apt অপারেশনে `--force-confold --force-confdef` দেয় এবং ভাঙা অবস্থা
স্বয়ংক্রিয় মেরামত করে — ম্যানুয়াল ইনস্টল বা পুরনো ভার্সনের জন্যই ওপরের
সমাধানটি।

---

## apt ব্যর্থতা {#apt-failures}

**লক্ষণ:** `rar`, `p7zip-rar`, `policykit-1` বা একগুচ্ছ প্যাকেজে `apt
install` ব্যর্থ।

**কারণ:** এগুলো Debian-এর **non-free** কম্পোনেন্টে থাকে, যা ডিফল্ট PRoot
Debian রুটফসে চালু থাকে না। `polkitd` বনাম `policykit-1` হলো Debian
রিলিজভেদে নামের পার্থক্য।

**সমাধান:** ternux ইনস্টলার এগুলোকে আগে থেকেই বেস্ট-এফোর্ট ধরে। *আপনার* যদি
দরকার হয়:

```bash
db
sudo sed -i 's/ main$/ main contrib non-free non-free-firmware/' /etc/apt/sources.list
sudo apt update && sudo apt install -y rar unrar p7zip-full
```

---

## আপগ্রেডের পর GPU পথ হারিয়ে গেছে {#after-an-upgrade-the-gpu-path-is-gone}

**লক্ষণ:** রেন্ডারার ছিল `zink … Turnip`, `apt upgrade`-এর পর এখন
`llvmpipe`।

**কারণ:** হোল্ড করা Mesa প্যাকেজ আনহোল্ড হয়ে গেছে (বা হোল্ডটি এমন একটি
আপগ্রেডের পরে বসেছে যা আগেই প্যাকেজ বদলে দিয়েছে)।

**সমাধান:** `bash install.sh --resume` চালান (ড্রাইভার ও হোল্ড পুনঃপ্রয়োগ
হয়), তারপর `glxinfo` দিয়ে যাচাই করুন। অ্যাক্সিলারেশন রেখে ইচ্ছা করে Mesa
আপগ্রেড করতে চাইলে [কনফিগারেশন](CONFIGURATION.html#held-mesa-packages-zink-route)-এর
আনহোল্ড → আপগ্রেড → রি-হোল্ড → যাচাই ক্রমটি অনুসরণ করুন।

---

## চূড়ান্ত অস্ত্র: পরিষ্কার রি-ইনস্টল

```bash
bash install.sh --uninstall     # অপশন ৪: কন্টেইনার ডিলিট
rm -f ~/x.sh ~/.ternux-state
bash install.sh                 # নতুন ইনস্টল
```

কন্টেইনার ডিলিট করলে **ভেতরের সব ডেটা** যায় — আগে দামি জিনিস বের করে নিন
(দেখুন [ব্যবহার → ব্যাকআপ](USAGE.html#backups))।

---

## সমস্যা রিপোর্ট করা

[ইস্যু](https://github.com/soobujmiah/ternux/issues) খোলার সময় শুধু
পড়া-যায় এমন প্রমাণ দিন — লাইসেন্স কি, টোকেন বা প্রাইভেট ফাইল কখনোই নয়:

```bash
uname -m
getprop ro.product.manufacturer; getprop ro.product.model
getprop ro.build.version.release
bash install.sh --doctor
db -c 'glxinfo | grep "renderer string"; vulkaninfo --summary | grep -i driverName'
```

---

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · MIT*
