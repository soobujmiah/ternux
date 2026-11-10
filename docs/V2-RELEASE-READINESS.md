---
title: "Ternux v2.0.0 release readiness"
description: "Current repository reconciliation, qualification evidence, and remaining release gates for Ternux v2.0.0."
lang: "en"
alt_url: "/bn/docs/V2-RELEASE-READINESS.html"
---
**Status: NOT_READY**
**Audit:** 2026-11-10 17:44 UTC
**Release tag/publication:** no v2.0.0 tag or release; GitHub latest stable is v1.4.0.
**Latest `main` at this audit:** `68f14ba48a67829d3aaa09b799233f79f2f59cc8`, generated-state merge over documentation PR #128 (`d87919f`). Product source remains `5e41401dd60bf5261f6a638c62b4ad94eea98812`.
**Machine gate:** `docs/release-gates.json` derives `NOT_READY`: six P1 release-blocking gates remain incomplete.

## Executive recommendation

Do not publish Ternux v2.0.0 yet. Source and CI remediation has advanced: the immutable installer, host CLI, and Debian guest CLI fallbacks now verify pinned source; PR #127 merged as `5e41401dd60bf5261f6a638c62b4ad94eea98812`; all required PR checks and the exact-main Validate, package-artifact, and Repo Knowledge Sync runs passed. The exact product-source ARM64 build and independent license audit for P0-01 passed in run `42863263043`; six P1 release-blocking acceptance checks still lack required evidence: updated installed desktop lifecycle, a published v2 migration, updated-package GUI/storage smoke, broader CPU/Vulkan qualification, signed public APT installation, and native package lifecycle.

Fresh direct HTTPS checks at 2026-11-10 17:44 UTC returned HTTP 404 for all four public signed APT paths. No APT publication, Pages deployment, v2 tag, or v2 release was made; `release_approved` remains false.

## Stage 0 — repository and work reconciliation

### Repository and active work

- Canonical origin is `https://github.com/soobujmiah/ternux.git`.
- Product-source audit baseline was clean `main` at `5e41401dd60bf5261f6a638c62b4ad94eea98812`; generated-state PR #126 subsequently advanced `main` to `0940a31e1a44d06442813c5c0061388b708877a1` with only `.repo/` changes. The source remediation is already on `main`; PR #128 refreshed this documentation and merged as `d87919f`. Generated-state PR #129 then merged as `68f14ba`; neither changed product source.
- PR #127 merged as `5e41401`. Its exact head `72a83f50071d5f2d5bc15b1091ce70a34b12ef8f` passed `Validate` run `42859849676`, package-artifact run `42859849734`, repo-contract run `42859849685`, and Repo Knowledge Sync run `42859849726` (`test` and `sync`).
- Exact-main runs for source commit `5e41401`: Validate `42860196252`, Termux package artifact `42860196300`, and Repo Knowledge Sync `42860196265` passed. Generated-state PR #126 merged as `0940a31`; exact-main Validate `42863611485`, package artifact `42863611730`, and Repository State Contract `42863611641` passed. The package is an unsigned CI artifact and is not a public release. The exact product-source ARM64 Stable Diffusion build, binary inspection, and license audit passed as run `42863263043` on `5e41401`; artifact `ternux-stable-diffusion-vulkan-linux-arm64-master-1053-candidate` (27,381,115 bytes) was uploaded. Prerelease publication was disabled and skipped.
- PR #126 was the generated `.repo` state synchronization from the Repo Knowledge Sync workflow; it merged as `0940a31` and contains no product-source change. Other open PRs are Dependabot action updates (#42, #44, #45) and the owner-review license proposal (#35); none is an active v2 product implementation PR.
- Relevant remote branches were inspected. The old `codex/v2-next-stage-2026-11-10` contains only stale report/gate edits; its evidence is superseded here. The Ctrl+Space change from PR #95 is already in current `main`. Workload-manifest code from PR #116 is in `main`. Older APT/deployment branches are stale or superseded. Experimental HTP/QNN branches and owner research artifacts remain excluded from stable claims. No branch was force-pushed or discarded.
- Local `ternux-task-fix` had no user changes or untracked files at audit start. No other active agent work was present. Separate research/local artifacts were not accessed or modified in this audit.

### Reconciliation matrix

