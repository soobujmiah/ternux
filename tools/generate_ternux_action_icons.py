#!/usr/bin/env python3
"""Generate crisp, branded icons for common XFCE/Thunar menu actions."""
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / "lib/ternux-assets/icons/Ternux/scalable/apps"
GLYPHS = {
    "application-exit": '<path d="M14 6h5v12h-5M11 10l-4 4 4 4m-4-4h13"/>',
    "document-new": '<path d="M9 6h9l4 4v14H9zM18 6v5h4m-6 3v7m-3.5-3.5h7"/>',
    "document-open": '<path d="M6 12a2 2 0 0 1 2-2h5l2 2h8v9a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2zM11 18h8m-4-4v8m-3-3 3 3 3-3"/>',
    "document-save": '<path d="M7 6h13l3 3v15H7zM11 6v7h8V6m-7 18v-7h8v7"/>',
    "document-properties": '<path d="M8 5h10l5 5v15H8zM18 5v6h5"/><circle cx="15" cy="16" r="3"/><path d="M15 15v2"/>',
    "edit-copy": '<path d="M11 10V6h11v14h-4M7 10h11v14H7zM10 14h5m-5 4h5"/>',
    "edit-cut": '<circle cx="9" cy="8" r="2.5"/><circle cx="9" cy="20" r="2.5"/><path d="m11 10 11 10M11 18 22 8m-7 5 7 7"/>',
    "edit-paste": '<path d="M11 7h10v17H7V7h2m2-2h6v5h-6zM10 14h8m-8 4h8"/>',
    "edit-delete": '<path d="M7 9h16m-14 0 1 14h10l1-14m-9 3v8m4-8v8M11 6h8l1 3h-10z"/>',
    "edit-rename": '<path d="m7 20 2-6L19 4l5 5-10 10-7 1zm9-14 5 5m-11 4 3 3"/>',
    "edit-select-all": '<rect x="7" y="7" width="18" height="18" rx="2" stroke-dasharray="2 2"/><path d="m11 16 3 3 7-8"/>',
    "edit-find": '<circle cx="13" cy="13" r="7"/><path d="m18 18 6 6m-11-14v6m-3-3h6"/>',
    "system-search": '<circle cx="13" cy="13" r="7"/><path d="m18 18 6 6"/>',
    "go-home": '<path d="m5 14 11-9 11 9m-18-2v12h14V12m-9 12v-7h5v7"/>',
    "go-up": '<path d="M16 24V8m-7 7 7-7 7 7"/>',
    "go-previous": '<path d="M24 16H8m7-7-7 7 7 7"/>',
    "go-next": '<path d="M8 16h16m-7-7 7 7-7 7"/>',
    "view-refresh": '<path d="M24 12a9 9 0 0 0-16-4L5 11m0-6v6h6m2 7a9 9 0 0 0 16 4l3-3m0 6v-6h-6"/>',
    "view-list": '<path d="M13 8h13M13 16h13M13 24h13"/><circle cx="7" cy="8" r="1"/><circle cx="7" cy="16" r="1"/><circle cx="7" cy="24" r="1"/>',
    "view-grid": '<rect x="6" y="6" width="8" height="8" rx="1"/><rect x="18" y="6" width="8" height="8" rx="1"/><rect x="6" y="18" width="8" height="8" rx="1"/><rect x="18" y="18" width="8" height="8" rx="1"/>',
    "view-details": '<path d="M6 7h20v18H6zM6 13h20M13 13v12M9 10h2m-2 6h2m-2 4h2"/>',
    "view-sort-ascending": '<path d="M8 25V7m-4 4 4-4 4 4m4 10h10m-10-5h7m-7-5h4"/>',
    "view-sort-descending": '<path d="M8 7v18m-4-4 4 4 4-4m4-10h4m-4 5h7m-7 5h10"/>',
    "user-bookmarks": '<path d="M9 6h14v20l-7-5-7 5zM12 10h8m-8 4h8"/>',
    "process-stop": '<circle cx="16" cy="16" r="11"/><path d="M11 11 21 21m0-10L11 21"/>',
    "window-close": '<rect x="6" y="7" width="20" height="18" rx="2"/><path d="m13 14 6 6m0-6-6 6"/>',
    "window-close-symbolic": '<path d="m8 8 16 16M24 8 8 24"/>',
    "help-about": '<circle cx="16" cy="16" r="11"/><path d="M13 12a3 3 0 1 1 5 2c-2 1-2 2-2 4m0 4h.01"/>',
    "emblem-symbolic-link": '<path d="M12 20H9a5 5 0 0 1 0-10h5m6 0h2a5 5 0 0 1 0 10h-5m-8-5h14"/>',
    "view-more-symbolic": '<circle cx="8" cy="16" r="1.8" fill="#b5ffd7"/><circle cx="16" cy="16" r="1.8" fill="#b5ffd7"/><circle cx="24" cy="16" r="1.8" fill="#b5ffd7"/>',
}

for name, glyph in GLYPHS.items():
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
 <path d="M16 2 29 9.5v13L16 30 3 22.5v-13z" fill="#10221a" stroke="#39e68c" stroke-width="1.5"/>
 <g fill="none" stroke="#b5ffd7" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">{glyph}</g>
</svg>
'''
    (OUT / f"{name}.svg").write_text(svg)
