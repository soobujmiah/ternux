---
title: "টার্নাক্স v3 Extension SDK"
description: "Ternux-owned extension-এর পরিকল্পিত manifest, permission, lifecycle, compatibility ও security contract।"
lang: "bn"
alt_url: "/docs/v3/EXTENSION-SDK.html"
---

## অবস্থা ও পরিধি

**অবস্থা: PLANNED; সাধারণ উদ্দেশ্যের Extension SDK বাস্তবায়িত নয়।** বর্তমান Ternux workload ও integration নিজস্ব manifest/evidence অনুযায়ী চলবে। এই নকশা ভবিষ্যৎ v3 extension boundary-এর জন্য; v2.0.1 আচরণ বদলায় না বা বর্তমান preview-কে qualify করে না।

Extension হলো Ternux-owned workload, compute backend, desktop integration বা Device Bridge adapter যোগ করার package। Manifest kernel isolation-এর প্রতিশ্রুতি দিতে পারবে না: guest/extension শেষ পর্যন্ত Termux app UID-তেই চলে। LAI ও অন্য unrelated repository/product Ternux scope-এর বাইরে, যতক্ষণ না owner নতুন সিদ্ধান্ত দেন।

## Package contract

প্রতিটি extension-এ versioned, schema-validated manifest থাকবে:

- স্থির extension ID, display name, publisher ও manifest schema version।
- Extension version, compatible Ternux API range, guest/profile শর্ত, CPU architecture, declared entry point।
- Immutable artifact URL বা repository identity, archive format, SHA-256 এবং থাকলে signing identity/key reference।
- License ID ও bundled notice, dependency, disk/resource estimate, upgrade/removal behavior।
- প্রতিটি permission-এর সহজ ভাষায় কারণসহ typed capability list।

Manager unknown required field, duplicate ID, incompatible API range, missing provenance, invalid digest, unsupported architecture এবং cycle-যুক্ত dependency reject করবে। Optional metadata কেবল schema-তে optional ঘোষিত থাকলেই উপেক্ষা করা যাবে।

## Permission ও execution boundary

Permission হবে explicit capability; arbitrary host path বা ambient environment variable নয়। Grant একটি extension, একটি guest/workload এবং ক্ষুদ্রতম resource-এ সীমিত হবে। উদাহরণ: নির্বাচিত guest-owned directory, brokered camera capture request, বা অনুমোদিত network operation। Host-device access point-of-use consent ও দৃশ্যমান denial/cancel path-সহ Ternux-owned broker দিয়ে হবে।

Unrestricted Termux home, arbitrary `/sdcard` mount, secret/environment scrape, নীরব privilege escalation ও root ধরে নেওয়া reject করতে হবে। Extension code Ternux-এর মতো একই Android app UID boundary-তে চলে; PRoot Termux app owner বা একই UID-এর process থেকে security sandbox নয়। কোনো manifest এর বিপরীত দাবি করতে পারবে না।

## Lifecycle ও compatibility

Manager staged lifecycle ব্যবহার করবে:

1. Extension code না চালিয়ে metadata discover।
2. Schema, compatibility, permission, provenance, license, architecture, free storage ও dependency যাচাই।
3. User-কে plan দেখানো; privileged broker action-এর আগে grant নেওয়া।
4. Private temporary path-এ download, signature/digest ও archive path safety verify; active version overwrite না করে stage।
5. সীমিত health check; atomic activate, অথবা আগের version ফিরিয়ে দেওয়া।
6. একই staged transaction-এ update। Remove কেবল extension-owned file সরাবে; user data থাকবে, যদি না user স্পষ্টভাবে remove করেন।

Extension minimum ও maximum compatible manager API জানাবে। Incompatible extension নীরবে install হবে না; recovery-তে mutable `main` source execute হবে না; অন্য extension-এর file মুছবে না। মাঝপথে install/update/remove হলে নিরাপদে resume বা rollback হতে হবে।

## Acceptance ও security test

SDK বা extension `VERIFIED` বলার আগে অন্তত পরীক্ষা করুন:

- Valid/invalid schema, duplicate ID, API mismatch, dependency cycle, architecture/space/guest অনুপযুক্ত হওয়া।
- Signature/checksum mismatch, altered metadata, traversal, absolute path, symlink escape, archive-root mismatch ও partial download।
- Permission grant/deny/revoke/cancel/timeout ও broker failure; deny/revoke-এর পর কোনো action না হওয়া।
- Interrupted lifecycle, failed health check, rollback, repeated idempotent operation এবং user data/অন্য guest অক্ষত থাকা।
- License/provenance দৃশ্যমানতা ও manager API version অনুযায়ী compatibility।

শুধু source থাকা বা package install হওয়া support claim-এর জন্য যথেষ্ট নয়। প্রতিটি qualification-এ exact Ternux commit, extension version/digest, device, guest, command, log ও limitation রাখুন। পূর্ণ matrix [v3 acceptance criteria](ACCEPTANCE-CRITERIA.html) ও [testing strategy](TESTING-STRATEGY.html)-তে।
