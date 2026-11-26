"""Single source of truth for Ternux's Green/Crimson brand color tokens.

Before this module existed, the same semantic colors (background, surface,
accent, muted text, border...) were hand-copied into three independent
places: tools/generate_ternux_xfwm.py's THEMES dict, tools/generate_
wallpapers.py's PALETTES dict, and the hand-written GTK CSS / xfwm4 themerc
/ terminalrc files. They happened to agree, but nothing enforced that.
Generators now import PALETTES from here instead of hardcoding their own
copy; tests/palette_consistency.py checks the hand-written files against it.
"""

PALETTES = {
    "green": dict(
        bg="#101816",
        base="#0c1311",
        surface="#17221e",
        surface2="#202e28",
        fg="#e4f3eb",
        muted="#a4b8ad",
        accent="#39e68c",
        accent_dark="#08784c",
        border="#34483e",
        selected_fg="#ffffff",
    ),
    "crimson": dict(
        bg="#190f12",
        base="#140c0e",
        surface="#241419",
        surface2="#2d1a1f",
        fg="#f7e8eb",
        muted="#bfa0a6",
        accent="#e2425c",
        accent_dark="#c23350",
        border="#4a2a30",
        selected_fg="#ffffff",
    ),
}


def hex_to_rgb(value):
    value = value.lstrip("#")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


def hex_to_rgba(value, alpha=255):
    return hex_to_rgb(value) + (alpha,)
