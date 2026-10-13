# llama.cpp CPU + Vulkan extension (ARM64)

এই repository guide-এ Ternux-এর automatic installer এবং checksum-যাচাইসহ
manual install—দুই পদ্ধতি আছে। Website-এর [সহজ guide](https://soobujmiah.github.io/ternux/bn/docs/QUICK-START.html#ঐচ্ছিক-লোকাল-cpu--vulkan-language-model)-এ শুধু দ্রুত setup রাখা হয়েছে; বিস্তারিত এখানে।

## পরিধি ও প্রয়োজন

- এটি `ternux-llama-vulkan-linux-arm64-b11582` **prerelease**; llama.cpp
  commit `af50f2f248b475d9760f8e67503d01c0f194f5f4` থেকে build করা।
- Ternux-এর Debian ARM64 glibc guest-এর ভেতরে চালান। Installer command চলে
  Termux host-এ; manual পদ্ধতি চলে Debian-এ।
- প্রকাশিত binary-র জন্য **glibc 2.38 বা নতুন** লাগবে। Ternux-এ পরীক্ষিত
  Debian PRoot-এ glibc 2.41 আছে। Guest-এ OpenSSL 3 runtime
  (`libssl3` বা `libssl3t64`), `libgomp1`, ও `libvulkan1`-ও লাগবে; কোনোটি না
  থাকলে Debian-এর উপযুক্ত package install করুন। পুরোনো glibc হলে
  installer download বা file write করার আগেই থেমে যাবে।
- Package-এ llama.cpp CPU ও Vulkan backend আছে। এটি model weight, Vulkan
  driver/ICD বা HTP/QNN support install করে না। GGUF ফাইল আগের জায়গায় রাখুন।
  Vulkan-এর জন্য system Vulkan ICD কাজ করতে হবে; পরীক্ষিত Adreno setup-এ device
  ছিল `Vulkan0`।
- এটি একটি device-এ যাচাই করা prerelease; clean-device driver qualification
  বা দীর্ঘ সময় চালানোর দাবি নয়। [Benchmark evidence](https://soobujmiah.github.io/ternux/bn/docs/BENCHMARKS.html#2026-10-14-published-vulkan-extension-install-and-inference) দেখুন।

## পদ্ধতি A: automatic install (প্রস্তাবিত)

**Termux**-এ extension তালিকা দেখুন ও install করুন:

```bash
ternux extension list
ternux extension install llama-vulkan
```

Host CLI নির্বাচিত Debian guest-এ নির্দেশ পাঠায়। Guest-side installer Linux
ARM64/glibc যাচাই করে, pinned release ও SHA-256 sidecar নামায়, archive digest
যাচাই করে, archive path ও link পরীক্ষা করে, manifest এবং আবশ্যক ফাইল দেখে, তারপর
atomic ভাবে এখানে install করে:

```text
$HOME/.local/opt/ternux-extensions/llama-vulkan
```

আগে থেকে থাকা destination overwrite হয় না। In-place updater নেই। নতুন করে
install করার আগে নির্দিষ্ট extension directory পরীক্ষা করে নিজে সরিয়ে নিন।
অন্য extension থাকলে parent `ternux-extensions` directory মুছবেন না।

Debian-এ environment চালু করে device দেখুন:

```bash
source "$HOME/.local/opt/ternux-extensions/llama-vulkan/env.sh"
llama-cli --version
llama-cli --list-devices
```

আগে CPU baseline চালান (কোনো GPU layer নয়):

```bash
llama-cli -m /path/to/model.gguf -ngl 0 \
  -p 'What is 2 + 2? Answer with the number only.' -n 8
```

Vulkan-এ চালান (আপনার আগে থেকে থাকা GGUF-এর path দিন):

```bash
llama-cli -m /path/to/model.gguf -dev Vulkan0 -ngl 99 \
  -p 'What is 2 + 2? Answer with the number only.' -n 8
```

`--list-devices`-এ `Vulkan0` থাকতে হবে; নাম আলাদা হলে দেখানো নাম ব্যবহার
করুন। `-ngl 99` সব উপযুক্ত model layer offload করতে বলে; verbose run log-এ
আসলেই কত layer গেছে যাচাই করুন। Vulkan device না এলে `-ngl 0` দিয়ে CPU-তে
চালিয়ে system ICD/driver পরীক্ষা করুন।

## পদ্ধতি B: manual install

নিজে release পরীক্ষা ও যাচাই করতে চাইলে, অথবা host extension command ব্যবহার
করতে না পারলে এটি নিন। সব command **Debian guest**-এ স্বাভাবিক user হিসেবে
চালান। Version-সহ আলাদা directory ব্যবহার হবে, তাই automatic install path-এর
সাথে সংঘর্ষ হবে না।

প্রথমে ABI minimum ও system runtime package যাচাই করুন:

```bash
getconf GNU_LIBC_VERSION   # glibc 2.38 বা নতুন হতে হবে
if apt-cache show libssl3t64 >/dev/null 2>&1; then
  SSL_PACKAGE=libssl3t64
else
  SSL_PACKAGE=libssl3
fi
sudo apt install libgomp1 libvulkan1 "$SSL_PACKAGE"
```

HTTPS দিয়ে archive ও প্রকাশিত checksum sidecar নামিয়ে digest যাচাই করুন:

```bash
TAG=ternux-llama-vulkan-linux-arm64-b11582
ASSET="$TAG.tar.gz"
RELEASE="https://github.com/soobujmiah/ternux/releases/download/$TAG"
CACHE="$HOME/.cache/ternux-artifacts/$TAG"
mkdir -p "$CACHE"
cd "$CACHE"
curl -fL --retry 3 -o "$ASSET" "$RELEASE/$ASSET"
curl -fL --retry 3 -o "$ASSET.sha256" "$RELEASE/$ASSET.sha256"
sha256sum -c "$ASSET.sha256"
```

এই প্রকাশিত build-এর প্রত্যাশিত archive SHA-256:

```text
3753fa3044ec258732cc52729eafc42c0cbf5b476f27fd247be3619617611d9e  ternux-llama-vulkan-linux-arm64-b11582.tar.gz
```

Extract করার আগে archive-এর path দেখুন এবং নিশ্চিত করুন সব entry নির্দিষ্ট
একটি top-level directory-র ভেতরে আছে। Automatic পদ্ধতি link ও package layout-ও
যাচাই করে; manual install দরকার না হলে সেটিই ব্যবহার করুন।

```bash
tar -tzf "$ASSET" | less
```

সব path `ternux-llama-vulkan-linux-arm64-b11582/`-এর নিচে, absolute path নয়
এবং কোনো path component `..` নয়—এটি নিশ্চিত হলেই পরের ধাপ চালান। নতুন
version-specific directory-তে extract করুন; সেটি আগে থেকে থাকলে থামুন:

```bash
DEST="$HOME/.local/opt/ternux-extensions/llama-vulkan-b11582"
mkdir -p "$(dirname "$DEST")"
test ! -e "$DEST" && test ! -L "$DEST" || {
  printf 'Destination already exists: %s\n' "$DEST" >&2
  exit 1
}
STAGE="$(mktemp -d "$(dirname "$DEST")/.llama-vulkan-b11582.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT
tar --no-same-owner -xzf "$ASSET" -C "$STAGE"
test -x "$STAGE/$TAG/bin/llama-cli"
test -f "$STAGE/$TAG/env.sh"
grep -Fq '"artifact": "ternux-llama-vulkan-linux-arm64-b11582"' \
  "$STAGE/$TAG/build-manifest.json"
mv "$STAGE/$TAG" "$DEST"
```

সেই version-এর environment চালু করে আগে CPU পরীক্ষা করুন:

```bash
source "$DEST/env.sh"
llama-cli --version
llama-cli --list-devices
llama-cli -m /path/to/model.gguf -ngl 0 \
  -p 'What is 2 + 2? Answer with the number only.' -n 8
```

তালিকায় প্রত্যাশিত device থাকলেই Vulkan চেষ্টা করুন:

```bash
llama-cli -m /path/to/model.gguf -dev Vulkan0 -ngl 99 \
  -p 'What is 2 + 2? Answer with the number only.' -n 8
```

Manual install প্রকাশিত archive hash ও package-এর মৌলিক layout যাচাই করে, তবে
Route A-এর host delegation, archive safety, atomicity ও reinstall সুরক্ষা সব
দেয় না। Audit trail দরকার হলে যাচাইকৃত archive ও checksum sidecar রেখে দিন।

## সমস্যা সমাধান ও অপসারণ

- **Termux-এ `ternux: command not found`:** আগে Ternux install/update করে
  Termux host shell-এ command চালান, Debian-এর ভেতরে নয়।
- **Linux ARM64 glibc দরকার বলে:** guest-side কাজ Debian ARM64 guest-এর বাইরে
  চালানো হয়েছে; Termux থেকে Route A নিন অথবা Route B-এর জন্য সঠিক guest-এ যান।
- **`Vulkan0` নেই:** CPU-তে package চলতে পারে। `vulkaninfo --summary` এবং
  guest-এর Vulkan ICD/driver দেখুন। Extension Turnip বা অন্য driver install করে না।
- **Destination আগে থেকেই আছে:** সরানোর আগে path পরীক্ষা করুন। Automatic ও
  manual path আলাদা। না দেখে কোনো directory মুছবেন না।
- **Model path ভুল:** extension model file সরায় না। `-m`-এ বিদ্যমান GGUF path দিন।

শুধু automatic install সরাতে Debian home-এর নির্দিষ্ট path দেখে তারপর মুছুন:

```bash
ls -la "$HOME/.local/opt/ternux-extensions/llama-vulkan"
rm -rf -- "$HOME/.local/opt/ternux-extensions/llama-vulkan"
```

Manual install-এর জন্য `llama-vulkan-b11582` path ব্যবহার করুন। এই command-এ
model weight বা cached release archive মোছা হয় না।
