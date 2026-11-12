---
title: "Ternux v2.0.0 release readiness"
description: "Current acceptance gates and device evidence for the three supported Ternux v2 guest profiles."
lang: "en"
alt_url: "/bn/docs/V2-RELEASE-READINESS.html"
---

**Status: NOT READY**
**Audit date:** 2026-11-13
**Target:** Ternux 2.0.0
**Latest stable release:** v1.4.0; v2.0.0 is not tagged or published.

Ternux v2 desktop support is limited to **Debian, Ubuntu, and Alpine**. Other
named distro recipes remain in the CLI but are not v2-qualified. The machine
inventory in [`release-gates.json`](https://github.com/soobujmiah/ternux/blob/main/docs/release-gates.json) currently derives
`NOT_READY` with two blocking gates: the exact-head browser CI matrix and public
signed Termux APT publication/lifecycle verification.

## Current acceptance gates

| Gate | Status | What closes it |
|---|---|---|
| P1-03 updater safety | **COMPLETE** | Source/hash pinning, stage-before-replace, interrupted-update recovery, downgrade guard, concurrency and symlink fixtures pass; the v1.4.0 source fixture upgrades to v2. A published v2 rollback demonstration is not required. Public package upgrade remains under P1-APT. |
| P1-09 default browser | **PARTIAL** | Clean Debian Trixie, Ubuntu 24.04, and Alpine 3.24 installs must each launch a visible Firefox X11 window on the exact proposed commit. Ubuntu uses Mozilla ESR without Snap. |
| P1-APT signed Termux package | **BLOCKED** | Publish the signed RC tree, verify hosted key/index/package hashes, then verify native `pkg` install, upgrade, and uninstall. Stable v2 publication follows only after the remaining gates pass. |

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
- `python3 tests/release_gates.py --check` and `--self-test`: valid inventory;
  `NOT_READY`, with P1-09 and P1-APT blocking.
- `bash tests/firefox_package_matrix.sh`: added to exact-head CI for Debian,
  Ubuntu, and Alpine. It starts a GTK Firefox window in Xvfb/Openbox and checks
  the mapped visible application window. This Termux host has no Docker executable, so
  the container matrix must be established by CI, not claimed as a local pass.
- `bash tests/focused.sh`: the audit exposed a test-hygiene regression because
  its `py_compile` step wrote `__pycache__` into packaged assets; the test now
  directs bytecode to its temporary directory. Re-run the complete suite on the
  exact candidate commit before release.
- Public `/apt` and `/apt-rc` endpoints previously returned 404. Publishing is
  still required; the signed repository build alone is not public installation
  evidence.

## Release sequence

1. Pass the complete exact-head CI suite, including the three-profile browser
   matrix, focused tests, docs/site build, package build, repository contracts,
   and generated-state checks.
2. Merge the reviewed product changes, then allow the deterministic `.repo/`
   workflow to generate and validate its state update. Do not edit `.repo/`
   manually.
3. Publish `/apt-rc`; verify the public bootstrap, key fingerprint, signed
   `InRelease`, package index, and package checksums. Test the native package
   lifecycle without deleting the owner's Debian, Ubuntu, or Alpine guests.
4. Recompute the machine gates against exact current evidence. Publish stable
   v2 only when every blocking gate is complete and readiness is
   `READY_FOR_OWNER_APPROVAL`. The stable APT workflow now runs this validator
   and refuses `publish-v2` while any blocking gate remains incomplete.
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
