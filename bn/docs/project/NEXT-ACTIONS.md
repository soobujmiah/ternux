---
title: "Ternux-এর পরবর্তী কাজ"
description: "পরের v2-major platform release-এর dependency অনুযায়ী engineering ও evidence কাজ।"
lang: "bn"
alt_url: "/docs/project/NEXT-ACTIONS.html"
---

## পরবর্তী কাজ

**শেষ পর্যালোচনা:** 2026-11-14। Stable channel withdrawn থাকবে; এই তালিকা পরের
v2-major release-এর অসম্পূর্ণ implementation ও qualification কাজ দেখায়।

1. পূর্ণ native Control Center শেষ করা: authenticated ও confirmation-bound
   lifecycle action, log, diagnostics, graphics/audio/storage/workload panel,
   accessible mobile layout এবং কম resource-ব্যবহারের idle profile যোগ করা।
   Current source dashboard read-only; Python বা browser না থাকলেও CLI চলবে।
2. Manager service-এর optional supervision যোগ করা—startup, health, stop ও crash
   recovery-সহ। Service update-এ guest session restart করা যাবে না।
3. Durable progress, safe cancellation ও confirmation-bound plan-সহ typed,
   idempotent lifecycle job সম্পূর্ণ করা; service বন্ধ থাকলে CLI দিয়ে recovery
   চালাতে হবে। Per-guest state ও unrelated PRoot guest অক্ষত রাখতে হবে।
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
হয়েছে। `tx manager migrate --apply sha256:PLAN_ID` state-bound plan আবার যাচাই
করে exclusive lock নেয়; active guest বা unsafe target থাকলে থামে। Journal rollback
ও `--recover` সমর্থন করে। Focused migration regression এবং তিন guest-এর
lifecycle/browser CI PR #233 ও merge commit
`376abe08a936c2fcbf161fc779d3c101e8255e99`-এ pass করেছে। Reference device-এ
Debian, Ubuntu ও Alpine session তখন চলছিল, তাই live display assignment switch
চালানো হয়নি; saved `:0/:2/:3` অপরিবর্তিত আছে। Owner classification best-effort,
OS-level socket ownership-এর প্রমাণ নয়।

Read-only Unix-socket service ও browser dashboard source feature; withdrawn
2.0.0 package-এ নেই। এই roadmap implementation record, release বা publication
অনুমোদন নয়।
