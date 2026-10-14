# পরীক্ষামূলক llama.cpp Hexagon HTP extension

এই guide-এ Ternux-এর ঐচ্ছিক `llama-htp-experimental` extension-এর কথা আছে।
এতে Linux ARM64 llama.cpp build-এর সঙ্গে Ternux Binder/FastRPC broker ও
launcher আছে। এটি Qualcomm SM8735 / Hexagon V73-এর জন্য device-specific
experiment; supported বা production-ready Ternux feature নয়।

## বর্তমান evidence ও সীমা

SM8735-এ known-answer-safe configuration-এ HVX-only matmul
(`GGML_HEXAGON_MM_SELECT=1`) এবং flash attention বন্ধ ছিল। এই device-এ ছোট
CPU/HTP তুলনা এবং 2,955-token prompt / 511-token generation প্রত্যাশিত recall
key ফিরিয়েছে; clean-idle তুলনায় HTP Vulkan-এর চেয়ে ধীর ছিল। আলাদা test-এ
HMX-selected matmul এবং flash attention চালু—দুটিই ভুল answer দিয়েছে। এই
package-এ ওই failure ঠিক করা হয়নি।

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
hardware তথ্য v73, HMX উপস্থিত, 8 MB VTCM। একই operator suite-এ
`GGML_HEXAGON_MM_SELECT=1` (HVX-only matmul) দিলে ১৮০ সেকেন্ড limit-এ ২,৩৮৯টি
case output-এর পর থামানো হয়েছে। ওই অসম্পূর্ণ output-এ numerical failure দেখা
যায়নি, তবে suite শেষ হয়নি—এটি pass নয়। দুই run-এ `closeSession [0, 0]` হয়েছে।

এতে SM8735-এ HMX `MUL_MAT` correctness সমস্যা নিশ্চিত হয়, কিন্তু কারণ নিশ্চিত
হয় না। Upstream-এ অন্য SM7750 v73 device-এর HMX FP16 support না থাকার সঙ্গে একই
ধরনের failure report আছে; আরেক SM8650 v75 report-এ flash-attention queue race
আছে। এগুলো অন্য device-এর diagnostic lead, SM8735-এর confirmed root cause নয়:
[SM7750 HMX report](https://github.com/ggml-org/llama.cpp/issues/29473),
[SM8650 flash-attention report](https://github.com/ggml-org/llama.cpp/issues/26759)।
SM8735-এর HMX FP16 capability ও সম্পূর্ণ HVX operator coverage আলাদাভাবে যাচাই
বাকি। `GGML_HEXAGON_MM_SELECT=1` দিয়ে `FLASH_ATTN_EXT` run ১২০ সেকেন্ডের সীমায়
থেমেছে; ৪,৬৬০ output line-এর মধ্যে ১,৮৪৮টি infinite numerical-error case এবং
১১২টি pass ছিল (exit 124)। Suite অসম্পূর্ণ, pass নয়; child থামানো হয়েছে এবং
broker CDSP session cleanly close করেছে। তাই flash-attention operator correctness
এখনও unqualified। HTP launcher এখনও HVX matmul বেছে নিয়ে flash attention বন্ধ
রাখে।

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

Debian guest-এ runtime package install করুন:

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
