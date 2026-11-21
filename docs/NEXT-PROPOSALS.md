---
title: "Proposals for the Next Version"
description: "Ideas for future consideration, not release commitments."
lang: "en"
alt_url: "/bn/docs/NEXT-PROPOSALS.html"
---

This page collects ideas for future review. These are proposals—not current
support claims or release gates. See the [next-version architecture](NEXT-ARCHITECTURE.html)
and [implementation roadmap](next/IMPLEMENTATION-ROADMAP.html) for possible
review methods.

## Candidate proposals

### 1. Trusted package distribution

Consider a signed Termux package channel with key rotation, reproducible
metadata, safe upgrade and rollback, and a repository health page. The package
repository is currently unavailable. A prototype requires a separate feasibility
review and owner approval.

### 2. Qualification for additional distros

Keep the four maintained desktop setups reliable; consider a new guest profile
only with clean-install evidence. Check desktop startup, graphics, audio,
keyboard input, storage isolation, browser behavior, and removal. Publish results
by distro and device so a recipe is not mistaken for device-verified support.

### 3. Optional accelerator and model packs

Consider separate CPU, Vulkan/GPU, and device-specific NPU packs for text and
image workloads. Each pack needs hardware/runtime requirements, artifact
provenance and hash verification, measured memory/performance, and an uninstall
path that does not alter the base desktop. Keep an experimental route isolated
until correctness and recovery tests pass.

### 4. Android camera and microphone integration

Investigate permission-aware camera streaming and, where needed, microphone
access through Termux API. Request permission only when capture starts, show the
device state, and store verified media in the selected guest. Check Android and
Termux capabilities as well as device-specific privacy and lifecycle behavior.

### 5. Low-resource desktop profile

Consider a profile with optional services, bounded background startup, and a
smaller default app set. Publish idle and interactive RAM/CPU measurements on
specific devices while keeping the full desktop available.

No proposal has a target date. The [project roadmap](project/PROJECT-ROADMAP.html)
describes current work; the [accelerator plan](ACCELERATOR-RELEASE-PLAN.html)
records existing evidence and limits.
