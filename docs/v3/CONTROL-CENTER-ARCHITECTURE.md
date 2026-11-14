---
title: "Ternux v3 Native Control Center"
description: "Architecture and lifecycle for the Termux-native Ternux Control Center."
lang: "en"
---

## Native Control Center

**Status: PARTIAL IMPLEMENTATION.** `tx control` starts a mobile-first local
browser dashboard from Termux. It uses a random loopback port, a one-hour
in-memory bearer token, restrictive CSP, and existing manager CLI snapshots.
Installed Ternux desktop profiles also have typed start/stop actions: the client
requests a state-bound plan, presents an explicit confirmation, submits a
one-use confirmation with same-origin and CSRF checks, and receives a durable
local job ID. The adapter invokes only fixed `start|stop GUEST` CLI arguments;
it does not accept shell text, install/uninstall, generic OCI guests, paths, or
environment overrides. Durable job records use restrictive permissions and are
marked `INTERRUPTED` for state reconciliation if the service exits mid-action. Terminal jobs are pruned after 30 days; active jobs are retained. A private
nonblocking host lock allows only one dashboard service instance so startup
recovery cannot mark another live instance's jobs interrupted.
Backend integration tests exist; actual device-browser action validation remains
open. Native Android UI, service supervision, cancellation, diagnostics, and the
full panel set are not implemented. This source feature is not in the withdrawn
v2.0.0 package.

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
- Dashboard snapshots read existing manager CLI JSON. Lifecycle mutations use
  separate typed HTTP routes and still do not require the socket service. Native
  Android UI and service-backed web transport remain future clients of the
  versioned API.
- The CLI can call the core directly when the service is stopped, so recovery
  does not depend on `txd`.

## Dashboard scope

The current screen shows manager health, installed guests, active desktop
assignments, display conflicts, a non-executable guest display migration
preview, device-qualification records, and copyable CLI commands. Desktop cards
can start or stop an installed Ternux desktop and poll its durable job record.
Qualification labels are records, not live verification. Graphics/audio,
storage grants, optional workloads, logs, diagnostics, cancellation, and native
Android UI remain future dashboard work.

## Local API and browser safety

The browser client uses a restrictive content security policy, same-origin/Host
checks, a short-lived bearer token, no wildcard CORS, and no query-string token.
Lifecycle POST routes additionally require the bearer token, exact local Origin,
CSRF header, typed inputs, a state-bound plan, a one-use confirmation, and an
idempotency key. Journal records are private to the Termux app UID. The HTTP
adapter is loopback-only; jobs invoke only fixed CLI argv and never shell input. The
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
