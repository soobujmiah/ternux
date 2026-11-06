# পরীক্ষামূলক llama.cpp Hexagon HTP extension

এই guide-এ Ternux-এর ঐচ্ছিক `llama-htp-experimental` extension-এর কথা আছে।
এতে Linux ARM64 llama.cpp build-এর সঙ্গে Ternux Binder/FastRPC broker ও
launcher আছে। এটি Qualcomm SM8735 / Hexagon V73-এর জন্য device-specific
experiment; supported বা production-ready Ternux feature নয়।

## বর্তমান evidence ও সীমা

SM8735-এ known-answer-safe configuration-এ HVX-only matmul
(`GGML_HEXAGON_MM_SELECT=1`) এবং flash attention বন্ধ ছিল। এই device-এ ছোট
CPU/HTP তুলনা এবং 2,955-token prompt / 511-token generation প্রত্যাশিত recall
key ফিরিয়েছে; clean-idle তুলনায় HTP Vulkan-এর চেয়ে ধীর ছিল। আগের default
attention selection-এ HMX-selected matmul এবং flash attention চালু—দুটিই আলাদা
test-এ ভুল answer দিয়েছে। Explicit HVX attention selection operator failure কমায়,
কিন্তু সাতটি numerical error আবার reproduce হয়েছে; কোনোটিই এই package-এ qualify নয়।

বর্তমান launcher HTP0, সব eligible layer এবং পর্যবেক্ষিত
HVX/flash-attention-off setting জোর করে ব্যবহার করে। Broker
SIGINT/SIGTERM/SIGHUP আলাদা inference process group-এ পাঠায়; bounded wait-এর
পর TERM/KILL দেয় এবং CDSP `closeSession` result জানায়। Source-level device
check-এ ফল `4` এসেছে; broker-এ SIGINT দিলে child বন্ধ হয়েছে, broker exit 130
এবং `closeSession [0, 0]` হয়েছে। এই check আগের b11582 binary ও local shim দিয়ে
হয়েছে। Workflow run `38560288558`-এর exact archive isolated home-এ install
করে test করা হয়েছে: answer `4`, 31/31 layer HTP0-তে, child exit 0 এবং
`closeSession [0, 0]`। একই package-এ bounded SIGINT দিলে child বন্ধ, broker exit
130 এবং clean session close হয়েছে। Follow-up build `38562008524` শুধু package
README/manifest dependency metadata ঠিক করছে; runtime payload hash comparison
bাকি। Restart, অন্য model/SoC, optimized HTP configuration ও sustained operation
এখনো qualify করা হয়নি। Automatic CPU/Vulkan fallback নেই; HTP command ব্যর্থ
হলে error return করে।

বর্তমান gate ও dated device evidence একক
[accelerator release plan](../../docs/ACCELERATOR-RELEASE-PLAN.md) এবং
[device benchmark record](device-benchmark-evidence.md)-এ আছে।

২০২৬-১১-০৬-এর exploratory speculative-decoding test-এ Qwen2.5 1.5B Q4_0 main
model HTP0-তে এবং Qwen2.5 0.5B Q4_0 draft model Vulkan0-তে চালানো হয়েছে। একই
short prompt-এ baseline 19.5 generated tok/s; draft window 2 ও 4-এ যথাক্রমে
9.1 ও 7.1 tok/s পাওয়া গেছে। দুই broker session-ই clean close হয়েছে। Mixed
backend setup ধীর ছিল, তাই launcher-এ যোগ করা হয়নি এবং optimization হিসেবেও
দেখানো যাবে না। এই একবারের ছোট run sustained performance প্রমাণ করে না।

