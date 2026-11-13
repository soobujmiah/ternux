---
title: "Ternux v2.0.0 release readiness"
description: "Current acceptance gates and device evidence for the three supported Ternux v2 guest profiles."
lang: "en"
alt_url: "/bn/docs/V2-RELEASE-READINESS.html"
---

**Status: READY FOR GITHUB RELEASE**
**Audit date:** 2026-11-13
**Target:** Ternux 2.0.0
**Latest GitHub release:** v1.4.0. Ternux 2.0.0 is published in the signed stable APT repository; the GitHub tag and release remain to be created.

Ternux v2 desktop support is limited to **Debian, Ubuntu, and Alpine**. Other
named distro recipes remain in the CLI but are not v2-qualified. The machine
inventory in [`release-gates.json`](https://github.com/soobujmiah/ternux/blob/main/docs/release-gates.json) currently derives
`READY_FOR_OWNER_APPROVAL`; the owner has authorized the release. The signed RC
and stable repositories, website preservation, native Termux package lifecycle,
and three-profile browser CI passed. Stable APT publication is complete. The
remaining publication actions are the `v2.0.0` GitHub tag/release and the final
release report. Exact-main Validate run `43362104082` passed on
`faa5f0c4733e82fa0e82c88c6a2cd4531a1c3442`, including the three-profile browser
matrix and documentation suite.

## Current acceptance gates

| Gate | Status | What closes it |
|---|---|---|
| P1-03 updater safety | **COMPLETE** | Source/hash pinning, stage-before-replace, interrupted-update recovery, downgrade guard, concurrency and symlink fixtures pass; the v1.4.0 source fixture upgrades to v2. A published v2 rollback demonstration is not required. |
| P1-09 default browser | **COMPLETE** | Clean Debian Trixie, Ubuntu 24.04, and Alpine 3.24 Firefox X11 window checks passed in exact-main Validate run `43362104082` on `faa5f0c4733e82fa0e82c88c6a2cd4531a1c3442`; Ubuntu uses Mozilla ESR without Snap. |
| P1-APT signed Termux package | **COMPLETE** | Stable signed APT publication workflow `43362569559` succeeded on exact main `faa5f0c4733e82fa0e82c88c6a2cd4531a1c3442`. Public stable `InRelease` verifies against fingerprint `E5527F4D5B83037FF77B65AE5E894BBB81168B1D`; `Packages.xz` SHA-256 is `3bbab20f0119b3c038e14c9a49714e499325b0c7036a899c3304e67b3b39e137` and the indexed package SHA-256 is `4ef03210c71e3d5671671e9a49fc83f6aebf7cdb5e5a28cb32db61d49e85c89f`. Native `pkg update`, clean package uninstall/install, `dpkg --verify`, active-default and explicit `db`/`ub`/`alp` JSON verification passed. Evidence is in `release-gates.json` and `audit/REPOSITORY-STATE.md`. |

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
  the mapped visible application window; exact-main run `43362104082` passed
  on `faa5f0c4733e82fa0e82c88c6a2cd4531a1c3442`. This Termux host has no
  Docker executable, so the container matrix is established by CI, not claimed
  as a local pass.
- `bash tests/focused.sh`: the audit exposed a test-hygiene regression because
  its `py_compile` step wrote `__pycache__` into packaged assets; the test now
  directs bytecode to its temporary directory. The complete exact-main suite
  passed in `43362104082`.
- Stable publication run `43362569559` signed and deployed exact-main package
  `faa5f0c4733e82fa0e82c88c6a2cd4531a1c3442`. The public bootstrap, key,
  `InRelease`, and `Packages.xz` endpoints returned HTTP 200; `gpgv` verified the
  signature against `E5527F4D5B83037FF77B65AE5E894BBB81168B1D`. Stable index and
  package SHA-256 values are recorded above and in `release-gates.json`. Native
  Termux fetched the stable index, removed and freshly reinstalled `ternux`, and
  passed `dpkg --verify`, `ternux verify --json`, `ternux verify db --json`,
  `tx verify ub --json`, and `tx verify alp --json`. The three existing guests
  remained READY with their original PIDs. The GitHub tag/release is still
  pending.

## Release sequence

1. Exact-main Validate run `43362104082` on
   `faa5f0c4733e82fa0e82c88c6a2cd4531a1c3442` passed required CI and the
   clean three-profile browser matrix.
2. Merge the reviewed product changes, then allow the deterministic `.repo/`
   workflow to generate and validate its state update. Do not edit `.repo/`
   manually.
3. Signed `/apt-rc` and stable `/apt` publication, signature/index/checksum
   verification, native clean package install, per-guest `verify`, and exact-main
   CI have passed. The Debian, Ubuntu, and Alpine guests remain installed and
   running with their original PIDs.
4. Create the `v2.0.0` tag and GitHub release on the exact validated main commit,
   attach the verified Termux package and checksum, then publish the final
   release report. The stable APT workflow refuses publication if any blocking
   gate is incomplete.
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
