# Ternux repository and release state

**Audit snapshot:** 2026-11-13, 12:26 UTC
**Canonical repository:** `https://github.com/soobujmiah/ternux`
**Main at snapshot:** `13f966eb987fddcb720809d07dbbe89c78860fc9`
**Released v2 source:** `9106b04fc8627ae98b1d63c9912a28c8a4677441`

## GitHub state

- The `v2.0.0` release is published and remains the latest stable release.
- The current main source adds v3 read-only manager JSON commands and refreshed
  website/docs after the release tag; these changes do not alter the immutable
  v2.0.0 tag or stable package.
- PR #202 added bilingual installation routes and current v2/v3 state to both
  homepages. It merged as `1107f790e5b5368530b7218c41121d055cf39ccd` after
  required checks passed; Pages deployment
  [43421466805](https://github.com/soobujmiah/ternux/actions/runs/43421466805)
  succeeded.
- Generated-state PR #203 merged as `13f966eb987fddcb720809d07dbbe89c78860fc9`.
  Its diff contained only deterministic `.repo/` files. The generated state
  describes the source commit that triggered the sync; it was not hand-edited.
- At the snapshot, unrelated open PRs were Dependabot #42, #44, #45 and the
  owner-review license-terms PR #35. They are not v2 release blockers and were
  not included in the release or site update.

## Release and package integrity

- GitHub release [v2.0.0](https://github.com/soobujmiah/ternux/releases/tag/v2.0.0)
  was published 2026-11-13. Its tag points to
  `9106b04fc8627ae98b1d63c9912a28c8a4677441`.
- Assets: `ternux_2.0.0_all.deb` and `SHA256SUMS`. The `.deb` SHA-256 is
  `4ef03210c71e3d5671671e9a49fc83f6aebf7cdb5e5a28cb32db61d49e85c89f`.
- The stable APT publication and key/index/package checks are preserved in the
  [release-time report](../V2-RELEASE-REPORT.md). On the audited Termux host,
  `apt-cache policy ternux` showed installed and candidate version 2.0.0 from
  the signed `stable/main` source; `dpkg --verify ternux` produced no findings
  in the earlier lifecycle audit.
- `pkg install ternux` requires the documented one-time signed repository
  bootstrap. The package installs the Termux host CLI; `tx install` provisions
  one or more guest environments. A fresh Termux install cannot resolve the
  package before the trust bootstrap unless Ternux is accepted into an official
  Termux repository.
- Public website deployment
  [`43421466805`](https://github.com/soobujmiah/ternux/actions/runs/43421466805)
  succeeded for the updated site and preserved both published signed APT
  channels. The bootstrap endpoint returned HTTP 200 in the post-deploy check.

## Exact-main CI and generated-state evidence

For product source commit `1107f790e5b5368530b7218c41121d055cf39ccd`, the website
PR checks passed, including the full `Validate` workflow and hosted Astro
build. Exact-commit Validate run
[`43421436113`](https://github.com/soobujmiah/ternux/actions/runs/43421436113),
Termux package artifact run
[`43421436061`](https://github.com/soobujmiah/ternux/actions/runs/43421436061),
repository contract run
[`43421436003`](https://github.com/soobujmiah/ternux/actions/runs/43421436003),
and knowledge sync run
[`43421436238`](https://github.com/soobujmiah/ternux/actions/runs/43421436238)
passed. Generated PR #203 synchronized that commit's machine state. On
generated-state merge `13f966eb987fddcb720809d07dbbe89c78860fc9`,
exact-main Validate run
[`43412683916`](https://github.com/soobujmiah/ternux/actions/runs/43412683916),
Termux APT artifact run
[`43412683743`](https://github.com/soobujmiah/ternux/actions/runs/43412683743),
and repository-state contract run
[`43412683675`](https://github.com/soobujmiah/ternux/actions/runs/43412683675)
passed. The generated snapshot intentionally records the triggering product
commit `1107f790e5b5368530b7218c41121d055cf39ccd`; its state-only PR is the
subsequent main commit.

At this audit, local `python3 -m tools.repo_knowledge verify` returned
`VERIFY: 0 findings`. The machine-generated `.repo/STATUS.md` is governed by
the repository sync workflow and must never be edited by hand.

## v2 qualification and current device distinction

The only v2-supported desktop guests are Debian, Ubuntu, and Alpine on ARM64
Android. Their evidence depths differ: Debian has the broadest test record;
Ubuntu and Alpine are supported with narrower testing. Clean Firefox package
qualification covers exactly those three guests; it does not qualify the other
twelve recipes.

The live reference device has all three guest sessions running and each
read-only `tx verify` passed. These existing sessions are not evidence of a
fresh reinstall. The installed package is stable v2.0.0, while `main` contains
newer source-only manager JSON commands. This distinction is recorded in the
[device report](DEVICE-VERIFICATION.md).

## Release boundary

All blocking v2 acceptance gates were completed before v2.0.0 publication. The
owner explicitly removed a published v1.4.0-to-v2 rollback demonstration from
the v2 blocker list; the historical v1.4.0 artifact remains available. Future
release upgrades still require integrity, data-protection, and recovery
evidence. HTP/HMX, QNN image generation, twelve additional recipes, other
Android devices, and physical-keyboard behavior beyond the recorded probes are
not stable v2 claims.

See the [current v2 report](../release/V2-RELEASE-REPORT.md),
[release-time report](../V2-RELEASE-REPORT.md),
[machine gate inventory](../release-gates.json), and
[public release](https://github.com/soobujmiah/ternux/releases/tag/v2.0.0).
