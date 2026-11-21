---
title: "Ternux release and package status"
description: "Current release records and the unavailable package channel."
lang: "en"
alt_url: "/bn/docs/project/RELEASE-STATUS.html"
---

## Current status

- **Latest GitHub Release:** v1.4.0. Keep its release artifacts and
  documentation unchanged.
- **Later source provenance:** a later source tag remains in Git history for
  provenance. Its GitHub Release entry was removed; do not present it as an
  available GitHub Release.
- **APT/package channel:** unavailable. `pkg install ternux` is not a working
  installation route. See [package-channel status](../TERMUX-APT.md).
- **Maintained desktop setups:** Debian, Ubuntu, Kali Linux, and Alpine. The
  setup recipes and device-verification evidence are distinct; consult the
  [feature matrix](../audit/FEATURE-MATRIX.md) and
  [device verification record](../audit/DEVICE-VERIFICATION.md).
- **Current install guidance:** use the pinned source installation route in the
  [installation guide](../INSTALLATION.md).

The historical release reports retain dated evidence and provenance. They are
not current installation or package availability instructions: [release
archive](../release/README.md).
