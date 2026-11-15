---
title: "CLI রেফারেন্স"
description: "ternux কমান্ড-লাইন ইন্টারফেসের রেফারেন্স — command, subcommand, global flag ও নথিভুক্ত JSON output।"
lang: "bn"
alt_url: "/docs/CLI.html"
---

`tx` হলো ব্যবস্থাপনার প্রধান কমান্ড-লাইন ব্যবস্থা—ইনস্টল, ত্রুটি নির্ণয়,
মেরামত, কর্মদক্ষতা যাচাই, ডেস্কটপ চালানো এবং সিস্টেমের তথ্য দেখার জন্য। ইনস্টল
চালু বা পুনরায় শুরু, গেস্ট ব্যবস্থাপনা, লগ দেখা, হালনাগাদ এবং নির্দিষ্ট অংশ
অপসারণও `tx` দিয়েই করা যায়।

এই নির্দেশিকা `$PREFIX/bin/tx`-এ থাকা **টার্মাক্স হোস্ট** কমান্ডের।
`$PREFIX/bin/ternux` একই ব্যবস্থা চালানোর আরেকটি নাম। ডেবিয়ান/এক্সএফসিই
টার্মিনালে আলাদা গেস্ট-সচেতন `/usr/local/bin/ternux` সহায়ক কমান্ড থাকে; এটি
শুধু `status`, `info`, `doctor` (`verify` একই কাজের বিকল্প নাম), `env`,
`--version` এবং সাহায্য দেখায়। এটি আরেকটি নেস্টেড প্রুট সেশন না খুলে হোস্টের
চালানো-বন্ধ করার কমান্ড প্রত্যাখ্যান করে। নিচের হোস্ট কমান্ডগুলো টার্মাক্সে
চালান। ইনস্টলার দুই কমান্ড চালিয়ে সংস্করণ যাচাই করে; ফাইল থাকলেই সফল ইনস্টল
ধরা হয় না।

## ব্যবহার

```bash
ternux <command> [options] [subcommand]
```

## গ্লোবাল ফ্ল্যাগ

| ফ্ল্যাগ | বিবরণ |
|---------|--------|
| `--help`, `-h` | যেকোনো কমান্ডের জন্য সাহায্য |
| `--json` | structured output অনুরোধ; নিচে JSON-সহ নথিভুক্ত command-ই schema নিশ্চিত করে |
| `--verbose` | বিস্তারিত আউটপুট |
| `--quiet` | অ-গুরুত্বপূর্ণ বার্তা বন্ধ |
| `--version`, `-V` | ভার্সন তথ্য |

Dispatcher command load করার আগে global flag চিনে, তাই command-এর আগে বা পরে
দেওয়া যায়। কিন্তু সব command JSON schema দেয় না। `install`, live `logs tail`
বা `uninstall`-এ `--json` দিয়ে structured output আশা করবেন না; নিচে JSON
উদাহরণ আছে এমন command-এই ব্যবহার করুন। ওই path-গুলোর stdout একটি parseable
JSON object, এবং backend value canonical `zink` বা `virgl`; পুরোনো
`zink-turnip` শুধু compatibility input/state হিসেবে accepted। Shared
dispatch/environment failure-এ `command: "error"`, `status: "fatal"` ও
`message` থাকে; unknown command-এ `requested_command`-ও থাকে। `lib/core.sh`
load হওয়ার আগের failure JSON বানাতে পারে না, তাই সেটি plain stderr।

## কমান্ডসমূহ

### `tx -h` এবং `tx mic` / `tx cam`

`tx -h`-এ সব হোস্ট কমান্ড, তাদের সমর্থিত উপকমান্ড, সার্বিক বিকল্প, কমান্ডের
বিকল্প নাম এবং গেস্টের সংক্ষিপ্ত নাম থাকে। `ternux -h` একই তালিকা দেখায়;
কোনো কমান্ডের বিস্তারিত জানতে `tx COMMAND -h` চালান। `tx guides` সংক্ষিপ্ত
ব্যবহারবিধি এবং পূর্ণ নির্দেশিকার লিংক দেখায়।

`tx mic` টার্মাক্স:এপিআই-এর মাইক্রোফোন অনুমতি পরীক্ষা বা চায়। এটি এক সেকেন্ডের
মধ্যে সীমাবদ্ধ একটি অস্থায়ী রেকর্ডিং করে, তারপর রেকর্ডার বন্ধ করে ফাইল মুছে
দেয়। টার্মাক্স:এপিআই না থাকলে সক্রিয় ওপেনএসএল ইনপুট অল্প সময়ের জন্য চালু
হতে পারে; ধারণ করা শব্দ সংরক্ষণ করা হয় না। `tx cam` একটি অস্থায়ী পেছনের
ক্যামেরার ছবি তুলে টার্মাক্স:এপিআই-এর ক্যামেরা অনুমতি চায়, তারপর ছবিটি মুছে
দেয়। দুই কমান্ডের জন্য `termux-api` প্যাকেজ এবং টার্মাক্স যে উৎস থেকে ইনস্টল
করা, সেই একই উৎসের টার্মাক্স:এপিআই অ্যান্ড্রয়েড অ্যাপ লাগবে। সহায়ক অ্যাপ না
থাকলেও টার্মাক্সের ওপেনএসএল সেতু দিয়ে ডেস্কটপের মাইক্রোফোন চলে; ক্যামেরার
বিকল্প হিসেবে অ্যান্ড্রয়েড ক্যামেরা ব্যবহার করুন। টার্মাক্স এবং
টার্মাক্স:এপিআই-এর অ্যান্ড্রয়েড অনুমতি আলাদা।

