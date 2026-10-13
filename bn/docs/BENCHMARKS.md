---
title: "বেঞ্চমার্ক ও ডিভাইস প্রমাণ"
description: "Measured glmark2 FPS, Blender renderer evidence, workload boundary এবং পুনরুৎপাদনযোগ্য ternux benchmark protocol।"
lang: "bn"
alt_url: "/docs/BENCHMARKS.html"
---

এই পৃষ্ঠায় বাস্তব ternux setup-এ আসলে কী মাপা হয়েছে, কী শুধু দেখা হয়েছে এবং
কী এখনো যাচাই হয়নি—তা রেকর্ড করা হয়েছে। Build success, renderer detection ও
benchmark performance যেন এক claim-এ মিশে না যায়, সেটিই এর উদ্দেশ্য।

> **Snapshot:** project author-এর দেওয়া August 2026-এর evidence। এটি একটি
> device/configuration; compatibility বা performance guarantee নয়।

---

## Result class

| Class | অর্থ |
|---|---|
| **Measured** | Complete output-এ numeric score, scene FPS বা অন্য reproducible measurement আছে |
| **Observed** | Output দেখায় যে application launch/build করেছে বা renderer/backend শনাক্ত করেছে |
| **Not benchmarked** | Complete, reproducible performance output দেওয়া হয়নি |

GPU option দিয়ে configure করা build **observed** থাকবে—যতক্ষণ না runtime log
নির্দিষ্ট device/backend দেখায় এবং benchmark বা workload সম্পন্ন করে।

---

## পরীক্ষিত configuration

| Field | Captured value |
|---|---|
| Phone | Redmi Turbo 4 Pro |
| SoC / GPU | Snapdragon 8s Gen 4 / Adreno 825 |
| Guest | PRoot Distro-এর মাধ্যমে Debian ARM64 |
| Display | Termux:X11-এর মাধ্যমে X11 |
| Mesa | 26.2.0-devel (দেওয়া output-এ `git-9452d1daec`) |
| Renderer | `zink Vulkan 1.4(Adreno (TM) 825 (MESA_TURNIP))` |
| OpenGL | glmark2-তে 4.6 compatibility profile; Blender-এ 4.6 core profile |
| OpenGL ES | 3.2 |
| glmark2 | 2023.01 |
| Surface | 800×600; captured header দুটিতে windowed হিসেবে reported |

Setup note route-টিকে Turnip/KGSL-এর ওপর Mesa Zink হিসেবে বর্ণনা করে। glmark2 ও
Blender-এর স্বাধীন renderer string সেই route-এর সঙ্গে সঙ্গতিপূর্ণ এবং কোনোটিতে
`llvmpipe` নেই।

---

## Measured: glmark2

### সারাংশ

| Command | Captured score | সর্বনিম্ন scene | সর্বোচ্চ scene |
|---|---:|---:|---:|
| `glmark2` | **140** | terrain: **45 FPS** | texture mipmap: **164 FPS** |
| `glmark2-es2 --off-screen` | **364** | loop/uniform: **53 FPS** | bump/height: **465 FPS** |

প্রথম command OpenGL 4.6 compatibility profile report করেছে। দ্বিতীয়টি OpenGL
ES 3.2 report করলেও এটিও print করেছে:

```text
MESA-EGL: warning: DRI3 error: Could not get DRI3 device
MESA-EGL: warning: Ensure your X server supports DRI3 to get accelerated rendering
```

তার renderer-এ তবু Zink, Adreno 825 ও `MESA_TURNIP` ছিল; `--off-screen` command
হওয়া সত্ত্বেও header-এ `Surface Size: 800x600 windowed` ছিল। তিনটি তথ্যই রাখা
হয়েছে। Result-টি evidence, তবে caveat-সহ evidence।

### সম্পূর্ণ captured scene FPS

`GL FPS` হলো `glmark2` run। `ES FPS` হলো আলাদাভাবে captured
`glmark2-es2 --off-screen` run। শুধু data archive করার জন্য পাশাপাশি রাখা হয়েছে;
এগুলো **apples-to-apples comparison নয়**।

| Scene | Options (পুনরাবৃত্ত অংশ সংক্ষেপিত) | GL FPS | ES FPS |
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

### Score-এর অর্থ

