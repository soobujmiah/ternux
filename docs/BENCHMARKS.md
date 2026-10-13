---
title: "Benchmarks and device evidence"
description: "Measured glmark2 FPS, Blender renderer evidence, workload boundaries and a reproducible Ternux benchmark protocol."
lang: "en"
alt_url: "/bn/docs/BENCHMARKS.html"
---

This page records what has actually been measured on a real ternux setup, what was
only observed, and what remains unverified. It exists to prevent build success,
renderer detection and benchmark performance from being mixed into one claim.

> **Snapshot:** evidence supplied by the project author in August 2026. This is one
> device/configuration, not a compatibility or performance guarantee.

---

## Result classes

| Class | Meaning |
|---|---|
| **Measured** | Complete output contains a numeric score, scene FPS or another reproducible measurement |
| **Observed** | Output shows that an application launched, built or detected a renderer/backend |
| **Not benchmarked** | No complete, reproducible performance output was supplied |

A build configured with a GPU option belongs under **observed** until a runtime log
names the device/backend and completes a benchmark or workload.

---

## Tested configuration

| Field | Captured value |
|---|---|
| Phone | Redmi Turbo 4 Pro |
| SoC / GPU | Snapdragon 8s Gen 4 / Adreno 825 |
| Guest | Debian ARM64 through PRoot Distro |
| Display | X11 through Termux:X11 |
| Mesa | 26.2.0-devel (`git-9452d1daec` in the supplied output) |
| Renderer | `zink Vulkan 1.4(Adreno (TM) 825 (MESA_TURNIP))` |
| OpenGL | 4.6 compatibility profile in glmark2; 4.6 core profile in Blender |
| OpenGL ES | 3.2 |
| glmark2 | 2023.01 |
| Surface | 800×600, reported as windowed in both captured headers |

The setup notes describe the route as Mesa Zink over Turnip/KGSL. The independent
renderer strings from glmark2 and Blender are consistent with that route and do not
contain `llvmpipe`.

---

## Measured: glmark2

### Summary

| Command | Captured score | Minimum scene | Maximum scene |
|---|---:|---:|---:|
| `glmark2` | **140** | terrain: **45 FPS** | texture mipmap: **164 FPS** |
| `glmark2-es2 --off-screen` | **364** | loop/uniform: **53 FPS** | bump/height: **465 FPS** |

The first command reported OpenGL 4.6 compatibility profile. The second reported
OpenGL ES 3.2, but also printed:

```text
MESA-EGL: warning: DRI3 error: Could not get DRI3 device
MESA-EGL: warning: Ensure your X server supports DRI3 to get accelerated rendering
```

Its renderer still named Zink, Adreno 825 and `MESA_TURNIP`, and its header still
said `Surface Size: 800x600 windowed` despite the `--off-screen` command. All three
facts are retained. The result is evidence, but it is caveated evidence.

### Complete captured scene FPS

`GL FPS` is the `glmark2` run. `ES FPS` is the separately captured
`glmark2-es2 --off-screen` run. They are placed together only to archive the data;
they are **not an apples-to-apples comparison**.

| Scene | Options (abridged only where repetitive) | GL FPS | ES FPS |
|---|---|---:|---:|
| build | `use-vbo=false` | 138 | 436 |
| build | `use-vbo=true` | 147 | 382 |
| texture | nearest | 141 | 325 |
| texture | linear | 143 | 426 |
| texture | mipmap | 164 | 449 |
| shading | gouraud | 150 | 425 |
| shading | blinn-phong-inf | 153 | 436 |
| shading | phong | 151 | 401 |
| shading | cel | 150 | 424 |
| bump | high-poly | 153 | 384 |
| bump | normals | 142 | 464 |
| bump | height | 140 | 465 |
| effect2d | 3×3 kernel | 141 | 412 |
| effect2d | 5×5 kernel | 138 | 316 |
| pulsar | light=false, quads=5, texture=false | 142 | 439 |
| desktop | blur, radius=5, windows=4 | 137 | 321 |
| desktop | shadow, windows=4 | 139 | 362 |
| buffer | non-interleaved, map | 117 | 272 |
| buffer | non-interleaved, subdata | 148 | 256 |
| buffer | interleaved, map | 114 | 270 |
| ideas | speed=duration | 127 | 166 |
| jellyfish | default | 154 | 407 |
| terrain | default | 45 | 118 |
| shadow | default | 151 | 397 |
| refract | default | 120 | 152 |
| conditionals | fragment=0, vertex=0 | 144 | 443 |
| conditionals | fragment=5, vertex=0 | 149 | 445 |
| conditionals | fragment=0, vertex=5 | 151 | 451 |
| function | low complexity, steps=5 | 155 | 442 |
| function | medium complexity, steps=5 | 151 | 449 |
| loop | fragment-loop=false, steps=5 | 154 | 441 |
| loop | fragment-uniform=false, steps=5 | 156 | 446 |
| loop | fragment-uniform=true, steps=5 | 151 | 53 |

