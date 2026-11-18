---
title: "টার্নাক্স v2 release audit reconciliation"
description: "মালিকের সিদ্ধান্ত, source, release history, device qualification ও বাকি v2 gate-এর প্রমাণভিত্তিক মিল-পর্যালোচনা।"
lang: "bn"
alt_url: "/docs/release/V2-RELEASE-RECONCILIATION.html"
---

**পর্যালোচনার তারিখ:** ২০২৬-১১-১৮  
**Repository baseline:** `main` at `1f8ffabaab7fe982f5bfc91759b14b921e6ebd8f`  
**অবস্থা:** v2.0.1 source candidate `main`-এ merge হয়েছে; প্রকাশ ও release artifact যাচাই বাকি।

বর্তমান source, GitHub history, exact-main CI, device record এবং মালিকের সর্বশেষ সিদ্ধান্তের সঙ্গে আগের audit ও project record মিলিয়ে এই প্রতিবেদন তৈরি। এটি প্রকাশের আগের reconciliation; v2.0.1 প্রকাশিত হয়েছে—এমন দাবি নয়।

সংস্করণভিত্তিক install guide-এর জন্য [release guide index](README.md) দেখুন।

## Audit-এর উৎস ও কর্তৃত্ব

- পূর্ণ Codex audit `/sdcard/Ternux_Full_Audit_2026-11-18.md`-এ রাখা। তার প্রাথমিক repository snapshot বর্তমান `main`-এর আগের; পরের release পরিবর্তন ও নতুন প্রমাণ এখানে মিলিয়ে লেখা হয়েছে।
- কাজে উল্লেখ করা স্বতন্ত্র ChatGPT audit বর্তমান attachment directory বা repository-তে ছিল না। তাই তার finding অনুপস্থিত; অনুমান করে যোগ করা হয়নি।
- `AI_ASSISTANT.md`, বর্তমান source, release record, feature matrix, device verification log ও exact-main CI পর্যালোচনা করা হয়েছে। তারিখ-চিহ্নিত audit-কে হালনাগাদ না করা পর্যন্ত ঐতিহাসিক snapshot হিসেবে ধরতে হবে।
- আগের কোনো নথির সঙ্গে বিরোধ হলে মালিকের সর্বশেষ সিদ্ধান্ত প্রযোজ্য: v2 বর্তমান implementation-এ frozen; নতুন architecture ও capability v3-তে থাকবে।

## Release ও version-এর অবস্থা

| বিষয় | যাচাইকৃত অবস্থা |
|---|---|
| বর্তমান `main` | `1f8ffabaab7fe982f5bfc91759b14b921e6ebd8f`; generated repository state merge-এর পর local checkout পরিষ্কার |
| v1.4.0 | অপরিবর্তনীয় tag `3e6c07e2afcb5f1e65ecd57af19b0382a948835a`; প্রকাশিত release-এ binary asset নেই; নির্দিষ্ট সংস্করণের নিজস্ব নির্দেশিকা আছে |
| v2.0.0 | release object ও stable APT channel প্রত্যাহার করা; provenance-এর জন্য tag `9106b04fc8627ae98b1d63c9912a28c8a4677441` রাখা—সরানো বা পুনর্ব্যবহার করা যাবে না |
| v2.0.1 | পরের অব্যবহৃত v2 সংস্করণ; source change `main`-এ আছে, কিন্তু tag, GitHub release, source asset বা checksum file এখনো নেই |
| Stable APT | প্রত্যাহৃত; v2.0.1-এর অংশ নয়। APT build workflow-এর unsigned package কেবল CI artifact, stable channel প্রকাশ নয় |

PR #297-এর release follow-up `4f96802576fab1f1806e4ea0db052de6719a4b47` commit-এ merge হয়েছে। ওই exact-main commit-এ Validate `44328593196`, Termux APT package artifact `44328592790` ও Repo Knowledge Sync `44328593206` pass করেছে। পরে generated-state PR #280 `1f8ffabaab7fe982f5bfc91759b14b921e6ebd8f`-এ merge হয়; `.repo/STATUS.md`-এ merge commit, build/test signal ও sync time আছে। Workflow এটি তৈরি করেছে, হাতে লেখা হয়নি।

## v2 scope ও qualification

মালিক-নিশ্চিত v2 desktop baseline হলো **Debian, Ubuntu, Kali Linux ও Alpine Linux**। প্রমাণের গভীরতা এক নয়:

- Debian, Ubuntu ও Alpine পরিষ্কার guest/browser CI matrix-এ আছে এবং বিস্তারিত reference-device record আছে।
- Kali-র installed reference-device qualification record-এ [device verification](../../../docs/audit/DEVICE-VERIFICATION.md)-এ তালিকাভুক্ত guest ও test আছে। একই মাত্রার পরিষ্কার install/browser CI নেই।
- বর্তমান ফোন session-এ Debian installed ও চলমান। `tx distro list` বাকি তিনটিকে qualified profile বললেও বর্তমানে installed বলে না। পুরোনো device record সে সময়ের installed guest-এর প্রমাণ, বর্তমান session-এর বর্ণনা নয়।
- অন্য ১১টি নামযুক্ত recipe v2 support promise-এর বাইরে। Source-এ recipe থাকাই qualification নয়।

