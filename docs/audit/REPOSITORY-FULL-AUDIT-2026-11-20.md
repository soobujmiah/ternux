# Ternux repository and website audit — 2026-11-20

**Audit date:** 2026-11-20 (Asia/Dhaka)
**Repository:** `soobujmiah/ternux`
**Remote `main` at audit start:** `2046d10a9191f41b52ca52f5cae74f418ad7f140`
**Published source release:** `v2.0.1`
**Scope:** full tracked-repository inventory, production code and workflow checks,
website structure and redesign, documentation consistency, automated tests,
plus a read-only check of the locally installed Ternux source parity.

This is an audit of source and available test evidence. It is not a fresh
Android-device qualification, a clean-install test, a visual-browser review, or
a claim that every optional workload works on every device. The prior
[2026-11-13 current-state snapshot](CURRENT-STATE.md) remains historical; its
dated facts are not substituted for this audit.

## Executive summary

The remote `main` checkout was current at audit start (`HEAD` equaled
`origin/main`). The repository builds as a static Astro site; the current build
produced 98 page outputs and finalized 60 HTML routes. The website has now been
reorganized around a shared bilingual documentation shell, clearer navigation,
searchable guide links, a calmer terminal/Linux visual system, and current
release/support facts.

The audit also found and corrected a real updater defect: stale update-lock
recovery used invalid recursive `return` syntax. The updater now propagates the
recursive result correctly, and regression cases cover stale-lock recovery with
and without a recovery journal.

The main open repository risk is supply-chain pinning: **64 of 64 GitHub Actions
references use movable tags rather than full commit SHAs**. Other high-priority
work already tracked in the v3 security roadmap is immutable uninstaller source
recovery. The password verifier remains a salted, fast single SHA-256 digest;
the existing threat model describes it as a convenience gate, not an OS
security boundary.

Stable Ternux APT remains withdrawn, so `pkg install ternux` is currently
unavailable. The v2.0.1 source release is published. v3 is active development
work, not a published package or a promise that every design is implemented.

## Repository inventory and method

At the audit baseline Git listed 1,733 tracked paths. The largest groups were:

| Surface | Count | Audit method |
|---|---:|---|
| Generated `.repo/` YAML state | 834 | Strict YAML parse with duplicate-key detection; generated-state workflow contract test |
| SVG assets | 355 | XML parse |
| Markdown documents | 143 tracked at baseline | Document-scope classification, bilingual structure, route/link/fragment checks |
| Python sources | 79 | Bytecode compilation; relevant test suites |
| Shell sources (`.sh`) | 67 | `bash -n`; production paths also error-level ShellCheck |
| Astro pages/components | 16 | Astro production build, formatting, static HTML checks |
| TypeScript/JavaScript | 5 | Astro build, Prettier, and `node --check` on standalone entry points |
| JSON manifests/schemas | 28 | Strict JSON parse plus schema and contract tests |

The remaining tracked files include workflow YAML, package metadata, license
and font assets, desktop launchers, native/runtime assets, benchmark records,
and experiment inputs. Tests exercise package-manager routing, guest setup,
optional installers, graphics/artifact provenance, permissions, update
transactions, and site/documentation behavior. Binary media were inventoried
and project-specific license checks ran where the repository provides them;
the inventory is not a manual pixel-by-pixel review of each binary asset.

## Current product and release state

- v2.0.1 is the published source archive/tag. The v2.0.0 GitHub release was
  withdrawn; its tag is retained for provenance.
- The stable signed Termux APT path is withdrawn. `pkg install ternux` does not
  currently resolve from a supported stable Ternux channel.
- Debian, Ubuntu, Kali Linux, and Alpine are the four owner-confirmed v2
  desktop profiles. Eleven more named recipes exist but are outside that
  verified baseline. Their evidence depth differs; Kali has no equivalent
  clean-install Firefox matrix in this environment.