### `tx manager`

কোনো service বা guest চালু না করেই Native Termux manager-এর read-only snapshot
দেখুন। এই command-গুলো installed PRoot guest, পরিচিত desktop profile এবং বর্তমান/
পরিকল্পিত display assignment দেখায়। `displays` socket/lock/server occupancy জানায়
এবং v2 display migration দরকার কি না দেখায়; কোনো assignment বদলায় বা চলমান
session সরায় না। Schema-গুলো `docs/v3/schemas/manager-*.schema.json`-এ আছে।
Local Unix-socket API দরকার হলে `tx manager serve` চালান; এটি Ctrl-C না দেওয়া পর্যন্ত
foreground-এ চলে, private socket ব্যবহার করে এবং TCP listener খোলে না। এই command-এর
জন্য Python 3 optional।

**কোন সংস্করণে আছে:** read-only manager command ও socket service বর্তমান source-এ
আছে; withdrawn v2.0.0 APT package-এ নেই। JSON compatibility-র জন্য
`schema_version` ও `command` দেখুন। Display JSON schema `1.3.0`; কোনো running guest-এর
সাথে মিল পাওয়া assignment OS-level socket ownership-এর প্রমাণ নয়।

```bash
tx manager status [--json]
tx manager guests [--json]
tx manager displays [--json]
tx manager capabilities [--json]
tx manager migrate --apply sha256:PLAN_ID
tx manager migrate --recover
```

`tx manager displays --json`-এ guest-পিছু read-only migration preview থাকে। এতে
`initialize`, `keep` বা `move` plan এবং active session, target conflict অথবা
invalid registry blocker দেখা যায়। Preview read-only এবং এতে state-bound `plan_id` থাকে। শুধু বর্তমান snapshot থেকে
ready plan দেখে `tx manager migrate --apply sha256:PLAN_ID` চালিয়ে apply করা যায়।
পুরোনো plan, active session, occupied target, malformed বা mismatch registry, এবং
STOPPED নয় এমন lifecycle থাকলে apply প্রত্যাখ্যান করে। লেখার আগে profile ও registry
backup journal-এ থাকে; write ব্যর্থ হলে দুটোই rollback হয়। মাঝপথে process বন্ধ হলে
আগে `tx manager migrate --recover` চালাতে হবে; তার আগে guest start আটকে থাকে।
Migration নিজে desktop stop বা restart করে না।

### `tx control`

এই device-এর browser-এ mobile-first Control Center খুলুন। এতে manager-এর স্বাস্থ্য,
installed guest, active desktop, display conflict, migration preview এবং copy করার host
command দেখায়। Installed Ternux desktop guest-এর জন্য state-bound plan ও browser-এ
স্পষ্ট confirmation নিয়ে start বা stop request করা যায়; প্রতিটি request-এর অগ্রগতি local
job record-এ থাকে। Generic OCI image install/uninstall এখানে নেই। Loopback-only server
এক ঘণ্টার in-memory bearer token, action-এর জন্য same-origin ও CSRF check, এবং নির্দিষ্ট
CLI argument ব্যবহার করে। Termux-এ Ctrl-C দিলে server বন্ধ হয়; অসমাপ্ত job পরেরবার
চালু হলে status মিলিয়ে দেখার জন্য চিহ্নিত হয়। Python 3 optional: `pkg install python`।
Browser না খুলে local link দেখাতে `--no-open` ব্যবহার করুন।

```bash
tx control
tx control --no-open
```

Dashboard ও manager command পরের stable v2-major release-এর জন্য source-এ আছে;
withdrawn v2.0.0 package-এ নেই।

### `tx guides`

Termux host অথবা Debian/Xfce guest-এ `tx guides` চালালে installation,
workload, ecosystem tool, graphics-persistence এবং daily-use guide-এর link দেখা যায়। এটি
কিছু
install করে না।

### `tx storage`

PRoot-এ Android shared storage default-এ hidden থাকে। `/sdcard`-এর নিচে থাকা
বিদ্যমান একটি directory grant করলে generic guest command এবং পরের desktop session-এ
শুধু ওই directory mount হয়। পুরো storage root grant করা যায় না। দরকার হলে grant
করার সময়ই Android storage permission চাওয়া হয়। Revoke করলে grant মুছে যায়;
চলমান desktop session বন্ধ হওয়া পর্যন্ত আগের mount থাকবে।

```bash
ternux storage list
ternux storage grant /sdcard/Llms
ternux storage revoke /sdcard/Llms
```

### `tx install`

সম্পূর্ণ টার্নাক্স ডেস্কটপ ইনস্টল বা পুনরায় ইনস্টল করুন।

```bash
tx install [options]
```

