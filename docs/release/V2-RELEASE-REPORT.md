---
title: "Ternux v2.0.0 release and current audit"
description: "The published v2.0.0 release record reconciled with current source, package, CI, website, and device evidence."
lang: "en"
alt_url: "/bn/docs/release/V2-RELEASE-REPORT.html"
---

**Release:** published 2026-11-13 05:31 UTC
**Tag target:** `9106b04fc8627ae98b1d63c9912a28c8a4677441`
**Current-state audit snapshot:** 2026-11-13 11:04 UTC
**Main at that snapshot:** `ed326b58d76b8abba05434eb516135b84d7d3858`

This report separates the immutable release from post-release source and device
state. It does not imply that later `main` code is present in the v2.0.0
package.

## Release outcome

Ternux v2.0.0 is the published stable Termux host CLI and Linux desktop release.
The supported v2 desktop guests are Debian, Ubuntu, and Alpine on ARM64 Android.
Debian has the deepest test record; Ubuntu and Alpine remain supported with a
narrower qualification record. Physical device evidence is limited to Xiaomi
Redmi Turbo 4 Pro (`25053RT47C`), Android 16, SM8735 / Adreno 825.

The release-time report at [`../V2-RELEASE-REPORT.md`](../V2-RELEASE-REPORT.md)
preserves the original publication record. The machine-readable release gates
are in the [repository gate inventory](https://github.com/soobujmiah/ternux/blob/main/docs/release-gates.json),
and the owner-approved scope is summarized in
[release readiness](../V2-RELEASE-READINESS.md).

## Release assets and package channel

- GitHub release: [Ternux v2.0.0](https://github.com/soobujmiah/ternux/releases/tag/v2.0.0)
- Tag target: `9106b04fc8627ae98b1d63c9912a28c8a4677441`
- Package: `ternux_2.0.0_all.deb`
- Package SHA-256: `4ef03210c71e3d5671671e9a49fc83f6aebf7cdb5e5a28cb32db61d49e85c89f`
- The attached `SHA256SUMS` covers the release package.
- Stable Termux APT primary-key fingerprint:
  `E5527F4D5B83037FF77B65AE5E894BBB81168B1D`
- Stable `Packages.xz` SHA-256:
  `3bbab20f0119b3c038e14c9a49714e499325b0c7036a899c3304e67b3b39e137`

The `.deb` installs the host CLI. A one-time signed repository bootstrap is
required before `pkg install ternux`; after package installation, `tx install`
provisions the selected guest profiles. See the [signed APT guide](../TERMUX-APT.md).
The stable repository remains separate from the opt-in RC channel.

## Release verification

- Exact release-main `Validate` run
  [`43372097795`](https://github.com/soobujmiah/ternux/actions/runs/43372097795),
  package-artifact run
  [`43372097797`](https://github.com/soobujmiah/ternux/actions/runs/43372097797),
  and repository-contract run
  [`43372097798`](https://github.com/soobujmiah/ternux/actions/runs/43372097798)
  passed on the release commit.
- Stable APT publication run
  [`43362569559`](https://github.com/soobujmiah/ternux/actions/runs/43362569559)
  published package 2.0.0 and its signed index.
- The clean Firefox package/runtime matrix passed for Debian, Ubuntu, and
  Alpine. It does not qualify the other twelve named distro recipes.
- The package lifecycle audit used the real Termux package manager, verified
  the package integrity and guest verification commands, and preserved the
  owner's existing guest roots and running sessions.
- The v2 policy does not require a published rollback demonstration from
  v1.4.0 to v2.0.0. The v1.4.0 release artifact remains available; future
  upgrades still require integrity, data-protection, and recovery evidence.

## Post-release repository and website snapshot

The source on `main` advanced after the v2 tag. The product commit
`4b44e5a7799e8518f89edb910c6b7b79f938b6de` updated the bilingual homepages with
curl, wget, and signed-APT setup commands, companion-app links, and a v2/v3
status panel. Its main `Validate` run
[`43411550433`](https://github.com/soobujmiah/ternux/actions/runs/43411550433),
package artifact run
[`43411550393`](https://github.com/soobujmiah/ternux/actions/runs/43411550393),
and Repo Knowledge Sync run
[`43411550426`](https://github.com/soobujmiah/ternux/actions/runs/43411550426)
passed. Generated-state PR #201 merged as `ed326b58d76b8abba05434eb516135b84d7d3858`.
That exact main commit passed Validate run
[`43412683916`](https://github.com/soobujmiah/ternux/actions/runs/43412683916),
Termux APT artifact run
[`43412683743`](https://github.com/soobujmiah/ternux/actions/runs/43412683743),
and repository-state contract run
[`43412683675`](https://github.com/soobujmiah/ternux/actions/runs/43412683675).

Pages deployment
[`43411586659`](https://github.com/soobujmiah/ternux/actions/runs/43411586659)
completed successfully for the updated website and preserved the stable and RC
signed APT repositories. Post-deploy checks found the curl, wget, and APT
copyable commands on both language homepages, and the APT bootstrap endpoint
returned HTTP 200. This deployment changed the website, not the v2.0.0 package.

## Reference-device snapshot

At 2026-11-13 10:49 UTC, the installed host package was `ternux 2.0.0` and the
stable APT candidate was also 2.0.0. The three existing desktop sessions were
READY: Debian `:0` / PID 18218, Ubuntu `:1` / PID 14129, Alpine `:2` / PID
26946. `tx verify` passed for each and reported the guest service checks and
Turnip payload as present.

Those commands verify lifecycle/service probes and driver presence. They do
not by themselves prove that a renderer was selected or a Vulkan workload
completed during this snapshot. Existing GUI sessions were not restarted, and
this snapshot did not rerun camera, microphone, audio playback, or visual
application checks. The [device report](../audit/DEVICE-VERIFICATION.md)
preserves earlier workload evidence and its limits.

The newer read-only manager JSON commands are present in `main` source and
passed source-side invocation. The installed v2.0.0 package returns
`Unknown command: manager`; it does not include that newer module. Neither
source nor package provides a running Unix-socket manager service or graphical
Control Center. See the [implementation status](../project/IMPLEMENTATION-STATUS.md).

## Known qualification limits

- IBus helper/configuration works, but Alpine synthetic Ctrl+Space probes
  conflict and physical Android keyboard delivery is unverified.
- Theme, window-fit, and Firefox titlebar checks cover observed GTK/XFCE and
  tested applications, not every toolkit or future third-party window.
- `tx verify` reporting Turnip present is not a substitute for current renderer,
  Vulkan correctness, or performance evidence.
- Direct `/dev/video*` webcam streaming is not implemented; Ternux Camera uses
  on-demand Termux:API still capture.
- HTP/HMX and QNN remain experimental/research-only. Stable Diffusion CPU/Vulkan
  remains a preview extension. None is promoted to stable base functionality.
- The other twelve distro recipes and other Android devices are not v2-qualified.

## Evidence index

- [Current-state audit](../audit/CURRENT-STATE.md)
- [Repository-state audit](../audit/REPOSITORY-STATE.md)
- [Device-verification record](../audit/DEVICE-VERIFICATION.md)
- [Feature matrix](../audit/FEATURE-MATRIX.md)
- [Current project roadmap](../project/PROJECT-ROADMAP.md)
- [Historical v2 release-readiness report](../V2-RELEASE-READINESS.md)
