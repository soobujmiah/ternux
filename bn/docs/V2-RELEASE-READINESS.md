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

### Release-tag updater ও interrupted-update recovery

- Non-APT update এখন সর্বশেষ প্রকাশিত stable release দেখে এবং নতুন development build-কে downgrade হতে দেয় না।
- Updater exact `vX.Y.Z` tag থেকে Git commit resolve ও fetch করে; pin-এর সঙ্গে commit না মিললে source বাতিল করে। Installed file বদলানোর আগে tag/core version, CLI ও guest syntax, symlink-মুক্ত source layout এবং staged CLI response যাচাই করে।
- সম্পূর্ণ `lib/` tree target filesystem-এ stage হয়। আগের CLI ও module tree `$PREFIX/lib/ternux-update-backups/`-এ রাখা হয়। Journal-এ owner PID/start identity ও backup ID থাকে। একই filesystem-এ rename করে dispatcher ও module switch হয়; installed verification ব্যর্থ হলে আগের দুটোই restore হয়।
- Transaction চলার সময় installed dispatcher concurrent CLI call আটকায়। updater মাঝপথে বন্ধ হলে পরের CLI launch-এ আগের version restore হয়। সফল update-এর পরও backup থাকে।
- `tests/update_transaction.sh` স্থানীয় tagged Git repository দিয়ে exact commit, downgrade আটকানো, সম্পূর্ণ tree switch, failed-candidate rollback, dead-owner crash recovery এবং live-owner blocking যাচাই করে। এতে GitHub Actions artifact ব্যবহার হয় না।
- Provenance হলো authenticated Git transport-এ আনা Git commit object ID; release tag বর্তমানে cryptographically signed নয়। আগে থেকে ইনস্টল v1.4.0 CLI-র প্রথম upgrade তখনকার পুরোনো updater দিয়েই হবে; সেই transition এবং native APT/public install এখনো unverified। বর্তমান stable metadata v1.4.0 আর v2 source version 2.0.0, তাই updater downgrade প্রস্তাব করে না।
- এই continuation-এর local focused verification: `bash tests/focused.sh` **133/133** পাস, যার মধ্যে updater transaction fixture আছে; `python3 tests/docs_check.py`-তে **3,041 assertion, 312 internal link ও 20 bilingual page pair** পাস; `git diff --check` পাস। এগুলো current-head hosted CI বা প্রকাশিত release migration-এর বিকল্প নয়।
- Storage audit-এ দেখা গেছে normal Termux PRoot-Distro login Debian guest-এ Android shared storage (`/sdcard`), Termux app path, `$PREFIX` ও Termux home bind করে। `/sdcard` access Ternux-এর স্বাভাবিক feature এবং থাকবে। আলাদা least-privilege প্রশ্ন হলো camera/microphone bridge-এর জন্য পুরো Termux home/prefix দরকার কি না, নাকি সীমিত API path যথেষ্ট; এই audit-এ কোনো bind বদলানো হয়নি।

## যাচাইয়ের প্রমাণ

### বর্তমান অডিট আপডেট — 2026-11-09

এই report refresh শুরুতে implementation head ছিল `60c937865cdc9fd7096d169874f196d150a8bfda`; checkout clean ছিল এবং `origin/fix/managed-htp-extension-prerequisites`-এর সঙ্গে যুক্ত ছিল। PR #97 এখনও open ও draft। ওই exact implementation head-এ সব required workflow সফল: Validate (`42641354925`), Termux APT package (`42641355428`), repository contract (`42641355103`), knowledge sync (`42641355025`), llama CPU/Vulkan (`42641355199`), Stable Diffusion CPU/Vulkan (`42641354978`), HTP build (`42641355238`) এবং HMX build (`42641355262`)। Draft PR হওয়ায় HTP/HMX publication বাদ গেছে।

আলাদা `~/ternux-tools` checkout-এ owner-এর ছয়টি modified/untracked entry আছে: accelerator plan দুটি, QNN experiment file দুটি, `experiments/qnn-native/clip_mnn_native_probe.cpp` এবং `experiments/native-ai-qualification/`। Detached `~/ternux-package-audit` worktree-তে অজানা provenance-এর untracked `ci-artifact/` আছে। দুই worktree-ই আগের অবস্থায় রাখা হয়েছে; কোনো file stage, move, delete করা হয়নি এবং artifact directory পড়া হয়নি। এগুলো নীরবে PR #97-এ যোগ করা হয়নি।

