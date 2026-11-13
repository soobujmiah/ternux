# Ternux v2 and v3 delivery audit

**Audit date:** 2026-11-13 (UTC)
**Repository:** `soobujmiah/ternux`
**Audit base:** `main` at `faa5f0c4733e82fa0e82c88c6a2cd4531a1c3442`
**Target:** finish v2.0.0 for Debian, Ubuntu, and Alpine; publish the complete v3 architecture only after v2 acceptance.

This page is the concise current-state index. Evidence, device checks, and the
feature-by-feature qualification are split into [device verification](DEVICE-VERIFICATION.md),
[repository state](REPOSITORY-STATE.md), and [feature matrix](FEATURE-MATRIX.md).
The repository's generated `.repo/` state is maintained by its workflow; it is
never edited by hand.

## Current outcome

**All blocking v2 acceptance gates are complete.** Signed `/apt-rc` and stable
`/apt` publication, signature/index/hash checks, routine website preservation,
and native Termux clean install/reinstall/removal tests passed. The updated
multi-distro `verify` selector is installed from the stable APT package and
verified on device. The owner authorized release; only the `v2.0.0` GitHub tag,
GitHub release and final release report remain. Exact-main Validate run
`43362104082` passed on `faa5f0c4733e82fa0e82c88c6a2cd4531a1c3442`; it includes
the clean Debian/Ubuntu/Alpine Firefox X11 matrix. The in-place updater's staged migration,
integrity, interrupted-update, and recovery fixtures pass; a physical rollback
demonstration is not a v2 acceptance requirement.

The v2 support statement is limited to Debian, Ubuntu, and Alpine guest profiles
on the documented Android/ARM64 device stack. Other named guest recipes remain
available as experimental or future-qualified profiles; their existence is not
a v2 support guarantee. Hardware evidence is specific to Redmi Turbo 4 Pro,
SM8735, Adreno 825, Android 16.

## Active device work

The owner's Debian `:0`, Ubuntu `:1`, and Alpine `:2` desktops remain READY at
the same managed PIDs 18218, 14129, and 26946. The 2026-11-13 live check queried
each X11 display at 640×1386 and confirmed its current Ternux GTK, icon, and
XFWM theme, `|HMC` titlebar controls, and Ctrl+Space helper binding. Direct
helper calls cycle to the other installed IBus engine in each guest. A fresh
host-generated key event switched engines on Debian and Ubuntu; Alpine stayed
on English in the same probe although its helper works directly. This conflicts
with the earlier focused GTK/XTest result and is recorded for follow-up. It does
not verify a physical Android keyboard.

An oversized 1800×1900 test window was created separately on each existing
display. The active watcher constrained each client to 640×1339 and kept its
framed geometry inside the available work area; only those temporary test
windows were destroyed. The desktops were not restarted.

The owner's Debian `:0`, Ubuntu `:1`, and Alpine `:2` desktops were kept running.
The X11 window-fit watcher fix was applied to the source and copied to all three
active guests; the source and guest helper SHA-256 values match
(`a990edf3a929eb1633e70ad86d4d2044f841677531e770fdff953cc81aed4017`). Ubuntu's
already-open XFCE About window was brought inside its phone viewport without
closing it or restarting XFCE, Termux:X11, PulseAudio, or IBus. The managed
window-fit helper is the only desktop-related process that was refreshed.

Earlier GTK test evidence recorded a synthetic XTest Ctrl+Space switch in all
three guests. The newest host-generated probe changed Debian and Ubuntu engines
but not Alpine; the direct Alpine helper still switches correctly, so current
keyboard-event behavior needs another focused check before making a universal
input claim. This is not physical-keyboard typing evidence. Firefox test
windows showed the close control on all three live desktops and were closed
after their own launch checks; user-owned windows were left untouched. Existing
desktop status is READY for all three guests with Termux:X11 and PulseAudio
routes present. Renderer qualification for the exact SM8735/Adreno 825 target is
recorded separately; no universal GPU claim is made.

## Delivery order

1. Exact-main browser matrix and required Validate checks passed in run
   `43362104082`; stable signed package and native verification passed.
2. Create the `v2.0.0` tag and GitHub release on the validated main commit.
3. Publish the final v2 release report and verify the public stable APT and
   GitHub release assets.
4. After v2 is complete, publish the v3 architecture and its versioned
   acceptance plan. V3 work must not be described as part of v2.

## Evidence labels

- **Verified:** directly exercised on the named test path/device and date.
- **CI verified:** exact workflow evidence, not physical-device evidence.
- **Partial:** a related route passed but a required part remains unverified.
- **Experimental:** functionality exists but is not a stable v2 promise.
- **Deferred:** explicitly outside v2 acceptance.
- **Blocked:** a required endpoint, credentialed publication, or test cannot yet
  be observed.

No release or tag is implied by a local source change or a passing artifact
build. The final v2 claim must cite the exact merged commit and hosted APT URL
checks.
