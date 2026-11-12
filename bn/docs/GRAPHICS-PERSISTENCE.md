---
title: "আপডেটের পরেও GPU driver ধরে রাখা"
description: "নতুন Adreno ডিভাইসে কেন নতুন Turnip দরকার, package update কীভাবে তা মুছে দিতে পারে, এবং যে apt-নিরাপদ layout তা আটকায়।"
lang: "bn"
alt_url: "/docs/GRAPHICS-PERSISTENCE.html"
---

নতুন Adreno hardware-এ Debian-এর দেওয়া Vulkan driver GPU-কে একেবারেই শনাক্ত
করতে না-ও পারে। তখন ternux-এর Zink route-এর নিচে কোনো Vulkan device থাকে না যার
উপর OpenGL দাঁড়াবে — অর্থাৎ নতুন Turnip কোনো performance tweak নয়, GPU ব্যবহারযোগ্য
থাকার কারণই সেটি। এই পৃষ্ঠা দেখায় কীভাবে সেটি এমনভাবে বসাবেন যাতে সাধারণ একটি
package update তা কেড়ে নিতে না পারে — কারণ driver ফিরে গেলে সেটা চোখে পড়া কঠিন:
desktop চালু হতেই থাকে, শুধু ধীর হয়ে যায় বা accelerate হয় না।

> **ডিভাইস প্রমাণ, ২০২৬-১১-০৭, Redmi Turbo 4 Pro (Adreno 825):** Debian trixie-এর
> `mesa-vulkan-drivers 25.0.7-2+deb13u1`-এ `vulkaninfo` **কোনো Adreno device
> পায়নি** — শুধু `llvmpipe`, `PHYSICAL_DEVICE_TYPE_CPU` হিসেবে। Ternux-এর staged
> upstream Mesa 27.0.0 archive-এ Vulkan এবং Zink GLX দুটোতেই Adreno 825 দেখা যায়।
> একই model/settings-এ তিন-run median ছিল staged 27.0 driver-এ 27.2 tok/s এবং
> installed 26.3 driver-এ 26.6 tok/s। এটি এক device-এর short test, sustained
> performance claim নয়; বিস্তারিত [প্রমাণ ও বেঞ্চমার্ক](BENCHMARKS.html)-এ।

## Ternux কীভাবে graphics readiness জানায়

`ternux info` এবং `ternux profile` Vulkan device readiness ও OpenGL rendering
আলাদা করে দেখায়। KGSL node, Vulkan loader বা ICD manifest দেখা গেলেই hardware
acceleration বলা হয় না। Ternux Debian guest-এর ভেতর প্রযোজ্য KGSL device bind
করে `vulkaninfo --summary` চালায়, তারপর physical device-এর ধরন ও driver যাচাই
করে। `vulkan_state`-এর মান `NOT_DETECTED`, `HARDWARE_AVAILABLE`,
`LOADER_MISSING`, `DRIVER_MISSING`, `ICD_MISSING`,
`DEVICE_ENUMERATION_FAILED`, `VULKAN_READY` অথবা `SOFTWARE_FALLBACK` হতে পারে।
`graphics_state`-এ `OPENGL_ACCELERATION_READY` কেবল তখনই আসে, যখন `glxinfo`
চলমান non-software renderer শনাক্ত করে।

সংযুক্ত Redmi Turbo 4 Pro-তে Termux host-এর Vulkan probe
`VK_ERROR_INCOMPATIBLE_DRIVER` দিয়ে ব্যর্থ হয়েছে; Debian guest-এর probe Turnip
দিয়ে Adreno 825 এবং আলাদা llvmpipe device enumerate করেছে। তাই source CLI
`vulkan_state=VULKAN_READY` দেখিয়েছে এবং live X11 probe
`zink Vulkan 1.4(Adreno (TM) 825 (MESA_TURNIP))` শনাক্ত করেছে। এগুলো এই
ডিভাইসের বর্তমান observation; অন্য ডিভাইসের জন্য দাবি নয়।

## তিনটি layout: Debian, distro overlay, এবং package-এ লেখা driver

| | Debian Turnip layout | Distro bundle overlay | Fragile layout |
|---|---|---|
| Driver | `/usr/local/lib/aarch64-linux-gnu/libvulkan_freedreno.so` | `/usr/local/lib/ternux/<Mesa bundle>/lib/aarch64-linux-gnu/libvulkan_freedreno.so` | `/usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so` |
| ICD manifest | `/usr/local/share/vulkan/icd.d/ternux_freedreno_icd.json` | `<overlay>/share/vulkan/icd.d/ternux_freedreno_icd.json` | `/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json` |
| distro package-এর মালিকানায়? | না — `/usr/local` dpkg-এর আওতার বাইরে | না — versioned bundle `/usr/local/lib/ternux`-এ থাকে | হ্যাঁ — path-টি `mesa-vulkan-drivers`-এর |
| runtime selection | Loader search path | Ternux desktop matching Mesa-এর জন্য `LD_LIBRARY_PATH`, `LIBGL_DRIVERS_PATH`, `VK_DRIVER_FILES` সেট করে | distro default |
| `apt upgrade`-এর পরে | অপরিবর্তিত | অপরিবর্তিত; distro Mesa file-এ হাত দেয় না | distro সংস্করণ দিয়ে প্রতিস্থাপিত |
| `dpkg -V mesa-vulkan-drivers` | চুপ | চুপ | driver-এর জন্য `??5??????` জানায় |

