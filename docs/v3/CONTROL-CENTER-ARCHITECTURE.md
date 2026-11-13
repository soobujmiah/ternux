---
title: "Ternux v3 Native Control Center"
description: "Architecture and lifecycle for the Termux-native Ternux Control Center."
lang: "en"
---

## Native Control Center

**Status: DESIGNED.** The Control Center is a Termux-native host application
and local service. It is not an XFCE app and never runs inside PRoot. The
manager and CLI remain functional if the Control Center is stopped or
uninstalled.

The native workspace reserves display `:0`; guest desktop displays begin at
`:1` and are allocated independently. See
[display allocation ADR](ADR/0005-native-display-allocation.md).

## Process model

- `txd` is a per-Termux-user, foreground-capable service managed by Termux
  runit where available. It binds only to a Unix-domain socket under a
  private `$PREFIX/var/lib/ternux/control/` directory.
- The local web UI binds to loopback only and obtains a short-lived session
  token from the service. No public or LAN listener is enabled by default.
- Native Android UI is a future client of the same versioned manager API; it
  does not receive broader host privileges than the local web UI.
- The CLI can call the core directly when the service is stopped, so recovery
  does not depend on `txd`.

## Dashboard scope

The first screen shows guest state, active displays, backend status, audio
route, storage grants, optional workload state, recent jobs, and explicit
permission state. It must distinguish detected, installed, active, and
verified states. Long actions show named phases, usable cancellation where
safe, and a durable job record. Errors include one next action and a copyable
diagnostic reference.

## Local API and browser safety

The browser client uses same-origin requests, restrictive content security
policy, CSRF-resistant action tokens, and no wildcard CORS. Mutating endpoints
require a session token and an origin check. Socket/file permissions are
limited to the Termux app UID. The service never accepts a guest-provided
filesystem path without resolving it beneath an allowlisted root.

## Startup and recovery

`txd` starts only after Termux is available; it does not start a desktop or
load a model. Health checks are bounded and do not poll sensors. If the UI
crashes, `txd` and guests continue. If `txd` crashes, the supervisor records
the condition and `tx` can inspect/repair it. A service update is staged and
restarts only `txd`; it does not restart Termux:X11, audio, IBus, or guests.

The exact API surface is in [API design](API-DESIGN.md); authorization and
threat boundaries are in [Security model](SECURITY-MODEL.md).
