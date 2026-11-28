# Ternux V3 — remaining work (read this first in a new session)

Internal agent-handoff record, not user-facing documentation — intentionally
outside `docs/` so it is never swept into the bilingual docs_check pairing.
Delete this file once all items below are merged and their facts (if still
worth keeping) have been folded into `docs/project/` canonical docs, per
`AI_ASSISTANT.md`'s "keep one canonical record" rule.

Workstreams **02–17 of the original 18 are done and merged to main**
(PRs #326–335, #337, #339, #341, #343, #345, #347) — note that excludes
01, listed as item 7 below, not yet started. Before touching any area below, check whether
it already exists — grep the codebase and `git log --oneline -30`
first; `CHANGELOG.md` and recent merge commits are the fastest way to
confirm current state. What's left:

1. ~~**09. Adaptive Terminal UI**~~ — **done, PR #337.** Extended
   `tests/ui_render.py`'s PTY harness with a resize schedule and added
   keyboard open/close, rapid-resize, and orientation-change scenarios,
   plus checks that a resize is honored *before* `tnx_frame_close`'s own
   re-measure (a real Codex finding — the original checks only saw the
   close-time redraw). All scenarios pass against `lib/ui.sh` unchanged;
   testing found no real resize-handling defects (it also turned up a
   periodic resize poll independent of SIGWINCH, which is why nothing
   broke even with the signal trap disabled in a throwaway check).
2. ~~**10. Desktop and Window Management**~~ — **done, PR #339.** Added
   `tests/window_fit_lua_geometry.lua`: stubs devilspie2's injected
   globals and reloads `lib/ternux-window-fit.lua` fresh per scenario
   (centering, oversized-window clamping, idempotence, dialog/normal/
   other window types, narrow screens, a degenerate tiny-height edge
   case). All 7 cases pass against the script unchanged — confirms the
   "already works" assessment. A real Codex finding caught that the new
   test's `lua5.4` dependency was missing from a second workflow
   (`repo-knowledge-sync.yml`) that also runs `tests/focused.sh`; fixed.
3. ~~**11. Startup and Performance**~~ — **done, PR #341.** Moved the
   theme/icon/cursor/wallpaper `xfconf-query` calls in `lib/phases.sh`'s
   guest-setup sequence to run *before* `startxfce4 &` instead of after
   (xfconf-query only needs the D-Bus session already held, not a
   running xfwm4/xfdesktop) — fixes the first-boot flicker from stock
   XFCE to the Ternux look. The one piece that genuinely needs a live
   XFCE (the panel background-style loop, which enumerates xfce4-panel's
   own panel objects) stays post-ready. Added `SECONDS`-based timing
   instrumentation at the X11-ready/xfwm4-ready/panel-ready/desktop-ready
   boundaries without touching the existing timeout/failure logic. Full
   pin-refresh dance done (lib/ changed). Caught two real "apostrophe
   breaks the outer single-quoted `bash -c '...'`" bugs along the way —
   one in the new `lib/phases.sh` comment, one in my own new
   `tests/focused.sh` assertions — both found via direct `bash -n`
   reproduction before any PR was opened, not by CI.
4. ~~**13. Everyday Commands and Setup Guides**~~ — **done, PR #343.**
   Added `tx logs view` (the advanced live viewer) alongside the
   existing `tx logs desktop tail` mention in step 4, and a new step 8
   for `tx wallpaper list`/`set <id>` and `tx theme list`/
   `set Green|Crimson`. Every subcommand/flag was copy-pasted from the
   commands' own `--help` output. Pin-refresh dance done (`bin/`
   changed).
5. ~~**14/15/16. Fetch identity + monograms + 3-line layout**~~ —
   **done, PR #345.** Curated `native_logo_ids` from 17 to 10 (plus
   Sobuj): kept Android, redesigned the Workstation mark, dropped all
   managed distro logos from native rotation, added eight new
   tech/science marks (atom, circuit, DNA, rocket, satellite,
   telescope, radar, flask) with dense filled art matching Android's
   style — PRoot guests unaffected, every existing `set_logo()`/
   `compact_logo` case only had entries added, none deleted. Added the
   3-line "protected monogram region" layout for terminals too narrow
   even for the compact bracket tag. Found and fixed a real pre-existing
   bug: native rotation's `rockylinux` entry never matched `set_logo()`'s
   `rocky` case, silently falling back to the generic placeholder.
   `tests/terfetch.sh` existed with real assertions but was never
   actually wired into CI — fixed that too. Design was iterated live
   with the user (direct terminal rendering, then an ASCII mockup) before
   writing the final version.
