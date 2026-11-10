---
title: "Ternux v2.0.0 release readiness"
description: "Ternux v2.0.0-এর বর্তমান repository reconciliation, পরীক্ষার প্রমাণ এবং বাকি release gate।"
lang: "bn"
alt_url: "/docs/V2-RELEASE-READINESS.html"
---
**অবস্থা: NOT_READY**
**অডিট:** 2026-11-10 19:10 UTC
**Release tag/publication:** v2.0.0 tag বা release নেই; GitHub-এর সর্বশেষ stable হলো v1.4.0।
**এই audit-এর `main`:** `f94b83ea0d626c3d873fb9076d0871b42ea990c4`, PR #132-এর পর generated-state merge; product source baseline `5e41401dd60bf5261f6a638c62b4ad94eea98812` অপরিবর্তিত।
**Machine gate:** `docs/release-gates.json` ছয়টি অসম্পূর্ণ release blocker-সহ `NOT_READY` দেখায়।

## সুপারিশ

এখনই Ternux v2.0.0 প্রকাশ করা যাবে না। Source ও CI remediation এগিয়েছে: installer, host CLI এবং Debian guest CLI fallback এখন pinned source যাচাই করে; PR #127 `5e41401dd60bf5261f6a638c62b4ad94eea98812` হিসেবে merge হয়েছে; PR-এর সব required check এবং exact-main Validate, package-artifact ও Repo Knowledge Sync pass করেছে। P0-01 exact product-source ARM64 build ও independent license audit run `42863263043`-এ pass করেছে। এখনো ছয়টি P1 release-blocking acceptance check-এর প্রমাণ বাকি: updated installed desktop lifecycle, published v2 migration, updated-package GUI/storage smoke, বিস্তৃত CPU/Vulkan qualification, signed public APT install এবং native package lifecycle।

Public signed APT path চারটিই এখন HTTP 404 দেয়। Benchmark documentation-এর Pages deployment পরে সফল হয়েছে; APT publication, v2 tag বা v2 release করা হয়নি। `release_approved` false আছে।

## Stage 0 — repository ও কাজের reconciliation

### Repository ও চলমান কাজ

- Canonical origin `https://github.com/soobujmiah/ternux.git`।
- Product-source audit baseline ছিল clean `main`, commit `5e41401dd60bf5261f6a638c62b4ad94eea98812`; current `main` `68f14ba` পর্যন্ত এগিয়েছে। PR #128 শুধু readiness report আপডেট করেছে, PR #129 শুধু generated `.repo` state sync করেছে; product source অপরিবর্তিত।
- PR #127 `5e41401` হিসেবে merge হয়েছে। Exact head `72a83f50071d5f2d5bc15b1091ce70a34b12ef8f`-এ Validate run `42859849676`, package-artifact `42859849734`, repo-contract `42859849685` এবং Repo Knowledge Sync `42859849726`-এর `test` ও `sync` pass করেছে।
- Source commit `5e41401`-এর exact-main run: Validate `42860196252`, Termux package artifact `42860196300` এবং Repo Knowledge Sync `42860196265` pass। Generated-state PR #126 `0940a31`-এ merge হয়েছে; exact-main Validate `42863611485`, package artifact `42863611730`, Repository State Contract `42863611641` pass। Package-টি unsigned CI artifact, public release নয়। ARM64 Stable Diffusion build, binary inspection ও license audit `42863263043`-এ pass করেছে; 27,381,115-byte artifact upload হয়েছে এবং prerelease publication skip হয়েছে.
- PR #126 Repo Knowledge Sync workflow-এর generated `.repo` state ছিল; `0940a31`-এ merge হয়েছে, product-source change নেই। PR #128 report update `d87919f`-এ এবং generated-state PR #129 `68f14ba`-এ merge হয়েছে; latest exact-main Validate `42867226542`, package artifact `42867226104`, Repository State Contract `42867226155` pass। অন্য open PR হলো Dependabot action update (#42, #44, #45) এবং owner-review license proposal (#35); কোনোটিই চলমান v2 product implementation PR নয়।
- প্রাসঙ্গিক remote branch পরীক্ষা করা হয়েছে। পুরোনো `codex/v2-next-stage-2026-11-10`-এ কেবল stale report/gate edit; এর evidence এখানে supersede হয়েছে। PR #95-এর Ctrl+Space change current `main`-এ আছে। PR #116-এর workload manifest code-ও `main`-এ আছে। পুরোনো APT/deploy branch stale বা superseded। Experimental HTP/QNN branch ও owner research artifact stable claim থেকে বাদ। কোনো branch force-push বা discard করা হয়নি।
- Audit শুরুর সময় local `ternux-task-fix`-এ user change বা untracked file ছিল না। অন্য কোনো agent-এর active কাজ ছিল না। আলাদা research/local artifact এই audit-এ access বা modify করা হয়নি।

