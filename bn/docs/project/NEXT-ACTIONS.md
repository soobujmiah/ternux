---
title: "Ternux-এর পরবর্তী কাজ"
description: "সম্পন্ন v2.0.1 release gate এবং ভবিষ্যৎ v3 কাজ।"
lang: "bn"
alt_url: "/docs/project/NEXT-ACTIONS.html"
---

## v2.0.1 release — সম্পন্ন

**পর্যালোচনা:** 2026-11-20। v2.0.1 পরীক্ষিত exact commit থেকে প্রকাশিত। v2 scope
frozen থাকবে; stable APT withdrawn-ই থাকবে।

- v2.0.0 withdrawal history ও বর্তমান owner scope মিলিয়ে দেখা হয়েছে; historical
  tag ও evidence রাখা হয়েছে।
- v1.4.0 ও v2.0.1-এর আলাদা exact-version installation guide আছে।
- Bilingual README, changelog, release index, status ও reconciliation report-এ
  প্রকাশিত v2.0.1 source archive এবং চার-distro baseline আছে।
- Local implementation/device evidence এবং exact-commit hosted check নথিভুক্ত।
- Commit `5be29360c9ca7e4516366711ec09f7a9b4d56940` থেকে source archive ও
  `SHA256SUMS` তৈরি, download ও checksum-verify করা হয়েছে।
- GitHub Release `v2.0.1` প্রকাশিত। Stable APT withdrawn; v2 APT repository
  প্রকাশ করা হয়নি।

## v2 প্রকাশের পরে Version 3

- Future product scope, architecture, acceptance criteria, ADR, testing, security
  এবং measurable milestone `docs/v3/`-এ একত্র করুন।
- Arch, Fedora, Void, openSUSE Tumbleweed, CentOS Stream ও Gentoo যাচাই করুন;
  প্রথম চারটি অগ্রাধিকার, আটটি qualified distro লক্ষ্য ও দশটি stretch goal।
- APT hosting, signing, ARM64 package build, metadata, upgrade/recovery, rollback,
  mirror ও supply-chain risk নিয়ে feasibility study করুন; owner approval ছাড়া
  prototype বা publication নয়।
- প্রতিটি v3 milestone-এ objective, dependency, acceptance test, documentation,
  security, release blocker ও out-of-scope স্পষ্ট করুন।

বর্তমান source-এ native Manager CLI, foreground read-only socket service, partial
Control Center, display migration ও multi-distro lifecycle code আছে। এর পূর্ণতা
ও device evidence component-ভেদে সীমিত। v2.0.0-এর পুরোনো evidence
[historical release report](../../../docs/release/V2-RELEASE-REPORT.md),
[device audit](../../../docs/audit/DEVICE-VERIFICATION.md) ও
[repository snapshot](../../../docs/audit/REPOSITORY-STATE.md)-এ রাখা হয়েছে।
