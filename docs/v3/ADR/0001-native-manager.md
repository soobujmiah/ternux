---
title: "ADR-0001: Native Termux manager and Control Center"
description: "Choose a host-native manager independent of Linux guests."
lang: "en"
---

## ADR-0001: Native Termux manager and Control Center

- **Status:** Accepted for v3 design; implementation pending.
- **Date:** 2026-11-13.
- **Decision owners:** Ternux project owner.

## Context

Managing guests from inside one guest prevents reliable guest-independent
status, installation, repair, and multi-distro lifecycle. A guest-owned web
server also cannot safely broker Android permissions or host package updates.

## Decision

The manager core, `tx` CLI, Control Center service, Device Bridge, and workload
registry run natively in Termux. Linux guests remain separately managed
workspaces. The service is optional; the CLI can inspect and recover it.

## Alternatives

- A manager inside Debian: rejected because it couples control to one guest
  and fails when that guest is absent or damaged.
- A guest-local web dashboard: rejected because it expands guest privilege and
  creates conflicting managers for multiple distributions.
- A required always-on daemon: rejected because it spends idle resources and
  makes base CLI actions depend on service health.

## Consequences

Host-side APIs need careful local authorization and compatibility handling.
In return, guests can be managed uniformly and the service can stop without
stopping guest sessions.
