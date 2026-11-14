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
  state ধরা যাবে না; 2026-11-14-এর live inventory-তে Debian, Ubuntu ও Alpine—তিনটিই READY ছিল।

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

বর্তমান source-এ native manager operation, foreground Unix-socket service,
confirmation-সহ desktop start/stop-যুক্ত loopback dashboard এবং journaled display
migration আছে। 2026-11-14-এ সব guest থামিয়ে reference device-এ migration করা হয়:
Debian `:1`-এ যায়, তারপর Debian, Ubuntu ও Alpine `:1/:2/:3`-এ READY হয়। অন্য
managed guest shared lifecycle lock ধরে রাখলে migration এখন planner-এ block হয়।
এটি এক device-এ একটি migration/restart-এর evidence; পূর্ণ clean install/update/
recovery/uninstall matrix নয়। Control Center backend-এ Ubuntu ও Alpine live
stop/start, এবং migration-এর পর Debian-এর live CLI restart evidence আছে; browser
rendered interaction এখনো যাচাই হয়নি। পূর্ণ Control Center, service supervision
ও workspace gate বাকি। বিস্তারিত
[implementation status](/bn/docs/project/IMPLEMENTATION-STATUS.html),
[current-state audit](https://github.com/soobujmiah/ternux/blob/main/docs/audit/CURRENT-STATE.md)
এবং [device verification](https://github.com/soobujmiah/ternux/blob/main/docs/audit/DEVICE-VERIFICATION.md)-এ আছে।

## পরবর্তী কাজ

Dependency-ordered implementation list [next actions](/bn/docs/project/NEXT-ACTIONS.html)-এ
আছে। সব বাধ্যতামূলক gate exact 2.x release candidate-এ pass না হওয়া পর্যন্ত
stable channel withdrawn থাকবে।
