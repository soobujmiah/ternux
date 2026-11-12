# Ternux v2 and v3 delivery audit

**Audit date:** 2026-11-13 (UTC)
**Repository:** `soobujmiah/ternux`
**Audit base:** `main` at `f963832fb4acf9c3adb873430408ce21ddd29a37`
**Target:** finish v2.0.0 for Debian, Ubuntu, and Alpine; publish the complete v3 architecture only after v2 acceptance.

This page is the concise current-state index. Evidence, device checks, and the
feature-by-feature qualification are split into [device verification](DEVICE-VERIFICATION.md),
[repository state](REPOSITORY-STATE.md), and [feature matrix](FEATURE-MATRIX.md).
The repository's generated `.repo/` state is maintained by its workflow; it is
never edited by hand.

## Current outcome

**v2 is not ready to publish.** The public signed Termux APT endpoints return
404, so a clean `pkg install ternux` from Ternux's own repository has not been
verified. This is the only remaining blocking gate. The exact merged-main
Validate run `43307868038` passed on `f963832fb4acf9c3adb873430408ce21ddd29a37`,
including the clean Debian/Ubuntu/Alpine Firefox X11 matrix. The in-place
updater's staged migration, integrity, interrupted-update, and recovery fixtures
pass; a physical rollback demonstration is not a v2 acceptance requirement.

The v2 support statement is limited to Debian, Ubuntu, and Alpine guest profiles
on the documented Android/ARM64 device stack. Other named guest recipes remain
available as experimental or future-qualified profiles; their existence is not
a v2 support guarantee. Hardware evidence is specific to Redmi Turbo 4 Pro,
SM8735, Adreno 825, Android 16.

## Active device work

The owner's Debian `:0`, Ubuntu `:1`, and Alpine `:2` desktops were kept running.
The X11 window-fit watcher fix was applied to the source and copied to all three
active guests; the source and guest helper SHA-256 values match
(`a990edf3a929eb1633e70ad86d4d2044f841677531e770fdff953cc81aed4017`). Ubuntu's
already-open XFCE About window was brought inside its phone viewport without
closing it or restarting XFCE, Termux:X11, PulseAudio, or IBus. The managed
window-fit helper is the only desktop-related process that was refreshed.

The GTK test entry accepted a synthetic XTest Ctrl+Space event and switched
between the current English/Bengali engines in all three guests. This is a
synthetic event check, not physical-keyboard typing evidence. Firefox test
windows showed the close control on all three live desktops and were closed
after their own launch checks; user-owned windows were left untouched. Existing
desktop status is READY for all three guests with Termux:X11 and PulseAudio
routes present. Renderer qualification for the exact SM8735/Adreno 825 target is
recorded separately; no universal GPU claim is made.

## Delivery order

1. The exact merged-main browser matrix and required Validate checks passed in
   run `43307868038`.
2. Publish the signed RC repository, verify hosted signatures/indexes, and test
   native Termux package install/upgrade/uninstall without removing user guests
   or unrelated packages.
3. Recompute every blocking v2 gate from current evidence. Publish v2.0.0 only
   when the machine validator reports `READY_FOR_OWNER_APPROVAL` and the owner
   authorizes the stable release.
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
