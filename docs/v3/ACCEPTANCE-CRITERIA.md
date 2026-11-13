---
title: "Ternux v3 acceptance criteria"
description: "Verifiable release gates for manager, guests, compute, AI, Device Bridge, and Control Center."
lang: "en"
---

## Acceptance criteria

**Status: DESIGNED.** All criteria are release gates for the named capability.
Evidence is attached to an exact commit and environment. `PASS` requires the
stated behavior; screenshots or logs without reproducible setup are
supporting, not sufficient, evidence.

## Native manager and Control Center

- Install/update/remove on a clean supported Termux environment; verify file
  ownership, checksums/signatures, idempotence, interrupted update recovery,
  and preservation of unrelated Termux packages.
- With all guests absent, `tx status`, help, repair plan, and Control Center
  diagnostics operate without PRoot. Stop the service and confirm the CLI can
  still manage it.
- Confirm the API binds only to its Unix socket/loopback adapter; reject
  off-origin mutations, invalid tokens, malformed JSON, duplicate jobs, and
  paths outside owned roots.
- Idle CPU/RAM, startup duration, and log growth are measured on a named
  low-resource device. No idle camera, microphone, model load, or sensor poll.

## Guest workspace

- Clean install, upgrade, shell aliases, root aliases, concurrent displays,
  selected stop, multi-select stop, restart recovery, and uninstall for every
  advertised distro.
- Verify GUI input, actual physical Ctrl+Space where claimed, GTK/icon/XFWM
  themes, titlebar controls, viewport fitting, audio, graphics backend,
  browser, storage permissions, and application menu on the named guest and
  device. Record third-party CSD/toolkit exceptions.
- Confirm `/sdcard` exposure is explicitly granted, read/write scope matches
  the grant, and revocation does not delete Android files.
- Guest removal reports and removes only the selected guest and its
  Ternux-owned state; model stores and unrelated guests survive.

## Compute and AI

- Separate detection, initialization, execution, correctness, and performance
  results. Preserve runtime/driver versions, input digest, model digest, device,
  thermal context, memory peak, result, and failure logs.
- CPU and accelerator routes use identical supported workload inputs and
  correctness references. Tests include a nontrivial language task and image
  decode/health checks, not only toy arithmetic.
- Model/artifact install verifies source, digest, architecture, license, free
  space, and rollback. Discovery is read-only; uninstall preserves models
  unless the user explicitly selects them.
- NPU claims require actual NPU runtime execution and output correctness on the
  named SoC. CPU/GPU emulation or app-reported model labels do not qualify.

## Device Bridge

- Test granted, denied, cancelled, missing-companion, timeout, low-storage,
  malformed-response, and guest-copy failure paths for each API.
- Microphone/camera are active only during a visible user request; cancellation
  stops capture; successful output decodes and lands at the selected path.
- Still capture, live preview, webcam streaming, and recording are verified
  separately and named accurately.

## Documentation and release

- README, CLI help, website, install command, package metadata, supported
  matrix, and release notes agree with exact source behavior.
- CI is green for focused tests, distro recipes, packaging/manifest integrity,
  security fixtures, and site build on the exact release commit.
- A release candidate is installed through the advertised clean path on a
  reference device. Record checksums, workflow IDs, screenshots/logs, and
  recovery result. Known limitations remain visible and dated.
