---
title: "Troubleshooting"
description: "Every common ternux failure, classified by symptom, with the cause and the exact fix — renderer falls back to software, sessions die, audio, network."
lang: "en"
alt_url: "/bn/docs/TROUBLESHOOTING.html"

---

# Troubleshooting

Every symptom below has been seen in the wild. Work top to bottom: the table
maps symptom → likely cause → fix, and the sections give the full picture.

| Symptom | Likely cause | Fix |
|---|---|---|
| Desktop dies silently, or `[Process completed (signal 9)]` | Android phantom process killer | [The desktop dies silently](#the-desktop-dies-silently) |
| Black/empty Termux:X11 window | X11 app not opened, or stale socket | [Black screen in Termux:X11](#black-screen-in-termuxx11) |
| `renderer string: llvmpipe` | Software fallback — GPU route not active | [Renderer says llvmpipe](#renderer-says-llvmpipe) |
| No sound in the desktop | PulseAudio bridge not running | [No audio](#no-audio) |
| No internet inside Debian | DNS not inherited over PRoot | [No network in the container](#no-network-in-the-container) |
| `Waiting for Termux-X11 display socket…` forever | Display :0 never appeared | [Display never appears](#display-never-appears) |
| `apt` install fails on some packages | Debian non-free not enabled | [apt failures](#apt-failures) |
| `pkg upgrade` errors on `openssl.cnf`, then **every** install fails | dpkg conffile prompt with closed stdin | [openssl.cnf conffile cascade](#opensslcnf-conffile-cascade) |
| `No command $ found` after pasting the install command | copied text included the display-only `$` prompt | [Pasted command starts with $](#pasted-command-starts-with) |
| `curl: CANNOT LINK … SSL_set_quic_tls_transport_params` | partial upgrade — curl/libngtcp2 newer than openssl | [curl cannot link after an upgrade](#curl-cannot-link-after-an-upgrade) |
| Everything was fine, now it's broken after an upgrade | Mesa packages got replaced | [After an upgrade the GPU path is gone](#after-an-upgrade-the-gpu-path-is-gone) |

---

## The desktop dies silently

**Symptom:** Xfce4 was running fine, then the session (or a long build) dies
with no error message. Termux may print
`[Process completed (signal 9) - press Enter]`.

**Cause:** Android 12+ enforces the **phantom process killer**: once ~32
background child processes exist system-wide — or one process uses excessive
CPU — Android silently SIGKILLs them. A PRoot desktop runs dozens of
processes (Xfce4 + dbus + PulseAudio + proot), so it trips the limit easily.

**Fix — pick the one that matches your Android version:**

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

*Why this is a device-level trade-off:* the limit protects Android from
runaway background apps generally. Disabling it is what the Termux community
recommends for exactly this workload; most people notice no downside.
`bash install.sh --doctor` re-checks this for you anytime.

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

If it still fails, run `bash install.sh --doctor --fix` — it re-checks the
display package, the launcher and the container core.

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
# 1. Re-run the GPU phase (this re-resolves, re-downloads, re-verifies):
bash install.sh --resume

# 2. If on Zink, confirm the files exist and packages are held:
db
ls -l /usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so
sudo apt-mark showhold
exit

# 3. Restart the session and re-check:
killx && x
#    inside desktop:  glxinfo | grep "renderer string"
```

If the download fails (GitHub unreachable from your network), fall back
deliberately: `bash install.sh --backend virgl --resume`.

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

**Fix inside the container:**

```bash
db
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf >/dev/null
sudo apt update
```

If you prefer DHCP/Android's resolver, use your router's IP
(usually `192.168.0.1` / `192.168.1.1`) instead of `1.1.1.1`.

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
3. Still stuck? Reinstall the display package:
   `pkg reinstall termux-x11-nightly -y`

---

## Pasted command starts with $

**Symptom:** you paste the install command and the shell answers
`No command $ found, did you mean: …` — the paste begins with a `$`.

**Cause:** the `$` on the site is a *display* prompt. If you select the
command line by hand, the selection used to include it (and the blinking
cursor block). The shell then tries to run a command literally named `$`.

**Fix:** use the **copy button** (or tap the command line) — since v1.1.3
the site copies exactly the command, with the prompt drawn by CSS so it can
never be selected. If you still paste a `$`, just delete it — only the first
character — and press Enter again.

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
> `pkg upgrade -y` to completion — you may have other interrupted upgrades)
> is the deterministic fix.

The installer (v1.1.4+) detects a broken curl during preflight and upgrades
the entire chain (`curl openssl openssl-tool libngtcp2 libnghttp3`) on its
own, so Option B alone is enough to get going.

---

## openssl.cnf conffile cascade

**Symptom:** during `pkg upgrade` (or a piped install) you see
`*** openssl.cnf (Y/I/N/O/D/Z) [default=N] ?` followed by
`end of file on stdin at conffile prompt`, and afterwards **every** `pkg
install` fails with the same error — even for unrelated packages.

**Cause:** dpkg hit a conffile prompt while stdin was closed, so it could not
answer. The package was left unconfigured and the package system stayed
**broken**; every later apt/dpkg operation re-attempts the pending configure
and fails the same way. (`termux-x11-nightly: unable to locate` right after is
usually the same cascade: the x11-repo package never actually installed.)

**Fix:**

```bash
# 1. Repair the broken state — auto-keep the old conffile, no prompts:
dpkg --configure -a --force-confold --force-confdef

# 2. Verify it is clean (should print nothing):
dpkg --configure -a --force-confold --force-confdef

# 3. Resume the installer:
bash install.sh --resume
```

*Why this happens at all:* Android shells are often piped/non-interactive, so
dpkg has no terminal to ask on. The ternux installer (v1.1.0+) now passes
`--force-confold --force-confdef` to every apt operation and repairs broken
state automatically, so this cascade no longer occurs — the fix above is for
manual installs or older versions.

---

## apt failures

**Symptom:** `apt install` fails on `rar`, `p7zip-rar`, `policykit-1` or a
whole group of packages.

**Cause:** those packages live in Debian's **non-free** component, which the
default PRoot Debian rootfs does not enable. `polkitd` vs `policykit-1` is a
naming difference between Debian releases.

**Fix:** the ternux installer already treats these as best-effort. If *you*
need them:

```bash
db
sudo sed -i 's/ main$/ main contrib non-free non-free-firmware/' /etc/apt/sources.list
sudo apt update && sudo apt install -y rar unrar p7zip-full
```

---

## After an upgrade the GPU path is gone

**Symptom:** renderer was `zink … Turnip`, then after `apt upgrade` it reads
`llvmpipe`.

**Cause:** the held Mesa packages were unheld (or the hold was applied after
an upgrade had already replaced them).

**Fix:** re-run `bash install.sh --resume` (re-applies the driver and the
holds), then verify with `glxinfo`. To upgrade Mesa deliberately and keep
acceleration, follow the unhold → upgrade → rehold → verify sequence in
[Configuration](CONFIGURATION.html#held-mesa-packages-zink-route).

---

## Nuclear option: clean reinstall

```bash
bash install.sh --uninstall     # choose 4: delete the container
rm -f ~/x.sh ~/.ternux-state
bash install.sh                 # fresh install
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
bash install.sh --doctor
db -c 'glxinfo | grep "renderer string"; vulkaninfo --summary | grep -i driverName'
```

---

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · MIT*
