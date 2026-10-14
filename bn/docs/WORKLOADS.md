---
title: "ওয়ার্কলোড — প্রতিটি অপশন কী বসায়, স্বয়ংক্রিয়ভাবে বা নিজের হাতে"
description: "অপ্ট-ইন ওয়ার্কলোডগুলো, প্রতিটিতে ঠিক কোন package বসে, এক-কমান্ড পথ ও তার manual সমতুল্য, এবং resume ও failure কীভাবে সামলানো হয়।"
lang: "bn"
alt_url: "/docs/WORKLOADS.html"
---

একটি ternux install মানে একটি desktop, আর তার সঙ্গে আপনি যা যা চান। এই পৃষ্ঠার
কোনো কিছুই না চাইলে বসে না, আর প্রতিটি অপশন একটি *workload*: নাম দেওয়া একটি
package সেট, যা guest-এ বসে এবং state-এ লিপিবদ্ধ হয় — যাতে `--resume` ও
`ternux repair` জানে কী কী ছিল।

প্রতিটি workload দুইভাবে বসানো যায়, আর দুটোই সমান বৈধ। এক-কমান্ড পথ হলো
installer-এর একটি flag। Manual পথ হলো একই command আপনি নিজে guest-এর ভেতরে
চালাচ্ছেন — যাতে চালানোর আগে পড়ে নিতে পারেন, এবং ব্যর্থ একটি install গোড়া থেকে
শুরু না করে হাতে শেষ করতে পারেন।

Interactive install-এ workload সংখ্যা দিয়ে বাছুন (`1` development, `2` local AI,
`3` network, `4` media, `5` Blender; একাধিক হলে comma দিন)। `6` সবগুলো,
Enter/`0` শুধু base desktop। Detected graphics route দেখে installer পরামর্শ দেয়
এবং RAM/storage সীমা জানায়। `--yes` এবং non-interactive run-এ flag না থাকলে
base profile-ই থাকে।

<h2 id="the-workloads">ওয়ার্কলোডগুলো</h2>

| Workload | Flag | কী বসায় |
|---|---|---|
| ডেভেলপমেন্ট | `--with-dev` | git, curl, wget, Node.js, npm, pip ও venv সহ Python 3, build-essential, ca-certificates |
| লোকাল AI | `--with-llm` | Vulkan ও shader toolchain, তারপর `GGML_VULKAN=ON` দিয়ে llama.cpp **source থেকে build** |
| নেটওয়ার্ক | `--with-network` | nmap, tmux |
| মিডিয়া | `--with-media` | ffmpeg, GIMP, Audacity, ImageMagick |
| Blender | `--with-blender` | headless EEVEE render-এর জন্য Blender ও Xvfb (Blender প্রায় ৯৫ MB, `--no-install-recommends` সহ) |
| সবকিছু | `--all` | পাঁচটিই |

বেস desktop — Xfce4, terminal, VLC, archive tool, Mesa utility, Vulkan tool —
সবসময় বসে এবং সেটি কোনো workload নয়।

<h2 id="automatic">স্বয়ংক্রিয়</h2>

```bash
bash install.sh --with-dev --with-llm --with-blender
bash install.sh --all
```

Flag একসঙ্গে দেওয়া যায়, আর সেটটি লিপিবদ্ধ হয়। পরে `bash install.sh --resume`
একই সেট ফিরিয়ে আনে, command line-এ আবার লিখতে হয় না; আর `ternux repair` যা
লিপিবদ্ধ ছিল তাই মেরামত করে, অনুমান করে না।

<h2 id="manual">নিজের হাতে</h2>

এগুলো guest-এর ভেতরে Debian user হিসেবে চালান — Xfce terminal থেকে, অথবা Termux
থেকে `proot-distro login debian --user <আপনি>`। ঠিক এই কাজের জন্যই ternux `db`
alias বসায়। প্রতিটি block installer যা চালায় তাই, তাই ফলাফল দুইভাবেই এক।

