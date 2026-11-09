---
title: "Ternux v2.0.0 release readiness"
description: "Ternux v2 release audit, verified evidence, and remaining gates."
lang: "bn"
alt_url: "/docs/V2-RELEASE-READINESS.html"
---

**অবস্থা: NOT_READY**

**অডিটের তারিখ:** 2026-11-10

**রিলিজ tag/publication:** তৈরি করা হয়নি

**সক্রিয় pull request:** [#97](https://github.com/soobujmiah/ternux/pull/97), draft

এই রিপোর্ট source ও CI-র প্রমাণকে বাস্তব ডিভাইস পরীক্ষার থেকে আলাদা রাখে। Build সফল হলেই GPU, desktop, package installation বা accelerator workload release-ready প্রমাণ হয় না।

## Stage 0: ২০২৬-১১-১০-এর বর্তমান repository reconciliation

এই pass শুরুর সময় primary worktree clean ছিল, commit `b9caeeb7a1dda7f0fd20ca1c2477a0e22804aa56`-এ। এই audit-এর implementation ও regression-test commit-গুলো branch-কে `e8dab0a3cdb795826b3f583efbaef4a9a9320e51` পর্যন্ত এগিয়েছে। Branch remote-এর সঙ্গে synced, `origin/main` (`8e24062589e81c20095c875fa4d19dd5cb928554`)-এর ওপর ভিত্তি করে ১৪৭ commit এগিয়ে। PR #97 open ও draft, target `main`; কোনো review decision নেই। v2 tag নেই। PR diff-এ ৫৬৯টি file—Ternux CLI/assets ও Debian packaging, bilingual docs, test/CI, এবং AI experiment-এর কাজ। Inventory-তে অপ্রাসঙ্গিক top-level path চোখে পড়েনি; final PR review-তে ৫৬৯টি file পুরো inspect করতে হবে।

| স্থান | বর্তমান অবস্থা | সমন্বয় |
|---|---|---|
| `ternux-task-fix` | report refresh-এর আগে implementation head `e8dab0a` | PR #97-তে কাজ চলবে; owner অনুমতি ছাড়া merge, tag বা publish হবে না। |
| `ternux-package-audit` | detached `727726a6`; untracked `ci-artifact/` ৭৪৭ KB | metadata অনুযায়ী এটি ৭ Nov-এর unsigned package/rootfs, source `b3a0f894…`; পুরোনো evidence হিসেবে রাখা হয়েছে, release diff-এ যোগ করা হয়নি। |
| `ternux-tools` | `main`-এ ছয়টি owner-modified/untracked QNN qualification entry | সব অপরিবর্তিত রাখা হয়েছে; এগুলো আলাদা research artifact, release source নয়। |
| `skb` | canonical checkout যাচাই করা; owner change আছে | শুধু guidance পড়া হয়েছে; file পরিবর্তন হয়নি। |
| চলমান Termux:X11 desktop | active; session restart করা হয়নি | session অক্ষত রাখা হয়েছে; desktop, audio বা Android service restart করা হয়নি। |

অন্য কোনো Codex agent সক্রিয় নেই। PR #35 আলাদা draft license proposal; owner review-এর অপেক্ষায়, v2 source-এর অংশ নয়। পাঁচটি open Dependabot PR action version update নিয়ে, release diff-এর বাইরে। Read-only GitHub check-এ `main` branch protection নেই, ruleset শূন্য। Report-only commit-এর আগে `e8dab0a` implementation tree clean ছিল; সর্বশেষ product-code commit `aa2c5f1`; এতে routine website deploy-তে signed APT tree যাচাই করে ধরে রাখার ব্যবস্থা আছে।

| Finding | সমন্বিত অবস্থা | Evidence/বাকি কাজ |
|---|---|---|
| P0-01 SD Vulkan license inventory | COMPLETE | Deterministic component manifest ও bundle regression test আছে; Ternux license সঠিকভাবে Apache-2.0। Exact-head ARM64 audit নিচে আছে। |
| P0-02 release branch consistency | PARTIAL | `main` ancestor; open draft PR #97-এর ১৪৭ commit review/integration বাকি। |
| P0-03 machine release gate | COMPLETE | ১৯টি gate; blocker থাকলে readiness `NOT_READY` থাকে। |
| P1-01 desktop lifecycle | PARTIAL | ownership/state handling ও host fixture pass; updated package-এ device start/stop/crash recovery বাকি। |
| P1-02 Vulkan/renderer detection | পরীক্ষিত Adreno 825 stack-এ COMPLETE | Enumeration ও live Zink/Turnip evidence আছে; অন্য GPU family qualify হয়নি। |
| P1-03 updater | PARTIAL | stage, integrity, rollback, interruption, concurrency fixture pass; published v2 ও v1.4.0 migration এখনো test করা যায়নি। |
| P1-04 storage isolation | PARTIAL | managed desktop ও guest login Termux HOME isolate করে, `/sdcard` রাখে; `/tmp` explicit। Device helper probe ও CI regression pass; full XFCE/app smoke বাকি। |
| P1-05 repository governance | BLOCKED | required review/branch rule নেই। Settings বদলাতে owner authorization দরকার; কিছু বদলানো হয়নি। |
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
- বর্তমান generated launcher contract version 19; আগের audit commit-এ version 18 ছিল। English/Bangla manual ও `killx` alias `ternux stop`-এর সঙ্গে মেলানো হয়েছে।

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
- `tests/update_transaction.sh` স্থানীয় tagged Git repository দিয়ে exact commit, downgrade আটকানো, সম্পূর্ণ tree switch, failed-candidate rollback, dead-owner crash recovery এবং live-owner blocking যাচাই করে। এতে GitHub Actions artifact ব্যবহার হয় না।
- Provenance হলো authenticated Git transport-এ আনা Git commit object ID; release tag বর্তমানে cryptographically signed নয়। আগে থেকে ইনস্টল v1.4.0 CLI-র প্রথম upgrade তখনকার পুরোনো updater দিয়েই হবে; সেই transition এবং native APT/public install এখনো unverified। বর্তমান stable metadata v1.4.0 আর v2 source version 2.0.0, তাই updater downgrade প্রস্তাব করে না।

### Continuation-এর file ও commit তালিকা

- `ce435e90cf4c4c4394d5bf2d0228858ad3ed34e2` updater transaction/recovery-এর জন্য `bin/ternux`, `lib/update.sh`, CLI help-এর `lib/help.sh`, নতুন `tests/update_transaction.sh`, `tests/focused.sh` এবং English/Bangla usage, installation ও readiness docs বদলেছে।
- `f3ba516ac6b5d6df0441c9db650e5b5ee090dcd5` ও `2cbf673599bc4e483cd0fc07af2265ba5dcc3b18` bilingual audit evidence আপডেট করেছে; product code বদলায়নি। এই documentation continuation-এ `SECURITY.md` এবং English/Bangla FAQ-তে বর্তমান guest bind behavior-ও স্পষ্ট করা হয়েছে। Pending report/security/FAQ change commit-এর আগে `tests/docs_check.py` ও `git diff --check` পাস করেছে।
- Updater code commit-এ 11টি file বদলেছে। `~/ternux-tools`-এর owner change, `~/ternux-package-audit`-এর শনাক্ত generated artifact এবং dirty `~/skb` checkout uncommitted ও অক্ষত আছে। এই continuation-এ artifact provenance read-only verify করা হয়েছে; PR #97-এ যোগ করা হয়নি.
- বর্তমান local focused verification: `bash tests/focused.sh` **134/134** pass করেছে; `python3 tests/docs_check.py`-তে **3,041 assertion, 312 internal link ও 20 bilingual page pair** pass; `git diff --check` pass। Exact-head hosted CI-ও নিচে নথিবদ্ধ। Published release migration এখনো unverified।
- আগের storage audit-এ default PRoot-Distro broad host binds ধরা পড়েছিল। পরের fix-এ Ternux managed desktop, guest-command wrapper ও `db`/`droot` alias isolated হয়েছে; ব্যবহারকারীর প্রয়োজনমতো `/sdcard` থাকে, Termux HOME গোপন থাকে, আর `/tmp` চাইলে share হয়। হাতে চালানো সরাসরি PRoot-Distro login তাদের upstream default-ই ব্যবহার করে।

## যাচাইয়ের প্রমাণ

### ২০২৬-১১-১০-এর বর্তমান exact-head audit

Core implementation ও regression fix `e8dab0a3cdb795826b3f583efbaef4a9a9320e51`-এ: isolated guest login ও `/sdcard` রাখা (`b9caeeb`), Stable Diffusion license metadata ঠিক করা (`6f6ae0c`), এবং regression coverage (`e8dab0a`)। Latest product-code head `aa2c5f1aeeed14e252c6c6d0669ceb745f6150f1` routine Pages deploy-তে signed APT preserve ও integration test যোগ করেছে; নিচে ওই head-এর exact CI-ও আছে। Base `main` এখনো `8e24062589e81c20095c875fa4d19dd5cb928554`; PR #97 draft, review নেই, branch ১৪৭ commit এগিয়ে।

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

একই code-এ local `bash tests/focused.sh` **134/134** pass; `python3 tests/docs_check.py` **3,041 assertion, 312 internal link, 20 bilingual page pair** pass। `tests/release_gates.py --self-test`, JSON parser, shell syntax ও `git diff --check` pass করেছে। Astro production build-ও Validate workflow-তে pass। Machine inventory-তে ১৯ gate; নয়টি অসম্পূর্ণ blocker থাকায় verdict `NOT_READY`।

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

### Device ও distribution evidence

- Live Termux host-এ Ternux `2.0.0` installed; X11 ও PulseAudio চলছিল। চলমান desktop অক্ষত রাখা হয়েছে, service restart করা হয়নি।
- Isolated generic guest helper device-এ pass: `/sdcard` ব্যবহারযোগ্য ছিল, কিন্তু host Termux HOME-এর একটি file guest-এ দেখা যায়নি। User PRoot-এ shared storage চান; `/sdcard` থাকলেই bind হয়, Android permission Termux-এর permission flow দিয়েই আসে। Guest alias ও helper host HOME isolate করে; `/tmp` শুধু চাইলে share হয়।
- 2026-11-10-এ repo source module দিয়ে `TERNUX_LIB_DIR=$PWD/lib TERNUX_JSON=1 bash bin/ternux verify --json` চালিয়ে `status=passed` পাওয়া গেছে; Termux:X11, PRoot-Distro, PulseAudio, `setsid`, launcher, Debian service ও Turnip present/OK ছিল। GUI বা service restart হয়নি।
- আগের isolated desktop probe-এ X11 query, PulseAudio, mic status ও camera-info pass করেছে। তবে updated launcher-এ fresh XFCE/app visual smoke এখনো হয়নি।
- SM8735 / Adreno 825 CPU ও Vulkan known-answer, Vulkan layer offload, bounded cancel ও reopen result `guides/device-benchmark-evidence.md`-এ আছে। Memory-pressure ও দীর্ঘ thermal test বাকি। HTP/HMX numerical failure স্পষ্ট রাখা হয়েছে; HTP ও QNN experimental, stable acceleration claim থেকে বাদ।
- Hosted signed APT bootstrap, public key, `InRelease`, `Packages`—চার URL-ই 2026-11-10-এ HTTP 404 দিয়েছে। Native `dpkg-query`-তে Ternux 2.0.0 installed, কিন্তু Ternux APT source configured নেই। Pages deploy আগে পুরো site tree upload করত, ফলে প্রকাশিত `/apt` মুছে যেতে পারত। `preserve-pages-apt.sh` এখন pinned key, signed `InRelease`, signed index checksum ও package checksum যাচাই করে APT tree ধরে রাখে। Signed-fixture integration test valid preserve pass করেছে এবং partial publish/tampering প্রত্যাখ্যান করেছে। Hosted path এখনো 404, তাই live redeploy preservation ও `pkg install ternux` lifecycle এখনো unverified।
- Read-only GitHub check-এ `main` branch protection নেই, repository ruleset শূন্য। Setting বদলানো হয়নি। `ternux-package-audit`-এর পুরোনো `ci-artifact/` ও owner-modified `ternux-tools` file release diff-এর বাইরে এবং অক্ষত।

## v2.0.0-এর আগে বাকি blocker

| Gate | অবস্থা | দরকারি evidence |
|---|---|---|
| P0-02 branch ও owner review | **PARTIAL** | ৫৬৯-file PR diff review করে PR #97 intended release branch-এ integrate করতে হবে; owner approval নেই। |
| P1-01 desktop lifecycle | **PARTIAL** | বর্তমান session না ভেঙে updated package-এ repeated/concurrent start, stop, stale/crash recovery, socket ownership ও audio readiness যাচাই। |
| P1-03 updater migration | **PARTIAL** | Published v2 update ও প্রথম v1.4.0 migration native Termux-এ পরীক্ষা; publication-এর আগে এটি সম্ভব নয়। |
| P1-04 storage ও desktop | **PARTIAL** | `/sdcard` access রেখে isolated bind বজায়; updated launcher-এ controlled/separate session-এ full XFCE ও app smoke। |
| P1-05 repository governance | **BLOCKED** | Owner-এর সিদ্ধান্ত ও অনুমতি নিয়ে required review এবং branch-protection rule। |
| P1-06 CPU/Vulkan qualification | **PARTIAL** | Supported hardware-এ memory-pressure, sustained thermal ও আরও model correctness evidence। |
| P1-APT public repository | **BLOCKED** | `aa2c5f1`-এ signed APT preservation code ও CI pass; owner-approved signed publish, hosted bootstrap/key/index verify, তারপর normal website redeploy ও clean `pkg install ternux` test বাকি। Endpoint এখনো 404। |
| P1-PKG native package lifecycle | **PARTIAL** | Published APT route ও standalone route দিয়ে supported device-এ clean install, upgrade, repair, uninstall verify। |
| P1-DOCS final review | **PARTIAL** | Owner review; release note ও version surface published artifact/exclusion-এর সঙ্গে মেলানো। |

HTP/HMX ও QNN numerical/stage-tensor qualification pass না করা পর্যন্ত experimental/research-only থাকবে; stable হিসেবে দেখানো হচ্ছে না। Phase modularization, বাকি test split, common workload manifest P2 maintainability কাজ। এই release-এর জন্য `lib/phases.sh`, test suite বা package manifest-এ ঝুঁকিপূর্ণ বড় rewrite হয়নি। PR #35-এর proposed license owner-review-only; বর্তমান Apache-2.0 terms ও notice অক্ষত।

## চূড়ান্ত সুপারিশ

**NOT_READY.** P0-01 ও P0-03 complete, কিন্তু নয়টি release-blocking gate অসম্পূর্ণ। আটটি required CI workflow implementation head `e8dab0a3cdb795826b3f583efbaef4a9a9320e51`-এ pass করেছে; এতে source build/check প্রমাণ হয়, public repository, installed package migration, live updated-desktop lifecycle বা owner review নয়। v2 tag, release, package publication, PR merge, repository setting change বা live desktop restart হয়নি। Actual release শুধু repository owner authorize করতে পারেন।
