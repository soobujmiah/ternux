---
title: "Ternux-এর পরবর্তী কাজ"
description: "পরের v2-major platform release-এর dependency অনুযায়ী engineering ও evidence কাজ।"
lang: "bn"
alt_url: "/docs/project/NEXT-ACTIONS.html"
---

## পরবর্তী কাজ

**শেষ পর্যালোচনা:** 2026-11-14। Stable channel withdrawn থাকবে; এই তালিকা পরের
v2-major release-এর অসম্পূর্ণ implementation ও qualification কাজ দেখায়।

1. আংশিক native Control Center এগিয়ে নেওয়া: working source-এ authenticated,
   confirmation-bound desktop start/stop ও durable job record আছে। Device browser-এ
   যাচাই, log, diagnostics, graphics/audio/storage/workload panel, accessible mobile
   layout ও কম resource-ব্যবহারের idle profile সম্পূর্ণ করা বাকি। Python বা browser
   না থাকলেও CLI চলবে।
2. Manager service-এর optional supervision যোগ করা—startup, health, stop ও crash
   recovery-সহ। Service update-এ guest session restart করা যাবে না।
3. Typed, idempotent lifecycle job-এ durable progress ও interruption recovery
   আছে; cancellation, retained-job policy এবং service বন্ধ থাকলে CLI recovery
   সম্পূর্ণ করতে হবে। Per-guest state ও unrelated PRoot guest অক্ষত রাখতে হবে।
4. Workspace acceptance matrix শেষ করা: Debian, Ubuntu ও Alpine-এ clean install,
   update, resume, restart, stop ও uninstall। Multi-guest install-এর আগে shared
   shell, প্রতিটি username ও workload সংগ্রহের বর্তমান precollection contract
   বজায় রাখতে হবে।
5. Acceptance criteria অনুযায়ী Compute, AI, Device Bridge ও extension-এর কাজ
   চালিয়ে যাওয়া; correctness, permission, failure, rollback ও device evidence
   আলাদা রাখতে হবে।
6. Package metadata, CLI help, English/Bengali docs, website, security review,
   exact-commit CI এবং clean reference-device install audit করে align করা। Exact
   2.x release candidate-এর সব বাধ্যতামূলক gate pass না হওয়া পর্যন্ত stable
   channel withdrawn থাকবে।

## সম্পন্ন source slice: display migration

Native display registry ও explicit migration executor source-এ implement করা
হয়েছে। Plan exclusive lock-এ revalidate হয়; active guest, অন্য managed session-এর
shared lock বা unsafe target থাকলে থামে। Journal rollback ও `--recover` সমর্থন করে।
2026-11-14-এ সব guest থামিয়ে reference device-এ migration হয়; Debian launcher
`:1`-এ refresh করে Debian, Ubuntu, Alpine-কে `:1/:2/:3`-এ READY করা হয়। পূর্ণ
clean install/update/resume/restart/stop/uninstall matrix বাকি। Owner classification
best-effort, OS-level socket ownership-এর প্রমাণ নয়.

Read-only Unix-socket service ও desktop action-সহ browser dashboard-এর বর্তমান
working-source slice source feature; withdrawn 2.0.0 package-এ নেই। এই roadmap implementation record, release বা publication
অনুমোদন নয়।
