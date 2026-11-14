# Ternux Termux APT package

This package installs the Ternux host CLI and its shell modules. It does not
run the desktop/container installer during `pkg install`; it provides both
`tx` and `ternux` commands. After installing the package, explicitly start
provisioning with `tx install`.

## Build a package

Run this in native Termux from a clean checkout:

```bash
pkg update
pkg install termux-create-package
bash packaging/termux/build.sh
```

The generated `.deb` is written to `artifacts/ternux-apt/debs/`. Its version comes
from `lib/core.sh`; the package architecture is `all` because the package
contains shell scripts only. The manifest lists the installed files explicitly
so a new CLI module must be added to `manifest.json` when introduced.

## Build and verify the APT repository tree

```bash
pkg install termux-apt-repo
bash packaging/termux/build-repository.sh
```

The unsigned tree is written to `artifacts/ternux-apt/repository/` for local
install testing only. Each build recreates this generated directory and checks
the package identity, architecture, filename, and SHA-256 in the APT index.
Never publish an unsigned tree or configure clients with `trusted=yes`.

To sign with a key already available in the current GnuPG home, inspect its full
fingerprint first, then run:

```bash
gpg --list-secret-keys --fingerprint
TERNUX_APT_SIGNING_FINGERPRINT='<full fingerprint>' \
  bash packaging/termux/build-repository.sh --sign
```

The script writes `Origin`/`Label` metadata, signs `InRelease` with that exact
full fingerprint, verifies the signature, and exports only
`ternux-archive-key.asc` (the public key). It does not create, import, copy, or
export a private key. For a passphrase protected key, read the passphrase without
echo and pass it through the environment; the script forwards it to GnuPG on
stdin, not in a command argument or file:

```bash
read -r -s -p 'Signing key passphrase: ' TERNUX_APT_SIGNING_PASSPHRASE
printf '\n'
export TERNUX_APT_SIGNING_PASSPHRASE
TERNUX_APT_SIGNING_FINGERPRINT='<full signing fingerprint>' \
  bash packaging/termux/build-repository.sh --sign
unset TERNUX_APT_SIGNING_PASSPHRASE
```

Keep private signing material in an owner-managed secure signing environment;
never put it in the repository, package artifacts, website, or shared storage.

## Release workflow

The release-only GitHub Actions workflow `termux-apt-release.yml` accepts
manual runs from `main`. `verify-signing` validates signing setup without
deployment; `publish-rc` publishes an isolated candidate under `/apt-rc/` and
preserves an existing stable tree. The v2 stable channel is retired: the
`withdraw-v2` mode deploys the website with the signed RC tree preserved and
`/apt/` omitted. There is no mode to republish v2 stable. A future v3 stable
publisher requires a separately reviewed versioned workflow and gates.

Configure the protected `apt-release` environment with the armored private
signing key and optional passphrase secrets, plus the full primary-key
fingerprint variable. The workflow publishes only the public key and never
includes private signing material in the Pages artifact.

The v2 primary-key fingerprint is published independently from GitHub Pages
in [`docs/TERMUX-APT.md`](../../docs/TERMUX-APT.md):
`E5527F4D5B83037FF77B65AE5E894BBB81168B1D`. The workflow publishes the public
key at `apt/ternux-archive-key.asc`; it never publishes private signing
material. Publishing RC requires an explicit workflow dispatch after the relevant
candidate checks pass.

## Install from a published repository

The signed release tree includes `bootstrap.sh`. After installing `curl` and
`gnupg` from Termux's normal repository, users download and run it; it verifies
the pinned primary-key fingerprint, writes a `signed-by` source, refreshes APT,
and installs Ternux. The script also supports `--configure-only`. Future
updates use normal `pkg update` / `pkg upgrade ternux` commands. It never uses
`[trusted=yes]`.

The bootstrap URL is `https://soobujmiah.github.io/ternux/apt/bootstrap.sh` and
exists only after the signed release is published. See the paired
[English](../../docs/TERMUX-APT.md) and
[Bengali](../../bn/docs/TERMUX-APT.md) user guide. A custom repository cannot
make the first `pkg install ternux` work before APT trusts its signing key;
zero-bootstrap discovery requires acceptance into an official Termux package
repository.
