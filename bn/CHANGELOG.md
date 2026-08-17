---
title: "পরিবর্তনলগ"
description: "ternux-এর সংস্করণ ইতিহাস — এক-কমান্ড ইনস্টলার, পাবলিক ডকুমেন্টেশন সেট ও সাইট।"
lang: "bn"
alt_url: "/CHANGELOG.html"

---

ternux-এর উল্লেখযোগ্য পরিবর্তনগুলো। তারিখ ISO 8601 ফরম্যাটে।

---

## [Unreleased]

### Professional bilingual documentation experience

- Refined terminal design-এ দুই landing page পুনর্গঠন: পরিষ্কার hierarchy,
  responsive layout, local font, উন্নত accessibility, সংক্ষিপ্ত installation choice,
  evidence boundary এবং upstream repository-তে যাওয়া workload card।
- Flat documentation chip shell-এর বদলে grouped sidebar navigation, filterable page
  index, breadcrumb, generated local table of contents, previous/next navigation,
  edit/feedback path, mobile drawer, print style ও consistent project footer যোগ।
- Mirrored English/বাংলা documentation hub ও সম্পূর্ণ বাংলা benchmark/evidence
  archive যোগ; captured 66 scene value ও caveat-সহ।
- `_data/docs.yml`-এ bilingual information architecture কেন্দ্রীভূত; repository
  authoring map, reciprocal language metadata, complete sitemap, corrected canonical
  URL config ও professional contribution guidance যোগ।
- দুই ভাষা ও redesigned surface-এ measured, observed, reported-build এবং untested
  পার্থক্য সংরক্ষিত।

### বাস্তব-device evidence archive ও installer hardening

- README-কে archival, evidence-led guide হিসেবে পুনর্গঠন করা হয়েছে: exact
  renderer, measured glmark2 score/FPS range, architecture/backend ব্যাখ্যা,
  verification ও reproduction command, workload, FAQ, thermal guidance এবং
  measured/observed/build-only/untested দাবির স্পষ্ট পার্থক্য।
- `docs/BENCHMARKS.md`-এ captured OpenGL ও OpenGL ES-এর সব ৬৬টি scene result,
  test condition, anomaly, evidence matrix ও reproduction protocol সংরক্ষিত।
- One-command, সব executable component review-করা automatic route এবং English/
  Bengali manual procedure যোগ/সংশোধন করা হয়েছে।
- Backend detection/normalization, Turnip archive validation ও staged extraction,
  launcher env/argument/cleanup, loopback PulseAudio config, persisted user/locale,
  repair, verification, resume এবং scoped uninstall documentation harden করা হয়েছে।
- যেসব reporting command-এর schema documented শুধু সেগুলোর JSON standardized;
  interactive/lifecycle command human-oriented—এই সীমা এখন স্পষ্ট।
- English/Bengali troubleshooting, configuration, architecture ও CLI reference
  বিস্তৃত; workload card সরাসরি Blender, llama.cpp ও stable-diffusion.cpp upstream
  repository-তে যায়।

---

## [1.3.0] — 2026-08-15

### ternux CLI v1.3.0 — নথিভুক্ত JSON output-সহ production modular CLI

**সম্পূর্ণ CLI পুনর্গঠন।** CLI-টি শুরু থেকে নতুন করে তৈরি করা হয়েছে: ছোট
dispatcher, স্বয়ংসম্পূর্ণ command module, যথাযথ help system এবং consistent UX।
যেসব reporting command-এর schema নথিভুক্ত, সেগুলো machine-readable JSON দেয়;
interactive ও lifecycle command human-oriented থাকে।

**নতুন architecture:**
- `bin/ternux` এখন **thin dispatcher** (~৮০ লাইন): `tnx_cmd_*` function naming
  convention দিয়ে command খুঁজে পায়, library lazy-load করে এবং global flag
  সঠিকভাবে পরিচালনা করে।
- প্রতিটি command function নিজস্ব library file-এ (`lib/<name>.sh`) থাকে।
- নতুন `lib/help.sh` — per-command help function-সহ কেন্দ্রীয় help system।
- নতুন `lib/info.sh` — system information command-এর dedicated module।
- Command dispatch **extensible**: নতুন command যোগ করতে নতুন `lib/<name>.sh`
  file-এ একটি `tnx_cmd_<name>()` function যোগ করলেই হয়।

