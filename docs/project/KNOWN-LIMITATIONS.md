---
title: "Ternux known limitations"
description: "Current support, packaging, and device-verification limitations."
lang: "en"
alt_url: "/bn/docs/project/KNOWN-LIMITATIONS.html"
---

## Known limitations

- The Termux APT/package channel is unavailable. `pkg install ternux` is not a
  supported or working installation method; use the pinned source installer.
- Setup recipes for Debian, Ubuntu, Kali Linux, and Alpine do not imply equal
  physical-device verification. Consult the [device evidence](../audit/DEVICE-VERIFICATION.md).
- Device behavior is not universal across Android versions, SoCs, GPUs, or
  vendor builds. Report only the device and tests actually verified.
- The Manager and Control Center work is partial. Browser/device validation,
  supervision, and other unfinished capabilities must not be described as a
  complete platform.
- Historical release records describe their dated artifacts and scope; they do
  not establish present package availability. See the [release archive](../release/README.md).

See [implementation status](IMPLEMENTATION-STATUS.md) and
[package-channel status](../TERMUX-APT.md) for current details.
