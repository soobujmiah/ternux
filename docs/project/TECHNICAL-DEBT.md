---
title: "Ternux technical debt"
description: "Known maintenance and verification work with current evidence boundaries."
lang: "en"
---

## Technical debt

| Item | Impact | Disposition |
| --- | --- | --- |
| Package distribution is unavailable | Users cannot install through `pkg install ternux` or a hosted APT repository | Keep the pinned source installer as the documented route; any package return requires independent security, recovery, and operations review |
| Distro behavior varies by package family and environment | A recipe may regress or behave differently on a device | Retain the Debian, Ubuntu, Kali Linux, and Alpine setup references; maintain distro-specific tests and evidence |
| Device qualification is limited | Results from one device cannot establish universal Android compatibility | Publish exact device and test evidence; avoid broad compatibility claims |
| Manager and Control Center are partial | Source functionality may be mistaken for complete support | Keep the unfinished boundary explicit and gate each proposal with tests and review |
| Historical release documents can be mistaken for current instructions | Readers may follow stale package commands or support claims | Link historical reports only as provenance; keep current instructions in the install and status pages |

Preserve APT timeout/dpkg recovery behavior and its focused regression coverage.
Future design proposals are collected under [Next Version](../next/README.md).
