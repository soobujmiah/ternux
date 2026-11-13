---
title: "ADR-0005: Native-first display allocation"
description: "Reserve the first X11 display for the native Termux workspace and allocate guest displays after it."
lang: "en"
---

## ADR-0005: Native-first display allocation

- **Status:** Accepted for v3 design; implementation pending.
- **Date:** 2026-11-13.
- **Decision owners:** Ternux project owner.

## Context

Ternux v3 adds a native Termux management GUI alongside the Linux guest
desktops. Display ownership must be deterministic so that the manager and each
guest can run concurrently without stealing or reusing another workspace's
X11 display.

## Decision

Reserve display `:0` for the native Termux workspace and Control Center.
Allocate guest displays in stable order: Debian `:1`, Ubuntu `:2`, Alpine
`:3`, then subsequent installed distributions receive the next free serial
display. A registry records workspace identity, display number, socket owner,
and lifecycle state. Allocation checks both registry records and live X
sockets/processes; stale records may be reclaimed only after proving no server
owns the display.

The current v2 mapping on the reference device (Debian `:0`, Ubuntu `:1`,
Alpine `:2`) remains untouched. v3 migration stages new assignments, checks
all target displays and sessions, and switches only after validation; failed
migration retains the working v2 assignments.

## Alternatives

- Keep guest Debian on `:0`: rejected for v3 because native Termux GUI would
  have no reserved first display and could collide with the default guest.
- Allocate arbitrary free displays on every start: rejected because display
  identity would change unpredictably across restarts.
- Derive display numbers only from installed guest order: rejected because
  adding or removing a distro could shift running workspaces.

## Consequences

The manager needs a persistent, collision-checked display registry and a
migration path. Guest display IDs remain stable through install-order changes;
unrecognized or externally occupied displays cause a clear allocation error
instead of being terminated or reused.