| বিকল্প | কাজ |
|-------|-----|
| `--yes` | প্রশ্ন না করে পূর্বনির্ধারিত পছন্দ নেয় |
| `--user NAME` | লিনাক্স গেস্টের ব্যবহারকারীর নাম ঠিক করে; পূর্বনির্ধারিত নাম `ternux` |
| `--distro NAME` | ১৫টি নামযুক্ত ডেস্কটপ বিন্যাসের একটি বেছে নেয় |
| `--distros LIST` | কমা দিয়ে আলাদা করে একাধিক গেস্ট ইনস্টল করে |
| `--locale LANG` | লোকেল ঠিক করে; পূর্বনির্ধারিত `en_US.UTF-8` |
| `--backend auto\|zink\|virgl` | গ্রাফিক্স ব্যাকএন্ড বেছে নেয় |
| `--zsh` | `bash`-এর বদলে `zsh` ব্যবহার করে |
| `--with-dev` | উন্নয়ন সরঞ্জাম যোগ করে |
| `--with-llm` | ভলকানসহ `llama.cpp` তৈরি করে |
| `--with-network` | নেটওয়ার্ক সরঞ্জাম যোগ করে |
| `--with-media` | ছবি ও শব্দের কাজের সরঞ্জাম যোগ করে |
| `--with-blender` | `Blender` এবং জিপিইউ-ছাড়া রেন্ডারের জন্য `Xvfb` যোগ করে |
| `--all` | সব ঐচ্ছিক কাজের সরঞ্জাম যোগ করে |
| `--resume` | শেষ হওয়া ধাপ বাদ দিয়ে থেমে যাওয়া ইনস্টল চালিয়ে যায় |

নামযুক্ত ডেস্কটপ বিন্যাসের স্থায়ী ক্রম: `debian`/`db`, `ubuntu`/`ub`,
`kali`, `alpine`/`alp`, `archlinux`/`archx`, `fedora`/`fed`,
`opensuse`/`suse`, `void`/`vsh`, `artix`/`art`, `chimera`/`chim`,
`deepin`/`deep`, `manjaro`/`manj`, `pardus`/`par`, `rockylinux`/`rock` এবং
`adelie`/`adel`। কালি ইনস্টলে কালি প্রকল্পের `kalilinux/kali-rolling` OCI
ছবি ব্যবহার হয়, কারণ টার্মাক্সের `PRoot-Distro` প্যাকেজে কালি নামটি নেই।
কালির ডেস্কটপে টার্নাক্সের এক্সএফসিই আছে; এটি কালির পূর্ণ ডেস্কটপ ইমেজ নয়।
ডিফল্টে এনম্যাপ, এসকিউএলম্যাপ, হাইড্রা, জন দ্য রিপার, গোবাস্টার, নিকটো, হুইজ
ও নেটক্যাট বসে। বড় কালি প্যাকেট-সমষ্টি ডিফল্টে বসে না; সেগুলোতে অ্যান্ড্রয়েডের
পিআরুটে কাজে না-লাগা কিছু বিশেষ সুবিধা ও ওয়াই-ফাই-নির্ভর সরঞ্জামসহ অনেক প্যাকেট থাকে।
২০২৬-১১-১৫ তারিখে কালি `:3` প্রদর্শনে জিঙ্ক/টার্নিপ গ্রাফিক্স দেখা গেছে; তবে
কালির পূর্ণ ডেস্কটপ এখনও যন্ত্রে যাচাইকৃত নয়। যন্ত্রে যাচাই করা হয়েছে ডেবিয়ান,
উবুন্টু ও অ্যালপাইন। অ্যালপাইনে `Ctrl+Space`-এর কৃত্রিম
কিবোর্ড সংকেতে অমিল আছে। অন্য বিন্যাসগুলো যন্ত্রে যাচাই করা হয়নি।

ইন্টারঅ্যাকটিভ ইনস্টলে তালিকা থেকে একাধিক গেস্ট বাছুন। স্বয়ংক্রিয় ইনস্টলে
`--distros`-এর সঙ্গে কমা-আলাদা নাম দিন, যেমন
`tx install --distros debian,ubuntu,kali,alpine`। প্রতিটি গেস্টের নিজস্ব অবস্থা
ও চিহ্নিত টার্মাক্স:এক্স১১ প্রদর্শন থাকে। ইনস্টল শুরুর আগে গেস্ট, গ্রাফিক্স
ব্যাকএন্ড, ব্যবহারকারী, ঐচ্ছিক সরঞ্জাম ও প্রয়োজনীয় জায়গা দেখানো হয়। মূল
ডেস্কটপ যাচাই হলেও ঐচ্ছিক সরঞ্জাম ব্যর্থ হলে গেস্ট প্রস্তুত থাকে, সতর্কতা
দেখায় এবং কমান্ড ব্যর্থতার সংকেত দেয়। থেমে যাওয়া ধাপ আবার চালাতে
`tx install --resume` ব্যবহার করুন।

### গেস্ট ব্যবস্থাপনা

