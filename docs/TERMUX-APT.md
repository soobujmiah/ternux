---
title: "Install Ternux from the signed Termux APT repository"
description: "Verify the Ternux v2 repository signing key and install the host CLI with pkg."
lang: "en"
alt_url: "/bn/docs/TERMUX-APT.html"
---


The signed Termux APT repository is prepared for the Ternux 2.0.0 release. The
repository has **not been published yet**, so `pkg install ternux` is not
available until the release gates are closed and the publishing workflow runs.
The package installs the host CLI; it does not provision Debian/Xfce by itself.
After package installation, run `ternux install` to set up the desktop.

## Trust fingerprint

Compare the full OpenPGP primary-key fingerprint shown here with the fingerprint
on this GitHub source page before trusting a key downloaded from the project
Pages host. The GitHub repository and Pages-hosted APT repository are separate
endpoints.

```text
E552 7F4D 5B83 037F F77B 65AE 5E89 4BBB 8116 8B1D
```

The key is an RSA 4096 signing key created on 2026-11-06 and expires on
2031-11-05. The protected private key is held in the `apt-release` GitHub
Actions environment; only the public key will be published with the repository.

## Install after the repository is published

```bash
pkg install curl gnupg
install -d -m 700 "$PREFIX/etc/apt/keyrings"
curl -fsSLo "$TMPDIR/ternux-archive-key.asc" \
  https://soobujmiah.github.io/ternux/apt/ternux-archive-key.asc
gpg --show-keys --with-fingerprint "$TMPDIR/ternux-archive-key.asc"
```

Confirm the displayed primary fingerprint matches the value above, then add the
repository and install its CLI package:

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

Never configure the repository with `[trusted=yes]`. Signed index verification
and the fingerprint comparison are both part of the first-install trust check.
