---
title: "কনট্রিবিউটিং"
description: "ternux-এ code, documentation, English/Bengali translation, reproducible bug report অথবা সতর্কভাবে classified device evidence দিন।"
lang: "bn"
alt_url: "/CONTRIBUTING.html"
---

ternux উন্নত করার জন্য ধন্যবাদ। Code, test, documentation, English/Bengali
translation, reproducible bug report ও device evidence—সবই কার্যকর contribution।
সম্পর্কহীন অনেক পরিবর্তন একসাথে দেওয়ার চেয়ে ছোট, focused change review করা সহজ।

## শুরু করার আগে

- [Contributor Covenant](https://github.com/soobujmiah/ternux/blob/main/CODE_OF_CONDUCT.md) অনুসরণ করুন।
- একই কাজ আবার শুরু করার আগে [open issue](https://github.com/soobujmiah/ternux/issues)
  ও pull request খুঁজুন।
- সন্দেহজনক vulnerability-এর জন্য
  [security policy](https://github.com/soobujmiah/ternux/security/policy) ব্যবহার করুন।
  Issue-তে exploit detail প্রকাশ করবেন না।
- Installer boundary বা graphics behavior বদলানোর আগে
  [ডকুমেন্টেশন পরিচিতি](https://soobujmiah.github.io/ternux/bn/docs/) এবং
  [আর্কিটেকচার](https://soobujmiah.github.io/ternux/bn/docs/ARCHITECTURE.html) পড়ুন।

## অবদানের পথ

### Reproducible bug report করুন

[Bug report template](https://github.com/soobujmiah/ternux/issues/new/choose) ব্যবহার
করুন। অন্তর্ভুক্ত করুন:

1. ফোন model, Android version, architecture ও Termux source;
2. ternux version বা exact commit;
3. নির্বাচিত profile ও public backend (`zink` বা `virgl`);
4. চালানো command ও সম্পূর্ণ প্রাসঙ্গিক output;
5. private path বা token মুছে `ternux doctor` output;
6. problem trigger করা সবচেয়ে ছোট repeatable sequence।

আগে [সমস্যা সমাধান](https://soobujmiah.github.io/ternux/bn/docs/TROUBLESHOOTING.html)
দেখুন। Screenshot text output-কে সহায়তা করতে পারে, কিন্তু প্রতিস্থাপন করা উচিত নয়।

### Device evidence দিন

Device report template ব্যবহার করে প্রতিটি result সঠিকভাবে classify করুন:

- **Measured** — score, FPS, time, memory বা tokens/s-এর মতো captured numeric output।
- **Observed** — application-reported renderer-এর মতো সরাসরি non-numeric output।
- **Reported build** — build সম্পন্ন হয়েছে, কিন্তু runtime performance প্রতিষ্ঠিত নয়।
- **Untested** — কোনো affirmative result পাওয়া যায়নি।

Benchmark submission-এ command, commit/version, renderer ও backend, resolution বা
model, thermal/power condition, সব repetition এবং raw output record করুন। শুধু সেরা
run দেবেন না। [Evidence protocol](https://soobujmiah.github.io/ternux/bn/docs/BENCHMARKS.html)
অনুসরণ করুন।

### Code বা test দিন

`install.sh`, `bin/ternux` বা `lib/*.sh`-এর পরিবর্তন যেন:

- idempotent হওয়ার কথা যে phase-এর, সেখানে আবার চালানো নিরাপদ থাকে;
- expansion quote করে এবং untrusted input evaluate না করে;
- explicit backend name ও state-file compatibility ধরে রাখে;
- human-readable ও documented JSON output সত্য রাখে;
- প্রতিটি corrected failure mode-এর focused regression যোগ করে;
- Android system partition বা সম্পর্কহীন Termux state না বদলায়।

### Documentation বা translation উন্নত করুন

English ও বাংলা navigation এবং core technical coverage একই। User behavior বদলানো
কোনো change দুই ভাষার path reconcile না করা পর্যন্ত অসম্পূর্ণ। Translation-এ command,
backend name, evidence value, warning severity ও technical meaning অপরিবর্তিত রাখুন;
English sentence order নকল করার দরকার নেই।

## Development workflow

```bash
git clone https://github.com/soobujmiah/ternux.git
cd ternux
git checkout -b fix/short-description
```

তারপর:

1. একটি coherent change করুন;
2. focused test যোগ বা update করুন;
3. behavior বদলালে English ও বাংলা documentation update করুন;
4. documentation page বা label বদলালে `_data/docs.yml` update করুন;
5. নিচের validation command চালান;
6. generated file, secret ও সম্পর্কহীন edit-এর জন্য `git diff` দেখুন;
7. repository template ব্যবহার করে pull request খুলুন।

Imperative form-এ পরিষ্কার commit subject লিখুন, যেমন
`Harden archive member validation`। Conventional prefix ব্যবহার করা যায়, কিন্তু
নির্দিষ্ট prefix scheme-এর চেয়ে স্পষ্টতা গুরুত্বপূর্ণ।

## Engineering standard

- **Shell:** সচেতনভাবে Bash, function-এর ভেতরে `local` variable, quoted expansion,
  explicit failure handling এবং backtick command substitution নয়।
- **Input:** ব্যবহারের আগে path, archive member, identifier, flag ও external data
  validate করুন।
- **State:** সম্ভব হলে atomically লিখুন এবং documented state-এর সঙ্গে repair/update
  path compatible রাখুন।
- **JSON:** stdout-এ valid JSON দিন; JSON stream-এর বাইরে progress, warning ও
  diagnostic রাখুন।
- **Cleanup:** শুধু owned ও documented target uninstall করুন। Broad package set,
  repository, user project বা সম্পর্কহীন configuration মুছবেন না।
- **Claims:** successful build-কে runtime বা performance claim বানাবেন না।
- **Dependencies:** নতুন dependency-এর কারণ দেখান এবং existing Termux/Debian tool
  অগ্রাধিকার দিন।

## Documentation standard

Site navigation source হলো `_data/docs.yml`। English ও বাংলা list একই order-এ থাকবে
এবং matching destination দেখাবে। Core page `docs/` ও `bn/docs/`-এ; landing page
`index.html` ও `bn/index.html`।

User-facing behavior বদলালে:

1. প্রাসঙ্গিক English guide update করুন;
2. তার বাংলা counterpart update করুন;
3. CLI example ও structured-output note update করুন;
4. `alt_url` front matter reciprocal রাখুন;
5. destination বদলালে navigation, landing link, README map ও sitemap update করুন;
6. অন্য page থেকে referenced explicit heading বা fragment ধরে রাখুন।

Workload/tool card অবশ্যই upstream project repository-তে link করবে। Performance
ভাষায় measured, observed, reported-build ও untested boundary ধরে রাখতে হবে।

## Validation

Repository root থেকে চালান:

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

`bats` `PATH`-এ না থাকলে আগে [bats-core](https://github.com/bats-core/bats-core)
ইনস্টল করুন। Site change-এর জন্য keyboard navigation, narrow screen, reduced motion
ও print output হাতে inspect করুন; deterministic link, front matter, language parity
ও content-integrity check `tests/docs_check.py` করে।

নিজের real environment-এ destructive uninstall scenario চালাবেন না। Isolated test
home/container বা existing mocked regression ব্যবহার করুন।

## Repository map

```text
bin/ternux             public CLI entry point
lib/*.sh               installer ও runtime module
install.sh             hosted bootstrap entry point
uninstall.sh           scoped removal entry point
tests/                  focused ও Bats regression
docs/                   English technical documentation
bn/docs/                বাংলা technical documentation
_data/docs.yml          mirrored site navigation model
_layouts/default.html   documentation application shell
assets/                 local CSS, JavaScript, font ও social image
share/templates/        schema ও managed template
.github/                issue, pull-request, ownership ও automation policy
```

## Review, আচরণ ও license

Merge করার আগে maintainer ছোট scope, raw evidence, regression বা language parity
চাইতে পারেন। Review comment change নিয়ে—contributor নিয়ে নয়। অংশগ্রহণ করে আপনি
[আচরণবিধি](https://github.com/soobujmiah/ternux/blob/main/CODE_OF_CONDUCT.md)
মানতে সম্মত হন। Contribution repository-এর
[MIT License](https://github.com/soobujmiah/ternux/blob/main/LICENSE)-এর অধীনে গৃহীত হয়।
