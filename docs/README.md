# ternux documentation source

This directory contains the English source for the published documentation.
The Bengali mirror is [`bn/docs/`](../bn/docs/README.md); user-facing behavior,
navigation order, warnings, commands, and evidence boundaries must stay aligned.

**Published hub:** <https://soobujmiah.github.io/ternux/docs/>

## Information architecture

| Section | Pages |
|---|---|
| Start here | `QUICK-START.md`, `INSTALLATION.md`, `MANUAL.md` |
| Repository deep guides | `../guides/`, `../bn/guides/` (source repository only; not rendered on the website) |
| Operate | `USAGE.md`, `CONFIGURATION.md`, `TROUBLESHOOTING.md` |
| Understand | `ARCHITECTURE.md`, `BENCHMARKS.md`, `FAQ.md` |
| Reference | `CLI.md`, root `CHANGELOG.md`, root `CONTRIBUTING.md` |

`QUICK-START.md` carries the website's short optional llama.cpp extension path.
The paired repository guides carry release verification and automatic/manual
installation detail, so the website does not duplicate the deep procedures.
`index.md` is the task-based published hub. `_data/docs.yml` is the canonical
sidebar and page-order model; English and Bengali lists must remain structurally
identical.

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

The site shell is `_layouts/default.html`; shared presentation and behavior live in
`assets/css/ternux.css`, `assets/js/docs.js`, and `assets/js/codecopy.js`. Do not add
external runtime assets when a local, dependency-free implementation is practical.
