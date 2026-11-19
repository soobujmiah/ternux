---
title: "টার্নাক্স v3 বাস্তবায়ন roadmap"
description: "নির্ভরতা অনুযায়ী v3 কাজের ধাপ ও release milestone-এর gate।"
lang: "bn"
alt_url: "/docs/v3/IMPLEMENTATION-ROADMAP.html"
---

## বাস্তবায়ন roadmap

**অবস্থা: বাস্তবায়ন চলছে।** v2.0.1 ও তার exact installation guide প্রকাশিত ও যাচাইকৃত। v2 স্থির। Phase 0 সম্পন্ন; Phase 1-এর contract ও security foundation সক্রিয়। ক্রম dependency-নির্ভর। Evidence record না হওয়া পর্যন্ত phase সম্পন্ন নয়; baseline ও device capacity না মাপা পর্যন্ত সময়সীমা প্রতিশ্রুতি নয়।

| Phase | পরিধি | সমাপ্তির gate |
|---|---|---|
| 0. Baseline | প্রকাশিত v2.0.1, repo, device state, সীমাবদ্ধতা | **সম্পন্ন:** exact release ও version-specific page যাচাই; evidence link, recovery/support boundary ও owner scope মিলানো |
| 1. Contract | component ownership, state, API, security, ADR, distro qualification, test plan ও APT feasibility | API schema ও threat review গৃহীত; ownership conflict নেই; measurable qualification/release gate |
| 2. Native core | guest registry, manager service, structured job, CLI parity | service ঐচ্ছিক; CLI offline-এ চলে; প্রতি-guest lifecycle idempotent |
| 3. Control Center | local UI, status, start/stop, log, diagnostics | loopback/socket security test, accessibility ও কম-resource idle profile |
| 4. Workspace | বহু-distro profile/recipe engine, selection flow, theme package | Debian/Ubuntu/Kali/Alpine-এ clean install/remove/update matrix; প্রতিটি নতুন profile আলাদা gate পাস করে |
| 5. Compute | capability registry, backend pack, resource policy | device-ভিত্তিক route probe, correctness, fallback, artifact/license ও rollback gate |
| 6. AI | Ternux-owned workload registry, runtime, model discovery ও job report | provenance, representative task correctness, memory/thermal/performance evidence; অন্য product-এর dependency নয় |
| 7. Device Bridge | অনুরোধভিত্তিক camera/mic/storage broker | permission, denial, cancel, file integrity, privacy ও per-device check |
| 8. Extension | manifest, permission grant, install/update/remove | malicious manifest, path, signature/hash, rollback ও uninstall fixture |
| 9. Release | docs/site, upgrade, stable package, support matrix | exact release commit-এ blocking gate green এবং evidence সংরক্ষিত |

## Version milestone

এগুলো evidence-নির্ভর milestone, delivery date নয়। কোনো milestone নিজে থেকে feature বা distro-কে support দেয় না; আলাদা প্রমাণ ও support decision লাগে। নামযুক্ত contract গ্রহণ না হওয়া পর্যন্ত কাজের ধাপ মেশানো যাবে না।

| Milestone | লক্ষ্য ও কাজ | নির্ভরতা | Acceptance gate | স্পষ্টভাবে scope-এর বাইরে |
|---|---|---|---|---|
| **V3.0 — Foundation** | component ownership, manager/API/state contract, installer modularization boundary, test layer, security threat model/remediation, distro qualification এবং APT feasibility decision গ্রহণ। v2.0.1 আচরণ ও চার-distro baseline অক্ষত রেখে v3 foundation। | প্রকাশিত v2.0.1; Phase 1 contract; বড় architecture decision-এ owner review। | Contract ও ADR সামঞ্জস্যপূর্ণ; প্রতিটি subsystem-এর owner ও test gate; recovery, credential, dependency/action pinning risk-এর গৃহীত plan; APT স্থগিত অথবা gated prototype plan; v2 regression pass। | Stable APT প্রকাশ, নতুন distro-র support claim, credential বদল, বড় installer rewrite বা সম্পূর্ণ v3 দাবি। |
| **V3.1 — Platform Expansion** | ঐচ্ছিক native manager, guest lifecycle/state, supervision/recovery, display allocation ও প্রথম Control Center workflow। একবারে একটি candidate profile পরীক্ষা/যোগ্য করা। | V3.0 contract; native-manager security review; installer ও guest ownership test। | Service বন্ধ থাকলেও CLI চলে; guest না থাকলেও manager কাজ করে; socket/API negative test pass; install/start/stop/restart/recovery/uninstall-এ অন্য guest ও user data অক্ষত; বিজ্ঞাপিত candidate পূর্ণ distro matrix pass করে। | Recipe-কে support বলা, host management-এ guest daemon বাধ্যতামূলক, systemd/kernel-container দাবি, বা সব candidate একসঙ্গে চালু। |
| **V3.2 — Compute and Workloads** | Capability registry, backend/resource policy, Ternux-owned AI/workload lifecycle, on-demand Device Bridge broker এবং permission-সহ Extension SDK prototype। | স্থিতিশীল manager contract; V3.1 lifecycle/job model; artifact ও permission schema। | Detection ও correctness আলাদা; artifact provenance, architecture, license ও digest verify; grant/deny/revoke/cancel pass; named hardware-এ device integration qualify; rollback/data-preservation fixture pass। | সীমাহীন host access, background camera/microphone, app label-কে accelerator proof ধরা, বা unrelated product integration। |
| **V3.3 — Ecosystem Maturity** | Developer API, automation, extension lifecycle/docs, বিস্তৃত device qualification, security remediation ও release/support process। আটটি qualified distro লক্ষ্য; দশটি stretch goal। APT feasibility gate pass হলেই আলাদা করে পুনর্বিবেচনা। | V3.1/V3.2-এর গৃহীত contract ও implementation; security/distro evidence; stable APT-তে স্পষ্ট owner decision। | Exact-commit CI, release provenance, upgrade/rollback/uninstall, support ownership, দ্বিভাষিক docs ও reference-device evidence pass; প্রতিটি supported distro পূর্ণ matrix pass। APT-এর সব gate পূরণ হলেই supported। | Fixed date, দশ distro promise, qualification কমানো বা অযোগ্য extension/backend/package channel প্রকাশ। |

নিচের phase-গুলো subsystem-এর ক্রম দেখায়; milestone-গুলো সেগুলোকে release-sized ফল হিসেবে ভাগ করে। বর্তমানে V3.0 foundation active। V3.1–V3.3 planned; তাদের gate এখনো সম্পূর্ণ নয়।

## পরিবর্তনের নিয়ম

প্রতিটি vertical slice-এ source, focused test, user behavior বদলালে CLI help/README/site entry point এবং প্রাসঙ্গিক architecture/living-state doc একসঙ্গে update হবে। Generated `.repo/` workflow দিয়ে বজায় থাকবে, হাতে edit নয়। Hardware-নির্ভর কাজ code-এ এগোতে পারে, তবে physical qualification `UNTESTED` বলেই থাকবে।

## Release channel

Experimental artifact-এর নাম, manifest ও documentation stable channel থেকে আলাদা। শুধু installer সফল হলেই backend বা distro promote হবে না। Publish-এর আগে exact source commit, artifact digest, workflow run, test device এবং limitation record হবে।
