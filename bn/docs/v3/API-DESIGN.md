---
title: "টার্নাক্স v3 API design"
description: "Versioned local manager API, event stream, job model ও error contract।"
lang: "bn"
alt_url: "/docs/v3/API-DESIGN.html"
---

## API design

**অবস্থা: বাস্তবায়িত (read-only CLI ও explicit Unix-socket transport)।** `tx manager status`, `tx manager guests`, `tx manager displays` ও `tx manager capabilities` versioned JSON snapshot দেয়। Display snapshot guest-এর saved current display ও v3 target আলাদা করে, live socket/lock/server occupancy রেকর্ড করে, সম্ভব হলে এককভাবে মেলা active guest-এর saved assignment দেখায় এবং অমীমাংসিত ownership স্পষ্ট চিহ্নিত করে। এটি OS-level socket owner-এর প্রমাণ নয়। Display payload schema `1.3.0`; এতে per-guest read-only migration preview (`initialize`, `keep`, `move`) ও active session, occupied target, malformed registry বা profile-registry disagreement blocker থাকে। Preview সবসময় বলে execution unavailable; guest state বদলায় না। Lock-protected registry workspace ID, saved/target display, শেষ lifecycle ও update time রাখে। Snapshot saved display ও শেষ record lifecycle দেখায়। Socket ownership runtime observation, persisted claim নয়। অন্য manager payload `1.0.0`। Command session শুরু বা বদলায় না; native Termux-এ guest install ছাড়াই চলে। Browser loopback adapter read-only snapshot, সীমিত desktop start/stop এবং durable job-status endpoint দেয়। বৃহত্তর service-backed HTTP API, event stream, cancellation ও workload/device mutation এখনো design contract। Shared-core সিদ্ধান্ত [ADR-0004](ADR/0004-shared-manager-contract.html)-এ।

ঐচ্ছিক foreground socket service চালাতে `tx manager serve` দিন। প্রতি connection-এ newline-শেষ JSON request, v1 request envelope, সীমিত request/response এবং Linux peer credential check লাগে; এটি CLI core-এ শুধু চারটি বর্তমান read-only operation দেয়। Private socket directory mode `0700`, socket ও startup lock `0600`; Ctrl-C-তে service বন্ধ। Advisory lock একাধিক start-এ startup চলাকালে socket সরানো ঠেকায়। Python 3 কেবল service স্পষ্টভাবে চালালে প্রয়োজন (`pkg install python`)। Unix-socket service auto-start করে না, TCP/HTTP listener-ও খোলে না। পৃথক `tx control` process dashboard খোলা থাকা অবস্থায় শুধু `127.0.0.1`-এ temporary HTTP listener খোলে; snapshot ও typed desktop lifecycle route দেয় এবং Ctrl-C-তে বন্ধ হয়।

Direct CLI JSON snapshot-এর command-specific schema অপরিবর্তিত। JSON consumer `schema_version` ও `command` দেখে compatibility ঠিক করবে; service response correlation-এর জন্য `request_id` ফেরায়। Browser snapshot wrapper `schemas/control-center-snapshot-v1.schema.json`-এ এবং `GET /api/v1/snapshot`-এ। সীমিত action API নিচে; PUT/DELETE সমর্থিত নয়।

## Transport

Manager request-এ Unix-domain socket; প্রতি connection-এ একটি সীমিত JSON request/response। দীর্ঘ job newline-delimited JSON event ব্যবহার করে। Request envelope-এ exact schema version, UUIDv4 `request_id`, catalogued operation ও typed argument থাকবে। v1 schema শুধু চারটি বাস্তবায়িত read-only operation ও ফাঁকা argument মানে। অজানা operation/field বা ভুল argument fail closed। v1 minor response field বাড়াতে পারে; incompatible request change-এ নতুন major version দরকার।

বর্তমান `tx control` web client Unix socket প্রকাশ বা LAN-এ listen না করে শুধু `127.0.0.1`-এ temporary HTTP listener ব্যবহার করে। Lifecycle route install করা Ternux desktop profile-এর স্থির start/stop-এ সীমিত। ভবিষ্যৎ service-owned HTTP adapter-এ একই boundary বজায় থাকবে। `GET /v1/meta` বা সমতুল্য socket method-এ protocol version negotiate হয়। Unix socket-এর parent directory Termux UID-এর জন্য private (`0700`), socket `0600`; client নিজে socket path দিতে পারে না। Web mutation-এ short-lived session token, same-origin check ও CSRF সুরক্ষাও লাগে। User `tx manager serve` না চালানো পর্যন্ত service বন্ধ থাকবে।

## বর্তমান Control Center lifecycle route

বর্তমান source-এর browser adapter Unix-socket service ছাড়াও এই route দেয়:

- `POST /api/v1/guest-plans`-এ ঠিক `{"operation":"start|stop","guest":"NAME"}` পাঠালে state-bound plan ও short-lived confirmation token ফেরে।
- `POST /api/v1/guest-actions`-এ ঠিক `{"plan_id":"sha256:…","confirmation":"…","idempotency_key":"…"}` পাঠালে অপরিবর্তিত state যাচাই, job journal এবং শুধু স্থির `ternux start NAME` বা `ternux stop NAME` argv queue হয়।
- `GET /api/v1/jobs/{uuid}` bounded public job field ফেরে। Server restart হলে queued/running record `INTERRUPTED` করে retry-র আগে status check চায়।

