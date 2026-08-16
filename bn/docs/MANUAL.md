---
title: "ম্যানুয়াল ইনস্টলেশন"
description: "ternux-এর প্রতিটি ধাপ হাতে-কলমে, কমান্ডে কমান্ডে — যারা পুরো নিয়ন্ত্রণ চান বা ইনস্টলার নিজেই ডিবাগ করতে চান, তাদের সম্পূর্ণ নির্দেশিকা।"
lang: "bn"
alt_url: "/docs/MANUAL.html"

---

# ম্যানুয়াল ইনস্টলেশন

এক-কমান্ড ইনস্টলার আসলে এই পাতাটাই, স্ক্রিপ্ট আকারে। এখানে সেই একই যাত্রা
**হাতে-কলমে, কমান্ডে কমান্ডে** — যারা প্রতিটি ধাপ দেখতে ও নিয়ন্ত্রণ করতে
চান, নেটওয়ার্ক সমস্যা ঘুরিয়ে কাজ করতে চান, বা ইনস্টলার কী করে সেটাই শিখতে
চান, তাদের জন্য। প্রতিটি ব্লক Termux-এ চালান, যতক্ষণ না ধাপে বলা হয় ভিন্ন
কোথাও।

**মাঝপথে কোনো ধাপ ব্যর্থ হলে:** নিচের প্রতিটি ধাপ স্বাধীন ও বারবার চালানো
নিরাপদ। হাতে করলে কোনো ধাপ স্বয়ংক্রিয়ভাবে বাদ পড়ে না — এটাই হাতে করার
উদ্দেশ্য — তবে কোনো ধাপ দুবার চালালে কিছুই ভাঙে না।

---

## ধাপ ১ — দুটি অ্যাপ ইনস্টল করুন

