# Ternux V3 test and evidence matrix

**Baseline source:** `f04b7261ef9ba2dba2c38fd987f760e80583f2d2` (`main`, equal to `origin/main` at capture).\
**Audit state:** initial independently repeated checks; this matrix is updated as audit and implementation proceed.\
**Evidence rule:** CI, source inspection, installed-state observation, and physical-device interaction are separate evidence classes.

## Exact-head CI

GitHub Actions reported all three exact-head runs completed successfully on the baseline SHA:

| Workflow | Run | Result | Boundary |
|---|---:|---|---|
| Validate | `44671809723` | PASS | Full Ubuntu CI job, including build, shell checks, Bats, manager/Control Center, Firefox guest matrix, experiments, documentation, and formatting. The clean Firefox package matrix covers Debian, Ubuntu, and Alpine; Kali is not included. |
| Termux APT package artifact | `44671809736` | PASS | Artifact build/contract evidence; no stable package publication is implied. |
| Repository State Contract | `44671809722` | PASS | Workflow contract only. It does not refresh the checked-in generated status file. |

The checked-in `.repo/STATUS.md` still names `3bfb0fbdd9fedb8ccc2aa9d37ff125ec55be27d1`, not the audited baseline SHA. It is generated and must be refreshed through its intended workflow, never hand-edited.

## Repeated locally

