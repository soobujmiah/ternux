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
runs only from `main` with `confirm_release=publish-v2` and refuses to build
unless the project version is exactly `2.0.0`. Configure the protected
`apt-release` environment with the armored private signing key and optional
passphrase secrets, plus the full primary-key fingerprint variable. The
workflow is prepared but does not run on pushes; invoke it only after every
release-plan gate is closed.

Before enabling client installation, publish the public key fingerprint through
an independent channel and verify it from a clean Termux environment. The
workflow publishes the public key at `apt/ternux-archive-key.asc`; it never
publishes private signing material.

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

Example client setup after the owner has published the key and confirmed the
fingerprint through an independent channel:

```bash
pkg install gnupg
curl -fsSLo "$TMPDIR/ternux-archive-key.asc" https://<host>/<path>/ternux-archive-key.asc
gpg --show-keys --with-fingerprint "$TMPDIR/ternux-archive-key.asc"
# Compare the displayed fingerprint with the independently published value.
gpg --dearmor --output "$TMPDIR/ternux.gpg" "$TMPDIR/ternux-archive-key.asc"
install -Dm600 "$TMPDIR/ternux.gpg" "$PREFIX/etc/apt/keyrings/ternux.gpg"
printf 'deb [signed-by=%s/etc/apt/keyrings/ternux.gpg] https://<host>/<path> stable main\n' "$PREFIX" \
  > "$PREFIX/etc/apt/sources.list.d/ternux.list"
pkg update
pkg install ternux
```

The host, path, and fingerprint remain placeholders until the owner publishes
the signed repository and verifies its independent fingerprint channel.