- The runtime catalog has 15 named guest profiles. The website and installation
  docs previously said “12 additional” and omitted Kali from a support table;
  these contradictions are corrected to four verified plus eleven unqualified.
- Ternux runs as the Termux app UID under PRoot. PRoot does not create an
  Android-kernel security boundary from that UID.
- The current source has native manager and Control Center foundations, but
  source presence does not mean those features are part of the published v2.0.1
  package. The v3 roadmap now labels active work and future designs separately.

## Website audit and changes

### Findings corrected

1. The Bengali documentation navigation sent “Project status” to the v3
   architecture overview. It now links to the Bengali project roadmap.
2. English and Bengali guide navigation had different destinations and lacked
   a consistent information architecture. They now share five mirrored
   categories with 22 destinations each.
3. The documentation index said the next stable release remained v2 and
   presented a signed APT package as an install path, despite v2.0.1 being
   published and stable APT being withdrawn. Both language pages now state the
   current source-release/channel status and that `pkg install ternux` is
   unavailable.
4. The support table omitted Kali and showed twelve unqualified profiles even
   though the manifest contains 15 total and the supported baseline contains
   four. Landing pages and installation docs now use the current 4 + 11 count.
5. English and Bengali guide pages duplicated their sidebar, breadcrumbs,
   table-of-contents logic, and article footer. They now render through the
   shared `DocumentationLayout.astro` component.
6. Guide pages had no quick way to find a topic in the long navigation. The
   shared shell adds an accessible search input, a `/` focus shortcut, an empty
   result message, current-page marking, breadcrumbs, a table of contents, and
   documentation/support next steps.
7. Website styles had accumulated into one 4,885-line stylesheet. The existing
   cascade is now separated into ordered style layers, with an explicit
   `site.css` entry point and a final terminal-inspired design layer. The new
   palette uses graphite surfaces, restrained green status accents, readable
   typography, compact borders, and responsive documentation columns. Reduced
   motion and keyboard focus styles remain in place.
8. The homepage headline included an unrelated personal signature in its
   accessible name. It now identifies the product as a no-root ARM64 Linux
   desktop on Android and puts the platform facts in a small status label.

### Design and technical limits

The production build and generated HTML were checked, including duplicate IDs,
landmarks, image alternatives, metadata, generated internal links, and page
routes. CSS and Astro source pass the repository formatting/build checks.
There was no functioning browser/screenshot tool in this environment for a
visual capture at phone and desktop widths. The optional Superdesign canvas
login returned `Invalid poll token`, so no remote draft was made. The local
implementation proceeded from the repository’s design system and static
responsive checks; a human visual pass is still useful before a production
Pages deployment.

## Code and supply-chain findings

### High priority

- **GitHub Actions references are mutable.** All 64 action references in the
  repository workflows use version tags (`@vN`), with zero full 40-character
  commit-SHA pins. Pin each reviewed action to a verified SHA, retain a readable
  version comment, and define a reviewed update process.
- **Uninstaller recovery uses a mutable source branch in its fallback path.**
  Bind recovery to an immutable versioned archive and trusted digest, and fail
  closed if its identity cannot be verified. Negative archive/tamper and
  path-safety cases are already outlined in the v3 security roadmap.

### Medium priority

- **Password verifier is a fast hash.** The current verifier uses salted single
  SHA-256. Its documented scope is accidental/shared terminal access, not
  protection from the Android app owner or another process with the same UID.
  A versioned slow-KDF migration needs legacy-login, rollback, interruption,
  recovery, and performance coverage.
- **Live installed source does not match the checkout.** The read-only parity
  check inspected 1,648 Ternux-owned paths across native Termux and four guests
  and reported 13 mismatches. Two guests retain the same legacy
  `/usr/local/bin/ternux-app-center` Synaptic wrapper (SHA-256
  `6cc4c39f7ed5a66c59751a67c9d61a59617d773d2cfea315327287db5014946a`). Current
  source removes that legacy launcher during managed asset installation; the
  installed copies need a later managed reconciliation. The other differences
  include current `lib/update.sh`, manager modules, assets, and generated
  package-manager files. No live files were changed during this audit.
