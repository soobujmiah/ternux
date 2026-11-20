# Ternux V3 prioritized gap analysis

**Baseline:** source `f04b7261ef9ba2dba2c38fd987f760e80583f2d2`; published source release v2.0.1.\
**Status:** initial priority order; Phase 1 audit closure and owner review of architecture deltas are still required before major V3 implementation.\
**Source plan:** [`../v3/IMPLEMENTATION-ROADMAP.md`](../v3/IMPLEMENTATION-ROADMAP.md), [`../v3/SECURITY-ROADMAP.md`](../v3/SECURITY-ROADMAP.md), ADRs, and [`../project/PROJECT-ROADMAP.md`](../project/PROJECT-ROADMAP.md). Existing milestone gates remain authoritative where the requested V3 master goal does not add a stricter requirement.

## Current baseline

- `main` is clean and equals `origin/main` at `f04b726…`; v2.0.1 remains the published source release. Stable APT is withdrawn.
- Four owner-confirmed profile targets remain Debian, Ubuntu, Kali, and Alpine. Fifteen recipes exist; the other eleven are not promoted by this audit.
- Current source already contains a CLI, multi-guest recipe/lifecycle code, a read-only native manager service, typed manager schemas, a loopback Control Center preview with confirmation-bound start/stop jobs, diagnostics/repair, and three registry-backed workload extensions.
- Current source does not contain a supervised manager service, full Control Center, general-purpose V3 Extension SDK, common Device Bridge, or unified AI/compute orchestrator. Existing docs mostly call these partial/planned.
- The exact current-head CI passes. Local test fixtures also pass for current tests; physical clean install, manual browser rendering, and ADB-connected evidence were not available in this session.
- Public website is behind current `main`: its English homepage reports v2.0.1 and four profiles, while Bengali still says three profiles and that the next v2 platform release is being prepared. The source copies are aligned, but Pages has not been redeployed from the current main SHA. Stable APT endpoints return 404 as documented.
- Action immutability, uninstaller source authenticity, and startup KDF remain the highest security gaps. Installed-source parity against release v2.0.1 remains divergent at 12 paths/ownership cases.

## Dependency-ordered roadmap

| Order / milestone | Work package | Current gap | Dependencies | Exit evidence |
|---|---|---|---|---|
| **Audit gate (pre-V3.0)** | Finish repository-wide inventory review and reconcile the five audit deliverables | Inventory hashes exist, but file-by-file semantic classification, implementation/docs/test links, binary provenance/licensing, and website route review are not complete | Phase 1 files and current source tree | Every tracked/relevant file has a reviewed status; all unreadable/unavailable items named; binary metadata and provenance scoped; prioritized gaps reconciled with current V3 ADRs and four-profile baseline |
| **V3.0 Foundation — S0** | Pin all third-party Actions to verified full SHAs and add automated policy enforcement | Baseline 64/64 used movable tags; current local diff pins all 64 and adds a CI policy check, with changed-workflow CI pending | Ten upstream release refs resolved; least-privilege workflow permissions/token scopes reviewed | Local policy test passes all current references; exact-head CI, provenance/signature review, and action update process still required |
| **V3.0 Foundation — S1** | Make uninstaller direct-pipe recovery immutable and digest-verified | Recovery sources mutable `main` | Version/digest source of truth, trusted archive, bootstrap compatibility | Tamper, wrong commit, missing network, archive root, traversal/symlink, partial download, and scoped cleanup fixtures; copyable fail-closed recovery |
| **V3.0 Foundation — S2** | Migrate the startup verifier to portable versioned KDF metadata without resetting credentials | Salted single SHA-256 is fast; current documented threat boundary is narrow | Termux availability/portability, viable parameters, stored format, backup/recovery wording | Legacy success migrates only after valid authentication; wrong password, corrupt record, interruption, recovery, no secret logging, and measured Termux cost pass |
| **V3.0 Foundation — S3** | Complete installer/update/uninstall recovery and provenance contracts | Update journals/verified workload paths are uneven; live source differs from release tag; clean device install is unqualified. Full uninstall previously continued after session-stop failure; that data-safety defect is fixed locally with a regression test. Update backups persist without quota/retention policy. | Audit all downloads, extraction roots, permissions and ownership; retain v2 compatibility | Installer/update/rollback/recovery idempotency, low storage and interrupted-network fixtures; backup retention policy; exact source/digest; clean source install and removal qualification on supported profiles; no unrelated data loss |
| **V3.0 Foundation — S4** | Correct release/version/support and bilingual architecture mismatches; preserve v2 claims | Kali missing from one v3 diagram and stale implementation-version wording (both corrected locally); production Bengali home is stale, including direct-pipe install commands; OG card has an unresolved MIT-vs-Apache label; site visual pass absent | Audit matrix and exact release/source facts; resolve the card's asset-specific license intent; a production Pages dispatch requires the applicable human authorization gate | English/Bengali docs and site agree with implementation; broken link/route checks pass; production deploy is based on exact verified main; browser rendering reviewed at phone/desktop sizes; v2 published claims remain distinct |
| **V3.1 Unified workstation management** | Finish per-guest registry/lifecycle, optional service supervision, structured jobs/logs, resource awareness, diagnostics and repair | Read-only manager service is foreground; Control Center covers only bounded preview workflows; resource policy is incomplete | V3.0 schemas, ownership contract, security review | CLI usable with service stopped and zero guests; service socket/API negatives, per-guest start/stop/restart/recovery, idempotence, locks, health, memory/disk state and unrelated guest preservation pass |
| **V3.1 Control Center completion** | Grow the existing Control Center with only backend-backed workflows | UI is not a complete manager; native Android client and several panels/actions are absent | Stable manager API/jobs and supervisor behavior | Every visible action invokes one typed backend operation and reports observed result; no decorative control; accessibility/keyboard, loopback/auth, resize, empty/error states, cancellation/recovery and real browser inspection pass |
| **V3.2 Workload/compute integration** | Consolidate capability, package, artifact, license, resource and lifecycle contracts for existing Ternux workloads | Three workload packages use a registry, but no platform-wide job/resource policy; HTP/SD routes remain experimental or preview | V3.1 lifecycle/jobs, artifact manifest and device capability contracts | Stable CPU fallback; separate detect vs execute vs correctness/performance; digest/license/ABI checks; storage/RAM/thermal limits; rollback/remove; real tasks on named hardware |
| **V3.2 Extension SDK decision** | Implement an SDK only after comparing it to the existing workload/extension registry | A planned general manifest could duplicate `lib/workload-registry.sh` and `lib/extension.sh` | Audit manifest fields, dependency handling, permissions and ownership first | One canonical validated manifest contract or an ADR proving why a distinct SDK is necessary; malicious manifest/path/license/permission/update/remove tests; no ambient Termux access |
| **V3.2 Device Bridge** | Broker camera/mic/storage only when a user action needs access | Existing Termux API helpers are point features; the general broker is design only | Manager permission, job/cancel, data-ownership and privacy contracts | Grant/deny/revoke/cancel/timeout/error flows; media/file integrity; no background capture; named-device qualification |
| **V3.3 Ecosystem maturity** | Broaden distro/device/integration qualification and developer interfaces | Current Firefox clean-guest matrix omits Kali; other profiles lack support evidence; docs and visual/release parity need ongoing maintenance | V3.0–3.2 contracts, exact release workflows, per-profile evidence | Each promoted distro passes the full clean lifecycle/browser/graphics/audio/input/storage/removal matrix; exact-source CI and artifact provenance; support claims limited to evidence |

