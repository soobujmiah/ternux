---
title: "Changelog"
description: "Version history of ternux — the one-command installer, the public documentation set and the site."
lang: "en"
alt_url: "/bn/CHANGELOG.html"

---

# Changelog

Notable changes to ternux. Dates are ISO 8601.

---

## [1.3.0] — 2026-08-15

### ternux CLI v1.3.0 — production modular CLI with AI-native JSON

**The ternux CLI is born.** The monolithic `install.sh` is now accompanied by a
production-quality `ternux` command-line interface with modular shell libraries,
AI-native JSON output, and a consistent command structure for every operation.

**New CLI (`bin/ternux`):**
- `ternux install` — full installation (delegates to `install.sh`)
- `ternux start` / `stop` / `restart` — desktop lifecycle
- `ternux doctor` — comprehensive diagnostics
- `ternux repair` — auto-fix common issues
- `ternux verify` — installation completeness check
- `ternux benchmark` — GPU benchmarks (glmark2, vkmark)
- `ternux profile` — device profiling (show, save, load, list, compare)
- `ternux backend` — GPU backend management (show, set, detect)
- `ternux update` — self-update via git
- `ternux logs` — log management (show, tail, clear, list)
- `ternux info` — system information summary
- `ternux state` — installation state
- `ternux uninstall` — component removal

**AI-native JSON output (critical requirement):**
Every major command supports `--json` for machine-readable output:
- `ternux doctor --json` — structured diagnostics with issues and actions
- `ternux info --json` — full device profile
- `ternux benchmark --json` — benchmark scores and renderer
- `ternux profile --json` — device hardware snapshot
- `ternux verify --json` — check results
- `ternux backend --json` — GPU and backend information
- JSON schemas documented in `share/templates/json-schema.md`

**Modular library architecture:**
- `lib/core.sh` — shared I/O, JSON builder, state, logging, CLI framework
- `lib/detect.sh` — device detection and profiling (GPU, Vulkan, Android, etc.)
- `lib/backend.sh` — GPU backend management (zink-turnip, virgl)
- `lib/profile.sh` — profile save/load/compare
- `lib/doctor.sh` — diagnostics and verification
- `lib/repair.sh` — auto-fix for common issues
- `lib/benchmark.sh` — glmark2 and vkmark benchmarking
- `lib/update.sh` — self-update via git
- `lib/desktop.sh` — desktop lifecycle management
- `lib/logs.sh` — log viewing and management
- `lib/state.sh` — installation state queries

**Every command supports:**
- `--help` — command-specific help
- `--json` — AI-native structured output
- `--verbose` — detailed output
- `--quiet` — suppressed non-critical output

**Thin bootstrapper:**
- `install.sh` now detects the CLI and delegates doctor/status/help commands
- Full standalone functionality preserved (backward compatible)
- All 9 installation phases remain self-contained in `install.sh`

**Directory structure:**
```
bin/ternux          # Main CLI entry point
lib/*.sh            # 11 modular shell libraries
share/templates/    # JSON schema documentation
docs/               # Documentation (unchanged)
```

**State management:**
- State directory: `~/.local/share/ternux/`
- Tracks: version, backend, renderer, driver version, install phases,
  benchmark history, repair history

---

## [1.0.10] — 2026-08-15

### Installer v1.2.2 — perfectly-aligned live dashboard with full details

**Geometry engine (the box now lines up on every terminal):**
- New `padline()` measures ANSI-coloured lines by their VISIBLE width —
  measuring by bytes made every box row shorter than its border and cut
  escape codes mid-sequence, leaking garbage glyphs.
- CSI stripping moved from globs to sed: a bash glob `[0-9;]*m` means
  "one digit/semicolon then ANYTHING then m" (`*` is a free wildcard,
  not a quantifier) and was swallowing whole lines; sed's regex does it
  correctly.
- A UTF-8 locale is bootstrapped at startup so '✓' counts as one column
  everywhere; `_vtrunc()` does locale-independent character truncation
  (cut -c ignores the locale on some systems).
