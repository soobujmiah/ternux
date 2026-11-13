# Repository and release state

**Audit date:** 2026-11-13 (UTC)
**Canonical repository:** `https://github.com/soobujmiah/ternux`
**v2 release commit:** `9106b04fc8627ae98b1d63c9912a28c8a4677441`

## Git and review

- PR #189 merged the stable APT setup and current v2 release evidence. Its exact head passed Validate, package-artifact, repository-contract, and generated repository-state checks.
- Generated-state PR #190 was produced by the repository workflow, validated, and merged. Its diff contained only `.repo/` state; that directory was not edited by hand.
- Final main commit `9106b04fc8627ae98b1d63c9912a28c8a4677441` passed exact-main Validate run `43372097795`, package artifact `43372097797`, and repository contract `43372097798`.
- The v2 desktop qualification scope is Debian, Ubuntu, and Alpine. Other guest recipes, Dependabot PRs #42/#44/#45, and owner-review licensing PR #35 are independent and were not folded into the release.

## v2.0.0 publication

- GitHub release [v2.0.0](https://github.com/soobujmiah/ternux/releases/tag/v2.0.0) was published on 2026-11-13. Lightweight tag `v2.0.0` points to exact validated commit `9106b04fc8627ae98b1d63c9912a28c8a4677441`.
- Release assets are `ternux_2.0.0_all.deb` and `SHA256SUMS`. The package SHA-256 is `4ef03210c71e3d5671671e9a49fc83f6aebf7cdb5e5a28cb32db61d49e85c89f`, matching the stable APT index and release asset digest.
- Stable `/apt` publication run `43362569559` published package version 2.0.0 from exact source main `faa5f0c4733e82fa0e82c88c6a2cd4531a1c3442`. Public `InRelease` verifies against primary fingerprint `E5527F4D5B83037FF77B65AE5E894BBB81168B1D`. `Packages.xz` SHA-256 is `3bbab20f0119b3c038e14c9a49714e499325b0c7036a899c3304e67b3b39e137`.
- Website deploy `43371001392` on main `1ca00d3cd28ec78ae2339d2f974a7db1523f7c7b` ran after stable publication. Its preservation script fetched and verified both stable `/apt` and RC `/apt-rc` signatures with the pinned key, verified index/package hashes and records, and included both repository trees in the deployed artifact.
- Native Termux retrieved and reinstalled the stable package. `dpkg --verify` and default, Debian, Ubuntu, and Alpine `ternux verify` paths passed. The existing guest roots and running sessions were preserved.

## Scope and qualification limits

All blocking v2 release gates are complete; the release is published. The 20-item machine gate inventory records the pre-publication readiness and owner approval. The final release state is documented in [`../V2-RELEASE-REPORT.md`](../V2-RELEASE-REPORT.md).

Hardware evidence is specific to Xiaomi Redmi Turbo 4 Pro, Android 16, SM8735 / Adreno 825. The latest Alpine Ctrl+Space event probe disagreed with an earlier GTK/XTest pass; its helper works directly, but physical Android keyboard input is not certified. HTP/HMX and QNN image generation remain experimental or research-only. Other twelve named guest recipes and future third-party toolkit apps are not v2-qualified.

## Repository maintenance

`.repo/` is deterministic generated state and may only be updated by its workflow and validated generated-state PR. English and Bengali documentation must stay aligned on stable APT setup, v2 supported guest scope, and known qualification limits.
