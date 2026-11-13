---
title: "Ternux release status"
description: "Published v2 release facts, support boundary, and current package/site state."
lang: "en"
---

## Release status

**Last checked:** 2026-11-13 12:26 UTC.

## Ternux v2.0.0

- **State:** released on 2026-11-13.
- **Source:** tag `v2.0.0`; release commit `9106b04fc8627ae98b1d63c9912a28c8a4677441`.
- **Termux package:** signed stable APT publication is recorded in the
  [current v2 report](../release/V2-RELEASE-REPORT.md),
  [release-time report](../V2-RELEASE-REPORT.md), and gate inventory.
- **Support boundary:** Debian, Ubuntu, and Alpine desktop profiles, with
  device qualification limited to the reference Xiaomi Redmi Turbo 4 Pro
  (Android 16, SM8735 / Adreno 825) and explicitly recorded tests.
- **Current source/site:** `main` has advanced beyond the release tag. The
  current homepage deployment completed in
  [Pages run 43421466805](https://github.com/soobujmiah/ternux/actions/runs/43421466805).
  It reflects curl, wget, signed APT setup, Termux companion links, and the v2/v3
  status snapshot. This does not change the installed v2.0.0 package.
- **Native manager CLI:** the three read-only JSON commands are present in
  current repository source and passed source-side invocation; they are not in
  the released 2.0.0 `.deb`. The installed `tx manager` command is unavailable.
- **Experimental:** HTP/HMX and QNN artifacts are not stable release claims.

The source `origin/main` later advanced after release for documentation and
repository-state maintenance. The device's installed stable APT package
observed in this audit is still `2.0.0`; do not imply that later main changes
are installed on the device.

## Next release

No v2.0.1 or v3 release is declared by this document. A new release requires
an explicit version, exact source commit, package/artifact digests, CI run,
upgrade/recovery evidence, and synchronized README/site/release notes.
