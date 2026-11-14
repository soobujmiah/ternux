# Device verification record

**Baseline date:** 2026-11-13; **follow-up:** 2026-11-14
**Device:** Xiaomi 25053RT47C (Redmi Turbo 4 Pro), Android 16, ARM64,
SM8735 / Adreno 825.

This record separates physical-device observation from source tests and CI.
It does not claim qualification on other GPUs, Android builds, or Termux:X11
versions.

## 2026-11-14 managed Debian resume and GUI follow-up

**Device:** Xiaomi 25053RT47C (Redmi Turbo 4 Pro), Android 16, ARM64, Adreno 825.
**Repository code head at test time:** `0797d31130e73593183926b48244057815397dd4`.
**Installed CLI:** Ternux `2.0.0`; `dpkg-query -S "$PREFIX/bin/ternux"` found no package owner, so this was not a signed APT clean-install test.

| Check | Result |
|---|---|
| Resume command | `bash ./install.sh --resume --yes --ui plain` completed all 11 phases. Existing Debian was reused; no guest reset/removal occurred. |
| Guest | Debian 13.7 (Trixie), Xfce4, user `sbj`, locale `en_US.UTF-8`, backend `zink`. |
| Installer verification | Passed host tools, launcher, CLI library load, guest companion, Debian desktop core, and Turnip checks. All 23 installed shell modules matched the source checkout byte-for-byte. |
| Standalone bootstrap | A temporary copy of `install.sh` loaded the pinned codeload snapshot `30a109c6e412f6b0514592c8928adba650b064d5`; SHA-256 `27be90807e6f86f80f17ffdc41ac98ed346b09c4b6eaa8381b1a9901b85503da` matched and `--status` completed. No install phase ran. |
| Native host verification | `ternux verify --json` passed on Android 16 / Adreno 825. |
| Desktop startup | `ternux start debian` reached `READY` on display `:0`; X11 functional and PulseAudio route ready. |
| X11 application observation | Via the explicitly authorized xdotool test, `DISPLAY=:0` reported 312×640, a visible Firefox ESR window titled `Linux, beyond the desktop · Ternux — Mozilla Firefox`, and an Escape key event completed. This was a live window query, not a screenshot or a test of physical Android touch/keyboard input. |
| Later status | `ternux status --json` reported `READY`, X11 yes, PulseAudio ready yes, managed desktop PID 21290. No spontaneous close was observed during this run; it was not a controlled long-duration soak. |
| Clean stop | `ternux stop debian` returned STOPPED; subsequent host `ternux verify --json` passed. |

The first start attempt correctly refused to replace a display socket created
by a manually launched Termux:X11 process that did not pass Ternux readiness.
After that process exited, the managed start removed the now-proven stale socket
and started XFCE successfully. This supports the lifecycle safety behavior; it
does not identify the cause of the earlier cross-distro GUI closures.

During resume, Termux:API microphone permission was not confirmed, so its
optional microphone feature was skipped. Android's child-process setting could
not be read; the installer displayed its warning and did not claim that setting
was enabled. These remain device-side checks, not installer failures.

The live guest inventory before the disposable test contained Debian only. A
generic Alpine 3.24.4 OCI guest was then installed with
`ternux distro image-install alpine:latest ternux-test-disposable`, queried via
`ternux distro exec` (`id` returned root), and removed with
`ternux distro uninstall ternux-test-disposable --yes`. Follow-up checks found
neither its container nor Ternux registry entry. This tests generic guest
lifecycle only; it does **not** qualify the Alpine desktop recipe. Ubuntu and
fresh Ternux desktop installs for Ubuntu/Alpine remain unverified in this
follow-up.

## 2026-11-14 Ternux-managed Ubuntu and Alpine install lifecycle

**Repository code head at test time:** `f789097` on the roadmap/device-evidence branch.
**Installed host CLI:** Ternux `2.0.0`; existing Debian was retained throughout.

