---
title: "টার্নাক্স v3 acceptance criteria"
description: "Manager, guest, compute, AI, Device Bridge ও Control Center-এর যাচাইযোগ্য gate।"
lang: "bn"
alt_url: "/docs/v3/ACCEPTANCE-CRITERIA.html"
---

## Acceptance criteria

**অবস্থা: নকশা সম্পন্ন; v3 gate সক্রিয়।** এই criteria ভবিষ্যৎ v3 capability-র জন্য। v2.0.1 প্রকাশিত, স্থির এবং অপরিবর্তিত। Evidence-এ exact commit ও environment থাকতে হবে। `PASS` বলতে চাওয়া আচরণ বাস্তবে হওয়া বোঝায়; reproducible setup ছাড়া screenshot/log কেবল সহায়ক প্রমাণ।

## Native manager ও Control Center

- Clean supported Termux environment-এ install/update/remove; file ownership, checksum/signature, idempotence, interrupted update recovery এবং সম্পর্কহীন Termux package সংরক্ষণ যাচাই।
- Guest না থাকলেও `tx status`, help, repair plan ও Control Center diagnostics PRoot ছাড়া চলে। Service বন্ধ করেও CLI-তে management সম্ভব নিশ্চিত করা।
- API শুধু Unix socket/loopback adapter-এ bind করে; off-origin mutation, invalid token, malformed JSON, duplicate job ও owned root-এর বাইরের path প্রত্যাখ্যান করে।
- নামসহ low-resource device-এ idle CPU/RAM, startup time ও log growth মাপা। Idle-এ camera, microphone, model load বা sensor poll নয়।

## Guest workspace

- প্রত্যেক বিজ্ঞাপিত distro-তে clean install, upgrade, shell/root alias, concurrent display, নির্বাচিত stop, multi-select, restart recovery ও uninstall পরীক্ষা।
- নামযুক্ত guest/device-এ GUI input, দাবিকৃত ক্ষেত্রে physical Ctrl+Space, GTK/icon/XFWM theme, titlebar, viewport fitting, audio, graphics backend, browser, storage permission ও app menu যাচাই। Third-party CSD/toolkit ব্যতিক্রম record করা।
- Termux-এর storage permission আগে থেকেই থাকলে `/sdcard` আছে নিশ্চিত করা; Ternux নীরবে permission চাইবে না। Extra directory grant সীমিত এবং revoke-এ Android file অক্ষত থাকে যাচাই।
- Native Termux `:0`-এর মালিক; Debian/Ubuntu/Alpine default `:1`/`:2`/`:3` এবং পরের guest collision-checked serial slot পায়। Explicit staged migration-এ v2 session সংরক্ষিত থাকে যাচাই।
- Guest remove শুধু নির্বাচিত guest ও Ternux-owned state সরায়; model store ও অন্য guest অক্ষত থাকে।

## Compute ও AI

- Detection, initialization, execution, correctness ও performance ফল আলাদা রাখা। Runtime/driver version, input/model digest, device, thermal context, peak memory, ফল ও failure log সংরক্ষণ।
- CPU ও accelerator route একই supported input এবং correctness reference ব্যবহার করবে। Toy arithmetic ছাড়া nontrivial language task ও image decode/health check থাকবে।
- Model/artifact install source, digest, architecture, license, free space ও rollback যাচাই করে। Discovery read-only; user আলাদা করে না বললে uninstall model রাখে।
- NPU claim-এর জন্য নামযুক্ত SoC-তে বাস্তব NPU runtime execution ও output correctness চাই। CPU/GPU emulation বা app-reported model label যথেষ্ট নয়।

## Device Bridge

- প্রতিটি API-তে granted, denied, cancelled, missing companion, timeout, low-storage, malformed response ও guest-copy failure path পরীক্ষা।
- Microphone/camera শুধু দৃশ্যমান user request-এ সক্রিয়; cancellation capture থামায়; সফল output decode হয় ও নির্বাচিত path-এ যায়।
- Still capture, live preview, webcam streaming ও recording আলাদাভাবে verify করে সঠিক নামে প্রকাশ।

## Documentation ও release

- README, CLI help, website, install command, package metadata, support matrix ও release note exact source behavior-এর সঙ্গে মেলে।
- Exact release commit-এ focused test, distro recipe, packaging/manifest integrity, security fixture ও site build-এর CI pass।
- বিজ্ঞাপিত clean path দিয়ে reference device-এ release candidate install। Checksum, workflow ID, screenshot/log ও recovery result record; known limitation তারিখসহ দৃশ্যমান।
