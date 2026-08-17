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
| Black/empty Termux:X11 window | X11 app not opened, or stale socket | [Black screen in Termux:X11](#black-screen-in-termuxx11) |
| `renderer string: llvmpipe` | Software fallback — GPU route not active | [Renderer says llvmpipe](#renderer-says-llvmpipe) |
| No sound in the desktop | PulseAudio bridge not running | [No audio](#no-audio) |
| No internet inside Debian | DNS not inherited over PRoot | [No network in the container](#no-network-in-the-container) |
| `Waiting for Termux-X11 display socket…` forever | Display :0 never appeared | [Display never appears](#display-never-appears) |
| `Error: unrecognized option: '-c'` when starting | Old launcher against newer proot-distro | [proot-distro says option -c is unrecognized](#proot-distro-says-option--c-is-unrecognized) |
| `apt` install fails on some packages | package/repository mismatch for the Debian release | [apt failures](#apt-failures) |
| `pkg upgrade` errors on `openssl.cnf`, then **every** install fails | dpkg conffile prompt with closed stdin | [openssl.cnf conffile cascade](#opensslcnf-conffile-cascade) |
| `No command $ found` after pasting the install command | copied text included the display-only `$` prompt | [Pasted command starts with $](#pasted-command-starts-with) |
| `curl: CANNOT LINK … SSL_set_quic_tls_transport_params` | partial upgrade — curl/libngtcp2 newer than openssl | [curl cannot link after an upgrade](#curl-cannot-link-after-an-upgrade) |
| Everything was fine, now it's broken after an upgrade | Mesa packages got replaced | [After an upgrade the GPU path is gone](#after-an-upgrade-the-gpu-path-is-gone) |

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
  enable **"Disable child process restrictions"** → reboot.
- **Android 12L/13 (needs a PC or root):**
  ```bash
  adb shell settings put global settings_enable_monitor_phantom_procs false
  ```
- **Rooted:**
  ```bash
  su -c "settings put global settings_enable_monitor_phantom_procs false"
  ```
- **Android 12 exactly** also needs:
  ```bash
  adb shell "/system/bin/device_config set_sync_disabled_for_tests persistent"
  adb shell "/system/bin/device_config put activity_manager max_phantom_processes 2147483647"
  ```

These controls are advanced, may be renamed/blocked by an OEM, and change a
system-wide protection against runaway background work. Record the original
setting, change only what your OS exposes, reboot, and reverse the change if it
causes instability or abnormal battery drain. `ternux doctor` reports the
settings it can read, but it cannot distinguish every OEM process killer.

---

## Black screen in Termux:X11

**Symptom:** the `x` command runs, Termux:X11 shows a black or empty window.

**Cause (in order of likelihood):**

1. The Termux:X11 **app was never opened once** — Android needs that first
   launch to allow the display service.
2. A **stale socket** from a crashed session — `x` normally cleans these, but
   a hard kill can leave them.
3. Xfce4 crashed after the display started.

**Fix:**

```bash
killx
# open Termux:X11 once (the app itself), then:
x
```

If it still fails, run `ternux repair` — it checks the Termux-side display
package and regenerates a missing, broken or backend-mismatched launcher. Then
use `ternux verify` to inspect the Debian-side desktop prerequisites.

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
killx && x

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
2. `killx && x`
3. Still stuck? Reinstall the maintained Termux-side package:
   `pkg install x11-repo -y && pkg reinstall termux-x11-nightly -y`

---

<h2 id="proot-distro-says-option--c-is-unrecognized">proot-distro says option -c is unrecognized</h2>

**Symptom:** running `x` prints `Error: unrecognized option: '-c'.` followed
by the proot-distro usage screen.

**Cause:** proot-distro **5.x requires a `--` separator** between the
container name and the command it should run inside. The `~/x.sh` launcher
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
x
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
# Option A: let pkg bring everything back in sync:
pkg upgrade -y -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef
pkg reinstall -y curl openssl openssl-tool libngtcp2 libnghttp3

# Option B: skip curl entirely and fetch the installer with wget
# (wget links openssl directly and usually still works):
wget -qO- https://soobujmiah.github.io/ternux/install.sh | bash
```

> **Already upgraded curl and it STILL fails?** The missing symbol is
> exported by **openssl**, not curl — a newer curl against an older openssl
> keeps failing no matter how many times curl is reinstalled. The whole
> chain must move together: the `pkg reinstall` line above (or a full
> `pkg upgrade -y` to completion) is the deterministic fix.

The installer detects a broken curl during preflight and upgrades the entire
chain (`curl openssl openssl-tool libngtcp2 libnghttp3`) on its own, so
Option B alone is enough to get going.

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

## After an upgrade the GPU path is gone

**Symptom:** renderer was `zink … Turnip`, then after `apt upgrade` it reads
`llvmpipe`.

**Cause:** the held Mesa packages were unheld (or the hold was applied after
an upgrade had already replaced them).

**Fix:** re-run `ternux repair` (re-applies the driver and the holds), then
verify with `glxinfo`. To upgrade Mesa deliberately and keep acceleration,
follow the unhold → upgrade → rehold → verify sequence in
[Configuration](CONFIGURATION.html#held-mesa-packages-zink-route).

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
ternux info --json             # full device profile
db -c 'glxinfo | grep "renderer string"; vulkaninfo --summary | grep -i driverName'
```

---

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · MIT*
