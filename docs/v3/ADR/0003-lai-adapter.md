---
title: "ADR-0003: Integrate with LAI through a versioned adapter"
description: "Keep LAI separate and integrate only through a documented runtime interface."
lang: "en"
---

## ADR-0003: Integrate with LAI through a versioned adapter

- **Status:** Accepted for v3 design; implementation pending.
- **Date:** 2026-11-13.
- **Decision owners:** Ternux project owner.

## Context

Ternux should expose optional AI workloads without duplicating LAI's model
registry, runtime selection, or accelerator implementation. Private or
unstable app internals are not a reliable integration contract.

## Decision

Ternux will use a versioned, documented LAI API/intent/IPC adapter. Discovery
of model files is read-only. Ternux never moves or removes LAI-owned models
automatically. If no supported LAI interface is available, Ternux reports the
integration unavailable and may offer a separately scoped compatible runtime
pack only after an explicit product decision.

## Consequences

The adapter needs capability negotiation, job/result correlation, permission
handling, and compatibility tests. LAI remains independently installable and
maintainable.
