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

> **ডিভাইস প্রমাণ, ২০২৬-১০-১৩, Redmi Turbo 4 Pro (Adreno 825):** Debian trixie-এর
> `mesa-vulkan-drivers 25.0.7-2+deb13u1`-এ `vulkaninfo` **কোনো Adreno device
> পায়নি** — শুধু `llvmpipe`, `PHYSICAL_DEVICE_TYPE_CPU` হিসেবে। স্থানীয়ভাবে build
> করা Turnip (Mesa 26.3.0-devel)-এ একই command জানায় `Adreno (TM) 825`,
> `PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU`। একটি ডিভাইস, একটি configuration; এখানে
> ব্যবহৃত result class-এর জন্য দেখুন [প্রমাণ ও বেঞ্চমার্ক](BENCHMARKS.html)।

## দুটি layout, এবং কেন শুধু একটি apt-এর পরেও টেকে

| | Managed layout | Fragile layout |
|---|---|---|
| Driver | `/usr/local/lib/aarch64-linux-gnu/libvulkan_freedreno.so` | `/usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so` |
| ICD manifest | `/usr/local/share/vulkan/icd.d/ternux_freedreno_icd.json` | `/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json` |
| কোনো package-এর মালিকানায়? | না — `/usr/local` dpkg-এর আওতার বাইরে | হ্যাঁ — path-টি `mesa-vulkan-drivers`-এর |
| `apt upgrade`-এর পরে | অপরিবর্তিত | Debian-এর সংস্করণ দিয়ে প্রতিস্থাপিত |
| `dpkg -V mesa-vulkan-drivers` | চুপ | driver-এর জন্য `??5??????` জানায় |

Fragile layout ততক্ষণ কাজ করে যতক্ষণ `mesa-vulkan-drivers` স্পর্শ করে এমন প্রথম
package operation না ঘটে — একটি upgrade, একটি security update, কিংবা
`apt install --reinstall`। dpkg তখন নিজের file ফিরিয়ে দেয়, যেটা তার কাজই, আর নতুন
driver চলে যায়।

Vulkan loader `/usr/share/vulkan/icd.d`-এর পাশাপাশি `/usr/local/share/vulkan/icd.d`-ও
খোঁজে, তাই managed layout-এ কোনো environment variable বা launcher পরিবর্তন লাগে না।

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
