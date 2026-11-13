# Repository and release-state audit

**Audit date:** 2026-11-13
**Canonical repository:** `https://github.com/soobujmiah/ternux`
**Audit base:** `main` at `faa5f0c4733e82fa0e82c88c6a2cd4531a1c3442`

## Git and review

- The local source worktree is isolated from the original checkout and preserves
  `.tmp/`, `tests/.distro_recipes.keep.sh`, and `tests/distro-debug/`.
- PR #185 merged the signed RC lifecycle evidence and multi-guest verify
  selector. Generated-state PR #186 refreshed `.repo/` through its deterministic
  workflow; neither generated PR was edited by hand.
- Main is now `faa5f0c4733e82fa0e82c88c6a2cd4531a1c3442`. Exact-main Validate
  `43362104082`, package artifact `43362104168`, and repository contract
  `43362104084` passed.
- PR #180's seven-package-family Firefox matrix is outside the v2 support
  contract. The v2 replacement matrix qualifies only Debian, Ubuntu, and Alpine.
- Dependabot PRs #42, #44, and #45 and owner-review licensing PR #35 are
  independent of v2 product acceptance; none is silently incorporated here.

## Release and package state

- Latest stable GitHub release at audit start: v1.4.0 (2026-09-18).
- No v2.0.0 tag or GitHub release exists yet; those are the remaining
  publication actions.
- Stable `/apt` was published by workflow `43362569559` on exact main
  `faa5f0c4733e82fa0e82c88c6a2cd4531a1c3442`. Bootstrap, archive key, signed
  `InRelease`, and compressed binary-all Packages index returned HTTP 200. The
  signature verifies against primary fingerprint
  `E5527F4D5B83037FF77B65AE5E894BBB81168B1D`. Stable `Packages.xz` SHA-256 is
  `3bbab20f0119b3c038e14c9a49714e499325b0c7036a899c3304e67b3b39e137`; indexed
  `ternux_2.0.0_all.deb` SHA-256 is
  `4ef03210c71e3d5671671e9a49fc83f6aebf7cdb5e5a28cb32db61d49e85c89f`.
- Signed `/apt-rc` remains published separately for candidate testing. Earlier
  RC signature, index, package hash, and package-manager evidence remains in
  `release-gates.json`; it does not substitute for stable publication.
- Repository-preservation fixtures passed in Pages run `43312672558` before the
  stable tree was published; this was not a post-publication stable redeploy.
  Run the normal website deployment after the current documentation merge, then
  recheck stable and RC signatures and package checksums.
- `docs/TERMUX-APT.md` now documents the published stable signed `/apt` route
  first and retains `/apt-rc` as an opt-in qualification channel.
- Native Termux fetched the stable indexed package, ran
  `pkg uninstall --yes ternux` followed by `pkg install --yes ternux`, and
  cleanly verified the package. `ternux verify --json`,
  `ternux verify db --json`, `tx verify ub --json`, and `tx verify alp --json`
  all passed; `dpkg --verify ternux` was clean. All
  three managed guest rootfs trees remained present and the live sessions kept
  the same READY state, displays, and managed PIDs. `apt-get --only-upgrade`
  confirms 2.0.0 is the newest candidate; since this is the first published
  package version, no earlier APT version exists for a version-delta test.
- Release workflow `termux-apt-release.yml` exposes `verify-signing`,
  `publish-rc`, and `publish-v2`. The RC route was published and exercised
  before stable publication. The stable `publish-v2` mode now runs the machine
  release-gate validator and exits before building a Pages artifact unless all
  blocking gates pass.

## Scope and release blockers

The only v2 clean-desktop guest profiles are Debian, Ubuntu, and Alpine.
`lib/core.sh` still has fifteen named recipes, but the other twelve are not
thereby v2-qualified. The machine release inventory currently has 20 gates.
All blocking v2 acceptance gates are complete. The machine inventory derives
`READY_FOR_OWNER_APPROVAL`, with owner authorization recorded. Stable `/apt` is
published; only the `v2.0.0` GitHub tag/release and the final release report
remain.

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