| ক্ষেত্র | বর্তমান প্রমাণ ও পরিপক্বতা | সীমা / বাকি যাচাই |
|---|---|---|
| Installer ও bootstrap | Standalone ও CLI fallback একই immutable source commit (`555ce1374957cf35b7a7afa17bbb720b4529d64a`) এবং মেলা codeload SHA-256 `b52347389d70314e2b9118528bab3a19cb982b839d3f4627b2d0a66a5493ce83` ব্যবহার করে; local archive, hosted short-SHA codeload byte ও bootstrap sync test মেলে | Final v2.0.1 archive ও checksum manifest তৈরি ও যাচাই বাকি |
| CLI, PRoot lifecycle, uninstall/update/recovery | Exact-main CI ও focused test pass; updater rollback/recovery এবং data preservation-এর test আছে | CI fixture প্রতিটি বাস্তব device failure প্রমাণ করে না; guest data ও public command অক্ষত রাখতে হবে |
| Xfce ও Termux:X11 | বর্তমান Xfce/X11 integration রাখা হয়েছে। Live Debian-এ Ctrl zoom focused application-এ পৌঁছেছে; zoom-in screenshot-এ 13.55% pixel difference, zoom-out-এ baseline-এর সঙ্গে exact match | Intermittent X11 stall তৈরি করা যায়নি; স্বল্প round-trip sample দিয়ে এটি বাদ যায় না |
| Window placement ও resize | Live Debian test-এ সংশোধিত helper pointer resize-এর size/position ধরে। Reversible helper-on/helper-paused Xmessage comparison-এ move ও resize geometry একই | Move-এর পর মাঝখানে ফেরার অভিযোগ synthetic test-এ দেখা যায়নি। পুরো helper সরালে launch-time fit/clamp ও Ctrl zoom-ও হারাবে। Touch/device-specific আচরণ খোলা আছে |
| Graphics | Xiaomi `25053RT47C`, Android 16, Adreno 825, Zink/Turnip-এ চার distro-র device record আছে; বর্তমান Debian `tx verify` pass | প্রমাণ device/profile-নির্দিষ্ট; অন্য SoC, GPU, Android build বা workload performance-এর নিশ্চয়তা নয় |
| Audio | আগের per-distro/device record-এ audio route ও loopback test আছে; restart-এর পর বর্তমান Debian status PulseAudio চলমান বললেও `pulseaudio_ready=no` দেখায় | বর্তমান live audio readiness দাবি করার আগে route আবার পরীক্ষা করে transient কি না নির্ধারণ করতে হবে |
| বাংলা input | মালিক installed distro-তে physical-keyboard switching নিশ্চিত করেছেন; device record-এ Avro-র focused test আছে | প্রতিটি app/widget বা keyboard-এর qualification নয় |
| Camera ও microphone | Termux:API-ভিত্তিক integration ও lifecycle path আছে; test permission ও failure behavior দেখে | এই session-এ নতুন ছবি বা microphone recording করা হয়নি |
| AI ও optional workload | llama.cpp CPU/Vulkan ও Stable Diffusion CPU/Vulkan optional/preview; HTP/HMX ও QNN experimental/research-only | Experimental route-কে stable base feature বলা যাবে না; workload/model/device qualification সীমিত |
| Blender GPU MCP | Repository implementation ও documentation আছে | আলাদা device test-এর সীমানায় দাবি করতে হবে; source থাকাই broad compatibility প্রমাণ করে না |
| Manager ও Control Center | বর্তমান source-এ আংশিক manager/read-only ও dashboard অংশ আছে, CI test-ও আছে | সম্পূর্ণ Manager, service supervision, পূর্ণ Control Center, cancellation ও v3 orchestration v2 release promise নয় |

## Security ও রক্ষণাবেক্ষণের finding

- Startup password verifier-এ salted single SHA-256 ব্যবহার হয়। এটি convenience gate, security boundary নয়—এভাবে নথিভুক্ত; Termux app owner guest file পড়তে ও shell startup check এড়াতে পারেন। Compatibility ও recovery-সহ slow-KDF migration v3 security plan-এ রাখুন, যদি critical exploit প্রমাণিত না হয়।
- Local checkout বা installed CLI ছাড়া `uninstall.sh` direct pipe-এ চালালে fallback mutable `main` থেকে implementation file নামায়, syntax-check করে, তারপর scoped uninstaller চালায়। এটি reproducibility/supply-chain দুর্বলতা; documented scoped deletion safeguard ভাঙার প্রমাণ এই audit-এ নেই। Version-specific recovery-তে exact release archive ব্যবহার করুন; immutable pinning ভবিষ্যৎ security improvement।
- GitHub Actions full commit-SHA-এর বদলে version tag ব্যবহার করে এবং ShellCheck job নেই। এগুলো supply-chain ও analysis উন্নতির বিষয়; compromise বা critical defect প্রমাণ হয়নি।
- বড় shell module ও aggregate test runner maintenance খরচ বাড়ায়। শুধু আকার v2 release blocker নয়; module split ও test partitioning v3-র কাজ।
- Website dependency audit-এ build tree-এর Picomatch-সংশ্লিষ্ট নয়টি high-severity path পাওয়া গিয়েছিল; আগের review-তে যাচাইকৃত patched version না থাকায় unverified override যোগ করা হয়নি। প্রকাশের আগে advisory অবস্থা আবার দেখুন; build toolchain-কে ঝুঁকিমুক্ত বলা যাবে না।