শুধু `tx distro` চালালে গেস্ট ব্যবস্থাপনার সংক্ষিপ্ত পরিচিতি ও সব উপকমান্ড
দেখায়। `tx distro list` ইনস্টল-ক্রমে টার্নাক্সের সব ডেস্কটপ বিন্যাসের তালিকা,
সংক্ষিপ্ত নাম, পূর্বনির্ধারিত এক্স১১ প্রদর্শন নম্বর, প্যাকেজ পরিবার, প্রস্তাবিত
গ্রাফিক্স পথ এবং ইনস্টল/যাচাই অবস্থা দেখায়। সাধারণ ওসিআই গেস্ট ডেস্কটপ
বিন্যাস পায় না, তাই সেগুলো আলাদা অংশে থাকে।

`tx distro search QUERY` গেস্টের ছবি খোঁজে।
`tx distro shell NAME` প্রোফাইলে ঠিক করা সাধারণ ব্যবহারকারীর শেল খোলে;
সাধারণ OCI ছবিতে ছবির পূর্বনির্ধারিত ব্যবহারকারী থাকে। `tx distro root NAME`
মূল ব্যবহারকারীর শেল খোলে। `tx distro exec NAME -- COMMAND` গেস্টের ভেতরে
নির্দিষ্ট কমান্ড চালায়। সাধারণ OCI ছবি শুধু শেল-গেস্ট; ডেস্কটপ প্রোফাইলের
জন্য তালিকাভুক্ত বিন্যাস ব্যবহার করুন। `tx distro search QUERY` ছবি খোঁজে;
`tx distro image-install IMAGE[:TAG] [NAME]` সাধারণ OCI ছবি ইনস্টল করে;
`tx distro uninstall NAME [--yes]` নিবন্ধিত গেস্ট সরায়।

ব্যবহারকারীর শেলের সংক্ষিপ্ত নাম: `db`, `ub`, `kali`, `alp`, `archx`,
`fed`, `suse` ও `vsh`; কালির মূল-ব্যবহারকারী শেলের জন্য `kalir` বা `kaliroot`
এবং অন্য অতিথির জন্য `dbroot`, `ubroot`, `alproot`, `archroot`, `fedr`,
`suser` ও `vroot` আছে। সব অতিথি ও
সংক্ষিপ্ত নামের তালিকা `tx distro list`-এ দেখুন। `xgo` ইনস্টল করা ডেস্কটপ
গেস্টের তালিকা দেখায় এবং একটি বেছে নিতে দেয়।

### `tx start`

ডেস্কটপ চালু করতে `tx start` ব্যবহার করুন। একাধিক ইনস্টল করা ডেস্কটপ ধারাবাহিকভাবে
চালাতে পূর্ণ নাম বা সংক্ষিপ্ত নাম দিন:

```bash
tx start debian ubuntu kali alpine
tx start ub db kali alp
```

একটি গেস্ট ব্যর্থ হলেও পরেরগুলোর চেষ্টা হয়; শেষে প্রতিটি গেস্টের ফল দেখিয়ে
কোনোটি ব্যর্থ হলে কমান্ড ব্যর্থতার সংকেত দেয়। `--json` দিলে সব গেস্টের ফল
একটি JSON অবজেক্টে পাওয়া যায়। নতুন বিন্যাসে `:0` স্থানীয় টার্মাক্স কর্মক্ষেত্রের
জন্য; ডেবিয়ান `:1`, উবুন্টু `:2`, কালি `:3`, অ্যালপাইন `:4` এবং পরের
নামযুক্ত বিন্যাসগুলো `:5` থেকে প্রদর্শন পায়। আগে সংরক্ষিত v2 প্রদর্শন নম্বর
স্পষ্ট স্থানান্তর না হওয়া পর্যন্ত বদলায় না। স্থানান্তরের আগে
`tx manager displays` দিয়ে অবস্থা দেখুন। লক্ষ্য সকেট বা টার্মাক্স:এক্স১১
সার্ভার ব্যস্ত থাকলে ডেস্কটপ চালু হবে না। চালু সেশন আবার আনতে একই কমান্ড দিন।
সমস্যা হলে `tx status` এবং `tx logs desktop show` চালান।

### `tx stop`

`tx stop` চালু ডেস্কটপগুলোর তালিকা দেখিয়ে এক বা একাধিকটি বাছতে দেয়। নাম অথবা
তালিকার নম্বর দিন; একাধিক পছন্দ ফাঁক বা কমা দিয়ে আলাদা করুন, আর `0` দিলে
বাতিল হয়। নির্দিষ্ট গেস্ট বন্ধ করতে `tx stop db`, `tx stop ub`, `tx stop kali`
বা `tx stop alp` চালান। `tx stop --all` সব ডেস্কটপ বন্ধ করে।

### `tx restart`

নির্দিষ্ট ডেস্কটপ বন্ধ করে আবার চালায়। যেমন:

```bash
tx restart debian
```

### `tx doctor`

