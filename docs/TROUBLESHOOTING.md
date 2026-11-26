---
title: "Troubleshooting"
description: "Common ternux failures classified by symptom, with evidence-led checks and safe repair paths for rendering, sessions, audio and networking."
lang: "en"
alt_url: "/bn/docs/TROUBLESHOOTING.html"
---

The table maps common symptoms to likely causes and checks. A symptom can have
more than one cause, so collect the named evidence before applying a repair.

| Symptom | Likely cause | Fix |
|---|---|---|
| Desktop dies silently, or `[Process completed (signal 9)]` | Android process policy, memory pressure, or OEM battery management | [The desktop dies silently](#the-desktop-dies-silently) |
| Xfce/X11 becomes slow or stops responding after opening Termux:X11 | Android may deprioritize Termux while its X11 companion app is in front | [X11 slows down or stalls](#x11-slows-down-or-stalls) |
| Black/empty Termux:X11 window | X11 app not opened, or stale socket | [Black screen in Termux:X11](#black-screen-in-termuxx11) |
| `renderer string: llvmpipe` | Software fallback — GPU route not active | [Renderer says llvmpipe](#renderer-says-llvmpipe) |
| `lost connection to rendering server` while starting XFCE | VirGL socket is unavailable to the isolated guest, or its Mesa VirGL preflight fails | [VirGL fails during XFCE startup](#virgl-fails-during-xfce-startup) |
| No sound in the desktop | PulseAudio bridge not running | [No audio](#no-audio) |
| No internet inside Debian | DNS not inherited over PRoot | [No network in the container](#no-network-in-the-container) |
| `Waiting for Termux-X11 display socket…` forever | Display :0 never appeared | [Display never appears](#display-never-appears) |
| `Error: unrecognized option: '-c'` when starting | Old launcher against newer proot-distro | [proot-distro says option -c is unrecognized](#proot-distro-says-option--c-is-unrecognized) |
| `proot-distro: Argument list too long` during Debian setup | The desktop asset payload exceeded Linux's per-argument limit | [proot-distro argument list is too long](#proot-distro-argument-list-is-too-long) |
| `apt` install fails on some packages | package/repository mismatch for the Debian release | [apt failures](#apt-failures) |
| `awk: cannot open "Manager"` during the Debian + Xfce phase | package-manager desktop-entry command lost quoting around the spaced Synaptic name | [Desktop package entry fails](#desktop-package-manager-entry-fails) |
| `ternux install --resume` skips a guest that was removed | stale per-guest phase metadata from an older install | [Resume after removing a guest](#resume-after-removing-a-guest) |
| `pkg upgrade` errors on `openssl.cnf`, then **every** install fails | dpkg conffile prompt with closed stdin | [openssl.cnf conffile cascade](#opensslcnf-conffile-cascade) |
| `No command $ found` after pasting the install command | copied text included the display-only `$` prompt | [Pasted command starts with $](#pasted-command-starts-with) |
| `curl: CANNOT LINK … SSL_set_quic_tls_transport_params` | partial upgrade — curl/libngtcp2 newer than openssl | [curl cannot link after an upgrade](#curl-cannot-link-after-an-upgrade) |
| Everything was fine, now it's broken after an upgrade | Mesa packages got replaced | [After an upgrade the GPU path is gone](#after-an-upgrade-the-gpu-path-is-gone) |
| Installer dashboard flickers, log lines overlap the frame | An installer older than the current renderer, or a terminal whose size cannot be measured | [The installer screen flickers or the frame is broken](#the-installer-screen-flickers-or-the-frame-is-broken) |

---

## proot-distro argument list is too long

**Symptom:** the Debian + Xfce phase stops with
`proot-distro: Argument list too long` after the guest has been created.

**Cause:** older installer code passed the compressed desktop asset bundle as
one `sh -c` argument, exceeding Linux's per-argument size limit.

**Fix:** rerun the one-command installer from the README. The current installer
streams that setup script into the guest over stdin and automatically resumes
the incomplete guest from the failed phase. Do not uninstall or remove Debian.

---

## Resume after removing a guest

**Symptom:** an interrupted install resumes against a guest that was removed,
or the selected distro still points at an absent container.

**Fix:** remove the stale Ternux registration through its managed command, then
start a fresh install. This also clears the old phase and workspace records:

```bash
ternux distro uninstall ubuntu --yes
ternux install --distro ubuntu
```

Ternux checks that the PRoot container still exists before it skips recorded
guest phases. Do not remove a managed guest with `proot-distro remove`; that
bypasses Ternux's profile and session cleanup.

---

## The desktop dies silently

**Symptom:** Xfce4 was running fine, then the session (or a long build) dies
with no error message. Termux may print
`[Process completed (signal 9) - press Enter]`.

**Cause:** Android 12+ monitors and limits app-spawned child processes. A PRoot
desktop can create many such processes (Xfce4, D-Bus, build workers and PRoot),
so Android may terminate part of the session. Exact thresholds and settings vary
by Android release and OEM; signal 9 can also come from memory pressure or vendor
battery management.

First set Termux and Termux:X11 battery use to **Unrestricted**, keep Termux in the
foreground while testing, avoid extreme build parallelism, and retry after a
cool reboot. If the termination persists and diagnostics point to child-process
restrictions, use the control available on your Android release:

- **Android 14+ (no PC needed):**
  Settings → About phone → tap *Build number* 7× → Developer options →
  enable **"Disable child process restrictions"** if the OS exposes it, then
  follow any reboot prompt.
- **ADB shell or Shizuku:** use the [Android phantom-process controls guide](ANDROID-PHANTOM-PROCESS.md)
  for native Termux ADB, Shizuku `rish`, computer USB/wireless ADB, exact
  version caveats, verification, and rollback. Shizuku's `rish` shell runs the
  system command directly; it does not create an ADB transport.
- **Rooted:**
  ```bash
  su -c "settings put global settings_enable_monitor_phantom_procs false"
  ```
These controls are advanced, may be renamed/blocked by an OEM, and change a
system-wide protection against runaway background work. Persistent DeviceConfig
sync mode also affects unrelated DeviceConfig settings; record and restore the
previous mode. Follow the guide's read-before-write, verification, and rollback
steps. `ternux doctor` reports the settings it can read, but it cannot
distinguish every OEM process killer.

---

## X11 slows down or stalls

**Symptom:** the desktop becomes sluggish or stops responding after Termux:X11
is brought to the foreground, especially while Termux itself is in the
background.

**Likely cause:** Android can give Termux less CPU time when another app is on
screen. The [Termux:X11 project documents this scheduling effect](https://github.com/termux/termux-x11#avoiding-slowdowns)
and provides a shared-UID APK variant to avoid it. That variant only works with
the GitHub-signed Termux app; do not install it over an F-Droid or Play Store
Termux installation.

**Checks and mitigations:**

1. Set battery use for both Termux and Termux:X11 to **Unrestricted**. On
   Xiaomi devices, also allow Termux background activity/autostart if those
   controls are available.
2. Keep the device awake during long sessions. Termux:Boot can run a startup
   script and `termux-wake-lock` can prevent sleep, but Boot does not fix a
   live X11/GPU hang or change Android's CPU scheduling between separate apps.
   See the [Termux:Boot instructions](https://github.com/termux/termux-boot#how-to-use).
3. Capture `tx status --json`, `tx info --json`, and `tx logs desktop show debian`
   while the issue is present. If the X11 activity is black or its server is
   unresponsive, `tx restart debian` restarts the managed session and closes
   its current windows.

If the renderer remains hardware accelerated and the X11 server responds while
the desktop still freezes, collect a Termux:X11 debug log using the [upstream
debug instructions](https://github.com/termux/termux-x11#logs). A short healthy
test does not rule out an intermittent Android scheduler or GPU-driver stall.

---

## Ctrl+plus/minus does not zoom window content

**Symptom:** pressing Ctrl+- or Ctrl+plus does not change text size in the
focused terminal or another X11 application.

**Cause:** Ternux watches these keys to keep the XFCE Terminal font preference
persistent. An asynchronous X11 keyboard grab can consume the shortcut before
the focused application receives it. This is corrected in the v2.0.1
release; older installed helpers need the matching release update and desktop
restart.

**Fix:** update Ternux, then restart the managed desktop with `tx restart
debian` (replace `debian` with the active guest). In XFCE Terminal, use Ctrl+-
to zoom out and Ctrl+Shift+= to zoom in; the plus sign shares the `=` key on
many keyboards. Other applications receive the shortcut and apply their own
zoom behavior if they support it. App-specific key bindings can differ.

---

## Black screen in Termux:X11

**Symptom:** `tx start` runs, but Termux:X11 shows a black or empty window.

**Cause (in order of likelihood):**

1. The Termux:X11 **app was never opened once** — Android needs that first
   launch to allow the display service.
2. A **stale socket** from a crashed session — `tx start` normally cleans these, but
   a hard kill can leave them.
3. Xfce4 crashed after the display started.

**Fix:**

```bash
killx
# open Termux:X11 once (the app itself), then:
tx start
```

If it still fails, run `ternux repair` — it checks the Termux-side display
package and regenerates a missing, broken or backend-mismatched launcher. Then
use `ternux verify` to inspect the Debian-side desktop prerequisites.

---

## VirGL fails during XFCE startup

**Symptom:** `tx start` fails with `lost connection to rendering server` and
`startxfce4` aborts. The `X server already running` line can appear because
Termux:X11 already owns that display; check the following VirGL and XFCE lines
for the actual failure.

**Cause:** VirGL's host socket must be visible inside the isolated guest. Some
Debian Mesa builds also fail the VirGL `glxinfo` preflight.

**Fix:** Update Ternux, then run `tx repair` to regenerate the managed launcher.
It binds only the VirGL socket into the guest and tests the renderer before
starting XFCE. If VirGL fails, the desktop starts with Mesa's `llvmpipe`
software renderer so the session remains usable; graphics-heavy apps will be
slower. This check is limited to VirGL (`virpipe`) sessions; it does not switch
a Zink/Turnip session to software. PowerVR and other non-Adreno devices use the
shared VirGL route here, but whether VirGL reaches the phone GPU depends on the
Android host renderer. Read the exact probe and XFCE output with
`tx logs desktop`.

---

## Renderer says llvmpipe

**Symptom:** the desktop works, but `glxinfo | grep "renderer string"` says
`llvmpipe`.

**Cause:** Mesa fell back to software rendering. The accelerated path is
missing or was replaced:

1. **Zink route:** the Turnip driver files were never installed, were removed,
   or an `apt upgrade` replaced the held Mesa packages.
2. **VirGL route:** `virgl_test_server_android` did not start (the launcher
   warns about exactly this).
3. The forced `--backend zink` on a device without `/dev/kgsl-3d0` — the
   preflight rejects this, so if you got here, check that the install state
   matches your hardware.

**Fix:**

```bash
# 1. Select the intended route. "auto" uses /dev/kgsl-3d0 detection.
ternux backend set auto
# or: ternux backend set zink    # Adreno with /dev/kgsl-3d0 only
# or: ternux backend set virgl

# 2. Apply it. Repair restores missing validated Turnip targets when needed
#    and regenerates a launcher that is missing, broken, or for another route.
ternux repair

# 3. If on Zink, inspect the installed targets and package holds:
db
ls -l /usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so
sudo apt-mark showhold
exit

# 4. Restart the session and re-check:
ternux stop && ternux start
#    inside desktop:  glxinfo -B
```

Do not use `bash install.sh --resume` to replace these artifacts: resume skips
GPU and launcher phases already recorded as complete. If the validated Turnip
download is unreachable or incompatible, fall back deliberately with
`ternux backend set virgl && ternux repair`, then verify what VirGL actually
provides on that device.

---

## No audio

**Symptom:** desktop runs, but no sound. (Or: sound stopped after an update.)

**Fix, in order:**

```bash
# 1. Restart the audio bridge — the launcher rebuilds it every start:
killx && tx start

# 2. If still silent, check the host-side daemon in Termux:
pulseaudio --start --exit-idle-time=-1
pactl info | head -n 3

# 3. Check the Debian client config:
db
cat ~/.config/pulse/client.conf    # expect: default-server = tcp:127.0.0.1:4713
pactl info                          # should report the same server
```

*Why it breaks:* the bridge is a TCP connection between container and host.
If the host-side PulseAudio dies (killed, or never restarted after a crash),
the container keeps a config pointing at a port nobody listens on.

---

## No network in the container

**Symptom:** `apt update` works in Termux but fails inside Debian.

**Cause:** PRoot inherits the host's network but not always its resolver
configuration — DNS is the usual casualty.

First confirm the host can resolve names, then inspect the guest rather than
immediately replacing its configuration:

```bash
# Termux host
getent hosts deb.debian.org
getprop | grep -i '\[net\..*dns'

# Debian guest
db
cat /etc/resolv.conf
getent hosts deb.debian.org
```

If Android resolves names but the guest file is empty or invalid, stop and
restart the PRoot session first. As a temporary diagnostic only, set
`DNS_SERVER` to a resolver you trust (for example, one supplied by your
router/provider) and retry:

```bash
DNS_SERVER='REPLACE_WITH_A_TRUSTED_IP'
printf 'nameserver %s\n' "$DNS_SERVER" | sudo tee /etc/resolv.conf
getent hosts deb.debian.org
sudo apt update
```

The file may later be regenerated. A public resolver changes who receives
your DNS queries, so ternux does not silently force one.

---

## Display never appears

**Symptom:** the launcher prints `Waiting for Termux-X11 display socket…`
then times out after 30 s.

**Cause:** the `termux-x11` binary exited before creating its socket — almost
always because the Termux:X11 app has never been opened, or was force-stopped
by Android.

**Fix:**

1. Open the Termux:X11 app, let it sit for a second, switch back to Termux.
2. `killx && tx start`
3. Still stuck? Reinstall the maintained Termux-side package:
   `pkg install x11-repo -y && pkg reinstall termux-x11-nightly -y`

---

<h2 id="proot-distro-says-option--c-is-unrecognized">proot-distro says option -c is unrecognized</h2>

**Symptom:** running `tx start` prints `Error: unrecognized option: '-c'.` followed
by the proot-distro usage screen.

**Cause:** proot-distro **5.x requires a `--` separator** between the
container name and the command it should run inside. The launcher script
from **older ternux installs** runs `proot-distro login debian … bash -c '…'`
without that `--`, so proot-distro tries to read `-c` as its own flag.

**Fix — regenerate the launcher with the current, fixed installer:**

```bash
# Regenerate the launcher with the persisted user, locale and backend:
ternux repair
```

`bash install.sh --resume` is not a launcher replacement mechanism when the
launcher phase is already recorded as complete.

Do not patch only the visible `-c`: current launchers also repeat each
`proot-distro --env VAR=VALUE` argument correctly. Regenerate the complete file,
then start the desktop again:

```bash
tx start
```

---

<h2 id="pasted-command-starts-with">Pasted command starts with $</h2>

**Symptom:** you paste the install command and the shell answers
`No command $ found, did you mean: …` — the paste begins with a `$`.

**Cause:** the `$` on the site is a *display* prompt. If you select the
command line by hand, the selection can include it (and the blinking cursor
block). The shell then tries to run a command literally named `$`.

**Fix:** use the **copy button** (or tap the command line) — the site copies
exactly the command, with the prompt drawn by CSS so it can never be
selected. If you still paste a `$`, just delete it — only the first character
— and press Enter again.

---

## curl cannot link after an upgrade

**Symptom:** running curl prints
`CANNOT LINK EXECUTABLE "curl": cannot locate symbol "SSL_set_quic_tls_transport_params" referenced by …/libngtcp2_crypto_ossl.so`.

**Cause:** a **partial upgrade** — `libngtcp2`/curl were upgraded while
`openssl` stayed older (typically right after an interrupted upgrade; on
older installer versions openssl was exactly the package that got stuck on
the conffile prompt above). curl then needs a symbol the installed openssl
does not export.

**Fix — two options:**

```bash
# Option A: finish the complete Termux package upgrade:
apt update && apt full-upgrade -y

# Option B: download and run the latest installer with curl/wget fallback:
pkg update -y && pkg upgrade -y && pkg install -y curl wget && bash -c 's=$(mktemp) && (curl -fsSL https://raw.githubusercontent.com/soobujmiah/ternux/a53b254e5dc50f64e7c1910c81d7bc0fe6fcb3bf/install.sh -o "$s" || wget -qO "$s" https://raw.githubusercontent.com/soobujmiah/ternux/a53b254e5dc50f64e7c1910c81d7bc0fe6fcb3bf/install.sh) && bash "$s"; r=$?; rm -f "$s"; exit "$r"'
```

`pkg update` refreshes package indexes; it does not finish an interrupted
package upgrade. If both curl and wget are unusable, run Option A directly in
Termux, then retry the installer. If curl still cannot start after the full
upgrade, reinstall the linked packages from the refreshed index:

```bash
apt install --reinstall curl libcurl openssl openssl-tool
```

If Termux setup succeeded but Debian desktop setup stopped, rerun the source
installer command above. It downloads current code and resumes the incomplete
guest from the failed phase; do not remove the Debian guest.

`ternux repair` uses the Termux `apt-get` wrapper to refresh indexes and run a
full upgrade when curl is missing or cannot start, then verifies curl again.
The standalone installer also checks that curl can start and falls back to
wget when curl is broken or cannot fetch its pinned source archive.

---

<h2 id="opensslcnf-conffile-cascade">openssl.cnf conffile cascade</h2>

**Symptom:** during `pkg upgrade` (or a piped install) you see
`*** openssl.cnf (Y/I/N/O/D/Z) [default=N] ?` followed by
`end of file on stdin at conffile prompt`, and afterwards **every** `pkg
install` fails with the same error — even for unrelated packages.

**Cause:** dpkg hit a conffile prompt while stdin was closed, so it could not
answer. The package was left unconfigured and the package system stayed
**broken**; every later apt/dpkg operation re-attempts the pending configure
and fails the same way. (`termux-x11: unable to locate` right after is
usually the same cascade: the x11-repo package never actually installed.)

**Fix:**

```bash
# 1. Repair the broken state — auto-keep the old conffile, no prompts:
dpkg --configure -a --force-confold --force-confdef

# 2. Verify it is clean (should print nothing):
dpkg --configure -a --force-confold --force-confdef

# 3. Continue the interrupted installer; recorded successful phases are skipped:
bash install.sh --resume

# For an installation that had already completed, repair managed artifacts instead:
ternux repair
```

*Why this happens at all:* Android shells are often piped/non-interactive, so
dpkg has no terminal to ask on. The ternux installer passes
`--force-confold --force-confdef` to every apt operation and repairs broken
state automatically, so this cascade no longer occurs — the fix above is for
manual installs or older versions.

---

## apt failures

**Symptom:** an `apt install` group fails because one package name is missing
or unavailable for the guest's Debian release.

**Cause:** package names and repository components change across Debian
releases. Adding a component to `/etc/apt/sources.list` with a blind `sed` is
also unreliable on systems that use deb822 `.sources` files.

**Fix:** identify the package that actually failed, inspect policy, and install
the maintained base alternatives used by ternux:

```bash
db
. /etc/os-release; printf '%s %s\n' "$ID" "$VERSION_CODENAME"
sudo apt update
apt-cache policy unrar-free 7zip polkitd
sudo apt install -y unrar-free 7zip polkitd
```

If a separate application specifically requires non-free software, review the
guest's files under `/etc/apt/sources.list*` and Debian's repository guidance
for that exact release before changing components. Do not replace sources just
to make an obsolete package name resolve.

---

<h2 id="desktop-package-manager-entry-fails">Desktop package entry fails during the Debian + Xfce phase</h2>

**Symptom:** Synaptic and its dependencies install successfully, then the
required Debian + Xfce phase fails with:

```text
awk: cannot open "Manager" (No such file or directory)
[FAIL] Desktop package installation failed.
```

**Cause:** the generated guest setup script rewrote the Synaptic desktop entry
with an unquoted `Synaptic Package Manager` value. The shell split the name into
separate `awk` arguments, so the phase stopped before registering the desktop
user and completing setup.

**Fix:** run the current pinned one-command installer in the README again. It
will rerun the incomplete Debian phase and reuse packages already installed;
do not remove the guest or start from a clean install. If the updated installer
has already installed the current host CLI, this also resumes the phase:

```bash
ternux install --resume
```

When the phase completes, check the guest and start it:

```bash
ternux verify db
tx start db
```

If the same error remains, capture `ternux logs show` and the exact installer
phase. Do not paste passwords or private tokens.

---

## After an upgrade the GPU path is gone

**Symptom:** renderer was `zink … Turnip`, then after `apt upgrade` it reads
`llvmpipe`.

**Cause:** the held Mesa packages were unheld (or the hold was applied after
an upgrade had already replaced them).

**Fix:** re-run `ternux repair` (re-applies the driver and the holds), then
verify with `glxinfo`. To upgrade Mesa deliberately and keep acceleration,
follow the unhold → upgrade → rehold → verify sequence in
[Configuration](CONFIGURATION.html#held-mesa-packages-zink-route).

A hold is not a permanent guarantee. `apt install --reinstall mesa-vulkan-drivers`
resets that package's selection to `install`, which drops the hold without
reporting it — measured on 2026-10-13, where the other four Mesa holds survived
because they were never named on the command line. For a layout that keeps the
driver even when the package is reinstalled, and needs no holds at all, see
[Graphics persistence](GRAPHICS-PERSISTENCE.html).

---

## The installer screen flickers or the frame is broken

**Symptom:** during `install.sh` the framed dashboard repaints over and over,
log lines overlap or wrap through the borders, and the window scrolls so fast
that nothing can be read.

**Cause:** three separate renderer faults, all fixed in the current installer.
The frame used the full terminal width, so writing the last column armed the
terminal's pending-wrap state and the following newline pushed every row one
cell out of place. Carriage-return progress output (`apt`, `dpkg`,
`proot-distro`, `curl`) was expanded into one new log line per update. And when
the terminal size could not be measured, the resize check compared a clamped
value against a raw one, decided the terminal had changed, and repainted the
whole screen several times per second.

**Fix — update, then pick a renderer if you still want a quieter screen:**

```bash
# 1. Re-run the current installer (completed phases are skipped).
bash install.sh --resume

# 2. Or choose the renderer explicitly.
bash install.sh --plain      # plain scrolling log, no full-screen dashboard
bash install.sh --no-anim    # keep the dashboard, freeze the spinner
TERNUX_UI=off bash install.sh   # no framing at all, raw command output
```

The renderer selects itself: the dashboard needs an interactive terminal with
colour, at least 39 usable columns and at least 13 rows. Pipes, `curl | bash`
without a TTY, `TERM=dumb`, `--quiet` and `--json` all fall back to plain
scrolling output automatically. The complete reference is
[Installation → The installer screen](INSTALLATION.html#the-installer-screen).

Nothing is ever lost to the screen. Every line the phases produce is appended to
the log file, including the lines a burst summarises on screen as
`... +N more lines`:

```bash
ternux logs tail          # follow the live install log
ternux logs show          # read the whole log
```

---

## Nuclear option: clean reinstall

```bash
ternux uninstall all             # review and confirm irreversible deletion
# or interactively: ternux uninstall, then choose 5
bash install.sh                  # fresh install from a reviewed checkout
```

Deleting the container destroys **all data inside it** — pull anything
valuable out first (see [Usage → Backups](USAGE.html#backups)).

---

## Reporting a problem

When opening an [issue](https://github.com/soobujmiah/ternux/issues), include
read-only evidence — never paste licence keys, tokens, or private files:

```bash
uname -m
getprop ro.product.manufacturer; getprop ro.product.model
getprop ro.build.version.release
ternux doctor --json           # machine-readable diagnostics
ternux doctor extensions --json  # health of installed extensions only
ternux info --json             # full device profile
db -c 'glxinfo | grep "renderer string"; vulkaninfo --summary | grep -i driverName'
```

---

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · Apache-2.0*
