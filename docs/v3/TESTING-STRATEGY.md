---
title: "Ternux v3 testing strategy"
description: "Layered test plan for shell modules, distro profiles, manager contracts, device behavior, and releases."
lang: "en"
---

## Purpose

Tests must show behavior at the layer they exercise. A syntax check does not
prove install success; a CI guest fixture does not prove Android X11/audio/GPU;
and a successful UI launch does not prove update recovery. Report each result
with its environment and evidence level.

## Test layers

| Layer | Coverage | Environment and evidence |
|---|---|---|
| Static and unit | Shell syntax, ShellCheck, Python lint/types where adopted, schemas, path/ownership helpers, package-manager dispatch, input validation | Deterministic CI; no network or device claim |
| Contract | Manager requests/responses, state transitions, idempotence, cancellation, socket permissions, malformed input, schema compatibility | Isolated process fixtures; exact protocol version |
| Component integration | Installer phases, source bootstrap, downloader/hash verification, update transaction, guest registry, display allocation, audio/device brokers | Temporary roots and injected failures; preserve real user data |
| Distro matrix | Bootstrap, lifecycle, package manager, resume, update/remove, desktop package selection for each candidate | Pinned ARM64 rootfs or recorded repository snapshot; per-profile outcome |
| Clean-install qualification | Fresh Termux baseline, installer source, permissions, distro creation, recovery | Reference Android device; exact commit and installer digest |
| Live desktop/device | X11, resize/move, keyboard, audio, graphics correctness, storage, camera/mic permission/cancel behavior | Human-visible reference device where needed; measured or observed separately |
| Release and supply chain | Source archive reproducibility, checksums, action pins, package contents, signatures/provenance, docs/links | Exact release commit, isolated signing, archived workflow evidence |
| Reliability | Repeated start/stop, interrupted download/install/update, low storage, lost network, stale process, Android process kill/recovery | Bounded, reversible scenario with before/after data checks |

## Test organization

Keep `tests/focused.sh` as the single supported aggregate entry point while
partitioning implementation into focused subsystem suites. Each suite must
be safe on a developer phone: use temporary test roots, mock destructive
operations, never uninstall the owner's app, never delete existing guests,
and require an explicit fixture root for tests that write. Tests should print
pass/fail totals, retain actionable logs on failure, and clean only artifacts
they created.

Suggested suites:

- `tests/unit/`: parsers, validators, hashing/manifests, state transition rules.
- `tests/installer/`: bootstrap, phase resume, download fallback, rollback.
- `tests/distro/`: recipe contract and manager dispatch for each profile.
- `tests/manager/`: socket/API, jobs, lifecycle, permissions, concurrent calls.
- `tests/security/`: tampering, path traversal, symlink, hostile manifest,
  mutable source rejection, credential migration.
- `tests/device/`: documented human-run scripts and evidence templates; do not
  mark these passed from CI.

Adopt the directory split incrementally; do not create duplicate suites that
are not called by CI or the aggregate runner.

## Required failure injection

Every installer/update/remove state machine must test at least: DNS failure,
IPv4/IPv6 route mismatch and alternate-family retry, HTTP error, truncated
archive, wrong digest/signature, insufficient storage, permission denial,
process interruption after each durable step, retry, rollback, and a second
successful run proving idempotence. Destructive actions must prove their
allowlisted path set before execution.

For manager/service work also test daemon absent, stale PID, duplicate request,
service crash during a job, cancellation race, unreadable log, malformed state,
concurrent guest operations, and restart reconciliation. Keep guest operations
isolated per guest unless the contract explicitly models a shared resource.

## Device evidence record

For each reference-device test capture:

- Ternux commit and installed source digest.
- Device model/SoC, Android build, Termux version, display/input/audio stack.
- Distro image/repository snapshot and installed package versions.
- Exact command and setup; starting state and guest-data inventory.
- Expected and actual result, exit status, timestamps, logs/screenshots as
  appropriate, and whether the owner visually/hearing-tested the result.
- Cleanup and final state, including that unrelated guests and user data remain.

Use `VERIFIED` only for the exact named scenario. A broader claim needs a
broader matrix. Separate `SUPPORTED`, `EXPERIMENTAL`, `PLANNED`, `DEPRECATED`,
and `NOT TESTED` according to project maturity terminology.

## Release gates

1. Focused tests and aggregate runner pass on the exact commit.
2. Static checks, docs/link/parity checks, and workflow policy checks pass.
3. Regression matrix covers the four v2 baseline distros before testing new
   profiles.
4. Clean-install and rollback/recovery tests pass on the reference Termux
   environment without deleting existing user state.
5. Device-specific GUI, audio, graphics, input, and device-bridge claims have
   appropriately scoped evidence; CI is not substituted for human/device
   checks.
6. Release archive, checksums, source/tag identity, docs, and workflow evidence
   agree on the same source commit.

The v3.0 test-infrastructure milestone is complete only when the suites are
actually split or clearly partitioned, aggregate execution is deterministic,
negative/recovery tests are required in CI, and the evidence record is
generated for a clean release candidate. This document defines the target; it
does not claim that target is already implemented.