বিভাগ অনুযায়ী রোগ-নির্ণয় চালান। প্রতিটি পরীক্ষার ফল `ok`, `warn`, `fail` বা `info` হিসেবে সমাধানের নির্দেশসহ দেখানো হয়। কোনো অতিথির নাম না দিলে হোস্ট, ব্যবস্থা, ইনস্টল করা সব পরিচালিত অতিথি, গ্রাফিক্স এবং ডেবিয়ানের এক্সটেনশন পরীক্ষা হয়। পূর্ণ বা সংক্ষিপ্ত অতিথির নাম দিলে সেই অতিথি ও তার গ্রাফিক্স পরীক্ষা হয়। শুধু গ্রাফিক্স পরীক্ষার জন্য `gpu` দিন।

| বিভাগ | পরীক্ষা |
|---|---|
| `system` | স্থাপত্য, সংরক্ষণ-জায়গা, স্মৃতি, ব্যাটারির তাপমাত্রা, অবস্থা-ডিরেক্টরি |
| `host` | প্রুট-ডিস্ট্রো, ইনস্টল করা অতিথি, টার্মাক্স:এক্স১১, পালসঅডিও, কার্ল, অ্যান্ড্রয়েডের শিশু-প্রক্রিয়া সেটিং |
| `guest` | প্রতিটি অতিথির ব্যবস্থা, স্থাপত্য, গ্লিবসি যেখানে আছে, সুডো, ডেস্কটপ নির্দেশনা, প্যাকেজ-তথ্য ও ফাঁকা জায়গা |
| `graphics` / `gpu` | ভলকান, জিপিইউ, অতিথিভিত্তিক ব্যাকএন্ড, কেজিএসএল নোড, টার্নিপ বিন্যাস, রেন্ডারার, লঞ্চার, ভারজিএল |
| `extensions` | ডেবিয়ানের এক্সটেনশন: প্যাকেজ, সংস্করণ, চলতি লাইব্রেরি ও লঞ্চার ফাইল |

অতিথির পরীক্ষা প্রতিটি অতিথির ভেতরে শুধু-পড়া অনুসন্ধান চালায়। কোনো অতিথিতে ঢোকা না গেলে সেটি ত্রুটি না দেখিয়ে `info` হিসেবে জানায়।

```bash
tx doctor [CATEGORY|DISTRO ...] [--quick] [--strict] [--json]
tx doc gpu
tx doctor kali
tx doctor db gpu
```

| বিকল্প | কাজ |
|---|---|
| `CATEGORY` | এক বা একাধিক বিভাগ চালান, যেমন `tx doctor extensions`; `gpu` শুধু গ্রাফিক্স পরীক্ষা চালায় |
| `DISTRO` | পূর্ণ বা সংক্ষিপ্ত নামে একটি অতিথি বাছুন, যেমন `kali`, `db` বা `ub` |
| `--quick` | অতিথিতে প্রবেশ করে চালানো পরীক্ষা বাদ দেয় |
| `--strict` | warning থাকলে `1` ও check ব্যর্থ হলে `2` exit করে; default exit status `0`-ই থাকে |
| `--json` | machine-readable output |

**JSON output-এর উদাহরণ** (সংক্ষেপিত; `schema_version` 2 মূল `issues` ও `recommended_actions` array রাখে এবং `summary` ও `checks` যোগ করে):
```json
{
  "command": "doctor",
  "status": "warning",
  "gpu": "Adreno (730)",
  "backend": "zink",
  "renderer": "zink Vulkan (Adreno ... (MESA_TURNIP))",
  "vulkan": "yes",
  "schema_version": 2,
  "summary": {"ok": 30, "warn": 1, "fail": 0, "info": 3},
  "checks": [
    {"id": "ext_llama-vulkan", "category": "extensions", "status": "ok",
     "title": "llama-vulkan: ternux-llama-vulkan-linux-arm64-b11582",
     "detail": "", "fix": ""}
  ],
  "issues": ["phantom_process_killer_enabled"],
  "recommended_actions": ["Review Android process restrictions and other Signal 9 causes (see docs)"]
}
```

### `tx repair`

ছয় ধাপে common issue inspect/repair করে:

1. broken curl/OpenSSL host toolchain;
2. missing `termux-x11-nightly`;
3. configured backend apply, stored SHA-256 অনুযায়ী missing/changed Turnip
   target reinstall, এবং launcher backend alignment;
4. missing বা syntax-broken launcher regeneration;
5. populated Mesa shader cache clear;
6. missing PulseAudio TCP bridge add।

Healthy check repair count-এ যোগ হয় না। যেকোনো step fail হলে অন্য step চলতে
পারে, কিন্তু শেষ status non-zero হয়। Backend/launcher repair-এর পর desktop
restart করে renderer আবার verify করুন।

```bash
ternux repair
```

### `tx verify`

বর্তমানে active guest-এর installation যাচাই করে; চাইলে full distro name বা
short command দিয়ে নির্দিষ্ট guest বেছে নিন। Active guest না থাকলে saved
installed profile, তারপর Debian, তারপর অন্য installed Ternux profile নেওয়া হয়।
এটি host binary, launcher, guest service ও GPU driver যাচাই করে। Human এবং
`--json`—দুই mode-এই ব্যর্থ verification nonzero exit status দেয়।

```bash
ternux verify [DISTRO] [--json]
tx verify db --json
tx verify ub --json
tx verify alp --json
```

### `tx benchmark`

