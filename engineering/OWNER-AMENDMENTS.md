# Owner amendments to the Ternux master assignment

**Last updated:** 2026-11-14
**Authority:** Owner instruction in the active Ternux work session.
**Original scope:** [`MASTER-GOAL.md`](MASTER-GOAL.md) is retained verbatim as the original assignment. This file records later direction changes without rewriting that source.

## 2026-11-14 — Keep the next stable release in the v2 major

The owner changed the release sequence: the planned Ternux v3 platform work is
now part of the next v2-major stable release. Do not create a separate v3 stable
release. Keep the product's next stable target in the 2.x major and do not publish
it until its implementation, three supported guest profiles, host/guest lifecycle,
security, documentation, and release acceptance are complete.

Ternux v2.0.0 was withdrawn on 2026-11-14. Its GitHub Release object and stable APT publication are absent; the `v2.0.0` Git tag remains as source provenance and must not be reused. The next 2.x release needs a new version/tag after scope and compatibility review.

The architecture and acceptance material under [`docs/v3/`](../docs/v3/README.md) remains the specification source for this work. Its planned scope is brought into the v2-major release gate, including:

- Native Termux manager, service/job handling, CLI parity, Control Center, diagnostics, and safe migration.
- Multi-guest workspace registry, profile collection before install, per-guest lifecycle, and clean Debian/Ubuntu/Alpine install, update, recovery, and uninstall.
- Hardware capability registry, backend packages, resource policy, and evidence-based CPU/GPU/AI workload integration.
- LAI integration through its documented interface and model/workload lifecycle.
- Permission-aware Android Device Bridge for camera, microphone, and scoped storage.
- Extension manifests, permission grants, integrity checks, rollback, and safe removal.
- Security, accessibility, documentation, upgrade, recovery, and release gates defined by the architecture acceptance criteria.

A design document, source implementation, successful install, or CI build alone does not close a capability. Mark each phase by the evidence required in its acceptance criteria. Keep the stable APT channel withdrawn during this work.

## Current qualification note

The 2026-11-14 native device follow-up freshly resumed and verified Debian, exercised its visible X11 Firefox window, and cleanly stopped the desktop. A disposable generic Alpine image passed Ternux-managed install/exec/uninstall. This does not qualify Alpine's Ternux desktop recipe, Ubuntu, all three clean-install/update paths, or the full platform work above. See [`docs/audit/DEVICE-VERIFICATION.md`](../docs/audit/DEVICE-VERIFICATION.md).
