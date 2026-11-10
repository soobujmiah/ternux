---
title: "Ternux v2.0.0 release readiness"
description: "Verified evidence and remaining release gates for Ternux v2.0.0."
lang: "en"
alt_url: "/bn/docs/V2-RELEASE-READINESS.html"
---

**Status: NOT_READY**

**Audit date:** 2026-11-10

**Release tag/publication:** not created

**Active pull request:** [#97](https://github.com/soobujmiah/ternux/pull/97), draft

This report separates source and CI evidence from physical-device qualification. A green build does not establish release readiness for the GPU, desktop, package installation, or accelerator workloads.

## Stage 0: current repository reconciliation — 2026-11-10

Validated code snapshot before this report-only refresh: `ternux-task-fix` was clean at `e7654d261a795817ed5ac22edce83143da2adf25`, synced with its remote, and 168 commits ahead of `origin/main` (`8e24062589e81c20095c875fa4d19dd5cb928554`). PR #97 is open, draft, cleanly mergeable, and has no review decision; GitHub reports 576 changed files. The v2 tag does not exist. The diff is concentrated in Ternux CLI/assets, Debian packaging, bilingual docs, tests/CI and AI experiments. The complete 576-file review and owner review remain open.

| Location | Current state | Reconciliation |
|---|---|---|
| `ternux-task-fix` | clean at `e7654d2`; 168 commits ahead; 576 PR files | Continue PR #97; keep it draft while release blockers remain. No merge, tag, or publication performed. |
| `ternux-package-audit` | detached at `727726a6`; untracked `ci-artifact/` is 747 KB | Build metadata identifies an unsigned Nov 7 package/rootfs from source `b3a0f894…`; preserve as stale evidence, never include it in the release diff. |
| `ternux-tools` | `main` with six owner-modified/untracked QNN qualification entries | Preserve all entries; they are separate research materials and are not release-source changes. |
| `skb` | verified canonical checkout; contains owner changes | Guidance only; no files changed. |
| `.repo/STATUS.md` | Generated snapshot from `main`, last synced at `aadc925` on Nov 7 | `python3 -m tools.repo_knowledge verify` reports zero findings. It was not hand-edited; PR head state is represented by exact-head CI. |
| Live Termux:X11 desktop | running; current session not restarted | Keep it undisturbed. No desktop, audio, or Android service restart was performed. |

There are no other active Codex agents. PR #35 remains a separate draft license proposal awaiting owner review; it is not part of this v2 source. Five open Dependabot PRs are unrelated action-version updates. Read-only GitHub inspection still finds no `main` branch protection and zero repository rulesets. The implementation tree was clean at `e8dab0a` before the report-only commits; the latest product-code commit is `aa2c5f1`; it adds verified preservation of the signed APT tree during routine website deployments.

| Finding | Reconciled state | Evidence/remaining gap |
|---|---|---|
| P0-01 SD Vulkan license inventory | COMPLETE | Deterministic component manifest and bundle regression tests; Ternux component now correctly says Apache-2.0. Exact-head ARM64 artifact audit is recorded below. |
| P0-02 release branch consistency | PARTIAL | `main` is an ancestor; 168 commits and a 576-file diff remain in draft PR #97. Exact current checks pass, but release-critical acceptance and owner review/integration remain open. |
| P0-03 machine release gate | COMPLETE | 19 gates; readiness derives `NOT_READY` while blocking items remain. |
| P1-01 desktop lifecycle | PARTIAL | Ownership/state handling and host fixtures pass; controlled device start/stop/crash recovery on the updated package remains unverified. |
| P1-02 Vulkan/renderer detection | COMPLETE on the tested Adreno 825 stack | Enumeration and real Zink/Turnip observations exist; other GPU families remain unqualified. |
| P1-03 updater | PARTIAL | Staging, integrity, rollback, interruption, and concurrency fixtures pass; published v2 and v1.4.0 migration cannot be verified before publication. |
| P1-04 storage isolation | PARTIAL | Normal PRoot access to Android shared storage at `/sdcard` is verified, while Termux HOME stays isolated and `/tmp` remains explicit. The remaining gap is full XFCE/app smoke through the updated launcher. |
| P1-05 repository governance | BLOCKED | Required review/branch rules are absent. Only the owner can authorize changing repository settings; none were changed. |
| P1-06 CPU/Vulkan LLM | PARTIAL | Known-answer, offload, cancellation, and reopen evidence exists; broad model, sustained thermal, and memory-pressure qualification remains open. |
| P1-07 HTP/HMX | PARTIAL, experimental and release-excluded | Build evidence exists; failing/incomplete operator numerical qualification prevents stable claims/defaults. |
| P1-08 QNN Stable Diffusion | PARTIAL, experimental and release-excluded | Device artifacts exist; full stage-tensor/reference qualification is incomplete. |
| P1-APT / P1-PKG | BLOCKED / PARTIAL | Signed pipeline works, but all four hosted APT paths still return 404; ordinary Pages redeploy now has a signed-repository preservation check, but native clean install, upgrade, and uninstall through the repository remain unverified. |
| P1-DOCS | PARTIAL | README, install/update/remove guidance, troubleshooting, changelog, security, and accelerator matrix exist; the readiness report has been refreshed to the current evidence; owner review remains open. |
| P2 modularization / test architecture / workload schema | NOT_STARTED / PARTIAL / NOT_STARTED | Keep these incremental and non-blocking; no risky one-shot refactor is justified before release gates close. |

## Repository and work reconciliation

The following original inventory is the Nov 9 audit checkpoint; the current Nov 10 Stage 0 snapshot and reconciliation matrix are above.

| Location | State at audit start | Handling |
|---|---|---|
| `ternux-task-fix` | `fix/managed-htp-extension-prerequisites`, clean at `8101fa5e51f0f5b28c51a35b4d714cd0836c0026`; based on current `main` (`8e24062`) | Active v2 PR #97. New fixes are kept on this branch. |
| `ternux-tools` | Separate `main` checkout at `9fda631`; six owner-modified/untracked entries, including native AI qualification scripts and evidence | Preserved in place. They were not staged, moved, or folded into the release PR without source review and reproducible validation. They are research evidence, not proof of Ternux-integrated HTP/QNN support. |
| `ternux-package-audit` | Detached checkout at `727726a`; untracked `ci-artifact/` contains a generated Ternux 2.0.0 package/rootfs and doctor snapshot | Provenance now confirmed from `build-info.txt`: project commit `b3a0f894…`, package builder `a7e20f9…`, APT builder `f2bf088…`, explicitly unsigned CI artifact, generated Nov 7. Preserved as local test evidence; not staged, moved, or deleted. It is not evidence for current head or a signed/public package. |
| `skb` | Canonical remote verified; checkout already contains owner changes | Read for operating guidance only; no files changed. |
| Live desktop | Read-only status reported `running`, supervisor PID `16987`, Termux:X11 PID `16779`, PulseAudio PID `16492`, XFCE PID `20829` | Left running and untouched. No GUI restart or installed-file change was made. |

The separate owner checkout contains modified bilingual accelerator plans, QNN experiment files, and untracked native qualification artifacts. The exact list remains available from `git -C ~/ternux-tools status --short`; none of those files was discarded.

### Remote branch reconciliation

- PR #97 is open as a draft and targets `main`. At audit start its head contained the current main baseline and was 122 commits ahead.
- Draft PR #35 (`codex/license-terms-review-20261016`) proposes PolyForm Noncommercial terms for first-party material and corresponding notices. It is explicitly awaiting Sobuj’s license review; it is not merged or included in v2. The current `main` license is Apache-2.0, so this proposal is not required for the current release and must not be implied as effective.
- `origin/codex/v2-reinstall-device-evidence-2026-11-07` contains the IBus Ctrl+Space fix; equivalent trigger reset and assertions are already in the PR source.
- `origin/feat/apt-trust-channel-2026-11-06` is an ancestor of current `main`; it has no branch-only commits. `origin/fix/detached-desktop-service-2026-11-06` is 134 commits behind `main` with one branch-only APT commit. That commit was inspected: it removes the `bootstrap.sh` executable assertion from the publish workflow, while current `main` retains the stricter check and has updated paired trust/install guides. No cherry-pick is needed.
- `origin/docs/record-htp-session-soak-2026-11-07` and `origin/docs/record-exact-ci-package-smoke` carry older evidence than current plans. Native AI evidence remains owner-local until reconciled against current source and runtime.

## Priority zero gates

| Gate | Result | Evidence / remaining work |
|---|---|---|
| Stable Diffusion dependency notices | **Fixed on `8101fa5`; CI passed** | Added exact upstream component/license mapping, embedded header notices, deterministic manifest/checksums, absent optional dependency handling, and regression tests. Current-head CI must pass again after the lifecycle/GPU changes below. |
| Release branch consistency | **PR #97 is based directly on current `main`; merge/review remains open** | Current `main` is an ancestor of the v2 PR head. The older APT trust branch is an ancestor of `main`; the sole commit on the detached-service branch was inspected and is superseded by stricter current workflow validation. Older evidence branches were checked and are not silently included. Complete owner review and PR integration before any release build. |
| Explicit release readiness gate | **Added by this report** | Current verdict is `NOT_READY`; CI green alone cannot change it. |

## Changes in this audit

### Desktop lifecycle and shared-service safety

- Added a non-blocking `flock` lifecycle lock so overlapping `ternux start` calls cannot spawn duplicate launchers. Concurrent callers receive a `starting` status.
- Added `STARTING`, `READY`, `STOPPING`, `STOPPED`, `FAILED`, and `RECOVERING` state reporting. `ternux status --json` now includes `lifecycle`.
- Session identity stores PID, Linux `/proc` start time, and process-group ID. Start/status/stop compare these values before treating a PID as Ternux-owned, preventing PID reuse from validating or killing an unrelated process.
- Stop signals only the verified Ternux process group. It does not globally kill Termux:X11, VirGL, PulseAudio, IBus, or remove shared X11/Pulse sockets.
- New launcher cleanup terminates only its recorded X11/VirGL child PIDs after checking their start identities, unloads only the PulseAudio module it created, and leaves the shared PulseAudio daemon running.
- Legacy launcher records without identity are stopped only after verifying the recorded process group, exact launcher path, inherited `TNX_PID_FILE`, and live start identity. They receive SIGKILL to bypass the old launcher’s global cleanup trap.
- Uninstall now reuses the same ownership-checked stop path. The direct-pipe uninstaller fetches and syntax-checks the required desktop module.
- The current generated launcher contract is version 19; earlier audit commits used version 18. English and Bangla manual examples and the `killx` alias are synchronized to `ternux stop`.

### Vulkan and renderer detection

- KGSL visibility and loader/ICD file presence no longer imply Vulkan readiness.
- Ternux probes `vulkaninfo --summary` in Debian with the available KGSL node bound in and checks each physical device’s type and driver. CPU-only llvmpipe is `SOFTWARE_FALLBACK`, even when it appears beside a real Turnip GPU.
- `vulkan_state` distinguishes `NOT_DETECTED`, `HARDWARE_AVAILABLE`, `LOADER_MISSING`, `DRIVER_MISSING`, `ICD_MISSING`, `DEVICE_ENUMERATION_FAILED`, `VULKAN_READY`, and `SOFTWARE_FALLBACK`. `graphics_state` reports `OPENGL_ACCELERATION_READY` only for a live non-software `glxinfo` renderer.
- Renderer identification no longer falls back to Turnip file existence when no live OpenGL renderer can be queried.
- English and Bangla GPU documentation explain these states and the device evidence.

### Preserve the signed APT repository during routine Pages deploys

- `.github/workflows/deploy.yml` now preserves the shared `pages` deployment instead of canceling an in-flight signed APT release; after building the website, it runs `packaging/termux/preserve-pages-apt.sh` before uploading the Pages artifact.
- The preservation helper accepts the official HTTPS Pages endpoint in production. It checks the pinned primary-key fingerprint, verifies the signed `InRelease`, downloads and verifies each signed Release index by SHA-256 and size, parses the Packages indexes, and verifies every referenced package by SHA-256 and size. It carries forward the existing signature and packages, and includes the current repository bootstrap script.
- Before first publication it allows deployment only when `InRelease`, the public key, and bootstrap are all absent. Network errors, partial publication, invalid signatures, unsafe signed paths, or content mismatches fail the site deployment before an APT tree is assembled.
- `tests/termux_apt_pages_preservation.sh` uses a generated signing key and local HTTP fixture to cover the no-repository first deploy, inconsistent partial publication, valid signed preservation, tampered package rejection, and signed path traversal rejection. Local integration passed. A live website redeploy remains unverified because the public APT endpoints are still 404.

### Release-tag updater and interrupted-update recovery

- Non-APT updates now inspect the latest published stable release and refuse to downgrade a newer development build.
- The updater resolves the exact `vX.Y.Z` tag to a Git commit, fetches the tag, and rejects the source if the resolved commit differs from the pin. It checks the tag/core version, CLI and guest syntax, symlink-free source layout, and staged CLI response before touching the installed files.
- It stages the complete `lib/` tree on the target filesystem, saves the previous CLI and module tree under `$PREFIX/lib/ternux-update-backups/`, and records a journal containing the owner PID/start identity and backup ID. Dispatcher and module switches use same-filesystem renames; failed installed verification restores both prior paths.
- The installed dispatcher blocks concurrent CLI calls during the transaction and restores the saved version on the next launch after an interrupted updater. Backups remain available after success.
- `tests/update_transaction.sh` uses local tagged repositories to verify exact commit resolution, no-downgrade behavior, complete-tree switch, failed-candidate rollback, dead-owner crash recovery, and live-owner blocking. It does not access GitHub Actions artifacts.
- Provenance is the Git commit object ID fetched over the authenticated Git transport; the release tag is not currently cryptographically signed. The first upgrade from an existing v1.4.0 CLI still uses that older CLI's updater, and the native APT/public install transition remains unverified. Current stable release metadata is v1.4.0 while the v2 source reports 2.0.0, so the updater correctly does not offer a downgrade.

### Continuation file and commit inventory

- `ce435e90cf4c4c4394d5bf2d0228858ad3ed34e2` implements the updater transaction and recovery path in `bin/ternux` and `lib/update.sh`, updates CLI help in `lib/help.sh`, adds `tests/update_transaction.sh`, wires it into `tests/focused.sh`, and updates English/Bangla usage, installation, and readiness documentation.
- `f3ba516ac6b5d6df0441c9db650e5b5ee090dcd5` and `2cbf673599bc4e483cd0fc07af2265ba5dcc3b18` refresh bilingual audit evidence; no product code was changed in those commits. This final documentation continuation also updates `SECURITY.md` and the English/Bangla FAQ to disclose the current guest bind behavior. All pending report/security/FAQ edits pass `tests/docs_check.py` and `git diff --check` before commit.
- The updater code commit changes 11 files; the unrelated owner changes in `~/ternux-tools`, the identified generated artifact in `~/ternux-package-audit`, and the dirty `~/skb` checkout remain uncommitted and preserved. The artifact provenance was read-only verified during this continuation; none was added to PR #97.

## Verification evidence

### Current exact-head audit — 2026-11-10

Core implementation and regression fixes are at `e8dab0a3cdb795826b3f583efbaef4a9a9320e51`, including isolated guest login and normal `/sdcard` access (`b9caeeb`), corrected Stable Diffusion license metadata (`6f6ae0c`), and regression coverage (`e8dab0a`). Latest product-code commit `aa2c5f1aeeed14e252c6c6d0669ceb745f6150f1` adds signed APT preservation to ordinary Pages deployments and its integration tests. The validated evidence head is `e1212bbc10078ec761dd5911f7858dbdc9b22c19`; the later report-only sync commit is `0a292c3f13d32d597b996304b86195d7be5ae343`. At the validated evidence head, PR #97 was draft with no review decision and had 573 changed files.

All eight required workflows passed on that exact implementation head:

| Workflow | Run ID | Result |
|---|---:|---|
| Validate (Astro site, syntax, 134 focused regressions, docs and gate checks) | `42693350220` | Passed |
| Termux unsigned APT package build/inspection | `42693350684` | Passed |
| Repository state contract | `42693350209` | Passed |
| Repo knowledge sync/test | `42693350631` | Passed |
| llama.cpp CPU + Vulkan ARM64 artifact | `42693350529` | Passed |
| Stable Diffusion CPU + Vulkan plus license audit | `42693350226` | Passed |
| Snapdragon HTP artifact | `42693350490` | Build passed; publication skipped on draft PR |
| Snapdragon HMX capability candidate | `42693350221` | Build passed; publication skipped on draft PR |

Local verification on the same code: `bash tests/focused.sh` passed **134/134**; `python3 tests/docs_check.py` passed **3,041 assertions, 312 internal links, 20 bilingual page pairs**; `python3 tests/release_gates.py --self-test`, both relevant JSON parsers, shell syntax checks, and `git diff --check` passed. The website's Astro production build also passed in Validate. The machine-readable inventory has 19 gates and still reports `NOT_READY` with nine incomplete blockers.

All eight workflows passed on the latest product-code head `aa2c5f1aeeed14e252c6c6d0669ceb745f6150f1`. Validate includes the new signed APT preservation fixture; the deployment workflow itself runs only on `main` or manual dispatch, so its live Pages operation remains unverified until publication.

| Workflow | Run ID | Result |
|---|---:|---|
| Validate (Astro site, 134 regressions, signed APT preservation, docs and gates) | `42704005351` | Passed |
| Termux unsigned APT package build/inspection | `42704005345` | Passed |
| Repository state contract | `42704005391` | Passed |
| Repo knowledge sync/test | `42704005633` | Passed |
| llama.cpp CPU + Vulkan ARM64 artifact | `42704005356` | Passed |
| Stable Diffusion CPU + Vulkan plus license audit | `42704005340` | Passed |
| Snapdragon HTP artifact | `42704005486` | Build passed; publication skipped on draft PR |
| Snapdragon HMX capability candidate | `42704005958` | Build passed; publication skipped on draft PR |

The report-only head `e1212bbc10078ec761dd5911f7858dbdc9b22c19` also passed all eight required workflows: Validate `42707570617`, Termux APT package `42707570582`, repository contract `42707570627`, knowledge sync `42707570460`, llama CPU/Vulkan `42707570564`, Stable Diffusion/license `42707570566`, HTP `42707570651`, and HMX `42707570549`. The APT and accelerator artifact publication jobs correctly skipped on this draft PR. The branch is clean and synced to its remote at that head.

The latest report-only head `b5cf839bdb5597392022ec21438cc45b9cf4e83c` passed all eight required workflows: Validate `42712474036`, Termux APT package `42712474219`, repository contract `42712474435`, knowledge sync `42712474995`, llama CPU/Vulkan `42712474493`, Stable Diffusion/license `42712473855`, HTP `42712474195`, and HMX `42712474393`. Both Snapdragon builds completed successfully; publication jobs were skipped because PR #97 is draft. Local documentation checks on this evidence state passed 3,041 assertions, 312 internal links and 20 bilingual page pairs; repo knowledge verification found zero issues. CI/build success does not close the nine device, hosted APT, package lifecycle or owner-review blockers.

### Exact-head verification after the lifecycle update

Commit `f4bb945576f03a9d8979d7d89553660471dafbaf` passed all eight required workflows on 2026-11-10. Validate `42773827524`, Termux APT package `42773827442`, repository state `42773827490`, repo knowledge sync `42773827401`, llama CPU/Vulkan `42773827384`, Stable Diffusion CPU/Vulkan `42773827441`, HTP artifact `42773827791`, and HTP/HMX candidate `42773827449` all succeeded. Publication was skipped because PR #97 remains draft. The Validate job includes the current 140 focused regressions and documentation/gate checks. The PR is open with a clean merge state, 573 changed files, and no review decision.

### Device and distribution evidence

- The live Termux host reports Ternux `2.0.0` installed, with X11 and PulseAudio running. The active desktop was left untouched; no service restart was made.
- The isolated generic guest helper passed on-device: `/sdcard` was accessible and a host Termux HOME file was not. The user explicitly expects shared storage in PRoot; the bind is conditional on `/sdcard` existing, and Android storage permission still comes from the Termux permission flow. Generic aliases and helper now isolate host HOME; `/tmp` is shared only when requested.
- On 2026-11-10, running the repository source modules with `TERNUX_LIB_DIR=$PWD/lib TERNUX_JSON=1 bash bin/ternux verify --json` returned `status=passed`; Termux:X11, PRoot-Distro, PulseAudio, `setsid`, launcher, Debian services and Turnip were present/OK. No GUI or service restart occurred.
- Earlier isolated desktop probes recorded X11 query, PulseAudio connection, microphone status and camera-info success. These probes do not substitute for a fresh XFCE/app visual smoke on the updated generated launcher.
- On 2026-11-10, the repository source `start --json` reused the active desktop (`already_running`, PID 16987); source `status --json` then reported `READY`, passed its bounded guest X11 query, and reported `pulseaudio_ready=yes`. The installed CLI still reported the same desktop running. No stop/restart, app close, or installed-file replacement occurred. This verifies safe reuse and live X11/audio-route probes, not updated-package stop/crash recovery or managed PID identity.
- The lifecycle implementation now requires an actual bounded guest X11 query before treating a session as live, refuses a JSON duplicate start when an existing Termux:X11 server fails that query, and reports the PulseAudio daemon separately from its guest TCP route. Focused regressions passed 140/140 locally; the lifecycle update also passed Validate run `42773827524` on commit `f4bb945`.
- SM8735 / Adreno 825 CPU and Vulkan known-answer, Vulkan layer-offload, bounded cancellation and reopen results are recorded in `guides/device-benchmark-evidence.md`. Memory-pressure and sustained thermal tests remain open. HTP/HMX numerical failures remain visible; HTP and QNN are experimental and excluded from stable acceleration claims.
- On 2026-11-10, direct checks of the canonical GitHub Pages URLs for `apt/bootstrap.sh`, `apt/ternux-archive-key.asc`, `apt/dists/stable/InRelease`, and `apt/dists/stable/main/binary-all/Packages` returned HTTP 404. Native `dpkg-query` shows Ternux 2.0.0 installed, but no Ternux APT source is configured. A Pages deploy previously replaced the whole site tree and could erase `/apt`; `preserve-pages-apt.sh` now validates the pinned key, signed `InRelease`, signed index checksums, and package checksums before retaining the repository. Its local signed-fixture integration test passes for valid preservation and rejects partial publication, package tampering, and signed path traversal. The host still returns 404, so live post-publish preservation and `pkg install ternux` lifecycle remain unverified.
- GitHub read-only inspection found no `main` branch protection and zero repository rulesets. No settings were changed. The old `ci-artifact/` in `ternux-package-audit` and owner-modified `ternux-tools` files remain outside the release diff and were preserved.

### Heavy artifact build repeat prevention — 2026-11-10

PR #97's artifact workflows had broad `pull_request` triggers. Since their path
filters match the overall PR diff, each `synchronize` event could rerun ARM64/HTP
compilation even when the newly pushed commit only changed documentation. The
repeat runs on head `9016bf9` were canceled: llama Vulkan `42774732346`, Stable
Diffusion `42774732436`, HTP `42774732564`, and integer-HMX `42774732544`.
Those four heavy workflows are now manual-dispatch only. The three optional
artifact workflows can validate an earlier successful run ID, checksum the exact
archive, and copy it into a fresh 90-day CI artifact without compiling again.
The candidate HMX workflow already provides the same retention-refresh path.
All four existing f4 artifacts were revalidated and refreshed without compilation or publication. Refresh runs `42783356045` (Vulkan), `42783357108` (Stable Diffusion), `42783356495` (HTP), and `42783356082` (HMX) succeeded with build and publisher jobs skipped. New artifact IDs `13747211879`, `13747515887`, `13747701121`, and `13746772303`, respectively, expire 2027-02-08. The
provenance verifier compares the pinned build job and package inputs, while allowing
retention-only workflow changes. Focused regressions cover these paths plus wrong
workflow, expired artifacts, changed package inputs/build definitions, and manual-only
triggers. Latest PR head `e7654d2` passed Validate `42783161375`, Termux APT package `42783161248`, Repository State Contract `42783160978`, and Repo Knowledge Sync `42783161055`. Four source-run refresh workflows also passed; all compile and publish jobs were skipped.

On artifact-reuse commit `89802f73408a1638221c0b3f62c26d212385b2ea`, Validate `42779265831`, Termux APT package `42779265743`, Repository State Contract `42779266172`, and Repo Knowledge Sync `42779266194` all passed. No ARM64/Vulkan, Stable Diffusion, HTP, or HMX build workflow triggered on this PR update.

## Remaining blockers before v2.0.0

| Gate | Status | Required evidence |
|---|---|---|
| P0-02 branch and owner review | **PARTIAL** | Review the 576-file PR diff and integrate PR #97 into the intended release branch. Owner approval is still absent. |
| P1-01 desktop lifecycle | **PARTIAL** | Validate repeated/concurrent start, stop, stale/crash recovery, socket ownership and independent audio readiness on the updated package without disturbing the current session. |
| P1-03 updater migration | **PARTIAL** | Exercise the published v2 update and first v1.4.0 migration in native Termux. Until publication, these cannot be verified. |
| P1-04 storage and desktop | **PARTIAL** | Normal `/sdcard` use inside PRoot is verified and expected; Termux HOME remains isolated. Run full XFCE and user-facing app smoke through the updated launcher in a separate/controlled session. |
| P1-05 repository governance | **BLOCKED** | Owner must decide and authorize required-review and branch-protection rules. |
| P1-06 CPU/Vulkan qualification | **PARTIAL** | Add memory-pressure, sustained thermal and broader model correctness evidence on supported hardware. |
| P1-APT public repository | **BLOCKED** | Signed APT preservation code and CI pass on `aa2c5f1`; still needs owner-authorized publication, hosted bootstrap/key/index verification, a normal website redeploy, and clean `pkg install ternux`. Current checks of the four canonical GitHub Pages APT paths return HTTP 404. |
| P1-PKG native package lifecycle | **PARTIAL** | Verify exact supported-device clean install, upgrade, repair and uninstall using the published APT route and standalone route. |
| P1-DOCS final review | **PARTIAL** | Finish owner review and ensure release notes/version surfaces match the actual published artifacts and exclusions. |

HTP/HMX and QNN remain experimental/research-only until their numerical or stage-tensor qualification passes. They are not silently promoted to stable. Phase modularization, remaining test-suite splitting and a common workload manifest remain P2 maintainability work; the current `lib/phases.sh`, test suite and package manifest were not riskily rewritten for this release. PR #35's proposed license terms remain owner-review-only; current Apache-2.0 terms and notices are preserved.

## Final recommendation

**NOT_READY.** P0-01 and P0-03 are complete, but nine release-blocking gates remain incomplete. All eight build/test workflows passed on product commit `f4bb945576f03a9d8979d7d89553660471dafbaf`. On latest code head `e7654d2`, Validate `42783161375`, Termux APT package `42783161248`, Repository State Contract `42783160978`, and Repo Knowledge Sync `42783161055` passed. Four manual artifact refresh runs passed provenance/checksum checks, skipped builds and publishers, and extended the exact artifacts through 2027-02-08. This proves source/build checks, not public repository availability, installed-package migration, live updated-desktop lifecycle, or owner review. No v2 tag, release, package publication, PR merge, repository-settings change, or live desktop restart was performed. Only the repository owner can authorize the actual release.
