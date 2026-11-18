---
title: "Ternux v2 release readiness"
description: "Local v2.0.1 candidate status, v2.0.0 withdrawal history, and four-distro evidence boundaries."
lang: "en"
alt_url: "/bn/docs/V2-RELEASE-READINESS.html"
---

## Current status — 2026-11-18

The v2.0.0 source tag is retained, but its GitHub Release object was removed
and stable APT withdrawn on 2026-11-14. The owner revoked the 2026-11-14 scope
change that moved former v3 features into v2: v2 is frozen to the existing
implementation, and new architecture/capabilities remain v3 work.

The next unused candidate is **v2.0.1**. It is being prepared locally from
current `main` and is **not published**. There is no approved release commit,
tag, generated artifact, checksum, or GitHub Release page for this candidate.
The stable APT channel remains withdrawn and is not a v2 release requirement.
The owner-confirmed v2 verified desktop baseline is Debian, Ubuntu, Kali Linux,
and Alpine; evidence depth differs by distro. The clean-container Firefox CI
matrix currently covers Debian, Ubuntu, and Alpine. See the
[feature matrix](audit/FEATURE-MATRIX.md) and [device evidence](audit/DEVICE-VERIFICATION.md).

## Local v2.0.1 candidate checks — 2026-11-18

- `python3 tests/window_fit_geometry.py`: 12 geometry/state cases passed.
- `bash tests/focused.sh`: 211 passed, 0 failed.
- `bash tests/update_transaction.sh`: passed the pinned update, 2.0.0→2.0.1
  upgrade, 1.4.0→2.0.1 migration fixture, rollback, interrupted-update
  recovery, concurrency, and symlink-safety checks.
- Astro build: 90 static pages built; finalizer reported 56 HTML routes.
- `python3 tests/docs_check.py`: 6,518 assertions, 616 internal links, and 24
  bilingual page pairs passed. `npm run format:check` passed after formatting
  both modified landing pages.
- An earlier live X11 check used `xdotool windowsize`, so it did not exercise a
  pointer resize and was insufficient evidence for the reported behavior. The
  corrected live pointer test is recorded below.
- `npm audit --json` found nine high-severity dependency paths, all through
  Picomatch versions 4.0.7 and 2.3.2 in the website build tree. GitHub Advisory
  Database lists CVE-2026-112366 as affecting Picomatch through 4.0.7 with no
  patched version; the installed Ternux CLI has no Node dependency. The
  vulnerable code is therefore in the website build toolchain, not the guest
  runtime. No dependency downgrade or override was applied because no verified
  safe fix is available; the upstream issue remains unresolved. This is a
  documented CI/build-chain risk, not evidence of a v2 runtime exploit.

## Live resize correction and X11 stall investigation — 2026-11-18

The earlier live check above used programmatic `xdotool windowsize` and did not
exercise the pointer resize path. It was insufficient evidence for the user's
reported resize bug. The repeated live test found that the window fitter
reapplied its launch-time minimum size during resize events and used
`StaticGravity` with frame coordinates, which could fight XFWM and shift a
decorated window by its title-bar extent.

The local fix now limits minimum-size policy to initial placement, keeps the
user's chosen size and position during interactive resizing, and sends frame
coordinates with EWMH `NorthWestGravity`. On the live Debian/XFCE session, a
temporary window was moved to client position `(74, 244)` and pointer-resized
from `280x240` to `340x300`, then `380x340`. Its position remained `(74, 244)`
after each drag and after a one-second settle. No resize-time correction was
logged. The candidate helper was installed through `tx distro root debian`,
Python syntax-checked in Debian, and the desktop was restarted through
`tx restart debian`.

