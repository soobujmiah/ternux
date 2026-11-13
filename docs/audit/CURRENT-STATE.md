# Ternux current-state audit

**Audit snapshot:** 2026-11-13, 16:11 UTC
**Repository:** `soobujmiah/ternux`
**Main at snapshot:** `9a35bac2e9d47e5699de8bead4029c95bb16a0cf` (generated-state PR #211)
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

At the snapshot, remote `main` was
`9a35bac2e9d47e5699de8bead4029c95bb16a0cf`, after PR #210 merged the v3
display defaults, startup collision guards, read-only display reporting,
schemas, docs and tests. PR #211 then merged the deterministic generated state
for product commit `7b7ea438b96ef11debfa3555852a6619b51be4d8`; its workflow
created all `.repo/` files, none were hand-edited. The feature commit's PR
checks and exact-main workflows passed. Post-generated-state Validate, APT
artifact, and repository-state workflows also passed for `9a35bac` (runs
`43457455444`, `43457455294`, and `43457455258`). The production website deploy
for product commit `7b7ea43` succeeded (run `43456239621`).

The released 2.0.0 host package does **not** contain the newer source-side
`tx manager` JSON interface. On the device, the installed `tx manager`
continues to return `Unknown command: manager`. Current `main` has four
read-only manager operations, including `tx manager displays`, and the explicit
foreground Unix-socket service. These are source-only features; the graphical
Control Center and service supervisor are not implemented.

## Device snapshot

The native Termux host is F-Droid Termux 0.119.0-beta.3 on Android 16, ARM64,
Xiaomi model `25053RT47C`. Termux:API, Termux:Boot, Termux:Styling, and
Termux:X11 are installed. Debian `:0`, Ubuntu `:1`, and Alpine `:2` were already
running with PIDs 18218, 14129, and 26946. Read-only `tx status` reported all
three lifecycle states `READY`, X11 active, and PulseAudio routes ready.
`tx verify` returned `passed` for all three and reported the Turnip payload
present. A new read-only status check at 15:52 UTC confirmed the same three
PIDs, READY state, X11 and PulseAudio route readiness. This presence/service
check does not by itself prove current renderer
selection, Vulkan workload correctness, microphone capture, camera capture, or
visual GUI quality; those claims require their separate evidence.

No desktop, X11, PulseAudio, IBus, Termux, or Android process was restarted as
part of this snapshot. The detailed test boundaries are in
[device verification](DEVICE-VERIFICATION.md) and the
[feature matrix](FEATURE-MATRIX.md).

## v3 state

The product, system, component, Control Center, compute, AI runtime, Device
Bridge, workspace, security, API, UX, roadmap, and acceptance documents exist,
with five ADRs. ADR-0005 reserves `:0` for the native Termux workspace and
assigns Debian/Ubuntu/Alpine `:1`/`:2`/`:3` for v3; current v2 sessions remain
on their existing displays until explicit migration. Current main includes four
read-only native manager CLI operations. The stable installed 2.0.0 package
does not include them. An on-device source invocation at 15:56 UTC from current
`main` again observed native display `:0` occupied and all three managed
desktops still running on their saved v2 displays (Debian `:0`, Ubuntu `:1`,
Alpine `:2`). It reported migration required for Debian/Ubuntu, without
changing any state. The explicit
socket service is implemented and verified from source; authorization/session
runtime, GUI, supervisor integration, central display ownership, staged
migration, and guest lifecycle mutations remain open.

The doctor active-guest selection and Ubuntu Mesa-overlay detection fixes
merged in PR #204 and are in main; the installed stable package remains v2.0.0
and does not contain them. The socket transport was exercised on-device at
13:39 UTC and in six integration tests; no existing guest session was
restarted. See the device verification record for the exact scope.

The next implementation milestone is the native Control Center client and
service lifecycle, preserving v2 guest displays until staged migration.

## Audit index

- [Repository and release state](REPOSITORY-STATE.md)
- [Live device verification](DEVICE-VERIFICATION.md)
- [Feature/evidence matrix](FEATURE-MATRIX.md)
- [v2 release readiness](../V2-RELEASE-READINESS.md)
- [v2 acceptance inventory](../release-gates.json)
