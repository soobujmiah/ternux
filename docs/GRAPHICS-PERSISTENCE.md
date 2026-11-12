---
title: "Keeping the GPU driver across updates"
description: "Why a newer Turnip is required on recent Adreno devices, how package updates can remove it, and the apt-safe layout that prevents it."
lang: "en"
alt_url: "/bn/docs/GRAPHICS-PERSISTENCE.html"
---

On recent Adreno hardware the Vulkan driver shipped by Debian can be too old to
recognise the GPU at all. ternux's Zink route then has no Vulkan device to build
OpenGL on, so a newer Turnip is not a performance tweak — it is the reason the
GPU is usable. This page explains how to install it so that a routine package
update cannot take it away, because a reverted driver is easy to miss: the
desktop keeps starting, only slower or not accelerated at all.

> **Device evidence, 2026-10-13, Redmi Turbo 4 Pro (Adreno 825):** with Debian
> trixie's `mesa-vulkan-drivers 25.0.7-2+deb13u1`, `vulkaninfo` reported **no
> Adreno device** — only `llvmpipe` as `PHYSICAL_DEVICE_TYPE_CPU`. With a
> locally built Turnip (Mesa 26.3.0-devel) the same command reported
> `Adreno (TM) 825`, `PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU`. One device, one
> configuration; see [Evidence & benchmarks](BENCHMARKS.html) for the result
> classes used here.

## How Ternux reports graphics readiness

`ternux info` and `ternux profile` distinguish Vulkan device readiness from
OpenGL rendering. A visible KGSL node, Vulkan loader, or ICD manifest is not
reported as hardware acceleration by itself. Ternux runs `vulkaninfo --summary`
in the Debian guest with the available KGSL device bound in, then checks the
physical device type and driver. The `vulkan_state` value is one of
`NOT_DETECTED`, `HARDWARE_AVAILABLE`, `LOADER_MISSING`, `DRIVER_MISSING`,
`ICD_MISSING`, `DEVICE_ENUMERATION_FAILED`, `VULKAN_READY`, or
`SOFTWARE_FALLBACK`. `graphics_state` reports `OPENGL_ACCELERATION_READY` only
when `glxinfo` identifies a live non-software renderer.

On the connected Redmi Turbo 4 Pro, the Termux host Vulkan probe failed with
`VK_ERROR_INCOMPATIBLE_DRIVER`; the Debian guest probe enumerated Adreno 825
through Turnip plus a separate llvmpipe device. The source CLI therefore
reported `vulkan_state=VULKAN_READY`, and the live X11 probe identified
`zink Vulkan 1.4(Adreno (TM) 825 (MESA_TURNIP))`. These are current device
observations, not claims for other devices.

## Two layouts, and why only one survives apt

| | Debian Turnip layout | Distro bundle overlay | Fragile layout |
|---|---|---|---|
| Driver | `/usr/local/lib/aarch64-linux-gnu/libvulkan_freedreno.so` | `/usr/local/lib/ternux/<Mesa bundle>/lib/aarch64-linux-gnu/libvulkan_freedreno.so` | `/usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so` |
| ICD manifest | `/usr/local/share/vulkan/icd.d/ternux_freedreno_icd.json` | `<overlay>/share/vulkan/icd.d/ternux_freedreno_icd.json` | `/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json` |
| Owned by a distro package? | No — `/usr/local` is outside dpkg's reach | No — the exact-match Mesa bundle stays under `/usr/local/lib/ternux` | Yes — the path belongs to `mesa-vulkan-drivers` |
| Runtime selection | Loader search path | Ternux desktop sets `LD_LIBRARY_PATH`, `LIBGL_DRIVERS_PATH`, and `VK_DRIVER_FILES` to the matching overlay | Distro default |
| After package upgrade | Unchanged | Unchanged; distro Mesa files remain package-owned and untouched | Replaced by the distro package version |
| `dpkg -V mesa-vulkan-drivers` | quiet | quiet | reports `??5??????` for an overwritten driver |

The fragile layout works until the first package operation that touches
`mesa-vulkan-drivers` — an upgrade, a security update, or
`apt install --reinstall`. dpkg then restores its own file, as it is designed
to, and the newer driver is gone.

The Vulkan loader searches `/usr/local/share/vulkan/icd.d` as well as
`/usr/share/vulkan/icd.d`, so the managed layout needs no environment variable
and no launcher changes.

Ternux's GPU phase installs the upstream Debian Trixie arm64 Turnip archive in
the Debian managed layout. For Ubuntu and other supported profiles that use a
full distro-matched Mesa archive, it extracts the bundle to a versioned
`/usr/local/lib/ternux` overlay and selects that matching Mesa stack only in
the Ternux desktop session. It does not extract the archive into `/`, replace
dpkg-owned driver files, or globally change the system loader configuration.
The source pins release `mesa-27.0.0-devel-20261025` and
checks SHA-256 `b711d1d9ab5537ee9085da8896dfe2115e791b33aa317fe37538f276c967d687`
before extraction. On 2026-11-07, this exact archive's checksum matched the
upstream release manifest; its staged AArch64 driver resolved dynamic
dependencies on the connected Debian guest, and Vulkan enumeration plus Zink
GLX identified Adreno 825. A short interleaved Qwen2.5 0.5B Vulkan run measured
27.2 tok/s median on staged 27.0 versus 26.6 on the installed 26.3 driver. This
three-run, one-device sample is not a sustained performance claim. Ternux
downloads the archive from its upstream project; it does not build or host Mesa.

