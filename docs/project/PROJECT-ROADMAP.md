---
title: "Ternux project roadmap"
description: "Version 2 release candidate status and the separate future v3 direction."
lang: "en"
alt_url: "/bn/docs/project/PROJECT-ROADMAP.html"
---

## Current direction

**Reviewed:** 2026-11-19. Version 2 represents the existing implementation on
`main`. The owner revoked the decision to move the former v3 platform scope
into v2. Version 2 is frozen: no new distribution support, manager architecture,
Device Bridge, Control Center capability, extension framework, API, AI/compute
architecture, desktop environment, or APT channel is being added for this
release.

## Release status

- `v2.0.0` was withdrawn on 2026-11-14. Its source tag remains for provenance;
  its GitHub Release object is absent and stable APT endpoints return 404.
- `v2.0.1` is the proposed next version. The tag is unused in local and remote
  tag history. A local documentation/source candidate is being prepared from
  current `main`; it is not published and has no release commit or artifact
  checksum yet.
- `v1.4.0` remains the latest published stable release. Its live GitHub release
  page links the dedicated exact-version installation guide, which was checked
  against the immutable v1.4.0 tag. It has no attached binary assets.
- The stable APT channel remains withdrawn. Version 2 uses the verified
  version-specific source installation route. APT feasibility is a separate
  v3 research item, not a v2 release gate.
- The owner-confirmed v2 verified desktop baseline is Debian, Ubuntu, Kali
  Linux, and Alpine. Evidence boundaries and the narrower clean-browser CI
  subset are documented in the [feature matrix](../audit/FEATURE-MATRIX.md).

## Version 2 release freeze and exit criteria

The candidate may be published only after its exact source commit is fixed and
verified, version metadata and release guide match that commit, the existing
focused suite and exact-commit CI pass, artifact provenance and checksums are
recorded, and release notes document limits honestly. Release page publication
and the v1.4.0 historical guide must be checked against the actual source
archive. This page does not mark any unpublished gate complete.

Known verification boundaries:

- Local `tests/focused.sh` passes 212/212 on the Termux ARM64 host as of
  2026-11-19. The immutable bootstrap source-sync test remains open because the
  pinned archive predates the local source correction.
- The owner requested the Debian desktop be started for a live window-fit
  regression check. The local helper preserved a moved window through resize;
  the desktop remains open. This does not qualify a release package.
- Kali has reference-device desktop evidence. The clean-container Firefox CI
  script currently covers Debian, Ubuntu, and Alpine only.
- Physical live tests of microphone capture, camera capture, optional AI
  artifacts, and every workload were not rerun for this candidate.
- The local Node executable cannot start in this Termux runtime due to a
  dynamic linker error, and Docker is unavailable. Therefore the Astro build,
  container browser matrix, package artifact build, and full CI workflow need
  hosted verification after the approved changes are synchronized.

## Version 3 — future scope

Start v3 engineering only after v2.0.1 is published and its release page and
installation guide are verified. Keep architecture and implementation in
`docs/v3/`; do not treat planned features as current capabilities.

The v3 distribution candidates are Arch Linux, Fedora Linux, Void Linux,
openSUSE Tumbleweed, CentOS Stream, and Gentoo, in addition to the four v2
baseline distributions. Prioritize Arch, Fedora, Void, and openSUSE. The first
v3 release target is eight fully qualified distributions; ten is a stretch
goal. A candidate remains **Planned** until its installation, lifecycle,
desktop, graphics, audio, recovery, and resource matrix passes.

The architecture agenda includes installer modularization, stronger test
isolation, supply-chain review, optional supervised manager, Control Center,
workspace lifecycle, Device Bridge, compute/AI ownership, extension security,
and repository-state freshness. These are future plans, not v2 blockers. The
v3 roadmap defines dependencies and measurable acceptance gates; delivery dates
are not promised.

APT return requires an independent feasibility study covering hosting, ARM64
package builds, signing, metadata, upgrades, rollback, recovery, mirrors,
maintenance, and supply-chain risks. Keep it **Planned** until the study and
owner decision support an implementation.

## Evidence and history

- [Current implementation status](IMPLEMENTATION-STATUS.md)
- [Known limitations](KNOWN-LIMITATIONS.md)
- [Technical debt](TECHNICAL-DEBT.md)
- [Next actions](NEXT-ACTIONS.md)
- [Historical release and withdrawal report](../release/V2-RELEASE-REPORT.md)
- [Generated repository state](../../.repo/STATUS.md) — maintained by CI, not by hand.
