---
title: "Ternux next actions"
description: "Completed v2.0.1 release gates and active v3 foundation work."
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

## Active: version 3 foundation

The v2.0.1 publication gate is complete. V3 foundation planning and security
baselining are active, separate from the frozen v2 feature set:

- `docs/v3/` now contains an APT feasibility recommendation, distribution
  qualification matrix, security roadmap, testing strategy, and measurable
  implementation phases. Architecture remains partial; capabilities are not
  being claimed as shipped.
- Evaluate Arch Linux, Fedora Linux, Void Linux, openSUSE Tumbleweed, CentOS
  Stream, and Gentoo. Prioritize the first four; target eight fully qualified
  distributions and treat ten as a stretch goal.
- Current APT recommendation: keep it out of v3.0's critical path; continue the
  version-specific source installer unless a bounded prototype demonstrates
  user value and passes security, upgrade, rollback, and operational gates.
- Completed locally in the active slice: stale updater-lock status propagation
  is fixed and regression-tested; CI now has a ShellCheck error-level baseline.
- Next implementation gate: inventory and pin workflow actions to reviewed
  commit SHAs, then design immutable uninstaller recovery. Treat startup-verifier
  migration as a separate compatibility change.
- Continue local-first implementation and verification before repository sync.
  Current owner authorization covers Ternux development and repository work.

## Preserved implementation and history

The current source already includes a native manager CLI, a foreground
read-only Unix-socket service, a partial local Control Center with confirmed
desktop start/stop, display migration, and multi-distro lifecycle code. These
are current source facts; completeness varies by component and device evidence.
The v2.0.0 release history, device runs, and prior roadmap remain in the dated
[release report](../release/V2-RELEASE-REPORT.md),
[device audit](../audit/DEVICE-VERIFICATION.md), and
[repository snapshot](../audit/REPOSITORY-STATE.md).