> **Ubuntu 26.04 live verification, 2026-11-12:** on the qualified Redmi Turbo
> 4 Pro, the Ubuntu Turnip asset was installed into its Ternux overlay. The
> distro package `mesa-vulkan-drivers` was then reinstalled from Ubuntu and
> `dpkg -V mesa-vulkan-drivers` returned no differences; no Mesa packages were
> held. With the overlay-selected ICD, `vulkaninfo --summary` enumerated one
> Adreno 825 integrated GPU and `glxinfo -B` reported direct rendering with
> `zink Vulkan 1.4(Adreno (TM) 825 (MESA_TURNIP))`. `ternux doctor --json`
> reported the overlay as managed and the renderer as accelerated. This is a
> one-device observation; other Ubuntu releases still need their own live test.

> **Alpine 3.24 live verification, 2026-11-12:** its pinned archive uses
> `/usr/lib` instead of Debian-family `/usr/lib/aarch64-linux-gnu`. The
> installer now records and validates the archive's actual library directory
> in `/etc/ternux/mesa-overlay-libdir`, while retaining the isolated overlay
> and selecting it only for Ternux sessions. A fresh managed install
> completed, `tx doctor --json` enumerated the Adreno 825 Vulkan device, and
> live Alpine desktop `:2` reported Zink on Mesa Turnip. This qualifies this
> device/profile only, not every Alpine version.

## Check which layout you have

```bash
ternux verify
```

`turnip:present` means the managed layout. `turnip:fragile` means the driver is
on a dpkg-owned path and will be reverted. `turnip:missing` means neither was
found.

Inside the Debian guest you can confirm directly:

```bash
vulkaninfo --summary | grep -E "deviceName|deviceType|driverInfo"
dpkg -V mesa-vulkan-drivers
```

One `Adreno` entry with a `driverInfo` newer than Debian's package version, and
a quiet `dpkg -V`, is the healthy state.

## Move an existing install to the managed layout

Run these inside the Debian guest. Back up first: the custom driver may be the
only copy you have, and nothing on the device can rebuild it.

```bash
# 1. Back up the driver and its manifest, with checksums
mkdir -p ~/mesa-backup && cd ~/mesa-backup
cp -a /usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so .
cp -a /usr/share/vulkan/icd.d/freedreno_icd.aarch64.json . 2>/dev/null || true
sha256sum libvulkan_freedreno.so > MANIFEST.sha256

# 2. Install it where apt cannot reach
sudo mkdir -p /usr/local/lib/aarch64-linux-gnu /usr/local/share/vulkan/icd.d
sudo install -m 0755 libvulkan_freedreno.so \
  /usr/local/lib/aarch64-linux-gnu/libvulkan_freedreno.so
sudo tee /usr/local/share/vulkan/icd.d/ternux_freedreno_icd.json >/dev/null <<'JSON'
{
    "ICD": {
        "api_version": "1.4.359",
        "library_arch": "64",
        "library_path": "/usr/local/lib/aarch64-linux-gnu/libvulkan_freedreno.so"
    },
    "file_format_version": "1.0.1"
}
JSON

# 3. Remove the manifest that lived in dpkg's territory
sudo rm -f /usr/share/vulkan/icd.d/freedreno_icd.aarch64.json

# 4. Retire Debian's own manifest so the GPU is not enumerated twice
sudo dpkg-divert --add --rename \
  --divert /usr/share/vulkan/icd.d/freedreno_icd.json.distrib \
  /usr/share/vulkan/icd.d/freedreno_icd.json

# 5. Hand the dpkg-owned path back to Debian
sudo apt-get install -y --reinstall mesa-vulkan-drivers
```

Set `api_version` in step 2 to the value from your own manifest, not the one
printed here — it describes the driver you built.

Then verify that the GPU survived the reinstall in step 5:

```bash
vulkaninfo --summary | grep -E "deviceName|driverInfo"
dpkg -V mesa-vulkan-drivers
```

Exactly one `Adreno` entry with your own driver version, and no `dpkg -V`
output, means the migration worked. The diversion is recorded in dpkg's
database, so it persists across upgrades; `dpkg-divert --list | grep freedreno`
shows it, and `dpkg-divert --remove` undoes it.

## Why the GPU may appear twice

Two ICD manifests pointing at the same library make the loader report the same
GPU twice, with an identical `deviceUUID`. It is confusing rather than harmful,
and step 4 above resolves it. The duplicate was not the cause of any crash we
tested: pinning `VK_DRIVER_FILES` to a single manifest did not change the
outcome of a failing Vulkan-backend test.

## If an update already reverted the driver

The symptom is a desktop that still starts while GPU work becomes slow or
unavailable, and `vulkaninfo` no longer listing the Adreno. Restore the driver
from your backup, then follow the migration above so it does not happen again.
Without a backup the driver has to be rebuilt; ternux does not yet ship a
released Turnip artifact, which is tracked as a release gate in
[the accelerator release plan](ACCELERATOR-RELEASE-PLAN.html).

Software rasterisation is not a usable fallback on every device: on the tested
device, forcing it (`LIBGL_ALWAYS_SOFTWARE=1`) ended in an immediate `SIGILL`
rather than a slow render. Treat "it will just fall back to software" as
unverified until measured on your own hardware.

## Boundaries

- The evidence above is from one device and one configuration. A different
  Adreno generation may be fully supported by Debian's own Mesa, in which case
  none of this applies.
- Whether a running Xfce session survives a mid-session driver revert was not
  tested; doing so would mean deliberately breaking a live desktop.
- ternux does not build or distribute Mesa. These steps describe where to place
  a driver you supply, not how to produce one.

For symptom-led diagnosis see [Troubleshooting](TROUBLESHOOTING.html), and for
graphics route selection see [Configuration](CONFIGURATION.html).
