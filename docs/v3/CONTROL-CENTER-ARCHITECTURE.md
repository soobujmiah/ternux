---
title: "Ternux v3 Native Control Center"
description: "Architecture and lifecycle for the Termux-native Ternux Control Center."
lang: "en"
---

## Native Control Center

**Status: PARTIAL IMPLEMENTATION.** `tx control` now starts a mobile-first,
read-only local browser dashboard from Termux. It uses a random loopback port, a
one-hour in-memory bearer token, strict Host/Origin checks, restrictive CSP,
and exposes GET-only snapshots through the existing manager CLI. It does not
use the Unix-socket service, expose mutation endpoints, start/stop guests, or
provide a native Android APK. The dashboard is source-only; it is not in the
withdrawn v2.0.0 package. The full Control Center, typed mutation operations, service supervisor,
durable jobs, and native Android UI remain incomplete.

The manager CLI remains usable when the optional UI or socket service is
stopped. Python 3 is optional and required only to run `tx control` or
`tx manager serve`.
The native workspace reserves display `:0`; guest desktop displays begin at
`:1` and are allocated independently. See
[display allocation ADR](ADR/0005-native-display-allocation.md).

## Process model

- The manager socket runs in the foreground only when explicitly invoked by
  `tx manager serve`. It binds under the private
  `$PREFIX/var/lib/ternux/control/` directory and never opens a TCP port.
- `tx control` separately starts a temporary HTTP server on `127.0.0.1` and a
  random port. Its session key is held in memory for at most one hour and sent
  to the page in the URL fragment, never in an HTTP request or referrer. The
client removes the fragment immediately and keeps the key only in the current
browser tab's session storage so reloads work; closing the tab discards it.
- The first dashboard only reads existing manager CLI JSON. It has no guest
  mutation routes and does not require the socket service. Native Android UI
  and service-backed web transport remain future clients of the versioned API.
- The CLI can call the core directly when the service is stopped, so recovery
  does not depend on `txd`.

## Dashboard scope

The current first screen shows manager health, installed guests, active desktop
assignments, display conflicts, a non-executable guest display migration
preview, device-qualification records, and copyable CLI commands. It labels
itself read-only and does not imply that profile
qualification is a live verification. Graphics/audio, storage grants, optional
workloads, recent jobs, diagnostics, mutations, named progress, cancellation,
and durable job records remain future dashboard work.

## Local API and browser safety

The current browser client has no mutation endpoints, uses a restrictive
content security policy, same-origin/Host checks, a short-lived bearer token,
no wildcard CORS, and no query-string token. The HTTP adapter is loopback-only.
Future mutations still require typed authorization, same-origin checks,
CSRF-resistant tokens, idempotency, immutable preview plans, and durable
journaling. Socket/file permissions stay limited to the Termux app UID. The
service must never accept a guest-provided path without resolving it beneath
an allowlisted root.

## Future startup and recovery

`txd` starts only after Termux is available; it does not start a desktop or
load a model. Health checks are bounded and do not poll sensors. If the UI
crashes, `txd` and guests continue. If `txd` crashes, the supervisor records
the condition and `tx` can inspect/repair it. A service update is staged and
restarts only `txd`; it does not restart Termux:X11, audio, IBus, or guests.

The exact API surface is in [API design](API-DESIGN.md); authorization and
threat boundaries are in [Security model](SECURITY-MODEL.md).
