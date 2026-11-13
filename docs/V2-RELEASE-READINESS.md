---
title: "Ternux v2.0.0 release readiness"
description: "Current acceptance gates and device evidence for the three supported Ternux v2 guest profiles."
lang: "en"
alt_url: "/bn/docs/V2-RELEASE-READINESS.html"
---

**Status: READY FOR STABLE PUBLICATION**
**Audit date:** 2026-11-13
**Target:** Ternux 2.0.0
**Latest stable release:** v1.4.0; v2.0.0 stable APT publication and GitHub release are in progress.

Ternux v2 desktop support is limited to **Debian, Ubuntu, and Alpine**. Other
named distro recipes remain in the CLI but are not v2-qualified. The machine
inventory in [`release-gates.json`](https://github.com/soobujmiah/ternux/blob/main/docs/release-gates.json) currently derives
`READY_FOR_OWNER_APPROVAL`; the owner has authorized the release. The signed RC
repository, website preservation, and native Termux install/remove/reinstall
checks passed. Stable `/apt` publication and the v2 tag/release are the remaining
release actions, not open acceptance gates. The exact current main Validate run
`43311661213` passed on `ca0bba9093ecbe838df4b09f09dfee3197814845`; the
three-profile browser gate passed in run `43307868038`.

## Current acceptance gates

| Gate | Status | What closes it |
|---|---|---|
| P1-03 updater safety | **COMPLETE** | Source/hash pinning, stage-before-replace, interrupted-update recovery, downgrade guard, concurrency and symlink fixtures pass; the v1.4.0 source fixture upgrades to v2. A published v2 rollback demonstration is not required. |
| P1-09 default browser | **COMPLETE** | Clean Debian Trixie, Ubuntu 24.04, and Alpine 3.24 Firefox X11 window checks passed in exact merged-main Validate run `43307868038` on `f963832fb4acf9c3adb873430408ce21ddd29a37`; Ubuntu uses Mozilla ESR without Snap. |
| P1-APT signed Termux package | **COMPLETE** | Signed RC public tree verified before and after a regular Pages redeploy; native Termux clean install, repository replacement, removal, and no-op upgrade resolution passed. v2.0.0 is the first published package version, so no older APT package exists for a version-delta upgrade. Evidence is in `release-gates.json` and `audit/REPOSITORY-STATE.md`. |

HTP/HMX and QNN remain experimental or research-only and are excluded from
stable v2 promises. CPU/Vulkan claims are limited to the named model, task, and
SM8735/Adreno 825 evidence in the accelerator plan. Other guest recipes and
other Android GPU families are not covered by these v2 gates.

## Device evidence

The reference device is Xiaomi 25053RT47C (Redmi Turbo 4 Pro), Android 16,
ARM64, SM8735 / Adreno 825. Existing Debian `:0`, Ubuntu `:1`, and Alpine `:2`
sessions were observed READY with Termux:X11 and PulseAudio routes. The sessions
were left running. Live Firefox titlebars showed visible close controls, and a
synthetic XTest Ctrl+Space switched the configured Bengali input engines in all
three guests. Synthetic key input does not prove physical keyboard behavior.

The window-fit helper now translates client coordinates in the correct
direction, reads EWMH `_NET_CLIENT_LIST` as WINDOW IDs, clamps a stale work area
to current screen dimensions, and retains valid maximized geometry. Its source
and installed helper hashes match across all three guests. Ubuntu's already-open
XFCE About window was moved into its phone viewport without closing it or
restarting the desktop. Full detail and test limitations are in the
[current-state audit](audit/CURRENT-STATE.md) and [device verification](audit/DEVICE-VERIFICATION.md).

Prior device evidence records Turnip/Vulkan-backed Zink on all three profiles
for this device. A renderer probe using the wrong display number for Ubuntu and
Alpine was discarded; it is not used as contrary or qualifying evidence.
Qualification does not extend to other GPUs or devices.

## Verification snapshot

- `bash tests/update_transaction.sh`: passed the pinned update, migration,
  interrupted-update, recovery, rollback-fixture, concurrency, and symlink
  checks during this audit.
- `python3 tests/release_gates.py --check --self-test`: valid 20-gate inventory;
  all blocking gates complete; recorded owner authorization is accepted only
  after the gate inventory is ready.
- `bash tests/firefox_package_matrix.sh`: added to exact-head CI for Debian,
  Ubuntu, and Alpine. It starts Firefox in Xvfb/Openbox and checks
  the mapped visible application window; exact merged-main run `43307868038`
  passed. This Termux host has no Docker executable, so the container matrix is
  established by CI, not claimed as a local pass.
- `bash tests/focused.sh`: the audit exposed a test-hygiene regression because
  its `py_compile` step wrote `__pycache__` into packaged assets; the test now
  directs bytecode to its temporary directory. The complete suite passed on
  exact main in run `43311661213`.
- Signed `/apt-rc` paths returned HTTP 200 and the InRelease signature verified
  after candidate publication and routine website redeploy. Native Termux fetched
  and installed the indexed package. Stable `/apt` and the v2 tag/release remain
  the final publication steps.

## Release sequence

1. Exact merged-main Validate run `43311661213` on
   `ca0bba9093ecbe838df4b09f09dfee3197814845` passed the required CI; the
   three-profile browser matrix passed earlier in Validate run `43307868038`.
2. Merge the reviewed product changes, then allow the deterministic `.repo/`
   workflow to generate and validate its state update. Do not edit `.repo/`
   manually.
3. Signed `/apt-rc` publication, signature/index/checksum verification, a
   routine website redeploy, native Termux package lifecycle, and exact-main CI
   have all passed. The Debian, Ubuntu, and Alpine guests remain installed and
   running.
4. Publish stable `/apt`, switch the native bootstrap source to stable, verify
   its signature and index, then create the `v2.0.0` tag and GitHub release. The
   stable APT workflow refuses publication if any blocking gate is incomplete.
5. After v2 closes, publish and review the full v3 architecture and acceptance
   plan. The v3 system design is not a v2 deliverable.

## Detailed audit records

- [Current state and decisions](audit/CURRENT-STATE.md)
- [Live-device verification](audit/DEVICE-VERIFICATION.md)
- [Repository and publication state](audit/REPOSITORY-STATE.md)
- [Feature support matrix](audit/FEATURE-MATRIX.md)
- [Machine-readable gate inventory](https://github.com/soobujmiah/ternux/blob/main/docs/release-gates.json)

Do not report v2 as released until the stable tag, GitHub release, signed APT
URLs, and exact release commit all exist and are verified.