Fragile layout ততক্ষণ কাজ করে যতক্ষণ `mesa-vulkan-drivers` স্পর্শ করে এমন প্রথম
package operation না ঘটে — একটি upgrade, একটি security update, কিংবা
`apt install --reinstall`। dpkg তখন নিজের file ফিরিয়ে দেয়, যেটা তার কাজই, আর নতুন
driver চলে যায়।

Vulkan loader `/usr/share/vulkan/icd.d`-এর পাশাপাশি `/usr/local/share/vulkan/icd.d`-ও
খোঁজে, তাই Debian layout-এ environment variable লাগে না। Ubuntu ও অন্য যে
profile-এ full distro-matched Mesa bundle লাগে, সেগুলো versioned
`/usr/local/lib/ternux` overlay-তে থাকে। Ternux desktop matching Mesa library,
GL driver directory ও একটিমাত্র Vulkan ICD বেছে নেয়। Archive কখনো `/`-এ extract
হয় না, package-owned driver বদলায় না, system-wide loader config-ও বদলায় না।

> **Ubuntu 26.04 live verification, 2026-11-12:** যোগ্য Redmi Turbo 4 Pro-তে
> Ubuntu Turnip asset Ternux overlay-তে install করা হয়েছে। এরপর Ubuntu-র
> `mesa-vulkan-drivers` package পুনরায় install করে `dpkg -V mesa-vulkan-drivers`
> চালালে কোনো পার্থক্য দেখায়নি; কোনো Mesa package hold-ও ছিল না। Overlay-এর
> ICD বেছে `vulkaninfo --summary` একটিমাত্র Adreno 825 integrated GPU দেখিয়েছে,
> আর `glxinfo -B` direct rendering ও
> `zink Vulkan 1.4(Adreno (TM) 825 (MESA_TURNIP))` দেখিয়েছে।
> `ternux doctor --json` overlay-কে managed এবং renderer-কে accelerated বলেছে।
> এটি একটি device-এর observation; অন্য Ubuntu release আলাদাভাবে পরীক্ষা করা বাকি।

> **Alpine 3.24 live verification, 2026-11-12:** pinned archive-এ Debian-family
> `/usr/lib/aarch64-linux-gnu`-এর বদলে `/usr/lib` path আছে। এখন installer
> archive-এর আসল library directory `/etc/ternux/mesa-overlay-libdir`-এ লিখে
> validate করে; overlay isolated থাকে এবং শুধু Ternux session-এ select হয়।
> Fresh managed install complete হয়েছে, `tx doctor --json` Adreno 825 Vulkan
> device enumerate করেছে, আর Alpine desktop `:2` live অবস্থায় Mesa Turnip-এর
> ওপর Zink দেখিয়েছে। এই পরীক্ষা শুধু এই device/profile-এর জন্য; সব Alpine
> version-এর qualification নয়।

## আপনার কোন layout তা যাচাই করুন

```bash
ternux verify
```

`turnip:present` মানে managed layout। `turnip:fragile` মানে driver একটি dpkg-মালিকানার
path-এ আছে এবং ফিরিয়ে দেওয়া হবে। `turnip:missing` মানে কোনোটিই পাওয়া যায়নি।

Debian guest-এর ভেতর সরাসরিও নিশ্চিত করা যায়:

```bash
vulkaninfo --summary | grep -E "deviceName|deviceType|driverInfo"
dpkg -V mesa-vulkan-drivers
```

Debian-এর package সংস্করণের চেয়ে নতুন `driverInfo` সহ একটি `Adreno` entry, এবং চুপ
থাকা `dpkg -V` — এটাই সুস্থ অবস্থা।

## চালু install-কে managed layout-এ সরানো

নিচেরগুলো Debian guest-এর ভেতরে চালান। আগে backup নিন: custom driver-টির হয়তো
এটাই একমাত্র কপি, আর ডিভাইসের ভেতরে কিছুই সেটি আবার build করতে পারবে না।

