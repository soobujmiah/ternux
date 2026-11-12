---
title: "Ternux v2.0.0 release readiness"
description: "Ternux v2.0.0-এর repo audit, implementation evidence, device qualification ও বাকি release gate।"
lang: "bn"
alt_url: "/docs/V2-RELEASE-READINESS.html"
---
**অবস্থা: NOT_READY**
**Audit date:** 2026-11-13 (PR #179 merge হওয়ার পর পুনরায় যাচাই)
**লক্ষ্য:** Ternux 2.0.0
**বর্তমান qualification source:** main `d2f525e6177146e2a9253f9cc17f5f022bed8f04` (PR #179)। Mesa overlay, আলাদা signed APT RC channel, cross-distro IBus/window-fit fix এবং exact-head check merge হয়েছে। এখনো RC বা stable APT প্রকাশ হয়নি।
**Product source audit base:** `159806ff395a34349086504ae3055ddef21ddbec`
**সর্বশেষ stable release:** v1.4.0; v2.0.0 tag বা release নেই।
**Machine gate:** ২০ gate-এর মধ্যে P1-01, P1-02, P1-04 ও P1-PKG complete; P1-03, P1-09, P1-APT—এই তিন blocker এখনো বাকি।

**সর্বশেষ release check:** `python3 tests/release_gates.py --check` এখনো `NOT_READY`। GitHub-এর latest stable v1.4.0; v2.0.0 tag/release নেই। RC bootstrap এবং signed Pages preservation-এর local test pass, কিন্তু RC এখনো publish হয়নি এবং native `pkg` দিয়ে পরীক্ষা হয়নি। V3 proposal আলাদা পরিকল্পনা; v2 acceptance-এর অংশ নয়।

## বর্তমান তিন distro-র device check (2026-11-12)

Redmi Turbo 4 Pro / SM8735 / Adreno 825-এ Debian (`:0`), Ubuntu (`:1`) এবং Alpine (`:2`) managed setup-এ একে একে চালিয়ে পরীক্ষা করা হয়েছে। তিনটিতেই Mesa Turnip-সহ Zink দেখা গেছে; PulseAudio playback সম্পন্ন হয়েছে, microphone capture-এ data এসেছে, IBus Ctrl+Space configuration/engine switching এবং Ternux theme/wallpaper asset পরীক্ষা হয়েছে। এটি শুধু এই একটি device-এ এই তিন profile-এর partial runtime integration evidence; clean install, browser install, প্রতিটি GUI app, upgrade/migration বা বাকি ১২টি profile qualify হয়েছে—এ প্রমাণ নয়। README ও English/Bengali website-এ এখন upstream shared-UID debug APK link, background throttling কমানোর কাজ এবং GitHub signature requirement ব্যাখ্যা করা আছে। এরপর `tx stop --all`-এ তিনটি বন্ধ হয়েছে; `tx status db`, `ub`, `alp` তিনটিই `STOPPED`। Guest route ছাড়া host PulseAudio daemon চালু থাকা স্বাভাবিক।

## তিন distro-র desktop UX পুনরায় যাচাই (2026-11-13)

লাইভ Debian, Ubuntu ও Alpine guest চালু রাখা হয়েছে। তিনটিতেই XFCE GTK, icon ও window-manager theme `Ternux`, এবং titlebar button layout `|HMC`। focused GTK entry-তে synthetic Ctrl+Space event পাঠিয়ে তিন guest-এই English থেকে configured Bangla engine-এ switch যাচাই হয়েছে। আগের shortcut কাজ না করার কারণ ছিল IBus `engines-order` ফাঁকা থাকা; fresh-install recipe ও session initializer এখন preload list-এর সঙ্গে এটি sync করে এবং XFCE fallback binding যাচাই করে। Debian ও Ubuntu-তে `python3-xlib`, Alpine-এ `py3-xlib` যোগ হয়েছে, ফলে fresh profile একই X11 window-fit watcher পায়। Watcher এখন EWMH-এর `_NET_CLIENT_LIST`-কে WINDOW property হিসেবে পড়ে এবং window-manager decoration-এ হাত দেয় না। Live placement probe-এ XFCE oversized/off-screen test window বর্তমান phone viewport-এর ভেতরে রেখেছে। Ubuntu ও Alpine Firefox screenshot-এ Ternux styling এবং দৃশ্যমান close control দেখা গেছে। Base app ও সাধারণ shell action-এ Ternux icon আছে; অপরিচিত বা নতুন app-এ নথিভুক্ত Adwaita fallback থাকে। এটি একটি device-এর evidence; physical keyboard typing বা সব third-party app যাচাই নয়। v2-এর তিন blocker অপরিবর্তিত।

## Native package follow-up (2026-11-12)

`tx uninstall all --yes` তিনটি registered Debian/Ubuntu/Alpine guest, Ternux launcher/alias, state/log এবং Termux-এর `ternux` package files সরিয়েছে। পরে PRoot container, Ternux dpkg package/CLI, state directory বা package-owned module পাওয়া যায়নি; Termux:API installed ছিল এবং Android shared storage অক্ষত ছিল। আগের inventory-তে unrelated PRoot guest ছিল না। এরপর exact local `ternux_2.0.0_all.deb` fresh install ও package replacement করা হয়েছে; `dpkg --verify`, `tx --version`, `tx distro list` pass। Fresh Debian guest `/sdcard`, `/sdcard/Llms`, `/sdcard/LAI/models` পড়েছে; guest HOME `/home/ternux`, Termux HOME guest-এ expose হয়নি। Package replacement-এর পরেও একই path check pass। Public repo install/upgrade আলাদা P1-APT gate। Termux package command-এ shell-এর injected `LD_LIBRARY_PATH` খালি রাখতে হয়েছে; অন্য Termux package upgrade হয়নি।

বর্তমান regression check: `bash tests/focused.sh` 178/178 pass; multi-guest, ১৫টি distro recipe, signed-APT bootstrap/preservation, updater migration/rollback ও release-gate self-test pass। Fresh Debian, Ubuntu এবং Alpine browser provisioning pass। Alpine-এর clean install-এ archive-এর `/usr/lib` layout ধরা পড়ে; path-aware overlay fix-এর পর fresh resume, Vulkan এবং live Zink check pass। Debian, Ubuntu Mozilla ESR, Alpine, Arch, Fedora, openSUSE এবং Void-এ clean package install ও headless Firefox launch-এর জন্য required CI matrix যোগ হয়েছে; exact-head result এখনো pending। এই container test full fresh Ternux device install-এর বিকল্প নয়। PR #179-এর exact-head website build ও docs check pass। `python3 tests/release_gates.py --check` তিন blocker-সহ NOT_READY দেখায়।

## সুপারিশ

এখনই v2.0.0 প্রকাশ করবেন না। PR #179 `d2f525e` commit-এ merge হয়েছে; Validate, package artifact, repository-contract, test ও sync check pass। P1-04 clean-guest storage ও P1-PKG full cleanup complete। Local updater migration/rollback fixture pass করলেও published RC-ভিত্তিক device migration বাকি; clean browser family qualification এবং signed public APT install/upgrade-ও বাকি।

## Stage 0 — repo ও কাজের পুনর্মিলন

Audit শুরুতে পরিষ্কার `main` ছিল `bcf363e10bc52a87fe2806a28f44dfdd220cf98f`। Open PR #137 ছিল CI-generated `.repo/` state update। সেখানে `Repo Knowledge Sync` first-run approval-এর অপেক্ষায় থাকলেও branch-filtered API query run-টি খুঁজে পায়নি, ফলে workflow timeout হয়। PR #138-এ unfiltered সাম্প্রতিক ১০০টি run থেকে exact SHA/branch মেলানো হয়েছে; bounded polling-সহ সব দরকারি check পাস করে এটি `5d4be243e8d3` হিসেবে merge হয়েছে। এরপর generated-state PR #137 check পাস করে `aff6aae40f8fa22bfe76a2a91e56f1ee10c51b60` হিসেবে merge হয়েছে। `.repo/` হাতে edit করা হয়নি।

PR #139 storage privacy implement করে সব required check পাসের পর `eaf97fc514c045193e7ef5968a95d1b26c449f9c` হিসেবে merge হয়েছে। Generated-state PR #140 সব check পাস করে `3c03dffa4ba07a2c0355613560c0768b45022c96` হিসেবে merge হয়েছে। এই audit PR #141 (`2763bac0cde5f38e2d3009eb236db2a89606f1c1`) এবং generated-state PR #142 (`f35fd95f60731c7d4638099285b7b314f459f4d2`) merge হয়েছে। Follow-up PR #143-তে bounded CPU/Vulkan model profile ও 90-day package-artifact retention নথিবদ্ধ; current-main merge `30bea68ff4440a97fc98a3f2c8b4d041e13c15f8`। Generated-state PR #144 check পাস করে `de52efcf5d4666dfa872c248d9370607a209c1ed` হিসেবে merge হয়েছে। Session-এর শুরুতে যাচাইকৃত SKB checkout-এ আগের dirty change ছিল; সেটি স্পর্শ করা হয়নি। অন্য কোনো active agent কাজ ছিল না। Open PR #42, #44, #45 Dependabot action update; PR #35 owner-review-এর licensing proposal, merge করা হয়নি।

সর্বশেষ reconciliation-এ PR #147/#149 transient Pages 5xx retry ঠিক করেছে; merge SHA `c78c03efa9875ca96613165de64bbcb174f1d075`। Generated-state PR #150 merge হয়ে `159806ff395a34349086504ae3055ddef21ddbec`; এরপর docs PR #151/#153 এবং generated-state PR #152/#154 merge হয়েছে। বর্তমান audit snapshot exact `main` `c3d318dfe9e2e6dadc73c33198b92f2dd4eeb33a`; `159806ff` product-source base-এর পর পরিবর্তন শুধু documentation ও generated repo state-এ। Exact-main Validate `42916453866`, package artifact `42916453776`, Repository State Contract `42916453730` pass করেছে। PR #153 exact-head Validate `42915521511`, package artifact `42915521584`, Repo Knowledge Sync `42915521562`, repo-contract `42915521483` pass করেছে। Non-publishing signing verification `42916703212` current main-এ pass; deploy/publish job skip হয়েছে। Open PR #42/#44/#45 Dependabot, #35 owner-review licensing। Package-audit worktree `727726a6b32124992a8c0153159a440ced0708c8` এবং untracked CI artifact অক্ষত রাখা হয়েছে। Local Codex TUI MCP endpoint unavailable হওয়ায় অন্য session enumeration হয়েছে—এ দাবি করছি না। Read-only native status ও `ternux verify` পুরোনো live desktop-এর জন্য pass (PID 16987; X11, PulseAudio চালু); installed module hash source থেকে আলাদা, restart হয়নি। এই managed filesystem policy native `$PREFIX` write দেয় না এবং ADB binary load হয় না; তাই এই session থেকে updated-package lifecycle বা GUI-control evidence সম্ভব নয়। Open PR #42, #44, #45 Dependabot update; #35 owner-review licensing proposal। Package-audit worktree detached অবস্থায় `727726a6b32124992a8c0153159a440ced0708c8`; untracked `ci-artifact/` পরীক্ষা করে অক্ষত রাখা হয়েছে। Local Codex TUI MCP endpoint connection দেয়নি, তাই অন্য Codex session enumeration হয়েছে—এ দাবি করছি না। বর্তমান live desktop read-only status-এ running, Termux:X11 ও PulseAudio চালু; restart করা হয়নি। এই session-এর managed filesystem scope native `$PREFIX`-এ write দেয় না এবং ADB binary load হয় না; ফলে এখান থেকে native package lifecycle বা GUI-control evidence যোগ করা যাচ্ছে না।

## Finding-ভিত্তিক অবস্থা

| Finding | অবস্থা | প্রমাণ ও বাকি acceptance |
|---|---|---|
| P0-01 Stable Diffusion Vulkan license CI | **COMPLETE** | Deterministic notice manifest ও regression আছে। Exact ARM64 build, binary inspection, independent license audit run `42863263043`-এ source `5e41401dd60bf5261f6a638c62b4ad94eea98812`-এ পাস; prerelease প্রকাশ বন্ধ ছিল। |
| P0-02 release branch consistency | **COMPLETE** | Product fix `main`-এ আছে; PR #138, generated PR #137, storage PR #139 merge হয়েছে। product head `eaf97fc`-এর সব exact-main check এবং generated-state PR #140-এর check পাস; release tag নেই। |
| P0-03 machine release gate | **COMPLETE** | `docs/release-gates.json`-এ ২০ gate; বর্তমান snapshot-এ বাকি তিন blocker অসম্পূর্ণ থাকলে validator `NOT_READY` দেয়। |
| P1-01 desktop lifecycle | **COMPLETE** | Exact native package-এ Debian, Ubuntu, Alpine READY ও PulseAudio route ready হয়েছে, তারপর clean stop-এ STOPPED। Verified process-group crash-এর পর status FAILED হয়; restart READY হয়েছে, stop-এ STOPPED। Host PulseAudio ও guest route আলাদা status, bounded readiness ও ownership regression CI-তে pass। |
| P1-02 GPU/Vulkan detection | **শুধু tested Adreno device-এ COMPLETE** | Redmi Turbo 4 Pro / SM8735 / Adreno 825-এ Debian, Ubuntu ও Alpine—তিনটিতেই Vulkan/Turnip-backed Zink দেখা গেছে; software renderer false-positive regression আছে। অন্য device qualify নয়। |
| P1-03 installer/updater | **PARTIAL** | Pinned bootstrap, host CLI, guest CLI tampered source reject করে; local rollback ও v1.4.0-to-v2 fixture পাস। Published v2 native migration/rollback বাকি। |
| P1-04 storage isolation | **COMPLETE** | Native package flow-তে তৈরি fresh Debian guest `/sdcard`, `/sdcard/Llms`, `/sdcard/LAI/models` পড়েছে; guest HOME `/home/ternux`, Termux HOME expose হয়নি। Package replacement-এর পরেও path check pass। |
| P1-09 default browser | **PARTIAL** | সব ১৫ recipe-তে Firefox route pass। Fresh Debian, Ubuntu ও Alpine install on-device pass। Required CI-তে Debian, Ubuntu Mozilla ESR, Alpine, Arch, Fedora, openSUSE ও Void clean container-এ browser install এবং headless launch যোগ হয়েছে; exact-head result pending। Container test পূর্ণ device provisioning নয়। |
| P1-05 repository protection | **owner-only repo-র জন্য COMPLETE** | Live read-back-এ PR ও required check, strict check, admin enforcement, force-push/delete বন্ধ; second-person review অসম্ভব হওয়ায় approval count শূন্য। `.github/CODEOWNERS`-এ owner নির্ধারিত। |
| P1-06 CPU/Vulkan LLM | **ঘোষিত device/model/workload profile-এর জন্য COMPLETE** | SM8735 / Adreno 825-এ Llama 3.2 3B Q4_K_M CPU/Vulkan known-answer ও 768 MiB pressure-সহ support-queue retrieval পাস করেছে; bounded cancel/reopen এবং CPU/Vulkan generation stability যাচাই হয়েছে। পাঁচটি 512-token CPU run ও চারটি Vulkan run সম্পূর্ণ; battery 42°C guard-এ পরের কাজ থামানো হয়েছে। তিন Qwen variant 100-record exact retrieval-এ ব্যর্থ এবং চাপের সময় invoice ফল 24.75, প্রত্যাশিত 39.50। এই model/task, অন্য device ও general correctness claim qualification-এর বাইরে। |
| P1-07 HTP/HMX | **PARTIAL; experimental, release-excluded** | Numerical/operator failure বাকি; failing operator stable default নয়, production claim নেই। |
| P1-08 QNN Stable Diffusion | **PARTIAL; research-only, release-excluded** | Stage-tensor correctness ও production qualification বাকি। |
| P1-APT public repository | **BLOCKED** | Stable APT path এখনো unpublished। এই branch-এ signed `/apt-rc` candidate channel, bootstrap selector ও deployment preservation যোগ হয়েছে; local signature/index/hash/bootstrap test pass। Merge/publish, hosted signature/hash check এবং native `pkg` lifecycle বাকি। |
| P1-PKG native package lifecycle | **COMPLETE** | Native `tx uninstall all --yes` সব registered Ternux guest ও owned host state/CLI file সরিয়েছে; Termux:API ও Android shared storage অক্ষত ছিল। Local `.deb` fresh install/replacement, `dpkg --verify`, `tx --version` ও `tx distro list` pass। Public APT P1-APT gate। |
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
- `python3 tests/release_gates.py --self-test` এবং `--check`: পাস; ২০ gate, পাঁচ release blocker, readiness `NOT_READY`.
- On-device Llama 3.2 3B CPU/Vulkan bounded sustained-generation evidence এবং tested profile exclusion accelerator plan ও benchmark guide-এ আছে।
- Bash syntax, `git diff --check`, JSON parse: পাস।
- PR #139 head `53344d9a69a7f7a3019b10840a7495aaf56f548d`: Validate `42897454459`, unsigned package artifact `42897454586`, repo-contract `42897311193` ও `42897454513`, Repo Knowledge Sync/test `42897454842`: সব পাস।
- Current-main `verify-signing` workflow `42902118784` pass করেছে, commit `f35fd95f60731c7d4638099285b7b314f459f4d2`-এ; publish job skip হয়েছে। চারটি public APT endpoint এখনো 404।
- Exact product head `eaf97fc`: Validate `42897720583`, unsigned package artifact `42897720810`, Repository State Contract `42897720730`, এবং Repo Knowledge Sync `42897720595`—সব পাস। Generated-state PR #140 head `e8754415c25fce38ab9bfd7011e990a5000b7fb8`-এর Validate `42898005440`, unsigned package artifact `42898005215`, repo-contract `42898005314`, Repo Knowledge Sync/test `42898005386`—সব পাস; merge SHA `f35fd95f60731c7d4638099285b7b314f459f4d2`।
- Local Astro build পাওয়া যায়নি: Termux `node` binary `_ZNSt6__ndk113__hash_memoryEPKvm` symbol link করতে পারে না। Ubuntu CI Astro site build করে; exact-main Validate workflow-এ build পাস। Live GUI/service restart বা পরিবর্তন করা হয়নি।

## Device ও release exclusion

Qualified device Android 16, Xiaomi 25053RT47C (Redmi Turbo 4 Pro, SM8735, Adreno 825)। Exact native Ternux 2.0.0 package local artifact থেকে install করে `dpkg --verify` pass হয়েছে; package CLI Debian :0, Ubuntu :1, Alpine :2 READY করেছে এবং PulseAudio route ready দেখিয়েছে। Verified Debian process-group crash-এ FAILED, তারপর packaged `tx start db`-এ READY, `tx stop db`-এ STOPPED হয়েছে। Package uninstall ও local-file fresh `pkg install` pass; এটি existing guest evidence, clean guest provisioning বা public APT install নয়।

HTP/HMX ও QNN stable v2 claim-এর অংশ নয়। CPU/Vulkan claim-ও উপরের model/device evidence-এর মধ্যে সীমিত। v2 tag/release বা signed APT publication হয়নি। Native package install/removal ও exact-package desktop lifecycle পরীক্ষা হয়েছে। Clean package-family browser launch check PR #180-তে pending; RC migration ও native package-source upgrade বাকি।

## বাকি release blocker

1. **P1-03 updater:** device-এ published v1.4.0-to-v2 migration, interrupted update recovery ও rollback verify। Local source fixture pass।
2. **P1-09 browser:** নতুন clean package-family Firefox CI matrix pass করে exact run record করতে হবে; ১৫ recipe pass, fresh Debian, Ubuntu ও Alpine browser launch on-device pass।
3. **P1-APT:** candidate gate pass হলে signed repo publish, public URL/signature/hash ও native `pkg install`/upgrade/uninstall verify; এখনো চারটি public path 404।

Final intended release commit-এ required CI আবার চালাতে হবে। আলাদা qualification না হওয়া পর্যন্ত HTP/HMX ও QNN বাদ।

## চূড়ান্ত সুপারিশ

**NOT_READY।** PR #179 merge হয়েছে; P1-01, P1-02, P1-04 ও P1-PKG complete। P1-03, P1-09, P1-APT বাকি। RC migration, fresh browser qualification এবং signed public APT evidence pass না হওয়া পর্যন্ত v2.0.0 tag বা publish করবেন না।
