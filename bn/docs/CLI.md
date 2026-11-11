---
title: "CLI রেফারেন্স"
description: "ternux কমান্ড-লাইন ইন্টারফেসের রেফারেন্স — command, subcommand, global flag ও নথিভুক্ত JSON output।"
lang: "bn"
alt_url: "/docs/CLI.html"
---

`ternux` CLI হলো স্থায়ী ব্যবস্থাপনা ইন্টারফেস — ইনস্টল, ডায়াগনস্টিক,
মেরামত, বেঞ্চমার্ক, ডেস্কটপ লাইফসাইকেল ও সিস্টেম তথ্যের জন্য।

এই reference `$PREFIX/bin/ternux`-এ installed পূর্ণ **Termux host** command-এর।
Debian/Xfce terminal-এ আলাদা guest-aware `/usr/local/bin/ternux` companion আছে;
এটি শুধু `status`, `info`, `doctor` (`verify` একই কাজের alias), `env`, `--version`
ও help দেয়। Nested PRoot না খুলে host lifecycle command প্রত্যাখ্যান করে। নিচের
host commandগুলো Termux-এ
চালান। Installer command দুটি execute ও version-check করে; শুধু file presence-কে
successful CLI installation ধরা হয় না।

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

### `ternux guides`

Termux host অথবা Debian/Xfce guest-এ `ternux guides` চালালে installation,
workload, ecosystem tool, graphics-persistence এবং daily-use guide-এর link দেখা যায়। এটি
কিছু
install করে না।

### `ternux storage`

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

### `ternux install`

সম্পূর্ণ ternux ডেস্কটপ ইনস্টল বা পুনরায় ইনস্টল।

```bash
ternux install [options]
```

| অপশন | বিবরণ |
|-------|--------|
| `--yes` | ডিফল্ট, কোনো প্রশ্ন নয় |
| `--user NAME` | Linux guest ইউজারনেম (ডিফল্ট: `ternux`) |
| `--distro NAME` | Debian বা Ubuntu guest profile বাছুন; Debian device-verified। |
| `--distros LIST` | একাধিক আলাদা guest ধারাবাহিকভাবে install, যেমন `debian,ubuntu`। |
| `--locale LANG` | লোকেল (ডিফল্ট: `en_US.UTF-8`) |
| `--backend auto\|zink\|virgl` | GPU ব্যাকএন্ড (ডিফল্ট: auto) |
| `--zsh` | bash-এর বদলে zsh ব্যবহার |
| `--with-dev` | ডেভেলপমেন্ট টুলস ইনস্টল |
| `--with-llm` | Vulkan-সহ llama.cpp বিল্ড |
| `--with-network` | নেটওয়ার্ক টুলস ইনস্টল |
| `--with-media` | মিডিয়া টুলস ইনস্টল |
| `--with-blender` | Blender ও headless GPU render-এর জন্য Xvfb ইনস্টল |
| `--all` | সব ঐচ্ছিক ওয়ার্কলোড |
| `--resume` | completed phase skip এবং interrupted run-এর saved optional workload set restore |

Guest prompt-এ Debian (recommended, device-verified) অথবা Ubuntu (snapd pinned/held, device validation বাকি) বাছুন। দুটিতেই একই Ternux base desktop profile বসে; launcher ও user/backend settings আলাদা থাকে। `tx install --distros debian,ubuntu` দুটো guest আলাদাভাবে install করে। Debian ও Ubuntu আলাদা tagged Termux:X11 display ব্যবহার করে এবং একসাথে চালানো যায়। `tx stop` একাধিক চলমান desktop থাকলে একটি বা একাধিক বাছতে দেয়; `tx stop --all` সব বন্ধ করে।

