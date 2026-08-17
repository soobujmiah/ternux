---
title: "সাধারণ প্রশ্ন"
description: "ternux নিয়ে সোজাসাপ্টা উত্তর: root, নিরাপত্তা, Play Store Termux, স্টোরেজ, ব্যাটারি, গেমিং, প্রাইভেসি — মানুষ আসলে যা জিজ্ঞেস করে।"
lang: "bn"
alt_url: "/docs/FAQ.html"

---

---

## root কি লাগবে? root করলেই বা কী ক্ষতি?

না। Root-based setup-এ bootloader/device change লাগতে পারে, verified boot,
banking/DRM behavior বদলাতে পারে এবং ভুল বা untrusted code-এর blast radius
বাড়ে; exact ফল device/vendor ভেদে আলাদা।

ternux **PRoot** দিয়ে userspace-এ root-like filesystem/identity emulate করে;
Android root দেয় না। এতে privileged-system impact কমে, কিন্তু PRoot security
boundary নয়—Termux-accessible বা Debian-এ bound path code পড়তে/বদলাতে পারে।

## এটি কি ফোন নষ্ট বা "ব্রিক" করবে?

Installer bootloader বা Android system partition বদলায় না এবং root চায় না;
স্বাভাবিক install failure-এ phone brick হওয়ার কথা নয়। তবে এটি Termux package/
config, shell file ও Debian container বদলায়। Bug, untrusted command বা manual
system-setting change data loss/disruption করতে পারে—আগে backup নিন।

## কোন Termux release line ব্যবহার করব?

