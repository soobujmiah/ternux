---
title: "নথি"
description: "ইনস্টলের পথ বেছে নিন, টার্নাক্স পরিচালনা করুন, নকশা বুঝুন এবং পরীক্ষার সীমা অতিক্রম না করে যন্ত্রের প্রমাণ যাচাই করুন।"
lang: "bn"
alt_url: "/docs/"
---

এই নথিগুলো ইনস্টলারের উৎস-কাঠামো নয়, ব্যবহারকারীর সিদ্ধান্ত ও কাজ অনুযায়ী
সাজানো। প্রথমবার এলে নিচের পথগুলোর একটি বেছে নিন। আগে থেকে কোনো সমস্যা থাকলে
সরাসরি [সমস্যা সমাধান](TROUBLESHOOTING.html)-এ যান।

> **প্রকাশনার অবস্থা:** v2.0.1 হলো প্রকাশিত source release। v2.0.0 release
> এবং stable Termux APT channel প্রত্যাহার করা হয়েছে; বর্তমানে
> `pkg install ternux` পাওয়া যায় না। v3 এখন নকশা ও বাস্তবায়নের পর্যায়ে,
> প্রকাশিত package নয়। [বর্তমান প্রকাশনার অবস্থা](project/RELEASE-STATUS.html) দেখুন।

## গেস্ট ব্যবস্থার সংক্ষিপ্ত পরিচয়

| v2-তে যাচাইকৃত ডেস্কটপ | অন্য নামযুক্ত বিন্যাস | পূর্বনির্ধারিত বিন্যাস |
|---|---|---|
| ডেবিয়ান, উবুন্টু, কালি লিনাক্স, আল্পাইন | আরও ১১টি; যোগ্যতা যাচাই হয়নি | ডেবিয়ান |

