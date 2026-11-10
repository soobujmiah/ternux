---
title: "Ternux v2.0.0 release readiness"
description: "Ternux v2 release audit, verified evidence, and remaining gates."
lang: "bn"
alt_url: "/docs/V2-RELEASE-READINESS.html"
---

**অবস্থা: NOT_READY**

**অডিটের তারিখ:** 2026-11-10

**Ternux v2.0.0 tag/publication:** তৈরি করা হয়নি

**সর্বশেষ source baseline:** `main` commit `bacb6dc35246deccb6473fb6ba4737b0e9b244b5` (2026-11-10 15:27 UTC; generated-state merge; PR #116-এর Ternux product source অপরিবর্তিত)

**সর্বশেষ v2 integration PR:** [#97](https://github.com/soobujmiah/ternux/pull/97), merge commit `394d0d12e972dd977cd7ec8c639caaead84b1b40`

**বর্তমান blocker:** ছয়টি release gate অসম্পূর্ণ; canonical signed APT endpoint চারটিই HTTP 404। v2.0.0 tag/release নেই। Pages run `42816692044` deploy চলাকালে cancel হয়েছিল, external effect unverified; deploy এখন manual-only, কোনো v2 publication হয়নি। Non-deploy signing verification `42831035262` main `97e2ac6`-এ pass করেছিল, তবে website upload/deploy skip করেছে।

### সর্বশেষ live reconciliation — 2026-11-10 15:34 UTC

- **Stage 0 repository ও কাজের reconciliation:** `origin` যাচাই করা হয়েছে `https://github.com/soobujmiah/ternux.git`; local `main` clean এবং `origin/main`-এর সঙ্গে `bacb6dc35246deccb6473fb6ba4737b0e9b244b5`-এ মেলে। Active source worktree-তে staged, unstaged বা untracked file নেই। Detached `ternux-package-audit` `727726a6`-এ তার আগের untracked `ci-artifact/`-সহ অক্ষত; এটি unsigned historical build evidence। আলাদা `ternux-tools` checkout-এর ছয়টি owner-modified/untracked accelerator ও QNN research entry অপরিবর্তিত। আর কোনো agent সক্রিয় নেই।
- **Branch ও PR:** PR #97 merged। Workload schema/installer migration PR #116 `5071d3390d7f941bfc708b0864c7052103eb1c81`-এ; P2-03 evidence PR #117 `6a78db24c78a4d4199156b17774a24c11fb9b6e4`-এ; generated-state PR #118 `bacb6dc35246deccb6473fb6ba4737b0e9b244b5`-এ merge হয়েছে। Open PR #45/#44/#42 Dependabot action update; #35 owner-review license proposal। পুরোনো IBus Ctrl+Space branch-এর সমতুল্য trigger reset ও test `main`-এ আছে। আলাদা HTP broker branch experimental; প্রকাশিত HTP archive-এ manager-এর প্রয়োজনীয় broker/launcher ও license inventory নেই, তাই সেটিকে stable path-এ তোলা হয়নি। অন্য unmerged evidence branch পুরোনো, অসংশ্লিষ্ট বা release-excluded; কোনো worktree বা owner edit বাদ দেওয়া হয়নি।
- **Exact main CI:** merge commit `bacb6dc`-এ Validate `42844437275`, Termux package-artifact `42844437171`, Repository State Contract `42844437133` pass। আগের report commit-এর Repo Knowledge Sync `42844002371`-এ test/sync pass; তার generated-state PR #118 merge-এর আগে সব required check pass করেছে। PR #116/#117-এর exact-head check-ও pass। এগুলো source, documentation ও package build check; native clean install বা release publish প্রমাণ করে না।
- **Live native Termux ও device:** physical target property-তে Xiaomi `25053RT47C`, Android 16 / API 36। Installed package `ternux 2.0.0`; `dpkg -V ternux`-এ local modification report আসেনি। Installed `ternux status --json`-এ `READY`, X11 ও PulseAudio running। Current repo module live session-এ চালিয়ে (`TERNUX_LIB_DIR=$PWD/lib ternux status --json` ও `verify --json`) `READY` এবং `passed` এসেছে। Codex-এর `LD_LIBRARY_PATH` unset করলে `adb` কাজ করে। App input, screenshot, desktop stop/restart বা installed file বদলানো হয়নি। 15:31 UTC-তে battery temperature 42.5°C; `doctor --quick` sustained heavy work স্থগিত রাখতে বলেছে। Current `lib/desktop.sh` SHA-256 `b3f0753a771f54c2c337310b2f23485926c9fded314ace818d76828c96af8ea3`; installed `$PREFIX/lib/ternux/desktop.sh` SHA-256 `02c5f6175f45c94c4ec68f323294f1c633bd7e4f501430b243f72132ed0950cb`। তাই live session updated package-এর stop/crash lifecycle প্রমাণ করে না। এই execution sandbox-এ repo/home-এই write অনুমোদিত; native `$PREFIX` install/upgrade/uninstall করা যায়নি।
- **Hosted APT ও release artifact:** 15:30 UTC-তে HTTPS GET করে `apt/bootstrap.sh`, `apt/ternux-archive-key.asc`, `apt/dists/stable/InRelease`, `apt/dists/stable/main/binary-all/Packages`—চারটিই HTTP 404। GitHub-এর latest stable release v1.4.0; v2.0.0 tag/release নেই। চারটি workload prerelease আছে, তবে HTP experimental এবং বর্তমান archive-এর কারণে blocked। APT publish, Pages deploy, v2 tag বা release publication করা হয়নি; `release_approved` এখনও false।
- **বর্তমান gate matrix:** P0-01/02/03, P1-02/05, P1-DOCS, P2-03/04 complete। ছয়টি release blocker: P1-01, P1-03, P1-04, P1-06, P1-APT, P1-PKG। P1-07/P1-08 experimental ও release-excluded; P2-01 শুরু হয়নি; P2-02 ও P2-DEVICE আংশিক, non-blocking। প্রতিটি gate-এর evidence নিচে এবং `docs/release-gates.json`-এ আছে।

#### Release-এর ঠিক বাকি blocker

1. **P1-01 — Desktop lifecycle:** updated installed package-এ stop, restart, crash recovery ও managed-process identity যাচাই। Source test ও non-disruptive live readiness pass, কিন্তু installed module hash পুরোনো।
2. **P1-03 — Updater:** native device-এ v1.4.0 থেকে published v2 migration ও rollback যাচাই। Exact v1.4.0 local source-fixture test pass; v2 release নেই।
3. **P1-04 — Storage/security:** নতুন package দিয়ে storage isolation ও full XFCE/user-app smoke test। `/sdcard` preserve এবং host-HOME isolation test pass; updated-package visual/app validation বাকি।
4. **P1-06 — CPU/Vulkan AI:** আরও model-এ known-answer, fallback, memory pressure, sustained thermal, repeated run, cancellation ও cleanup পরীক্ষা। Adreno 825 offload/correctness evidence আছে, তবে তা short-run।
5. **P1-APT — Public repository:** সব gate close ও owner-এর explicit release approval-এর পর signed APT publish; এরপর hosted path, সাধারণ Pages deploy-এ preservation এবং clean Termux `pkg install/upgrade/uninstall` flow verify।
6. **P1-PKG — Native package lifecycle:** actual Termux-এ clean install/update/repair/uninstall এবং metadata/checksum যাচাই। CI artifact ও installed package integrity pass; fresh device lifecycle test হয়নি।

সামগ্রিক recommendation এখনও **NOT_READY**। Machine-readable ১৯-gate inventory একই ছয় blocker দেখায়। Green CI-কে stable release বা production deploy-এর প্রমাণ হিসেবে ধরা যাবে না।
> বর্তমান অবস্থার নোট (2026-11-10): নিচের reconciliation ও gate matrix এই রিপোর্টের আগের snapshot-গুলোকে supersede করে, যেখানে PR #97 open, independent reviewer বাধ্যতামূলক, বা পুরোনো `main` commit দেখানো হয়েছে। সেগুলো কেবল historical evidence।

### সর্বশেষ repository reconciliation — 2026-11-10

- **Repository:** audit intake-এ `origin/main` ছিল `195304de13dce6e7c2c0d12163b6cba80e571030`; বর্তমান main `97e2ac6524d2b206d6e24c0e813f9656eda13941`। PR #108/#110 evidence update এবং #109/#111 generated `.repo` state sync। release tag নেই।
- **PR #97:** v2 source integration `394d0d12e972dd977cd7ec8c639caaead84b1b40` হিসেবে merge; main `bdae6d70c9015f6893bad4f81f79e3f1e059e41d`-এ পাঁচটি required check pass (Validate `42813902350`, package `42813902395`, repo-contract `42813902288`, repo-knowledge `42813902314` test/sync)।
- **PR #104:** manual-only Pages deploy ও readiness correction `87cf37304e350a5e74ff7d5458e27928fa852d11` হিসেবে merge; exact PR head `82425705e3248ee024c29a7e85cef5016a045715`-এ পাঁচটি required check pass (Validate `42818230722`, package `42818230539`, repo-contract `42818230660`, repo-knowledge `42818230597` test/sync)।
- **PR #105:** শুধু generated `.repo` state; পাঁচটি PR check pass করে `3c1a28d724a5a27d28aaf4eb9e52c65a71b7c470` হিসেবে merge। Current-main exact-SHA workflow pass: Validate `42819072679`, package `42819072756`, Repository State Contract `42819072717`, Repo Knowledge Sync `42818593252` (test ও sync)। PR #106-এর পাঁচটি exact-head check pass করে merge; current main `ea33209dee7845d0312cf8165eb2420d349020cc` CI চলছে।
- **PR #106:** documentation gate closure `ea33209dee7845d0312cf8165eb2420d349020cc` হিসেবে merge। Exact PR head `9f84ae1100d2de5d498ca44ed0b0491037ec610c`-এ Validate `42819629282`, package `42819629144`, repo-contract `42819629057`, Repo Knowledge Sync test/sync `42819629146` pass। Merge commit-এ Validate `42820001846`, package `42820001935`, Repo Knowledge Sync `42820001824` pass; exact PR-tree-তে repo-contract pass হয়েছে।
- **PR #107:** শুধু generated `.repo` state; Validate `42820215882`, package `42820215769`, repo-contract `42820215978`, Repo Knowledge Sync test/sync `42820215777`-সহ পাঁচটি PR check pass করে `5760a1f7eb98c86f731dcf24a982b929c7e5b018` হিসেবে merge। Merge commit-এর exact-SHA main workflow-ও pass: Validate `42820744142`, package `42820743872`, Repository State Contract `42820743837`।
- **PR #108:** bilingual release evidence update হিসেবে `a5abc1c1204460807a9bcd874a0a7dc3f759431a`-এ merge; PR head `0ff5b696679564dce16d69746265cdd76bbd9a53`-এ পাঁচটি check pass। Merge-SHA Validate `42822157291`, package `42822157290`, Repo Knowledge Sync `42822157263` pass।
- **PR #109:** শুধু generated `.repo` state; পাঁচটি check pass করে `7536e291b5a846f1b6c38665c834b19782dab624`-এ merge। Merge-SHA Validate `42823382729`, package `42823382687`, Repository State Contract `42823382682` pass।
- **PR #110:** measured CPU/Vulkan llama.cpp benchmark evidence `b998108e31d43c03fb5f4cc62ee5a0aae355de46`-এ merge; exact-head required check pass। **PR #111:** শুধু generated `.repo` state, বর্তমান main `97e2ac6524d2b206d6e24c0e813f9656eda13941`-এ merge; পাঁচটি PR check pass (Validate `42828281595`, package `42828281632`, repo-contract `42828281500`, Repo Knowledge Sync test/sync `42828281721`)। Current-main exact-SHA Validate `42828693127`, package `42828693381`, Repository State Contract `42828693104` pass।
- **Review protection:** main-এ PR ও পাঁচটি CI context বাধ্যতামূলক; strict checks ও admin enforcement চালু। Required approval শূন্য; CODEOWNERS review ও latest-push approval বন্ধ। Force-push ও branch deletion বন্ধ। একমাত্র collaborator owner। কোনো review impersonate বা fabricate করা হয়নি।
- **PR #104–#111:** উপরে বর্ণিত, সব merge হয়েছে; কোনো main push Pages workflow শুরু করেনি। অন্য open PR: #45 Dependabot (`CLEAN`); #44 ও #42 Dependabot (`BLOCKED`); #35 proposed license terms (`DIRTY`)। এগুলো v2 product integration PR নয়।
- **Native device evidence:** 2026-11-10 14:09 UTC-তে read-only source-module `status --json` lifecycle `READY`, functional X11, `pulseaudio_ready=yes`, desktop running দেখায়; installed CLI-ও X11/PulseAudio running দেখায়। আগের doctor run Android 16, Adreno 825, Zink/Vulkan 1.4 Turnip, Debian 13 aarch64, glibc 2.41 দেখায়। এতে নির্দিষ্ট GUI app render বা updated-package stop/crash recovery প্রমাণ হয় না। GUI/service restart করা হয়নি।
- **Source baseline `97e2ac6` ধরে local verification (report edits-ও revalidate করা):** focused suite 145/145 pass; updater transaction suite version/pinning/staging/rollback/crash/concurrency/symlink ও v1.4.0-to-v2 source-migration fixture pass; Stable Diffusion license-bundle test ও release-gate self-test pass; documentation check 3,072 assertion, 312 link, 20 bilingual page pair pass। Machine-readable readiness এখনও ছয়টি অসম্পূর্ণ blocker-সহ `NOT_READY`।
- **LLM device verification:** আগে থেকে installed `llama-vulkan` (upstream b11582, commit `af50f2f`) যাচাই করে ব্যবহার করেছি; extension replace করিনি, model copy/download করিনি। Existing Qwen2.5 0.5B Q4_0 (`/sdcard/Llms`) ও Qwen2.5 1.5B Q4_0 (`/sdcard/LAI/models`) CPU এবং Vulkan correctness smoke-তে `4` দিয়েছে। Adreno 825-তে bundled `llama-bench`: prompt 16 token + generation 64 token, 2 repeat, 8 thread। 0.5B CPU-only (`-ngl 0`) `5.99 ± 1.47 tok/s`, Vulkan0 (`-ngl 99`) `32.46 ± 0.45 tok/s`; 1.5B CPU-only `4.48 ± 0.12 tok/s`, Vulkan0 `21.27 ± 0.02 tok/s`। 1.5B Vulkan prompt processing `45.33 ± 0.14 tok/s`; verbose CLI log-এ layer 0–27 Vulkan0-তে এবং model memory প্রায় 885 MiB দেখা গেছে। এগুলো এক device-এর short repeated decode benchmark; sustained thermal/memory-pressure বা বিস্তৃত model qualification নয়.
- **অন্য কাজ:** আলাদা `ternux-tools`-এর owner edit/untracked native-AI qualification ও QNN probe, detached `ternux-package-audit` worktree-র untracked package artifact এবং SKB owner changes preserve করা হয়েছে।
- **Public APT / Pages:** 2026-11-10-এ canonical GitHub Pages URL-এ bootstrap, archive key, `InRelease`, `Packages`—চারটি endpoint HTTP 404 দিয়েছে। Signing verification run `42831035262` `97e2ac6`-এ সফলভাবে signed repository তৈরি ও verify করেছে, ephemeral key মুছে ফেলেছে; `verify-signing` mode হওয়ায় website build, Pages upload ও deploy skipped ছিল। আগের Pages run `42816692044` deploy action চলাকালে cancel হয়েছিল, external effect unverified। Public APT/site deploy, v2 tag, release publication করা হয়নি।

১৯টি gate-এর বর্তমান matrix: **COMPLETE** P0-01, P0-02, P0-03, P1-02 (পরীক্ষিত Adreno 825 stack), P1-05, P1-DOCS, P2-04; **PARTIAL** P1-01, P1-03, P1-04, P1-06, P1-07 (experimental/release-excluded), P1-08 (experimental/release-excluded), P1-PKG, P2-02, P2-DEVICE; **BLOCKED** P1-APT; **NOT_STARTED** P2-01; **COMPLETE** P2-03। ছয়টি gate এখনো release block করে: P1-01, P1-03, P1-04, P1-06, P1-APT, P1-PKG। Machine-readable inventory `NOT_READY` দেখায়। Main push-এ automatic Pages run `42816692044` শুরু হয়েছিল; `actions/deploy-pages` চলার সময় cancel করা হয়েছে। Workflow এখন manual-dispatch only। Pages root HTTP 200, কিন্তু deployment history API 404 হওয়ায় ওই run-এর external effect অনিশ্চিত।

## আগের audit archive — উপরের সর্বশেষ reconciliation দ্বারা superseded

### সর্বশেষ continuation snapshot — ২০২৬-১১-১০

### সর্বশেষ continuation — ২০২৬-১১-১০

Standalone bootstrap এখন commit `614d3b7d1ceda1ecd96107333b5d03795c4d5b7a` এবং archive SHA-256 `f55737a18eedff270ce32416ab55fbc070132dd02d41f0234f509f03f99cbf8c` pin করে। Focused test exact codeload URL verify করে এবং extraction-এর আগে byte-modified archive reject করে; local suite 145/145 pass। Follow-up change-এর আগে PR #97-এর exact-head-এ পাঁচটি required CI check pass ছিল; source change `985c5c5ae1c942315c5e3d0a85a9ffb3d3682a9d` হিসেবে push হয়েছে; exact-head-এর পাঁচটি required CI check pass। Release এখনও `NOT_READY`; validator আটটি incomplete blocker দেখায়।

### আগের session snapshot — উপরের সর্বশেষ reconciliation দ্বারা superseded

- **Repository:** `origin/main` হলো `8e24062589e81c20095c875fa4d19dd5cb928554`; active branch `fix/managed-htp-extension-prerequisites` clean head `6f8e8344c13d6cf2013ab7f9a6dc7cf6df836ac8`-এ, এবং `main` তার ancestor। Branch-টি ১৮৩ commit এগিয়ে; PR #97-এ ৫৮১টি file পরিবর্তিত (+১৩,৯৭৫/−১,৩৮৬)। এই continuation-এর desktop change-এর আগে এই checkout-এ staged, unstaged বা untracked কাজ ছিল না।
- **Open PR:** #97 হলো v2 branch; #45/#44/#43/#42/#41 Dependabot action update; #35 আলাদা proposed-license review। Signed APT setup-এর PR #96 merged। PR #97 non-draft, author `soobujmiah`, review request নেই; GitHub `REVIEW_REQUIRED`/`BLOCKED` দেখায়।
- **CI:** exact head `6f8e8344c13d6cf2013ab7f9a6dc7cf6df836ac8`-এ পাঁচটি required check pass: Validate `42801811480`, Termux package `42801811821`, repository contract `42801811505`, Repo Knowledge Sync `42801811494` (`test` job `129780954399`, `sync` job `129781022516`)।
- **Protection:** live read-back-এ strict required check, একটি approval ও CODEOWNERS review, admin enforcement, stale approval বাতিল, latest-push approval, force-push নিষিদ্ধ এবং branch deletion নিষিদ্ধ দেখা গেছে। একমাত্র collaborator `soobujmiah`, যিনি PR #97-এর author; একই account দিয়ে independent review দেওয়া যায় না।
- **অন্য local state:** `ternux-package-audit` detached `727726a`-তে এবং untracked CI artifact অক্ষত। আলাদা `ternux-tools` checkout `main`-এ; owner-modified bilingual accelerator plan ও QNN research file অক্ষত। দুটিই PR #97-এর বাইরে। Live desktop restart করা হয়নি।

পূর্ণ reconciliation matrix: P0-01 COMPLETE; P0-02 PARTIAL; P0-03 COMPLETE; P1-01 PARTIAL; P1-02 শুধু পর্যবেক্ষিত Adreno 825-এ COMPLETE; P1-03 PARTIAL; P1-04 PARTIAL; P1-05 protection configured, কিন্তু PR integration P0-02-এর অধীনে বাকি; P1-06 PARTIAL; P1-07 ও P1-08 PARTIAL এবং release থেকে বাদ; P1-APT BLOCKED; P1-PKG/P1-DOCS PARTIAL; non-blocking P2-01 NOT_STARTED; P2-03 COMPLETE; P2-02 PARTIAL; P2-04 COMPLETE; P2-DEVICE PARTIAL। Release validator-এ ১৯টি gate এবং ছয়টি অসম্পূর্ণ release blocker। Retained HTP candidate experimental-ই থাকবে, stable release claim নয়।


এই report-only refresh-এর আগে audited PR head ছিল `8041c33939fc00639fe3296779ba840a352f82a3`, `main`
(`8e24062589e81c20095c875fa4d19dd5cb928554`)-এর চেয়ে ১৭২ commit এগিয়ে;
GitHub ৫৭৬টি changed file, review-ready state ও `REVIEW_REQUIRED` দেখায়। এই exact
head-এ পাঁচটি required check-ই pass করেছে: Validate `42792959040`, Termux APT
package `42792958963`, repository contract `42792959029`, এবং Repo Knowledge Sync
`42792959241`-এর `sync` ও `test` check। HTP candidate run `42783356495` পুনর্ব্যবহারের
exact publisher verifier-ও pass করেছে: source ancestry, build definition, package input,
run/artifact provenance ও expiry যাচাই হয়েছে। Public prerelease-এ এখনো পুরোনো archive;
প্রকাশনা `main`-এ owner/CODEOWNERS review ও merge-এর অপেক্ষায়।

সর্বশেষ exact-head follow-up: PR #97 এখন `b97ea9965865c602d0119f8f8916e0430e06d847` commit-এ। পাঁচটি required check-ই pass করেছে: Validate `42798314264`, Termux APT package `42798314373`, repository contract `42798315057`, Repo Knowledge Sync `42798315019`-এর `sync` ও `test`। GitHub এখনো `REVIEW_REQUIRED`, `BLOCKED`; কোনো review request বা approval নেই। `.github/CODEOWNERS`-এ শুধু PR author `@soobujmiah`; collaborator তালিকায় শুধু owner, আর non-owner review entry-গুলো bot comment। PR merge ও main-only HTP publisher চালাতে independent human reviewer লাগবে।

এই exact head-এ HTP source run `42783356495`-এর জন্য no-rebuild verifier আবার চালিয়ে pass করেছে; source ancestry, artifact provenance, অপরিবর্তিত build input, এবং successful source run যাচাই হয়েছে। Actions artifact `13747701121` এখনো ২০২৭-০২-০৮ পর্যন্ত মেয়াদোত্তীর্ণ নয়। এই যাচাইয়ে artifact download বা rebuild করা হয়নি। Public prerelease-এ এখনো পুরোনো archive; protected merge না হওয়া পর্যন্ত retained candidate publish করা যাবে না.

Public experimental HTP prerelease আছে, তবে এখনো ২০২৬-১০-১৩-এর পুরোনো archive
serve করছে (SHA-256 `dffcf83fa969f3ccfad238217b4ca7f3d47040e5e5b2fa834ebd3f123d144ea5`)।
সর্বশেষ retained candidate run `42783356495`, artifact `13747701121`; archive
SHA-256 `a139a6248356a44e89348ddbe1334edaad33f81a9efbe8f5b8fe3c5733dcf3de`, size
১৫,৬৯১,৩২৩ byte; ২০২৭-০২-০৮ পর্যন্ত রাখা আছে। Artifact download করে sidecar
checksum মেলানো হয়েছে। PR integrate হলে `main`-only publisher এই run পুনর্ব্যবহার
করে আর compile ছাড়াই existing experimental prerelease update করতে পারবে। এতে
HTP stable support হিসেবে qualified হয় না।

এই রিপোর্ট source ও CI-র প্রমাণকে বাস্তব ডিভাইস পরীক্ষার থেকে আলাদা রাখে। Build সফল হলেই GPU, desktop, package installation বা accelerator workload release-ready প্রমাণ হয় না।

## ঐতিহাসিক Stage 0 repository snapshot — উপরের সর্বশেষ reconciliation দ্বারা superseded

এই report-only refresh-এর আগের validated PR snapshot-এ `ternux-task-fix` clean ও remote-এর সঙ্গে synced ছিল, head `6fd2772e4245be0069bf8777ee00c01a16c51aac`; `origin/main` (`8e24062589e81c20095c875fa4d19dd5cb928554`)-এর চেয়ে ১৬৯ commit এগিয়ে। PR #97 open/draft, ৫৭৬টি changed file; নতুন branch protection অনুযায়ী GitHub `REVIEW_REQUIRED` দেখায়। v2 tag নেই। Diff মূলত Ternux CLI/assets, Debian packaging, bilingual docs, test/CI ও AI experiment। পুরো ৫৭৬-file review এবং owner review বাকি।

| স্থান | বর্তমান অবস্থা | সমন্বয় |
|---|---|---|
| `ternux-task-fix` | `6fd2772`-এ clean; ১৬৯ commit এগিয়ে; PR-এ ৫৭৬ file | PR #97 draft; owner/CODEOWNERS review না হওয়া পর্যন্ত merge হবে না; v2 tag/publication হয়নি। |
| `ternux-package-audit` | detached `727726a6`; untracked `ci-artifact/` ৭৪৭ KB | metadata অনুযায়ী এটি ৭ Nov-এর unsigned package/rootfs, source `b3a0f894…`; পুরোনো evidence হিসেবে রাখা হয়েছে, release diff-এ যোগ করা হয়নি। |
| `ternux-tools` | `main`-এ ছয়টি owner-modified/untracked QNN qualification entry | সব অপরিবর্তিত রাখা হয়েছে; এগুলো আলাদা research artifact, release source নয়। |
| `skb` | canonical checkout যাচাই করা; owner change আছে | শুধু guidance পড়া হয়েছে; file পরিবর্তন হয়নি। |
| `.repo/STATUS.md` | `main` থেকে generated snapshot; ৭ Nov-এ `aadc925`-এ sync | `python3 -m tools.repo_knowledge verify`-তে কোনো finding নেই। হাতে edit করা হয়নি; PR head-এর state exact-head CI-তে আছে। |
| চলমান Termux:X11 desktop | active; session restart করা হয়নি | session অক্ষত রাখা হয়েছে; desktop, audio বা Android service restart করা হয়নি। |

এই session-এ subagent spawn করা হয়নি। PR #35 আলাদা draft license proposal; owner review-এর অপেক্ষায়, v2 source-এর অংশ নয়। পাঁচটি open Dependabot PR action version update নিয়ে, release diff-এর বাইরে। Owner-authorized `main` branch protection এখন সক্রিয়: পাঁচটি exact CI context, ১টি approval, CODEOWNERS review, stale approval dismiss, latest-push approval, admin enforcement, conversation resolution, force-push ও deletion নিষিদ্ধ। Ruleset শূন্য, তবে branch protection আলাদাভাবে সক্রিয়। PR #97-তে owner review বাকি।

| Finding | সমন্বিত অবস্থা | Evidence/বাকি কাজ |
|---|---|---|
| P0-01 SD Vulkan license inventory | COMPLETE | Deterministic component manifest ও bundle regression test আছে; Ternux license সঠিকভাবে Apache-2.0। Exact-head ARM64 audit নিচে আছে। |
| P0-02 release branch consistency | PARTIAL | `main` ancestor; draft PR #97-এ ১৬৯ commit ও ৫৭৬-file diff আছে। Current checks pass; branch protection owner/CODEOWNERS review বাধ্যতামূলক করেছে। |
| P0-03 machine release gate | COMPLETE | ১৯টি gate; blocking item থাকলে readiness `NOT_READY`; এখন ৮টি blocker incomplete। |
| P1-01 desktop lifecycle | PARTIAL | ownership/state handling ও host fixture pass; updated package-এ device start/stop/crash recovery বাকি। |
| P1-02 Vulkan/renderer detection | পরীক্ষিত Adreno 825 stack-এ COMPLETE | Enumeration ও live Zink/Turnip evidence আছে; অন্য GPU family qualify হয়নি। |
| P1-03 updater | PARTIAL | exact v1.4.0 CLI fixture থেকে v2 source-level migration pass। Standalone installer immutable source archive extract করার আগে verify করে; publication-এর পর public route ও native-device migration verify করতে হবে। |
| P1-04 storage ও desktop | PARTIAL | PRoot থেকে Android shared storage-এর স্বাভাবিক `/sdcard` access verified; Termux HOME isolated, `/tmp` explicit। বাকি শুধু updated launcher-এ full XFCE/app smoke। |
| P1-05 repository governance | COMPLETE | Owner-authorized `main` protection-এ ১টি CODEOWNERS approval ও পাঁচটি CI context লাগে; admin-দেরও মানতে হবে, force-push/deletion বন্ধ। PR #97 `REVIEW_REQUIRED`; সেটি P0-02। |
| P1-06 CPU/Vulkan LLM | PARTIAL | known-answer, offload, cancel, reopen evidence আছে; model breadth, sustained thermal ও memory-pressure qualification বাকি। |
| P1-07 HTP/HMX | PARTIAL, experimental এবং release থেকে বাদ | Build evidence আছে; operator numerical qualification অসম্পূর্ণ/ব্যর্থ হওয়ায় stable claim/default নয়। |
| P1-08 QNN Stable Diffusion | PARTIAL, experimental এবং release থেকে বাদ | Device artifact আছে; পূর্ণ stage-tensor/reference qualification হয়নি। |
| P1-APT / P1-PKG | BLOCKED / PARTIAL | Signed pipeline কাজ করে, কিন্তু hosted APT-এর চারটি URL-ই 404; সাধারণ Pages deploy-তে signed repository preserve করার check যোগ হয়েছে, কিন্তু native clean install, upgrade, uninstall unverified। |
| P1-DOCS | PARTIAL | README, install/update/remove guide, troubleshooting, changelog, security ও accelerator matrix আছে; Readiness report বর্তমান evidence-এ refresh হয়েছে; owner review বাকি। |
| P2 modularization / test architecture / workload schema | NOT_STARTED / PARTIAL / NOT_STARTED | Incremental/non-blocking রাখব; release gate না মিটিয়ে risky one-shot refactor করব না। |

## Repository ও কাজের অবস্থা

নিচের original inventory ৯ Nov-এর audit checkpoint; বর্তমান ১০ Nov Stage 0 snapshot ও reconciliation matrix উপরে আছে।

| অবস্থান | অডিট শুরুর অবস্থা | কী করা হয়েছে |
|---|---|---|
| `ternux-task-fix` | `fix/managed-htp-extension-prerequisites`, `8101fa5e51f0f5b28c51a35b4d714cd0836c0026`-এ clean; বর্তমান `main` (`8e24062`)-এর ওপর | সক্রিয় v2 PR #97; নতুন fix এই branch-এ থাকবে। |
| `ternux-tools` | আলাদা `main` checkout, `9fda631`; ছয়টি owner-modified/untracked entry, যার মধ্যে native AI qualification script ও evidence আছে | নিজ জায়গায় অক্ষত রাখা হয়েছে। যাচাই ছাড়া release PR-এ যোগ করা হয়নি; এগুলো Ternux-এ HTP/QNN integration-এর প্রমাণ নয়। |
| `ternux-package-audit` | Detached checkout `727726a`; untracked `ci-artifact/`-এ generated Ternux 2.0.0 package/rootfs ও doctor snapshot | `build-info.txt` থেকে provenance read-only verify: project commit `b3a0f894…`, package builder `a7e20f9…`, APT builder `f2bf088…`; artifact স্পষ্টত unsigned CI output, Nov 7-এ তৈরি। Local test evidence হিসেবে অক্ষত রাখা হয়েছে; stage/move/delete করা হয়নি। এটি current head বা signed/public package-এর evidence নয়। |
| `skb` | canonical remote যাচাই করা; checkout-এ owner পরিবর্তন আগে থেকেই ছিল | শুধু কাজের নির্দেশনা পড়া হয়েছে; কোনো ফাইল বদলানো হয়নি। |
| Live desktop | read-only status-এ `running`; supervisor PID `16987`, Termux:X11 PID `16779`, PulseAudio PID `16492`, XFCE PID `20829` | চালু ও অক্ষত রাখা হয়েছে। GUI restart বা installed file বদলানো হয়নি। |

আলাদা owner checkout-এর পূর্ণ তালিকা `git -C ~/ternux-tools status --short`-এ আছে; কোনো ফাইল বাদ দেওয়া হয়নি।

### Remote branch

- PR #97 `main`-কে target করে draft অবস্থায় আছে। অডিট শুরুর head বর্তমান main baseline-এর ওপর 122 commit এগিয়ে ছিল।
- Draft PR #35 (`codex/license-terms-review-20261016`) first-party material-এর জন্য PolyForm Noncommercial terms ও notice প্রস্তাব করে। এটি Sobuj-এর license review-এর অপেক্ষায়; merge হয়নি বা v2-তে নেই। `main`-এর বর্তমান license Apache-2.0, তাই এই proposal বর্তমান release-এর জন্য দরকারি নয় এবং এটিকে কার্যকর license বলা যাবে না।
- `origin/codex/v2-reinstall-device-evidence-2026-11-07`-এর IBus Ctrl+Space fix PR source-এ সমতুল্যভাবে আছে।
- `origin/feat/apt-trust-channel-2026-11-06` current `main`-এর ancestor; branch-only commit নেই। `origin/fix/detached-desktop-service-2026-11-06` main থেকে 134 commit পিছিয়ে, branch-এ একটিমাত্র unique APT commit আছে। সেটি পরীক্ষা করে দেখা গেছে publish workflow থেকে `bootstrap.sh` executable assertion সরায়; current `main`-এ stricter check আছে এবং paired trust/install guide update করা। Cherry-pick দরকার নেই।
- পুরোনো HTP soak ও package smoke evidence বর্তমান পরিকল্পনার চেয়ে পুরোনো। Native AI evidence বর্তমান source/runtime-এর সঙ্গে মেলানো না পর্যন্ত owner-local থাকবে।

## Priority zero gate

| Gate | ফল | Evidence / বাকি কাজ |
|---|---|---|
| Stable Diffusion dependency notice | **`8101fa5`-এ ঠিক; CI পাস** | Upstream component/license mapping, header notice, deterministic manifest/checksum, optional dependency handling ও regression test যোগ হয়েছে। বর্তমান change-এর পর CI আবার পাস করতে হবে। |
| Release branch consistency | **PR #97 current `main`-এর ওপর; merge/review বাকি** | Current `main` v2 PR head-এর ancestor। পুরোনো APT trust branch-ও main-এর ancestor; detached-service branch-এর একমাত্র unique commit পরীক্ষা করে দেখা গেছে current workflow-এর চেয়ে দুর্বল। পুরোনো evidence branch পরীক্ষা করে release PR-এ অন্তর্ভুক্ত হয়নি নিশ্চিত করা। Release build-এর আগে owner review ও PR integration দরকার। |
| Release readiness gate | **এই রিপোর্টে যোগ হয়েছে** | বর্তমান verdict `NOT_READY`; শুধু CI green হলেই release-ready হবে না। |

## এই অডিটে করা পরিবর্তন

### Desktop lifecycle ও shared-service নিরাপত্তা

- Non-blocking `flock` lock যোগ হয়েছে, যাতে একসঙ্গে একাধিক `ternux start` duplicate launcher না চালায়; অপেক্ষমাণ caller `starting` পায়।
- Lifecycle state `STARTING`, `READY`, `STOPPING`, `STOPPED`, `FAILED`, `RECOVERING` যোগ হয়েছে; `ternux status --json`-এ `lifecycle` আছে।
- Session identity-তে PID, Linux `/proc` start time ও process-group ID থাকে। PID reuse হলে অন্য process-কে Ternux session ধরে না।
- Stop শুধু যাচাই করা Ternux process group-কে signal করে। Termux:X11, VirGL, PulseAudio, IBus globalভাবে বন্ধ করে না এবং shared X11/Pulse socket মুছে না।
- নতুন launcher নিজের যাচাইকৃত X11/VirGL child বন্ধ করে, নিজের তৈরি PulseAudio module unload করে এবং shared PulseAudio daemon চালু রাখে।
- পুরোনো launcher-এর identity file না থাকলে process group, launcher path, inherited `TNX_PID_FILE` ও start identity যাচাই করে তবেই stop হয়।
- Uninstall একই ownership-checked stop path ব্যবহার করে; direct-pipe uninstaller desktop module-ও download ও syntax-check করে।
- Desktop startup-এ launcher marker-এর পাশাপাশি Termux:X11 process, `xfce4-session`, `xfwm4`, `xfdesktop` এবং guest `xdpyinfo` round-trip boundedভাবে verify হয়; marker আসার পর সর্বোচ্চ তিনবার probe হয়।
- `ternux start --json` PulseAudio TCP route আলাদাভাবে `ready`/`unavailable` জানায়। Audio ব্যর্থ হলেও working desktop বন্ধ করা হয় না। Lifecycle lock ধরে নিরাপদে stop করা না গেলে `ternux restart` abort করে।
- এই source tree-তে focused regression ১৪৪/১৪৪ pass। Live desktop restart হয়নি; updated package-এর stop/crash recovery controlled device run এখনও বাকি।
- বর্তমান generated launcher contract version 19; আগের audit commit-এ version 18 ছিল। English/Bangla manual ও `killx` alias `ternux stop`-এর সঙ্গে মেলানো হয়েছে।

### যাচাইকৃত optional AI installer

- Hermes ও OpenClaw-এর optional setup এখন পরিবর্তনশীল URL-এর script সরাসরি Bash-এ pipe করে না। Script unique temporary file-এ download হয়, ২ MB সীমা, `bash -n`, এবং pinned SHA-256 pass করলেই execute হয়।
- Hermes-এর official `v0.23.1` release commit `3b421578588243f920886e6fe79a6faa87ea026e`-এ pinned; official bootstrap SHA-256 `abf338605dae6dd28d101673ac6aed7995c955745db46d47676bc591a7957209`।
- OpenClaw-এর official `v2026.11.2` release pinned; official bootstrap SHA-256 `5b46a876404005229ee62fc2615ddeb1c3f510a434ced47dbbed06b93849c704`।
- `tests/pinned_optional_installers.sh` সঠিক checksum-এ execution, mismatch-এ refusal, source allowlist, এবং temporary file cleanup যাচাই করে। Upstream script বদলালে reviewed version ও digest update না হওয়া পর্যন্ত install বন্ধ থাকবে।
- ২০২৬-১১-১০-এ first-party [Hermes install guide](https://github.com/NousResearch/hermes-agent/blob/main/website/docs/getting-started/installation.md), [Hermes installer source](https://github.com/NousResearch/hermes-agent/blob/v0.23.1/scripts/install.sh), এবং [OpenClaw install guide](https://docs.openclaw.ai/install)-এর সঙ্গে pin মেলানো হয়েছে।

### Vulkan ও renderer detection

- KGSL node বা loader/ICD file থাকাকে Vulkan readiness-এর প্রমাণ ধরা বন্ধ হয়েছে।
- Debian guest-এ `vulkaninfo --summary` চালিয়ে physical device type ও driver যাচাই হয়। আসল Turnip GPU-র পাশে llvmpipe থাকলেও CPU-only llvmpipe `SOFTWARE_FALLBACK`।
- `vulkan_state`: `NOT_DETECTED`, `HARDWARE_AVAILABLE`, `LOADER_MISSING`, `DRIVER_MISSING`, `ICD_MISSING`, `DEVICE_ENUMERATION_FAILED`, `VULKAN_READY`, `SOFTWARE_FALLBACK`। Live `glxinfo` non-software renderer দেখালেই `OPENGL_ACCELERATION_READY`।
- Live renderer query না পেলে Turnip file দেখে renderer দাবি করা হয় না। GPU documentation-এর English/Bangla দুই সংস্করণ হালনাগাদ।

### সাধারণ Pages deploy-তে signed APT repository অক্ষত রাখা

- `.github/workflows/deploy.yml` এখন shared `pages` deployment cancel না করে signed APT release-এর সঙ্গে serialize হয়। Website build-এর পরে Pages artifact upload করার আগে `packaging/termux/preserve-pages-apt.sh` চলে।
- Preservation helper production-এ শুধু official HTTPS Pages endpoint গ্রহণ করে। এটি pinned primary-key fingerprint যাচাই করে, signed `InRelease` verify করে, Release-এ উল্লেখিত প্রতিটি index-এর SHA-256 ও size মিলায়, Packages index পড়ে প্রতিটি package-এর SHA-256 ও size যাচাই করে। বর্তমান signature ও package রেখে দেয়, আর source repository-র bootstrap script যোগ করে।
- প্রথম publish-এর আগে deploy চলবে শুধু যখন `InRelease`, public key ও bootstrap—তিনটিই অনুপস্থিত। Network error, partial publish, invalid signature, unsafe signed path বা content mismatch হলে APT tree তৈরি করার আগেই site deploy থামে।
- `tests/termux_apt_pages_preservation.sh` generated signing key ও local HTTP fixture দিয়ে no-repository first deploy, inconsistent partial publication, valid signed preservation, tampered package rejection ও signed path traversal rejection পরীক্ষা করে। Local integration pass। Public APT endpoint এখনো 404 হওয়ায় live website redeploy test বাকি।

### Release-tag updater ও interrupted-update recovery

- Non-APT update এখন সর্বশেষ প্রকাশিত stable release দেখে এবং নতুন development build-কে downgrade হতে দেয় না।
- Updater exact `vX.Y.Z` tag থেকে Git commit resolve ও fetch করে; pin-এর সঙ্গে commit না মিললে source বাতিল করে। Installed file বদলানোর আগে tag/core version, CLI ও guest syntax, symlink-মুক্ত source layout এবং staged CLI response যাচাই করে।
- সম্পূর্ণ `lib/` tree target filesystem-এ stage হয়। আগের CLI ও module tree `$PREFIX/lib/ternux-update-backups/`-এ রাখা হয়। Journal-এ owner PID/start identity ও backup ID থাকে। একই filesystem-এ rename করে dispatcher ও module switch হয়; installed verification ব্যর্থ হলে আগের দুটোই restore হয়।
- Transaction চলার সময় installed dispatcher concurrent CLI call আটকায়। updater মাঝপথে বন্ধ হলে পরের CLI launch-এ আগের version restore হয়। সফল update-এর পরও backup থাকে।
- `tests/update_transaction.sh` স্থানীয় tagged Git repository দিয়ে exact commit, downgrade আটকানো, সম্পূর্ণ tree switch, failed-candidate rollback, dead-owner crash recovery এবং live-owner blocking যাচাই করে। এটি `3e6c07e2afcb5f1e65ecd57af19b0382a948835a`-এর published v1.4.0 dispatcher/core/updater fixture-ও local `main` branch-এর v2 source-এ update করে। Fake `proot-distro` live guest-কে স্পর্শ হতে দেয় না। GitHub Actions artifact ব্যবহার হয় না।
- ২০২৬-১১-১০-এ legacy migration fixture যোগ করার আগে PR head `4c8348d1a9199465c8f40b1f5b70530d19793154`-এ `bash tests/update_transaction.sh` pass করেছিল; exact-head Validate run `42794218577`-ও pass। এখন expanded test source-level migration cover করে; published-device migration বাকি।
- ২০২৬-১১-১০-এ `bash tests/update_transaction.sh` v1.4.0-to-v2 source-level migration fixture ও সব transaction case pass করেছে। এতে published v2 release বা physical-device migration qualify হয় না। Provenance হলো authenticated Git transport-এ আনা Git commit object ID; release tag cryptographically signed নয়। Native APT/public install transition এখনো unverified। বর্তমান stable metadata v1.4.0 আর v2 source version 2.0.0, তাই updater downgrade প্রস্তাব করে না।

### Continuation-এর file ও commit তালিকা

- `ce435e90cf4c4c4394d5bf2d0228858ad3ed34e2` updater transaction/recovery-এর জন্য `bin/ternux`, `lib/update.sh`, CLI help-এর `lib/help.sh`, নতুন `tests/update_transaction.sh`, `tests/focused.sh` এবং English/Bangla usage, installation ও readiness docs বদলেছে।
- `f3ba516ac6b5d6df0441c9db650e5b5ee090dcd5` ও `2cbf673599bc4e483cd0fc07af2265ba5dcc3b18` bilingual audit evidence আপডেট করেছে; product code বদলায়নি। এই documentation continuation-এ `SECURITY.md` এবং English/Bangla FAQ-তে বর্তমান guest bind behavior-ও স্পষ্ট করা হয়েছে। Pending report/security/FAQ change commit-এর আগে `tests/docs_check.py` ও `git diff --check` পাস করেছে।
- Updater code commit-এ 11টি file বদলেছে। `~/ternux-tools`-এর owner change, `~/ternux-package-audit`-এর শনাক্ত generated artifact এবং dirty `~/skb` checkout uncommitted ও অক্ষত আছে। এই continuation-এ artifact provenance read-only verify করা হয়েছে; PR #97-এ যোগ করা হয়নি.
- বর্তমান local focused verification: `bash tests/focused.sh` **134/134** pass করেছে; `python3 tests/docs_check.py`-তে **3,041 assertion, 312 internal link ও 20 bilingual page pair** pass; `git diff --check` pass। Exact-head hosted CI-ও নিচে নথিবদ্ধ। Published release migration এখনো unverified।
- আগের storage audit-এ default PRoot-Distro broad host binds ধরা পড়েছিল। পরের fix-এ Ternux managed desktop, guest-command wrapper ও `db`/`droot` alias isolated হয়েছে; ব্যবহারকারীর প্রয়োজনমতো `/sdcard` থাকে, Termux HOME গোপন থাকে, আর `/tmp` চাইলে share হয়। হাতে চালানো সরাসরি PRoot-Distro login তাদের upstream default-ই ব্যবহার করে।

## যাচাইয়ের প্রমাণ

### ২০২৬-১১-১০-এর বর্তমান exact-head audit

Core implementation ও regression fix `e8dab0a3cdb795826b3f583efbaef4a9a9320e51`-এ: isolated guest login ও স্বাভাবিক `/sdcard` access (`b9caeeb`), Stable Diffusion license metadata ঠিক করা (`6f6ae0c`), এবং regression coverage (`e8dab0a`)। Latest product-code head `aa2c5f1aeeed14e252c6c6d0669ceb745f6150f1` routine Pages deploy-তে signed APT preserve ও integration test যোগ করেছে। Validated evidence head `e1212bbc10078ec761dd5911f7858dbdc9b22c19`; পরের report-only sync commit `0a292c3f13d32d597b996304b86195d7be5ae343`। ওই evidence head-এ PR #97 draft ছিল, review decision ছিল না, এবং diff-এ ৫৭৩টি file ছিল।

এই exact implementation head-এ আটটি required workflow-ই pass করেছে:

| Workflow | Run ID | ফল |
|---|---:|---|
| Validate (Astro site, syntax, ১৩৪ focused regression, docs ও gate check) | `42693350220` | Pass |
| Termux unsigned APT package build/inspection | `42693350684` | Pass |
| Repository state contract | `42693350209` | Pass |
| Repo knowledge sync/test | `42693350631` | Pass |
| llama.cpp CPU + Vulkan ARM64 artifact | `42693350529` | Pass |
| Stable Diffusion CPU + Vulkan ও license audit | `42693350226` | Pass |
| Snapdragon HTP artifact | `42693350490` | Build pass; draft PR-এ publication skip |
| Snapdragon HMX capability candidate | `42693350221` | Build pass; draft PR-এ publication skip |

একই code-এ local `bash tests/focused.sh` **134/134** pass; `python3 tests/docs_check.py` **3,041 assertion, 312 internal link, 20 bilingual page pair** pass। `tests/release_gates.py --self-test`, JSON parser, shell syntax ও `git diff --check` pass করেছে। Astro production build-ও Validate workflow-তে pass। সেই পুরোনো code snapshot-এ ১৯ gate-এর মধ্যে নয়টি blocker অসম্পূর্ণ ছিল; P1-05 governance complete হওয়ার পর বর্তমান inventory-তে আটটি blocker আছে।

Latest product-code head `aa2c5f1aeeed14e252c6c6d0669ceb745f6150f1`-এ আটটি workflow pass করেছে। Validate-এ signed APT preservation fixture-ও আছে। Deployment workflow শুধু `main` push বা manual dispatch-এ চলে; তাই publication-এর পরে live Pages redeploy এখনো যাচাই হয়নি।

| Workflow | Run ID | ফল |
|---|---:|---|
| Validate (Astro site, ১৩৪ regression, signed APT preservation, docs ও gate) | `42704005351` | Pass |
| Termux unsigned APT package build/inspection | `42704005345` | Pass |
| Repository state contract | `42704005391` | Pass |
| Repo knowledge sync/test | `42704005633` | Pass |
| llama.cpp CPU + Vulkan ARM64 artifact | `42704005356` | Pass |
| Stable Diffusion CPU + Vulkan ও license audit | `42704005340` | Pass |
| Snapdragon HTP artifact | `42704005486` | Build pass; draft PR-এ publication skip |
| Snapdragon HMX capability candidate | `42704005958` | Build pass; draft PR-এ publication skip |

Report-only head `e1212bbc10078ec761dd5911f7858dbdc9b22c19`-এও আটটি required workflow pass করেছে: Validate `42707570617`, Termux APT package `42707570582`, repository contract `42707570627`, knowledge sync `42707570460`, llama CPU/Vulkan `42707570564`, Stable Diffusion/license `42707570566`, HTP `42707570651`, এবং HMX `42707570549`। Draft PR হওয়ায় APT ও accelerator artifact publication job যথাযথভাবে skip করেছে। Branch ওই head-এ clean এবং remote-এর সঙ্গে synced.

সর্বশেষ report-only head `b5cf839bdb5597392022ec21438cc45b9cf4e83c`-এ আটটি required workflow-ই pass করেছে: Validate `42712474036`, Termux APT package `42712474219`, repository contract `42712474435`, knowledge sync `42712474995`, llama CPU/Vulkan `42712474493`, Stable Diffusion/license `42712473855`, HTP `42712474195`, এবং HMX `42712474393`। Snapdragon build দুটিই সফল; PR #97 draft থাকায় publication job skip হয়েছে। এই evidence state-এ local docs check-এ ৩,০৪১ assertion, ৩১২ internal link ও ২০টি bilingual page pair pass করেছে; repo knowledge verification-এ কোনো issue পাওয়া যায়নি। সেই historical snapshot-এ নয়টি blocker খোলা ছিল; branch governance complete হওয়ার পর বর্তমান inventory-তে আটটি আছে।

### Lifecycle update-এর exact-head যাচাই

`f4bb945576f03a9d8979d7d89553660471dafbaf` commit 2026-11-10-এ আটটি required workflow-ই pass করেছে। Validate `42773827524`, Termux APT package `42773827442`, repository state `42773827490`, repo knowledge sync `42773827401`, llama CPU/Vulkan `42773827384`, Stable Diffusion CPU/Vulkan `42773827441`, HTP artifact `42773827791`, এবং HTP/HMX candidate `42773827449`—সব success। PR #97 draft থাকায় publication skip হয়েছে। Validate job-এ বর্তমান 140 focused regression এবং docs/gate check আছে। PR open, merge state clean, 573টি changed file, review decision এখনো নেই।

### Device ও distribution evidence

- Live Termux host-এ Ternux `2.0.0` installed; X11 ও PulseAudio চলছিল। চলমান desktop অক্ষত রাখা হয়েছে, service restart করা হয়নি।
- Isolated generic guest helper device-এ pass: `/sdcard` ব্যবহারযোগ্য ছিল, কিন্তু host Termux HOME-এর একটি file guest-এ দেখা যায়নি। User PRoot-এ shared storage চান; `/sdcard` থাকলেই bind হয়, Android permission Termux-এর permission flow দিয়েই আসে। Guest alias ও helper host HOME isolate করে; `/tmp` শুধু চাইলে share হয়।
- 2026-11-10-এ repo source module দিয়ে `TERNUX_LIB_DIR=$PWD/lib TERNUX_JSON=1 bash bin/ternux verify --json` চালিয়ে `status=passed` পাওয়া গেছে; Termux:X11, PRoot-Distro, PulseAudio, `setsid`, launcher, Debian service ও Turnip present/OK ছিল। GUI বা service restart হয়নি।
- 2026-11-10-এ একসঙ্গে দুটি source `start --json` call-এর result ছিল `starting` ও `already_running` (PID 16987); দুটিই success। পরে source `status --json`-এ `READY`, কার্যকর X11 এবং `pulseaudio_ready=yes` এসেছে। Process check-এ একই Termux:X11, PulseAudio, XFCE ও Ternux supervisor PID ছিল। এটি non-disruptive concurrent-start/reuse check; stop বা restart হয়নি।
- Retained HTP archive-এর SHA-256 ও inventory যাচাই করা হয়েছে, কিন্তু device-এ চালানো হয়নি। Preflight-এ battery 35.7°C এবং সর্বোচ্চ দেখা CPU thermal zone 50.8°C ছিল; exact-archive inference `NOT_TESTED`। আগের HTP ফল অন্য artifact-এর।
- আগের isolated desktop probe-এ X11 query, PulseAudio, mic status ও camera-info pass করেছে। তবে updated launcher-এ fresh XFCE/app visual smoke এখনো হয়নি।
- 2026-11-10-এ repository source-এর `start --json` চালু desktop-টিই reuse করেছে (`already_running`, PID 16987); এরপর source `status --json`-এ `READY`, সীমিত সময়ের guest X11 query pass, এবং `pulseaudio_ready=yes` এসেছে। Installed CLI-ও একই desktop running দেখিয়েছে। Stop/restart, app close বা installed file বদলানো হয়নি। এতে safe reuse এবং live X11/audio-route probe যাচাই হয়েছে; updated package-এর stop/crash recovery বা managed PID identity নয়।
- Lifecycle implementation এখন session live বলার আগে guest-এর ভেতর সীমিত সময়ের X11 query চায়, query ব্যর্থ হলে JSON mode-এ duplicate start আটকায়, এবং PulseAudio daemon ও guest TCP route আলাদাভাবে দেখায়। Focused regression local-এ 140/140 pass; lifecycle update commit `f4bb945`-এ Validate run `42773827524`-ও pass করেছে।
- SM8735 / Adreno 825 CPU ও Vulkan known-answer, Vulkan layer offload, bounded cancel ও reopen result `guides/device-benchmark-evidence.md`-এ আছে। Memory-pressure ও দীর্ঘ thermal test বাকি। HTP/HMX numerical failure স্পষ্ট রাখা হয়েছে; HTP ও QNN experimental, stable acceleration claim থেকে বাদ।
- Hosted signed APT bootstrap, public key, `InRelease`, `Packages`—চার URL-ই 2026-11-10-এ HTTP 404 দিয়েছে। Native `dpkg-query`-তে Ternux 2.0.0 installed, কিন্তু Ternux APT source configured নেই। Pages deploy আগে পুরো site tree upload করত, ফলে প্রকাশিত `/apt` মুছে যেতে পারত। `preserve-pages-apt.sh` এখন pinned key, signed `InRelease`, signed index checksum ও package checksum যাচাই করে APT tree ধরে রাখে। Signed-fixture integration test valid preserve pass করেছে এবং partial publish/tampering প্রত্যাখ্যান করেছে। Hosted path এখনো 404, তাই live redeploy preservation ও `pkg install ternux` lifecycle এখনো unverified।
- Owner-authorized GitHub branch protection `main`-এ সক্রিয় এবং পুনরায় read-back করা হয়েছে: strict required checks, এক approving review, CODEOWNERS review, stale approval dismissal, latest-push approval, admin enforcement, conversation resolution, এবং force-push/deletion বন্ধ। Repository ruleset শূন্য; active branch protection আলাদাভাবে প্রযোজ্য। `ternux-package-audit`-এর পুরোনো `ci-artifact/` ও owner-modified `ternux-tools` file release diff-এর বাইরে এবং অক্ষত।

### Heavy artifact build বারবার চালানো বন্ধ — ২০২৬-১১-১০

PR #97-এর artifact workflow-গুলোতে broad `pull_request` trigger ছিল। Path filter
পুরো PR diff match করায়, নতুন commit শুধু documentation বদলালেও প্রতিটি
`synchronize` event ARM64/HTP compile আবার চালাতে পারত। Head `9016bf9`-এর repeat
run-গুলো cancel করা হয়েছে: llama Vulkan `42774732346`, Stable Diffusion
`42774732436`, HTP `42774732564`, integer-HMX `42774732544`। চারটি heavy
workflow এখন শুধু manual dispatch-এ চলে। তিনটি optional artifact workflow আগের
successful run ID যাচাই করে, archive checksum মেলায়, এবং compile না করেই একই
archive নতুন ৯০ দিনের CI artifact হিসেবে upload করতে পারে। HMX candidate-এও এই
retention-refresh path আছে। আগের চারটি f4 artifact compile বা publish না করে পুনরায় verify ও refresh হয়েছে। Refresh run `42783356045` (Vulkan), `42783357108` (Stable Diffusion), `42783356495` (HTP), `42783356082` (HMX) pass করেছে; build ও publisher job skip হয়েছে। নতুন artifact ID যথাক্রমে `13747211879`, `13747515887`, `13747701121`, `13746772303`; সবগুলোর expiry 2027-02-08।
Provenance verifier pinned build job ও package input তুলনা করে, retention-only
workflow change অনুমোদন করে। Focused regression-এ ভুল workflow, expired artifact,
বদলানো package input/build definition, reuse এবং manual-only trigger-ও যাচাই হয়।

Artifact-reuse commit `89802f73408a1638221c0b3f62c26d212385b2ea`-এ Validate `42779265831`, Termux APT `42779265743`, Repository State Contract `42779266172`, Repo Knowledge Sync `42779266194` pass করেছে। audited PR head `8041c33939fc00639fe3296779ba840a352f82a3`-এ পাঁচটি required check pass করেছে: Validate `42792959040`, Termux APT package `42792958963`, Repository State Contract `42792959029`, এবং Repo Knowledge Sync `42792959241`-এর `sync` ও `test`; HTP candidate reuse verifier-ও pass করেছে। চারটি source-run refresh workflow-ও pass করেছে; সব compile ও publish job skip হয়েছে।

## v2.0.0-এর আগে বাকি blocker

| Gate | অবস্থা | দরকারি evidence |
|---|---|---|
| P0-02 branch ও owner review | **PARTIAL** | PR #97 ready, CI green; কিন্তু CODEOWNER/collaborator শুধু PR author। Trusted independent reviewer যোগ/অনুমোদন, ৫৭৬-file diff review ও PR merge বাকি। |
| P1-01 desktop lifecycle | **PARTIAL** | বর্তমান session না ভেঙে updated package-এ repeated/concurrent start, stop, stale/crash recovery, socket ownership ও audio readiness যাচাই। |
| P1-03 updater migration | **PARTIAL** | Published v2 update ও প্রথম v1.4.0 migration native Termux-এ পরীক্ষা; publication-এর আগে এটি সম্ভব নয়। Standalone bootstrap commit ও SHA-256 pin করে, tampered archive reject test সহ focused suite 145/145 pass করেছে। |
| P1-04 storage ও desktop | **PARTIAL** | PRoot-এর ভেতর স্বাভাবিক `/sdcard` ব্যবহার verified ও expected; Termux HOME isolated থাকে। Updated launcher-এ controlled/separate session-এ full XFCE ও app smoke বাকি। |

| P1-06 CPU/Vulkan qualification | **PARTIAL** | Supported hardware-এ memory-pressure, sustained thermal ও আরও model correctness evidence। |
| P1-APT public repository | **BLOCKED** | `aa2c5f1`-এ signed APT preservation code ও CI pass; owner-approved signed publish, hosted bootstrap/key/index verify, তারপর normal website redeploy ও clean `pkg install ternux` test বাকি। Canonical GitHub Pages-এর চারটি APT path এখনো HTTP 404 দিচ্ছে। |
| P1-PKG native package lifecycle | **PARTIAL** | Published APT route ও standalone route দিয়ে supported device-এ clean install, upgrade, repair, uninstall verify। |
| P1-DOCS final review | **PARTIAL** | Owner review; release note ও version surface published artifact/exclusion-এর সঙ্গে মেলানো। |

HTP/HMX ও QNN numerical/stage-tensor qualification pass না করা পর্যন্ত experimental/research-only থাকবে; stable হিসেবে দেখানো হচ্ছে না। Phase modularization ও বাকি test split P2 maintainability কাজ। Canonical workload manifest ও generated extension registry বাস্তবায়িত এবং tested। PR #35-এর proposed license owner-review-only; বর্তমান Apache-2.0 terms ও notice অক্ষত।

## চূড়ান্ত সুপারিশ

**NOT_READY.** P0-01, P0-03 ও P1-05 complete, কিন্তু আটটি release-blocking gate অসম্পূর্ণ। Product commit `f4bb945576f03a9d8979d7d89553660471dafbaf`-এ আটটি build/test workflow pass করেছে। audited PR head `8041c33939fc00639fe3296779ba840a352f82a3`-এ পাঁচটি required check pass করেছে: Validate `42792959040`, Termux APT package `42792958963`, Repository State Contract `42792959029`, এবং Repo Knowledge Sync `42792959241`-এর `sync` ও `test`; HTP candidate reuse verifier-ও pass করেছে। চারটি manual artifact refresh provenance/checksum pass করেছে, build/publish skip করে একই artifact 2027-02-08 পর্যন্ত সংরক্ষণ করেছে। এতে source/build check প্রমাণ হয়, public repository, installed package migration, live updated-desktop lifecycle বা owner review নয়। v2.0.0 tag/release, v2 APT package publication, PR merge বা live desktop restart হয়নি। Existing optional HTP prerelease-এর asset এখনো পুরোনো; latest retained archive-এর checksum ও no-rebuild reuse path উপরে নথিবদ্ধ। `main` branch-protection settings authorization অনুযায়ী বদলে verify করা হয়েছে; actual v2 release এখনো প্রস্তুত নয়।