**UX bug সমাধান:**
- `ternux doctor --help` এখন doctor-specific help দেখায় (আগে main help দেখাত)।
- `ternux profile --help` এখন profile subcommand সঠিকভাবে দেখায়।
- যেকোনো command-এর পর `--help` সঠিক `tnx_help_<command>` function-এ dispatch হয়।
- অজানা command এখন সঠিক exit code-সহ পরিষ্কার error message দেয়।

**Standardized subcommand pattern:**
- Subcommand নেওয়া প্রতিটি command তা validate করে এবং error হলে usage দেখায়।
- প্রতিটি স্তরে consistent `--help` handling।
- সব command সঠিক exit code দেয় (০=success, ১=error)।

**JSON output উন্নতি:**
- Item escaping-সহ `tnx_json_add_array()`।
- সব JSON output-এ consistent field naming (`snake_case`)।
- Error JSON object-এ `command`, `status: "error"`, ও `reason` field।
- JSON schema `share/templates/json-schema.md`-এ নথিভুক্ত।

**নতুন feature:**
- `ternux backend detect` — সঠিক GPU backend স্বয়ংক্রিয়ভাবে শনাক্ত।
- `ternux update check` — install না করে update পরীক্ষা।
- প্রতিটি command path-এ যথাযথ `--version` flag।
- `TERNUX_QUIET` সর্বত্র non-critical message বন্ধ করে।
- `TERNUX_VERBOSE` consistentভাবে debug output চালু করে।

**Refactored library:**
| Library | লাইন | অবস্থা |
|---------|------:|--------|
| `bin/ternux` | ~৮০ | Thin dispatcher (আগে ৫৩২) |
| `lib/core.sh` | ২৩৯ | Shared foundation |
| `lib/help.sh` | ১৩০ | **নতুন** — centralized help |
| `lib/desktop.sh` | ১৬৮ | Self-contained lifecycle |
| `lib/doctor.sh` | ২৫০ | Clean diagnostics + verify |
| `lib/backend.sh` | ৯৫ | Backend management |
| `lib/benchmark.sh` | ১৬৪ | GPU benchmark |
| `lib/info.sh` | ৮৬ | **নতুন** — system info |
| `lib/profile.sh` | ১৮০ | Profile management |
| `lib/repair.sh` | ১৮৪ | Auto-fix engine |
| `lib/logs.sh` | ৯৭ | Log management |
| `lib/update.sh` | ১৫০ | Self-update |
| `lib/state.sh` | ৮৬ | State query |
| `lib/phases.sh` | ৭০৪ | Installation phase |

**Extensibility (plugin readiness):**
- নতুন command: `tnx_cmd_mycommand()`-সহ `lib/mycommand.sh` তৈরি করুন।
- Help যোগ: `lib/help.sh`-এ `tnx_help_mycommand()` তৈরি করুন।
- Command function `declare -F` দিয়ে স্বয়ংক্রিয়ভাবে খুঁজে পাওয়া যায়।

**নতুন documentation:**
- `docs/CLI.md` — প্রতিটি command, flag ও JSON schema-সহ সম্পূর্ণ CLI reference।
- `share/ternux-completion.bash` — সব command-এর Bash tab completion।

**নতুন CI/CD pipeline:**
- `.github/workflows/ci.yml` — ShellCheck, syntax check, ৪৩টি smoke test ও doc link check।
- `.github/workflows/release.yml` — `v*` tag-এ স্বয়ংক্রিয় GitHub Release।
- `.github/dependabot.yml` — সাপ্তাহিক GitHub Actions dependency update।

**নতুন contributor tooling:**
- `.github/stale.yml` — ৯০ দিন পর stale issue স্বয়ংক্রিয় ব্যবস্থাপনা।
- `.github/FUNDING.yml` — GitHub Sponsors support।
- Repository-তে ১৪টি discoverable topic সেট করা হয়েছে।