### Reconciliation matrix

| Finding | অবস্থা | বর্তমান প্রমাণ / বাকি acceptance |
|---|---|---|
| P0-01 Stable Diffusion Vulkan license CI | **COMPLETE** | Deterministic component manifest, source/header notice, missing/duplicate/path regression এবং exact product-source ARM64 build/license audit pass। Run `42863263043`-এ `5e41401`-এর artifact build ও inspect হয়েছে এবং license bundle independently audit হয়েছে; prerelease publication skip। |
| P0-02 release branch consistency | **COMPLETE** | v2 source `main`-এ integrated; PR #132 এবং generated-state PR #133 merge। `f94b83e`-এ exact-main Validate `42872807131`, package artifact `42872807143`, repo-contract `42872806994` pass; v2 tag নেই। |
| P0-03 release gate | **COMPLETE** | ১৯টি machine-readable gate; blocking gate অসম্পূর্ণ থাকলে validator `NOT_READY` রাখে। |
| P1-01 desktop lifecycle | **PARTIAL** | Source lifecycle fixture ও live READY status pass। Installed `desktop.sh` current source থেকে আলাদা; updated package-এ stop/restart/crash recovery ও managed-process identity যাচাই হয়নি। |
| P1-02 GPU/Vulkan detection | **শুধু পরীক্ষিত Adreno 825-এর জন্য COMPLETE** | Physical device Adreno 825, Vulkan/Turnip ও Zink renderer দেখায়; software-renderer false positive regression test আছে। অন্য GPU/device qualify হয়নি। |
| P1-03 installer/updater reliability | **PARTIAL** | Bootstrap archive, host CLI archive ও guest CLI fallback immutable commit pin এবং SHA-256 যাচাই করে; tamper regression merged PR #127-এ pass। Local v1.4.0 migration/rollback fixture pass। Published-v2 native migration বাকি। |
| P1-04 storage isolation | **PARTIAL** | PRoot-এ `/sdcard` ইচ্ছাকৃতভাবে ব্যবহারযোগ্য; generic guest test তা রাখে এবং Termux HOME isolate করে। Updated package-এ পূর্ণ XFCE/app smoke বাকি। |
| P1-05 repository protection | **COMPLETE** | Main branch protection read-back-এ required PR check, admin enforcement, force-push/deletion বন্ধ নিশ্চিত। Owner-only repo-র জন্য required approval count শূন্য। |
| P1-06 CPU/Vulkan LLM | **PARTIAL** | চারটি local GGUF variant-এর CPU ও Adreno Vulkan তিন-repeat benchmark-এর ফল published page-এ আছে। Llama 3.2 3B, CPU/Vulkan দুটোতেই 768 MiB memory-pressure retrieval/recovery pass করেছে। তিন Qwen variant structured retrieval-এ ভুল করেছে; pressure-এ CPU invoice task 39.50-এর বদলে 24.75 দিয়েছে। Correctness failure থাকায় gate partial। দীর্ঘ thermal soak ও অন্য device-এ qualification বাকি। |
| P1-07 HTP/HMX | **PARTIAL, experimental এবং release-excluded** | Operator numerical failure/অসম্পূর্ণ qualification আছে; stable default বা claim নয়। |
| P1-08 QNN Stable Diffusion | **PARTIAL, experimental এবং release-excluded** | Stage tensor/reference correctness ও production qualification অসম্পূর্ণ। |
| P1-APT public repository | **BLOCKED** | চারটি canonical signed APT URL-ই 404। Publish, hosted verification, Pages preservation এবং clean Termux install/upgrade/uninstall বাকি। |
| P1-PKG native package lifecycle | **PARTIAL** | Unsigned package artifact ও metadata check pass। Native clean install/update/repair/uninstall unverified। |
| P1-DOCS | **Source documentation-এর জন্য COMPLETE** | README, install/update/remove, troubleshooting, accelerator ও security docs bilingual check-সহ আছে। প্রকাশিত artifact অনুযায়ী final release note পরে মিলাতে হবে। |
| P2-01 installer modularization | **NOT_STARTED; non-blocking** | Incremental maintainability কাজ হিসেবে রাখুন; release qualification-এর মধ্যে broad refactor করবেন না। |
| P2-02 test decomposition | **PARTIAL; non-blocking** | `tests/focused.sh` বড়; regression coverage অক্ষত। Critical release gate-এর পরে ভাগ করুন। |
| P2-03 workload manifest | **COMPLETE** | Schema, canonical manifest, generated registry ও extension lifecycle `main`-এ আছে। |
| P2-04 machine release governance | **COMPLETE** | Schema, duplicate/failure/exclusion test এবং readiness derivation কার্যকর। |
| P2-DEVICE multi-device matrix | **PARTIAL; non-blocking** | Qualification শুধু নথিভুক্ত Redmi Turbo 4 Pro / SM8735 / Adreno 825-এ। অন্য device untested বা experimental। |

