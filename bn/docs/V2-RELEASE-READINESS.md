---
title: "Ternux v2.0.0 release readiness"
description: "Ternux v2.0.0-এর repo audit, implementation evidence, device qualification ও বাকি release gate।"
lang: "bn"
alt_url: "/docs/V2-RELEASE-READINESS.html"
---
**অবস্থা: NOT_READY**
**Audit date:** 2026-11-11
**লক্ষ্য:** Ternux 2.0.0
**সর্বশেষ exact `main`:** `7bfac09c026ecd093da1e2ac1b7426bd36a6a0b5` (2026-11-11)
**Product source audit base:** `159806ff395a34349086504ae3055ddef21ddbec`
**সর্বশেষ stable release:** v1.4.0; v2.0.0 tag বা release নেই।
**Machine gate:** ১৯টি gate-এর মধ্যে P1-01, P1-03, P1-04, P1-APT, P1-PKG—এই পাঁচটি release-blocking gate অসম্পূর্ণ।

## সুপারিশ

এখনই v2.0.0 প্রকাশ করবেন না। Generated-state CI timeout ঠিক হয়েছে এবং Android storage এখন opt-in ও নির্দিষ্ট directory-তে সীমিত। Product PR #138/#139, audit PR #141 এবং generated-state PR #137/#140/#142 required CI পাস করে merge হয়েছে। Native package lifecycle ও updated-package desktop যাচাই বাকি, public APT-এর চারটি endpoint 404, আর পরীক্ষিত Qwen model-গুলো structured retrieval-এ ব্যর্থ হয়েছে।

## Stage 0 — repo ও কাজের পুনর্মিলন

Audit শুরুতে পরিষ্কার `main` ছিল `bcf363e10bc52a87fe2806a28f44dfdd220cf98f`। Open PR #137 ছিল CI-generated `.repo/` state update। সেখানে `Repo Knowledge Sync` first-run approval-এর অপেক্ষায় থাকলেও branch-filtered API query run-টি খুঁজে পায়নি, ফলে workflow timeout হয়। PR #138-এ unfiltered সাম্প্রতিক ১০০টি run থেকে exact SHA/branch মেলানো হয়েছে; bounded polling-সহ সব দরকারি check পাস করে এটি `5d4be243e8d3` হিসেবে merge হয়েছে। এরপর generated-state PR #137 check পাস করে `aff6aae40f8fa22bfe76a2a91e56f1ee10c51b60` হিসেবে merge হয়েছে। `.repo/` হাতে edit করা হয়নি।

PR #139 storage privacy implement করে সব required check পাসের পর `eaf97fc514c045193e7ef5968a95d1b26c449f9c` হিসেবে merge হয়েছে। Generated-state PR #140 সব check পাস করে `3c03dffa4ba07a2c0355613560c0768b45022c96` হিসেবে merge হয়েছে। এই audit PR #141 (`2763bac0cde5f38e2d3009eb236db2a89606f1c1`) এবং generated-state PR #142 (`f35fd95f60731c7d4638099285b7b314f459f4d2`) merge হয়েছে। Follow-up PR #143-তে bounded CPU/Vulkan model profile ও 90-day package-artifact retention নথিবদ্ধ; current-main merge `30bea68ff4440a97fc98a3f2c8b4d041e13c15f8`। Generated-state PR #144 check পাস করে `de52efcf5d4666dfa872c248d9370607a209c1ed` হিসেবে merge হয়েছে। Session-এর শুরুতে যাচাইকৃত SKB checkout-এ আগের dirty change ছিল; সেটি স্পর্শ করা হয়নি। অন্য কোনো active agent কাজ ছিল না। Open PR #42, #44, #45 Dependabot action update; PR #35 owner-review-এর licensing proposal, merge করা হয়নি।