Active desktop-এ Debian container-এর ভেতর glmark2/vkmark health benchmark এবং
renderer inspection চালায়। Renderer classification `llvmpipe`, Zink/Turnip,
plain Zink, বা VirGL/virpipe route আলাদা করে; শুধু VirGL নাম hardware-backed
route প্রমাণ করে না। এটি archived evidence run-এর identical protocol নয়।

```bash
ternux benchmark [--json]
```

### `tx profile`

ডিভাইস প্রোফাইলিং ও ব্যবস্থাপনা।

```bash
ternux profile <subcommand> [name]
```

| সাবকমান্ড | বিবরণ |
|-----------|--------|
| `show` | বর্তমান প্রোফাইল দেখান |
| `save [name]` | প্রোফাইল সেভ করুন (ডিফল্ট: `default`) |
| `load [name]` | সেভ করা প্রোফাইল লোড করুন |
| `list` | সব প্রোফাইল তালিকা |
| `compare [a] [b]` | দুটি প্রোফাইল তুলনা |

### `tx backend`

GPU ব্যাকএন্ড ব্যবস্থাপনা।

```bash
ternux backend <subcommand> [backend]
```

| সাবকমান্ড | বিবরণ |
|-----------|--------|
| `show` | বর্তমান ব্যাকএন্ড দেখান |
| `set auto\|zink\|virgl` | GPU ব্যাকএন্ড পরিবর্তন |
| `detect` | স্বয়ংক্রিয় ব্যাকএন্ড শনাক্ত |

### `tx gpu`

GPU backend ও guest userspace driver দেখুন বা update করুন। `update` Zink route-এ
Ternux-এর pinned এবং SHA-256-যাচাইকৃত Debian Turnip driver আবার install করে;
তারপর desktop restart করতে হবে। এটি Android-এর vendor/kernel driver update করে না।
VirGL route-এ guest Turnip driver ব্যবহৃত হয় না।

```bash
ternux gpu show
ternux gpu update
ternux gpu update --json
```

`tx backend update` একই কাজের সমতুল্য command।

### `tx info`

অ্যান্ড্রয়েড এসডিকে, যন্ত্র ও প্রসেসরের বিবরণ, মোট ও ব্যবহারযোগ্য মেমরি,
খালি সংরক্ষণ-জায়গা, অ্যান্ড্রয়েড পড়তে দিলে কাজের চাপের গড়, জিপিইউ ও
ব্যাকএন্ড, চলতি ওপেনজিএল রেন্ডারার, ভলকান অবস্থা এবং ফ্যান্টম প্রসেস বন্ধের
সেটিং পড়া যাচ্ছে কি না দেখায়। `Renderer: not running` মানে টার্মাক্স:এক্স১১
বন্ধ; `unknown` মানে প্রদর্শন চালু ছিল, কিন্তু গেস্টের রেন্ডারার অনুসন্ধান নাম
দিতে পারেনি। কোনো ডেস্কটপ প্রদর্শন চালু না থাকলে গ্রাফিক্স অবস্থা
`DISPLAY_STOPPED` দেখায়। অ্যান্ড্রয়েডের কোনো সংস্করণে সেটিংস-এ টার্মাক্সের
প্রবেশাধিকার না থাকলে ফ্যান্টম প্রসেস সেটিং চালু বা বন্ধ অনুমান না করে পড়া
যাচ্ছে না বলে দেখায়। ডেস্কটপের চলতি অবস্থা দেখতে `tx status [DISTRO]`, আর
হোস্টের প্রস্তুতি দেখতে `tx doctor --quick` চালান।

জিপিইউ শনাক্ত করতে অ্যান্ড্রয়েডের গ্রাফিক্স বৈশিষ্ট্য ও কার্নেল ইন্টারফেস দেখা
হয়। কেজিএসএল-সহ অ্যাড্রেনো হলে কেবল সমর্থিত গেস্ট বিন্যাসে জিঙ্ক/টার্নিপ পথ
নেওয়া হয়। কালির জন্য এখন ভিরজিএল ব্যবহৃত হয়; তার প্যাকেটভুক্ত জিঙ্ক বিন্যাস
পরীক্ষায় চালু হয়নি এবং যাচাইকৃত টার্নিপ প্যাকেটও নেই। অন্য জিপিইউ পরিবারেও
ভিরজিএল ব্যবহৃত হয়; অ্যান্ড্রয়েডের হোস্ট গ্রাফিক্স ব্যবস্থা সেখানে রেন্ডারিং
যন্ত্র সরবরাহ করে। নির্বাচিত পথটি কেবল বিন্যাস—ডেস্কটপে হার্ডওয়্যার ত্বরণ চলছে
তার প্রমাণ নয়। চলতি রেন্ডারার ও গ্রাফিক্স অবস্থাও দেখুন।

```bash
ternux info [--json]
```

### `tx state`

ইনস্টলার সম্পন্ন ধাপ, সংরক্ষিত ব্যবহারকারী/গেস্ট/লোকেল, ইনস্টল করা পরিচালিত
গেস্টের প্রদর্শন নম্বর ও প্রস্তুতির অবস্থা এবং সাম্প্রতিক কর্মদক্ষতা/মেরামতের
ইতিহাস দেখায়। JSON ফলাফলে `installed_profiles` থাকে।

