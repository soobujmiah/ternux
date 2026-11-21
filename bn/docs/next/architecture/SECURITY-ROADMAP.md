---
title: "টার্নাক্স পরবর্তী সংস্করণ security ও supply-chain roadmap"
description: "পরবর্তী সংস্করণ security finding, অগ্রাধিকারভিত্তিক কাজ ও evidence gate।"
lang: "bn"
alt_url: "/docs/next/architecture/SECURITY-ROADMAP.html"
---

## Baseline ও boundary

Ternux Android Termux app UID-তে চলে। PRoot ওই UID থেকে kernel security boundary তৈরি করে না। বর্তমান security model threat-model baseline; এই roadmap কাজের পরিকল্পনা, control ইতিমধ্যে চালু—এমন দাবি নয়।

পরিচিত finding maintenance risk, confirmed compromise-এর প্রমাণ নয়:

| Finding | বর্তমান evidence | অগ্রাধিকার ও প্রস্তাবিত control | Verification gate |
|---|---|---|---|
| Uninstaller recovery mutable `main` থেকে source আনতে পারে | আগের implementation reconciliation-এ direct-pipe fallback-এ mutable branch ব্যবহারের তথ্য; scoped deletion check আছে | High: versioned immutable source archive ও expected digest-এ recovery bind; identity verify না হলে fail closed | Tamper, stale version, network নেই, checksum mismatch, symlink/traversal ও scoped delete fixture |
| Startup password verifier salted single SHA-256 | `lib/auth.sh`, `lib/password.sh` ও installer phase-এ fast SHA-256; OS security boundary নয়, convenience gate | Medium: cost/version metadata-সহ portable slow KDF বাছাই; migration-এ legacy verify, credential নীরবে reset নয় | Legacy login, rehash, wrong password, corrupt record, interruption, performance limit ও Termux recovery test |
| GitHub Actions reference mutable version tag | Workflow-তে `actions/checkout@v5`-এর মতো `uses:`; tag সরানো যেতে পারে | High: third-party action reviewed full commit SHA-তে pin, readable version comment ও reviewed update PR | Policy linter non-SHA reject; workflow expression test ও exact commit-এ required workflow |
| Error-level ShellCheck CI-তে আছে; warning/info এখনো gate নয় | Local check stale update-lock recovery-তে recursive `return` error পেয়েছে; regression যোগ হয়েছে | Medium: warning triage, দরকারে সংকীর্ণ rationale-সহ suppression ও scoped coverage | নতুন actionable error নেই; suppression অল্প ও কারণসহ |
| Python dependency supply-chain review চলমান | কিছু build path hash-check requirement ব্যবহার করে; project-wide inventory/update policy মেলানো বাকি | Medium: runtime/build/test dependency inventory, আলাদা lock, সম্ভব হলে hash, license/advisory review | Clean locked install, mismatch rejection, inventory parity ও advisory record |
| Installer-এর বহু অংশে artifact identity/ownership ভাগ করা | কিছু package-এ manifest/checksum আছে; control সব path-এ সমান নয় | High: source, version, arch, digest, license, owner ও uninstall semantics-এর common manifest contract | Manifest schema, tamper/path test ও package-ভিত্তিক provenance report |

## কাজের ক্রম

### S0 — তাৎক্ষণিক CI guardrail

- Workflow action inventory করে first-party, third-party, reusable workflow, container ও downloaded tool আলাদা করা।
- Action verified full SHA-তে pin; update process ও action permission/job token scope review।
- **স্থানীয়ভাবে বাস্তবায়িত:** CI ShellCheck install করে production shell source-এ প্রতি file-এ `--shell=bash --severity=error` চালায়। Local baseline stale update-lock recovery-র invalid recursive `return` পেয়েছে ও ঠিক করেছে; `tests/update_transaction.sh` journal থাকুক/না থাকুক lock cleanup cover করে। Warning/info triage চলবে; broad suppression নেই।
- Warning/info baseline triage হলে threshold বাড়ানো; unavoidable suppression সংকীর্ণ ও ব্যাখ্যাসহ রাখা।
- Python dependency input ও hash/lock coverage inventory। Broad version bump বা unreviewed override audit-এর বিকল্প নয়।

### S1 — Immutable recovery ও artifact contract

- Uninstaller/recovery-তে mutable branch execution বাদ। Installed metadata বা user নির্বাচন থেকে version নিয়ে immutable archive fetch; trusted project manifest-এর SHA-256 verify করে path/syntax check-এর পরই চালানো।
- Trusted version/digest না থাকলে copyable recovery নির্দেশসহ থামা; `main` fallback নয়।
- Altered archive, root mismatch, stale hash, symlink, traversal, partial download ও network না থাকা—negative fixture যোগ।

### S2 — Credential verifier migration

- বাস্তব threat boundary নির্ধারণ: verifier accidental/shared terminal access ঠেকায়; Android app owner বা একই UID process থেকে file রক্ষা করে না।
- Termux-এ availability, parameter, memory/time cost, portability ও maintenance যাচাইয়ের পর KDF নির্বাচন। Algorithm, parameter, salt ও digest versioned record-এ; password log নয়।
- সম্ভব হলে constant-time comparison-এ পুরনো record সমর্থন; successful authentication-এর পরই rehash। Backup/recovery route নথিভুক্ত। User invalidate বা password নীরবে বদলানো যাবে না।

### S3 — সাধারণ permission ও evidence

- File mode, Termux/guest path boundary, socket permission, temp file, log, archive extraction, symlink race ও cleanup list review।
- Release asset-এর artifact provenance ও license inventory তৈরি।
- Security regression fixture aggregate runner ও exact-release CI-তে; Android/PRoot-এর সীমা documentation-এ।

## Security release gate

Source edit হলেই কোনো item `VERIFIED` নয়। Focused negative test, aggregate CI, exact-commit evidence, migration/recovery docs এবং user guest data/অন্য Termux package অক্ষত রাখার review চাই। High-severity unresolved finding stable পরবর্তী সংস্করণ release আটকাবে; গৃহীত residual risk-এ owner, mitigation ও review date থাকবে। Test pass করাতে security control দুর্বল করা যাবে না।
