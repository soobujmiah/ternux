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

The source installer is the supported install route; see the [main
installation guide](../README.md). Rechecked on 2026-11-16, the stable APT
bootstrap/key/index and the RC signed index return HTTP 404. The RC bootstrap
and signing key return HTTP 200, but neither hosted repository can currently
install `ternux` with `pkg install`. The RC channel remains reserved for
opt-in candidate testing after its signed repository is published.
The owner revoked the 2026-11-14 decision that required former v3 platform
scope before another v2 release. Version 2 remains frozen to the existing
implementation; v2.0.1 is the published source release described in the
[project roadmap](project/PROJECT-ROADMAP.html). APT remains withdrawn and is
not a v2 release requirement. Any APT return is a separate v3 feasibility
decision after v2 publication and owner approval.

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

## RC channel

The RC bootstrap and key URLs currently return HTTP 200, but the signed index
returns HTTP 404. These commands therefore cannot configure a working package
source. Do not run `pkg install ternux` expecting it to install from
stable or RC. Once a candidate channel is published, verify its key and signed
index before restoring runnable instructions.

For now, use the source installer from the project `main` branch. Routine
website deployments preserve only APT channels that are currently published and
pass signature and checksum verification.