| Check | Result |
|---|---|
| Clean Ubuntu profile install | `ternux install --yes --user sbj --locale en_US.UTF-8 --backend zink --shell bash --distros ubuntu,alpine --ui plain` completed Ubuntu's 11 phases, including desktop packages, Firefox ESR, Zink overlay, companion, user, launcher, and final verification. The rootfs identified itself as Ubuntu Resolute ARM64. |
| Ubuntu desktop start/stop | `ternux start ubuntu` reached running XFCE on display `:2`; XFCE session, window manager, panel, and PulseAudio route were observed. `ternux stop ubuntu` returned cleanly. |
| Window-level input | `xdotool` was installed inside Ubuntu for the authorized smoke test. `ternux distro exec` did not expose the X11 socket to that transient command, so no window enumeration or input event was established. The temporary guest was later removed. |
| Alpine desktop install | Alpine 3.24.4 installed 546 packages, then failed extracting `usr/lib/libjavascriptcoregtk-4.1.so.0.8.10` from `webkit2gtk-4.1-2.48.7-r0` with `I/O error`. Ternux retried three times and stopped before desktop setup, companion, or launcher completion. Available host storage was ample; the specific extraction cause remains undetermined. |
| Recovery and cleanup | `ternux install --resume --distro debian --yes ...` restored Debian as the selected guest; `ternux verify --json` passed. The Ubuntu and partial Alpine test guests were removed with `ternux distro uninstall ubuntu --yes` and `ternux distro uninstall alpine --yes`. A final Debian verification passed. |

This run establishes Ubuntu profile installation and managed desktop start/stop on this device, but not window-level GUI input. Alpine's desktop recipe did not install successfully and is **not qualified** by this run. Both test guests were removed through Ternux-managed commands; Debian remains installed and verified.

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

## Native Termux snapshot — 2026-11-13 10:49 UTC

This is a new read-only snapshot; it does not replace the earlier workload and
GUI evidence above. `termux-info` identified F-Droid Termux 0.119.0-beta.3,
Android 16, ARM64, Xiaomi model `25053RT47C`. Termux:API (1002), Termux:Boot
(1000), Termux:Styling (1000), and Termux:X11 (15) were installed. The Ternux
stable signed source was configured alongside the Termux main, X11, and TUR
sources.

`dpkg-query` reported `ternux 2.0.0 install ok installed`; read-only
`apt-cache policy ternux` reported version 2.0.0 installed and as the stable
repository candidate. The installed package's `tx manager status --json`
returned a structured fatal `Unknown command: manager` result. The newer
read-only manager CLI exists in the current source checkout and was invoked
there separately:

| Source command | Observed result |
|---|---|
| `TERNUX_LIB_DIR="$PWD/lib" bash ./bin/ternux manager status --json` | `available`, direct CLI mode, 3 installed guests and running desktops Debian/Ubuntu/Alpine |
| `TERNUX_LIB_DIR="$PWD/lib" bash ./bin/ternux manager guests --json` | 3 guests, displays 0/1/2, qualification field `device-qualified` |
| `TERNUX_LIB_DIR="$PWD/lib" bash ./bin/ternux manager capabilities --json` | 3 allowlisted read-only operations |

The checkout-source result does not imply that the released `.deb` contains the
new CLI, that a manager service runs, or that a Control Center exists. No
socket/service was started.

At 10:49 UTC, live commands `tx status db|ub|alp --json` reported lifecycle
`READY`, the expected display, X11 running, and PulseAudio running/route-ready.
`tx verify db|ub|alp --json` returned `passed` and included each guest's
service check and `turnip:present`. This verifies the CLI's current presence and
service probes only; it is not a fresh renderer, Vulkan workload, audio
playback, microphone, or camera test. The three sessions retained PIDs
18218/14129/26946. No GUI, X11, PulseAudio, IBus, or Android process was
restarted, and no guest or user data was changed.

## Diagnostic and renderer recheck — 2026-11-13 12:20 UTC

The installed stable APT package remained Ternux 2.0.0. All three existing
guest desktops remained running; `tx verify debian|ubuntu|alpine --json`
returned passed. No desktop, Termux:X11, PulseAudio, IBus, or Termux process
was restarted.

