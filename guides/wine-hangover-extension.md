# Windows programs with Wine + Hangover (ARM64) — experimental extension

This repository guide covers the automatic Ternux installer and a manual,
checksum-verified installation of [Hangover](https://github.com/AndreRH/hangover),
a Wine build that runs x86 and x86-64 Windows programs on ARM64 Linux. It is an
**experimental** extension: it works on the tested device, but it is not a
qualified release feature. The measured results are in the
[device qualification record](#device-qualification-record).

## Scope and requirements

- Hangover **11.16** (Wine 11.16; the upstream release notes list FEX 2608 and
  Box64 v0.4.4), the `hangover_11.16_debian13_trixie_arm64.tar` asset of the
  upstream release `hangover-11.16`. Ternux does not rebuild or mirror it: the
  installer downloads the upstream asset and pins its SHA-256.
- Run it inside Ternux's Debian **13 (trixie)** ARM64 guest. The installer
  command runs in the Termux host and delegates to the guest; the manual route
  runs in Debian. Other distributions need their own Hangover asset and are
  refused.
- glibc 2.38 or newer (the tested guest has 2.41) and about 4 GB of free space
  while installing. The installed extension is about 2.3 GB; **each Wine
  prefix adds about 2.3 GB** more, because Wine 11 copies its DLLs into the
  prefix.
- Debian runtime packages: `libasound2t64 libavcodec61 libavformat61
  libavutil59 libglib2.0-0t64 libgphoto2-6t64 libgphoto2-port12t64
  libgstreamer-plugins-base1.0-0 libgstreamer1.0-0 libpulse0 libsane1 libudev1
  libusb-1.0-0 libwayland-client0 libwayland-egl1 libx11-6 libxext6
  libxkbcommon0 libxkbregistry0 libncurses6 libfreetype6 libfontconfig1
  libxrender1 libxrandr2 libxcursor1 libxi6 libxcomposite1 libxfixes3
  libxinerama1 libxxf86vm1 libgnutls30t64`. The installer checks them before it
  downloads anything and prints the exact `sudo apt install` line if some are
  missing. On a full Ternux desktop only `libxkbregistry0` was absent.
- A display: the Ternux Termux:X11 desktop, or Xvfb for headless use.
- There is no `binfmt_misc` in PRoot, so Windows programs are started as
  `wine program.exe`, not by running the `.exe` directly.
- This is not a Windows compatibility promise. See what was and was not tested
  in the [qualification record](#device-qualification-record).

## Route A: automatic install (recommended)

In **Termux**, list the extensions and install it:

```bash
ternux extension list
ternux extension install wine-hangover
```

The host CLI delegates to the selected Debian guest. The guest-side installer:

1. checks Linux ARM64, glibc, Debian 13, free space and the Debian runtime
   packages above, and stops before any download if one check fails;
2. downloads the 293 MB upstream tarball and compares its SHA-256 with the
   value pinned in `lib/extension.sh` (the same digest GitHub publishes for the
   release asset): `b5493f5903ab3c05f78bf4c03b06ac0005eb26f732437748c1592fefa45e861a`;
3. accepts only the five expected members, checks every path and link inside
   each `.deb`, and unpacks them with `dpkg-deb` into your home. No root is
   used, the dpkg database is not changed, and the packages' headers and man
   pages are left out;
4. writes `env.sh` and `build-manifest.json`, runs `wine --version` from the
   staged copy, and only then moves the directory into place atomically:

```text
$HOME/.local/opt/ternux-extensions/wine-hangover
```

An existing destination is never overwritten, and a failure at any step leaves
no files and no staging directory. To replace an installation, inspect it and
remove that exact directory yourself, then repeat the command. Your Wine
prefixes and programs are separate and are not touched.

## First run and running programs

In Debian, load the environment and create a prefix. The first run takes about
3 to 4 minutes and creates a prefix of about 2.3 GB (a different prefix can be
chosen with `WINEPREFIX`):

```bash
source "$HOME/.local/opt/ternux-extensions/wine-hangover/env.sh"
wine --version
WINEDLLOVERRIDES="mscoree=d;winemenubuilder.exe=d" wine wineboot -u
```

`mscoree=d` skips the wine-mono download that upstream warns is broken in
this release, and `winemenubuilder.exe=d` skips desktop-menu integration. The
upstream alternative is `WINEDEBUG=wininet wine wineboot -u`. Programs that
need .NET need wine-mono, which this extension does not install.

Run a program with a display available. Console programs need none of the
graphics settings below:

```bash
wine ./your_program.exe
```

Hangover chooses the x86 emulator per program type; both come with the package:

| Program type | Default emulator | How to choose another |
|---|---|---|
| x86-64 | FEX through ARM64EC (`libarm64ecfex.dll`) | `HODLL64=libarm64ecfex.dll` |
| x86 (32-bit) | Box64 (`wowbox64.dll`) | `HODLL=libwow64fex.dll` selects FEX |

### Graphics: GPU first, CPU fallback

`env.sh` follows Ternux's own backend rule and never forces a backend you did
not ask for:

1. If `GALLIUM_DRIVER` is already set it is kept. A terminal inside the Ternux
   desktop session inherits the session's driver: `zink` on Adreno, `virpipe`
   (VirGL, served by the Termux host) on other GPUs.
2. Otherwise, if the Adreno KGSL node is visible (`/dev/kgsl-3d0`, or
   `/dev/kgsl` where Ternux binds it into the guest), it sets
   `GALLIUM_DRIVER=zink` so OpenGL runs on the GPU through Zink and Mesa
   Turnip.
3. Otherwise it sets nothing and Mesa uses its CPU renderer (llvmpipe).

Force the CPU path at any time with `GALLIUM_DRIVER=llvmpipe wine ...`. Check
what a Windows OpenGL program actually gets by running a program that prints
its renderer; `experiments/wine-hangover/validate.sh` does this with GLEW's
`glewinfo.exe`. `ternux doctor extensions` reports the path `env.sh` selects.

For headless use under Xvfb, start it with GLX enabled:

```bash
Xvfb :77 -screen 0 1024x768x24 +extension GLX +render -noreset &
export DISPLAY=:77
```

Zink's output is not visible on Xvfb in this environment (see the
[qualification record](#device-qualification-record)), so use the Termux:X11
desktop when you need to see a GPU-rendered window.

## Route B: manual install

Use this to inspect and verify the release yourself or when the host extension
command is unavailable. Run everything in the **Debian guest**, as your normal
user. It installs a versioned directory that does not collide with Route A.

Check the baseline and install the runtime packages (the list in
[Scope and requirements](#scope-and-requirements)):

```bash
getconf GNU_LIBC_VERSION   # glibc 2.38 or newer
grep -E '^(ID|VERSION_ID)=' /etc/os-release   # debian, 13
sudo apt install libasound2t64 libavcodec61 libavformat61 libavutil59 \
  libglib2.0-0t64 libgphoto2-6t64 libgphoto2-port12t64 \
  libgstreamer-plugins-base1.0-0 libgstreamer1.0-0 libpulse0 libsane1 libudev1 \
  libusb-1.0-0 libwayland-client0 libwayland-egl1 libx11-6 libxext6 \
  libxkbcommon0 libxkbregistry0 libncurses6 libfreetype6 libfontconfig1 \
  libxrender1 libxrandr2 libxcursor1 libxi6 libxcomposite1 libxfixes3 \
  libxinerama1 libxxf86vm1 libgnutls30t64
```

Download the asset and verify it against the pinned digest:

```bash
ASSET=hangover_11.16_debian13_trixie_arm64.tar
WORK="$(mktemp -d)"
cd "$WORK"
curl -fL --retry 3 -o "$ASSET" \
  "https://github.com/AndreRH/hangover/releases/download/hangover-11.16/$ASSET"
echo "b5493f5903ab3c05f78bf4c03b06ac0005eb26f732437748c1592fefa45e861a  $ASSET" | sha256sum -c -
```

Only continue if the check prints `OK`. Inspect the archive, then unpack it into
a new directory (these are the five expected members):

```bash
tar -tf "$ASSET"
mkdir dl root
tar --no-same-owner -xf "$ASSET" -C dl
for deb in dl/hangover-*.deb; do
  dpkg-deb -f "$deb" Package Version
  dpkg-deb --fsys-tarfile "$deb" | tar -tv | grep -E '^h| -> /|\.\./' && echo "STOP: unsafe entry in $deb"
done
```

Stop if anything is printed after `STOP`. Otherwise unpack into a versioned
destination that does not exist yet and test it:

```bash
DEST="$HOME/.local/opt/ternux-extensions/wine-hangover-11.16"
test ! -e "$DEST" && test ! -L "$DEST" || { echo "exists: $DEST" >&2; exit 1; }
for deb in dl/hangover-*.deb; do
  dpkg-deb --fsys-tarfile "$deb" |
    tar --no-same-owner -x -C root --exclude=./usr/include --exclude=./usr/share/man
done
mkdir -p "$(dirname "$DEST")"
mkdir -p "$DEST/share"
mv root/usr/bin "$DEST/bin"
mv root/usr/lib "$DEST/lib"
mv root/usr/share/wine "$DEST/share/wine"
"$DEST/bin/wine" --version     # expect: wine-11.16 (Hangover)
```

The manual route does not create `env.sh`, the manifest, or the GPU/CPU
selection. Use the variables directly:

```bash
export PATH="$DEST/bin:$PATH" WINEPREFIX="$HOME/.wine"
export GALLIUM_DRIVER=zink      # GPU through Zink/Turnip; omit it for the CPU fallback
WINEDLLOVERRIDES="mscoree=d;winemenubuilder.exe=d" wine wineboot -u
```

Manual installation verifies the archive hash and package paths, but it lacks
the checks, atomic move and smoke test of Route A. Keep the verified archive if
you want an audit trail.

## Troubleshooting and removal

- **`ternux: command not found` in Termux:** install or update Ternux and run
  the command in the Termux host shell, not in Debian.
- **"Missing Debian runtime packages":** run the `sudo apt install` line the
  installer printed, then repeat the command. Nothing was downloaded.
- **"requires glibc 2.38" or "built for Debian 13":** this guest is not the
  verified Debian 13 guest. The extension will not install there.
- **First `wineboot` seems stuck:** a first run takes minutes. Do not set
  `WINEDEBUG=+all`; tracing every channel makes Wine many times slower. Use the
  default quiet `WINEDEBUG=-all` that `env.sh` sets.
- **A GPU window is black on Xvfb:** Zink output does not reach the Xvfb frame
  buffer here; llvmpipe windows do. Use Termux:X11, or force the CPU path with
  `GALLIUM_DRIVER=llvmpipe` to see the window.
- **A program fails but `wine --version` works:** run `ternux doctor
  extensions --json` and read the `ext_wine_*` rows, then try the other
  emulator for 32-bit programs with `HODLL=libwow64fex.dll`.
- **Existing destination:** inspect the named path before removing it. Route A
  and Route B use separate directories.

To remove only the automatic install, inspect then remove its exact path:

```bash
ls -la "$HOME/.local/opt/ternux-extensions/wine-hangover"
rm -rf -- "$HOME/.local/opt/ternux-extensions/wine-hangover"
```

For the manual route use `wine-hangover-11.16`. Wine prefixes (`~/.wine` by
default, about 2.3 GB each) and the cached download are separate and are not
removed by these commands.

## Device qualification record

On 2026-10-17 I installed the extension, created a prefix and ran real Windows
programs on the Redmi Turbo 4 Pro workstation: Termux with PRoot Debian 13
arm64, glibc 2.41, Debian's Mesa 25.0.7-2+deb13u1. Vulkan lists the Adreno 825
(Turnip, Vulkan 1.4) and an `llvmpipe` device. I ran the guest-side installer
function directly in that Debian guest (`_tnx_extension_guest_dispatch install
wine-hangover`) with an isolated `HOME`; the Termux-host wrapper that delegates
into the guest was not exercised on the device and is covered only by the
repository's mocked delegation test. Labels follow the repository's convention:
**verified**, **observed**, **measured**, **untested**.

### Installation and prefix

- **Verified:** the SHA-256 pinned in `lib/extension.sh` equals both the digest
  GitHub's API publishes for the release asset and the hash of my download
  (`b5493f59…861a`, 293,099,520 bytes).
- **Verified:** with `libxkbregistry0` (the only missing package, 87 KB) absent,
  the installer refused before any download and created nothing. After
  `sudo apt install libxkbregistry0` the install finished and
  `wine --version` printed `wine-11.16 (Hangover)`.
- **Measured:** the install took 55 s including the 293 MB download. The
  extension is 2.3 GB in 2,326 files.
- **Measured:** the first `wineboot -u` took 188 s by hand and 221 s inside the
  validation script. The resulting prefix is 2.3 GB (2,043 regular files, because
  Wine copies its DLLs). An earlier attempt of mine with every Wine debug channel
  enabled (`WINEDEBUG=+all`) had not finished after 10 minutes and was stopped.
- **Verified:** `experiments/wine-hangover/validate.sh` run against this install:
  15 of 15 checks passed, exit status 0. The repository's focused tests
  (88, including 18 new ones for the installer and doctor) pass.

### Programs that ran

All are real programs downloaded from their publishers' release pages. The
first four rows are exercised by `experiments/wine-hangover/validate.sh`, and
the benchmark rows by `experiments/wine-hangover/benchmark.sh`; both pin every
download's SHA-256.

| Program | Type | Result |
|---|---|---|
| Python 3.13.1 embeddable | 32-bit x86 (Box64) | printed `PY 32` |
| Python 3.13.1 embeddable | 64-bit x86-64 (FEX) | printed `PY 64` |
| GLEW 2.2.0 `glewinfo.exe` | 32-bit and 64-bit | created an OpenGL context and reported the renderer (next section) |
| 7-Zip 23.01 installers | 32-bit and 64-bit | silent `/S` install; `7z a` then `7z t` reported `Everything is Ok`; the archives carry the 7z signature |
| ChimbaBenchXPL A3 (GPL-3.0 OpenGL benchmark) | 32-bit and 64-bit | completed its "Simple Test" and wrote a score |

**Observed:** by default a 32-bit program runs on Box64 and a 64-bit program on
FEX (the log prints `WowBox64 arm64 v0.4.4 (Hangover 11.16)` and `starting FEX
(Hangover 11.16) based libarm64ecfex.dll`); `HODLL=libwow64fex.dll` ran 32-bit
programs on FEX as well.

### Graphics: GPU and CPU fallback

**Observed:** `glewinfo.exe` prints the renderer of the context it gets.

| Setting | 32-bit and 64-bit result |
|---|---|
| `env.sh` default (KGSL node visible) | `zink Vulkan 1.4(Adreno (TM) 825 (MESA_TURNIP))` |
| `GALLIUM_DRIVER=llvmpipe` | `llvmpipe (LLVM 19.1.7, 128 bits)` |

**Verified:** `env.sh` keeps a `GALLIUM_DRIVER` that is already set, picks `zink`
when the KGSL node is visible, and leaves the variable unset when it is not
(the CPU fallback). The unit tests cover those three cases, and I checked a
pre-set `virpipe` by hand.

### Benchmarks

**ChimbaBenchXPL A3** (a Godot-based OpenGL 2.1 benchmark; release asset
digest `81321e4c…b803` matches GitHub's). "Simple Test", 640×360, three runs per
cell; the project's result database labels the score as FPS.

| Program | CPU path (`llvmpipe`) | GPU path (Zink/Turnip) | GPU / CPU (means) |
|---|---|---|---|
| 32-bit (Box64) | 91, 82, 79 (mean 84.0) | 128, 126, 112 (mean 122.0) | 1.45× |
| 64-bit (FEX) | 91, 90, 83 (mean 88.0) | 179, 180, 185 (mean 181.3) | 2.06× |

These are **measured** scores with limits that matter. On Xvfb the Zink window
stays black in every test I ran, including native `glxgears` (llvmpipe windows
are visible), so I could not confirm that the GPU runs drew the scenes
correctly; read the GPU column as unverified. The benchmark prints the adapter
name Wine reports (`Adreno (TM) 825`) in both modes, so its header does not
show which renderer ran; the renderer was set by `GALLIUM_DRIVER`, and GLEW
confirmed what each setting selects. KGSL load counters are not readable from
the guest. Only this scene was run, with all cells of one program type run
together rather than interleaved.

**7-Zip `b -mmt8`** total rating (higher is faster), three passes. Native is
Debian's `7zip` 25.01 package; the Wine rows run the 7-Zip 23.01 installed in
the prefix.

| Pass | Native arm64 | Wine x86-64 (FEX) | Wine x86 (Box64) | Wine x86 (FEX) |
|---|---|---|---|---|
| 1 | 17,683 | 11,465 | 8,986 | 8,750 |
| 2 | 13,874 | 10,085 | 8,284 | 9,127 |
| 3 | 14,713 | 10,169 | 8,901 | 9,417 |
| mean | 15,423 | 10,573 (69%) | 8,724 (57%) | 9,098 (59%) |

**Measured**, not controlled: the battery thermal zone read 43.6 °C at the start
of pass 2 and 44.8 °C at the end of pass 3 (pass 1 was not recorded), and the
native rating fell from 17,683 to 13,874–14,713, so heat is visible in the
numbers. Per pass the emulated results were 65–73% (x86-64), 51–60% (x86 on Box64)
and 49–66% (x86 on FEX) of native. The versions differ, so treat the ratios as
rough.

**Measured:** a later single run of `benchmark.sh --runs 1` on the warmer phone
(battery zone 43.4–44.1 °C) kept the ordering at lower absolute numbers:
ChimbaBenchXPL 75 (32-bit CPU), 99 (32-bit GPU), 79 (64-bit CPU) and 171 (64-bit
GPU); 7-Zip native 15,173, x86-64 on FEX 10,378, x86 on Box64 8,813 and x86 on FEX
9,304. The script exited 0.

### Not established

- Windows games, DirectX (DXVK ships in `share/ternux/` and was not tried),
  audio, input devices, .NET (wine-mono is not installed), larger installers,
  long sessions and thermal limits.
- Visual correctness of GPU-rendered windows: Xvfb cannot show Zink output and I
  did not test a windowed program on the Termux:X11 desktop in this run.
- The VirGL path on non-Adreno GPUs (no such device here), a clean device, and
  Termux-host delegation on the device.
- A minimal hand-assembled x86-64 test executable of mine faulted inside FEX
  while every real 64-bit program above ran. I treat my hand-built file as an
  invalid test input and did not investigate it further.
