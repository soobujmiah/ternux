# Repository and release-state audit

**Audit date:** 2026-11-13
**Canonical repository:** `https://github.com/soobujmiah/ternux`
**Audit base:** `main` at `d1ab4ef4ec4b74a48d570f46b27a33290049299b`

## Git and review

- The local source worktree is isolated from the original checkout and preserves
  `.tmp/`, `tests/.distro_recipes.keep.sh`, and `tests/distro-debug/`.
- PR #170 merged generated repository-state output. Its merge advanced main to
  `d1ab4ef4ec4b74a48d570f46b27a33290049299b`; the generated `.repo/` snapshot
  recorded the pre-merge commit and awaits the next workflow synchronization.
- PR #180's seven-package-family Firefox matrix is outside the v2 support
  contract. The v2 replacement matrix qualifies only Debian, Ubuntu, and Alpine.
- Dependabot PRs #42, #44, and #45 and owner-review licensing PR #35 are
  independent of v2 product acceptance; none is silently incorporated here.

## Release and package state

- Latest stable GitHub release at audit start: v1.4.0 (2026-09-18).
- No v2.0.0 tag or release exists.
- The Termux package artifact can be built in CI, but stable and RC public APT
  URL checks returned HTTP 404 at audit time. A CI artifact is not a published
  signed repository.
- `docs/TERMUX-APT.md` states that `pkg install ternux` is unavailable until the
  signed repository is published. Do not claim otherwise in install guides.
- Native Termux has the local Ternux 2.0.0 package installed; local package
  removal/install and managed guest cleanup have historical device evidence.
  This is not evidence of fetching the package from the public signed index.
- Release workflow `termux-apt-release.yml` exposes `verify-signing`,
  `publish-rc`, and `publish-v2`. The RC route must be published and exercised
  before stable publication. The stable `publish-v2` mode now runs the machine
  release-gate validator and exits before building a Pages artifact unless all
  blocking gates pass.

## Scope and release blockers

The only v2 clean-desktop guest profiles are Debian, Ubuntu, and Alpine.
`lib/core.sh` still has fifteen named recipes, but the other twelve are not
thereby v2-qualified. The machine release inventory currently has 20 gates.
The intended current blockers are:

1. **P1-09 browser:** the new exact three-profile clean install and real GTK
   launch CI matrix must pass on the final commit.
2. **P1-APT:** publish the signed RC tree, verify signatures/index/checksums at
   the public URL, and test native Termux package install/upgrade/uninstall.

P1-03's rollback-fixture gate is being narrowed to the actual safety contract:
verified pinning, atomic/staged update, interrupted update recovery, and data
integrity. A published v2 rollback demonstration is not a release requirement.
This does not waive package upgrade integrity or the signed APT lifecycle test.

## Documentation and generated state

The v2 readiness report and machine gates are the source of truth for release
status; this audit directory explains evidence provenance. `.repo/` is
generated from the workflow and must only change through its automated PR.
English/Bengali user-facing docs must continue to agree on supported distros,
installation routes, and experimental accelerator exclusions.
