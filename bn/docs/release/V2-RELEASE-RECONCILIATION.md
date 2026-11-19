---
title: "টার্নাক্স v2 release audit reconciliation"
description: "মালিকের সিদ্ধান্ত, source, release history, device qualification ও বাকি v2 gate-এর প্রমাণভিত্তিক মিল-পর্যালোচনা।"
lang: "bn"
alt_url: "/docs/release/V2-RELEASE-RECONCILIATION.html"
---

**পর্যালোচনার তারিখ:** ২০২৬-১১-১৯

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
| Audio | ২০২৬-১১-১৮-তে controlled Debian stop/start করে আগে থাকা দুটি PulseAudio daemon সরানো হয়; এরপর একটিমাত্র Ternux daemon (`--exit-idle-time=-1`) config-এর 4713 port ও launcher-এর নির্বাচিত 4714 port serve করেছে। নির্বাচিত port-টি guest-এ পাঠানো হয়। ৩০ সেকেন্ড idle-এর পরও host status-এ `pulseaudio_ready=yes` ছিল; পরের VLC test শোনার বিষয়টি owner নিশ্চিত করেছেন। Historical device record-এ Debian/Ubuntu/Alpine concurrent audio route এবং Kali `paplay` loopback capture-ও আছে। | বিদ্যমান Debian install-এ fresh start হয়েছে, clean Android install নয়। বর্তমান device-এ Ubuntu/Kali/Alpine নেই, তাই এই ঘটনার পর সেগুলো retest হয়নি। XFCE চলাকালে Android PulseAudio মেরে দিলে recovery-ও unverified |
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

1. Final release commit থেকে source archive তৈরি, root/version ও SHA-256 manifest যাচাই এবং archive contents পর্যালোচনা করুন।
2. Exact release commit ও version-specific guide-সহ v2.0.1 প্রকাশ করুন; stable APT channel প্রকাশ করবেন না।
3. GitHub থেকে published v2 page, exact tag, asset, checksum, install command এবং v1.4.0 page link যাচাই করুন।
4. Final release SHA ও evidence দিয়ে release status এবং এই reconciliation হালনাগাদ করুন; source merge হলে generated `.repo/` state যাচাই করুন।

## v3-এর সীমানা

v2.0.1 প্রকাশ ও যাচাইয়ের পরই v3 implementation বা APT feasibility কাজ শুরু হবে। প্রথম আট-distro লক্ষ্য হতে পারে v2 baseline-এর চারটির সঙ্গে Arch Linux, Fedora, Void ও openSUSE Tumbleweed যোগ করে; প্রতিটি নতুন profile-কে নিজস্ব qualification matrix pass করতে হবে। দশটি stretch goal, delivery promise নয়। APT ফেরানো আলাদা v3 feasibility study ও মালিকের সিদ্ধান্তের ওপর নির্ভর করবে।

পরের v3 planning-এ installer/module boundary, test architecture, Manager ও Control Center completion, service supervision, device/display management, Ternux-native workload ও compute lifecycle, extension/API design, security/supply-chain hardening এবং repository-state/documentation governance থাকবে।

## Local follow-up — fresh guest audio ও bootstrap archive পরিচয় (২০২৬-১১-১৯)

