# Mesa / Freedreno Turnip third-party license bundle

This bundle is copied from the exact source tree used for the pinned upstream
Mesa container release:

- Project: <https://github.com/lfdevs/mesa-for-android-container>
- Source tag: `mesa-27.0.0-devel-20261025`
- Source commit: `6f90e92dfdacc4759d8e9ccb328805d0f0b4439b`
- Binary archive: `mesa-for-android-container_27.0.0-devel-20261025_debian_trixie_arm64.tar.gz`
- Binary SHA-256: `b711d1d9ab5537ee9085da8896dfe2115e791b33aa317fe37538f276c967d687`
- Release: <https://github.com/lfdevs/mesa-for-android-container/releases/tag/mesa-27.0.0-devel-20261025>

`docs/license.rst` is Mesa's license and copyright overview. The `licenses/`
directory contains every license text present in that exact source tree, including
the Linux syscall note exception. The source tree identifies file-specific
copyrights and license terms with SPDX identifiers; consult the pinned source
when identifying the terms for an individual object in the compiled driver.

Ternux installs this notice bundle beside the downloaded driver at
`/usr/local/share/doc/ternux/mesa-27.0.0-devel-20261025/`. It does not claim that
every license in the source tree applies to the extracted binary. The exact
binary-to-source component mapping and broader transitive license review remain
release gates; see the Ternux accelerator release plan.

Files copied from the pinned source tree are listed and SHA-256 checked in
`SHA256SUMS`.
