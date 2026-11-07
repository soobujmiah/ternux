#!/usr/bin/env python3
"""Generate original, touch-friendly Ternux Xfwm frame assets."""
from pathlib import Path
from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parents[1] / "lib/ternux-assets/themes/Ternux/xfwm4"
ACTIVE = (23, 34, 30, 255)
INACTIVE = (16, 24, 22, 255)
EDGE = (52, 72, 62, 255)
GREEN = (57, 230, 140, 255)
PALE = (228, 243, 235, 255)
MUTED = (164, 184, 173, 255)


def save(name, size, draw_fn):
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw_fn(ImageDraw.Draw(image), size)
    image.save(OUT / name, optimize=True)


def state_button(kind, state, inactive=False):
    color = MUTED if inactive else PALE
    outline = EDGE
    bg = (27, 42, 35, 210) if inactive else (35, 60, 47, 250)
    if not inactive and kind == "close":
        color = (255, 226, 226, 255)
        bg = (101, 38, 42, 255)
        outline = (255, 111, 115, 255)
    if state == "prelight":
        bg = (57, 230, 140, 255)
        color = (7, 32, 21, 255)
        outline = (135, 255, 193, 255)
        if kind == "close":
            bg = (220, 56, 66, 255)
            color = (255, 255, 255, 255)
            outline = (255, 180, 181, 255)
    elif state == "pressed":
        bg = (8, 120, 76, 255)
        color = PALE
        outline = GREEN
        if kind == "close":
            bg = (150, 35, 43, 255)
            outline = (255, 111, 115, 255)

    def draw(d, size):
        w, h = size
        d.rounded_rectangle((1, 1, w - 2, h - 2), radius=9, fill=bg,
                            outline=outline, width=1)
        cx, cy = w // 2, h // 2
        stroke = 4
        if kind == "close":
            r = 9
            d.line((cx-r, cy-r, cx+r, cy+r), fill=color, width=stroke)
            d.line((cx+r, cy-r, cx-r, cy+r), fill=color, width=stroke)
        elif kind == "hide":
            d.line((cx-9, cy+6, cx+9, cy+6), fill=color, width=stroke)
        elif kind == "maximize":
            d.rectangle((cx-9, cy-9, cx+9, cy+9), outline=color, width=stroke)
        elif kind == "menu":
            for yy in (-7, 0, 7):
                d.line((cx-9, cy+yy, cx+9, cy+yy), fill=color, width=stroke)
        elif kind == "shade":
            d.line((cx-7, cy-3, cx, cy+5, cx+7, cy-3), fill=color, width=stroke, joint="curve")
        elif kind == "stick":
            d.ellipse((cx-6, cy-6, cx+6, cy+6), outline=color, width=stroke)

    save(f"{kind}-{state}.png", (32, 32), draw)


def edge(name, color, vertical=True, corner=False):
    if corner:
        def draw(d, size):
            w, h = size
            d.rectangle((0, 0, w-1, h-1), fill=color)
            d.line((0, h-1, w-1, h-1), fill=EDGE, width=1)
            d.line((w-1, 0, w-1, h-1), fill=EDGE, width=1)
        save(name, (6, 6), draw)
    elif vertical:
        save(name, (2, 5), lambda d, s: (d.rectangle((0,0,1,4), fill=color), d.line((1,0,1,4), fill=EDGE)))
    else:
        save(name, (5, 2), lambda d, s: (d.rectangle((0,0,4,1), fill=color), d.line((0,1,4,1), fill=EDGE)))

OUT.mkdir(parents=True, exist_ok=True)
for state, color in (("active", ACTIVE), ("inactive", INACTIVE)):
    edge(f"top-{state}.png", color, vertical=True)
    edge(f"bottom-{state}.png", color, vertical=True)
    edge(f"left-{state}.png", color, vertical=False)
    edge(f"right-{state}.png", color, vertical=False)
    for corner_name in ("top-left", "top-right", "bottom-left", "bottom-right"):
        edge(f"{corner_name}-{state}.png", color, corner=True)
    for i in range(1, 6):
        save(f"title-{i}-{state}.png", (2, 32), lambda d, s, c=color: d.rectangle((0,0,1,31), fill=c))

for kind in ("close", "hide", "maximize", "menu", "shade", "stick"):
    state_button(kind, "active")
    state_button(kind, "inactive", True)
    if kind in ("close", "hide", "maximize"):
        state_button(kind, "prelight")
        state_button(kind, "pressed")
