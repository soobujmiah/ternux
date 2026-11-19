---
title: "টার্নাক্স v3 native Control Center"
description: "Termux-native Ternux Control Center-এর architecture ও lifecycle।"
lang: "bn"
alt_url: "/docs/v3/CONTROL-CENTER-ARCHITECTURE.html"
---

## Native Control Center

**অবস্থা: আংশিক বাস্তবায়ন।** `tx control` Termux থেকে mobile-first local browser dashboard চালু করে। এটি random loopback port, এক ঘণ্টা পর্যন্ত memory-তে থাকা bearer token, restrictive CSP এবং manager CLI snapshot ব্যবহার করে। স্থাপিত Ternux desktop profile-এর জন্য typed start/stop action আছে: client state-bound plan চায়, explicit confirmation দেখায়, same-origin ও CSRF check-সহ one-use confirmation পাঠায় এবং durable local job ID পায়। Adapter শুধু স্থির `start|stop GUEST` CLI argument চালায়; shell text, install/uninstall, generic OCI guest, path বা environment override গ্রহণ করে না। Durable job record-এর permission restrictive; service মাঝপথে বন্ধ হলে reconciliation-এর জন্য `INTERRUPTED` হয়। 30 দিনের বেশি terminal job prune হয়, active job থাকে। Private nonblocking host lock একটির বেশি dashboard service ঠেকায়, যাতে startup recovery অন্য চলমান instance-এর job interrupted না করে। Backend integration test আছে; বাস্তব device-browser action validation এখনো বাকি। Native Android UI, service supervision, cancellation, diagnostics ও সম্পূর্ণ panel set নেই। এই source feature প্রত্যাহার করা v2.0.0 package-এ ছিল না।

ঐচ্ছিক UI বা socket service বন্ধ হলেও manager CLI ব্যবহারযোগ্য। Python 3 শুধু `tx control` বা `tx manager serve` চালাতে প্রয়োজন। Native workspace display `:0` সংরক্ষণ করে; guest desktop আলাদা display পায়। [Display allocation ADR](ADR/0005-native-display-allocation.html) দেখুন।

## Process model

- Manager socket কেবল `tx manager serve` স্পষ্টভাবে চালালে foreground-এ চলে। এটি private `$PREFIX/var/lib/ternux/control/`-এ bind করে, TCP port খোলে না।
- `tx control` আলাদাভাবে `127.0.0.1` ও random port-এ অস্থায়ী HTTP server চালায়। Session key সর্বোচ্চ এক ঘণ্টা memory-তে থাকে এবং URL fragment-এ page-এ যায়; HTTP request বা referrer-এ নয়। Client fragment সঙ্গে সঙ্গে মুছে ফেলে; reload-এর জন্য key কেবল বর্তমান tab-এর session storage-এ রাখে। Tab বন্ধ হলে key মুছে যায়।
- Dashboard snapshot manager CLI-এর JSON পড়ে। Lifecycle mutation-এর আলাদা typed HTTP route আছে এবং socket service লাগবেই এমন নয়। Native Android UI ও service-backed web transport ভবিষ্যতের versioned API client।
- Service বন্ধ থাকলে CLI core সরাসরি ব্যবহার করতে পারে; recovery `txd`-এর উপর নির্ভরশীল নয়।

## Dashboard scope

বর্তমান screen manager health, installed guest, সক্রিয় desktop assignment, display conflict, executable নয় এমন migration preview, device qualification record ও copyable CLI command দেখায়। Desktop card ইনস্টল করা Ternux desktop চালু/বন্ধ করে এবং durable job poll করে। Qualification label record—live verification নয়। Graphics/audio, storage grant, optional workload, log, diagnostics, cancellation ও native Android UI ভবিষ্যতের কাজ।

## Local API ও browser safety

Browser client restrictive content-security policy, same-origin/Host check, স্বল্পমেয়াদি bearer token, wildcard CORS না থাকা এবং query-string token না থাকার নিয়ম মানে। Lifecycle POST route-এ bearer token, exact local Origin, CSRF header, typed input, state-bound plan, one-use confirmation ও idempotency key লাগে। Journal record শুধু Termux app UID-এর জন্য private। HTTP adapter loopback-only; job স্থির CLI argv চালায়, shell input নয়। Allowlist root-এর নিচে resolve না করে guest-প্রদত্ত path গ্রহণ করা যাবে না।

## ভবিষ্যৎ startup ও recovery

Termux প্রস্তুত হলে `txd` শুরু হবে; এটি desktop চালাবে না বা model load করবে না। Health check সীমিত, sensor poll করে না। UI crash হলে `txd` ও guest চলবে। `txd` crash হলে supervisor তা record করবে এবং `tx` inspect/repair করতে পারবে। Service update stage করে শুধু `txd` restart করে; Termux:X11, audio, IBus বা guest restart করে না।

API-র পূর্ণ রূপ [API design](API-DESIGN.html)-এ; authorization ও threat boundary [Security model](SECURITY-MODEL.html)-এ।
