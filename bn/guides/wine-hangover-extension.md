# Wine + Hangover দিয়ে Windows প্রোগ্রাম (ARM64) — পরীক্ষামূলক extension

এই রেপোসিতোর্য্ গুইদে-এ Ternux-এর automatic installer এবং checksum যাচাই করে manual install-এর নিযম দেওয়া হযেছে। [Hangover](https://github.com/AndreRH/hangover) একটি Wine build, যা ARM64 Linux-এ x86 ও x86-64 Windows প্রোগ্রাম চালায়। এটি **পরীক্ষামূলক** extension: পরীক্ষিত device-এ কাজ করেছে, কিন্তু এটি যাচাই করা release feature নয়। মাপা ফলাফল [device qualification record](#device-qualification-record)-এ আছে।

## পরিসর ও প্রয়োজনীয়তা

- Hangover **11.16** (Wine 11.16; upstream রেলেঅসে নোতে-এ FEX 2608 ও Box64 v0.4.4), `hangover_11.16_debian13_trixie_arm64.tar` asset, upstream রেলেঅসে `hangover-11.16`। Ternux এটি নিজে build করে না, mirror-ও করে না: installer upstream asset download করে তার SHA-256 pin করে রাখে।
- Ternux-এর Debian 13 (trixie) ARM64 guest-এর্ ভিতরে চালান। installer command Termux host-এ চলে এবং guest-এ কাজ পাঠায়; manual পথে Debian-এর্ ভিতরে চালাতে হয়। অন্য distribution-এর্ জোন্য আলাদা Hangover asset লাগে, তাই সেগুলি প্রত্যাখ্যান কর হয়।
- glibc 2.38 বা তার চেয়ে নতুন (পরীক্ষিত guest-এ 2.41) এবং install চলাকালে প্রায় 4 GB ফাঁকা জায়গা। install করা extension প্রায় 2.3 GB; প্রতি Wine prefix আও প্রায় 2.3 GB বাড়ায়, কারণ Wine 11 তার DLL-গুলি prefix-এ copy করে।
- Debian runtime package: `libasound2t64 libavcodec61 libavformat61 libavutil59 libglib2.0-0t64 libgphoto2-6t64 libgphoto2-port12t64 libgstreamer-plugins-base1.0-0 libgstreamer1.0-0 libpulse0 libsane1 libudev1 libusb-1.0-0 libwayland-client0 libwayland-egl1 libx11-6 libxext6 libxkbcommon0 libxkbregistry0 libncurses6 libfreetype6 libfontconfig1 libxrender1 libxrandr2 libxcursor1 libxi6 libxcomposite1 libxfixes3 libxinerama1 libxxf86vm1 libgnutls30t64`। installer কিচু download করার আগে সেগুলি যাচাই করে, কোনো package না থাকলে ঠিক্তামতী `sudo apt install` লাইন ছাপে। পূর্ণ Ternux desktop-এ শুধু `libxkbregistry0` ছিল না।
- একটি display: Ternux-এর Termux:X11 desktop, অথবা headless ব্যবহারের জন্য Xvfb।
- PRoot-এ binfmt_misc নেই, তাই Windows প্রোগ্রাম `wine program.exe` হিসেবে চালাতে হয়; `.exe` সরাসরি চালালে চলবে না।
- এটি Windows compatibility-র্ প্রতিশ্রুতি নয়। কি পরীক্ষা করা হযেছে এবং কি হয়নি তা [qualification record](#device-qualification-record)-এ দেখুন।

## Route A: automatic install (প্রস্তাবিত)

**Termux**-এ extension-এর্ তালিকা দেখুন এবং install করুন:

```bash
ternux extension list
ternux extension install wine-hangover
```

host CLI নির্বাচিত Debian guest-এ কাজ পাঠায়। guest-এর্ installer:

1. Linux ARM64, glibc, Debian 13, ফাঁকা জায়গা এবং উপরে দেওয়া Debian runtime package যাচাই করে; কোনো যাচাই ব্যর্থ হলে কোনো download-এর্ আগেই থামে;
2. 293 MB upstream tarball download করে তার SHA-256 `lib/extension.sh`-এ pin করা মানের সাথে মিলিয়ে দেখে (এটি release asset-এর্ জন্য GitHub যেটি প্রকাশ করে, হুবহু সেটি): `b5493f5903ab3c05f78bf4c03b06ac0005eb26f732437748c1592fefa45e861a`;
3. কেবল পাঁচটি প্রত্যাশিত member গ্রহণ করে, প্রতি `.deb`-এর্ ভিতরের প্রতি path ও link যাচাই করে, এবং `dpkg-deb` দিয়ে home-এ unpack করে। root ব্যবহার করা হয় না, dpkg database বদলায় না, এবং package-গুলি-র্ header ও man page বাদ যায়;
4. `env.sh` ও `build-manifest.json` লেখে, stage করা কপি থেকে `wine --version` চালায়, তারপর কেবল তখন directory-টি atomically জায়গায় সরায়:

```text
$HOME/.local/opt/ternux-extensions/wine-hangover
```

একটি বিদ্যমান গন্তব্য কখনো overwrite করা হয় না, এবং যেকোনো ধাপে ব্যর্থ হলে কোনো ফাইল ব staging directory থাকে না। install বদলাতে হলে নিজে এই নির্দিষ্ট directory-টি পরীক্ষা করে মুছে ফেলুন্, তারপর command-টি আবার চালান। আপনার Wine prefix এবং প্রোগ্রাম আলাদা, সেগুলি স্পর্শ করা হয় না।

## প্রথম চালানো ও প্রোগ্রাম চালানো

Debian-এ environment load করে একটি prefix বানিয়ে নিন। প্রথম চালায় প্রায় 3 থেকে 4 মিনিট লাগে এবং প্রায় 2.3 GB-এর্ একটি prefix তৈরি হয় (`WINEPREFIX` দিয়ে অন্য prefix বাছা যায়):

```bash
source "$HOME/.local/opt/ternux-extensions/wine-hangover/env.sh"
wine --version
WINEDLLOVERRIDES="mscoree=d;winemenubuilder.exe=d" wine wineboot -u
```

`mscoree=d` wine-mono download skip করে, যা upstream এই release-এ ভাঙা বলে সতর্ক করেছে; `winemenubuilder.exe=d` desktop-menu integration skip করে। upstream-এর বিকল্প হল `WINEDEBUG=wininet wine wineboot -u`। যাদের .NET লাগে, তাদের wine-mono লাগে, যা এই extension install করে না।

একটি display থাকা অবস্থায় প্রোগ্রাম চালান। console প্রোগ্রামের জন্য নিচে দেওয়া graphics settings লাগে না:

```bash
wine ./your_program.exe
```

Hangover প্রোগ্রামের প্রকার অনুসারে x86 emulator বাছে; দুটি-ই package-এ আছে:

| প্রোগ্রামের প্রকার | default emulator | অন্য emulator কীভাবে বাছবেন |
|---|---|---|
| x86-64 | ARM64EC-এর মাধ্যমে FEX (`libarm64ecfex.dll`) | `HODLL64=libarm64ecfex.dll` |
| x86 (32-bit) | Box64 (`wowbox64.dll`) | `HODLL=libwow64fex.dll` দিয়ে FEX |

### Graphics: আগে GPU, না হলে CPU fallback

`env.sh` Ternux-এর নিজস্ব backend নিযম অনুসরণ করে এবং আপনি যেটি চাননি সেটি কখনো জোর করে ছাপিয়ে দেয় না:

1. `GALLIUM_DRIVER` আগে থেকে থাকলে সেটি-ই থাকে। Ternux desktop session-এর্ ভিতরে terminal session-এর driver উত্তরাধিকার করে: Adreno-এ `zink`, অন্য GPU-তে `virpipe` (VirGL, Termux host পরিবেষন করে);
2. না হলে, Adreno KGSL node দেখা গেলে (`/dev/kgsl-3d0`, অথবা Ternux যেখানে সেটি guest-এ `/dev/kgsl` হিসেবে bind করে) `GALLIUM_DRIVER=zink` set করে, যা OpenGL-কে Zink ও Mesa Turnip-এর মাধ্যমে GPU-তে চালায়;
3. এই দুটির কোনোটাই না হলে কিচু set করে না, Mesa তার CPU renderer (llvmpipe) ব্যবহার করে।

যেকোনো সময় `GALLIUM_DRIVER=llvmpipe wine ...` দিয়ে CPU পথ জোর করে চালাতে পারবেন। Windows OpenGL প্রোগ্রাম অসলে কি পাচ্ছে তা দেখ্তে এমন একটি প্রোগ্রাম চালান যা তার renderer ছাপে; `experiments/wine-hangover/validate.sh` GLEW-এর `glewinfo.exe` দিয়ে এটি করে। `ternux doctor extensions` `env.sh` যেটি বাছাই করে সেটি দেখায়।

headless ব্যবহারের জন্য GLX enable করে Xvfb চালু করুন:

```bash
Xvfb :77 -screen 0 1024x768x24 +extension GLX +render -noreset &
export DISPLAY=:77
```

এই environment-এ Xvfb-তে Zink-এর output দেখা যায় না ([qualification record](#device-qualification-record) দেখুন), তাই GPU-তে render করা window দেখ্তে Termux:X11 desktop ব্যবহার করুন।

## Route B: manual install

release-টি নিজে যাচাই করতে চাইলে অথবা host extension command না থাক্লে এটি ব্যবহার করুন। সব কিচু **Debian guest**-এ, স্বাভাবিক user হিসেবে চালান। এটি একটি version-যুক্ত directory-এ install করে, তাই Route A-এর সাথে সংঘর্ষ হয় না।

baseline যাচাই করুন এবং runtime package install করুন (তালিকা [পরিসর ও প্রয়োজনীয়তা](#পরিসর-ও-প্রয়োজনীয়তা)-এ):

```bash
getconf GNU_LIBC_VERSION   # glibc 2.38 or newer
grep -E '^(ID|VERSION_ID)=' /etc/os-release   # debian, 13
sudo apt install libasound2t64 libavcodec61 libavformat61 libavutil59 \
  libglib2.0-0t64 libgphoto2-6t64 libgphoto2-port12t64 \
  libgstreamer-plugins-base1.0-0 libgstreamer1.0-0 libpulse0 libsane1 libudev1 \
  libusb-1.0-0 libwayland-client0 libwayland-egl1 libx11-6 libxext6 \
  libxkbcommon0 libxkbregistry0 libncurses6 libfreetype6 libfontconfig1 \
  libxrender1 libxrandr2 libxcursor1 libxi6 libxcomposite1 libxfixes3 \
  libxinerama1 libxxf86vm1 libgnutls30t64
```

asset-টি download করুন এবং নির্দিষ্ট digest-এর বিরুদ্ধে যাচাই করুন:

```bash
ASSET=hangover_11.16_debian13_trixie_arm64.tar
WORK="$(mktemp -d)"
cd "$WORK"
curl -fL --retry 3 -o "$ASSET" \
  "https://github.com/AndreRH/hangover/releases/download/hangover-11.16/$ASSET"
echo "b5493f5903ab3c05f78bf4c03b06ac0005eb26f732437748c1592fefa45e861a  $ASSET" | sha256sum -c -
```

কেবল `OK` ছাপালে এগিয়ে যান। archive-টি পরীক্ষা করুন, তারপর একটি নতুন directory-এ unpack করুন (এই পাঁচটি প্রত্যাশিত member):

```bash
tar -tf "$ASSET"
mkdir dl root
tar --no-same-owner -xf "$ASSET" -C dl
for deb in dl/hangover-*.deb; do
  dpkg-deb -f "$deb" Package Version
  dpkg-deb --fsys-tarfile "$deb" | tar -tv | grep -E '^h| -> /|\.\./' && echo "STOP: unsafe entry in $deb"
done
```

`STOP` ছাপালে থামুন। নৈলে একটি versioned গন্তব্যে unpack করুন যেটি এখনো নেই, এবং পরীক্ষা করুন:

```bash
DEST="$HOME/.local/opt/ternux-extensions/wine-hangover-11.16"
test ! -e "$DEST" && test ! -L "$DEST" || { echo "exists: $DEST" >&2; exit 1; }
for deb in dl/hangover-*.deb; do
  dpkg-deb --fsys-tarfile "$deb" |
    tar --no-same-owner -x -C root --exclude=./usr/include --exclude=./usr/share/man
done
mkdir -p "$(dirname "$DEST")"
mkdir -p "$DEST/share"
mv root/usr/bin "$DEST/bin"
mv root/usr/lib "$DEST/lib"
mv root/usr/share/wine "$DEST/share/wine"
"$DEST/bin/wine" --version     # expect: wine-11.16 (Hangover)
```

manual পথে `env.sh`, manifest বা GPU/CPU বাছাই তৈরি হয় না। variable-গুলি সরাসরি ব্যবহার করুন:

```bash
export PATH="$DEST/bin:$PATH" WINEPREFIX="$HOME/.wine"
export GALLIUM_DRIVER=zink      # GPU through Zink/Turnip; omit it for the CPU fallback
WINEDLLOVERRIDES="mscoree=d;winemenubuilder.exe=d" wine wineboot -u
```

manual install archive hash ও package-এর path যাচাই করে, কিন্তু Route A-এর check, atomic সরানো ও smoke test তাতে নেই। audit trail দরকার হলে যাচাই করা archive-টি রেখে দিন।

## সমস্যা সমাধান ও সরানো

- **Termux-এ `ternux: command not found`:** Ternux install বা update করে Debian-এ নয়, Termux host shell-এ command-টি চালান।
- **"Missing Debian runtime packages":** installer যেটি ছাপায় সেই `sudo apt install` লাইন চালান, তারপর command-টি আবার চালান। কিচু download করা হয়নি।
- **"requires glibc 2.38" বা "built for Debian 13":** এই guest যাচাই করা Debian 13 guest নয়। সেখানে extension install হবে না।
- **প্রথম `wineboot` অটকে থাকার মোতো মনে হলে:** প্রথম চালায় কয়েক মিনিট লাগে। `WINEDEBUG=+all` set করবেন না; সব channel trace করলে Wine অনেক গুণ ধীর হয়। `env.sh`-এর দেওয়া default `WINEDEBUG=-all` ব্যবহার করুন।
- **Xvfb-এ GPU window কালো:** এই environment-এ Zink-এর output Xvfb frame buffer-এ পৌঁছায় না; llvmpipe window পৌঁছায়। Termux:X11 ব্যবহার করুন, বা `GALLIUM_DRIVER=llvmpipe` দিয়ে CPU পথ জোর করে window দেখুন্।
- **`wine --version` কাজ করে কিন্তু প্রোগ্রাম ব্যর্থ:** `ternux doctor extensions --json` চালিয়ে `ext_wine_*` সারিগুলি পড়ুন, তারপর 32-bit প্রোগ্রামের জন্য `HODLL=libwow64fex.dll` দিয়ে অন্য emulator চেষ্টা করুন।
- **বিদ্যমান গন্তব্য:** সরানোর আগে নির্দিষ্ট পথ পরীক্ষা করুন। Route A ও Route B আলাদা directory ব্যবহার করে।

কেবল automatic install-টি সরাতে, পরীক্ষা করে নির্দিষ্ট পথটি সরান:

```bash
ls -la "$HOME/.local/opt/ternux-extensions/wine-hangover"
rm -rf -- "$HOME/.local/opt/ternux-extensions/wine-hangover"
```

manual পথের জন্য `wine-hangover-11.16` ব্যবহার করুন। Wine prefix (default-এ `~/.wine`, প্রতিটি প্রায় 2.3 GB) এবং cache করা download আলাদা, এই command-গুলি সেগুলি সরায় না।

## Device qualification record

2026-10-17 তারিখে আমি extension-টি install করি, একটি prefix তৈরি করি এবং Redmi Turbo 4 Pro workstation-এ আসল Windows প্রোগ্রাম চালাই: Termux-এর সাথে PRoot Debian 13 arm64, glibc 2.41, Debian-এর Mesa 25.0.7-2+deb13u1। Vulkan Adreno 825 (Turnip, Vulkan 1.4) এবং একটি `llvmpipe` device দেখায়। আমি guest-সিদে installer function-টি সরাসরি ওই Debian guest-এ (`_tnx_extension_guest_dispatch install wine-hangover`) একটি আলাদা `HOME` দিয়ে চালিয়েচি; guest-এ delegate করা Termux-host wrapper device-এ চালানো হয়নি, তার কেবল repository-এর mock করা delegation পরীক্ষা আছে। label-গুলো repository-এর রীতি অনুসারে: **verified**, **observed**, **measured**, **untested**।

### install ও prefix

- **Verified:** `lib/extension.sh`-এ pin করা SHA-256 GitHub-এর API release asset-এর জন্য যেটি প্রকাশ করে এবং আমর download-এর hash, দুটির সাথেই হুবহু মিলে যায় (`b5493f59…861a`, 293,099,520 byte)।
- **Verified:** `libxkbregistry0` (একমাত্র অনুপস্থিত package, 87 KB) না থাকায় installer কোনো download-এর আগেই প্রত্যাখ্যান করল এবং কিচুই তৈরি করেনি। `sudo apt install libxkbregistry0`-এর পরে install সম্পন্ন হল এবং `wine --version` `wine-11.16 (Hangover)` ছাপল।
- **Measured:** install-এ 293 MB download সমেত 55 সেকেন্ড লাগল। extension-টি 2,326-টি file-এ 2.3 GB।
- **Measured:** প্রথম `wineboot -u` হাতে 188 সেকেন্ড এবং validation script-এর ভিতরে 221 সেকেন্ড নিয়েছে। ফলে prefix 2.3 GB (2,043-টি সাধারণ file, কারণ Wine তার DLL copy করে)। আমার আগের একটি চেষ্টায় সব Wine debug channel চালু (`WINEDEBUG=+all`) করায় 10 মিনিটে-ও শেষ হয়নি, তাই থামিয়ে দিয়েচি।
- **Verified:** এই install-এর বিরুদ্ধে `experiments/wine-hangover/validate.sh`: 15-টির মধ্যে 15-টি check পাস করেছে, exit status 0। repository-এর focused পরীক্ষা (88-টি, installer ও doctor-এর জন্য 18-টি নতুন সমেত) পাস করে।

### যেসব প্রোগ্রাম চলেছে

সবগুলি publisher-এর release পাতা থেকে নামানো আসল প্রোগ্রাম। প্রথম চার সারি `experiments/wine-hangover/validate.sh`-এ, benchmark সারি `experiments/wine-hangover/benchmark.sh`-এ চালানো হয়; দুটি-ই প্রতি download-এর SHA-256 pin করে।

| Program | Type | ফল |
|---|---|---|
| Python 3.13.1 embeddable | 32-bit x86 (Box64) | `PY 32` ছাপল |
| Python 3.13.1 embeddable | 64-bit x86-64 (FEX) | `PY 64` ছাপল |
| GLEW 2.2.0 `glewinfo.exe` | 32-bit ও 64-bit | একটি OpenGL context তৈরি করে renderer জানাল (পরের অনুচ্ছেদে) |
| 7-Zip 23.01 installer | 32-bit ও 64-bit | নীরব `/S` install; `7z a` ও তারপর `7z t` `Everything is Ok` জানাল; archive-গুলি 7z signature বহন করে |
| ChimbaBenchXPL A3 (GPL-3.0 OpenGL benchmark) | 32-bit ও 64-bit | তার "Simple Test" শেষ করে একটি score লিখল |

**Observed:** default-এ 32-bit প্রোগ্রাম Box64-এ এবং 64-bit প্রোগ্রাম FEX-এ চলে (log-এ `WowBox64 arm64 v0.4.4 (Hangover 11.16)` ও `starting FEX (Hangover 11.16) based libarm64ecfex.dll` ছাপা হয়); `HODLL=libwow64fex.dll` 32-bit প্রোগ্রামও FEX-এ চালিয়েছে।

### Graphics: GPU ও CPU fallback

**Observed:** `glewinfo.exe` যেই context পায় তার renderer ছাপে।

| Setting | 32-bit ও 64-bit ফল |
|---|---|
| `env.sh` default (KGSL node দেখা গেলে) | `zink Vulkan 1.4(Adreno (TM) 825 (MESA_TURNIP))` |
| `GALLIUM_DRIVER=llvmpipe` | `llvmpipe (LLVM 19.1.7, 128 bits)` |

**Verified:** `env.sh` আগে থেকে set থাকা `GALLIUM_DRIVER` রাখে, KGSL node দেখা গেলে `zink` set করে, না দেখা গেলে variable-টি unset রাখে (CPU fallback)। unit পরীক্ষা ওই তিনটি অবস্থা cover করে, এবং আগে থেকে set `virpipe` আমি হাতে পরীক্ষা করেছি।

### Benchmark

**ChimbaBenchXPL A3** (Godot-ভিত্তিক OpenGL 2.1 benchmark; release asset-এর digest `81321e4c…b803`, GitHub-এর সাথে মিলে)। "Simple Test", 640×360, প্রতি cell-এ তিনটি run; প্রকল্পের result database score-টি-কে FPS বলে চিহ্নিত করে।

| Program | CPU পথ (`llvmpipe`) | GPU পথ (Zink/Turnip) | GPU / CPU (mean) |
|---|---|---|---|
| 32-bit (Box64) | 91, 82, 79 (mean 84.0) | 128, 126, 112 (mean 122.0) | 1.45× |
| 64-bit (FEX) | 91, 90, 83 (mean 88.0) | 179, 180, 185 (mean 181.3) | 2.06× |

এই **measured** score-গুলোর কিচু গুরুত্বপূর্ণ সীমা আছে। Xvfb-এ Zink window আমি যত test চালিয়েচি সবখানেই কালো থাকে, native `glxgears`-ও (llvmpipe window দেখা যায়); তাই GPU run-গুলো scene ঠিকভাবে draw করেছিল কিনা নিশ্চিত কর্তে পারিঅনি — GPU স্তম্ভটি unverified হিসেবে পড়ুন। benchmark দুটি mode-এই Wine-এর জানানো adapter-এর নাম (`Adreno (TM) 825`) ছাপে, তাই তার header renderer বোঝায় না; renderer `GALLIUM_DRIVER` দিয়ে set করা হযেছে এবং GLEW দেখিয়েছে প্রতি setting কি বাছাই করে। KGSL load counter guest থেকে পড়া যায় না। কেবল এই scene-টি চালানো হযেছে, এবং একৈ প্রকারের সব cell একসাথে চালানো হযেছে, interleave করে নয়।

**7-Zip `b -mmt8`** total rating (বেশি মানে দ্রুত), তিনটি pass। native হল Debian-এর `7zip` 25.01 package; Wine সারিগুলি prefix-এ install করা 7-Zip 23.01 চালায়।

| Pass | Native arm64 | Wine x86-64 (FEX) | Wine x86 (Box64) | Wine x86 (FEX) |
|---|---|---|---|---|
| 1 | 17,683 | 11,465 | 8,986 | 8,750 |
| 2 | 13,874 | 10,085 | 8,284 | 9,127 |
| 3 | 14,713 | 10,169 | 8,901 | 9,417 |
| mean | 15,423 | 10,573 (69%) | 8,724 (57%) | 9,098 (59%) |

**Measured**, নিওযন্ত্রিত নয়: pass 2-এর শুরুত battery thermal zone 43.6 °C এবং pass 3-এর শেষে 44.8 °C ছিল (pass 1-এর তাপমাত্রা record করা হয়নি), এবং native rating 17,683 থেকে 13,874–14,713-এ নেমে যায়, তাই সংখ্যাগুলোর মধ্যেই তাপ দেখা যায়। প্রতি pass-এ emulated ফল native-এর 65–73% (x86-64), 51–60% (Box64-এ x86) ও 49–66% (FEX-এ x86) ছিল। version আলাদা, তাই ratio-গুলো মোটামুটি ধারণা হিসেবে নিন।

**Measured:** পরবর্তী একটি `benchmark.sh --runs 1` চালানোয় ফোনে বেশি গরম ছিল (battery zone 43.4–44.1 °C); ক্রম একৈ থাকে, তবে মান কম: ChimbaBenchXPL 75 (32-bit CPU), 99 (32-bit GPU), 79 (64-bit CPU) ও 171 (64-bit GPU); 7-Zip native 15,173, FEX-এ x86-64 10,378, Box64-এ x86 8,813 ও FEX-এ x86 9,304। script-টি `0` exit status দিয়েছিল।

### যা এখনো প্রমাণিত নয়

- Windows গেম, DirectX (DXVK `share/ternux/`-এ আছে, কিন্তু চেস্টা করা হয়নি), audio, input device, .NET (wine-mono install করা নেই), বোড় installer, দীর্ঘ session ও তাপীয় সীমা।
- GPU-তে render করা window-এর ছবি ঠিক কিনা: Xvfb Zink-এর output দেখাতে পারে না, এবং এই run-এ আমি Termux:X11 desktop-এ কোনো windowed প্রোগ্রাম পরীক্ষা করিঅনি।
- অন্য GPU-তে VirGL পথ (এই machine-এ এমন device নেই), একটি পরিষ্কার device, এবং device-এ Termux-host delegation।
- আমার হাতে তৈরি একটি ন্যূনতম x86-64 পরীক্ষা executable FEX-এর ভিতরে fault করেছিল, অথচ উপরের প্রতি আসল 64-bit প্রোগ্রাম চলেছে। আমার হাতে তৈরি ফাইলটিকে আমি বাতিল পরীক্ষা-ইন্পুত্ ধরে নিয়েচি এবং আর তদন্ত করিঅনি।