Report-only refresh `a165b532488a08388566a2a1edfa7f21b3e5424b` হিসেবে commit হয়েছে; এর Validate, package ও documentation check পাস করেছে, তবে এই snapshot-এর সময় accelerator build চলছিল। 2026-11-09-এ hosted signed APT-এর চারটি path আবার পরীক্ষা করে সবগুলোতে HTTP 404 পাওয়া গেছে। তাই package build পাস করলেই public `pkg install ternux` কাজ করে—এটা প্রমাণ হয় না।

এই অডিটে local verification: `bash tests/focused.sh` **134/134 পাস**, `python3 tests/docs_check.py` **3,041 assertion, 312 internal link ও 20 bilingual page pair পাস**, এবং `git diff --check` পাস। Termux checkout-এ dependency install নেই (`node_modules/.bin/astro` অনুপস্থিত), তাই Astro production build চালানো হয়নি।

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
| P0 | Current-head CI ও PR review | **Updater-এর বর্তমান change local-এ আছে; hosted CI এখনো চলেনি। আগের implementation head `60c9378`-এর required workflow পাস করেছিল** | Review করা continuation commit/push করে current-head-এর সব required workflow শেষ হওয়া পর্যন্ত অপেক্ষা; এরপর owner review ও final PR diff review। |
| P1 | Device desktop lifecycle | **Code বদলেছে; live deployment unverified** | নিয়ন্ত্রিত update-এর পর repeated/concurrent start, `status --json`, stop/start, crash recovery, socket ownership ও audio readiness যাচাই। চলমান GUI restart করা হয়নি। |
| P1 | Update transaction/provenance | **Implemented ও local fixture-tested; migration আংশিক বাকি** | প্রকাশিত v2 release দিয়ে native Termux-এ যাচাই এবং প্রথম v1.4.0 upgrade path পরীক্ষা দরকার। Release tag signed নয়; transition-এর আগে পুরোনো installed updater বদলানো যায় না। |
| P1 | APT ও clean install | **Public endpoint এখন unavailable** | 2026-11-09-এ `https://soobujmiah.github.io/ternux/apt/bootstrap.sh`, `apt/ternux-archive-key.asc`, `apt/dists/stable/InRelease`, `apt/dists/stable/main/binary-all/Packages`—সব HTTP 404 দিয়েছে। Signed repository deploy/restore করে supported Termux device-এ `pkg install ternux`, upgrade ও uninstall যাচাই করতে হবে। |
| P1 | Workload correctness | **মিশ্র/experimental** | llama.cpp artifact build হলেও target-device known-answer, offload, memory pressure, repeat/cancel ও sustained measurement বাকি। HTP/HMX experimental; QNN Stable Diffusion supported NPU feature হিসেবে integrated নয়। |
| P1 | Host path exposure | **আংশিক: `/sdcard` ইচ্ছাকৃতভাবে guest-এ থাকে; Termux home/prefix-ও default-এ bind হয়** | স্বাভাবিক shared-storage access বজায় রেখে camera/microphone bridge-এর জন্য পুরো Termux home/prefix-এর বদলে সীমিত Termux API bind সম্ভব কি না audit ও verify করা। Desktop, audio, camera ও microphone পরীক্ষা করতে হবে। |
| P1 | Repository governance | **বদলানো হয়নি** | Required checks, branch protection, CODEOWNERS, secret/release protection-এর owner-approved settings দরকার। কোনো settings বদলানো হয়নি। |
| P2 | Release documentation/review | **আংশিক** | README/install/upgrade/uninstall/limitations package-এর সঙ্গে মেলানো, release notes তৈরি, বড় PR diff-এর unrelated/duplicate change review। |
| P2 | Device coverage | **এক device** | Hardware/software support matrix; অন্য GPU/NPU-কে `NOT_TESTED` বা experimental চিহ্নিত করা। |

`~/ternux-tools`-এর native AI qualification কাজ অক্ষত আছে; তা Ternux integration বা stable HTP/QNN support প্রমাণ করে না।

## চূড়ান্ত সুপারিশ

**NOT_READY.** Release-tag updater-এর transaction, rollback, crash recovery ও concurrency local-এ যাচাই হয়েছে। Published-v2/native-Termux update এবং v1.4.0 migration unverified। Public signed APT path এখনও 404। নিয়ন্ত্রিত desktop lifecycle verification, workload correctness, Termux host-path review, owner-approved governance এবং final PR review বাকি। শুধু build সফল হওয়া এই gate-গুলো পূরণ করে না।

কোনো release tag, package publication, merge, repository setting change বা live desktop restart করা হয়নি।
