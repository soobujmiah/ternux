---
title: "Ternux v3 proposals"
description: "Post-v2 proposal backlog based on owner-requested Ternux capabilities; proposals are not release commitments."
lang: "en"
alt_url: "/bn/docs/V3-PROPOSALS.html"
---

This page preserves the early post-v2 proposal backlog. The owner has since
authorized a broader v3 direction, now recorded as a design baseline in the
[v3 architecture overview](V3-ARCHITECTURE.html) and its
[implementation roadmap](v3/IMPLEMENTATION-ROADMAP.html). Those documents are
design, not proof of implementation or release qualification. The candidate
items below remain historical context and do not override the canonical v3
scope or acceptance criteria.

## Candidate proposals

### 1. Trusted, zero-setup package distribution

Make the normal Termux package flow (`pkg install ternux`) available through a
trusted package index or another signed distribution channel, with key
rotation, reproducible metadata, upgrade and rollback behavior, and a clear
repository health page. The v2 public APT endpoint and clean package lifecycle
remain v2 release gates; this proposal is about long-term distribution
resilience after those gates close.

### 2. Broader distro qualification

Keep the existing distro profiles easy to install, but add automated clean
guest qualification for desktop startup, graphics route, audio, keyboard input,
storage isolation, browser availability, and removal. Publish results per
distro and architecture so a recipe is never mistaken for a device-tested
release.

### 3. Optional accelerator and model packs

Offer separately installable CPU, Vulkan/GPU, and device-specific NPU packs for
text and image workloads. Each pack should declare supported hardware and
runtime versions, verify model provenance and hashes, expose measured memory
and speed ranges, and remove cleanly without changing the base desktop. Keep
experimental paths clearly separated until correctness and recovery gates pass.

### 4. Android camera and microphone integration

Investigate a permission-aware camera streaming bridge for live preview and
webcam use, plus on-demand microphone access through Termux APIs. The desktop
must request access only when the user opens a capture/recording action, show
permission and device status, and save validated media inside the selected
guest. This depends on Android API and Termux companion capabilities and needs
device-specific privacy and lifecycle tests.

### 5. Lower-resource desktop profile

Define a measured low-memory profile with optional desktop services, bounded
background startup, and a smaller default application set. Report idle and
interactive RAM/CPU use on named devices, while preserving the existing
full-featured XFCE option.

## Proposal status

All five items are **proposed**. None is represented as implemented or
committed for v3. Current v2 behavior and limitations remain documented in the
[v2 release-readiness report](V2-RELEASE-READINESS.md),
[installation guide](INSTALLATION.md), and
[accelerator release plan](ACCELERATOR-RELEASE-PLAN.md).