২০২৬-১১-০৭-এর আরেকটি ছোট probe-এ Qwen2.5 1.5B Q4_0 model, একই prompt, seed,
context ও 64-token cap দিয়ে b11582 CPU/Vulkan ও HTP build পরীক্ষা হয়েছে। HTP-তে
default power mode 19.6 tok/s, `GGML_HEXAGON_POWER_MODE=burst`-এ 19.0 tok/s এবং
Vulkan-এ 17.6 tok/s মাপা হয়েছে। HTP Q4_K_M model 15.9 tok/s দিয়েছে। HTP session
গুলো clean close হয়েছে। প্রতিটি ফল একবারের ছোট run; এটি বড় বা repeatable NPU
speed advantage কিংবা sustained performance প্রমাণ করে না।

Official llama.cpp `b12177` Snapdragon Linux ARM64 asset-ও isolated temporary
directory-তে পরীক্ষা করেছি (commit `6c01da6`, SHA-256
`b3d2503821a6688ec5c500d43b7e57d96fad893a206bbefe208b07ee647d85e7`)। বর্তমান
Ternux broker দিয়ে চালালে inference শুরুর আগেই HTP session start error
`0x8000040e` এসেছে; broker-এর `closeSession` তবুও `[0, 0]` ফিরিয়েছে। Speed
result নেই; installed b11582 extension অপরিবর্তিত আছে।

`/sdcard/Llms/qwen2.5-0.5b-instruct-q4_0.gguf`-কেও direct HTP model হিসেবে
পরীক্ষা করেছি। Qwen2.5 0.5B Instruct Q4_0 এক short known-answer prompt-এ `4`
দিয়েছে; verbose trace-এ 24/24 transformer layer HTP0-তে এবং HTP compute buffer
দেখা গেছে। আগের তিন-run HTP/Vulkan তুলনায় median ছিল যথাক্রমে 40.8 ও 27.9 tok/s।
পরের matched CPU/Vulkan/HTP comparison-এ একই prompt, 64-token output limit,
context 2048, batch/ubatch 128, seed 42, temperature 0 এবং চার thread ব্যবহার
করে প্রতি backend-এ তিনটি interleaved run নেওয়া হয়েছে। Generation rate: CPU
7.2/8.0/8.1 tok/s (median 8.0), Vulkan 24.1/24.8/26.3 (median 24.8), HTP
46.9/46.2/43.9 (median 46.2)। HTP-র সব broker session clean close হয়েছে। এটি
এক device-এর short throughput result; response quality, energy use, thermal
stability বা sustained performance যাচাই করে না এবং HTP correctness-এর খোলা gate
বন্ধ করে না।

## সর্বশেষ operator check

২০২৬-১০-১৪-এ workflow run `38567329752`-এর Linux ARM64 package
(SHA-256 `7eb99a5532c2741fce2b84c757b9182bd69c891d907513c67f51e0c51e4c2211`)
দিয়ে Redmi Turbo 4 Pro / SM8735-এ operator check হয়েছে। Broker CDSP
descriptor পেয়েছে এবং দুই run-ই clean session close করেছে। Local Debian runtime-এ
আগে থেকে extracted `libgbinder`, `libglibutil` ও FastRPC file ব্যবহার হয়েছে;
আলাদা scratch symlink দিয়ে `libcdsprpc.so` unversioned নাম দেওয়া হয়েছে—সাধারণত
এটি `libfastrpc-dev` package দেয়। কোনো package install বা Ternux runtime
configuration পরিবর্তন হয়নি।

Default HMX matmul selection-এ `test-backend-ops -b HTP0 -o MUL_MAT` চালিয়ে ৫২৯টি
failing case পাওয়া গেছে। সব numerical error `inf`; backend result **FAIL**। HTP
hardware তথ্য v73, HMX উপস্থিত, 8 MB VTCM। পরে `GGML_HEXAGON_MM_SELECT=1` দিয়ে
HVX-only suite চালিয়ে **1,389/1,389 HTP `MUL_MAT` test pass** হয়েছে। CPU backend
skip হয়েছে; HTP backend OK এবং broker clean `closeSession [0, 0]` দিয়েছে। এটি
শুধু এই operator suite-এর ফল, সব HTP operator নয়।