- **Termux** — [GitHub releases](https://github.com/termux/termux-app/releases)
  বা [F-Droid](https://f-droid.org/en/packages/com.termux/) থেকে।
  *কেন Play Store নয়?* সেই বিল্ডটি পরিত্যক্ত; এর প্যাকেজ রিপোজিটরি মৃত,
  তাই `pkg install` সবকিছুতে ব্যর্থ হয়।
- **Termux:X11** — [GitHub releases](https://github.com/termux/termux-x11/releases)
  থেকে। **একবার** খুলুন, তারপর রেখে দিন — প্রথম লঞ্চের পরই Android ডিসপ্লে
  সার্ভিসের অনুমতি দেয়।

---

## ধাপ ২ — Termux বেস প্যাকেজ

```bash
# Android একটি স্টোরেজ-অনুমতির ডায়ালগ দেখাবে — অনুমোদন করুন।
termux-setup-storage

# প্যাকেজ ইনডেক্স রিফ্রেশ ও আপগ্রেড।
pkg update -y
pkg upgrade -y

# X11 ও গ্রাফিক্স প্যাকেজ বহনকারী রিপোজিটরি।
pkg install x11-repo tur-repo -y

# ডিসপ্লে অ্যাপ সার্ভিস, অডিও, এবং কন্টেইনার ইঞ্জিন।
pkg install termux-x11-nightly -y
pkg install pulseaudio proot-distro -y

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

## ধাপ ৩ — Debian ইনস্টল

```bash
proot-distro install debian
```

*কেন PRoot?* এটি ইউজারস্পেসে রুট-সদৃশ Debian ইউজারল্যান্ড দেয় — বুটলোডার
আনলক নেই, root নেই, Android-এর জন্য ঝুঁকি নেই। "কন্টেইনার" আসলে Termux-এর
স্টোরেজের একটি ফোল্ডার।

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
apt install -y sudo nano dbus-x11 pulseaudio pulseaudio-utils x11-utils \
  mesa-utils libgl1-mesa-dri xfce4 xfce4-terminal vlc pm-utils colord

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

# ইউজার তৈরি (প্রম্পট এড়িয়ে — ডেস্কটপে পাসওয়ার্ড লাগে না)।
adduser --disabled-password --gecos "" "$USER_NAME"

# গ্রাফিক্স ও অডিও গ্রুপ।
usermod -aG sudo "$USER_NAME"
usermod -aG video "$USER_NAME"
usermod -aG render "$USER_NAME"
usermod -aG audio "$USER_NAME"

# যাচাইকৃত ড্রপ-ইন ফাইলে পাসওয়ার্ডবিহীন sudo। /etc/sudoers-এ সরাসরি জুড়বেন
# না: একটি টাইপোই sudo চিরতরে লক করতে পারে — এমন কন্টেইনারে যার রুটে যাওয়ার
# আর কোনো পথ নেই।
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

[lhfdevs/mesa-for-android-container → Releases](https://github.com/lfdevs/mesa-for-android-container/releases/latest)
থেকে Debian/arm64 ড্রাইভার অ্যাসেট নামান। রিলিজ পাতায় সেই অ্যাসেটের URL
কপি করুন যার নামে `debian` ও `arm64.tar.gz` আছে — Fedora বা Alpine টারবল
কখনোই নয়।

```bash
cd ~
curl -fLO "https://github.com/lfdevs/mesa-for-android-container/releases/latest/download/<ASSET-NAME>.tar.gz"
```

আপগ্রেডের পর curl লিংক না হলে wget দিয়েও একই কাজ:

```bash
wget -q "https://github.com/lfdevs/mesa-for-android-container/releases/latest/download/<ASSET-NAME>.tar.gz"
```

> চাইলে API দিয়েও রিজলভ করা যায়:
> `curl -fsSL https://api.github.com/repos/lfdevs/mesa-for-android-container/releases/latest`
> — সেখানে `debian…arm64.tar.gz` `browser_download_url` খুঁজুন।

এক্সট্র্যাক্টের আগে যাচাই করুন — অর্ধেক ডাউনলোড বা HTML এরর পেজ রুট হিসেবে
আনপ্যাক করা চলবে না:

```bash
# ১. এটি সত্যিকারের gzip টারবল হতে হবে:
tar -tzf mesa-freedreno.tar.gz >/dev/null && echo "valid tarball"

# ২. কোনো অ্যাবসোলিউট পাথ বা পাথ-ট্রাভার্সাল নয়:
tar -tzf mesa-freedreno.tar.gz | grep -E '^/|(^|/)\.\.(/|$)' && echo "UNSAFE - STOP" || echo "paths ok"

# ৩. কোনো লিংক বা স্পেশাল ফাইল নয় (প্রথম কলাম - বা d হতে হবে):
tar -tvzf mesa-freedreno.tar.gz | awk '{t=substr($1,1,1); if (t!="-" && t!="d") exit 1}' && echo "entries ok"

# ৪. নিজের রেকর্ডের জন্য SHA-256 লিখে রাখুন:
sha256sum mesa-freedreno.tar.gz
```

ternux-এর দরকারি **শুধু দুটি ফাইল** এক্সট্র্যাক্ট করুন — Turnip ড্রাইভার ও
তার ICD ম্যানিফেস্ট — তারপর ইনস্টল করে Mesa হোল্ড করুন, যাতে সাধারণ `apt
upgrade` নিঃশব্দে GPU পথ বদলে দিতে না পারে:

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

base="$(find "$stage" -mindepth 1 -maxdepth 1 -type d | head -n1)"
[ -f "$base/usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so" ] \
  || { echo "driver missing from archive"; exit 1; }

cp -a "$base/usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so" \
      /usr/lib/aarch64-linux-gnu/
mkdir -p /usr/share/vulkan/icd.d
cp -a "$base/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json" \
      /usr/share/vulkan/icd.d/
ldconfig

# Mesa পিন করুন: "রেন্ডারার llvmpipe-তে ফিরে গেল" সমস্যার এক নম্বর কারণ আপগ্রেড।
apt-mark hold mesa-vulkan-drivers libgl1-mesa-dri libglx-mesa0 \
             libgbm1 libegl-mesa0

exit
```

ফাইল সত্যিই বসেছে কিনা নিশ্চিত হোন:

```bash
proot-distro login debian -- bash -c '
  test -f /usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so &&
  test -f /usr/share/vulkan/icd.d/freedreno_icd.aarch64.json &&
  echo "Turnip installed"'
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
cat >> "$PREFIX/etc/pulse/default.pa" << 'EOF'
load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 port=4713
load-module module-opensles-sink sink_name=Speaker
set-default-sink Speaker
EOF
```

*কেন শুধু লুপব্যাক?* শব্দ TCP দিয়ে কন্টেইনার সীমানা পাড়ি দেয়, তাই
অ্যানোনিমাস ACL দরকার — `127.0.0.1` মাইক্রোফোনকে নেটওয়ার্ক থেকে দূরে রাখে।

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
mkdir -p ~/.config/pulse
echo 'default-server = tcp:127.0.0.1:4713' > ~/.config/pulse/client.conf

# টার্মিনাল আইকন গ্লিফের জন্য Nerd Font (বেস্ট-এফোর্ট)।
mkdir -p ~/.local/share/fonts
wget -q -O /tmp/font.zip \
  https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip \
  && unzip -oq /tmp/font.zip -d ~/.local/share/fonts/ \
  && fc-cache -f
rm -f /tmp/font.zip

exit
```

---

## ধাপ ৮ — লঞ্চার (`~/x.sh`)

ইনস্টলার যে ফাইলটি তৈরি করে, এটি সেই ফাইল। হাতে বানান:

```bash
nano ~/x.sh
```

আপনার পথের কনটেন্ট পেস্ট করুন, সেভ করুন, তারপর:

```bash
chmod +x ~/x.sh
```

### ৮ক — Zink (Adreno) লঞ্চার

```bash
#!/data/data/com.termux/files/usr/bin/bash
# ternux launcher — Zink/Turnip route (Adreno)
set -u

TMPDIR="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"

# আগের সেশন পরিষ্কার
pkill -9 -f termux-x11 2>/dev/null || true
pkill -9 -f virgl_test_server 2>/dev/null || true
pkill -9 -f dbus-daemon 2>/dev/null || true
pkill -9 -f dbus-launch 2>/dev/null || true
pulseaudio --kill 2>/dev/null || true
pkill -9 -f pulseaudio 2>/dev/null || true
rm -rf $TMPDIR/.X11-unix/X* $TMPDIR/.X*-lock $TMPDIR/pulse-socket 2>/dev/null || true

# Android যেন সেশন সাসপেন্ড না করে
termux-wake-lock 2>/dev/null || true

# অডিও
unset PULSE_SERVER
pulseaudio --start --exit-idle-time=-1 --daemonize 2>/dev/null || true
sleep 0.3
pactl load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 port=4713 \
  >/dev/null 2>&1 || true

# ডিসপ্লে
termux-x11 :0 -ac &
X11_PID=$!
echo "Waiting for Termux-X11 display socket..."
WAITED=0
while [ ! -e "$TMPDIR/.X11-unix/X0" ]; do
  if ! kill -0 "$X11_PID" 2>/dev/null; then
    echo "ERROR: termux-x11 exited before creating its socket."
    echo "       Open the Termux:X11 app once, then run this again."
    exit 1
  fi
  if [ "$WAITED" -ge 300 ]; then
    echo "ERROR: timed out after 30s waiting for display :0."
    exit 1
  fi
  WAITED=$((WAITED + 1))
  sleep 0.1
done
echo "Display :0 ready."

# ডেস্কটপ
proot-distro login debian --shared-tmp \
  --bind /dev/kgsl-3d0:/dev/kgsl \
  --bind /dev/dri \
  --user ternux -- env \
  DISPLAY=:0 \
  PULSE_SERVER=tcp:127.0.0.1:4713 \
  AUDIODRIVER=pulse \
  MESA_LOADER_DRIVER_OVERRIDE=zink \
  GALLIUM_DRIVER=zink \
  TU_DEBUG=sysmem,noconform \
  MESA_VK_WSI_DEBUG=sw \
  MESA_DISK_CACHE_SINGLE_FILE=1 \
  MESA_SHADER_CACHE_MAX_SIZE=2048M \
  MESA_SHADER_CACHE_DIR=/tmp/mesa_cache \
  QT_X11_NO_MITSHM=1 \
  _X11_NO_MITSHM=1 \
  XDG_RUNTIME_DIR=/home/ternux/.runtime \
  LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
  bash -c '
    set -u
    mkdir -p ~/.runtime && chmod 700 ~/.runtime
    mkdir -p /tmp/mesa_cache && chmod 700 /tmp/mesa_cache

    until xdpyinfo -display :0 >/dev/null 2>&1; do sleep 0.1; done

    sudo -n mkdir -p /var/run/dbus /run/dbus 2>/dev/null || true
    sudo -n dbus-uuidgen --ensure >/dev/null 2>&1 || true
    sudo -n dbus-daemon --system --fork >/dev/null 2>&1 || true
    sudo -n rm -f /etc/xdg/autostart/light-locker.desktop 2>/dev/null || true

    mkdir -p ~/.config/pulse
    echo "default-server = tcp:127.0.0.1:4713" > ~/.config/pulse/client.conf

    xfconf-query -c xfwm4 -p /general/use_compositing -s false >/dev/null 2>&1 || true
    xfconf-query -c xfwm4 -p /general/vblank_mode -s off      >/dev/null 2>&1 || true

    exec dbus-launch --exit-with-session startxfce4
  '

# টিয়ারডাউন
pkill -9 -f termux-x11 2>/dev/null || true
pkill -9 -f virgl_test_server 2>/dev/null || true
termux-wake-unlock 2>/dev/null || true
```

### ৮খ — VirGL সংস্করণ: মাত্র দুটি বদল

ওপরের ফাইলটি থেকে শুরু করে **দুটি এডিট** করুন:

1. `echo "Display :0 ready."` আর `# Desktop`-এর মাঝে এই ব্লকটি ঢোকান:

```bash
virgl_test_server_android >/dev/null 2>&1 &
VIRGL_PID=$!
sleep 1
if ! kill -0 "$VIRGL_PID" 2>/dev/null; then
  echo "WARNING: virgl_test_server_android failed to start."
  echo "         Rendering will fall back to software (llvmpipe)."
fi
```

2. পুরো `--bind … LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8` আর্গুমেন্ট ব্লকের
বদলে দিন:

```bash
  --user ternux -- env \
  DISPLAY=:0 \
  PULSE_SERVER=tcp:127.0.0.1:4713 \
  AUDIODRIVER=pulse \
  GALLIUM_DRIVER=virpipe \
  MESA_GL_VERSION_OVERRIDE=4.3COMPAT \
  MESA_GLES_VERSION_OVERRIDE=3.2 \
  QT_X11_NO_MITSHM=1 \
  _X11_NO_MITSHM=1 \
  XDG_RUNTIME_DIR=/home/ternux/.runtime \
  LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
```

শেষ ফাইলটি সিনট্যাক্স-চেক করুন:

```bash
bash -n ~/x.sh && echo "launcher ok"
```

---

## ধাপ ৯ — শেল শর্টকাট

```bash
cat >> ~/.bashrc << 'EOF'

# ==== TERNUX ALIASES ====
alias x='~/x.sh'
alias killx='pkill -f termux-x11; pkill -f pulseaudio; pkill -f dbus; \
  rm -rf $TMPDIR/.X11-unix/X* $TMPDIR/.X*-lock'
alias db='proot-distro login debian --user ternux'
alias droot='proot-distro login debian'
alias xgo='am start -n com.termux.x11/com.termux.x11.MainActivity 2>/dev/null; sleep 1; ~/x.sh'
clean-mesa() {
  proot-distro login debian --user ternux -- bash -c 'rm -rf ~/.cache/mesa/*'
  echo "Mesa cache cleared."
}
sysmon() {
  echo "--- CPU & Memory ---"; free -h
  echo ""; echo "--- GPU / KGSL Nodes ---"
  ls -l /dev/kgsl-3d0 /dev/dri 2>/dev/null || echo "Direct GPU nodes not available."
}
# ==== END TERNUX ALIASES ====
EOF
```

রিলোড করে শুরু করুন:

```bash
source ~/.bashrc
x
```

---

## ধাপ ১০ — Android 12+ ফ্যান্টম-কিলার চেক

```bash
getprop ro.build.version.sdk
settings get global settings_enable_monitor_phantom_procs
```

SDK **৩১ বা তার বেশি** এবং সেটিংটি `false` না হলে Android নিঃশব্দে ডেস্কটপ
SIGKILL করতে পারে। ভার্সন অনুযায়ী সমাধান:

- **Android 14+:** Settings → Developer options → **Disable child process
  restrictions** → রিবুট।
- **Android 12L/13:** `adb shell settings put global settings_enable_monitor_phantom_procs false`
- **রুটেড:** `su -c "settings put global settings_enable_monitor_phantom_procs false"`

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

| ভালো | খারাপ |
|---|---|
| `zink Vulkan (Adreno (TM) … (MESA_TURNIP))` | `llvmpipe` — সফটওয়্যার রেন্ডারিং |
| `virgl` (সামঞ্জস্য পথ) | ফাঁকা উত্তর |

---

## হাতে-কলমে আনইনস্টল

```bash
killx
rm -f ~/x.sh ~/.ternux-state
sed -i '/# ==== TERNUX ALIASES/,/# ==== END TERNUX ALIASES/d' ~/.bashrc
proot-distro remove debian        # কন্টেইনারের ভেতরের সব ডেটা ধ্বংস হয়
```

---

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · MIT*