**Repository metadata:**
- GitHub topic: `termux`, `android`, `linux-desktop`, `gpu-acceleration`, `vulkan`,
  `zink`, `turnip`, `adreno`, `proot`, `xfce4`, `debian`, `no-root`, `cli`,
  `shell-script`।
- README badge update: CI status, release version ও GitHub star।
- সঠিক line-ending rule-সহ `.gitattributes`।

---

## [1.0.10] — 2026-08-15

### ইনস্টলার v1.2.2 — নিখুঁতভাবে সারিবদ্ধ লাইভ ড্যাশবোর্ড, পূর্ণ বিবরণসহ

**জ্যামিতি ইঞ্জিন (বক্স এখন প্রতিটি টার্মিনালে সোজা):**
- নতুন `padline()` ANSI-রঙিন লাইন মাপে তার দৃশ্যমান প্রস্থে — বাইটে মাপলে
  প্রতিটি বক্স-সারি বর্ডারের চেয়ে ছোট হতো আর এস্কেপ কোড মাঝপথে কেটে আবর্জনা
  গ্লিফ ফাঁস হতো।
- CSI স্ট্রিপিং glob থেকে sed-এ সরানো হয়েছে: bash glob `[0-9;]*m` মানে
  "একটি সংখ্যা/সেমিকোলন তারপর যেকোনো কিছু তারপর m" (`*` ফ্রি ওয়াইল্ডকার্ড,
  কোয়ান্টিফায়ার নয়) — পুরো লাইন গিলে ফেলছিল; sed-এর regex ঠিকঠাক করে।
- শুরুতে UTF-8 লোকেল বসানো হয় যাতে '✓' সব জায়গায় এক কলাম গোনা হয়;
  `_vtrunc()` লোকেল-নিরপেক্ষ অক্ষর-ট্রাঙ্কেশন করে (কিছু সিস্টেমে cut -c
  লোকেল মানে না)।
- বক্সে ডান বর্ডার ও ২-কলাম নিরাপদ মার্জিন — টার্মিনালের অটো-র্যাপ কিনারায়
  আর কিছুই লাগে না।

**ড্যাশবোর্ডে আরও বিবরণ:**
- ডিভাইস সারি: Android ভার্সন, আর্কিটেকচার, মডেল ও RAM — প্রিফ্লাইটে ধরা হয়।
- ফেজ ঘড়ি: প্রগ্রেস সারিতে বর্তমান ফেজ ও মোট সময় (চওড়া টার্মিনালে), প্রতি
  ফেজের সময় রেকর্ড হয়ে শেষের সারাংশে ✓/· সহ দেখায়।
- লাইভ লগ-টেইল স্যানিটাইজড (ক্যারেজ-রিটার্ন/কন্ট্রোল কোড বাদ) — প্যানেলের
  ভেতরে apt/curl-এর প্রগ্রেস আর কার্সর লাফাতে পারে না।
- জমে থাকা শেষ ফ্রেম এখন লাইভ ফ্রেমের সমান উচ্চতার (পুরনো বর্ডারের অবশেষ
  নেই) এবং পূর্ণ চেকলিস্ট, ডিভাইস ও সই দেখায়।

**যাচাই:** কাঁচা PTY আউটপুট একটি আসল টার্মিনাল এমুলেটর দিয়ে রেন্ডার করে
দেখা হয়েছে — প্রতিটি বক্সের প্রতিটি সারি তার বর্ডারের সমান প্রস্থ, শূন্য
এস্কেপ ফাঁস, শূন্য স্প্যাম; সম্পূর্ণ মক ইনস্টল সবুজ; সরু-টার্মিনাল ফলব্যাক,
পাইপ পরিচ্ছন্নতা ও রিগ্রেশন A–D সব পাস।

---

## [1.0.9] — 2026-08-15

### ইনস্টলার v1.2.1 — পুরো ইনস্টল জুড়ে লেখকের নাম

- **বয়ে চলা রংধনু সই।** নতুন sig ইঞ্জিন "Sobuj Miah" নামটি অক্ষরে অক্ষরে
  রেন্ডার করে — প্রতিটি অক্ষর ছয়টি থিম রঙের মধ্যে দিয়ে প্রতি-টিক ফেজ
  অফসেটসহ ঘোরে, ফলে রংগুলো নামের ভেতর দিয়ে ক্রমাগত বয়ে চলে।
