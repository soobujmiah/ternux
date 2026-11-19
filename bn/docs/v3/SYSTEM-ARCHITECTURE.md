---
title: "টার্নাক্স v3 system architecture"
description: "টার্নাক্স v3-এর trust boundary, data flow, lifecycle ও failure handling।"
lang: "bn"
alt_url: "/docs/v3/SYSTEM-ARCHITECTURE.html"
---

## System architecture

**অবস্থা: নকশা সম্পন্ন।** Ternux হলো Termux-native manager, যা আলাদা PRoot workspace পরিচালনা করে। Guest-এ Linux userland app চলে; manager, Android permission flow বা host-wide lifecycle-এর মালিক guest নয়।

## Runtime layer

```text
Android OS and Termux companion apps
  ├─ Termux:API broker (camera, microphone, notifications, battery, etc.)
  └─ Termux:X11 app / Android input and display; native workspace owns `:0`
       │ explicit IPC, app grants, X11 socket
Termux host ($PREFIX)
  ├─ tx CLI and native manager core
  ├─ Native Control Center service and local UI
  ├─ Device Bridge adapters and permission broker
  ├─ workload/artifact registry and resource policy
  └─ per-guest state, logs, caches, and lifecycle supervisors
       │ explicit bind mounts, PRoot process boundary
Linux guest (Debian / Ubuntu / Alpine / qualified profiles)
  ├─ user session, XFCE, applications, guest packages
  ├─ optional workload client (CPU/GPU/NPU runtime)
  └─ guest-local config and files
       │
No dependency on unrelated projects or external product runtimes
```

v3-তে native Termux display `:0`-এর মালিক হবে; guest display শুরু হবে Debian `:1`, Ubuntu `:2`, Kali `:3`, Alpine `:4` থেকে এবং পরে collision-পরীক্ষিত serial slot পাবে। এটি v3 লক্ষ্য। ধাপে ধাপে migration সফল না হওয়া পর্যন্ত বর্তমান v2 display assignment বদলাবে না; বিস্তারিত [ADR-0005](ADR/0005-native-display-allocation.html)।

PRoot হলো compatibility boundary, kernel container-এর সমতুল্য security boundary নয়। Manager-ও এমন দাবি করবে না। Host-এর প্রধান security boundary Android app sandbox।

## Trust ও data flow

1. ব্যবহারকারী `tx` চালান; native manager argument যাচাই করে এবং Termux `$PREFIX`-এর versioned state পড়ে।
2. Guest action immutable ID ও যাচাই করা নামে একটি registered guest বেছে নেয়। Supervisor শুধু সেই guest-এর process tree ও display চালায়।
3. Workload অনুরোধে install বা execute করার আগে manifest, device capability, runtime, disk/RAM budget এবং user choice যাচাই হয়।
4. Android device action Termux API client দিয়ে যায়। ব্যবহারকালে permission চাওয়া হয়; idle guest camera বা microphone poll করতে পারে না।
5. Log ও result সংশ্লিষ্ট component-এর state directory-তে লেখা হয়। UI request, process, guest ও ফল মিলিয়ে দেখতে পারে, অন্য process-এর data না খুলে।

## Lifecycle state machine

Guest install/update চলে `ABSENT → PREPARING → READY`; ব্যর্থ হলে `PREPARING → FAILED`, সঙ্গে diagnostic ও নিরাপদ retry থাকে। Desktop চলে `STOPPED → STARTING → RUNNING → STOPPING → STOPPED`। Process exit, display failure বা timeout হলে exit code ও log path-সহ `DEGRADED` হয়। বারবার `start` idempotent; `stop` একটি guest বা স্পষ্ট নির্বাচনে প্রয়োগ হয়। Update নতুন file stage ও verify করে atomic switch করে; চলমান guest-এর active binary সরাসরি বদলায় না।

## Failure isolation

- Control Center crash করলেও guest চলবে এবং `tx` ব্যবহারযোগ্য থাকবে।
- এক guest crash করলে অন্য guest বা display বন্ধ হবে না।
- Android API permission না দিলে typed error ফিরবে; নীরব capture বা অন্য sensor দিয়ে fallback হবে না।
- GPU initialization ব্যর্থ হলে শুধু ঘোষিত ও report-করা backend chain-এ fallback হবে; ব্যর্থ accelerator ব্যবহার হয়েছে বলা যাবে না।
- ঐচ্ছিক workload ব্যর্থ হলে base desktop ও অন্য workload directory অক্ষত থাকবে।
- Manager state নষ্ট হলে backup ও report হবে; guest data না মুছে পুনর্গঠন করা যায়—শুধু এমন deterministic state-ই স্বয়ংক্রিয়ভাবে repair হবে।

## State ownership

নির্ধারিত ভূমিকা অনুযায়ী native manager `$PREFIX/var/lib/ternux` system record এবং `$HOME/.local/share/ternux` user record-এর মালিক। প্রতিটি guest তার rootfs ও guest home-এর মালিক। Ternux workload artifact-এর ownership স্পষ্ট থাকবে এবং ব্যবহারকারী নির্দিষ্ট data সরাতে না বললে guest uninstall-এ তা মুছবে না। বিস্তারিত [Workspace](WORKSPACE-ARCHITECTURE.html), [Security](SECURITY-MODEL.html) ও [ADR-0001](ADR/0001-native-manager.html)।
