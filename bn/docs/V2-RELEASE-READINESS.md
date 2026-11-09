---
title: "Ternux v2.0.0 release readiness"
description: "Ternux v2 release audit, verified evidence, and remaining gates."
lang: "bn"
alt_url: "/docs/V2-RELEASE-READINESS.html"
---

**অবস্থা: NOT_READY**

**অডিটের তারিখ:** 2026-11-09

**রিলিজ tag/publication:** তৈরি করা হয়নি

**সক্রিয় pull request:** [#97](https://github.com/soobujmiah/ternux/pull/97), draft

এই রিপোর্ট source ও CI-র প্রমাণকে বাস্তব ডিভাইস পরীক্ষার থেকে আলাদা রাখে। Build সফল হলেই GPU, desktop, package installation বা accelerator workload release-ready প্রমাণ হয় না।

## Repository ও কাজের অবস্থা

| অবস্থান | অডিট শুরুর অবস্থা | কী করা হয়েছে |
|---|---|---|
| `ternux-task-fix` | `fix/managed-htp-extension-prerequisites`, `8101fa5e51f0f5b28c51a35b4d714cd0836c0026`-এ clean; বর্তমান `main` (`8e24062`)-এর ওপর | সক্রিয় v2 PR #97; নতুন fix এই branch-এ থাকবে। |
| `ternux-tools` | আলাদা `main` checkout, `9fda631`; ছয়টি owner-modified/untracked entry, যার মধ্যে native AI qualification script ও evidence আছে | নিজ জায়গায় অক্ষত রাখা হয়েছে। যাচাই ছাড়া release PR-এ যোগ করা হয়নি; এগুলো Ternux-এ HTP/QNN integration-এর প্রমাণ নয়। |
| `skb` | canonical remote যাচাই করা; checkout-এ owner পরিবর্তন আগে থেকেই ছিল | শুধু কাজের নির্দেশনা পড়া হয়েছে; কোনো ফাইল বদলানো হয়নি। |
| Live desktop | read-only status-এ `running`; supervisor PID `16987`, Termux:X11 PID `16779`, PulseAudio PID `16492`, XFCE PID `20829` | চালু ও অক্ষত রাখা হয়েছে। GUI restart বা installed file বদলানো হয়নি। |

আলাদা owner checkout-এর পূর্ণ তালিকা `git -C ~/ternux-tools status --short`-এ আছে; কোনো ফাইল বাদ দেওয়া হয়নি।

### Remote branch

- PR #97 `main`-কে target করে draft অবস্থায় আছে। অডিট শুরুর head বর্তমান main baseline-এর ওপর 122 commit এগিয়ে ছিল।
- `origin/codex/v2-reinstall-device-evidence-2026-11-07`-এর IBus Ctrl+Space fix PR source-এ সমতুল্যভাবে আছে।
- `origin/fix/detached-desktop-service-2026-11-06`-এ পুরোনো APT trust implementation আছে; বর্তমান package/signing flow থেকে আলাদা, তাই যাচাই ছাড়া cherry-pick করা হয়নি।
- পুরোনো HTP soak ও package smoke evidence বর্তমান পরিকল্পনার চেয়ে পুরোনো। Native AI evidence বর্তমান source/runtime-এর সঙ্গে মেলানো না পর্যন্ত owner-local থাকবে।

## Priority zero gate

| Gate | ফল | Evidence / বাকি কাজ |
|---|---|---|
| Stable Diffusion dependency notice | **`8101fa5`-এ ঠিক; CI পাস** | Upstream component/license mapping, header notice, deterministic manifest/checksum, optional dependency handling ও regression test যোগ হয়েছে। বর্তমান change-এর পর CI আবার পাস করতে হবে। |
| Release branch consistency | **আংশিক** | PR #97 বর্তমান main-এর ওপর। পুরোনো APT ও evidence branch release branch বাছার আগে file-level-এ মেলাতে হবে। |
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
- Generated launcher contract version 18। English/Bangla manual ও `killx` alias `ternux stop`-এর সঙ্গে মেলানো হয়েছে।

### Vulkan ও renderer detection

- KGSL node বা loader/ICD file থাকাকে Vulkan readiness-এর প্রমাণ ধরা বন্ধ হয়েছে।
- Debian guest-এ `vulkaninfo --summary` চালিয়ে physical device type ও driver যাচাই হয়। আসল Turnip GPU-র পাশে llvmpipe থাকলেও CPU-only llvmpipe `SOFTWARE_FALLBACK`।
- `vulkan_state`: `NOT_DETECTED`, `HARDWARE_AVAILABLE`, `LOADER_MISSING`, `DRIVER_MISSING`, `ICD_MISSING`, `DEVICE_ENUMERATION_FAILED`, `VULKAN_READY`, `SOFTWARE_FALLBACK`। Live `glxinfo` non-software renderer দেখালেই `OPENGL_ACCELERATION_READY`।
- Live renderer query না পেলে Turnip file দেখে renderer দাবি করা হয় না। GPU documentation-এর English/Bangla দুই সংস্করণ হালনাগাদ।

## যাচাইয়ের প্রমাণ

### Local checks

- `bash tests/focused.sh`: **134 check, 134 পাস**।
- `python3 tests/docs_check.py`: **ব্যর্থ — 1 error / 3023 assertion**; নতুন readiness report-এর Bangla mirror অনুপস্থিত ছিল। Mirror যোগ হয়েছে; আবার চালাতে হবে।
- পরিবর্তিত shell module ও entry point-এ `bash -n` পাস।
- শেষ edit-এর আগে `git diff --check` পাস; commit-এর আগে পুনরায় চালাতে হবে।
- Read-only source CLI probe-এ Redmi Turbo 4 Pro-তে `vulkan_state=VULKAN_READY`, `graphics_state=OPENGL_ACCELERATION_READY`, renderer `zink Vulkan 1.4(Adreno (TM) 825 (MESA_TURNIP))`।

### বাস্তব ডিভাইসে Vulkan

- Termux host-এর `vulkaninfo --summary` GPU ID `6830`-এর জন্য `VK_ERROR_INCOMPATIBLE_DRIVER` দিয়েছে।
- Debian guest `Adreno (TM) 825`, integrated GPU, Mesa Turnip driver এবং আলাদা llvmpipe CPU device enumerate করেছে।
- Live X11 renderer Zink/Turnip দেখিয়েছে; desktop চালু রাখা হয়েছিল। এই প্রমাণ শুধু এই device/software stack-এর জন্য; অন্য GPU বা sustained performance-এর জন্য নয়।

### আগের source head `8101fa5`-এর GitHub Actions

| Workflow | Run ID | ফল |
|---|---:|---|
| APT unsigned package build/inspection | `42620922012` | পাস |
| State contract | `42620921995` | পাস |
| Shell, behavior, documentation | `42620922110` | পাস |
| Knowledge sync/test | `42620922151` | পাস |
| llama.cpp CPU + Vulkan artifact | `42620922091` | পাস |
| Stable Diffusion CPU + Vulkan artifact | `42620922036` | পাস |
| Snapdragon HTP candidate | `42620921974` | Build পাস; PR-এ publication বাদ |
| Snapdragon HMX candidate | `42620921987` | Build পাস; PR-এ publication বাদ |

এগুলো বর্তমান lifecycle/Vulkan change-এর আগের CI। ঠিক `0906ffa74f4d7de1f4f3d58a596d6a729531a803` head-এর প্রথম `Validate` run (`42630638797`)-এ একটি focused assertion fail করে: Vulkan parser test host-এ `proot-distro` আছে ধরে নিয়েছিল, তাই GitHub Actions-এ mocked guest probe চলেনি। Implementation local-এ পাস করেছে; test-এ এখন guest-probe path স্পষ্টভাবে enable করা হয়েছে। Termux package ও repository-contract job পাস করেছে; রিপোর্ট লেখার সময় artifact ও knowledge-sync job চলছিল। Test fix push হওয়ার পর exact নতুন head-এর CI আবার পাস করতে হবে।

## বাকি blocker ও release exclusion

| Priority | Gate | অবস্থা | v2.0.0-এর আগে দরকার |
|---|---|---|---|
| P0 | Current-head CI ও PR review | **Source head `8ed1766`-এর সব workflow পাস; report-only follow-up CI অপেক্ষমাণ** | Report-only head-এর check confirm, log/artifact review, PR draft রাখা ও owner review দরকার। |
| P1 | Device desktop lifecycle | **Code বদলেছে; live deployment unverified** | নিয়ন্ত্রিত update-এর পর repeated/concurrent start, `status --json`, stop/start, crash recovery, socket ownership ও audio readiness যাচাই। চলমান GUI restart করা হয়নি। |
| P1 | Update transaction/provenance | **অসম্পূর্ণ** | `lib/update.sh` moving repository head clone করে module একে একে বসায়। Release commit pin, provenance/checksum, staging, pre-switch test ও failure rollback দরকার। |
| P1 | APT ও clean install | **Public endpoint এখন unavailable** | 2026-11-09-এ `https://soobujmiah.github.io/ternux/apt/bootstrap.sh`, `apt/ternux-archive-key.asc`, `apt/dists/stable/InRelease`, `apt/dists/stable/main/binary-all/Packages`—সব HTTP 404 দিয়েছে। Signed repository deploy/restore করে supported Termux device-এ `pkg install ternux`, upgrade ও uninstall যাচাই করতে হবে। |
| P1 | Workload correctness | **মিশ্র/experimental** | llama.cpp artifact build হলেও target-device known-answer, offload, memory pressure, repeat/cancel ও sustained measurement বাকি। HTP/HMX experimental; QNN Stable Diffusion supported NPU feature হিসেবে integrated নয়। |
| P1 | Shared-storage/security | **আংশিক** | Bind/permission audit এবং প্রতিটি workload-এর storage exposure নথিভুক্ত করা। |
| P1 | Repository governance | **বদলানো হয়নি** | Required checks, branch protection, CODEOWNERS, secret/release protection-এর owner-approved settings দরকার। কোনো settings বদলানো হয়নি। |
| P2 | Release documentation/review | **আংশিক** | README/install/upgrade/uninstall/limitations package-এর সঙ্গে মেলানো, release notes তৈরি, বড় PR diff-এর unrelated/duplicate change review। |
| P2 | Device coverage | **এক device** | Hardware/software support matrix; অন্য GPU/NPU-কে `NOT_TESTED` বা experimental চিহ্নিত করা। |

`~/ternux-tools`-এর native AI qualification কাজ অক্ষত আছে; তা Ternux integration বা stable HTP/QNN support প্রমাণ করে না।

## চূড়ান্ত সুপারিশ

**NOT_READY.** Stable Diffusion notice defect ঠিক এবং আগের PR head-এর CI পাস। Unsafe global desktop cleanup ও Vulkan false-positive source-এ ঠিক হয়েছে, regression test-সহ। নতুন change-এর exact-head CI ও নিয়ন্ত্রিত device verification বাকি। Update rollback/provenance, signed APT clean install/upgrade, workload qualification এবং owner-reviewed governance অসম্পূর্ণ।

কোনো release tag, package publication, merge, repository setting change বা live desktop restart করা হয়নি।
