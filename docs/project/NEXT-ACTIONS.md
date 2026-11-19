---
title: "Ternux next actions"
description: "Completed v2.0.1 release gates and future v3 planning."
lang: "en"
alt_url: "/bn/docs/project/NEXT-ACTIONS.html"
---

## v2.0.1 release — completed

**Last reviewed:** 2026-11-20. v2.0.1 is published from the tested exact commit.
Keep v2 frozen to current functionality; stable APT remains withdrawn.

- v2.0.0 withdrawal history and the current owner scope are reconciled; historical
  tag and evidence are preserved.
- Exact-version v1.4.0 and v2.0.1 installation guides are maintained separately.
- Bilingual README, changelog, release index, status, and reconciliation records
  describe the published v2.0.1 source archive and four-distro baseline.
- Local implementation/device evidence and exact-commit hosted checks are recorded.
- Source archive and `SHA256SUMS` were generated from commit
  `5be29360c9ca7e4516366711ec09f7a9b4d56940`, downloaded, and checksum-verified.
- GitHub Release `v2.0.1` is published. Stable APT remains withdrawn; no v2 APT
  repository was published.

## Next: version 3

The v2.0.1 source release and installation page are verified. Proceed with the
separately scoped v3 planning below:

- Consolidate future product scope, architecture, acceptance criteria, ADRs,
  testing strategy, security plan, and measurable milestone roadmap in `docs/v3/`.
- Evaluate Arch Linux, Fedora Linux, Void Linux, openSUSE Tumbleweed, CentOS
  Stream, and Gentoo. Prioritize the first four; target eight fully qualified
  distributions and treat ten as a stretch goal.
- Research APT hosting, builds, signing, versioning, upgrade/recovery, rollback,
  mirrors, maintenance, and supply-chain risks. Keep it Planned unless the
  feasibility study supports a prototype and the owner approves it.
- Keep local implementation and verification first; report exact changes,
  evidence, and limitations for owner approval before repository updates.

## Preserved implementation and history

The current source already includes a native manager CLI, a foreground
read-only Unix-socket service, a partial local Control Center with confirmed
desktop start/stop, display migration, and multi-distro lifecycle code. These
are current source facts; completeness varies by component and device evidence.
The v2.0.0 release history, device runs, and prior roadmap remain in the dated
[release report](../release/V2-RELEASE-REPORT.md),
[device audit](../audit/DEVICE-VERIFICATION.md), and
[repository snapshot](../audit/REPOSITORY-STATE.md).
