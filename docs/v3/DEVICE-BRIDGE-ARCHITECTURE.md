---
title: "Ternux v3 Device Bridge"
description: "Permission-aware access to Android storage, camera, microphone, and other Termux APIs."
lang: "en"
---

## Device Bridge

**Status: DESIGNED.** Android services are accessed by a Termux-host broker
using Termux:API, never by granting a guest arbitrary Android device nodes.
The broker checks companion-app availability, permission, request scope, and
target guest before invoking an API.

## Request flow

1. A user starts a capture or sensor action in a guest application or Ternux
   UI. The request names the operation and destination; it cannot provide an
   arbitrary host command.
2. The host broker validates the operation against a fixed API allowlist and
   asks Android for any required permission at point of use.
3. The broker invokes Termux:API on demand, validates the returned file or
   data, and transfers only the result into the selected guest path.
4. It reports granted/denied/unavailable, capture duration, output path, and
   cleanup result. Microphone and camera sessions end when the request exits
   or is cancelled.

## Storage grants

The existing scoped `/sdcard` exposure remains a user-visible grant. v3 adds
path-level grant records with owner, guest, access mode, created time, and
revocation state. Read-only is the default; write access is limited to a
selected directory. `/sdcard` remains available to guests when explicitly
granted. Revocation stops new accesses and removes the corresponding mount on
the next guest start; it does not erase user files.

## Camera and microphone

Still-photo capture, live preview, webcam device emulation, and audio recording
are distinct capabilities. A still-photo API must not be presented as a live
stream. If Android or Termux:API cannot expose a live stream, the UI explains
that limit and offers supported capture instead. Microphone input is
request-driven, visibly active, bounded by user-selected duration where
possible, and saved only to the chosen destination. The broker never keeps a
background hot microphone.

## Failure and privacy

Missing companion apps, revoked permission, cancelled dialogs, malformed
responses, low storage, and guest-transfer errors have separate result codes.
Temporary media is private to the requesting job and removed on failure.
Diagnostics redact media content, prompts, and raw Android identifiers.
