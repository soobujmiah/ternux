---
title: "Ternux known limitations"
description: "Current product and verification limits, with the exact scope of each claim."
lang: "en"
---

## Known limitations

**Last reviewed:** 2026-11-18.

- v2 device qualification is for one named Android/Adreno device. It does not
  establish equivalent behavior on other SoCs, GPUs, Android versions, or
  keyboards.
- Physical Android Ctrl+Space delivery was not certified by the current
  automated/configuration audit; prior synthetic results disagree for Alpine.
- Ternux's GTK and XFWM theme does not guarantee a third-party app's
  client-side decorations, Qt theme, custom drawing, or icon-name coverage.
- The local v2.0.1 candidate keeps a moved window in place when its size changes
  and clamps it only when it would leave the work area. This was verified with
  one live Debian/XFCE session and a geometry regression test; other window
  managers, devices, and published packages are not covered. The helper cannot
  correct a window that draws its own oversized content.
- PRoot provides a userland compatibility environment, not kernel container
  isolation or root privileges.
- Termux:API still-photo capability does not by itself provide continuous
  camera streaming or a `/dev/video*` webcam device. These are separate,
  unqualified capabilities.
- HTP/HMX and QNN artifacts remain experimental unless a later release
  explicitly changes that status with hardware and correctness evidence.
- The manager API currently exposes read-only CLI operations and an explicit
  foreground Unix-socket service. `tx control` adds a loopback browser dashboard
  and typed, confirmation-bound start/stop actions for installed desktop profiles,
  with durable local job records; it requires optional Python 3 and remains
  source-only, absent from the withdrawn v2.0.0 package. Device-browser action
  validation, cancellation, service supervision, Device Bridge, and platform
  workload orchestration remain incomplete.
- The installed v2.0.0 doctor can select a stale saved distro instead of the
  active guest, and Ubuntu's default renderer diagnostic can miss its isolated
  Mesa overlay when an optional path marker is absent. The fix is in current
  main, but the installed stable v2.0.0 package has not been updated.

See [device verification](DEVICE-VERIFICATION.md) and the
[current v2 report](../release/V2-RELEASE-REPORT.md) and
[release-time report](../V2-RELEASE-REPORT.md) for dated evidence.
