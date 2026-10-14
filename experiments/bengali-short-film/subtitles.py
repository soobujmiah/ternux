#!/usr/bin/env python3
"""Bengali subtitles and the closing card, rendered as RGBA overlays.

Blender's text objects do not shape Indic scripts, and ffmpeg's drawtext has no
complex-script shaping either, so conjuncts and vowel signs would break. Pillow
with the raqm layout engine does shape correctly, so each caption is rendered
once as a PNG and composited over the picture by ffmpeg.

    python3 subtitles.py out_dir
"""

import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont

W, H = 1280, 720
FONT = "/usr/share/fonts/truetype/lohit-bengali/Lohit-Bengali.ttf"
HERE = os.path.dirname(os.path.abspath(__file__))


def layout(draw, text, font, max_width):
    """Wrap on spaces, measuring shaped runs rather than counting characters."""
    words = text.split(" ")
    lines, cur = [], ""
    for w in words:
        trial = (cur + " " + w).strip()
        if draw.textlength(trial, font=font) <= max_width or not cur:
            cur = trial
        else:
            lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    return lines


def caption(text, path, size=44, bottom=True, band=True, colour=(255, 255, 255, 255)):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    font = ImageFont.truetype(FONT, size, layout_engine=ImageFont.Layout.RAQM)
    lines = []
    for para in text.split("\n"):
        lines.extend(layout(d, para, font, W - 200))
    line_h = int(size * 1.52)
    total = line_h * len(lines)
    y0 = H - 72 - total if bottom else (H - total) // 2
    if band:
        pad = 18
        widest = max(d.textlength(l, font=font) for l in lines)
        x0 = (W - widest) / 2 - 26
        d.rounded_rectangle([x0, y0 - pad, W - x0, y0 + total + pad - 8], radius=14,
                            fill=(0, 0, 0, 150))
    for i, line in enumerate(lines):
        w = d.textlength(line, font=font)
        x = (W - w) / 2
        y = y0 + i * line_h
        d.text((x + 2, y + 2), line, font=font, fill=(0, 0, 0, 190))     # shadow
        d.text((x, y), line, font=font, fill=colour)
    img.save(path)
    return path


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "..", "assets", "subs")
    os.makedirs(out, exist_ok=True)
    lines = {l["id"]: l for l in json.load(open(os.path.join(HERE, "..", "assets", "lines.json")))}
    cues = json.load(open(os.path.join(HERE, "..", "assets", "cues.json")))
    timing = json.load(open(os.path.join(HERE, "..", "assets", "lipsync.json")))

    overlays = []
    for c in cues["lines"]:
        text = lines[c["id"]]["subtitle"]
        p = os.path.join(out, f"{c['id']}.png")
        caption(text, p)
        dur = timing[c["id"]]["seconds"]
        overlays.append(dict(file=p, start=round(c["start"], 3),
                             end=round(c["start"] + dur + 0.35, 3)))
        print(f"{c['id']:10s} {c['start']:6.2f}s  {text[:40]}")

    card = cues["card"]
    p = os.path.join(out, "card.png")
    caption(card["text"], p, size=52, bottom=False, band=False, colour=(250, 246, 238, 255))
    overlays.append(dict(file=p, start=card["start"], end=card["end"]))
    print(f"card       {card['start']:6.2f}s")

    json.dump(overlays, open(os.path.join(out, "overlays.json"), "w"), indent=1)


if __name__ == "__main__":
    main()
