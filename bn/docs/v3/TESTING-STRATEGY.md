---
title: "টার্নাক্স v3 testing strategy"
description: "Shell module, distro profile, manager contract, device behavior ও release-এর স্তরভিত্তিক test plan।"
lang: "bn"
alt_url: "/docs/v3/TESTING-STRATEGY.html"
---

## উদ্দেশ্য

Test যে layer চালায়, evidence-ও সেই layer-এর আচরণই দেখাবে। Syntax check install success প্রমাণ করে না; CI guest fixture Android X11/audio/GPU প্রমাণ করে না; UI চালু হওয়া update recovery প্রমাণ করে না। প্রতিটি ফল environment ও evidence level-সহ report করতে হবে।

## Test layer

| Layer | Coverage | Environment/evidence |
|---|---|---|
| Static ও unit | Shell syntax, ShellCheck, গৃহীত হলে Python lint/type, schema, path/ownership helper, package-manager dispatch, input validation | Deterministic CI; network/device claim নয় |
| Contract | Manager request/response, state, idempotence, cancel, socket permission, malformed input ও schema compatibility | Isolated process fixture; exact protocol version |
| Component integration | Installer phase, source bootstrap, downloader/hash, update transaction, guest registry, display allocation ও audio/device broker | Temporary root ও injected failure; বাস্তব user data অক্ষত |
| Distro matrix | Bootstrap, lifecycle, package manager, resume, update/remove, প্রতি candidate desktop package | Pinned ARM64 rootfs বা record-করা repo snapshot; profile অনুযায়ী ফল |
| Clean-install qualification | Fresh Termux baseline, installer source, permission, distro creation ও recovery | Reference Android device; exact commit ও installer digest |
| Live desktop/device | X11, resize/move, keyboard, audio, graphics correctness, storage, camera/mic permission/cancel | প্রয়োজনমতো মানুষ দেখে পরীক্ষা করা device; measured/observed আলাদা |
| Release/supply chain | Source archive reproducibility, checksum, action pin, package content, signature/provenance ও docs link | Exact release commit, isolated signing, archived workflow evidence |
| Reliability | Repeated start/stop, interrupted download/install/update, low storage, network loss, stale process, Android kill/recovery | সীমিত, reversible scenario; আগে/পরে data check |

## Test সংগঠন

`tests/focused.sh` একমাত্র supported aggregate entry point থাকবে; subsystem অনুযায়ী suite ভাগ হবে। Developer phone-এ নিরাপদ হতে temporary root, destructive operation mock, fixture root বাধ্যতামূলক এবং শুধু নিজের তৈরি artifact cleanup চাই। Owner-এর app uninstall, existing guest delete বা real data overwrite করা যাবে না। Test pass/fail total ছাপাবে, failure-এ কার্যকর log রাখবে, এবং শুধু নিজের artifact পরিষ্কার করবে।

প্রস্তাবিত ভাগ:

- `tests/unit/`: parser, validator, hashing/manifest ও state transition।
- `tests/installer/`: bootstrap, phase resume, download fallback ও rollback।
- `tests/distro/`: recipe contract ও প্রতি profile manager dispatch।
- `tests/manager/`: socket/API, job, lifecycle, permission ও concurrent call।
- `tests/security/`: tamper, traversal, symlink, hostile manifest, mutable-source rejection ও credential migration।
- `tests/device/`: মানুষ চালাবে এমন script/evidence template; CI এগুলোকে pass বলতে পারবে না।

CI বা aggregate runner-এ না থাকা duplicate suite তৈরি না করে split ধীরে করুন।

## আবশ্যিক failure injection

প্রতিটি installer/update/remove state machine-এ অন্তত DNS failure, IPv4/IPv6 mismatch ও alternate-family retry, HTTP error, truncated archive, wrong digest/signature, storage কম, permission denial, প্রতিটি durable step-এর পর interruption, retry, rollback এবং দ্বিতীয়বার সফল idempotent run পরীক্ষা করুন। Destructive action-এর আগে allowlisted path set প্রমাণ করতে হবে।

Manager/service test-এ daemon অনুপস্থিত, stale PID, duplicate request, job চলাকালে service crash, cancellation race, unreadable log, malformed state, concurrent guest operation ও restart reconciliation থাকবে। Contract shared resource না বললে guest operation পৃথক থাকবে।

## Device evidence record

প্রতি reference-device test-এ রাখুন:

- Ternux commit ও installed source digest।
- Device model/SoC, Android build, Termux version, display/input/audio stack।
- Distro image/repo snapshot ও installed package version।
- Exact command/setup, starting state ও guest data inventory।
- Expected/actual result, exit status, time, প্রাসঙ্গিক log/screenshot এবং owner চোখে/কানে পরীক্ষা করেছেন কি না।
- Cleanup/final state; অন্য guest/user data অক্ষত থাকার প্রমাণ।

`VERIFIED` শুধু exact named scenario-তে ব্যবহার করুন। বড় claim-এ বড় matrix চাই। Maturity অনুযায়ী `SUPPORTED`, `EXPERIMENTAL`, `PLANNED`, `DEPRECATED`, `NOT TESTED` পৃথক রাখুন।

## Release gate

1. Exact commit-এ focused test ও aggregate runner pass।
2. Static, docs/link/parity ও workflow policy check pass।
3. নতুন profile-এর আগে চার v2 baseline distro regression matrix pass।
4. Reference Termux environment-এ user state না মুছে clean install এবং rollback/recovery pass।
5. Device GUI, audio, graphics, input ও Device Bridge claim-এর সুনির্দিষ্ট evidence থাকতে হবে; CI মানুষ/device test-এর বিকল্প নয়।
6. Release archive, checksum, source/tag identity, docs ও workflow evidence একই commit দেখাবে।

v3.0 test-infrastructure milestone সম্পন্ন বলতে suite সত্যিই ভাগ করা/স্পষ্টভাবে partitioned, aggregate execution deterministic, negative/recovery test CI-তে আবশ্যিক এবং clean release candidate-এর evidence record generated হতে হবে। এই নথি লক্ষ্য নির্ধারণ করে; বাস্তবায়ন সম্পন্ন বলে দাবি করে না।