```bash
ternux state [--json]
```

### `terfetch`

`terfetch` একটি স্বতন্ত্র সিস্টেম-তথ্য প্রদর্শক; এটি টার্মাক্স হোস্ট ও প্রতিটি
পরিচালিত গেস্টে বসে। টার্মাক্সের নিজস্ব লগইন ব্যানার বন্ধ করতে সমর্থিত
`~/.hushlogin` ফাইল ব্যবহার হয়; এরপর নতুন ইন্টারঅ্যাক্টিভ ব্যাশ বা জেডশ শেলে
তার বদলে টারফেচ দেখায়। গেস্টে চালালে সেই গেস্টের অপারেটিং সিস্টেম ও সম্পদের
তথ্য দেখায়। একটি শেলে স্বয়ংক্রিয় প্রদর্শন বন্ধ করতে
`TERFETCH_NO_AUTORUN=1` দিন। কাঠামোবদ্ধ ফলাফলের জন্য `terfetch --json` এবং
সব বিকল্পের জন্য `terfetch --help` চালান। পরে আলাদা সংগ্রহশালা বানিয়ে এখানকার
কোড সরানো যাবে; তার জন্য মূল ফাইলগুলো `share/terfetch/`-এ রাখা আছে।

```bash
terfetch
terfetch --json
```

### `tx status`

অতিথির নাম ছাড়া চালালে ইনস্টল করা সব পরিচালিত ডেস্কটপের অবস্থা একসঙ্গে দেখায়;
পূর্ণ বা সংক্ষিপ্ত নাম দিলে একটি অতিথির অবস্থা দেখায়। `running` দেখানোর আগে
অতিথির ভেতরে নির্দিষ্ট সময়ের মধ্যে এক্স১১ অনুসন্ধান সফল হতে হয়; শুধু সকেট বা
প্রসেস থাকলেই ডেস্কটপ ব্যবহারযোগ্য ধরা হয় না। `pulseaudio` হোস্টে শব্দসেবা
চলছে কি না জানায়; `pulseaudio_ready` ডেবিয়ান অ্যাপের জন্য স্থানীয় টিসিপি
শব্দপথ আলাদাভাবে যাচাই করে।

```bash
tx status [--json]
tx status kali --json
```

একটি অতিথির JSON ফলাফলে `lifecycle`, `x11_running`, `pulseaudio`, `pulseaudio_ready`,
`virgl`, `launcher`, `display`, `desktop_log` ও `desktop_pid` থাকে। একাধিক
অতিথির ফলাফলে `guest_count` এবং `guests` তালিকায় প্রত্যেকের আলাদা তথ্য থাকে।

### `tx logs`

ইনস্টলার, হোস্ট এবং প্রতিটি অতিথির ডেস্কটপ লগ দেখা ও ব্যবস্থাপনা। `list`
লগের পথ ও আকার দেখায়; `desktop show` ও `desktop tail` চলতি অথবা সর্বশেষ
সংরক্ষিত অতিথির লগ খোলে। নির্দিষ্ট অতিথির লগের জন্য নাম যোগ করুন:
`tx logs desktop show kali`।

```bash
ternux logs <subcommand> [n]
```

| সাবকমান্ড | বিবরণ |
|-----------|--------|
| `show [n]` | শেষ n লাইন দেখান (ডিফল্ট: ৫০) |
| `tail` | রিয়েল-টাইম লগ দেখা |
| `clear` | লগ ফাইল মুছে ফেলা |
| `list` | লগ ফাইলের তালিকা |
| `desktop [show|tail]` | ডেস্কটপ সেশনের লগ পড়ুন বা সরাসরি অনুসরণ করুন |

### `tx extension`

ঐচ্ছিক release-ভিত্তিক Linux ARM64 extension list, install, repair বা remove করে। Host CLI কাজগুলো নির্বাচিত Debian guest-এ পাঠিয়ে দেয়।

```bash
ternux extension list
ternux extension install llama-vulkan
ternux extension install stable-diffusion
ternux extension install llama-htp-experimental
ternux extension repair stable-diffusion
ternux extension remove stable-diffusion
```

