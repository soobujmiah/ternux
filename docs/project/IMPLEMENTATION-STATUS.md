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
| Native Control Center (required next v2 scope) | PARTIAL; responsive local dashboard with confirmation-bound desktop start/stop and durable job records in current working source | `tx control` uses a random loopback port, one-hour bearer token, same-origin/CSRF checks for mutations, fixed CLI arguments, and state-bound plans. Backend tests exercise typed requests, idempotency, stale-plan rejection, job progress, and restart reconciliation. A source-branch authenticated API harness completed stop/start on live Ubuntu and Alpine and a fresh snapshot showed all three guests running; rendered browser interaction remains unverified, and Debian is guarded until its display migration is applied. Native APK, supervisor, cancellation, logs, diagnostics, and graphics/audio/storage/workload panels remain open. Python 3 optional; not in withdrawn 2.0.0 package |
| Native manager read-only CLI payloads | IMPLEMENTED in this source revision; display snapshot verified on-device | `TERNUX_LIB_DIR="$PWD/lib" bash ./bin/ternux manager ... --json` returned status/guest/capability and current/target display payloads on this device. Display schema 1.3.0 reports a state-bound migration preview and explicit journaled apply path and a unique running guest's saved display assignment, or labels ownership unresolved/reserved; it does not prove OS-level socket ownership. The released stable APT package remains 2.0.0 and `tx manager` there returns `Unknown command: manager`; source verification does not imply package delivery |
| Native manager API service / Control Center | PARTIAL; read-only Unix socket and loopback dashboard with start/stop job adapter in working source | `tests/manager_service.py` covers Unix-socket peer UID and malformed requests; `tests/control_center.py` covers bearer expiry, Host/Origin, CSP, read-only snapshots, typed lifecycle routes, idempotency, display migration guards, concurrent confirmation, singleton service ownership, state verification, retention, and interrupted-job recovery (20/20 on the working branch). Service supervisor, cancel/retry UI, native Android client, and full dashboard panels remain open |
| Display allocation and migration (required next v2 scope) | Source executor implemented; one live migration/restart verified | The schema 1.3.0 state-bound plan is revalidated under an exclusive lock; active guests, another managed session holding the shared lifecycle lock, and unsafe targets block execution, with journaled rollback/recovery. On 2026-11-14 the reference-device migration was applied after stopping all guests; Debian regenerated its launcher for `:1`, and all three guests restarted READY on `:1/:2/:3`. This is one-device evidence, not the full clean lifecycle matrix. Owner classification remains best-effort, not OS-level socket-owner proof; see [device verification](../audit/DEVICE-VERIFICATION.md) and [next actions](NEXT-ACTIONS.md) |
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
  has no background supervisor. `tx control` is a separate browser dashboard
  with confirmed desktop actions in working source; neither feature is in the
  withdrawn 2.0.0 package.
  See [next actions](NEXT-ACTIONS.md) for remaining UI and host-service gates.
