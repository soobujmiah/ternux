---
title: "টার্নাক্স পরবর্তী সংস্করণ Termux APT বিতরণ feasibility"
description: "ভবিষ্যৎ Ternux APT channel-এর evidence-ভিত্তিক সিদ্ধান্ত ও qualification gate।"
lang: "bn"
alt_url: "/docs/next/architecture/APT-DISTRIBUTION-FEASIBILITY.html"
---

## সিদ্ধান্তের সারাংশ

**সুপারিশ: APT-কে Phase 0-এর critical path-এর বাইরে রাখুন এবং যাচাইকৃত source installer-কে supported route হিসেবে রাখুন।** Phase 0 security ও release foundation সম্পন্ন হলে signed, versioned APT channel prototype করার সুযোগ রাখা যায়। Stable repository প্রত্যাহৃত থাকলে APT available বলা যাবে না। এটি feasibility recommendation, package channel আবার প্রকাশের অনুমতি নয়।

ঐতিহাসিক implementation প্রমাণ করে signed Termux package/repository build ও install করা সম্ভব ছিল। এখনো APT delivery চালু আছে, অথবা installer-এর চেয়ে নিরাপদ/সহজ—এটা প্রমাণ করে না। release policy পরিবর্তনের অংশ হিসেবে 2026-11-14-এ stable package channel বন্ধ হয়। উপলভ্য history-তে `pkg` বা repository format-এর মৌলিক সীমাবদ্ধতা নয়, release policy প্রত্যাহারের কথা আছে। আগের website deployment hosted APT tree-ও সরিয়ে ফেলতে পারত; পরে preserve ও signature/checksum validation যোগ হয়। বাকি maintenance cost ও upgrade আচরণে ইতিবাচক সিদ্ধান্তের আগে নতুন prototype দরকার।

## Evidence baseline

- `docs/TERMUX-APT.md` অনুযায়ী stable `/apt` প্রত্যাহৃত; stable bootstrap, key, index ও package endpoint unavailable। Opt-in `/apt-rc` supported install source নয়।
- `docs/release/V2-RELEASE-RECONCILIATION.md`-এ ঐতিহাসিক signed package Termux `pkg` দিয়ে install হওয়ার এবং পরে stable distribution প্রত্যাহারের তথ্য আছে। পরবর্তী source archive installer-ভিত্তিক।
- `packaging/termux/`-এ package, repository, bootstrap ও Pages preservation tooling আছে। `.github/workflows/termux-apt-release.yml` প্রত্যাহৃত source-tag release-তে version-gated, RC publication ও stable-channel withdrawal path আছে; এটি পরবর্তী সংস্করণ pipeline নয়।
- এই file-গুলো historical evidence। বর্তমান package install, stable repo publication, key rotation drill, rollback বা পরবর্তী সংস্করণ upgrade প্রমাণিত নয়।

## সুবিধা-ঝুঁকি

| ক্ষেত্র | APT-এর সম্ভাব্য সুবিধা | খরচ/অমীমাংসিত ঝুঁকি | Prototype evidence |
|---|---|---|---|
| খোঁজা ও update | পরিচিত `pkg install`/`pkg upgrade`, dependency metadata | Ternux শুধু static CLI নয়; package update যেন guest state নীরবে না বদলায় | Clean Termux install, চলমান guest-সহ upgrade, interruption ও rollback |
| ARM64 | `Architecture: all` দিয়ে shell/Python asset বিতরণ | Native helper/optional artifact-এর ABI ও provenance আলাদা লাগে | Supported ARM64 Termux-এ package contents/dependency closure যাচাই |
| Repository hosting | Signed index, Release metadata, checksum | Pages deployment, retention, key custody/rotation, index expiry ও incident response চলমান কাজ | Reproducible build, signed metadata, failure/key rotation drill |
| Dependency | `Depends` দিয়ে host package ঘোষণা | Termux package আলাদা গতিতে বদলায়; guest dependency host package নয় | Clean dependency, missing dependency, held package, offline/error path |
| Versioning | নির্দিষ্ট version ও downgrade সুবিধা | Package, installer pin, CLI ও guest schema সামঞ্জস্যে থাকতে হবে | Upgrade, downgrade, version pin ও migration test |
| Removal | `pkg uninstall` host ownership সামলায় | Guest data অক্ষত রেখে শুধু host file সরাতে হবে | Package remove-এ guest/model data রক্ষা ও owned file removal |
| Integrity | Signed metadata archive/key ও metadata integrity নিশ্চিত করে | Key compromise ও CI compromise supply-chain threat; hash publisher পরিচয় নয় | Protected signing, full fingerprint, provenance ও recovery plan |
| Maintenance | Standard metadata সাধারণ update সহজ করতে পারে | দ্বিতীয় delivery path docs, CI, release, support ও endpoint monitoring দ্বিগুণ করে | অন্তত দুই release cycle-এ owner maintenance task মাপা |

## Gate-এর ধাপ

### A. Research

1. Script বদলানোর আগে প্রত্যাহৃত source-tag release withdrawal-এর exact workflow run, release asset ও support commitment মিলিয়ে দেখা।
2. Termux host file, guest data, cache, model, config, log ও generated artifact-এর ownership document করা।
3. Supported Termux version, dependency, version policy, key custody/rotation, expiry, rollback ও incident response নির্ধারণ।
4. Source installer-এর সঙ্গে user benefit ও maintenance time তুলনা করা। Material benefit না থাকলে installer-only policy বজায় রাখা।

### B. বিচ্ছিন্ন prototype

1. Exact source commit থেকে reproducible `Architecture: all` package build; manifest, digest ও build provenance তৈরি।
2. আলাদা key ও explicit opt-in নির্দেশসহ কেবল isolated experimental channel-এ প্রকাশ।
3. Clean Termux-এ signed `InRelease`, package/index hash, full key fingerprint, version pin, dependency closure ও package content verify।
4. Install/update/interruption/retry/downgrade/uninstall, network না থাকা, stale metadata, invalid signature ও key-rotation recovery পরীক্ষা।
5. Package removal ও ব্যর্থ upgrade-এ guest data এবং unrelated Termux package অক্ষত নিশ্চিত করা।

### C. Qualification ও release decision

Prototype evidence পুনরাবৃত্তিযোগ্য না হওয়া এবং owner maintenance/security দায়িত্ব না নেয়া পর্যন্ত APT `EXPERIMENTAL` থাকবে। Repository availability, signed metadata, reproducible build, safe upgrade/removal/recovery, provenance, monitoring, key rotation ও release docs নির্দিষ্ট Termux baseline-এ pass হলেই `SUPPORTED` বলা যাবে। নইলে `PLANNED` রাখুন বা বাতিল করে source installer চালিয়ে যান।

## বর্তমান status

| বিষয় | অবস্থা |
|---|---|
| Stable APT endpoint | প্রত্যাহৃত / unavailable |
| Signed আগের implementation package | ঐতিহাসিকভাবে verified; এখনকার নয় |
| RC endpoint | Supported install source নয়; ব্যবহারের আগে live availability যাচাই দরকার |
| পরবর্তী সংস্করণ feasibility | এই নথিতে মূল্যায়িত; prototype ও operational cost-এর evidence বাকি |
| User-facing দাবি | APT install বিজ্ঞাপন দেবেন না |
| Supported install route | Version-specific source installation guide |
