---
title: "পরবর্তী সংস্করণের স্থাপত্য"
description: "বর্তমান সমর্থন থেকে পৃথক রেখে ভবিষ্যৎ স্থাপত্যের সম্ভাব্য দিকনির্দেশ।"
lang: "bn"
alt_url: "/docs/NEXT-ARCHITECTURE.html"
---

এটি সম্ভাব্য স্থাপত্যের দিকনির্দেশ—এখনকার প্রকাশিত সুবিধা বা release commitment
নয়। বর্তমান source-এ management ও Control Center-এর কিছু অংশ আছে; এগুলো পূর্ণ
platform-এর প্রমাণ নয়।

## নীতি

- **দাবির আগে প্রমাণ:** implementation, test evidence ও device qualification
  আলাদা করে দেখান।
- **সর্বনিম্ন কর্তৃত্ব:** host/guest সীমানা, সংবেদনশীল কাজের আগে স্পষ্ট সম্মতি,
  এবং স্থানীয় control surface-এ loopback সীমা।
- **পুনরুদ্ধারযোগ্যতা:** idempotent operation, প্রয়োজনমতো durable journal এবং
  নিরাপদ repair/remove পথ।
- **বহনযোগ্য সীমানা:** distro-ভিত্তিক setup স্পষ্ট profile-এর আড়ালে রাখুন;
  desktop recipe রক্ষণাবেক্ষণ না থাকলে arbitrary OCI image shell guest।
- **ঐচ্ছিক acceleration:** CPU baseline; target device-এ correctness, license ও
  recovery যাচাই না হওয়া পর্যন্ত GPU/NPU উপাদান opt-in।
- **সত্যনিষ্ঠ বিতরণ-অবস্থা:** package signing এবং দৃশ্যমান channel-health status
  আবশ্যক; repository অপ্রাপ্য থাকলে channel ব্যবহারযোগ্য নয়।

## সম্ভাব্য উপাদান

একটি স্থানীয় manager installed guest সমন্বয় করতে এবং mutation API বিবেচনার
আগে versioned read-only status interface দিতে পারে। Workspace স্তর guest পরিচয়,
display বরাদ্দ ও recovery state রাখতে পারে। Device bridge কেবল সীমিত Android
integration দিতে পারে, যেখানে ব্যবহারের সময় permission চাওয়া হবে। User model
weights bundle না করে পৃথক license-যুক্ত compute runtime extension হিসেবে রাখা যায়।

গ্রহণের আগে এসব দিকের threat modeling, compatibility review, দ্বিভাষিক operator
নির্দেশনা এবং স্বাধীন পরীক্ষা দরকার। [বাস্তবায়ন পরিকল্পনায়](next/IMPLEMENTATION-ROADMAP.html)
ধাপ ও evidence gate আছে; [প্রস্তাবগুলো](NEXT-PROPOSALS.html) এখনো review-এর জন্য।
