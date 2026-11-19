---
title: "Ternux v3 security and supply-chain roadmap"
description: "Prioritized security findings, implementation sequence, and evidence gates for Ternux v3."
lang: "en"
---

## Baseline and boundaries

Ternux runs under the Termux Android application UID. PRoot does not create a
kernel security boundary from that UID. The existing security model remains
the threat-model baseline; this roadmap tracks implementation work and does
not imply that a control is already deployed.

Known findings are maintenance risks, not evidence of a confirmed compromise:

| Finding | Current evidence | Priority and intended control | Verification gate |
|---|---|---|---|
| Uninstaller recovery may fetch source from mutable `main` | v2 reconciliation records that direct-pipe fallback fetches implementation files from mutable branch; scoped deletion checks exist | High: bind recovery to a versioned immutable source archive and expected digest; fail closed when identity cannot be verified | Tampered archive, stale version, missing network, checksum mismatch, symlink/path traversal, and scoped deletion fixtures |
| Startup password verifier uses salted single SHA-256 | `lib/auth.sh`, `lib/password.sh`, and installer phase use one fast SHA-256 digest; documented as a convenience gate, not an OS security boundary | Medium: choose a portable slow KDF with explicit cost/version metadata; preserve legacy verification only for migration and never silently reset credentials | Legacy login, successful rehash, wrong password, corrupt record, interrupted migration, performance bound, and recovery tests on Termux |
| GitHub Actions references use mutable version tags | Workflow search shows `uses:` entries such as `actions/checkout@v5`; tags may move | High: pin third-party actions to reviewed full commit SHAs, retain human-readable version comments, automate reviewed update PRs | Policy linter rejects non-SHA action refs; test all workflow expressions and run required workflows on exact commit |
| Error-level ShellCheck baseline is now in CI; warning/info findings remain ungated | Local run found invalid recursive `return` usage in stale update-lock recovery and added regression coverage | Medium: triage remaining warnings, add narrow justified suppressions only where needed, and maintain scoped CI coverage | CI reports no new actionable errors; suppressions include rationale and narrow path/line scope |
| Python dependencies need ongoing supply-chain review | Build workflows use hash-checked requirements in some paths; project-wide dependency inventory and update policy need reconciliation | Medium: inventory runtime/build/test deps, separate lock files, require hashes where feasible, license and advisory review | Clean locked install, hash mismatch rejection, dependency inventory parity, and advisory review record |
| Artifact identity and ownership cross many installer components | Existing manifests/checksums cover some packages; controls vary by artifact path | High: common manifest contract for source, version, arch, digest, license, owner, and uninstall semantics | Manifest schema tests, tamper/path traversal tests, and package-by-package provenance report |

## Delivery order

### S0 — Immediate CI guardrails

- Inventory every workflow action and classify first-party, third-party,
  reusable workflow, container, and downloaded tool references.
- Pin action refs to verified full commit SHAs; document update procedure and
  review action permissions/job token scopes.
- **Implemented locally:** CI installs ShellCheck and runs `--shell=bash
  --severity=error` one file per process over the production shell sources.
  Local baseline found and fixed invalid recursive `return` usage in stale
  update-lock recovery; `tests/update_transaction.sh` now covers lock cleanup
  both with and without a recovery journal. Warning/info cleanup remains
  incremental; no broad suppressions were added.
- Tighten the ShellCheck threshold after the existing warning/info baseline is
  triaged; keep unavoidable suppressions narrow and explained.
- Inventory Python dependency inputs and hash/lock coverage. Do not apply broad
  version bumps or unreviewed overrides as a substitute for audit.

### S1 — Immutable recovery and artifact contract

- Remove mutable-branch execution from uninstaller/recovery paths. Resolve the
  version from installed metadata or an explicit user selection, fetch its
  immutable archive, verify its SHA-256 against a trusted project manifest,
  and execute only after path and syntax checks.
- If no trusted version/digest is available, stop with a copyable recovery
  instruction; do not fall back to `main`.
- Add negative fixtures for altered archives, archive-root mismatch, stale
  hashes, symlinks, traversal, partial downloads, and no network.

### S2 — Credential verifier migration

- Define the actual threat boundary: the verifier protects accidental/shared
  terminal access, not files from the Android app owner or a process with the
  same UID.
- Select a KDF only after checking Termux availability, parameter support,
  memory/time cost, portability, and maintenance. Store algorithm, parameters,
  salt, and digest in a versioned record; never log password material.
- Support old records by constant-time comparison where available, then
  rehash only after successful authentication. Provide a documented backup and
  recovery route. Do not invalidate existing users or silently change their
  configured password.

### S3 — Common permissions and evidence

- Review file modes, Termux/guest path boundaries, socket permissions,
  temporary files, logs, archive extraction, symlink races, and cleanup lists.
- Produce artifact provenance and license inventory for release assets.
- Keep security regression fixtures in the aggregate runner and exact-release
  CI; document limitations where Android/PRoot cannot provide stronger
  isolation.

## Security release gate

No item becomes `VERIFIED` from a source change alone. Each implementation must
have focused negative tests, aggregate CI, exact-commit evidence, documented
migration/recovery behavior, and a review that confirms user guest data and
unrelated Termux packages remain protected. High-severity unresolved findings
block a stable v3 release; accepted residual risks must name the owner,
mitigation, and review date. Do not weaken a control to obtain a passing test.
