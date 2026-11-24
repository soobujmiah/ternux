---
title: "সমস্যা সমাধান"
description: "টার্নাক্সের ব্যর্থতা প্রমাণের ভিত্তিতে শনাক্ত করা ও নিরাপদে মেরামত—রেন্ডারিং, অধিবেশন, অডিও, নেটওয়ার্ক ও পরিষ্কার পুনঃইনস্টল।"
lang: "bn"
alt_url: "/docs/TROUBLESHOOTING.html"

---

টেবিলটি সাধারণ লক্ষণকে সম্ভাব্য কারণ ও যাচাইয়ের সঙ্গে মিলিয়েছে। একই
লক্ষণের একাধিক কারণ হতে পারে, তাই মেরামতের আগে প্রমাণ সংগ্রহ করুন।

| লক্ষণ | সম্ভাব্য কারণ | সমাধান |
|---|---|---|
| ডেস্কটপ নিঃশব্দে মরে যায়, বা `[Process completed (signal 9)]` | অ্যান্ড্রয়েডের প্রক্রিয়া-নীতি, মেমরির চাপ বা নির্মাতার ব্যাটারি-ব্যবস্থাপনা | [ডেস্কটপ নিঃশব্দে মরে যায়](#the-desktop-dies-silently) |
| Termux:X11 সামনে আনলে Xfce/X11 ধীর বা অচল হয় | X11 companion অ্যাপ সামনে থাকলে Android Termux-কে কম CPU সময় দিতে পারে | [X11 ধীর বা অচল হয়](#x11-slows-down-or-stalls) |
| টার্মাক্স:এক্স১১-এ কালো/খালি জানালা | এক্স১১ অ্যাপ খোলা হয়নি বা পুরনো সকেট রয়ে গেছে | [টার্মাক্স:এক্স১১-এ কালো স্ক্রিন](#black-screen-in-termuxx11) |
| `renderer string: llvmpipe` | সফটওয়্যার বিকল্প-পথ—জিপিইউ সক্রিয় নয় | [রেন্ডারার llvmpipe বলে](#renderer-says-llvmpipe) |
| এক্সএফসিই শুরুর সময় `lost connection to rendering server` | ভিরজিএল সকেট গেস্টে নেই বা ডেবিয়ান মেসার ভিরজিএল প্রাথমিক যাচাই ব্যর্থ | [এক্সএফসিই শুরুর সময় ভিরজিএল ব্যর্থ](#virgl-fails-during-xfce-startup) |
| ডেস্কটপে শব্দ নেই | পালসঅডিও সেতু চলছে না | [অডিও নেই](#no-audio) |
| ডেবিয়ানে ইন্টারনেট নেই | প্রুটে ডিএনএস আসেনি | [কন্টেইনারে নেটওয়ার্ক নেই](#no-network-in-the-container) |
| `Waiting for Termux-X11 display socket…` থেমে থাকে | Display :0 আসেনি | [ডিসপ্লে আসছে না](#display-never-appears) |
| `Error: unrecognized option: '-c'` | নতুন প্রুট-ডিস্ট্রোর সঙ্গে পুরনো লঞ্চার | [প্রুট-ডিস্ট্রো `-c` চেনে না](#proot-distro-says-option--c-is-unrecognized) |
| `proot-distro: Argument list too long` | ডেস্কটপ asset payload Linux-এর প্রতি-argument সীমা ছাড়িয়েছে | [প্রুট-ডিস্ট্রো argument list বেশি বড়](#proot-distro-argument-list-is-too-long) |
| কিছু প্যাকেজে `apt` ব্যর্থ | ডেবিয়ানের নন-ফ্রি উপাদান চালু নেই | [এপিটি ব্যর্থতা](#apt-failures) |
| Debian + Xfce ধাপে `awk: cannot open "Manager"` | Synaptic-এর ফাঁকাসহ নাম desktop-entry script-এ quote ছাড়া গেছে | [ডেস্কটপ package entry ব্যর্থ](#desktop-package-manager-entry-fails) |
| `ternux install --resume` মুছে ফেলা গেস্ট এড়িয়ে যায় | পুরনো ইনস্টলের বাসি গেস্ট-ধাপের তথ্য | [গেস্ট মুছে ফেলার পর পুনরায় শুরু](#resume-after-removing-a-guest) |
| `pkg upgrade`-এ `openssl.cnf` এরর, তারপর **প্রতিটি** ইনস্টল ব্যর্থ | বন্ধ stdin-এ dpkg conffile প্রম্পট | [openssl.cnf conffile ক্যাসকেড](#opensslcnf-conffile-cascade) |
| ইনস্টল কমান্ড পেস্ট করলে `No command $ found` | কপি করা টেক্সটে ডিসপ্লে-শুধু `$` প্রম্পট ঢুকে গেছে | [পেস্ট করা কমান্ড $ দিয়ে শুরু](#pasted-command-starts-with) |
| `curl: CANNOT LINK … SSL_set_quic_tls_transport_params` | আংশিক আপগ্রেড — curl/libngtcp2 openssl-এর চেয়ে নতুন | [আপগ্রেডের পর curl লিংক হতে পারে না](#curl-cannot-link-after-an-upgrade) |
| আগে সব ঠিক ছিল, হালনাগাদের পর ভেঙেছে | মেসা প্যাকেজ বদলে গেছে | [হালনাগাদের পর জিপিইউ পথ হারিয়েছে](#after-an-upgrade-the-gpu-path-is-gone) |
| ইনস্টলার ড্যাশবোর্ড ঝিকমিক করে, লগ লাইন ফ্রেমের উপরে উঠে যায় | বর্তমান রেন্ডারারের চেয়ে পুরনো ইনস্টলার, বা যে টার্মিনালের মাপ পড়া যায় না | [ইনস্টলার স্ক্রিন ঝিকমিক করে বা ফ্রেম ভেঙে যায়](#the-installer-screen-flickers-or-the-frame-is-broken) |

---

<h2 id="proot-distro-argument-list-is-too-long">প্রুট-ডিস্ট্রো argument list বেশি বড়</h2>

**লক্ষণ:** গেস্ট তৈরি হওয়ার পর Debian + Xfce ধাপ
`proot-distro: Argument list too long` বার্তা দিয়ে থেমে যায়।

**কারণ:** পুরনো installer compressed desktop asset bundle-টি একটিমাত্র
`sh -c` argument হিসেবে পাঠাত; সেটি Linux-এর প্রতি-argument সীমা পেরিয়ে যেত।

**সমাধান:** README-তে থাকা এক-কমান্ড installer আবার চালান। বর্তমান installer
setup script-টি stdin দিয়ে গেস্টে পাঠায় এবং ব্যর্থ ধাপ থেকে অসম্পূর্ণ guest
নিজে থেকেই চালায়। Debian uninstall বা remove করবেন না।

---

<h2 id="resume-after-removing-a-guest">গেস্ট মুছে ফেলার পর পুনরায় শুরু</h2>

**লক্ষণ:** গেস্ট মুছে ফেলার পর ইনস্টলার পুনরায় শুরু হলে পুরনো ধাপ এড়িয়ে যায়,
অথবা বেছে নেওয়া ডিস্ট্রোর প্রুট কন্টেইনার আর নেই।

**সমাধান:** টার্নাক্সের পরিচালিত কমান্ড দিয়ে বাসি নিবন্ধন মুছে নতুন ইনস্টল
শুরু করুন। এতে আগের ধাপ ও কর্মক্ষেত্রের নথিও পরিষ্কার হবে:

```bash
ternux distro uninstall ubuntu --yes
ternux install --distro ubuntu
```

টার্নাক্স নথিভুক্ত গেস্টের ধাপ এড়ানোর আগে প্রুট কন্টেইনার আছে কি না যাচাই করে।
`proot-distro remove` দিয়ে পরিচালিত গেস্ট মুছবেন না; এতে টার্নাক্সের বিন্যাস ও
অধিবেশনের অবস্থা পরিষ্কার হয় না।

---

<h2 id="the-desktop-dies-silently">ডেস্কটপ নিঃশব্দে মরে যায়</h2>

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

- **Android 14+ (PC লাগে না):** About phone → *Build number* ৭ বার চাপুন →
  Developer options-এ **Disable child process restrictions** থাকলে চালু করুন;
  Android reboot চাইলে reboot দিন।
- **ADB shell বা Shizuku:** native Termux ADB, Shizuku `rish`, computer-এর USB/
  wireless ADB, সংস্করণভেদ, যাচাই ও rollback-এর জন্য
  [Android phantom-process নিয়ন্ত্রণ নির্দেশিকা](ANDROID-PHANTOM-PROCESS.md)
  দেখুন। Shizuku `rish` সরাসরি system command চালায়; এটি ADB transport তৈরি করে না।
- **Rooted:**
  ```bash
  su -c "settings put global settings_enable_monitor_phantom_procs false"
  ```
এই advanced control OEM block/rename করতে পারে এবং runaway background work-এর
বিরুদ্ধে system-wide protection বদলায়। Persistent DeviceConfig sync mode অন্য
DeviceConfig setting-ও প্রভাবিত করে; আগের mode লিখে রেখে restore করুন।
নির্দেশিকার read-before-write, verification ও rollback ধাপ অনুসরণ করুন।
`ternux doctor` readable setting report করে; সব OEM process killer আলাদা করতে পারে না।

---

<h2 id="x11-slows-down-or-stalls">X11 ধীর বা অচল হয়</h2>

**লক্ষণ:** Termux:X11 সামনে আনার পর ডেস্কটপ ধীর হয়ে যায় বা response বন্ধ
করে—বিশেষত Termux background-এ থাকলে।

**সম্ভাব্য কারণ:** অন্য অ্যাপ screen-এ থাকলে Android Termux-কে কম CPU সময় দিতে
পারে। [Termux:X11 প্রকল্প এই scheduling আচরণ নথিভুক্ত করেছে](https://github.com/termux/termux-x11#avoiding-slowdowns)
এবং একই UID-তে চালানো APK variant দিয়েছে। সেটি শুধু GitHub-signed Termux-এর
সঙ্গে কাজ করে; F-Droid বা Play Store-এর Termux-এর ওপর সেটি ইনস্টল করবেন না।

**যাচাই ও করণীয়:**

1. Termux ও Termux:X11—দুটির battery use **Unrestricted** করুন। Xiaomi-তে
   এই control থাকলে Termux-এর background activity/autostart-ও অনুমতি দিন।
2. দীর্ঘ session-এ device জেগে রাখুন। Termux:Boot startup script চালাতে পারে,
   আর `termux-wake-lock` sleep আটকাতে পারে; কিন্তু Boot চলমান X11/GPU hang ঠিক
   করে না বা আলাদা অ্যাপের মধ্যে Android CPU scheduling বদলায় না।
   [Termux:Boot-এর নির্দেশনা দেখুন](https://github.com/termux/termux-boot#how-to-use)।
3. সমস্যার সময় `tx status --json`, `tx info --json`, এবং
   `tx logs desktop show debian` সংগ্রহ করুন। X11 কালো বা server-টি সাড়া না
   দিলে `tx restart debian` managed session পুনরায় চালু করবে এবং খোলা window
   বন্ধ হবে।

Renderer hardware-accelerated এবং X11 server সাড়া দিলেও desktop freeze হলে
[Termux:X11 upstream debug নির্দেশনা](https://github.com/termux/termux-x11#logs)
অনুযায়ী log সংগ্রহ করুন। অল্প সময়ের সফল পরীক্ষা intermittent Android
scheduling বা GPU-driver stall-কে বাদ দেয় না।

---

<h2 id="ctrlplusminus-does-not-zoom-window-content">Ctrl+plus/minus-এ window-এর content zoom হয় না</h2>

**লক্ষণ:** Ctrl+- বা Ctrl+plus চাপলেও focused terminal বা অন্য X11
application-এর লেখার আকার বদলায় না।

**কারণ:** XFCE Terminal-এর font preference ধরে রাখতে Ternux এই key-গুলো দেখে।
Asynchronous X11 keyboard grab shortcut-টি focused application-এ পৌঁছানোর আগে
consume করতে পারে। v2.0.1 release-এ এটি ঠিক করা হয়েছে; পুরনো installed
helper-এর জন্য সংশ্লিষ্ট release update ও desktop restart দরকার।

**সমাধান:** Ternux update করে managed desktop `tx restart debian` দিয়ে restart
করুন (সক্রিয় guest অনুযায়ী `debian` বদলান)। XFCE Terminal-এ zoom out করতে
Ctrl+- এবং zoom in করতে Ctrl+Shift+= চাপুন; অনেক keyboard-এ plus চিহ্ন `=` key-এর
সঙ্গেই থাকে। অন্য application shortcut পেলে নিজস্ব zoom আচরণ করবে, যদি সেটি
সেই shortcut সমর্থন করে। Application অনুযায়ী key binding আলাদা হতে পারে।

---

<h2 id="black-screen-in-termuxx11">Termux:X11-এ কালো স্ক্রিন</h2>

**লক্ষণ:** `tx start` চলে, কিন্তু Termux:X11-এ কালো বা খালি উইন্ডো।

**কারণ (সম্ভাবনার ক্রমে):**

1. Termux:X11 **অ্যাপটি একবারও খোলা হয়নি** — ডিসপ্লে সার্ভিসের অনুমতি
   পেতে Android-এর সেই প্রথম লঞ্চ দরকার।
2. ক্র্যাশ হওয়া সেশনের **পুরনো সকেট** — `tx start` সাধারণত পরিষ্কার করে, কিন্তু
   হার্ড-কিল করলে থেকে যেতে পারে।
3. ডিসপ্লে চালুর পর Xfce4 ক্র্যাশ করেছে।

**সমাধান:**

```bash
killx
# Termux:X11 অ্যাপটি একবার খুলুন, তারপর:
tx start
```

তবু ব্যর্থ হলে `ternux repair` চালান — এটি ডিসপ্লে প্যাকেজ,
লঞ্চার ও কন্টেইনার কোর আবার পরীক্ষা করে।

---

<h2 id="virgl-fails-during-xfce-startup">XFCE শুরুর সময় VirGL ব্যর্থ</h2>

**লক্ষণ:** `tx start`-এ `lost connection to rendering server` আসে এবং
`startxfce4` থেমে যায়। Termux:X11 display চালু থাকলে
`X server already running` লাইনটিও দেখা যেতে পারে; আসল ত্রুটির জন্য VirGL ও
XFCE-এর পরের লাইনগুলো দেখুন।

**কারণ:** isolated guest-এর ভেতরে VirGL host socket দৃশ্যমান থাকতে হয়। কিছু
Debian Mesa build-এ VirGL `glxinfo` preflight-ও ব্যর্থ হয়।

**সমাধান:** Ternux আপডেট করে `tx repair` চালান, যাতে managed launcher নতুন করে
তৈরি হয়। এটি শুধু VirGL socket-টি guest-এ bind করে এবং XFCE চালুর আগে
renderer পরীক্ষা করে। VirGL ব্যর্থ হলে desktop Mesa-র `llvmpipe` software
renderer-এ চালু হবে; graphics-heavy app ধীর হতে পারে। এই পরীক্ষা শুধু VirGL
(`virpipe`) session-এ প্রযোজ্য; Zink/Turnip session-কে software-এ বদলায় না।
PowerVR ও অন্য non-Adreno device-এ এখানে shared VirGL পথ ব্যবহৃত হয়, তবে সেটি
phone GPU ব্যবহার করতে পারবে কি না Android host renderer-এর ওপর নির্ভর করে।
বিস্তারিত দেখতে `tx logs desktop` চালান।

---

<h2 id="renderer-says-llvmpipe">রেন্ডারার llvmpipe বলে</h2>

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

<h2 id="no-audio">অডিও নেই</h2>

**লক্ষণ:** ডেস্কটপ চলে, কিন্তু শব্দ নেই। (বা: আপডেটের পর শব্দ বন্ধ।)

**সমাধান, ক্রমে:**

```bash
# ১. অডিও ব্রিজ রিস্টার্ট করুন — লঞ্চার প্রতিটি শুরুতে এটি আবার বানায়:
killx && tx start

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

<h2 id="no-network-in-the-container">কন্টেইনারে নেটওয়ার্ক নেই</h2>

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

<h2 id="display-never-appears">ডিসপ্লে আসছে না</h2>

**লক্ষণ:** লঞ্চার `Waiting for Termux-X11 display socket…` দেখিয়ে ৩০
সেকেন্ডে টাইমআউট করে।

**কারণ:** `termux-x11` বাইনারি সকেট বানানোর আগেই বেরিয়ে গেছে — প্রায়
সবসময়ই Termux:X11 অ্যাপ কখনো খোলা হয়নি, বা Android ফোর্স-স্টপ করেছে।

**সমাধান:**

1. Termux:X11 অ্যাপ খুলুন, এক সেকেন্ড রেখে আবার Termux-এ ফিরুন।
2. `killx && tx start`
3. তবু আটকে? ডিসপ্লে প্যাকেজ রি-ইনস্টল করুন:
   `pkg reinstall termux-x11-nightly -y`

---

<h2 id="proot-distro-says-option--c-is-unrecognized">proot-distro <code>-c</code> option চেনে না</h2>

**লক্ষণ:** `tx start` চালালে `Error: unrecognized option: '-c'.` ও proot-distro usage।

**কারণ:** proot-distro 5.x container name ও guest command-এর মাঝে `--` চায়;
পুরনো launcher separator ছাড়া `bash -c` পাঠায়। শুধু visible `-c` patch করবেন
না—বর্তমান launcher প্রতিটি `--env VAR=VALUE`-ও আলাদা করে পাঠায়।

```bash
ternux repair   # saved user, locale ও backend দিয়ে launcher regenerate
tx start
```

Launcher phase complete হিসেবে recorded থাকলে `bash install.sh --resume`
replacement mechanism নয়।

---

<h2 id="pasted-command-starts-with">পেস্ট করা কমান্ড $ দিয়ে শুরু</h2>

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

<h2 id="curl-cannot-link-after-an-upgrade">আপগ্রেডের পর curl লিংক হতে পারে না</h2>

**লক্ষণ:** curl চালালে আসে
`CANNOT LINK EXECUTABLE "curl": cannot locate symbol "SSL_set_quic_tls_transport_params" referenced by …/libngtcp2_crypto_ossl.so`।

**কারণ:** **আংশিক আপগ্রেড** — `libngtcp2`/curl আপগ্রেড হয়েছে, কিন্তু
`openssl` পুরনো থেকে গেছে (সাধারণত বিঘ্নিত আপগ্রেডের ঠিক পরে; পুরনো ইনস্টলার
ভার্সনে openssl-ই সেই প্যাকেজ যা ওপরের conffile প্রম্পটে আটকে যেত)। ফলে curl
এমন একটি সিম্বল চায় যা ইনস্টল করা openssl-এ নেই।

**সমাধান — দুটি পথ:**

```bash
# পথ ক: Termux-এর সম্পূর্ণ package upgrade শেষ করুন:
apt update && apt full-upgrade -y

# পথ খ: curl/wget বিকল্পসহ installer নামিয়ে চালান:
pkg update -y && pkg upgrade -y && pkg install -y curl wget && bash -c 's=$(mktemp) && (curl -fsSL https://raw.githubusercontent.com/soobujmiah/ternux/c2a008cc4e6dc038fdf324f5128e2205e8a1583a/install.sh -o "$s" || wget -qO "$s" https://raw.githubusercontent.com/soobujmiah/ternux/c2a008cc4e6dc038fdf324f5128e2205e8a1583a/install.sh) && bash "$s"; r=$?; rm -f "$s"; exit "$r"'
```

`pkg update` শুধু package index রিফ্রেশ করে; আটকে থাকা package upgrade শেষ করে
না। curl ও wget দুটিই অচল হলে Termux-এ সরাসরি পথ ক চালান, তারপর installer
আবার চেষ্টা করুন। সম্পূর্ণ upgrade-এর পরও curl না চললে refreshed index থেকে
যুক্ত package-গুলো reinstall করুন:

```bash
apt install --reinstall curl libcurl openssl openssl-tool
```

টার্মাক্সের setup শেষ হলেও ডেবিয়ান desktop ধাপে কাজ থেমে গেলে উপরের source
installer command আবার চালান। এতে বর্তমান code নামবে এবং ব্যর্থ ধাপ থেকে
অসম্পূর্ণ guest-এর কাজ চলবে; ডেবিয়ান guest মুছবেন না।

`ternux repair` curl অনুপস্থিত বা চালু না হলে Termux `apt-get` wrapper দিয়ে
index রিফ্রেশ ও full upgrade চালায়, তারপর curl আবার যাচাই করে। Standalone
installer-ও curl চালু কি না পরীক্ষা করে; curl ভাঙা বা pinned source archive
নামাতে ব্যর্থ হলে wget-এ fallback করে।

---

<h2 id="opensslcnf-conffile-cascade">openssl.cnf conffile ক্যাসকেড</h2>

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

<h2 id="apt-failures">apt ব্যর্থতা</h2>

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

<h2 id="desktop-package-manager-entry-fails">Debian + Xfce ধাপে desktop package entry ব্যর্থ</h2>

**লক্ষণ:** Synaptic ও তার নির্ভরশীল package বসে যায়, তারপর আবশ্যিক Debian + Xfce
ধাপটি এই বার্তায় ব্যর্থ হয়:

```text
awk: cannot open "Manager" (No such file or directory)
[FAIL] Desktop package installation failed.
```

**কারণ:** তৈরি করা guest setup script-এ Synaptic desktop entry বদলানোর সময়
`Synaptic Package Manager` নামটি quote ছাড়া `awk`-তে গেছে। Shell নামটিকে
আলাদা argument-এ ভাগ করে, ফলে desktop user তৈরি ও setup শেষ হওয়ার আগেই ধাপটি থামে।

**সমাধান:** README-র বর্তমান নির্দিষ্ট commit-এ pinned one-command installer
আবার চালান। অসম্পূর্ণ Debian ধাপটি আবার চলবে এবং আগে বসানো package পুনর্ব্যবহার
করবে; guest মুছবেন না বা নতুন করে শুরু করবেন না। বর্তমান host CLI ইতিমধ্যে বসানো
থাকলে এটিও ধাপটি পুনরায় চালায়:

```bash
ternux install --resume
```

ধাপ শেষ হলে guest যাচাই করে চালু করুন:

```bash
ternux verify db
tx start db
```

আবার একই error এলে `ternux logs show`-এর প্রাসঙ্গিক অংশ এবং ঠিক কোন installer
phase-এ থেমেছে তা দিন। Password বা private token পাঠাবেন না।

---

<h2 id="after-an-upgrade-the-gpu-path-is-gone">আপগ্রেডের পর GPU পথ হারিয়ে গেছে</h2>

**লক্ষণ:** রেন্ডারার ছিল `zink … Turnip`, `apt upgrade`-এর পর এখন
`llvmpipe`।

**কারণ:** হোল্ড করা Mesa প্যাকেজ আনহোল্ড হয়ে গেছে (বা হোল্ডটি এমন একটি
আপগ্রেডের পরে বসেছে যা আগেই প্যাকেজ বদলে দিয়েছে)।

**সমাধান:** `ternux repair` চালান (ড্রাইভার ও হোল্ড পুনঃপ্রয়োগ
হয়), তারপর `glxinfo` দিয়ে যাচাই করুন। অ্যাক্সিলারেশন রেখে ইচ্ছা করে Mesa
আপগ্রেড করতে চাইলে [কনফিগারেশন](CONFIGURATION.html#held-mesa-packages-zink-route)-এর
আনহোল্ড → আপগ্রেড → রি-হোল্ড → যাচাই ক্রমটি অনুসরণ করুন।

হোল্ড কোনো স্থায়ী নিশ্চয়তা নয়। `apt install --reinstall mesa-vulkan-drivers` চালালে
apt সেই package-এর selection `install`-এ রিসেট করে, অর্থাৎ হোল্ড কিছু না জানিয়েই চলে
যায় — ২০২৬-১০-১৩-এ মাপা, যেখানে বাকি চারটি Mesa হোল্ড টিকে ছিল কারণ সেগুলোর নাম
command line-এ ছিল না। Package রি-ইনস্টল হলেও driver যে layout-এ টেকে, এবং কোনো
হোল্ডই লাগে না, তার জন্য দেখুন
[গ্রাফিক্স স্থায়িত্ব](GRAPHICS-PERSISTENCE.html)।

---

<h2 id="the-installer-screen-flickers-or-the-frame-is-broken">ইনস্টলার স্ক্রিন ঝিকমিক করে বা ফ্রেম ভেঙে যায়</h2>

**লক্ষণ:** `install.sh` চলার সময় ফ্রেম করা ড্যাশবোর্ড বারবার নতুন করে আঁকা হয়, লগ
লাইন বর্ডারের উপরে উঠে যায় বা মুড়ে যায়, আর উইন্ডো এত দ্রুত স্ক্রল করে যে কিছুই পড়া
যায় না।

**কারণ:** তিনটি আলাদা রেন্ডারার ত্রুটি, বর্তমান ইনস্টলারে সবগুলোই ঠিক করা হয়েছে।
ফ্রেমটি টার্মিনালের পুরো প্রস্থ ব্যবহার করত, ফলে শেষ কলামে লেখা হলে টার্মিনালের
pending-wrap অবস্থা চালু হয়ে যেত এবং পরের newline প্রতিটি সারিকে এক ঘর সরিয়ে দিত।
Carriage-return প্রগ্রেস আউটপুট (`apt`, `dpkg`, `proot-distro`, `curl`) প্রতিটি
আপডেটে একটি করে নতুন লগ লাইনে পরিণত হত। আর টার্মিনালের মাপ পড়া না গেলে resize
পরীক্ষা clamp করা মানের সঙ্গে raw মান মিলিয়ে ভাবত টার্মিনাল বদলে গেছে, এবং সেকেন্ডে
কয়েকবার পুরো স্ক্রিন নতুন করে আঁকত।

**সমাধান — আপডেট করুন, তারপর দরকার হলে রেন্ডারার বেছে নিন:**

```bash
# ১. বর্তমান ইনস্টলার আবার চালান (সম্পন্ন ফেজ বাদ যাবে)।
bash install.sh --resume

# ২. অথবা রেন্ডারার নিজে বেছে নিন।
bash install.sh --plain      # সাধারণ স্ক্রলিং লগ, ফুল-স্ক্রিন ড্যাশবোর্ড নয়
bash install.sh --no-anim    # ড্যাশবোর্ড থাকবে, স্পিনার থেমে থাকবে
TERNUX_UI=off bash install.sh   # কোনো ফ্রেম নয়, সরাসরি কমান্ড আউটপুট
```

রেন্ডারার নিজেই নির্বাচন করে: ড্যাশবোর্ডের জন্য রঙসহ ইন্টারেক্টিভ টার্মিনাল, অন্তত ৩৯
ব্যবহারযোগ্য কলাম ও অন্তত ১৩ সারি দরকার। পাইপ, TTY ছাড়া `curl | bash`, `TERM=dumb`,
`--quiet` ও `--json` — সব ক্ষেত্রেই স্বয়ংক্রিয়ভাবে সাধারণ স্ক্রলিং আউটপুটে ফিরে যায়।
পূর্ণ রেফারেন্স:
[ইনস্টলেশন → ইনস্টলার স্ক্রিন](INSTALLATION.html#the-installer-screen)।

স্ক্রিনের কারণে কিছুই হারায় না। ফেজগুলোর তৈরি প্রতিটি লাইন লগ ফাইলে যোগ হয়, স্ক্রিনে
`... +N more lines` হিসেবে সংক্ষেপ করা লাইনগুলোও:

```bash
ternux logs tail          # চলমান ইনস্টল লগ দেখুন
ternux logs show          # পুরো লগ পড়ুন
```

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
ternux doctor extensions --json  # health of installed extensions only
ternux info --json             # সম্পূর্ণ ডিভাইস প্রোফাইল
db -c 'glxinfo | grep "renderer string"; vulkaninfo --summary | grep -i driverName'
```

---

*টার্নাক্স — সর্বস্বত্ব (c) ২০২৬ সবুজ মিয়া ([@soobujmiah](https://github.com/soobujmiah)) · অ্যাপাচি-২.০*
