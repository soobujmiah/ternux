# Ternux Termux APT package

Ei package Ternux host CLI ebong tar shell module install kore. `pkg install`
cholakaline eta desktop/container setup kore na; package install-er por user
nije `ternux install` chaliye setup shuru korben.

## Package build

Native Termux-e clean checkout theke chalao:

```bash
pkg update
pkg install termux-create-package
bash packaging/termux/build.sh
```

Toiri `.deb` file thakbe `artifacts/ternux-apt/debs/`-e. Version neya hoy
`lib/core.sh` theke; package architecture `all`, karon package-e shudhu shell
script ache. Manifest-e install file-gulo alada kore deya, tai notun CLI module
add korle `manifest.json`-eo jog korte hobe.

## APT repository tree build o verify

```bash
pkg install termux-apt-repo
bash packaging/termux/build-repository.sh
```

Unsigned tree `artifacts/ternux-apt/repository/`-e toiri hoy; eta shudhu local
install test-er jonno. Prottek build generated directory notun kore toiri kore
APT index-e package identity, architecture, filename o SHA-256 mile kina check
kore. Unsigned tree kokhono publish koro na ba client-e `trusted=yes` use koro na.

Current GnuPG home-e age theke thaka key diye sign korte full fingerprint dekhe
command chalao:

```bash
gpg --list-secret-keys --fingerprint
TERNUX_APT_SIGNING_FINGERPRINT='<full fingerprint>' \
  bash packaging/termux/build-repository.sh --sign
```

Script `Origin`/`Label` metadata set kore, oi full fingerprint diye
`InRelease` sign o verify kore, ebong shudhu `ternux-archive-key.asc` public
key export kore. Eta private key toiri, import, copy ba export kore na.
Passphrase-protected key hole echo chara passphrase niye environment diye pathao;
script eta command argument ba file-e na rekhe GnuPG-r stdin-e dey:

```bash
read -r -s -p 'Signing key passphrase: ' TERNUX_APT_SIGNING_PASSPHRASE
printf '\n'
export TERNUX_APT_SIGNING_PASSPHRASE
TERNUX_APT_SIGNING_FINGERPRINT='<full signing fingerprint>' \
  bash packaging/termux/build-repository.sh --sign
unset TERNUX_APT_SIGNING_PASSPHRASE
```

Private signing key owner-managed secure signing environment-e rakhbe;
repository, package artifact, website ba shared storage-e private key rakhbe na.

## Publish ebong sign

Release-only GitHub Actions workflow `termux-apt-release.yml` signed tree
project Pages site-er `/apt/` path-e publish kore. Eta shudhu `main` theke
manual run ney, `confirm_release=publish-v2` chai, ebong project version
`2.0.0` na hole build bondho kore. Protected `apt-release` environment-e
armored private signing-key secret, optional passphrase secret, ebong full
primary-key fingerprint variable set korte hobe. Workflow-ti push-e auto-run
kore na; release-plan-er shob gate bondho howar por-i run koro.

Client install chalu korar age public key fingerprint independent channel-e
publish kore clean Termux environment theke verify koro. Workflow public key
`apt/ternux-archive-key.asc`-e publish kore; private signing key kokhono
publish kore na.

## Published repository theke install

Repository signing key verify kore install korar por, sei key diye APT source
entry add koro (`signed-by` option shoho), tarpor chalao:

```bash
pkg update
pkg install ternux
```

APT source URL ebong keyring path published repository configuration-er sathe
milte hobe. Release guide-e `[trusted=yes]` source line deya jabe na.

Owner signing key publish করে এবং independent channel-এ fingerprint
confirm করার পর client setup-এর উদাহরণ:

```bash
pkg install gnupg
curl -fsSLo "$TMPDIR/ternux-archive-key.asc" https://<host>/<path>/ternux-archive-key.asc
gpg --show-keys --with-fingerprint "$TMPDIR/ternux-archive-key.asc"
# দেখানো fingerprint independently published fingerprint-এর সঙ্গে মেলান।
gpg --dearmor --output "$TMPDIR/ternux.gpg" "$TMPDIR/ternux-archive-key.asc"
install -Dm600 "$TMPDIR/ternux.gpg" "$PREFIX/etc/apt/keyrings/ternux.gpg"
printf 'deb [signed-by=%s/etc/apt/keyrings/ternux.gpg] https://<host>/<path> stable main\n' "$PREFIX" \
  > "$PREFIX/etc/apt/sources.list.d/ternux.list"
pkg update
pkg install ternux
```

Host, path ebong fingerprint placeholder thakbe jotokkhon na owner signed
repository publish kore ebong independent fingerprint channel verify koren.