## Integration discovery

### Candidate: local verified artifact cache (deferred; not selected for implementation yet)

| Question | Assessment |
|---|---|
| Problem solved | Low-connectivity or interrupted downloads can force repeated network fetches for identical pinned Ternux sources and workload artifacts. Existing installers currently use path-specific download/staging behavior. |
| Why it may belong | A verified cache can improve offline repair/reinstall and fit Ternux's local-first Android workstation model without adding a remote account or service. |
| Dependencies | Existing source/workload manifest digest and architecture fields, private Termux cache root, locking, quota/eviction policy, and safe staging/rename; no new external dependency is inherently required. |
| Android/PRoot compatibility | Termux host storage and guest-visible package flows need explicit ownership. Never expose the whole cache to guests by default; a selected verified artifact can be staged into one managed guest. ARM64 and per-artifact ABI must remain declared. |
| CPU/RAM/storage | Low CPU/RAM; storage use is variable and can be large for model/runtime archives. Must have a configurable quota, free-space preflight, and deterministic eviction that never removes active/user model data. |
| Security/licensing | Cache key must include immutable artifact identity/digest/architecture; rehash on reuse; reject traversal/symlink archive members; preserve license/notice files; treat a valid cached digest as integrity only, not publisher authenticity. |
| Maintenance / complexity | Medium maintenance and medium implementation complexity; cache invalidation, migration, concurrent writers, partial files and quota races add lifecycle surface. |
| Test strategy | Hit/miss, wrong digest, changed manifest, partial download, offline reuse, interrupted writer, concurrent writer, low disk, path traversal, symlink, eviction safety, remove/reinstall, and no cache-to-guest broad bind. |
| Milestone | **V3.1 candidate**, after S1/S3 produce one trusted artifact contract. Defer from V3.0 until the complete download-path audit shows enough repeated code and measurable benefit. |

### Not selected from current evidence

No new cloud product, package store, model service, or third-party extension marketplace is selected. Current Ternux-owned workload and Termux API paths should first be stabilized and measured. A marketplace would add identity, signing, abuse response, licensing, and maintenance obligations without evidence that it solves the immediate V3.0 gaps.

## Confirmed documentation corrections after baseline closure

1. Completed in this audit: add Kali to the v3 system runtime diagram in both languages; rendered browser inspection remains open.
2. Completed in this audit: date/scope the historical installed-package statement and link the current v2.0.1 environment snapshot.
3. Make the exact released v2.0.1 versus unreleased current-main source distinction explicit in live parity/reconciliation docs.
4. Keep native manager/Control Center, Device Bridge, workload orchestration and Extension SDK status labeled partial/planned until their exact gates pass.
5. Completed in this audit: clarify ADR-0001/0002 in both languages to state that manager and ownership implementations have partial foundations, with the full contracts still pending.

## Gate and implementation status

No major V3 product source change has been made during this baseline pass. The next authorized work is to finish the full audit, validate the proposed priority/dependency ordering against every V3 ADR and contract, and only then begin V3.0 security/reliability work locally. Hardware-dependent items can be implemented in code while remaining `NOT YET TESTED`, but must not be called verified or released without their stated device evidence.