### What the score means

The glmark2 score aggregates scene results. It is not a universal GPU rating and is
not the FPS of Xfce, Blender or a game. Resolution, window/fullscreen/off-screen
mode, OpenGL versus OpenGL ES, compositor, VSync, Mesa version, thermal state and
background activity all change the result.

Only compare runs with the same:

1. glmark2 version and command;
2. API and scene list;
3. resolution and presentation mode;
4. Mesa/renderer stack;
5. compositor and VSync environment;
6. thermal and power conditions.

---

## Observed: Blender 4.3.2

The supplied Blender system report contains:

```text
platform: 'Linux-6.17.0-PRoot-Distro-aarch64-with-glibc2.41'
windowing environment: 'X11'
renderer: 'zink Vulkan 1.4(Adreno (TM) 825 (MESA_TURNIP))'
vendor: 'Mesa'
version: '4.6 (Core Profile) Mesa 26.2.0-devel (git-9452d1daec)'
device type: 'SOFTWARE'
backend type: 'OPENGL'
```

It also reports Python 3.13.5 and identifies Blender 4.3.2. The Cycles section lists
CPU capabilities but no GPU device.

### Supported conclusion

Blender launched on X11 and its OpenGL viewport saw the Zink/Turnip renderer.

### Unsupported conclusions

This report does not establish:

- Cycles GPU Compute support;
- Blender viewport FPS;
- Eevee or Cycles render time;
- heavy-scene stability or memory limits.

Blender supports Cycles GPU rendering only through its listed compute backends and
devices. An accelerated OpenGL viewport is a different path.

---

## Observed: llama.cpp Vulkan build/use

The setup notes report a Debian build configured with:

```bash
cmake -B build -DGGML_VULKAN=ON -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
```

They also contain local CLI/server examples using small 1–1.5B Q4 GGUF models and
GPU-layer offload. They do **not** contain a complete `llama-bench` table, build
commit, backend/device log, memory reading or thermal record.

Use this for publishable evidence:

```bash
cd ~/llama.cpp
./build/bin/llama-cli --list-devices
./build/bin/llama-bench -m models/YOUR_MODEL.gguf -ngl 99 \
  2>&1 | tee ~/benchmarks/llama-bench.txt
git rev-parse HEAD | tee ~/benchmarks/llama-commit.txt
```

Record model, quantization, model size, context, threads, GPU layers, `pp` and `tg`
rows, runtime backend/device, RAM and temperature. Until then, ternux makes no
llama.cpp tokens-per-second claim for the tested phone.

---

## Experimental: llama.cpp Hexagon HTP artifact for SM8735

The separate `llama.cpp Hexagon HTP artifact` workflow builds a reusable Linux
aarch64 package from upstream llama.cpp tag `b11582` (commit
`af50f2f248b475d9760f8e67503d01c0f194f5f4`). It uses the pinned upstream
Snapdragon Linux toolchain image digest recorded in the workflow. The workflow
creates the prerelease `ternux-llama-htp-sm8735-b11582`. The published
15,519,631-byte aarch64 archive has SHA-256
`dffcf83fa969f3ccfad238217b4ca7f3d47040e5e5b2fa834ebd3f123d144ea5`.

This is a research artifact, not part of `--with-llm` and not a supported
installer feature. The existing b11582 prebuilt ran HTP operators through the
brokered FastRPC path on Redmi Turbo 4 Pro / SM8735, but a deterministic
known-output comparison failed. The exact GH-built archive was then tested
through the existing PRoot Binder-brokered FastRPC path: model loading,
full-layer HTP placement, profiled HTP operators and clean session close
succeeded, but it generated malformed text (`.\".ss\"sssid Su SVː`). Known-output
inference therefore **failed**. Do not treat this as a supported inference
build or a performance claim. The package does not include Qualcomm vendor
runtime libraries, firmware, or the Android Binder/FastRPC broker.

