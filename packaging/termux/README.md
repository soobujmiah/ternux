# Ternux Termux APT package

This package installs the Ternux host CLI and its shell modules. It does not
run the desktop/container installer during `pkg install`; after installing the
package, the user explicitly starts provisioning with `ternux install`.

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

## Publish and sign

The release-only GitHub Actions workflow `termux-apt-release.yml` publishes
the signed tree under `/apt/` on the project Pages site. It accepts manual
runs only from `main` with the selected workflow mode and refuses to build
unless the project version is exactly `2.0.0`. Configure the protected
`apt-release` environment with the armored private signing key and optional
passphrase secrets, plus the full primary-key fingerprint variable. The
`verify-signing` mode signs and validates a repository without deployment. Use
`publish-v2` only after every release-plan gate closes; the workflow does not
run on pushes.

The v2 primary-key fingerprint is published independently from GitHub Pages
in [`docs/TERMUX-APT.md`](../../docs/TERMUX-APT.md):
`E5527F4D5B83037FF77B65AE5E894BBB81168B1D`. The workflow publishes the public
key at `apt/ternux-archive-key.asc`; it never publishes private signing
material. The repository is not deployed until the release workflow runs after
every release-plan gate closes.

## Install from a published repository

After the user has verified and installed the repository signing key, add a
source entry using that key with APT's `signed-by` option, then run:

```bash
pkg update
pkg install ternux
```

APT source URL and keyring path must match the repository's actual published
configuration. Do not copy a source line using `[trusted=yes]` into release
instructions.

Client setup after repository publication is documented in the paired
[English](../../docs/TERMUX-APT.md) and
[Bengali](../../bn/docs/TERMUX-APT.md) trust/install guide. The repository URL
will be `https://soobujmiah.github.io/ternux/apt`; verify the key fingerprint
against the GitHub source guide before adding it with `signed-by`. Never use
`[trusted=yes]`.
