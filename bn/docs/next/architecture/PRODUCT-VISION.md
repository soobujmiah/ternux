---
title: "টার্নাক্স পরবর্তী সংস্করণ পণ্যের লক্ষ্য"
description: "টার্নাক্স পরবর্তী সংস্করণ-এর ব্যবহারকারীর ফল, পরিধি ও পরিমাপযোগ্য নীতিমালা।"
lang: "bn"
alt_url: "/docs/next/architecture/PRODUCT-VISION.html"
---

## পণ্যের লক্ষ্য

**অবস্থা: নকশা সম্পন্ন।** টার্নাক্স পরবর্তী সংস্করণ-এর লক্ষ্য সীমিত হার্ডওয়্যারেও Android ফোনকে নির্ভরযোগ্য Linux workstation করা, যার আচরণ বোঝা ও নিয়ন্ত্রণ করা সহজ। পণ্যটি হবে Termux-এ চলা একটি native control surface, তার অধীনে পৃথক Linux workspace, ঐচ্ছিক compute ও AI workload, এবং Android device-এ অনুমতিনির্ভর প্রবেশ।

## ব্যবহারকারীর প্রত্যাশিত ফল

- একাধিক Linux distro চালানো ও পরিচালনা করা, যাতে তাদের ফাইল, user, display, package ও lifecycle state একে অন্যের সঙ্গে মিশে না যায়।
- ছোট ও পূর্বানুমেয় command-এ shell বা desktop চালু করা; কোন guest চলছে দেখা এবং শুধু নির্বাচিত guest বন্ধ করা।
- পরিচিত Linux app-কে একই Ternux পরিচয়, ফোনে ব্যবহারযোগ্য window, keyboard input, storage, sound ও graphics-সহ ব্যবহার করা।
- ইচ্ছা হলে CPU, GPU বা নির্দিষ্ট device-এর NPU workload যোগ করা; model/runtime/storage-এর চাহিদা জানা; base workstation ক্ষতিগ্রস্ত না করে workload সরানো।
- camera ও microphone শুধু স্পষ্ট, যাচাইযোগ্য এবং ব্যবহারের মুহূর্তে দেওয়া অনুরোধে চালানো। Termux-এর shared-storage অনুমতি আগে থেকেই থাকলে তা ব্যবহার করা; অতিরিক্ত directory grant দৃশ্যমান ও সীমাবদ্ধ রাখা।
- এক জায়গা থেকে সমস্যার প্রমাণ ও recovery ধাপ পাওয়া, যেখানে guest বা model data মুছে ফেলা লাগবে না।

## পণ্যের ক্ষেত্র

| ক্ষেত্র | ব্যবহারকারীর ফল | আবশ্যিক সীমানা |
|---|---|---|
| Workspace | নামসহ distro shell/desktop ও file access | প্রতি guest-এর পৃথক পরিচয় ও lifecycle |
| Compute | CPU/GPU route শনাক্ত, নির্বাচন ও পরিদর্শন | capability প্রমাণ ও নিরাপদ fallback |
| AI | Ternux-এর নিজস্ব ঐচ্ছিক workload স্থাপন ও চালানো | Ternux runtime, artifact provenance ও resource limit-এর মালিক; অন্য product-এর dependency নয় |
| Device Bridge | প্রয়োজনমতো Android camera, mic ও storage | Termux API broker এবং সীমিত permission |
| Native Control Center | status, action ও log-এর এক dashboard/API | PRoot-এর বাইরে Termux host process |

## নকশার নীতি

1. **ডিফল্টে হালকা:** সীমিত background কাজ, idle-এ model load নয়, নিরবচ্ছিন্ন camera/microphone capture নয়, কম RAM-এও ভদ্র আচরণ।
2. **শুরু থেকেই নিরাপদ:** স্পষ্ট component boundary, ন্যূনতম permission, atomic update, checksum-যাচাই artifact এবং recoverable state transition।
3. **বোঝা সহজ:** স্থির command, স্পষ্ট distro নাম, ধাপে ধাপে তথ্য, copy করা যায় এমন উদাহরণ এবং পরবর্তী কাজসহ error message।
4. **দাবির আগে প্রমাণ:** শনাক্ত হওয়া, বাস্তবে চালানো, correctness এবং speed qualification আলাদা ফল।
5. **Ownership গোপন নয়:** data কোথায়, কোন service-এর মালিকানায়, grant কী খুলে দেয় এবং uninstall কী সরাবে—ব্যবহারকারী দেখতে পাবেন।

## পরবর্তী সংস্করণ-এ প্রতিশ্রুতি নয়

- Root access, kernel namespace, বা Android যে device node Termux-কে দেয়নি তাতে arbitrary access।
- সব device-এ GPU/NPU সমর্থন বা শুধু device name দেখে স্বয়ংক্রিয় নির্বাচন।
- প্রত্যেক guest-এ সব desktop app ঠিকমতো চলার প্রতিশ্রুতি।
- নীরবে model download, background inference, বা Android storage/sensor-এ guest-এর সীমাহীন প্রবেশ।

কোনো ফল release claim করার আগে কী প্রমাণ দরকার তা [acceptance criteria](ACCEPTANCE-CRITERIA.html)-তে দেখুন।