| Finding | Status | Current evidence / remaining acceptance |
|---|---|---|
| P0-01 Stable Diffusion Vulkan license CI | **COMPLETE** | Deterministic component manifest, source/header notices, missing/duplicate/path regressions, and exact product-source ARM64 build/license audit all pass. Run `42863263043` built and inspected the ARM64 artifact and independently audited the license bundle on `5e41401`; prerelease publication was disabled. |
| P0-02 release branch consistency | **COMPLETE** | v2 source is integrated on `main`; PR #127 source checks and latest exact-main checks on `68f14ba` passed. PR #128 docs and generated-state PR #129 are merged. No v2 tag exists. |
| P0-03 release gate | **COMPLETE** | 19 machine-readable gates; validator returns `NOT_READY` while any blocking gate is incomplete. |
| P1-01 desktop lifecycle | **PARTIAL** | Source lifecycle fixtures and current live READY status pass. Installed `desktop.sh` differs from current source; updated-package stop/restart/crash-recovery and managed-process identity are not verified. |
| P1-02 GPU/Vulkan detection | **COMPLETE for tested Adreno 825 only** | Physical device reports Adreno 825, Vulkan/Turnip and Zink renderer; software renderer false positives have regression coverage. Other GPU/device families are not qualified. |
| P1-03 installer/updater reliability | **PARTIAL** | Bootstrap archive, host CLI archive, and guest CLI fallback use immutable commit pins and SHA-256 checks; tamper regressions pass on merged PR #127. Local v1.4.0 migration/rollback fixtures pass. Published-v2 native migration remains untested. |
| P1-04 storage isolation | **PARTIAL** | `/sdcard` is intentionally available in PRoot; generic guest tests preserve it while isolating Termux HOME. Full updated-package XFCE/app smoke remains unverified. |
| P1-05 repository protection | **COMPLETE** | Main branch protection read-back showed required PR checks, admin enforcement, and force-push/deletion disabled; required approval count is zero to support the owner-only repository. |
| P1-06 CPU/Vulkan LLM | **PARTIAL** | Qwen2.5 0.5B/1.5B CPU/Vulkan correctness, 25/25 and 29/29 layer offload, short repeated throughput, cancellation and reopen evidence exists on one Adreno 825. Fresh single-turn runs returned 4 on both models/backends. Broad-model and sustained/memory-pressure qualification remains. |
| P1-07 HTP/HMX | **PARTIAL, experimental and release-excluded** | Numerical operator failures/incomplete qualification remain; no stable default or claim. |
| P1-08 QNN Stable Diffusion | **PARTIAL, experimental and release-excluded** | Stage-tensor/reference correctness and production qualification remain incomplete. |
| P1-APT public repository | **BLOCKED** | All four canonical signed APT URLs return 404. Publish, hosted verification, Pages preservation, and clean Termux install/upgrade/uninstall remain. |
| P1-PKG native package lifecycle | **PARTIAL** | Unsigned package artifact and metadata checks pass. Native clean install/update/repair/uninstall remain unverified. |
| P1-DOCS | **COMPLETE for source documentation** | README, install/update/remove, troubleshooting, accelerator and security docs are present and bilingual checks pass. Release notes must be finalized against the eventual published artifacts. |
| P2-01 installer modularization | **NOT_STARTED; non-blocking** | Keep as incremental maintainability work; avoid broad refactor during release qualification. |
| P2-02 test decomposition | **PARTIAL; non-blocking** | `tests/focused.sh` remains large; regression coverage is retained. Split incrementally after critical release gates. |
| P2-03 workload manifest | **COMPLETE** | Schema, canonical manifest, generated registry and extension lifecycle are in `main`. |
| P2-04 machine release governance | **COMPLETE** | Schema, duplicate/failure/exclusion tests and readiness derivation are active. |
| P2-DEVICE multi-device matrix | **PARTIAL; non-blocking** | Qualification is limited to the documented Redmi Turbo 4 Pro / SM8735 / Adreno 825. Other devices remain untested or experimental. |

## Implemented remediation

- Stable Diffusion license inventory uses an explicit component manifest, deterministic bundle/index/checksum generation, and regression checks for missing, duplicate, unsafe, and embedded notice paths.
- Installer source acquisition and host CLI fallback use a pinned codeload commit plus SHA-256 verification. The Debian guest CLI fallback now fetches `bin/ternux-guest` from that same immutable commit and verifies its dedicated SHA-256 before syntax validation or installation.
- Desktop lifecycle uses owned-process/session identity and bounded readiness probes; X11 and audio are reported independently. Source tests cover start/reuse/stop, stale state, concurrency, and lock contention.
- Renderer detection separates hardware, loader, ICD, device enumeration, renderer and acceleration state, and identifies common software renderers as `SOFTWARE_FALLBACK`.
- Generic PRoot access preserves `/sdcard` when present and does not expose Termux HOME. Shared `/tmp` remains explicit.
- Main branch protection and release-gate validation are active. Workload metadata and managed extension behavior use the canonical workload schema/registry.
- Signed APT construction/preservation checks verify key, Release metadata, index/package checksums and safe paths. This makes deployment verifiable; it does not publish a repository.

## Verification evidence

### Current repository and CI

