---
title: "Signed Termux APT repository থেকে Ternux install"
description: "Ternux v2 repository signing key যাচাই করে pkg দিয়ে host CLI install করুন।"
lang: "bn"
alt_url: "/docs/TERMUX-APT.html"
---


Ternux 2.0.0-এর signed **release-candidate** APT repository qualification-এর
জন্য `/apt-rc`-এ প্রকাশিত। Stable `/apt` repository ও v2.0.0 release final
release check-এর পরে আলাদাভাবে publish হবে। Package host CLI install করে,
Debian/Xfce নিজে provision করে না। Package install-এর পরে desktop সেটআপে
`ternux install` চালান।

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

## Release candidate install

প্রথমে Termux-এর স্বাভাবিক repository থেকে bootstrap-এর ছোট prerequisite
install করুন। এরপর project script pinned primary-key fingerprint যাচাই করে,
`signed-by` দিয়ে APT configure করে, index refresh ও Ternux install করবে:

```bash
pkg install curl gnupg
curl -fsSLo "$TMPDIR/ternux-bootstrap.sh" \
  https://soobujmiah.github.io/ternux/apt-rc/bootstrap.sh
bash "$TMPDIR/ternux-bootstrap.sh" --channel rc
```

এই একবারের setup-এর পর update বা reinstall সাধারণ Termux command-এ হবে:

```bash
pkg update
pkg upgrade ternux
# নতুন device-এ repository bootstrap করার পরে:
pkg install ternux
```

Package এখনই install না করে candidate repository configure করতে
`bash "$TMPDIR/ternux-bootstrap.sh" --channel rc --configure-only` চালান; পরে
`pkg install ternux` চালাতে পারবেন। Script বারবার চালানো নিরাপদ; এটি symlink করা
APT configuration path বা উপরের fingerprint-এর সঙ্গে না-মেলা primary signing
key প্রত্যাখ্যান করে। এটি কখনো `[trusted=yes]` ব্যবহার করে না।

RC bootstrap qualification-এর জন্য। Stable প্রকাশের পরে
`https://soobujmiah.github.io/ternux/apt/bootstrap.sh` ব্যবহার করুন; সেখানে
`--channel rc` লাগবে না। Termux-এর নিজস্ব official package repository-তে
Ternux গ্রহণ না করা পর্যন্ত একেবারে নতুন Termux setup-এ trust bootstrap ছাড়া
`pkg install ternux` resolve করা সম্ভব নয়।

Repository প্রকাশের পর সাধারণ website deploy বর্তমান APT signature ও প্রতিটি
index/package checksum যাচাই করে signed tree-টি নতুন Pages artifact-এ রেখে দেয়।
যাচাই ব্যর্থ বা অসম্পূর্ণ হলে website deploy থেমে যায়, তাই package repository
নীরবে মুছে বা বদলে যায় না।
