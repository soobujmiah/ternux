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
    color = MUTED if inactive else GREEN
    bg = (23, 34, 30, 0)
    if state == "prelight":
        bg = (57, 230, 140, 44)
    elif state == "pressed":
        bg = (8, 120, 76, 210)
    elif inactive:
        bg = (30, 43, 37, 190)

    def draw(d, size):
        w, h = size
        d.rounded_rectangle((1, 1, w - 2, h - 2), radius=8, fill=bg,
                            outline=(52, 72, 62, 255) if state != "active" else None, width=1)
        cx, cy = w // 2, h // 2
        stroke = 3
        if kind == "close":
            r = 6
            d.line((cx-r, cy-r, cx+r, cy+r), fill=color, width=stroke)
            d.line((cx+r, cy-r, cx-r, cy+r), fill=color, width=stroke)
        elif kind == "hide":
            d.line((cx-7, cy+5, cx+7, cy+5), fill=color, width=stroke)
        elif kind == "maximize":
            d.rectangle((cx-7, cy-7, cx+7, cy+7), outline=color, width=stroke)
        elif kind == "menu":
            for yy in (-5, 0, 5):
                d.line((cx-7, cy+yy, cx+7, cy+yy), fill=color, width=stroke)
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
        save(name, (10, 10), draw)
    elif vertical:
        save(name, (2, 10), lambda d, s: (d.rectangle((0,0,1,9), fill=color), d.line((1,0,1,9), fill=EDGE)))
    else:
        save(name, (10, 2), lambda d, s: (d.rectangle((0,0,9,1), fill=color), d.line((0,1,9,1), fill=EDGE)))

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
