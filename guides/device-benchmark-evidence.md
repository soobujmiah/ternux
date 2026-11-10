# Ternux device benchmark evidence — detailed record

> This repository-only record preserves the complete graphics and accelerator evidence, test boundaries, reproduction steps, and dated experiment history. The published benchmark page is a concise current-state summary.

This page records what has actually been measured on a real ternux setup, what was
only observed, and what remains unverified. It exists to prevent build success,
renderer detection and benchmark performance from being mixed into one claim.

> **Snapshot:** evidence through 2026-11-07 on one Redmi Turbo 4 Pro / SM8735
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

<a id="mpfb2-human-character-build"></a>

## Measured: MPFB2 human-character build, 2026-10-14/15

The owner-reported device run completed on the Redmi Turbo 4 Pro in PRoot
Debian 13 arm64, from 2026-10-14 23:00 to 2026-10-15 01:00 (+06). It used
Blender 4.3.2, MPFB2 2.0.18, EEVEE Next, and the Adreno 825 through
Zink/Turnip. This is a separate human-mesh workflow from the procedural
character used in the cartoon-pipeline measurements above.

| Operation | Measured time / output |
|---|---:|
| `HumanService.create_human` | 0.4 s |
| Full character rebuild (macro + 6 targets + skin + 6 assets + rig + weight binding) | 3.9 s |
| Load and fit all 6 assets | about 2 s |
| 460×800 still | about 4 s |
| 540×960 animation frame | 3.8 s |
| 120-frame, 5 s shot | about 7.5 min; output 392 kB after x264 CRF 18 |

The reported 5-second output was 540×960 at 24 fps. The timing is evidence for
this one character, scene, and device configuration; it is not a general
throughput promise or a multi-hour thermal test. The report did not provide
per-frame timing distribution, peak memory, power, or thermal measurements for
this run.

