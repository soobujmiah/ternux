---
title: "Ternux release status"
description: "Withdrawn v2.0.0 history and local v2.0.1 candidate status."
lang: "en"
alt_url: "/bn/docs/project/RELEASE-STATUS.html"
---

## Current status — 2026-11-18

- **Latest published numbered release:** v1.4.0. Its GitHub release is
  published, and the tag points to
  `3e6c07e2afcb5f1e65ecd57af19b0382a948835a`. The release has no attached
  binary assets; its exact source-archive install guide is now prepared locally
  and verified against the tagged archive. The public release page has not been
  edited.
- **v2.0.0:** source tag remains at
  `9106b04fc8627ae98b1d63c9912a28c8a4677441`; its GitHub Release object was
  removed on 2026-11-14 and stable APT was withdrawn. Do not move or reuse the
  tag or represent either distribution as active.
- **v2.0.1:** unused version candidate based on current `main`. The working
  tree is being reviewed locally; there is no published tag, release commit,
  package artifact, checksum, or release page for it yet.
- **Stable APT:** withdrawn and not a v2.0.1 install method. APT return is a
  separate future v3 feasibility decision.
- **v2 verified desktop baseline:** Debian, Ubuntu, Kali Linux, and Alpine as
  confirmed by the owner. The feature matrix records the per-profile evidence
  and narrower clean-container CI coverage.

## Historical v2.0.0 release

Ternux v2.0.0 was published on 2026-11-13 and withdrawn on 2026-11-14. The
immutable tag and release-time artifacts remain documented in the
[v2.0.0 release report](../release/V2-RELEASE-REPORT.md) and
[release-time report](../V2-RELEASE-REPORT.md). The withdrawn release's Debian,
Ubuntu, and Alpine scope must not be confused with the owner's current four-
distribution v2 baseline for the next release.

## Version 2 release policy

Keep v2 frozen to current implementation. Do not add distro support, new
architecture, APT, or other new capabilities. A v2.0.1 release requires an
approved exact commit, green exact-commit checks, release artifact integrity,
version-specific install instructions, and honest known limitations. The
release is not complete until the actual GitHub Release page and both version-
specific pages have been verified.

## Version 3 separation

The future v3 architecture and candidate distribution plan are described in
[`docs/v3/`](../v3/README.md). Start v3 work only after v2.0.1 has been
published and verified. Current source may contain partial manager or Control
Center code; that does not make the complete v3 architecture available.
