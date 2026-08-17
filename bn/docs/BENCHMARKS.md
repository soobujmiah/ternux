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

| প্রশ্ন | Status |
|---|---|
| glmark2 কি Zink/Adreno/Turnip নাম দেখায়? | **হ্যাঁ — observed** |
| Windowed OpenGL FPS কি captured? | **হ্যাঁ — measured** |
| ES command/output কি DRI3 warning-সহ captured? | **হ্যাঁ — measured, caveat-সহ** |
| Blender কি একই OpenGL renderer দেখে? | **হ্যাঁ — observed** |
| Blender Cycles GPU rendering কি প্রমাণিত? | **না** |
| llama.cpp Vulkan compile/use কি reported? | **হ্যাঁ — observed** |
| llama.cpp tokens/s কি measured? | **না** |
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

---

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · MIT*