6. ~~**17. CLI design system**~~ — **done, PR #347.** The color-token
   table and dashboard/log-viewer work were already done; auditing
   actual rendered output found a real, visible inconsistency:
   `tnx_ok`/`tnx_warn`/`tnx_fail`/`tnx_info` use a 2-space gap after the
   bracket tag, while `tnx_spin_run`'s `[TASK]`/`[DONE]`/`[FAIL]` and
   several other inline status lines across `lib/extension.sh`,
   `lib/phases.sh`, `bin/ternux`, `bin/ternux-guest`, and `install.sh`
   used only 1 space — visibly misaligning mixed output (e.g. during
   Termux package repair). Fixed every occurrence found by an
   exhaustive grep sweep; added a regression test.

   **Lesson for future PRs touching any pinned-content file**: editing
   `bin/ternux-guest`'s text changed its bytes and therefore its
   SHA-256, but `TERNUX_GUEST_CLI_SHA256` in `lib/core.sh` — the pin
   `tnx_install_guest_cli` verifies the downloaded companion against —
   was not updated to match. This produced a **100% deterministic**
   test failure (`tests/focused.sh`'s "guest CLI fallback downloads the
   immutable pinned file and verifies its digest") that was misdiagnosed
   as CI flakiness for 5 consecutive reruns before being properly
   debugged: reproduced the test's exact mock scenario locally, traced
   it to the SHA mismatch via direct output inspection. Any file with a
   pinned hash elsewhere in the codebase (`TERNUX_SOURCE_SHA256`,
   `TERNUX_GUEST_CLI_SHA256`, and similar) needs its pin re-verified —
   not just the usual `TERNUX_SOURCE_COMMIT`/`SHA256` bootstrap pair —
   whenever the pinned file's *content* changes, not just when doing
   the standard pin-refresh dance.
7. **01. Brand identity and graffiti logo** — mostly asset creation
   (logo files, optional terminal animation). Not started; no design
   decisions locked beyond the existing Green/Crimson theme palette.
8. **18. Integration and regression testing** — run the full
   `tests/focused.sh` + Bats suite + `tests/docs_check.py` +
   `tests/ui_render.py` after whichever of the above lands, not saved
   for one big pass at the end.

After the items above (= the rest of the original "Stage 3 —
Incremental implementation"), these stages are still fully pending:

- **Stage 4** — actual installation on a physical device.
- **Stage 5** — physical device testing.
- **Stage 6** — full regression, a complete bn/en documentation A-Z
  pass (including the still-unresolved `docs/audit/` + `docs/project/`
  Bengali-mirror scope question — ask the user, don't invent), final
  report, release.

## Workflow established over PRs #324-335 — follow it, don't reinvent

1. Branch off synced `main`.
2. Implement.
3. Verify locally: `shellcheck --shell=bash --severity=error` on every
   touched `lib/*.sh`, plus a targeted test that fits —
   `script -qec`-based PTY tests for anything interactive/raw-keypress
   (see `tests/workload_menu_pty.py`, `tests/logs_view_pty.py`), or
   `tests/ui_render.py`'s real pty+VT100 emulator for anything touching
   the installer dashboard.
4. **Pin-refresh dance if `lib/`, `bin/`, or `install.sh` changed at
   all** — not just `lib/core.sh`; `tests/bootstrap_source_sync.sh`
   diffs the whole tree against the pinned snapshot:
   - Commit, push.
   - Wait ~8s, then download the codeload archive for the exact
     *full* 40-character commit hash 2-3 times and confirm the
     SHA-256 is identical each time before trusting it (a short hash
     and the full hash of the *same* commit produce *different*
     archives — always use the full hash, and always re-verify
     stability rather than trusting one download).
   - Update `install.sh` + `lib/core.sh`, verify
     `bash tests/bootstrap_source_sync.sh`, commit, push.
   - Update the same commit hash across `README.md`, `bn/README.md`,
     `docs/{INSTALLATION,QUICK-START,TROUBLESHOOTING}.md`, the `bn/`
     mirrors of those three, and `src/pages/{index,bn/index}.astro`.
   - `npm run build`, verify `bash tests/documented_install_pin.sh`
     and `python3 tests/docs_check.py`, commit, push. Watch for
     `package-lock.json` reordering noise after `npm install` —
     `git checkout -- package-lock.json` if it shows up, it's not a
     real change.
5. `gh pr create`.
6. Poll `gh pr checks <N>`. If your `gh` has the (preview, not
   guaranteed available) `gh event listen` command — check with
   `gh event --help` first — it can wait for a state change instead of
   tight-polling: `gh event listen --resource <pr-url> --event
   com.github.pull_request.check_suite.status.changed.v1`. Otherwise
   `gh pr checks <N> --watch`, or plain repeated polling, work fine.
7. If CI fails, get the real failure with
   `gh run view <run> --job <job> --log-failed`, fix it, redo the pin
   dance if `lib/` changed again, repeat from step 5.
8. Check Codex review: `gh pr view <N> --json comments`, and
   `gh api graphql` for review threads. For any real finding — verify
   it's real first, don't just comply — fix it, verify the fix, reply
   via `gh api repos/<owner>/<repo>/pulls/<N>/comments/<id>/replies`
   quoting the fix commit, resolve via the GraphQL
   `resolveReviewThread` mutation.
9. `gh pr merge <N> --merge`, sync local `main`.
10. Update `docs/project/NEXT-ACTIONS.md`/this file as needed, and
    delete the completed item from this file once it's merged.

**Known local-session flakiness, not real regressions** (confirmed via
a clean CI container): a "Stable Diffusion maturity label" test, and
`tests/update_transaction.sh`'s stale-journal-recovery test (confirmed
via `git stash` to fail identically on unmodified `main`, unrelated to
whatever you were actually changing). If either fails locally and
CI passes, trust CI — don't chase it.

**Two real environment-specific bugs only a clean CI container ever
caught, worth remembering before writing anything interactive**:
`/dev/tty` is not always acquirable even when stdin itself is a real
pty (fall back to checking `[ -t 0 ]`, mirroring
`lib/phases.sh`'s `tnx_prompt_distro`); and GitHub Actions sets
`TERM=dumb` even under a real pty, so never treat `TERM=dumb` as "no
usable terminal" — check `-t <fd>` only.
