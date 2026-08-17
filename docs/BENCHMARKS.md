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

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · MIT*
