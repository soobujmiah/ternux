---
title: "Ternux project roadmap"
description: "পরের v2-major platform release-এর বর্তমান roadmap।"
lang: "bn"
alt_url: "/docs/project/PROJECT-ROADMAP.html"
---

## Ternux project roadmap

**শেষ পর্যালোচনা:** 2026-11-14। **অবস্থা:** owner-নির্দেশিত সক্রিয় release plan।

## Release status

- Ternux v2.0.0 2026-11-14-এ withdrawn হয়েছে। GitHub Release object নেই
  এবং public stable APT index HTTP 404 দেয়। Provenance-এর জন্য `v2.0.0` source
  tag রাখা হয়েছে; এই tag আবার ব্যবহার করা যাবে না।
- পরের stable release v2 major-এই থাকবে। আগে v3 নামে পরিকল্পিত platform
  architecture ও acceptance gate এখন পরের 2.x release-এর বাধ্যতামূলক scope;
  আলাদা v3 stable release হবে না।
- Implementation ও exact-release gate শেষ না হওয়া পর্যন্ত stable APT channel
  withdrawn থাকবে। `/apt-rc` কেবল candidate testing-এর জন্য।
- Supported desktop guest হলো Debian, Ubuntu ও Alpine। Dated evidence-কে বর্তমান
  state ধরা যাবে না; 2026-11-14-এর live inventory-তে শুধু Debian ছিল।

## বাধ্যতামূলক platform scope

[Architecture dossier](/docs/v3/README.html)-এ detailed specification আছে। Dependency অনুযায়ী কাজ এগোবে, এবং প্রতিটি অংশ পরের v2-major stable release-এর gate:

1. **Native manager ও migration:** host-owned registry, structured job, CLI parity, optional supervised service, নিরাপদ display/session ownership, এবং working guest অক্ষত রেখে staged migration।
2. **Control Center:** সুরক্ষিত local status, start/stop, log, diagnostics, accessibility ও low-resource আচরণ; GUI না থাকলেও CLI ব্যবহারযোগ্য থাকবে।
3. **Workspace:** কোনো guest install শুরুর আগে নির্বাচিত সব guest-এর username ও shell সংগ্রহ; তারপর Debian, Ubuntu ও Alpine আলাদাভাবে install/update/recover/remove, user data ও unrelated guest অক্ষত রেখে।
4. **Compute ও AI:** capability registry, backend/workload ownership, CPU/GPU correctness, failure recovery, resource policy এবং documented interface দিয়ে LAI integration।
5. **Android Device Bridge:** camera, microphone ও scoped storage-এর permission-aware operation; deny/cancel/failure path-সহ।
6. **Extension:** যাচাইকৃত manifest, scoped permission, integrity/provenance check, rollback, repair ও নিরাপদ uninstall।
7. **Release integration:** package metadata, CLI help, bilingual docs/site, security review, exact-commit CI, clean device install এবং তিন guest-এর lifecycle evidence।

প্রতিটি phase reproducible acceptance evidence পেলে তবেই complete। Source implementation, build, installer completion বা এক device check দিয়ে পুরো platform qualified হয় না।

## বর্তমান implementation evidence

বর্তমান source-এ read-only native manager operation ও foreground Unix-socket service আছে। Graphical Control Center, service supervision ও staged migration অসম্পূর্ণ। Guest desktop এবং GPU/AI integration-এর অবস্থা আলাদা; live source ও নির্দিষ্ট device-এ পরীক্ষা করতে হবে। [Implementation status](/docs/project/IMPLEMENTATION-STATUS.html), [current-state audit](/docs/audit/CURRENT-STATE.html) এবং [device verification](/docs/audit/DEVICE-VERIFICATION.html) দেখুন।

## পরবর্তী কাজ

1. Architecture-এর প্রতিটি phase-এর implementation ও acceptance audit সম্পূর্ণ করে পরীক্ষিত component সংরক্ষণ।
2. Debian, Ubuntu ও Alpine-এর জন্য clean profile precollection, install/update/recovery/uninstall test শেষ করা।
3. বাকি Control Center, manager supervision, migration, Device Bridge ও extension gate implement করা।
4. নতুন 2.x release candidate-এর সব বাধ্যতামূলক gate pass না হওয়া পর্যন্ত stable channel withdrawn রাখা।