- Boxes carry right borders and a 2-column safety margin so nothing
  touches the terminal's auto-wrap edge.

**More dashboard details:**
- Device row: Android version, arch, model and RAM, captured in preflight.
- Phase clock: current-phase and total elapsed timers on the progress row
  (wide terminals), per-phase durations recorded and shown with ✓/· in
  the final summary.
- Live log tail is sanitised (carriage returns/control codes stripped) so
  apt/curl progress can never jump the cursor inside the panel.
- Frozen finish frame is now the same height as the live frame (no stale
  border leftovers) and prints the full checklist, device and signature.

**Verification:** rendered the raw PTY output with a real terminal
emulator — every row of every box measured exactly equal to its border,
zero escape leaks, zero spam; full mock install green; narrow-terminal
fallback, pipe purity and regressions A–D all pass.

---

## [1.0.9] — 2026-08-15

### Installer v1.2.1 — the author's name rides the whole install

- **Flowing rainbow signature.** A new sig engine renders "Sobuj Miah"
  letter by letter, each letter cycling through the six theme colours
  with a per-tick phase offset, so the colours flow through the name
  continuously.
- The signature lives in **every stage** of the install: the banner
  byline shimmers on arrival, the HUD panel carries a "✦ ternux by
  Sobuj Miah" row on every frame, the frozen finish frame keeps it, the
  compact status line appends a cycling-colour name on wide terminals,
  the completion celebration prints "built with ♥ by Sobuj Miah" as an
  animated flourish, and the final summary box signs off with it.
- All signature output degrades to plain text when piped or with
  NO_COLOR; compact view skips it on narrow terminals.

---

## [1.0.8] — 2026-08-15

### Installer v1.2.0 — HUD dashboard, glitch banner, summary panel

- **Glitch-in banner:** the ASCII wordmark now resolves from random
  glyphs in three animated passes (matrix-style reveal), each row in the
  green→cyan gradient; plain banner when piped.
- **Live HUD dashboard on every task:** a bordered panel redrawn in place
  — spinner, `[3/9]` counter, task name and elapsed time, an eased phase
  bar with shimmer lead, a sliding activity track, a nine-phase checklist
  (`✓` done / `⟳` running / `·` pending) and the live last line of the
  install log. Finished tasks freeze the panel with a `✓`/`✗` frame.
- **Boxed summary panel** at the end: backend, user, elapsed, launcher,
  start command and log path — plain text on narrow terminals.
- **Narrow-terminal fallback:** below 46 columns (typical phone width)
  everything degrades to the compact single-line view automatically.
- Cursor hide/show is now stateful (no stray escape codes in piped
  output); banner gradient is suppressed when piped; eased percent resets
  on fresh installs.
- Tested under a real PTY: boxed HUD frames, frozen finish box, summary
  panel, full mock install, narrow fallback, pipe purity, and all prior
  regressions (conffile cascade, sleep-breaking upgrade, broken dpkg).

---

## [1.0.7] — 2026-08-15

### Installer v1.1.4 — the whole toolchain, not just curl

- Real device follow-up: curl was upgraded (8.12.1 → 8.21.0) yet still
  failed to link — the missing symbol comes from **openssl**, so repairing
  curl alone can never fix it. repair_curl now upgrades the entire chain
  (`curl openssl openssl-tool libngtcp2 libnghttp3`) and, if curl still
  cannot link, points the user at a full `pkg upgrade -y`.
- Troubleshooting (EN + BN) documents the "already upgraded curl and it
  still fails" case with the deterministic fix.

---

## [1.0.6] — 2026-08-15

### Installer v1.1.3 + site: copy-safe commands and curl resilience

- **Copy can no longer include the `$` prompt.** On the landing page the
  prompt and blinking cursor are now drawn with CSS pseudo-elements, so
  selecting or copying the install line yields exactly the command. Copy
  buttons on guide blocks also strip display-only `$ ` prefixes per line.
  Fixes the reported `No command $ found` after pasting.
