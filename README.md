<div align="center">

# ternux

### Debian + Xfce4 on Android with a measured Adreno GPU route — one command, no root

[![Version](https://img.shields.io/badge/version-1.3.0-00e5a0?style=flat-square)](https://github.com/soobujmiah/ternux/releases)
[![Platform](https://img.shields.io/badge/platform-Android%20arm64-38bdf8?style=flat-square)](https://github.com/soobujmiah/ternux)
[![Shell](https://img.shields.io/badge/shell-Bash-8b5cf6?style=flat-square)](https://github.com/soobujmiah/ternux)
[![License](https://img.shields.io/badge/license-MIT-22c55e?style=flat-square)](LICENSE)

[Website](https://soobujmiah.github.io/ternux/) · [Documentation](https://soobujmiah.github.io/ternux/docs/) · [Quick start](docs/QUICK-START.md) · [Manual install](docs/MANUAL.md) · [Evidence](docs/BENCHMARKS.md) · [বাংলা](bn/README.md)

</div>

---

**ternux** installs a real Debian ARM64 userspace, Xfce4 desktop, Termux:X11 display,
PulseAudio bridge, a Zink/Turnip GPU route on supported Adreno devices, and a
VirGL compatibility route for other cases. It also installs a permanent `ternux`
CLI for starting, stopping, diagnosing, repairing and benchmarking the environment.

> **Evidence policy:** the numbers below come from output supplied from one real
> Redmi Turbo 4 Pro setup. They are not a promise for every phone. Measured,
> observed and not-yet-tested results are kept separate so a successful build is
> never presented as a performance benchmark.

| If you want to… | Start here |
|---|---|
| Install and verify the shortest safe path | [Quick start](docs/QUICK-START.md) |
| Review every module before running it | [Installation → download, review, then run](docs/INSTALLATION.md#method-2--download-review-then-run) |
| Perform every setup step yourself | [Manual installation](docs/MANUAL.md) |
| Diagnose an existing installation | [Troubleshooting](docs/TROUBLESHOOTING.md) |
| Inspect raw results and claim boundaries | [Benchmarks and device evidence](docs/BENCHMARKS.md) |
| Navigate the complete guide set | [Documentation overview](https://soobujmiah.github.io/ternux/docs/) |

## Contents

- [What gets installed](#what-gets-installed)
- [Measured device results](#measured-device-results)
- [How the graphics stack works](#how-the-graphics-stack-works)
- [Requirements](#requirements)
- [Automatic installation](#automatic-installation)
- [Manual installation](#manual-installation)
- [Start, stop and verify](#start-stop-and-verify)
- [Reproduce the benchmark](#reproduce-the-benchmark)
- [Optional workloads](#optional-workloads)
- [Limits and safety](#limits-and-safety)
- [FAQ](#faq)
- [Troubleshooting](#troubleshooting)
- [Documentation](#documentation)

---

## What gets installed

| Layer | Component | Purpose |
|---|---|---|
| Android app | **Termux:X11** | Displays the Linux X11 desktop on Android |
| Termux host | `termux-x11`, PulseAudio, PRoot Distro | Display socket, Android audio and container lifecycle |
| Linux guest | **Debian ARM64** | Standard `apt`-managed GNU/Linux userspace |
| Desktop | **Xfce4** | Lightweight desktop, terminal and file manager |
| Adreno graphics | Mesa **Zink → Turnip → KGSL** | OpenGL translated to Vulkan and sent to the Qualcomm GPU |
| Fallback graphics | **VirGL** | More portable virtual OpenGL route for unsupported devices |
| Control plane | `ternux` CLI + `~/x.sh` | Install, launch, stop, verify, diagnose, repair and benchmark |
| Audio | PulseAudio over loopback TCP | Debian applications play through Android's audio sink |

Base applications include Xfce Terminal, VLC, archive tools, Mesa utilities and Vulkan
tools. Development tools, llama.cpp, media tools, network tools and Blender are opt-in.

---

## Measured device results

### Tested setup snapshot

The following is an **August 2026 evidence snapshot** supplied by the project author:

| Item | Captured value |
|---|---|
| Device | Redmi Turbo 4 Pro |
| SoC / GPU | Snapdragon 8s Gen 4 / Adreno 825 |
| Guest | Debian ARM64 through PRoot Distro |
| Desktop path | X11 through Termux:X11 |
| Graphics | Mesa 26.2.0-devel, Zink over Vulkan 1.4, `MESA_TURNIP` |
| OpenGL | 4.6 compatibility profile in glmark2; 4.6 core profile in Blender |
| OpenGL ES | 3.2 |
| Test surface | 800 × 600 as reported by glmark2 |

The renderer string in both glmark2 and Blender was:

```text
zink Vulkan 1.4(Adreno (TM) 825 (MESA_TURNIP))
```

That string is the important proof that these OpenGL applications reached the
Zink/Turnip path instead of Mesa `llvmpipe` software rasterization.

### glmark2 scores and FPS

| Captured command | API / reported mode | Score | Selected scene FPS | Full scene range |
|---|---|---:|---|---:|
| `glmark2` | OpenGL 4.6, 800×600 windowed | **140** | build 138–147; desktop 137–139; jellyfish 154; terrain 45; refract 120 | **45–164** |
| `glmark2-es2 --off-screen` | OpenGL ES 3.2; header still says 800×600 windowed | **364** | build 382–436; desktop 321–362; bump 384–465; terrain 118; refract 152 | **53–465** |

Important interpretation notes:

- A glmark2 score is a suite aggregate, **not the desktop's constant FPS**.
- The two rows use different APIs and modes and must not be compared as if they
  were the same test.
- The ES2 run printed `DRI3 error: Could not get DRI3 device`, while still naming
  Zink/Adreno/Turnip as its renderer. Its command, warning and reported surface are
  preserved exactly rather than silently relabelled.
- FPS depends on resolution, compositor, refresh/VSync state, Mesa build, thermal
  state and background load. Compare results only when those conditions match.

See [Benchmarks and device evidence](docs/BENCHMARKS.md) for the scene table,
methodology, reproduction commands and evidence boundaries.

### Application evidence

| Workload | What the supplied output establishes | What it does **not** establish |
|---|---|---|
| Blender 4.3.2 | Blender launched on X11 and saw Mesa 26.2.0-devel with the Zink/Adreno 825/Turnip OpenGL renderer | Cycles GPU rendering; Blender FPS; render time |
| llama.cpp | User notes report a successful Vulkan build and use with small GGUF models | prompt-processing or generation tokens/s; memory, power or thermal results |
| stable-diffusion.cpp | User notes report a successful build with `-DSD_VULKAN=ON` | a completed image, Vulkan runtime log, seconds/image or peak memory |

Blender's report also says `device type: SOFTWARE`, `backend type: OPENGL` and lists
no Cycles device. This is compatible with Blender using its OpenGL viewport through
Zink, but it is **not evidence of Cycles GPU Compute**. The project therefore does
not claim GPU-accelerated Cycles rendering.

### Still needed for a complete performance picture

- `llama-bench` prompt-processing and token-generation rates
- stable-diffusion.cpp runtime backend log and seconds per reproducible image
- Blender viewport FPS and Cycles CPU/GPU comparison
- sustained temperature, power and throttling measurements
- a same-device, same-resolution Zink versus VirGL comparison

---

## How the graphics stack works

```text
OpenGL desktop application                    Vulkan compute application
(Blender viewport, glmark2, Xfce apps)         (llama.cpp, stable-diffusion.cpp)
                 │                                           │
                 ▼                                           ▼
        Mesa OpenGL state tracker                       Vulkan loader
                 │                                           │
                 ▼                                           │
              Zink                                           │
       (OpenGL → Vulkan)                                      │
                 └──────────────────┬────────────────────────┘
                                    ▼
                            Turnip Vulkan driver
                                    ▼
                       Android KGSL / Adreno GPU

Display: application → X11 socket → Termux:X11 → Android screen
Audio:   application → PulseAudio TCP 127.0.0.1:4713 → Termux → Android audio
```

Zink is Mesa's OpenGL-on-Vulkan driver. On supported Qualcomm Adreno devices,
Turnip supplies Vulkan over Android's KGSL interface. Direct Vulkan applications
skip Zink and use the Vulkan loader/Turnip route directly.

When the Adreno/KGSL route is unavailable, ternux selects VirGL:

```text
OpenGL application → Mesa virpipe → virglrenderer-android → Android graphics
```

VirGL is the compatibility fallback. It is not guaranteed to match Zink/Turnip's
features or speed, and some Mali/PowerVR/Xclipse devices may still require
device-specific work that ternux does not automate today.

### Why no root is needed

PRoot translates filesystem paths and process behavior in userspace. It does not
boot another kernel and does not grant Android kernel capabilities. Debian uses the
phone's existing Android kernel, CPU, memory and device-access rules.

This also explains the limitations: no systemd boot, no kernel modules, no monitor
mode magically provided by Debian, and some sandbox/container overhead.

---

## Requirements

| Requirement | Minimum / guidance |
|---|---|
| Architecture | **ARM64** (`aarch64` / `arm64`) |
| Android | ternux baseline: **Android 10+**; Termux:X11 itself requires Android 8+ |
| RAM | 4 GB minimum; 6–8 GB recommended for desktop + development or small local models |
| Free storage | About 12 GB for the base install; more for Blender, build trees and models |
| Root | **Not required** |
| Network | Stable connection during installation |
| Best GPU route | Qualcomm Adreno with accessible `/dev/kgsl-3d0` |

### Install both Android apps first

1. Install **Termux** from [F-Droid](https://f-droid.org/packages/com.termux/) or
   the [official Termux GitHub releases](https://github.com/termux/termux-app/releases).
   The Google Play build is an experimental, separate branch and is not the
   recommended base for this guide.
2. Install the **Termux:X11 Android APK** from its
   [nightly release](https://github.com/termux/termux-x11/releases/tag/nightly).
3. Do not mix Termux and plugin APKs from different sources: F-Droid and GitHub
   builds use different signing keys. Termux's own installation documentation is
   the authority if its packaging changes.

The ternux installer installs the Termux-side `termux-x11` companion package; it
cannot silently install the separate Android APK for you.

---

## Automatic installation

### One-command install

Run this **inside Termux**:

```bash
curl -fsSL https://soobujmiah.github.io/ternux/install.sh | bash
```

The default is unattended: user `ternux`, locale `en_US.UTF-8`, and automatic
backend selection (`zink` when the Adreno KGSL node is available, otherwise
`virgl`). Do not close Termux while package installation is running.

> Piping a network script to Bash is convenient, but it executes the current
> remote version immediately. Use the auditable path below if you want to inspect
> or pin the code first.

### Auditable automatic install

Clone the repository so the entry script **and every library it sources** are
available for review before anything runs:

```bash
pkg update -y && pkg install git -y
git clone https://github.com/soobujmiah/ternux.git
cd ternux
git log -1 --oneline                 # record the exact commit
(set -e; for f in install.sh uninstall.sh bin/ternux lib/*.sh; do bash -n "$f"; done)
less install.sh lib/core.sh lib/phases.sh lib/detect.sh lib/ui.sh
# In less, use :n for the next file and q when finished.
bash install.sh
```

To pin an exact release, check out its tag **before** inspection and execution:

```bash
git fetch --tags
git checkout <release-tag>
git status --short                   # should be empty
(set -e; for f in install.sh uninstall.sh bin/ternux lib/*.sh; do bash -n "$f"; done)
bash install.sh
```

Reviewing only a downloaded `install.sh` is not equivalent: the standalone entry
script fetches its library modules at runtime.

### Installer options

Run options from a cloned repository so they can be passed directly:

```bash
bash install.sh --backend zink --user myuser --locale en_US.UTF-8
bash install.sh --with-dev --with-llm --with-blender
bash install.sh --all
bash install.sh --resume
```

| Option | Effect |
|---|---|
| `--backend auto\|zink\|virgl` | Auto-detect, force Adreno Zink/Turnip, or force VirGL |
| `--user NAME` | Debian user name; default `ternux` |
| `--locale LANG` | Guest locale; default `en_US.UTF-8` |
| `--zsh` | Configure zsh instead of Bash |
| `--with-dev` | Git, Node.js, Python, venv and build tools |
| `--with-llm` | Build llama.cpp with `GGML_VULKAN=ON` |
| `--with-network` | Install nmap and tmux for authorised administration/testing |
| `--with-media` | Install FFmpeg, GIMP, Audacity and ImageMagick |
| `--with-blender` | Install Debian's Blender package |
| `--all` | Install every optional profile above |
| `--resume` | Re-run while skipping phases already recorded as complete |
| `--no-anim` | Disable installer animations |

### What the automatic installer does

| Phase | Action |
|---:|---|
| 1 | Checks Termux, ARM64, Android version, storage and network |
| 2 | Updates Termux and installs X11, audio, PRoot and graphics packages |
| 3 | Installs the `ternux` CLI |
| 4 | Installs Debian, Xfce4, applications and a non-root Debian user |
| 5 | Selects and installs Zink/Turnip or validates VirGL |
| 6 | Configures loopback-only audio, locale and fonts |
| 7 | Generates the backend-aware `~/x.sh` launcher |
| 8 | Adds `x`, `xgo`, `killx`, `db`, `droot`, `sysmon` and cache helpers |
| 9 | Installs only the optional workload profiles you requested |
| 10 | Reports readable Android child-process settings with version-aware guidance |
| 11 | Verifies the host tools, guest desktop, launcher and selected GPU route |

If the install is interrupted, return to the repository and run
`bash install.sh --resume`. For diagnosis, use `ternux doctor`; for common repairs,
use `ternux repair`.

---

## Manual installation

The following is the complete **manual path overview**. It deliberately avoids the
unsafe patterns found in many copy-paste phone guides: no hard-coded password in a
launcher, no raw append to `/etc/sudoers`, no world-writable system directories,
and no extraction of an uninspected archive directly over `/`.

The maintained copy/paste guide, including the complete Zink and VirGL launcher,
is [docs/MANUAL.md](docs/MANUAL.md).

### 1. Prepare Termux

```bash
termux-setup-storage
termux-change-repo
pkg update -y && pkg upgrade -y
pkg install x11-repo tur-repo -y
pkg install termux-x11-nightly pulseaudio proot-distro \
  virglrenderer-android zsh git curl wget nano tar termux-api -y
pkg install mesa-vulkan-icd-freedreno -y   # Adreno/Zink route; skip if unavailable
proot-distro install debian
```

`termux-change-repo` is interactive. Select reachable main and X11 mirrors. The
storage command triggers Android's permission dialog.

### 2. Install Debian desktop packages

```bash
proot-distro login debian --shared-tmp
```

Inside Debian as root:

```bash
apt update
DEBIAN_FRONTEND=noninteractive apt install -y \
  sudo nano dbus-x11 pulseaudio pulseaudio-utils x11-utils mesa-utils \
  libgl1-mesa-dri libvulkan1 vulkan-tools xfce4 xfce4-terminal \
  vlc colord polkitd locales zip unzip xarchiver unrar-free 7zip

adduser ternux
for group in sudo video render audio; do
  getent group "$group" >/dev/null && usermod -aG "$group" ternux
 done

printf '%s\n' 'ternux ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/ternux
chmod 0440 /etc/sudoers.d/ternux
visudo -cf /etc/sudoers.d/ternux
exit
```

Choose a password when `adduser` asks. The launcher does not store it. If you use a
different name, replace `ternux` consistently in every later command.

### 3. Install the Adreno Turnip files, or choose VirGL

For **Zink/Turnip**, first confirm the host node exists:

```bash
test -e /dev/kgsl-3d0 && echo "Adreno KGSL available" || echo "Use VirGL"
```

First verify that the guest reports `VERSION_CODENAME=trixie`, then use the latest
**Debian Trixie ARM64** asset from
[`lfdevs/mesa-for-android-container`](https://github.com/lfdevs/mesa-for-android-container/releases/latest).
A distribution-mismatched archive can overwrite incompatible Mesa components.
Download to a fixed temporary filename, validate it, stage it, and copy only the
Vulkan driver and ICD files:

```bash
URL="$(curl -fsSL https://api.github.com/repos/lfdevs/mesa-for-android-container/releases/latest \
  | grep -o '"browser_download_url": *"[^"]*debian[^"]*trixie[^"]*arm64\.tar\.gz"' \
  | head -n1 | sed 's/.*"browser_download_url": *"//; s/"$//')"
test -n "$URL" || { echo "No Debian Trixie ARM64 driver asset found"; false; }
curl -fL "$URL" -o "$TMPDIR/mesa-freedreno.tar.gz"
tar -tzf "$TMPDIR/mesa-freedreno.tar.gz" >/dev/null
! tar -tzf "$TMPDIR/mesa-freedreno.tar.gz" | grep -qE '^/|(^|/)\.\.(/|$)'
sha256sum "$TMPDIR/mesa-freedreno.tar.gz"
```

Then follow the staging/copy block in
[Manual installation → Zink/Turnip](docs/MANUAL.md#zink-turnip-adreno).
The release publisher does not currently provide a hash pinned by ternux, so record
the computed SHA-256 for your own rollback/audit rather than treating it as
publisher verification.

For **VirGL**, no guest Turnip archive is needed. Confirm the host helper exists:

```bash
command -v virgl_test_server_android
```

### 4. Configure audio, locale and fonts

On the Termux side, append the bridge only if it is absent:

```bash
PA="$PREFIX/etc/pulse/default.pa"
OLD='load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 port=4713'
NEW='load-module module-native-protocol-tcp listen=127.0.0.1 auth-ip-acl=127.0.0.1 auth-anonymous=1 port=4713'
SINK='load-module module-opensles-sink sink_name=Speaker'
DEFAULT='set-default-sink Speaker'
mkdir -p "$(dirname "$PA")"
if [ -L "$PA" ] || { [ -e "$PA" ] && [ ! -f "$PA" ]; }; then
  echo "PulseAudio config path is not a regular, non-symlink file: $PA" >&2
  false
else
  INPUT=/dev/null
  [ ! -f "$PA" ] || INPUT="$PA"
  if grep -E '^[[:space:]]*load-module[[:space:]]+module-native-protocol-tcp([[:space:]]|$)' "$INPUT" \
     | grep -Fvx -e "$OLD" -e "$NEW" | grep -q .; then
    echo "Custom PulseAudio TCP module found; review it instead of overwriting it." >&2
    false
  elif TMP="$(mktemp "${PA}.ternux.XXXXXX")"; then
    awk -v old="$OLD" -v new="$NEW" '
      $0 == old || $0 == new { if (!seen) print new; seen=1; next }
      { print }
      END { if (!seen) print new }
    ' "$INPUT" > "$TMP" &&
    { grep -qxF "$SINK" "$TMP" || printf '%s\n' "$SINK" >> "$TMP"; } &&
    { grep -qxF "$DEFAULT" "$TMP" || printf '%s\n' "$DEFAULT" >> "$TMP"; } &&
    { [ ! -f "$PA" ] || chmod --reference="$PA" "$TMP" 2>/dev/null || true; } &&
    mv -f "$TMP" "$PA" || { rm -f "$TMP"; false; }
  else
    echo "Could not create a PulseAudio staging file." >&2
    false
  fi
fi
```

The server listens only on loopback; do not expose anonymous PulseAudio on a Wi-Fi
interface.

Inside Debian as your user:

```bash
mkdir -p ~/.config/pulse ~/.runtime
chmod 700 ~/.runtime
printf '%s\n' 'default-server = tcp:127.0.0.1:4713' > ~/.config/pulse/client.conf
sudo sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sudo locale-gen en_US.UTF-8
```

### 5. Create the launcher and aliases

The launcher must clean stale X11/audio processes, wait for the X socket, export
the selected Mesa variables, create a private runtime directory, start Xfce in a
D-Bus session, and release the wake lock on exit. Copy the complete reviewed block
for your backend from [docs/MANUAL.md](docs/MANUAL.md#create-launcher), then:

```bash
chmod +x ~/x.sh
bash -n ~/x.sh
```

Add basic aliases on the Termux side:

```bash
cat >> ~/.bashrc <<'EOF'
alias x='~/x.sh'
alias xgo='am start -n com.termux.x11/com.termux.x11.MainActivity 2>/dev/null; sleep 1; ~/x.sh'
alias killx='pkill -f termux-x11 || true; pulseaudio --kill 2>/dev/null || pkill -KILL -x pulseaudio || true; rm -f $TMPDIR/.X11-unix/X* $TMPDIR/.X*-lock $TMPDIR/.pulse-*/native'
alias db='proot-distro login debian --shared-tmp --user ternux'
alias droot='proot-distro login debian --shared-tmp'
EOF
source ~/.bashrc
```

### 6. Manual preflight

```bash
command -v termux-x11 pulseaudio proot-distro
proot-distro login debian --user ternux -- bash -lc \
  'command -v startxfce4 glxinfo pactl && sudo -n true'
bash -n ~/x.sh
```

If these pass, continue with the runtime verification below.

---

## Start, stop and verify

### Daily controls

```bash
xgo                  # open Termux:X11 and start the desktop
x                    # start when the Termux:X11 app is already open
killx                # stop the display/audio session and clear stale sockets

db                   # Debian shell as your regular user
droot                # Debian shell as root; use carefully
```

The installed CLI provides the same lifecycle plus diagnostics:

```bash
ternux start
ternux stop
ternux restart
ternux verify
ternux doctor
ternux repair
ternux info
ternux logs
```

### Verify the renderer

Start the desktop first, open Xfce Terminal, then run:

```bash
glxinfo -B
vulkaninfo --summary
pactl info
```

Healthy Adreno output should contain all of these ideas, though exact versions vary:

```text
OpenGL renderer string: zink ... Adreno ... MESA_TURNIP
OpenGL version string: 4.x ... Mesa ...
Vulkan device: Adreno ...
Server String: tcp:127.0.0.1:4713
```

A VirGL candidate route should name `virgl` or `virpipe`, not `llvmpipe`, but that
name alone does not prove host hardware acceleration or acceptable performance.
Test the target application on the actual device.

The check is not "did a window open?" A desktop can open while Mesa silently falls
back to CPU rendering. If `glxinfo -B` says `llvmpipe`, fix the renderer before
running a benchmark or claiming GPU acceleration.

### Structured diagnostics

```bash
ternux doctor --json
ternux info --json
ternux benchmark --json
```

`ternux benchmark` is a quick health benchmark. For a result directly comparable to
the attached evidence, use the exact commands and conditions in the next section.

---

## Reproduce the benchmark

From Xfce Terminal or a Debian shell connected to the active display:

```bash
sudo apt update && sudo apt install -y glmark2
mkdir -p ~/benchmarks

glxinfo -B | tee ~/benchmarks/glxinfo.txt
vulkaninfo --summary 2>&1 | tee ~/benchmarks/vulkan-summary.txt

glmark2 2>&1 | tee ~/benchmarks/glmark2-windowed.txt
glmark2-es2 --off-screen 2>&1 | tee ~/benchmarks/glmark2-es2-offscreen.txt
```

For useful, honest comparisons, record:

- phone model, SoC/GPU, Android version and ternux backend
- Mesa/renderer strings and benchmark version
- exact command, resolution, Xfce compositor and VSync environment
- battery level, charger state, approximate room/device temperature
- cold run versus repeated/warm run

Do not compare the windowed OpenGL score with the ES off-screen score as if one were
a percentage improvement. Do not discard warnings. Save the complete output, not
only the final score.

---

## Optional workloads

### llama.cpp with Vulkan

The automatic path is:

```bash
bash install.sh --with-llm
```

It builds the current `ggml-org/llama.cpp` source with `GGML_VULKAN=ON`. After adding
a legitimately obtained GGUF model, verify the runtime rather than trusting the
build flag alone:

```bash
db
cd ~/llama.cpp
./build/bin/llama-cli --list-devices
./build/bin/llama-bench -m models/YOUR_MODEL.gguf -ngl 99
```

A publishable result should include the model name/quantization, context, `ngl`,
prompt-processing (`pp`) and token-generation (`tg`) rates, build commit, backend
log, RAM and thermal conditions. No such numbers were present in the supplied
output, so ternux publishes none yet.

Keep `llama-server` on `127.0.0.1` unless you deliberately add authentication and
understand the network exposure.

### stable-diffusion.cpp with Vulkan

This is manual and experimental; it is not installed by an existing ternux flag:

```bash
db
sudo apt update
sudo apt install -y build-essential cmake git libvulkan-dev vulkan-tools glslc spirv-headers
git clone --recursive https://github.com/leejet/stable-diffusion.cpp ~/stable-diffusion.cpp
cmake -S ~/stable-diffusion.cpp -B ~/stable-diffusion.cpp/build \
  -DSD_VULKAN=ON -DCMAKE_BUILD_TYPE=Release
cmake --build ~/stable-diffusion.cpp/build --config Release -j"$(nproc)"
~/stable-diffusion.cpp/build/bin/sd-cli --help
```

The supplied Redmi Turbo 4 Pro notes report that this build succeeded. A successful
configure/build proves only that Vulkan support was compiled. Before reporting GPU
inference, save a verbose runtime log that names the Vulkan backend/device plus the
full model, seed, steps, dimensions and wall time for a completed image.

### Blender

```bash
bash install.sh --with-blender
```

The supplied Blender 4.3.2 system report proves that the OpenGL **viewport** reached
Zink/Turnip. It found no Cycles GPU device. Treat Cycles as CPU rendering unless
Blender explicitly lists a supported compute backend/device. Keep scenes modest,
reduce viewport samples and texture sizes, and save often.

### Development, media and administration

```bash
bash install.sh --with-dev
bash install.sh --with-media
bash install.sh --with-network
```

`--with-network` is for systems and networks you own or are explicitly authorised
to test. PRoot does not bypass Android's kernel, Wi-Fi or USB restrictions.
Third-party AI-agent install scripts, mining tools and offensive-security recipes
from personal setup notes are intentionally not part of the base ternux guide.

---

## Limits and safety

- **Not a VM:** Debian shares Android's kernel through PRoot.
- **No Android-root capabilities:** guest root can manage Debian files, but cannot load
  Android kernel modules, provide a real systemd boot or grant unrestricted hardware access.
- **GPU support varies:** Zink/Turnip is primarily the Adreno path; VirGL is fallback,
  not a guarantee for every Mali, PowerVR or Xclipse device.
- **Display acceleration is not compute acceleration:** an OpenGL renderer proves the
  viewport path, not Blender Cycles, llama.cpp or diffusion runtime offload.
- **Heat matters:** sustained builds, inference and rendering can throttle the phone,
  degrade the battery and trigger Android process management. Stop if the device is
  uncomfortably hot.
- **Back up before experiments:** `proot-distro backup debian --output ~/debian.tar.gz`.
- **Do not expose local services casually:** bind development and AI servers to
  `127.0.0.1` unless you add appropriate authentication/firewalling.

---

## FAQ

<details>
<summary><strong>Does ternux require root?</strong></summary>

No. Termux, PRoot Distro and Termux:X11 run in userspace. Root-only kernel and device
features remain unavailable.
</details>

<details>
<summary><strong>Will the one command install the Termux:X11 Android app?</strong></summary>

No. Install the Android APK from the official Termux:X11 nightly release first. The
script installs only its Termux-side companion package.
</details>

<details>
<summary><strong>Why did ternux select VirGL instead of Zink?</strong></summary>

Automatic selection uses the Adreno KGSL node. If `/dev/kgsl-3d0` is not available,
it falls back to VirGL. Do not force Zink on a non-Adreno device merely to make the
configuration say `zink`.
</details>

<details>
<summary><strong>Does glmark2 score 140 mean the desktop always runs at 140 FPS?</strong></summary>

No. It is a suite aggregate. The measured windowed scenes ranged from 45 to 164 FPS,
and real applications have different workloads and may be limited by the screen's
refresh rate, compositor or CPU.
</details>

<details>
<summary><strong>Is the off-screen score 364 more than twice as fast as 140?</strong></summary>

That conclusion is invalid. The commands use different APIs/modes, and the ES run
also emitted a DRI3 warning while its header still reported a windowed surface.
Compare only identical commands and conditions.
</details>

<details>
<summary><strong>Why does Blender say SOFTWARE when the renderer says Adreno/Turnip?</strong></summary>

The report confirms Blender's OpenGL viewport used the Zink/Turnip renderer, but
Blender classified that OpenGL backend as `SOFTWARE` and found no Cycles device.
Use the exact renderer and backend fields; do not reinterpret it as proven Cycles
GPU Compute.
</details>

<details>
<summary><strong>Does a Vulkan build of llama.cpp or stable-diffusion.cpp prove GPU use?</strong></summary>

No. Build flags establish compiled capability. Runtime proof requires a log naming
the Vulkan device/backend and a reproducible benchmark or completed workload.
</details>

<details>
<summary><strong>Can I install normal Debian packages?</strong></summary>

Yes: run `db`, then use `sudo apt install <package>`. Packages that require kernel
modules, systemd services or unsupported hardware access may not work under PRoot.
</details>

<details>
<summary><strong>Where are my files?</strong></summary>

Debian home is inside the container. Android shared storage is available through
Termux's `~/storage/shared` and is normally linked as `/sdcard` in the guest. Keep
important code in Git and make container backups.
</details>

More answers: [docs/FAQ.md](docs/FAQ.md).

---

## Troubleshooting

Start with evidence, not random environment variables:

```bash
ternux doctor
ternux info
ternux logs show 100
```

| Symptom | Check | First repair |
|---|---|---|
| Black screen / no Xfce | `pgrep -af termux-x11`; `ls "$TMPDIR/.X11-unix"` | `ternux stop`; reopen Termux:X11; `ternux start` |
| `connection refused` on display | `echo "$DISPLAY"`; `xdpyinfo -display :0` | Ensure `DISPLAY=:0` and the shared X11 socket exists |
| Renderer says `llvmpipe` | `glxinfo -B` | Set `zink` on supported Adreno or `virgl` otherwise; run `ternux repair`, then restart and recheck |
| Zink fails / no Adreno device | `ls -l /dev/kgsl-3d0`; `vulkaninfo --summary` | Use VirGL without KGSL; on supported Adreno, `ternux repair` can restore missing validated Turnip targets and regenerate the launcher |
| DRI3 warning in ES benchmark | Save stderr and renderer string | Treat the run as caveated; do not hide the warning or compare modes |
| No sound | `pactl info`; `ss -ltn | grep 4713` in Termux | `ternux restart`; verify loopback PulseAudio config |
| Desktop dies during builds | Android setting, memory pressure, OEM battery policy; `ternux doctor` | Reduce parallelism and follow the evidence-led Android process checks |
| `apt` DNS failure | `getent hosts deb.debian.org` inside Debian | Restart network/session; then use the DNS repair in the full guide |
| Build says Vulkan but runtime uses CPU | app `--list-devices` / verbose backend log | Check `vulkaninfo`, rebuild cleanly, pass the app's Vulkan device/offload option |
| Phone is hot / performance falls | repeat score after cooldown | Stop workload, cool device, reduce threads/model/scene, retest consistently |

Never solve renderer issues by forcing fake OpenGL version strings alone. A version
string can change what an app attempts; it cannot create missing Vulkan features or
hardware acceleration.

Full symptom-by-symptom repair guide: [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).

---

## Documentation

| Guide | Contents |
|---|---|
| [Documentation overview](https://soobujmiah.github.io/ternux/docs/) | Task-based map, installation chooser and evidence vocabulary |
| [Quick start](docs/QUICK-START.md) | Fast install, first launch and renderer verification |
| [Installation](docs/INSTALLATION.md) | Automatic installer, phases, profiles, update and removal |
| [Manual installation](docs/MANUAL.md) | Auditable command-by-command setup and full launchers |
| [Usage](docs/USAGE.md) | Daily controls, storage, workloads, backups and heat |
| [Configuration](docs/CONFIGURATION.md) | Graphics routes, launch variables, audio, locale and files |
| [Troubleshooting](docs/TROUBLESHOOTING.md) | Symptom → diagnosis → safe repair |
| [Architecture](docs/ARCHITECTURE.md) | X11, audio, PRoot and GPU data paths |
| [Benchmarks](docs/BENCHMARKS.md) | Device evidence, all FPS values, caveats and reproduction |
| [FAQ](docs/FAQ.md) | Common installation, graphics and benchmark questions |
| [CLI reference](docs/CLI.md) | Commands, flags and explicit structured-output coverage |
| [Contributing](CONTRIBUTING.md) | Code, translation, patches and classified device evidence |
| [Security](SECURITY.md) | Private vulnerability reporting |

### Upstream technical references

- [Termux installation](https://github.com/termux/termux-app#installation)
- [Termux:X11 setup](https://github.com/termux/termux-x11#setup-instructions)
- [PRoot Distro](https://github.com/termux/proot-distro)
- [Termux PulseAudio package recipe (upstream PulseAudio 17)](https://github.com/termux/termux-packages/blob/master/packages/pulseaudio/build.sh)
- [PulseAudio 17 TCP protocol source (`listen` and `port` arguments)](https://github.com/pulseaudio/pulseaudio/blob/v17.0/src/modules/module-protocol-stub.c)
- [PulseAudio network authorization and exposure warning](https://www.freedesktop.org/wiki/Software/PulseAudio/Documentation/User/Network/)
- [Mesa Zink documentation](https://docs.mesa3d.org/drivers/zink.html)
- [glmark2](https://github.com/glmark2/glmark2)
- [Blender GPU rendering documentation](https://docs.blender.org/manual/en/4.3/render/cycles/gpu_rendering.html)
- [llama.cpp Vulkan build](https://github.com/ggml-org/llama.cpp/blob/master/docs/build.md#vulkan)
- [stable-diffusion.cpp Vulkan build](https://github.com/leejet/stable-diffusion.cpp/blob/master/docs/build.md#build-with-vulkan)

---

## Uninstall

```bash
ternux uninstall
```

Or, from a cloned repository:

```bash
bash uninstall.sh
```

Back up Debian first if it contains anything important. `ternux uninstall all`
removes only its four documented targets (session, launcher/aliases, state/logs,
and the Debian container); it deliberately leaves installed Termux packages,
the ternux CLI/libraries, repository/storage choices, and Termux PulseAudio
configuration in place.

---

## License

[MIT](LICENSE) © 2026 [Sobuj Miah](https://github.com/soobujmiah)