এতে SM8735-এ HMX `MUL_MAT` correctness সমস্যা নিশ্চিত হয়, কিন্তু কারণ নিশ্চিত
হয় না। Upstream-এ অন্য SM7750 v73 device-এর HMX FP16 support না থাকার সঙ্গে একই
ধরনের failure report আছে; আরেক SM8650 v75 report-এ flash-attention queue race
আছে। এগুলো অন্য device-এর diagnostic lead, SM8735-এর confirmed root cause নয়:
[SM7750 HMX report](https://github.com/ggml-org/llama.cpp/issues/29473),
[SM8650 flash-attention report](https://github.com/ggml-org/llama.cpp/issues/26759)।
SM8735-এর HMX FP16 capability ও অন্য HVX operator coverage আলাদাভাবে যাচাই
বাকি। প্রথম `FLASH_ATTN_EXT` run-এ `GGML_HEXAGON_MM_SELECT=1` দিয়ে HVX matmul
নির্বাচিত হলেও attention selection default-এ ছিল; ১২০ সেকেন্ডে timeout-এর আগে
৪,৬৬০ output line-এ ১,৮৪৮টি `inf` numerical error ও ১১২ pass ছিল, তাই run অসম্পূর্ণ।
পরের run-এ `GGML_HEXAGON_MM_SELECT=1 GGML_HEXAGON_FA_SELECT=1` দিয়ে matmul ও
attention দুটোই HVX বেছে suite সম্পন্ন হয়: ৫,৩৩২ unique case-এর ২,৫৯৩ pass,
২,৭৩২ unsupported, ৭টি tolerance-এর বেশি finite numerical error-সহ fail। Filtered
rerun-এ সাতটি failed parameter case-ই reproduce হয়েছে। Test failure-এর কারণে
exit 1; broker CDSP session cleanly close করেছে। আগের error pattern অনেক কমেছে,
তবু flash attention qualify হয়নি; HTP launcher এটি বন্ধ রাখে। Raw log আছে
`/home/sbj/npu-probe-2026-10-13/htp-op-qualification-38567329752/`-এ।

Reduced queue setting (`GGML_HEXAGON_OPBATCH=128`,
`GGML_HEXAGON_OPQUEUE=2`) দিয়ে broad HVX-selected
`test-backend-ops -b HTP0` run-এ abort-এর আগে 3,520টি passing case line,
`DIV`, `GET_ROWS`, `SWIGLU_CLAMP`, `ADD` ও `SUB`-এ ৪৫টি numerical-error failure,
এবং ৪,৮৭৪টি unsupported case log হয়েছে। পরে
`dspqueue_read failed: 0x0000002e`-এ child abort করেছে (exit -6); broker CDSP
session cleanly close করেছে। এটি অসম্পূর্ণ, broad suite pass নয়। আলাদা
`MUL_MAT_W4A4` check 1/1 pass; all-operator abort-এর কারণ এখনও অজানা।

## প্রয়োজনীয়তা

- Ternux Debian ARM64 glibc guest; glibc 2.38 বা নতুন।
- Qualcomm SM8735 এবং বর্তমান Termux/PRoot process-এর জন্য vendor DSP service
  উপলভ্য থাকতে হবে। অন্য device qualify করা হয়নি।
- Debian package `libgbinder1`, `libglibutil1`, `libfastrpc1` ও
  `libfastrpc-dev`। llama.cpp-এর dynamic loader `libcdsprpc.so` নামটি খোঁজে;
  `libfastrpc1` একা শুধু versioned runtime নাম ইনস্টল করে, unversioned linker
  নামটি `libfastrpc-dev` দেয়।
- Debian guest থেকে পড়া যায় এমন path-এ GGUF model। Extension model weight
  download, copy বা bundle করে না।

Ternux interactive installer-এ HTP বেছে নিলে extension install-এর আগে Debian
Trixie Backports-এর `main` ও `contrib` সক্রিয় করে runtime package-গুলো বসায়।
পরে হাতে `ternux extension install` চালালে আগে Debian guest-এ package বসান:

```bash
sudo apt install libgbinder1 libglibutil1 libfastrpc1 libfastrpc-dev
```

Debian 13-এ `libgbinder1` ও `libglibutil1` Trixie Backports-এ, আর `libfastrpc1`
ও `libfastrpc-dev`-এর জন্য `contrib` component দরকার। apt package না পেলে official
`trixie-backports` source-এ `main` এবং `contrib` সক্রিয় করে package index update
করুন, তারপর install আবার চালান। Debian package record:
[`libgbinder1`](https://packages.debian.org/trixie-backports/arm64/libs/libgbinder1),
[`libglibutil1`](https://packages.debian.org/trixie-backports/arm64/libs/libglibutil1),
[`libfastrpc1`](https://packages.debian.org/trixie-backports/arm64/contrib/libfastrpc1),
এবং [`libfastrpc-dev`](https://packages.debian.org/trixie-backports/arm64/libdevel/libfastrpc-dev)।

Launcher `/dev/fastrpc-cdsp` permission বদলায় না এবং Qualcomm vendor library
বা firmware bundle করে না।

## Install ও চালান

Termux থেকে Ternux CLI-তে experimental package install করুন:

```bash
ternux extension list
ternux extension install llama-htp-experimental
```

Runtime library না থাকলে installer যে package-এর নাম দেখায়, সেগুলো Debian
guest-এ install করে command আবার চালান। Installer release checksum, archive path,
package manifest, launcher ও broker file যাচাই করে; আগে থেকে থাকা extension
directory overwrite না করে atomic install করে।

Debian-এ নিজের বর্তমান model path দিয়ে launcher চালান:

```bash
"$HOME/.local/opt/ternux-extensions/llama-htp-experimental/bin/htp-run" \
  -m /path/to/model.gguf \
  -p 'What is 2 + 2? Reply with only the number.' -n 8
```

### ছোট model-এ দ্রুত চালানোর উদাহরণ

পরীক্ষিত SM8735 ফোনে থাকা Qwen2.5 0.5B Instruct Q4_0 file
`/sdcard/Llms/qwen2.5-0.5b-instruct-q4_0.gguf` HTP0-তে 24/24 transformer layer
assign করে `4` দিয়েছে। Shared storage থেকেই সরাসরি চালাতে:

```bash
"$HOME/.local/opt/ternux-extensions/llama-htp-experimental/bin/htp-run" \
  -m /sdcard/Llms/qwen2.5-0.5b-instruct-q4_0.gguf \
  -p 'What is 2 + 2? Reply with only the number.' -n 8
```

পরের matched তিন-backend test-এ ছোট model-এর HTP median ছিল 46.2 tok/s, Vulkan
24.8 tok/s এবং চার-thread CPU 8.0 tok/s। এক device-এ প্রতি backend-এ তিনটি short
run হয়েছে; response quality, energy, thermal stability বা sustained use যাচাই
করা হয়নি। বড় model-এ একই ফল ধরে নেবেন না।

Launcher observed HVX-only / flash-attention-off configuration ব্যবহার করে এবং
eligible model layer HTP-তে পাঠাতে চায়। Output ও exit code যাচাই করুন; শুধু
model load বা HTP operator profile দেখেই inference সঠিক বলা যাবে না। Model-কে
তার বর্তমান path-এই রাখুন। CPU বা Vulkan আলাদা করে চালাতে `llama-vulkan` install
করে [CPU/Vulkan extension guide](llama-vulkan-extension.md) অনুসরণ করুন।

## Remove

আগে নির্দিষ্ট installation-এর content inspect করুন। শুধু এই extension সরাতে
চাইলে inference process বন্ধ করে Debian guest-এ এই directory সরান:

```text
$HOME/.local/opt/ternux-extensions/llama-htp-experimental
```

এতে model, system package বা অন্য extension সরবে না।
