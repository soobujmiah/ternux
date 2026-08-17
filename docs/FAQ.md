---
title: "FAQ"
description: "Straight answers about ternux: root, safety, the Play Store Termux, storage, battery, gaming, privacy and everything people actually ask."
lang: "en"
alt_url: "/bn/docs/FAQ.html"

---

# FAQ

---

## Is root required? Why not just root my phone?

No — and deliberately not. Root-based setups may require bootloader/device
changes, can affect verified-boot, banking or DRM behavior, and grant a much
larger blast radius to mistakes or untrusted code. The exact consequences vary
by device and vendor.

ternux uses **PRoot**, which emulates a root-like filesystem and identity in
userspace without granting Android root. This limits privileged-system impact,
but PRoot is not a security boundary: code can access paths available to Termux
or explicitly bound into Debian. Review commands and back up valuable data.

## Will this damage or "brick" my phone?

The installer does not modify the bootloader or Android system partitions and
does not require root, so a normal install failure is not expected to brick the
phone. It does change Termux packages/configuration, shell files and the Debian
container; bugs, untrusted commands or manual system-setting changes can still
cause data loss or disruption. Back up the container and important shared files.

## Why can't I use the Termux from the Play Store?

Google Play currently carries a separate experimental Android 11+ branch with
known missing functionality and bugs. This guide follows the main releases from
[F-Droid](https://f-droid.org/en/packages/com.termux/) or
[GitHub](https://github.com/termux/termux-app/releases). Whichever source you
choose, install Termux and every plugin from that same source so the signing
keys match.

## How much storage will it really use?

Plan for **about 12 GB free** for the base installation and working room. The
actual result varies with Debian package versions, package caches and your
filesystem. Development build trees, Blender, media tools and especially model
files can add several more gigabytes. Check rather than guessing:

```bash
df -h "$HOME"
du -sh "$PREFIX/var/lib/proot-distro/installed-rootfs/debian" 2>/dev/null
```

## Does it work on non-Qualcomm phones?

They can use the **VirGL** compatibility route, but support, features and speed
vary by GPU, Android build and renderer package. Do not assume that an open
desktop is accelerated: run `glxinfo -B`. `llvmpipe` means CPU rendering.
Ternux's submitted measurements cover one Adreno/Zink/Turnip device, not all
non-Qualcomm devices.

## Why is my renderer `llvmpipe`? Is that bad?

`llvmpipe` is Mesa's software renderer: the desktop runs, but every GL app
renders on the CPU — slow and battery-hungry. It means the accelerated path
is not active. See
[Troubleshooting → renderer says llvmpipe](TROUBLESHOOTING.html#renderer-says-llvmpipe).

## Can I play PC games with this?

Not the way you might hope. ternux is a desktop environment on phone
hardware, not a compatibility layer for Windows games. Light native Linux/GL
games and emulators can run; AAA PC titles cannot — that is an x86 + Windows
problem, not a display problem.

## Can I run Windows or macOS apps?

No. ternux runs **arm64 Linux** binaries. Windows `.exe` and macOS apps need
their own OS (or heavy emulators this is not). Android apps also keep running
in Android — they are not "inside" the desktop.

## Why does my desktop die when the screen locks or after a while?

Common causes include Android child-process policy, memory pressure, and OEM
battery management. Set Termux and Termux:X11 battery use to *Unrestricted*,
reduce excessive build parallelism, and follow the evidence-led checks in
[Troubleshooting](TROUBLESHOOTING.html#the-desktop-dies-silently) before
changing any system-wide Android safeguard.

## Is this safe from a security/privacy point of view?

The design choices that matter:

- **No root** — no privileged Android access is requested; PRoot remains within
  Termux's app permissions and is not a separate security boundary.
- **Loopback-only defaults/examples** — the audio bridge and documented model
  servers use `127.0.0.1`, keeping them off the LAN. Other same-device clients
  may still reach loopback listeners, so do not treat anonymous services as authenticated.
- **Validated driver extraction** — the Turnip archive is checked for unsafe
  paths, the two selected members must be regular files, and only those two
  members are staged and installed. Other legitimate archive symlinks are not
  extracted.
- **Auditable installer** — one plain-text file, MIT licensed; read it before
  you run it.

The usual rules still apply: don't run untrusted binaries as root inside the
container, and never paste credentials into issues or logs.

## How do I make everything bilingual?

Core guides exist in English and Bangla; the full benchmark evidence archive is currently in English.
Inside the desktop:

```bash
bash install.sh --locale bn_BD.UTF-8
sudo dpkg-reconfigure locales
```

## What happens when I update Android or the Termux apps?

- **Android OS updates:** the container is files — it survives. Re-check the
  phantom-killer setting afterwards (`ternux doctor`).
- **Termux app updates:** normally fine. Use `ternux doctor`/`ternux verify`
  afterwards; `--resume` only skips phases already recorded as successful and
  is not a general repair mechanism.
- **Debian updates:** safe, except see the held-Mesa note in
  [Configuration](CONFIGURATION.html#held-mesa-packages-zink-route).

## Is ternux really free?

Yes. MIT licensed — code and documentation. Built and maintained by
[Sobuj Miah](https://github.com/soobujmiah). Contributions welcome.

## What is it NOT for?

- Sustained heavy 3D rendering, mining or large simulations
- Models whose weights, context and runtime allocations do not fit available
  shared memory
- Anything that requires `systemd`, kernel modules, monitor mode or unrestricted
  USB/radio access

It is for an ARM64 Linux desktop and selected development/graphics workloads in
Android's app sandbox. No-root substantially limits blast radius; it does not
make arbitrary downloaded code risk-free or eliminate heat, battery wear and
data-loss risks.

---

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · MIT*
