---
title: "Changelog"
description: "Version history of ternux — the one-command installer, the public documentation set and the site."
lang: "en"
alt_url: "/bn/CHANGELOG.html"

---

Notable changes to ternux. Dates are ISO 8601.

---

## [Unreleased]

### Installer renderer rebuilt — stable frame, readable log

The installation dashboard is rendered by a new engine. On real devices the
previous one could wrap log lines through its own borders, repaint the whole
screen several times per second, and expand package-manager progress into
thousands of scrolling lines.

**Fixed**

- **Frame integrity.** The frame no longer writes into the terminal's last
  column, so the pending-wrap state is never armed and a log line can no longer
  shift every row that follows it.
- **Repaint storms.** The screen is cleared only when it opens, when the
  terminal genuinely changes size, and when it closes. Resize detection compares
  raw terminal measurements with the previous raw measurement — never with the
  clamped drawing size — and is polled at most once per second, with `SIGWINCH`
  short-circuiting the poll.
- **Size detection.** The window size is read from the kernel through
  `stty`/`tput` with descriptor fallbacks, so a phase running inside a pipeline
  can still measure the terminal. When no measurement is possible the frame
  stays fixed instead of thrashing.
- **Progress floods.** Carriage-return output from apt, dpkg, proot-distro and
  curl updates one row in place instead of scrolling the log window away.
- **Split lines.** Partial reads are buffered, so a slowly produced line is
  reassembled rather than printed in fragments.
- **Log window content.** The window is redrawn from a dedicated stream log, so
  timestamped diagnostic entries no longer appear between package lines.
- **Terminal state.** The scroll region and cursor are restored on every exit
  path, including `SIGINT` and `SIGTERM`.

**Changed**

- Output bursts are coalesced to a readable rate and the remainder is reported
  as `... +N more lines`. Errors, warnings and phase markers are never
  coalesced, and the complete stream is always written to the log file.
- Closing the installer reserves rows for a short recap — outcome, phase and log
  path — as ordinary scrollback text.
- A terminal that becomes too small drops cleanly to plain scrolling output
  instead of drawing a broken frame.
- The per-line render path no longer forks a subprocess; clipping, padding,
  colouring and the animated signature use shell builtins only.

**Added**

- `--ui auto|dashboard|plain|off`, `--plain`, and the `TERNUX_UI` environment
  variable. `--no-anim` now only freezes the animation instead of affecting
  layout, and `TERNUX_COLS`/`TERNUX_ROWS` force a geometry for reproducible
  transcripts.
- `tests/ui_render.py`, run in CI: the installer is executed inside a real
  pseudo-terminal and replayed through a VT100 emulator that asserts border
  integrity, bounded repaints, progress collapsing, and correct re-fitting after
  a resize.
- Documentation for the installer screen, its renderer modes and its logs in the
  installation guide, the CLI reference, the configuration reference and
  troubleshooting, in both languages.

### Professional bilingual documentation experience

- Rebuilt both landing pages in a refined terminal design with clearer hierarchy,
  responsive layouts, local fonts, stronger accessibility, concise installation
  choices, evidence boundaries, and workload cards that open upstream repositories.
- Replaced the flat documentation-chip shell with grouped sidebar navigation,
  filterable page index, breadcrumbs, generated local tables of contents,
  previous/next navigation, edit and feedback paths, mobile drawer behavior, print
  styles, and a consistent project footer.
- Added mirrored English/Bengali documentation hubs and the complete Bengali
  benchmark/evidence archive, including all 66 captured scene values and caveats.
- Centralized the bilingual information architecture in `_data/docs.yml`; added
  repository authoring maps, reciprocal language metadata, a complete sitemap,
  corrected canonical URL configuration, and professional contribution guidance.
- Preserved measured, observed, reported-build, and untested distinctions across
  both languages and all redesigned surfaces.

### Archival real-device guide and installer hardening

- Rebuilt the README as an evidence-led, archival guide: exact renderer,
  measured glmark2 scores and all observed FPS ranges, architecture and backend
  interpretation, verification/benchmark protocols, workloads, FAQ, thermal
  guidance, limitations, and explicit separation of measured, observed,
  build-only and untested claims.
- Added `docs/BENCHMARKS.md`, preserving all 66 captured OpenGL/OpenGL ES scene
  results, test conditions, anomalies, evidence matrix and reproduction steps.
- Added one-command and full download-review-run installation routes plus
  English and Bengali manual procedures. Review instructions now cover every
  executable installer component, not just the entry script.
- Hardened backend normalization/detection, Turnip archive selection and staged
  extraction, launcher argument/env handling, PulseAudio loopback configuration,
  locale/user persistence, repair aggregation, verification, resumability and
  scoped uninstall documentation.
- Standardized supported command JSON and shared fatal envelopes while
  documenting which lifecycle commands remain human-oriented.
- Expanded English/Bengali troubleshooting, configuration, architecture and CLI
  references; workload cards link directly to Blender, llama.cpp and
  stable-diffusion.cpp upstream repositories.

---

## [1.4.0] — 2026-08-17

### Animated installer dashboard

- Rebuilt the one-command installer frame as a persistent dashboard: a live
  device panel (model, Android, GPU, backend, memory), a fixed step progress
  bar, a framed scrolling log, and an animated copyright footer with a spinner.
- Borders now auto-fit the terminal and repaint on resize — including font or
  zoom changes and the on-screen keyboard — so log lines never wrap past the
  frame.
- Replaced the thin single-line frame with thicker double-line borders and
  clipped, color-coded log lines; the identity, progress and footer text is
  ellipsized instead of overflowing on narrow viewports.