| Evidence | Result |
|---|---|
| `bash tests/focused.sh` on the PR #127 source | **150/150 pass**, including pinned CLI/guest fallback success and tampered-byte rejection. |
| `python3 tests/docs_check.py` | **3096 assertions**, 312 internal links, 20 bilingual page pairs passed. |
| `python3 tests/release_gates.py --self-test` | 19 gates valid; `NOT_READY`; six incomplete blocking gates, all P1. |
| `git diff --check`, Bash syntax checks | Passed for the merged installer changes. |
| PR #127 exact-head required checks | Validate, package artifact, repo-contract, Repo Knowledge Sync test/sync all passed. |
| Main `5e41401` exact-SHA CI | Validate `42860196252`, package artifact `42860196300`, Repo Knowledge Sync `42860196265` passed. |
| Stable Diffusion ARM64 and license bundle | Exact product-source build, binary inspection, and independent license audit passed in run `42863263043`; 27,381,115-byte candidate artifact uploaded, prerelease publication skipped. |
| Device CPU/Vulkan smoke | Qwen2.5 0.5B/1.5B known-answer passed on CPU and Vulkan0; verbose logs confirmed full layer offload. Battery rose 36.3°C → 37.4°C; no sustained run. |

### Device and distribution

- Native `ternux status --json` at 2026-11-10 17:42 UTC reports version 2.0.0, desktop `running`, X11 `yes`, PulseAudio `running`, launcher present, PID 16987. `ternux verify --json` passed at 17:44 UTC.
- `ternux verify --json` at 17:44 UTC passed on Android 16, Adreno 825; Termux:X11, PRoot-Distro, PulseAudio, `setsid`, launcher, Debian services and Turnip were present.
- `dpkg -V ternux` returned no modified packaged files. This does not prove package lifecycle success.
- Source `lib/desktop.sh` SHA-256 is `b3f0753a771f54c2c337310b2f23485926c9fded314ace818d76828c96af8ea3`; installed `$PREFIX/lib/ternux/desktop.sh` is `02c5f6175f45c94c4ec68f323294f1c633bd7e4f501430b243f72132ed0950cb`. Therefore the current running desktop is not evidence for the updated source lifecycle.
- Latest `ternux doctor --quick --json` at 17:42:58 UTC reports 42°C battery temperature and 3646 MB available memory. No sustained inference/rendering or artificial memory-pressure run was started at that thermal state. Existing evidence remains limited to one device and does not close broad-model, sustained thermal, or memory-pressure qualification.
- The provided `adb` binary cannot start because of a missing Android NDK linker symbol. Native `$PREFIX` is outside this session's writable paths, so this session cannot install the CI package or run native package lifecycle changes. The current GUI/service was not stopped, restarted, or modified. Source `desktop.sh` SHA-256 `b3f0753a...` still differs from installed `02c5f617...`.
- Direct HTTPS GET at 2026-11-10 17:44 UTC returned **404** for `apt/bootstrap.sh`, `apt/ternux-archive-key.asc`, `apt/dists/stable/InRelease`, and `apt/dists/stable/main/binary-all/Packages`.
- Signing-only APT verification run `42863371746` passed and skipped all deployment-related steps. GitHub latest stable is `v1.4.0`; there is no v2.0.0 release tag/publication. No APT publish, Pages production deployment, or v2 release action was performed.

## Exact blockers and next acceptance evidence

1. **P1-01 desktop lifecycle:** safely install/use the exact package containing current `desktop.sh`; verify owned PID identity, bounded XFCE/X11 readiness, independent audio status, stop/restart, crash recovery, and unrelated-process/socket preservation.
2. **P1-03 updater migration:** after an approved v2 publication exists, run native v1.4.0 → v2 migration and rollback on the supported Termux device; keep the exact local transaction fixtures passing.
3. **P1-04 storage/security:** through the updated package, smoke-test XFCE and user-facing apps while confirming expected `/sdcard` access and Termux HOME isolation.
4. **P1-06 CPU/Vulkan:** complete the supported-device correctness, fallback, memory-pressure, repeated, cancellation and cleanup matrix. Recheck thermal state before long tests; do not infer broader-device support.
5. **P1-APT:** after owner approval, publish the signed repository, verify all hosted paths and signatures/hashes, confirm a routine Pages deployment preserves `/apt`, then test clean `pkg install`, upgrade and uninstall.
6. **P1-PKG:** verify native package install/update/repair/uninstall and metadata/checksum on the supported Termux device; CI artifact integrity alone is insufficient.

HTP/HMX and QNN Stable Diffusion remain explicitly experimental/research-only and are not required for the stable Ternux v2 claim. P2 modularization, test-suite splitting and multi-device qualification remain documented non-blocking work.

## Final recommendation

**NOT_READY.** Current source and exact-main CI on `68f14ba` are verified, but six release-blocking acceptance checks remain incomplete. The public APT repository is absent, and the running installed package does not contain the current desktop lifecycle module. Do not tag or publish v2.0.0 until the device/package gates close and the repository owner explicitly approves publication.
