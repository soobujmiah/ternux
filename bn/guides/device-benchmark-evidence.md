# Ternux device benchmark evidence — detailed record

> এটি repository-only বিস্তারিত রেকর্ড: graphics ও accelerator evidence, test সীমা, পুনরুৎপাদন ধাপ এবং dated experiment history। প্রকাশিত benchmark page-এ বর্তমান অবস্থার সংক্ষিপ্তসার আছে।

এই পৃষ্ঠায় বাস্তব ternux setup-এ আসলে কী মাপা হয়েছে, কী শুধু দেখা হয়েছে এবং
কী এখনো যাচাই হয়নি—তা রেকর্ড করা হয়েছে। Build success, renderer detection ও
benchmark performance যেন এক claim-এ মিশে না যায়, সেটিই এর উদ্দেশ্য।

> **Snapshot:** 2026-10-14 পর্যন্ত evidence। এটি একটি
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

## পরিমাপ: EEVEE-তে ৬০০ ফ্রেমের ধারাবাহিক render, 2026-10-14

একই 1280x720 Suzanne scene-এ Blender-এর একটি process-এ পরপর ৬০০টি frame render
করেছি। Redmi Turbo 4 Pro-তে Debian PRoot, Blender 4.3.2, EEVEE Next, ১৬টি render
sample, `--gpu-backend opengl` এবং `DISPLAY=:0` ব্যবহার করা হয়েছে। ওই session-এ
`glxinfo -B` দেখিয়েছে `zink Vulkan 1.4(Adreno (TM) 825 (MESA_TURNIP))`; আর
`vulkaninfo --summary` Adreno 825-এ Turnip 26.3.0-devel দেখিয়েছে।

৬০০টি PNG-ই সংরক্ষিত হয়েছে। Blender-এর render/save সময়ের যোগফল 891.6 সেকেন্ড;
প্রতি frame median 1.49 সেকেন্ড, গড়ও 1.49 সেকেন্ড। প্রথম ৩০টির গড় 1.58 সেকেন্ড,
শেষ ৩০টির 1.46 সেকেন্ড—এই ব্যবধানে slowdown দেখা যায়নি। Blender-এর সর্বোচ্চ
memory ছিল 77.59 MiB। Android thermal status 0 ছিল; নমুনায় skin temperature সর্বোচ্চ
44.5 C, battery 41.8 C, আর charge 84% থেকে 80%-এ নেমেছে। এগুলো প্রায় ১৫ মিনিটের
run-এর ফল; multi-hour thermal behavior প্রমাণ করে না। render log ও `.blend` file
local scratch-এ `/home/sbj/npu-probe-2026-10-13/eevee-sustained/`-এ আছে।

Ternux installer এখন upstream Turnip archive pin করে extraction-এর আগে SHA-256
যাচাই করে। তবে device render-এর প্রমাণ এই device-এর graphics stack-নির্ভর; সব Adreno
generation-এর qualification নয়।

---

## পরিমাপ: screen ছাড়াই render করা ৬৪৮ ফ্রেমের animated short, 2026-10-14