- সইটি ইনস্টলের **প্রতিটি ধাপে** থাকে: ব্যানার বাইলাইন আসার সময় ঝিলমিল করে,
  HUD প্যানেলের প্রতিটি ফ্রেমে "✦ ternux by Sobuj Miah" সারি থাকে, জমে থাকা
  শেষ ফ্রেমেও থাকে, চওড়া টার্মিনালে কমপ্যাক্ট স্ট্যাটাস লাইনে রং-বদলানো
  নাম জোড়া হয়, সমাপ্তি উদযাপনে "built with ♥ by Sobuj Miah" অ্যানিমেটেড
  সাজসজ্জা হিসেবে প্রিন্ট হয়, আর শেষের সারাংশ বক্সটি সই দিয়ে শেষ হয়।
- পাইপ করা বা NO_COLOR-এ সব সই সাধারণ টেক্সটে নেমে আসে; সরু টার্মিনালে
  কমপ্যাক্ট ভিউ সইটি বাদ দেয়।

---

## [1.0.8] — 2026-08-15

### ইনস্টলার v1.2.0 — HUD ড্যাশবোর্ড, গ্লিচ ব্যানার, সারাংশ প্যানেল

- **গ্লিচ-ইন ব্যানার:** ASCII ওয়ার্ডমার্ক এখন তিনটি অ্যানিমেটেড পাসে এলোমেলো
  চিহ্ন থেকে জেগে ওঠে (ম্যাট্রিক্স-ধাঁচে), প্রতিটি সারি সবুজ→সায়ান গ্রেডিয়েন্টে;
  পাইপ করা হলে সাধারণ ব্যানার।
- **প্রতিটি কাজে লাইভ HUD ড্যাশবোর্ড:** জায়গামতো নতুন করে আঁকা বর্ডারযুক্ত
  প্যানেল — স্পিনার, `[3/9]` কাউন্টার, কাজের নাম ও অতিবাহিত সময়, শিমার-লিডসহ
  ইজড ফেজ বার, স্লাইডিং অ্যাক্টিভিটি ট্র্যাক, নয়-ধাপের চেকলিস্ট
  (`✓` শেষ / `⟳` চলছে / `·` বাকি) এবং ইনস্টল লগের সর্বশেষ লাইন। শেষ হওয়া কাজ
  প্যানেলটিকে `✓`/`✗` ফ্রেমে জমিয়ে রাখে।
- **শেষে বক্স করা সারাংশ প্যানেল:** ব্যাকএন্ড, ইউজার, অতিবাহিত সময়, লঞ্চার,
  শুরু করার কমান্ড ও লগ পাথ — সরু টার্মিনালে সাধারণ টেক্সট।
- **সরু-টার্মিনাল ফলব্যাক:** ৪৬ কলামের নিচে (সাধারণ ফোনের প্রস্থ) সবকিছু
  স্বয়ংক্রিয়ভাবে কমপ্যাক্ট এক-লাইন ভিউতে নেমে আসে।
- কার্সর হাইড/শো এখন স্টেটফুল (পাইপ করা আউটপুটে আর ভুল এস্কেপ কোড নেই);
  পাইপে ব্যানার গ্রেডিয়েন্ট বন্ধ; নতুন ইনস্টলে ইজড শতাংশ রিসেট হয়।
- আসল PTY-তে পরীক্ষিত: বক্সড HUD ফ্রেম, জমে থাকা শেষ বক্স, সারাংশ প্যানেল,
  সম্পূর্ণ মক ইনস্টল, সরু ফলব্যাক, পাইপ পরিচ্ছন্নতা এবং আগের সব রিগ্রেশন
  (conffile ক্যাসকেড, sleep-ভাঙা আপগ্রেড, ভাঙা dpkg)।

---

## [1.0.7] — 2026-08-15

### ইনস্টলার v1.1.4 — শুধু curl নয়, পুরো টুলচেইন

