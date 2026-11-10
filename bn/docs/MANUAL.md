---
title: "ম্যানুয়াল ইনস্টলেশন"
description: "ternux-এর প্রতিটি ধাপ হাতে-কলমে, কমান্ডে কমান্ডে — যারা পুরো নিয়ন্ত্রণ চান বা ইনস্টলার নিজেই ডিবাগ করতে চান, তাদের সম্পূর্ণ নির্দেশিকা।"
lang: "bn"
alt_url: "/docs/MANUAL.html"

---

এক-কমান্ড ইনস্টলার আসলে এই পাতাটাই, স্ক্রিপ্ট আকারে। এখানে সেই একই যাত্রা
**হাতে-কলমে, কমান্ডে কমান্ডে** — যারা প্রতিটি ধাপ দেখতে ও নিয়ন্ত্রণ করতে
চান, নেটওয়ার্ক সমস্যা ঘুরিয়ে কাজ করতে চান, বা ইনস্টলার কী করে সেটাই শিখতে
চান, তাদের জন্য। প্রতিটি ব্লক Termux-এ চালান, যতক্ষণ না ধাপে বলা হয় ভিন্ন
কোথাও।

**মাঝপথে কোনো ধাপ ব্যর্থ হলে:** থামুন, কারণ নির্ণয় করুন, তারপর এগোন।
প্রতিটি block আবার চালানোর আগে পড়ুন: যেখানে সম্ভব guard/check দেওয়া হয়েছে,
কিন্তু manual package, user ও file operation সর্বজনীনভাবে idempotent নয়। এই
guide-এ `ternux` Debian account ধরা হয়েছে; অন্য বৈধ lowercase নাম নিলে পরের
সব literal `ternux` একই নামে বদলান।

---

## ধাপ ১ — দুটি অ্যাপ ইনস্টল করুন