The X11 stall itself was not reproduced during this check. The device is
Android 16 on Xiaomi model `25053RT47C`, with F-Droid Termux `0.119.0-beta.3`,
Adreno 825, and Zink/Turnip. Termux:X11 stayed alive; 80 X11 request round trips
measured 1.41 ms minimum, 1.84 ms median, 2.93 ms p95, and 4.81 ms maximum.
At sampling, Termux:X11 used about 228 MiB RSS and the host reported roughly
4.1 GiB available RAM. These short measurements cannot rule out an intermittent
Android scheduling or GPU-driver stall. The upstream
[Termux:X11 documentation](https://github.com/termux/termux-x11#avoiding-slowdowns)
states that Android may give Termux less CPU time while the separate X11 app is
foregrounded. Its shared-UID workaround requires GitHub-signed Termux and is
not compatible with this F-Droid install.

Termux:Boot is installed. It can start a script after reboot and can invoke
`termux-wake-lock` to prevent device sleep; it does not correct an already
running X11/GPU hang or the separate-app scheduling behavior. Battery
unrestricted settings for Termux and Termux:X11 are documented in
[Troubleshooting](TROUBLESHOOTING.md#x11-slows-down-or-stalls).

At the final status sample, Ternux and X11 reported READY/running, but the
PulseAudio bridge had transitioned back to `pulseaudio_ready=no` after briefly
reporting ready on restart. This is separate from the resize test and remains
an observed runtime issue to investigate; `tx verify debian` still passed its
desktop and GPU checks. The desktop was left running with Termux:X11 open.

The standalone and CLI fallback now share an immutable local source snapshot at
`f7d2a43d97df2bec90cf0a481926e6f57234cbd9`. Its deterministic source archive
SHA-256 is
`2924d17dce9a3971c5765b115c81f13c80f2914a3072c6fd627b012201b123b2`, and
`TERNUX_SOURCE_ARCHIVE_OVERRIDE=<archive> bash tests/bootstrap_source_sync.sh`
passed against that archive. A known published commit established that this
local `git archive | gzip -n` format reproduces GitHub's short-SHA codeload
archive digest. Since the new snapshot is not on GitHub yet, its live codeload
URL cannot be checked until repository synchronization; the exact-commit CI
check remains required after approval.

These are local candidate results, not exact-commit GitHub CI or release
qualification. No repository release object, tag, release asset, or GitHub
change was created.

## Ctrl zoom shortcut correction — 2026-11-18

The live report that Ctrl zoom did not work was reproduced. The X11 helper had
installed passive key grabs with an asynchronous keyboard mode, then called
`ReplayKeyboard`; the intercepted key was consequently not delivered to the
focused application. For an active XFCE Terminal, the helper also consumed a
recognized zoom shortcut after saving the font preference, preventing the
terminal from resizing its current content.

The local correction uses a synchronous keyboard grab and replays every
intercepted zoom key after recording the Xfce Terminal font preference. The
focused Debian live session received Ctrl+Shift+= as `plus` and Ctrl+- as
`minus` in an `xev` window. A Terminal screenshot comparison measured 11.8%
pixel difference after zoom-in and an exact pixel match after zoom-out. The
helper installed in the running Debian guest matches the local file at SHA-256
`80121b944b8d980119ee59e97d3f3278d4c8fd3328a244a242246e2ece1aeb55`; Debian
was restarted through `tx restart debian`. The X11 session reports READY, but
PulseAudio readiness again reports `no` and remains a separate issue.

The pure geometry and shortcut regression suite passes 13 cases, and the full
focused suite passes **211/211**. `python3 tests/docs_check.py` passes 6,518
assertions, 620 internal links, and 24 bilingual page pairs. `tx verify debian`
passes desktop-service and Turnip checks. Exact-commit CI for this follow-up is
pending; the preceding merged main commit `f7963c6b7bcacf43cabf30a1da3d5bdbf1ebf490`
passed Validate, Repository State Contract, Termux APT package artifact, and
Repo Knowledge Sync. The local Termux Node executable could not start because
of an Android C++ runtime symbol mismatch, so its `npm run format:check` did
not run; the preceding exact-main CI formatter check passed and this follow-up
does not modify website source files. The intermittent X11 stall has not been
reproduced; the earlier short response-time measurements remain insufficient to
rule it out. This correction is local and is not yet part of main or a
published v2 artifact.

## Historical v2.0.0 qualification snapshot

**Status:** withdrawn from public distribution
**Audit date:** 2026-11-16
**Target:** Ternux 2.0.0
**v2 GitHub release:** withdrawn 2026-11-14; [tag retained for provenance](https://github.com/soobujmiah/ternux/tree/v2.0.0). Stable APT paths return HTTP 404 after withdrawal run [43532161200](https://github.com/soobujmiah/ternux/actions/runs/43532161200); signed RC remains available.

Ternux v2 desktop support is limited to **Debian, Ubuntu, and Alpine**; other
named distro recipes are not v2-qualified. The 20-gate inventory records the
pre-publication approval state; all blocking gates passed before release. The
source tag remains, while the GitHub release and stable APT channel were
withdrawn on 2026-11-14. See the historical [v2.0.0 release report](V2-RELEASE-REPORT.md)
for the exact tag, package hashes, CI runs,
post-publication APT preservation, supported scope, and device limits. Exact-main
Validate run `43372097795` passed on release commit
`9106b04fc8627ae98b1d63c9912a28c8a4677441`.
## Current acceptance gates

| Gate | Status | What closes it |
|---|---|---|
| P1-03 updater safety | **COMPLETE** | Source/hash pinning, stage-before-replace, interrupted-update recovery, downgrade guard, concurrency and symlink fixtures pass; the v1.4.0 source fixture upgrades to v2. A published v2 rollback demonstration is not required. |
| P1-09 default browser | **COMPLETE** | Clean Debian Trixie, Ubuntu 24.04, and Alpine 3.24 Firefox X11 window checks passed in exact-main Validate run `43372097795` on release commit `9106b04fc8627ae98b1d63c9912a28c8a4677441`; Ubuntu uses Mozilla ESR without Snap. |
| P1-APT signed Termux package | **PASSED AT RELEASE; CHANNEL WITHDRAWN** | Stable signed APT publication workflow `43362569559` succeeded on exact main `faa5f0c4733e82fa0e82c88c6a2cd4531a1c3442`. Public stable `InRelease` verifies against fingerprint `E5527F4D5B83037FF77B65AE5E894BBB81168B1D`; `Packages.xz` SHA-256 is `3bbab20f0119b3c038e14c9a49714e499325b0c7036a899c3304e67b3b39e137` and the indexed package SHA-256 is `4ef03210c71e3d5671671e9a49fc83f6aebf7cdb5e5a28cb32db61d49e85c89f`. Native `pkg update`, clean package uninstall/install, `dpkg --verify`, active-default and explicit `db`/`ub`/`alp` JSON verification passed. Evidence is in `release-gates.json` and `audit/REPOSITORY-STATE.md`. |

HTP/HMX and QNN remain experimental or research-only and are excluded from
stable v2 promises. CPU/Vulkan claims are limited to the named model, task, and
SM8735/Adreno 825 evidence in the accelerator plan. Other guest recipes and
other Android GPU families are not covered by these v2 gates.

## Device evidence

The reference device is Xiaomi 25053RT47C (Redmi Turbo 4 Pro), Android 16,
ARM64, SM8735 / Adreno 825. Existing Debian `:0`, Ubuntu `:1`, and Alpine `:2`
sessions were observed READY with Termux:X11 and PulseAudio routes. The sessions were left running. Live Firefox
titlebars showed visible close controls. The owner reports that physical
keyboard input switching works in all installed distros. The latest Alpine
follow-up on 2026-11-16 started its display at `:4`; a focused Xfce Terminal
switched IBus with synthetic Ctrl+Space from English to Avro and back to English.
This supersedes the earlier Alpine event discrepancy for this focused X11 check.

On 2026-11-13, runtime D-Bus queries confirmed the GTK, icon, and XFWM themes,
`|HMC` titlebar controls, and active Ctrl+Space binding in every guest. The
assigned IBus helper switched to the other installed language and restored the
original engine. Temporary 1800×1900 X11 clients were constrained inside each
640×1386 display, then only those test clients were destroyed. This tests the
managed switch command, not a physical Android keyboard event.

The window-fit helper now translates client coordinates in the correct
direction, reads EWMH `_NET_CLIENT_LIST` as WINDOW IDs, clamps a stale work area
to current screen dimensions, and retains valid maximized geometry. Its source
and installed helper hashes match across all three guests. Ubuntu's already-open
XFCE About window was moved into its phone viewport without closing it or
restarting the desktop. Full detail and test limitations are in the
[current-state audit](audit/CURRENT-STATE.md) and [device verification](audit/DEVICE-VERIFICATION.md).

Prior device evidence records Turnip/Vulkan-backed Zink on all three profiles
for this device. A renderer probe using the wrong display number for Ubuntu and
Alpine was discarded; it is not used as contrary or qualifying evidence.
Qualification does not extend to other GPUs or devices.

## Verification snapshot

- `bash tests/update_transaction.sh`: passed the pinned update, migration,
  interrupted-update, recovery, rollback-fixture, concurrency, and symlink
  checks during this audit.
- `python3 tests/release_gates.py --check --self-test`: valid 20-gate inventory;
  all blocking gates complete; recorded owner authorization is accepted only
  after the gate inventory is ready.
- `bash tests/firefox_package_matrix.sh`: added to exact-head CI for Debian,
  Ubuntu, and Alpine. It starts Firefox in Xvfb/Openbox and checks
  the mapped visible application window; exact-main run `43372097795` passed
  on release commit `9106b04fc8627ae98b1d63c9912a28c8a4677441`. This Termux host has no
  Docker executable, so the container matrix is established by CI, not claimed
  as a local pass.
- `bash tests/focused.sh`: the audit exposed a test-hygiene regression because
  its `py_compile` step wrote `__pycache__` into packaged assets; the test now
  directs bytecode to its temporary directory. The complete exact-main suite
  passed in `43372097795` on `9106b04fc8627ae98b1d63c9912a28c8a4677441`.
- Stable publication run `43362569559` signed and deployed exact-main package
  `faa5f0c4733e82fa0e82c88c6a2cd4531a1c3442`. The public bootstrap, key,
  `InRelease`, and `Packages.xz` endpoints returned HTTP 200; `gpgv` verified the
  signature against `E5527F4D5B83037FF77B65AE5E894BBB81168B1D`. Stable index and
  package SHA-256 values are recorded above and in `release-gates.json`. Native
  Termux fetched the stable index, removed and freshly reinstalled `ternux`, and
  passed `dpkg --verify`, `ternux verify --json`, `ternux verify db --json`,
  `tx verify ub --json`, and `tx verify alp --json`. The three existing guests
  remained READY with their original PIDs. The GitHub release and stable APT channel were withdrawn on 2026-11-14; see the historical [release report](V2-RELEASE-REPORT.md) and current [APT channel status](TERMUX-APT.md).

## Completed release sequence

1. PR #189 updated English/Bengali install and release documentation; its checks passed and it was merged.
2. Repository workflow generated `.repo/` state in PR #190; its checks passed and it was merged without manual edits.
3. Stable APT signature/index/package, native package lifecycle, per-guest verification, and post-publication website preservation passed.
4. Tag `v2.0.0` was published on validated main `9106b04fc8627ae98b1d63c9912a28c8a4677441`.
5. The final v2.0.0 publication and qualification record is the [historical release report](V2-RELEASE-REPORT.md). The 2026-11-14 decision to move former v3 scope into the next v2 release was revoked on 2026-11-18; see the [current project roadmap](project/PROJECT-ROADMAP.md).
## Detailed audit records

- [Current state and decisions](audit/CURRENT-STATE.md)
- [Live-device verification](audit/DEVICE-VERIFICATION.md)
- [Repository and publication state](audit/REPOSITORY-STATE.md)
- [Feature support matrix](audit/FEATURE-MATRIX.md)
- [Machine-readable gate inventory](https://github.com/soobujmiah/ternux/blob/main/docs/release-gates.json)

The `v2.0.0` source tag is retained for provenance. Its GitHub release was
removed and its signed stable APT paths were withdrawn on 2026-11-14; only the
opt-in RC channel remains public. The 2026-11-14 scope change was revoked on
2026-11-18: the former v3 platform scope remains future v3 work. See the current
[project roadmap](project/PROJECT-ROADMAP.md).
