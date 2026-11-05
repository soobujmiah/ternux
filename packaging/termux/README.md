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

## Build the APT repository tree

```bash
pkg install termux-apt-repo
termux-apt-repo artifacts/ternux-apt/debs artifacts/ternux-apt/repository stable main
```

`termux-apt-repo` deletes the output directory before regenerating it. Keep the
`.deb` input directory outside the repository output directory.

## Publish and sign

Host the generated repository directory at a stable HTTPS URL, for example
`https://soobujmiah.github.io/ternux-apt/`. Before public distribution, create
and retain an offline signing key, publish its public key through a separately
verified channel, and sign the repository with the supported `--sign` option.
Verify the key fingerprint independently when bootstrapping clients. Do not
tell users to trust an unsigned repository with `trusted=yes` for public use.

Publishing the repository requires a GitHub repository/Pages deployment and a
maintained signing-key process. This package build does not publish anything.

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
curl -fsSLo "$TMPDIR/ternux-archive-key.gpg" https://soobujmiah.github.io/ternux-apt/ternux-archive-key.gpg
gpg --show-keys --with-fingerprint "$TMPDIR/ternux-archive-key.gpg"
# Compare the displayed fingerprint with the independently published value.
install -Dm600 "$TMPDIR/ternux-archive-key.gpg" "$PREFIX/etc/apt/keyrings/ternux.gpg"
printf 'deb [signed-by=%s/etc/apt/keyrings/ternux.gpg] https://soobujmiah.github.io/ternux-apt stable main\n' "$PREFIX" \
  > "$PREFIX/etc/apt/sources.list.d/ternux.list"
pkg update
pkg install ternux
```

The URL and fingerprint above are examples until the owner creates the signing
key and publishes the repository.
