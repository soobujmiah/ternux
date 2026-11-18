---
title: "Ternux v<VERSION> ইনস্টলেশন নির্দেশিকার ছক"
description: "নির্দিষ্ট সংস্করণের Ternux release installation guide তৈরির পুনর্ব্যবহারযোগ্য তালিকা।"
lang: "bn"
alt_url: "/docs/release/templates/RELEASE-INSTALLATION-TEMPLATE.html"
---

**প্রকাশনা:** v<VERSION><br>
**Tag:** `v<VERSION>`<br>
**Tag commit:** `<FULL_COMMIT_SHA>`<br>
**প্রকাশের তারিখ:** `<YYYY-MM-DD>`<br>
**Artifact:** `<EXACT_FILENAME_OR_TAGGED_SOURCE_ARCHIVE>`<br>
**SHA-256:** `<PUBLISHED_SHA256>`

## প্রকাশনার পরিচয়

এই সংস্করণে কী আছে এবং এটি স্থিতিশীল, preview, না ঐতিহাসিক release—তা লিখুন।
এর অপরিবর্তনীয় tag ও release asset-এর লিংক দিন।

## পূর্বশর্ত ও সমর্থিত পরিবেশ

Android architecture/version, Termux-এর উৎস, প্রয়োজনীয় companion app,
storage/network, permission এবং সমর্থিত guest distribution লিখুন। যাচাইকৃত ও
পরীক্ষা না করা পরিবেশ আলাদা করে দেখান।

## এই নির্দিষ্ট সংস্করণ ইনস্টল

সংস্করণে pin করা command এবং যে নির্দিষ্ট archive/artifact চালানো হবে তা উল্লেখ
করুন। চলমান branch বা generic `latest` URL ব্যবহার করবেন না। নিরাপদ extraction,
checksum/signature যাচাই এবং একবারের setup ধাপ দিন।

```bash
# এই release artifact অনুযায়ী সংস্করণ-নির্দিষ্ট command দিন এবং যাচাই করুন।
```

## ইনস্টল যাচাই

Command ও প্রত্যাশিত output দিন। Source, package, guest এবং device verification
আলাদা করুন। CI ফলাফল physical-device support প্রমাণ করে না।

## পরিচিত সীমাবদ্ধতা

এই release-এর সীমাবদ্ধতা, maturity label ও সীমানা লিখুন। Hardware/device-এর
পরিধি এবং অসমর্থিত feature-ও উল্লেখ করুন।

## সমস্যা সমাধান ও recovery

Download/integrity ব্যর্থতা, মাঝপথে থেমে যাওয়া install, নিরাপদ resume, log,
repair এবং upgrade/downgrade নিয়ম দিন। কী মুছবেন বা overwrite করবেন না তাও লিখুন।

## নিরাপত্তা ও provenance

Source commit, tag, workflow run, artifact provenance, checksum/signing
fingerprint, security policy ও report করার ঠিকানা দিন। কোনো বিষয় যাচাই করা না
গেলে তা স্পষ্ট করে লিখুন।
