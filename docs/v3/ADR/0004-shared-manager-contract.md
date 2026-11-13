---
title: "ADR-0004: Shared typed manager contract"
description: "Keep native management behavior in one typed core shared by CLI and future clients."
lang: "en"
---

## ADR-0004: Shared typed manager contract

- **Status:** Accepted for v3 implementation.
- **Date:** 2026-11-13.
- **Decision owners:** Ternux project owner.

## Context

Ternux v3 will have a native CLI, optional Control Center service, and later
graphical clients. Duplicating validation and lifecycle behavior in each client
would produce inconsistent guest state and unsafe operation paths. A separate
Android/PRoot management project was audited for engineering patterns; its
source and GPL-3.0-or-later license are not imported into Ternux, which remains
Apache-2.0. This decision independently specifies the pattern for Ternux.

The audit snapshot was TernuxX commit `419f910` (2026-11-13). Its management
API contract describes shared CLI/TUI/GUI operations and an authenticated,
loopback-only Web adapter. The reviewed source contains typed operation
dispatch (`lib/management_service.py`), implemented-operation catalog
generation (`lib/management_catalog.py`), capability checks
(`lib/management_authorization.py`), request idempotency
(`lib/management_request_store.py`), and journaled recovery
(`lib/operation_journal.py`). These are research references, not Ternux
dependencies or imported implementation.

## Decision

- Keep manager operations in a native, typed application core. CLI and future
  clients call that core through narrow adapters; clients contain presentation
  logic, not a second implementation of management policy.
- Reject unknown operations and validate typed arguments before provider work.
  Do not expose arbitrary shell strings, caller environment maps, or
  unrestricted filesystem paths as manager operations.
- Derive any future capability catalog and client menus from operations the
  core actually implements. Report provider, state source, and evidence age
  explicitly; do not promote unknown state to installed or healthy.
- Keep initial status and guest inventory read-only, native, and useful without
  a guest or running Control Center service.
- Before mutations are enabled, require a preview of the exact immutable plan,
  confirmation bound to that plan, idempotent request handling, and a durable
  operation record with defined interruption recovery.
- Keep the local service optional and off until requested. Any Web adapter must
  remain loopback-only and separately authenticated; it never exposes a shell
  or general-purpose file API.

## Consequences

The first implementation can remain a small direct CLI slice while preserving
one application contract for future clients. Service transport, authorization,
request replay, job state, and mutation planning remain separate gates; this ADR
does not claim they are implemented. Ternux's source and documentation are
written independently and remain under the project's existing Apache-2.0
license.

## Research references

- [TernuxX management API contract at audited commit](https://github.com/soobujmiah/ternuxx/blob/419f910/docs/architecture/MANAGEMENT-API.md)
- [TernuxX shared management plan at audited commit](https://github.com/soobujmiah/ternuxx/blob/419f910/docs/architecture/SHARED-MANAGEMENT-PLAN.md)
- [TernuxX typed dispatcher at audited commit](https://github.com/soobujmiah/ternuxx/blob/419f910/lib/management_service.py)
- [TernuxX original-source license at audited commit](https://github.com/soobujmiah/ternuxx/blob/419f910/LICENSE)
