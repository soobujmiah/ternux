---
title: "Signed Termux APT repository থেকে Ternux install"
description: "Ternux v2 repository signing key যাচাই করে pkg দিয়ে host CLI install করুন।"
lang: "bn"
alt_url: "/docs/TERMUX-APT.html"
---

# Ternux Termux APT repository

Ternux 2.0.0 release-এর জন্য signed Termux APT repository প্রস্তুত। Repository
এখনো **প্রকাশিত হয়নি**; release gate শেষ করে publish workflow চালানোর পর
`pkg install ternux` পাওয়া যাবে। Package host CLI install করে, Debian/Xfce
নিজে provision করে না। Package install-এর পরে desktop সেটআপে `ternux install`
চালান।

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

## Repository প্রকাশের পরে install

```bash
pkg install curl gnupg
install -d -m 700 "$PREFIX/etc/apt/keyrings"
curl -fsSLo "$TMPDIR/ternux-archive-key.asc" \
  https://soobujmiah.github.io/ternux/apt/ternux-archive-key.asc
gpg --show-keys --with-fingerprint "$TMPDIR/ternux-archive-key.asc"
```

দেখানো primary fingerprint উপরের মানের সঙ্গে মিলিয়ে repository যোগ করে CLI
install করুন:

```bash
gpg --dearmor --output "$PREFIX/etc/apt/keyrings/ternux.gpg" \
  "$TMPDIR/ternux-archive-key.asc"
chmod 600 "$PREFIX/etc/apt/keyrings/ternux.gpg"
printf 'deb [signed-by=%s/etc/apt/keyrings/ternux.gpg] https://soobujmiah.github.io/ternux/apt stable main\n' \
  "$PREFIX" > "$PREFIX/etc/apt/sources.list.d/ternux.list"
pkg update
pkg install ternux
ternux install
```

কখনো `[trusted=yes]` দিয়ে repository configure করবেন না। Signed index verify
এবং fingerprint মিল—দুটিই প্রথম install-এর trust check।