সর্বশেষ reconciliation-এ PR #147 ও #149 signed repository preservation-এর transient Pages 5xx retry যোগ করেছে; PR #149 merge SHA `c78c03efa9875ca96613165de64bbcb174f1d075`। Generated-state PR #150 merge হয়ে `159806ff395a34349086504ae3055ddef21ddbec` হয়েছে। এরপর documentation reconciliation PR #151 এবং শুধু `.repo/` update থাকা generated-state PR #152 merge হয়ে বর্তমান exact `main` `7bfac09c026ecd093da1e2ac1b7426bd36a6a0b5` হয়েছে। Checkout পরিষ্কার। এই exact SHA-তে Validate `42914923141`, package artifact `42914923198`, Repository State Contract `42914923230` পাস করেছে; PR #151-এর exact-head check-ও পাস। Product source `159806ff` audit base-এর পরে বদলায়নি। Open PR #42, #44, #45 Dependabot update; #35 owner-review licensing proposal। Package-audit worktree detached অবস্থায় `727726a6b32124992a8c0153159a440ced0708c8`; untracked `ci-artifact/` পরীক্ষা করে অক্ষত রাখা হয়েছে। Local Codex TUI MCP endpoint connection দেয়নি, তাই অন্য Codex session enumeration হয়েছে—এ দাবি করছি না। বর্তমান live desktop read-only status-এ running, Termux:X11 ও PulseAudio চালু; restart করা হয়নি। এই session-এর managed filesystem scope native `$PREFIX`-এ write দেয় না এবং ADB binary load হয় না; ফলে এখান থেকে native package lifecycle বা GUI-control evidence যোগ করা যাচ্ছে না।

## Finding-ভিত্তিক অবস্থা

