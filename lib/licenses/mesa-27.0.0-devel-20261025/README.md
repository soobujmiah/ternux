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

## Pinned binary inspection

The release archive was downloaded and rechecked against the SHA-256 above. The
member installed by Ternux is `usr/lib/aarch64-linux-gnu/libvulkan_freedreno.so`:

- SHA-256: `c9333136d9818fa91244d506ac17635988199e337485bd0fff4b0f1aeda6c895`
- ELF build ID: `d13adeba2d8da0f4711455afe9d0a2ede63f70d4`
- ELF SONAME: `libvulkan_freedreno.so`
- Architecture: AArch64; the binary identifies itself as Mesa 27.0.0-devel,
  commit `6f90e92dfdacc4759d8e9ccb328805d0f0b4439b`

Inspection of the installed member found these ELF `DT_NEEDED` entries:
`libz.so.1`, `libzstd.so.1`, `libdrm.so.2`, `libxcb-dri3.so.0`,
`libwayland-client.so.0`, `libxcb.so.1`, `libX11-xcb.so.1`,
`libxcb-present.so.0`, `libxcb-xfixes.so.0`, `libxcb-sync.so.1`,
`libxcb-randr.so.0`, `libxcb-shm.so.0`, `libxshmfence.so.1`,
`libexpat.so.1`, `libstdc++.so.6`, `libm.so.6`, `libgcc_s.so.1`,
`libc.so.6`, and `ld-linux-aarch64.so.1`. The binary has no ELF RPATH or
RUNPATH. These are runtime imports only; they do not enumerate statically linked
components or establish the license of any binary component.

The pinned source tag's
[`build-check.yml`](https://github.com/lfdevs/mesa-for-android-container/blob/6f90e92dfdacc4759d8e9ccb328805d0f0b4439b/.github/workflows/build-check.yml)
records the release build options: X11 and Wayland platforms, Gallium
`freedreno,zink,virgl,llvmpipe`, and Vulkan `freedreno`; it packages the result
with `meson install`. The archive also contains other Mesa binaries, but Ternux
extracts only `libvulkan_freedreno.so` and
`freedreno_icd.aarch64.json` for this phase.

This is a binary identity, build-configuration, and runtime-import record, not a
complete binary-to-source SBOM. The installed ELF has no debug sections or
per-object license manifest. An exact mapping of all statically linked Mesa
components and their file-level SPDX terms, plus a reviewed inventory of
third-party build/runtime components, remains a release gate. Do not infer that
all source-tree license texts apply to this binary.

Ternux installs this notice bundle beside the downloaded driver at
`/usr/local/share/doc/ternux/mesa-27.0.0-devel-20261025/`. It does not claim that
every license in the source tree applies to the extracted binary. The exact
binary-to-source component mapping and broader transitive license review remain
release gates; see the Ternux accelerator release plan.

Files copied from the pinned source tree are listed and SHA-256 checked in
`SHA256SUMS`.
