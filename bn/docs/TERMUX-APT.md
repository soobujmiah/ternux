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

এখন source installer-ই সমর্থিত install পথ; [main installation
guide](../README.md) দেখুন। 2026-11-15 তারিখে stable APT bootstrap/key/index
HTTP 404 দিয়েছে। RC bootstrap ও signing key HTTP 200 দিলেও signed index HTTP 404
দেয়। RC signing key HTTP 200 দেয়, কিন্তু signed index HTTP 404। তাই hosted stable বা
RC repository থেকে `pkg install ternux` এখন install
হবে না। Signed repository প্রকাশিত হলে তবেই RC channel opt-in candidate test-এর
জন্য ব্যবহার করা যাবে। পরের stable release v2 major-এই থাকবে; বিস্তারিত [project
roadmap](/bn/docs/project/PROJECT-ROADMAP.html)।

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

## RC channel

নিচের RC setup নির্দেশগুলো পুরোনো। 2026-11-15 তারিখে hosted bootstrap ও index
যাচাই করে HTTP 404 পাওয়া গেছে, তাই এগুলো দিয়ে এখন কার্যকর package source যোগ
হবে না। Stable বা RC—কোনো hosted source থেকেই `pkg install ternux` এখন install
করবে না। Candidate channel আবার প্রকাশিত হলে এই নির্দেশ ফেরানোর আগে bootstrap
URL ও signed index যাচাই করতে হবে।

আপাতত project-এর `main` branch-এর source installer ব্যবহার করুন। Website deploy-এ
শুধু প্রকাশিত এবং signature ও checksum যাচাই করা APT channel রাখা হয়।
