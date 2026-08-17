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
ternux doctor --json    # machine-readable structured diagnostics
ternux repair           # Auto-fix common issues
ternux verify           # Verify installation completeness
ternux benchmark        # Run GPU benchmarks (glmark2, vkmark)
ternux profile          # Show or save device hardware profile
ternux backend set virgl    # Switch to VirGL backend
ternux update           # Self-update ternux CLI
ternux logs             # View and manage log files
ternux info --json      # machine-readable system info
ternux state            # Show installation state
ternux uninstall        # Remove ternux components
```

The dispatcher recognizes `--help`, `--json`, `--verbose`, and `--quiet` globally,
but not every command defines JSON output. Commands shown below provide the
structured forms intended for automation; see the [CLI reference](CLI.html).

### Structured JSON output

Selected diagnostics and information commands produce machine-readable JSON:

```bash
ternux doctor --json | jq '.issues[]'
ternux info --json | jq '.gpu, .backend, .renderer'
ternux benchmark --json | jq '.glmark2_score, .vkmark_score'
```

See [CLI reference](CLI.html) for the implemented command and JSON fields.

---

## Where things live (and why)

```text
Termux host                          PRoot Debian
────────────                         ────────────
~/x.sh             launcher          /home/<user>     your home
~/.local/share/ternux/ state          /root            root's home
~/storage/shared   Android storage   /sdcard          same files, bind-mounted
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

### Blender viewport work

Install Blender with `bash install.sh --with-blender`, start the desktop, then
launch it from a Debian terminal:

```bash
blender
```

The captured Blender 4.3.2 system report saw the renderer
`zink Vulkan 1.4(Adreno (TM) 825 (MESA_TURNIP))`. That is evidence for the X11
**OpenGL viewport path**. It is not a Cycles GPU result: the same report listed
device type `SOFTWARE` and no Cycles GPU device. Keep scenes modest, save often,
and do not infer render speed from the archived glmark2 score.

Record your own evidence before and after a change:

```bash
glxinfo -B | tee ~/blender-gl-baseline.txt
blender --version | tee ~/blender-version.txt
```

### llama.cpp with Vulkan

`--with-llm` clones llama.cpp and builds its Vulkan backend inside Debian.
Supply a GGUF model you are licensed to use, then verify the binary and devices
before measuring it:

```bash
db
cd ~/llama.cpp
./build/bin/llama-cli --list-devices
./build/bin/llama-cli -m /path/to/model.gguf -ngl 99 \
  -p "Explain Zink in two sentences." -n 128
./build/bin/llama-bench -m /path/to/model.gguf -ngl 99
```

The supplied device notes report a successful Vulkan build/use, but contain no
reproducible token-rate table. Treat `--list-devices` as capability evidence
and `llama-bench` output as the performance evidence. Save the exact model
filename, quantisation, context, GPU layers, commit, prompt/prefill rate,
generation rate, memory and temperature; changing any of them weakens a
comparison.

Start with a model that fits comfortably in available shared memory. There is
no model size guaranteed to work on every 6–8 GB phone: Android, the desktop,
model weights, context/KV cache and Vulkan allocations all compete for the
same RAM.

### stable-diffusion.cpp with Vulkan

This is a manual developer workload rather than an installer profile. The
submitted notes report that a Vulkan-enabled build completed using this
configuration pattern:

```bash
db
sudo apt update
sudo apt install -y git cmake build-essential libvulkan-dev \
  glslang-tools glslang-dev

git clone --recursive https://github.com/leejet/stable-diffusion.cpp.git
cd stable-diffusion.cpp
cmake -S . -B build -DSD_VULKAN=ON -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release -j2
./build/bin/sd-cli --help
```

A successful build proves neither successful image generation nor speed. For
a defensible result, record the exact model and commit, resolution, steps,
sampler, seed, command, elapsed time, peak memory, temperature and output
image. Begin with a low resolution and a single image; stop if the device
becomes uncomfortably hot or Android starts reclaiming processes.

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

- Sustained compute while fast-charging adds two heat sources. Start with a
  charged battery; if the phone warms quickly, disconnect charging, remove a
  heat-trapping case, lower screen brightness, and let the device cool in open
  air. Do not use a freezer, ice, or condensation-prone cooling.
- Prefer bounded work: `cmake --build build -j2`, one image at a time, modest
  Blender scenes, and pauses between benchmark repetitions. More threads can
  reduce completion time but also raise peak temperature and memory pressure.
- If the Termux:API app and package are installed, `termux-battery-status` can
  expose a battery-temperature field. Treat it as one sensor, not the SoC
  junction temperature. Also heed Android thermal warnings, abrupt clock/FPS
  drops, charging pauses, instability, or a case that becomes uncomfortable to
  hold; stop the workload and cool the phone when any appears.
- On Android 12+, a killed build is not automatically the phantom-process
  policy. Check memory pressure and OEM battery restrictions first, then use
  the evidence-led flow in
  [Troubleshooting](TROUBLESHOOTING.html#the-desktop-dies-silently).
- The launcher holds a wake-lock while the desktop runs and releases it on
  exit. End the session when idle; a wake-lock prevents sleep and therefore
  consumes battery.
- Heavy sustained rendering, generation, large builds, and especially mining
  are poor phone workloads. No archived result here establishes sustained
  performance or a universally safe runtime.

---

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · MIT*
