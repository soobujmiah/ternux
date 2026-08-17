---
title: "CLI রেফারেন্স"
description: "ternux কমান্ড-লাইন ইন্টারফেসের রেফারেন্স — command, subcommand, global flag ও নথিভুক্ত JSON output।"
lang: "bn"
alt_url: "/docs/CLI.html"
---

`ternux` CLI হলো স্থায়ী ব্যবস্থাপনা ইন্টারফেস — ইনস্টল, ডায়াগনস্টিক,
মেরামত, বেঞ্চমার্ক, ডেস্কটপ লাইফসাইকেল ও সিস্টেম তথ্যের জন্য।

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

### `ternux install`

সম্পূর্ণ ternux ডেস্কটপ ইনস্টল বা পুনরায় ইনস্টল।

```bash
ternux install [options]
```

| অপশন | বিবরণ |
|-------|--------|
| `--yes` | ডিফল্ট, কোনো প্রশ্ন নয় |
| `--user NAME` | Debian ইউজারনেম (ডিফল্ট: `ternux`) |
| `--locale LANG` | লোকেল (ডিফল্ট: `en_US.UTF-8`) |
| `--backend auto\|zink\|virgl` | GPU ব্যাকএন্ড (ডিফল্ট: auto) |
| `--zsh` | bash-এর বদলে zsh ব্যবহার |
| `--with-dev` | ডেভেলপমেন্ট টুলস ইনস্টল |
| `--with-llm` | Vulkan-সহ llama.cpp বিল্ড |
| `--with-network` | নেটওয়ার্ক টুলস ইনস্টল |
| `--with-media` | মিডিয়া টুলস ইনস্টল |
| `--with-blender` | Blender ইনস্টল |
| `--all` | সব ঐচ্ছিক ওয়ার্কলোড |
| `--resume` | interrupted install-এ শুধু recorded-successful phase skip |

### `ternux start`

Xfce4 ডেস্কটপ সেশন চালু করে।

```bash
ternux start
```

### `ternux stop`

ডেস্কটপ সেশন বন্ধ করে সকেট পরিষ্কার করে।

```bash
ternux stop
```

### `ternux restart`

ডেস্কটপ পুনরায় চালু করে (stop + ১ সেকেন্ড + start)।

```bash
ternux restart
```

### `ternux doctor`

সম্পূর্ণ সিস্টেম ডায়াগনস্টিক চালায়।

```bash
ternux doctor [--json]
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

### `ternux update`

ternux CLI আপডেট।

```bash
ternux update [check]
```

| সাবকমান্ড | বিবরণ |
|-----------|--------|
| *(none)* | সর্বশেষ ভার্সন ডাউনলোড ও ইনস্টল |
| `check` | ইনস্টল না করেই আপডেট চেক |

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
```

নতুন কমান্ড যোগ করা:
1. `lib/<name>.sh` তৈরি করুন `tnx_cmd_<name>()` ফাংশন দিয়ে
2. `lib/help.sh`-এ `tnx_help_<name>()` যোগ করুন
3. শেষ — ডিসপ্যাচার স্বয়ংক্রিয় শনাক্ত করে

---

*ternux — সর্বস্বত্ব (c) ২০২৬ Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · MIT লাইসেন্স*