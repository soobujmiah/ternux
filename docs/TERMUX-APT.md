---
title: "Ternux Termux APT channel status"
description: "Current status of the withdrawn Ternux v2 stable channel and opt-in RC repository."
lang: "en"
alt_url: "/bn/docs/TERMUX-APT.html"
---


The Ternux v2.0.0 GitHub release and signed stable APT distribution were
withdrawn on 2026-11-14. The public `/apt` bootstrap, key, index, and package
paths now return HTTP 404. The `v2.0.0` Git tag is retained for provenance; its
package and checksum data below are historical. Existing installations are
unaffected, but stable APT no longer offers Ternux updates.

The signed `/apt-rc` channel remains available only for opt-in candidate tests.
It is not a supported production install source. Use the source installer in
the [main installation guide](../README.md) until the next stable release.
The next stable release remains in the v2 major. The complete platform
architecture formerly planned for v3 is required before a new 2.x stable
release; see the [project roadmap](project/PROJECT-ROADMAP.html).

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

## Historical stable package details

The withdrawn stable repository contained `ternux_2.0.0_all.deb`, SHA-256
`4ef03210c71e3d5671671e9a49fc83f6aebf7cdb5e5a28cb32db61d49e85c89f`. These
values are retained for audit and do not provide a current download route.

## Opt-in RC channel

Use the RC bootstrap only when deliberately testing a candidate package. Fetch
it from the separate path, verify the published fingerprint above, and configure
the RC source explicitly:

Before adding the RC source, finish any pending Termux upgrade so the downloader
and its OpenSSL libraries stay from one package generation. If `curl --version`
fails, use a working `wget` or run `apt update && apt full-upgrade` first.

```bash
apt update && apt full-upgrade
pkg install curl gnupg
curl -fsSLo "$TMPDIR/ternux-rc-bootstrap.sh" \
  https://soobujmiah.github.io/ternux/apt-rc/bootstrap.sh
bash "$TMPDIR/ternux-rc-bootstrap.sh" --channel rc --configure-only
bash "$TMPDIR/ternux-rc-bootstrap.sh" --channel rc
```

The RC repository is separate from stable and may contain pre-release packages.
Do not use it as a stable update source. The source installer remains available
from the project `main` branch.

Routine website deployments preserve only currently published APT channels.
The signed v2 stable tree is intentionally absent; the opt-in RC tree is
signature- and checksum-verified before preservation.