glmark2 score scene result aggregate করে। এটি universal GPU rating নয় এবং Xfce,
Blender বা game-এর FPS-ও নয়। Resolution, window/fullscreen/off-screen mode,
OpenGL বনাম OpenGL ES, compositor, VSync, Mesa version, thermal state ও background
activity—সবই result বদলায়।

শুধু একই নিচের বিষয়সহ run তুলনা করুন:

1. glmark2 version ও command;
2. API ও scene list;
3. resolution ও presentation mode;
4. Mesa/renderer stack;
5. compositor ও VSync environment;
6. thermal ও power condition।

---

## Observed: Blender 4.3.2

দেওয়া Blender system report-এ আছে:

```text
platform: 'Linux-6.17.0-PRoot-Distro-aarch64-with-glibc2.41'
windowing environment: 'X11'
renderer: 'zink Vulkan 1.4(Adreno (TM) 825 (MESA_TURNIP))'
vendor: 'Mesa'
version: '4.6 (Core Profile) Mesa 26.2.0-devel (git-9452d1daec)'
device type: 'SOFTWARE'
backend type: 'OPENGL'
```

এতে Python 3.13.5-ও report করা হয়েছে এবং Blender 4.3.2 শনাক্ত করা হয়েছে। Cycles
section-এ CPU capability আছে, কিন্তু GPU device নেই।

### সমর্থিত conclusion

Blender X11-এ launch করেছে এবং তার OpenGL viewport Zink/Turnip renderer দেখেছে।

### অসমর্থিত conclusion

এই report নিচের কোনোটিই প্রতিষ্ঠা করে না:

- Cycles GPU Compute support;
- Blender viewport FPS;
- Eevee বা Cycles render time;
- heavy-scene stability বা memory limit।

Blender কেবল তার তালিকাভুক্ত compute backend ও device-এর মাধ্যমে Cycles GPU
rendering support করে। Accelerated OpenGL viewport একটি আলাদা path।

---

## Observed: llama.cpp Vulkan build/use

Setup note-এ এইভাবে configured Debian build report করা হয়েছে:

```bash
cmake -B build -DGGML_VULKAN=ON -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
```

এতে ছোট 1–1.5B Q4 GGUF model ও GPU-layer offload-এর local CLI/server example-ও
আছে। কিন্তু complete `llama-bench` table, build commit, backend/device log, memory
reading বা thermal record নেই।

Publish করা যায় এমন evidence-এর জন্য চালান:

```bash
cd ~/llama.cpp
./build/bin/llama-cli --list-devices
./build/bin/llama-bench -m models/YOUR_MODEL.gguf -ngl 99 \
  2>&1 | tee ~/benchmarks/llama-bench.txt
git rev-parse HEAD | tee ~/benchmarks/llama-commit.txt
```

Model, quantization, model size, context, thread, GPU layer, `pp` ও `tg` row,
runtime backend/device, RAM ও temperature record করুন। তার আগে পরীক্ষিত ফোনটির
জন্য ternux কোনো llama.cpp tokens-per-second claim করে না।

---

## পরীক্ষামূলক: SM8735-এর জন্য llama.cpp Hexagon HTP artifact

আলাদা `llama.cpp Hexagon HTP artifact` workflow upstream llama.cpp tag
`b11582` (commit `af50f2f248b475d9760f8e67503d01c0f194f5f4`) থেকে reusable
Linux aarch64 package বানায়। এতে workflow-এ নথিভুক্ত pinned Snapdragon Linux
toolchain image digest ব্যবহার হয়। Workflow `ternux-llama-htp-sm8735-b11582`
নামে prerelease তৈরি করে। প্রকাশিত 15,519,631-byte aarch64 archive-এর
SHA-256 `dffcf83fa969f3ccfad238217b4ca7f3d47040e5e5b2fa834ebd3f123d144ea5`।

