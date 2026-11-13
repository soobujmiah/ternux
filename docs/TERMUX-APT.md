---
title: "Install Ternux from the signed Termux APT repository"
description: "Verify the Ternux v2 repository signing key and install the host CLI with pkg."
lang: "en"
alt_url: "/bn/docs/TERMUX-APT.html"
---


The signed Ternux 2.0.0 stable repository is published at `/apt`. The signed
`/apt-rc` repository remains available for release-candidate qualification.
The package installs the Termux host CLI; it does not provision a Linux guest
or desktop. After package installation, run `tx install` to set up the desktop.

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

## Install the stable package

Install the small bootstrap prerequisites from the normal Termux repository.
You do not need to run `apt full-upgrade` manually first: the bootstrap refreshes
the package index, and `tx install` performs the normal Termux update/upgrade
and dependency setup. Use curl or wget to fetch the same bootstrap:

```bash
pkg update -y && pkg install -y curl gnupg
curl -fsSLo "$TMPDIR/ternux-bootstrap.sh" \
  https://soobujmiah.github.io/ternux/apt/bootstrap.sh
bash "$TMPDIR/ternux-bootstrap.sh"
```

If you prefer wget:

```bash
pkg update -y && pkg install -y wget gnupg
wget -qO "$TMPDIR/ternux-bootstrap.sh" \
  https://soobujmiah.github.io/ternux/apt/bootstrap.sh
bash "$TMPDIR/ternux-bootstrap.sh"
```

The script is idempotent and refuses symlinked APT
configuration paths or a signing key whose primary fingerprint does not match
the value above. It never uses `[trusted=yes]`.

After this one-time setup, manage Ternux with ordinary Termux package commands:

```bash
pkg update
pkg upgrade ternux
# On another Termux installation after bootstrapping the repository:
pkg install ternux
```

After package installation, provision the desktop with `tx install` and follow
the distro selection prompts. `pkg upgrade ternux` updates the host CLI without
removing or reinstalling guest environments.

The RC channel is opt-in and separate. Use these commands only when testing a
release candidate:

```bash
bash "$TMPDIR/ternux-bootstrap.sh" --channel rc --configure-only
bash "$TMPDIR/ternux-bootstrap.sh" --channel rc
```

Switch back to stable by rerunning the stable bootstrap command above.

The project cannot make a brand-new Termux installation resolve `pkg install
ternux` before this one-time trust setup unless Termux accepts Ternux into one
of its own official package repositories.

After publication, routine website deployments verify the currently published
APT signature and every index/package checksum, then carry that signed tree into
the new Pages artifact. A failed or incomplete verification stops the website
deployment so it cannot silently remove or replace the package repository.
