---
title: "Ternux v2.0.0 release readiness"
description: "Repository reconciliation, implementation evidence, device qualification, and open release gates for Ternux v2.0.0."
lang: "en"
alt_url: "/bn/docs/V2-RELEASE-READINESS.html"
---
**Status: NOT_READY**
**Audit date:** 2026-11-11
**Target:** Ternux 2.0.0
**Current `main`:** `3c03dffa4ba07a2c0355613560c0768b45022c96`
**Latest stable release:** v1.4.0; no v2.0.0 tag or release exists.
**Machine gates:** 19 gates; six release-blocking gates remain incomplete: P1-01, P1-03, P1-04, P1-06, P1-APT, P1-PKG.

## Recommendation

Do not publish v2.0.0 yet. The source now fixes the generated-state CI timeout and makes Android storage opt-in and directory-scoped. CI passed for both merged PRs. Exact-main Validate, repository-contract, Repo Knowledge Sync, and unsigned Termux package artifact all passed; the generated-state PR also passed before merge. Native package installation and updated-package desktop validation remain open, the public APT endpoints still return 404, and one tested AI model family failed retrieval correctness.

## Stage 0 — reconciliation

The audit began with a clean `main` at `bcf363e10bc52a87fe2806a28f44dfdd220cf98f`. Open PR #137 was a CI-generated `.repo/` state update. It had three checks registered while the `Repo Knowledge Sync` run waited for first-run approval; the workflow's branch-filtered API query hid that fourth run and timed out. PR #138 fixed discovery, bounded polling to one newest-100 API page, passed all required checks, and merged as `5d4be243e8d3`. Its main-triggered state PR #137 then passed its exact-head checks and merged as `aff6aae40f8fa22bfe76a2a91e56f1ee10c51b60`. No `.repo/` files were edited by hand.

PR #139 implemented storage privacy and merged with all required checks as `eaf97fc514c045193e7ef5968a95d1b26c449f9c`. The generated-state PR #140 passed its checks and merged as `3c03dffa4ba07a2c0355613560c0768b45022c96`. The verified SKB checkout was dirty at session start and was left untouched; no other active agent work was present. Open PRs #42, #44 and #45 are Dependabot action updates; PR #35 is an owner-review licensing proposal and was not merged.

## Finding reconciliation

