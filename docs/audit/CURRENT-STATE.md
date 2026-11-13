# Ternux current-state audit

**Audit snapshot:** 2026-11-13, 11:04 UTC
**Repository:** `soobujmiah/ternux`
**Main at snapshot:** `ed326b58d76b8abba05434eb516135b84d7d3858`
**Latest stable release:** `v2.0.0`, tag target `9106b04fc8627ae98b1d63c9912a28c8a4677441`

This is a dated audit, not a claim that the device or repository remains in this
state indefinitely. Source, release, installed package, device sessions, and
deployed website are reported as separate evidence layers.

## Product and release state

Ternux v2.0.0 is released. Debian, Ubuntu, and Alpine are its three supported
desktop profiles; the Redmi Turbo 4 Pro / Android 16 / SM8735 / Adreno 825 is the
only device represented by the physical-device evidence in this audit. Other
named guest recipes remain available in source but are not v2-qualified.

The public signed Termux APT channel resolves `ternux` 2.0.0. On the audited
device, `dpkg-query` reports package 2.0.0 installed and `apt-cache policy`
reports 2.0.0 as the stable repository candidate. The installed package is the
host CLI; guest provisioning is a separate `tx install` operation.

Release-time facts, artifact hashes, acceptance evidence, and the owner-approved
rollback boundary are recorded in the [release report](../release/V2-RELEASE-REPORT.md)
and the original [v2 release record](../V2-RELEASE-REPORT.md). The published
release tag remains pinned to its release commit even though `main` has advanced.

## Source, package, and website state

At the snapshot, `main` was `ed326b58d76b8abba05434eb516135b84d7d3858`. The
product source commit immediately before the generated-state-only merge was
`4b44e5a7799e8518f89edb910c6b7b79f938b6de`; it added the bilingual installation
paths and current v2/v3 status section to the website. The Pages deployment
[`43411586659`](https://github.com/soobujmiah/ternux/actions/runs/43411586659)
completed successfully for that source commit and preserved the signed stable
and RC APT trees. The current live pages expose curl, wget, and signed-APT
bootstrap commands, the Termux companion-app links, and the release/roadmap
status links. Generated PR #201 synchronized that product commit's machine
state. On state-merge main commit `ed326b5`, Validate run
[`43412683916`](https://github.com/soobujmiah/ternux/actions/runs/43412683916),
Termux APT artifact run
[`43412683743`](https://github.com/soobujmiah/ternux/actions/runs/43412683743),
and repository-state contract run
[`43412683675`](https://github.com/soobujmiah/ternux/actions/runs/43412683675)
passed.

The released 2.0.0 host package does **not** contain the newer source-side
`tx manager` JSON interface. On the device, `tx manager status --json` returns
`Unknown command: manager`. Running `bin/ternux manager status|guests|capabilities
--json` from the audited `main` checkout succeeds and reports three read-only
operations. Neither result is a running manager service: no Unix-socket service
or graphical Control Center is implemented.

## Device snapshot

The native Termux host is F-Droid Termux 0.119.0-beta.3 on Android 16, ARM64,
Xiaomi model `25053RT47C`. Termux:API, Termux:Boot, Termux:Styling, and
Termux:X11 are installed. Debian `:0`, Ubuntu `:1`, and Alpine `:2` were already
running with PIDs 18218, 14129, and 26946. Read-only `tx status` reported all
three lifecycle states `READY`, X11 active, and PulseAudio routes ready.
`tx verify` returned `passed` for all three and reported the Turnip payload
present. This presence/service check does not by itself prove current renderer
selection, Vulkan workload correctness, microphone capture, camera capture, or
visual GUI quality; those claims require their separate evidence.

No desktop, X11, PulseAudio, IBus, Termux, or Android process was restarted as
part of this snapshot. The detailed test boundaries are in
[device verification](DEVICE-VERIFICATION.md) and the
[feature matrix](FEATURE-MATRIX.md).

## v3 state

The product, system, component, Control Center, compute, AI runtime, Device
Bridge, workspace, security, API, UX, roadmap, and acceptance documents exist,
with four ADRs. The source includes three read-only native manager CLI
operations. The stable installed 2.0.0 package does not include those newer
source operations. The socket service, authorization/session runtime, GUI, and
guest lifecycle mutations remain designed or deferred, not implemented.

The next implementation milestone is the native read-only Unix-socket service
with private socket permissions, schema validation, explicit opt-in startup,
and device verification that does not disturb existing guest sessions.

## Audit index

- [Repository and release state](REPOSITORY-STATE.md)
- [Live device verification](DEVICE-VERIFICATION.md)
- [Feature/evidence matrix](FEATURE-MATRIX.md)
- [v2 release readiness](../V2-RELEASE-READINESS.md)
- [v2 acceptance inventory](../release-gates.json)
