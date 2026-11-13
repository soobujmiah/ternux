---
title: "Ternux v3 Workspace architecture"
description: "Named, isolated Linux guest workspaces with independent shells, displays, and lifecycle."
lang: "en"
---

## Workspace architecture

**Status: DESIGNED.** A workspace is one registered PRoot-Distro guest plus
its Ternux profile, user mapping, packages, display assignment, mounts,
desktop state, and logs. Debian, Ubuntu, and Alpine remain the v2-qualified
profiles; other distributions are experimental until their own acceptance
evidence exists.

## Identity and commands

Each guest has an immutable internal ID and a unique human-readable name.
Stable aliases (`db`, `ub`, `alp`, and full names) resolve to one guest; a
shell alias enters the configured unprivileged user and a separate `root`
alias enters root. `tx start [guest]` starts the selected desktop. With more
than one eligible guest and no selection, the CLI presents one consistent
multi-choice prompt. It never silently changes the default guest based on
which display happens to be running.

`tx stop [guest...]` targets selected guests. An interactive no-argument stop
lists active sessions and supports one or more selections. In v3, display
`:0` is reserved for the native Termux workspace/Control Center. New guest
profiles receive stable defaults: Debian `:1`, Ubuntu `:2`, Alpine `:3`, then
other named profiles in serial order. Startup checks the target X11 socket and
matching Termux:X11 server, refuses occupied paths, and removes only a socket
proven stale by its lock PID and process checks. The display number is persisted
with the guest profile. Existing stored assignments remain authoritative: the
current v2 device's Debian `:0`, Ubuntu `:1`, Alpine `:2` sessions are not
changed by this code. A full collision registry and explicit staged migration
still need to validate every target, record owner and lifecycle state, and
switch only after all sessions can be moved safely.

## Per-guest recipe

A distro recipe contains package-family operations, user and sudo setup,
graphics/audio integration, Ternux theme assets, keyboard/input setup,
browser choice, applications, storage policy, health probes, and removal
ownership. Recipes declare unsupported operations rather than assuming every
package manager behaves like apt. Shared assets are versioned and installed
from the same checked source bundle.

## Isolation and persistence

Each guest gets only declared binds: `/dev`, required `/proc` and `/sys`
views, Termux:X11 socket, PulseAudio route, Android shared storage at
`/sdcard` when Termux already has permission, and user-granted extra
subdirectories. Host
`$PREFIX` and Termux home are not exposed by default. Guest packages and home
data persist across Ternux CLI updates. Guest deletion is a separate,
explicitly confirmed destructive action that reports the exact rootfs and
state it removes.

## GUI compatibility

Desktop setup applies GTK, icon, and window-manager theme defaults, usable
titlebar controls, phone viewport fitting, IBus setup, font support, and
desktop launchers. Claims are toolkit-specific: XFWM decorations cover
server-decorated windows; client-side decorations and other toolkits need
their own tests. The Ternux theme must provide inherited fallback icons and
must never replace an unknown application icon with an unrelated brand mark.
