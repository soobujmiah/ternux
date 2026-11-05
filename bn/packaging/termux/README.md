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

## APT repository tree toiri

```bash
pkg install termux-apt-repo
termux-apt-repo artifacts/ternux-apt/debs artifacts/ternux-apt/repository stable main
```

`termux-apt-repo` output directory delete kore abar toiri kore. `.deb` input
directory repository output directory-r baire rakhbe.

## Publish ebong sign

Toiri repository directory ekta stable HTTPS URL-e host koro, jemon
`https://soobujmiah.github.io/ternux-apt/`. Public distribution-er age ekta
offline signing key toiri kore nirapode rakhbe, public key alada verified
channel-e publish korbe, ebong `--sign` option diye repository sign korbe.
Client setup-er somoy key fingerprint aladabhabe verify korte hobe. Public
release-e unsigned repository-r jonno `trusted=yes` use korte bola jabe na.

Repository publish korte GitHub repository/Pages deployment ebong signing-key
maintenance lagbe. Ei package build kono kichu publish kore na.

## Published repository theke install

Repository signing key verify kore install korar por, sei key diye APT source
entry add koro (`signed-by` option shoho), tarpor chalao:

```bash
pkg update
pkg install ternux
```

APT source URL ebong keyring path published repository configuration-er sathe
milte hobe. Release guide-e `[trusted=yes]` source line deya jabe na.

Owner signing key publish kore ebong independent channel-e fingerprint
confirm korar por client setup-er udahoron:

```bash
pkg install gnupg
curl -fsSLo "$TMPDIR/ternux-archive-key.gpg" https://soobujmiah.github.io/ternux-apt/ternux-archive-key.gpg
gpg --show-keys --with-fingerprint "$TMPDIR/ternux-archive-key.gpg"
# Dekhano fingerprint-ta independently published fingerprint-er sathe melabe.
install -Dm600 "$TMPDIR/ternux-archive-key.gpg" "$PREFIX/etc/apt/keyrings/ternux.gpg"
printf 'deb [signed-by=%s/etc/apt/keyrings/ternux.gpg] https://soobujmiah.github.io/ternux-apt stable main\n' "$PREFIX" \
  > "$PREFIX/etc/apt/sources.list.d/ternux.list"
pkg update
pkg install ternux
```

Signing key toiri o repository publish na howa porjonto URL ebong fingerprint
shudhu example.
