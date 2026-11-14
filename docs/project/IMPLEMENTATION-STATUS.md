---
title: "Ternux implementation status"
description: "Current implementation state by product area, separated from proposals and test evidence."
lang: "en"
---

## Implementation status

**Repository baseline:** 2026-11-13 16:55 UTC; owner release-direction update: 2026-11-14. This page reports repository and device state;
it does not upgrade a design status into an implementation claim.

| Area | State | Evidence / next gate |
|---|---|---|
| v2 Termux manager and distro CLI | 2.0.0 WITHDRAWN FROM DISTRIBUTION | Git tag retained for provenance; GitHub Release object removed and stable APT withdrawn; see [release status](RELEASE-STATUS.md) |
| Debian / Ubuntu / Alpine desktop profiles | Recipes implemented; qualification is mixed on reference device | Debian host `tx verify` passes; Ubuntu managed install/start/stop passed on 2026-11-14 but window input was not tested; Alpine install stopped on repeated WebKit extraction I/O errors and is not qualified. See [device verification](DEVICE-VERIFICATION.md) |
| Ternux GTK/icon/XFWM defaults | IMPLEMENTED and observed active in all three live guests | Runtime XFConf queries returned Ternux/Ternux/Ternux and `|HMC`; broad third-party CSD coverage is not claimed |
| Window viewport helper | IMPLEMENTED and deployed in all three guests | Identical SHA-256 `a990edf3a929eb1633e70ad86d4d2044f841677531e770fdff953cc81aed4017`; prior oversized-window evidence is linked in device audit |
| IBus engine switch command | IMPLEMENTED | Direct helper cycles each guest's configured engine and restores original; physical Ctrl+Space delivery remains separately qualified |
| Native Control Center (required next v2 scope) | PARTIAL; read-only Unix-socket service implemented, GUI not implemented | Explicit `tx manager serve`; not present in withdrawn 2.0.0 package |
| Native manager read-only CLI payloads | IMPLEMENTED in this source revision; display snapshot verified on-device | `TERNUX_LIB_DIR="$PWD/lib" bash ./bin/ternux manager ... --json` returned status/guest/capability and current/target display payloads on this device. Display schema 1.1.0 reports a unique running guest's saved display assignment, or labels ownership unresolved/reserved; it does not prove OS-level socket ownership. The released stable APT package remains 2.0.0 and `tx manager` there returns `Unknown command: manager`; source verification does not imply package delivery |
| Native manager API service / Control Center | PARTIAL; read-only Unix socket implemented and integration-tested on this Termux runtime | `python3 tests/manager_service.py` exercises the private socket, peer UID, malformed/oversized requests, concurrency, shutdown, and stale recovery; HTTP adapter, session authorization, supervisor, and graphical client remain open |
| Display allocation and migration (required next v2 scope) | PARTIAL in this source revision | New profiles default to native reservation `:0`, Debian `:1`, Ubuntu `:2`, Alpine `:3`, and stable serial slots for the other 12 recipes. Start refuses occupied socket/lock/server paths; `tx manager displays` reports current/target assignments and best-known owner classification. Live v2 `:0/:1/:2` values remain saved and unmigrated. Persistent registry identity/state, native workspace, and staged migration remain open; see [next actions](NEXT-ACTIONS.md) |
| Compute/AI orchestration (required next v2 scope) | DESIGNED; existing optional artifacts remain separate | No platform-wide runtime qualification claim |
| Camera/microphone Device Bridge (required next v2 scope) | DESIGNED; no broker implementation | Existing limitations remain in the audit docs |
| Distro-profile framework (required next v2 scope) | DESIGNED; not implemented | Debian/Ubuntu/Alpine behavior remains the compatibility baseline |

The stale-distro doctor selection and Ubuntu Mesa-overlay detection fixes
merged to `main` as `b26010d17694b4b18ebc757d1001dc48f3d9ab6a`. Exact-main
hosted validation passed, the focused suite passed 185/185, and source-only
on-device `doctor --quick --json` returned status `ok` for both default active
Debian and explicit Ubuntu selections. The installed stable v2.0.0 package
remains unchanged and does not yet contain these fixes.

## Active limitations

- Physical Android keyboard delivery of Ctrl+Space is not established by a
  config query or direct helper invocation. Earlier synthetic probes conflict.
- v2 qualification is for the named Android/Adreno reference device and the
  stated three guests; do not generalize to other devices or distros.
- The withdrawn 2.0.0 package and current `main` source are different artifacts.
  Read-only manager commands exist in `main` but are not present in the
  historical package. The next stable release remains in the v2 major and must
  meet the complete platform acceptance criteria.
- The current v3 service runs only when started explicitly from source. It is
  not present in the released 2.0.0 package and has no background supervisor.
  See [next actions](NEXT-ACTIONS.md) for the UI and host-service milestones.
