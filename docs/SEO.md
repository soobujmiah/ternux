---
title: "SEO record"
description: "Current Ternux metadata, bilingual indexing and deployment notes."
lang: "en"
alt_url: "/bn/docs/SEO.html"
---

This is an internal source record and is not published in the documentation navigation or sitemap. The public site is built with Astro and hosted as a GitHub Pages project site at `https://soobujmiah.github.io/ternux/`.

The shared Astro page shell supplies a unique title and description, canonical URL, reciprocal English/Bengali `hreflang` links, Open Graph and Twitter card metadata, localized language, and SoftwareApplication or TechArticle JSON-LD. The build writes `robots.txt`, a sitemap with language alternates, and `.nojekyll` into the deployment artifact. Internal release-plan pages are marked `noindex` and omitted from the sitemap.

Google Search Console verification is not configured here because the owner confirmed this site is covered by the portfolio property's verification. Do not add a token without an explicit request.

Before switching GitHub Pages to GitHub Actions, confirm that the workflow build completes. The deployment workflow publishes only `dist/`; it does not publish repository source files.