- **Termux** — [GitHub releases](https://github.com/termux/termux-app/releases)
  বা [F-Droid](https://f-droid.org/en/packages/com.termux/) থেকে। Google Play
  build আলাদা পরীক্ষামূলক Android 11+ line, যেখানে feature/bug-এর পার্থক্য
  আছে; এই guide মূল F-Droid/GitHub release line ধরে। Termux:API ও অন্য plugin
  **Termux-এর একই source** থেকে নিন, যাতে signing key মেলে।
- **Termux:X11** — [GitHub releases](https://github.com/termux/termux-x11/releases)
  থেকে। **একবার** খুলুন, তারপর রেখে দিন — প্রথম লঞ্চের পরই Android ডিসপ্লে
  সার্ভিসের অনুমতি দেয়।

---

## ধাপ ২ — Termux বেস প্যাকেজ

```bash
# প্যাকেজ ইনডেক্স রিফ্রেশ ও আপগ্রেড।
pkg update -y
pkg upgrade -y

# X11 ও গ্রাফিক্স প্যাকেজ বহনকারী রিপোজিটরি।
pkg install x11-repo tur-repo -y

# ডিসপ্লে অ্যাপ সার্ভিস, অডিও, এবং কন্টেইনার ইঞ্জিন।
pkg install termux-x11-nightly -y
pkg install pulseaudio proot-distro util-linux -y

# হোস্ট-পাশের VirGL রেন্ডারার (সামঞ্জস্য GPU পথ — Adreno-তেও ইনস্টল করুন;
# খরচ কম, আর পথ বদল করা সহজ থাকে)।
pkg install virglrenderer-android -y

# পরে এই গাইডে লাগবে এমন শেল ও ডাউনলোড টুল।
pkg install zsh git curl wget nano tar -y

# ডেস্কটপ যাতে স্ক্রিন জাগিয়ে রাখতে পারে, তার ওয়েক-লক সাপোর্ট।
pkg install termux-api -y
```

শুধু Adreno ডিভাইস (Qualcomm GPU — `ls -l /dev/kgsl-3d0` দিয়ে দেখুন):

```bash
pkg install mesa-vulkan-icd-freedreno -y
```

> `/dev/kgsl-3d0` না থাকলে Freedreno ICD বাদ দিন: আপনার ডিভাইস VirGL পথে
> যাবে, সেখানে এই প্যাকেজের কোনো কাজ নেই।

তিনটি জরুরি বাইনারি সত্যিই ইনস্টল হলো কিনা যাচাই করুন:

```bash
command -v proot-distro && command -v termux-x11 && command -v pulseaudio
```

---


Debian desktop-এ Ternux Camera ও Ternux Sound Recorder থাকে। Android front/rear camera দিয়ে photo তুলতে Termux-এর **একই source থেকে Termux:API Android app** ইনস্টল করুন এবং প্রথম capture-এ Termux:API-কে Camera permission দিন। ছবি যাচাইয়ের পর Debian PRoot-এর `/home/ternux/Pictures/Ternux`-এ (অথবা নির্বাচিত guest user-এর home-এ) সেভ হয়। preview-তে ছবির EXIF orientation মানা হয় এবং নিচের action button compact রাখা হয়েছে। Android Gallery-তে যোগ করা হয় না। Termux:API camera info ও still photo দেয়, continuous camera stream দেয় না। Sound Recorder-এর Start চাপলে তবেই Termux:API mic চালু হয়; setup-এর সময় Termux:API permission চাওয়া হয়; না পেলে প্রথম ব্যবহারে Android permission চাইতে পারে। Record করার আগে AAC/M4A (default) অথবা MP3 বেছে নিন। Stop and save করলে নির্বাচিত format Debian user-এর `~/Music/Ternux`-এ সেভ হয়। Android mic capture AAC-তে হয়; MP3 Debian-এর FFmpeg দিয়ে local-এ encode হয়।

## ধাপ ৩ — Debian ইনস্টল

```bash
proot-distro install debian
```

*কেন PRoot?* এটি userspace-এ root-like Debian userland দেয়—bootloader
unlock বা Android root লাগে না। তবে PRoot security boundary নয়; Termux-accessible
বা explicitly bound path reachable থাকে। Destructive কাজের আগে backup নিন।

---

## ধাপ ৪ — Debian-এর ভেতরে ডেস্কটপ প্যাকেজ

রুট হিসেবে কন্টেইনারে ঢুকে Xfce4 ও GL/অডিও প্লাম্বিং ইনস্টল করুন:

```bash
proot-distro login debian
```

```bash
export DEBIAN_FRONTEND=noninteractive
apt update

# কোর ডেস্কটপ + GL/অডিও। এটি সফল হতেই হবে।
apt install -y sudo nano mousepad fonts-noto-core python3-gi gir1.2-gtk-3.0 ibus ibus-avro devilspie2 dbus-x11 pulseaudio pulseaudio-utils pavucontrol x11-utils mesa-utils libgl1-mesa-dri adwaita-icon-theme xfce4 xfce4-taskmanager xfce4-terminal zenity vlc ristretto qt5-gtk-platformtheme arc-theme colord

# PolicyKit: polkitd = trixie+, policykit-1 = bookworm। বেস্ট-এফোর্ট।
apt install -y polkitd || apt install -y policykit-1 || true

# স্পষ্ট Vulkan লোডার (Zink রানটাইমে libvulkan.so.1 dlopen করে) + টুলস।
apt install -y libvulkan1 vulkan-tools || true

# আর্কাইভ টুল। বেস্ট-এফোর্ট — rar/p7zip-rar থাকে Debian non-free-তে।
apt install -y zip unzip xarchiver unrar-free || true
apt install -y 7zip || apt install -y p7zip-full || true

exit
```

---

## ধাপ ৫ — আপনার ইউজার তৈরি (নিরাপদ sudo সহ)

```bash
proot-distro login debian
```

```bash
USER_NAME=ternux

# ইউজার অনুপস্থিত থাকলে তৈরি করুন (ডেস্কটপ অ্যাকাউন্টে লগইন পাসওয়ার্ড লাগে না)।
id -u "$USER_NAME" >/dev/null 2>&1 \
  || adduser --disabled-password --gecos "" "$USER_NAME"

# গ্রাফিক্স ও অডিও গ্রুপ।
usermod -aG sudo "$USER_NAME"
usermod -aG video "$USER_NAME"
usermod -aG render "$USER_NAME"
usermod -aG audio "$USER_NAME"

# যাচাইকৃত ড্রপ-ইন ফাইলে পাসওয়ার্ডবিহীন sudo। /etc/sudoers-এ সরাসরি জুড়বেন
# না: একটি টাইপো এই অ্যাকাউন্টের sudo ভেঙে দিতে পারে। PRoot Distro দিয়ে
# guest-root recovery shell খোলা যায়; সেটি Android root নয়।
TMP_SUDOERS="$(mktemp)"
printf '%s ALL=(ALL) NOPASSWD: ALL\n' "$USER_NAME" > "$TMP_SUDOERS"
visudo -cf "$TMP_SUDOERS" \
  && install -m 0440 -o root -g root "$TMP_SUDOERS" /etc/sudoers.d/ternux
rm -f "$TMP_SUDOERS"

exit
```

এটি কাজ করছে কিনা যাচাই করুন (এটিই সেই ব্যর্থতা যা পরে লঞ্চারকে নিঃশব্দে
আটকে দেয়):

```bash
proot-distro login debian --user ternux -- sudo -n true
```

---

## ধাপ ৬ — GPU ড্রাইভার

### আপনার পথ শনাক্ত করুন

```bash
ls -l /dev/kgsl-3d0
```

- **ফাইল আছে** → Adreno → *৬ক — Zink/Turnip*-এ যান।
- **নেই** → Mali/Xclipse/PowerVR → *৬খ — VirGL*-এ যান।

### ৬ক — Zink + Turnip (Adreno)

[lfdevs/mesa-for-android-container → Releases](https://github.com/lfdevs/mesa-for-android-container/releases/latest)
থেকে বর্তমান **Debian Trixie ARM64** asset resolve করুন। Fedora, Ubuntu,
Alpine বা Arch archive বদলি করবেন না। আগে guest distribution মিলিয়ে নিন:

```bash
proot-distro login debian -- bash -c '. /etc/os-release; echo "$VERSION_CODENAME"'
# এই documented asset route-এ প্রত্যাশিত ফল: trixie
```

`trixie` না এলে থামুন; অন্য distribution-এর Mesa file overwrite করবেন না।

```bash
DRIVER_API=https://api.github.com/repos/lfdevs/mesa-for-android-container/releases/latest
DRIVER_TARBALL="$TMPDIR/mesa-freedreno.tar.gz"

DRIVER_URL="$(curl -fsSL "$DRIVER_API" \
  | grep -o '"browser_download_url": *"[^"]*debian[^"]*trixie[^"]*arm64\.tar\.gz"' \
  | head -n 1 \
  | sed 's/.*"browser_download_url": *"//; s/"$//')"

[ -n "$DRIVER_URL" ] || { echo "No Debian Trixie ARM64 release asset found"; exit 1; }
printf 'Resolved: %s\n' "$DRIVER_URL"
curl -fL --retry 3 "$DRIVER_URL" -o "$DRIVER_TARBALL"
```

Partial upgrade-এর পরে curl link না হলে শেষ line-এর বদলে চালান:

```bash
wget -O "$DRIVER_TARBALL" "$DRIVER_URL"
```

Extract করার আগে validate করুন—truncated download বা HTML error page root
হিসেবে unpack করা যাবে না:

```bash
# ১. আসল gzip tarball:
tar -tzf "$DRIVER_TARBALL" >/dev/null && echo "valid tarball"

# ২. absolute path বা path traversal নয়:
tar -tzf "$DRIVER_TARBALL" \
  | grep -E '^/|(^|/)\.\.(/|$)' \
  && { echo "UNSAFE - STOP"; exit 1; } \
  || echo "paths ok"

# ৩. যে target দুটি extract হবে, প্রতিটি ঠিক একবার regular file হতে হবে।
#    অন্য Mesa member বৈধ symlink হতে পারে; সেগুলো extract হবে না।
tar -tvzf "$DRIVER_TARBALL" | awk '
  /\/usr\/lib\/aarch64-linux-gnu\/libvulkan_freedreno[.]so$/ {
    if (substr($1,1,1) != "-") bad=1
    driver++
  }
  /\/usr\/share\/vulkan\/icd[.]d\/freedreno_icd[.]aarch64[.]json$/ {
    if (substr($1,1,1) != "-") bad=1
    icd++
  }
  END { if (bad || driver != 1 || icd != 1) exit 1 }
' && echo "one regular driver and one regular ICD found" \
  || { echo "unexpected archive layout"; exit 1; }

# ৪. troubleshooting/reproduction record:
sha256sum "$DRIVER_TARBALL"
```

ternux-এর দরকারি **শুধু দুটি file**—Turnip driver ও ICD manifest—staging
folder-এ extract করুন, তারপর mode-সহ install ও Mesa package hold করুন:

```bash
proot-distro login debian --shared-tmp
```

```bash
set -e
stage=/tmp/ternux-driver-stage
rm -rf "$stage"; mkdir -p "$stage"
trap 'rm -rf "$stage"' EXIT

tar -xzf /tmp/mesa-freedreno.tar.gz -C "$stage" \
  --wildcards "*/usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so" \
              "*/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json"

driver="$(find "$stage" -type f \
  -path '*/usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so' -print -quit)"
icd="$(find "$stage" -type f \
  -path '*/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json' -print -quit)"
[ -n "$driver" ] && [ -n "$icd" ] \
  || { echo "Turnip target files missing after staged extraction"; exit 1; }

install -m 0755 "$driver" /usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so
mkdir -p /usr/share/vulkan/icd.d
install -m 0644 "$icd" \
  /usr/share/vulkan/icd.d/freedreno_icd.aarch64.json
ldconfig

apt-mark hold mesa-vulkan-drivers libgl1-mesa-dri libglx-mesa0 \
             libgbm1 libegl-mesa0

exit
```

Target ও hold যাচাই করুন:

```bash
proot-distro login debian -- bash -c '
  test -f /usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so &&
  test -f /usr/share/vulkan/icd.d/freedreno_icd.aarch64.json &&
  apt-mark showhold && echo "Turnip targets installed"'
```

### ৬খ — VirGL (অন্যান্য GPU)

ইনস্টল করার কিছু নেই — শুধু হোস্ট রেন্ডারার আছে কিনা যাচাই করুন:

```bash
command -v virgl_test_server_android && echo "VirGL ready"
```

---

## ধাপ ৭ — অডিও, লোকেল, ফন্ট

### ৭ক — অডিও ব্রিজ (Termux পাশে)

PulseAudio-র কনফিগে লুপব্যাক-শুধু TCP ব্রিজ জুড়ে দিন:

```bash
PA_CONF="$PREFIX/etc/pulse/default.pa"
OLD='load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 port=4713'
NEW='load-module module-native-protocol-tcp listen=127.0.0.1 auth-ip-acl=127.0.0.1 auth-anonymous=1 port=4713'
SINK='load-module module-opensles-sink sink_name=Speaker'
SOURCE='load-module module-sles-source source_name=Ternux_Microphone'
DEFAULT='set-default-sink Speaker'
mkdir -p "$(dirname "$PA_CONF")"
if [ -L "$PA_CONF" ] || { [ -e "$PA_CONF" ] && [ ! -f "$PA_CONF" ]; }; then
  echo "PulseAudio config path is not a regular, non-symlink file: $PA_CONF" >&2
  false
else
  INPUT=/dev/null
  [ ! -f "$PA_CONF" ] || INPUT="$PA_CONF"
  if grep -E '^[[:space:]]*load-module[[:space:]]+module-native-protocol-tcp([[:space:]]|$)' "$INPUT" \
     | grep -Fvx -e "$OLD" -e "$NEW" | grep -q .; then
    echo "Custom PulseAudio TCP module আছে; overwrite না করে review করুন।" >&2
    false
  elif TMP="$(mktemp "${PA_CONF}.ternux.XXXXXX")"; then
    awk -v old="$OLD" -v new="$NEW" '
      $0 == old || $0 == new { if (!seen) print new; seen=1; next }
      { print }
      END { if (!seen) print new }
    ' "$INPUT" > "$TMP" &&
    { grep -qxF "$SINK" "$TMP" || printf '%s\n' "$SINK" >> "$TMP"; } &&
    { grep -qxF "$SOURCE" "$TMP" || printf '%s\n' "$SOURCE" >> "$TMP"; } &&
    { grep -qxF "$DEFAULT" "$TMP" || printf '%s\n' "$DEFAULT" >> "$TMP"; } &&
    { [ ! -f "$PA_CONF" ] || chmod --reference="$PA_CONF" "$TMP" 2>/dev/null || true; } &&
    mv -f "$TMP" "$PA_CONF" || { rm -f "$TMP"; false; }
  else
    echo "Could not create a PulseAudio staging file." >&2
    false
  fi
fi
```

*কেন শুধু loopback?* Audio TCP দিয়ে container boundary পার হয়।
`listen=127.0.0.1` service-টিকে LAN থেকে দূরে রাখে; anonymous same-device
client তবুও পৌঁছাতে পারে, তাই bind address সরাবেন না।

Ternux Android OpenSL ES microphone source load করে, নাম `Ternux_Microphone`;
কোনো desktop audio client capture চাইলে তবেই এটি সক্রিয় হয়। Android permission
নিয়ন্ত্রণ করে। Capture অনুমতি না পেলে Android Settings-এ Termux app-এর
**Microphone** permission দিয়ে আবার চেষ্টা করুন। Xfce-তে **PulseAudio Volume
Control → Input Devices** খুলে `Ternux_Microphone` বেছে নিন। Capture চলার সময়
Android microphone privacy indicator দেখায়। বর্তমান Termux:API
`termux-microphone-record` command ফাইলে record করে; desktop app-এর live
PulseAudio source দেয় না, তাই Ternux এটিকে live desktop capture path বলে না।

### ৭খ — লোকেল ও ফন্ট (Debian-এর ভেতরে)

```bash
proot-distro login debian --user ternux
```

```bash
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt install -y locales
echo 'en_US.UTF-8 UTF-8' | sudo tee -a /etc/locale.gen >/dev/null
sudo locale-gen en_US.UTF-8
echo "export LANG=en_US.UTF-8" >> ~/.bashrc
echo "export LC_ALL=en_US.UTF-8" >> ~/.bashrc

sudo apt install -y fonts-symbola fonts-noto-color-emoji \
  fonts-font-awesome fonts-powerline

# ডেস্কটপের PulseAudio ক্লায়েন্টকে লুপব্যাক ব্রিজের দিকে দেখান।
# The launcher exports the selected loopback PulseAudio endpoint to desktop apps.

# টার্মিনাল আইকন গ্লিফের জন্য Nerd Font (বেস্ট-এফোর্ট)।
mkdir -p ~/.local/share/fonts
font_archive=$(mktemp /tmp/ternux-jetbrainsmono.XXXXXX.tar.xz)
wget -q -O "$font_archive" \
  https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/JetBrainsMono.tar.xz \
  && echo "04d5e8f903693f9dd13e16f867e994834e681eb3c72c0d337a770dcda09010cf  $font_archive" | sha256sum -c - \
  && tar -xJf "$font_archive" -C ~/.local/share/fonts/ \
  && fc-cache -f
rm -f "$font_archive"

exit
```

---

## ধাপ ৮ — managed desktop চালু করুন

ইনস্টলার `~/x.sh` তৈরি ও রক্ষণাবেক্ষণ করে। readiness যাচাই এবং পুরোনো
launcher নিরাপদে refresh করার জন্য Ternux lifecycle manager দিয়ে desktop
চালু করুন:

```bash
ternux start
```

`x` shortcut একই command চালায়। Android shared storage default-এ mount হয়
না। দরকারি folder-এর জন্য `ternux storage grant /sdcard/Folder` চালান; অনুমতি
না থাকলে এটি Android storage permission চাইবে এবং নতুন guest session-এ শুধু ওই
folder mount করবে। নতুন grant চালু করতে চলমান desktop restart করতে হবে। পুরোনো `proot-distro login --shared-tmp` launcher example
`~/x.sh`-এ কপি করবেন না—ওগুলো PRoot-Distro-এর বিস্তৃত host mount ব্যবহার করে।
`ternux start` launcher missing বললে Ternux installer `ternux install` দিয়ে
resume করুন।

---

## ধাপ ৯ — শেল শর্টকাট

ইনস্টলার `x`, `killx`, `db`, `droot`, `xgo`, `clean-mesa` এবং `sysmon`
shortcut তৈরি ও রক্ষণাবেক্ষণ করে। Guest alias isolated PRoot binding ব্যবহার
করে, শুধু `ternux storage grant`-এ থাকা folder mount করে এবং দরকারে `/tmp` share করে। Alias তৈরি বা refresh
করতে `ternux install` চালান; পুরোনো guide-এর alias block কপি করবেন না।

রিলোড করে শুরু করুন:

```bash
source ~/.bashrc
```

```bash
x
```

---

## ধাপ ১০ — Android 12+ child-process setting check

```bash
getprop ro.build.version.sdk
settings get global settings_enable_monitor_phantom_procs
```

SDK ৩১+-এ `false`/`0` readable global monitor disabled, `true`/`1` enabled,
আর blank/unknown inconclusive। Signal 9 memory pressure বা OEM battery
management থেকেও আসতে পারে। প্রথমে Termux/Termux:X11 battery use Unrestricted
করুন ও build parallelism কমান। Evidence child-process restriction দেখালে
system-wide trade-off পড়ে release-এ exposed control ব্যবহার করুন:

- **Android 14+:** Developer options-এ **Disable child process restrictions**
  থাকতে পারে; OEM wording/availability বদলায়। Change-এর পর reboot।
- **Android 12L/13:** `adb shell settings put global settings_enable_monitor_phantom_procs false`
- **Android 12 exactly:** [Troubleshooting](TROUBLESHOOTING.html#the-desktop-dies-silently)-এর `device_config` control review করুন।
- **Rooted:** `su -c "settings put global settings_enable_monitor_phantom_procs false"`

Original value record করুন; abnormal battery drain বা instability হলে reverse করুন।

---

## ধাপ ১১ — পুরো স্ট্যাক যাচাই

```bash
# Termux পাশে
command -v termux-x11 proot-distro pulseaudio virgl_test_server_android
[ -x ~/x.sh ] && echo "launcher executable"

# Debian পাশে
proot-distro login debian --user ternux -- bash -c '
  command -v startxfce4 && command -v glxinfo && command -v pactl &&
  sudo -n true && echo "Debian core OK"'
```

ডেস্কটপ চলার পর (`x` চালিয়ে) ডেস্কটপের টার্মিনাল থেকে GPU প্রমাণ করুন:

```bash
glxinfo | grep "renderer string"
```

| Observation | ব্যাখ্যা |
|---|---|
| `zink … (MESA_TURNIP)` | পরীক্ষিত Adreno Zink/Turnip route detected |
| `virgl` / `virpipe` | compatibility route detected; host acceleration/workload আলাদা যাচাই করুন |
| `llvmpipe` | CPU software rendering |
| blank/error | display বা GL stack আগে diagnose করুন |

## ঐচ্ছিক tool ও release extension

এই command-by-command পথ Termux/PRoot desktop তৈরি করে; এটি Ternux-এর managed
host CLI install করে না। Debian package workload ও তার manual command-এর জন্য
[ওয়ার্কলোড guide](WORKLOADS.html) দেখুন। ADT-এর জন্য
[ADT setup অংশ](INSTALLATION.html#install-adt-tools-inside-the-ternux-debian-guest)
অনুসরণ করুন।

CPU + Vulkan prerelease-এর আলাদা
[manual, checksum-verified install guide](https://github.com/soobujmiah/ternux/blob/main/bn/guides/llama-vulkan-extension.md)
আছে। Experimental HTP package Termux host-এর `ternux extension install`
ব্যবহার করে; এটি এই manual-only setup-এর অংশ নয়। ব্যবহারের আগে
[HTP limit ও install guide](https://github.com/soobujmiah/ternux/blob/main/bn/guides/llama-htp-experimental.md)
পড়ুন। Stable Diffusion/QNN এখনও standalone experiment; Ternux installable
extension নয়।

---

## আনইনস্টল

One-command installer ব্যবহার করে Ternux CLI install করা থাকলে target ও
confirmation স্পষ্ট রাখতে তার scoped uninstaller ব্যবহার করুন:

```bash
ternux uninstall                 # interactive component choice
ternux uninstall container       # Debian data delete করার আগে confirm
ternux uninstall all             # Ternux CLI ও guest-সহ সব managed component
```

`container`/`all` Debian-এর ভেতরের সব data ধ্বংস করে। `all` Ternux host CLI ও
update backup-ও সরায়; Termux নিজে, shared package, অন্য PRoot guest এবং non-empty
capture folder থাকে। Automation-এ `--yes` শুধু explicit irreversible confirmation হিসেবে দিন।

উপরের manual-only ধাপগুলো CLI install করে না। Manual setup সরাতে Termux থেকে
scoped uninstaller চালান:

```bash
curl -fsSL https://soobujmiah.github.io/ternux/uninstall.sh | bash
```

এটি কোন অংশ সরাবেন তা জিজ্ঞেস করবে। Confirm করার আগে প্রতিটি target দেখে নিন।

---

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · Apache-2.0*