- Android 16 reference device-এ Ubuntu Resolute, Kali rolling এবং Alpine v3.24 fresh local install সম্পন্ন হয়েছে। তিনটি desktop-ই Ternux `READY` হয়েছে; সবগুলোতে Xfce4 ও shared Ternux PulseAudio route ব্যবহার করা হয়েছে।
- প্রতিটি guest-এ `pactl info` `tcp:127.0.0.1:4714` ও `OpenSL_ES_sink` দেখিয়েছে। দুই-সেকেন্ড test tone-এর `paplay` exit code 0 দিয়েছে এবং মালিক তিনটি desktop-এই tone শোনার কথা আলাদাভাবে নিশ্চিত করেছেন। এই session-এর জন্য Ubuntu, Kali ও Alpine audio playback device-verified।
- Multi-guest install Termux package index/upgrade refresh করেছে। এই fresh-install/audio পর্যায়ে host PulseAudio configuration বদলানো বা host PulseAudio daemon restart করা হয়নি। শেষে তিন guest-এর status-এ `pulseaudio_ready=yes` ছিল।
- Live Ubuntu bootstrap failure-এ pinned source archive verify না হওয়ার কারণ ধরা পড়েছে: codeload URL-এ সাত-অক্ষরের commit prefix ব্যবহারে archive root directory ও SHA-256 পূর্ণ commit URL থেকে আলাদা হয়। Standalone bootstrap ও CLI fallback এখন পূর্ণ immutable commit SHA এবং full-URL-এ পাওয়া digest `060dbfa8489bc581ffa996d20b585616e628e227c6cc88d20a4429aa6fd4f3b5` ব্যবহার করে।
- Source change এখনও local। বর্তমান pinned commit-এ URL/test পরিবর্তন নেই, তাই owner repository sync অনুমোদন করে committed snapshot-এ source pin উন্নীত না করা পর্যন্ত `tests/bootstrap_source_sync.sh` parity difference দেখাবে। Focused suite: 211 passed. Shell syntax ও `git diff --check`: passed।
- Fresh install-এর পরে live host-এ local CLI phase আলাদাভাবে চালানো হয়েছে। আগের host CLI/module `~/.cache/ternux-v2-local-live-backup-2026-11-19/`-এ backup ছিল; installed `core.sh` ও `phases.sh` hash local source-এর সঙ্গে হুবহু মেলে, `ternux` ও `tx` v2.0.1 দেখায়, এবং `tx verify alpine` pass করেছে।
- Deploy-এর পর live `tx verify` Debian, Ubuntu, Kali ও Alpine—চারটিতেই pass করেছে। `tests/docs_check.py`-তে 6,638 assertion, 629 internal link ও 24 bilingual page pair pass করেছে। Focused suite 211/211 pass। Source-sync test আবার চালিয়ে fail পাওয়া গেছে, কারণ পুরোনো pinned archive-এ abbreviated URL আছে; এটিকে approval-gated pin refresh হিসেবে open রাখতে হবে, passing gate বলা যাবে না।
- Install caveat: Kali-র নির্বাচিত Xfce profile-এ 606টি base desktop package-এর সঙ্গে profile-selected application install হয়েছে; Alpine-এ 547টি base package এবং অতিরিক্ত locale/Avro/GPU/browser package হয়েছে। পরে storage check-এ প্রায় 60 GiB ফাঁকা ছিল। Installer ভুলভাবে Termux:API detect করতে পারেনি বলে জানিয়েছিল; পরের host check-এ companion app ও `termux-api` package installed নিশ্চিত হয়েছে। এই install-এ camera capture বা microphone permission request করা হয়নি। Android child-process setting পড়া যায়নি।
- এই install-গুলো বিদ্যমান Termux host-এ fresh guest setup প্রমাণ করে; clean Android বা Termux reinstall নয়। Desktop খোলা থাকা অবস্থায় Android PulseAudio process বন্ধ করলে recovery এখনও যাচাই হয়নি। Audio/install check-এ intermittent X11 stall পুনরুৎপাদন বা সমাধান—কোনোটিই হয়নি।

### Termux:API detection correction (২০২৬-১১-১৯)

- Install log-এ Termux:API unavailable বলা ভুল ছিল। Android package lookup (`pm path com.termux.api`, `cmd package path com.termux.api`) এবং Termux package state-এ companion app ও `termux-api` client package installed নিশ্চিত হয়েছে।
- কারণ: installer শুধু Android-এর `cmd package path` query করত; query ব্যর্থ হলেই app অনুপস্থিত ধরে নিত। Local `tnx_termux_api_app_installed` এখন ওই query-এর পরে Termux-এর `pm path` fallback ব্যবহার করে এবং app অনুপস্থিত বলে দাবি না করে “could not be detected” জানায়।
- `bash -n lib/phases.sh tests/focused.sh` pass করেছে। Regression test-এ `cmd` ব্যর্থ ও `pm` সফল দেখানো হয়। পূর্ণ `bash tests/focused.sh` 212/212 pass করেছে। Live installed `phases.sh`-এর SHA-256 local source-এর সঙ্গে মেলে এবং installed detector এই device-এ Termux:API detect করেছে।
- আগের permission probe skip হওয়া false negative-এর কারণে installer-এর আচরণ ছিল; companion app অনুপস্থিত থাকার প্রমাণ নয়। এই follow-up-এ camera capture এবং microphone permission status পরীক্ষা করা হয়নি।

### Local scope audit ও final test update (২০২৬-১১-১৯)

