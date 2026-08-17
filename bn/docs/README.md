# ternux documentation source

এই directory-তে published documentation-এর বাংলা source আছে। English mirror হলো
[`docs/`](../../docs/README.md); user-facing behavior, navigation order, warning,
command ও evidence boundary aligned রাখতে হবে।

**Published hub:** <https://soobujmiah.github.io/ternux/bn/docs/>

## Information architecture

| Section | Page |
|---|---|
| শুরু করুন | `QUICK-START.md`, `INSTALLATION.md`, `MANUAL.md` |
| পরিচালনা | `USAGE.md`, `CONFIGURATION.md`, `TROUBLESHOOTING.md` |
| বুঝে নিন | `ARCHITECTURE.md`, `BENCHMARKS.md`, `FAQ.md` |
| রেফারেন্স | `CLI.md`, root `CHANGELOG.md`, root `CONTRIBUTING.md` |

`index.md` হলো task-based published hub। `_data/docs.yml` canonical sidebar ও page
order model; English ও বাংলা list structurally identical রাখতে হবে।

## Authoring contract

1. প্রতিটি paired page-এ reciprocal `alt_url` front matter ব্যবহার করুন।
2. Front-matter title body-level `#` heading হিসেবে আবার লিখবেন না; site shell single page `<h1>` render করে।
3. Translation-এ command, identifier, numeric evidence ও warning severity ধরে রাখুন।
4. Result-কে **measured**, **observed**, **reported build** অথবা **untested** classify করুন।
5. Successful build বা renderer detection থেকে performance infer করবেন না।
6. Existing heading fragment স্থির রাখুন, নইলে প্রতিটি inbound link update করুন।
7. Workload/tool card upstream repository-তে link করুন।
8. প্রযোজ্য হলে landing page, README map, navigation data ও sitemap দুই ভাষায় update করুন।
9. [`CONTRIBUTING.md`](../CONTRIBUTING.md)-এ থাকা validation চালান।

Site shell `_layouts/default.html`; shared presentation ও behavior আছে
`assets/css/ternux.css`, `assets/js/docs.js` এবং `assets/js/codecopy.js`-এ। Local,
dependency-free implementation practical হলে external runtime asset যোগ করবেন না।
