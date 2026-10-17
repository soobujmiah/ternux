# Wine + Hangover on the phone — validation and benchmarks

> **Where this sits in ternux.** This is the evidence behind the experimental
> `wine-hangover` extension: two scripts that run real, publicly distributed
> Windows programs under the installed Wine and print what happened. Nothing in
> the installer depends on them. The recorded results and their limits are in the
> [guide's qualification record](../../guides/wine-hangover-extension.md#device-qualification-record).

## Requirements

- The extension, installed from Termux: `ternux extension install wine-hangover`
- In the Debian guest: `sudo apt install xvfb python3 curl 7zip xdotool`
- About 6 GB of free space for the downloads and a new Wine prefix (2.3 GB), and
  a few minutes for the first prefix

Both scripts download into a new scratch directory, check each file against a
pinned SHA-256, use a private Xvfb display (`:77`) and a prefix inside the
scratch directory, and delete everything on exit unless `--keep` is given. They
touch nothing else in your home directory.

## Check that real Windows programs run

```bash
bash validate.sh [--keep] [SCRATCH_DIR]
```

It prints TAP and exits non-zero on any failure. It checks that Wine reports its
version and creates a prefix, then runs real 32-bit and 64-bit Python, GLEW's
`glewinfo.exe` (which prints the OpenGL renderer for the GPU path and for the CPU
fallback) and the 32-bit and 64-bit 7-Zip installers, using the archives they
create. Without a visible KGSL node the GPU lines check the CPU fallback instead.

## Measure

```bash
bash benchmark.sh [--runs N] [--keep] [SCRATCH_DIR]
```

It prints tab-separated lines for two benchmarks:

- 7-Zip `b` total rating: native arm64 7-Zip, x86-64 on FEX, x86 on Box64 and x86
  on FEX, with the battery temperature at the start and end of each pass.
- ChimbaBenchXPL A3 "Simple Test" at 640×360: the CPU path and the GPU path for
  the 32-bit and 64-bit builds, driven with `xdotool` on the private display.

## Reading the results

- Bash may print `Terminated` between benchmark cells; it is the benchmark
  process being stopped and is expected.
- The phone's temperature changes the numbers between passes. Compare within a
  pass, and report the temperatures printed beside them.
- The Zink window is not visible on Xvfb, so the GPU runs of the OpenGL
  benchmark are not checked for correct drawing. `glewinfo.exe` confirms which
  renderer a setting selects; the benchmark's own header shows the adapter Wine
  reports in both modes.
- The scores are the benchmark's own; its result database labels them FPS. They
  are single-device measurements, not a compatibility or sustained-performance
  claim.
- Programs are downloaded from their publishers (python.org, 7-zip.org, the GLEW
  and ChimbaBenchXPL GitHub releases). Their licences and terms are theirs;
  Ternux redistributes none of them.
