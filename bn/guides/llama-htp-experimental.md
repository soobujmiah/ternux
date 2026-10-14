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

বর্তমান launcher পর্যবেক্ষিত HVX/flash-attention-off setting ব্যবহার করে। Broker
SIGINT/SIGTERM/SIGHUP আলাদা inference process group-এ পাঠায়; bounded wait-এর
পর TERM/KILL দেয় এবং CDSP `closeSession` result জানায়। এই packaged launcher-এর
exact-archive device retest এখনো সম্পন্ন হয়নি। Cancellation, restart, automatic
fallback, অন্য model/SoC, optimized HTP configuration এবং sustained operation
এখনো qualify করা হয়নি। Automatic CPU/Vulkan fallback নেই; HTP command ব্যর্থ
হলে error return করে।

বর্তমান gate ও dated device evidence একক
[accelerator release plan](../../docs/ACCELERATOR-RELEASE-PLAN.md) এবং
[device benchmark record](device-benchmark-evidence.md)-এ আছে।

## প্রয়োজনীয়তা

- Ternux Debian ARM64 glibc guest; glibc 2.38 বা নতুন।
- Qualcomm SM8735 এবং বর্তমান Termux/PRoot process-এর জন্য vendor DSP service
  উপলভ্য থাকতে হবে। অন্য device qualify করা হয়নি।
- Debian runtime package `libgbinder1`, `libglibutil1` ও `libfastrpc1`।
- Debian guest থেকে পড়া যায় এমন path-এ GGUF model। Extension model weight
  download, copy বা bundle করে না।

Debian guest-এ runtime package install করুন:

```bash
sudo apt install libgbinder1 libglibutil1 libfastrpc1
```

Debian 13-এ `libgbinder1` ও `libglibutil1` Trixie Backports-এ, আর `libfastrpc1`
এর জন্য `contrib` component দরকার। apt package না পেলে official
`trixie-backports` source-এ `main` এবং `contrib` সক্রিয় করে package index update
করুন, তারপর install আবার চালান। Debian package record:
[`libgbinder1`](https://packages.debian.org/trixie-backports/arm64/libs/libgbinder1),
[`libglibutil1`](https://packages.debian.org/trixie-backports/arm64/libs/libglibutil1),
[`libfastrpc1`](https://packages.debian.org/trixie-backports/arm64/contrib/libfastrpc1)।

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