```bash
# ১. driver ও তার manifest backup করুন, checksum সহ
mkdir -p ~/mesa-backup && cd ~/mesa-backup
cp -a /usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so .
cp -a /usr/share/vulkan/icd.d/freedreno_icd.aarch64.json . 2>/dev/null || true
sha256sum libvulkan_freedreno.so > MANIFEST.sha256

# ২. apt যেখানে পৌঁছাতে পারে না সেখানে বসান
sudo mkdir -p /usr/local/lib/aarch64-linux-gnu /usr/local/share/vulkan/icd.d
sudo install -m 0755 libvulkan_freedreno.so \
  /usr/local/lib/aarch64-linux-gnu/libvulkan_freedreno.so
sudo tee /usr/local/share/vulkan/icd.d/ternux_freedreno_icd.json >/dev/null <<'JSON'
{
    "ICD": {
        "api_version": "1.4.359",
        "library_arch": "64",
        "library_path": "/usr/local/lib/aarch64-linux-gnu/libvulkan_freedreno.so"
    },
    "file_format_version": "1.0.1"
}
JSON

# ৩. dpkg-এর এলাকায় থাকা manifest সরিয়ে দিন
sudo rm -f /usr/share/vulkan/icd.d/freedreno_icd.aarch64.json

# ৪. Debian-এর নিজের manifest অবসরে পাঠান, যাতে GPU দুইবার enumerate না হয়
sudo dpkg-divert --add --rename \
  --divert /usr/share/vulkan/icd.d/freedreno_icd.json.distrib \
  /usr/share/vulkan/icd.d/freedreno_icd.json

# ৫. dpkg-মালিকানার path Debian-কে ফিরিয়ে দিন
sudo apt-get install -y --reinstall mesa-vulkan-drivers
```

ধাপ ২-এর `api_version` এখানে ছাপা মানটি নয়, আপনার নিজের manifest-এর মান বসান —
সেটি আপনার build করা driver-কেই বর্ণনা করে।

তারপর যাচাই করুন ধাপ ৫-এর reinstall-এর পরেও GPU টিকে আছে কি না:

```bash
vulkaninfo --summary | grep -E "deviceName|driverInfo"
dpkg -V mesa-vulkan-drivers
```

নিজের driver সংস্করণ সহ ঠিক একটি `Adreno` entry, আর `dpkg -V`-এর কোনো output না —
মানে migration সফল। Diversion dpkg-এর database-এ লেখা থাকে, তাই upgrade-এর পরেও
থাকে; `dpkg-divert --list | grep freedreno` দেখায়, আর `dpkg-divert --remove` ফিরিয়ে
নেয়।

## GPU কেন দুইবার দেখা যেতে পারে

একই library-তে point করা দুটি ICD manifest থাকলে loader একই GPU দুইবার জানায়,
একই `deviceUUID` নিয়ে। এটি ক্ষতিকর নয়, বিভ্রান্তিকর — উপরের ধাপ ৪ এর সমাধান। আমরা
যে crash পরীক্ষা করেছি তার কারণ এই duplicate ছিল না: `VK_DRIVER_FILES` একটি
manifest-এ pin করেও ব্যর্থ Vulkan-backend পরীক্ষার ফল বদলায়নি।

## কোনো update আগেই driver ফিরিয়ে দিয়ে থাকলে

লক্ষণ হলো desktop চালু হচ্ছে কিন্তু GPU-র কাজ ধীর বা অনুপলব্ধ, এবং `vulkaninfo`-তে
Adreno আর নেই। Backup থেকে driver restore করুন, তারপর উপরের migration অনুসরণ করুন
যাতে আবার না ঘটে। Backup না থাকলে driver আবার build করতে হবে; ternux এখনো কোনো
প্রকাশিত Turnip artifact দেয় না, যা release gate হিসেবে
[accelerator release plan](ACCELERATOR-RELEASE-PLAN.html)-এ লিপিবদ্ধ আছে।

Software rasterisation প্রতিটি ডিভাইসে ব্যবহারযোগ্য fallback নয়: পরীক্ষিত ডিভাইসে
জোর করে সেটি চালালে (`LIBGL_ALWAYS_SOFTWARE=1`) ধীর render নয়, সঙ্গে সঙ্গে `SIGILL`
হয়েছে। "software-এ fallback হয়ে যাবে" কথাটি নিজের hardware-এ মাপার আগ পর্যন্ত
unverified ধরুন।

## সীমা

- উপরের প্রমাণ একটি ডিভাইস ও একটি configuration থেকে। ভিন্ন Adreno প্রজন্ম Debian-এর
  নিজের Mesa-তেই পূর্ণ সমর্থিত হতে পারে, তখন এর কিছুই প্রযোজ্য নয়।
- চলমান একটি Xfce session মাঝপথে driver ফিরে গেলে টেকে কি না তা পরীক্ষা করা হয়নি;
  করতে গেলে একটি জীবন্ত desktop ইচ্ছাকৃতভাবে ভাঙতে হতো।
- ternux Mesa build বা বিতরণ করে না। এই ধাপগুলো আপনার দেওয়া driver কোথায় রাখতে হবে
  তা বলে, কীভাবে বানাতে হবে তা নয়।

লক্ষণভিত্তিক diagnosis-এর জন্য দেখুন [সমস্যা সমাধান](TROUBLESHOOTING.html), আর
graphics route বাছাইয়ের জন্য [কনফিগারেশন](CONFIGURATION.html)।
