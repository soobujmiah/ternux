---
title: "Contributing"
description: "Contribute code, documentation, Bengali translations, reproducible bug reports, or carefully classified device evidence to ternux."
lang: "en"
alt_url: "/bn/CONTRIBUTING.html"
---

Thank you for improving ternux. Useful contributions include code, tests,
documentation, Bengali translation, reproducible bug reports, and device evidence.
Small, focused changes are easier to review than unrelated changes bundled together.

## Before you start

- Follow the [Contributor Covenant](https://github.com/soobujmiah/ternux/blob/main/CODE_OF_CONDUCT.md).
- Search [open issues](https://github.com/soobujmiah/ternux/issues) and pull
  requests before duplicating work.
- Use the [security policy](https://github.com/soobujmiah/ternux/security/policy)
  for suspected vulnerabilities. Do not publish exploit details in an issue.
- Read the [documentation overview](https://soobujmiah.github.io/ternux/docs/)
  and [architecture guide](https://soobujmiah.github.io/ternux/docs/ARCHITECTURE.html)
  before changing installer boundaries or graphics behavior.

## Ways to contribute

### Report a reproducible bug

Use the [bug report template](https://github.com/soobujmiah/ternux/issues/new/choose).
Include:

1. phone model, Android version, architecture, and Termux source;
2. ternux version or exact commit;
3. selected profile and public backend (`zink` or `virgl`);
4. the command you ran and the complete relevant output;
5. `ternux doctor` output, with private paths or tokens redacted;
6. the smallest repeatable sequence that triggers the problem.

Check [Troubleshooting](https://soobujmiah.github.io/ternux/docs/TROUBLESHOOTING.html)
first. Screenshots can supplement text output, but should not replace it.

### Submit device evidence

Use the device report template and classify each result correctly:

- **Measured** — captured numeric output such as score, FPS, time, memory, or tokens/s.
- **Observed** — direct non-numeric output such as an application-reported renderer.
- **Reported build** — a build completed, but runtime performance is not established.
- **Untested** — no affirmative result is available.

For benchmark submissions, record the command, commit/version, renderer and backend,
resolution or model, thermal/power conditions, all repetitions, and raw output. Never
submit only the best run. Follow the
[evidence protocol](https://soobujmiah.github.io/ternux/docs/BENCHMARKS.html).

### Contribute code or tests

Changes to `install.sh`, `bin/ternux`, or `lib/*.sh` should:

- remain safe to rerun where the phase is intended to be idempotent;
- quote expansions and avoid evaluating untrusted input;
- preserve explicit backend names and state-file compatibility;
- keep human-readable output and documented JSON output truthful;
- include a focused regression for every corrected failure mode;
- avoid modifying Android system partitions or unrelated Termux state.

### Improve documentation or translation

English and Bengali have the same navigation and core technical coverage. A change
that affects user behavior is incomplete until both language paths are reconciled.
Translations should preserve commands, backend names, evidence values, warning
severity, and technical meaning; they do not need to imitate English sentence order.

## Development workflow

```bash
git clone https://github.com/soobujmiah/ternux.git
cd ternux
git checkout -b fix/short-description
```

Then:

1. make one coherent change;
2. add or update a focused test;
3. update English and Bengali documentation where behavior changes;
4. update `_data/docs.yml` if a documentation page or label changes;
5. run the validation commands below;
6. inspect `git diff` for generated files, secrets, and unrelated edits;
7. open a pull request using the repository template.

Write a clear commit subject in imperative form, such as
`Harden archive member validation`. Conventional prefixes are welcome but not
required; clarity matters more than a specific prefix scheme.

## Engineering standards

- **Shell:** use Bash deliberately, `local` variables inside functions, quoted
  expansions, explicit failure handling, and no backtick command substitution.
- **Input:** validate paths, archive members, identifiers, flags, and external data
  before use.
- **State:** write atomically where practical and keep repair/update paths compatible
  with documented state.
- **JSON:** emit valid JSON to stdout; keep progress, warnings, and diagnostics out
  of the JSON stream.
- **Cleanup:** uninstall only owned and documented targets. Do not remove broad
  package sets, repositories, user projects, or unrelated configuration.
- **Claims:** do not convert a successful build into a runtime or performance claim.
- **Dependencies:** justify additions and prefer existing Termux/Debian tools.

## Documentation standards

The site navigation source is `_data/docs.yml`. English and Bengali lists must stay
in the same order and expose matching destinations. Core pages live in `docs/` and
`bn/docs/`; landing pages are `index.html` and `bn/index.html`.

When changing a user-facing behavior:

1. update the relevant English guide;
2. update its Bengali counterpart;
3. update CLI examples and structured-output notes;
4. keep `alt_url` front matter reciprocal;
5. update navigation, landing links, README maps, and sitemap if destinations change;
6. preserve explicit headings or fragments referenced from other pages.

Workload/tool cards must link to the upstream project repositories. Performance
language must retain the measured, observed, reported-build, and untested boundary.

## Validation

Run from the repository root:

```bash
bash tests/focused.sh
bats tests/smoke.bats
python3 tests/docs_check.py

set -e
for file in install.sh uninstall.sh bin/ternux lib/*.sh; do
  bash -n "$file"
done

node --check assets/js/docs.js
node --check assets/js/codecopy.js
git diff --check
```

Install [bats-core](https://github.com/bats-core/bats-core) first if `bats` is not
on `PATH`. For site work, also inspect keyboard navigation, narrow screens, reduced
motion, and print output; `tests/docs_check.py` covers the deterministic link,
front-matter, language-parity, and content-integrity checks.

Do not run destructive uninstall scenarios against your real environment. Use an
isolated test home/container or the existing mocked regressions.

## Repository map

```text
bin/ternux             public CLI entry point
lib/*.sh               installer and runtime modules
install.sh             hosted bootstrap entry point
uninstall.sh           scoped removal entry point
tests/                  focused and Bats regressions
docs/                   English technical documentation
bn/docs/                Bengali technical documentation
_data/docs.yml          mirrored site navigation model
_layouts/default.html   documentation application shell
assets/                 local CSS, JavaScript, fonts, and social image
share/templates/        schemas and managed templates
.github/                issue, pull-request, ownership, and automation policy
```

## Review, conduct, and license

Maintainers may ask for a smaller scope, raw evidence, a regression, or language
parity before merging. Review comments address the change, not the contributor.
By participating, you agree to follow the [Code of Conduct](https://github.com/soobujmiah/ternux/blob/main/CODE_OF_CONDUCT.md).
Contributions are accepted under the repository's [MIT License](https://github.com/soobujmiah/ternux/blob/main/LICENSE).
