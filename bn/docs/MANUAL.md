---
title: "ম্যানুয়াল ইনস্টলেশন"
description: "ternux-এর প্রতিটি ধাপ হাতে-কলমে, কমান্ডে কমান্ডে — যারা পুরো নিয়ন্ত্রণ চান বা ইনস্টলার নিজেই ডিবাগ করতে চান, তাদের সম্পূর্ণ নির্দেশিকা।"
lang: "bn"
alt_url: "/docs/MANUAL.html"

---

এক-কমান্ড ইনস্টলার আসলে এই পাতাটিই, স্ক্রিপ্ট আকারে। এখানে সেই একই যাত্রা
**হাতে-কলমে, কমান্ডে কমান্ডে** — যারা প্রতিটি ধাপ দেখতে ও নিয়ন্ত্রণ করতে
চান, নেটওয়ার্ক সমস্যা ঘুরিয়ে কাজ করতে চান, বা ইনস্টলার কী করে সেটাই শিখতে
চান, তাদের জন্য। ধাপে ভিন্ন কোথাও চালাতে না বললে প্রতিটি নির্দেশনার ব্লক
টার্মাক্সে চালান।

**মাঝপথে কোনো ধাপ ব্যর্থ হলে:** থামুন, কারণ নির্ণয় করুন, তারপর এগোন।
প্রতিটি ব্লক আবার চালানোর আগে পড়ুন: যেখানে সম্ভব আগাম যাচাই ও সুরক্ষা রাখা
হয়েছে, কিন্তু হাতে চালানো প্যাকেজ, ব্যবহারকারী ও ফাইলের কাজ সব সময়
পুনরায় নিরাপদে চালানো যায় না। এই নির্দেশিকায় `ternux`-কে ডেবিয়ান
হিসাব-নাম ধরা হয়েছে; অন্য বৈধ ছোট হাতের নাম নিলে পরের সব `ternux`
লেখা একই নামে বদলান।

---

## ধাপ ১ — দুটি অ্যাপ ইনস্টল করুন

