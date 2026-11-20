# Ternux V3 independent repository audit baseline

**Audit date:** 2026-11-20 (Asia/Dhaka)\
**Audit status:** IN PROGRESS — this baseline captures verified inventory, current environment, repeated automated checks, and initial findings. It is not the final full-file semantic audit or permission to begin major V3 implementation.\
**Exact source baseline:** `f04b7261ef9ba2dba2c38fd987f760e80583f2d2` (`main == origin/main`)\
**Published source release:** v2.0.1 at `5be29360c9ca7e4516366711ec09f7a9b4d56940`\
**Remote:** `https://github.com/soobujmiah/ternux.git`

## Executive summary

At the source baseline, the checkout was clean and exactly equaled `origin/main`. The current audit scope contains 1,791 tracked source-baseline paths (1,729 text-classified and 62 binary-classified), nine untracked audit deliverables plus two untracked policy tests, and 9,879 ignored worktree paths: 11,681 distinct filesystem items in the repository tree. Tracked files are listed with baseline Git mode/size/SHA-256 in [`FILE-INVENTORY.md`](FILE-INVENTORY.md); untracked audit edits have current hashes in its delta, and ignored files have a complete path/size/SHA-256 ledger in [`IGNORED-ARTIFACT-INVENTORY.md`](IGNORED-ARTIFACT-INVENTORY.md). The row-level semantic review, active/reference state, implementation/documentation relationship, test coverage, and much third-party provenance/license/architecture review remain pending. No submodules, Git LFS pointers, or tracked symlinks were found; the local Git binary lacks the optional `git lfs` subcommand, and `.gitattributes` does not configure LFS filters.

The actual host is the Redmi Turbo 4 Pro (`25053RT47C`), Android 16, ARM64, in native Termux. Device and Ternux inspection found v2.0.1 installed, four guest profiles (Debian 13.7, Ubuntu 26.04.1, Kali 2026.3, Alpine 3.24.4), Adreno 825, and a current doctor report selecting the Zink/Turnip renderer. A Debian PRoot desktop session was already running with Debian and Ubuntu desktops active. The environment snapshot and reproduction commands are in [`V3-ENVIRONMENT-BASELINE-2026-11-20.md`](V3-ENVIRONMENT-BASELINE-2026-11-20.md).

Independent source review found 64/64 workflow Action refs at mutable tags in the clean baseline, direct-pipe uninstaller recovery from mutable `main`, and startup credentials using one salted SHA-256 pass. The current local workflow edit replaces the 64 refs with 10 exact upstream commits and adds an automated pin policy; its local check passes, while exact-head CI after that edit is pending. The uninstaller and credential findings remain open. A separate inspection of `lib/ternux-install-firefox-esr.sh` found that its Ubuntu-specific Firefox ESR installer consumes Mozilla’s mutable `firefox-esr-latest` URL without an expected digest or version pin (SEC-08). Additional download-path review found the host Powerlevel10k setup clones moving upstream `HEAD` and sources it from later Zsh sessions without a commit or digest pin (SEC-09). Package-lock review found 105 records without `resolved` source or `integrity` digest (94 non-optional); all 105 now have exact-version npm registry HTTPS tarball URLs and SHA-512 SRI, and a local CI policy check covers all 307 package records. The enriched candidate passed isolated `npm ci` (210 audited, zero vulnerabilities); changed-workflow exact-head CI is still pending. Package publisher provenance, lifecycle scripts and license review remain open. The read-only installed-source check reports 12 differences versus the published v2.0.1 source tag and 17 versus current `main`; this includes two unmapped legacy Debian/Ubuntu app-center launchers. These counts were independently repeated and source-tag attribution is separated in [`SECURITY-RELIABILITY-AUDIT.md`](SECURITY-RELIABILITY-AUDIT.md).

Current exact-head Validate, package-artifact, and repository-state-contract GitHub runs all passed on the untouched source baseline. They do not cover the local workflow pin edits, which still need exact-head CI. Local focused tests now pass 228/228, including the full-uninstall stop-failure guard and extension archive traversal/symlink and whitespace-target checks; the updater transaction suite passed standalone and in the final aggregate run. The current audit-document set passes `tests/docs_check.py` with 8,783 assertions, 802 links, and 25 bilingual pairs; see [`TEST-EVIDENCE-MATRIX.md`](TEST-EVIDENCE-MATRIX.md). Native Termux Node and ADB are present but fail before startup due a missing Android linker symbol. An isolated official Node v22.23.5 ARM64 toolchain was therefore run in Debian PRoot against a temporary worktree copy: `npm ci` audited 210 packages with 0 advisories, Astro built 124 pages and finalized 60 HTML routes, and `npm run format:check` passed. This does not establish browser rendering or clean-device install behavior. Clean Firefox package CI covers Debian, Ubuntu, and Alpine, not Kali.