- **Clean distro-browser qualification could not run locally.**
  `tests/firefox_package_matrix.sh` requires Docker, and this Termux/PRoot
  environment has no Docker daemon. The GitHub Linux runner is expected to run
  that matrix; do not infer a local clean Firefox test from the other distro
  tests.
- **The source snapshot synchronization test is commit-sensitive.** Changing
  updater source makes the working tree differ from the previously pinned
  immutable archive until the new implementation commit is made and
  `install.sh`/`lib/core.sh` are repinned to that commit’s verified source
  archive. This is a deliberate two-commit release/bootstrap constraint; the
  final synchronized test must pass before the change is considered complete.

### Lower priority and maintained behavior

- NPM’s current lockfile audit reported zero vulnerabilities on 2026-11-20.
- A high-confidence private-key/GitHub-token pattern scan returned no matching
  tracked source files. This is a narrow pattern scan, not a proof that a
  credential can never be encoded in another form.
- All 849 YAML documents parsed with duplicate-key rejection; all 28 JSON files
  parsed; all 355 SVGs parsed as XML. Workflow action pinning is still a
  separate supply-chain concern even though the YAML is syntactically valid.
- The shared package-manager launcher dispatches APT/APK/Pacman/DNF/Zypper/XBPS
  operations to their native tools. Its installed desktop name is selected per
  package family (Synaptic for APT, APK for Alpine, etc.); source tests cover
  all six dispatch families. The live parity check found a legacy unowned
  wrapper in Debian and Ubuntu that is not the current source launcher.
- `docs/audit/CURRENT-STATE.md` and the lower sections of the feature matrix
  are dated 2026-11-13/18 evidence snapshots. New summary links now identify
  them as historical and point to this current audit.

## Verification results

| Check | Result |
|---|---|
| `npm run build` | Pass — 98 page outputs, 60 finalized HTML routes |
| `npm run format:check` | Pass |
| `python3 tests/docs_check.py` | Pass — 7,333 assertions, 672 internal links, 25 bilingual page pairs |
| `bash tests/focused.sh` | Pass — 223/223 |
| `bash tests/update_transaction.sh` | Pass — update, rollback, crash recovery, stale lock, concurrency, symlink, and migration cases |
| `bats tests/smoke.bats` | Pass — 72/72 |
| `python3 tests/manager_service.py` | Pass — 7 tests |
| `python3 tests/control_center.py` | Pass — 21 tests |
| `bash tests/distro_multi_guest.sh` | Pass — multi-guest lifecycle and shortcut matrix |
| `python3 tests/ui_render.py` | Pass — 55 assertions across portrait, phone, compact, landscape, and resize layouts |
| QNN CLIP tokenizer/conditioning and SD1.5 batch tests | Pass — 7 + 2 tests |
| Release gates and generated-state workflow contract | Pass — 20 gates validated; 240-second exact-head wait contract |
| Termux signed APT bootstrap and Pages-preservation tests | Pass, including tampered checksum and unsafe path rejection fixtures |
| Bash syntax for tracked `.sh` files; Python compilation for tracked `.py` files | Pass — 67 shell files and 79 Python files |
| Production ShellCheck error threshold | Pass — one file per process, no error-level findings after the updater fix |
| Workload registry | Pass — 3 workload entries |
| YAML / JSON / SVG structure | Pass — 849 / 28 / 355 files |
| NPM dependency audit | Pass — 0 known advisories in the current lockfile snapshot |
| `tests/firefox_package_matrix.sh` | Not run — Docker is unavailable in local Termux/PRoot |
| `tests/bootstrap_source_sync.sh` | Pass — standalone installer and CLI pin commit `9069eb3d233f94f1cce9ba2f25bc0de88efda601`, archive SHA-256 `9535d8971f39c0722db969a82515755c9d9a22849e43a3b5c9be480a088b3e7c` |
| `tests/live_source_parity.py` | Reports 13 installed-source/path mismatches across 1,648 paths; installed device state is unchanged |