`llama-vulkan` হলো CPU + Vulkan prerelease। `stable-diffusion` pinned `sd-cli` preview install করে; Adreno Vulkan generation device-এ সীমিতভাবে test হয়েছে, CPU image quality unqualified। Model weights user-এর কাছেই থাকে। Repair checksum verify করে recognized install atomicভাবে replace করে; ব্যর্থ হলে আগের install restore করে। Remove শুধু recognized extension directory delete করে, model weights অক্ষত রাখে। `llama-htp-experimental` হলো
সীমিত experimental SM8735/V73 route; এটি supported release feature নয় এবং
automatic CPU/GPU fallback নেই।
[CPU/Vulkan guide](https://github.com/soobujmiah/ternux/blob/main/bn/guides/llama-vulkan-extension.md)
ও [Stable Diffusion guide](https://github.com/soobujmiah/ternux/blob/main/bn/guides/stable-diffusion-vulkan-extension.md) এবং [HTP guide](https://github.com/soobujmiah/ternux/blob/main/bn/guides/llama-htp-experimental.md) দেখুন।

### `tx update`

CLI-কে তার install source অনুযায়ী আপডেট করে। APT-managed install APT দিয়ে update/check করে; অন্য install GitHub থেকে self-update করে।

```bash
ternux update [check]
```

| সাবকমান্ড | বিবরণ |
|-----------|--------|
| *(none)* | APT package-managed হলে configured repository থেকে update; অন্যথায় GitHub থেকে latest version download/install |
| `check` | ইনস্টল না করেই আপডেট চেক; APT-managed install configured package candidate দেখে |

### `tx uninstall`

Scoped component removal। Action না দিলে interactive menu; non-interactive
shell-এ action অবশ্যই explicit দিন।

```bash
ternux uninstall [session|launcher|state|container|all] [--yes]
```

- `session` / `1` — desktop service stop ও stale socket cleanup
- `launcher` / `2` — `~/x.sh` এবং delimited shell-alias block remove
- `state` / `3` — ternux state/log remove; Debian অক্ষত
- `container` / `4` — Debian ও তার ভেতরের সব data delete
- `all` / `5` — উপরের চারটি action
- `0` — cancel

`all` Termux package বা ternux CLI/library uninstall, storage access revoke,
mirror reset বা Termux PulseAudio configuration revert করে না। Container deletion
confirmation চায়। Automation-এ irreversible data loss ইচ্ছাকৃতভাবে accept
করলেই শুধু `--yes` দিন।

## শেল কমপ্লিশন

Bash কমপ্লিশন উপলব্ধ `share/ternux-completion.bash`-এ:

```bash
source share/ternux-completion.bash
```

<h2 id="environment-variables">এনভায়রনমেন্ট ভেরিয়েবল</h2>

নিচের প্রতিটি ভেরিয়েবল শুরুতেই পড়া হয়; কমান্ড-লাইন ফ্ল্যাগ সবসময় অগ্রাধিকার পায়।

| ভেরিয়েবল | কোথায় কাজ করে | কাজ |
|---|---|---|
| `TERNUX_UI` | `install` | রেন্ডারার নির্বাচন: `auto`, `dashboard`, `plain`, `off` |
| `TERNUX_NO_ANIM` | `install` | `1` দিলে স্পিনার ও রঙ বদল থেমে যায় |
| `TERNUX_YES` | `install` | `1` দিলে নথিভুক্ত default প্রশ্ন ছাড়াই নেওয়া হয় |
| `TERNUX_QUIET` | সব | সাধারণ তথ্যমূলক বার্তা বন্ধ করে |
| `TERNUX_JSON` | নথিভুক্ত কমান্ড | structured output চায় |
| `TERNUX_VERBOSE` | সব | যেসব কমান্ডে আছে সেখানে debug বার্তা চালু করে |
| `TERNUX_USER` | সব | CLI যে Debian অ্যাকাউন্ট ধরে কাজ করে; সাধারণত saved state থেকে আসে |
| `TERNUX_STATE_DIR` | সব | ফেজ state ও সংরক্ষিত পছন্দ (ডিফল্ট `~/.local/share/ternux`) |
| `TERNUX_LOG_DIR` | সব | লগ ডিরেক্টরি (ডিফল্ট `$TMPDIR/ternux`) |

পূর্ণ বিবরণ: [কনফিগারেশন → ইনস্টলার আউটপুট](CONFIGURATION.html#installer-output)।

---

## আর্কিটেকচার

```
bin/ternux          ← thin command/flag dispatcher
lib/core.sh         ← শেয়ার্ড I/O, JSON বিল্ডার, স্টেট, লগিং
lib/help.sh         ← সেন্ট্রালাইজড হেল্প
lib/detect.sh       ← ডিভাইস ডিটেকশন
lib/desktop.sh      ← ডেস্কটপ লাইফসাইকেল
lib/doctor.sh       ← ডায়াগনস্টিক + ভেরিফিকেশন
lib/info.sh         ← সিস্টেম তথ্য
lib/backend.sh      ← GPU ব্যাকএন্ড
lib/profile.sh      ← ডিভাইস প্রোফাইলিং
lib/benchmark.sh    ← GPU benchmark ও renderer classification
lib/repair.sh       ← validated phase দিয়ে repair engine
lib/logs.sh         ← লগ ব্যবস্থাপনা
lib/update.sh       ← সেলফ-আপডেট
lib/state.sh        ← installation state
lib/uninstall.sh    ← scoped, confirmed component removal
lib/phases.sh       ← ইনস্টলেশন implementation (১১টি ধাপ)
lib/ui.sh           ← ইনস্টলার রেন্ডারার: dashboard, plain frame, log stream
```

নতুন কমান্ড যোগ করা:
1. `lib/<name>.sh` তৈরি করুন `tnx_cmd_<name>()` ফাংশন দিয়ে
2. `lib/help.sh`-এ `tnx_help_<name>()` যোগ করুন
3. শেষ — ডিসপ্যাচার স্বয়ংক্রিয় শনাক্ত করে

---

*ternux — সর্বস্বত্ব (c) ২০২৬ Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · Apache-2.0 লাইসেন্স*
