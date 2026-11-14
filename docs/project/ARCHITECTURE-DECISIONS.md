---
title: "Ternux architecture decisions"
description: "Index of accepted v2 constraints and v3 Architecture Decision Records."
lang: "en"
---

## Architecture decisions

The former v3 platform decision record lives in [Architecture Decision Records](../v3/ADR/README.md).

Accepted platform decisions for the next v2-major release:

- Native Termux manager and optional Control Center: [ADR-0001](../v3/ADR/0001-native-manager.md)
- Explicit guest and data ownership: [ADR-0002](../v3/ADR/0002-guest-data-ownership.md)
- LAI integration through a versioned adapter: [ADR-0003](../v3/ADR/0003-lai-adapter.md)
- Shared typed manager contract: [ADR-0004](../v3/ADR/0004-shared-manager-contract.md)
- Native-first display allocation: [ADR-0005](../v3/ADR/0005-native-display-allocation.md)

These decisions define required architecture for the next v2-major release, not
proof that their components are implemented. The withdrawn 2.0.0 behavior remains described by
[Architecture](../ARCHITECTURE.md) and [release status](RELEASE-STATUS.md).