| Check | Result | Evidence / limit |
|---|---|---|
| `bash tests/focused.sh` | PASS — 228/228 on the final rerun | Includes the stop-failure guard for `uninstall all`, correctly rehashed extension archive traversal/symlink and whitespace-target rejection, and Stable Diffusion experimental maturity label check; fixture-based, no live guest removal or installation. An earlier aggregate attempt had one transient updater rollback assertion failure; the updater suite then passed standalone and again inside the final aggregate run. |
| `bash tests/update_transaction.sh` | PASS | Standalone retest after one non-reproducible rollback assertion failure in an earlier aggregate run. Update staging, commit/rollback, crash recovery, live-owner rejection, backup-root symlink rejection, concurrency, and v1.4.0 migration fixtures. Current source review found no dedicated cases for malformed journal fields, missing backup components, or interruption during recovery restore; disk-full and real Termux power-loss remain untested. |
| `bash tests/distro_multi_guest.sh` | PASS | Multi-guest install/resume/lifecycle fixtures; not clean physical guest installs. |
| `bash tests/pinned_optional_installers.sh` | PASS | Fixed source, digest mismatch, and unapproved-source fixtures. |
| `bash tests/remote_install_bootstrap.sh` | PASS | Mocked downloader fallback and execution path; test now reads the exact v2.0.1 commit-pinned bootstrap URL from README. |
| `python3 -B tests/workflow_action_pin_policy.py` | PASS — 64/64 references | All third-party workflow actions use full 40-character SHAs and readable version labels; wired into Validate CI, but that changed workflow has not run remotely yet. |
| `python3 tests/npm_lock_integrity.py` | PASS — 307 package records | Requires HTTPS npm registry tarball URLs and SHA-512 SRI; wired into Validate CI, but the changed workflow has not run remotely yet. |
| Isolated `npm ci` against the enriched candidate lock | PASS — 209 added / 210 audited; 0 vulnerabilities | Official npm registry metadata matched all 105 exact package name/version records; dependency versions and graph unchanged. This was a candidate lock copy in Debian PRoot, not an exact-head CI run. |
| `bash tests/bootstrap_source_sync.sh` | PASS | Standalone installer and CLI match the pinned verified source snapshot. |
| `python3 tests/manager_service.py` | PASS — 7 tests | Read-only socket, peer UID, malformed requests, stale socket, concurrency, shutdown. |
| `python3 tests/control_center.py` | PASS — 21 tests | Loopback dashboard, typed actions, confirmation, durable jobs, recovery and security headers. |
| `python3 tests/ui_render.py` | PASS — 55 assertions | Portrait, phone, compact, landscape, and resize terminal layouts. Not a visual browser/UI review. |
| `python3 -B tests/docs_check.py` | PASS — 8,783 assertions, 802 internal links, 25 bilingual page pairs | Includes all audit files and documentation corrections created during this session. Structural parity is not a full semantic translation review. |
| `bats tests/smoke.bats` | PASS — 72/72 | Run in the installed Debian guest using an isolated PRoot with only the repository bound. |
| Production ShellCheck error-level set | PASS | Same production file set as CI, through Debian PRoot ShellCheck. |
| Strict YAML parse with duplicate-key rejection | PASS — 871/871 | Includes all 869 tracked `.yaml`/`.yml` documents plus two ignored dependency workflows under `node_modules/`. |
| Isolated `npm ci` using verified official Node v22.23.5 Linux ARM64 archive (SHA-256 `2babb9eb5264860d540849f4b064a6fbdebcdc323657d9d382ce23d313fd5e09`) in Debian PRoot | PASS — 209 added / 210 audited; 0 vulnerabilities | Ran against a temporary copy of the current worktree, excluding `.git`, existing `node_modules`, and generated output. Lockfile accepted; no lockfile write was made in the source tree. npm reports no vulnerabilities, which does not replace dependency provenance or license review. Temporary files were automatically removed. |
| `npm run build` (Astro + `scripts/finalize-site.mjs`) in the same isolated copy | PASS — 124 pages built; 60 HTML routes finalized | Node v22.23.5 / npm 10.9.9; no repository output directory was modified. |
| `npm run format:check` in the same isolated copy | PASS | Prettier reported all matched files use code style. |
| Python syntax compile (`compile()`) | PASS — 79/79 | All tracked `.py` sources; no bytecode cache written by this check. |
| JSON parse | PASS — 28/28 | All tracked `.json` files. |
| XML/SVG parse | PASS — 356/356 | All tracked `.xml`/`.svg` files. |
| `python3 tests/release_gates.py --self-test` | PASS | 20 release gates validated; readiness `READY_FOR_OWNER_APPROVAL` is the fixture's gate output, not a V3 release claim. |
| `python3 tests/repo_state_sync_workflow_test.py` | PASS | Bounded 240-second exact-head wait contract. |
| QNN CLIP tokenizer/conditioning tests | PASS — 7/7 | Debian PRoot; the same tests also passed natively. |
| QNN SD1.5 batch-runner tests | PASS — 2/2 | Debian PRoot. Native Termux NumPy could not load due the Android linker defect below. |
| `bash tests/termux_apt_bootstrap.sh` | PASS | Signed-key/fingerprint and package-flow fixtures. |
| `bash tests/termux_apt_pages_preservation.sh` | PASS | Signature, package hash/size, unsafe path, and preservation fixtures. |
| `python3 tests/live_source_parity.py` against current `main` | FAIL — 17 mismatches / 1,648 paths | Read-only; 11 native module/resource differences, 2 unmapped Debian/Ubuntu legacy app-center files, and 4 guest package-manager launcher differences. |
| Same parity test against release tag `v2.0.1` | FAIL — 12 mismatches / 1,648 paths | Read-only extracted tag in a temporary local tree; 10 native module/resource differences and the 2 unmapped Debian/Ubuntu legacy app-center files. Temporary extraction was removed automatically. |
| Live production English/Bengali homepage text | MISMATCH | Both routes return HTTP 200 and `Last-Modified: Fri, 20 Nov 2026 03:40:54 GMT`; latest Pages run `44669285260` used `cc7683e…`. English says v2.0.1/four verified guests; Bengali still says three/next v2 release. Current source copies are aligned. |
| Local Open Graph card asset | MANUALLY VIEWED; license label conflict | `assets/img/og-card.png` is 1200×630 and visibly says “MIT LICENSE”; root `LICENSE` is Apache-2.0. Asset-specific license intent remains unresolved. |
| Live stable APT bootstrap/index routes | WITHDRAWN as expected | `apt/dists/stable/InRelease` and `apt/bootstrap.sh` both return HTTP 404. No stable APT publication is claimed. |

## Not locally verified in this runtime

| Check | State | Reason / available evidence |
|---|---|---|
| `node --check` | NOT RUN | The isolated site build exercised the project build scripts but did not run a separate syntax-only check for every Node script. |
| Clean Firefox package matrix | NOT RUN locally | No Docker executable or socket. Exact-head Validate CI passed its Linux job for Debian, Ubuntu, and Alpine; Kali is absent from that matrix. |
| ADB device enumeration | NOT RUN | Termux `adb` fails at dynamic linking on the same missing symbol; device properties were read locally with Android properties instead. |
| Visual website/page inspection in a browser | NOT YET TESTED | Public text and response headers were inspected, not rendered appearance at phone/desktop widths. |
| Clean Ternux install/uninstall on a fresh Android/PRoot environment | NOT YET TESTED | Fixture tests and current-host read-only parity do not equal a clean real install/removal qualification. |
| New V3 GUI/hardware qualification | NOT YET TESTED | No V3 release implementation or human-operated interaction evidence exists in this baseline. |

No physical-device UI input was automated. No live Ternux install, uninstall, guest deletion, Android setting, or service lifecycle was changed during baseline capture.
