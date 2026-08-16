---
title: "FAQ"
description: "Straight answers about ternux: root, safety, the Play Store Termux, storage, battery, gaming, privacy and everything people actually ask."
lang: "en"
alt_url: "/bn/docs/FAQ.html"

---

# FAQ

---

## Is root required? Why not just root my phone?

No — and deliberately not. Rooting unlocks the bootloader and voids
warranties, trips banking and DRM apps, and exposes the whole device to
anything that runs on it.

ternux uses **PRoot**, which fakes a root filesystem *in userspace*. The
container thinks it is root; Android never notices. The entire risk of
ternux is one folder in Termux's storage. That is the design point.

## Will this damage or "brick" my phone?

No. ternux never touches the bootloader, system partitions or Android
settings. It writes files inside Termux's private storage and installs
ordinary apps. The worst realistic outcome of a broken install is deleting
the container and starting over.

## Why can't I use the Termux from the Play Store?

That build was abandoned by its maintainers years ago. Its package
repositories are dead, so `pkg install` fails on everything, and it is full
of known bugs that were fixed long ago in the maintained builds. Always use
[F-Droid](https://f-droid.org/en/packages/com.termux/) or
[GitHub releases](https://github.com/termux/termux-app/releases).

## How much storage will it really use?

~6 GB for the base Debian rootfs plus packages, so the installer asks for
**12 GB free** to leave working room. Each extra profile adds:

| Profile | Rough cost |
|---|---|
| `--with-dev` | +1–2 GB |
| `--with-llm` | +2–3 GB (build tree) + models (0.5–2 GB each) |
| `--with-blender` | +1 GB |
| `--with-media` | +1 GB |

## Does it work on non-Qualcomm phones?

Yes. Mali, Xclipse and PowerVR devices get the **VirGL** route — hardware
backed, but slower than Adreno's Zink/Turnip. Only the *speed* differs; the
desktop and tooling are identical.

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

Two usual causes:

1. **Phantom process killer** (Android 12+) — the #1 cause. Fix in
   [Troubleshooting](TROUBLESHOOTING.html#the-desktop-dies-silently).
2. **Aggressive OEM battery optimisation** killing Termux in the background.
   In Android settings, set Termux's battery usage to *Unrestricted* and
   disable its background restrictions.

## Is this safe from a security/privacy point of view?

The design choices that matter:

- **No root** — the sandbox Android ships with stays intact.
- **Loopback-only services** — audio and model servers bind to `127.0.0.1`,
  unreachable from the network.
- **Validated downloads** — the Turnip driver archive is checked for unsafe
  paths and links before extraction, and only two whitelisted files are
  installed.
- **Auditable installer** — one plain-text file, MIT licensed; read it before
  you run it.

The usual rules still apply: don't run untrusted binaries as root inside the
container, and never paste credentials into issues or logs.

## How do I make everything bilingual?

The site and docs exist in English and Bangla (header switch on every page).
Inside the desktop:

```bash
bash install.sh --locale bn_BD.UTF-8
sudo dpkg-reconfigure locales
```

## What happens when I update Android or the Termux apps?

- **Android OS updates:** the container is files — it survives. Re-check the
  phantom-killer setting afterwards (`ternux doctor`).
- **Termux app updates:** fine; the installer is re-runnable (`--resume`
  skips completed work).
- **Debian updates:** safe, except see the held-Mesa note in
  [Configuration](CONFIGURATION.html#held-mesa-packages-zink-route).

## Is ternux really free?

Yes. MIT licensed — code and documentation. Built and maintained by
[Sobuj Miah](https://github.com/soobujmiah). Contributions welcome.

## What is it NOT for?

- Heavy 3D rendering or large simulations
- Mining (thermal suicide on a phone)
- Huge local models (7B+ without serious RAM is a fantasy)
- Anything that needs `systemd`, kernel modules or real USB/radio access

It *is* for: a real Linux desktop, in your pocket, that costs nothing,
risks nothing, and keeps your phone a phone.

---

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · MIT*