- বাস্তব ডিভাইস ফলো-আপ: curl আপগ্রেড হয়েছিল (8.12.1 → 8.21.0) তবুও লিংক
  ব্যর্থ — হারানো সিম্বল আসে **openssl** থেকে, তাই শুধু curl মেরামত করে কখনোই
  সমাধান হবে না। repair_curl এখন পুরো চেইন আপগ্রেড করে
  (`curl openssl openssl-tool libngtcp2 libnghttp3`) এবং তবু লিংক ব্যর্থ হলে
  সম্পূর্ণ `pkg upgrade -y` চালাতে বলে।
- সমস্যা সমাধানে (EN + BN) "curl আপগ্রেড করেও STILL ব্যর্থ" কেসটি ও তার নিশ্চিত
  সমাধান লেখা হয়েছে।

---

## [1.0.6] — 2026-08-15

### ইনস্টলার v1.1.3 + সাইট: কপি-নিরাপদ কমান্ড ও curl-সহনশীলতা

- **কপিতে আর `$` প্রম্পট ঢুকতে পারে না।** ল্যান্ডিং পেজে প্রম্পট ও জ্বলজ্বলে
  কার্সর এখন CSS pseudo-element দিয়ে আঁকা — সিলেক্ট বা কপি করলে হুবহু
  কমান্ডটিই আসে। গাইড ব্লকের কপি বাটনও প্রতিটি লাইন থেকে দেখানোর `$ `
  প্রিফিক্স বাদ দেয়। রিপোর্ট করা `No command $ found` সমস্যার সমাধান।
- **ভাঙা curl আর কিছুই আটকায় না।** আংশিক আপগ্রেডের পর curl লিংকই হতে পারে না
  (`SSL_set_quic_tls_transport_params`)। ইনস্টলার এখন প্রিফ্লাইটে এটি শনাক্ত
  করে মেরামত করে (`pkg install curl openssl`), নেটওয়ার্ক চেক wget
  ফলব্যাকসহ চলে, আর Turnip ড্রাইভার নামায় `download()` হেল্পার দিয়ে যা
  wget-এ নেমে আসে। সাইট ও প্রতিটি ডক (README, দ্রুত শুরু, ইনস্টলেশন, ম্যানুয়াল
  — EN + BN) এখন curl-মুক্ত পথ হিসেবে `wget -qO- … | bash` ওয়ান-লাইনার দেখায়।
- সমস্যা সমাধানে দুটি নতুন সেকশন: পেস্ট করা কমান্ডে `$` এবং curl
  CANNOT LINK (EN + BN), টেবিল এন্ট্রিসহ।

---

## [1.0.5] — 2026-08-15

### ইনস্টলার v1.1.2 — পুরো ইনস্টল জুড়ে অ্যানিমেশন

- **প্রতিটি কাজে লাইভ স্ট্যাটাস লাইন:** একটি স্থির অ্যানিমেটেড লাইন —
  ব্রেইল স্পিনার, সামগ্রিক ফেজ বার `[2/9] ██░░…`, স্লাইডিং অ্যাক্টিভিটি
  ট্র্যাক ও অতিবাহিত সময় — প্রতিটি টিক-এ নতুন করে আঁকা হয়, সব wrapped
  কাজের জন্য।
- **প্রতিটি দীর্ঘ কাজ এখন অ্যানিমেটেড:** Debian প্যাকেজ ইনস্টল, ইউজার
  তৈরি, Turnip ড্রাইভার স্টেজিং, লোকেল/ফন্ট সেটআপ এবং সব ঐচ্ছিক ওয়ার্কলোড
  (dev, llama.cpp, network, media, Blender) আগে প্লেইন টেক্সটে চলত; এখন
  স্পিনারের মাধ্যমে চলে, আউটপুট লগে যায়।
- **অ্যানিমেটেড ফেজ হেডার:** নয়টি ধাপের প্রতিটি শুরু হয় দুটি ছুটে যাওয়া
  রেখা ও `[N/9]` শিরোনামে — স্থির `==>` নয়।