প্রতিটি নামযুক্ত বিন্যাসে সংশ্লিষ্ট প্যাকেজ পরিবারের জন্য আলাদা ডেস্কটপ
প্রস্তুতি রয়েছে। টার্নাক্সে ডেস্কটপ বিন্যাস না থাকলে সাধারণ ওসিআই ছবি কেবল
টার্মিনাল-গেস্ট হিসেবে চলে। [ইনস্টল ও গেস্ট বাছাই](INSTALLATION.html)
এবং [সংগ্রহশালার দ্বিতীয় সংস্করণের সমর্থন-তালিকা](https://github.com/soobujmiah/ternux/blob/main/docs/audit/FEATURE-MATRIX.md) দেখুন।

## ইনস্টলের পথ বেছে নিন

<div class="path-chooser">
  <div class="path-choice"><b>দ্রুততম</b><strong>দ্রুত শুরু</strong><p>ওয়েব থেকে ইনস্টলার চালান, ডেস্কটপ খুলুন এবং গ্রাফিক্স রেন্ডারার যাচাই করুন।</p></div>
  <div class="path-choice"><b>আগে পর্যালোচনা</b><strong>সংগ্রহস্থল নামিয়ে দেখুন</strong><p>সংগ্রহস্থলের নির্দিষ্ট সংস্করণ নিন, প্রতিটি শেল-লক্ষ্য যাচাই করুন, তারপর স্থানীয় ইনস্টলার চালান।</p></div>
  <div class="path-choice"><b>পূর্ণ নিয়ন্ত্রণ</b><strong>হাতে ইনস্টল</strong><p>হোস্ট, গেস্ট, গ্রাফিক্স, অডিও ও চালক তৈরির ধাপ নিজে সম্পন্ন করুন।</p></div>
</div>

<div class="doc-grid">
  <a class="doc-card" href="QUICK-START.html"><span class="doc-card__icon">01</span><strong>দ্রুত শুরু</strong><span>চালু ও যাচাইকৃত কর্মপরিসর পাওয়ার সবচেয়ে সংক্ষিপ্ত পথ।</span></a>
  <a class="doc-card" href="INSTALLATION.html"><span class="doc-card__icon">02</span><strong>ইনস্টল</strong><span>পূর্বশর্ত, আগে-পর্যালোচনার পথ, ধাপ, বিকল্প, হালনাগাদ ও অপসারণ।</span></a>
  <a class="doc-card" href="MANUAL.html"><span class="doc-card__icon">03</span><strong>হাতে ইনস্টল</strong><span>চালকের সব আচরণসহ যাচাইযোগ্য, কমান্ড-অনুযায়ী সম্পূর্ণ প্রস্তুতি।</span></a>
  <a class="doc-card" href="TERMUX-APT.html"><span class="doc-card__icon">এপিটি</span><strong>Termux প্যাকেজ চ্যানেল</strong><span>চ্যানেলের বর্তমান অবস্থা এবং কেন `pkg install ternux` এখন পাওয়া যায় না—দেখুন।</span></a>
  <a class="doc-card" href="FAQ.html"><span class="doc-card__icon">?</span><strong>ইনস্টলের আগে</strong><span>রুট, সামঞ্জস্য, জায়গা, ব্যাটারি, গোপনীয়তা ও প্রকল্পের সীমা।</span></a>
</div>

প্রসেসর ও ভলকান ব্যবহারকারীরা `llama.cpp` সরঞ্জামের জন্য ঐচ্ছিক [দ্রুত নির্দেশিকা](QUICK-START.html#ঐচ্ছিক-প্রসেসর-ও-ভলকান-দিয়ে-স্থানীয়-ভাষা-মডেল) দেখুন।
প্রকাশনা যাচাই ও হাতে ইনস্টলের বিস্তারিত [সংগ্রহশালার নির্দেশিকায়](https://github.com/soobujmiah/ternux/blob/main/bn/guides/llama-vulkan-extension.md)
আছে। অন্য কাজের সরঞ্জামের জন্য [ইনস্টল ও প্রকাশনা নির্দেশিকা](INSTALLATION.html)
দেখুন। ইনস্টলের পরে টার্মাক্স বা ডেবিয়ানে `ternux guides` চালালেও এই সংযোগগুলো পাবেন।

## কর্মপরিসর পরিচালনা

<div class="doc-grid">
  <a class="doc-card" href="USAGE.html"><span class="doc-card__icon">$</span><strong>দৈনন্দিন ব্যবহার</strong><span>সেশন চালু বা বন্ধ, ফাইল সামলানো, কাজের সরঞ্জাম চালানো ও নকল রাখা।</span></a>
  <a class="doc-card" href="WORKLOADS.html"><span class="doc-card__icon">+</span><strong>কাজের সমষ্টি</strong><span>ঐচ্ছিক কাজের সমষ্টিতে কী ইনস্টল হয় এবং কীভাবে ব্যবহার করবেন।</span></a>
  <a class="doc-card" href="BLENDER-MCP.html"><span class="doc-card__icon">৩-ডি</span><strong>ব্লেন্ডার গ্রাফিক্স এমসিপি</strong><span>কোডিং সহকারী যুক্ত করে মাপা পর্দাহীন গ্রাফিক্স-পথ ব্যবহার করুন।</span></a>
  <a class="doc-card" href="CONFIGURATION.html"><span class="doc-card__icon">{ }</span><strong>বিন্যাস</strong><span>গ্রাফিক্স পদ্ধতি, চালনার চলক, অডিও, ভাষা, হরফ ও ফাইলের অবস্থান।</span></a>
  <a class="doc-card" href="GRAPHICS-PERSISTENCE.html"><span class="doc-card__icon">জিপিইউ</span><strong>গ্রাফিক্স চালু রাখা</strong><span>প্যাকেজ হালনাগাদের পরও গ্রাফিক্স চালক সচল রাখুন।</span></a>
  <a class="doc-card" href="TROUBLESHOOTING.html"><span class="doc-card__icon">!</span><strong>সমস্যা সমাধান</strong><span>লক্ষণ ধরে যাচাই, `ternux doctor`, নিরাপদ মেরামত ও পরিষ্কার করে পুনরায় ইনস্টল।</span></a>
  <a class="doc-card" href="CLI.html"><span class="doc-card__icon">--</span><strong>কমান্ড-লাইন নির্দেশিকা</strong><span>প্রকাশ্য প্রতিটি কমান্ড, বিকল্প, অবস্থা-সংক্রান্ত আচরণ ও নথিভুক্ত জেসন ফল।</span></a>
</div>

## ব্যবস্থা বুঝুন

<div class="doc-grid">
  <a class="doc-card" href="ARCHITECTURE.html"><span class="doc-card__icon">→</span><strong>ব্যবস্থার নকশা</strong><span>পর্দা, অডিও, ফাইলব্যবস্থা, প্রক্রিয়া, জিঙ্ক/টার্নিপ ও ভিরজিএলের পথ অনুসরণ করুন।</span></a>
  <a class="doc-card" href="V3-ARCHITECTURE.html"><span class="doc-card__icon">৩</span><strong>তৃতীয় সংস্করণের নকশা</strong><span>নিজস্ব নিয়ন্ত্রণকেন্দ্র, কর্মপরিসর, গণনা, কৃত্রিম বুদ্ধিমত্তা, যন্ত্র-সংযোগ, নিরাপত্তা ও গ্রহণযোগ্যতার নকশা পড়ুন।</span></a>
  <a class="doc-card" href="project/PROJECT-ROADMAP.html"><span class="doc-card__icon">→</span><strong>প্রকল্পের অবস্থা</strong><span>বর্তমান বাস্তবায়ন, প্রকাশনা, যন্ত্রের প্রমাণ, বকেয়া কাজ, সীমা ও পরবর্তী পদক্ষেপ দেখুন।</span></a>
  <a class="doc-card" href="release/V2-RELEASE-REPORT.html"><span class="doc-card__icon">২</span><strong>প্রকাশনা ও বর্তমান নিরীক্ষা</strong><span>মূল প্রকাশনা এবং বর্তমান প্যাকেজ, উৎস, ওয়েবসাইট ও যন্ত্রের চিত্র আলাদা করে দেখুন।</span></a>
  <a class="doc-card" href="V2-RELEASE-READINESS.html"><span class="doc-card__icon">২</span><strong>দ্বিতীয় সংস্করণের প্রস্তুতি</strong><span>চারটি v2 ডেস্কটপ প্রোফাইল, ভিন্ন পরীক্ষার গভীরতা, বর্তমান প্রকাশনা-শর্ত ও তারিখযুক্ত যন্ত্র-প্রমাণ দেখুন।</span></a>
  <a class="doc-card" href="ACCELERATOR-RELEASE-PLAN.html"><span class="doc-card__icon">এনপিইউ</span><strong>ত্বরণ-সরঞ্জাম প্রকাশনা পরিকল্পনা</strong><span>প্রসেসর, গ্রাফিক্স, এইচটিপি ও কিউএনএন-এর বর্তমান শর্ত ও স্থগিত কাজ।</span></a>
  <a class="doc-card" href="BENCHMARKS.html"><span class="doc-card__icon">∿</span><strong>প্রমাণ ও কর্মদক্ষতা পরীক্ষা</strong><span>সংরক্ষিত দৃশ্যমান মান, সতর্কতা, সীমা ও পুনরাবৃত্তির ধাপ দেখুন।</span></a>
  <a class="doc-card" href="FAQ.html"><span class="doc-card__icon">?</span><strong>সাধারণ প্রশ্ন</strong><span>টার্নাক্স কী সমর্থন করে, কী সুরক্ষিত রাখে এবং ইচ্ছাকৃতভাবে কী করে না—তার সরাসরি উত্তর।</span></a>
  <a class="doc-card" href="../CONTRIBUTING.html"><span class="doc-card__icon">+</span><strong>অবদান</strong><span>কোড, নথি, অনুবাদ, সমস্যার প্রতিবেদন বা নতুন যন্ত্রের প্রমাণ জমা দিন।</span></a>
</div>

## দাবির প্রমাণ বুঝুন

টার্নাক্স প্রমাণের চারটি স্তর আলাদা রাখে। এই শব্দগুলো মূল পরিচিতি, ওয়েবসাইট,
সমস্যার প্রতিবেদন ও কর্মদক্ষতা পরীক্ষার জমায় প্রযোজ্য।

<div class="evidence-key">
  <div><b>পরিমাপ করা</b><strong>সংরক্ষিত সংখ্যাসূচক ফল</strong><span>সংরক্ষিত কমান্ড, পরিবেশ, নম্বর, প্রতি সেকেন্ডে দৃশ্যমান চিত্র বা সরাসরি মাপা অন্য মান।</span></div>
  <div><b>পর্যবেক্ষণ করা</b><strong>সরাসরি দেখা আচরণ</strong><span>যেমন, কোনো অ্যাপের দেখানো রেন্ডারার বা নিশ্চিতভাবে কাজ করা পথ।</span></div>
  <div><b>তৈরির প্রতিবেদন</b><strong>সফল তৈরির নথি</strong><span>সামঞ্জস্য যাচাইয়ে সহায়ক, তবে চালনার ফল বা কর্মদক্ষতা পরীক্ষা নয়।</span></div>
  <div><b>পরীক্ষা হয়নি</b><strong>ফল প্রতিষ্ঠিত নয়</strong><span>সামঞ্জস্য বা কর্মদক্ষতা সম্পর্কে ইতিবাচক দাবি ধরে নেওয়া যাবে না।</span></div>
</div>

> **বর্তমান প্রমাণের সীমা:** প্রকাশিত গ্রাফিক্সের চিত্র একটি রেডমি টার্বো ৪ প্রো
> থেকে নেওয়া। সংরক্ষিত রেন্ডারার এবং `glmark2`-এর ৬৬টি দৃশ্যের মান ওই যন্ত্রে
> কী ঘটেছে তা দেখায়; সব অ্যান্ড্রয়েড যন্ত্রে কী হবে তা নয়।

## প্রকল্প ও সহায়তা

- প্রকাশিত ইতিহাস জানতে [পরিবর্তনলগ](../CHANGELOG.html) পড়ুন।
- সংশোধন বা যন্ত্রের ফল পাঠানোর আগে [অবদান নির্দেশিকা](../CONTRIBUTING.html) পড়ুন।
- দুর্বলতার প্রতিবেদন প্রকাশ্য সমস্যায় না দিয়ে
  [নিরাপত্তা নীতি](https://github.com/soobujmiah/ternux/security/policy) ব্যবহার করুন।
- পুনরুৎপাদনযোগ্য ত্রুটি, নথির ঘাটতি ও নতুন বৈশিষ্ট্যের প্রস্তাবের জন্য
  [গিটহাব সমস্যা-পাতা](https://github.com/soobujmiah/ternux/issues/new/choose) খুলুন।
