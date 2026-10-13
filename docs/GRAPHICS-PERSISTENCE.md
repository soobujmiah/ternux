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

## Two layouts, and why only one survives apt

| | Managed layout | Fragile layout |
|---|---|---|
| Driver | `/usr/local/lib/aarch64-linux-gnu/libvulkan_freedreno.so` | `/usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so` |
| ICD manifest | `/usr/local/share/vulkan/icd.d/ternux_freedreno_icd.json` | `/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json` |
| Owned by a package? | No — `/usr/local` is outside dpkg's reach | Yes — the path belongs to `mesa-vulkan-drivers` |
| After `apt upgrade` | Unchanged | Replaced by Debian's version |
| `dpkg -V mesa-vulkan-drivers` | quiet | reports `??5??????` for the driver |

The fragile layout works until the first package operation that touches
`mesa-vulkan-drivers` — an upgrade, a security update, or
`apt install --reinstall`. dpkg then restores its own file, as it is designed
to, and the newer driver is gone.

The Vulkan loader searches `/usr/local/share/vulkan/icd.d` as well as
`/usr/share/vulkan/icd.d`, so the managed layout needs no environment variable
and no launcher changes.

Ternux's GPU phase installs the upstream Debian Trixie arm64 Turnip archive in
this managed layout. The source pins release `mesa-26.3.0-devel-20260824` and
checks SHA-256 `c014cf66bdbff96417ee30d34f006cf51df64ae04893d599711b0b6b73b52ccf`
before extraction. This makes the downloaded input reproducible; it does not
mean Ternux builds or redistributes Mesa.

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