This MPFB2 run used Blender's saved user preferences so the extension could
load. `--factory-startup` disables extensions and the `blender-gpu` MCP server
uses that flag, so MPFB2 scripts must use a separate Blender process. For
headless work, the tested display paths were `DISPLAY=:0` or Xvfb `:9` with
`GALLIUM_DRIVER=zink`; recheck the active display before reuse. The extension's
API setup, helper-group rigging caveat, fitting sequence, licensing, and
reproduction notes are in the SKB
[MPFB2 workflow](https://github.com/soobujmiah/skb/blob/main/engineering/ANIMATION_PRODUCTION_PIPELINE.md#mpfb2-human-character-workflow)
and [device environment record](https://github.com/soobujmiah/skb/blob/main/devices/redmi-turbo-4-pro/current-termux-environment.md#blender-mpfb2-human-generation).

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

### Managed Stable Diffusion Vulkan inference (2026-11-07)

The pinned `stable-diffusion.cpp` ARM64 extension (upstream commit
`5a1ba5d895bec4e07deab80d6d791721cd59d9c2`) generated a valid 512×512 image
with 10 steps, seed 42 and tiled Vulkan VAE on the Redmi Turbo 4 Pro / SM8735 /
Adreno 825. The user-provided SD1.5 Q8_0 model SHA-256 is
`d0555243938c62faeefb4ac93f6c7a053ad373a4290c5256bce229aeb193bf94`. The
managed-extension run took 92.91 s; a second clean Debian guest run took 91.18 s
and produced the same PNG SHA-256
`b59b0b3e43226b4ae484b433aadf4d681eb87de7ee300b78a9adc1029a2ec65a`. The
model remained outside the extension. This verifies one model/device/settings
combination, not broad quality or performance. CPU image output remains
unqualified. Full reproduction and dependency details: [Stable Diffusion
CPU/Vulkan qualification](../handoffs/stable-diffusion-cpu-vulkan-qualification-2026-11-07.md).

### Historical build-only observation (superseded)

The initial Vulkan-enabled `stable-diffusion.cpp` build report did not include a
model run. That observation was superseded by the managed-extension device
qualification below: a pinned ARM64 build generated a valid tiled-Vulkan image
on Adreno 825. The old build report alone is not the inference evidence.

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
| MPFB2 human-character build and render timing | **Measured — one rigged build and 120-frame shot on one device; no thermal/power result** |
| Blender Cycles GPU rendering | **Untested / not established** |
| llama.cpp CPU + Vulkan inference | **Verified — known-answer pass on both backends** |
| llama.cpp CPU + Vulkan throughput | **Measured — bounded repeated short and long workloads; one device/model** |
| stable-diffusion.cpp Vulkan build | **Verified — pinned managed extension installed and launched** |
| stable-diffusion.cpp Vulkan inference | **Verified — 512×512 / 10-step tiled-VAE image on Adreno 825; repeated hash in clean guest** |
| stable-diffusion.cpp CPU image quality | **Unqualified — severe artifacts in tested Q8_0 output** |
| Are sustained thermals/power measured? | **No** |
| Is same-device VirGL versus Zink measured? | **No** |

---

### Ternux desktop restart and idle-resource observation (2026-11-06)

On the Redmi Turbo 4 Pro running Android 16, Termux, Debian 13 PRoot, and the Zink/Turnip route, the installed Ternux 2.0.0 package was rebuilt from launcher revision 13 and reinstalled locally. The managed `ternux restart` command was timed from before shutdown until `xfce4-session`, `xfce4-panel`, and `xfdesktop` were all visible in the process table: **14,198 ms**. This end-to-end value includes teardown, the restart command's fixed one-second pause, and readiness polling; it is not a desktop-only startup latency.

Three seconds after the readiness point, `ternux status --json` still reported the session running with X11 and PulseAudio active. A read-only 752×1155 X11 capture showed the Xfce panel, dock, desktop icons, and wallpaper rendered normally. `ternux verify --json` passed; full `ternux doctor --json` reported 26 OK, zero warnings, zero failures. At the later doctor sample, Android reported about 3,984 MiB available of about 11 GiB total and a 40°C battery reading.

The new launcher applies theme, wallpaper, and compositor-off defaults once per guest user, then skips repeated Xfconf launches and wallpaper reloads on later sessions. No pre-change timing or controlled before/after memory measurement was collected, so this observation does **not** quantify a speedup or memory reduction. The focused regression suite passed 98/98 after the launcher change. The sample is one device/session and does not establish low-RAM behavior across devices.

### 2026-11-07 matched small-model CPU/Vulkan/HTP throughput (Qwen2.5 0.5B Q4_0)

The model at `/sdcard/Llms/qwen2.5-0.5b-instruct-q4_0.gguf` used the same
prompt, 64-token output cap, context 2048, batch/ubatch 128, temperature 0,
seed 42 and four-thread setting on CPU, Adreno Vulkan and brokered Hexagon HTP.
Three rounds ran in CPU → Vulkan → HTP order so the backends were interleaved.

| Backend | Generation tok/s, three runs | Median |
|---|---:|---:|
| CPU (`-ngl 0`) | 7.2 / 8.0 / 8.1 | 8.0 |
| Adreno 825 Vulkan (`-dev Vulkan0 -ngl 99`) | 24.1 / 24.8 / 26.3 | 24.8 |
| Hexagon HTP (`htp-run`, HTP0) | 46.9 / 46.2 / 43.9 | 46.2 |

In this bounded run, HTP's median was about 1.86× Vulkan and 5.78× CPU.
All three HTP broker sessions closed cleanly (`closeSession` transport status 0,
reply `[0, 0]`). A separate known-answer run returned `4` and assigned all
24 layers to HTP0. The throughput runs did not separately verify response
quality or HTP layer assignment; this is a short generation benchmark on one
device, not an energy, thermal-stability or sustained-performance test. HTP
correctness/operator gates remain open.

A later llama.cpp verbose load of this same file reported GGUF `general.name`
`qwen2.5-0.5b-instruct`, but runtime model type `1B` and 630.17 million
parameters. Until that difference from the filename's nominal 0.5B label is
explained against the model source, treat the throughput figures as results for
this exact file rather than a verified 0.5B model-size comparison.

Reproduce in the Debian guest after loading the Vulkan extension environment;
the HTP launcher supplies its own broker and configuration:

```bash
MODEL=/sdcard/Llms/qwen2.5-0.5b-instruct-q4_0.gguf
PROMPT='Write a concise paragraph about how an efficient mobile computer balances speed, battery use, and memory.'
source "$HOME/.local/opt/ternux-extensions/llama-vulkan/env.sh"
# Repeat each command three times, in CPU → Vulkan → HTP order.
llama-cli -m "$MODEL" -ngl 0 -t 4 -tb 4 -p "$PROMPT" -n 64 -c 2048 -b 128 -ub 128 --temp 0 --seed 42 --ignore-eos
llama-cli -m "$MODEL" -dev Vulkan0 -ngl 99 -t 4 -tb 4 -p "$PROMPT" -n 64 -c 2048 -b 128 -ub 128 --temp 0 --seed 42 --ignore-eos
"$HOME/.local/opt/ternux-extensions/llama-htp-experimental/bin/htp-run" -m "$MODEL" -t 4 -tb 4 -p "$PROMPT" -n 64 -c 2048 -b 128 -ub 128 --temp 0 --seed 42 --ignore-eos
```

### 2026-11-07 same-build CPU/Vulkan throughput repeat (Qwen2.5 0.5B Q4_0)

Using the existing user model `/sdcard/Llms/qwen2.5-0.5b-instruct-q4_0.gguf`
(SHA-256 `7671c0c304e6ce5a7fc577bcb12aba01e2c155cc2efd29b2213c95b18edaf6ed`),
I ran the same Vulkan-enabled `llama-bench` binary three times per setting in
the Debian guest. The CPU row used `-ngl 0` (no model layers offloaded); the
GPU row used `-ngl 99` and the detected Adreno 825 Turnip device. Both used a
128-token prompt workload, 64-token generation workload, and four threads.

| Setting | Prompt processing, pp128 (tok/s) | Generation, tg64 (tok/s) |
|---|---:|---:|
| CPU (`-ngl 0`) | 145.11 ± 12.42 | 12.73 ± 0.75 |
| Adreno 825 Vulkan (`-ngl 99`) | 360.55 ± 2.12 | 33.73 ± 0.59 |

These are llama-bench mean ± standard deviation across three repetitions. In
this short workload, Vulkan generation throughput was about 2.65× the CPU
setting. The test did not measure answer quality, energy, thermals, sustained
use, or performance across other models/devices. The binary was llama.cpp
`0.6.0-dev`, build commit `af50f2f`, SHA-256
`f62b0d2717159175792d83e807208b90539681611e78b5c3c7acb145fb85112c`.

Reproduce from the Debian guest with the installed Vulkan extension:

```bash
MODEL=/sdcard/Llms/qwen2.5-0.5b-instruct-q4_0.gguf
BENCH="$HOME/.local/opt/ternux-extensions/llama-vulkan/bin/llama-bench"
"$BENCH" -m "$MODEL" -p 128 -n 64 -r 3 -t 4 -ngl 0
"$BENCH" -m "$MODEL" -p 128 -n 64 -r 3 -t 4 -ngl 99
```

### 2026-11-07 managed-extension CPU/Vulkan known-answer check (Qwen GGUF)

I verified the installed `llama-vulkan` extension from the Debian guest using
the existing `/sdcard/Llms/qwen2.5-0.5b-instruct-q4_0.gguf` file in place
(SHA-256 `7671c0c304e6ce5a7fc577bcb12aba01e2c155cc2efd29b2213c95b18edaf6ed`).
The installed `llama-cli` reported version `0.6.0-dev`, build commit
`af50f2f`, matching the extension manifest. On CPU (`-ngl 0`, two threads),
the deterministic `2 + 2` prompt returned `4`. On `Vulkan0`, identified as
Adreno 825, it also returned `4`; the verbose log confirmed **25/25 layers
offloaded** to Vulkan. This rechecks both installed-extension routes against
the model currently stored under `/sdcard/Llms`.

The short interactive runs reported 11.6 tok/s generation on CPU and
19.6 tok/s on Vulkan in two separate invocations. A subsequent same-binary
`llama-bench` comparison used 128 prompt tokens, 64 generated tokens, two
threads, and three repetitions per backend:

| Backend | Prompt processing, pp128 (tok/s) | Generation, tg64 (tok/s) |
|---|---:|---:|
| CPU (`-ngl 0`) | 133.09 ± 1.39 | 13.15 ± 0.08 |
| Adreno 825 Vulkan (`-ngl 99`) | 360.96 ± 5.53 | 33.94 ± 0.52 |

Vulkan generation was 2.58× CPU in this bounded benchmark. The benchmark
identified the file as `qwen2 1B Q4_0`, 630.17M parameters, despite the
filename's 0.5B label. Results apply only to this exact file, binary, device,
and settings. They do not qualify output quality, thermal or sustained
behavior, or other devices. The benchmark executable is llama.cpp
`0.6.0-dev`, build commit `af50f2f`, SHA-256
`f62b0d2717159175792d83e807208b90539681611e78b5c3c7acb145fb85112c`.

Reproduce in the Debian guest:

```bash
MODEL=/sdcard/Llms/qwen2.5-0.5b-instruct-q4_0.gguf
source "$HOME/.local/opt/ternux-extensions/llama-vulkan/env.sh"
llama-cli --version
llama-cli -m "$MODEL" -ngl 0 -t 2 -c 256 \
  -p 'What is 2 + 2? Answer with the number only.' -n 8 --no-warmup
llama-cli -m "$MODEL" -dev Vulkan0 -ngl 99 -t 2 -c 256 \
  -p 'What is 2 + 2? Answer with the number only.' -n 8 --no-warmup -v
llama-bench -m "$MODEL" -p 128 -n 64 -r 3 -t 2 -ngl 0
llama-bench -m "$MODEL" -p 128 -n 64 -r 3 -t 2 -ngl 99 -dev Vulkan0
```

### 2026-11-07 Qwen2.5 1.5B Q4_K_M CPU/Vulkan benchmark

The pre-existing model `/sdcard/LAI/models/qwen2.5-1.5b-instruct-q4_k_m.gguf`
was verified by SHA-256 (`6a1a2eb6d15622bf3c96857206351ba97e1af16c30d7a74ee38970e434e9407e`)
to match the Qwen GGUF file at repository revision
[`91cad51170dc346986eccefdc2dd33a9da36ead9`](https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/tree/91cad51170dc346986eccefdc2dd33a9da36ead9). It is 1,117,320,736 bytes
(1.04 GiB). No new model download was needed.

I used the same installed Vulkan-enabled `llama-bench` binary for both
settings, with three repetitions, a 128-token prompt workload, a 64-token
generation workload and four threads. `-ngl 0` kept model layers on CPU;
`-ngl 99` offloaded them to the detected Adreno 825 Turnip device.

| Setting | Prompt processing, pp128 (tok/s) | Generation, tg64 (tok/s) |
|---|---:|---:|
| CPU (`-ngl 0`) | 75.62 ± 0.11 | 6.11 ± 0.87 |
| Adreno 825 Vulkan (`-ngl 99`) | 106.18 ± 0.21 | 17.32 ± 0.26 |

Values are mean ± standard deviation across three repetitions. Vulkan
generation was about 2.83× the CPU result in this bounded benchmark. A separate
deterministic `2 + 2 =` known-answer run returned `4` with both CPU and Vulkan
settings (temperature 0, seed 42, four threads). This does not establish broad
answer quality, energy use, thermals, sustained behavior, or results on other
models/devices. The benchmark executable is llama.cpp `0.6.0-dev`, build commit
`af50f2f`, SHA-256
`f62b0d2717159175792d83e807208b90539681611e78b5c3c7acb145fb85112c`.

Reproduce in the Debian guest with the installed Vulkan extension:

```bash
MODEL=/sdcard/LAI/models/qwen2.5-1.5b-instruct-q4_k_m.gguf
BENCH="$HOME/.local/opt/ternux-extensions/llama-vulkan/bin/llama-bench"
"$BENCH" -m "$MODEL" -p 128 -n 64 -r 3 -t 4 -ngl 0
"$BENCH" -m "$MODEL" -p 128 -n 64 -r 3 -t 4 -ngl 99
CLI="$HOME/.local/opt/ternux-extensions/llama-vulkan/bin/llama-cli"
"$CLI" -m "$MODEL" -p "2 + 2 =" -n 8 -c 512 -t 4 --temp 0 --seed 42 --no-warmup -ngl 0
"$CLI" -m "$MODEL" -p "2 + 2 =" -n 8 -c 512 -t 4 --temp 0 --seed 42 --no-warmup -ngl 99
```

### 2026-11-07 Qwen2.5 1.5B HTP cold-start known-answer repeats

Using the existing `/sdcard/LAI/models/qwen2.5-1.5b-instruct-q4_k_m.gguf` in place, I started three independent HTP runner processes in sequence. Each used the same deterministic arithmetic prompt, seed 42, temperature 0, four threads, and an eight-token limit. All three returned `4`; generation measured 22.0–22.3 tok/s, each brokered child exited 0, and every CDSP session closed with transport status 0 and reply `[0, 0]`. No timeout or error appeared in the captured runs. This is a short restart/reopen check on one model and device, not sustained or broad HTP qualification; numerical operator failures and other release gates remain open.

Reproduce in the Debian guest as `ternux`:

```bash
MODEL=/sdcard/LAI/models/qwen2.5-1.5b-instruct-q4_k_m.gguf
RUNNER="$HOME/.local/opt/ternux-extensions/llama-htp-experimental/bin/htp-run"
for run in 1 2 3; do
  timeout 90 "$RUNNER" -m "$MODEL" -t 4 -tb 4 \
    -p "What is 2 + 2? Reply with only the number." -n 8 -c 512 \
    -b 128 -ub 128 --temp 0 --seed 42
done
```

### 2026-11-07 installed HTP long-session and repeated-reopen check (Qwen2.5 1.5B Q4_K_M)

On the Redmi Turbo 4 Pro / SM8735, I used the already-installed managed
llama-htp-experimental launcher and the existing model
/sdcard/LAI/models/qwen2.5-1.5b-instruct-q4_k_m.gguf (SHA-256
6a1a2eb6d15622bf3c96857206351ba97e1af16c30d7a74ee38970e434e9407e). No model
file was moved or modified. Five additional independent cold-start processes
used four threads, a fixed 2 + 2 prompt, 64 generated tokens, context 2048,
batch/ubatch 128, temperature 0, seed 42, and --ignore-eos. All five began
with the expected answer 4; generation measured 19.6–19.9 tok/s, each child
exited 0, and each CDSP session returned [0, 0] on close.

A separate single session generated 2,048 tokens with context 4096, the same
four-thread managed HTP route, batch/ubatch 128, temperature 0, seed 42 and
--ignore-eos. It completed in 136 seconds at 15.5 generation tok/s; the broker
child exited 0 and CDSP returned [0, 0]. This shows one clean, approximately
two-minute long-session workload plus five clean cold restarts for this exact
model, extension and device. It is not a thermal soak, power/energy measurement,
a CPU/Vulkan comparison, general operator qualification, or evidence that the
experimental HTP route is release-supported. The lower long-session rate is
observed but its cause was not isolated.

Reproduce in the Debian guest as the ternux user. Each cold-start invocation must print its broker child exit and CDSP close status; the five short runs should begin with answer 4.

```bash
MODEL=/sdcard/LAI/models/qwen2.5-1.5b-instruct-q4_k_m.gguf
RUNNER="$HOME/.local/opt/ternux-extensions/llama-htp-experimental/bin/htp-run"
for run in 1 2 3 4 5; do
  "$RUNNER" -m "$MODEL" -t 4 -tb 4 -p "Solve 2 + 2. Reply with only the number." -n 64 -c 2048 -b 128 -ub 128 --temp 0 --seed 42 --ignore-eos
done
"$RUNNER" -m "$MODEL" -t 4 -tb 4 -p "Write a detailed but factual explanation of how smartphone neural processing units execute local language models." -n 2048 -c 4096 -b 128 -ub 128 --temp 0 --seed 42 --ignore-eos
```

### 2026-11-07 matched Qwen2.5 1.5B CPU/Vulkan/HTP generation

On the Redmi Turbo 4 Pro / SM8735, I ran three interleaved CPU → Vulkan → HTP
rounds with the existing model /sdcard/LAI/models/qwen2.5-1.5b-instruct-q4_k_m.gguf
(SHA-256 6a1a2eb6d15622bf3c96857206351ba97e1af16c30d7a74ee38970e434e9407e).
Each route used four threads, the same arithmetic prompt, 64 generated tokens,
context 2048, batch/ubatch 128, temperature 0, seed 42 and --ignore-eos. All
nine runs began with the expected answer 4.

| Backend | Generation tok/s, three rounds | Median |
|---|---:|---:|
| CPU, llama.cpp b11582 (-ngl 0) | 8.8 / 7.6 / 7.6 | 7.6 |
| Adreno 825 Vulkan, b11582 (-ngl 99) | 18.1 / 18.4 / 18.2 | 18.2 |
| Hexagon HTP0, managed experimental build b1-af50f2f | 18.9 / 18.7 / 19.0 | 18.9 |

For this exact model and workload, the HTP median was about 1.04x Vulkan and
2.49x CPU. CPU and Vulkan used the same b11582 binary; the managed HTP extension
is a separate build, so this is a matched workload rather than a same-binary
comparison. Each HTP child exited 0 and each CDSP session closed with reply
[0, 0]. This bounded test does not qualify HTP operator correctness, sustained
thermal behavior, energy efficiency, or release support.

Reproduce in the Debian guest as the ternux user:

```bash
MODEL=/sdcard/LAI/models/qwen2.5-1.5b-instruct-q4_k_m.gguf
VULKAN_HOME="$HOME/.local/opt/ternux-extensions/llama-vulkan"
source "$VULKAN_HOME/env.sh"
CLI="$VULKAN_HOME/bin/llama-cli"
HTP="$HOME/.local/opt/ternux-extensions/llama-htp-experimental/bin/htp-run"
for run in 1 2 3; do
  "$CLI" -m "$MODEL" -ngl 0 -t 4 -tb 4 -p "Solve 2 + 2. Reply with only the number." -n 64 -c 2048 -b 128 -ub 128 --temp 0 --seed 42 --ignore-eos
  "$CLI" -m "$MODEL" -dev Vulkan0 -ngl 99 -t 4 -tb 4 -p "Solve 2 + 2. Reply with only the number." -n 64 -c 2048 -b 128 -ub 128 --temp 0 --seed 42 --ignore-eos
  env -u LD_LIBRARY_PATH -u LLAMA_HOME -u VK_ICD_FILENAMES "$HTP" -m "$MODEL" -t 4 -tb 4 -p "Solve 2 + 2. Reply with only the number." -n 64 -c 2048 -b 128 -ub 128 --temp 0 --seed 42 --ignore-eos
done
```

### 2026-11-07 HTP CPU-thread scaling

Using the same existing Qwen2.5 1.5B Q4_K_M model, deterministic arithmetic
prompt, four batch threads, 64 generated tokens, context 2048, batch/ubatch 128,
temperature 0, seed 42 and --ignore-eos, I interleaved three HTP runs each at
one, two and four generation threads (in that fixed order per round). All nine
runs began with answer 4 and each broker/CDSP session closed cleanly.

| Generation threads (-t) | Generation tok/s, three rounds | Median |
|---|---:|---:|
| 1 | 18.9 / 19.0 / 17.8 | 18.9 |
| 2 | 18.2 / 17.9 / 18.8 | 18.2 |
| 4 | 18.4 / 16.5 / 18.4 | 18.4 |

One generation thread had the highest median in this small sample, while the
spread and fixed run order make the differences inconclusive. This does not
measure CPU utilization, memory, power or thermal behavior, and is not enough
to change the launcher's defaults. It suggests testing a low-thread setting
for this exact model when prioritizing interactive headroom.

Reproduce as the ternux user in the Debian guest:

```bash
MODEL=/sdcard/LAI/models/qwen2.5-1.5b-instruct-q4_k_m.gguf
RUNNER="$HOME/.local/opt/ternux-extensions/llama-htp-experimental/bin/htp-run"
for round in 1 2 3; do
  for threads in 1 2 4; do
    "$RUNNER" -m "$MODEL" -t "$threads" -tb 4 -p "Solve 2 + 2. Reply with only the number." -n 64 -c 2048 -b 128 -ub 128 --temp 0 --seed 42 --ignore-eos
  done
done
```

### 2026-11-07 SM8735 integer-HMX candidate probe

A build-only [CI run 42348072918](https://github.com/soobujmiah/ternux/actions/runs/42348072918) produced a disposable artifact from the unmerged [llama.cpp PR #29740](https://github.com/ggml-org/llama.cpp/pull/29740), commit `08c83734f9c5c3b497e98b96f1a380f5a6084468`. The archive SHA-256 was `52877aad044c6da3f701d0230fde86520ce26066a412118bfb93e1a6f238de0a`. I verified the checksum and installed the extracted files only in the isolated `ternux-clean-apt` Debian guest; the production HTP extension and active Debian desktop were not changed.

On SM8735 / HTP V73, llama.cpp detected `HMX FP16: no` and selected its integer-HMX route. With the existing model `/sdcard/Llms/qwen2.5-0.5b-instruct-q4_0.gguf` (SHA-256 `7671c0c304e6ce5a7fc577bcb12aba01e2c155cc2efd29b2213c95b18edaf6ed`), the deterministic prompt used in the earlier matched benchmark, 64 generated tokens, context 2048, batch/ubatch 128, four threads, temperature 0, seed 42, and flash attention off produced:

| Run | Prompt tok/s | Generation tok/s | HTP placement | Broker close |
|---|---:|---:|---|---|
| 1 | 303.4 | 48.5 | 25/25 layers | `[0, 0]` |
| 2 | 299.3 | 47.3 | 25/25 layers | `[0, 0]` |
| 3 | 295.7 | 49.7 | 25/25 layers | `[0, 0]` |
| Median | 299.3 | 48.5 | 25/25 layers | clean |

The median generation rate was about 1.95× the earlier 24.8 tok/s Adreno Vulkan result and 6.06× the earlier 8.0 tok/s CPU result for the same model and prompt. Those CPU/Vulkan measurements used a different llama.cpp build, so this is a directional comparison rather than a same-binary comparison. The file name calls this a 0.5B model, but its GGUF metadata previously reported 630.17M parameters; these results apply to the exact file.

In the same guest and artifact, HTP `MUL_MAT` correctness completed 1,588/1,588 tests, and `GATED_DELTA_NET` completed 43/43. The full `FLASH_ATTN_EXT` suite aborted with a DSP `INTERNAL-ERROR` (child exit `-6`); a filtered, backend-reported supported subset (`kv=1024, nb=32`) reproduced the abort. In both cases the broker reported a clean CDSP `closeSession` reply `[0, 0]`. Therefore the candidate is **not** broadly operator-qualified. Ternux's production HTP launcher remains on the previously tested HVX matmul path with flash attention disabled. The candidate was not installed as an extension and does not qualify the upstream PR for release.

### 2026-11-07 installed HTP HVX perplexity screen

I compared the already-installed managed production HTP extension (HVX matmul,
flash attention off) with the CPU backend on the same Debian guest and
Wikitext-2 corpus. The CPU path used the installed llama.cpp b11582 CPU/Vulkan
extension; the HTP path used managed build b1-af50f2f through the Binder/FastRPC
broker. Each run evaluated the same first ten 512-token chunks with context,
batch and ubatch 512, four threads, no warm-up and flash attention off. Both
model files stayed at their existing user-provided paths.

| Existing model | CPU PPL | Installed HTP HVX PPL | Absolute difference | Relative difference |
|---|---:|---:|---:|---:|
| Qwen2.5 0.5B-named Q4_0 (SHA-256 7671c0c304e6ce5a7fc577bcb12aba01e2c155cc2efd29b2213c95b18edaf6ed) | 19.0657 ± 1.14854 | 19.0715 ± 1.14855 | 0.0058 | 0.03% |
| Qwen2.5 1.5B Q4_K_M (SHA-256 6a1a2eb6d15622bf3c96857206351ba97e1af16c30d7a74ee38970e434e9407e) | 12.1464 ± 0.65534 | 12.1015 ± 0.65151 | 0.0449 | 0.37% |

Both production HTP runs exited 0 and CDSP returned [0, 0] on close. The output
shows close CPU-reference perplexity for these exact models and corpus chunks.
It is not token-by-token equality, broad conversational quality, all-operator
coverage, or sustained/thermal qualification. The HTP run also warned that
manual -ngl 99 prevented its free-device-memory auto-fit query; inference still
completed. The model loader warned about the same non-control-looking </s>
token in both CPU and HTP runs.

Reproduce in the Debian guest as the ternux user. The corpus is the verified
file /tmp/ternux-hmx-quality/wikitext-2-raw/wiki.test.raw (SHA-256
173c87a53759e0201f33e0ccf978e510c2042d7f2cb78229d9a50d79b9e7dd08).

```bash
DATA=/tmp/ternux-hmx-quality/wikitext-2-raw/wiki.test.raw
SMALL=/sdcard/Llms/qwen2.5-0.5b-instruct-q4_0.gguf
LARGE=/sdcard/LAI/models/qwen2.5-1.5b-instruct-q4_k_m.gguf
VULKAN_HOME="$HOME/.local/opt/ternux-extensions/llama-vulkan"
source "$VULKAN_HOME/env.sh"
for MODEL in "$SMALL" "$LARGE"; do
  "$LLAMA_HOME/bin/llama-perplexity" -m "$MODEL" -f "$DATA" -ngl 0 -dev none -t 4 -c 512 -b 512 -ub 512 --chunks 10 -fa off --no-warmup
done
PKG="$HOME/.local/opt/ternux-extensions/llama-htp-experimental"
export LD_LIBRARY_PATH="$PKG/lib"
export ADSP_LIBRARY_PATH="$PKG/lib"
export LD_PRELOAD="$PKG/lib/libternux-htp-broker.so"
export GGML_HEXAGON_MM_SELECT=1
for MODEL in "$SMALL" "$LARGE"; do
  timeout 900 python3 "$PKG/libexec/htp-broker.py" -- "$PKG/bin/llama-perplexity" -m "$MODEL" -f "$DATA" -ngl 99 -dev HTP0 -t 4 -c 512 -b 512 -ub 512 --chunks 10 -fa off --no-warmup
done
```

### 2026-11-07 SM8735 integer-HMX model perplexity screen

I compared the disposable PR #29740 candidate's CPU and integer-HMX routes
against the same existing GGUF weights. The model files were not moved or
modified. The test used the upstream llama.cpp `wikitext-2-raw-v1.zip` corpus
from `ggml-org/ci` (archive SHA-256
`ef7edb566e3e2b2d31b29c1fdb0c89a4cc683597484c3dc2517919c615435a11`; extracted
`wiki.test.raw` SHA-256
`173c87a53759e0201f33e0ccf978e510c2042d7f2cb78229d9a50d79b9e7dd08`). Both
runs used the first ten 512-token chunks, context/batch/ubatch 512, four CPU
threads, flash attention off, and the same candidate build. The HTP run used
`GGML_HEXAGON_MM_SELECT=2` (HMX) through the Binder/FastRPC broker; it exited
0 and CDSP `closeSession` returned `[0, 0]`.

| Existing model | CPU PPL | Candidate HMX PPL | Absolute difference | Relative difference |
|---|---:|---:|---:|---:|
| `/sdcard/Llms/qwen2.5-0.5b-instruct-q4_0.gguf` (SHA-256 `7671c0c304e6ce5a7fc577bcb12aba01e2c155cc2efd29b2213c95b18edaf6ed`) | 19.1083 ± 1.15135 | 19.0430 ± 1.14537 | 0.0653 | 0.34% |
| `/sdcard/LAI/models/qwen2.5-1.5b-instruct-q4_k_m.gguf` (SHA-256 `6a1a2eb6d15622bf3c96857206351ba97e1af16c30d7a74ee38970e434e9407e`) | 12.1935 ± 0.65831 | 12.1015 ± 0.65151 | 0.0920 | 0.75% |

This is a useful target-device perplexity agreement signal across these two
models, not proof of token-by-token equality, broad answer quality, every HTP
operator, or sustained stability. A separate integer-HMX candidate run on the
same Qwen2.5 1.5B Q4_K_M model returned `4` for the deterministic `2 + 2`
prompt at 18.7 tok/s; its child exited 0 and CDSP `closeSession` returned
`[0, 0]`. This is one answer check, not a performance result. The HTP program
also logged that it could not query free device memory for its automatic fit
heuristic because the test set `-ngl 99`; inference continued to completion.
It does not change the production extension:
the candidate remains unmerged and its `FLASH_ATTN_EXT` path aborted on this
SM8735, while the production launcher keeps flash attention disabled. The
candidate is not yet release-qualified.

Reproduce in the isolated Debian guest after extracting the checksum-verified
candidate under `/tmp/ternux-hmx-probe-42348072918/extracted/` and the corpus
under `/tmp/ternux-hmx-quality/`:

```bash
PKG=/tmp/ternux-hmx-probe-42348072918/extracted/ternux-llama-htp-sm8735-hmx-probe-08c8373
DATA=/tmp/ternux-hmx-quality/wikitext-2-raw/wiki.test.raw
MODEL=/mnt/sdcard/Llms/qwen2.5-0.5b-instruct-q4_0.gguf
export LD_LIBRARY_PATH="$PKG/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
"$PKG/bin/llama-perplexity" -m "$MODEL" -f "$DATA" -ngl 0 -dev none \
  -t 4 -c 512 -b 512 -ub 512 --chunks 10 -fa off --no-warmup
export ADSP_LIBRARY_PATH="$PKG/lib"
export LD_PRELOAD="$PKG/lib/libternux-htp-broker.so"
export GGML_HEXAGON_MM_SELECT=2
timeout 240 python3 "$PKG/libexec/htp-broker.py" -- \
  "$PKG/bin/llama-perplexity" -m "$MODEL" -f "$DATA" -ngl 99 \
  -dev HTP0 -t 4 -c 512 -b 512 -ub 512 --chunks 10 -fa off --no-warmup
```

Repeat with the `/mnt/sdcard/LAI/models/qwen2.5-1.5b-instruct-q4_k_m.gguf`
model for the second row. These logs are in Termux temporary storage at
`/tmp/ternux-hmx-quality/{cpu-ppl,htp-ppl,cpu-1p5-ppl,htp-1p5-ppl}.log`.

### 2026-11-07 HTP long-generation thermal-boundary cancellation

Using the existing `/sdcard/LAI/models/qwen2.5-1.5b-instruct-q4_k_m.gguf`
directly, the installed experimental HTP runner started a 4,096-token-cap
generation (`-t 4 -tb 4 -c 6144 -b 128 -ub 128`, temperature 0, seed 42,
`--ignore-eos`). Battery temperature was 40.4 °C before the run. I sent SIGINT
after a live battery sample reached 43.0 °C; the immediate post-stop sample was
43.3 °C, and the highest sampled system thermal-zone value was 68.5 °C (zone
identities were not mapped to CPU/GPU/NPU). The partial run reported 12.9
generation tok/s. The brokered child exited 0 with cancel signal 2, and CDSP
`closeSession` returned transport status 0 and `[0, 0]`. No HTP process remained.

This is an intentional thermal-boundary stop, not a completed 4,096-token run
or a thermal-safety qualification. The generated text was repetitive and made
incorrect hardware claims; this stress prompt/run is excluded from answer-
quality evidence. Do not compare its rate with other runs because the prompt,
context, and duration differed. The raw output was held temporarily under
`/tmp/ternux-htp-sustained-4096-20261107.log` and removed after recording these
measurements. After the battery cooled to 41.9 °C, a new cold-start run on the
same model answered `4`; the brokered child exited 0 and CDSP returned `[0, 0]`
on close. Generation measured 16.7 tok/s for this eight-token check. This
validates one controlled cancel-then-reopen sequence only.

### 2026-11-07 single-turn chat-format known-answer screen (Qwen2.5 1.5B)

I used the existing `/sdcard/LAI/models/qwen2.5-1.5b-instruct-q4_k_m.gguf`
in place (SHA-256 `6a1a2eb6d15622bf3c96857206351ba97e1af16c30d7a74ee38970e434e9407e`).
CPU and Vulkan used the same installed b11582 binary; HTP used the installed
managed experimental build `b1-af50f2f`. All three ran a single-turn chat
(`-st --simple-io --no-display-prompt`), context 2048, four threads, batch and
ubatch 128, temperature 0, seed 42, no warmup, 16-token maximum, with the same
prompt: “What is the capital of France? Answer with one word.” All three
returned `Paris`. Reported generation rates were CPU 3.3, Vulkan 16.6, and HTP
15.5 tok/s. HTP child exit was 0 and CDSP `closeSession` returned `[0, 0]`.

This is one short known-answer check, not broad language-quality evidence. The
short no-warmup rates are not a backend ranking; HTP also uses a separate build.

### 2026-11-07 QNN batch setup-reuse repeat

Three 20-step, two-image batches were compared with separate same-seed single-image controls on the SM8735 phone using the existing QNN archive and licensed runtime. Two sequences ran single→batch→single; one ran batch→single→single. The latter ordering gives one counter-order sample, but the run order was not randomized.

| Seeds | Order | Single controls (s) | Batch total (s) | PNG SHA-256 (single = batch) |
|---|---|---:|---:|---|
| 20261016/17 | single → batch → single | 30.945 / 29.484 | 47.825 | `d93d395a437f57c92b81827bfd08e1347d6926eaf1534cb990af0a8ef504a977` / `cee7951bcd73ca0f677be9f8e2feed4151c42ba931adfb2929532fb71449cde0` |
| 20261018/19 | single → batch → single | 28.326 / 28.819 | 46.946 | `31470ff3c9292cbd67f972bff020857ded3031ddfa217256f93dcb808f89b00b` / `0bf7907657a36109f61b882fbb02267753c4b2110a255ecf3cd4a68b646f1c98` |
| 20261020/21 | batch → single → single | 31.084 / 28.928 | 45.931 | `0c337ab69e50fa21b4d15cf31cd224600c1c13d4dcbf75954fccdaae9a1e2d50` / `ee3f7a0a05a188b583128392efe8663bcbce5c1923ca244faadd6ee734cad553` |

Batch total mean was 46.901 s (45.931–47.825); paired single-control total mean was 59.195 s (57.145–60.429). In this three-pair sample the batch mean wall time was 20.8% lower. This is a small non-randomized comparison without confidence bounds, not a statistically established speedup or performance promise. The per-image work is still around 23.45 s on average, far from the owner's 3–5 s target. The same PNG hashes prove repeatability for these outputs only, not independent QNN model-stage correctness.

Before the two new sequences, Android's Termux battery API read 63%, 36.5°C; after them it read 62%, 37.1°C. These are battery readings, not an NPU thermal measurement. No NPU-specific sensor was identified. The original archive remained at SHA-256 `f479f3221fb90d31de1e695577f5aec9a5afb5fb7e076cfac40f00e039b22977`, and the runner reported `model_copy_to_disk: false` for all eight generated images in the two new sequences.

The eight new PNGs remain under `/sdcard/Llms/ternux-v2-validation/`: `qnn-single20-seed18.png`, `qnn-batch20-seed18-001.png`, `qnn-batch20-seed18-002.png`, `qnn-single20-seed19.png`, `qnn-batch20-seed20-001.png`, `qnn-batch20-seed20-002.png`, `qnn-single20-seed20.png`, and `qnn-single20-seed21.png`. The runner and QNN contexts were launched from the isolated Debian guest and the existing Android/Bionic helper. Reproduction command shape:

```bash
proot-distro login --shared-tmp ternux-clean-apt -- bash -lc '
  cd /data/data/com.termux/files/home/ternux-task-fix/experiments/qnn-native
  /root/.cache/ternux-qnn-venv/bin/python sd15_qnn_image.py \
    --archive /sdcard/Llms/AbsoluteReality_qnn2.28_8gen2.zip \
    --helper /data/data/com.termux/files/usr/tmp/ternux-qnn-audit/unpacked/bin/ternux-qnn-context-inspect \
    --runtime-dir /data/data/com.termux/files/home/.cache/native-ai-qualification/qnn-2.29-v73-image-test \
    --steps 20 --seed 20261018 --output /sdcard/Llms/ternux-v2-validation/repro.png
'
```

Add `--count 2` and use a new output path to reproduce a paired batch. Do not reuse these seeds/paths if preserving the captured files.

### 2026-11-09 short managed HTP known-answer check (two existing Qwen GGUFs)

On the Redmi Turbo 4 Pro / SM8735, I ran one eight-token, temperature-zero
known-answer check per model using the already-installed managed
`llama-htp-experimental` extension (`b1-af50f2f`, HVX matmul, flash attention
off). The existing files stayed in place:

| Model path | Prompt tok/s | Generation tok/s | Answer | Broker child | CDSP close |
|---|---:|---:|---|---:|---|
| `/sdcard/Llms/qwen2.5-0.5b-instruct-q4_0.gguf` | 107.3 | 38.3 | `4` | 0 | `[0, 0]` |
| `/sdcard/LAI/models/qwen2.5-1.5b-instruct-q4_k_m.gguf` | 32.5 | 13.2 | `4` | 0 | `[0, 0]` |

Both used four threads, context 512, batch/ubatch 128, seed 42, and the prompt
`What is 2 + 2? Reply with only the number.` Each was one cold-start run with
an eight-token cap; throughput is a spot reading, not a model comparison or
performance claim. The launcher reported HTP service discovery and access to
`/dev/fastrpc-cdsp`; both brokered children exited normally and their CDSP
sessions closed cleanly. The files were neither copied nor modified.

Battery temperature was 45.1°C before and 45.2°C after the two short runs. The
post-run doctor emitted its `battery_hot` warning, so further model/graphics
load was stopped. This validates a short known answer on the installed
experimental package and these two existing model files; it does not qualify
the current CI candidate, model quality, HTP operator coverage, or sustained
thermal behavior.

Reproduction, as Debian user `ternux`:

```bash
RUNNER="$HOME/.local/opt/ternux-extensions/llama-htp-experimental/bin/htp-run"
for MODEL in /sdcard/Llms/qwen2.5-0.5b-instruct-q4_0.gguf \
  /sdcard/LAI/models/qwen2.5-1.5b-instruct-q4_k_m.gguf; do
  timeout 60 "$RUNNER" -m "$MODEL" -t 4 -tb 4 \
    -p "What is 2 + 2? Reply with only the number." -n 8 -c 512 \
    -b 128 -ub 128 --temp 0 --seed 42
done
```

### 2026-11-10 bounded CPU/Vulkan cancellation and reopen check

On the Redmi Turbo 4 Pro (SM8735 / Adreno 825), the currently installed managed `llama-vulkan` CLI reports llama.cpp `0.6.0-dev`, build commit `af50f2f`, SHA-256 `4827f62ac89a442d76e9461c18115fa37d2c6cced0a887bf559b8ee615046eb5`. The unchanged Qwen2.5 0.5B Q4_0 model at `/sdcard/Llms/qwen2.5-0.5b-instruct-q4_0.gguf` has SHA-256 `7671c0c304e6ce5a7fc577bcb12aba01e2c155cc2efd29b2213c95b18edaf6ed`.

On CPU (`-ngl 0`) and Vulkan0 (`-ngl 99`), a 4,096-token counting generation was interrupted by a five-second SIGINT timeout. Both processes returned the expected timeout status 124, logged normal `Exiting...`, and left no `llama-cli` process. The Vulkan log identified Adreno 825 and showed model layers assigned to Vulkan0. Fresh CPU and Vulkan launches immediately afterward both returned the known answer `4`. The existing desktop and PulseAudio session stayed running.

This verifies bounded cancellation and reopen on this installed build/model. It does not qualify memory-pressure cancellation, sustained thermals, other models, or other devices. A post-run memory snapshot showed 4.3 GiB available; no artificial memory pressure was induced. Full output was captured in Termux temporary logs during the check; no model files were copied or modified.

## References

- [glmark2](https://github.com/glmark2/glmark2)
- [Mesa Zink](https://docs.mesa3d.org/drivers/zink.html)
- [Blender 4.3 GPU rendering](https://docs.blender.org/manual/en/4.3/render/cycles/gpu_rendering.html)
- [llama.cpp Vulkan build](https://github.com/ggml-org/llama.cpp/blob/master/docs/build.md#vulkan)
- [stable-diffusion.cpp Vulkan build](https://github.com/leejet/stable-diffusion.cpp/blob/master/docs/build.md#build-with-vulkan)


### 2026-11-10 retained HTP prerelease archive preflight

The no-rebuild candidate from Actions run `42783356495`, artifact `13747701121`,
was downloaded and its sidecar verified: archive SHA-256
`a139a6248356a44e89348ddbe1334edaad33f81a9efbe8f5b8fe3c5733dcf3de`,
15,691,323 bytes. Its build manifest targets Linux AArch64 / SM8735 HTP V73;
archive inventory includes `bin/htp-run`, `bin/llama-cli`,
`lib/libggml-htp-v73.so`, the broker shim/client, and the indexed upstream
license bundle. This is artifact-integrity and inventory evidence, not runtime
qualification.

Before a candidate inference run, Termux battery status reported 35.7°C; sampled
CPU thermal zones reached 50.8°C (`cpu-2-0-1`). No HTP inference was started. The
existing Qwen2.5 0.5B-named model remained at its original path and retained
SHA-256 `7671c0c304e6ce5a7fc577bcb12aba01e2c155cc2efd29b2213c95b18edaf6ed`.
No desktop process or model file was changed. Exact retained-archive device
execution remains **NOT_TESTED**; the previously recorded HTP device results
refer to earlier installed/build artifacts and are not silently transferred to
this archive.



### 2026-11-10 Llama 3.2 3B CPU/Vulkan bounded-context run

At 17:59–18:02 UTC on the Redmi Turbo 4 Pro (Android 16, SM8735 / Adreno
825), I inspected the already-authorized model directories and tested the
existing `/sdcard/LAI/models/llama-3.2-3b-instruct-q4_k_m.gguf` in place. The
file is 2,019,373,920 bytes, SHA-256
`c55a83bfb6396799337853ca69918a0b9bbb2917621078c34570bc17d20fd7a1`. The
installed llama.cpp binary is `0.6.0-dev` / `af50f2f`, SHA-256
`4827f62ac89a442d76e9461c18115fa37d2c6cced0a887bf559b8ee615046eb5`.
GGUF metadata identifies `Llama 3.2 3B Instruct`, Q4_K_M, 29 layers, and a
131,072-token maximum context.

One CPU attempt using the CLI defaults was killed during model loading before
producing output. The reason was not independently confirmed; no OOM-killer or
kernel log was available. A subsequent controlled run with `-c 512 -b 64
-ub 64` returned `4` on CPU and Vulkan. CPU short-run output reported 10.3 tok/s
prompt processing and 5.2 tok/s generation. Vulkan reported 40.9 tok/s prompt
processing and 12.0 tok/s generation, assigned 29/29 layers to Adreno 825, and
used about 1,918 MiB model, 56 MiB KV, and 9 MiB compute buffers. The first
Vulkan memory fit projected 1,983 MiB total against 3,678 MiB free. These
single-turn numbers are correctness/offload observations, not a performance
benchmark. The explicit small context proves only this short workload; longer
context behavior and sustained memory pressure remain untested.

Before the bounded runs, `ternux doctor --quick --json` reported 40 C battery
temperature and about 4.6 GiB available memory. Afterward it reported 40 C and
about 4.3 GiB available; `ternux status --json` and `ternux verify --json`
passed, with the existing desktop, X11 and PulseAudio still running under PID
16987. No model file was moved, copied, or deleted, and no service was
restarted. The default-context kill is retained as a failure observation; it
is not silently replaced by the bounded-context pass.

### 2026-11-10 short Qwen2.5 CPU/Vulkan correctness rerun

At 17:24–17:28 UTC on the Redmi Turbo 4 Pro (Android 16, SM8735 / Adreno
825), I ran a single-turn greedy `2 + 2` prompt against the existing models in
place. No model was downloaded, copied, moved, or deleted. Model hashes were
verified before inference:

- Qwen2.5 0.5B Instruct Q4_0 at `/sdcard/Llms/qwen2.5-0.5b-instruct-q4_0.gguf`,
  SHA-256 `7671c0c304e6ce5a7fc577bcb12aba01e2c155cc2efd29b2213c95b18edaf6ed`.
- Qwen2.5 1.5B Instruct Q4_K_M at
  `/sdcard/LAI/models/qwen2.5-1.5b-instruct-q4_k_m.gguf`, SHA-256
  `6a1a2eb6d15622bf3c96857206351ba97e1af16c30d7a74ee38970e434e9407e`.

The installed llama-vulkan CLI reports llama.cpp `0.6.0-dev`, build commit
`af50f2f`, binary SHA-256
`4827f62ac89a442d76e9461c18115fa37d2c6cced0a887bf559b8ee615046eb5`. The
reproducible command form was:

```bash
source "$HOME/.local/opt/ternux-extensions/llama-vulkan/env.sh"
MODEL=/sdcard/Llms/qwen2.5-0.5b-instruct-q4_0.gguf
llama-cli -m "$MODEL" -ngl 0 -t 4 \
  -p 'What is 2 + 2? Answer with the number only.' -n 8 --temp 0 --seed 1234 \
  --single-turn --verbosity 1
llama-cli -m "$MODEL" -dev Vulkan0 -ngl 99 -t 4 \
  -p 'What is 2 + 2? Answer with the number only.' -n 8 --temp 0 --seed 1234 \
  --single-turn --verbosity 4
```

The same commands were repeated with the 1.5B model path. All four runs exited
successfully and returned `4`. Verbose Vulkan logs identified `Vulkan0: Adreno
(TM) 825`, confirmed `offloaded 25/25 layers` for the 0.5B model and `29/29`
for 1.5B. The 0.5B Vulkan allocation used about 330 MiB model, 384 MiB KV and
67.51 MiB compute buffers; 1.5B used about 934 MiB model, 896 MiB KV and 96.51
MiB compute buffers. This is short correctness/offload evidence, not a
representative speed benchmark. One-token generation rates varied across these
brief invocations and are deliberately not presented as performance claims.

Battery temperature was 36.3°C before and 37.4°C after; the phone remained
unplugged and discharging. Native `ternux status --json` afterward still
reported the existing desktop running with X11 and PulseAudio, PID 16987. No
desktop, service, or model file was changed. This rerun does not test sustained
thermals, artificial memory pressure, broader model compatibility, or other
devices.