`tx` হলো `ternux`-এর ছোট alias। `tx distro list` সব installed PRoot guest দেখায় এবং কোনগুলোর Ternux desktop recipe আছে তা চিহ্নিত করে। যেকোনো installed guest-এর জন্য `tx distro shell NAME` ও `tx distro exec NAME -- COMMAND` ব্যবহার করুন। Generic OCI image install: `tx distro image-install alpine:latest`—এটি shell guest। বর্তমানে Ternux desktop recipe শুধু Debian ও Ubuntu-র জন্য; matching recipe implement ও qualify না হওয়া পর্যন্ত generic image desktop-ready নয়। `xgo` একাধিক guest থাকলে তালিকা দেখিয়ে desktop বাছতে বলে। `db`/`dbr`, `ub`/`ubr`, `alp`/`alpr` যথাক্রমে Debian, Ubuntu, Alpine-এর user/root shell shortcut। Desktop command: `tx start NAME`, `tx stop [NAME|--all]`, `tx restart NAME`, `tx status NAME`। `tx stop` একাধিক session থাকলে এক বা একাধিক বাছতে দেয়; প্রতিটি stop শুধু ওই guest-এর launcher ও tagged window-তে সীমিত। এখন Debian ও Ubuntu desktop recipe আছে; device-verified শুধু Debian।

Workload flag না দিলে interactive install-এ category-সহ checklist আসে। Up/Down
বা `j`/`k` দিয়ে চলুন, Space বা item-এর নম্বর দিয়ে একাধিক item বাছুন, Enter-এ
plan review করুন, আর শুধু base desktop-এর জন্য `q` চাপুন। আলাদা managed extension
option-এ llama.cpp CPU + Vulkan, Stable Diffusion CPU + Vulkan preview, এবং
experimental SM8735/V73 HTP আছে। `--with-llm` আলাদা source থেকে llama.cpp build
করে। GPU route অনুযায়ী পরামর্শ ও RAM/storage সীমা দেখায়। `--yes` checklist না
দেখিয়ে base profile রাখে।

### `ternux start`

Xfce4 desktop-কে আলাদা detached session-এ চালু করে, তাই shell বন্ধ হলেও desktop চলে। Termux:X11-এর সঙ্গে XFCE session, window manager ও desktop প্রস্তুত হলে Termux:X11 app-টিও সামনে আনে। আবার চালালে নতুন session না বানিয়ে চলমান desktop-টাই সামনে আনে; supervisor marker না থাকলেও live XFCE session শনাক্ত করে। startup ব্যর্থ হলে error দেখিয়ে `~/.local/share/ternux/session/desktop.log`-এর ঠিকানা দেয়। `ternux status` বা `ternux logs desktop tail` দিয়ে session দেখুন। CLI package update-এর পর প্রতিটি guest-এর launcher আলাদা `~/.local/share/ternux/distros/NAME/launcher.sh`-এ থাকে; `~/x.sh` সর্বশেষ install করা profile-এর compatibility link।

```bash
ternux start              # saved guest profile
ternux start ubuntu       # Ubuntu explicitly
```

### `ternux stop`

একটি guest desktop বন্ধ করে। একাধিক display চললে একটি বা একাধিক বাছুন; `--all` সব Ternux desktop বন্ধ করে। অন্য guest display ও shared PulseAudio চলতে থাকে।

```bash
tx stop                   # একটি বা একাধিক চলমান session বাছুন
 tx stop --all            # সব managed desktop বন্ধ
 tx stop ubuntu           # Ubuntu explicitly
```

### `ternux restart`

ডেস্কটপ পুনরায় চালু করে (stop + ১ সেকেন্ড + start)।

```bash
ternux restart
```

### `ternux doctor`

category আনুসরে সাজানো diagnostic চালান। প্রতি check-এর ফল `ok`, `warn`, `fail` বা `info` হিসেবে সমাধানের hint-শহ দেখানো হয়; `info` কেবল প্রসংগ, এখানে কখনো issue গণ্য হয় না।

| Category | Check |
|---|---|
| `system` | architecture, storage, memory, battery তাপমাত্রা, state directory |
| `host` | proot-distro, Debian container, Termux:X11, PulseAudio, curl, Android child-process setting |
| `guest` | Debian glibc, passwordless sudo, desktop command, dpkg অবস্থা, ফাঁকা জায়গা |
| `graphics` | Vulkan, GPU, backend, KGSL node, Turnip layout, renderer, launcher, VirGL |
| `extensions` | install করা extension: package, version, runtime library ও launcher file |

`guest`, `graphics` (Turnip layout) ও `extensions` check-গুলি Debian guest-এর ভিতরে চলা একটি read-only probe থেকে আসে। guest নাগালে না পাওয়া গেলে সেটি `info` হিসেবে জানানো হয়, ত্রুটি হিসেবে না।

