---
title: "Ternux v2.0.0 release readiness"
description: "Ternux v2 release audit, verified evidence, and remaining gates."
lang: "bn"
alt_url: "/docs/V2-RELEASE-READINESS.html"
---

**অবস্থা: NOT_READY**

**অডিটের তারিখ:** 2026-11-10

**Ternux v2.0.0 tag/publication:** তৈরি করা হয়নি

**সক্রিয় pull request:** [#97](https://github.com/soobujmiah/ternux/pull/97), review-এর জন্য প্রস্তুত

### সর্বশেষ continuation snapshot — ২০২৬-১১-১০

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

## Stage 0: ২০২৬-১১-১০-এর বর্তমান repository reconciliation

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
| P1-03 updater | PARTIAL | exact v1.4.0 CLI fixture থেকে v2 source-level migration pass; publication-এর পর public route ও native-device migration verify করতে হবে। |
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
- বর্তমান generated launcher contract version 19; আগের audit commit-এ version 18 ছিল। English/Bangla manual ও `killx` alias `ternux stop`-এর সঙ্গে মেলানো হয়েছে।

### যাচাইকৃত optional AI installer

- Hermes ও OpenClaw-এর optional setup এখন পরিবর্তনশীল URL-এর script সরাসরি Bash-এ pipe করে না। Script unique temporary file-এ download হয়, ২ MB সীমা, `bash -n`, এবং pinned SHA-256 pass করলেই execute হয়।
- Hermes-এর official `v0.23.1` release commit `3b421578588243f920886e6fe79a6faa87ea026e`-এ pinned; official bootstrap SHA-256 `abf338605dae6dd28d101673ac6aed7995c955745db46d47676bc591a7957209`।
- OpenClaw-এর official `v2026.11.2` release pinned; official bootstrap SHA-256 `5b46a876404005229ee62fc2615ddeb1c3f510a434ced47dbbed06b93849c704`।
- [`tests/pinned_optional_installers.sh`](../../tests/pinned_optional_installers.sh) সঠিক checksum-এ execution, mismatch-এ refusal, source allowlist, এবং temporary file cleanup যাচাই করে। Upstream script বদলালে reviewed version ও digest update না হওয়া পর্যন্ত install বন্ধ থাকবে।
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
| P1-03 updater migration | **PARTIAL** | Published v2 update ও প্রথম v1.4.0 migration native Termux-এ পরীক্ষা; publication-এর আগে এটি সম্ভব নয়। |
| P1-04 storage ও desktop | **PARTIAL** | PRoot-এর ভেতর স্বাভাবিক `/sdcard` ব্যবহার verified ও expected; Termux HOME isolated থাকে। Updated launcher-এ controlled/separate session-এ full XFCE ও app smoke বাকি। |

| P1-06 CPU/Vulkan qualification | **PARTIAL** | Supported hardware-এ memory-pressure, sustained thermal ও আরও model correctness evidence। |
| P1-APT public repository | **BLOCKED** | `aa2c5f1`-এ signed APT preservation code ও CI pass; owner-approved signed publish, hosted bootstrap/key/index verify, তারপর normal website redeploy ও clean `pkg install ternux` test বাকি। Canonical GitHub Pages-এর চারটি APT path এখনো HTTP 404 দিচ্ছে। |
| P1-PKG native package lifecycle | **PARTIAL** | Published APT route ও standalone route দিয়ে supported device-এ clean install, upgrade, repair, uninstall verify। |
| P1-DOCS final review | **PARTIAL** | Owner review; release note ও version surface published artifact/exclusion-এর সঙ্গে মেলানো। |

HTP/HMX ও QNN numerical/stage-tensor qualification pass না করা পর্যন্ত experimental/research-only থাকবে; stable হিসেবে দেখানো হচ্ছে না। Phase modularization, বাকি test split, common workload manifest P2 maintainability কাজ। এই release-এর জন্য `lib/phases.sh`, test suite বা package manifest-এ ঝুঁকিপূর্ণ বড় rewrite হয়নি। PR #35-এর proposed license owner-review-only; বর্তমান Apache-2.0 terms ও notice অক্ষত।

## চূড়ান্ত সুপারিশ

**NOT_READY.** P0-01, P0-03 ও P1-05 complete, কিন্তু আটটি release-blocking gate অসম্পূর্ণ। Product commit `f4bb945576f03a9d8979d7d89553660471dafbaf`-এ আটটি build/test workflow pass করেছে। audited PR head `8041c33939fc00639fe3296779ba840a352f82a3`-এ পাঁচটি required check pass করেছে: Validate `42792959040`, Termux APT package `42792958963`, Repository State Contract `42792959029`, এবং Repo Knowledge Sync `42792959241`-এর `sync` ও `test`; HTP candidate reuse verifier-ও pass করেছে। চারটি manual artifact refresh provenance/checksum pass করেছে, build/publish skip করে একই artifact 2027-02-08 পর্যন্ত সংরক্ষণ করেছে। এতে source/build check প্রমাণ হয়, public repository, installed package migration, live updated-desktop lifecycle বা owner review নয়। v2.0.0 tag/release, v2 APT package publication, PR merge বা live desktop restart হয়নি। Existing optional HTP prerelease-এর asset এখনো পুরোনো; latest retained archive-এর checksum ও no-rebuild reuse path উপরে নথিবদ্ধ। `main` branch-protection settings authorization অনুযায়ী বদলে verify করা হয়েছে; actual v2 release এখনো প্রস্তুত নয়।
