---
title: "Next Version Architecture"
description: "Architecture directions for future review, separate from current support."
lang: "en"
alt_url: "/bn/docs/NEXT-ARCHITECTURE.html"
---

This document describes possible architectural directions, not shipped
capabilities or a release commitment. Current source has partial management and
Control Center components; their presence does not imply a complete platform.

## Principles

- **Evidence before claims:** distinguish implementation, test evidence, and
  device qualification.
- **Least authority:** host/guest boundaries, explicit consent for sensitive
  operations, and loopback-only local control surfaces.
- **Recoverability:** idempotent operations, durable journals where needed, and
  safe repair/removal paths.
- **Portable boundaries:** keep distro-specific setup behind explicit
  profiles; arbitrary OCI images remain shell guests unless a desktop recipe is
  maintained.
- **Optional acceleration:** CPU is the baseline; GPU/NPU components remain
  opt-in until target-device correctness, licensing, and recovery are verified.
- **Honest distribution status:** package signing and a visible channel health
  state are prerequisites; no channel is available while its repository is
  unavailable.

## Possible components

A local manager may coordinate installed guests and expose a versioned,
read-only status interface before any mutating API is considered. A workspace
layer may track guest identity, display allocation, and recovery state. A device
bridge may offer narrowly-scoped Android integrations with permission prompts
at point of use. Extensions may package separately licensed compute runtimes
without bundling user model weights.

These directions require threat modeling, compatibility review, bilingual
operator guidance, and independent tests before adoption. The [implementation
roadmap](next/IMPLEMENTATION-ROADMAP.html) lists sequencing and evidence gates;
[proposals](NEXT-PROPOSALS.html) remain candidates for review only.
