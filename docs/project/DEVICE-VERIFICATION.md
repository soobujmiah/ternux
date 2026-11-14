---
title: "Ternux device verification status"
description: "Dated live-device evidence for Ternux guests and the limits of each observation."
lang: "en"
---

## Device verification status

**Reference device:** Xiaomi Redmi Turbo 4 Pro, Android 16, ARM64, SM8735 /
Adreno 825. **Audit date:** 2026-11-13.

## Live guest snapshot

`tx verify debian --json`, `tx verify ubuntu --json`, and
`tx verify alpine --json` each returned `status: passed`. Existing desktops
were kept running. X11 read-only queries reported 640×1386 for Debian `:0`
and Ubuntu `:1`; XFConf, IBus, and window metadata were queried on all three.

| Check | Debian | Ubuntu | Alpine | Evidence limit |
|---|---|---|---|---|
| GTK theme | Ternux | Ternux | Ternux | GTK theme selection, not every app's custom widget styling |
| Icon theme | Ternux | Ternux | Ternux | Theme selected; individual icon names may use inherited fallback |
| XFWM theme / controls | Ternux / `|HMC` | Ternux / `|HMC` | Ternux / `|HMC` | Existing normal windows show WM decoration metadata; Firefox is not currently open |
| Firefox ESR executable | `/usr/bin/firefox-esr` | `/usr/local/bin/firefox-esr` | `/usr/bin/firefox-esr` | Version query succeeded; current audit did not launch new visible browser windows |
| Viewport helper | same SHA-256 | same SHA-256 | same SHA-256 | helper file and autostart entry present; oversized-window live test is preserved in `../audit/DEVICE-VERIFICATION.md` |
| Ctrl+Space helper config | registered | registered | registered | direct helper switches engines; physical Android key delivery is not proven here |

All three contain the same viewport helper digest:
`a990edf3a929eb1633e70ad86d4d2044f841677531e770fdff953cc81aed4017`.
Each autostart desktop entry runs
`/usr/local/bin/ternux-window-fit-x11`.

## IBus observation

The IBus daemon answered in all three active display sessions. Directly
calling the configured helper switched the engine in each guest; this audit
restored the original engines (`ibus-avro`, `ibus-avro`, and
`xkb:us::eng`). IBus settings contain the engine order, and XFCE maps
`<Primary>space` to the helper. This establishes configuration and helper
behavior, not physical key delivery. The earlier synthetic probe discrepancy
remains in [the detailed device report](../audit/DEVICE-VERIFICATION.md).

## 2026-11-14 install and lifecycle follow-up

A later clean Ternux-managed Ubuntu profile install completed and its XFCE
desktop/audio reached running state on display `:2`; managed stop succeeded.
Window-level input was not tested because the transient guest command did not
have the X11 socket available. Alpine 3.24.4 profile installation failed after
546 packages while extracting the WebKit JavaScriptCore library, despite three
managed retries. Debian was restored and verified. Ubuntu and partial Alpine
test guests were removed through `ternux distro uninstall`; see the
[detailed device record](../audit/DEVICE-VERIFICATION.md).

## 2026-11-14 read-only display migration preview

On the Xiaomi Redmi Turbo 4 Pro (Android 16, ARM64, Adreno 825), the source
implementation at commit `71562a28adced8dd8ad163d1651b961ea3770a4b` was queried
with `TERNUX_LIB_DIR="$PWD/lib" bash ./bin/ternux manager displays --json`.
Schema 1.3.0 reported Debian `:0 → :1` as `move` with an `active-session`
blocker, while Ubuntu `:2` and Alpine `:3` were `keep`. The top-level preview
reported `preview-only`, `executor_implemented: false`, and
`ready_to_execute: false`. No guest was stopped, restarted, or reassigned.
Disposable tests also verified that malformed registry data and a profile /
registry mismatch are reported without rewriting either record.

## Not re-tested in this audit

No GUI, X11, PulseAudio, IBus, or Termux session was restarted. This snapshot
does not re-measure GPU performance, audio recording, camera capture, live
preview, thermal behavior, or physical keyboard input. See the historical
[feature matrix](../audit/FEATURE-MATRIX.md) for prior evidence and limits.


## 2026-11-14 local migration executor qualification

The source worktree now implements `tx manager migrate --apply sha256:PLAN_ID`
and `--recover`. Disposable state tests cover exact plan matching, stale-plan
refusal, active blockers, profile/registry rollback, interrupted-journal restore,
and blocking starts while recovery is pending. These tests do not apply the
reference device's Debian `:0 → :1` move: that guest was active in the recorded
snapshot, and this local implementation has not yet been device-qualified.
