---
title: "সমস্যা সমাধান"
description: "ternux failure-এর evidence-led diagnosis ও নিরাপদ repair path — rendering, session, audio, network ও clean reinstall।"
lang: "bn"
alt_url: "/docs/TROUBLESHOOTING.html"

---

# সমস্যা সমাধান

টেবিলটি সাধারণ symptom-কে সম্ভাব্য cause ও check-এর সঙ্গে মিলিয়েছে। একই
symptom-এর একাধিক কারণ হতে পারে, তাই repair-এর আগে নাম দেওয়া evidence নিন।

| লক্ষণ | সম্ভাব্য কারণ | সমাধান |
|---|---|---|
| ডেস্কটপ নিঃশব্দে মরে যায়, বা `[Process completed (signal 9)]` | Android process policy, memory pressure, বা OEM battery management | [ডেস্কটপ নিঃশব্দে মরে যায়](#the-desktop-dies-silently) |
| Termux:X11-এ কালো/খালি উইন্ডো | X11 অ্যাপ খোলা হয়নি, বা পুরনো সকেট | [Termux:X11-এ কালো স্ক্রিন](#black-screen-in-termuxx11) |
| `renderer string: llvmpipe` | সফটওয়্যার ফলব্যাক — GPU পথ সক্রিয় নয় | [রেন্ডারার llvmpipe বলে](#renderer-says-llvmpipe) |
| ডেস্কটপে শব্দ নেই | PulseAudio ব্রিজ চলছে না | [অডিও নেই](#no-audio) |
| Debian-এ ইন্টারনেট নেই | PRoot-এ DNS আসেনি | [কন্টেইনারে নেটওয়ার্ক নেই](#no-network-in-the-container) |
| `Waiting for Termux-X11 display socket…` থেমে থাকে | Display :0 আসেনি | [ডিসপ্লে আসছে না](#display-never-appears) |
| `Error: unrecognized option: '-c'` | নতুন proot-distro-এর সঙ্গে পুরনো launcher | [proot-distro -c চেনে না](#proot-distro-says-option--c-is-unrecognized) |
| কিছু প্যাকেজে `apt` ব্যর্থ | Debian non-free চালু নেই | [apt ব্যর্থতা](#apt-failures) |
| `pkg upgrade`-এ `openssl.cnf` এরর, তারপর **প্রতিটি** ইনস্টল ব্যর্থ | বন্ধ stdin-এ dpkg conffile প্রম্পট | [openssl.cnf conffile ক্যাসকেড](#opensslcnf-conffile-cascade) |
| ইনস্টল কমান্ড পেস্ট করলে `No command $ found` | কপি করা টেক্সটে ডিসপ্লে-শুধু `$` প্রম্পট ঢুকে গেছে | [পেস্ট করা কমান্ড $ দিয়ে শুরু](#pasted-command-starts-with) |
| `curl: CANNOT LINK … SSL_set_quic_tls_transport_params` | আংশিক আপগ্রেড — curl/libngtcp2 openssl-এর চেয়ে নতুন | [আপগ্রেডের পর curl লিংক হতে পারে না](#curl-cannot-link-after-an-upgrade) |
| আগে সব ঠিক ছিল, আপগ্রেডের পর ভেঙে গেছে | Mesa প্যাকেজ বদলে গেছে | [আপগ্রেডের পর GPU পথ হারিয়ে গেছে](#after-an-upgrade-the-gpu-path-is-gone) |

---

<a id="the-desktop-dies-silently"></a>
## ডেস্কটপ নিঃশব্দে মরে যায়

**লক্ষণ:** Xfce4 বা দীর্ঘ build কোনো error message ছাড়া বন্ধ হয়। Termux-এ
`[Process completed (signal 9) - press Enter]` আসতে পারে।

**সম্ভাব্য কারণ:** Android 12+ app-spawned child process monitor/limit করে।
PRoot desktop-এ Xfce4, D-Bus, build worker ও PRoot মিলে অনেক process হয়, তাই
Android session-এর অংশ terminate করতে পারে। কিন্তু exact threshold ও setting
Android release/OEM-ভেদে বদলায়; signal 9 memory pressure বা vendor battery
management থেকেও হতে পারে।

প্রথমে Termux ও Termux:X11 battery use **Unrestricted** করুন, test-এর সময়
Termux foreground-এ রাখুন, অতিরিক্ত build parallelism কমান এবং cool reboot-এর
পরে retry করুন। এরপরও termination হলে এবং diagnostics child-process
restriction দেখালে আপনার Android release-এ থাকা control বিবেচনা করুন:

- **Android 14+ (PC লাগে না):** Developer options-এ exposed থাকলে
  **Disable child process restrictions** চালু করে reboot।
- **Android 12L/13 (PC বা root):**
  ```bash
  adb shell settings put global settings_enable_monitor_phantom_procs false
  ```
- **Rooted:**
  ```bash
  su -c "settings put global settings_enable_monitor_phantom_procs false"
  ```
- **Android 12 exactly**-এ প্রয়োজন হতে পারে:
  ```bash
  adb shell "/system/bin/device_config set_sync_disabled_for_tests persistent"
  adb shell "/system/bin/device_config put activity_manager max_phantom_processes 2147483647"
  ```

এই advanced control OEM block/rename করতে পারে এবং runaway background work-এর
বিরুদ্ধে system-wide protection বদলায়। original value লিখে রাখুন, OS যে
control expose করে শুধু সেটিই বদলান, reboot করুন, instability বা অস্বাভাবিক
battery drain হলে reverse করুন। `ternux doctor` readable setting report করে;
সব OEM process killer আলাদা করতে পারে না।

---

<a id="black-screen-in-termuxx11"></a>
## Termux:X11-এ কালো স্ক্রিন

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

তবু ব্যর্থ হলে `ternux repair` চালান — এটি ডিসপ্লে প্যাকেজ,
লঞ্চার ও কন্টেইনার কোর আবার পরীক্ষা করে।

---

<a id="renderer-says-llvmpipe"></a>
## রেন্ডারার llvmpipe বলে

**লক্ষণ:** desktop চলে, কিন্তু `glxinfo -B`-তে renderer `llvmpipe`। এটি Mesa
software fallback; শুধু visible desktop GPU route প্রমাণ করে না।

**সম্ভাব্য কারণ:** Zink target missing/replaced, VirGL host service start হয়নি,
অথবা configured backend hardware-এর সঙ্গে মেলে না।

```bash
# ১. intended route নির্বাচন করুন; auto /dev/kgsl-3d0 দেখে।
ternux backend set auto
# অথবা: ternux backend set zink    # শুধু /dev/kgsl-3d0-সহ Adreno
# অথবা: ternux backend set virgl

# ২. backend artifact ও launcher প্রয়োগ/মেরামত করুন।
ternux repair

# ৩. Zink হলে target ও package hold দেখুন:
db
ls -l /usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so
sudo apt-mark showhold
exit

# ৪. restart ও evidence নিন:
ternux stop && ternux start
# desktop terminal-এ: glxinfo -B
```

Completed GPU/launcher phase আবার প্রয়োগ করতে `bash install.sh --resume`
ব্যবহার করবেন না—resume সফল হিসেবে recorded phase বাদ দেয়। Validated Turnip
asset unreachable/incompatible হলে সচেতনভাবে
`ternux backend set virgl && ternux repair` চালিয়ে device-এ VirGL কী দেয়
`glxinfo -B` ও workload দিয়ে যাচাই করুন।

---

<a id="no-audio"></a>
## অডিও নেই

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

<a id="no-network-in-the-container"></a>
## কন্টেইনারে নেটওয়ার্ক নেই

**লক্ষণ:** Termux-এ network চলে, Debian guest-এ name resolution ব্যর্থ।
PRoot host network নিলেও resolver config সব সময় ঠিকমতো আসে না। Config
তাৎক্ষণিক overwrite না করে host ও guest evidence নিন:

```bash
# Termux host
getent hosts deb.debian.org
getprop | grep -i '\[net\..*dns'

# Debian guest
db
cat /etc/resolv.conf
getent hosts deb.debian.org
```

Host resolve করলেও guest file empty/invalid হলে আগে PRoot session stop/start
করুন। শুধু diagnostic হিসেবে `DNS_SERVER`-এ আপনার router/provider-এর trusted
resolver IP দিয়ে retry করুন:

```bash
DNS_SERVER='REPLACE_WITH_A_TRUSTED_IP'
printf 'nameserver %s\n' "$DNS_SERVER" | sudo tee /etc/resolv.conf
getent hosts deb.debian.org
sudo apt update
```

File পরে regenerate হতে পারে। Public resolver ব্যবহার করলে DNS query কে পায়
তা বদলে যায়, তাই ternux নীরবে নির্দিষ্ট resolver force করে না।

---

<a id="display-never-appears"></a>
## ডিসপ্লে আসছে না

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

<a id="proot-distro-says-option--c-is-unrecognized"></a>
## proot-distro `-c` option চেনে না

**লক্ষণ:** `x` চালালে `Error: unrecognized option: '-c'.` ও proot-distro usage।

**কারণ:** proot-distro 5.x container name ও guest command-এর মাঝে `--` চায়;
পুরনো launcher separator ছাড়া `bash -c` পাঠায়। শুধু visible `-c` patch করবেন
না—বর্তমান launcher প্রতিটি `--env VAR=VALUE`-ও আলাদা করে পাঠায়।

```bash
ternux repair   # saved user, locale ও backend দিয়ে launcher regenerate
x
```

Launcher phase complete হিসেবে recorded থাকলে `bash install.sh --resume`
replacement mechanism নয়।

---

<a id="pasted-command-starts-with"></a>
## পেস্ট করা কমান্ড $ দিয়ে শুরু

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

<a id="curl-cannot-link-after-an-upgrade"></a>
## আপগ্রেডের পর curl লিংক হতে পারে না

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

বর্তমান ইনস্টলার preflight-এই ভাঙা curl শনাক্ত করে পুরো chain
(`curl openssl openssl-tool libngtcp2 libnghttp3`) আপগ্রেড করে, তাই পথ খ-ই
শুরু করার জন্য যথেষ্ট।

---

<a id="opensslcnf-conffile-cascade"></a>
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

# ৩. বিঘ্নিত ইনস্টলার চালিয়ে যান; সফল হিসেবে রেকর্ড হওয়া phase বাদ যাবে:
bash install.sh --resume

# আগে সম্পূর্ণ হওয়া installation-এর managed artifact মেরামত করতে:
ternux repair
```

*কেন এমনটা ঘটে:* Android শেলে প্রায়ই পাইপ/নন-ইন্টারঅ্যাক্টিভ চলে, তাই
dpkg-র জিজ্ঞেস করার কোনো টার্মিনাল থাকে না। বর্তমান ternux ইনস্টলার প্রতিটি
apt অপারেশনে `--force-confold --force-confdef` দেয় এবং ভাঙা অবস্থা
স্বয়ংক্রিয় মেরামত করে — manual install বা পুরনো version-এর জন্যই ওপরের
সমাধানটি।

---

<a id="apt-failures"></a>
## apt ব্যর্থতা

**লক্ষণ:** guest Debian release-এ একটি package name unavailable হওয়ায় install
group ব্যর্থ। Package name ও repository component release-ভেদে বদলায়; deb822
`.sources` ব্যবহার করা system-এ blind `sed`-ও নির্ভরযোগ্য নয়।

```bash
db
. /etc/os-release; printf '%s %s\n' "$ID" "$VERSION_CODENAME"
sudo apt update
apt-cache policy unrar-free 7zip polkitd
sudo apt install -y unrar-free 7zip polkitd
```

কোনো app বিশেষভাবে non-free software চাইলে exact Debian release-এর repository
guidance দেখে `/etc/apt/sources.list*` review করুন। obsolete package name resolve
করতে পুরো source blind replace করবেন না।

---

<a id="after-an-upgrade-the-gpu-path-is-gone"></a>
## আপগ্রেডের পর GPU পথ হারিয়ে গেছে

**লক্ষণ:** রেন্ডারার ছিল `zink … Turnip`, `apt upgrade`-এর পর এখন
`llvmpipe`।

**কারণ:** হোল্ড করা Mesa প্যাকেজ আনহোল্ড হয়ে গেছে (বা হোল্ডটি এমন একটি
আপগ্রেডের পরে বসেছে যা আগেই প্যাকেজ বদলে দিয়েছে)।

**সমাধান:** `ternux repair` চালান (ড্রাইভার ও হোল্ড পুনঃপ্রয়োগ
হয়), তারপর `glxinfo` দিয়ে যাচাই করুন। অ্যাক্সিলারেশন রেখে ইচ্ছা করে Mesa
আপগ্রেড করতে চাইলে [কনফিগারেশন](CONFIGURATION.html#held-mesa-packages-zink-route)-এর
আনহোল্ড → আপগ্রেড → রি-হোল্ড → যাচাই ক্রমটি অনুসরণ করুন।

---

## চূড়ান্ত অস্ত্র: পরিষ্কার রি-ইনস্টল

```bash
ternux uninstall all             # irreversible deletion review ও confirm করুন
# অথবা interactively: ternux uninstall, তারপর ৫
bash install.sh                  # reviewed checkout থেকে fresh install
```

Container delete করলে **ভেতরের সব data** যায়। আগে valuable file বের করুন
([ব্যবহার → backup](USAGE.html#backups))। Uninstall target scoped; তবু prompt
ও path পড়ে confirm করুন।

---

## সমস্যা রিপোর্ট করা

[ইস্যু](https://github.com/soobujmiah/ternux/issues) খোলার সময় শুধু
পড়া-যায় এমন প্রমাণ দিন — লাইসেন্স কি, টোকেন বা প্রাইভেট ফাইল কখনোই নয়:

```bash
uname -m
getprop ro.product.manufacturer; getprop ro.product.model
getprop ro.build.version.release
ternux doctor --json           # machine-readable diagnostic
ternux info --json             # সম্পূর্ণ ডিভাইস প্রোফাইল
db -c 'glxinfo | grep "renderer string"; vulkaninfo --summary | grep -i driverName'
```

---

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · MIT*
