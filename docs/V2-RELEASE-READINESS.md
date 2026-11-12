---
title: "Ternux v2.0.0 release readiness"
description: "Repository reconciliation, implementation evidence, device qualification, and open release gates for Ternux v2.0.0."
lang: "en"
alt_url: "/bn/docs/V2-RELEASE-READINESS.html"
---
**Status: NOT_READY**
**Audit date:** 2026-11-12 (rechecked after PR #178; candidate fixes in this branch are not merged)
**Target:** Ternux 2.0.0
**Current qualification source:** main `bad334de607718cb6a171bb1806bc6fb8e1a9b38` (PR #178). This audit branch adds an apt-safe non-Debian Mesa overlay and an isolated signed APT RC channel; these changes still need exact-head CI and publication.
**Product source audit base:** `159806ff395a34349086504ae3055ddef21ddbec`
**Latest stable release:** v1.4.0; no v2.0.0 tag or release exists.
**Machine gates:** 20 gates; P1-01, P1-02, P1-04, and P1-PKG are complete. Three release blockers remain: P1-03, P1-09, and P1-APT.

**Fresh release check:** `python3 tests/release_gates.py --check` reports `NOT_READY` with those three blockers. GitHub still lists v1.4.0 as the latest stable release; no v2.0.0 tag or release exists. The stable APT bootstrap, archive key, `InRelease`, and `Packages` are unpublished. Local RC bootstrap and signed Pages-preservation tests pass, but the RC tree has not been published or tested via native `pkg`. V3 proposals are tracked separately in [Ternux v3 proposals](V3-PROPOSALS.md); they are not part of v2 release acceptance.

## Current three-profile device check (2026-11-12)

On the Redmi Turbo 4 Pro / SM8735 / Adreno 825, Debian (`:0`), Ubuntu (`:1`), and Alpine (`:2`) were each started and checked on the current managed setup. All three reported Zink on Mesa Turnip, PulseAudio playback completed, microphone capture returned data, IBus Ctrl+Space configuration/engine switching was checked, and the shared Ternux theme/wallpaper assets were present. This is partial runtime integration evidence for these three profiles on this one device; it does not establish clean installation, browser installation, every desktop app, upgrade/migration, or support for the other 12 profiles. `tx stop --all` then stopped all three. `tx status db`, `ub`, and `alp` each report `STOPPED`; the host PulseAudio daemon remains running without a guest route, which is expected after desktop shutdown.

### Native package follow-up (2026-11-12)

Native package and clean-guest evidence (2026-11-12): `tx uninstall all --yes` removed all three registered Debian/Ubuntu/Alpine guests, Ternux launcher/aliases, state/logs, and the Termux `ternux` package files. Postchecks found no PRoot containers, Ternux dpkg package/CLI, Ternux state directories, or package-owned modules; Termux:API remained installed and Android shared storage was untouched. No unrelated PRoot guest existed in the pre-test inventory. The exact local `ternux_2.0.0_all.deb` was then installed fresh, replaced over the installed package, and passed `dpkg --verify`; `tx --version` and `tx distro list` passed. This closes native package lifecycle cleanup/install; public-repository install/upgrade is separate P1-APT evidence. A fresh Debian guest created by this package reads `/sdcard`, `/sdcard/Llms`, and `/sdcard/LAI/models`; guest HOME is `/home/ternux`, and Termux HOME is not exposed. The same path checks passed after reinstalling the package. The Termux shell injects `LD_LIBRARY_PATH`, so package operations use a cleared value. No unrelated Termux packages were upgraded.

Current package regression checks: `bash tests/focused.sh` passed 178/178; multi-guest, all 15 recipe generators, signed-APT bootstrap/preservation (including RC channel), updater migration/rollback, and release-gate self-tests pass. Fresh Debian, Ubuntu, and Alpine browser provisioning is qualified; Alpine’s clean install also exposed and helped fix its archive-specific `/usr/lib` Turnip layout, then passed Vulkan and live Zink checks. Arch, RPM, openSUSE, and Void browser routes remain open. `npm run format:check` and exact-head CI are required on the final PR. Local `tests/docs_check.py` found the generated sitemap snapshot has 38 URLs while its current source contract expects 40; the Termux Node binary cannot run the local Astro build, so final site validation must come from CI. `bats` is not installed in this runtime; CI remains required. `python3 tests/release_gates.py --check` correctly remains NOT_READY with three blockers.

## Recommendation

Do not publish v2.0.0 yet. PR #178 is merged and all three exact-main checks passed; the candidate changes described here are still unmerged. Native package install/removal, full Ternux cleanup, and clean Debian storage isolation pass. Remaining gates are RC-backed v1.4.0-to-v2 migration/rollback, clean browser qualification across package-manager families, and signed public APT install/upgrade verification. The v3 proposal document is a planning note only; it does not change v2 scope or gate status.

## Stage 0 — reconciliation

The audit began with a clean `main` at `bcf363e10bc52a87fe2806a28f44dfdd220cf98f`. Open PR #137 was a CI-generated `.repo/` state update. It had three checks registered while the `Repo Knowledge Sync` run waited for first-run approval; the workflow's branch-filtered API query hid that fourth run and timed out. PR #138 fixed discovery, bounded polling to one newest-100 API page, passed all required checks, and merged as `5d4be243e8d3`. Its main-triggered state PR #137 then passed its exact-head checks and merged as `aff6aae40f8fa22bfe76a2a91e56f1ee10c51b60`. No `.repo/` files were edited by hand.

PR #139 implemented storage privacy and merged with all required checks as `eaf97fc514c045193e7ef5968a95d1b26c449f9c`. The generated-state PR #140 passed its checks and merged as `3c03dffa4ba07a2c0355613560c0768b45022c96`. This audit update merged as PR #141 (`2763bac0cde5f38e2d3009eb236db2a89606f1c1`), followed by generated-state PR #142 (`f35fd95f60731c7d4638099285b7b314f459f4d2`). Follow-up PR #143 recorded the bounded CPU/Vulkan model profile and 90-day package-artifact retention; its current-main merge is `30bea68ff4440a97fc98a3f2c8b4d041e13c15f8`. Generated-state PR #144 then passed checks and merged as `de52efcf5d4666dfa872c248d9370607a209c1ed`. The verified SKB checkout was dirty at session start and was left untouched. Open PRs #42, #44 and #45 are Dependabot action updates; PR #35 is an owner-review licensing proposal and was not merged.

Latest reconciliation: PRs #147/#149 fix transient Pages 5xx retries and merge as `c78c03efa9875ca96613165de64bbcb174f1d075`. Generated-state PR #150 merged as `159806ff395a34349086504ae3055ddef21ddbec`; docs PRs #151/#153 and generated-state PRs #152/#154 followed. The current audit snapshot is exact `main` `c3d318dfe9e2e6dadc73c33198b92f2dd4eeb33a`; changes after product-source base `159806ff` are documentation and generated repository state. Exact-main Validate `42916453866`, package artifact `42916453776`, and Repository State Contract `42916453730` passed. PR #153 exact-head Validate `42915521511`, package artifact `42915521584`, Repo Knowledge Sync `42915521562`, and repo-contract `42915521483` passed. Non-publishing signing verification `42916703212` passed on current main; the deploy/publish job was skipped. Open PRs remain #42/#44/#45 (Dependabot) and #35 (owner-review licensing). Package-audit worktree at `727726a6b32124992a8c0153159a440ced0708c8` and its untracked CI artifact remain preserved. Codex TUI task/worktree enumeration failed because its local MCP endpoint refused connections, so other Codex sessions are not claimed as enumerated. Read-only native status and `ternux verify` pass for the pre-existing live desktop (PID 16987, Termux:X11 and PulseAudio running); installed-package hashes still differ from current source, and no restart occurred. Managed session filesystem policy excludes native `$PREFIX` writes and the ADB executable fails to load, so updated-package lifecycle or GUI-control evidence cannot be produced in this session. Open PRs remain #42, #44, #45 (Dependabot) and #35 (owner-review licensing proposal). The package-audit worktree remains detached at `727726a6b32124992a8c0153159a440ced0708c8`; its untracked `ci-artifact/` was inspected and preserved. Codex TUI task/worktree enumeration was unavailable because its local MCP endpoint refused the connection, so no claim is made that other Codex sessions were enumerated. The current live desktop was observed read-only as running with Termux:X11 and PulseAudio; it was not restarted. This session's managed filesystem scope does not permit writes to native `$PREFIX`, and its ADB binary fails to load, so native package lifecycle and GUI-control evidence cannot be added from this session.

## Finding reconciliation

| Finding | Status | Evidence and remaining acceptance |
|---|---|---|
| P0-01 Stable Diffusion Vulkan license CI | **COMPLETE** | Deterministic notice manifest and regression checks are present. Exact ARM64 build, binary inspection and independent license audit passed in run `42863263043` on source commit `5e41401dd60bf5261f6a638c62b4ad94eea98812`; prerelease publication was skipped. |
| P0-02 release branch consistency | **COMPLETE** | Product fixes are on `main`; PR #138, generated-state PRs #137 and #140, and storage PR #139 are merged. Exact-main checks on product head `eaf97fc` all passed; no release tag exists. |
| P0-03 machine release gate | **COMPLETE** | `docs/release-gates.json` has 20 gates; `tests/release_gates.py` derives `NOT_READY` while any of the three remaining blocking checks is incomplete. |
| P1-01 desktop lifecycle | **COMPLETE** | Exact native package reached READY with working X11 and PulseAudio route, stopped cleanly on Debian, Ubuntu, and Alpine, and recovered from a controlled verified process-group crash. Recovery moved FAILED → READY → STOPPED; host PulseAudio status remained distinct from guest route status. Bounded readiness, ownership and concurrency regressions pass in CI. |
| P1-02 GPU/Vulkan detection | **COMPLETE on the qualified device only** | Debian, Ubuntu, and Alpine each reported Vulkan/Turnip-backed Zink on Redmi Turbo 4 Pro / SM8735 / Adreno 825; software-renderer false positives have regression coverage. Other device families are not qualified. |
| P1-03 installer/updater | **PARTIAL** | Pinned bootstrap, host CLI and guest CLI checks reject tampered source; local rollback and v1.4.0-to-v2 fixtures pass. Published-v2 native migration/rollback remains untested. |
| P1-04 storage availability | **COMPLETE** | A fresh Debian guest created by the native package flow reads `/sdcard`, `/sdcard/Llms`, and `/sdcard/LAI/models`; guest HOME is `/home/ternux`, and Termux HOME is not exposed. Replacing the exact local package and rechecking the paths passes. |
| P1-09 default browser | **PARTIAL** | Firefox is mandatory in every fresh profile and all 15 recipe routes pass. Fresh Debian and Ubuntu installs passed; Ubuntu ESR 153.7.0esr passed desktop-file validation and a headless PNG launch check. Fresh Alpine 3.24 installed Firefox ESR 140.12.0, passed desktop-file validation and generated a valid 1366×768 headless PNG; Arch, RPM, openSUSE, and Void package-manager families remain unqualified. |
| P1-05 repository protection | **COMPLETE for the owner-only repository** | Live read-back confirms required PR and checks, strict checks, admin enforcement, force-push/deletion disabled, and zero required approvals so the sole owner can merge their own PR without impossible second-person review. `.github/CODEOWNERS` names the owner. |
| P1-06 CPU/Vulkan LLM | **COMPLETE for the declared device/model/workload profile** | On SM8735 / Adreno 825, Llama 3.2 3B Q4_K_M passed CPU/Vulkan known-answer and support-queue retrieval under 768 MiB pressure; bounded cancellation/reopen and CPU/Vulkan generation stability are verified. Five 512-token CPU runs and four Vulkan runs completed; each route stopped further work at the 42°C battery guard. Three Qwen variants failed 100-record exact retrieval, and the pressure-time invoice probe returned 24.75 instead of 39.50. These model/task combinations, other devices, and general correctness claims are explicitly excluded. |
| P1-07 HTP/HMX | **PARTIAL; experimental and release-excluded** | Known numerical/operator failures remain. Failing operators are not stable defaults; no production claim is made. |
| P1-08 QNN Stable Diffusion | **PARTIAL; research-only and release-excluded** | Stage-tensor reference correctness and production qualification are incomplete. |
| P1-APT public repository | **BLOCKED** | The stable endpoints still need their signed release publication. A separate signed `/apt-rc` candidate channel, bootstrap selector, and stable/RC Pages preservation path are implemented; local signature, index, package hash, and channel-bootstrap tests pass. Publish the RC after merge, then verify hosted URLs and native `pkg` install/upgrade/uninstall before stable v2. |
| P1-PKG native package lifecycle | **COMPLETE** | Native `tx uninstall all --yes` removed all registered Ternux guests and owned host state/CLI files while Termux:API and Android shared storage remained. Fresh local `.deb` install/replacement, `dpkg --verify`, `tx --version`, and `tx distro list` pass. Public APT is tracked separately in P1-APT. |
| P1-DOCS | **COMPLETE for source documentation** | README, CLI, install, usage, security, accelerator and release-readiness docs are updated in English and Bengali. Pages publication uses the explicit main-only deployment workflow. |
| P2-01 installer modularization | **NOT_STARTED; non-blocking** | Keep future work incremental; avoid a broad refactor during qualification. |
| P2-02 test decomposition | **PARTIAL; non-blocking** | Focused regressions expanded; `tests/focused.sh` remains large. |
| P2-03 workload manifest | **COMPLETE** | Schema, registry and managed workload definitions are present. |
| P2-04 repository state and gate automation | **COMPLETE** | CI state sync now detects approval-gated checks; machine gate schema and readiness validation pass. |
| P2-DEVICE multi-device qualification | **PARTIAL; non-blocking** | Physical qualification is limited to Redmi Turbo 4 Pro / SM8735 / Adreno 825. |

## Changes delivered

- Fixed Repo Knowledge Sync polling so approval-gated runs are visible without paging through repository history; merged PR #138.
- Removed automatic Android storage permission requests during installation and broad `/sdcard` binds.
- Added `ternux storage list`, `grant DIRECTORY`, and `revoke DIRECTORY`. The mount source and guest path are validated on every guest login; the storage root, traversal paths, malformed grants and changed identities fail closed.
- Applied the allowlist to generic guest commands, the generated desktop launcher, and regenerated db/droot aliases. Re-running setup refreshes only Ternux's marked alias block while preserving surrounding shell configuration.
- Added the storage module to the Termux package manifest, refreshed the English/Bengali docs and changelog, and recorded the remaining device acceptance check.

## Verification

- `bash tests/focused.sh`: **153/153 passed**, including default no-mount behavior, exact scoped mounts, malformed/out-of-root rejection, stale revocation, no setup-time permission prompt, launcher/alias refresh and host isolation.
- `python3 tests/docs_check.py`: documentation, internal-link, and bilingual consistency checks passed.
- `python3 tests/release_gates.py --self-test` and `--check`: pass; 20 gates derive `NOT_READY` with three blockers: P1-03, P1-09, P1-APT.
- On-device Llama 3.2 3B CPU/Vulkan bounded sustained-generation evidence and the tested profile exclusions are recorded in the accelerator plan and benchmark guide.
- Bash syntax checks, `git diff --check`, and JSON parsing: pass.
- PR #139 head `53344d9a69a7f7a3019b10840a7495aaf56f548d`: Validate `42897454459`, unsigned package artifact `42897454586`, repo-contract `42897311193` and `42897454513`, Repo Knowledge Sync/test `42897454842`: all passed.
- Current-main `verify-signing` workflow `42902118784` passed on the audited baseline `f35fd95f60731c7d4638099285b7b314f459f4d2`; the publish job was skipped. The four public APT endpoints still return 404.
- Exact current source main `c3d318dfe9e2e6dadc73c33198b92f2dd4eeb33a`: Validate `42916453866`, package artifact `42916453776`, and Repository State Contract `42916453730` passed. Non-publishing signing run `42916703212` built and verified the signed repository; deployment steps were skipped. The last direct HTTPS check found all four APT paths 404.
- Read-only native check: `ternux status` shows desktop, Termux:X11 and PulseAudio running (PID 16987); `ternux verify` passes. The installed desktop module still differs from source, so this is not updated-package lifecycle evidence; no restart or package mutation was performed.
- Native read-only check in this reconciliation: `ternux status` reports the existing desktop, Termux:X11, and PulseAudio running (managed PID 16987). This is not updated-package lifecycle evidence. Native package install/uninstall was not attempted because the managed filesystem boundary excludes `$PREFIX`; no Termux package was touched.
- PR #143 head `fe2a990af4c335e834c1eba8a99bffa616706096` passed Validate `42906330663`, unsigned package build `42906330771`, repo-contract `42906330855`, and Repo Knowledge Sync/test `42906330849`. Its main push produced the retained artifact listed above.
- Generated-state PR #144 passed Validate `42906921938`, package artifact `42906921774`, repo-contract `42906921815`, and Repo Knowledge Sync/test `42906921733`; merged as `de52efcf5d4666dfa872c248d9370607a209c1ed`.
- Exact product head `eaf97fc514c045193e7ef5968a95d1b26c449f9c`: Validate `42897720583`, unsigned package artifact `42897720810`, Repository State Contract `42897720730`, Repo Knowledge Sync `42897720595`: all passed.
- Main package artifact run `42901133225` produced reusable CI artifact `13801733817`; this is unsigned build evidence, not a native package lifecycle test.
- Generated-state PR #140 head `e8754415c25fce38ab9bfd7011e990a5000b7fb8` passed Validate `42898005440`, unsigned package artifact `42898005215`, repo-contract `42898005314`, and Repo Knowledge Sync/test `42898005386`; merged as `3c03dffa4ba07a2c0355613560c0768b45022c96`.
- Local Astro build was unavailable: the Termux `node` binary fails to link `_ZNSt6__ndk113__hash_memoryEPKvm`. The exact-main Validate workflow passed, including its Ubuntu Astro site build. The running GUI and services were not restarted or modified.

## Device and release exclusions

The qualified device is Android 16 on Xiaomi 25053RT47C (Redmi Turbo 4 Pro, SM8735, Adreno 825). The exact native 2.0.0 package was installed from the local package artifact and passed `dpkg --verify`; its CLI started and stopped Debian :0, Ubuntu :1, and Alpine :2 with READY and PulseAudio route status. A verified Debian process-group crash produced FAILED, then packaged `tx start db` recovered to READY and `tx stop db` returned STOPPED. Package removal and fresh local-file `pkg install` passed. This is existing-guest device evidence, not clean guest provisioning or public APT installation.

HTP/HMX and QNN remain experimental/research-only. They are excluded from stable v2 claims. CPU/Vulkan support claims must stay within the model/device evidence above. No v2 tag/release or signed APT publication was made. Native package install/removal and exact-package desktop lifecycle were exercised. Browser routes pass in all 15 generated profiles, while clean first-install browser runs, native package update/repair, and full managed-container cleanup remain open.

## Remaining release blockers

1. **P1-03 updater:** publish the RC metadata/tag and verify v1.4.0-to-v2 migration, interrupted-update recovery, and rollback on device. Local migration/rollback fixtures pass.
2. **P1-09 browser:** finish clean-install browser qualification for the Arch, RPM, openSUSE, and Void package-manager families; 15 generated recipe routes pass, and fresh Debian, Ubuntu, and Alpine browser launches pass.
3. **P1-APT:** merge and publish `/apt-rc`, verify hosted signatures and hashes, then exercise native `pkg install`, `pkg upgrade`, and `pkg uninstall`. Stable `/apt` publication remains gated on the final release.

Re-run required CI on the final intended release commit. HTP/HMX and QNN remain excluded unless separately qualified.

## Final recommendation

**NOT_READY.** PR #177 is merged; P1-01, P1-04, and P1-PKG are complete. P1-03, P1-09, and P1-APT remain open. Do not tag or publish v2.0.0 until migration, clean browser qualification, and signed public APT evidence pass.