- **বাড়তে থাকা প্রগ্রেস বার:** ফেজ-বার এখন আগের ফেজ থেকে পরের ফেজ পর্যন্ত
  নিজের ফিল অ্যানিমেট করে (▓ শিমার লিড, শতাংশ, কাউন্ট ও অতিবাহিত সময়) —
  একবার প্রিন্ট করার বদলে।
- **টাইপ করা পরবর্তী ধাপ** ও দুই লাইনের সমাপ্তি উদযাপন।
- সব টাইমিং bsleep() দিয়ে; `--no-anim`, `NO_COLOR=1` ও পাইপ করা রান
  প্লেইন টেক্সটেই থাকে। ফুল-ফ্লো রিগ্রেশন: আসল PTY-তে মক এন্ড-টু-এন্ড
  ইনস্টল সফল — উদযাপন, লঞ্চার ও অ্যালায়াস লেখা হয়েছে; আগের ব্যর্থতার
  দৃশ্যপটগুলোও (conffile ক্যাসকেড, sleep-ভাঙা আপগ্রেড, ভাঙা dpkg) পাস করে।

---

## [1.0.4] — 2026-08-15

### ইনস্টলার v1.1.1 — প্রিফিক্স বদলের সময়ও টিকে থাকা স্পিনার

- **আপগ্রেড-সময়ের এরর স্প্যাম ও হ্যাং ঝুঁকি সমাধান।** `pkg upgrade`
  Termux প্রিফিক্স বদলানোর সময় স্পিনারের `sleep` মাঝপথে ব্যর্থ হতে পারত
  (`CANNOT LINK EXECUTABLE "sleep": library "libpcre2-8.so" not found`,
  `/usr/bin/sleep: No such file or directory`) — টার্মিনালে স্প্যাম আর বিজি
  লুপের ঝুঁকি। এখন ইনস্টলার `bsleep()` ব্যবহার করে: সত্যিকারের `sleep` (stderr
  নীরব), ব্যর্থ হলে নিজের FIFO-তে বিশুদ্ধ-bash `read -t` টাইমআউট — স্পিনারের
  এমন কোনো বাইনারি দরকার নেই যা আপগ্রেড মুছে ফেলতে পারে।
- FIFO প্রিফিক্স-বদলের ধাপের আগে একবার তৈরি হয়, প্রস্থানে মুছে যায়;
  ইনস্টলারের প্রতিটি sleep এখন `bsleep` দিয়ে চলে।
- হুবহু ব্যর্থতা রিপ্লে করে রিগ্রেশন-টেস্ট (আসল PTY-তে মক sleep আপগ্রেডের
  মাঝে CANNOT-LINK তারপর হারিয়ে যাওয়া): স্পিনার ঘুরতে থেকেছে, শূন্য এরর
  স্প্যাম, ইনস্টল সবুজ। `sleep` স্থায়ীভাবে ভাঙা রেখে ফলব্যাক পেসিং যাচাই
  (১.৫ সেকেন্ড ±০.১)।

---

## [1.0.3] — 2026-08-15

### ইনস্টলার v1.1.0 — সমাধান ও সত্যিকারের টার্মিনাল থিম

- **openssl/conffile ক্যাসকেড সমাধান।** `pkg upgrade`-এ dpkg conffile প্রম্পটে
  পড়ে বন্ধ stdin-এ এরর হয়ে প্যাকেজ সিস্টেম ভেঙে যেত, ফলে পরের প্রতিটি
  ইনস্টল ব্যর্থ হতো। এখন সব apt অপারেশন নন-ইন্টারঅ্যাক্টিভভাবে
  force-confold/force-confdef সহ চলে, আপগ্রেডের আগে-পরে ভাঙা dpkg স্টেট মেরামত
  হয়, আর Debian কন্টেইনারের ভেতরের প্রতিটি apt ধাপেও একই সুরক্ষা।
- **run()-এর এক্সিট-কোড রিপোর্টিং সমাধান।** আগে ব্যর্থতায় `rc=0` দেখাত;
  এখন সত্যিকারের এক্সিট কোড ধরা ও দেখানো হয়।
- **Termux-X11 ফলব্যাক।** কোনো মিররে `termux-x11-nightly` না থাকলে ইনস্টলার
  ব্যর্থ না হয়ে স্থিতিশীল `termux-x11`-এ নেমে আসে।
