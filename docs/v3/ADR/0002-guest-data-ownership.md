---
title: "ADR-0002: Explicit guest and data ownership"
description: "Separate guest lifecycle from user models, Android files, and unrelated Termux data."
lang: "en"
---

## ADR-0002: Explicit guest and data ownership

- **Status:** Accepted for v3 design; implementation pending.
- **Date:** 2026-11-13.
- **Decision owners:** Ternux project owner.

## Context

Uninstall and repair must not erase data that the manager did not create or
that belongs to a separate workload, LAI, or Android user directory.

## Decision

Every managed file, guest, runtime pack, model copy, and storage grant has an
owner ID and lifecycle record. Default guest uninstall removes only the
selected rootfs and its explicitly Ternux-owned guest state. Models and shared
media require a separate user selection. `/sdcard` remains available when
explicitly granted and is not treated as guest-owned data.

## Consequences

The registry and uninstall UI must enumerate ownership and disk use. Legacy
untracked files need a report/reconciliation path; they cannot be silently
classified as disposable.
