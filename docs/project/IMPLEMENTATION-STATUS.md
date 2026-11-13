---
title: "Ternux implementation status"
description: "Current implementation state by product area, separated from proposals and test evidence."
lang: "en"
---

## Implementation status

**Last reviewed:** 2026-11-13 11:04 UTC. This page reports repository and device state;
it does not upgrade a design status into an implementation claim.

| Area | State | Evidence / next gate |
|---|---|---|
| v2 Termux manager and distro CLI | RELEASED (`2.0.0`) | GitHub tag/release and signed stable APT record; see [release status](RELEASE-STATUS.md) |
| Debian / Ubuntu / Alpine desktop profiles | IMPLEMENTED; v2 qualified on reference device | Current live `tx verify` passed all three; device snapshot in [verification](DEVICE-VERIFICATION.md) |
| Ternux GTK/icon/XFWM defaults | IMPLEMENTED and observed active in all three live guests | Runtime XFConf queries returned Ternux/Ternux/Ternux and `|HMC`; broad third-party CSD coverage is not claimed |
| Window viewport helper | IMPLEMENTED and deployed in all three guests | Identical SHA-256 `a990edf3a929eb1633e70ad86d4d2044f841677531e770fdff953cc81aed4017`; prior oversized-window evidence is linked in device audit |
| IBus engine switch command | IMPLEMENTED | Direct helper cycles each guest's configured engine and restores original; physical Ctrl+Space delivery remains separately qualified |
| Native Control Center | DESIGNED; not implemented | v3 architecture docs |
| Native manager read-only CLI payloads | IMPLEMENTED in current source; source-device verified | `TERNUX_LIB_DIR="$PWD/lib" bash ./bin/ternux manager ... --json` returned status/guest/capability payloads on this device. The released stable APT package remains 2.0.0 and `tx manager` there returns `Unknown command: manager`; source verification does not imply package delivery |
| Native manager API service / Control Center | DESIGNED; not implemented | v1 request/response/error schemas and negative contract fixtures are tested; no Unix socket service, HTTP adapter, authorization/session runtime, or graphical client is implemented |
| Compute/AI orchestration v3 | DESIGNED; existing v2 optional artifacts remain separate | No v3 runtime qualification claim |
| Camera/microphone Device Bridge v3 | DESIGNED; no v3 broker implementation | Existing v2 limitations remain in the audit docs |
| v3 distro-profile framework | DESIGNED; not implemented | v2 Debian/Ubuntu/Alpine behavior remains the compatibility baseline |

## Active limitations

- Physical Android keyboard delivery of Ctrl+Space is not established by a
  config query or direct helper invocation. Earlier synthetic probes conflict.
- v2 qualification is for the named Android/Adreno reference device and the
  stated three guests; do not generalize to other devices or distros.
- The released 2.0.0 package and current `main` source are different artifacts.
  Read-only manager commands exist in `main` but are not present in the
  installed/published 2.0.0 package.
- v3 pages are a design baseline. Implementation begins only in phased,
  tested vertical slices; see [next actions](NEXT-ACTIONS.md).
