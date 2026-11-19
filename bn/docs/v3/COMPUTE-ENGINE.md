---
title: "টার্নাক্স v3 compute engine"
description: "CPU, Vulkan, GPU ও device NPU route শনাক্ত ও নিরাপদে নির্বাচনের নকশা।"
lang: "bn"
alt_url: "/docs/v3/COMPUTE-ENGINE.html"
---

## Compute engine

**অবস্থা: নকশা সম্পন্ন।** Capability শনাক্তকরণ, runtime স্থাপন, backend নির্বাচন, workload execution ও performance qualification আলাদা state। কোনো একটি থাকলেই অন্যটি প্রমাণ হয় না।

## Capability record

প্রতিটি route-এ backend ID, device/driver পরিচয়, architecture, runtime ও driver version, সমর্থিত operation, memory budget, provenance, শনাক্তকরণ পদ্ধতি, শেষ probe ফল এবং evidence level থাকবে। Export করা report-এ sensitive device identifier কমানো হবে। Device model string একা route-কে usable প্রমাণ করতে পারবে না।

## Selection chain

Graphics/compute অনুরোধে engine শুধু স্থাপিত ও compatible route, user-configurable ক্রমে পরীক্ষা করবে। Initialization ব্যর্থ হলে diagnostic দেবে এবং ঘোষিত fallback-এ যেতে পারে—যেমন সমর্থিত desktop graphics path-এ Turnip/Zink, VirGL, তারপর llvmpipe। নিজস্ব guest/device acceptance test পাস না করা পর্যন্ত বর্তমান v2 route compatibility baseline থাকবে। নির্বাচিত route session/job record-এ লেখা হবে এবং শুধু সেই session-এ app environment-এ প্রকাশ হবে; incompatible GPU-র জন্য global driver variable বসবে না।

## Runtime pack

Driver ও compute pack হবে versioned, signed বা checksum-pinned manifest; তাতে architecture, ABI, source, license inventory, install destination, conflict, post-install probe ও rollback নির্দেশ থাকবে। Install file stage করে activation-এর আগে validate করবে। Remove operation shared file জানাবে এবং অন্য pack-এর file মুছবে না।

## Resource policy

Job minimum RAM, disk, accelerator memory, thread count, প্রত্যাশিত সময়সীমা ও interrupt করা যাবে কি না জানাবে। Default Android ও desktop-এর জন্য resource রাখবে। Thermal বা memory pressure-এ engine সতর্ক বা defer করতে পারে; অপরিমাপিত device-এ performance claim করতে পারবে না। সমর্থিত হলে user CPU/GPU/NPU স্পষ্টভাবে বেছে নিতে পারবেন।

## Evidence level

- `detected`: device/driver শনাক্ত হয়েছে।
- `available`: runtime initialize করতে পারে।
- `executed`: নির্দিষ্ট operation সম্পন্ন হয়েছে।
- `correctness-verified`: output নির্দিষ্ট reference check পাস করেছে।
- `measured`: পুনরাবৃত্তিযোগ্য workload ও সংখ্যাসূচক ফল রেকর্ড হয়েছে।
- `qualified`: নির্দিষ্ট device class-এ release-এর correctness, stability, resource ও recovery gate পাস করেছে।

বিস্তারিত [acceptance criteria](ACCEPTANCE-CRITERIA.html)।