Per-display read-only GLX/Vulkan probes returned Zink Vulkan 1.4 on Adreno 825
through Mesa Turnip for Debian `:0`, Ubuntu `:1`, and Alpine `:2`. Ubuntu
required the exact environment of its already-running XFCE process; with that
environment its renderer was accelerated. The default host doctor path
incorrectly reported software fallback because Ubuntu's valid overlay directory
had no `mesa-overlay-libdir` marker. Its launcher already falls back to the
known `lib/aarch64-linux-gnu` directory; detection did not.

The global saved distro setting contained stale `archlinux`, while the active
session state selected Debian and all three managed desktop records were
READY. Consequently, the installed v2.0.0 doctor could incorrectly say the
Debian container was missing and fail Vulkan enumeration. The source fix
follows the active installed guest and recovers the isolated Mesa overlay
path; it merged in PR #204 and is covered by focused regression tests. It is
not installed in the released v2.0.0 package.

The v3 display proposal is separate from these live observations: native
Termux `:0`, Debian `:1`, Ubuntu `:2`, Alpine `:3`. The current v2
sessions remain Debian `:0`, Ubuntu `:1`, Alpine `:2` until a staged v3
migration is implemented and validated.

## Native manager socket service — 2026-11-13 14:07 UTC

From the current source checkout, `TERNUX_LIB_DIR="$PWD/lib" bash
./bin/ternux manager serve` started the explicit foreground service on the
Android Termux host. The socket was
`$PREFIX/var/lib/ternux/control/manager.sock`; its parent mode was `0700`,
startup lock `0600`, and socket `0600`. Requests from the Termux UID for `manager.status`,
`manager.guests`, and `manager.capabilities` each returned `status: ok`, the
matching request UUID, and the expected operation payload. Ctrl-C stopped the
service and removed the socket. The GUI guest sessions were not restarted or
modified. The installed signed package remained v2.0.0; this source test does
not represent package delivery or a graphical Control Center.

`python3 tests/manager_service.py` passed 7/7 integration cases on this device,
covering all three operations, malformed and oversized input, concurrent
clients, graceful shutdown, stale-socket recovery, and refusal to remove a
live service socket. A second source run on the real Termux prefix verified
the lock prevents a duplicate service start and leaves the active socket
intact. The request/response schema fixture suite passed 14/14, the focused
regression suite passed 186/186, and repository-knowledge verification found
zero findings. No guest data was changed.

## v3 workspace display snapshot — 2026-11-13 15:17 UTC (merged as PR #210)

The `codex/v3-display-registry` source branch, later merged as main commit
`7b7ea438b96ef11debfa3555852a6619b51be4d8`, ran
`TERNUX_LIB_DIR="$PWD/lib" env -u LD_LIBRARY_PATH bash ./bin/ternux manager displays --json`
on the Termux host. It reported native display `:0` occupied (socket, lock and
Termux:X11 server present), with Debian/Ubuntu/Alpine all still running on
their saved v2 assignments `:0`/`:1`/`:2`. The planned v3 targets were
`:1`/`:2`/`:3`; Debian and Ubuntu target conflicts were flagged, and migration
was required for all three guests. The command did not change assignments,
start or stop a guest, or launch the manager socket service. This is read-only
registry reporting evidence, not a migration or native-workspace readiness
test.

After both PR #210 and generated-state PR #211 merged, the same read-only
command was rerun from main `9a35bac2e9d47e5699de8bead4029c95bb16a0cf` at
15:56 UTC. It returned the same current/target displays and conflict flags.
`python3 -m tools.repo_knowledge verify` returned `VERIFY: 0 findings` for
the merged generated state.

Before merge, the focused shell suite passed 187/187, display registry,
manager API 5/5, manager protocol 16/16, manager service 7/7, and the
multi-guest lifecycle test. Exact-main CI passed again after merge. These
tests used isolated fixtures; no live guest session was changed.

At 15:52 UTC, installed `tx status db|ub|alp --json` still reported v2.0.0,
READY, X11 running and PulseAudio route-ready for the same guest PIDs
18218/14129/26946. No desktop or Android service was restarted. The website
deployment for main commit `7b7ea43` succeeded in run `43456239621`; the
homepage and `/docs/v3/API-DESIGN.html` returned HTTP 200 and included the
updated manager/display status and schema link.