- **টার্মাক্স** — [গিটহাবের প্রকাশনা](https://github.com/termux/termux-app/releases)
  অথবা [এফ-ড্রয়েড](https://f-droid.org/en/packages/com.termux/) থেকে নিন।
  গুগল প্লের বিল্ড আলাদা পরীক্ষামূলক অ্যান্ড্রয়েড ১১-পরবর্তী ধারা; এতে
  সুবিধা ও ত্রুটির পার্থক্য রয়েছে। এই নির্দেশিকা এফ-ড্রয়েড/গিটহাবের মূল
  প্রকাশনা-ধারা ধরে। টার্মাক্স:এপিআই ও অন্য প্লাগইন **টার্মাক্সের একই উৎস**
  থেকে নিন, যাতে স্বাক্ষর-চাবি মেলে।
- **টার্মাক্স:এক্স১১** — [গিটহাবের প্রকাশনা](https://github.com/termux/termux-x11/releases)
  থেকে নিন। **একবার** খুলে রাখুন—প্রথমবার চালানোর পরই অ্যান্ড্রয়েড
  ডিসপ্লে-সেবার অনুমতি দেয়।

---

## ধাপ ২ — টার্মাক্সের মূল প্যাকেজ

```bash
# প্যাকেজ ইনডেক্স রিফ্রেশ ও আপগ্রেড।
apt update && apt full-upgrade -y

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

শুধু অ্যাড্রেনো যন্ত্রে (কোয়ালকম জিপিইউ—`ls -l /dev/kgsl-3d0` দিয়ে দেখুন):

```bash
pkg install mesa-vulkan-icd-freedreno -y
```

> `/dev/kgsl-3d0` না থাকলে ফ্রিড্রেনো আইসিডি বাদ দিন: আপনার যন্ত্র ভিরজিএল
> পথে চলবে, সেখানে এই প্যাকেজের প্রয়োজন নেই।

তিনটি জরুরি বাইনারি সত্যিই ইনস্টল হয়েছে কি না যাচাই করুন:

```bash
command -v proot-distro && command -v termux-x11 && command -v pulseaudio
```

---


ডেবিয়ান ডেস্কটপে টার্নাক্স ক্যামেরা ও টার্নাক্স শব্দ-রেকর্ডার থাকে।
অ্যান্ড্রয়েডের সামনের বা পেছনের ক্যামেরায় ছবি তুলতে টার্মাক্সের **একই
উৎসের টার্মাক্স:এপিআই অ্যান্ড্রয়েড অ্যাপ** বসান। অনুমতি দেওয়ার আগেও
ক্যামেরা শনাক্ত করা যায়। ছবি তুলতে অনুমতির ত্রুটি এলে অ্যান্ড্রয়েডের
সেটিংস → অ্যাপ → টার্মাক্স:এপিআই → অনুমতি → ক্যামেরা খুলে অনুমতি দিয়ে
আবার চেষ্টা করুন। টার্নাক্স ক্যামেরা প্রথমে ছবিটি টার্মাক্স অ্যাপের
ব্যক্তিগত সংরক্ষণস্থলে রাখে, যাচাই করে, তারপর ডেবিয়ান পিআররুটের
`/home/ternux/Pictures/Ternux`-এ (অথবা নির্বাচিত গেস্ট ব্যবহারকারীর
ব্যক্তিগত ডিরেক্টরিতে) সংরক্ষণ করে। ছবি অ্যান্ড্রয়েড গ্যালারিতে যোগ হয়
না। ক্যামেরা অ্যাপের টর্চ-সুইচ ও টার্নাক্স টর্চ ডেস্কটপ শর্টকাট
টার্মাক্স:এপিআই টর্চ ব্যবহার করে; যন্ত্রে ক্যামেরার ফ্ল্যাশ না থাকলে এটি
কাজ করবে না। এটি একটানা জ্বলা টর্চ—ছবি তোলার সময় বন্ধ হয়, কারণ
টার্মাক্স:এপিআই-এর স্থির-ছবি তোলার ব্যবস্থায় ফ্ল্যাশ নিয়ন্ত্রণ নেই।
পূর্বরূপে ছবির এক্সিফ ঘূর্ণন-তথ্য মানা হয় এবং ধারণের নিয়ন্ত্রণগুলো ছোট
রাখা হয়েছে। টার্মাক্স:এপিআই ক্যামেরার তথ্য ও স্থির ছবি দেয়, একটানা
ক্যামেরা-দৃশ্য নয়; তাই ছবি তোলার আগে অ্যাপে সরাসরি দৃশ্য দেখানো হয় না।
শব্দ-রেকর্ডারে **শুরু** চাপলেই টার্মাক্স:এপিআই মাইক্রোফোন চালু হয়। সেটআপের
সময়ে টার্মাক্স:এপিআই থাকলে মাইক্রোফোনের অনুমতি চাওয়া হয়; না থাকলে
প্রথমবার ব্যবহারের সময় অ্যান্ড্রয়েড অনুমতি চাইবে। ধারণের আগে এএসি/এম৪এ
(পূর্বনির্ধারিত) অথবা এমপিথ্রি বেছে নিন।
**থামিয়ে সংরক্ষণ** করলে নির্বাচিত ধরনে ডেবিয়ান ব্যবহারকারীর
`~/Music/Ternux`-এ ফাইল রাখা হয়। অ্যান্ড্রয়েডে শব্দ এএসি-তে ধারণ হয়;
এমপিথ্রি হলে ডেবিয়ানের এফএফএমপেগ দিয়ে স্থানীয়ভাবে রূপান্তর করা হয়।

টার্মাক্স:এপিআই ও টার্মাক্স:বুট ঐচ্ছিক; টার্নাক্স বসাতে বা চালাতে কোনোটিই
প্রয়োজন নেই। টার্মাক্স:এপিআই অ্যাপ না থাকলে সেটআপ তার অনুমতির অনুরোধ
বাদ দেয়। ডেস্কটপের সরাসরি মাইক্রোফোন টার্মাক্সের ওপেন-এসএল-ইএস সেতু দিয়ে
চলে; প্রথমবার ধারণের সময় টার্মাক্সের অনুমতি চাইতে পারে। এপিআই ছাড়া ছবি
তুলতে অ্যান্ড্রয়েড ক্যামেরা ব্যবহার করুন, তারপর থুনারে `/sdcard/DCIM/Camera`
খুলুন; ডিরেক্টরিটি না এলে টার্মাক্সে `termux-setup-storage` চালান। টার্নাক্স
ক্যামেরা, শব্দ-রেকর্ডার বা এপিআই-ভিত্তিক অন্য সুবিধা চাইলে তবেই টার্মাক্সের
একই উৎস থেকে টার্মাক্স:এপিআই বসান।

## ধাপ ৩ — ডেবিয়ান ইনস্টল

```bash
proot-distro install debian
```

*পিআররুট কেন?* এটি ব্যবহারকারী-পরিসরে রুটের মতো ডেবিয়ান পরিবেশ দেয়—
বুটলোডার আনলক বা অ্যান্ড্রয়েডে রুট লাগে না। তবে পিআররুট নিরাপত্তা-সীমানা
নয়; টার্মাক্স থেকে পাওয়া যায় বা স্পষ্টভাবে যুক্ত করা পথ গেস্ট থেকেও
পাওয়া যায়। তথ্য মুছে যেতে পারে এমন কাজের আগে ব্যাকআপ নিন।

---

## ধাপ ৪ — ডেবিয়ানের ভেতরে ডেস্কটপ প্যাকেজ

রুট ব্যবহারকারী হিসেবে কন্টেইনারে ঢুকে এক্সএফসিই ৪ ও জিএল/শব্দ-সংযোগ বসান:

```bash
proot-distro login debian
```

```bash
export DEBIAN_FRONTEND=noninteractive
apt update

# মূল ডেস্কটপ ও জিএল/শব্দ। এই ধাপ সফল হওয়া আবশ্যক।
apt install -y sudo nano mousepad fonts-noto-core python3-gi python3-xlib gir1.2-gtk-3.0 ibus ibus-avro devilspie2 dbus-x11 pulseaudio pulseaudio-utils pavucontrol x11-utils mesa-utils libgl1-mesa-dri adwaita-icon-theme xfce4 xfce4-taskmanager xfce4-terminal zenity vlc ristretto qt5-gtk-platformtheme arc-theme colord

# পলিসিকিট: trixie বা নতুন সংস্করণে polkitd, bookworm-এ policykit-1। যথাসাধ্য চেষ্টা।
apt install -y polkitd || apt install -y policykit-1 || true

# স্পষ্ট ভলকান লোডার (Zink চালুর সময় libvulkan.so.1 খোলে) ও সরঞ্জাম।
apt install -y libvulkan1 vulkan-tools || true

# আর্কাইভ সরঞ্জাম। যথাসাধ্য চেষ্টা—rar/p7zip-rar ডেবিয়ান non-free-তে থাকে।
apt install -y zip unzip xarchiver unrar-free || true
apt install -y 7zip || apt install -y p7zip-full || true

exit
```

---

## ধাপ ৫ — আপনার ব্যবহারকারী তৈরি (নিরাপদ সুডোসহ)

```bash
proot-distro login debian
```

```bash
USER_NAME=ternux

# ব্যবহারকারী না থাকলে তৈরি করুন (ডেস্কটপ অ্যাকাউন্টে প্রবেশের পাসওয়ার্ড লাগে না)।
id -u "$USER_NAME" >/dev/null 2>&1 \
  || adduser --disabled-password --gecos "" "$USER_NAME"

# গ্রাফিক্স ও শব্দের দল।
usermod -aG sudo "$USER_NAME"
usermod -aG video "$USER_NAME"
usermod -aG render "$USER_NAME"
usermod -aG audio "$USER_NAME"

# যাচাইকৃত অতিরিক্ত ফাইলে পাসওয়ার্ডবিহীন সুডো। /etc/sudoers-এ সরাসরি জুড়বেন
# না: একটি বানানভুলে এই হিসাব-নামের সুডো নষ্ট হতে পারে। PRoot Distro দিয়ে
# গেস্টের রুট মেরামতি শেল খোলা যায়; সেটি অ্যান্ড্রয়েডের রুট নয়।
TMP_SUDOERS="$(mktemp)"
printf '%s ALL=(ALL) NOPASSWD: ALL\n' "$USER_NAME" > "$TMP_SUDOERS"
visudo -cf "$TMP_SUDOERS" \
  && install -m 0440 -o root -g root "$TMP_SUDOERS" /etc/sudoers.d/ternux
rm -f "$TMP_SUDOERS"

exit
```

এটি কাজ করছে কি না যাচাই করুন। এই যাচাই ব্যর্থ হলে পরে লঞ্চার কোনো বার্তা
ছাড়াই আটকে যেতে পারে:

```bash
proot-distro login debian --user ternux -- sudo -n true
```

---

## ধাপ ৬ — জিপিইউ ড্রাইভার

### আপনার গ্রাফিক্স-পথ শনাক্ত করুন

```bash
ls -l /dev/kgsl-3d0
```

- **ফাইল আছে** → অ্যাড্রেনো → *৬ক—জিঙ্ক/টার্নিপ*-এ যান।
- **নেই** → মালি/এক্সক্লিপস/পাওয়ারভিআর → *৬খ—ভিরজিএল*-এ যান।

### ৬ক — জিঙ্ক ও টার্নিপ (অ্যাড্রেনো)

টার্নাক্স ডেবিয়ানে মেলা এআরএম৬৪ টার্নিপ আর্কাইভ বেছে চেকসম যাচাই করে,
মূল প্রকল্পের লাইসেন্স-নোটিশ রেখে দেয় এবং পরিচালিত `/usr/local` বিন্যাসে
ইনস্টল করে। সাধারণ ইনস্টলার চালান:

```bash
tx install --distro debian
```

মেসা প্যাকেজ কখনো `/usr`-এ খুলবেন না বা গেস্টের প্যাকেজ ব্যবস্থাপকের
মালিকানাধীন ফাইল বদলাবেন না। পুরোনো ইনস্টলেশন হাতে মেরামত করতে
[এপিটি-নিরাপদ গ্রাফিক্স স্থানান্তর নির্দেশিকা](GRAPHICS-PERSISTENCE.html)
দেখুন; সেখানে প্যাকেজের অখণ্ডতা ও সচল ভলকান রেন্ডারার যাচাইয়ের ধাপ আছে।

### ৬খ — ভিরজিএল (অন্য জিপিইউ)

কিছু ইনস্টল করতে হবে না—শুধু হোস্ট রেন্ডারার আছে কি না যাচাই করুন:

```bash
command -v virgl_test_server_android && echo "VirGL ready"
```

---

## ধাপ ৭ — শব্দ, ভাষা-অঞ্চল ও হরফ

### ৭ক — শব্দ-সেতু (টার্মাক্স পাশে)

পালসঅডিওর বিন্যাসে শুধু স্থানীয় যন্ত্রে শোনা যায় এমন টিসিপি সেতু যোগ করুন:

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
    echo "Custom PulseAudio TCP module found; review it instead of overwriting it." >&2
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

*শুধু লুপব্যাক কেন?* টিসিপি দিয়ে শব্দ কন্টেইনারের সীমানা পার হয়।
`listen=127.0.0.1` সেবাটিকে স্থানীয় নেটওয়ার্ক থেকে আড়ালে রাখে; একই
যন্ত্রের নামহীন ক্লায়েন্ট তবুও এতে পৌঁছাতে পারে, তাই বাঁধাই-ঠিকানা বদলাবেন না।

টার্নাক্স অ্যান্ড্রয়েড ওপেন-এসএল-ইএস মাইক্রোফোন উৎসটি
`Ternux_Microphone` নামে চালু করে; ডেস্কটপের কোনো শব্দ-অ্যাপ ধারণ শুরু
করলেই এটি সক্রিয় হয়। অনুমতি অ্যান্ড্রয়েড নিয়ন্ত্রণ করে। ধারণের অনুমতি
না পেলে অ্যান্ড্রয়েডের সেটিংসে টার্মাক্স অ্যাপের **মাইক্রোফোন** অনুমতি
দিয়ে আবার চেষ্টা করুন। এক্সএফসিইতে **পালসঅডিও শব্দমাত্রা নিয়ন্ত্রণ →
ইনপুট যন্ত্র** খুলে `Ternux_Microphone` বেছে নিন। ধারণ চললে অ্যান্ড্রয়েডের
মাইক্রোফোন গোপনীয়তা-চিহ্ন দেখা যায়। বর্তমান টার্মাক্স:এপিআই-এর
`termux-microphone-record` কমান্ড ফাইলে শব্দ ধারণ করে; এটি ডেস্কটপ অ্যাপের
সরাসরি পালসঅডিও মাইক্রোফোন উৎস দেয় না। তাই টার্নাক্স ওই কমান্ডকে ডেস্কটপে
সরাসরি শব্দ ধারণের পথ বলে না।

### ৭খ — ভাষা-অঞ্চল ও হরফ (ডেবিয়ানের ভেতরে)

```bash
proot-distro login debian --user ternux
```

```bash
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt install -y locales
grep -qxF 'en_US.UTF-8 UTF-8' /etc/locale.gen \
  || echo 'en_US.UTF-8 UTF-8' | sudo tee -a /etc/locale.gen >/dev/null
sudo locale-gen en_US.UTF-8
grep -qxF 'export LANG=en_US.UTF-8' ~/.bashrc \
  || echo 'export LANG=en_US.UTF-8' >> ~/.bashrc
grep -qxF 'export LC_ALL=en_US.UTF-8' ~/.bashrc \
  || echo 'export LC_ALL=en_US.UTF-8' >> ~/.bashrc

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

## ধাপ ৮ — পরিচালিত ডেস্কটপ চালু করুন

ইনস্টলার `~/x.sh` তৈরি ও রক্ষণাবেক্ষণ করে। প্রস্তুতি যাচাই ও পুরোনো
লঞ্চার নিরাপদে নবায়নের জন্য টার্নাক্সের অধিবেশন-ব্যবস্থাপক দিয়ে ডেস্কটপ
চালু করুন:

```bash
ternux start
```

`tx start` একই পরিচালিত ডেস্কটপ-চালুর ধাপ চালায়। টার্মাক্সে অ্যান্ড্রয়েডের
সংরক্ষণ-অনুমতি থাকলে পরিচালিত গেস্টে ভাগ করা সংরক্ষণস্থান পূর্বনির্ধারিতভাবে
`/sdcard`-এ যুক্ত হয়। পথটি না থাকলে টার্মাক্সে `termux-setup-storage`
চালিয়ে ডেস্কটপ আবার চালু করুন। পুরোনো
`proot-distro login --shared-tmp` লঞ্চার উদাহরণ `~/x.sh`-এ কপি করবেন না—
সেগুলো পিআররুট-ডিস্ট্রোর বিস্তৃত হোস্ট পথ যুক্ত করে। `ternux start` লঞ্চার
না পেলে `ternux install` দিয়ে টার্নাক্স ইনস্টলার আবার চালান।

---

## ধাপ ৯ — শেল শর্টকাট

ইনস্টলার `tx`, `killx`, `db`/`dbroot`, `ub`/`ubroot`, `alp`/`alproot`, `xgo`,
`clean-mesa` ও `sysmon` শর্টকাট তৈরি ও রক্ষণাবেক্ষণ করে। গেস্টের নামগুলো
আলাদা পিআররুট বাঁধাই ব্যবহার করে, অ্যান্ড্রয়েডের ভাগ করা সংরক্ষণস্থান
`/sdcard`-এ যুক্ত করে এবং প্রয়োজন হলেই `/tmp` ভাগ করে। শর্টকাট তৈরি বা
নবায়ন করতে `ternux install` চালান; পুরোনো নির্দেশিকার শর্টকাটের ব্লক কপি
করবেন না।

শেল বিন্যাস আবার পড়ে ডেস্কটপ চালান:

```bash
source ~/.bashrc
```

```bash
tx start
```

---

## ধাপ ১০ — অ্যান্ড্রয়েড ১২ বা নতুন সংস্করণে শিশু-প্রক্রিয়া-নিয়ন্ত্রণ যাচাই

```bash
getprop ro.build.version.sdk
settings get global settings_enable_monitor_phantom_procs
```

এসডিকে ৩১ বা নতুন সংস্করণে `false`/`0` মানে পাঠযোগ্য বৈশ্বিক পর্যবেক্ষক
বন্ধ, `true`/`1` মানে চালু; ফাঁকা বা অজানা ফল থেকে সিদ্ধান্তে পৌঁছানো যায়
না। সিগন্যাল ৯ মেমরির চাপ বা নির্মাতার ব্যাটারি-ব্যবস্থাপনা থেকেও আসতে
পারে। আগে টার্মাক্স/টার্মাক্স:এক্স১১-এর ব্যাটারি ব্যবহার **সীমাহীন** করুন
এবং একসঙ্গে নির্মাণের কাজ কমান। প্রমাণে শিশু-প্রক্রিয়া সীমাবদ্ধতা দেখা
গেলে গোটা ব্যবস্থায় এর প্রভাব পড়ে—সেটি পড়ে তারপর প্রকাশিত নিয়ন্ত্রণ
ব্যবহার করুন:

- **অ্যান্ড্রয়েড ১৪ বা নতুন:** নির্মাতা-বিকল্পে
  **শিশু-প্রক্রিয়া সীমাবদ্ধতা বন্ধ করুন** থাকতে পারে; নির্মাতা অনুযায়ী
  নাম ও প্রাপ্যতা বদলায়। পরিবর্তনের পর যন্ত্র আবার চালু করুন।
- **অ্যান্ড্রয়েড ১২এল/১৩:** `adb shell settings put global settings_enable_monitor_phantom_procs false`
- **শুধু অ্যান্ড্রয়েড ১২:** [সমস্যা সমাধান](TROUBLESHOOTING.html#the-desktop-dies-silently)-এ থাকা `device_config` নিয়ন্ত্রণ পর্যালোচনা করুন।
- **রুট করা যন্ত্র:** `su -c "settings put global settings_enable_monitor_phantom_procs false"`

মূল মান লিখে রাখুন; ব্যাটারির অস্বাভাবিক ক্ষয় বা অস্থিতিশীলতা দেখা দিলে
পরিবর্তনটি ফিরিয়ে দিন।

---

## ধাপ ১১ — পুরো ব্যবস্থার স্তরগুলো যাচাই

```bash
# টার্মাক্স পাশে
command -v termux-x11 proot-distro pulseaudio virgl_test_server_android
[ -x ~/x.sh ] && echo "launcher executable"

# ডেবিয়ান পাশে
proot-distro login debian --user ternux -- bash -c '
  command -v startxfce4 && command -v glxinfo && command -v pactl &&
  sudo -n true && echo "Debian core OK"'
```

ডেস্কটপ চালু হলে (`tx start` চালিয়ে) ডেস্কটপ টার্মিনাল থেকে জিপিইউ
রেন্ডারারের তথ্য দেখুন:

```bash
glxinfo | grep "renderer string"
```

| দেখা ফল | ব্যাখ্যা |
|---|---|
| `zink … (MESA_TURNIP)` | পরীক্ষিত অ্যাড্রেনো জিঙ্ক/টার্নিপ পথ শনাক্ত হয়েছে |
| `virgl` / `virpipe` | সামঞ্জস্য-পথ শনাক্ত; হোস্টের ত্বরণ ও কাজের চাপ আলাদা যাচাই করুন |
| `llvmpipe` | প্রসেসরে সফটওয়্যার দিয়ে রেন্ডার হচ্ছে |
| ফাঁকা/ত্রুটি | আগে ডিসপ্লে বা জিএল ব্যবস্থা পরীক্ষা করুন |

## ঐচ্ছিক সরঞ্জাম ও প্রকাশিত এক্সটেনশন

এই কমান্ডে-কমানে পথ টার্মাক্স/পিআররুট ডেস্কটপ তৈরি করে; এটি টার্নাক্সের
পরিচালিত হোস্ট কমান্ড-লাইন সরঞ্জাম বসায় না। ডেবিয়ান প্যাকেজের কাজ ও তার
হাতে চালানোর নির্দেশের জন্য [কাজের ধরন নির্দেশিকা](WORKLOADS.html) দেখুন।
এডিটি বসাতে
[এডিটি স্থাপনের অংশ](INSTALLATION.html#install-adt-tools-inside-the-ternux-debian-guest)
অনুসরণ করুন।

সিপিইউ ও ভলকান প্রাক্‌প্রকাশনা বসানোর আলাদা
[হাতে চালানোর, চেকসম-যাচাইকৃত নির্দেশিকা](https://github.com/soobujmiah/ternux/blob/main/bn/guides/llama-vulkan-extension.md)
আছে। পরীক্ষামূলক এইচটিপি প্যাকেজ টার্মাক্স হোস্টের
`ternux extension install` ব্যবহার করে; এটি শুধু হাতে সেটআপের অংশ নয়।
ব্যবহারের আগে
[এইচটিপির সীমা ও ইনস্টল নির্দেশিকা](https://github.com/soobujmiah/ternux/blob/main/bn/guides/llama-htp-experimental.md)
পড়ুন। স্টেবল ডিফিউশন/কিউএনএন এখনো আলাদা পরীক্ষা; টার্নাক্সে ইনস্টলযোগ্য
এক্সটেনশন নয়।

---

## আনইনস্টল

এক-কমান্ড ইনস্টলার দিয়ে টার্নাক্সের কমান্ড-লাইন সরঞ্জাম বসানো থাকলে
কোন অংশ সরাবেন ও নিশ্চিতকরণ—দুটিই স্পষ্ট রাখতে এর নির্দিষ্ট অপসারণ-সরঞ্জাম
ব্যবহার করুন:

```bash
ternux uninstall                 # অংশ বেছে নেওয়ার তালিকা
ternux uninstall container       # বাছা গেস্ট মোছার আগে নিশ্চিতকরণ
ternux uninstall all             # সব Ternux-পরিচালিত গেস্ট, CLI ও state সরায়
```

`container` বাছা গেস্টটি মুছে; `all` টার্নাক্সের পরিচালিত প্রোফাইল এবং
নিবন্ধিত সাধারণ ছবির গেস্ট সরায়। কোনো গেস্ট মোছা ব্যর্থ হলে আবার চেষ্টা
করার জন্য কমান্ড-লাইন সরঞ্জাম ও অবস্থা রেখে দেয়। টার্মাক্স, ভাগ করা
প্যাকেজ, অসংশ্লিষ্ট পিআররুট গেস্ট, অ্যান্ড্রয়েডের ভাগ করা সংরক্ষণস্থান ও
ব্যবহারকারীর ফাইল অক্ষত থাকে। স্বয়ংক্রিয় কাজে `--yes`-কে স্পষ্ট
নিশ্চিতকরণ হিসেবে ব্যবহার করুন।

উপরের হাতে চালানো ধাপগুলো কমান্ড-লাইন সরঞ্জাম বসায় না। হাতে করা সেটআপ
সরাতে টার্মাক্স থেকে নির্দিষ্ট অপসারণ-সরঞ্জাম চালান:

```bash
curl -fsSL https://raw.githubusercontent.com/soobujmiah/ternux/main/uninstall.sh | bash
```

এটি কোন অংশ সরাবেন তা জিজ্ঞেস করবে। নিশ্চিত করার আগে প্রতিটি লক্ষ্য দেখে নিন।

---

*টার্নাক্স — সর্বস্বত্ব (c) ২০২৬ সবুজ মিয়া ([@soobujmiah](https://github.com/soobujmiah)) · অ্যাপাচি-২.০*
