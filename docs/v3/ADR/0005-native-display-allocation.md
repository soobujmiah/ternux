---
title: "ADR-0005: Native-first display allocation"
description: "Reserve the first X11 display for the native Termux workspace and allocate guest displays after it."
lang: "en"
---

## ADR-0005: Native-first display allocation

- **Status:** Accepted; defaults, startup collision guards, lifecycle registry, read-only preview, and journaled explicit migration executor implemented in source; device apply remains unverified.
- **Date:** 2026-11-13.
- **Decision owners:** Ternux project owner.

## Context

Ternux includes a native Termux manager alongside the Linux guest desktops.
Display ownership must be deterministic so the manager and each guest can run
concurrently without stealing or reusing another workspace's X11 display.

## Decision

Reserve display `:0` for the native Termux workspace and Control Center.
Allocate guest displays in stable order: Debian `:1`, Ubuntu `:2`, Alpine
`:3`, then subsequent installed distributions receive the next free serial
display. A registry records workspace identity, display number, socket owner,
and lifecycle state. Allocation checks both registry records and live X
sockets/processes; stale records may be reclaimed only after proving no server
owns the display.

The saved mapping on the reference device (Debian `:0`, Ubuntu `:2`, Alpine
`:3` in the latest source snapshot) remains untouched until an operator applies a
ready state-bound plan. Migration checks all targets and sessions, records exact
profile and registry backups in a private journal, and restores them on write
failure or interrupted execution.

## Alternatives

- Keep guest Debian on `:0`: rejected for the prior layout because native Termux GUI would
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

The current implementation provides stable defaults for newly configured
profiles and preserves each existing profile's saved display. A versioned,
lock-protected registry atomically stores workspace ID, current and target
display, last lifecycle state, and update time. Socket paths, locks, server
processes, and inferred owner class remain live observations; the registry does
not claim OS-level socket ownership. Desktop startup
checks for an occupied socket, X lock, or matching server process and refuses
to reuse it. The read-only `tx manager displays` command reports current and
target assignments, occupied target paths, blockers, and a state-bound plan ID.
Schema 1.3.0 exposes whether the explicit executor is ready. `tx manager migrate
--apply sha256:PLAN_ID` rechecks the exact snapshot while holding the migration
lock; it never stops or restarts guests and refuses active sessions, occupied
targets, invalid or mismatched registry data, and non-stopped lifecycle states.
Profiles and the registry are backed up before writes. Failed writes restore both;
interrupted writes block guest startup until `tx manager migrate --recover`
restores the journal. The live mapping is not changed automatically.
