---
title: "Ternux project roadmap"
description: "Current project status and the proposal-only Next Version planning boundary."
lang: "en"
alt_url: "/bn/docs/project/PROJECT-ROADMAP.html"
---

## Current direction

Keep the current source and user-facing support claims evidence-based. Do not
present a numbered future major version or unshipped design as a release.
Future architecture and feature proposals belong under **Next Version / পরবর্তী
সংস্করণ**.

### Current facts

- v1.4.0 release artifacts and documentation remain unchanged.
- The later source tag remains in Git for provenance; its GitHub Release entry
  was removed.
- The Termux APT/package channel is unavailable; `pkg install ternux` does not
  currently work. Use the pinned source route documented in
  [installation](../INSTALLATION.md).
- Debian, Ubuntu, Kali Linux, and Alpine remain the named desktop setup targets.
  Report recipe availability separately from physical-device qualification.
- Preserve APT timeout/dpkg recovery behavior and its tests.

### Next Version planning

The bilingual [Next Version index](../next/README.md) collects proposals,
architecture notes, and acceptance gates. These materials do not promise a
release, package channel, or device support. See also the
[implementation status](IMPLEMENTATION-STATUS.md),
[known limitations](KNOWN-LIMITATIONS.md), and
[release status](RELEASE-STATUS.md).

Dated historical evidence and source-tag provenance remain in the
[release archive](../release/README.md).