## বাস্তবায়িত remediation

- Stable Diffusion license inventory-তে explicit component manifest, deterministic bundle/index/checksum এবং missing, duplicate, unsafe ও embedded notice path regression আছে।
- Installer source ও host CLI fallback pinned codeload commit এবং SHA-256 যাচাই করে। Debian guest CLI fallback একই immutable commit থেকে `bin/ternux-guest` আনে এবং syntax check বা install-এর আগে আলাদা SHA-256 যাচাই করে।
- Desktop lifecycle Ternux-owned process/session identity ও bounded readiness probe ব্যবহার করে; X11 ও audio আলাদা দেখায়। Source test start/reuse/stop, stale state, concurrency ও lock contention কভার করে।
- Renderer detection hardware, loader, ICD, device enumeration, renderer ও acceleration আলাদা করে; পরিচিত software renderer-কে `SOFTWARE_FALLBACK` চিহ্নিত করে।
- Generic PRoot `/sdcard` থাকলে তা ব্যবহারযোগ্য রাখে, কিন্তু Termux HOME expose করে না। Shared `/tmp` explicit।
- Main branch protection ও release-gate validation সক্রিয়। Workload metadata ও managed extension canonical schema/registry ব্যবহার করে।
- Signed APT construction/preservation check key, Release metadata, index/package checksum ও safe path যাচাই করে। এতে deploy যাচাইযোগ্য হয়; repository publish হয় না।

## যাচাইয়ের প্রমাণ

### বর্তমান repository ও CI

| প্রমাণ | ফল |
|---|---|
| PR #127 source-এ `bash tests/focused.sh` | **150/150 pass**, pinned CLI/guest fallback success ও tampered-byte rejection-সহ। |
| `python3 tests/docs_check.py` | **3112 assertion**, 314 internal link, 20 bilingual page pair pass। |
| PR #133 generated-state merge-এর exact-main CI | Validate `42872807131`, package artifact `42872807143`, repo-contract `42872806994` — `f94b83e`-এ সব pass। |
| `python3 tests/release_gates.py --self-test` | ১৯ gate valid; `NOT_READY`; ছয়টি incomplete blocking gate, সব P1। |
| `git diff --check`, Bash syntax check | Merged installer change-এর জন্য pass। |
| PR #127 exact-head required check | Validate, package artifact, repo-contract, Repo Knowledge Sync test/sync সব pass। |
| Main `5e41401` exact-SHA CI | Validate `42860196252`, package artifact `42860196300`, Repo Knowledge Sync `42860196265` pass। |
| Stable Diffusion ARM64 ও license bundle | Exact product-source build, binary inspection ও independent license audit run `42863263043`-এ pass; 27,381,115-byte candidate artifact upload হয়েছে, prerelease publication skip। |
| Device CPU/Vulkan এবং throughput | চারটি exact GGUF file CPU ও Vulkan-এ প্রতি backend-এ ৩ বার benchmark হয়েছে; 512 prompt / 128 generated token। Prompt/generation tok/s: Qwen 0.5B-named Q4_0 CPU 65.0/15.4, Vulkan 319.8/34.5; Qwen 1.5B Q4_0 17.4/7.47, 101.9/19.8; Qwen 1.5B Q4_K_M 19.1/7.92, 96.7/17.6; Llama 3.2 3B Q4_K_M 8.93/5.15, 46.3/10.7। Synthetic retrieval-এ 3B exact marker দিয়েছে; তিনটি Qwen ভুল record value দিয়েছে। আগের bounded 3B Vulkan cancellation clean exit করেছে। ফল এক device-এর; universal model quality বা sustained thermal claim নয়। পূর্ণ capture device guide ও published Benchmarks page-এ আছে। |

### Device ও distribution

