#!/usr/bin/env python3
"""Check hand-maintained theme files agree with tools/ternux_palette.py.

tools/generate_ternux_xfwm.py and tools/generate_wallpapers.py both derive
their colors from tools/ternux_palette.py (the single source of truth), but
the GTK CSS files, xfwm4 themerc, and the terminalrc heredoc in
lib/phases.sh are hand-written and could silently drift from it. This test
is the enforcement mechanism for the "one shared token table" goal: it does
not generate those files, it just fails loudly if their hex values ever
stop matching the canonical palette.
"""
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_ROOT / "tools"))
from ternux_palette import PALETTES  # noqa: E402

THEME_DIRS = {"green": "Green", "crimson": "Crimson"}
errors = []


def check(label, actual, expected):
    if actual.lower() != expected.lower():
        errors.append(f"{label}: found {actual}, expected {expected} (tools/ternux_palette.py)")


def extract(text, pattern):
    match = re.search(pattern, text, re.MULTILINE)
    return match.group(1) if match else None


def check_gtk3(colorway, theme_dir, p):
    css = (REPO_ROOT / "lib/ternux-assets/themes" / theme_dir / "gtk-3.0/gtk.css").read_text()
    mapping = {
        "theme_bg_color": p["bg"], "theme_fg_color": p["fg"], "theme_base_color": p["base"],
        "theme_selected_bg_color": p["accent_dark"], "borders": p["border"],
        "wm_bg": p["surface"], f"ternux_{colorway}": p["accent"],
        f"ternux_{colorway}_dark": p["accent_dark"], "ternux_border": p["border"],
    }
    for name, expected in mapping.items():
        actual = extract(css, rf"@define-color\s+{re.escape(name)}\s+(#[0-9a-fA-F]{{6}})")
        if actual is None:
            errors.append(f"{theme_dir} gtk-3.0: missing @define-color {name}")
            continue
        check(f"{theme_dir} gtk-3.0 {name}", actual, expected)


def check_gtk4(theme_dir, p):
    css = (REPO_ROOT / "lib/ternux-assets/themes" / theme_dir / "gtk-4.0/gtk.css").read_text()
    mapping = {
        "window-bg-color": p["bg"], "window-fg-color": p["fg"], "view-bg-color": p["base"],
        "headerbar-bg-color": p["surface"], "accent-bg-color": p["accent_dark"], "accent-color": p["accent"],
    }
    for name, expected in mapping.items():
        actual = extract(css, rf"--{re.escape(name)}:\s*(#[0-9a-fA-F]{{6}})")
        if actual is None:
            errors.append(f"{theme_dir} gtk-4.0: missing --{name}")
            continue
        check(f"{theme_dir} gtk-4.0 {name}", actual, expected)


def check_themerc(theme_dir, p):
    rc = (REPO_ROOT / "lib/ternux-assets/themes" / theme_dir / "xfwm4/themerc").read_text()
    mapping = {
        "active_text_color": p["fg"], "inactive_text_color": p["muted"],
        "active_color": p["surface"], "inactive_color": p["bg"],
        "active_shadow_color": p["accent"], "inactive_shadow_color": p["border"],
    }
    for name, expected in mapping.items():
        actual = extract(rc, rf"^{re.escape(name)}=(#[0-9a-fA-F]{{6}})$")
        if actual is None:
            errors.append(f"{theme_dir} themerc: missing {name}")
            continue
        check(f"{theme_dir} themerc {name}", actual, expected)


def check_terminalrc():
    # terminalrc is only written once at install time (lib/phases.sh), using
    # the Green palette as the shipped default; it is intentionally not
    # re-written on theme switch (users may have customized it since), so it
    # is only ever checked against Green here.
    phases = (REPO_ROOT / "lib/phases.sh").read_text()
    p = PALETTES["green"]
    mapping = {
        "ColorForeground": p["fg"],
        "ColorBackground": p["bg"],
        "ColorCursor": p["accent"],
        "ColorSelection": p["accent_dark"],
    }
    for name, expected in mapping.items():
        actual = extract(phases, rf"^{re.escape(name)}=(#[0-9a-fA-F]{{6}})$")
        if actual is None:
            errors.append(f"lib/phases.sh terminalrc: missing {name}")
            continue
        check(f"lib/phases.sh terminalrc {name}", actual, expected)


def check_welcome_gui():
    # The guest-side Welcome Center can't import tools/ternux_palette.py (it
    # ships as a standalone guest asset, not host build tooling), so it
    # keeps its own small PALETTES dict — check it stays a subset of the
    # canonical values rather than drifting.
    source = (REPO_ROOT / "lib/ternux-welcome-gui.py").read_text()
    import ast
    tree = ast.parse(source)
    assign = None
    for node in tree.body:
        if isinstance(node, ast.Assign) and any(
            isinstance(t, ast.Name) and t.id == "PALETTES" for t in node.targets
        ):
            assign = node
            break
    if assign is None:
        errors.append("lib/ternux-welcome-gui.py: no PALETTES dict found")
        return
    # Written as {"green": dict(bg=..., ...), "crimson": dict(...)} — each
    # value is a dict(**kwargs) call, not a literal, so literal_eval can't
    # parse it directly; pull the keyword values out by hand instead.
    guest_palettes = {
        key.value: {kw.arg: kw.value.value for kw in call.keywords}
        for key, call in zip(assign.value.keys, assign.value.values)
    }
    for colorway, guest_values in guest_palettes.items():
        canonical = PALETTES.get(colorway)
        if canonical is None:
            errors.append(f"lib/ternux-welcome-gui.py: unknown colorway {colorway}")
            continue
        for token, value in guest_values.items():
            check(f"lib/ternux-welcome-gui.py {colorway} {token}", value, canonical.get(token, ""))


def main():
    for colorway, theme_dir in THEME_DIRS.items():
        p = PALETTES[colorway]
        check_gtk3(colorway, theme_dir, p)
        check_gtk4(theme_dir, p)
        check_themerc(theme_dir, p)
    check_terminalrc()
    check_welcome_gui()

    if errors:
        for error in errors:
            print(f"FAIL {error}")
        print(f"Palette consistency: FAIL ({len(errors)} mismatches)")
        return 1
    print("Palette consistency: PASS — all hand-written theme files match tools/ternux_palette.py")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
