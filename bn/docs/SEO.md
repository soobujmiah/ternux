---
title: "এসইও রেকর্ড"
description: "ternux-এর সার্চ-আবিষ্কারযোগ্যতা নিরীক্ষার রেকর্ড: লাইভ সাইটের অবস্থা, যাচাই করা মেটাডেটা, কী পরিবর্তন করা হয়েছে ও কী ইচ্ছাকৃতভাবে করা হয়নি।"
lang: "bn"
alt_url: "/docs/SEO.html"
---


| ক্ষেত্র | মান |
|---|---|
| **এসইও মান** | [soobujmiah SEO Standard v1](https://github.com/soobujmiah/soobujmiah.github.io/blob/main/docs/SEO_STANDARD.md) |
| **সর্বশেষ নিরীক্ষা** | ২০২৬-০৯-১৬ |
| **সাইটের অবস্থা** | `LIVE_SITE` — https://soobujmiah.github.io/ternux/ (GitHub Pages, Jekyll) |
| **সার্চ ইনটেন্ট** | Android-এ Linux ডেস্কটপ · Termux · Debian · root ছাড়া · ARM64 · Adreno / Zink / Turnip / Vulkan |
| **পরিচয় হাব** | https://soobujmiah.github.io/ (লেখক: সবুজ মিয়া) |

## নিরীক্ষার ফল (২০২৬-০৯-১৬)

| পরীক্ষা | ফল |
|---|---|
| `<title>`, description, canonical, `lang`, viewport, robots meta | পাস |
| `robots.txt`, `sitemap.xml` (EN + BN পৃষ্ঠা) | পাস |
| `hreflang` en / bn / x-default | পাস |
| Open Graph (title, description, url, image 1200×630 + alt, locale, site_name) | পাস |
| Twitter card | image ছিল; **title/description ছিল না → যোগ করা হয়েছে** |
| JSON-LD | পাস — `SoftwareApplication` (লেখক Person → পোর্টফোলিও), `BreadcrumbList` (পোর্টফোলিও → Ternux) |
| পোর্টফোলিও / GitHub সোর্স / ADT-তে ব্যাকলিংক | পাস |
| রিপোজিটরির বিবরণ, homepage, ১৪টি টপিক | পাস (শক্ত প্রযুক্তিগত ভিত্তি) |
| README-তে লেখক + পোর্টফোলিও লিংক | **ঘাটতি → যোগ করা হয়েছে** |
| ইনটেন্ট বাক্যাংশ (Linux desktop on Android, Debian on Android, Termux Linux desktop, no-root, ARM64 Linux on Android, GPU-accelerated) | আংশিক → README-তে একটি স্বাভাবিক বাক্য যোগ |

## যে পরিবর্তন করা হয়েছে

- `index.html`: `twitter:title`, `twitter:description` যোগ (বিদ্যমান OG ট্যাগের মানই ব্যবহৃত)।
- `README.md`: এসইও ব্যাজ; একটি সার্চ-ইনটেন্ট অনুচ্ছেদ; লেখক → পোর্টফোলিও লিংক; ADT-এর লিংক।
- GitHub টপিক: `linux-on-android`, `arm64`, `debian-on-android`, `termux-x11` যোগ।

## ইচ্ছাকৃতভাবে যা পরিবর্তন করা হয়নি

সাইটের লেআউট, লেখা, অ্যানিমেশন, ডক্স, দ্বিভাষিক জোড়া, sitemap, canonical, JSON-LD, রিপোজিটরির বিবরণ (আগে থেকেই সুনির্দিষ্ট)।