- **Broken curl no longer blocks anything.** After a partial upgrade curl
  can fail to link (`SSL_set_quic_tls_transport_params`). The installer now
  detects this in preflight and repairs it (`pkg install curl openssl`),
  checks the network with a wget fallback, and downloads the Turnip driver
  through a `download()` helper that falls back to wget. The site and every
  doc (README, Quick start, Installation, Manual — EN + BN) now show the
  `wget -qO- … | bash` one-liner as the curl-free path.
- Troubleshooting gains both sections: pasted-command `$` and curl
  CANNOT LINK (EN + BN), with table entries.

---

## [1.0.5] — 2026-08-15

### Installer v1.1.2 — animation through the whole install

- **Live status line during every task:** one persistent animated line —
  braille spinner, overall phase bar `[2/9] ██░░…`, sliding activity
  track and elapsed timer — redrawn on every tick for ALL wrapped tasks.
- **Every long task is now animated:** the Debian package install, user
  creation, Turnip driver staging, locale/fonts setup and all optional
  workloads (dev, llama.cpp, network, media, Blender) previously ran as
  plain text; they now run through the spinner with their output logged.
- **Animated phase headers:** each of the nine phases opens with two
  sweeping rules and a `[N/9]` title instead of a static `==>`.
- **Growing progress bars:** the per-phase bar now animates its fill from
  the previous phase to the current one (▓ shimmer lead, percent, count
  and elapsed time) instead of printing once.
- **Typed next steps** and a two-line completion celebration.
- All timings use bsleep(); `--no-anim`, `NO_COLOR=1` and piped runs stay
  plain text. Full-flow regression: mock end-to-end install under a real
  PTY passes with the celebration, launcher and aliases written; prior
  failure scenarios (conffile cascade, sleep-breaking upgrade, broken
  dpkg) still pass.

---

## [1.0.4] — 2026-08-15

### Installer v1.1.1 — spinner hardened against prefix replacement

- **Fixed upgrade-time error spam and hang risk.** While `pkg upgrade`
  replaces the Termux prefix, the spinner's `sleep` could fail mid-run
  (`CANNOT LINK EXECUTABLE "sleep": library "libpcre2-8.so" not found`,
  `/usr/bin/sleep: No such file or directory`), spamming the terminal and
  risking a busy loop. The installer now uses `bsleep()`: the real `sleep`
  with stderr silenced, falling back to a pure-bash `read -t` timeout on a
  self-owned FIFO — the spinner needs no binary the upgrade can remove.
- The FIFO is created lazily before any prefix-modifying step and removed
  on exit; every installer sleep now goes through `bsleep`.
- Regression-tested by replaying the exact failure (mock sleep breaking
  CANNOT-LINK then missing mid-upgrade under a real PTY): spinner kept
  animating, zero error spam, install completed green. Fallback pacing
  verified (1.5 s ±0.1 s) with `sleep` permanently broken.

---

## [1.0.3] — 2026-08-15

### Installer v1.1.0 — fixes and a real terminal theme

- **Fixed the openssl/conffile cascade.** `pkg upgrade` could hit a dpkg
  conffile prompt; with stdin closed it errors and leaves the package
  system broken, failing every later install. All apt operations now run
  non-interactively with force-confold/force-confdef, broken dpkg state is
  repaired before and after upgrades, and the same hardening is applied to
  every apt step inside the Debian container.
- **Fixed run() exit-code reporting.** Failures previously printed
  `rc=0`; the real exit code is now captured and shown.
- **Termux-X11 fallback.** If a mirror lacks `termux-x11-nightly`, the
  installer falls back to stable `termux-x11` instead of failing.
- **Terminal theme:** gradient banner, animated typed intro, braille
  spinner on long tasks, a custom `█▓░` progress bar with percentage and
  phase counter, success celebration, and a themed uninstaller banner.
  Disable with `--no-anim` / `TERNUX_NO_ANIM=1`; `NO_COLOR=1` still
  produces plain output.
