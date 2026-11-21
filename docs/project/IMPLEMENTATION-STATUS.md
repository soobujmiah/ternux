---
title: "Ternux implementation status"
description: "Current source status, evidence boundaries, and support limitations."
lang: "en"
alt_url: "/bn/docs/project/IMPLEMENTATION-STATUS.html"
---

## Current status

Source presence is not equivalent to a release, a working package channel, or
device verification. See the linked evidence for the scope of each claim.

| Area | Status | Evidence boundary |
| --- | --- | --- |
| Release | v1.4.0 release artifacts remain unchanged; a later source tag is retained for provenance, but its GitHub Release entry was removed | [Release status](RELEASE-STATUS.md) and [historical release archive](../release/README.md) |
| Installation | Pinned source installer is the current documented route | [Installation guide](../INSTALLATION.md) |
| APT/package channel | Unavailable; `pkg install ternux` is not a working route | [Channel status](../TERMUX-APT.md) |
| Desktop setups | Debian, Ubuntu, Kali Linux, and Alpine recipes are retained; evidence depth varies | [Feature matrix](../audit/FEATURE-MATRIX.md) and [device verification](../audit/DEVICE-VERIFICATION.md) |
| Manager and Control Center | Partial source implementation; not a complete platform or release claim | [Next Version plans](../next/README.md) |
| Recovery | APT timeout/dpkg recovery paths and regression coverage are retained | Focused recovery tests |

Device-specific and known limitations are recorded in
[known limitations](KNOWN-LIMITATIONS.md). Historical release evidence is in the
[release archive](../release/README.md).