এই guide মূল [F-Droid](https://f-droid.org/en/packages/com.termux/) বা
[GitHub releases](https://github.com/termux/termux-app/releases) line ধরে লেখা।
Google Play-এ আলাদা পরীক্ষামূলক Android 11+ branch আছে; feature ও bug-এর
পার্থক্য থাকতে পারে। Termux ও সব plugin একই source থেকে ইনস্টল করুন।

## আসলে কত স্টোরেজ লাগবে?

সংশোধিত আনুমানিক **installed footprint** হলো **বেস ইনস্টলে ৩–৪ GB** এবং সব
repository tool-সহ সম্পূর্ণ `--all` ইনস্টলে **১০–১২ GB**। Debian package version,
filesystem accounting, optional tool ও cache retention অনুযায়ী actual use বদলায়।
Model ও নিজের project এই হিসাবের বাইরে।

Installed size আর install চলাকালীন free-space requirement এক নয়। Download,
package cache, extraction ও build tree কিছু সময় একসঙ্গে থাকে; তাই সম্ভব হলে
base-এর আগে প্রায় **৬ GB free**, আর `--all`-এর আগে **১৪ GB free** রাখুন:

```bash
df -h "$HOME"
du -sh "$PREFIX/var/lib/proot-distro/installed-rootfs/debian" 2>/dev/null
```

## Termux ও Debian desktop—দুই জায়গায় `ternux` কেন?

এগুলো environment-aware entry point। Termux-এ `$PREFIX/bin/ternux` পূর্ণ host
control plane—start, stop, repair, update ও uninstall করতে পারে। Xfce/Debian
terminal-এ `/usr/local/bin/ternux` safe guest-local `status`, `info`, `doctor` ও
`env` দেয়। Nested PRoot এড়াতে এটি host lifecycle command প্রত্যাখ্যান করে;
সেগুলো Termux terminal-এ চালান।

Installer installed entry point দুটি execute করে version response যাচাই করে।
শুধু কোনো path-এ file থাকাকে success ধরা হয় না।

## নন-Qualcomm ফোনে কি চলবে?

সম্ভাব্যভাবে। Mali, Xclipse ও PowerVR-এ installer **VirGL** সামঞ্জস্য পথ
বেছে নেয়, কিন্তু renderer name একাই hardware-backed acceleration প্রমাণ করে
না। Feature coverage ও গতি ডিভাইসভেদে বদলায়; `glxinfo -B` ও বাস্তব workload
দিয়ে যাচাই করুন।

## আমার রেন্ডারার `llvmpipe` কেন? এটা কি খারাপ?

`llvmpipe` হলো Mesa-র সফটওয়্যার রেন্ডারার: ডেস্কটপ চলে, কিন্তু প্রতিটি GL
অ্যাপ CPU-তে রেন্ডার হয় — ধীর আর ব্যাটারিখেকো। মানে অ্যাক্সিলারেটেড পথ
সক্রিয় নয়। দেখুন [সমস্যা সমাধান → llvmpipe](TROUBLESHOOTING.html#renderer-says-llvmpipe)।

## এ দিয়ে কি PC গেম খেলা যাবে?

যেভাবে আশা করছেন সেভাবে নয়। ternux ফোন হার্ডওয়্যারে একটি ডেস্কটপ
পরিবেশ, Windows গেমের কম্প্যাটিবিলিটি লেয়ার নয়। হালকা নেটিভ Linux/GL গেম
ও এমুলেটর চলতে পারে; AAA PC টাইটেল নয় — সেটা x86 + Windows-এর সমস্যা,
ডিসপ্লের নয়।

## Windows বা macOS অ্যাপ চালাতে পারব?

না। ternux **arm64 Linux** বাইনারি চালায়। Windows `.exe` আর macOS অ্যাপের
নিজস্ব OS (বা ভারী এমুলেটর) লাগে — যা এটি নয়। Android অ্যাপও Android-এই
চলে; সেগুলো ডেস্কটপের "ভেতরে" নয়।

## স্ক্রিন লক হলে বা কিছুক্ষণ পর ডেস্কটপ মরে যায় কেন?

সাধারণ কারণের মধ্যে Android child-process policy, memory pressure এবং OEM
battery management আছে। Termux ও Termux:X11 battery use *Unrestricted* করুন,
অতিরিক্ত build parallelism কমান এবং system-wide Android safeguard বদলানোর আগে
[evidence-led troubleshooting](TROUBLESHOOTING.html#the-desktop-dies-silently) অনুসরণ করুন।

## নিরাপত্তা/প্রাইভেসির দিক থেকে এটি কি নিরাপদ?

যে নকশা সিদ্ধান্তগুলো গুরুত্বপূর্ণ:

- **root নেই** — privileged Android access চাওয়া হয় না; PRoot Termux app
  permission-এর মধ্যেই থাকে, কিন্তু নিজে আলাদা security boundary নয়।
- **Loopback default/example** — audio bridge ও documented model server
  `127.0.0.1` ব্যবহার করে, তাই LAN-এ expose হয় না। একই ফোনের অন্য client
  loopback listener-এ পৌঁছাতে পারে; anonymous service-কে authenticated ভাববেন না।
- **যাচাইকৃত extraction** — unsafe path প্রত্যাখ্যান হয়, নির্বাচিত driver/ICD
  member দুটি regular file কিনা পরীক্ষা হয়, এবং শুধু সেগুলোই install হয়।
  Archive-এর অন্য বৈধ symlink extract করা হয় না।
- **পরীক্ষাযোগ্য ইনস্টলার** — একটি প্লেইন-টেক্সট ফাইল, MIT লাইসেন্স; চালানোর
  আগে পড়ে নিন।

সাধারণ নিয়ম তো আছেই: কন্টেইনারে অপরিচিত বাইনারি রুট হিসেবে চালাবেন না, আর
ইস্যু বা লগে ক্রেডেনশিয়াল পেস্ট করবেন না।

## সবকিছু দ্বিভাষিক করব কীভাবে?

মূল guide English ও বাংলায় আছে; পূর্ণ benchmark evidence archive বর্তমানে English-এ।
ডেস্কটপের ভেতরে:

```bash
bash install.sh --locale bn_BD.UTF-8
sudo dpkg-reconfigure locales
```

## Android বা Termux অ্যাপ আপডেট হলে কী হবে?

- **Android OS আপডেট:** কন্টেইনার তো ফাইল — টিকে যায়। পরে ফ্যান্টম-কিলার
  সেটিং আবার চেক করুন (`ternux doctor`)।
- **Termux app update:** সাধারণত ঠিক থাকে। পরে `ternux doctor`/`ternux verify`
  চালান; `--resume` recorded-successful phase বাদ দিয়ে saved optional workload
  set restore করে, কিন্তু general repair নয়।
- **Debian আপডেট:** নিরাপদ, তবে হোল্ড করা Mesa-র নোট দেখুন
  [কনফিগারেশনে](CONFIGURATION.html#held-mesa-packages-zink-route)।

## ternux কি সত্যিই ফ্রি?

হ্যাঁ। কোড ও ডকুমেন্টেশন MIT লাইসেন্সকৃত।
নির্মাতা ও রক্ষণাবেক্ষণকারী: [Sobuj Miah](https://github.com/soobujmiah)।
কনট্রিবিউশন স্বাগত।

## এটি কীসের জন্য নয়?

- ভারী 3D রেন্ডার বা বড় সিমুলেশন
- মাইনিং (ফোনের জন্য তাপীয় আত্মহত্যা)
- model weight, context ও runtime allocation available shared memory-তে না আঁটা workload
- `systemd`, কার্নেল মডিউল বা আসল USB/রেডিও অ্যাক্সেস লাগে এমন কিছু

এটি Android app sandbox-এর ভেতরে ARM64 Linux desktop ও নির্বাচিত development/
graphics workload-এর জন্য। No-root ঝুঁকির পরিধি কমায়; arbitrary downloaded
code, heat, battery wear বা data loss-এর ঝুঁকি শূন্য করে না।

---

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · MIT*