- Regression-tested against the exact reported failure (mock pkg/dpkg
  replay): upgrade crash, repair, nightly-missing fallback, clean run,
  pre-broken state.

---

## [1.0.2] — 2026-08-15

### Copy-to-clipboard everywhere

- Every code block on the site now carries a terminal-style header bar with
  a copy button — documentation pages and landing-page command blocks alike.
- Inline `code` is now click-to-copy with a flash confirmation.
- New shared `assets/js/codecopy.js` (clipboard API + fallback for older
  webviews); runs on every page with no dependencies.

### Installer spotlight

- The one-command install box is now an animated centrepiece: rotating
  gradient ring, breathing glow, shine sweep, live pulse dot, version tag
  and a blinking cursor — all disabled under `prefers-reduced-motion`.
- The whole command line is click-to-copy, not just the button.

### Guide cross-links

- The landing guide banner and hero CTA now point to the Manual
  installation page; Installation and Quick start reference it as
  "Method 3 / পদ্ধতি ৩".

---

## [1.0.1] — 2026-08-15

### New: Manual installation page (EN + BN)

- **Manual installation** — every step by hand, command by command: apps,
  base packages, Debian, user + sudo, GPU driver (Zink/VirGL), audio/locale/
  fonts, the complete launcher file for both routes, shortcuts,
  phantom-killer, verification and uninstall.
- Linked from Installation and Quick start; added to doc-nav, sitemap and
  the landing docs cards.

### Responsiveness overhaul (all pages)

- **Inline commands now wrap** — a long inline command no longer stretches
  its paragraph (pages measured 1100+ px wide on a 360 px screen before).
- **Tables wrap naturally on desktop**; degrade to a scroll box on phones
  only when they must.
- **Sticky nav is a single row** — scrolls sideways on phones instead of
  stacking into 2–3 rows.
- **Landing guide cards fixed** — long commands no longer blow cards out to
  640 px; hero, buttons, step cards and switch tuned for mobile.
- All pages verified with Playwright at 360/768/1280/1920 px: zero
  horizontal overflow.

---

## [1.0.0] — 2026-08-15

### First public release — free and open

- **One-command installer released.** `install.sh` is now a public, MIT-licensed,
  single-file installer: preflight → base packages → Debian + Xfce4 → GPU driver
  (Zink/Turnip or VirGL) → audio/locale/fonts → launcher → shortcuts → optional
  workloads → phantom-killer advisory → verification.
- **Installer tooling:** `--yes`, `--user`, `--locale`, `--backend`, `--zsh`,
  workload flags (`--with-dev`, `--with-llm`, `--with-network`, `--with-media`,
  `--with-blender`, `--all`), `--doctor [--fix]`, `--resume`, `--status`,
  `--uninstall`, `--version`, `--help`.
- **Safety hardening:** driver archive validation (no links, no path
  traversal, whitelisted extraction only), SHA-256 recorded in install state,
  `visudo`-validated sudoers drop-in, idempotent phases, verified binaries.
- **Standalone `uninstall.sh`** with session stop, launcher/shortcut removal
  and container deletion.
- **Documentation rewritten from scratch, EN + BN:** Quick start, Installation
  (with the why of every phase), Usage, Configuration, Troubleshooting
  (symptom → cause → fix), Architecture and FAQ. Bangla mirrors for every
  page, including this changelog.
- **Site rebuilt:** landing page with a copyable one-command install box, GPU
  route switch, phase and design-decision sections; the "Pro coming soon"
  framing and private-installer language are gone — ternux is free software.
- **Removed:** the Pro page and the public/private documentation boundary.

---

## [0.x] — 2026-08-13 and earlier

Pre-release era: documentation-only site describing the private installer.
Superseded by 1.0.0, which publishes the installer itself under MIT.

---

*ternux — Copyright (c) 2026 Sobuj Miah ([@soobujmiah](https://github.com/soobujmiah)) · MIT*
