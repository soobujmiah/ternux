#!/usr/bin/env python3
"""Generate Ternux-branded folder icons with distinct content emblems."""
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / "lib/ternux-assets/icons/Ternux/scalable/places"
GLYPHS = {
    "folder": '<path fill="#b5ffd7" d="M23 31h19v5h-7v13h-5V36h-7z"/>',
    "folder-activities": '<path d="M21 40h5l3-9 5 17 4-12h5"/>',
    "folder-android": '<path d="M24 37v-7h16v7m-14 0v8m12-8v8m-10-16-3-4m13 4 3-4"/><circle cx="29" cy="34" r="1" fill="#b5ffd7" stroke="none"/><circle cx="35" cy="34" r="1" fill="#b5ffd7" stroke="none"/>',
    "folder-backup": '<path d="M40 33a9 9 0 1 0 2 8m-2-8v-6m0 6h-6m-10 7 5 5 9-10"/>',
    "folder-books": '<path d="M22 30h9a4 4 0 0 1 4 4v13h-9a4 4 0 0 0-4 3zm22 0h-9a4 4 0 0 0-4 4v13h9a4 4 0 0 1 4 3z"/>',
    "folder-code": '<path d="m28 31-7 8 7 8m8-16 7 8-7 8"/>',
    "folder-compressed": '<path d="M31 29h7v4h-7v4h7v4h-7v4h7v4h-7"/><path d="M28 29v19m13-19v19"/>',
    "folder-documents": '<path d="M25 29h12l5 5v16H25zM37 29v6h6m-14 5h9m-9 4h9"/>',
    "folder-download": '<path d="M32 29v16m-7-7 7 7 7-7M23 49h18"/>',
    "folder-games": '<path d="M25 34h14a6 6 0 0 1 5 9l-2 4-7-5h-8l-7 5-2-4a6 6 0 0 1 7-9z"/><path d="M26 36v6m-3-3h6"/><circle cx="38" cy="38" r="1" fill="#b5ffd7"/><circle cx="41" cy="41" r="1" fill="#b5ffd7"/>',
    "folder-home": '<path d="m21 38 11-9 11 9m-18-2v13h14V36m-9 13v-8h5v8"/>',
    "folder-important": '<path fill="#b5ffd7" stroke="none" d="m32 28 4 9 10 1-7.5 6.5 2.3 10L32 49l-8.8 5.5 2.3-10L18 38l10-1z"/>',
    "folder-music": '<path d="M35 29v16a5 5 0 1 1-3-4V32l12-3v12a5 5 0 1 1-3-4v-9z"/>',
    "folder-network": '<circle cx="32" cy="31" r="4"/><circle cx="23" cy="46" r="4"/><circle cx="41" cy="46" r="4"/><path d="m30 35-5 7m9-7 5 7m-12 4h10"/>',
    "folder-open": '<path d="M21 36h24l-4 12H20l-2-15h8l4 3"/><path d="M27 29h12l4 5"/>',
    "folder-pictures": '<circle cx="39" cy="33" r="3"/><path d="m22 47 7-8 5 5 4-4 7 7z"/>',
    "folder-publicshare": '<circle cx="24" cy="39" r="3"/><circle cx="40" cy="31" r="3"/><circle cx="40" cy="47" r="3"/><path d="m27 38 10-6m-10 8 10 6"/>',
    "folder-remote": '<rect x="22" y="29" width="20" height="16" rx="2"/><path d="M27 49h10m-5-4v4m-5-11h10m-3-3 3 3-3 3"/>',
    "folder-templates": '<rect x="23" y="29" width="18" height="21" rx="2"/><path d="M27 34h10m-10 5h10m-10 5h6"/>',
    "folder-videos": '<circle cx="32" cy="39" r="11"/><path fill="#b5ffd7" stroke="none" d="M29 33v12l10-6z"/>',
}

BASE = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
 <defs><linearGradient id="g" x1="8" y1="12" x2="54" y2="59" gradientUnits="userSpaceOnUse"><stop stop-color="#39e68c"/><stop offset="1" stop-color="#078b55"/></linearGradient><linearGradient id="d" x1="18" y1="20" x2="45" y2="52" gradientUnits="userSpaceOnUse"><stop stop-color="#263a34"/><stop offset="1" stop-color="#111b19"/></linearGradient></defs>
 <path fill="#07120f" d="M5 16a7 7 0 0 1 7-7h14l7 7h19a7 7 0 0 1 7 7v25a8 8 0 0 1-8 8H13a8 8 0 0 1-8-8z"/>
 <path fill="url(#g)" d="M5 21a6 6 0 0 1 6-6h16l6 6h20a6 6 0 0 1 6 6v20a7 7 0 0 1-7 7H12a7 7 0 0 1-7-7z"/>
 <path fill="url(#d)" d="M11 27a4 4 0 0 1 4-4h34a4 4 0 0 1 4 4v18a4 4 0 0 1-4 4H15a4 4 0 0 1-4-4z"/>
 <g fill="none" stroke="#8bf3bd" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round">{glyph}</g>
 <path fill="none" stroke="#b5ffd7" stroke-opacity=".56" stroke-width="1.5" d="M7 26a5 5 0 0 1 5-5h15l6 6h20"/>
</svg>
'''

OUT.mkdir(parents=True, exist_ok=True)
for name, glyph in GLYPHS.items():
    (OUT / f"{name}.svg").write_text(BASE.replace("{glyph}", glyph))
