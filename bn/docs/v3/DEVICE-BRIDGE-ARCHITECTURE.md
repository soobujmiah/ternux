---
title: "টার্নাক্স v3 Device Bridge"
description: "Android storage, camera, microphone ও Termux API-তে অনুমতিনির্ভর প্রবেশ।"
lang: "bn"
alt_url: "/docs/v3/DEVICE-BRIDGE-ARCHITECTURE.html"
---

## Device Bridge

**অবস্থা: নকশা সম্পন্ন।** Android service-এ প্রবেশ Termux:API ব্যবহার করা Termux-host broker দিয়ে হবে; guest-কে arbitrary Android device node দেওয়া হবে না। API চালানোর আগে broker companion app, permission, request scope ও target guest যাচাই করবে।

## Request flow

1. Guest app বা Ternux UI-তে user capture/sensor action শুরু করেন। Request operation ও destination জানায়; arbitrary host command দিতে পারে না।
2. Host broker fixed API allowlist-এর সঙ্গে operation মিলিয়ে দেখে এবং প্রয়োজন হলে ব্যবহারের সময় Android permission চায়।
3. Broker on-demand Termux:API চালায়, ফেরত file/data যাচাই করে এবং শুধু ফল নির্বাচিত guest path-এ দেয়।
4. Granted/denied/unavailable অবস্থা, capture সময়, output path ও cleanup ফল জানায়। Request শেষ বা cancel হলে microphone/camera session বন্ধ হয়।

## Storage grant

Termux-এর Android shared-storage permission আগে থেকেই থাকলে v2-র মতো canonical shared-storage directory guest `/sdcard`-এ default mount হবে। Ternux নীরবে Android permission চাইবে না। v3 উত্তরাধিকারসূত্রে পাওয়া permission state record করবে এবং অতিরিক্ত directory-র path-level grant যোগ করবে—owner, guest, access mode, created time ও revocation state-সহ। Extra directory ডিফল্টে read-only; write access নির্দিষ্ট directory-তে সীমিত। Revoke করলে নতুন access বন্ধ হবে এবং পরের guest start-এ সংশ্লিষ্ট mount সরবে; user file মোছা হবে না। Termux HOME ও private app data বিচ্ছিন্ন থাকবে।

## Camera ও microphone

Still-photo capture, live preview, webcam device emulation ও audio recording আলাদা capability। Still-photo API-কে live stream বলা যাবে না। Android বা Termux:API live stream দিতে না পারলে UI সেই সীমা জানিয়ে সমর্থিত capture বিকল্প দেখাবে। Microphone input user request-এ চালু হবে, দৃশ্যমানভাবে সক্রিয় থাকবে, সম্ভব হলে user-নির্ধারিত সময়ে সীমিত থাকবে এবং নির্বাচিত destination-এ save হবে। Broker background hot microphone রাখবে না।

## Failure ও privacy

Companion app অনুপস্থিত, permission revoke, dialog cancel, malformed response, storage কম এবং guest transfer error—প্রতিটির আলাদা result code থাকবে। Temporary media requestকারী job-এর private থাকবে এবং failure-এ মুছে যাবে। Diagnostic-এ media content, prompt ও raw Android identifier redacted হবে।
