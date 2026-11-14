---
title: "Ternux implementation status"
description: "Current implementation state by product area, separated from proposals and test evidence."
lang: "en"
alt_url: "/bn/docs/project/IMPLEMENTATION-STATUS.html"
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
| Installer onboarding and terminal UI | IMPLEMENTED in current main source | Multi-guest setup precollects shared shell, usernames, and workload choices before installation; each guest has an explicit final start/shell command. The 80x24 dashboard shows the large ASCII wordmark and compact device/graphics panel; 18x39 terminals show compact hardware/backend details. Local renderer suite: 56/56; focused suite: 190/190; package bootstrap tests cover broken-curl wget fallback. PR #235 and generated-state PR #236 merged; exact-main Validate, package, and repository-contract checks passed. |
| Native Control Center (required next v2 scope) | PARTIAL; responsive, read-only local browser dashboard implemented in source | `tx control` shows manager/guest/display state on a random loopback port with a one-hour in-memory token and strict Host/Origin checks. Authenticated lifecycle actions, native APK, supervisor, durable jobs, and graphics/audio/storage/workload panels remain open. Python 3 optional; not in withdrawn 2.0.0 package |
| Native manager read-only CLI payloads | IMPLEMENTED in this source revision; display snapshot verified on-device | `TERNUX_LIB_DIR="$PWD/lib" bash ./bin/ternux manager ... --json` returned status/guest/capability and current/target display payloads on this device. Display schema 1.3.0 reports a state-bound migration preview and explicit journaled apply path and a unique running guest's saved display assignment, or labels ownership unresolved/reserved; it does not prove OS-level socket ownership. The released stable APT package remains 2.0.0 and `tx manager` there returns `Unknown command: manager`; source verification does not imply package delivery |
| Native manager API service / Control Center | PARTIAL; read-only Unix socket and loopback dashboard implemented in source | `tests/manager_service.py` covers Unix-socket peer UID and malformed requests; `tests/control_center.py` covers bearer expiry, Host/Origin, CSP, read-only routes and CLI snapshots. Service supervisor, durable jobs, mutations, native Android client, and full dashboard panels remain open |
| Display allocation and migration (required next v2 scope) | Source executor implemented; device apply pending | New profiles default to native reservation `:0`, Debian `:1`, Ubuntu `:2`, Alpine `:3`, and stable serial slots for the other 12 recipes. Start refuses occupied socket/lock/server paths. `tx manager displays` reports current/target assignments and a schema 1.3.0 state-bound plan; `tx manager migrate --apply sha256:PLAN_ID` revalidates under an exclusive lock, refuses active guests or unsafe targets, and journals rollback/recovery. Focused migration tests and exact-head CI passed in PR #233 / merge `376abe08a936c2fcbf161fc779d3c101e8255e99`. The reference device's Debian/Ubuntu/Alpine sessions are active, so the live switch was not applied; saved assignments remain unchanged. Owner classification is best-effort, not OS-level socket-owner proof; see [next actions](NEXT-ACTIONS.md) |
| Compute/AI orchestration (required next v2 scope) | DESIGNED; existing optional artifacts remain separate | No platform-wide runtime qualification claim |
| Camera/microphone Device Bridge (required next v2 scope) | DESIGNED; no broker implementation | Existing limitations remain in the audit docs |
| Distro-profile framework (required next v2 scope) | PARTIAL; shared recipe engine and 15 named profiles implemented | Multi-guest precollection now gathers shell, usernames, and workload choices before guest transactions; clean lifecycle and device qualification remains required per advertised guest |

The stale-distro doctor selection, Ubuntu Mesa-overlay detection, guest-state resume reset, managed uninstall cleanup, Alpine AppStream PRoot-hook fixes, and journaled display migration are covered by current focused tests and exact-main CI (2026-11-14). Fresh Ubuntu and Alpine device results are recorded above. Earlier main-branch validation remains historical. The installed stable v2.0.0 package
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
