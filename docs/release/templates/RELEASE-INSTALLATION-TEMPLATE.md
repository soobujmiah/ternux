---
title: "Ternux v<VERSION> installation guide template"
description: "Reusable checklist for exact-version Ternux release installation instructions."
lang: "en"
alt_url: "/bn/docs/release/templates/RELEASE-INSTALLATION-TEMPLATE.html"
---

**Release:** v<VERSION><br>
**Tag:** `v<VERSION>`<br>
**Tag commit:** `<FULL_COMMIT_SHA>`<br>
**Release date:** `<YYYY-MM-DD>`<br>
**Artifact:** `<EXACT_FILENAME_OR_TAGGED_SOURCE_ARCHIVE>`<br>
**SHA-256:** `<PUBLISHED_SHA256>`

## Release identity

State what this version contains and whether this is a stable release, preview,
or historical release. Link to its immutable tag and release assets.

## Prerequisites and supported environment

List Android architecture/version, Termux source, required companion apps,
storage/network requirements, permissions, and supported guest distributions.
Separate verified environments from untested ones.

## Install this exact version

Give a version-pinned command and identify the exact archive/artifact it runs.
Never use a moving branch or generic `latest` URL here. Include safe extraction,
checksum/signature verification, and any one-time setup steps.

```bash
# Version-specific command goes here. Verify it against this release artifact.
```

## Verify the installation

List commands and expected version/output. Distinguish source, package, guest,
and device verification. A CI result does not establish physical-device support.

## Known limitations

List release-specific limitations, maturity labels, and boundaries. Include
hardware/device scope and unsupported features.

## Troubleshooting and recovery

Cover failed download/integrity checks, interrupted installation, safe resume,
logs, repair, and upgrade/downgrade rules. State what not to remove or overwrite.

## Security and provenance

Link source commit, tag, workflow run, artifact provenance, checksums/signing
fingerprint, security policy, and reporting channel. Record when any of these
could not be verified.