```bash
ternux doctor [CATEGORY...] [--quick] [--strict] [--json]
```

| Option | প্রভাব |
|---|---|
| `CATEGORY` | কেবল নামকরা category চালান, যেমন `ternux doctor extensions` |
| `--quick` | Debian guest probe বাদ দেয় |
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

### `ternux repair`

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

### `ternux verify`

ইনস্টলেশন সম্পূর্ণতা যাচাই করে। যাচাই ব্যর্থ হলে human এবং `--json`—দুই
mode-এই nonzero exit status দেয়।

```bash
ternux verify [--json]
```

### `ternux benchmark`

Active desktop-এ Debian container-এর ভেতর glmark2/vkmark health benchmark এবং
renderer inspection চালায়। Renderer classification `llvmpipe`, Zink/Turnip,
plain Zink, বা VirGL/virpipe route আলাদা করে; শুধু VirGL নাম hardware-backed
route প্রমাণ করে না। এটি archived evidence run-এর identical protocol নয়।

```bash
ternux benchmark [--json]
```

### `ternux profile`

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

### `ternux backend`

GPU ব্যাকএন্ড ব্যবস্থাপনা।

```bash
ternux backend <subcommand> [backend]
```

| সাবকমান্ড | বিবরণ |
|-----------|--------|
| `show` | বর্তমান ব্যাকএন্ড দেখান |
| `set auto\|zink\|virgl` | GPU ব্যাকএন্ড পরিবর্তন |
| `detect` | স্বয়ংক্রিয় ব্যাকএন্ড শনাক্ত |

### `ternux gpu`

GPU backend ও guest userspace driver দেখুন বা update করুন। `update` Zink route-এ
Ternux-এর pinned এবং SHA-256-যাচাইকৃত Debian Turnip driver আবার install করে;
তারপর desktop restart করতে হবে। এটি Android-এর vendor/kernel driver update করে না।
VirGL route-এ guest Turnip driver ব্যবহৃত হয় না।

```bash
ternux gpu show
ternux gpu update
ternux gpu update --json
```

`ternux backend update` একই কাজের সমতুল্য command।

### `ternux info`

সিস্টেম তথ্য সারসংক্ষেপ।

```bash
ternux info [--json]
```

### `ternux state`

ইনস্টলেশন অবস্থা দেখান।

```bash
ternux state [--json]
```

### `ternux status`

Desktop lifecycle এবং host service-এর অবস্থা দেখায়। `running` দেখানোর আগে
guest-এর ভেতর সীমিত সময়ে X11 query সফল হতে হয়; শুধু socket বা process থাকলেই
desktop usable ধরা হয় না। `pulseaudio` host daemon process আছে কি না জানায়;
`pulseaudio_ready` Debian app-এর জন্য loopback TCP audio route আলাদাভাবে যাচাই
করে।

```bash
ternux status [--json]
```

JSON output-এ `lifecycle`, `x11_running`, `pulseaudio`, `pulseaudio_ready`,
`virgl`, `launcher` এবং `desktop_pid` থাকে।

### `ternux logs`

লগ ফাইল দেখা ও ব্যবস্থাপনা।

```bash
ternux logs <subcommand> [n]
```

| সাবকমান্ড | বিবরণ |
|-----------|--------|
| `show [n]` | শেষ n লাইন দেখান (ডিফল্ট: ৫০) |
| `tail` | রিয়েল-টাইম লগ দেখা |
| `clear` | লগ ফাইল মুছে ফেলা |
| `list` | লগ ফাইলের তালিকা |
| `desktop [show|tail]` | desktop session log পড়ুন বা live follow করুন |

### `ternux extension`

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

### `ternux update`

CLI-কে তার install source অনুযায়ী আপডেট করে। APT-managed install APT দিয়ে update/check করে; অন্য install GitHub থেকে self-update করে।

```bash
ternux update [check]
```

| সাবকমান্ড | বিবরণ |
|-----------|--------|
| *(none)* | APT package-managed হলে configured repository থেকে update; অন্যথায় GitHub থেকে latest version download/install |
| `check` | ইনস্টল না করেই আপডেট চেক; APT-managed install configured package candidate দেখে |

### `ternux uninstall`

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
