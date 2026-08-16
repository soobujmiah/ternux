---
title: "Usage"
description: "Daily ternux operation: launch controls, storage layout, real workloads (Blender, local AI, development, security lab) and backups."
lang: "en"
alt_url: "/bn/docs/USAGE.html"
---

# Usage

Everything you need for day-to-day life with a Linux desktop in your pocket.

---

## Daily controls

| Command | What it does |
|---|---|
| `x` | Start the desktop (audio → display → Debian → Xfce4) |
| `xgo` | Open the Termux:X11 app automatically, then start the desktop |
| `killx` | Stop the session cleanly and clear stale sockets |
| `db` | Shell inside Debian as your user |
| `droot` | Shell inside Debian as root — careful in there |
| `ai` | Chat with a local model (needs `--with-llm` and a model file) |
| `sysmon` | Quick CPU/RAM/GPU-node overview |
| `clean-mesa` | Clear the shader cache (after driver changes) |

**A healthy start/stop routine:**

1. Start with `xgo` (or open Termux:X11 first, then `x`).
2. Close apps normally inside the desktop.
3. When done: log out of Xfce4 (Applications → Log Out), or run `killx` from
   the Termux side. This clears sockets so the next start is clean.

*Why bother?* A leftover X11 socket or zombie PulseAudio process makes the
next session "start" against a dead service — the desktop appears but audio
or display behaves oddly. `x` cleans these up at every start, so a clean stop
mainly saves battery.

---

## Ternux CLI — the permanent interface

When ternux is installed, the `ternux` command is your single entry point for
everything — install, diagnostics, repair, benchmarking, and daily desktop
management:

```bash
ternux install          # Full installation (delegates to install.sh)
ternux start            # Start the desktop session
ternux stop             # Stop the desktop session
ternux restart          # Restart the desktop session
ternux doctor           # Run system diagnostics
ternux doctor --json    # AI-readable structured diagnostics
ternux repair           # Auto-fix common issues
ternux verify           # Verify installation completeness
ternux benchmark        # Run GPU benchmarks (glmark2, vkmark)
ternux profile          # Show or save device hardware profile
ternux backend set virgl    # Switch to VirGL backend
ternux update           # Self-update ternux CLI
ternux logs             # View and manage log files
ternux info --json      # AI-readable system info
ternux state            # Show installation state
ternux uninstall        # Remove ternux components
```

Every command supports `--help`, `--json`, `--verbose`, and `--quiet`.

### AI-native JSON output

Critical commands produce structured machine-readable JSON for AI agents,
Android assistants, and automation:

```bash
ternux doctor --json | jq '.issues[]'
ternux info --json | jq '.gpu, .backend, .renderer'
ternux benchmark --json | jq '.glmark2_score, .vkmark_score'
```

See `share/templates/json-schema.md` for complete schemas.

---

## Where things live (and why)

```text
Termux host                          PRoot Debian
────────────                         ────────────
~/x.sh             launcher          /home/<user>     your home
~/.ternux-state    install state     /root            root's home
~/storage/shared   Android storage   /sdcard          same files, symlinked
```

- **Debian home** is inside the container — it travels with a
  `proot-distro backup` and is deleted with the container.
- **`~/storage/shared`** (Termux) and **`/sdcard`** (Debian) are the *same*
  Android storage. Files you want other apps (gallery, Drive, WhatsApp) to
  see belong here. *Why:* the container is invisible to Android apps; shared
  storage is the hand-off point.
- **Source code you care about** should also live in a Git remote. A phone is
  easy to lose and containers are easy to delete — GitHub is not.

---

## Workloads

### Everyday desktop

Browser, file manager, terminal, editors, archives, office docs — the default
Xfce4 install covers all of it. Install more with `sudo apt install <pkg>`.

*Tip:* in Xfce4 → Settings → Appearance, pick a dark theme and set the panel
to auto-hide — the phone screen is small, and dark is battery-friendly on
AMOLED.

### Lightweight Blender

Blender runs with GPU acceleration on the Zink route. This is real, useful
Blender for **low-poly modelling, simple materials and modest scenes** —
reported smooth on the author's Turnip-enabled device.

*Reality check:* a heavy render, smoke/fluid simulation or 4K scene is a poor
phone workload. Keep scenes small, viewport samples low, and save often.
Enable with `bash install.sh --with-blender`.

### Local AI with Vulkan

`--with-llm` builds **llama.cpp with the Vulkan backend** inside the
container. Then:

1. Download a compact GGUF model (1–2B Q4 runs comfortably on 6–8 GB phones):

   ```bash
   db
   cd ~/llama.cpp/models
   wget https://huggingface.co/ggml-org/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q4_K_M.gguf
   exit
   ```

2. Chat from Termux with the `ai` alias — it serves the first `.gguf` it
   finds with full GPU offload (`-ngl 99`).

*Why compact models?* Vulkan offload shares the phone's physical memory and
thermal budget with Android and the desktop. A 7B model on a phone is a
freezer-and-prayer situation; 1–2B is the practical sweet spot. The model
server stays on **loopback** — keep it that way unless you deliberately add
authentication.

### Development

`--with-dev` installs Git, Node.js, Python (with `venv`) and build tools.
Terminal-based coding assistants work inside the container; account and
licence terms are between you and the provider.

*Tip:* run `git` inside the container (`db`), but push from wherever is
convenient — both sides share the same Android storage if you clone under
`/sdcard`.

### Authorised security lab

`--with-network` adds nmap and tmux. **Use them only on systems, applications
and networks you own or have explicit written permission to test.**

*Know the limit:* PRoot provides a Debian userspace, not unrestricted
wireless. Monitor mode, packet injection and raw USB access stay behind
Android's kernel rules — by design.

---

## Backups

```bash
# In Termux — snapshot the whole container:
proot-distro backup debian --output ~/debian-backup.tar.gz

# Restore:
proot-distro restore debian ~/debian-backup.tar.gz

# Keep Android-side files safe too — they are NOT inside the container backup:
tar -czf ~/storage-backup.tar.gz -C ~/storage/shared .
```

*When to back up:* right after a verified install (your known-good baseline),
before big experiments, and before `apt dist-upgrade`s.

---

## Power, heat and longevity

- Charge while doing sustained work; remove a heat-trapping case.
- On Android 12+, apply the phantom-killer fix from
  [Troubleshooting](TROUBLESHOOTING.html#the-desktop-dies-silently) — without
  it, long builds can die randomly.
- The launcher holds a wake-lock while the desktop runs and releases it on
  exit; don't disable it.
- Heavy compute (large renders, big builds) is exactly what phones throttle.
  Short bursts: fine. Sustained mining/rendering: the wrong tool.

---

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · MIT*