প্রথমে, প্রতি session-এ একবার:

```bash
sudo apt update
export DEBIAN_FRONTEND=noninteractive
```

**ডেভেলপমেন্ট**

```bash
sudo apt install -y git curl wget nodejs npm python3 python3-pip python3-venv \
  build-essential ca-certificates
```

**নেটওয়ার্ক**

```bash
sudo apt install -y nmap tmux
```

কেবল অনুমোদিত পরীক্ষার জন্য। নিজের নয় এমন network-এ nmap চালাতে ternux আপনাকে
বলছে না।

**মিডিয়া**

```bash
sudo apt install -y ffmpeg gimp audacity imagemagick
```

**Blender**

```bash
sudo apt install -y --no-install-recommends blender xvfb
```

`--no-install-recommends` প্রায় ২৩ MB speech-synthesis package বাদ দেয়, যা
Blender-এর লাগে না। Xvfb পরীক্ষিত headless Zink/Turnip route-এর virtual X11
context দেয়। Render করার আগে পড়ুন
[গ্রাফিক্স স্থায়িত্ব](GRAPHICS-PERSISTENCE.html): নতুন Adreno hardware-এ GPU পথ
Debian-এর চেয়ে নতুন একটি Mesa driver-এর উপর নির্ভর করে, আর একটি package update
সেটি সরিয়ে দিতে পারে।

**লোকাল AI (llama.cpp)**

এটি compile করে। লম্বা build আর সত্যিকারের তাপ আশা করুন; চার্জে রেখে করুন, আর
ফোন এটি দ্রুত শেষ করবে এমন আশা করবেন না।

```bash
sudo apt install -y build-essential cmake git pkg-config libvulkan-dev \
  vulkan-tools clinfo glslang-dev glslang-tools libshaderc-dev glslc
git clone --depth 1 --branch b11582 https://github.com/ggml-org/llama.cpp.git \
  ~/llama.cpp-b11582
cd ~/llama.cpp-b11582
# Installer-er pin-ta verify korun.
test "$(git rev-parse HEAD)" = af50f2f248b475d9760f8e67503d01c0f194f5f4
cmake -S . -B build -DGGML_VULKAN=ON -DGGML_HEXAGON=OFF \
  -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release -j"$(nproc)"
```

