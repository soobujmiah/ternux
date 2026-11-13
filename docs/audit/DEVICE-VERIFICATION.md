# Device verification record

**Date:** 2026-11-13
**Device:** Xiaomi 25053RT47C (Redmi Turbo 4 Pro), Android 16, ARM64,
SM8735 / Adreno 825.

This record separates physical-device observation from source tests and CI.
It does not claim qualification on other GPUs, Android builds, or Termux:X11
versions.

## Live guest sessions

| Guest | Display | Lifecycle | Termux:X11 | PulseAudio route | Firefox executable |
|---|---:|---|---|---|---|
| Debian 13 (Trixie) | `:0` | READY | running | ready | `/usr/bin/firefox-esr` |
| Ubuntu 26.04.1 | `:1` | READY | running | ready | `/usr/local/bin/firefox-esr` |
| Alpine 3.24 | `:2` | READY | running | ready | `/usr/bin/firefox-esr` |

All three desktops were already running during these checks. No desktop, X11,
audio, or IBus service was restarted. The user was told to keep GUI sessions
available; the active sessions were preserved.

On 2026-11-13, the managed session records still reported READY with the same
Debian/Ubuntu/Alpine PIDs (18218/14129/26946). Read-only X11 queries connected
to each existing display and reported 640×1386 pixels. The XFCE runtime
configuration returned `Ternux` for GTK, icon and XFWM themes, with titlebar
layout `|HMC`; Ctrl+Space resolves to
`/usr/local/bin/ternux-ibus-next-engine` on all three sessions. The IBus daemon
answered on every display. Calling the assigned switch helper once and again
returned each guest to its original engine:

| Guest | Before | After one switch | After second switch |
|---|---|---|---|
| Debian | `ibus-avro` | `xkb:us::eng` | `ibus-avro` |
| Ubuntu | `ibus-avro` | `xkb:us::eng` | `ibus-avro` |
| Alpine | `xkb:us::eng` | `m17n:bn:avro-phonetic` | `xkb:us::eng` |

This validates the runtime command, its live XFCE binding, and both configured
engines. The command was invoked directly; this run does not prove a physical
Android keyboard delivers the Ctrl+Space event. Earlier per-display synthetic
XTest evidence is recorded below.

## Window fit and theme

The X11 helper's coordinate translation was reversed in source, and its old
event scan could inspect decoration windows instead of the managed application
list. The fix now translates the client origin into root coordinates, reads
`_NET_CLIENT_LIST` as WINDOW IDs, clamps stale work areas to the physical screen,
and preserves valid maximized dimensions while constraining off-screen windows.
The same helper SHA-256 is present in the source and all three active guests:

```text
a990edf3a929eb1633e70ad86d4d2044f841677531e770fdff953cc81aed4017
```

Ubuntu's already-open XFCE About window was observed beyond the right display
edge. The running helper moved that window into the available work area without
closing it. On this audit, source and live tests cover the existing applications
and known common GTK/Firefox titlebar behavior; they do not certify every
third-party toolkit or future desktop application.

On 2026-11-13, a temporary oversized normal X11 client (1800×1900) was mapped
on each existing display. The active helper constrained each to a 640×1339
client in the 640×1359 XFCE work area, accounting for the 20-pixel titlebar;
all outer frames remained within 640×1386. Only the temporary verification
windows were destroyed. No desktop process or existing application was
stopped. This qualifies the helper's live viewport behavior on all three
displays; it does not guarantee every toolkit's custom client-side decorations.

Debian, Ubuntu, and Alpine report the Ternux GTK, icon, and XFWM themes. The
common titlebar layout is `|HMC` (minimize, maximize, close). A live Firefox
window was opened on each guest and the close control was visible in the
captured frame. Only those temporary test windows were closed after inspection.

## IBus

| Guest | English engine | Bengali engine | Configured next-engine shortcut | Synthetic GTK/XTest result |
|---|---|---|---|---|
| Debian | `xkb:us::eng` | `ibus-avro` | `Control+space` | English → Avro → restored English |
| Ubuntu | `xkb:us::eng` | `ibus-avro` | `Control+space` | Avro → English → restored Avro |
| Alpine | `xkb:us::eng` | `m17n:bn:avro-phonetic` | `Control+space` | English → Bengali → restored English |

Ubuntu's engine order was reversed, so it began on Bengali. The active engine
order was normalized to English first, Bengali second. A focused GTK entry
received a synthetic XTest Control+Space and switched engines in each guest.
This verifies the X11/IBus path; it does not establish physical keyboard input
on every Android soft keyboard or hardware keyboard.

On a later 2026-11-13 recheck, the GTK/icon/XFWM theme values, XFCE shortcut
binding, IBus engine order, and daemon response still matched in all guests.
Calling the assigned helper directly switched Alpine from English to its m17n
Avro engine. A host-generated Ctrl+Space event switched Debian and Ubuntu in
the current focused window, but did not change Alpine's engine; a temporary
Alpine GTK entry probe also did not switch. The earlier Alpine GTK/XTest pass
and this recheck disagree. The live config was restored to the original
Ctrl+Space setup, temporary test files were removed, and no IBus, XFCE, X11,
audio, or desktop session was restarted. This Alpine event discrepancy remains
unresolved; no physical Android keyboard claim is made.

## Graphics and browser

The documented device profile has observed Mesa Turnip Vulkan and Zink on the
three guest families. A read-only probe run with the wrong display number for
Ubuntu/Alpine emitted llvmpipe; that output is intentionally **not** used as
renderer evidence. Correct per-display probes must use Debian `:0`, Ubuntu `:1`,
and Alpine `:2`, and must record loader/device enumeration and renderer together.

Firefox ESR is installed on the three active guests. Live GUI launch checks on
all three displayed a Firefox window with the Ternux titlebar close control.
The clean Debian/Ubuntu/Alpine browser matrix passed in exact-main Validate run
`43359028809` on commit `db9fe4a70177641b1e1312d2db47462191daf582`. This is CI
evidence; it is distinct from the live existing-guest launches above.

## Evidence boundaries

- Existing desktop READY status is not a clean-install or upgrade test.
- Synthetic XTest is not physical-keyboard typing.
- One SM8735 device is not a universal Android/GPU qualification.
- The active live guests are owner data; they were not deleted or reinstalled.
- No full Android reboot or critical desktop/audio service restart was performed.
