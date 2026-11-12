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
| Firefox package source | Native `firefox-esr` | Mozilla ESR tarball; no Snap dependency | Native `firefox-esr` | Clean CI launch matrix added; awaiting pass |
| IBus Control+Space | Synthetic XTest passed | Synthetic XTest passed | Synthetic XTest passed | Physical keyboard path remains unverified |
| Ternux theme/titlebar | Live observed | Live observed | Live observed | Firefox close button visible in live test |
| Window viewport fitting | Helper installed and source regression added | Existing About window corrected live | Helper installed and source regression added | Test common app windows; future toolkit behavior is not guaranteed |
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

The exact current blockers are maintained in [`../release-gates.json`](../release-gates.json)
and summarized in [the v2 report](../V2-RELEASE-READINESS.md). Stable publication
requires exact-head CI, the three-profile browser matrix, a signed RC APT
publication with hosted native package lifecycle evidence, and a machine gate
result of `READY_FOR_OWNER_APPROVAL`.
