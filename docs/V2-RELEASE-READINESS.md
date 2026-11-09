---
title: "Ternux v2.0.0 release readiness"
description: "Verified evidence and remaining release gates for Ternux v2.0.0."
lang: "en"
alt_url: "/bn/docs/V2-RELEASE-READINESS.html"
---

**Status: NOT_READY**

**Audit date:** 2026-11-09

**Release tag/publication:** not created

**Active pull request:** [#97](https://github.com/soobujmiah/ternux/pull/97), draft

This report separates source and CI evidence from physical-device qualification. A green build does not establish release readiness for the GPU, desktop, package installation, or accelerator workloads.

## Repository and work reconciliation

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
- Generated launcher contract is version 18. English and Bangla manual examples and the `killx` alias are synchronized to `ternux stop`.

### Vulkan and renderer detection

- KGSL visibility and loader/ICD file presence no longer imply Vulkan readiness.
- Ternux probes `vulkaninfo --summary` in Debian with the available KGSL node bound in and checks each physical device’s type and driver. CPU-only llvmpipe is `SOFTWARE_FALLBACK`, even when it appears beside a real Turnip GPU.
- `vulkan_state` distinguishes `NOT_DETECTED`, `HARDWARE_AVAILABLE`, `LOADER_MISSING`, `DRIVER_MISSING`, `ICD_MISSING`, `DEVICE_ENUMERATION_FAILED`, `VULKAN_READY`, and `SOFTWARE_FALLBACK`. `graphics_state` reports `OPENGL_ACCELERATION_READY` only for a live non-software `glxinfo` renderer.
- Renderer identification no longer falls back to Turnip file existence when no live OpenGL renderer can be queried.
- English and Bangla GPU documentation explain these states and the device evidence.

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

### Current audit refresh — 2026-11-09

At the start of this report refresh, the implementation head was `60c937865cdc9fd7096d169874f196d150a8bfda`; the checkout was clean and tracked `origin/fix/managed-htp-extension-prerequisites`. PR #97 remains open and draft. All required workflows completed successfully on that exact implementation head: Validate (`42641354925`), Termux APT package (`42641355428`), repository contract (`42641355103`), knowledge sync (`42641355025`), llama CPU/Vulkan (`42641355199`), Stable Diffusion CPU/Vulkan (`42641354978`), HTP build (`42641355238`), and HMX build (`42641355262`). HTP/HMX publication was skipped because this is a draft pull request.

The separate `~/ternux-tools` checkout still has six owner-modified/untracked entries: the two accelerator plans, two QNN experiment files, `experiments/qnn-native/clip_mnn_native_probe.cpp`, and `experiments/native-ai-qualification/`. The detached `~/ternux-package-audit` worktree has an untracked `ci-artifact/` directory. Read-only inspection of its build metadata confirms it is a generated, unsigned CI package/rootfs for project commit `b3a0f894…` (Nov 7), with a doctor snapshot; it is preserved and not staged, moved, or deleted. It is stale evidence and does not qualify the current head or public APT. Neither checkout's content was silently included in PR #97.

The report-only refresh was committed as `a165b532488a08388566a2a1edfa7f21b3e5424b`; its Validate, package, and documentation checks passed, while accelerator builds were still running at the time of this snapshot. The four hosted signed APT paths were checked again on 2026-11-09 and each returned HTTP 404. Non-deploy signing verification then passed on main commit `8e24062589e81c20095c875fa4d19dd5cb928554` (run `42654336547`): the v2 package and signed repository were built and signature-verified, with ephemeral key cleanup; website build, artifact upload, and deployment were skipped. Public install remains unavailable until the approved publication workflow runs and device install is verified.

Local verification on the previous report-only refresh: `bash tests/focused.sh` passed **134/134** and documentation checks passed. On updater commit `ce435e90cf4c4c4394d5bf2d0228858ad3ed34e2`, `bash tests/focused.sh` passed **133/133**, including transaction/recovery fixtures; `python3 tests/docs_check.py` passed **3,041 assertions, 312 internal links, and 20 bilingual page pairs**; shell syntax checks and `git diff --check` passed. The Astro production build was not run because dependencies are not installed in this Termux checkout (`node_modules/.bin/astro` is absent).

### Local source checks

- `bash tests/focused.sh`: **133 checks, 133 passed** on updater commit `ce435e90cf4c4c4394d5bf2d0228858ad3ed34e2`.
- `python3 tests/docs_check.py`: **3041 assertions, 312 internal links, 20 bilingual page pairs passed**. The Termux host could not run the Astro site build (`astro` is unavailable here); GitHub Actions rebuilds the generated sitemap.
- `bash -n` passed for the changed shell modules and launcher/uninstaller entry points.
- `git diff --check`: passed after final edits.
- Read-only source CLI probe: `info --json` returned `vulkan_state=VULKAN_READY`, `graphics_state=OPENGL_ACCELERATION_READY`, and renderer `zink Vulkan 1.4(Adreno (TM) 825 (MESA_TURNIP))` on the connected Redmi Turbo 4 Pro.

### Physical-device Vulkan observation

- Termux-host `vulkaninfo --summary` failed with `VK_ERROR_INCOMPATIBLE_DRIVER` for GPU ID `6830`; a host Vulkan library alone is insufficient evidence.
- Debian guest `vulkaninfo --summary` enumerated `Adreno (TM) 825`, `PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU`, `DRIVER_ID_MESA_TURNIP`, and a separate `llvmpipe` CPU device.
- Live X11 renderer query identified the Zink/Turnip renderer. The desktop remained running throughout.

These observations qualify only this device and current software stack. They do not qualify other Adreno devices, Mali/Xclipse devices, or sustained graphics performance.

### GitHub Actions on prior source head `8101fa5`

All required PR workflows passed on exact head `8101fa5e51f0f5b28c51a35b4d714cd0836c0026`:

| Workflow | Run ID | Result |
|---|---:|---|
| APT unsigned package build/inspection | `42620922012` | Passed |
| State contract | `42620921995` | Passed |
| Shell, behavior, documentation | `42620922110` | Passed |
| Knowledge sync/test | `42620922151` | Passed |
| llama.cpp CPU + Vulkan artifact | `42620922091` | Passed |
| Stable Diffusion CPU + Vulkan artifact | `42620922036` | Passed |
| Snapdragon HTP candidate | `42620921974` | Build passed; publication skipped on PR |
| Snapdragon HMX candidate | `42620921987` | Build passed; publication skipped on PR |

Those CI runs predate the current lifecycle and Vulkan-state changes. On exact head `0906ffa74f4d7de1f4f3d58a596d6a729531a803`, the first `Validate` run (`42630638797`) failed one focused assertion: its Vulkan parser test assumed the host had `proot-distro`, so GitHub Actions skipped the mocked guest probe. The implementation passed locally; the test now explicitly enables the guest-probe path. The Termux package, repository-contract, and knowledge-sync jobs passed. The second run also exposed a stale sitemap-count assertion (36); the two new bilingual report pages raise it to 38. Both test issues were fixed. All PR workflows then passed on exact head `8ed1766f75735bcb55777f2a718988429c184d78`:

| Workflow | Run ID | Result |
|---|---:|---|
| Termux APT package build/inspection | `42631907368` | Passed |
| Repository state contract | `42631907373` | Passed |
| Shell, behavior, documentation | `42631907351` | Passed |
| Repo knowledge sync/test | `42631907829` | Passed |
| llama.cpp CPU + Vulkan artifact | `42631907378` | Passed |
| Stable Diffusion CPU + Vulkan artifact | `42631907382` | Passed |
| Snapdragon HTP candidate | `42631907409` | Build passed; publication skipped on PR |
| Snapdragon HMX candidate | `42631907376` | Build passed; publication skipped on PR |

A documentation-only commit updates this report after those results; its own exact-head CI will run separately.

### Latest exact-head CI — `65c2ad7aa517a6d50af5b1259a447cabbeb427ed`

All eight required PR workflows passed on this exact head on 2026-11-09: Validate `42667605757`, APT artifact `42667606027`, repository contract `42667605778`, knowledge sync/test `42667606023`, llama CPU/Vulkan `42667605843`, Stable Diffusion CPU/Vulkan `42667605877`, HTP artifact `42667605868`, and HMX capability probe `42667606050`. HTP/HMX publication jobs were skipped because PR #97 remains a draft. The focused regression suite passed 133/133, including the new assertion that managed desktop stop reaps its test process group. The release-gate validator passed and reports `NOT_READY` with nine incomplete blocking gates.

### Physical-device CPU/Vulkan lifecycle follow-up — 2026-11-10

The existing SM8735/Adreno 825 installation passed a fresh CPU and Vulkan known-answer reopen after each backend's bounded SIGINT cancellation. Both 4,096-token generations stopped at the five-second deadline with expected status 124, logged normal exit, and left no `llama-cli` process; the immediate fresh runs returned `4`. The desktop and audio session remained active. Details, model/binary hashes, and limits are in the [device benchmark record](https://github.com/soobujmiah/ternux/blob/main/guides/device-benchmark-evidence.md#2026-11-10-bounded-cpuvulkan-cancellation-and-reopen-check). Memory-pressure and sustained thermal/cancellation tests remain incomplete, so CPU/Vulkan qualification stays partial.

## Remaining blockers and release exclusions

| Priority | Gate | Current status | Required evidence before v2.0.0 |
|---|---|---|---|
| P0 | Current-head CI and PR review | **All eight required workflows passed on exact head `65c2ad7aa517a6d50af5b1259a447cabbeb427ed`; owner review remains open** | Validate `42667605757`, APT `42667606027`, contract `42667605778`, knowledge sync/test `42667606023`, llama Vulkan `42667605843`, Stable Diffusion Vulkan `42667605877`, HTP `42667605868`, HMX probe `42667606050`. Publication steps skipped on draft PR. Owner review and final diff review remain open. |
| P1 | Desktop lifecycle on device | **Code changed; live deployment unverified** | After a controlled package/update path, verify repeated/overlapping start, `status --json`, stop/start, crash/stale-record recovery, X11 socket ownership, audio readiness, and ensure the current working GUI remains usable. Current live session was deliberately not restarted. |
| P1 | Update transaction and provenance | **Implemented and locally fixture-tested; migration remains partial** | Verify on a published v2 release in native Termux, then verify the first v1.4.0 upgrade path. Release tags are not signed, and the old installed updater cannot be retroactively replaced before the transition. |
| P1 | APT repository and clean install | **Signing/build pipeline verified; public endpoint unavailable and device install unverified** | Non-deploy signing run `42654336547` passed on main `8e24062589e81c20095c875fa4d19dd5cb928554`; publish/deploy remained skipped. On 2026-11-09, bootstrap, key, `InRelease`, and `Packages` URLs returned HTTP 404. After all release gates and owner approval, publish the signed repository and verify clean `pkg install ternux`, upgrade, and uninstall on a supported Termux device. |
| P1 | Workload correctness | **CPU/Vulkan correctness and one bounded cancellation/reopen path verified; broader qualification remains partial; HTP/HMX/QNN experimental** | On the SM8735/Adreno 825 device, CPU and Vulkan known-answer checks returned `4`; verbose logs confirmed 25/25 layers offloaded in prior tests. On 2026-11-10, both backends also exited cleanly after bounded SIGINT and reopened successfully. Broad model/quality coverage, memory-pressure and sustained-run/cancellation matrices remain incomplete. HTP numerical failures and QNN stage-tensor correctness gaps remain. |
| P1 | Host-path exposure review | **Partial: `/sdcard` access is intentional; Termux home/prefix are also bound by default** | Preserve normal shared-storage access. Audit whether the camera/microphone bridge can use narrower Termux API bindings instead of exposing all of Termux home/prefix, then verify desktop, audio, camera and microphone behavior. |
| P1 | Repository governance | **Protection gap verified; no settings changed** | Read-only GitHub API on 2026-11-09: `main` has no branch protection (404), repository rulesets list is empty, and no required checks are enforced. A tracked `.github/CODEOWNERS` already assigns `@soobujmiah` as the default and for sensitive paths. Dependabot security updates, secret scanning, and secret push protection are enabled; non-provider secret scanning and validity checks are disabled. Release-branch and required-review enforcement remain absent. No repository settings were changed. |
| P2 | Proposed license terms | **Draft PR #35 awaits owner review; current release source remains Apache-2.0** | Keep PR #35 out of this release unless Sobuj reviews and merges it. The proposal is optional and is not a v2 release blocker while current terms and notices remain intact. |
| P2 | Full release documentation and review | **Partial** | Reconcile README/install/upgrade/uninstall/known-limitations text against current package contents and publish a complete release notes set after technical gates pass. Review the broad PR diff (551 files at Stage 0) for unrelated or duplicated changes. |
| P2 | Installer phase modularization | **Not started; `lib/phases.sh` is 2,439 lines** | Plan a compatibility-preserving, incremental split by responsibility and add boundary tests before moving functions. No one-shot rewrite was attempted. |
| P2 | Test architecture | **Partial; `tests/focused.sh` is 2,781 lines** | The updater transaction suite is now separate; split remaining tests into core, installer, desktop, GPU, extension, package, security, and docs suites while retaining the full regression contract. |
| P2 | Workload manifest schema | **Not started; extension/workload selection remains code-defined** | Define and migrate to a common schema for version, architecture, backend, dependencies, source/checksum, licenses, permissions, verification, cleanup, hardware, and experimental status. `packaging/termux/manifest.json` is only a package file list, not this schema. |
| P2 | Machine-readable release gates | **Implemented and exact-head CI verified** | `docs/release-gates.json` tracks 19 gates and keeps source, CI and device state separate. `tests/release_gates.py` validates the schema, evidence-file paths, duplicate IDs, exclusions, failed/pending CI and readiness derivation; exact-head Validate `42667605757` passed the regression fixtures. Inventory derives `NOT_READY` from nine incomplete blocking gates. |
| P2 | Device coverage | **One-device evidence only** | Record supported hardware/software matrix and mark other GPU/NPU paths `NOT_TESTED` or experimental. Do not generalize Redmi Turbo 4 Pro results. |

Native AI qualification work in `~/ternux-tools` is preserved. It does not currently prove Ternux release integration or stable HTP/QNN support.

## Final recommendation

**NOT_READY.** All eight required workflows passed on exact source head `65c2ad7aa517a6d50af5b1259a447cabbeb427ed`; CI run IDs and results are listed above. Nine blocking gates remain incomplete: branch/owner review, controlled device lifecycle, published updater migration, host-path review, governance, workload qualification, public APT, native package lifecycle, and final documentation/package review. Public signed APT endpoints returned 404 on 2026-11-09. No release tag or publication was created.

No release tag, package publication, merge, repository-settings change, or live desktop restart was performed.