- **টার্মিনাল থিম:** গ্রেডিয়েন্ট ব্যানার, অ্যানিমেটেড টাইপ করা ইন্ট্রো,
  দীর্ঘ কাজে ব্রেইল স্পিনার, শতাংশ ও ধাপ-কাউন্টারসহ কাস্টম `█▓░` প্রগ্রেস বার,
  সফলতার উদযাপন, আর থিমড আনইনস্টলার ব্যানার। `--no-anim` /
  `TERNUX_NO_ANIM=1` দিয়ে বন্ধ; `NO_COLOR=1`-এ প্লেইন আউটপুট।
- রিপোর্ট করা ব্যর্থতাটির হুবহু রিপ্লে করে রিগ্রেশন-টেস্ট (মক pkg/dpkg):
  আপগ্রেড ক্র্যাশ, মেরামত, নাইটলি-অনুপস্থিত ফলব্যাক, পরিষ্কার রান,
  আগে থেকে ভাঙা অবস্থা।

---

## [1.0.2] — 2026-08-15

### সবখানে কপি-টু-ক্লিপবোর্ড

- সাইটের প্রতিটি কোড ব্লকে এখন টার্মিনাল-ধাঁচের হেডার বার ও কপি বাটন —
  ডকুমেন্টেশন পেজ এবং ল্যান্ডিং পেজের কমান্ড ব্লক, দুই জায়গাতেই।
- ইনলাইন `code`-এ এখন ক্লিক করলেই কপি হয়, ফ্ল্যাশ কনফার্মেশনসহ।
- নতুন শেয়ার্ড `assets/js/codecopy.js` (ক্লিপবোর্ড API + পুরনো ওয়েবভিউয়ের
  জন্য ফলব্যাক); কোনো ডিপেন্ডেন্সি ছাড়াই সব পেজে চলে।

### ইনস্টলার স্পটলাইট

- এক-কমান্ড ইনস্টল বক্স এখন অ্যানিমেটেড কেন্দ্রবিন্দু: ঘূর্ণায়মান গ্রেডিয়েন্ট
  রিং, শ্বাস-প্রশ্বাসের মতো গ্লো, শাইন সুইপ, লাইভ পালস ডট, ভার্সন ট্যাগ ও
  জ্বলজ্বলে কার্সর — `prefers-reduced-motion`-এ সব বন্ধ থাকে।
- শুধু বাটন নয়, পুরো কমান্ড লাইনেই ক্লিক করলে কপি হয়।

### গাইড ক্রস-লিংক

- ল্যান্ডিং গাইডের ব্যানার ও হিরো CTA এখন ম্যানুয়াল ইনস্টলেশন পাতায় নিয়ে
  যায়; ইনস্টলেশন ও দ্রুত-শুরু পাতায় এটি "Method 3 / পদ্ধতি ৩" হিসেবে যুক্ত।

---

## [1.0.1] — 2026-08-15

### নতুন: ম্যানুয়াল ইনস্টলেশন পেজ (EN + BN)

- **ম্যানুয়াল ইনস্টলেশন** যুক্ত — প্রতিটি ধাপ হাতে-কলমে, কমান্ডে কমান্ডে:
  অ্যাপ, বেস প্যাকেজ, Debian, ইউজার ও sudo, GPU ড্রাইভার (Zink/VirGL),
  অডিও/লোকেল/ফন্ট, সম্পূর্ণ লঞ্চার ফাইল (দুটি পথই), শর্টকাট, ফ্যান্টম-কিলার,
  যাচাইকরণ ও আনইনস্টল।
- ইনস্টলেশন ও দ্রুত-শুরু পেজ থেকে লিংক; ডক-নেভ, সাইটম্যাপ ও ল্যান্ডিং কার্ডে যুক্ত।

### রেসপনসিভনেস ওভারহল (সব পেজ)

- **ইনলাইন কমান্ড এখন ভাঙতে পারে** — লম্বা ইনলাইন কমান্ড আর মোবাইলে পেজ
  ফুলিয়ে দেয় না (আগে ৩৬০px স্ক্রিনে পেজ ১১০০+ px চওড়া হতো)।
