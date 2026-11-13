---
title: "Ternux v3 product vision"
description: "Product outcomes, user groups, scope, and measurable principles for Ternux v3."
lang: "en"
---

## Product vision

**Status: DESIGNED.** Ternux v3 makes an Android phone a dependable Linux
workstation that stays understandable and responsive on constrained hardware.
The product is one native Termux control surface with isolated Linux workspaces,
optional compute and AI workloads, and permission-aware access to Android
devices.

## User outcomes

- Install and manage several Linux distributions without mixing their files,
  users, displays, packages, or lifecycle state.
- Start a shell or desktop by a short, predictable command; see which guest is
  running and stop only the selected guest.
- Use common Linux applications with consistent Ternux branding and usable
  phone-sized windows, keyboard input, storage, sound, and graphics.
- Add CPU, GPU, or device-specific NPU workloads only when desired, understand
  their model/runtime/space requirements, and remove them without damaging the
  base workstation.
- Use camera and microphone only through explicit, inspectable, point-of-use
  requests. Use Android shared storage when Termux already has permission, with
  additional directory grants visible and scoped.
- Diagnose a problem from one place with evidence and recovery steps that do
  not require deleting the user's guest or model data.

## Product areas

| Area | User-facing result | Required boundary |
|---|---|---|
| Workspace | Named distro shells/desktops and file access | Per-guest identity and lifecycle |
| Compute | Detect, select, and inspect CPU/GPU routes | Capability evidence; safe fallback |
| AI | Install/run compatible workloads and models | LAI integration; provenance and resource limits |
| Device Bridge | On-demand Android camera, mic, and storage access | Termux API broker; scoped permission |
| Native Control Center | One dashboard/API for status, actions, and logs | Termux host process, independent of PRoot |

## Design principles

1. **Fast by default:** bounded background work, no idle model loading, no
   continuous camera/microphone capture, and graceful operation on low RAM.
2. **Strong by construction:** explicit component boundaries, least privilege,
   atomic updates, checksummed artifacts, and recoverable state transitions.
3. **Easy to understand:** stable commands, clear distro names, progressive
   disclosure, copyable examples, and errors with a next action.
4. **Evidence before claims:** detect separately from use; use separately from
   correctness; correctness separately from speed qualification.
5. **No hidden ownership:** users can see where data lives, which service owns
   it, what a grant exposes, and what uninstall will remove.

## Out of scope for a v3 promise

- Root access, kernel namespaces, or arbitrary Android device-node access that
  Android does not grant to Termux.
- Universal GPU/NPU support or automatic selection based only on a device name.
- Running every desktop application correctly in every guest profile.
- Silent model downloads, background inference, or unrestricted guest access to
  Android storage and sensors.

See [acceptance criteria](ACCEPTANCE-CRITERIA.md) for the evidence needed to
turn each outcome into a release claim.
