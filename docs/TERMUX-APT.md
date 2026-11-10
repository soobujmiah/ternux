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

## One-command install after the repository is published

Install the small bootstrap prerequisites from the normal Termux repository,
then let the project script verify the pinned primary-key fingerprint, configure
APT with `signed-by`, refresh indexes, and install Ternux:

```bash
pkg install curl gnupg
curl -fsSLo "$TMPDIR/ternux-bootstrap.sh" \
  https://soobujmiah.github.io/ternux/apt/bootstrap.sh
bash "$TMPDIR/ternux-bootstrap.sh"
```

After this one-time setup, updates and reinstall use ordinary Termux commands:

```bash
pkg update
pkg upgrade ternux
# or, on a new device after the repository has been bootstrapped:
pkg install ternux
```

To configure the verified repository without installing the package yet, run
`bash "$TMPDIR/ternux-bootstrap.sh" --configure-only`, then use `pkg install
ternux` when ready. The script is idempotent and refuses symlinked APT
configuration paths or a signing key whose primary fingerprint does not match
the value above. It never uses `[trusted=yes]`.

Before the signed repository is published, the bootstrap URL will return 404;
use the source installer in the README until the release workflow publishes
v2. The project cannot make a brand-new Termux installation resolve
`pkg install ternux` before this one-time trust setup unless Termux accepts
Ternux into one of its own official package repositories.

After publication, routine website deployments verify the currently published
APT signature and every index/package checksum, then carry that signed tree into
the new Pages artifact. A failed or incomplete verification stops the website
deployment so it cannot silently remove or replace the package repository.
