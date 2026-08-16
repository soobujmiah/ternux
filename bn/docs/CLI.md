---
title: "CLI রেফারেন্স"
description: "ternux কমান্ড-লাইন ইন্টারফেসের সম্পূর্ণ রেফারেন্স — প্রতিটি কমান্ড, সাবকমান্ড, ফ্ল্যাগ ও JSON আউটপুট স্কিমা।"
lang: "bn"
alt_url: "/docs/CLI.html"
---

# ternux CLI রেফারেন্স

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
| `--json` | মেশিন-পাঠযোগ্য JSON আউটপুট (AI-নেটিভ) |
| `--verbose` | বিস্তারিত আউটপুট |
| `--quiet` | অ-গুরুত্বপূর্ণ বার্তা বন্ধ |
| `--version`, `-V` | ভার্সন তথ্য |

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
| `--resume` | বিঘ্নিত ইনস্টল চালিয়ে যান |

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

সাধারণ সমস্যা অটো-ফিক্স করে।

```bash
ternux repair
```

### `ternux verify`

ইনস্টলেশন সম্পূর্ণতা যাচাই করে।

```bash
ternux verify [--json]
```

### `ternux benchmark`

GPU বেঞ্চমার্ক চালায় (glmark2, vkmark)।

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

ternux কম্পোনেন্ট অপসারণ (ইন্টারঅ্যাক্টিভ)।

```bash
ternux uninstall
```

## শেল কমপ্লিশন

Bash কমপ্লিশন উপলব্ধ `share/ternux-completion.bash`-এ:

```bash
source share/ternux-completion.bash
```

## আর্কিটেকচার

```
bin/ternux          ← থিন ডিসপ্যাচার (৮২ লাইন)
lib/core.sh         ← শেয়ার্ড I/O, JSON বিল্ডার, স্টেট, লগিং
lib/help.sh         ← সেন্ট্রালাইজড হেল্প
lib/detect.sh       ← ডিভাইস ডিটেকশন
lib/desktop.sh      ← ডেস্কটপ লাইফসাইকেল
lib/doctor.sh       ← ডায়াগনস্টিক + ভেরিফিকেশন
lib/info.sh         ← সিস্টেম তথ্য
lib/backend.sh      ← GPU ব্যাকএন্ড
lib/profile.sh      ← ডিভাইস প্রোফাইলিং
lib/benchmark.sh    ← GPU বেঞ্চমার্ক
lib/repair.sh       ← অটো-ফিক্স
lib/logs.sh         ← লগ ব্যবস্থাপনা
lib/update.sh       ← সেলফ-আপডেট
lib/state.sh        ← ইনস্টলেশন স্টেট
lib/phases.sh       ← ইনস্টলেশন ফেজ (৯টি যাচাইকৃত ধাপ)
```

নতুন কমান্ড যোগ করা:
1. `lib/<name>.sh` তৈরি করুন `tnx_cmd_<name>()` ফাংশন দিয়ে
2. `lib/help.sh`-এ `tnx_help_<name>()` যোগ করুন
3. শেষ — ডিসপ্যাচার স্বয়ংক্রিয় শনাক্ত করে

---

*ternux — সর্বস্বত্ব (c) ২০২৬ Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · MIT লাইসেন্স*