## [1.3.1] — 2026-08-17

### Real-device installer recovery

- Replaced fragile human-output matching with one shared Debian-container probe.
  It understands PRoot-Distro 5's `list --quiet` interface, both current and
  legacy rootfs layouts, and older Alias/Status output, so an existing Debian
  container is reused instead of passed to `proot-distro install` again.
- Changed standalone bootstrap and fallback host-CLI acquisition from many
  independent raw-file requests to one validated source archive with bounded
  retries. The one-click route reuses that same extracted snapshot for bootstrap,
  host CLI and Debian guest companion installation.
- Removed the full-screen `termux-change-repo` dialog from the persistent install
  frame. Package setup keeps the user's current apt source and temporarily
  disables `pkg`'s all-mirror sweep; an unreachable source fails normally and can
  be changed manually before `--resume`.
- Fixed failed dashboard closure so it retains the actual failed phase and title
  instead of rewriting every error as `FAILED [11/11]`; only success advances
  the counter to the total.
- Preserved line-streamed logs, required-phase failure propagation, resumability,
  host/guest CLI verification, the 3–4 GB base and 10–12 GB complete estimates,
  and the visible Sobuj Miah installer identity.
- Added regression coverage for current/legacy PRoot-Distro layouts, existing
  Debian reuse, noninteractive repository handling, and a transiently failed but
  successfully retried standalone source-bundle download.

---

## [1.3.0] — 2026-08-15

### ternux CLI v1.3.0 — production modular CLI with documented JSON output

**Complete CLI redesign.** The CLI has been rebuilt from the ground up as a
thin dispatcher with self-contained command modules, proper help system and
consistent UX. Machine-readable JSON is available for the reporting commands
whose schemas are documented; interactive/lifecycle commands remain
human-oriented.

**New architecture:**
- `bin/ternux` is now a **thin dispatcher** (~80 lines): discovers commands
  via `tnx_cmd_*` function naming convention, lazy-loads libraries, handles
  global flags properly
- Every command function lives in its own library file (`lib/<name>.sh`)
- New `lib/help.sh` — centralized help system with per-command help functions
- New `lib/info.sh` — dedicated system information command module
- Command dispatch is **extensible**: adding a new command = add a
  `tnx_cmd_<name>()` function in a new `lib/<name>.sh` file

**Fixed UX bugs:**
- `ternux doctor --help` now shows doctor-specific help (was showing main help)
- `ternux profile --help` now shows profile subcommands properly
- `--help` after any command correctly dispatches to `tnx_help_<command>`
- Unknown commands now produce clear error messages with correct exit codes

**Standardized subcommand pattern:**
- Every command that takes subcommands validates them and shows usage on error
- Consistent `--help` handling at every level
- All commands return proper exit codes (0=success, 1=error)

**JSON output improvements:**
- `tnx_json_add_array()` with proper item escaping
- All JSON output uses consistent field naming (`snake_case`)
- Error JSON objects include `command`, `status: "error"`, and `reason` field
- JSON schemas documented in `share/templates/json-schema.md`

**New features added:**
- `ternux backend detect` — auto-detect the correct GPU backend
- `ternux update check` — check for updates without installing
- Proper `--version` flag on all command paths
- `TERNUX_QUIET` suppresses non-critical messages everywhere
- `TERNUX_VERBOSE` enables debug output consistently

**Refactored libraries:**
| Library | Lines | Status |
|---------|-------|--------|
| `bin/ternux` | ~80 | Thin dispatcher (was 532) |
| `lib/core.sh` | 239 | Shared foundation |
| `lib/help.sh` | 130 | **New** — centralized help |
| `lib/desktop.sh` | 168 | Self-contained lifecycle |
| `lib/doctor.sh` | 250 | Clean diagnostics + verify |
| `lib/backend.sh` | 95 | Backend management |
| `lib/benchmark.sh` | 164 | GPU benchmarks |
| `lib/info.sh` | 86 | **New** — system info |
| `lib/profile.sh` | 180 | Profile management |
| `lib/repair.sh` | 184 | Auto-fix engine |
| `lib/logs.sh` | 97 | Log management |
| `lib/update.sh` | 150 | Self-update |
| `lib/state.sh` | 86 | State queries |
| `lib/phases.sh` | 704 | Installation phases |

**Extensibility (plugin readiness):**
- Add a new command: create `lib/mycommand.sh` with `tnx_cmd_mycommand()`
- Add help: create `tnx_help_mycommand()` in `lib/help.sh`
- Command functions are auto-discovered via `declare -F`

**New documentation:**
- `docs/CLI.md` — complete CLI reference (every command, flag, and JSON schema)
- `share/ternux-completion.bash` — bash tab-completion for all commands

**CI/CD pipeline (new):**
- `.github/workflows/ci.yml` — ShellCheck, syntax check, 43 smoke tests, doc link check
- `.github/workflows/release.yml` — auto-GitHub-Release on `v*` tag
- `.github/dependabot.yml` — weekly GitHub Actions dependency updates

**Contributor tooling (new):**
- `.github/stale.yml` — 90-day stale issue auto-management
- `.github/FUNDING.yml` — GitHub Sponsors support
- Repository topics set: 14 discoverable tags on GitHub

**Repository metadata:**
- GitHub topics added: `termux`, `android`, `linux-desktop`, `gpu-acceleration`, `vulkan`, `zink`, `turnip`, `adreno`, `proot`, `xfce4`, `debian`, `no-root`, `cli`, `shell-script`
- README badges updated: CI status, release version, GitHub stars
- `.gitattributes` with proper line-ending rules

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
