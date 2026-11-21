---
title: "Ternux Next Version distribution expansion and qualification"
description: "Candidate distro order, architecture risks, and release qualification gates."
lang: "en"
---

## Scope and baseline

The published source archive owner-confirmed baseline is Debian, Ubuntu, Kali Linux, and Alpine
Linux. Evidence depth is not identical for each profile; consult the
[feature matrix](../../audit/FEATURE-MATRIX.md) and
[earlier release reconciliation](../../release/V2-RELEASE-RECONCILIATION.md). Do not convert
the presence of a recipe into a `VERIFIED` or `SUPPORTED` claim.

The Next Version target is **eight fully qualified distributions**, using the four
baseline profiles plus four candidates. Ten distributions is a stretch goal,
not a delivery promise. The proposed first candidates, in evaluation order,
are Arch Linux, Fedora Linux, Void Linux, and openSUSE Tumbleweed. CentOS
Stream and Gentoo remain later candidates pending capacity and evidence.

## Candidate screening

| Candidate | ARM64 and bootstrap questions | PRoot and package questions | Desktop and upkeep risks | Initial status |
|---|---|---|---|---|
| Arch Linux | Confirm maintained ARM64 rootfs/bootstrap source, architecture naming, mirror availability, and signature verification | `pacman` keyring bootstrap, rolling updates, and PRoot syscall assumptions need live tests | Fast package churn and frequent ABI changes increase regression load | `PLANNED` |
| Fedora Linux | Confirm supported ARM64 rootfs and mirror/bootstrap path | `dnf` metadata/cache footprint, package scripts, and PRoot limitations need tests | SELinux policy expectations do not imply Android/PRoot enforcement; large desktop footprint | `PLANNED` |
| Void Linux | Confirm ARM64 musl and glibc image choices, bootstrap provenance, and mirror reliability | `xbps` trust bootstrap, package scripts, and runit behavior without init need tests | Musl/glibc split expands compatibility matrix; service assumptions need explicit handling | `PLANNED` |
| openSUSE Tumbleweed | Confirm ARM64 image/bootstrap availability and signature path | `zypper` solver and rolling snapshot update behavior need interruption/recovery tests | Large updates and snapshot cadence raise storage and regression costs | `PLANNED` |
| CentOS Stream | Confirm ARM64 rootfs availability, lifecycle, and bootstrap reliability | `dnf` and RPM scripts under PRoot need compatibility tests | Long-lived stream expectations differ from rolling/fixed profiles; overlap with Fedora needs product justification | `PLANNED` |
| Gentoo | Bootstrap provenance and ARM64 stage3 choice must be pinned and reproducible | Source-build assumptions, portage resource demands, and init integration may not fit phone storage/RAM | Very high install time, thermal/load, storage, and support burden | `PLANNED` |

These entries are screening hypotheses, not verified claims. Check current
upstream support and rootfs availability at implementation time; record URL,
date, digest/signature, architecture, and selected image in each qualification
record.

## Qualification matrix

Every profile must pass the same baseline gates, plus package-manager-specific
checks:

1. **Bootstrap integrity:** source is maintained, ARM64 is explicit, signatures
   or upstream checksums verify, archive path traversal is rejected, and
   installation can resume after a controlled failure.
2. **Lifecycle:** install, enter/exit, start/stop/restart, update, repair,
   preserve, and selected uninstall all behave idempotently; unrelated guests
   and host packages remain untouched.
3. **Package manager:** index refresh, install, upgrade, remove, broken mirror,
   IPv4/IPv6 fallback, invalid metadata, and interrupted transaction paths are
   exercised using the distro's native tooling.
4. **PRoot compatibility:** shell, users/groups, DNS, proc/dev/tmp behavior,
   locales, certificates, and package scripts work without implying kernel
   isolation or systemd/init support.
5. **Desktop:** Xfce startup/shutdown, X11, keyboard zoom, move/resize,
   clipboard/input, browser and selected optional-app installation are
   verified on a named device and image digest.
6. **Device integrations:** audio, graphics route/correctness, storage,
   camera/microphone point-of-use flow, and Bengali input are reported
   separately as `VERIFIED`, `NOT TESTED`, or a precise limitation.
7. **Resource and reliability:** download/storage footprint, peak memory,
   install duration, recovery, and a bounded idle/start/stop soak are measured;
   never infer performance from package install success.
8. **Security and support:** ownership boundaries, repository keys, package
   provenance, lifecycle support, documentation, and rollback are reviewed.

Qualification records must include exact Ternux commit, distro release/image
digest, package repository snapshot or timestamp, Android/Termux/device
details, commands, logs, failures, and retest evidence. CI is useful for recipe
and lifecycle fixtures but cannot replace device qualification for X11,
graphics, audio, input, camera, or microphone behavior.

## Sequence and release gate

1. Keep the four baseline profiles in the regression suite.
2. Screen Arch, Fedora, Void, and openSUSE for maintained ARM64 bootstrap
   sources and PRoot fit before authoring recipes.
3. Implement one candidate at a time behind an explicit experimental profile.
4. Complete the full matrix and recovery test before marking it `VERIFIED`.
5. Promote to `SUPPORTED` only after documentation, CI coverage, owner review,
   and support ownership are established.
6. Add CentOS Stream or Gentoo only after the first four candidates qualify or
   their blockers are documented with a revised target.

The Phase 0 release gate is eight qualified profiles only if each new profile
passes every mandatory gate. Otherwise the release must state the smaller
verified count and explain which candidate remains unqualified; never lower the
qualification bar to hit the number.