| Finding | Status | Evidence and remaining acceptance |
|---|---|---|
| P0-01 Stable Diffusion Vulkan license CI | **COMPLETE** | Deterministic notice manifest and regression checks are present. Exact ARM64 build, binary inspection and independent license audit passed in run `42863263043` on source commit `5e41401dd60bf5261f6a638c62b4ad94eea98812`; prerelease publication was skipped. |
| P0-02 release branch consistency | **COMPLETE** | Product fixes are on `main`; PR #138, generated-state PRs #137 and #140, and storage PR #139 are merged. Exact-main checks on product head `eaf97fc` all passed; no release tag exists. |
| P0-03 machine release gate | **COMPLETE** | `docs/release-gates.json` has 19 gates; `tests/release_gates.py` derives `NOT_READY` when a blocking acceptance check is incomplete. |
| P1-01 desktop lifecycle | **PARTIAL** | Source lifecycle regression coverage and prior live READY status exist. The installed v2.0.0 `desktop.sh` hash differs from current source; updated-package GUI, stop/restart and crash recovery remain unverified. |
| P1-02 GPU/Vulkan detection | **COMPLETE on the qualified device only** | Redmi Turbo 4 Pro / SM8735 / Adreno 825 reported Vulkan/Turnip and Zink; software-renderer false positives have regression coverage. Other device families are not qualified. |
| P1-03 installer/updater | **PARTIAL** | Pinned bootstrap, host CLI and guest CLI checks reject tampered source; local rollback and v1.4.0-to-v2 fixtures pass. Published-v2 native migration/rollback remains untested. |
| P1-04 storage isolation | **PARTIAL** | Default `/sdcard` binds and setup-time storage permission are removed. `ternux storage grant DIRECTORY` records only an existing canonical subdirectory; generic guest commands, desktop launcher, and db/droot aliases validate that same private allowlist. Focused regressions and PR CI pass. Updated-package device verification remains open; the pre-existing live desktop is from the old package and was not restarted. |
| P1-05 repository protection | **COMPLETE for the owner-only repository** | Live read-back confirms required PR and checks, strict checks, admin enforcement, force-push/deletion disabled, and zero required approvals so the sole owner can merge their own PR without impossible second-person review. `.github/CODEOWNERS` names the owner. |
| P1-06 CPU/Vulkan LLM | **PARTIAL** | Four local GGUF variants have three-repeat CPU/Vulkan benchmark evidence. Llama 3.2 3B passed a 180-record retrieval and 768 MiB pressure/recovery check on CPU and Vulkan. Three Qwen variants failed their structured retrieval probes; a pressure-time invoice probe returned 24.75 instead of 39.50. Longer soak and explicit supported-model boundary remain open. |
| P1-07 HTP/HMX | **PARTIAL; experimental and release-excluded** | Known numerical/operator failures remain. Failing operators are not stable defaults; no production claim is made. |
| P1-08 QNN Stable Diffusion | **PARTIAL; research-only and release-excluded** | Stage-tensor reference correctness and production qualification are incomplete. |
| P1-APT public repository | **BLOCKED** | On 2026-11-11 all four public paths returned 404: bootstrap, archive key, `InRelease`, and `Packages`. Signed publication, hosted verification, and clean Termux install/upgrade/uninstall remain. |
| P1-PKG native package lifecycle | **PARTIAL** | Exact-main unsigned package artifact builds in CI. Native clean install, upgrade, repair and uninstall remain unverified. |
| P1-DOCS | **COMPLETE for source documentation** | README, CLI, install, usage, security, accelerator and release-readiness docs are updated in English and Bengali. Production site deployment has not been run for this change. |
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
- `python3 tests/release_gates.py --self-test` and `--check`: pass; 19 gates derive `NOT_READY`, with the six blockers listed above.
- Bash syntax checks, `git diff --check`, and JSON parsing: pass.
- PR #139 head `53344d9a69a7f7a3019b10840a7495aaf56f548d`: Validate `42897454459`, unsigned package artifact `42897454586`, repo-contract `42897311193` and `42897454513`, Repo Knowledge Sync/test `42897454842`: all passed.
- Exact product head `eaf97fc514c045193e7ef5968a95d1b26c449f9c`: Validate `42897720583`, unsigned package artifact `42897720810`, Repository State Contract `42897720730`, Repo Knowledge Sync `42897720595`: all passed.
- Generated-state PR #140 head `e8754415c25fce38ab9bfd7011e990a5000b7fb8` passed Validate `42898005440`, unsigned package artifact `42898005215`, repo-contract `42898005314`, and Repo Knowledge Sync/test `42898005386`; merged as `3c03dffa4ba07a2c0355613560c0768b45022c96`.
- Local Astro build was unavailable: the Termux `node` binary fails to link `_ZNSt6__ndk113__hash_memoryEPKvm`. The exact-main Validate workflow passed, including its Ubuntu Astro site build. The running GUI and services were not restarted or modified.

## Device and release exclusions

The qualified device is Android 16 on Xiaomi 25053RT47C (Redmi Turbo 4 Pro, SM8735, Adreno 825). Earlier native verification reported Ternux 2.0.0 with X11 and PulseAudio active and desktop PID 16987. The currently installed `desktop.sh` differs from source, so that running session does not validate the updated launcher. The storage change has not been installed on-device; the legacy session still has the previous package's mounts until its process exits and a new session starts.

HTP/HMX and QNN remain experimental/research-only. They are excluded from stable v2 claims. CPU/Vulkan support claims must stay within the model/device evidence above. No v2 tag/release, signed APT publication, native package mutation, or production Pages deployment was made in this audit.

## Remaining release blockers

1. Install the exact current package on the supported Termux device and verify native install/upgrade/repair/uninstall.
2. On that package, verify storage is absent by default, an exact granted folder is visible, revocation takes effect on the next session, and Termux HOME stays hidden; run GUI lifecycle/app smoke without touching unrelated processes.
3. Complete native v1.4.0-to-v2 migration and rollback verification.
4. Resolve the CPU/Vulkan support boundary with a sustained representative model run and model-specific correctness claims; do not label failing Qwen tasks as passed.
5. Publish the signed APT repository only after the release candidate is qualified; verify all public paths, signatures and package hashes, then run clean `pkg install`, upgrade and uninstall.
6. Re-run all required CI on the final intended release commit and update this report. HTP/HMX and QNN remain excluded unless separately qualified.

## Final recommendation

**NOT_READY.** Core source regressions and CI fixes are integrated, but six release-blocking gates remain incomplete. Do not tag or publish v2.0.0 until the device/package gates close, the APT route is verified, and final exact-commit checks pass.