The `dist/` build output and test fixtures were generated locally and are not
tracked as source changes. Tests used isolated temporary prefixes/state where
designed to do so. Debian PRoot development dependencies installed for this
audit were Bats 1.11.1, NumPy 2.2.4, PyYAML 6.0.2, and Debian GCC 14.2.0;
ShellCheck had been installed in an earlier local verification pass. No managed guest distro
install/uninstall, Android setting, X11/audio service, or live Ternux install
was changed for this website redesign and audit.

## Recommended next work

1. Pin the 64 workflow action references to reviewed full SHAs and add a CI
   policy test that rejects unpinned third-party actions.
2. Replace mutable-branch uninstaller recovery with immutable, digest-verified
   recovery and cover tampering/traversal/no-network cases.
3. Migrate the startup verifier to a portable versioned KDF without resetting
   existing passwords; preserve the stated Android/PRoot threat boundary.
4. Rerun exact-commit CI after repository synchronization, including the
   Docker-backed Firefox distro matrix.
5. Schedule a later managed live reconciliation for the installed source drift
   and legacy Debian/Ubuntu app-center wrapper, then verify by read-only parity
   and native package-manager menus.
6. Review the new website in a real phone and desktop browser before dispatching
   the production Pages deployment; site deployment remains explicit/manual.

## Final-main follow-up — 2026-11-20

The inventory and checks above describe the audit baseline at `2046d10a`. The
following follow-up records later merged work and must be used for current
repository state; it does not rewrite the audit-time counts or claim a new
physical-device qualification.

- Final checked-out `main` is `255d1380efe03026894a52af4a2d314faab4df28`.
  Website/audit PR [#304](https://github.com/soobujmiah/ternux/pull/304), v3
  roadmap and bilingual-doc PR
  [#307](https://github.com/soobujmiah/ternux/pull/307), and generated-state
  PR [#308](https://github.com/soobujmiah/ternux/pull/308) are merged.
- The English and Bengali scope inventories now each enumerate 174 Markdown
  files plus all 11 Astro route/navigation entries. The 25 v3 technical and
  ADR pages have Bengali counterparts. Inventory parity does not prove every
  translation has received an independent semantic review.
- PR #307 added dependency-gated V3.0–V3.3 milestones and a planned,
  Ternux-owned Extension SDK design. These are v3 plans, not v2 capabilities.
  The APT feasibility recommendation remains to keep stable APT out of the
  v3.0 critical path while retaining the source installer.
- Exact-main Validate [run `44627829795`](https://github.com/soobujmiah/ternux/actions/runs/44627829795),
  unsigned package artifact [run `44627829822`](https://github.com/soobujmiah/ternux/actions/runs/44627829822),
  and repository-state contract [run `44627830225`](https://github.com/soobujmiah/ternux/actions/runs/44627830225)
  passed on the checked main SHA. The Validate suite includes lifecycle,
  manager/Control Center, distro/browser, QNN/APT, Bats, and documentation
  checks. It is CI evidence, not a substitute for device/browser qualification.
- A subsequent local `tests/docs_check.py` run passed 8,744 assertions, 720
  internal links, and 25 bilingual page pairs. A local Astro build produced
  124 page outputs and finalized 60 HTML routes.
- Production Pages still served `2046d10a9191f41b52ca52f5cae74f418ad7f140`
  at the latest HTTP check (last-modified 2026-11-19 18:40:39 GMT). The source
  redesign has not been published; `.github/workflows/deploy.yml` requires a
  manual `workflow_dispatch`. A real phone/desktop visual review also remains
  unperformed.
- The independent ChatGPT audit remains unavailable in the authorized
  attachment set. Its findings were not fabricated or inferred.