এই device-এই একটি সম্পূর্ণ ২৭ সেকেন্ডের animated film বানিয়েছি — চারটি shot, 1280x720
ও ১৬ sample-এ ৬৪৮টি frame, Blender 4.3.2-এর EEVEE Next, প্রতি shot-এ একটি করে Blender
process। scene-টি procedural: character, প্রধান ফুল আর মাঠ — সবই script-এ primitive
থেকে তৈরি, কোনো download করা asset নয়। pipeline আর হুবহু command গুলো আছে
[`experiments/cartoon-pipeline/`](https://github.com/soobujmiah/ternux/tree/main/experiments/cartoon-pipeline)-এ।

এই run-এ **কোনো X server app চালু ছিল না**। `:9`-এ `Xvfb` আর `GALLIUM_DRIVER=zink`
দিয়েই পুরো render হয়েছে, এবং ওই display-এ `glxinfo -B` দেখিয়েছে
`zink Vulkan 1.4(Adreno (TM) 825 (MESA_TURNIP))`।

| Shot | Frame | Blender-এর render সময় | গড় | Wall clock |
|---|---|---|---|---|
| 1 | 144 | 164.5 s | 1.142 s | 209 s |
| 2 | 144 | 160.3 s | 1.113 s | 205 s |
| 3 | 168 | 192.4 s | 1.145 s | 244 s |
| 4 | 192 | 212.4 s | 1.106 s | 270 s |
| **সব** | **648** | **729.6 s** | **1.126 s** | **928 s** |

Wall clock render সময়ের চেয়ে বেশি — পার্থক্যটা process startup, shader compilation
আর PNG লেখার। প্রতিটি shot-এর প্রথম frame-এ লেগেছে 2.95-4.06 সেকেন্ড, অথচ steady
state 1.1 সেকেন্ড; এই shader compilation একটি sequence একবারই দেয়। frame ধরে ধরে
আলাদা process-এ render করলে ওই খরচ ৬৪৮ বার দিতে হতো।

run জুড়ে কোনো slowdown নেই। প্রথম ৩০টি frame-এর গড় 1.186 সেকেন্ড, শেষ ৩০টির 1.149
সেকেন্ড। Blender-এর সর্বোচ্চ memory 86.6 MiB। শেষ 6.3 মিনিটের thermal নমুনা: GPU zone
52.3-63.4 C, `quiet_therm` 47.7-50.0 C, battery 43.5 C থেকে 44.5 C। এটি প্রায় ১৫
মিনিটের ধারাবাহিক run; multi-hour thermal behaviour প্রমাণ করে না।

### পরিমাপ: display পথগুলোর তুলনা

একই scene-এর একই দশটি frame, প্রতিটিতে একটি করে Blender process:

| পথ | প্রতি frame গড় | ফল |
|---|---|---|
| `DISPLAY=:0`, Termux:X11 app চালু | 1.733 s | ১০টি frame |
| `DISPLAY=:9` Xvfb + `GALLIUM_DRIVER=zink` | 1.697 s | ১০টি frame |
| `DISPLAY=:9` Xvfb, Mesa-র নিজের driver পছন্দ | - | **০ frame, `Illegal instruction`** |
| `DISPLAY` একেবারেই না দিলে | - | **০ frame, `EGL_BAD_MATCH`** |

screen ছাড়া চালানোর মাপা খরচ শূন্য, আর দুই কার্যকর পথে render করা একই frame-এ
2,764,800টি channel sample-এর মধ্যে মাত্র ৫টিতে পার্থক্য, সর্বোচ্চ পার্থক্য 3/255 — অর্থাৎ
GPU-র nondeterminism, ভিন্ন renderer নয়। নিয়মের দুটি অংশই অপরিহার্য: virtual display
না থাকলে Blender EGL-এ নেমে কিছুই render করে না, আর driver override না দিলে Mesa
`llvmpipe` বেছে নেয়, যা এই device-এ SIGILL-এ মারা যায় — 2026-10-13-এর software-GL
control-এ যেমনটা হয়েছিল।

```bash
Xvfb :9 -screen 0 1280x720x24 &
DISPLAY=:9 GALLIUM_DRIVER=zink blender -b --factory-startup --python render.py -- --shot 1
```

## পরিমাপ: সংলাপসহ ১,৪৪০ ফ্রেমের একটি কাহিনিচিত্র, 2026-10-14

এই device-এই একটি সম্পূর্ণ ৬০ সেকেন্ডের বাংলা স্বল্পদৈর্ঘ্য বানিয়েছি — পাঁচটি দৃশ্য, বারোটি
shot, ছয়জন সংলাপ ও উপস্থিতির চরিত্র, একটি জনতা, স্থানীয় neural speech model থেকে বাংলা
সংলাপ, সেই সংলাপ দিয়েই চালানো ঠোঁট, আর ছবিতে বসানো বাংলা caption। pipeline আর হুবহু
command গুলো আছে
[`experiments/bengali-short-film/`](https://github.com/soobujmiah/ternux/tree/main/experiments/bengali-short-film)-এ।

1280x720, ১৬টি render sample, EEVEE Next, প্রতি দৃশ্যে একটি করে Blender process,
`Xvfb :9`-এ `GALLIUM_DRIVER=zink` দিয়ে screen ছাড়াই render — কোনো X11 app চালু ছিল না।

| দৃশ্য | Frame | Blender-এর render | গড় | প্রথম frame |
|---|---|---|---|---|
| 1 | 240 | 427.7 s | 1.782 s | 22.6 s |
| 2 | 288 | 501.3 s | 1.741 s | 9.3 s |
| 3 | 312 | 569.9 s | 1.826 s | 8.5 s |
| 4 | 312 | 633.4 s | 2.030 s | 13.0 s |
| 5 | 288 | 666.5 s | 2.314 s | 8.9 s |
| **সব** | **1,440** | **2,798.8 s** | **1.944 s** | |

Blender-এর সর্বোচ্চ memory ছিল 459.1 MB। প্রতিটি দৃশ্যের প্রথম frame ধীর, কারণ shader
compilation প্রতি process-এ একবারই দিতে হয়; গড়টি steady state-এর কথা বলে।

একই ছবির আগের একটি pass-এ **3.22 s/frame ও 713.7 MB** মেপেছিলাম — ২৪ sample, প্রতিটি
শরীরে দুই স্তরের subdivision, আর ছায়া-ফেলা fill light নিয়ে। ১৬ sample, গলার নিচে এক
স্তরের subdivision, sky fill-এ shadow map বাদ, এবং যেসব shot-এ লাগে কেবল সেখানে depth
of field — এতে 1.944 s/frame হয়েছে, অথচ এই shot-আকারে চোখে পড়ার মতো কিছু হারায়নি;
অর্থাৎ frame যা দেখায় না, সেখানেই ৪০% সাশ্রয়।

কণ্ঠ এসেছে Meta-র MMS-TTS Bengali (VITS) থেকে, CPU-তে `onnxruntime` দিয়ে চালানো:
ছয়টি লাইনে মোট 27.5 সেকেন্ড audio, প্রতিটি নিজের দৈর্ঘ্যের প্রায় 1.3 গুণ সময়ে তৈরি। ওই
model **CC-BY-NC-4.0, অর্থাৎ অবাণিজ্যিক**; pipeline-এর বাকি অংশ ওর উপর নির্ভর করে না।

সরবরাহ করা file-টি 60.000 s, 1280x720, 24 fps, ১,৪৪০ frame, H.264 ও 44.1 kHz AAC
stereo। caption আগে থেকে shape করা PNG থেকে বসানো, কারণ Blender-এর text object আর
ffmpeg-এর `drawtext` কোনোটিই বাংলা যুক্তাক্ষর shape করে না।

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

## Measured: llama.cpp CPU + Vulkan package

প্রকাশিত ARM64 CPU + Vulkan prerelease configured SM8735 device-এ install করে
পরীক্ষা করা হয়েছে। CPU ও Adreno Vulkan greedy known-answer prompt-এ `4` দিয়েছে;
verbose output Vulkan0-তে Adreno 825 এবং 29/29 layer assign নিশ্চিত করেছে। আলাদা
bounded clean-idle comparison-এ CPU ও Vulkan prompt/generation throughput মাপা
হয়েছে, তবে এটি `llama-bench` matrix বা সাধারণ performance claim নয়। Package,
ABI ও test-এর বিস্তারিত [repository-only extension guide](https://github.com/soobujmiah/ternux/blob/main/bn/guides/llama-vulkan-extension.md#device-qualification-record)
এবং [বর্তমান release plan](https://github.com/soobujmiah/ternux/blob/main/docs/ACCELERATOR-RELEASE-PLAN.md)-এ
আছে।

---

<a id="experimental-llamacpp-hexagon-htp-artifact-for-sm8735"></a>

## পরীক্ষামূলক: SM8735-এর জন্য llama.cpp Hexagon HTP artifact

আলাদা `llama.cpp Hexagon HTP artifact` workflow upstream llama.cpp tag
`b11582` (commit `af50f2f248b475d9760f8e67503d01c0f194f5f4`) থেকে reusable
Linux aarch64 package বানায়। এতে workflow-এ নথিভুক্ত pinned Snapdragon Linux
toolchain image digest ব্যবহার হয়। Workflow `ternux-llama-htp-sm8735-b11582`
নামে prerelease তৈরি করে। প্রকাশিত 15,519,631-byte aarch64 archive-এর
SHA-256 `dffcf83fa969f3ccfad238217b4ca7f3d47040e5e5b2fa834ebd3f123d144ea5`।

এটি research artifact; `--with-llm`-এর অংশ বা supported installer feature নয়।
প্রথম b11582 default-path known-answer test Redmi Turbo 4 Pro / SM8735-এ fail
করেছিল, যদিও HTP operator load ও session clean close হয়েছিল। 2026-10-14-এর
configuration isolation-এ একটি সীমিত passing route পাওয়া যায়: HVX-only
matmul এবং flash attention বন্ধ রেখে short known-answer prompt ও long
recall-key workload pass করেছে। সব 29 layer HTP0-তে ছিল, তবে matched clean-idle
run-এ Vulkan-এর চেয়ে ধীর ছিল। অন্য দুই isolated configuration fail করেছে:
HMX-selected matmul + flash attention off, এবং HVX matmul + flash attention on।
HTP এখনো experimental, supported নয়; এই evidence সব model/operator qualify
করে না। Package-এ Qualcomm vendor runtime library, firmware বা Android
Binder/FastRPC broker নেই। বর্তমান gate [release plan](https://github.com/soobujmiah/ternux/blob/main/docs/ACCELERATOR-RELEASE-PLAN.md)-এ
আছে।

[Build run](https://github.com/soobujmiah/ternux/actions/runs/38381879734)।
একই packaged `llama-cli`-এর CPU baseline `-ngl 0`-এ সফল হয়েছিল; ওই initial
configuration-এ brokered HTP-তে দুই run-এ একই malformed text আসে। ছোট 135M
Q4_0 test-এ CPU-তে 44.32 generated token/s এবং দ্বিতীয় HTP run-এ 28.63 মাপা
হয়েছিল। এই সংখ্যাগুলো initial failing configuration-এর, পরের Qwen2.5 clean-idle
run-এর সঙ্গে তুলনাযোগ্য নয় এবং সাধারণ performance comparison-ও নয়। Model SHA-256:
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

এটি 2026-10-13-এর default-path failure-এর historical record। পরের
configuration-specific HVX/flash-attention-off known-answer ও long-workload pass
নিচে আছে; বর্তমান gate [release plan](https://github.com/soobujmiah/ternux/blob/main/docs/ACCELERATOR-RELEASE-PLAN.md)-এ
রাখা হয়েছে।

### 2026-10-14 conditional Hexagon known-answer result

Checksum-যাচাইকৃত pinned b11582 artifact-টি SM8735-এ একই Qwen2.5 1.5B Q4_0 model
দিয়ে আবার পরীক্ষা করেছি। আগে থেকে চলা broker তার CDSP descriptor glibc child process-এ
পাঠায়। `GGML_HEXAGON_MM_SELECT=1` (HVX matmul) এবং `-fa off` দিয়ে HTP তিনটি ছোট
run-এ `What is 2 + 2? Reply with only the number.`-এর উত্তরে `4` দিয়েছে। দ্বিতীয়
prompt `The capital of France is` একই চার-token greedy setting-এ CPU ও HTP দুটোতেই
`Paris, and the` দিয়েছে। Verbose HTP log-এ `HTP0`, `q4_0 x f32` `MUL_MAT`,
`hvx-tiled`, অন্যান্য HTP operator এবং HTP compute buffer দেখা গেছে। Broker-সহ child
process 0 status-এ শেষ হয়েছে; `closeSession` সফল হয়েছে। এই নির্দিষ্ট configuration-এ
প্রকৃত HTP কাজ এবং দুটি ছোট correct completion-এর প্রমাণ এটি।

এটি default configuration, অন্য model/quantization, দীর্ঘ generation বা পূর্ণ release
compatibility-এর প্রমাণ নয়।

### 2026-10-14 একই long workload-এ CPU/GPU/NPU তুলনা (Qwen2.5 1.5B Q4_0)

একই greedy workload ক্রমানুসারে CPU, Adreno Vulkan, তারপর Hexagon HTP-তে চালানো হয়েছে।
Model `/sdcard/LAI/models/qwen2.5-1.5b-instruct-q4-0.gguf` থেকে সরাসরি read হয়েছে;
copy বা convert করা হয়নি। প্রতিটি run-এ context 4096, batch/ubatch 128, একবারের
recall key `KITE-8042`-সহ 2,955-token project-ledger prompt, এবং EOS উপেক্ষা করে
সর্বোচ্চ 512-token generation ছিল। তিনটি output-ই সঠিক key দিয়ে শুরু হয়েছে এবং
cap-এ পৌঁছানোর আগে 511 token তৈরি করেছে; প্রতিটি process exit status 0। Vulkan-এ
29/29 model layer Vulkan0-তে এবং HTP-তে `GGML_HEXAGON_MM_SELECT=1`, `-fa off`
সহ 29/29 layer HTP0-তে offload হয়েছে। HTP brokered child exit status 0-তে শেষ
হয়েছে; `closeSession`-এর transport ও reply status-ও 0।

| Backend | Prompt processing | Generation | llama.cpp total | Evidence log |
|---|---:|---:|---:|---|
| CPU | 60.04 tok/s | 2.47 tok/s | 256.41 s | `cpu-qwen15-long-4096ctx-512gen-2026-10-14.log` |
| Adreno 825 Vulkan | 91.61 tok/s | 13.26 tok/s | 71.53 s | `gpu-qwen15-long-4096ctx-512gen-2026-10-14.log` |
| Hexagon HTP | 34.21 tok/s | 12.08 tok/s | 129.22 s | `npu-qwen15-long-4096ctx-512gen-2026-10-14.log` |

এটি HTP-র সর্বোচ্চ throughput নয়। known-answer correctness রাখতে HTP run-এ
`GGML_HEXAGON_MM_SELECT=1` (শুধু HVX matmul; HMX বন্ধ) এবং `-fa off` ব্যবহার করেছি;
আগের default/HMX ও flash-attention control ছোট পরীক্ষায় ভুল উত্তর দিয়েছিল। তাই
HTP-র সংখ্যাটি pass-করা conservative configuration-এর, accelerator-এর optimized
সর্বোচ্চ ক্ষমতার নয়। অন্য SoC-এর উপর [SM7750 / HTP v73 upstream report](https://github.com/ggml-org/llama.cpp/issues/29473)-এ
মিল-ধরনের HMX ও attention correctness failure আছে; সেটি SM8735-এর কারণের প্রমাণ
নয়, শুধু তদন্তের সূত্র। বর্তমান evidence test-করা llama.cpp HTP path-এ correctness
ও performance-এর সীমাবদ্ধতা দেখায়; kernel defect-এর কারণ বা fix এখনও প্রতিষ্ঠিত
হয়নি।

Log-গুলো `/home/sbj/npu-probe-2026-10-13/`-এ। Device battery-তে চলছিল; পর্যবেক্ষণের
সময় thermal status 0 ছিল। CPU run-এর আগে battery প্রায় 37%, GPU-র পরে 36%; skin
temperature প্রায় 43–44.5 C ছিল। test চলার সময় অন্য session-এ চারটি Blender
background shell থাকার কথা জানানো হয়েছিল; সেগুলোর প্রকৃত resource use যাচাই করা
হয়নি। তাই এগুলো long-workload functional run এবং পর্যবেক্ষিত timing, clean controlled
benchmark বা sustained thermal/stability soak নয়। Performance claim-এর আগে device
idle রেখে একই তুলনা আবার চালাতে হবে। HTP-র দীর্ঘ inference প্রমাণ বাড়লেও আগের default
HVX correctness failure, অন্য model-এর compatibility, বা Ternux-এর end-user NPU route
এখনও qualify হয়নি।

### ২০২৬-১০-১৪ idle অবস্থায় CPU/GPU/NPU long inference repeat (Qwen2.5 1.5B Q4_0)

Blender render, encoding, mux ও output validation শেষ হওয়ার পর একই model ও workload
ক্রমে CPU, Adreno Vulkan এবং Hexagon HTP-তে চালানো হয়। Model-টি
`/sdcard/LAI/models/qwen2.5-1.5b-instruct-q4-0.gguf` থেকে সরাসরি read হয়েছে;
copy বা conversion হয়নি। প্রতিটি run-এ 2,955-token prompt, context 4096,
batch/ubatch 128 এবং 512-token cap ছিল। প্রতিটি backend 511 token তৈরি করেছে,
সঠিক প্রথম লাইন `Key: KITE-8042` দিয়েছে এবং exit 0 করেছে। Vulkan-এর 29/29 layer
`Vulkan0`-তে এবং brokered llama.cpp Hexagon backend-এর সব 29 layer `HTP0`-তে ছিল;
`closeSession` status 0।

| Backend | Prompt processing | Generation | Total | Evidence log |
|---|---:|---:|---:|---|
| CPU | 59.04 tok/s | 2.38 tok/s | 264.39 s | `cpu-qwen15-idle-long-2026-10-14.log` |
| Adreno 825 Vulkan | 92.19 tok/s | 13.27 tok/s | 71.30 s | `gpu-qwen15-idle-long-2026-10-14.log` |
| Hexagon HTP | 34.20 tok/s | 12.02 tok/s | 129.46 s | `npu-qwen15-idle-long-2026-10-14.log` |

HTP-তে `GGML_HEXAGON_MM_SELECT=1` (HVX matmul; HMX বন্ধ) এবং known-answer pass
করা `-fa off` configuration ব্যবহার হয়েছে। এই workload-এ HTP CPU-র চেয়ে দ্রুত
শেষ করেছে, কিন্তু Vulkan-এর চেয়ে ধীর; prompt processing ও generation—দুটোতেই
Vulkan এগিয়ে। এটি দীর্ঘ HTP text-inference pass, QNN-এ compile করা text model নয়,
এবং NPU GPU-র চেয়ে দ্রুত—এমন প্রমাণও নয়। `/sdcard/LAI/models/`-এর file-গুলো
GGUF weight; `llama.cpp` এই Qwen-কে HTP-তে চালায়। আলাদা
`/sdcard/Llms/AbsoluteReality_qnn2.28_8gen2.zip` হলো QNN picture model; এর full
prompt-to-image pipeline এখনো যাচাই হয়নি।

তুলনাটি sequential এবং অন্য কাজ বন্ধ থাকা অবস্থায় হয়েছে। Thermal status 0 ছিল;
sequence-এ skin temperature সর্বোচ্চ 44.5 C এবং battery 31% থেকে 28%-এ নেমেছে।
এটি এই device, model ও configuration-এর clean controlled comparison; multi-hour
stability soak বা সব Snapdragon device-এর performance claim নয়। Log
`/home/sbj/npu-probe-2026-10-13/`-এ আছে।

### Stable Diffusion মূল্যায়ন (`stable-diffusion.cpp` inference untested)

`stable-diffusion.cpp`-এর Vulkan-enabled build report শুধু observation। কোনো
compatible model/backend inference run, সম্পন্ন image, বা seconds-per-image
measurement এখানে নেই। Build success থেকে inference support ধরে নেওয়া যাবে না।

আলাদা QNN SD1.5 runner পরে সীমাবদ্ধ ২০-step 512×512 prompt-to-image run
সম্পন্ন করেছে। একই seed-এর output হুবহু repeat হয়েছে (SHA-256
`1a13957f…6764fc3`); visual review-তে coherent landscape ও একটি ছোট cyan
artifact দেখা গেছে। Independent expected stage tensor এখনো যাচাই হয়নি। এটি
আলাদা implementation; `stable-diffusion.cpp`-কে qualify করে না। বিস্তারিত
[QNN experiment](../../experiments/qnn-native/README.md) ও
[release plan](../docs/ACCELERATOR-RELEASE-PLAN.md)-এ আছে।

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
| Blender viewport renderer শনাক্তকরণ | **Observed — Zink/Turnip; render performance নয়** |
| Blender EEVEE render output | **Measured — ৬০০ + ৬৪৮ + ১,৪৪০ frame; আলাদা ১০-frame path comparison** |
| Blender Cycles GPU rendering | **Untested / প্রমাণিত নয়** |
| llama.cpp CPU + Vulkan inference | **Verified — দুই backend-এই known-answer pass** |
| llama.cpp CPU + Vulkan throughput | **Measured — সীমাবদ্ধ repeated short ও long workload; একটি device/model** |
| stable-diffusion.cpp Vulkan build | **শুধু observed — build report, inference run নেই** |
| stable-diffusion.cpp inference / seconds per image | **Untested** |
| Sustained thermal/power কি measured? | **না** |
| একই device-এ VirGL বনাম Zink কি measured? | **না** |

---

## রেফারেন্স

- [glmark2](https://github.com/glmark2/glmark2)
- [Mesa Zink](https://docs.mesa3d.org/drivers/zink.html)
- [Blender 4.3 GPU rendering](https://docs.blender.org/manual/en/4.3/render/cycles/gpu_rendering.html)
- [llama.cpp Vulkan build](https://github.com/ggml-org/llama.cpp/blob/master/docs/build.md#vulkan)
- [stable-diffusion.cpp Vulkan build](https://github.com/leejet/stable-diffusion.cpp/blob/master/docs/build.md#build-with-vulkan)