`--with-llm` এখনো source-build workload। এটি প্রকাশিত CPU + Vulkan prerelease-এর
extension install থেকে আলাদা। সংক্ষিপ্ত setup-এর জন্য
[দ্রুত শুরু](QUICK-START.html) দেখুন; automatic ও manual release install-এর জন্য
[repository extension guide](https://github.com/soobujmiah/ternux/blob/main/bn/guides/llama-vulkan-extension.md) ব্যবহার করুন।
এই prerelease পরের stable Ternux release-কে qualified করে না; খোলা gate-এর জন্য
[accelerator release plan](ACCELERATOR-RELEASE-PLAN.html) দেখুন।

Model file কোনো workload বসায় না। যেখানে আছে সেখানেই রাখুন এবং llama.cpp-কে সেই
path দেখান; ternux model weight কপিও করে না, ব্যবস্থাপনাও করে না।

<h2 id="backend-selection-applies-to-workloads-too">Backend নির্বাচন workload-এও প্রযোজ্য</h2>

GPU স্পর্শ করে এমন workload — Blender, এবং llama.cpp-র Vulkan build — install যে
graphics route বেছেছে তার উপরেই চলে। Workload-কে দোষ দেওয়ার আগে সেটি দেখুন:

```bash
ternux info            # নির্বাচিত backend, GPU, Vulkan
glxinfo -B             # desktop terminal-এ: আসলে যে renderer চলছে
```

ওই renderer string-এ `llvmpipe` মানে software rendering, আর কিছু ডিভাইসে software
rendering শুধু ধীর চলে না — crash করে। Route-গুলোর জন্য দেখুন
[কনফিগারেশন](CONFIGURATION.html), আর লক্ষণভিত্তিক diagnosis-এর জন্য
[সমস্যা সমাধান](TROUBLESHOOTING.html)।

<h2 id="when-a-workload-fails">কোনো workload ব্যর্থ হলে</h2>

একটি workload-এর ব্যর্থতা পুরো install ব্যর্থ করে না। Phase ব্যর্থতাটি লিপিবদ্ধ
করে, বাকি install চলতে থাকে, আর desktop তবুও ওঠে। এটি ইচ্ছাকৃত: Audacity না বসার
দামে একটি চালু workstation হারানো উচিত নয়।

```bash
ternux logs show                    # আসলে কী ব্যর্থ হলো
bash install.sh --resume            # লিপিবদ্ধ সেটটি আবার চেষ্টা
ternux repair                       # লিপিবদ্ধ install মেরামত
```

একটি workload বারবার ব্যর্থ হলে বাকিগুলো স্বয়ংক্রিয়ভাবে বসান আর ওইটি উপরের block
থেকে হাতে করুন — manual পথ এই কারণেই আছে।

<h2 id="driving-blender-from-an-ai-agent">AI agent থেকে Blender চালানো</h2>

`tools/blender-gpu-mcp/` একটি ছোট MCP server — কেবল Python standard library, আলাদা
কিছু বসাতে হয় না — যা পরীক্ষিত headless পথটিকে তিনটি tool হিসেবে দেয়: `gpu_check`,
`render_script` ও `render_blend`। এটি দরকার, কারণ পথটি সহজেই হারিয়ে যায়: `DISPLAY`
বাদ পড়লে Blender `EGL_BAD_MATCH` দিয়ে থামে, আর `GALLIUM_DRIVER=zink` বাদ পড়লে Mesa
`llvmpipe` বেছে নেয়, যা এই hardware-এ `Illegal instruction` দিয়ে মরে। দুটো ব্যর্থতাই
শূন্য frame লেখে, আর কোনোটিই scene-এর দোষ নয়।

Wrapper-টি দীর্ঘ সময় চালু থাকা Blender-এ addon না বসিয়ে এই পৃষ্ঠার command-টিই ধরে
রাখে, `--factory-startup` সহ: agent যে renderer-এ পৌঁছায় সেটি
[প্রমাণ ও বেঞ্চমার্ক](BENCHMARKS.html)-এ মাপা renderer-ই। Display বন্ধ থাকলেই এটি Xvfb
চালু করে, path অবশ্যই absolute চায়, আর কোনো directory ঘেঁটে দেখে না।

```bash
claude mcp add --scope user blender-gpu -- python3 ~/ternux/tools/blender-gpu-mcp/server.py
```

**মাপা হয়েছে** ২০২৬-১০-১৪, Redmi Turbo 4 Pro-তে: `gpu_check` ফিরিয়ে দিয়েছে
`zink Vulkan 1.4(Adreno (TM) 825 (MESA_TURNIP))`, আর একটি ৩২০×১৮০ EEVEE Next frame
২.৪৯ সেকেন্ডে render হয়েছে। Tool-এর তালিকা ও সীমার জন্য দেখুন
`tools/blender-gpu-mcp/README.md`।

<h2 id="status">অবস্থা</h2>

এই পৃষ্ঠার package সেটগুলো installer থেকেই পড়া, তাই এই সংস্করণের জন্য সেগুলো
সঠিক। যা এখানে **দাবি করা হচ্ছে না**: প্রতিটি workload ডিভাইসে qualify করা হয়েছে।
Sustained run, repeat run ও thermal আচরণ একটি pending release gate, আর আসলে কী
মাপা হয়েছে তা কেবল [প্রমাণ ও বেঞ্চমার্ক](BENCHMARKS.html)-ই বলে।