- LAI adapter প্রস্তাব করা পুরোনো v3 ADR মালিকের Ternux-only scope-এর সঙ্গে সাংঘর্ষিক ছিল। ADR-0003 identifier অক্ষুণ্ণ রেখে rejected historical proposal হয়েছে; v3 architecture, roadmap, AI runtime ও component map এখন Ternux-owned workload এবং unrelated product integration না থাকার সীমা জানায়। English ও বাংলা scope summary মিলিয়ে দেওয়া হয়েছে।
- বর্তমান device/feature matrix-এ তিন নতুন distro-র audio playback, Termux:API detector correction এবং window-helper evidence যোগ হয়েছে। চার guest-এর hash মিললেও interactive move/resize সরাসরি শুধু Debian-এ পরীক্ষা হয়েছে।
- Local final checks: `bash tests/focused.sh` 212/212; `python3 tests/docs_check.py` 6,638 assertion, 632 internal link, 24 bilingual pair; `bash -n` ও `git diff --check` pass।
- `bash tests/bootstrap_source_sync.sh` পুরোনো immutable pin-এ abbreviated codeload ref ও বর্তমান source change না থাকায় fail করেছে। Approval-এর পরে exact committed snapshot pin করতে হবে; এটি open gate।
- GitHub read-only check-এ PR #298 open এবং বর্তমান remote commit-এ একটি shell/documentation job fail। Reconciliation header-এর চার লাইনের trailing whitespace-এ `git show --check` fail করেছে। Local working tree-তে whitespace সরানো হয়েছে; approved repository update-এর পরেই remote check আবার চলবে।
- v1.4.0 live release page published এবং dedicated v1.4.0 guide-এ link করে। Tag `3e6c07e2afcb5f1e65ecd57af19b0382a948835a`, binary asset নেই; tag অনুযায়ী version ও command যাচাই করা হয়েছে। v2.0.1-এর tag, release page বা asset এখনও নেই।

- সর্বশেষ read-only host status-এ Debian `:1`, Ubuntu `:2`, Kali `:3` এবং Alpine
  `:4`—চারটিই `READY`; X11 চলছে এবং PulseAudio route ready। আলাদা `tx verify`
  চারটিতেই pass করেছে। এই check-এ guest lifecycle বা audio service বদলানো হয়নি;
  এটি intermittent X11 stall হওয়ার সম্ভাবনা নাকচ করে না।

### Initial optional-workload selector regression (২০২৬-১১-১৯)

- Real PTY menu test ও aggregate focused suite-এ `jq` যোগ হয়েছে। Test-এ
  keyboard navigation এবং numeric entry—দুইভাবেই initial interactive selector
  থেকে `jq` ফেরত আসা নিশ্চিত হয়। Existing package-phase regression যাচাই করে যে
  নির্বাচিত APT workload sudo/stdin prompt ছাড়া guest root হিসেবে চলে।
- `python3 tests/workload_menu_pty.py . jq` pass এবং পূর্ণ focused suite 215/215
  pass। Live clean Ubuntu install-এ initial menu থেকে `jq` select করে একই run-এ
  install হয়েছে। এটি `jq`-র reported install path সরাসরি cover করে; অন্য
  selection-গুলোর জন্য app-specific live check এখনও বাকি।

## Blender/ADT-এর ঐচ্ছিক qualification — ২০২৬-১১-১৯

Numeric multi-selection delimiter এবং ADT prerequisite-এর ঘাটতি local code-এ
ঠিক হয়েছে। exact Blender + Ternux ADT Build Tools live workload Debian, Ubuntu
ও Kali-তে package install এবং Blender/Java/sdkmanager/aapt2 smoke check pass।
Alpine-এ এখন `xvfb-run` ও NumPy-সহ Blender APK recipe আছে; Blender background ও active-Xfce GUI smoke test pass। Kali Blender 5.2 asset
add-on-এর জন্য `python3-cattr` ও `python3-requests` দরকার ছিল; workload এখন
দুটিই install করে। Integrated ADT binary এখন Alpine musl/PRoot runtime-এর সঙ্গে
compatible নয়: Java executable memory page map করতে পারে না এবং `aapt2`-এর
প্রয়োজনীয় glibc symbol নেই। Alpine selector শুধু Blender দেখায়, ADT আগেই reject
করে। বিস্তারিত evidence readiness report-এ আছে। অর্থাৎ সব baseline distro-তে
ADT চালানোর owner request পুরোপুরি পূরণ হয়নি; এই দাবি দিয়ে v2 release-ready নয়।