Live production inspection found a release-relevant bilingual mismatch. Both `/ternux/` routes return HTTP 200 with `Last-Modified: Fri, 20 Nov 2026 03:40:54 GMT`, tied to Pages deploy run `44669285260` at older source SHA `cc7683ed49a5f259e26024f583f3c6407175d76c`. The public English homepage says v2.0.1 is published and lists four verified profiles; the public Bengali homepage still says only three profiles are supported and describes the next v2 platform release. Current local `src/pages/index.astro` and `src/pages/bn/index.astro` have both been updated, so the mismatch is a stale production deployment, not current source parity. Current stable APT `InRelease` and bootstrap endpoints both return HTTP 404. A website deployment is a production publication and was not dispatched during this audit pass.

## Inventory and inspection coverage

| Requirement | Evidence at this baseline | Status |
|---|---|---|
| Exact commit, branch, remote, and Git state | `git status`, `git rev-parse`, remote, and history checked; `HEAD == origin/main == f04b726…`; clean before audit deliverables | Complete for initial state |
| Tracked path inventory | 1,791 tracked paths; each includes baseline mode/size/SHA-256, byte-level text/binary class, and path/extension-derived file kind | Baseline inventory complete; per-file semantic/reference/test coverage remains explicitly pending in every row |
| Untracked/ignored items | Initial tree had no pre-existing untracked source. Nine current audit deliverables, two untracked policy tests, and 39 tracked edits (including npm lock integrity metadata) are listed with current hashes/scope in the inventory delta. All 9,879 ignored paths are separately inventoried by path, bytes, and SHA-256 | Worktree bytes are inventoried; ignored dependencies/build outputs still need semantic/license/provenance review |
| File type and binary identification | 1,729 text and 62 NUL-detected binary files; extension/path inventory includes 174 Markdown, 869 YAML/YML, 79 Python, 67 `.sh`, 28 JSON, 355 SVG, and 56 PNG files | Format/hash/dimension/header metadata and group provenance reviewed in [`BINARY-ASSET-AUDIT.md`](BINARY-ASSET-AUDIT.md); OG-card license scope, Avro upstream revision, generator reproducibility, and runtime compatibility remain open |
| Symlinks, submodules, LFS | Git mode scan found none; no `.gitmodules`; no LFS pointer content; no LFS extension configured | Complete for tracked repository metadata |
| Syntax/structured parsing | Python `compile()` 79/79; JSON 28/28; XML/SVG 356/356; strict YAML duplicate-key rejection 869/869 tracked documents (plus 2 ignored dependency YAML files parsed successfully) | Complete for these parse checks |
| Source/docs/test relationship | Preliminary subsystem matrix in [`IMPLEMENTATION-DOCUMENTATION-MATRIX.md`](IMPLEMENTATION-DOCUMENTATION-MATRIX.md) | Partial; file-by-file matrix review pending |
| Runtime/device state | Current doctor, manager status/catalog, OS release files, host properties, memory/storage, process snapshot, read-only parity | Complete for captured Phase 0 evidence; ADB transport unavailable |
| External dependencies and release refs | Action pins and policy, lock package/version counts, npm source/integrity fields and CI guard, release inputs, installer and workload hashes | Partial; exact-head CI, license/provenance/native binary review pending |

`FILE-INVENTORY.md` is generated from Git's tracked path/mode list and exact current bytes. It is not a claim that every file's behavior has already been manually read. The per-file review must replace `PENDING` only when source, references, docs, tests, and activity status have evidence. For binaries, metadata inspection must not be reported as visual/content inspection.

## Previous audit comparison

[`REPOSITORY-FULL-AUDIT-2026-11-20.md`](REPOSITORY-FULL-AUDIT-2026-11-20.md) remains unchanged as historical evidence. Its primary audit baseline was `2046d10a…`; later follow-up sections record changing main SHAs and website/CI work. This independent baseline uses `f04b7261…`, not the earlier counts or conclusions. Prior risk rechecks are recorded in the security audit; current findings do not treat source presence or an earlier CI pass as proof of physical qualification.

