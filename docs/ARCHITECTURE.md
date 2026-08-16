---
title: "Architecture"
description: "How Android, Termux, PRoot Debian, Termux:X11 and Mesa cooperate in ternux — the graphics routes, the boundaries, and the failure modes to watch for."
lang: "en"
alt_url: "/bn/docs/ARCHITECTURE.html"

---

# Architecture

Understanding the stack makes every symptom in
[Troubleshooting](TROUBLESHOOTING.html) obvious. This page explains how the
pieces cooperate, and where they fail when they don't.

---

## The stack

```text
┌─────────────────────────────────────────────────────┐
│ Android                                             │
│                                                     │
│  Termux:X11 app ◀──── X11 display ────┐             │
│                                       │             │
│  Termux host                          │             │
│  ├─ display and audio services        │             │
│  ├─ PRoot supervisor                  │             │
│  └─ optional VirGL service            │             │
│               │                       │             │
│               └─ PRoot Debian ────────┘             │
│                  ├─ Xfce4 desktop                   │
│                  ├─ Debian applications             │
│                  └─ Mesa / Zink / VirGL             │
│                                                     │
│  Adreno kernel GPU interface ◀── Turnip path        │
└─────────────────────────────────────────────────────┘
```

### Android

Android owns the kernel, hardware drivers, the app sandbox, power policy and
process limits. ternux never replaces Android, unlocks the bootloader or asks
for root. That is why it is safe — and also why PRoot cannot grant hardware
capabilities Android does not expose.

### Termux

Termux is the host-side Linux environment. It coordinates the PRoot container
and the services that must live outside it (display, audio). Closing or
force-stopping Termux can end the desktop even while Termux:X11 remains
visible.

### PRoot Debian

PRoot provides a Debian userland **without a privileged chroot**. It rewrites
paths and selected system calls in userspace, so the container believes it is
root while Android's sandbox stays intact.

*What that means in practice:*

- Most normal arm64 Debian applications work.
- `systemd`, kernel modules, privileged mounts and direct hardware control do
  **not** — there is no real init system inside the container.
- The container is just files: backup = archive, uninstall = delete.

### Termux:X11

Termux:X11 is the Android app that *renders* the X11 session — it is not the
desktop itself. A black Termux:X11 view can mean the app is healthy while the
host service, socket or Xfce4 session is not.

---

## Graphics routes

### Zink + Turnip — Adreno devices (preferred)

```text
OpenGL application
       │
       ▼
     Zink          OpenGL → Vulkan translation
       │
       ▼
 Vulkan loader
       │
       ▼
    Turnip         Mesa's Vulkan driver for Adreno
       │
       ▼
 Android / kernel GPU interface
```

**Why two layers?** Adreno phones expose Vulkan to userland but have no
desktop OpenGL driver. Zink translates desktop GL calls to Vulkan; Turnip
implements Vulkan on Adreno. Together they give desktop apps a genuine
hardware path. Every layer must agree — a missing loader, ICD file or driver
binary leaves a desktop that opens but renders on the CPU.

### VirGL — other GPUs (compatibility)

```text
OpenGL application
       │
       ▼
 virpipe / VirGL
       │
       ▼
 host-side VirGL service  (virgl_test_server_android)
       │
       ▼
 Android graphics stack
```

VirGL is the universal route for Mali, Xclipse, PowerVR and anything else
without Turnip. GL commands cross the container boundary to a host-side
renderer. It is slower than Turnip; that is the honest trade-off for
compatibility. Choosing VirGL is not a failed Adreno setup — pretending
non-Adreno hardware can use Turnip *would* be the failure.

---

## Audio and file boundaries

**Audio** crosses the PRoot boundary through a loopback-only TCP bridge:
Debian apps → `tcp:127.0.0.1:4713` → host PulseAudio → phone speakers.
Loopback binding matters: a mobile workstation must not expose an
unauthenticated audio or model service to the local network by default.

**Storage** is three distinct locations:

| Location | What it is |
|---|---|
| Debian home (`/home/<user>`) | Inside the container; travels with backups |
| Termux home (`~`) | Host side; launcher, state, scripts |
| Shared storage (`~/storage/shared` ↔ `/sdcard`) | The Android files all apps see |

Source code and irreplaceable projects belong in shared storage or a Git
remote — not only inside the container.

---

## Silent failure modes

| Failure | Why the desktop may still open | Evidence |
|---|---|---|
| **Vulkan loader/driver path incomplete** | Mesa falls back to CPU rendering | Renderer string must not say `llvmpipe` |
| **Mesa replaced by an update** | Stock Mesa still renders a desktop | Compare renderer string with known-good baseline |
| **Wrong backend selected** | A compatible but slower route still works | GPU evidence and chosen route must agree |
| **VirGL host service missing** | Software fallback hides the missing service | Launcher warns; renderer says `llvmpipe` |
| **Android process policy intervenes** | Session works, then loses processes | `[Process completed (signal 9)]` — phantom killer |

**A visible Xfce4 desktop is not the definition of success.** The renderer
string, service health and a clean second launch are stronger evidence. That
is why the installer verifies each phase instead of assuming.

---

## Workload consequences

- **Blender:** viewport usefulness depends on the graphics route, scene
  complexity, memory and thermals. A smooth low-poly scene does not predict a
  large render.
- **Local AI:** Vulkan offload shares the same physical memory and thermal
  budget as Android and the desktop — hence the 1–2B model guidance.
- **Development agents:** tool execution happens inside your environment;
  provider credentials and command approval remain your boundaries.
- **Security tools:** PRoot gives Debian userspace, not monitor mode, USB
  passthrough or arbitrary kernel capabilities.
- **Sustained compute:** long constant load hits throttling, battery wear and
  heat — not a recommended target for any phone.

---

## Why the installer is phased and verified

Mobile networks drop, Android reclaims processes, multi-hundred-MB downloads
interrupt. A professional installer must treat interruption as an *expected
state*:

- **Idempotency** — a completed phase can be checked or re-entered without
  duplicating configuration.
- **Recorded resume** — completed phases are skipped on `--resume`.
- **Targeted repair** — `--doctor` maps a failure to its phase.
- **Verification before progression** — every critical file and binary is
  confirmed present before the next phase runs.
- **Supportable output** — failures name the check, the expected result and
  the safe next action.

---

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · MIT*
