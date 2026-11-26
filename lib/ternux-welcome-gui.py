#!/usr/bin/python3
"""Compact, responsive GTK3 first-run welcome for Ternux.

The native GTK Welcome Center (not a browser tab) is the first-run
experience; lib/ternux-welcome.sh only falls back to the website or a
text dialog if this script itself cannot start. Colors follow whichever
of Ternux's Green/Crimson themes is active, read live from xfconf, so
this never looks out of place next to the rest of the desktop — the
hex values below must stay in sync with tools/ternux_palette.py (the
same values GTK CSS/xfwm4/terminalrc in the parent repo are generated
from); tests/focused.sh checks both files' PALETTES dicts match.
"""
import os
import subprocess
from pathlib import Path
import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gdk, Gtk


STATE = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "ternux/welcome-seen"

PALETTES = {
    "green": dict(
        bg="#101816", surface="#17221e", fg="#e4f3eb", muted="#a4b8ad",
        accent="#39e68c", accent_dark="#08784c", border="#34483e",
    ),
    "crimson": dict(
        bg="#190f12", surface="#241419", fg="#f7e8eb", muted="#bfa0a6",
        accent="#e2425c", accent_dark="#c23350", border="#4a2a30",
    ),
}


def active_colorway():
    try:
        name = subprocess.run(
            ["xfconf-query", "-c", "xsettings", "-p", "/Net/ThemeName"],
            capture_output=True, text=True, timeout=3,
        ).stdout.strip().lower()
    except (OSError, subprocess.SubprocessError):
        name = ""
    return "crimson" if name == "crimson" else "green"


def add_section(box, title, text):
    heading = Gtk.Label(label=title)
    heading.set_xalign(0)
    heading.get_style_context().add_class("section-title")
    body = Gtk.Label(label=text)
    body.set_xalign(0)
    body.set_yalign(0)
    body.set_line_wrap(True)
    body.set_line_wrap_mode(2)  # Pango.WrapMode.WORD_CHAR
    body.get_style_context().add_class("body-copy")
    box.pack_start(heading, False, False, 0)
    box.pack_start(body, False, False, 0)


def main():
    palette = PALETTES[active_colorway()]

    screen = Gdk.Screen.get_default()
    root_window = screen.get_root_window() if screen else None
    screen_width = root_window.get_width() if root_window else 752
    screen_height = root_window.get_height() if root_window else 1155
    width = max(200, min(600, screen_width - 34))
    height = max(250, min(400, screen_height - 96))

    css = Gtk.CssProvider()
    css.load_from_data(("""
        window.ternux-welcome {{ background-color: {bg}; color: {fg}; }}
        .hero {{ background-color: {surface}; padding: 12px; }}
        .hero-title {{ color: {fg}; font-size: 18px; font-weight: 700; }}
        .hero-subtitle {{ color: {muted}; font-size: 10px; }}
        button.close-action {{ background: transparent; border: 0; color: {fg}; font-size: 18px; padding: 2px 8px; }}
        button.close-action:hover {{ background-color: rgba(255,255,255,.12); }}
        window.ternux-welcome {{ border: 1px solid {border}; border-radius: 12px; }}
        .section-title {{ color: {accent}; font-size: 11px; font-weight: 700; margin-top: 4px; }}
        .body-copy {{ color: {fg}; font-size: 10px; }}
        button.ternux-action {{ background-color: {accent}; color: {bg}; border: 0; border-radius: 8px; padding: 9px 16px; font-weight: 700; }}
        button.ternux-action:hover {{ background-color: {accent_dark}; color: {fg}; }}
    """.format(**palette)).encode("utf-8"))
    Gtk.StyleContext.add_provider_for_screen(
        screen, css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
    )

    window = Gtk.Window(title="Welcome to Ternux")
    window.set_name("ternux-welcome")
    window.get_style_context().add_class("ternux-welcome")
    window.set_position(Gtk.WindowPosition.CENTER)
    window.set_decorated(False)
    window.set_resizable(False)
    window.set_default_size(width, height)
    window.set_size_request(width, height)
    window.connect("destroy", Gtk.main_quit)

    root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
    window.add(root)

    hero = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
    hero.get_style_context().add_class("hero")
    title_stack = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
    title = Gtk.Label(label="Ternux Desktop")
    title.set_xalign(0)
    title.get_style_context().add_class("hero-title")
    subtitle = Gtk.Label(label="Debian on Termux · GPU benchmark ready")
    subtitle.set_xalign(0)
    subtitle.set_line_wrap(True)
    subtitle.set_line_wrap_mode(2)
    subtitle.get_style_context().add_class("hero-subtitle")
    title_stack.pack_start(title, False, False, 0)
    title_stack.pack_start(subtitle, False, False, 0)
    hero.pack_start(title_stack, True, True, 0)
    close_window = Gtk.Button(label="×")
    close_window.get_style_context().add_class("close-action")
    close_window.connect("clicked", lambda *_: window.destroy())
    hero.pack_end(close_window, False, False, 0)
    root.pack_start(hero, False, False, 0)

    scroll = Gtk.ScrolledWindow()
    scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
    scroll.set_shadow_type(Gtk.ShadowType.NONE)
    content = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
    content.set_border_width(12)
    scroll.add(content)
    root.pack_start(scroll, True, True, 0)

    add_section(content, "PROJECT & DEVELOPER", "Maintained by Sobuj Miah\nsoobujmiah.github.io/ternux\ngithub.com/soobujmiah/ternux")
    add_section(content, "QUICK USAGE", "Apps: Applications menu · Xfce Terminal\nCommands: ternux info / status / doctor\nBangla Avro: Ctrl+Space switches language.")
    add_section(content, "LOOK & FEEL", "Wallpapers: ternux wallpaper list / set <id>\nThemes: ternux theme list / set Green / set Crimson")
    add_section(content, "GPU BENCHMARK", "Termux host: ternux benchmark\nKeep the desktop open while it runs. Scores are measurements, not guarantees.")
    add_section(content, "MORE", "Full guide: ternux guides (also run inside Debian)\nFirefox is included; return to Termux with Android Back or the session switcher.")

    footer = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
    footer.set_border_width(12)
    footer.set_halign(Gtk.Align.END)
    close = Gtk.Button(label="Start using Ternux")
    close.get_style_context().add_class("ternux-action")
    close.connect("clicked", lambda *_: window.destroy())
    footer.pack_end(close, False, False, 0)
    root.pack_start(footer, False, False, 0)

    window.connect("destroy", lambda *_: (STATE.parent.mkdir(parents=True, exist_ok=True), STATE.touch()))
    window.show_all()
    Gtk.main()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
