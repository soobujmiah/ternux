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

## Graphics and browser

The documented device profile has observed Mesa Turnip Vulkan and Zink on the
three guest families. A read-only probe run with the wrong display number for
Ubuntu/Alpine emitted llvmpipe; that output is intentionally **not** used as
renderer evidence. Correct per-display probes must use Debian `:0`, Ubuntu `:1`,
and Alpine `:2`, and must record loader/device enumeration and renderer together.

Firefox ESR is installed on the three active guests. Live GUI launch checks on
all three displayed a Firefox window with the Ternux titlebar close control.
Separate clean installation qualification is CI work and remains pending until
the new three-profile matrix passes on the proposed commit.

## Evidence boundaries

- Existing desktop READY status is not a clean-install or upgrade test.
- Synthetic XTest is not physical-keyboard typing.
- One SM8735 device is not a universal Android/GPU qualification.
- The active live guests are owner data; they were not deleted or reinstalled.
- No full Android reboot or critical desktop/audio service restart was performed.
