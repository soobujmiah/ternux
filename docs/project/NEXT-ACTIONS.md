---
title: "Ternux next actions"
description: "Ordered local v2.0.1 candidate gates followed by future v3 planning."
lang: "en"
alt_url: "/bn/docs/project/NEXT-ACTIONS.html"
---

## Version 2.0.1 candidate gates

**Last reviewed:** 2026-11-18. The candidate is local and unpublished. Keep v2
frozen to current functionality and do not reopen stable APT.

1. Reconcile the v2.0.0 withdrawal record with the latest owner scope decision;
   preserve the old release tag and historical gate evidence.
2. Complete exact-version v1.4.0 and v2.0.1 install guides. Keep v2's guide
   marked candidate until its exact tag, source commit, archive digest, and
   release page are verified.
3. Align current `main` release status, feature maturity, four-distro baseline,
   limitations, English/Bengali docs, README, and site entry points. Keep the
   source-only / incomplete manager slice described at its actual maturity.
4. Run local source tests and bounded device checks. The owner requested the
   Debian desktop be started for a window-fit regression check; that existing
   guest was retained, `xdotool` was installed for testing, and the desktop is
   left open. Record this action separately from the earlier read-only audit.
5. Resolve local build limitations: Node cannot start in this Termux runtime,
   Docker is absent, and no four-distro clean-install matrix can run locally.
   Obtain exact-commit CI and package/site build evidence after approval and
   repository synchronization.
6. Generate release artifacts only from the final approved commit; verify
   provenance, source archive contents, version, checksums, release notes, and
   install command. Do not configure the withdrawn APT source.
7. Publish only after approval of the concrete reviewed candidate, then inspect
   the actual v2.0.1 release page and v1.4.0 page and verify both exact-version
   instructions against their tagged archives.

## After v2 publication: version 3

Only after the stable v2.0.1 release and its installation page are verified:

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