উপলভ্য source/device/CI evidence-এ confirmed critical security vulnerability মেলেনি। স্বতন্ত্র audit অনুপস্থিত; তাই দুই audit-এই কিছু মেলেনি—এমন দাবি নয়।

## Documentation, release page ও README

- v1.4.0 release page এখন immutable `v1.4.0` archive নামায়, নথিভুক্ত SHA-256 যাচাই করে এবং archived installer `1.4.0` দেখায়—এমন guide-এ link দেয়। Tag `3e6c07e2…` দিয়ে guide পরীক্ষা হয়েছে; release-এ binary asset নেই।
- v2.0.1 guide নির্দিষ্ট সংস্করণের; প্রকাশের সময় exact tag/source asset/checksum manifest ব্যবহার করবে, `main` নয়। প্রকাশ না হওয়া পর্যন্ত GitHub release page যাচাই করা যাবে না।
- README-র card-wise design অক্ষত এবং latest main, মালিক-নিশ্চিত চার distro, experimental feature-এর সীমা ও unpublished v2.0.1 অবস্থা দেখায়। Website card বর্তমান repository থেকে build হয়; পুরোনো release snapshot নয়।
- English ও Bengali v2 install/readiness/troubleshooting পেজ জোড়া আছে। বর্তমান CLI page-এ চার-distro baseline ও আলাদা evidence depth লেখা; v3 workspace document একই feature matrix দেখায়।
- ঐতিহাসিক v2.0.0 report ও তারিখ-চিহ্নিত audit নিজ নিজ সময়ের সত্য ধরে রেখেছে; সেখানে লেখা পুরোনো তিন-distro release scope নতুন v2.0.1 baseline নয়।

## Candidate-এর যাচাই

- Local window-fit suite: **১৩টি case pass**; Python syntax check pass।
- Local `bash tests/focused.sh`: **211 pass, 0 fail**।
- বর্তমান factual correction-এর পর local documentation check: **6,518 assertion, 621 internal link, 24 bilingual page pair pass**।
- `tests/bootstrap_source_sync.sh`: pinned archive-এ pass। Local archive ও GitHub short-SHA codeload archive-এর SHA `b5234738…3ce83`; root `ternux-555ce13/`।
- PR #297 head `d792c254c51fcedc29925e6d6ba2c1a6cf3eafab`: Validate, unsigned package-artifact, repo-contract, test ও sync pass। Automated review-এ ধরা keyboard freeze ঠিক হয়েছে—preference I/O-র আগে key replay করে—তারপর review thread resolve হয়েছে।
- Merge commit `4f968025…`-এ exact-main Validate, package-artifact ও Repo Knowledge Sync pass; generated-state PR-ও required check pass করে `1f8ffab…`-এ merge হয়েছে।
- Termux-এর Node executable Android C++ runtime symbol mismatch-এর জন্য local `npm run format:check` চালু হয়নি। Exact-main GitHub Actions website build/format validation pass; এই release PR-এ Astro source বদলায়নি।

## v2 release-এর বাকি gate

1. Live Debian audio route readiness আবার পরীক্ষা করে ফল ও সীমা লিখুন।
2. Final release commit থেকে source archive তৈরি, root/version ও SHA-256 manifest যাচাই এবং archive contents পর্যালোচনা করুন।
3. Exact release commit ও version-specific guide-সহ v2.0.1 প্রকাশ করুন; stable APT channel প্রকাশ করবেন না।
4. GitHub থেকে published v2 page, exact tag, asset, checksum, install command এবং v1.4.0 page link যাচাই করুন।
5. Final release SHA ও evidence দিয়ে release status এবং এই reconciliation হালনাগাদ করুন; source merge হলে generated `.repo/` state যাচাই করুন।

## v3-এর সীমানা

v2.0.1 প্রকাশ ও যাচাইয়ের পরই v3 implementation বা APT feasibility কাজ শুরু হবে। প্রথম আট-distro লক্ষ্য হতে পারে v2 baseline-এর চারটির সঙ্গে Arch Linux, Fedora, Void ও openSUSE Tumbleweed যোগ করে; প্রতিটি নতুন profile-কে নিজস্ব qualification matrix pass করতে হবে। দশটি stretch goal, delivery promise নয়। APT ফেরানো আলাদা v3 feasibility study ও মালিকের সিদ্ধান্তের ওপর নির্ভর করবে।

পরের v3 planning-এ installer/module boundary, test architecture, Manager ও Control Center completion, service supervision, device/display management, Ternux-native workload ও compute lifecycle, extension/API design, security/supply-chain hardening এবং repository-state/documentation governance থাকবে।
