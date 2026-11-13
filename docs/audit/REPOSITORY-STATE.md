# Repository and release-state audit

**Audit date:** 2026-11-13
**Canonical repository:** `https://github.com/soobujmiah/ternux`
**Audit base:** `main` at `db9fe4a70177641b1e1312d2db47462191daf582`

## Git and review

- The local source worktree is isolated from the original checkout and preserves
  `.tmp/`, `tests/.distro_recipes.keep.sh`, and `tests/distro-debug/`.
- PR #185 merged the signed RC lifecycle evidence and multi-guest verify
  selector. Generated-state PR #186 refreshed `.repo/` through its deterministic
  workflow; neither generated PR was edited by hand.
- Main is now `db9fe4a70177641b1e1312d2db47462191daf582`. Exact-main Validate
  `43359028809`, package artifact `43359028911`, and repository contract
  `43359028896` passed.
- PR #180's seven-package-family Firefox matrix is outside the v2 support
  contract. The v2 replacement matrix qualifies only Debian, Ubuntu, and Alpine.
- Dependabot PRs #42, #44, and #45 and owner-review licensing PR #35 are
  independent of v2 product acceptance; none is silently incorporated here.

## Release and package state

- Latest stable GitHub release at audit start: v1.4.0 (2026-09-18).
- No v2.0.0 tag or GitHub release exists yet; those are the remaining
  publication actions.
- Updated `/apt-rc` was published by workflow `43359599505` from exact main
  `db9fe4a70177641b1e1312d2db47462191daf582`. Bootstrap, archive key, signed
  `InRelease`, and compressed binary-all Packages index returned HTTP 200. The
  pinned primary fingerprint and signature verify; the new indexed package SHA-256
  is `f2862526cd5cfdd91bac163632e2c9e8600288926c4acb2b2c5dcffbca271be2`.
- Earlier routine Pages redeploy `43312672558` passed signed-repository
  preservation for stable and RC channels. The latest updated RC publication
  and native install below prove the package contents match the selector fix.
- `docs/TERMUX-APT.md` now documents the available signed RC route and clearly
  distinguishes it from the not-yet-published stable `/apt` route.
- Native Termux previously fetched the indexed package from `/apt-rc`, removed
  it with `pkg uninstall`, then performed a clean `pkg install`. After the
  multi-distro selector fix landed, native `pkg update` fetched the updated RC
  index and APT reinstalled the exact new 2.0.0 package. `ternux verify --json`,
  `ternux verify db --json`, `tx verify ub --json`, and `tx verify alp --json`
  all passed; `dpkg --verify ternux` was clean. All
  three managed guest rootfs trees remained present and the live sessions kept
  the same READY state, displays, and managed PIDs. `apt-get --only-upgrade`
  confirms 2.0.0 is the newest candidate; since this is the first published
  package version, no earlier APT version exists for a version-delta test.
- Release workflow `termux-apt-release.yml` exposes `verify-signing`,
  `publish-rc`, and `publish-v2`. The RC route must be published and exercised
  before stable publication. The stable `publish-v2` mode now runs the machine
  release-gate validator and exits before building a Pages artifact unless all
  blocking gates pass.

## Scope and release blockers

The only v2 clean-desktop guest profiles are Debian, Ubuntu, and Alpine.
`lib/core.sh` still has fifteen named recipes, but the other twelve are not
thereby v2-qualified. The machine release inventory currently has 20 gates.
All blocking v2 acceptance gates are now complete. The machine inventory
derives `READY_FOR_OWNER_APPROVAL`, with owner authorization recorded. Stable
`/apt` publication, tag `v2.0.0`, and the GitHub release are the remaining
publication actions.

P1-03's rollback-fixture gate was narrowed to the actual safety contract:
verified pinning, atomic/staged update, interrupted update recovery, and data
integrity. A published v2 rollback demonstration is not a release requirement.
The signed APT lifecycle gate is now complete and recorded above.

## Documentation and generated state

The v2 readiness report and machine gates are the source of truth for release
status; this audit directory explains evidence provenance. `.repo/` is
generated from the workflow and must only change through its automated PR.
English/Bengali user-facing docs must continue to agree on supported distros,
installation routes, and experimental accelerator exclusions.
