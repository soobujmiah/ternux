---
title: "Ternux implementation status"
description: "বাস্তব implementation, release অবস্থা ও প্রমাণের সীমা।"
lang: "bn"
alt_url: "/docs/project/IMPLEMENTATION-STATUS.html"
---

## বাস্তবায়নের অবস্থা

**Repository snapshot:** 2026-11-19। v2 বর্তমান implementation-এ frozen। v2.0.1
প্রকাশিত source release; পূর্ণ v3 কাজ ভবিষ্যতের জন্য। Source বা design
থাকলেই release/device verification হয়েছে—এমন দাবি করা হয় না।

| ক্ষেত্র | অবস্থা | প্রমাণ ও পরবর্তী সীমা |
|---|---|---|
| v2 release | v2.0.0 withdrawn; v2.0.1 published source release | পুরোনো tag provenance-এর জন্য আছে; GitHub Release ও stable APT নেই। Source tag, archive ও checksum যাচাই হয়েছে। [release status](RELEASE-STATUS.md) |
| Debian, Ubuntu, Kali, Alpine | Owner-confirmed v2 baseline | Clean guest/browser CI evidence Debian, Ubuntu ও Alpine-এ; Kali-র installed reference-device evidence আছে, clean-container install/Firefox CI নেই। [feature matrix](../../../docs/audit/FEATURE-MATRIX.md) |
| Window viewport helper | বর্তমান source-এ user position ধরে রাখার fix; published v2.0.1-এর live test | Live Debian/XFCE-তে `xdotool` দিয়ে move/resize test pass; resize-এর পর position থাকে। Debian, Ubuntu, Kali ও Alpine—চার guest-এ helper hash local source-এর সঙ্গে মেলে; interactive move/resize শুধু Debian/XFCE-তে পরীক্ষা হয়েছে। অন্য তিন guest-এর interactive qualification নয়। [device record](../../../docs/audit/DEVICE-VERIFICATION.md) |
| Installer ও CLI | বর্তমান source-এ multi-distro setup, lifecycle, recovery ও uninstall path | Host test আছে; clean-install, resume ও distro qualification evidence আলাদা করে ধরতে হবে। v1.4.0 এবং v2.0.1 guide আলাদা। |
| Desktop, graphics ও audio | বিদ্যমান Xfce/Termux:X11, Zink/VirGL এবং PulseAudio integration | Fresh Ubuntu, Kali ও Alpine desktop-এ PulseAudio route ও 2-second playback pass; owner প্রতিটিতে শব্দ শোনা নিশ্চিত করেছেন। Existing Debian VLC audio-ও owner-confirmed। এই device/session-এর বাইরে বা capture/recovery behavior প্রমাণ করে না। |
| Bengali input ও camera/microphone | বিদ্যমান app ও Termux API integration | Companion APK ও client package installed নিশ্চিত; local detector fix `cmd` ব্যর্থ হলে `pm path` চেষ্টা করে। Camera capture এবং microphone permission/status পরীক্ষা হয়নি; v3 Device Bridge এখনো design work। |
| AI workloads | Ternux-এর নিজস্ব optional llama.cpp/Stable Diffusion paths | HTP/HMX ও QNN experimental/research-only; model/runtime-সহ production AI support দাবি নয়। |
| Native Manager | Current source-এ read-only CLI ও foreground Unix-socket service | Service স্বয়ংক্রিয়ভাবে supervise হয় না; installed v2.0.0 package-এ এই source feature নেই। |
| Control Center | Source-এ partial local browser dashboard ও confirmation-bound start/stop | Device-browser validation, supervisor, cancellation, full panels ও native APK অসম্পূর্ণ; পূর্ণ v3 capability নয়। |
| Display migration | Current source-এ guarded planner/executor ও journaled recovery | সীমিত reference-device run; OS-level socket ownership-এর পূর্ণ নিশ্চয়তা নয়। |
| Stable APT | Withdrawn | v2.0.1-এর জন্য ফিরিয়ে আনা হবে না; v3 feasibility study ও owner approval লাগবে। |
| Distro framework | Source-এ একাধিক profile recipe আছে | চারটি owner-confirmed distro-র বাইরে v2 support claim নয়। |

## Local candidate test status

`python3 tests/window_fit_geometry.py`-এর 10টি case pass করেছে। Live Debian/XFCE
window move/resize reproduction ও local candidate verification-এর বিবরণ
[device verification](../../../docs/audit/DEVICE-VERIFICATION.md)-এ আছে। Full
`tests/focused.sh` candidate rerun **212/212 pass** করেছে। Shell syntax,
`git diff --check` ও documentation checker-ও pass করেছে; immutable bootstrap
source-sync check পুরোনো pinned snapshot-এ local source correction না থাকায়
এখনো open। বিস্তারিত [release reconciliation](../release/V2-RELEASE-RECONCILIATION.md)-এ।

Candidate source হলো local working tree; installed stable v2.0.0 package-এর সঙ্গে
এটি এক artifact নয়। Local Node executable dynamic-linker error-এ শুরু হয় না,
এবং Docker নেই; তাই Astro build ও clean-container browser matrix এখানে run করা
যায়নি। Exact-commit CI ও package/site build approval-এর পর repository sync-এ
চালাতে হবে।

## সক্রিয় সীমাবদ্ধতা

- Device evidence একটি Redmi Turbo 4 Pro / Android 16 / Adreno 825 reference
  device-এ সীমিত; অন্য hardware-এর claim নয়।
- Physical Ctrl+Space delivery config/helper invocation থেকে প্রমাণিত নয়।
- Window-fit helper source এবং চার deployed guest-এ একই hash; interactive move/resize কেবল Debian-এ live-verified। Release package-এ fix নেই।
- v2.0.0 withdrawn package এবং বর্তমান source আলাদা; নতুন source behavior কেবল
  exact v2.0.1 release commit pass ও publish হলে release claim হবে।
- Manager supervisor, Control Center পূর্ণতা, Device Bridge, platform-wide
  compute/AI lifecycle ও extension SDK ভবিষ্যৎ v3 কাজ।

বিস্তারিত: [পরবর্তী কাজ](NEXT-ACTIONS.md), [release status](RELEASE-STATUS.md),
[known limitations](/docs/project/KNOWN-LIMITATIONS.html), [device evidence](../../../docs/audit/DEVICE-VERIFICATION.md) ও
[feature matrix](../../../docs/audit/FEATURE-MATRIX.md)।