- **টেবিল ডেস্কটপে স্বাভাবিকভাবে র্যাপ করে**, মোবাইলে দরকার হলেই স্ক্রল-বক্স।
- **স্টিকি নেভ এক সারিতে** — মোবাইলে ২–৩ সারিতে ভাঙে না, পাশে স্ক্রল করে।
- **ল্যান্ডিং গাইড কার্ড ঠিক করা হয়েছে** — লম্বা কমান্ড আর কার্ড ৬৪০px
  চওড়া করে না; হিরো, বাটন, ধাপ-কার্ড ও সুইচের জন্য মোবাইল টিউনিং।
- Playwright দিয়ে ৩৬০/৭৬৮/১২৮০/১৯২০px-এ সব পেজ পরীক্ষিত: ০ অনুভূমিক ওভারফ্লো।

---

## [1.0.0] — 2026-08-15

### প্রথম পাবলিক রিলিজ — ফ্রি ও ওপেন

- **এক-কমান্ড ইনস্টলার প্রকাশ।** `install.sh` এখন পাবলিক, MIT-লাইসেন্সকৃত,
  একক-ফাইল ইনস্টলার: প্রিফ্লাইট → বেস প্যাকেজ → Debian + Xfce4 → GPU ড্রাইভার
  (Zink/Turnip বা VirGL) → অডিও/লোকেল/ফন্ট → লঞ্চার → শর্টকাট → ঐচ্ছিক
  ওয়ার্কলোড → ফ্যান্টম-কিলার পরামর্শ → যাচাইকরণ।
- **ইনস্টলার টুলিং:** `--yes`, `--user`, `--locale`, `--backend`, `--zsh`,
  ওয়ার্কলোড ফ্ল্যাগ (`--with-dev`, `--with-llm`, `--with-network`,
  `--with-media`, `--with-blender`, `--all`), `--doctor [--fix]`, `--resume`,
  `--status`, `--uninstall`, `--version`, `--help`।
- **নিরাপত্তা শক্তিশালীকরণ:** ড্রাইভার আর্কাইভ যাচাই (লিংক নেই, পাথ-ট্রাভার্সাল
  নেই, শুধু অনুমোদিত এক্সট্র্যাকশন), ইনস্টল স্টেটে SHA-256 রেকর্ড,
  `visudo`-যাচাইকৃত sudoers ড্রপ-ইন, আইডেমপোটেন্ট ধাপ, যাচাইকৃত বাইনারি।
- **আলাদা `uninstall.sh`** — সেশন থামানো, লঞ্চার/শর্টকাট অপসারণ ও কন্টেইনার
  ডিলিটসহ।
- **ডকুমেন্টেশন গোড়া থেকে নতুন, EN + BN:** দ্রুত শুরু, ইনস্টলেশন (প্রতিটি
  ধাপের "কেন" সহ), ব্যবহার, কনফিগারেশন, সমস্যা সমাধান (লক্ষণ → কারণ →
  সমাধান), আর্কিটেকচার ও সাধারণ প্রশ্ন। এই পরিবর্তনলগসহ প্রতিটি পাতার বাংলা
  মিরর।
- **সাইট পুনর্নির্মিত:** কপি-যোগ্য এক-কমান্ড ইনস্টল বক্স, GPU পথ সুইচ, ধাপ ও
  ডিজাইন-সিদ্ধান্ত সেকশনসহ ল্যান্ডিং পেজ; "Pro শীঘ্রই আসছে" ভাষা ও
  প্রাইভেট-ইনস্টলার কথাবার্তা সরানো হয়েছে — ternux এখন ফ্রি সফটওয়্যার।
- **অপসারিত:** Pro পেজ ও পাবলিক/প্রাইভেট ডকুমেন্টেশন সীমানা।

---

## [0.x] — 2026-08-13 ও তার আগে

প্রি-রিলিজ যুগ: প্রাইভেট ইনস্টলার বর্ণনাকারী শুধু-ডকুমেন্টেশন সাইট।
1.0.0-এ বাতিল — ইনস্টলার নিজেই এখন MIT-তে পাবলিক।

---

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · MIT*
