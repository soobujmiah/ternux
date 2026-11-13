# Ternux current-state audit

**Audit snapshot:** 2026-11-13, 12:26 UTC
**Repository:** `soobujmiah/ternux`
**Main at snapshot:** `13f966eb987fddcb720809d07dbbe89c78860fc9`
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

At the snapshot, `main` was `13f966eb987fddcb720809d07dbbe89c78860fc9`. The
product source commit immediately before the generated-state-only merge was
`1107f790e5b5368530b7218c41121d055cf39ccd`; it added bilingual installation
paths and current v2/v3 status to the website. Pages deployment
[`43421466805`](https://github.com/soobujmiah/ternux/actions/runs/43421466805)
completed successfully and preserved the signed stable and RC APT trees. The
current live pages expose curl, wget, signed-APT bootstrap commands, Termux
companion-app links, and release/roadmap status. Generated PR #203 synchronized
that source commit's machine state. On merge commit `13f966e`, exact-main
Validate run
[`43421436113`](https://github.com/soobujmiah/ternux/actions/runs/43421436113),
Termux APT artifact run
[`43421436061`](https://github.com/soobujmiah/ternux/actions/runs/43421436061),
and repository-state contract run
[`43421436003`](https://github.com/soobujmiah/ternux/actions/runs/43421436003)
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
with five ADRs. ADR-0005 reserves `:0` for the native Termux workspace and
assigns Debian/Ubuntu/Alpine `:1`/`:2`/`:3` for v3; current v2 sessions remain
on their existing displays until explicit migration. The source includes three read-only native manager CLI
operations. The stable installed 2.0.0 package does not include those newer
source operations. The socket service, authorization/session runtime, GUI, and
guest lifecycle mutations remain designed or deferred, not implemented.

A source audit also found two diagnostic defects now under correction: doctor can follow stale saved distro state instead of the active guest, and Ubuntu renderer/Vulkan detection can miss the isolated Mesa overlay when its optional library-path marker is absent. The fix is in the working branch and has focused regression coverage; it is not yet part of main or the installed package.

The next implementation milestone is the native read-only Unix-socket service
with private socket permissions, schema validation, explicit opt-in startup,
and device verification that does not disturb existing guest sessions.

## Audit index

- [Repository and release state](REPOSITORY-STATE.md)
- [Live device verification](DEVICE-VERIFICATION.md)
- [Feature/evidence matrix](FEATURE-MATRIX.md)
- [v2 release readiness](../V2-RELEASE-READINESS.md)
- [v2 acceptance inventory](../release-gates.json)
