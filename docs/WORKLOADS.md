---
title: "Workloads — what each option installs, automatically or by hand"
description: "The opt-in workloads, the exact packages each one installs, the one-command route and the manual equivalent, and how resume and failure are handled."
lang: "en"
alt_url: "/bn/docs/WORKLOADS.html"
---

A ternux install is a desktop plus whatever you opt into. Nothing on this page
is installed unless you ask for it, and each option is a *workload*: a named set
of packages, installed into the guest, recorded in state so `--resume` and
`ternux repair` know about it.

Every workload can be installed two ways, and both are first-class. The
one-command route is a flag on the installer. The manual route is the same
commands run yourself inside the guest, so you can read them before they run
and so a failed install can be finished by hand instead of started over.

## The workloads

| Workload | Flag | What it installs |
|---|---|---|
| Development | `--with-dev` | git, curl, wget, Node.js, npm, Python 3 with pip and venv, build-essential, ca-certificates |
| Local AI | `--with-llm` | Vulkan and shader toolchain, then llama.cpp **built from source** with `GGML_VULKAN=ON` |
| Network | `--with-network` | nmap, tmux |
| Media | `--with-media` | ffmpeg, GIMP, Audacity, ImageMagick |
| Blender | `--with-blender` | Blender (about 95 MB with `--no-install-recommends`) |
| Everything | `--all` | all five |

The base desktop — Xfce4, terminal, VLC, archive tools, Mesa utilities, Vulkan
tools — is always installed and is not a workload.

## Automatic

```bash
bash install.sh --with-dev --with-llm --with-blender
bash install.sh --all
```

Flags combine, and the set is recorded. A later `bash install.sh --resume`
restores the same set without repeating it on the command line, and
`ternux repair` repairs what was recorded rather than guessing.

## Manual

Run these as the Debian user inside the guest — from the Xfce terminal, or
`proot-distro login debian --user <you>` from Termux. `db` is the alias ternux
installs for exactly this. Each block is what the installer runs, so the result
is the same either way.

First, once per session:

```bash
sudo apt update
export DEBIAN_FRONTEND=noninteractive
```

**Development**

```bash
sudo apt install -y git curl wget nodejs npm python3 python3-pip python3-venv \
  build-essential ca-certificates
```

**Network**

```bash
sudo apt install -y nmap tmux
```

Authorised testing only. nmap against networks you do not own is not something
ternux is asking you to do.

**Media**

```bash
sudo apt install -y ffmpeg gimp audacity imagemagick
```

**Blender**

```bash
sudo apt install -y --no-install-recommends blender
```

`--no-install-recommends` drops about 23 MB of speech-synthesis packages Blender
does not need. Before rendering, read
[Graphics persistence](GRAPHICS-PERSISTENCE.html): on recent Adreno hardware the
GPU path depends on a Mesa driver newer than Debian's, and a package update can
remove it.

**Local AI (llama.cpp)**

This one compiles. Expect a long build and real heat; do it on power, and do not
expect a phone to finish it quickly.

```bash
sudo apt install -y build-essential cmake git pkg-config libvulkan-dev \
  vulkan-tools clinfo glslang-dev glslang-tools libshaderc-dev glslc
git clone --depth 1 https://github.com/ggml-org/llama.cpp.git ~/llama.cpp
cd ~/llama.cpp
cmake -S . -B build -DGGML_VULKAN=ON -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release -j"$(nproc)"
```

Building from source is the current route, not the intended one. A release-based
install with pinned inputs, checksums and a license review is a pending release
gate — see [the accelerator release plan](ACCELERATOR-RELEASE-PLAN.html), order 5
and order 6. Until that lands, treat a local build as yours: you chose the
commit, so you own the result.

Model files are not installed by any workload. Keep them where you already have
them and point llama.cpp at the path; ternux neither copies nor manages model
weights.

## Backend selection applies to workloads too

A workload that touches the GPU — Blender, and llama.cpp's Vulkan build — runs
over whatever graphics route the install selected. Check it before you blame a
workload:

```bash
ternux info            # selected backend, GPU, Vulkan
glxinfo -B             # in the desktop terminal: the renderer actually in use
```

`llvmpipe` in that renderer string means software rendering, and on some devices
software rendering does not merely run slowly — it crashes. See
[Configuration](CONFIGURATION.html) for the routes and
[Troubleshooting](TROUBLESHOOTING.html) for symptom-led diagnosis.

## When a workload fails

A workload failure does not fail the install. The phase records the failure,
the rest of the install continues, and the desktop still comes up. That is
deliberate: a missing Audacity should not cost you a working workstation.

```bash
ternux logs show                    # what actually failed
bash install.sh --resume            # retry the recorded set
ternux repair                       # repair the recorded install
```

If one workload keeps failing, install the rest automatically and do that one by
hand from the block above — the manual route exists for this.

## Status

The package sets on this page are read from the installer itself, so they are
accurate for this version. What is **not** claimed here is that every workload
has been qualified on a device: sustained runs, repeat runs and thermal
behaviour are a pending release gate, and
[Evidence & benchmarks](BENCHMARKS.html) is the only place that states what was
actually measured.
