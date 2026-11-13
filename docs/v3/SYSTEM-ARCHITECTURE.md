---
title: "Ternux v3 system architecture"
description: "Trust boundaries, data flow, lifecycle, and failure handling across Ternux v3."
lang: "en"
---

## System architecture

**Status: DESIGNED.** Ternux is a native Termux manager that coordinates
independent PRoot workspaces. Guests provide Linux userland applications; they
do not own the manager, Android permission flow, or host-wide lifecycle.

## Runtime layers

```text
Android OS and Termux companion apps
  ├─ Termux:API broker (camera, microphone, notifications, battery, etc.)
  └─ Termux:X11 app / Android input and display; native workspace owns `:0`
       │ explicit IPC, app grants, X11 socket
Termux host ($PREFIX)
  ├─ tx CLI and native manager core
  ├─ Native Control Center service and local UI
  ├─ Device Bridge adapters and permission broker
  ├─ workload/artifact registry and resource policy
  └─ per-guest state, logs, caches, and lifecycle supervisors
       │ explicit bind mounts, PRoot process boundary
Linux guest (Debian / Ubuntu / Alpine / qualified profiles)
  ├─ user session, XFCE, applications, guest packages
  ├─ optional workload client (CPU/GPU/NPU runtime)
  └─ guest-local config and files
       │ optional, explicit LAI API integration
LAI runtime and model store (separate project/service)
```

For v3, native Termux owns display `:0`; guest displays begin at Debian `:1`,
Ubuntu `:2`, Alpine `:3`, then continue through collision-checked serial
allocations. This is a v3 target. Existing v2 display assignments remain
unchanged until a staged migration succeeds; see
[ADR-0005](ADR/0005-native-display-allocation.md).

PRoot is a compatibility boundary, not a security boundary equivalent to a
kernel container. The manager must not describe it as one. Android's app
sandbox remains the primary host security boundary.

## Trust and data flow

1. A user invokes `tx`; the native manager validates arguments and reads its
   versioned state under Termux `$PREFIX`.
2. A guest action resolves one registered guest by immutable ID and validated
   name. The supervisor launches only that guest's process tree and display.
3. A workload request is checked against its manifest, device capability,
   installed runtime, disk/RAM budget, and user choice before installation or
   execution.
4. An Android device action goes through a Termux API client. Permission is
   requested at the point of use; an idle guest cannot poll a camera or
   microphone.
5. Logs and results are written to the owning component's state directory,
   with identifiers that let the UI correlate request, process, guest, and
   outcome without exposing unrelated process data.

## Lifecycle state machine

Guest install and update operations use `ABSENT → PREPARING → READY`; failure
uses `PREPARING → FAILED`, with a retained diagnostic and safe retry. Desktop
operations use `STOPPED → STARTING → RUNNING → STOPPING → STOPPED`. A process
exit, display failure, or timeout transitions to `DEGRADED` with its exit code
and log location. Repeated `start` is idempotent; `stop` addresses one guest or
an explicit selection. An update stages and verifies new files before an
atomic switch; it never rewrites a running guest's active binary in place.

## Failure isolation

- A Control Center crash does not terminate a guest; `tx` remains usable.
- A guest crash does not terminate other guests or their displays.
- An Android API denial returns a typed permission error; it does not fall back
  to silent continuous capture or another sensor.
- GPU initialization failure falls back only through an explicit, reported
  backend chain and never claims the failed accelerator was used.
- An optional workload failure leaves the base desktop and other workload
  directories untouched.
- Corrupt manager state is backed up and reported; automatic repair is limited
  to deterministic state that can be reconstructed without deleting guest data.

## State ownership

The native manager owns `$PREFIX/var/lib/ternux` system records and
`$HOME/.local/share/ternux` user records according to their documented role.
Each guest owns its rootfs and guest home. Models belong to a named workload or
LAI store and are never removed by a guest uninstall unless the user selects
that exact data removal. See the [Workspace](WORKSPACE-ARCHITECTURE.md),
[Security](SECURITY-MODEL.md), and [ADR-0001](ADR/0001-native-manager.md).