| Previous item | Independent current result |
|---|---|
| Mutable GitHub Actions references | 64/64 were tag refs in the clean baseline; local current diff pins all to 10 exact commits and adds policy enforcement. Local policy passes; changed-workflow CI is pending. |
| Uninstaller recovery from mutable `main` | Still present in direct-pipe fallback. |
| Fast single SHA-256 startup verifier | Still present. |
| Live installed-source mismatch | Reproduced: 12 vs published v2.0.1 source, 17 vs current `main`; read-only, no live writes. |
| Clean distro/browser qualification | Partially addressed by passing current exact-head CI for Debian, Ubuntu, Alpine; Kali clean-browser path and clean Ternux device install remain unverified. |
| Bootstrap source synchronization | Current `tests/bootstrap_source_sync.sh` passes; source and standalone/bootstrap snapshots agree. |

## Initial documentation findings

1. `docs/v3/SYSTEM-ARCHITECTURE.md` guest-layer diagram omitted Kali although architecture, workspace, and roadmap prose name the four-profile baseline. Corrected in English and Bengali during this audit.
2. `docs/project/IMPLEMENTATION-STATUS.md` reported the installed package as v2.0.0 without a date/scope boundary; the current native Ternux command reports v2.0.1. Clarified the historical observation and linked the dated environment baseline.
3. The Control Center/manager, Device Bridge, Compute/AI orchestration, and general-purpose Extension SDK are partial or planned. Current docs largely label these states accurately; specific source-to-documentation claims still need full matrix review.
4. The deployed Bengali homepage is stale relative to the English homepage and current `main`; source has already been corrected, but Pages has not been redeployed from the current main SHA.
5. ADR-0001 and ADR-0002 described their implementation as wholly pending although current source contains partial native manager/Control Center and owner-scoped cleanup foundations. Their status wording was clarified in English and Bengali to distinguish partial work from the remaining architecture.
6. Workload maturity metadata labeled Stable Diffusion as `supported`, while both workload guides called it a preview and the CLI displayed the metadata verbatim. Corrected locally to `experimental` without disabling installation; a focused display regression now checks the agreement.

## Changes made during this audit pass

Audit deliverables include this report, the environment snapshot, the 1,791-row tracked inventory, the exhaustive ignored-artifact inventory, binary metadata review, and initial implementation/security/test matrices. Confirmed documentation defects were corrected in the English/Bengali V3 system diagrams, the dated implementation-status wording, and ADR-0001/0002 status lines in both languages. A confirmed `uninstall all` safety defect and an extension symlink-target parsing defect (absolute target with embedded whitespace bypassed the verbose-listing parser) were fixed locally and covered by regression tests. Current hashes and the scope of 39 tracked edits (documentation/source-page/bootstrap-pin changes, workflow pin/policy integration, uninstall safety, workload maturity reconciliation, and npm lock integrity metadata) plus nine untracked audit documents and two untracked policy tests are recorded in [`FILE-INVENTORY.md`](FILE-INVENTORY.md). No managed guest, Android configuration, or live service was changed. The prior dated audit was not edited.

## Unresolved work before Phase 1 can close

- Finish the semantic review of every row in the inventory; classify active, referenced, generated, fixture, duplicated, obsolete, or orphaned; connect implementation, docs, tests, and evidence.
- Close the binary-audit open items: OG-card license scope/source, Avro upstream revision, asset-generator reproducibility, and runtime compatibility; metadata-only checks must remain distinct from visual/content review.
- Continue auditing all installer, updater, uninstaller, workload, and packaging download/extraction paths, cleanup ownership, permissions, secrets, and failure recovery; SEC-08 records the Firefox ESR mutable vendor artifact and archive-member validation gap, and SEC-09 records the Powerlevel10k moving-HEAD clone. Other paths remain under review.
- Finish bounded low-storage/interrupted-network update recovery qualification and document that retained rollback backups currently have no quota or automatic retention policy.
- Complete English/Bengali and website capability comparison against actual implementation, including canonical route/navigation and release claims.
- Reassess API/manager service, process supervision, guest registration, resource monitoring, Control Center action wiring, graphics, camera/audio, workload lifecycle, and license handling against tests/evidence.
- Produce the prioritized V3.0–V3.3 gap analysis with integration choices and dependencies.
- Correct confirmed documentation defects after the gap analysis is reviewable.
- Refresh generated `.repo/` status only through the intended repository-state workflow when source changes are synchronized; never hand-edit it.

**Gate:** no major V3 implementation starts until the above baseline and [`V3-GAP-ANALYSIS.md`](V3-GAP-ANALYSIS.md) are complete and reconciled with the existing V3 roadmap. This is an active continuation record, not a release-readiness claim.
