---
title: "Android phantom-process নিয়ন্ত্রণ"
description: "PRoot কাজের জন্য ঐচ্ছিক Android host control; Termux ADB, Shizuku rish, computer ADB, যাচাই ও rollback।"
lang: "bn"
alt_url: "/bn/docs/ANDROID-PHANTOM-PROCESS.html"
---

Android-এর phantom-process নীতি Ternux/PRoot কাজ বন্ধ করছে—এমন প্রমাণ থাকলে
এটি একটি উন্নত, ঐচ্ছিক Android host setting। সব `SIGKILL`, X11 stall,
memory-pressure বা OEM battery restriction-এর সাধারণ সমাধান এটি নয়।
Ternux-এর [`doctor`](CLI.md#tx-doctor) শুধু পরীক্ষা করে; Android setting বদলায় না।

Android 14 বা পরের সংস্করণে Developer options-এ **Disable child process
restrictions** থাকতে পারে। থাকলে Android-এর এই UI control-কে অগ্রাধিকার দিন।
নিচের shell command-গুলো পুরো device-এ প্রযোজ্য, আর OEM/সংস্করণ অনুযায়ী আচরণ
আলাদা হতে পারে। Phantom-process সীমা বাড়ানো ও monitor বন্ধ করলে অতিরিক্ত
background child process ঠেকানোর Android সুরক্ষা দুর্বল হয়; প্রয়োজন হলেই
ব্যবহার করুন এবং memory ও battery লক্ষ্য করুন।

## Shell route বেছে নিন

Command-গুলো Android-এর `shell` user (UID 2000) হিসেবে চালাতে হবে—সাধারণ
Termux app UID দিয়ে নয়। পরিবর্তনের আগে পরিচয় দেখুন:

```sh
id
```

Output-এ `uid=2000(shell)` থাকতে হবে। `uid=10490(u0_a490)`-এর মতো Termux app UID
দেখালে থামুন; এই shell যথেষ্ট privileged নয়।

### Termux থেকে Shizuku

Shizuku চলমান থাকলে এর **Use Shizuku in terminal apps** পৃষ্ঠা খুলে Termux-এর
জন্য export/setup নির্দেশ অনুসরণ করুন। এতে `rish` নামে Shizuku shell পাওয়া যায়;
এটি ADB transport তৈরি করে না, তাই `adb devices`-এ device দেখানো বাধ্যতামূলক নয়।
যাচাই করুন:

```sh
rish -c 'id'
```

শুধু `uid=2000(shell)` এলে পরের অংশের command `rish -c '...'` দিয়ে চালান।
Shizuku চলমান এবং Termux-কে অনুমতি দেওয়া থাকতে হবে। Reboot-এর পরে Shizuku আবার
চালু করতে হতে পারে। Ternux-এর Shizuku dependency নেই; এটি Shizuku ইনস্টল বা
configure করে না।

### Computer থেকে ADB

USB debugging চালু করে ফোনে computer-টিকে অনুমতি দিন; device state `device`
হয়েছে নিশ্চিত করুন:

```sh
adb devices -l
```

Wireless ADB-এর জন্য Developer options-এ **Wireless debugging** চালু করুন।
Android 11+ এ দেখানো pairing address, port ও code দিয়ে একবার pair করুন; এরপর
Wireless debugging পৃষ্ঠার আলাদা ADB address ও port-এ connect করুন:

```sh
adb pair PHONE_IP:PAIRING_PORT
adb connect PHONE_IP:ADB_PORT
adb devices -l
```

অবিশ্বস্ত network-এ wireless debugging port উন্মুক্ত রাখবেন না। Computer ADB
route-এ পরের অংশের প্রতিটি command-এর আগে `adb shell` যোগ করুন।

### Native Termux-এর ADB client

Termux package-এর নাম `android-tools`:

```sh
pkg install android-tools
adb devices -l
```

শুধু ADB client ইনস্টল করলেই device shell permission মেলে না। Connected ও
authorized ADB transport লাগবে। Shizuku আগে থেকেই চললে pairing ছাড়াই `rish`
shell ব্যবহার করা যায়—উপরের Shizuku route নিন। বিকল্পভাবে computer-এর ADB
connection-এ উপরের `adb pair` ও `adb connect` চালান।

## আগের মান লিখে রেখে পরিবর্তন করুন

পরিবর্তনের আগে আগের মান লিখে রাখুন, যাতে পরে হুবহু restore করা যায়:

```sh
adb shell /system/bin/device_config get_sync_disabled_for_tests
adb shell /system/bin/device_config get activity_manager max_phantom_processes
adb shell settings get global settings_enable_monitor_phantom_procs
```

Computer ADB route-এ command-গুলো চালান:

```sh
adb shell /system/bin/device_config set_sync_disabled_for_tests persistent
adb shell /system/bin/device_config put activity_manager max_phantom_processes 2147483647
adb shell settings put global settings_enable_monitor_phantom_procs false
```

`persistent` reboot-এর পরও DeviceConfig synchronization বন্ধ রাখে। এটি test mode;
remote-synced DeviceConfig value যেন local change overwrite না করে তা নিশ্চিত
করে। এর প্রভাব phantom-process setting-এর বাইরেও যায় এবং Android-এর অন্য
DeviceConfig namespace-এ লাগতে পারে। আগে sync mode লিখে নিন; Android-এর সাধারণ
DeviceConfig sync বজায় রাখা জরুরি হলে ভেবে না দেখে এটি চালাবেন না। স্বীকৃত mode:
`none`, `until_reboot`, `persistent`।

Shizuku `rish` হলে `adb shell` বাদ দিয়ে একই command চালান:

```sh
rish -c '/system/bin/device_config set_sync_disabled_for_tests persistent'
rish -c '/system/bin/device_config put activity_manager max_phantom_processes 2147483647'
rish -c 'settings put global settings_enable_monitor_phantom_procs false'
```

## যাচাই

চারটি check চালান। প্রথম দুইটিতে `2147483647`, তৃতীয়টিতে `false` আসা উচিত:

```sh
adb shell /system/bin/dumpsys activity settings | grep max_phantom_processes
adb shell /system/bin/device_config get activity_manager max_phantom_processes
adb shell settings get global settings_enable_monitor_phantom_procs
adb shell /system/bin/device_config get_sync_disabled_for_tests
```

`rish` route-এ `adb shell` বাদ দিয়ে `rish -c` ব্যবহার করুন। Write command সফল
হওয়া মানেই ActivityManager-এ কার্যকর মান বদলেছে—এমন নয়; `dumpsys` এবং
`device_config` দুটোই দেখুন। Permission deny, key না থাকা, বা মান সঙ্গে সঙ্গে
ফিরে গেলে থামুন; Android সংস্করণ-উপযোগী Developer options control বা vendor
নির্দেশ নিন। OEM protection এড়ানোর চেষ্টা করবেন না।

## আগের অবস্থায় ফিরুন

পরিবর্তনের আগে লেখা আসল মান হুবহু ফিরিয়ে দিন। Phantom-process DeviceConfig key
আগে না থাকলে নতুন মান রেখে না দিয়ে override মুছুন:

```sh
adb shell /system/bin/device_config delete activity_manager max_phantom_processes
```

আগে মান থাকলে সেই মান ফিরিয়ে দিন:

```sh
adb shell /system/bin/device_config put activity_manager max_phantom_processes ORIGINAL_VALUE
```

Global monitor setting-ও আগের মানে ফেরান। আগে না থাকলে override মুছুন:

```sh
adb shell settings delete global settings_enable_monitor_phantom_procs
```

DeviceConfig sync আগের mode-এ ফেরান; সাধারণ মান `none`:

```sh
adb shell /system/bin/device_config set_sync_disabled_for_tests none
```

যে authorized shell route দিয়ে change করেছিলেন, সেটিই ব্যবহার করুন। Android বা
device vendor চাইলে তবেই reboot দিন; এরপর restored value যাচাই করুন।

## Ternux live-device পর্যবেক্ষণ

Maintainer-এর Android 16 (SDK 36) device-এ আগের Shizuku/watchdog setup দিয়ে
Termux-native ADB transport পাওয়া গিয়েছিল। `adb shell id` UID 2000 (`shell`)
দেখিয়েছে। পরীক্ষা করার আগেই অনুরোধের মানগুলো সেট করা ছিল:

- DeviceConfig sync mode: `persistent`
- `activity_manager/max_phantom_processes`: `2147483647`
- `settings_enable_monitor_phantom_procs`: `false`
- এই Termux home-এ `rish` executable ছিল না; check-এর সময় existing ADB
  transport-ই কাজ করেছে।

Device-এর কোনো মান আবার লেখা হয়নি। এই check-এর সময়ের মান নিশ্চিত হয়েছে;
সব workload-এ phantom-process kill বা X11 stall বন্ধ—এটি প্রমাণ করে না।

সম্পর্কিত: [সমস্যা সমাধান](TROUBLESHOOTING.md#the-desktop-dies-silently) ·
[Ternux CLI](CLI.md)
