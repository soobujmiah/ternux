---
title: "এসইও ও indexing record"
description: "Ternux-এর বর্তমান metadata, দ্বিভাষিক indexing ও deployment তথ্য।"
lang: "bn"
alt_url: "/docs/SEO.html"
---

এটি internal source record; documentation navigation বা sitemap-এ প্রকাশিত নয়। Public site Astro দিয়ে build হয় এবং GitHub Pages project site `https://soobujmiah.github.io/ternux/`-এ host করা হয়।

Shared Astro page shell প্রতিটি page-এ আলাদা title ও description, canonical URL, reciprocal English/Bengali `hreflang`, Open Graph ও Twitter card metadata, localized language এবং SoftwareApplication বা TechArticle JSON-LD দেয়। Build deployment artifact-এ `robots.txt`, language alternate-সহ sitemap ও `.nojekyll` তৈরি করে। Internal release-plan page-এ `noindex` থাকে এবং sitemap থেকে বাদ যায়।

Owner নিশ্চিত করেছেন যে এই site portfolio property's verification-এর আওতায়; তাই এখানে Google Search Console verification token বসানো হয়নি। স্পষ্ট অনুরোধ ছাড়া token যোগ করবেন না।

GitHub Pages-কে GitHub Actions-এ বদলানোর আগে workflow build সম্পন্ন হয়েছে নিশ্চিত করুন। Deployment workflow শুধু `dist/` প্রকাশ করে; repository source প্রকাশ করে না।