[Build run](https://github.com/soobujmiah/ternux/actions/runs/38381879734).
The same packaged `llama-cli` also passed a CPU baseline: with `-ngl 0` and
the identical model, prompt, seed, and batch settings it returned `2 + 2 = 4.`
at 44.32 generated tokens/s. Two brokered HTP runs returned the same malformed
text; the second measured 28.63 generated tokens/s. This is one short run on a
135M Q4_0 model, so the numbers are diagnostic only and do not establish a
general performance comparison. Model SHA-256:
`f68203bfb98b1b1e8c64fac75fab10c4e36acac081609573b4df0fcc19c90dd9`.

Validation setup: `--device HTP0 -ngl 99 --ctx-size 128 --batch-size 128
--ubatch-size 128 -n 8 --seed 0 --temp 0 --no-warmup`; CPU used the same
arguments with `-ngl 0`. HTP was reached through Android's Binder DSP broker
and a passed CDSP FastRPC descriptor. The logs show HTP graph/operator records
including `MUL_MAT_NX`, `FLASH_ATTN_EXT`, `RMS_NORM` and `SWIGLU`; the host
reported clean broker child exit and CDSP session close. The exact run logs are
`gh-artifact-device-test.log`, `gh-artifact-htp-repeat.log`, and
`gh-artifact-cpu-baseline.log` in `/home/sbj/npu-probe-2026-10-13/` on the
test workspace.

### Isolated HTP operator checks

The same release libraries were tested in standalone GGML graphs through the
same brokered CDSP descriptor, with CPU fallback disabled:

| Operation | Shape / data | Result |
|---|---|---|
| `ADD` | 256 F32 elements | **Pass**; 0 mismatches; max absolute error `9.53674e-07` |
| `MUL_MAT` | F32 × F32, K=16, M=8, N=4 | **Pass**; 0 mismatches; max absolute error `3.57628e-07` |
| `MUL_MAT` | Q4_0 × F32, K=576, M=8, N=2 | **Mismatch** against the same-build CPU backend on 16/16 outputs at the probe's `1e-5` comparison threshold; maximum absolute HTP-vs-CPU difference `0.00947738`. Against the explicitly dequantized Q4_0 reference, max absolute error was `0.00601411` (max relative error `1.56%`). The HTP profile identified `MUL_MAT` with `q4_0 x f32`, `hvx-tiled`; compute status was success and the CDSP session closed cleanly. |
| `MUL_MAT` | Q4_0 × sparse F32, K=576, M=8, N=2 | **Numeric mismatch** on 15/16 outputs at `1e-5`; max absolute error `0.000181094`, max relative error `0.0908%`. Inputs were nonzero at only one K position per column to reduce long accumulation. HTP verbose trace confirmed `q4_0 x f32`, `hvx-tiled` execution; graph compute succeeded and the CDSP session closed cleanly. |
| `MUL_MAT` | dequantized Q4_0 weights as F32 × same sparse F32 input, K=576, M=8, N=2 | **Pass**; the HTP F32 path's max absolute error against the same explicit reference was `1.49012e-08`. The same graph's CPU Q4_0 result was within `1.21743e-05` max absolute error of that reference. This narrows the observed discrepancy to the Q4_0 HTP execution path; it does not identify a specific kernel defect. |
| Q4_0 tensor round-trip | 2,592 quantized weight bytes | **Pass**; backend set → get through the tiled host representation returned all bytes unchanged. This verifies host-side repack/de-repack data integrity for this tensor; it does not prove the DSP kernel's interpretation of the tile. |

These deterministic synthetic micro-tests do not prove that a particular
model layer is the sole source of the malformed text. I ran a sparse-input
follow-up to reduce accumulation effects; it still showed small per-output
differences. I also read the same 2,592 Q4_0 bytes back through the backend's
tiled repack/de-repack path and found zero changed bytes. This verifies the
host-side tensor round-trip, while the DSP kernel's interpretation of the tile
remains unverified. With the exact same dequantized weights and sparse inputs,
the HTP F32 matmul matched the reference within `1.49012e-08`; the CPU Q4_0
graph was within `1.21743e-05`. The pinned b11582 source shows the Q4_0 HTP
path quantizes F32 activations into Q8_0 tiles. A generic GGML Q8_0-quantized
activation reference still differed from HTP by up to `0.000193268`; the exact
HTP activation quantizer and rounding have not yet been emulated, so this does
not establish a kernel defect. The issue is narrowed to the Q4_0 HTP execution
path, with quantization and arithmetic behavior still unresolved. Probe logs
(`gh-artifact-htp-add-test.log`,
`gh-artifact-htp-matmul-test.log`, `gh-artifact-htp-q4-matmul-k576-test.log`,
`gh-artifact-htp-q4-sparse-verbose-test.log`,
`gh-artifact-htp-q4-roundtrip-test.log`, and
`gh-artifact-htp-q4-cpu-f32-ref-test.log`,
`gh-artifact-htp-q4-q8-reference-test.log`) are retained in
`/home/sbj/npu-probe-2026-10-13/`. Probe source and binaries are scratch
artifacts, not shipped in the llama.cpp release.

The pinned HTP source selects the tiled Q8_0 activation quantizer for Q4_0
weights in [`matmul-ops.c`](https://github.com/ggml-org/llama.cpp/blob/af50f2f248b475d9760f8e67503d01c0f194f5f4/ggml/src/ggml-hexagon/htp/matmul-ops.c#L743-L755). This Q8_0 work is only a diagnostic for that Q4_0 mismatch; it does not change the active NPU known-output inference gate into a Q8 model optimization task.

### Optional future candidate: ternary 1.58-bit models

Microsoft BitNet may be considered later as an optional Ternux extension. Its
[upstream project](https://github.com/microsoft/BitNet) currently describes CPU
and GPU support and lists NPU support as forthcoming. This is not evidence of
SM8735, Adreno, Hexagon HTP, or Debian PRoot compatibility. Keep this candidate
outside the active Q4_0 investigation; if evaluated later, test its native
1.58-bit runtime/model separately from ordinary IQ1/TQ1 GGUF quantizations and
measure CPU, GPU, and NPU paths independently. Device speed, heat, and output
quality remain unverified.

Workflow and source pin: [llama-htp-artifact.yml](../.github/workflows/llama-htp-artifact.yml).
Device test details: [SKB investigation](https://github.com/soobujmiah/skb/blob/main/devices/redmi-turbo-4-pro/evidence/debian-proot-npu-investigation-2026-10-13.md); exact archive retest log: `gh-artifact-device-test.log` in the local probe scratch directory.

---

## Observed: stable-diffusion.cpp Vulkan build

The supplied notes report a successful build on the same phone with:

```bash
cmake .. -DSD_VULKAN=ON -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release -j8
```

No generation command, verbose Vulkan device log, completed image, seed, model,
steps, dimensions, timing or memory figure was supplied. This proves a reported
Vulkan-enabled build, not measured inference.

A future result should include:

- exact stable-diffusion.cpp commit;
- model and weight format/quantization;
- verbose log naming Vulkan and Adreno/Turnip;
- prompt, negative prompt, seed, sampler, steps and resolution;
- wall time and peak memory;
- output image checksum;
- temperature/power conditions.

---

## Reproduce the graphics measurements

Start the ternux desktop and run inside Debian:

```bash
sudo apt update && sudo apt install -y glmark2
mkdir -p ~/benchmarks

date -Is | tee ~/benchmarks/run-context.txt
uname -a | tee -a ~/benchmarks/run-context.txt
glxinfo -B 2>&1 | tee ~/benchmarks/glxinfo.txt
vulkaninfo --summary 2>&1 | tee ~/benchmarks/vulkan-summary.txt

glmark2 2>&1 | tee ~/benchmarks/glmark2-windowed.txt
glmark2-es2 --off-screen 2>&1 | tee ~/benchmarks/glmark2-es2-offscreen.txt
```

Also record Android/device context from Termux:

```bash
ternux profile show | tee ~/ternux-profile.txt
getprop ro.product.model | tee -a ~/ternux-profile.txt
getprop ro.build.version.release | tee -a ~/ternux-profile.txt
```

For a fair comparison, cool the phone first, keep charger state and screen settings
constant, close unrelated apps, state whether Xfce compositing is enabled, and run
at least three repetitions. Publish every repetition rather than only the best one.

---

## Quick health benchmark versus evidence reproduction

`ternux benchmark` is designed as a convenient installation health check. It may
try fullscreen glmark2 and uses a timeout, so it is not automatically identical to
the two commands archived on this page.

Use:

```bash
ternux benchmark
ternux benchmark --json
```

for quick diagnostics. Use the exact raw commands above when trying to reproduce or
compare the published Redmi Turbo 4 Pro evidence.

---

## Current evidence matrix

| Question | Status |
|---|---|
| Does glmark2 name Zink/Adreno/Turnip? | **Yes — observed** |
| Is windowed OpenGL FPS captured? | **Yes — measured** |
| Is the ES command/output captured with its DRI3 warning? | **Yes — measured, caveated** |
| Does Blender see the same OpenGL renderer? | **Yes — observed** |
| Is Blender Cycles GPU rendering proven? | **No** |
| Is llama.cpp Vulkan compile/use reported? | **Yes — observed** |
| Is llama.cpp tokens/s measured? | **No** |
| Is stable-diffusion.cpp Vulkan build reported? | **Yes — observed** |
| Is diffusion seconds/image measured? | **No** |
| Are sustained thermals/power measured? | **No** |
| Is same-device VirGL versus Zink measured? | **No** |

---

## References

- [glmark2](https://github.com/glmark2/glmark2)
- [Mesa Zink](https://docs.mesa3d.org/drivers/zink.html)
- [Blender 4.3 GPU rendering](https://docs.blender.org/manual/en/4.3/render/cycles/gpu_rendering.html)
- [llama.cpp Vulkan build](https://github.com/ggml-org/llama.cpp/blob/master/docs/build.md#vulkan)
- [stable-diffusion.cpp Vulkan build](https://github.com/leejet/stable-diffusion.cpp/blob/master/docs/build.md#build-with-vulkan)

---

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · Apache-2.0*