এটি research artifact; `--with-llm`-এর অংশ বা supported installer feature নয়।
আগের b11582 prebuilt Redmi Turbo 4 Pro / SM8735-এ brokered FastRPC path দিয়ে
HTP operator চালিয়েছিল, কিন্তু deterministic known-output test fail করেছিল।
GH-তে build করা exact archive-টিও PRoot Binder-brokered FastRPC path দিয়ে
পরীক্ষা করা হয়েছে: model load, সব layer HTP-তে বসানো, HTP operator profile
এবং session clean close সফল; কিন্তু `What is 2 + 2? Reply with only the
number.` prompt-এ malformed text (`.\".ss\"sssid Su SVː`) এসেছে। তাই সঠিক
inference **fail**। এটিকে supported inference build বা performance result
বলা যাবে না। Package-এ Qualcomm vendor runtime library, firmware বা Android
Binder/FastRPC broker নেই।

[Build run](https://github.com/soobujmiah/ternux/actions/runs/38381879734)।
একই packaged `llama-cli`-এর CPU baseline-ও সফল: একই model, prompt, seed ও
batch setting-এ `-ngl 0` দিলে `2 + 2 = 4.` এসেছে, গতি 44.32 generated token/s।
Brokered HTP-তে দুইবার একই malformed text এসেছে; দ্বিতীয় run-এ 28.63 generated
token/s মাপা হয়েছে। এটি ছোট 135M Q4_0 model-এ একটি সংক্ষিপ্ত test; তাই এই সংখ্যা
শুধু diagnostic, সাধারণ performance comparison নয়। Model SHA-256:
`f68203bfb98b1b1e8c64fac75fab10c4e36acac081609573b4df0fcc19c90dd9`।

Test setup: `--device HTP0 -ngl 99 --ctx-size 128 --batch-size 128
--ubatch-size 128 -n 8 --seed 0 --temp 0 --no-warmup`; CPU-তে একই argument-এর
সাথে `-ngl 0`। Android Binder DSP broker থেকে CDSP FastRPC descriptor দিয়ে HTP
চালানো হয়েছে। Log-এ `MUL_MAT_NX`, `FLASH_ATTN_EXT`, `RMS_NORM`, `SWIGLU`-সহ
HTP graph/operator record আছে; broker child clean exit এবং CDSP session close
করেছে। Test workspace-এর `/home/sbj/npu-probe-2026-10-13/` directory-তে
`gh-artifact-device-test.log`, `gh-artifact-htp-repeat.log` ও
`gh-artifact-cpu-baseline.log` log file আছে।

### আলাদা HTP operator পরীক্ষা

একই release library-কে একই brokered CDSP descriptor দিয়ে standalone GGML
graph-এ চালানো হয়েছে; CPU fallback বন্ধ ছিল:

| Operation | Shape / data | Result |
|---|---|---|
| `ADD` | 256 F32 element | **Pass**; mismatch 0; সর্বোচ্চ absolute error `9.53674e-07` |
| `MUL_MAT` | F32 × F32, K=16, M=8, N=4 | **Pass**; mismatch 0; সর্বোচ্চ absolute error `3.57628e-07` |
| `MUL_MAT` | Q4_0 × F32, K=576, M=8, N=2 | probe-এর `1e-5` comparison threshold-এ একই build-এর CPU backend-এর সঙ্গে 16/16 output **mismatch**; HTP-CPU সর্বোচ্চ absolute difference `0.00947738`। Explicit dequantized Q4_0 reference-এর সঙ্গে সর্বোচ্চ absolute error `0.00601411` (সর্বোচ্চ relative error `1.56%`)। HTP profile-এ `q4_0 x f32`, `hvx-tiled` `MUL_MAT` দেখা গেছে; compute সফল এবং CDSP session cleanly close করেছে। |
| `MUL_MAT` | Q4_0 × sparse F32, K=576, M=8, N=2 | `1e-5` threshold-এ 16টির 15টি output-এ **numeric mismatch**; সর্বোচ্চ absolute error `0.000181094`, সর্বোচ্চ relative error `0.0908%`। Long accumulation কমাতে প্রতি column-এ একটিমাত্র K position nonzero ছিল। HTP verbose trace-এ `q4_0 x f32`, `hvx-tiled` execution নিশ্চিত; graph compute সফল এবং CDSP session cleanly close করেছে। |
| `MUL_MAT` | dequantized Q4_0 weight-কে F32 করে একই sparse F32 input, K=576, M=8, N=2 | **Pass**; একই explicit reference-এর তুলনায় HTP F32 path-এর সর্বোচ্চ absolute error `1.49012e-08`। একই graph-এর CPU Q4_0 ফল reference থেকে সর্বোচ্চ `1.21743e-05` আলাদা ছিল। এতে discrepancy Q4_0 HTP execution path-এ সীমাবদ্ধ হয়; নির্দিষ্ট kernel defect প্রমাণ হয় না। |
| `MUL_MAT` | Q4_0 one-hot weight × F32 input; 128 output row দিয়ে HTP Q8 activation lane দেখা | **HTP compute pass**; decoded output residual সর্বোচ্চ `1.525879e-05`। 128টির 127টি inferred Q8 integer সাধারণ host rounding reference-এর সঙ্গে মিলে; একটি rounding boundary-র কাছে `-74` এসেছে, host reference `-75` দিয়েছে। এটি exact HVX quantizer emulation নয়। |
| `MUL_MAT` | পরীক্ষামূলক dense Q4_0 reference extension, K=576, M=8 | **Diagnostic comparison fail**; HTP সর্বোচ্চ `532544.875` magnitude-এর output দিয়েছে, আর CPU control manually dequantized reference-এর কাছাকাছি ছিল (CPU/reference সর্বোচ্চ error `≤0.0301`)। 2,592-byte random Q4_0 tensor-এর backend set/get round-trip-এ mismatch ছিল 0। পরের 576-lane extension-এ simple Q8 integer-এর সঙ্গে 10টি difference ও সর্বোচ্চ `0.0825` reconstruction residual ছিল; decoded-Q8 reference/layout এখনো unverified। এই probe-এ HTP result fail করেছে, তবে kernel defect-এর কারণ নির্ণীত নয়। |
| Q4_0 tensor round-trip | 2,592 quantized weight byte | **Pass**; backend set → get-এর পর সব byte অপরিবর্তিত ছিল। এই tensor-এর host-side tiled repack/de-repack data integrity যাচাই হয়েছে; DSP kernel tile-টি কীভাবে interpret করে তা প্রমাণ হয়নি। |

এই deterministic synthetic micro-test প্রমাণ করে না যে নির্দিষ্ট model layer-ই
malformed output-এর একমাত্র কারণ। Long accumulation-এর প্রভাব কমাতে sparse-input
follow-up করেছি; তাতেও ছোট per-output difference ছিল। একই 2,592 Q4_0 byte
backend-এর tiled repack/de-repack path দিয়ে পড়ে দেখেছি; কোনো byte বদলায়নি। এতে
host-side tensor round-trip যাচাই হয়েছে, তবে DSP kernel tile-টি কীভাবে interpret
করে তা অমীমাংসিত। একই dequantized weight ও sparse input দিয়ে HTP F32 matmul
reference-এর সাথে `1.49012e-08`-এর মধ্যে মিলে; CPU Q4_0 graph-এর পার্থক্য ছিল
সর্বোচ্চ `1.21743e-05`। Pinned b11582 source দেখায় Q4_0 HTP path-এ F32
activation-কে Q8_0 tile-এ quantize করা হয়। Generic GGML Q8_0 quantized activation
reference দিয়েও HTP-এর সঙ্গে সর্বোচ্চ `0.000193268` difference ছিল; exact HTP
activation quantizer ও rounding এখনও emulate করা হয়নি। পরের one-hot Q4_0
test-এ successful HTP output থেকে 128টি Q8 activation lane infer করা হয়েছে;
127টি সাধারণ host rounding reference-এর সাথে মিলেছে, আর একটি boundary-র কাছে
এক integer আলাদা ছিল। এটি full HVX quantizer emulation নয়। Dense reference
extension-এ 2,592-byte random Q4_0 tensor backend round-trip-এ অপরিবর্তিত ছিল।
CPU control manually dequantized F32 reference-এর `0.0301`-এর মধ্যে ছিল, কিন্তু
HTP অস্বাভাবিক বড় output দিয়েছে। আরেক 576-lane decode extension-এ
simple reference থেকে 10 integer difference এবং `0.0825` সর্বোচ্চ reconstruction
residual ছিল; lane mapping/reference এখনো যাচাই হয়নি। তাই এই diagnostic-এ HTP
result **fail**, তবে সুনির্দিষ্ট কারণ unverified। Q4_0 HTP path-এর quantization
ও arithmetic এখনো unresolved। Probe log
(`gh-artifact-htp-add-test.log`, `gh-artifact-htp-matmul-test.log`,
`gh-artifact-htp-q4-matmul-k576-test.log`,
`gh-artifact-htp-q4-sparse-verbose-test.log`,
`gh-artifact-htp-q4-roundtrip-test.log`,
`gh-artifact-htp-q4-cpu-f32-ref-test.log`,
`gh-artifact-htp-q4-q8-reference-test.log`,
`htp-q8-activation-decode-child.log`,
`htp-q8-activation-decode-full.log`,
`htp-q8-activation-decode-child.log`)
একই local probe directory-তে আছে।

Pinned HTP source Q4_0 weight-এর জন্য tiled Q8_0 activation quantizer নির্বাচন
করে; দেখুন [`matmul-ops.c`](https://github.com/ggml-org/llama.cpp/blob/af50f2f248b475d9760f8e67503d01c0f194f5f4/ggml/src/ggml-hexagon/htp/matmul-ops.c#L743-L755)। এই Q8_0 কাজ শুধু বর্তমান Q4_0 mismatch বোঝার diagnostic; এতে active NPU known-output inference gate Q8 model optimization-এ বদলাচ্ছে না।

### ভবিষ্যতের ঐচ্ছিক প্রার্থী: ternary 1.58-bit model

Microsoft BitNet-কে পরে Ternux-এর optional extension হিসেবে বিবেচনা করা যায়।
[Upstream project](https://github.com/microsoft/BitNet) বর্তমানে CPU ও GPU support
বলে এবং NPU support-কে forthcoming হিসেবে চিহ্নিত করে। এটি SM8735, Adreno,
Hexagon HTP বা Debian PRoot compatibility-এর প্রমাণ নয়। বর্তমান Q4_0
investigation শেষ না হওয়া পর্যন্ত এটি active test-এর বাইরে থাকবে। পরে পরীক্ষা
করলে native 1.58-bit runtime/model-কে সাধারণ IQ1/TQ1 GGUF quantization থেকে
আলাদা করে CPU, GPU ও NPU path স্বাধীনভাবে মাপতে হবে। Device-এ speed, heat ও
output quality এখনও unverified।
Probe source ও binary scratch artifact; llama.cpp release-এ নেই।

Workflow ও source pin: [llama-htp-artifact.yml](../../.github/workflows/llama-htp-artifact.yml)।
Device test detail: [SKB investigation](https://github.com/soobujmiah/skb/blob/main/devices/redmi-turbo-4-pro/evidence/debian-proot-npu-investigation-2026-10-13.md)। Exact archive-er retest log local probe scratch-er `gh-artifact-device-test.log`।

---

## Observed: stable-diffusion.cpp Vulkan build

দেওয়া note-এ একই ফোনে সফল build report করা হয়েছে:

```bash
cmake .. -DSD_VULKAN=ON -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release -j8
```

Generation command, verbose Vulkan device log, completed image, seed, model, step,
dimension, timing বা memory figure দেওয়া হয়নি। এটি reported Vulkan-enabled build
প্রমাণ করে—measured inference নয়।

ভবিষ্যৎ result-এ থাকা উচিত:

- exact stable-diffusion.cpp commit;
- model ও weight format/quantization;
- Vulkan এবং Adreno/Turnip নামসহ verbose log;
- prompt, negative prompt, seed, sampler, step ও resolution;
- wall time ও peak memory;
- output image checksum;
- temperature/power condition।

---

## Graphics measurement পুনরুৎপাদন করুন

ternux desktop চালু করে Debian-এর ভেতরে চালান:

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

Termux থেকে Android/device context-ও record করুন:

```bash
ternux profile show | tee ~/ternux-profile.txt
getprop ro.product.model | tee -a ~/ternux-profile.txt
getprop ro.build.version.release | tee -a ~/ternux-profile.txt
```

Fair comparison-এর জন্য আগে ফোন ঠান্ডা করুন, charger state ও screen setting একই
রাখুন, অপ্রয়োজনীয় app বন্ধ করুন, Xfce compositing enabled কি না জানান এবং অন্তত
তিনবার run করুন। শুধু সেরা run নয়—প্রতিটি repetition publish করুন।

---

## Quick health benchmark বনাম evidence reproduction

`ternux benchmark` সুবিধাজনক installation health check হিসেবে তৈরি। এটি fullscreen
glmark2 চেষ্টা করতে পারে এবং timeout ব্যবহার করে; তাই এই পৃষ্ঠার archived দুই
command-এর সঙ্গে স্বয়ংক্রিয়ভাবে identical নয়।

দ্রুত diagnostic-এর জন্য ব্যবহার করুন:

```bash
ternux benchmark
ternux benchmark --json
```

Published Redmi Turbo 4 Pro evidence reproduce বা compare করার সময় ওপরের exact
raw command ব্যবহার করুন।

---

## বর্তমান evidence matrix

### বিদ্যমান LAI model path তুলনা (Qwen2.5 1.5B Q4_0)

`/sdcard/LAI/models/qwen2.5-1.5b-instruct-q4-0.gguf` সরাসরি ব্যবহার করেছি;
model copy, move বা convert করা হয়নি। একই packaged llama.cpp b11582 artifact,
prompt (`What is 2 + 2? Reply with only the number.`), greedy sampling, seed 0
এবং ৮-token limit দিয়ে:

| Path | ফল | Evidence |
|---|---|---|
| CPU (`-ngl 0`) | **Known-answer pass**: `4.000000`; prompt 121.4 tok/s, generation 21.8 tok/s | `/home/sbj/npu-probe-2026-10-13/htp-qwen15-cpu-baseline.log` |
| Hexagon HTP (`-ngl 99`, brokered CDSP) | **Known-answer fail**: ` LENG, the, the,`; প্রথম ৮-token run-এ generation 24.3 tok/s। Verbose repeat-এ ` LENG, the,` এবং `MUL_MAT`, `FLASH_ATTN_EXT`, `SWIGLU`-সহ HTP profile record ছিল। | একই scratch directory-র `htp-qwen15-htp-test.log` ও `htp-qwen15-htp-verbose-test.log` |
| Vulkan GPU | আলাদা local Vulkan-enabled build-এ **known-answer pass**: `4.000000`; verbose trace-এ ২৯/২৯ model layer Vulkan0 (Adreno 825)-তে assign হয়েছে। | `/home/sbj/npu-probe-2026-10-13/`-এর `llama-vulkan-qwen15-gpu.log` ও `llama-vulkan-package-gpu-test.log` |

HTP broker session ও child process cleanly exit করেছে; verbose per-op record এই
model-এর বাস্তব HTP কাজ নিশ্চিত করে। তবুও HTP known-answer check **fail**। CPU ও
HTP token rate ছোট diagnostic run, generation length-ও আলাদা—তাই controlled
performance comparison নয়। Sustained thermal/power মাপা হয়নি। বিদ্যমান
`/sdcard/Llms/AbsoluteReality_qnn2.28_8gen2.zip`-এ CLIP, VAE ও UNet-সহ Stable
Diffusion QNN image-generation package আছে; এটি GGUF vision model নয়। শুধু ZIP
entry list দেখা হয়েছে; extract বা run করা হয়নি।

এই model-path তুলনা পরের low-level diagnostic বদলায় না: Q4_0 kernel-এর numeric
mismatch বোঝার জন্য exact HTP Q8_0 activation quantizer reproduce করতে হবে।
Vulkan path এখন known-answer inference test pass করেছে; diagnosis ও পরবর্তী
known-answer pass না হওয়া পর্যন্ত HTP path fail অবস্থায় আছে।

### Stable Diffusion মূল্যায়ন (deferred: compatible model/backend pair নেই)

বিদ্যমান `/sdcard/Llms/AbsoluteReality_qnn2.28_8gen2.zip` হলো QNN Android
image-generation package, upstream `stable-diffusion.cpp` model bundle নয়। এর
archive entry আগে তালিকাভুক্ত করা হয়েছে, কিন্তু extract বা run করা হয়নি।
Official upstream `stable-diffusion.cpp` CMake option-এ Vulkan ও OpenCL backend
আছে, QNN বা Hexagon HTP নেই; upstream build guide-এ model file ও backend build
নির্দেশনা আছে। তাই বর্তমান QNN package দিয়ে ওই project-এর মাধ্যমে CPU, Adreno
Vulkan বা HTP validate করা যাচ্ছে না। এটি প্রমাণভিত্তিক compatibility gap, failed
inference test নয়।

ইতিমধ্যে অনুমোদিত scratch/repository path-এ compatible Stable Diffusion
checkpoint বা GGUF পাওয়া যায়নি, তাই SD build বা model download শুরু করিনি।
compatible model আগে থেকে থাকলে CPU/GPU test করা যাবে; HTP test-এর জন্য verified
QNN/HTP execution path-ও লাগবে। Known-input/output image test ও actual backend log
না হওয়া পর্যন্ত SD-কে accelerator pass matrix-এ ধরা হবে না।

তথ্যসূত্র: [stable-diffusion.cpp build guide](https://github.com/leejet/stable-diffusion.cpp/blob/master/docs/build.md),
[upstream CMake backend option](https://github.com/leejet/stable-diffusion.cpp/blob/master/CMakeLists.txt)।

### Standalone QNN runtime discovery

পরের [standalone QNN discovery experiment](../../experiments/qnn-native/README.md)-এ
PRoot-launched Android/Bionic helper existing HTP ও System library load করেছে;
HTP backend create/free-তে status 0 এসেছে। Runtime হলো
`v2.29.0.241129103708_105762` (core API 2.22.0, backend API 5.29.0)। এটি runtime
initialization evidence; QNN image model এখনো unverified।
[Completion plan](ACCELERATOR-RELEASE-PLAN.md)-এ owner-এর order আছে: standalone
QNN image route, মূল Ternux NPU correctness, qualification ও release।

### Vulkan llama.cpp model test (local Debian PRoot build)

Vulkan-enabled build-টি pinned llama.cpp source commit
`af50f2f248b475d9760f8e67503d01c0f194f5f4` (tag `b11582`) থেকে Redmi Turbo Pro-এর
Debian ARM64 PRoot-এ compile করা হয়েছে। GNU C++ 14.2.0 এবং
`GGML_NATIVE=ON`, `GGML_VULKAN=ON`, `GGML_HEXAGON=OFF`, `GGML_OPENCL=OFF`
configuration ব্যবহার হয়েছে। Vulkan development dependency scratch workspace-এ
unpack করা হয়েছিল; system package install করা হয়নি। Build artifact local
scratch-এ আছে, release asset হিসেবে প্রকাশিত হয়নি।

আগের model file-টিই সরাসরি ব্যবহার হয়েছে:
`/sdcard/LAI/models/qwen2.5-1.5b-instruct-q4-0.gguf` (SHA-256
`dcd819ff094852c38faba6873d8ff0c9d51eadb2844539e52042ae5d647bbfdb`)। Prompt ছিল
`What is 2 + 2? Reply with only the number.`; seed 0, temperature 0, top-k 1,
এবং সর্বোচ্চ ৮ token। `llama-cli -dev Vulkan0 -ngl 99` ফল দিয়েছে `4.000000`;
verbose output-এ `Vulkan0 (Adreno (TM) 825)` এবং ২৯/২৯ layer offload দেখা গেছে।
এটি এই model ও prompt-এ Vulkan inference কাজ করার প্রমাণ; সব model-এর
compatibility প্রমাণ নয়।

তিনটি `llama-bench` repetition (`pp16/tg16`, warm-up ছাড়া, ৮ thread) এই ফল
দিয়েছে:

| Backend | Prompt processing (`pp16`) | Token generation (`tg16`) |
|---|---:|---:|
| CPU (`-ngl 0`) | 25.38 ± 2.88 tok/s | 2.93 ± 0.35 tok/s |
| Vulkan (`-dev Vulkan0 -ngl 99`) | 42.18 ± 5.91 tok/s | 20.92 ± 0.50 tok/s |

এই সংক্ষিপ্ত run-এ এই model/configuration-এ Vulkan-এ বেশি measured throughput
দেখা গেছে। এটি দীর্ঘ সময়, একাধিক device বা thermal comparison নয়; CPU
thread-scaling run-এ যথেষ্ট variation ছিল। Sustained thermal, power draw ও বড়
workload এখনো মাপা হয়নি। Log: `/home/sbj/npu-probe-2026-10-13/`-এর
`llama-vulkan-qwen15-gpu.log`, `llama-vulkan-qwen15-gpu-repeat3.md`,
`llama-vulkan-qwen15-cpu-repeat3.md`, `llama-vulkan-qwen15-gpu-bench.md`,
`llama-vulkan-qwen15-cpu-bench.md`, ও `llama-vulkan-qwen15-cpu-scaling.md`।

| প্রশ্ন | Status |
|---|---|
| glmark2 কি Zink/Adreno/Turnip নাম দেখায়? | **হ্যাঁ — observed** |
| Windowed OpenGL FPS কি captured? | **হ্যাঁ — measured** |
| ES command/output কি DRI3 warning-সহ captured? | **হ্যাঁ — measured, caveat-সহ** |
| Blender কি একই OpenGL renderer দেখে? | **হ্যাঁ — observed** |
| Blender Cycles GPU rendering কি প্রমাণিত? | **না** |
| llama.cpp Vulkan compile ও device execution কি verified? | **হ্যাঁ — Adreno 825** |
| llama.cpp Vulkan inference known-answer test কি হয়েছে? | **হ্যাঁ — pass, একটি model/prompt** |
| llama.cpp Vulkan/CPU tokens/s কি measured? | **হ্যাঁ — ৩ repetition, একটি সংক্ষিপ্ত workload** |
| stable-diffusion.cpp Vulkan build কি reported? | **হ্যাঁ — observed** |
| Diffusion seconds/image কি measured? | **না** |
| Sustained thermal/power কি measured? | **না** |
| একই device-এ VirGL বনাম Zink কি measured? | **না** |

---

## রেফারেন্স

- [glmark2](https://github.com/glmark2/glmark2)
- [Mesa Zink](https://docs.mesa3d.org/drivers/zink.html)
- [Blender 4.3 GPU rendering](https://docs.blender.org/manual/en/4.3/render/cycles/gpu_rendering.html)
- [llama.cpp Vulkan build](https://github.com/ggml-org/llama.cpp/blob/master/docs/build.md#vulkan)
- [stable-diffusion.cpp Vulkan build](https://github.com/leejet/stable-diffusion.cpp/blob/master/docs/build.md#build-with-vulkan)

## 2026-10-13 standalone Android QNN VAE graph qualification

The pinned Android NDK CI helper from [run 38406862573](https://github.com/soobujmiah/ternux/actions/runs/38406862573) was downloaded to isolated scratch after the owner's explicit authorization. Checksums, AArch64 ELF, Android dependencies (`libc.so`, `libdl.so`) and absent RUNPATH were checked. On Redmi Turbo 4 Pro / SM8735 / Android 16, it streamed the existing ZIP members from `/sdcard/Llms/` into sealed anonymous memfds; no model copy was written. The licensed Qualcomm QNN 2.29 V73 stub/skel stayed in scratch and is not a release asset.

QNN System read the QNN 2.28 encoder and decoder metadata. Encoder input: `input` [1,3,512,512]; outputs: `mean`, `std` [1,4,64,64]. Decoder input: `input` [1,4,64,64]; output: `output` [1,3,512,512]. All have datatype 1046 (UFIXED_POINT_16). For both contexts, HTP backend/device/context create, CDSP graph retrieve and cleanup returned status 0. Encoder and decoder SHA-256 were `c7bd0cf7cce2cda7b073379bef97f58f5c0ea850d8e3d86933a5939f80570faa` and `42edf1474eea665f593b8c35daf64169da220b6e4095c860eaca494610579ccc` respectively.

A fixed raw-zero encoder input was executed twice on the QNN HTP/CDSP path. Both execute calls returned status 0, outputs changed from sentinel bytes and repeated exactly. FNV64 output hashes: `ae97b25a95bdac33` (`mean`), `7fb11db45bb92b10` (`std`). This verifies **graph execution and repeatability for that input**, but there is **no independent expected tensor**; numerical correctness and image generation remain unverified. Decoder execution and UNet/CLIP were not attempted. Earlier missing-stub status 14001 and direct HTP `dlclose` crash remain recorded in [the experiment](../../experiments/qnn-native/README.md) and SKB evidence. The short-lived helper retains the HTP library until process exit after explicit QNN handle cleanup.

---

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · Apache-2.0*
