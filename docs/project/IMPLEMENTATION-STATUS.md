---
title: "Ternux implementation status"
description: "Current implementation state by product area, separated from proposals and test evidence."
lang: "en"
---

## Implementation status

**Repository baseline:** 2026-11-14; owner release-direction update: 2026-11-14. This page reports repository and device state;
it does not upgrade a design status into an implementation claim.

| Area | State | Evidence / next gate |
|---|---|---|
| v2 Termux manager and distro CLI | 2.0.0 WITHDRAWN FROM DISTRIBUTION | Git tag retained for provenance; GitHub Release object removed and stable APT withdrawn; see [release status](RELEASE-STATUS.md) |
| Debian / Ubuntu / Alpine desktop profiles | Recipes implemented; reference-device install, graphics, and synthetic window input passed | Debian retained and verified; Ubuntu and Alpine freshly installed through managed commands, verified with Zink/Turnip, and passed xdotool terminal input. Ubuntu stop/start and >10-minute soak passed. See latest [device verification](DEVICE-VERIFICATION.md) section; physical Android keyboard delivery and other devices remain unqualified |
| Ternux GTK/icon/XFWM defaults | IMPLEMENTED and observed active in all three live guests | Runtime XFConf queries returned Ternux/Ternux/Ternux and `|HMC`; broad third-party CSD coverage is not claimed |
| Window viewport helper | IMPLEMENTED and deployed in all three guests | Identical SHA-256 `a990edf3a929eb1633e70ad86d4d2044f841677531e770fdff953cc81aed4017`; prior oversized-window evidence is linked in device audit |
| IBus engine switch command | IMPLEMENTED | Direct helper cycles each guest's configured engine and restores original; physical Ctrl+Space delivery remains separately qualified |
| Native Control Center (required next v2 scope) | PARTIAL; responsive, read-only local browser dashboard implemented in source | `tx control` shows manager/guest/display state on a random loopback port with a one-hour in-memory token and strict Host/Origin checks. No mutations, native APK, supervisor, jobs, or graphics/audio/storage/workload panels. Python 3 optional; not in withdrawn 2.0.0 package |
| Native manager read-only CLI payloads | IMPLEMENTED in this source revision; display snapshot verified on-device | `TERNUX_LIB_DIR="$PWD/lib" bash ./bin/ternux manager ... --json` returned status/guest/capability and current/target display payloads on this device. Display schema 1.2.0 reports a unique running guest's saved display assignment, or labels ownership unresolved/reserved; it does not prove OS-level socket ownership. The released stable APT package remains 2.0.0 and `tx manager` there returns `Unknown command: manager`; source verification does not imply package delivery |
| Native manager API service / Control Center | PARTIAL; read-only Unix socket and loopback dashboard implemented in source | `tests/manager_service.py` covers Unix-socket peer UID and malformed requests; `tests/control_center.py` covers bearer expiry, Host/Origin, CSP, read-only routes and CLI snapshots. Service supervisor, durable jobs, mutations, native Android client, and full dashboard panels remain open |
| Display allocation and migration (required next v2 scope) | PARTIAL on the merged main source | New profiles default to native reservation `:0`, Debian `:1`, Ubuntu `:2`, Alpine `:3`, and stable serial slots for the other 12 recipes. Start refuses occupied socket/lock/server paths; `tx manager displays` reports current/target assignments and best-known owner classification. Live v2 `:0/:1/:2` values remain saved and unmigrated. Persistent registry identity/state, native workspace, and staged migration remain open; see [next actions](NEXT-ACTIONS.md) |
| Compute/AI orchestration (required next v2 scope) | DESIGNED; existing optional artifacts remain separate | No platform-wide runtime qualification claim |
| Camera/microphone Device Bridge (required next v2 scope) | DESIGNED; no broker implementation | Existing limitations remain in the audit docs |
| Distro-profile framework (required next v2 scope) | DESIGNED; not implemented | Debian/Ubuntu/Alpine behavior remains the compatibility baseline |

The stale-distro doctor selection, Ubuntu Mesa-overlay detection, guest-state resume reset, managed uninstall cleanup, and Alpine AppStream PRoot-hook fixes are covered by the current focused suite (190/190 passed on 2026-11-14). Fresh Ubuntu and Alpine device results are recorded above. Earlier main-branch validation remains historical. The installed stable v2.0.0 package
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
- The manager socket service runs only when explicitly started from source and
  has no background supervisor. `tx control` is a separate read-only browser
  dashboard in this source, but neither feature is in the released 2.0.0 package.
  See [next actions](NEXT-ACTIONS.md) for remaining UI and host-service gates.
