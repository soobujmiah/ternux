---
title: "ADR-0004: Shared typed manager contract"
description: "CLI ও ভবিষ্যৎ client-এর জন্য native management behavior এক typed core-এ রাখা।"
lang: "bn"
alt_url: "/docs/next/architecture/ADR/0004-shared-manager-contract.html"
---

## ADR-0004: Shared typed manager contract

- **অবস্থা:** পরবর্তী সংস্করণ implementation-এর জন্য গৃহীত।
- **তারিখ:** 2026-11-13।
- **সিদ্ধান্তের মালিক:** Ternux project owner।

## প্রেক্ষাপট

Ternux পরবর্তী সংস্করণ-তে native CLI, ঐচ্ছিক Control Center service এবং পরে graphical client থাকবে। প্রতি client-এ validation/lifecycle আলাদা করলে guest state অসামঞ্জস্যপূর্ণ ও operation path অনিরাপদ হবে। Engineering pattern বোঝার জন্য আলাদা Android/PRoot management project audit করা হয়েছিল; source ও GPL-3.0-or-later license Ternux-এ নেওয়া হয়নি, Ternux Apache-2.0-ই থাকে। এই সিদ্ধান্ত একই pattern Ternux-এর জন্য স্বতন্ত্রভাবে নির্ধারণ করে।

Audit snapshot হলো 2026-11-13-এর TernuxX commit `419f910`। তার management API contract shared CLI/TUI/GUI operation এবং authenticated loopback-only Web adapter বর্ণনা করে। Reviewed source-এ typed operation dispatch (`lib/management_service.py`), implemented-operation catalog generation (`lib/management_catalog.py`), capability check (`lib/management_authorization.py`), request idempotency (`lib/management_request_store.py`) ও journaled recovery (`lib/operation_journal.py`) আছে। এগুলো research reference—Ternux dependency বা imported implementation নয়।

## সিদ্ধান্ত

- Manager operation native typed application core-এ থাকবে। CLI/ভবিষ্যৎ client narrow adapter দিয়ে core call করবে; client-এ presentation logic, দ্বিতীয় management policy নয়।
- অজানা operation reject হবে; provider কাজের আগে typed argument validate। Arbitrary shell string, caller environment map বা সীমাহীন filesystem path manager operation হবে না।
- ভবিষ্যৎ capability catalog/menu core-এ বাস্তবায়িত operation থেকে তৈরি। Provider, state source ও evidence age স্পষ্ট; অজানা state-কে installed/healthy বলা নয়।
- প্রাথমিক status ও guest inventory read-only, native এবং guest/Control Center service ছাড়াই ব্যবহারযোগ্য।
- Mutation চালুর আগে exact immutable plan preview, plan-এ বাঁধা confirmation, idempotent request ও interruption recovery-সহ durable operation record বাধ্যতামূলক।
- Local service user চাইলে তবেই চালু, ডিফল্টে বন্ধ। Web adapter loopback-only ও আলাদাভাবে authenticated; shell বা general-purpose file API নয়।

## ফলাফল

প্রথম implementation ছোট direct CLI slice হতে পারে, তবু ভবিষ্যৎ client-এর এক contract থাকবে। Service transport, authorization, request replay, job state ও mutation planning আলাদা gate; এই ADR এগুলো implement হয়েছে দাবি করে না। Ternux source/docs স্বাধীনভাবে লেখা এবং Apache-2.0 license-এই থাকবে।

## Research reference

- [Audit করা commit-এর TernuxX management API contract](https://github.com/soobujmiah/ternuxx/blob/419f910/docs/architecture/MANAGEMENT-API.md)
- [TernuxX shared management plan](https://github.com/soobujmiah/ternuxx/blob/419f910/docs/architecture/SHARED-MANAGEMENT-PLAN.md)
- [TernuxX typed dispatcher](https://github.com/soobujmiah/ternuxx/blob/419f910/lib/management_service.py)
- [TernuxX original-source license](https://github.com/soobujmiah/ternuxx/blob/419f910/LICENSE)
