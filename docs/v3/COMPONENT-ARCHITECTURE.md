---
title: "Ternux v3 component architecture"
description: "Component responsibilities, dependencies, interfaces, and ownership boundaries."
lang: "en"
---

## Component architecture

**Status: DESIGNED.** Components communicate through versioned local
interfaces. A component may be unavailable without making unrelated product
areas unusable.

| Component | Runs in | Owns | Depends on | Must not own |
|---|---|---|---|---|
| `tx` CLI | Termux host | Command parsing, stable UX, exit status | Manager core | Guest-specific business logic |
| Manager core | Termux host | Guest registry, state transitions, policy | Termux APIs, PRoot-Distro | GUI rendering or model internals |
| Control Center | Termux host | Dashboard, user action forms, event display | Local Manager API | Direct rootfs writes or Android permission bypass |
| Guest supervisor | Termux host | One guest process/display lifecycle | PRoot-Distro, Termux:X11 | Other guest process trees |
| Workspace adapter | Host plus guest | Guest profile, shell, desktop, scoped mounts | Distro package manager | Host CLI installation |
| Compute service | Host metadata + guest runtime | Capability and backend selection | Mesa/Turnip/runtime packs | Claims based on device-name heuristics |
| Workload manager | Termux host | Pack manifest, download, verify, install, remove | Artifact store, compute service | User model store unless selected |
| AI adapter | Host client + AI runtime | LAI discovery and job submission | Versioned LAI API | Forking LAI or duplicating its registry |
| Device Bridge | Termux host | Permission-aware API calls and file handoff | Termux:API | Persistent capture without an active request |
| Diagnostics | Termux host | Structured checks and safe repair plans | Component health APIs | Unscoped cleanup or automatic guest deletion |

## Dependency direction

The CLI and UI depend on manager interfaces. The manager depends on adapters,
not on presentation. Workspace and workload adapters may use the supervisor;
they do not import CLI formatting. Device Bridge and AI adapters expose
capabilities to the manager through narrow interfaces. No guest package may
call into manager internals by sourcing host shell files.

```text
CLI ───────┐
           ├── Manager API ── Guest registry ── Workspace adapter ── PRoot-Distro
Control UI ┘        ├──────── Compute service ── runtime adapters
                    ├──────── Workload manager ── verified artifacts
                    ├──────── Device Bridge ───── Termux:API
                    └──────── AI adapter ─────── LAI API
```

## Cross-component contracts

- IDs are stable opaque values; distro labels and display numbers are mutable
  attributes, not primary keys.
- Long tasks return a job ID, phase, progress, cancelability, and final
  structured result. A CLI can render the same event stream as the UI.
- Errors carry a stable code, safe user message, component, retry advice, and
  optional log reference. Secrets and raw environment values are excluded.
- Every mutating operation declares its target, expected current state, and
  rollback behavior before execution.
- Optional capabilities are discovered through explicit manifests. Absence is
  represented as `unavailable` with a reason, not a fake success.

Implementation boundaries are recorded in the [ADR index](ADR/README.md) and
tracked in [implementation status](../project/IMPLEMENTATION-STATUS.md).
