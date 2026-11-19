---
title: "Ternux implementation status"
description: "Current implementation state by product area, separated from proposals and test evidence."
lang: "en"
alt_url: "/bn/docs/project/IMPLEMENTATION-STATUS.html"
---

## Implementation status

**Repository baseline:** 2026-11-19; owner scope reset: 2026-11-18. Version 2 is
frozen to current implementation. v2.0.1 is the published source release;
complete v3 architecture stays future work. This page reports repository and
device state and does not upgrade a design status into an implementation claim.

| Area | State | Evidence / next gate |
|---|---|---|
| Ternux v2 release | v2.0.0 WITHDRAWN; v2.0.1 PUBLISHED SOURCE RELEASE | v2.0.0 tag retained for provenance; GitHub Release object removed and stable APT withdrawn. The v2.0.1 source archive and checksum are verified; see [release status](RELEASE-STATUS.md) |
| Debian / Ubuntu / Kali / Alpine desktop profiles | Owner-confirmed v2 verified baseline; evidence depth differs | Debian, Ubuntu and Alpine clean guest/browser CI evidence; Kali installed reference-device desktop evidence. Kali clean-container install and Firefox CI are not in the current matrix. See [device verification](../audit/DEVICE-VERIFICATION.md) and [feature matrix](../audit/FEATURE-MATRIX.md) |
| Ternux GTK/icon/XFWM defaults | IMPLEMENTED and observed active in all three live guests | Runtime XFConf queries returned Ternux/Ternux/Ternux and `|HMC`; broad third-party CSD coverage is not claimed |
| Window viewport helper | Position-retention helper source and deployed helper hashes match in Debian, Ubuntu, Kali, and Alpine; released in v2.0.1 | Interactive move/resize was directly tested on Debian/XFCE. Hash equality confirms identical helper bytes in all four guests, not interactive resize qualification in the other three. See [device audit](../audit/DEVICE-VERIFICATION.md) |
| IBus engine switch command | IMPLEMENTED | Direct helper cycles each guest's configured engine and restores original; physical Ctrl+Space delivery remains separately qualified |
| Installer onboarding and terminal UI | IMPLEMENTED in current main source | Multi-guest setup precollects shared shell, usernames, and workload choices before installation; each guest has an explicit final start/shell command. Historical renderer suite: 56/56; current local focused suite: 212/212. Package bootstrap tests cover broken-curl wget fallback. PR #235 and generated-state PR #236 merged; exact-main Validate, package, and repository-contract checks passed for those recorded revisions. |
| Native Control Center preview | PARTIAL in current source; included in the proposed v2.0.1 source baseline | `tx control` uses loopback access, confirmation-bound desktop start/stop and durable job records. Backend integration checks cover typed requests, idempotency, stale-plan rejection and restart reconciliation. Device-browser actions, service supervisor, cancellation, native APK, logs, diagnostics and full panels are incomplete. This is a preview, not a complete v3 Control Center |
| Native manager read-only CLI payloads | IMPLEMENTED in this source revision; display snapshot verified on-device | `TERNUX_LIB_DIR="$PWD/lib" bash ./bin/ternux manager ... --json` returned status/guest/capability and current/target display payloads on this device. Display schema 1.3.0 reports a state-bound migration preview and explicit journaled apply path and a unique running guest's saved display assignment, or labels ownership unresolved/reserved; it does not prove OS-level socket ownership. The released stable APT package remains 2.0.0 and `tx manager` there returns `Unknown command: manager`; source verification does not imply package delivery |
| Native manager API service / Control Center | PARTIAL; read-only Unix socket and loopback dashboard with start/stop job adapter in working source | `tests/manager_service.py` covers Unix-socket peer UID and malformed requests; `tests/control_center.py` covers bearer expiry, Host/Origin, CSP, read-only snapshots, typed lifecycle routes, idempotency, display migration guards, concurrent confirmation, singleton service ownership, state verification, retention, and interrupted-job recovery (20/20 on the working branch). Service supervisor, cancel/retry UI, native Android client, and full dashboard panels remain open |
| Display allocation and migration | Current source includes a state-bound planner/executor; one live migration/restart verified | Schema 1.3.0 plan revalidates under an exclusive lock; active guests and unsafe targets block execution, with journaled rollback/recovery. Reference-device migration evidence is one device, not the full clean lifecycle matrix. Owner classification is best-effort, not OS-level socket-owner proof |
| Compute/AI orchestration | Future v3 design; current optional artifacts remain separate | No platform-wide runtime qualification claim |
| Camera/microphone Device Bridge | Future v3 design; no broker implementation | Termux:API app behavior and current camera/microphone apps remain separately bounded |
| Distro-profile framework | Current source implements 15 named recipes and multi-guest precollection | Only the four owner-confirmed v2 baseline distros are included in the support claim; clean lifecycle evidence depth differs per distro |

The stale-distro doctor selection, Ubuntu Mesa-overlay detection, guest-state
resume reset, managed uninstall cleanup, Alpine AppStream PRoot-hook fixes, and
journaled display migration are covered by focused tests and exact-main CI from
their recorded dates. Candidate test results and release-build status are
recorded in [device verification](../audit/DEVICE-VERIFICATION.md). The current
installed package remains v2.0.0; the v2.0.1 source release has
built or published.

## Local v2.0.1 candidate follow-up — 2026-11-19

Fresh Ubuntu Resolute, Kali rolling, and Alpine v3.24 guests reached READY on
the reference Termux host. Their PulseAudio routes resolved the shared host
server and each played an owner-confirmed two-second test tone. The local
Termux:API detector falls back to Termux `pm path` when Android `cmd` cannot
confirm the package; the installed host module matches this source and detects
the already-installed app. Camera and microphone permission/capture checks
remain untested. Full focused tests pass 212/212; the immutable bootstrap
source-sync check remains open because its older pinned snapshot does not
include the local source correction. See the [release reconciliation](../release/V2-RELEASE-RECONCILIATION.md)
and [device record](../audit/DEVICE-VERIFICATION.md).

## Active limitations

- Physical Android keyboard delivery of Ctrl+Space is not established by a
  config query or direct helper invocation. Earlier synthetic probes conflict.
- Current candidate physical-device evidence is limited to the named Redmi
  Turbo 4 Pro / Android 16 / Adreno 825 device. Do not generalize to other
  devices, GPUs, or unlisted guest recipes.
- The withdrawn v2.0.0 package and current `main` source are different
  artifacts. Source changes belong to the v2.0.1 source release after
  its final commit passes verification and is published.
- The manager socket service runs only when explicitly started from source and
  has no background supervisor. `tx control` is a separate browser dashboard
  with confirmed desktop actions in working source; neither feature is in the
  withdrawn v2.0.0 package. The candidate source includes this partial preview;
  remaining service, UI, Device Bridge and platform orchestration work is v3.
  See [next actions](NEXT-ACTIONS.md) for the release gate and future work.
