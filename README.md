<div align="center">

# ⚡ ternux

**One command. A full GPU-accelerated Linux desktop on the phone already in your pocket.**

Termux + PRoot Debian + Xfce4 with Vulkan via Zink/Turnip (Adreno) or VirGL (any GPU).  
**No root. No PC. No waiting.**

[![License](https://img.shields.io/badge/license-MIT-00ff41?style=flat-square)](LICENSE)
[![Platform](https://img.shields.io/badge/Android-10%2B%20aarch64-ffb000?style=flat-square)](docs/INSTALLATION.md)
[![CI](https://img.shields.io/github/actions/workflow/status/soobujmiah/ternux/ci.yml?branch=main&label=CI&style=flat-square)](https://github.com/soobujmiah/ternux/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/soobujmiah/ternux?style=flat-square&color=00b32d)](https://github.com/soobujmiah/ternux/releases)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-00b32d?style=flat-square)](CONTRIBUTING.md)
[![Site](https://img.shields.io/badge/site-live-00ff41?style=flat-square)](https://soobujmiah.github.io/ternux)
[![GitHub stars](https://img.shields.io/github/stars/soobujmiah/ternux?style=flat-square&color=ffb000)](https://github.com/soobujmiah/ternux/stargazers)

[Installation](docs/INSTALLATION.md) · [Quick start](docs/QUICK-START.md) · [CLI Reference](docs/CLI.md) · [Usage](docs/USAGE.md) · [FAQ](docs/FAQ.md) · [বাংলা](bn/)

</div>

---

## Install

Open [Termux](https://github.com/termux/termux-app/releases) (F-Droid or GitHub
build) on an Android 10+ phone and run:

```bash
curl -fsSL https://soobujmiah.github.io/ternux/install.sh | bash
```

**That's it.** The installer detects your GPU, sets up the environment, and
tells you exactly what to do next:

```
1. Open the Termux:X11 app once and leave it running
2. source ~/.bashrc
3. x                    ← starts the desktop
```

> **curl broken after an upgrade?** A partial upgrade can leave curl unable to
> link. Use wget instead: `wget -qO- https://soobujmiah.github.io/ternux/install.sh | bash`

---

## Ternux CLI

After installation, the `ternux` command is your permanent management interface:

```bash
ternux doctor           # System diagnostics
ternux doctor --json    # AI-readable structured output
ternux start            # Start the desktop
ternux stop             # Stop the desktop
ternux restart          # Restart the desktop
ternux repair           # Auto-fix common issues
ternux verify           # Verify installation completeness
ternux benchmark        # GPU benchmarks (glmark2, vkmark)
ternux profile          # Device hardware profile
ternux backend          # GPU backend management
ternux info             # System information
ternux info --json      # AI-readable system info
ternux logs             # View and manage logs
ternux state            # Installation state
ternux update           # Self-update ternux CLI
```

Every command supports `--help`, `--json`, `--verbose`, and `--quiet`.
For complete reference: [CLI Reference](docs/CLI.md).

### AI-native output

Critical commands produce structured JSON for AI agents:

```bash
ternux doctor --json   | jq '.issues[], .recommended_actions[]'
ternux info --json     | jq '.gpu, .backend, .renderer'
ternux benchmark --json| jq '.glmark2_score, .vkmark_score'
```

---

## What this is

ternux turns an ordinary Android phone into a usable **Debian desktop with
hardware-accelerated graphics** — without root, without bootloader unlocking,
and without risking Android's normal life.

```
Android
 └─ Termux (host shell)
     ├─ Termux:X11       ← the screen
     ├─ PulseAudio       ← the speakers
     └─ PRoot Debian (container)
         └─ Xfce4 desktop
             └─ Mesa → Zink → Vulkan → Turnip (Adreno GPU)
                       └─ or VirGL → Android graphics (other GPUs)
```

### Why it works

| Principle | Why |
|-----------|-----|
| **No root** | PRoot fakes root in userspace. Uninstall = delete one folder. |
| **Zink + Turnip** | OpenGL → Vulkan translation for adreno GPUs. Real acceleration. |
| **VirGL fallback** | Works on Mali, Xclipse, PowerVR — universal compatibility. |
| **Verified phases** | Every step checks its work. Never leave a half-broken install. |

### Honest limits

- ✅ Everyday desktop, coding, browsing
- ✅ Light Blender, local AI (1–2B models), development
- ⚠️ Heavy rendering, huge simulations, mining — poor fits on phones

---

## Requirements

| | Minimum |
|---|---|
| **OS** | Android 10+ |
| **CPU** | `aarch64` (64-bit ARM) |
| **Storage** | ~12 GB free |
| **RAM** | 4 GB (6–8 GB recommended) |
| **GPU** | Adreno (best) or any GPU |
| **Apps** | [Termux](https://github.com/termux/termux-app/releases) + [Termux:X11](https://github.com/termux/termux-x11) |

> The Play Store Termux build is **not supported** — it is years out of date.

---

## Quick start

```bash
# 1. Install Termux from F-Droid or GitHub releases
# 2. Run this inside Termux:
curl -fsSL https://soobujmiah.github.io/ternux/install.sh | bash

# 3. Open Termux:X11 app once
# 4. Reload and start:
source ~/.bashrc
x
```

From a desktop terminal:
```bash
glxinfo | grep "renderer string"
```

| You want | Never accept |
|----------|-------------|
| `zink Vulkan (Adreno … (MESA_TURNIP))` | `llvmpipe` (software) |
| `virgl` (compatibility) | a blank answer |

---

## Documentation

| Document | Purpose |
|----------|---------|
| [Quick start](docs/QUICK-START.md) | Fastest path to a verified desktop |
| [Installation](docs/INSTALLATION.md) | Full install guide with every option |
| [Manual installation](docs/MANUAL.md) | Every command by hand |
| [CLI Reference](docs/CLI.md) | Complete ternux CLI command reference |
| [Usage](docs/USAGE.md) | Daily controls, workloads, backups |
| [Configuration](docs/CONFIGURATION.md) | GPU routes, audio, locale, fonts |
| [Troubleshooting](docs/TROUBLESHOOTING.md) | Symptom → cause → fix |
| [Architecture](docs/ARCHITECTURE.md) | How the stack fits together |
| [FAQ](docs/FAQ.md) | Root, safety, storage, battery |

---

## Verify the GPU

```bash
ternux doctor               # Full diagnostics
ternux doctor --json        # AI-readable output
ternux benchmark            # Run GL/VK benchmarks
```

---

## Safety

- ✅ **No root** — never asks, never modifies Android system files
- ✅ **Loopback-only audio** — services bind to 127.0.0.1 by default
- ✅ **Validated archives** — driver downloads are SHA-256 checked
- ✅ **Container isolation** — everything lives inside Termux's storage

Uninstall: `ternux uninstall` or `bash install.sh --uninstall`

---

## Contributing

Device reports, translations, and code contributions are welcome.
See [CONTRIBUTING.md](CONTRIBUTING.md) and [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## License

MIT — see [LICENSE](LICENSE).  
Not affiliated with Termux, Debian, Xfce, Blender, Qualcomm, or any
third-party project named here.

---

<div align="center">

Built by [Sobuj Miah (@soobujmiah)](https://github.com/soobujmiah)  
Copyright © 2026 Sobuj Miah · MIT licensed

</div>