- 2026-11-10 18:34 UTC-তে native `ternux status --json` version 2.0.0, desktop `running`, X11 `yes`, PulseAudio `running`, launcher present, PID 16987 দেখায়; একই সময়ে `ternux verify --json` pass।
- 17:44 UTC-তে `ternux verify --json` Android 16, Adreno 825-এ pass; Termux:X11, PRoot-Distro, PulseAudio, `setsid`, launcher, Debian services ও Turnip present।
- `dpkg -V ternux` packaged file পরিবর্তন দেখায়নি। এটা package lifecycle pass প্রমাণ করে না।
- Source `lib/desktop.sh` SHA-256 `b3f0753a771f54c2c337310b2f23485926c9fded314ace818d76828c96af8ea3`; installed `$PREFIX/lib/ternux/desktop.sh` SHA-256 `02c5f6175f45c94c4ec68f323294f1c633bd7e4f501430b243f72132ed0950cb`। তাই বর্তমান চলমান desktop updated source lifecycle-এর প্রমাণ নয়।
- Multi-model benchmark ও retrieval run-এর পরে native status 19:10 UTC-তে Ternux 2.0.0 running, X11/PulseAudio running এবং desktop PID 16987 দেখায়। Verify pass; doctor battery 40°C ও available memory 5372 MB দেখায়। পুরো workload-এর বিভিন্ন snapshot-এ একই desktop PID ছিল। তিন-repeat benchmark repeatability/throughput মাপে; পরে 768 MiB pressure-এ Llama 3.2 3B CPU/Vulkan retrieval ও recovery pass করেছে। Qwen ও invoice task-এর correctness failure রয়ে গেছে।
- `adb` binary missing Android NDK linker symbol-এর কারণে চালু হয় না। Native `$PREFIX` এই session-এর writable path-এর বাইরে; তাই CI package install বা native package lifecycle test করা যায়নি। চলমান GUI/service stop, restart বা modify করা হয়নি।
- 2026-11-10 18:34 UTC fresh direct HTTPS GET-এ `apt/bootstrap.sh`, `apt/ternux-archive-key.asc`, `apt/dists/stable/InRelease` এবং `apt/dists/stable/main/binary-all/Packages` **404** দিয়েছে।
- Signing-only APT verification `42863371746` pass করেছে এবং deploy step skip করেছে। GitHub-এর latest stable `v1.4.0`; v2.0.0 release tag/publication নেই। Benchmark documentation-এর Pages deploy পরে সফল হয়েছে; APT path-গুলো এখনো 404, এবং v2 release action চালানো হয়নি।

## সঠিক blocker ও পরের acceptance evidence

1. **P1-01 desktop lifecycle:** current `desktop.sh`-সহ exact package নিরাপদে install/use করে owned PID identity, bounded XFCE/X11 readiness, independent audio status, stop/restart, crash recovery এবং unrelated process/socket preservation যাচাই।
2. **P1-03 updater migration:** approved v2 publication হলে supported Termux device-এ native v1.4.0 → v2 migration ও rollback চালান; local transaction fixture pass রাখতে হবে।
3. **P1-04 storage/security:** updated package দিয়ে XFCE ও user-facing app smoke; প্রত্যাশিত `/sdcard` access এবং Termux HOME isolation নিশ্চিত করুন।
4. **P1-06 CPU/Vulkan:** চারটি local GGUF variant-এর CPU/Vulkan fallback ও repeated throughput evidence আছে; 3B path-এ bounded cancellation pass। Llama 3.2 3B-তে exact retrieval pass, কিন্তু পরীক্ষিত তিন Qwen variant-এ fail। 768 MiB pressure-এ Llama 3.2 3B CPU/Vulkan retrieval/recovery pass; তবে তিন Qwen retrieval miss ও ভুল invoice total correctness failure। Gate partial থাকবে যতক্ষণ না failure সমাধান বা model support boundary স্পষ্ট হয়; দীর্ঘ soak ও declared support matrix-এর বাকি check দরকার। অন্য device সমর্থনের দাবি করবেন না。
5. **P1-APT:** owner approval-এর পর signed repository publish, hosted path/signature/hash verify, সাধারণ Pages deploy-এ `/apt` অক্ষত রাখা, তারপর clean `pkg install`, upgrade ও uninstall test।
6. **P1-PKG:** supported Termux device-এ native package install/update/repair/uninstall এবং metadata/checksum verify; CI artifact integrity একা যথেষ্ট নয়।

HTP/HMX ও QNN Stable Diffusion experimental/research-only; stable Ternux v2 claim-এর জন্য এগুলো দরকার নেই। P2 modularization, test-suite split ও multi-device qualification non-blocking কাজ হিসেবে নথিভুক্ত।

## চূড়ান্ত সুপারিশ

**NOT_READY।** Current source ও `f94b83e`-এর exact-main CI verified, কিন্তু ছয়টি release-blocking acceptance check অসম্পূর্ণ। Public APT repository নেই, এবং চলমান installed package-এ current desktop lifecycle module নেই। Device/package gate বন্ধ এবং repository owner publication স্পষ্টভাবে approve না করা পর্যন্ত v2.0.0 tag বা publish করবেন না।
