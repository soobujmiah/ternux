---
title: "Ternux project roadmap"
description: "প্রকাশিত v2.0.1 অবস্থা এবং ভবিষ্যৎ v3-এর আলাদা roadmap।"
lang: "bn"
alt_url: "/docs/project/PROJECT-ROADMAP.html"
---

## বর্তমান দিকনির্দেশ

**পর্যালোচনা:** 2026-11-20। Version 2 হলো বর্তমান implementation; v2.0.1 source
release প্রকাশিত হয়েছে। 2026-11-14-এর সিদ্ধান্ত—আগের v3 platform scope-কে v2-তে
তোলার প্রস্তাব—2026-11-18-এ owner প্রত্যাহার করেছেন। v2-তে নতুন capability,
distro support, architecture, desktop environment বা APT channel যোগ হবে না।

## Release অবস্থা

- **v1.4.0:** ঐতিহাসিক প্রকাশিত version। Tag `3e6c07e2afcb5f1e65ecd57af19b0382a948835a`;
  historical source archive থেকে install guide যাচাই হয়েছে। Live GitHub release
  page dedicated exact-version guide-এ link করে; কোনো binary asset নেই।
- **v2.0.0:** 2026-11-14-এ GitHub Release ও stable APT channel প্রত্যাহার হয়েছে;
  source tag provenance-এর জন্য রাখা আছে, পুনর্ব্যবহার করা যাবে না।
- **v2.0.1:** published source release; stable APT withdrawn-ই আছে।
- Stable APT v2.0.1-এর install পদ্ধতি নয়। বর্তমান feasibility সুপারিশ হলো
  v3.0 critical path-এ APT না রাখা; source installer চালু থাকবে।
- Owner-confirmed v2 desktop baseline: Debian, Ubuntu, Kali Linux ও Alpine।
  Evidence-এর গভীরতা সমান নয়; [feature matrix](../../../docs/audit/FEATURE-MATRIX.md)
  এবং [device record](../../../docs/audit/DEVICE-VERIFICATION.md) দেখুন।

## Version 2 freeze ও release gate

v2 বর্তমান implementation-কে সংরক্ষণ করবে; নতুন distro, Manager architecture,
Device Bridge, Control Center capability, extension framework, API, AI/compute
architecture, desktop environment বা APT reintroduction এই release-এর scope নয়।

v2.0.1 নির্দিষ্ট release commit থেকে প্রকাশিত; tag, source archive, checksum,
version-specific guide ও exact-commit checks-এর প্রমাণ
[v2 reconciliation](../../../docs/release/V2-RELEASE-RECONCILIATION.md)-এ আছে।
v2 freeze থাকবে; পরবর্তী release-এ একই artifact ও evidence gate প্রযোজ্য।

## Local evidence ও সীমা

v2.0.1-এর device qualification ও test evidence-কে
[release reconciliation](../../../docs/release/V2-RELEASE-RECONCILIATION.md)
এবং [feature matrix](../../../docs/audit/FEATURE-MATRIX.md)-এ সংরক্ষণ করা হয়েছে।
সেগুলো release snapshot; পরবর্তী প্রতিটি source commit-এ নতুন পূর্ণ device run
বোঝায় না। এই v3 documentation slice-এ Termux-এর Node binary linker error দেয়;
স্থাপিত Debian guest-এর Node runtime দিয়ে 98 page build ও 60 HTML route
finalize হয়েছে। Documentation checker 7,330 assertion, 669 internal link এবং
25 bilingual page pair pass করেছে। এ থেকে নতুন device qualification দাবি করা
হচ্ছে না.

## Version 3 — সক্রিয় উন্নয়ন

v2.0.1 release, release page এবং version-specific install guide প্রকাশিত ও যাচাই
হয়েছে। v2 frozen; v3 foundation কাজ `docs/v3/`-এ সক্রিয়। কোনো নকশা, roadmap
বা source file একা কোনো capability-কে available বা release-qualified প্রমাণ করে না।

- `docs/v3/`-এ product scope, architecture, acceptance criteria, ADR, testing,
  security, এবং measurable milestone একত্রে রাখুন। v3 design-কে v2 feature claim
  হিসেবে দেখাবেন না।
- Arch Linux, Fedora Linux, Void Linux, openSUSE Tumbleweed, CentOS Stream ও
  Gentoo candidate হিসেবে যাচাই করুন। প্রথম চারটিকে অগ্রাধিকার; প্রথম v3 release-এ
  আটটি fully qualified distro লক্ষ্য, দশটি stretch goal।
- [APT feasibility study](../../../docs/v3/APT-DISTRIBUTION-FEASIBILITY.md)-র
  প্রাথমিক সুপারিশ হলো v3.0 critical path-এ APT না রাখা এবং যাচাইকৃত source
  installer চালু রাখা। prototype ও supported status-এর আগে সব security,
  recovery এবং operational gate পাস করতে হবে।
- প্রতিটি implementation local-first ভাবে test ও verify করে তারপর repository-তে
  sync করুন; বর্তমান owner authorization এই project-এর development ও repository
  work-কে অন্তর্ভুক্ত করে।

বর্তমান Manager CLI, foreground read-only Unix-socket service, partial local
Control Center, display migration ও multi-distro lifecycle implementation-এর
অংশ; সম্পূর্ণ v3 platform নয়। বিস্তারিত [implementation status](IMPLEMENTATION-STATUS.md),
[next actions](NEXT-ACTIONS.md), [release status](RELEASE-STATUS.md) ও
[historical v2 report](../../../docs/release/V2-RELEASE-REPORT.md)-এ।
