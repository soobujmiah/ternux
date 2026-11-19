---
title: "টার্নাক্স v3 architecture ও পরিকল্পনা"
description: "v3-এর ভবিষ্যৎ নকশা, সক্রিয় foundation ও স্পষ্ট release boundary।"
lang: "bn"
alt_url: "/docs/v3/README.html"
---

## টার্নাক্স v3 architecture baseline

**অবস্থা: v3 development active; বাস্তবায়ন আংশিক।** Version 2 প্রকাশিত implementation-এ স্থির। v2.0.1 release, release page ও version-specific guide প্রকাশিত ও যাচাইকৃত; তাই আগের release gate সম্পন্ন। Source-এ manager ও Control Center-এর আংশিক slice আছে, পুরো v3 platform নেই। বর্তমান v3 foundation-এ documentation, security baseline ও acceptance contract; নিজস্ব test ও release evidence না আসা পর্যন্ত কোনো capability shipped নয়। বর্তমান implementation [project status](/docs/project/IMPLEMENTATION-STATUS.html) ও [v2 release record](/docs/V2-RELEASE-REPORT.html)-এ।

## নথি

1. [পণ্যের লক্ষ্য](PRODUCT-VISION.html)
2. [System architecture](SYSTEM-ARCHITECTURE.html)
3. [Component architecture](COMPONENT-ARCHITECTURE.html)
4. [Native Control Center](CONTROL-CENTER-ARCHITECTURE.html)
5. [Compute engine](COMPUTE-ENGINE.html)
6. [AI runtime](AI-RUNTIME-ARCHITECTURE.html)
7. [Device Bridge](DEVICE-BRIDGE-ARCHITECTURE.html)
8. [Workspace](WORKSPACE-ARCHITECTURE.html)
9. [Security model](SECURITY-MODEL.html)
10. [API design](API-DESIGN.html)
11. [UX ও design system](UX-AND-DESIGN-SYSTEM.html)
12. [Implementation roadmap ও V3.0–V3.3 milestone](IMPLEMENTATION-ROADMAP.html)
13. [Acceptance criteria](ACCEPTANCE-CRITERIA.html)
14. [Architecture Decision Record](ADR/README.html)
15. [APT distribution feasibility](APT-DISTRIBUTION-FEASIBILITY.html)
16. [Distro সম্প্রসারণ ও qualification](DISTRIBUTION-ROADMAP.html)
17. [Security roadmap](SECURITY-ROADMAP.html)
18. [Testing strategy](TESTING-STRATEGY.html)
19. [Extension SDK](EXTENSION-SDK.html)

## Status vocabulary

`PROPOSED` মানে candidate, owner approval নেই। `DESIGNED` মানে boundary ও acceptance criteria লেখা হয়েছে। `IMPLEMENTING` মানে code-এ সক্রিয় কাজ চলছে। `IMPLEMENTED` মানে code আছে, কিন্তু acceptance check শেষ নয়। `VERIFIED` মানে নির্দিষ্ট environment-এ বলা check pass। `RELEASED` মানে নামযুক্ত release-এ capability এসেছে। `REJECTED` মানে owner প্রস্তাব নাকচ করেছেন; history-র জন্য ADR ID থাকবে, কিন্তু planned কাজ হিসেবে ধরা যাবে না। Status সবসময় নির্দিষ্ট component/version-এর জন্য, পুরো project-এর implicit status নয়।

## অপরিবর্তনীয় architecture নীতি

- Manager ও Control Center native Termux-এ চলে, প্রতিটি PRoot guest-এর বাইরে। কোনো guest না থাকলেও basic manager কাজ করে; নিজের lifecycle-এর জন্য guest daemon-এর উপর নির্ভরশীল নয়।
- Guest নামসহ পৃথক workspace। Owner-confirmed v2 baseline Debian, Ubuntu, Kali ও Alpine; নতুন profile-এ আলাদা qualification matrix চাই।
- কম resource ও offline-এ Linux workspace ব্যবহারযোগ্য থাকবে। AI, camera, mic, GPU ও NPU ঐচ্ছিক workload; resource/permission-এর খরচ দৃশ্যমান হবে।
- Android access Termux API broker বা explicit scoped mount দিয়ে হবে। Extension permission চাইলে guest-এর host access স্বয়ংক্রিয়ভাবে বাড়বে না।
- Ternux-এর AI tool/workload Ternux-এরই থাকবে। LAI ও অন্য সব unrelated product/repository Ternux scope-এর বাইরে; নতুন explicit owner decision ছাড়া integration/dependency নয়।
- Performance, accelerator, device ও distro claim-এ tested device, software, workload ও evidence level থাকবে।
