---
title: "Configuration"
description: "Every ternux setting explained: launcher environment variables, GPU routes, audio bridge, locale, fonts and where each file lives."
lang: "en"
alt_url: "/bn/docs/CONFIGURATION.html"

---

# Configuration

ternux installs with sensible defaults, and everything can be tuned. This page
explains every knob, where it lives, and *why* it is set the way it is.

---

## Install-time choices

| Setting | Default | Notes |
|---|---|---|
| `--user NAME` | `ternux` | Debian user created inside the container |
| `--locale LANG` | `en_US.UTF-8` | Desktop locale (see below for Bangla) |
| `--backend` | `auto` | `auto` detects Adreno → `zink`, else `virgl` |
| `--zsh` | off | Switch the Termux shell to zsh as well |
| `--with-*` | none | Optional workload profiles |

Changing the user or locale after install is possible but fiddly — easiest
path is `bash install.sh --user X --resume`, which re-applies phases without
re-downloading the container.

### Bangla locale

```bash
bash install.sh --locale bn_BD.UTF-8
```

This generates the `bn_BD.UTF-8` locale inside Debian and installs
Noto/Symbola font coverage, so Bangla renders correctly in the desktop
terminal and apps.

---

## The launcher — `~/x.sh`

Generated for your GPU route and syntax-checked at install time. Edit it
freely; a reinstall regenerates it (your edits are replaced).

### Zink (Adreno) environment

```text
MESA_LOADER_DRIVER_OVERRIDE=zink   Force Mesa's Zink Gallium driver
GALLIUM_DRIVER=zink                (same intent, legacy spelling — both set)
TU_DEBUG=sysmem,noconform          Turnip options for correct desktop GL
MESA_VK_WSI_DEBUG=sw               Software WSI — avoids X11/Vulkan surface issues
MESA_DISK_CACHE_SINGLE_FILE=1      Shader cache as one file, faster warm starts
MESA_SHADER_CACHE_MAX_SIZE=2048M   Cap so the cache can't eat all storage
MESA_SHADER_CACHE_DIR=/tmp/mesa_cache  Cache in the shared tmp (RAM-backed)
QT_X11_NO_MITSHM=1 / _X11_NO_MITSHM=1  Disable MIT-SHM (broken over X11 here)
XDG_RUNTIME_DIR=~/.runtime         Required by modern dbus/GTK apps
--bind /dev/kgsl-3d0               Expose the Adreno kernel node to the container
```

*Why the cache tweaks?* The phone's storage is slow flash; a single-file,
size-capped cache keeps app warm-starts fast without letting Mesa silently
consume gigabytes.

### VirGL environment

```text
GALLIUM_DRIVER=virpipe              Route GL over the VirGL pipe
MESA_GL_VERSION_OVERRIDE=4.3COMPAT  Advertise a modern GL version to apps
MESA_GLES_VERSION_OVERRIDE=3.2
```

The host-side `virgl_test_server_android` process is started before the
container; the launcher warns loudly if it fails to start (otherwise the
session silently falls back to software rendering).

---

## Audio

Three cooperating pieces:

| Where | What |
|---|---|
| Termux `$PREFIX/etc/pulse/default.pa` | TCP bridge module on **127.0.0.1:4713**, OpenSL sink as default |
| Launcher | starts `pulseaudio` before the container, loads the bridge |
| Debian `~/.config/pulse/client.conf` | `default-server = tcp:127.0.0.1:4713` |

*Why loopback-only?* The bridge crosses the container boundary over TCP, so
an anonymous ACL is needed — restricting it to `127.0.0.1` means only
processes on the phone itself can reach it. Never change this to `0.0.0.0`
"to make audio work over the network" — that is how you broadcast your
microphone to the LAN.

To pick a different sink (Bluetooth, headphones), change the
`set-default-sink` line in `default.pa` and restart the session (`killx`,
then `x`).

---

## Fonts

Installed inside Debian:

- `fonts-noto-color-emoji` — emoji
- `fonts-symbola`, `fonts-font-awesome`, `fonts-powerline` — symbol coverage
- **JetBrainsMono Nerd Font** — terminal icon glyphs, downloaded once into
  `~/.local/share/fonts` (sentinel file prevents re-downloads)

Add more fonts any time: drop the files in `~/.local/share/fonts` and run
`fc-cache -f`.

---

## State files

| Path | Purpose |
|---|---|
| `~/.ternux-state` | Which installer phases completed (powers `--resume`, `--status`) |
| `~/.ternux-state` also records | The SHA-256 of the downloaded Turnip driver |
| `$TMPDIR/ternux-install.log` | Full log of the last installer run |

Delete `~/.ternux-state` only if you want the installer to redo everything
from scratch (`--resume` will otherwise skip completed phases).

---

## Held Mesa packages (Zink route)

```bash
db
sudo apt-mark showhold        # expect: mesa-vulkan-drivers libgl1-mesa-dri ...
```

These are held so a routine `apt upgrade` cannot replace the Turnip-backed
path with stock Mesa and silently switch you to `llvmpipe`. Upgrade them
deliberately:

```bash
sudo apt-mark unhold mesa-vulkan-drivers libgl1-mesa-dri libglx-mesa0 libgbm1 libegl-mesa0
sudo apt upgrade
sudo apt-mark hold mesa-vulkan-drivers libgl1-mesa-dri libglx-mesa0 libgbm1 libegl-mesa0
```

…then verify the renderer string again (`glxinfo | grep renderer`).

---

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · MIT*
