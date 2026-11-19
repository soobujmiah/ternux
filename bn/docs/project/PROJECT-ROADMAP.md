---
title: "Ternux project roadmap"
description: "স্থানীয় v2.0.1 release candidate এবং ভবিষ্যৎ v3-এর আলাদা roadmap।"
lang: "bn"
alt_url: "/docs/project/PROJECT-ROADMAP.html"
---

## বর্তমান দিকনির্দেশ

**পর্যালোচনা:** 2026-11-19। Version 2 হলো বর্তমান implementation; v2.0.1 পরবর্তী
প্রস্তাবিত release। 2026-11-14-এর সিদ্ধান্ত—আগের v3 platform scope-কে v2-তে
তোলার প্রস্তাব—2026-11-18-এ owner প্রত্যাহার করেছেন। v2-তে নতুন capability,
distro support, architecture, desktop environment বা APT channel যোগ হবে না।

## Release অবস্থা

- **v1.4.0:** সর্বশেষ প্রকাশিত version। Tag `3e6c07e2afcb5f1e65ecd57af19b0382a948835a`;
  historical source archive থেকে install guide যাচাই হয়েছে। Live GitHub release
  page dedicated exact-version guide-এ link করে; কোনো binary asset নেই।
- **v2.0.0:** 2026-11-14-এ GitHub Release ও stable APT channel প্রত্যাহার হয়েছে;
  source tag provenance-এর জন্য রাখা আছে, পুনর্ব্যবহার করা যাবে না।
- **v2.0.1:** পরবর্তী version candidate; tag, release commit, artifact, checksum বা
  release page এখনো নেই। Local source ও documentation যাচাই চলছে।
- Stable APT v2.0.1-এর install পদ্ধতি নয়। APT কেবল v3-তে আলাদা feasibility
  study ও owner approval-এর পরে বিবেচ্য।
- Owner-confirmed v2 desktop baseline: Debian, Ubuntu, Kali Linux ও Alpine।
  Evidence-এর গভীরতা সমান নয়; [feature matrix](../../../docs/audit/FEATURE-MATRIX.md)
  এবং [device record](../../../docs/audit/DEVICE-VERIFICATION.md) দেখুন।

## Version 2 freeze ও release gate

v2 বর্তমান implementation-কে সংরক্ষণ করবে; নতুন distro, Manager architecture,
Device Bridge, Control Center capability, extension framework, API, AI/compute
architecture, desktop environment বা APT reintroduction এই release-এর scope নয়।

v2.0.1 প্রকাশের আগে নির্দিষ্ট release commit, version metadata, install guide,
source archive, checksum, artifact provenance, regression checks, exact-commit CI
ও release notes একে অন্যের সঙ্গে মিলতে হবে। Owner-এর অনুমতি ছাড়া GitHub-এ tag,
commit, publish, merge හෝ repository sync করা যাবে না.

## Local evidence ও সীমা

Debian guest-এ owner-এর অনুরোধে desktop চালু করে window-fit regression দেখা হয়েছে।
স্থানীয় candidate helper window resize-এর পর user-moved position রেখেছে; live
session `:1` খোলা আছে। `xdotool` Debian guest-এ test-এর জন্য install করা হয়েছে।
এটি একটি Debian/XFCE session-এর evidence; অন্য distro বা published package-এর নয়।
পুরোনো audit-এ desktop stopped দেখানো হয়েছিল—পরবর্তী পরিবর্তনটি
[device verification record](../../../docs/audit/DEVICE-VERIFICATION.md)-এ আলাদাভাবে আছে।

Termux ARM64 local focused suite 212/212 pass করেছে। Immutable bootstrap
source-sync check পুরোনো pinned snapshot-এ local source correction না থাকায়
open। Docker নেই এবং local Node runtime linker error-এ fail করে; তাই clean
browser matrix ও website/package build এখানে চালানো যায়নি। এগুলো clean-install
বা চার distro-র পূর্ণ qualification প্রমাণ করে না।

## v2 প্রকাশের পরে Version 3

v2.0.1 প্রকাশ ও তার version-specific install guide যাচাই হওয়ার পরেই v3 কাজ শুরু হবে।

- `docs/v3/`-এ product scope, architecture, acceptance criteria, ADR, testing,
  security, এবং measurable milestone একত্রে রাখুন। v3 design-কে v2 feature claim
  হিসেবে দেখাবেন না।
- Arch Linux, Fedora Linux, Void Linux, openSUSE Tumbleweed, CentOS Stream ও
  Gentoo candidate হিসেবে যাচাই করুন। প্রথম চারটিকে অগ্রাধিকার; প্রথম v3 release-এ
  আটটি fully qualified distro লক্ষ্য, দশটি stretch goal।
- APT hosting, ARM64 builds, signing, metadata, update/recovery, rollback, mirror,
  maintenance ও supply-chain ঝুঁকি নিয়ে গবেষণা করুন। সিদ্ধান্ত ও owner approval
  না হওয়া পর্যন্ত Planned রাখুন।
- Local implementation ও verification-এর পরে নির্দিষ্ট পরিবর্তন, evidence ও
  সীমা owner-কে দেখিয়ে approval নিন; তারপর repository synchronization করুন।

বর্তমান Manager CLI, foreground read-only Unix-socket service, partial local
Control Center, display migration ও multi-distro lifecycle implementation-এর
অংশ; সম্পূর্ণ v3 platform নয়। বিস্তারিত [implementation status](IMPLEMENTATION-STATUS.md),
[next actions](NEXT-ACTIONS.md), [release status](RELEASE-STATUS.md) ও
[historical v2 report](../../../docs/release/V2-RELEASE-REPORT.md)-এ।
