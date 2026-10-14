# ternux documentation source

The root README and English/Bengali website home pages are the short install
and basic-usage entry points. This directory contains the repository's deep
guides and the corresponding published documentation pages. The Bengali mirror
is [`bn/docs/`](../bn/docs/README.md); behavior, commands and warnings must stay
aligned across the paired pages.

The GitHub repository is the canonical home for deep technical documentation.
The website landing page and root README provide the same compact install and
basic-usage path, then link here for details.

## Information architecture

| Section | Pages |
|---|---|
| Start here | `QUICK-START.md`, `INSTALLATION.md`, `MANUAL.md` |
| Repository deep guides | [`../guides/device-benchmark-evidence.md`](../guides/device-benchmark-evidence.md), [`../guides/llama-vulkan-extension.md`](../guides/llama-vulkan-extension.md), matching `../bn/guides/` pages (source repository only; not rendered on the website) |
| Operate | `USAGE.md`, `CONFIGURATION.md`, `TROUBLESHOOTING.md` |
| Understand | `ARCHITECTURE.md`, `BENCHMARKS.md`, `FAQ.md` |
| Reference | `CLI.md`, root `CHANGELOG.md`, root `CONTRIBUTING.md` |

`index.md` and `_data/docs.yml` support the published guide pages. Keep the
English and Bengali guide sets structurally paired. The top-level website must
stay a short install/use page and point here instead of restating these guides.

## Authoring contract

1. Use reciprocal `alt_url` front matter on every paired page.
2. Do not repeat the front-matter title as a body-level `#` heading; the site shell renders the single page `<h1>`.
3. Preserve commands, identifiers, numeric evidence, and warning severity in translation.
4. Classify results as **measured**, **observed**, **reported build**, or **untested**.
5. Never infer performance from a successful build or renderer detection alone.
6. Keep existing heading fragments stable, or update every inbound link.
7. Link workload/tool cards to the upstream repositories.
8. Update both landing pages, README maps, navigation data, and sitemap when relevant.
9. Run the validation listed in [`CONTRIBUTING.md`](../CONTRIBUTING.md).
10. Keep published benchmark pages to concise result summaries; put full device
    procedures, audit details, raw-log locations and dated experiment history in
    repository-only guides or experiment records, then link to that canonical
    detail instead of copying it into the site page.

## Build and documentation updates

CI automatically refreshes the machine-generated operational state in `.repo/`
after eligible builds on `main` (or a manual workflow dispatch). Pull-request
runs validate and report state but do not commit generated updates. CI cannot
infer human-authored explanations, decisions, limitations or reproduction
steps: update those canonical docs in the same change that alters the behavior.

The site shell is `_layouts/default.html`; shared presentation and behavior live in
`assets/css/ternux.css`, `assets/js/docs.js`, and `assets/js/codecopy.js`. Do not add
external runtime assets when a local, dependency-free implementation is practical.
