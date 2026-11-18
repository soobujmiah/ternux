---
title: "Ternux v3 proposals"
description: "Post-v2 proposal backlog based on owner-requested Ternux capabilities; proposals are not release commitments."
lang: "en"
alt_url: "/bn/docs/V3-PROPOSALS.html"
---

This page preserves the early post-v2 proposal backlog. On 2026-11-14, the
owner temporarily directed former v3 platform scope into v2; that decision was
revoked on 2026-11-18. These proposals remain future v3 work and are not v2
release gates. The [v3 architecture overview](V3-ARCHITECTURE.html) and
[implementation roadmap](v3/IMPLEMENTATION-ROADMAP.html) describe the current
future scope; design does not prove implementation or release qualification.

## Candidate proposals

### 1. Trusted, zero-setup package distribution

Make the normal Termux package flow (`pkg install ternux`) available through a
trusted package index or another signed distribution channel, with key
rotation, reproducible metadata, upgrade and rollback behavior, and a clear
repository health page. Stable APT was withdrawn from v2 and is not a v2.0.1
release gate. Any future distribution prototype requires a separate v3
feasibility study and owner approval.

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

These five entries are historical proposals, not v2 release requirements.
Future v3 work is tracked in the [project roadmap](project/PROJECT-ROADMAP.html)
and [acceptance criteria](v3/ACCEPTANCE-CRITERIA.html). Current implementation and limitations are documented in the
[v2 release-readiness report](V2-RELEASE-READINESS.md),
[installation guide](INSTALLATION.md), and
[accelerator release plan](ACCELERATOR-RELEASE-PLAN.md).
