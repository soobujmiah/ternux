---
title: "টার্নাক্স পরবর্তী সংস্করণ distro সম্প্রসারণ ও qualification"
description: "Candidate distro-র ক্রম, architecture ঝুঁকি ও release qualification gate।"
lang: "bn"
alt_url: "/docs/next/architecture/DISTRIBUTION-ROADMAP.html"
---

## পরিধি ও baseline

রক্ষিত desktop setup হলো Debian, Ubuntu, Kali Linux ও Alpine Linux। Profile ভেদে evidence-এর গভীরতা আলাদা; [ঐতিহাসিক distro ও release reconciliation](/docs/release/V2-RELEASE-RECONCILIATION.html) দেখুন। Recipe থাকা মানেই `VERIFIED` বা `SUPPORTED` নয়।

পরবর্তী সংস্করণ লক্ষ্য চার baseline-সহ **আটটি সম্পূর্ণ qualified distro**। দশটি stretch goal, delivery promise নয়। প্রথম candidate-এর প্রস্তাবিত ক্রম Arch Linux, Fedora Linux, Void Linux, openSUSE Tumbleweed। Capacity ও evidence না আসা পর্যন্ত CentOS Stream ও Gentoo পরের candidate।

## Candidate যাচাই

| Candidate | ARM64/bootstrap প্রশ্ন | PRoot/package প্রশ্ন | Desktop/maintenance ঝুঁকি | প্রাথমিক status |
|---|---|---|---|---|
| Arch Linux | রক্ষিত ARM64 rootfs/bootstrap, architecture নাম, mirror ও signature verify | `pacman` keyring, rolling update ও PRoot syscall live test দরকার | দ্রুত package/ABI বদলে regression বাড়ে | `PLANNED` |
| Fedora Linux | সমর্থিত ARM64 rootfs ও mirror/bootstrap নিশ্চিত | `dnf` metadata/cache, package script ও PRoot সীমা পরীক্ষা | SELinux policy থাকলেই Android/PRoot enforcement হয় না; desktop বড় | `PLANNED` |
| Void Linux | ARM64 musl/glibc image, provenance ও mirror নির্ভরযোগ্যতা | `xbps` trust bootstrap, package script ও init ছাড়া runit | musl/glibc আলাদা matrix; service assumption স্পষ্ট দরকার | `PLANNED` |
| openSUSE Tumbleweed | ARM64 image/bootstrap ও signature path | `zypper` solver, rolling update ও interruption recovery | বড় update/snapshot-এ storage ও regression খরচ বেশি | `PLANNED` |
| CentOS Stream | ARM64 rootfs, lifecycle ও bootstrap reliability | PRoot-এ `dnf`/RPM script | Stream-এর lifecycle Fedora থেকে আলাদা; overlap-এর product rationale দরকার | `PLANNED` |
| Gentoo | Provenance ও ARM64 stage3 pin/reproducible করা | Source build, Portage resource ও init assumptions ফোনে নাও মানাতে পারে | Install time, heat, storage ও support burden বেশি | `PLANNED` |

এগুলো screening hypothesis, verified claim নয়। Recipe শুরুর সময় upstream support ও rootfs availability যাচাই করে URL, date, digest/signature, architecture ও নির্বাচিত image qualification record-এ রাখুন।

## Qualification matrix

প্রতিটি profile একই baseline gate এবং নিজস্ব package-manager check পাস করবে:

1. **Bootstrap integrity:** maintained source, explicit ARM64, signature/upstream checksum, archive traversal প্রতিরোধ, controlled failure-এর পর resume।
2. **Lifecycle:** install, enter/exit, start/stop/restart, update, repair, preserve ও selected uninstall idempotent; অন্য guest/host package অক্ষত।
3. **Package manager:** index refresh, install/upgrade/remove, broken mirror, IPv4/IPv6 fallback, invalid metadata ও interrupted transaction native tool দিয়ে পরীক্ষা।
4. **PRoot compatibility:** shell, user/group, DNS, proc/dev/tmp, locale, certificate ও package script—kernel isolation বা systemd/init দাবি ছাড়া।
5. **Desktop:** named device/image digest-এ Xfce startup/shutdown, X11, keyboard zoom, move/resize, clipboard/input, browser ও নির্বাচিত optional app installation।
6. **Device integration:** audio, graphics route/correctness, storage, camera/microphone point-of-use ও Bengali input আলাদাভাবে `VERIFIED`, `NOT TESTED` বা সুনির্দিষ্ট সীমা হিসেবে record।
7. **Resource/reliability:** download/storage, peak memory, install time, recovery ও সীমাবদ্ধ idle/start/stop soak মাপা; package install সাফল্য থেকে performance অনুমান নয়।
8. **Security/support:** ownership boundary, repo key, package provenance, lifecycle support, docs ও rollback review।

Qualification record-এ exact Ternux commit, distro release/image digest, repo snapshot/time, Android/Termux/device, command, log, failure ও retest থাকবে। CI recipe/lifecycle fixture যাচাই করতে পারে; X11, graphics, audio, input, camera/mic-এর device test-এর বিকল্প নয়।

## ক্রম ও release gate

1. চার baseline profile regression suite-এ রাখুন।
2. Recipe লেখার আগে Arch, Fedora, Void ও openSUSE-এর maintained ARM64 bootstrap এবং PRoot fit যাচাই।
3. একবারে একটি candidate explicit experimental profile-এ বাস্তবায়ন।
4. `VERIFIED` বলার আগে পূর্ণ matrix ও recovery test।
5. Documentation, CI, owner review ও support ownership স্থির হলে `SUPPORTED`।
6. প্রথম চার candidate qualify করলে অথবা blocker/revised target নথিভুক্ত হলে CentOS Stream/Gentoo বিবেচনা।

প্রতিটি নতুন profile বাধ্যতামূলক gate পাস করলেই Phase 0-এর আটটি qualified distro release condition হবে। নইলে কম verified সংখ্যা ও বাকি candidate-এর কারণ প্রকাশ করতে হবে; সংখ্যা পূরণে মান কমানো যাবে না।
