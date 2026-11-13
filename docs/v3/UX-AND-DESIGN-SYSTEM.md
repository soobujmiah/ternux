---
title: "Ternux v3 UX and design system"
description: "Consistent terminal, dashboard, desktop, and accessibility rules for Ternux v3."
lang: "en"
---

## UX and design system

**Status: DESIGNED.** Ternux is a branded workstation, not a set of unrelated
dialogs. Native Termux CLI, Control Center, XFCE defaults, icons, and docs use
one visual and language system while respecting each platform's conventions.

## Information hierarchy

Every status view separates **state**, **action**, and **evidence**. A user
can see which guest or workload is selected, what will change, current
progress, and where its logs live. Destructive actions state the target and
data categories before confirmation. Success includes the next useful action.

## CLI behavior

- All install, distro-selection, uninstall, repair, and stop flows use the
  same keyboard rules: arrows move, Space toggles multi-select, Enter confirms,
  Escape cancels; numbered selection is supported as an alternate input.
- Prompts have clear defaults, validation, timeout behavior, and a plain-text
  fallback when TTY features are unavailable.
- Commands remain scriptable with `--json`, deterministic exit codes, and no
  interactive prompt when stdin/stdout is not a TTY.
- Progress logs are concise in foreground and available through a bounded
  `tx logs` view; background services do not spam the terminal.

## Visual system

Use the existing Ternux forest/teal palette with high contrast, restrained
glow, consistent typography, and distinct status colors that also have text
labels. Icons are purpose-specific, coherent at small sizes, and preserve
recognizable application identity. Folder types may differ, but unrelated
applications must not receive the same generic emblem. GTK, XFWM, panel,
launchers, app icons, and wallpapers ship as one versioned theme pack.

## Accessibility and localization

Keyboard-only operation, TalkBack-compatible labels in native UI, scalable
text, reduced motion, visible focus, and non-color status cues are required.
English and Bangla documentation are maintained together; CLI labels avoid
ambiguous transliteration. Terminal symbols have ASCII fallbacks.

## Resource budgets

Idle UI target is bounded CPU activity with no periodic sensor polling. The
dashboard loads detailed logs and package inventories on demand. Animations
respect reduced motion and can be disabled. Low-memory mode removes decorative
effects before removing usability or status information.