| Finding | অবস্থা | প্রমাণ ও বাকি acceptance |
|---|---|---|
| P0-01 Stable Diffusion Vulkan license CI | **COMPLETE** | Deterministic notice manifest ও regression আছে। Exact ARM64 build, binary inspection, independent license audit run `42863263043`-এ source `5e41401dd60bf5261f6a638c62b4ad94eea98812`-এ পাস; prerelease প্রকাশ বন্ধ ছিল। |
| P0-02 release branch consistency | **COMPLETE** | Product fix `main`-এ আছে; PR #138, generated PR #137, storage PR #139 merge হয়েছে। product head `eaf97fc`-এর সব exact-main check এবং generated-state PR #140-এর check পাস; release tag নেই। |
| P0-03 machine release gate | **COMPLETE** | `docs/release-gates.json`-এ ১৯ gate; blocker অসম্পূর্ণ থাকলে validator `NOT_READY` দেয়। |
| P1-01 desktop lifecycle | **PARTIAL** | Source regression ও আগের live READY status আছে। Installed v2.0.0 `desktop.sh` বর্তমান source থেকে আলাদা; updated-package GUI, stop/restart ও crash recovery বাকি। |
| P1-02 GPU/Vulkan detection | **শুধু tested Adreno device-এ COMPLETE** | Redmi Turbo 4 Pro / SM8735 / Adreno 825-এ Vulkan/Turnip ও Zink শনাক্ত হয়েছে; software renderer false-positive regression আছে। অন্য device qualify নয়। |
| P1-03 installer/updater | **PARTIAL** | Pinned bootstrap, host CLI, guest CLI tampered source reject করে; local rollback ও v1.4.0-to-v2 fixture পাস। Published v2 native migration/rollback বাকি। |
| P1-04 storage isolation | **PARTIAL** | Default `/sdcard` bind ও setup-time permission prompt সরানো হয়েছে। `ternux storage grant DIRECTORY` কেবল canonical subdirectory রেকর্ড করে; generic guest, desktop launcher, db/droot একই allowlist যাচাই করে। Focused regression ও PR CI পাস। Updated-package device check বাকি; পুরোনো package-এর live desktop restart করা হয়নি। |
| P1-05 repository protection | **owner-only repo-র জন্য COMPLETE** | Live read-back-এ PR ও required check, strict check, admin enforcement, force-push/delete বন্ধ; second-person review অসম্ভব হওয়ায় approval count শূন্য। `.github/CODEOWNERS`-এ owner নির্ধারিত। |
| P1-06 CPU/Vulkan LLM | **ঘোষিত device/model/workload profile-এর জন্য COMPLETE** | SM8735 / Adreno 825-এ Llama 3.2 3B Q4_K_M CPU/Vulkan known-answer ও 768 MiB pressure-সহ support-queue retrieval পাস করেছে; bounded cancel/reopen এবং CPU/Vulkan generation stability যাচাই হয়েছে। পাঁচটি 512-token CPU run ও চারটি Vulkan run সম্পূর্ণ; battery 42°C guard-এ পরের কাজ থামানো হয়েছে। তিন Qwen variant 100-record exact retrieval-এ ব্যর্থ এবং চাপের সময় invoice ফল 24.75, প্রত্যাশিত 39.50। এই model/task, অন্য device ও general correctness claim qualification-এর বাইরে। |
| P1-07 HTP/HMX | **PARTIAL; experimental, release-excluded** | Numerical/operator failure বাকি; failing operator stable default নয়, production claim নেই। |
| P1-08 QNN Stable Diffusion | **PARTIAL; research-only, release-excluded** | Stage-tensor correctness ও production qualification বাকি। |
| P1-APT public repository | **BLOCKED** | 2026-11-11-এ bootstrap, archive key, `InRelease`, `Packages`—চারটি public path-ই 404। Signed publication, hosted verification ও clean Termux install/upgrade/uninstall বাকি। |
| P1-PKG native package lifecycle | **PARTIAL** | Current-main package artifact run `42906685681` থেকে artifact `13805237072` তৈরি হয়েছে; নতুন policy অনুযায়ী 2027-02-08 পর্যন্ত retained। Native clean install, upgrade, repair ও uninstall যাচাই বাকি। |
| P1-DOCS | **source documentation-এ COMPLETE** | README, CLI, install, usage, security, accelerator, release-readiness English ও Bengali-তে আপডেট। Pages publication explicit main-only deployment workflow দিয়ে হয়। |
| P2-01 installer modularization | **NOT_STARTED; non-blocking** | Qualification চলাকালে বড় refactor এড়িয়ে incremental কাজ রাখুন। |
| P2-02 test decomposition | **PARTIAL; non-blocking** | Focused regression বেড়েছে; `tests/focused.sh` এখনো বড়। |
| P2-03 workload manifest | **COMPLETE** | Schema, registry, managed workload definition আছে। |
| P2-04 repo state ও gate automation | **COMPLETE** | CI state sync gated check খুঁজে পায়; machine gate schema/readiness test পাস। |
| P2-DEVICE multi-device qualification | **PARTIAL; non-blocking** | Physical qualification Redmi Turbo 4 Pro / SM8735 / Adreno 825-এ সীমিত। |

## যে পরিবর্তন হয়েছে

- Repo Knowledge Sync-এর API polling ঠিক হয়েছে; approval-gated run আর বাদ পড়ে না, এবং পুরো repository history paginate হয় না। PR #138 merge হয়েছে।
- Install-এর সময় Android storage permission prompt ও broad `/sdcard` bind সরানো হয়েছে।
- `ternux storage list`, `grant DIRECTORY`, `revoke DIRECTORY` যোগ হয়েছে। প্রতিটি guest login-এ canonical host path এবং guest target যাচাই হয়; storage root, traversal path, malformed grant ও identity বদল fail-closed।
- Generic guest, desktop launcher এবং regenerated db/droot alias একই allowlist ব্যবহার করে। Installer শুধু Ternux-এর চিহ্নিত shell alias block refresh করে; পাশের user content অক্ষত থাকে।
- Termux package manifest-এ storage module যোগ, English/Bengali docs ও changelog আপডেট, device acceptance বাকি হিসেবে নথিবদ্ধ।

## যাচাই

