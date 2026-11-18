---
title: "Ternux-এর পরবর্তী কাজ"
description: "স্থানীয় v2.0.1 candidate gate, তারপর ভবিষ্যৎ v3 কাজ।"
lang: "bn"
alt_url: "/docs/project/NEXT-ACTIONS.html"
---

## v2.0.1 candidate gate

**পর্যালোচনা:** 2026-11-18। Candidate স্থানীয়, এখনো প্রকাশিত নয়। v2 scope frozen
থাকবে; stable APT পুনরায় চালু হবে না।

1. v2.0.0 withdrawal history, বর্তমান owner scope, audit record ও feature maturity
   মিলিয়ে দেখুন; historical tag/evidence অপরিবর্তিত রাখুন।
2. v1.4.0 এবং v2.0.1-এর আলাদা install guide সম্পূর্ণ করুন। v2 guide tag, exact
   source commit, archive SHA-256 ও public release page যাচাই না হওয়া পর্যন্ত
   candidate হিসেবেই চিহ্নিত থাকবে।
3. English/Bengali project status, README, website, distro baseline ও limitation
   এক করুন। Partial Manager/Control Center-কে সম্পূর্ণ হিসেবে দেখাবেন না।
4. স্থানীয় source regression test ও সীমিত device verification চালান। Owner-এর
   অনুরোধে বিদ্যমান Debian guest রেখে GUI চালু করে window-fit test করা হয়েছে;
   `xdotool` Debian-এ install হয়েছে এবং desktop খোলা আছে। এই কাজ আগের read-only
   audit থেকে পৃথকভাবে রেকর্ড করুন।
5. Build সীমা নথিবদ্ধ রাখুন: Docker নেই, native Node dynamic-linker error-এ শুরু হয়
   না, এবং এখানে চার-distro clean-install matrix চালানো যায় না। অনুমোদনের পর
   repository sync-এ exact-commit CI, website build ও package evidence নিন।
6. শুধু final approved commit থেকে release artifact তৈরি করুন; provenance, archive
   contents, version, checksum, notes ও exact install command যাচাই করুন। Withdrawn
   APT source configuration ফিরিয়ে আনবেন না।
7. Concrete local result-এ owner approval পাওয়ার আগে প্রকাশ করবেন না। অনুমোদিত
   sync-এর পর actual v2.0.1 ও v1.4.0 release page এবং সংশ্লিষ্ট tag archive যাচাই করুন।

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
