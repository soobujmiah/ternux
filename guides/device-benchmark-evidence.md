# Ternux device benchmark evidence — detailed record

> This repository-only record preserves the complete graphics and accelerator evidence, test boundaries, reproduction steps, and dated experiment history. The published benchmark page is a concise current-state summary.

This page records what has actually been measured on a real ternux setup, what was
only observed, and what remains unverified. It exists to prevent build success,
renderer detection and benchmark performance from being mixed into one claim.

> **Snapshot:** evidence through 2026-10-14 on one Redmi Turbo 4 Pro / SM8735
> configuration, not a compatibility or performance guarantee.

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
| Vulkan / Turnip | 26.3.0-devel (`git-98f3d6229d`) |
| OpenGL Mesa | Debian `25.0.7-2+deb13u1` |
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

## Measured: sustained EEVEE sequence, 2026-10-14

I rendered 600 consecutive frames in one Blender process on the same 1280x720
Suzanne scene. Blender 4.3.2, EEVEE Next, 16 render samples, `--gpu-backend
opengl`, `DISPLAY=:0`, Debian PRoot on the Redmi Turbo 4 Pro. In this session
`glxinfo -B` reported `zink Vulkan 1.4(Adreno (TM) 825 (MESA_TURNIP))` and
`vulkaninfo --summary` reported Turnip 26.3.0-devel on Adreno 825.

All 600 PNGs were saved. Summing Blender's per-frame render/save times gives
891.6 seconds, with 1.49 seconds median and 1.49 seconds mean per frame. The
first 30 averaged 1.58 seconds and the final 30 averaged 1.46 seconds; there is
no slowdown in that interval. Peak Blender memory was 77.59 MiB. Android thermal
status remained 0; sampled skin temperature peaked at 44.5 C, battery at 41.8 C,
and battery charge moved from 84% to 80%. These measurements describe this
roughly 15-minute run only; they do not establish multi-hour thermal behavior.
The render log and `.blend` files are in local scratch under
`/home/sbj/npu-probe-2026-10-13/eevee-sustained/`.

The Ternux installer can now reproduce the GPU input: it pins the upstream
Turnip archive and checks its SHA-256 before extraction. The device render
evidence still depends on this device's graphics stack and does not qualify
every Adreno generation.

## Measured: a 648-frame animated short rendered headless, 2026-10-14

