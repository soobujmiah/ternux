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
release actions, not open acceptance gates. Exact-main Validate run
`43359028809` passed on `db9fe4a70177641b1e1312d2db47462191daf582`, including
clean Debian/Ubuntu/Alpine Firefox qualification and the full documentation
suite.

## Current acceptance gates

| Gate | Status | What closes it |
|---|---|---|
| P1-03 updater safety | **COMPLETE** | Source/hash pinning, stage-before-replace, interrupted-update recovery, downgrade guard, concurrency and symlink fixtures pass; the v1.4.0 source fixture upgrades to v2. A published v2 rollback demonstration is not required. |
| P1-09 default browser | **COMPLETE** | Clean Debian Trixie, Ubuntu 24.04, and Alpine 3.24 Firefox X11 window checks passed in exact merged-main Validate run `43359028809` on `db9fe4a70177641b1e1312d2db47462191daf582`; Ubuntu uses Mozilla ESR without Snap. |
| P1-APT signed Termux package | **COMPLETE** | Latest signed RC tree and package hash verified after the verify-selector fix; Termux APT reinstalled the exact 2.0.0 candidate and active-default plus `db`/`ub`/`alp` JSON verification passed. The first Ternux APT version has no earlier candidate for a version-delta upgrade. Evidence is in `release-gates.json` and `audit/REPOSITORY-STATE.md`. |

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

On 2026-11-13, runtime D-Bus queries confirmed the GTK, icon, and XFWM themes,
`|HMC` titlebar controls, and active Ctrl+Space binding in every guest. The
assigned IBus helper switched to the other installed language and restored the
original engine. Temporary 1800×1900 X11 clients were constrained inside each
640×1386 display, then only those test clients were destroyed. This tests the
managed switch command, not a physical Android keyboard event.

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
  the mapped visible application window; exact merged-main run `43359028809`
  passed on `db9fe4a70177641b1e1312d2db47462191daf582`. This Termux host has no
  Docker executable, so the container matrix is established by CI, not claimed
  as a local pass.
- `bash tests/focused.sh`: the audit exposed a test-hygiene regression because
  its `py_compile` step wrote `__pycache__` into packaged assets; the test now
  directs bytecode to its temporary directory. The complete exact-main suite
  passed in `43359028809`.
- Signed RC publication run `43359599505` deployed the updated 2.0.0 package
  from exact main. The four public RC paths returned HTTP 200; the InRelease
  signature verified against fingerprint
  `E5527F4D5B83037FF77B65AE5E894BBB81168B1D`. The signed package index listed
  archive SHA-256 `f2862526cd5cfdd91bac163632e2c9e8600288926c4acb2b2c5dcffbca271be2`.
  Native `pkg update` and Termux APT reinstall succeeded; `ternux verify --json`
  and explicit `db`, `ub`, and `alp` checks passed. Stable `/apt` and the v2
  tag/release remain the final publication steps.

## Release sequence

1. Exact merged-main Validate run `43359028809` on
   `db9fe4a70177641b1e1312d2db47462191daf582` passed required CI and the
   clean three-profile browser matrix.
2. Merge the reviewed product changes, then allow the deterministic `.repo/`
   workflow to generate and validate its state update. Do not edit `.repo/`
   manually.
3. Signed `/apt-rc` publication, signature/index/checksum verification,
   native installation of the updated candidate package, per-guest `verify`,
   and exact-main CI have passed. The Debian, Ubuntu, and Alpine guests remain
   installed and running with their original PIDs.
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
