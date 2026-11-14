---
title: "Ternux v2.0.0 release report"
description: "Release record, validated commit, package hashes, supported guests, and device qualification limits for Ternux v2.0.0."
lang: "en"
alt_url: "/bn/docs/V2-RELEASE-REPORT.html"
---

**Current distribution status (2026-11-14):** The v2.0.0 GitHub release was
removed, its tag is retained for provenance, and the stable APT channel was
withdrawn by Pages run [43532161200](https://github.com/soobujmiah/ternux/actions/runs/43532161200).
Stable `/apt` paths return HTTP 404; signed RC paths remain HTTP 200 for
opt-in candidate tests. This file records the original publication; its install
commands are historical and no longer install the stable package.

**Status:** Released 2026-11-13 05:31 UTC
**GitHub release:** [v2.0.0](https://github.com/soobujmiah/ternux/tree/v2.0.0)
**Release tag target:** `9106b04fc8627ae98b1d63c9912a28c8a4677441`
**Supported desktop guests:** Debian, Ubuntu, Alpine

Ternux 2.0.0 is the stable Termux desktop release. The release adds signed
stable APT distribution for the host CLI and documents the supported Debian,
Ubuntu, and Alpine desktop profiles. The attached Termux package installs the
host CLI; `tx install` provisions a selected guest desktop.

## Release assets and installation

The GitHub release attaches the stable package also published in the signed
APT repository:

- `ternux_2.0.0_all.deb` — SHA-256
  `4ef03210c71e3d5671671e9a49fc83f6aebf7cdb5e5a28cb32db61d49e85c89f`
- `SHA256SUMS` — checksum manifest for the package.

To use `pkg install ternux`, first bootstrap the signed stable repository once:

```sh
pkg install curl gnupg
curl -fsSLo "$TMPDIR/ternux-bootstrap.sh" \
  https://soobujmiah.github.io/ternux/apt/bootstrap.sh
bash "$TMPDIR/ternux-bootstrap.sh"
tx install
```

The [Termux APT guide](TERMUX-APT.md) covers updates, key verification, and the
separate opt-in release-candidate channel.

## Release verification

- Tag `v2.0.0` points directly to validated main commit
  `9106b04fc8627ae98b1d63c9912a28c8a4677441`.
- Exact-main Validate run [`43372097795`](https://github.com/soobujmiah/ternux/actions/runs/43372097795), package artifact run
  [`43372097797`](https://github.com/soobujmiah/ternux/actions/runs/43372097797), and repository contract run
  [`43372097798`](https://github.com/soobujmiah/ternux/actions/runs/43372097798) passed on the release commit.
- Stable APT publish run [`43362569559`](https://github.com/soobujmiah/ternux/actions/runs/43362569559) published package version 2.0.0. The signed `InRelease` validates against primary key fingerprint `E5527F4D5B83037FF77B65AE5E894BBB81168B1D`. `Packages.xz` SHA-256 is `3bbab20f0119b3c038e14c9a49714e499325b0c7036a899c3304e67b3b39e137`.
- Routine website deploy [`43371001392`](https://github.com/soobujmiah/ternux/actions/runs/43371001392), after the stable repository was published, verified and preserved both the stable and RC signed APT trees and their indexed package records before deploying the website.
- Native Termux downloaded the published package; its hash matched the signed APT index and attached release checksum. Clean `pkg uninstall`/`pkg install`, `dpkg --verify ternux`, `ternux verify`, and Debian/Ubuntu/Alpine guest-specific verification passed.

## Supported scope

The v2 desktop support statement is limited to Debian, Ubuntu, and Alpine on
ARM64 Android/Termux. Device qualification was performed on Xiaomi Redmi Turbo
4 Pro, Android 16, SM8735 / Adreno 825. CI exercises clean guest lifecycle,
Firefox windows, release gates, installer behavior, and the documentation
build. The device record covers the three existing display sessions, GPU
route, audio route, theme, titlebar, viewport fitting, and input configuration.

Other named PRoot recipes are not v2-qualified. HTP/HMX and QNN image-generation
paths remain experimental or research-only. Results from this one device do
not qualify other Android or GPU families.

## Known input and UI qualification limits

The live Debian `:0`, Ubuntu `:1`, and Alpine `:2` sessions remained READY with
their original managed PIDs. Runtime queries confirmed the Ternux GTK, icon,
and XFWM themes, `|HMC` titlebar controls, and Ctrl+Space helper binding in
all three guests. Direct calls to the IBus helper switched the configured
engines in every guest.

Keyboard-event probes were inconsistent for Alpine: an earlier focused
GTK/XTest probe switched engines, but a later host-generated Ctrl+Space event
and a temporary GTK entry probe did not. Debian and Ubuntu changed engines in
the later probe. The configuration remains set to Ctrl+Space; physical Android
keyboard delivery has not been certified. This limitation is recorded rather
than treated as a successful input test. GTK/XFCE and tested Firefox windows
were checked; arbitrary future toolkits and third-party applications are not
universally certified.

## Evidence links

- [v2 release readiness and acceptance record](V2-RELEASE-READINESS.md)
- [Live device verification](audit/DEVICE-VERIFICATION.md)
- [Feature and qualification matrix](audit/FEATURE-MATRIX.md)
- [Repository, APT, and package state](audit/REPOSITORY-STATE.md)
- [Machine-readable release gates](https://github.com/soobujmiah/ternux/blob/main/docs/release-gates.json)
