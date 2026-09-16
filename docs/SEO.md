---
title: "SEO record"
description: "Ternux search-discoverability audit record: live-site status, verified metadata, changes made and deliberately not made."
lang: "en"
alt_url: "/bn/docs/SEO.html"
---


| Field | Value |
|---|---|
| **SEO standard** | [soobujmiah SEO Standard v1](https://github.com/soobujmiah/soobujmiah.github.io/blob/main/docs/SEO_STANDARD.md) |
| **Last audit** | 2026-09-16 |
| **Site status** | `LIVE_SITE` — https://soobujmiah.github.io/ternux/ (GitHub Pages, Jekyll) |
| **Search intent** | Linux desktop on Android · Termux · Debian · no-root · ARM64 · Adreno / Zink / Turnip / Vulkan |
| **Identity hub** | https://soobujmiah.github.io/ (author: Sobuj Miah) |

## Audit result (2026-09-16)

| Check | Result |
|---|---|
| `<title>`, description, canonical, `lang`, viewport, robots meta | PASS |
| `robots.txt`, `sitemap.xml` (EN + BN pages) | PASS |
| `hreflang` en / bn / x-default | PASS |
| Open Graph (title, description, url, image 1200×630 + alt, locale, site_name) | PASS |
| Twitter card | image present; **title/description were missing → added** |
| JSON-LD | PASS — `SoftwareApplication` (author Person → portfolio), `BreadcrumbList` (Portfolio → Ternux) |
| Backlink to portfolio / to GitHub source / to ADT | PASS |
| Repository description, homepage, 14 topics | PASS (strong technical base) |
| README author + portfolio link | **GAP → added** |
| Intent phrases (Linux desktop on Android, Debian on Android, Termux Linux desktop, no-root, ARM64 Linux on Android, GPU-accelerated) | partial → one natural sentence added to README |

## Changes made

- `index.html`: `twitter:title`, `twitter:description` added (values mirror existing OG tags).
- `README.md`: SEO badge; one search-intent paragraph; author → portfolio link; sibling link to ADT.
- GitHub topics: added `linux-on-android`, `arm64`, `debian-on-android`, `termux-x11`.

## Deliberately NOT changed

Site layout, copy, animations, docs, bilingual pairs, sitemap, canonical, JSON-LD, repository description (already precise).
