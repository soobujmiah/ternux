---
title: "ডকুমেন্টেশন"
description: "ইনস্টলেশনের পথ বেছে নিন, ternux নিরাপদে পরিচালনা করুন, আর্কিটেকচার দেখুন এবং পরীক্ষার সীমা না বাড়িয়ে device evidence মূল্যায়ন করুন।"
lang: "bn"
alt_url: "/docs/"
---

এই ডকুমেন্টেশন installer source tree অনুসারে নয়—সিদ্ধান্ত ও কাজ অনুসারে সাজানো।
প্রথমবার এলে নিচ থেকে একটি পথ বেছে নিন। কিছু ইতিমধ্যে নষ্ট হলে সরাসরি
[সমস্যা সমাধান](TROUBLESHOOTING.html)-এ যান।

## ইনস্টলেশনের পথ বেছে নিন

<div class="path-chooser">
  <div class="path-choice"><b>সবচেয়ে দ্রুত</b><strong>দ্রুত শুরু</strong><p>Hosted installer ব্যবহার করুন, desktop চালু করুন এবং renderer যাচাই করুন।</p></div>
  <div class="path-choice"><b>আগে দেখুন</b><strong>Clone ও inspect</strong><p>Repository pin করুন, প্রতিটি shell target পরীক্ষা করুন, তারপর local installer চালান।</p></div>
  <div class="path-choice"><b>সম্পূর্ণ নিয়ন্ত্রণ</b><strong>Manual setup</strong><p>Host, guest, graphics, audio ও launcher ধাপ নিজে সম্পন্ন করুন।</p></div>
</div>

<div class="doc-grid">
  <a class="doc-card" href="QUICK-START.html"><span class="doc-card__icon">01</span><strong>দ্রুত শুরু</strong><span>চালু ও যাচাইকৃত workspace পাওয়ার সংক্ষিপ্ততম পথ।</span></a>
  <a class="doc-card" href="INSTALLATION.html"><span class="doc-card__icon">02</span><strong>ইনস্টলেশন</strong><span>প্রয়োজনীয়তা, review-first route, phase, flag, update ও removal।</span></a>
  <a class="doc-card" href="MANUAL.html"><span class="doc-card__icon">03</span><strong>ম্যানুয়াল ইনস্টলেশন</strong><span>সম্পূর্ণ launcher behavior-সহ audit করা যায় এমন command-by-command setup।</span></a>
  <a class="doc-card" href="FAQ.html"><span class="doc-card__icon">?</span><strong>ইনস্টলের আগে</strong><span>Root, compatibility, storage, battery, privacy ও project limit।</span></a>
</div>

## Workspace পরিচালনা করুন

<div class="doc-grid">
  <a class="doc-card" href="USAGE.html"><span class="doc-card__icon">$</span><strong>দৈনন্দিন ব্যবহার</strong><span>Session চালু-বন্ধ, file management, workload ও backup।</span></a>
  <a class="doc-card" href="CONFIGURATION.html"><span class="doc-card__icon">{ }</span><strong>কনফিগারেশন</strong><span>Graphics backend, launch variable, audio, locale, font ও file location।</span></a>
  <a class="doc-card" href="TROUBLESHOOTING.html"><span class="doc-card__icon">!</span><strong>সমস্যা সমাধান</strong><span>লক্ষণভিত্তিক check, `ternux doctor`, নিরাপদ repair ও clean reinstall।</span></a>
  <a class="doc-card" href="CLI.html"><span class="doc-card__icon">--</span><strong>CLI রেফারেন্স</strong><span>প্রতিটি public command, option, status behavior ও নথিভুক্ত JSON surface।</span></a>
</div>

## System বুঝে নিন

<div class="doc-grid">
  <a class="doc-card" href="ARCHITECTURE.html"><span class="doc-card__icon">→</span><strong>আর্কিটেকচার</strong><span>Display, audio, filesystem, process, Zink/Turnip ও VirGL data path।</span></a>
  <a class="doc-card" href="BENCHMARKS.html"><span class="doc-card__icon">∿</span><strong>প্রমাণ ও বেঞ্চমার্ক</strong><span>সব captured scene value, caveat, boundary ও reproduction step।</span></a>
  <a class="doc-card" href="FAQ.html"><span class="doc-card__icon">?</span><strong>সাধারণ প্রশ্ন</strong><span>ternux কী support করে, কী রক্ষা করে এবং ইচ্ছাকৃতভাবে কী করে না—সরাসরি উত্তর।</span></a>
  <a class="doc-card" href="../CONTRIBUTING.html"><span class="doc-card__icon">+</span><strong>কনট্রিবিউটিং</strong><span>Code, documentation, translation, issue report বা নতুন device evidence দিন।</span></a>
</div>

## Claim সঠিকভাবে পড়ুন

ternux চারটি evidence level আলাদা রাখে। README, website, issue report এবং
benchmark submission—সবখানে এই vocabulary প্রযোজ্য।

<div class="evidence-key">
  <div><b>Measured</b><strong>সংরক্ষিত numeric output</strong><span>Preserved command, environment, score, FPS value বা অন্য সরাসরি measurement।</span></div>
  <div><b>Observed</b><strong>সরাসরি non-numeric behavior</strong><span>যেমন application-reported renderer বা নিশ্চিতভাবে কাজ করা path।</span></div>
  <div><b>Reported build</b><strong>সফল build report</strong><span>Compatibility evidence হিসেবে কার্যকর, কিন্তু runtime বা performance benchmark নয়।</span></div>
  <div><b>Untested</b><strong>কোনো result প্রতিষ্ঠিত নয়</strong><span>Affirmative compatibility বা performance claim ধরে নেওয়া যাবে না।</span></div>
</div>

> **বর্তমান evidence boundary:** প্রকাশিত graphics snapshot একটি Redmi Turbo 4
> Pro থেকে। সংরক্ষিত renderer ও glmark2-এর সব 66 scene value সেই device-এ কী
> ঘটেছে তা দেখায়—সব Android device কী দেবে তা নয়।

## Project ও support

- প্রকাশিত history-এর জন্য [পরিবর্তনলগ](../CHANGELOG.html) পড়ুন।
- Patch বা device result পাঠানোর আগে [কনট্রিবিউটিং](../CONTRIBUTING.html) পড়ুন।
- Vulnerability report-এর জন্য public issue নয়,
  [security policy](https://github.com/soobujmiah/ternux/security/policy) ব্যবহার করুন।
- Reproducible bug, documentation gap ও feature proposal-এর জন্য
  [GitHub issue](https://github.com/soobujmiah/ternux/issues/new/choose) খুলুন।
