#!/usr/bin/env python3
"""Generate branded launcher aliases for optional Ternux desktop workloads."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUTS = (
    ROOT / "lib/ternux-assets/icons/Ternux/scalable/apps",
    ROOT / "packaging/termux/icons/Ternux/scalable/apps",
)

# Simple, high-contrast line art that stays crisp from panel size to desktop
# launchers. No common oval or badge backdrop; each glyph owns its silhouette.
GLYPHS = {
    "firefox-esr": '<path d="M19 14c5-8 18-10 27-3 8 6 10 18 4 27-6 9-18 13-28 7-8-4-12-13-10-22l8 6c-1 7 4 12 10 12 7 0 12-5 12-12 0-6-5-11-11-11-4 0-8 2-10 5l7 1-11 7-8-10 7-7z" fill="#42efa0"/><path d="M15 11 9 8l4 9m35-5 8-3-5 9" fill="none" stroke="#c8ffe1" stroke-width="3"/>',
    "blender": '<path d="m8 23 23-7 25 8-23 8zm4 12 20-6 20 7-21 7zm8 12 14-5 14 5-15 6z" fill="#42efa0"/><circle cx="44" cy="24" r="5" fill="#101a17" stroke="#c8ffe1" stroke-width="2"/>',
    "gimp": '<path d="M13 21c7-10 25-12 36-3l5 11-8 4 5 12c-9 9-27 9-36 0l-5-13z" fill="none" stroke="#42efa0" stroke-width="3"/><path d="m21 41 7-12 6 8 7-11 7 15z" fill="#c8ffe1"/><circle cx="42" cy="22" r="2" fill="#c8ffe1"/>',
    "krita": '<path d="M17 45 38 16l10 7-21 29-12 4z" fill="#42efa0"/><path d="m37 18 6-7 11 8-6 7m-27 20 7 5" fill="none" stroke="#c8ffe1" stroke-width="3" stroke-linejoin="round"/>',
    "inkscape": '<path d="M32 9 52 50H12z" fill="none" stroke="#42efa0" stroke-width="3" stroke-linejoin="round"/><path d="m32 9 5 14-5 12-5-12zm0 26 8 15H24z" fill="#c8ffe1"/>',
    "audacity": '<path d="M14 34v-5a5 5 0 0 1 10 0v8a5 5 0 0 1-10 0m26-8a5 5 0 0 1 10 0v5m-10 4a5 5 0 0 0 10 0m-26-2v4a8 8 0 0 0 16 0V24a8 8 0 0 0-16 0" fill="none" stroke="#42efa0" stroke-width="3" stroke-linecap="round"/><path d="m32 8 3 7-3 5-3-5z" fill="#c8ffe1"/>',
    "mpv": '<path d="M12 15h40v34H12z" fill="none" stroke="#c8ffe1" stroke-width="3"/><path d="m26 22 17 10-17 10z" fill="#42efa0"/><path d="M20 54h24" stroke="#42efa0" stroke-width="3"/>',
    "evince": '<path d="M18 10h19l10 10v34H18z" fill="none" stroke="#42efa0" stroke-width="3"/><path d="M37 10v12h10m-21 8h13m-13 7h13m-13 7h9" fill="none" stroke="#c8ffe1" stroke-width="2.5"/><path d="m27 48 5-8 5 8" fill="none" stroke="#42efa0" stroke-width="2.5"/>',
    "geany": '<path d="m20 20-10 12 10 12m24-24 10 12-10 12M37 15 27 49" fill="none" stroke="#42efa0" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"/><path d="M17 54h30" stroke="#c8ffe1" stroke-width="2"/>',
    "thonny": '<path d="M18 22c0-5 5-9 13-9h14v8H31c-3 0-5 2-5 5v5h13v8H26v6c0 3 2 5 5 5h14v8H31c-8 0-13-4-13-11z" fill="none" stroke="#42efa0" stroke-width="3"/><circle cx="39" cy="25" r="2" fill="#c8ffe1"/><circle cx="26" cy="42" r="2" fill="#c8ffe1"/>',
    "libreoffice-writer": '<path d="M17 10h22l9 9v35H17z" fill="none" stroke="#42efa0" stroke-width="3"/><path d="M39 10v11h9m-23 9h15m-15 7h15m-15 7h11" fill="none" stroke="#c8ffe1" stroke-width="2.5"/><path d="m44 44 4 4 7-9" fill="none" stroke="#42efa0" stroke-width="2.5"/>',
    "libreoffice-calc": '<path d="M12 13h40v38H12z" fill="none" stroke="#42efa0" stroke-width="3"/><path d="M12 26h40M12 39h40M25 13v38m14-38v38" stroke="#c8ffe1" stroke-width="2.5"/><path d="m17 34 6-4m-6 17 6-5m9-11 6 6m6 10 5-7" stroke="#42efa0" stroke-width="2.5"/>',
    "libreoffice-draw": '<path d="M12 48 25 15l27 11-13 30z" fill="none" stroke="#42efa0" stroke-width="3" stroke-linejoin="round"/><path d="m25 15 7 21 20-10M32 36l7 20m-7-20-20 12" fill="none" stroke="#c8ffe1" stroke-width="2.5"/><circle cx="32" cy="36" r="3" fill="#42efa0"/>',
    "libreoffice-impress": '<path d="M12 14h40v30H12z" fill="none" stroke="#42efa0" stroke-width="3"/><path d="M20 22h24v14H20zm12 22v8m-8 0h16" fill="none" stroke="#c8ffe1" stroke-width="2.5"/><path d="m25 33 5-6 5 4 5-5" fill="none" stroke="#42efa0" stroke-width="2.5"/>',
    "zenity": '<path d="M12 14h40v30H12z" fill="none" stroke="#42efa0" stroke-width="3"/><path d="M24 52h16m-8-8v8m-9-29h18m-18 6h12" fill="none" stroke="#c8ffe1" stroke-width="2.5"/><circle cx="44" cy="36" r="3" fill="#42efa0"/>',
}

ALIASES = {
    "firefox-esr": ("firefox", "firefox-esr"),
    "blender": ("blender",),
    "gimp": ("gimp", "org.gimp.GIMP"),
    "krita": ("krita", "org.kde.krita"),
    "inkscape": ("inkscape", "org.inkscape.Inkscape"),
    "audacity": ("audacity",),
    "mpv": ("mpv",),
    "evince": ("evince", "org.gnome.Evince"),
    "geany": ("geany", "geany"),
    "thonny": ("thonny",),
    "libreoffice-writer": ("libreoffice-writer",),
    "libreoffice-calc": ("libreoffice-calc",),
    "libreoffice-draw": ("libreoffice-draw",),
    "libreoffice-impress": ("libreoffice-impress",),
    "zenity": ("zenity",),
}

TEMPLATE = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" role="img" aria-label="{label}"><g fill="none" stroke="#42efa0" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round">{glyph}</g></svg>\n'''

for base in OUTS:
    base.mkdir(parents=True, exist_ok=True)
    for key, names in ALIASES.items():
        svg = TEMPLATE.format(label=key.replace('-', ' ').title(), glyph=GLYPHS[key])
        for name in names:
            (base / f"{name}.svg").write_text(svg, encoding="utf-8")
