---
title: "Ternux project roadmap"
description: "Published v2.0.1 status and the active v3 foundation direction."
lang: "en"
alt_url: "/bn/docs/project/PROJECT-ROADMAP.html"
---

## Current direction

**Reviewed:** 2026-11-20. Version 2 represents the existing implementation on
`main`. The owner revoked the decision to move the former v3 platform scope
into v2. Version 2 is frozen: no new distribution support, manager architecture,
Device Bridge, Control Center capability, extension framework, API, AI/compute
architecture, desktop environment, or APT channel is being added for this
release.

## Release status

- `v2.0.0` was withdrawn on 2026-11-14. Its source tag remains for provenance;
  its GitHub Release object is absent and stable APT endpoints return 404.
- `v2.0.1` is published at tag `v2.0.1`, resolving to commit
  `5be29360c9ca7e4516366711ec09f7a9b4d56940`. The GitHub release includes a
  source archive and `SHA256SUMS`; the downloaded archive digest and exact
  installation guide were verified.
- `v1.4.0` is a historical published release. Its dedicated guide remains
  linked from its release page and its tag remains immutable.
- The stable APT channel remains withdrawn. Version 2 uses the verified
  version-specific source installation route. APT feasibility is a separate
  v3 research item, not a v2 release gate.
- The owner-confirmed v2 verified desktop baseline is Debian, Ubuntu, Kali
  Linux, and Alpine. Evidence boundaries and the narrower clean-browser CI
  subset are documented in the [feature matrix](../audit/FEATURE-MATRIX.md).

## Version 2 release freeze and exit criteria

Future releases require a fixed exact source commit, matching version metadata
and guide, passing focused tests and exact-commit CI, verified artifacts and
checksums, and honest limitation notes. The v2.0.1 release satisfies these
gates; see the release status page for its tag, digest, and checks.

The v2 qualification boundaries and exact release test evidence are preserved
in the [v2 release reconciliation](../release/V2-RELEASE-RECONCILIATION.md)
and [feature matrix](../audit/FEATURE-MATRIX.md). They describe the v2.0.1
release snapshot, not a new full-device run on every later source commit. For
this v3 documentation slice, the Termux-host Node binary still has a dynamic
linker error; the installed Debian guest Node runtime built the website
successfully (98 pages, 60 finalized HTML routes). The documentation checker
passed 7,333 assertions, 672 internal links, and 25 bilingual page pairs.
No new device qualification is claimed by these documentation checks.

## Version 3 — active development

The v2.0.1 release, its release page, and its version-specific installation
guide are published and verified. The release gate is complete and v2 remains
frozen. V3 foundation work is active in `docs/v3/`; design, a roadmap, or a
source file alone does not make a capability current or release-qualified.

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

APT return has an initial feasibility assessment in
[`docs/v3/APT-DISTRIBUTION-FEASIBILITY.md`](../v3/APT-DISTRIBUTION-FEASIBILITY.md).
Its current recommendation is to keep APT out of the v3.0 critical path and
retain the verified source installer. Any prototype requires its own research,
security, operational, and explicit release gates. APT remains withdrawn and
is not a current installation method.

## Evidence and history

- [Current implementation status](IMPLEMENTATION-STATUS.md)
- [Known limitations](KNOWN-LIMITATIONS.md)
- [Technical debt](TECHNICAL-DEBT.md)
- [Next actions](NEXT-ACTIONS.md)
- [Historical release and withdrawal report](../release/V2-RELEASE-REPORT.md)
- [Generated repository state](../../.repo/STATUS.md) — maintained by CI, not by hand.
