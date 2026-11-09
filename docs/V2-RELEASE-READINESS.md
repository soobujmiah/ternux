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
| `skb` | Canonical remote verified; checkout already contains owner changes | Read for operating guidance only; no files changed. |
| Live desktop | Read-only status reported `running`, supervisor PID `16987`, Termux:X11 PID `16779`, PulseAudio PID `16492`, XFCE PID `20829` | Left running and untouched. No GUI restart or installed-file change was made. |

The separate owner checkout contains modified bilingual accelerator plans, QNN experiment files, and untracked native qualification artifacts. The exact list remains available from `git -C ~/ternux-tools status --short`; none of those files was discarded.

### Remote branch reconciliation

- PR #97 is open as a draft and targets `main`. At audit start its head contained the current main baseline and was 122 commits ahead.
- `origin/codex/v2-reinstall-device-evidence-2026-11-07` contains the IBus Ctrl+Space fix; equivalent trigger reset and assertions are already in the PR source.
- `origin/fix/detached-desktop-service-2026-11-06` has older APT trust work. Its implementation differs from the current packaging/signing flow and was not blindly cherry-picked.
- `origin/docs/record-htp-session-soak-2026-11-07` and `origin/docs/record-exact-ci-package-smoke` carry older evidence than current plans. Native AI evidence remains owner-local until reconciled against current source and runtime.

## Priority zero gates

| Gate | Result | Evidence / remaining work |
|---|---|---|
| Stable Diffusion dependency notices | **Fixed on `8101fa5`; CI passed** | Added exact upstream component/license mapping, embedded header notices, deterministic manifest/checksums, absent optional dependency handling, and regression tests. Current-head CI must pass again after the lifecycle/GPU changes below. |
| Release branch consistency | **Partial** | PR #97 is based on current main. The older APT and evidence branches above still need direct file-level reconciliation before final release branch selection. |
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

## Verification evidence

### Local source checks

- `bash tests/focused.sh`: **134 checks, 134 passed**.
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

## Remaining blockers and release exclusions

| Priority | Gate | Current status | Required evidence before v2.0.0 |
|---|---|---|---|
| P0 | Current-head CI and PR review | **All workflows passed on source head `8ed1766`; report-only follow-up CI pending** | Confirm the report-only head checks, review logs/artifacts, keep the PR draft, and obtain owner review. |
| P1 | Desktop lifecycle on device | **Code changed; live deployment unverified** | After a controlled package/update path, verify repeated/overlapping start, `status --json`, stop/start, crash/stale-record recovery, X11 socket ownership, audio readiness, and ensure the current working GUI remains usable. Current live session was deliberately not restarted. |
| P1 | Update transaction and provenance | **Not fixed** | `lib/update.sh` still shallow-clones the moving repository head and installs modules one by one. Pin source to a release commit, verify provenance/checksum, stage all files, test them before switch, and roll back on failure/interruption. |
| P1 | APT repository and clean install | **Public endpoint currently unavailable** | On 2026-11-09, `https://soobujmiah.github.io/ternux/apt/bootstrap.sh`, `apt/ternux-archive-key.asc`, `apt/dists/stable/InRelease`, and `apt/dists/stable/main/binary-all/Packages` all returned HTTP 404. Restore/deploy the signed repository, then verify signed index/key lifecycle and clean `pkg install ternux`, upgrade, and uninstall on a supported Termux device. |
| P1 | Workload correctness | **Mixed / experimental** | llama.cpp CPU/Vulkan artifacts build, but target-device known-answer, offload confirmation, memory pressure, repeated runs, cancellation, and sustained measurements remain incomplete. HTP/HMX remain experimental pending operator-level numerical qualification. QNN Stable Diffusion remains experimental and not integrated as supported NPU functionality. |
| P1 | Shared-storage/security review | **Partial** | Complete an end-to-end bind/permission audit and document optional storage exposure for each workload. Avoid inferring user data access from a tool’s ability to bind a path. |
| P1 | Repository governance | **Not changed** | Required checks, branch protection, CODEOWNERS and secret/release protection need owner-approved settings. No repository settings were modified. |
| P2 | Full release documentation and review | **Partial** | Reconcile README/install/upgrade/uninstall/known-limitations text against current package contents and publish a complete release notes set after technical gates pass. Review the broad PR diff (551 files at Stage 0) for unrelated or duplicated changes. |
| P2 | Device coverage | **One-device evidence only** | Record supported hardware/software matrix and mark other GPU/NPU paths `NOT_TESTED` or experimental. Do not generalize Redmi Turbo 4 Pro results. |

Native AI qualification work in `~/ternux-tools` is preserved. It does not currently prove Ternux release integration or stable HTP/QNN support.

## Final recommendation

**NOT_READY.** The Stable Diffusion notice defect is fixed. Desktop lifecycle and Vulkan detection changes, focused regressions, documentation, and all candidate build workflows passed on source head `8ed1766`. Controlled device verification is still outstanding. The public APT endpoint returns 404; updater rollback/provenance, workload correctness qualification, and owner-reviewed governance also remain outstanding.

No release tag, package publication, merge, repository-settings change, or live desktop restart was performed.
