# Repository and release-state audit

**Audit date:** 2026-11-13
**Canonical repository:** `https://github.com/soobujmiah/ternux`
**Audit base:** `main` at `ca0bba9093ecbe838df4b09f09dfee3197814845`

## Git and review

- The local source worktree is isolated from the original checkout and preserves
  `.tmp/`, `tests/.distro_recipes.keep.sh`, and `tests/distro-debug/`.
- PR #181 merged the product/docs changes; generated-state PR #182 then advanced main to
  `f963832fb4acf9c3adb873430408ce21ddd29a37` and refreshed `.repo/` through its
  generated workflow. No `.repo/` files were hand-edited.
- PR #183 records the exact-main browser gate; generated-state PR #184 advanced
  main to `ca0bba9093ecbe838df4b09f09dfee3197814845`. Exact main Validate
  `43311661213`, package artifact `43311661198`, and repository contract
  `43311660996` passed.
- PR #180's seven-package-family Firefox matrix is outside the v2 support
  contract. The v2 replacement matrix qualifies only Debian, Ubuntu, and Alpine.
- Dependabot PRs #42, #44, and #45 and owner-review licensing PR #35 are
  independent of v2 product acceptance; none is silently incorporated here.

## Release and package state

- Latest stable GitHub release at audit start: v1.4.0 (2026-09-18).
- No v2.0.0 tag or GitHub release exists yet; those are the remaining
  publication actions.
- Signed `/apt-rc` was deployed by workflow `43311699170`. The public bootstrap,
  archive key, signed `InRelease`, and compressed binary-all Packages index all
  return HTTP 200. The primary-key fingerprint and signature verify, and the
  index's ternux 2.0.0 package SHA-256 is
  `df34f869b68beef3c817f71b80ece3a31e00df0f7e8fbed2918443f7b1905cbd`.
- Routine Pages redeploy `43312672558` passed signed-repository preservation
  for stable and RC channels; post-deploy RC paths and signature remained valid.
- `docs/TERMUX-APT.md` now documents the available signed RC route and clearly
  distinguishes it from the not-yet-published stable `/apt` route.
- Native Termux fetched the indexed package from `/apt-rc`, reinstalled it,
  removed it with `pkg uninstall`, then performed a clean `pkg install`. All
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
