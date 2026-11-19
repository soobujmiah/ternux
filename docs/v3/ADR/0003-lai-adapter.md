---
title: "ADR-0003: Rejected external-product adapter proposal"
description: "Historical proposal rejected by the owner; unrelated products remain outside Ternux scope."
lang: "en"
---

## ADR-0003: Rejected external-product adapter proposal

- **Status:** Rejected and superseded by the owner's 2026-11-19 scope directive; no implementation.
- **Date:** 2026-11-13.
- **Decision owners:** Ternux project owner.

## Context

An earlier proposal considered integrating an unrelated AI product. The owner
has since directed that LAI and all unrelated repositories/products remain
outside Ternux scope.

## Decision

Ternux will not integrate with LAI or depend on its APIs, services, private app
data, or model store. Ternux may continue to develop and maintain its own
AI tools, workloads, inference utilities, and integrations within the Ternux
repository. Any future scope change requires an explicit owner decision.

## Consequences

This historical proposal creates no implementation requirements or dependency.
The identifier is retained so existing ADR links and records remain stable.