I produced a complete 27-second animated film on this device — four shots, 648
frames at 1280x720 and 16 samples, Blender 4.3.2 with EEVEE Next, one Blender
process per shot. The scene is procedural: a character, a hero flower and a
meadow built from primitives by a script, not a downloaded asset. The pipeline
and the exact commands are in
[`experiments/cartoon-pipeline/`](https://github.com/soobujmiah/ternux/tree/main/experiments/cartoon-pipeline).

This run used **no X server app at all**. `Xvfb` on `:9` with
`GALLIUM_DRIVER=zink` carried the whole render, and `glxinfo -B` on that display
reported `zink Vulkan 1.4(Adreno (TM) 825 (MESA_TURNIP))`.

| Shot | Frames | Blender render time | Mean | Wall clock |
|---|---|---|---|---|
| 1 | 144 | 164.5 s | 1.142 s | 209 s |
| 2 | 144 | 160.3 s | 1.113 s | 205 s |
| 3 | 168 | 192.4 s | 1.145 s | 244 s |
| 4 | 192 | 212.4 s | 1.106 s | 270 s |
| **All** | **648** | **729.6 s** | **1.126 s** | **928 s** |

Wall clock exceeds render time by the per-process startup, shader compilation
and PNG writing. The first frame of each shot cost 2.95-4.06 s against a 1.1 s
steady state, which is the shader compilation a sequence pays once: rendering
frame by frame in separate processes would have cost that 648 times.

There is no slowdown across the run. The first 30 frames averaged 1.186 s and
the last 30 averaged 1.149 s. Peak Blender memory was 86.6 MiB. Thermal samples
over the final 6.3 minutes: GPU zone 52.3-63.4 C, `quiet_therm` 47.7-50.0 C,
battery 43.5 C rising to 44.5 C. This is a roughly 15-minute sustained run; it
does not establish multi-hour thermal behaviour.

### Measured: display paths compared

The same ten frames of the same scene, one Blender process each:

| Path | Mean per frame | Result |
|---|---|---|
| `DISPLAY=:0`, Termux:X11 app open | 1.733 s | 10 frames |
| `DISPLAY=:9` Xvfb + `GALLIUM_DRIVER=zink` | 1.697 s | 10 frames |
| `DISPLAY=:9` Xvfb, Mesa's own driver choice | - | **0 frames, `Illegal instruction`** |
| no `DISPLAY` set | - | **0 frames, `EGL_BAD_MATCH`** |

Going headless costs nothing measurable, and the same frame rendered down both
working paths differs in 5 channel samples out of 2,764,800, with a maximum
difference of 3/255 — GPU nondeterminism, not a different renderer. Both halves
of the headless rule are load-bearing: without the virtual display Blender falls
back to EGL and renders nothing, and without the driver override Mesa selects
`llvmpipe`, which dies with SIGILL on this device exactly as the software-GL
control did on 2026-10-13.

```bash
Xvfb :9 -screen 0 1280x720x24 &
DISPLAY=:9 GALLIUM_DRIVER=zink blender -b --factory-startup --python render.py -- --shot 1
```

## Measured: a 1,440-frame narrative film with dialogue, 2026-10-14

I produced a complete 60-second Bengali short on this device — five scenes cut
into twelve shots, six speaking and standing characters, a crowd, Bengali
dialogue from a local neural speech model, mouths driven by that dialogue, and
burnt-in Bengali captions. The pipeline and the exact commands are in
[`experiments/bengali-short-film/`](https://github.com/soobujmiah/ternux/tree/main/experiments/bengali-short-film).

1280x720, 16 render samples, EEVEE Next, one Blender process per scene, rendered
headless on `Xvfb :9` with `GALLIUM_DRIVER=zink` — no X11 application was open.

| Scene | Frames | Blender render | Mean | First frame |
|---|---|---|---|---|
| 1 | 240 | 427.7 s | 1.782 s | 22.6 s |
| 2 | 288 | 501.3 s | 1.741 s | 9.3 s |
| 3 | 312 | 569.9 s | 1.826 s | 8.5 s |
| 4 | 312 | 633.4 s | 2.030 s | 13.0 s |
| 5 | 288 | 666.5 s | 2.314 s | 8.9 s |
| **All** | **1,440** | **2,798.8 s** | **1.944 s** | |

Peak Blender memory was 459.1 MB. Each scene's first frame is slow because
shader compilation is paid once per process; the steady state is what the mean
describes.

An earlier pass of the same film measured **3.22 s/frame at 713.7 MB** with 24
samples, two subdivision levels on every body, and a shadow-casting fill light.
Dropping to 16 samples, one subdivision level below the neck, no shadow map on
the sky fill, and depth of field only in the shots that use it gave 1.944 s/frame
with no visible loss at these shot sizes — a 40% saving for a change the frame
does not show.

Speech is Meta's MMS-TTS Bengali (VITS) run through `onnxruntime` on the CPU:
six lines totalling 27.5 s of audio, each generated in roughly 1.3x its own
length. That model is **CC-BY-NC-4.0 and non-commercial**; the rest of the
pipeline does not depend on it.

The delivered file measures 60.000 s, 1280x720, 24 fps, 1,440 frames, H.264 with
AAC stereo at 44.1 kHz. Captions are composited from pre-shaped PNGs, because
neither Blender text objects nor ffmpeg's `drawtext` shape Bengali conjuncts.

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

## Measured: llama.cpp CPU + Vulkan package

The published ARM64 CPU + Vulkan prerelease was installed and tested on the
configured SM8735 device. CPU and Adreno Vulkan returned `4` for the greedy
known-answer prompt; verbose output confirmed Vulkan0 on Adreno 825 with 29/29
layers assigned. A separate bounded clean-idle comparison measured CPU and
Vulkan prompt/generation throughput, but this is not a `llama-bench` matrix or a
general performance claim. Full package, ABI and test evidence is in the
[repository-only extension guide](https://github.com/soobujmiah/ternux/blob/main/guides/llama-vulkan-extension.md#device-qualification-record)
and [current release plan](../docs/ACCELERATOR-RELEASE-PLAN.html).

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
installer feature. The first b11582 default-path known-answer runs failed on
Redmi Turbo 4 Pro / SM8735, although HTP operators loaded and the session closed
cleanly. Follow-up configuration isolation on 2026-10-14 found one bounded
passing route: HVX-only matmul with flash attention off returned `4` on short
known-answer prompts and completed the long recall-key workload. It placed all
29 layers on HTP0, but was slower than Vulkan in the matched clean-idle run.
Two other isolated configurations failed: HMX-selected matmul with flash
attention off, and HVX-selected matmul with flash attention on. HTP remains
experimental and unsupported; this evidence does not qualify every model or
operator. The published archive does not include Qualcomm vendor runtime libraries,
firmware, or the Android Binder/FastRPC broker. The working tree now adds an
experimental Binder/FastRPC broker and launcher to the artifact workflow; that
package has not yet been built or device-tested. The current gate is tracked in
the [release plan](../docs/ACCELERATOR-RELEASE-PLAN.html).

[Build run](https://github.com/soobujmiah/ternux/actions/runs/38381879734).
The same packaged `llama-cli` passed its CPU baseline with `-ngl 0`; two HTP runs
in that initial configuration returned the same malformed text. CPU measured
44.32 generated tokens/s and the second HTP run 28.63 on this one short 135M
Q4_0 test. These numbers describe the initial failing configuration only and
are not comparable to the later Qwen2.5 clean-idle run or a general performance
comparison. Model SHA-256:
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
| `MUL_MAT` | Q4_0 one-hot weights × F32 input; 128 output rows exposed the corresponding HTP Q8 activation lanes | **HTP compute pass**; decoded output residual was at most `1.525879e-05`. 127/128 inferred Q8 integers matched a simple host round reference; one near-boundary lane decoded as `-74` versus host `-75`. This is not an exact HVX quantizer emulation. |
| `MUL_MAT` | Exploratory dense Q4_0 reference extension, K=576, M=8 | **Failed diagnostic comparison**; HTP returned outputs up to magnitude `532544.875`, while the CPU control stayed near the manually dequantized reference (max CPU/reference error `≤0.0301`). The 2,592-byte random Q4_0 tensor passed backend set/get round-trip with 0 mismatches. A later 576-lane extension had 10 generic-Q8 integer differences and up to `0.0825` reconstruction residual, so its decoded-Q8 reference/layout remains unqualified. This is evidence of a failed HTP result for this probe, not a diagnosis of the kernel defect. |
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
not establish a kernel defect. A follow-up one-hot Q4_0 test inferred 128 HTP
Q8 activation lanes from successful output; 127 matched a simple host rounding
reference and one near-boundary value differed by one integer. The exact HVX
reciprocal and rounding path is still not emulated. An exploratory dense
reference extension returned values up to `532544.875`. The 2,592-byte random
Q4_0 tensor passed backend set/get round-trip with no changed bytes. The CPU
control stayed within `0.0301` of the direct dequantized F32 reference, while
the HTP output was far outside that range. A later 576-lane decode extension had 10 simple-reference
integer differences and a maximum reconstruction residual of `0.0825`; its
lane mapping/reference is not yet qualified. Thus the HTP result for this
diagnostic failed, but its exact cause remains unverified. The issue remains
narrowed to the Q4_0 HTP execution path, with quantization and arithmetic behavior
unresolved. Probe logs
(`gh-artifact-htp-add-test.log`,
`gh-artifact-htp-matmul-test.log`, `gh-artifact-htp-q4-matmul-k576-test.log`,
`gh-artifact-htp-q4-sparse-verbose-test.log`,
`gh-artifact-htp-q4-roundtrip-test.log`, and
`gh-artifact-htp-q4-cpu-f32-ref-test.log`,
`gh-artifact-htp-q4-q8-reference-test.log`, and
`htp-q8-activation-decode-child.log` and
`htp-q8-activation-decode-full.log`) are retained in
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

### 2026-10-13 default-path comparison (Qwen2.5 1.5B Q4_0)

I used `/sdcard/LAI/models/qwen2.5-1.5b-instruct-q4-0.gguf` directly; the model
was not copied, moved, or converted. With the same packaged llama.cpp b11582
artifact, prompt (`What is 2 + 2? Reply with only the number.`), greedy
sampling, seed 0, and an eight-token limit:

| Path | Result | Evidence |
|---|---|---|
| CPU (`-ngl 0`) | **Known-answer pass**: `4.000000`; prompt 121.4 tok/s, generation 21.8 tok/s | `htp-qwen15-cpu-baseline.log` in `/home/sbj/npu-probe-2026-10-13/` |
| Hexagon HTP (`-ngl 99`, brokered CDSP) | **Known-answer fail**: ` LENG, the, the,`; generation 24.3 tok/s in the initial eight-token run. Verbose repeat produced ` LENG, the,` and HTP profile records including `MUL_MAT`, `FLASH_ATTN_EXT`, and `SWIGLU`. | `htp-qwen15-htp-test.log` and `htp-qwen15-htp-verbose-test.log` in the same scratch directory |
| Vulkan GPU | **Known-answer pass** on a separate local Vulkan-enabled build: `4.000000`; verbose trace assigned all 29/29 model layers to Vulkan0 (Adreno 825). | `llama-vulkan-qwen15-gpu.log` and `llama-vulkan-package-gpu-test.log` in `/home/sbj/npu-probe-2026-10-13/` |

The HTP broker session and child process exited cleanly, and verbose per-op
records confirm actual HTP work for this model. The default HTP configuration
failed this known-answer check on 2026-10-13. The CPU and HTP token rates are short diagnostic
runs with different generation lengths and are not a controlled performance
comparison. No sustained thermal or power measurement was taken. The existing
`/sdcard/Llms/AbsoluteReality_qnn2.28_8gen2.zip` contains a Stable Diffusion
QNN image-generation package (including CLIP, VAE, and UNet files), not a GGUF
vision model. At the time of this comparison it had been inspected by listing
archive entries only. The later authorized CLIP input/CPU probe is recorded in
the QNN experiment handoff.

### 2026-10-14 conditional Hexagon known-answer result

I retested the checksum-verified pinned b11582 artifact with the same Qwen2.5
1.5B Q4_0 model on SM8735. The existing broker passed its own CDSP descriptor
to the glibc child process. With `GGML_HEXAGON_MM_SELECT=1` (HVX matmul) and
`-fa off`, HTP returned `4` for `What is 2 + 2? Reply with only the number.`
in three short runs. A second prompt, `The capital of France is`, returned
` Paris, and the` on both CPU and HTP with the same four-token greedy settings.
The verbose HTP log names `HTP0`, `q4_0 x f32` `MUL_MAT`, `hvx-tiled`, other
HTP operators and an HTP compute buffer. The brokered child exited 0 and
`closeSession` returned success. These observations establish actual HTP work
and two short correct completions for this **specific** configuration.
The same arithmetic prompt also returned `4` twice with the authorized
Qwen2.5 1.5B Q4_K_M file under the HVX/`-fa off` setting. Its verbose profile
identified `q4_K x f32` and `q6_K x f32` matmuls on `HTP0`. This adds a second
quantization to the bounded pass, not a new model family.

I also used the existing Llama 3.2 3B Instruct Q4_K_M model with prompt
`The capital of France is` and four greedy output tokens. HTP returned
` Paris. The capital`; the verbose trace showed `q4_K x f32` and `q6_K x f32`
matmuls through `hvx-tiled` on HTP0. Brokered child and CDSP session both
closed successfully. This adds one model-family result; there is no matched
CPU comparison for this prompt.

Two bounded controls kept `-fa off` and the same model/prompt: with
`GGML_HEXAGON_MM_SELECT=2` (HMX preferred), the arithmetic prompt returned
Arabic-script nonsense; with `MM_SELECT=1` but `-fa auto`, it returned `s,`.
With `MM_SELECT=1`, `-fa off` and no `GGML_HEXAGON_OPFILTER`, it returned `4`.
Thus both the default HMX path and the flash-attention setting are implicated
by these controls; the exact failing operator and numerical mechanism remain
unproven. A [separate upstream v73 report](https://github.com/ggml-org/llama.cpp/issues/29473)
describes similar controls on a different SoC; its workaround was a diagnostic
lead, not proof for this device.

The earlier default HTP failure remains historical evidence. The isolated Q4_0
matmul mismatch also remains unresolved. These short prompts do not establish
general model compatibility, sustained stability, release packaging, or a
Ternux-supported NPU route. Local logs:
`htp-qwen15-hvx-workaround-verbose-2026-10-14.log`,
`htp-qwen15-hmx-control-2026-10-14.log`,
`htp-qwen15-hvx-fa-auto-2026-10-14.log`,
`htp-qwen15-hvx-only-2026-10-14.log`,
`qwen15-q4km-htp-hvx-2026-10-14.log`,
`qwen15-q4km-htp-hvx-verbose-2026-10-14.log`,
`llama32-3b-hvx-france-2026-10-14.log`,
`qwen15-cpu-france-2026-10-14.log`, and
`qwen15-htp-hvx-france-2026-10-14.log` under
`/home/sbj/npu-probe-2026-10-13/`.

The conditional HTP result does not replace the next low-level diagnostic:
reproduce the exact HTP Q8_0 activation quantizer to understand the Q4_0 kernel
numeric mismatch. Vulkan has passed a known-answer inference test; HTP needs
broader correctness and stability checks with the HVX/attention settings.

### 2026-10-14 sequential long inference comparison (Qwen2.5 1.5B Q4_0)

The same greedy workload ran sequentially on CPU, Adreno Vulkan, then
Hexagon HTP, using the model directly at
`/sdcard/LAI/models/qwen2.5-1.5b-instruct-q4-0.gguf` (no model copy or
conversion). Each run used context 4096, batch/ubatch 128, a 2,955-token
synthetic project-ledger prompt containing the one-time recall key
`KITE-8042`, and a 512-token generation cap with EOS ignored. All three
outputs began with the exact requested key; each produced 511 tokens before
the cap. Process exit was 0 for all runs. The CPU was `-ngl 0`; Vulkan
offloaded all 29/29 model layers to Vulkan0; HTP used `GGML_HEXAGON_MM_SELECT=1`,
`-fa off`, and offloaded 29/29 layers to HTP0. HTP's brokered child exited 0
and `closeSession` returned transport and reply status 0.

| Backend | Prompt eval | Generation eval | llama.cpp total | Evidence log |
|---|---:|---:|---:|---|
| CPU | 60.04 tok/s | 2.47 tok/s | 256.41 s | `cpu-qwen15-long-4096ctx-512gen-2026-10-14.log` |
| Adreno 825 Vulkan | 91.61 tok/s | 13.26 tok/s | 71.53 s | `gpu-qwen15-long-4096ctx-512gen-2026-10-14.log` |
| Hexagon HTP | 34.21 tok/s | 12.08 tok/s | 129.22 s | `npu-qwen15-long-4096ctx-512gen-2026-10-14.log` |

This is not peak HTP throughput. To preserve known-answer correctness, the HTP
run forced `GGML_HEXAGON_MM_SELECT=1` (HVX matmul only; HMX is disabled) and
`-fa off`; the default/HMX and flash-attention controls had already produced
incorrect answers in short checks. The HTP number therefore describes the
conservative configuration that passed, not the accelerator's optimized
ceiling. An [upstream SM7750 / HTP v73 report](https://github.com/ggml-org/llama.cpp/issues/29473)
describes related HMX and attention correctness failures on a different SoC;
that report is an investigation lead, not proof of the cause on SM8735. The
current evidence points to a correctness-versus-performance limitation in the
tested llama.cpp HTP path; it does not yet identify or fix the kernel defect.

Logs are in `/home/sbj/npu-probe-2026-10-13/`. The device was battery powered;
thermal status stayed 0 during the observations. Battery was about 37% before
the CPU run and 36% after GPU; skin readings were about 43–44.5 C. A separate
session reported four Blender background shells while these runs were being
performed. Their actual resource use was not established, so these are
successful long-workload functional runs and observed timings, not a clean
controlled benchmark or a sustained thermal/stability soak. Repeat the
comparison with the device otherwise idle before publishing performance
claims. This first long comparison is superseded for controlled timing by the
idle repeat below. It still does not settle the earlier default/HMX correctness
failure, validate other models, or qualify an end-user Ternux NPU route.

### 2026-10-14 clean-idle long inference repeat (Qwen2.5 1.5B Q4_0)

After the Blender render, encoding, mux and output-validation processes had
ended, the same model and workload ran sequentially on CPU, Adreno Vulkan and
Hexagon HTP. The model was read directly from
`/sdcard/LAI/models/qwen2.5-1.5b-instruct-q4-0.gguf`; no model copy or
conversion was made. Each run used a 2,955-token prompt, context 4096,
batch/ubatch 128 and a 512-token cap. Every backend generated 511 tokens,
returned the exact first line `Key: KITE-8042`, and exited 0. Vulkan assigned
all 29 model layers to `Vulkan0`; HTP assigned all 29 to `HTP0` through the
brokered llama.cpp Hexagon backend, and `closeSession` returned status 0.

| Backend | Prompt processing | Generation | Total | Evidence log |
|---|---:|---:|---:|---|
| CPU | 59.04 tok/s | 2.38 tok/s | 264.39 s | `cpu-qwen15-idle-long-2026-10-14.log` |
| Adreno 825 Vulkan | 92.19 tok/s | 13.27 tok/s | 71.30 s | `gpu-qwen15-idle-long-2026-10-14.log` |
| Hexagon HTP | 34.20 tok/s | 12.02 tok/s | 129.46 s | `npu-qwen15-idle-long-2026-10-14.log` |

The HTP run used `GGML_HEXAGON_MM_SELECT=1` (HVX matmul; HMX disabled) and
`-fa off` to retain the configuration that passed known-answer checks. On this
workload it completed faster than CPU overall, but slower than Vulkan; both
prompt processing and generation were slower than Vulkan. This is a genuine
long HTP text-inference pass, not a QNN-compiled text model and not evidence
that NPU is faster than GPU. The files in `/sdcard/LAI/models/` are GGUF
weights; `llama.cpp` routes this one to HTP. The separate
`/sdcard/Llms/AbsoluteReality_qnn2.28_8gen2.zip` is the QNN image model, whose
at the time of this earlier comparison, no full prompt-to-image run had been completed; the separate QNN result below is a later run.

The comparison was sequential and otherwise idle. Thermal status stayed 0;
skin temperature peaked at 44.5 C and battery declined from 31% to 28% over the
sequence. This is a clean controlled comparison for this device, model and
configuration, not a multi-hour stability soak or a claim for every Snapdragon
device. Logs are in `/home/sbj/npu-probe-2026-10-13/`.

### 2026-10-14 additional CPU/HTP known-answer smoke (SmolLM2-135M Q4_0)

To check a second local model without touching the SD-card weights, the same
greedy `2 + 2` prompt ran on CPU and on the brokered HTP route. Both returned
`2 + 2 = 4` and exited 0. The test used the pinned b11582 CPU/Vulkan release
binary for CPU (`-ngl 0`) and the b11582 Snapdragon HTP build for HTP
(`-ngl 99`, `GGML_HEXAGON_MM_SELECT=1`, `-fa off`). HTP's brokered child exited
0 and the CDSP `closeSession` reply was `[0, 0]`. Thermal status was 0, battery
was 100%, and the phone was unplugged. The local model SHA-256 was
`f68203bfb98b1b1e8c64fac75fab10c4e36acac081609573b4df0fcc19c90dd9`.

This is a short functional smoke on one additional model, not a performance
measurement, a supported HTP configuration, or an end-user installation test.
It does not resolve the Qwen default/HMX and flash-attention failures, nor
qualify HTP cancellation, fallback, repeatability, or sustained operation. The
test used the local experimental broker from the device investigation; Ternux
still has no packaged HTP broker/launcher. Logs are
`cpu-smollm135-kat-2026-10-14.log` and
`htp-smollm135-hvx-faoff-kat-2026-10-14.log` in
`/home/sbj/npu-probe-2026-10-13/`.

The freshly rebuilt Vulkan prerelease was then installed to an isolated
temporary home by the current working-tree `ternux extension install` logic.
The same local model returned `2 + 2 = 4` on CPU and on Vulkan; verbose output
identified Vulkan0 as Adreno 825. The archive came from CI run
`38521164812` on main commit `6097aec`; the extension used the Turnip driver
already present on this device, so this was not a clean-driver installation
test. Logs are `cpu-vulkan-release-smollm-kat-2026-10-14.log` and
`gpu-vulkan-release-smollm-kat-2026-10-14.log` in the probe scratch directory.

A separate HTP interrupt probe sent SIGINT to the active inference child. The
child/broker did not finish within the 20-second cleanup window, and the test
harness had to kill their process group; no CDSP `closeSession` result was
recorded. This is a failed cancellation/cleanup check for the current
experimental probe route, not evidence that the HTP hardware itself failed.
After that forced process-group kill, a fresh HTP process again returned
`2 + 2 = 4`, exited 0, and closed the next broker session cleanly. This verifies
recovery after forced termination, not graceful cancellation. Logs:
`htp-smollm135-cancel-close-2026-10-14.log` and
`htp-smollm135-hvx-faoff-restart-kat-2026-10-14.log` in the same scratch directory.

### Stable Diffusion evaluation (`stable-diffusion.cpp` inference untested)

The supplied Vulkan-enabled `stable-diffusion.cpp` build is an observation only.
No compatible model/backend inference run, completed image, or seconds-per-image
measurement is recorded here. Do not infer inference support from build success.

The separate QNN SD1.5 runner has since completed a bounded 20-step 512×512
prompt-to-image run. Same-seed outputs repeated exactly (SHA-256
`1a13957f…6764fc3`) and visual review found a coherent landscape with one small
cyan artifact. Independent expected stage tensors remain unverified. This is a
separate implementation and does not qualify `stable-diffusion.cpp`; see the
[QNN experiment](../experiments/qnn-native/README.md) and
[release plan](../docs/ACCELERATOR-RELEASE-PLAN.md).

### Measured: repeated QNN SD1.5 image generation, 2026-10-14

The same separate runner generated 25 consecutive 512×512 images, each with 20
DPM++ steps, from the existing
`/sdcard/Llms/AbsoluteReality_qnn2.28_8gen2.zip`. All 25 completed without a
generation failure. Runner `image_complete.total_seconds` had a median of
29.758 s, mean of 31.116 s, and range of 28.233–55.803 s. The sum of the 20
UNet HTP denoising-step timings had a median of 15.962 s, mean of 17.027 s,
and range of 15.869–41.594 s. A single UNet step took 26.242 s in the slowest
image; that outlier was returned as a successful image, not a failed run.

CLIP prompt encoding ran on CPU; UNet denoising and VAE decoding ran through
Qualcomm QNN HTP. This reports an experimental mixed CPU/HTP image route. It is
not a CPU/GPU comparison using the same model, not an HTP-only end-to-end time,
and not proof of independent tensor correctness. All 25 outputs received a
visual screen: image 01 was inspected at full resolution and showed a coherent
landscape with a small cyan/black spot on the water; images 02–25 were inspected
in two contact sheets and showed coherent landscape variations without a
comparable obvious defect at that size. This is an initial visual screen, not
detailed full-resolution artifact review of every image. The 17m36s batch wall interval
includes monitoring poll delay and transitions between short-lived runner
processes. Per-run times above exclude that outer polling overhead.

The HTP route is supported by the per-run QNN HTP backend/device and graph
execution records. PRoot by itself does not expose an accelerator; this setup
reaches Android QNN through the existing FastRPC/Binder bridge. The GPU-labelled
thermal zones are sensor data, not evidence that GPU inference ran.

The same device has a separate Local Dream NPU observation: 512×512 at 20 steps
completed in 5.7 s. Ternux's 29.758 s median is about 5.2× longer at the same
resolution and step count. This is a substantial performance gap to investigate;
the models and runtimes differ, so it is not a controlled A/B comparison and
does not contradict the Ternux runner's QNN DSP execution logs. See the [Local
Dream device evidence](https://github.com/soobujmiah/skb/blob/main/devices/redmi-turbo-4-pro/accelerator-access-audit.md).

Per image, the median `runner_seconds - unet_20step_seconds` residual is
13.848 s. This includes CLIP, helper and QNN context startup, decoder execution,
and PNG writing; it is not a pure startup measurement. Code inspection shows
that each denoising step sends separate unconditional and conditional requests
to the UNet helper, for 40 serial graph requests per 20-step image. Each image
invocation also starts and tears down its UNet and decoder helpers. These are
specific profiling targets, not yet-proven explanations of the gap.

An instrumented follow-up on 2026-10-14 generated three more images in
30.797–31.122 s each. In the representative 30.797 s run, CPU CLIP took
3.482 s; streaming, hashing, and sealing the 880,827,736-byte UNet ZIP member
into a memfd took 7.275 s; 40 serial HTP UNet graph requests took 17.015 s;
both helper startups took 1.209 s; decoder execution took 0.791 s; and PNG
output took 0.044 s. Acquiring the 59,945,848-byte decoder member took 0.477 s.
This was a single instrumented timing profile; surrounding Python work and
timer boundaries account for small residuals. It identifies repeated UNet
archive streaming and serial graph requests as measured optimization targets,
without establishing the cause of Local Dream's speed advantage. No optimized
path has been qualified. The original archive remained unchanged. Local output
images are `/sdcard/Llms/ternux-profile-20261014-01.png` through
`ternux-profile-20261014-03.png`; the detailed timing log is
`/home/sbj/npu-probe-2026-10-13/sd15-profile-20261014-precise.log`.

Thermal-zone samples peaked at 41.9°C battery, 47.9°C `quiet_therm`, and 64.2°C
among GPU-labelled zones. No NPU-specific thermal sensor was identified. The
archive remained in place with SHA-256
`f479f3221fb90d31de1e695577f5aec9a5afb5fb7e076cfac40f00e039b22977`; model
members were passed via sealed anonymous memfds and were not extracted. The 25
PNG outputs were copied to `/sdcard/sdgen/`, with each destination hash checked
against the original. The machine-readable report, manifest and thermal samples
are also in that directory. Local per-image logs and original generated files
are under `/home/sbj/npu-probe-2026-10-13/sd15-npu-soak-20261014-182316/`.

### Vulkan llama.cpp model test (local Debian PRoot build)

The Vulkan-enabled build used the pinned llama.cpp source commit
`af50f2f248b475d9760f8e67503d01c0f194f5f4` (tag `b11582`) and was compiled
inside Debian ARM64 PRoot on the Redmi Turbo 4 Pro with GNU C++ 14.2.0,
`GGML_NATIVE=ON`, `GGML_VULKAN=ON`, `GGML_HEXAGON=OFF`, and
`GGML_OPENCL=OFF`. Vulkan development dependencies were unpacked under the
scratch workspace; no system packages were installed. The build artifact is
local scratch output and has not been published as a release asset.

The test used the existing file
`/sdcard/LAI/models/qwen2.5-1.5b-instruct-q4-0.gguf` in place (SHA-256
`dcd819ff094852c38faba6873d8ff0c9d51eadb2844539e52042ae5d647bbfdb`). The
prompt was `What is 2 + 2? Reply with only the number.` with seed 0, temperature
0, top-k 1, and an eight-token generation limit. `llama-cli -dev Vulkan0 -ngl
99` returned `4.000000`; verbose output showed `Vulkan0 (Adreno (TM) 825)` and
all 29/29 layers offloaded. This verifies functional Vulkan inference for this
model and prompt, not universal model compatibility.

Three `llama-bench` repetitions (`pp16/tg16`, no warm-up, 8 threads) reported:

| Backend | Prompt processing (`pp16`) | Token generation (`tg16`) |
|---|---:|---:|
| CPU (`-ngl 0`) | 25.38 ± 2.88 tok/s | 2.93 ± 0.35 tok/s |
| Vulkan (`-dev Vulkan0 -ngl 99`) | 42.18 ± 5.91 tok/s | 20.92 ± 0.50 tok/s |

This short run shows higher measured throughput on Vulkan for this model and
configuration. It is not a long-session, multi-device, or thermal comparison;
CPU thread-scaling runs varied substantially. Sustained thermals, power draw,
and longer workloads remain unmeasured. Logs:
`llama-vulkan-qwen15-gpu.log`, `llama-vulkan-qwen15-gpu-repeat3.md`,
`llama-vulkan-qwen15-cpu-repeat3.md`, `llama-vulkan-qwen15-gpu-bench.md`,
`llama-vulkan-qwen15-cpu-bench.md`, and `llama-vulkan-qwen15-cpu-scaling.md`
in `/home/sbj/npu-probe-2026-10-13/`.

| Question | Status |
|---|---|
| Does glmark2 name Zink/Adreno/Turnip? | **Yes — observed** |
| Is windowed OpenGL FPS captured? | **Yes — measured** |
| Is the ES command/output captured with its DRI3 warning? | **Yes — measured, caveated** |
| Blender viewport renderer identification | **Observed — Zink/Turnip; not a render-performance result** |
| Blender EEVEE render output | **Measured — 600 + 648 + 1,440 frames; separate 10-frame path comparison** |
| Blender Cycles GPU rendering | **Untested / not established** |
| llama.cpp CPU + Vulkan inference | **Verified — known-answer pass on both backends** |
| llama.cpp CPU + Vulkan throughput | **Measured — bounded repeated short and long workloads; one device/model** |
| stable-diffusion.cpp Vulkan build | **Observed only — build report, no inference run** |
| stable-diffusion.cpp inference / seconds per image | **Untested** |
| Are sustained thermals/power measured? | **No** |
| Is same-device VirGL versus Zink measured? | **No** |

---

## References

- [glmark2](https://github.com/glmark2/glmark2)
- [Mesa Zink](https://docs.mesa3d.org/drivers/zink.html)
- [Blender 4.3 GPU rendering](https://docs.blender.org/manual/en/4.3/render/cycles/gpu_rendering.html)
- [llama.cpp Vulkan build](https://github.com/ggml-org/llama.cpp/blob/master/docs/build.md#vulkan)
- [stable-diffusion.cpp Vulkan build](https://github.com/leejet/stable-diffusion.cpp/blob/master/docs/build.md#build-with-vulkan)