সব action-এ current bearer token, exact local Origin ও `X-Ternux-CSRF` লাগে; JSON content type, body size ও duplicate JSON key যাচাই হয়। Guest-এর display migration দরকার হলে plan fail closed। Start manager CLI-কে দেয়; সেটি stale প্রমাণিত display socket সরাতে পারে, unsafe live conflict প্রত্যাখ্যান করে। Idempotency key local Termux UID-তে scoped এবং private job record-এ terminal job-এর 30 দিন পর্যন্ত থাকে। পুরনো terminal record prune হয়; active job থাকে। Private process lock concurrent Control Center instance-কে একে অন্যের running job ভুলভাবে reconcile করা থেকে ঠেকায়। এই slice-এ job cancel করা যায় না। Route-গুলো source-এ আছে, প্রত্যাহৃত v2.0.0 package-এ নয়।

## Resource-এর আকার

```json
{"id":"guest-opaque-id","name":"debian","distro":"debian","state":"RUNNING","display":1}
{"id":"job-opaque-id","kind":"guest.start","state":"RUNNING","phase":"desktop-ready","progress":0.8,"cancelable":false}
{"code":"GUEST_NOT_FOUND","message":"Guest 'name' is not installed.","retry":"install-or-select-another","request_id":"opaque-id"}
```

নাম হলো যাচাইকৃত label, filesystem path নয়। ID manager তৈরি করে। Timestamp UTC ISO 8601। সত্যনিষ্ঠ fraction দেওয়া না গেলে progress null হতে পারে। Log arbitrary path নয়, সীমিত reference দিয়ে আসে।

## প্রথম resource family

- `GET /v1/status`, `GET /v1/guests`, `GET /v1/guests/{id}`
- `POST /v1/guests/{id}/start`, `POST /v1/guests/{id}/stop`
- `GET /v1/jobs/{id}`, `GET /v1/jobs/{id}/events`, `POST /v1/jobs/{id}/cancel`
- `GET /v1/compute/capabilities`, `GET /v1/workloads`, `POST /v1/workloads/{id}/install`
- `GET /v1/device/grants`, `POST /v1/device/grants`, `DELETE /v1/device/grants/{id}`
- `GET /v1/diagnostics`, `POST /v1/diagnostics/repair-plan`

ভবিষ্যৎ প্রতিটি mutation-এ authenticated client ও operation-এ scoped idempotency key থাকবে। Service canonical request-এর digest রাখে: একই key/body আবার এলে পুরনো job/result ফেরে; ভিন্ন body-তে একই key দিলে `IDEMPOTENCY_CONFLICT`। Mutation side effect-এর আগে desired-state/idempotent ও journaled হবে। Delete শুধু শনাক্ত Ternux-owned record সরায়; guest/model data remove করতে আলাদা explicit endpoint ও exact preview plan-এ বাঁধা confirmation token লাগে।

Mutation যোগের আগে core-এ typed operation allowlist, input validation, authorization, execution ও result recording থাকতে হবে। Client menu/capability list বাস্তবায়িত operation থেকে তৈরি হবে, আলাদা parallel list নয়। Filesystem operation opaque resource ID বা স্পষ্ট Ternux-owned root-এর relative path নেবে; root resolve করে traversal, symlink substitution ও বাইরের path reject করবে। Mutation exact immutable plan preview করবে, তার সঙ্গে বাঁধা confirmation নেবে এবং recoverable progress record করবে। Optional service/GUI বন্ধ থাকলেও direct CLI status/recovery চলবে। Arbitrary shell text, caller environment map বা unrestricted filesystem path কোনো operation নেবে না।

## Request ও error schema

- [Request envelope v1 JSON schema](https://github.com/soobujmiah/ternux/blob/main/docs/v3/schemas/manager-request-v1.schema.json) সমর্থিত read-only call নির্ধারণ করে।
- [Workspace display snapshot v1 schema](https://github.com/soobujmiah/ternux/blob/main/docs/v3/schemas/manager-displays-v1.schema.json) current/target assignment, socket/lock/server occupancy ও migration flag দেখায়; workspace mutation চালু করে না।
- [Response envelope v1 JSON schema](https://github.com/soobujmiah/ternux/blob/main/docs/v3/schemas/manager-response-v1.schema.json) request-এর সঙ্গে reply মেলায় এবং ঠিক একটি result বা error দেয়।
- [Error object v1 JSON schema](https://github.com/soobujmiah/ternux/blob/main/docs/v3/schemas/manager-error-v1.schema.json) স্থির machine code, localized-client-ready message ও retry নির্দেশ দেয়।

`tests/manager_protocol.py` schema fixture পরীক্ষা করে; `tests/manager_service.py` বাস্তব Unix socket-এ malformed/oversized input, concurrent client, graceful shutdown, stale-socket recovery ও duplicate service refusal পরীক্ষা করে। সীমিত desktop HTTP lifecycle route `tests/control_center.py`-তে আছে। General service HTTP API, job event stream, cancellation, workload mutation বা native Android client বাস্তবায়িত—এমন দাবি নেই।

## Error ও compatibility

Error code স্থির machine ID। Client message localize করে। HTTP status (বা socket result class), error code, retryability ও request ID সবসময় থাকবে। API compatibility test current/previous minor client, malformed input, path traversal, duplicate request, service restart ও client disconnect cover করে।
