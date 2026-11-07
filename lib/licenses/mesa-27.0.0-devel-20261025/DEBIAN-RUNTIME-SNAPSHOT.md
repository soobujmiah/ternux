# Mesa Turnip runtime dependency snapshot

This inventory was captured on 2026-11-07 from the isolated Debian 13 Trixie
ARM64 guest used for the pinned Turnip install. It describes that guest's
installed package versions; it is not a package lock for every Ternux device.

For the exact pinned `libvulkan_freedreno.so` member, `readelf -d` supplied the
ELF `DT_NEEDED` SONAMEs. In the guest, each SONAME was resolved through
`ldconfig -p`; its real path was matched with `dpkg-query -S`. Package versions
were checked with `dpkg-query -W`. Copyright-file hashes below were computed
from the installed Debian package documentation. The Ternux GPU phase installs
the Turnip ICD and JSON only; these runtime libraries come from Debian's APT
packages and are not copied into the Ternux artifact.

## SONAME to Debian package ownership

| ELF SONAME | Debian binary package (`arm64`) |
|---|---|
| `libz.so.1` | `zlib1g` |
| `libzstd.so.1` | `libzstd1` |
| `libdrm.so.2` | `libdrm2` |
| `libxcb-dri3.so.0` | `libxcb-dri3-0` |
| `libwayland-client.so.0` | `libwayland-client0` |
| `libxcb.so.1` | `libxcb1` |
| `libX11-xcb.so.1` | `libx11-xcb1` |
| `libxcb-present.so.0` | `libxcb-present0` |
| `libxcb-xfixes.so.0` | `libxcb-xfixes0` |
| `libxcb-sync.so.1` | `libxcb-sync1` |
| `libxcb-randr.so.0` | `libxcb-randr0` |
| `libxcb-shm.so.0` | `libxcb-shm0` |
| `libxshmfence.so.1` | `libxshmfence1` |
| `libexpat.so.1` | `libexpat1` |
| `libstdc++.so.6` | `libstdc++6` |
| `libgcc_s.so.1` | `libgcc-s1` |
| `libm.so.6`, `libc.so.6`, `ld-linux-aarch64.so.1` | `libc6` |

## Installed package and notice snapshot

The digest is SHA-256 of `/usr/share/doc/<package>/copyright` in that guest.
For `libstdc++6` and `libgcc-s1`, Debian points both documentation paths to
`gcc-14-base/copyright`.

| Debian package (`arm64`) | Installed version | Copyright SHA-256 |
|---|---|---|
| `zlib1g` | `1:1.3.dfsg+really1.3.1-1+b1` | `9e5b96d63773a5d177ba264254390f792be07e41748ebd94730981c6cac31cc6` |
| `libzstd1` | `1.5.7+dfsg-1` | `5cec9fef4d3fa7e0371fbef4ec3fc416e0105dc2a9922117f84e825cb11f50f8` |
| `libdrm2` | `2.4.124-2` | `512c9a57fd8b449aa157351da9df07bf8e19f767e496a72205a4020268ddb2e0` |
| `libxcb-dri3-0` | `1.17.0-2+b1` | `4f7cb9db6bf6542f5417e3d674c780d3a5fd12291a54d63054fb576ee0cfae80` |
| `libwayland-client0` | `1.23.1-3` | `99ade79b69c41bfb14b8a0567e9c0acdd858d6d8ad7d3ca4f9da1cfd000954b1` |
| `libxcb1` | `1.17.0-2+b1` | `4f7cb9db6bf6542f5417e3d674c780d3a5fd12291a54d63054fb576ee0cfae80` |
| `libx11-xcb1` | `2:1.8.12-1` | `0b380a7fd5b2228f26e9585e56f14812efd3350f3df307507d2bc055dfd8de3e` |
| `libxcb-present0` | `1.17.0-2+b1` | `4f7cb9db6bf6542f5417e3d674c780d3a5fd12291a54d63054fb576ee0cfae80` |
| `libxcb-xfixes0` | `1.17.0-2+b1` | `4f7cb9db6bf6542f5417e3d674c780d3a5fd12291a54d63054fb576ee0cfae80` |
| `libxcb-sync1` | `1.17.0-2+b1` | `4f7cb9db6bf6542f5417e3d674c780d3a5fd12291a54d63054fb576ee0cfae80` |
| `libxcb-randr0` | `1.17.0-2+b1` | `4f7cb9db6bf6542f5417e3d674c780d3a5fd12291a54d63054fb576ee0cfae80` |
| `libxcb-shm0` | `1.17.0-2+b1` | `4f7cb9db6bf6542f5417e3d674c780d3a5fd12291a54d63054fb576ee0cfae80` |
| `libxshmfence1` | `1.3.3-1` | `6a76b32c9174c0cb9e3d94c323a14d33d6a42bd2a61579b189cbc5addeb94abe` |
| `libexpat1` | `2.9.0-1~deb13u1` | `60919fe1a156395ff14511bb6ff79756c50ade2fff59ac60c9bae1d8a7fe6292` |
| `libstdc++6` | `14.2.0-19` | `20390f8a6f3b1e4d7cb45dd8652dabb259bbef688cbad839bcdb0b9ba7252f79` |
| `libgcc-s1` | `14.2.0-19` | `20390f8a6f3b1e4d7cb45dd8652dabb259bbef688cbad839bcdb0b9ba7252f79` |
| `libc6` | `2.41-12+deb13u4` | `f5788886720a2605a946e81d571e6c8162b09f58d2e2ceb8d36e5768fccd850d` |

This maps the binary's direct dynamic imports to the Debian packages and their
local copyright records. It does not map statically linked Mesa objects or
transitive build inputs. The Debian copyright files contain per-file terms and
must be consulted rather than reducing a multi-license package to one SPDX
label. Exact binary-to-source mapping and the wider dependency-license review
remain open release gates.
