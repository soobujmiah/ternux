---
title: "Ternux Termux APT channel-এর বর্তমান অবস্থা"
description: "Withdrawn Ternux v2 stable channel ও opt-in RC repository-এর বর্তমান অবস্থা।"
lang: "bn"
alt_url: "/docs/TERMUX-APT.html"
---


Ternux v2.0.0 GitHub release ও signed stable APT distribution 2026-11-14-এ
withdraw হয়েছে। Public `/apt` bootstrap, key, index ও package path এখন HTTP 404
দেয়। Provenance-এর জন্য `v2.0.0` Git tag রাখা হয়েছে; নিচের package ও checksum
তথ্য historical record। আগে থেকে install করা package অক্ষত আছে, তবে stable APT
থেকে Ternux update আর পাওয়া যায় না।

Signed `/apt-rc` channel কেবল opt-in candidate test-এর জন্য আছে; production
install source হিসেবে এটি সমর্থিত নয়। পরের stable release v2 major-এই থাকবে।
আগে v3 নামে পরিকল্পিত সম্পূর্ণ platform architecture ও acceptance gate শেষ হলে
নতুন 2.x stable release হবে। বিস্তারিত [project roadmap](/bn/docs/project/PROJECT-ROADMAP.html)
দেখুন; ততদিন [main installation guide](../README.md)-এর source installer ব্যবহার করুন।

## Trust fingerprint

Project Pages host থেকে key নেওয়ার আগে নিচের পূর্ণ OpenPGP primary-key
fingerprint-এর সঙ্গে GitHub source page-এর fingerprint মিলিয়ে নিন। GitHub
repository এবং Pages-এ থাকা APT repository আলাদা endpoint।

```text
E552 7F4D 5B83 037F F77B 65AE 5E89 4BBB 8116 8B1D
```

এটি RSA 4096 signing key; তৈরি 2026-11-06, মেয়াদ শেষ 2031-11-05। Protected
private key GitHub Actions-এর `apt-release` environment-এ আছে; repository-তে
শুধু public key প্রকাশ হবে।

## Historical stable package তথ্য

Withdraw হওয়া stable repository-তে `ternux_2.0.0_all.deb` ছিল; SHA-256
`4ef03210c71e3d5671671e9a49fc83f6aebf7cdb5e5a28cb32db61d49e85c89f`। এগুলো
audit-এর জন্য রাখা, বর্তমান download route নয়।

## Opt-in RC channel

শুধু candidate package ইচ্ছাকৃতভাবে test করলে RC bootstrap ব্যবহার করুন। আলাদা
path থেকে নামিয়ে উপরের fingerprint যাচাই করে RC source configure করুন:

RC source যোগ করার আগে Termux-এর pending package upgrade শেষ করুন, যাতে downloader
ও OpenSSL একই package generation-এর থাকে। `curl --version` ব্যর্থ হলে সচল `wget`
ব্যবহার করুন, অথবা আগে `apt update && apt full-upgrade` চালান।

```bash
apt update && apt full-upgrade
pkg install curl gnupg
curl -fsSLo "$TMPDIR/ternux-rc-bootstrap.sh" \
  https://soobujmiah.github.io/ternux/apt-rc/bootstrap.sh
bash "$TMPDIR/ternux-rc-bootstrap.sh" --channel rc --configure-only
bash "$TMPDIR/ternux-rc-bootstrap.sh" --channel rc
```

RC repository stable channel থেকে আলাদা এবং এতে pre-release package থাকতে পারে;
এটিকে stable update source হিসেবে ব্যবহার করবেন না। Project-এর `main` branch-এর
source installer ব্যবহার করা যায়।

সাধারণ website deploy-তে শুধু বর্তমানে প্রকাশিত APT channel থাকে। v2 stable
signed tree ইচ্ছাকৃতভাবে অনুপস্থিত; opt-in RC tree সংরক্ষণের আগে signature ও
checksum যাচাই হয়।
