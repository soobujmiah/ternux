# v2 feature and qualification matrix

**Audit date:** 2026-11-13. Scope: Ternux 2.0.0 on the documented Android
ARM64 reference device. A recipe existing in source does not mean it is a
supported v2 profile.

| Area | Debian | Ubuntu | Alpine | v2 statement |
|---|---|---|---|---|
| Clean guest and XFCE provisioning | Verified in prior fresh-device run | Verified in prior fresh-device run | Verified in prior fresh-device run | These are the only v2 desktop profiles |
| Independent desktop display | `:0` live READY | `:1` live READY | `:2` live READY | Device verified, separate from clean install |
| Mesa Turnip/Zink on SM8735 | Device qualified | Device qualified | Device qualified | Exact device only; no universal GPU promise |
| PulseAudio route | Live READY | Live READY | Live READY | Device route verified; broad hardware coverage deferred |
| Firefox package source | Native `firefox-esr` | Mozilla ESR tarball; no Snap dependency | Native `firefox-esr` | Clean Xvfb/Openbox launch and mapped-window matrix passed in exact-main Validate run `43359028809`; existing-device GUI launch also observed |
| IBus Control+Space | XFCE binding and switch helper live; XTest passed | XFCE binding and switch helper live; XTest passed | XFCE binding and switch helper live; XTest passed | Direct helper cycled and restored both engines on each live display; physical-keyboard path remains unverified |
| Ternux theme/titlebar | GTK, icon and XFWM themes active | GTK, icon and XFWM themes active | GTK, icon and XFWM themes active | Runtime theme values and `|HMC` controls queried on each live display; Firefox close controls were visible in prior live checks |
| Window viewport fitting | Oversized test window constrained live | Oversized test window constrained live | Oversized test window constrained live | 1800×1900 test clients fit within each 640×1386 display; future client-side decoration behavior is not guaranteed |
| Storage isolation | Existing fresh-package evidence | Existing package evidence | Existing package evidence | `/sdcard` is exposed when granted; Termux HOME stays isolated |

## Experimental or excluded from stable v2

| Capability | Status |
|---|---|
| HTP/HMX LLM acceleration | Experimental; known operator/numerical failures; excluded from stable support claims |
| QNN Stable Diffusion | Research-only; correctness and production qualification incomplete |
| Other Android SoCs/GPUs | Not qualified by the SM8735 device result |
| Other twelve named guest profiles | Existing recipes remain, but clean desktop/browser support is not part of v2 |
| Physical keyboard input across Android keyboards | Not verified by synthetic XTest |
| Every possible third-party app theme/window behavior | Not guaranteed; GTK/XFCE and tested Firefox path only |

## Release gates

The exact current acceptance status is maintained in [`../release-gates.json`](../release-gates.json)
and summarized in [the v2 report](../V2-RELEASE-READINESS.md). Signed RC APT
publication, hosted signature/index/hash verification, routine website
preservation, native package lifecycle, and owner approval are complete. Stable
`/apt` publication and the v2 tag/release remain. The latest exact-main CI run
`43359028809` passed the three-profile clean Firefox qualification.