- `bash tests/focused.sh`: **153/153 পাস**—default-এ mount না হওয়া, নির্দিষ্ট path mount, tampered grant rejection, stale grant revoke, install-এ permission prompt না আসা, alias refresh ও host isolation অন্তর্ভুক্ত।
- `python3 tests/docs_check.py`: documentation, internal-link ও bilingual consistency check পাস।
- `python3 tests/release_gates.py --self-test` এবং `--check`: পাস; ১৯ gate `NOT_READY`, পাঁচ blocker উপরে তালিকাভুক্ত।
- On-device Llama 3.2 3B CPU/Vulkan bounded sustained-generation evidence এবং tested profile exclusion accelerator plan ও benchmark guide-এ আছে।
- Bash syntax, `git diff --check`, JSON parse: পাস।
- PR #139 head `53344d9a69a7f7a3019b10840a7495aaf56f548d`: Validate `42897454459`, unsigned package artifact `42897454586`, repo-contract `42897311193` ও `42897454513`, Repo Knowledge Sync/test `42897454842`: সব পাস।
- Current-main `verify-signing` workflow `42902118784` pass করেছে, commit `f35fd95f60731c7d4638099285b7b314f459f4d2`-এ; publish job skip হয়েছে। চারটি public APT endpoint এখনো 404।
- Exact product head `eaf97fc`: Validate `42897720583`, unsigned package artifact `42897720810`, Repository State Contract `42897720730`, এবং Repo Knowledge Sync `42897720595`—সব পাস। Generated-state PR #140 head `e8754415c25fce38ab9bfd7011e990a5000b7fb8`-এর Validate `42898005440`, unsigned package artifact `42898005215`, repo-contract `42898005314`, Repo Knowledge Sync/test `42898005386`—সব পাস; merge SHA `f35fd95f60731c7d4638099285b7b314f459f4d2`।
- Local Astro build পাওয়া যায়নি: Termux `node` binary `_ZNSt6__ndk113__hash_memoryEPKvm` symbol link করতে পারে না। Ubuntu CI Astro site build করে; exact-main Validate workflow-এ build পাস। Live GUI/service restart বা পরিবর্তন করা হয়নি।

## Device ও release exclusion

Qualified device Android 16, Xiaomi 25053RT47C (Redmi Turbo 4 Pro, SM8735, Adreno 825)। আগের native verify-তে Ternux 2.0.0, X11, PulseAudio এবং desktop PID 16987 চলছিল। Installed `desktop.sh` বর্তমান source নয়; চলমান session নতুন launcher যাচাই করে না। নতুন storage code device-এ install হয়নি; পুরোনো session-এ আগের package-এর mount session process শেষ হয়ে নতুন session চালানো পর্যন্ত থাকবে।

HTP/HMX ও QNN stable v2 claim-এর অংশ নয়। CPU/Vulkan claim-ও উপরের model/device evidence-এর মধ্যে সীমিত। এই audit-এ v2 tag/release, signed APT publication বা native package mutation করা হয়নি।

## বাকি release blocker

1. Supported Termux device-এ current package install করে native install/upgrade/repair/uninstall যাচাই।
2. Updated package-এ default storage বন্ধ, নির্দিষ্ট grant visible, revoke পরের session-এ প্রযোজ্য, Termux HOME hidden—এসব এবং GUI lifecycle/app smoke যাচাই; unrelated process স্পর্শ নয়।
3. Native v1.4.0 থেকে v2 migration এবং rollback যাচাই।
4. Candidate qualify হওয়ার পরই signed APT publish; public URL, signature, hash এবং clean `pkg install`, upgrade, uninstall যাচাই।
5. চূড়ান্ত release commit-এ সব required CI পুনরায় চালিয়ে এই report আপডেট। HTP/HMX এবং QNN qualification না হওয়া পর্যন্ত বাদ।

## চূড়ান্ত সুপারিশ

**NOT_READY।** Core source regression ও CI fix merge হয়েছে, কিন্তু পাঁচটি release-blocking gate বাকি। Device/package gate, APT route এবং final exact-commit CI pass না হওয়া পর্যন্ত v2.0.0 tag বা publish করবেন না।
