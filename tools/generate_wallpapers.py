#!/usr/bin/env python3
"""Ternux Wallpaper Generator.

Produces the 15 conceptual wallpaper compositions from the V3 brand
brief, each in two colorways (Green, Crimson). This is the Generator
half of the wallpaper architecture only: it produces source artwork,
optimized WebP assets, thumbnails, and a manifest. It does not apply
wallpapers to a running desktop — that is the separate, not-yet-built
Wallpaper Apply Manager's job, by design (the two must stay decoupled).

Output layout, per concept:
  lib/ternux-assets/wallpapers-v3/<id>/source.png   (1920x1080, per colorway)
  lib/ternux-assets/wallpapers-v3/<id>/<colorway>.webp
  lib/ternux-assets/wallpapers-v3/<id>/<colorway>-preview.webp (480x270)
  lib/ternux-assets/wallpapers-v3/manifest.json

Note on alpha: plain PIL ImageDraw does not alpha-blend translucent
fills against whatever is already on the canvas — it writes the raw
RGBA values straight into the pixel buffer (overwriting, not
compositing). Every concept below therefore draws onto a transparent
RGBA overlay and alpha-composites that overlay onto the solid/gradient
base exactly once at the end, which is what actually produces the
intended soft/translucent look.
"""
import json
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

REPO_ROOT = Path(__file__).resolve().parents[1]
OUT_ROOT = REPO_ROOT / "lib/ternux-assets/wallpapers-v3"
SIZE = (1920, 1080)
PREVIEW_SIZE = (480, 270)

PALETTES = {
    "green": dict(
        bg=(16, 24, 22), bg2=(23, 34, 30), accent=(57, 230, 140),
        accent_dim=(8, 120, 76), fg=(228, 243, 235), muted=(164, 184, 173),
    ),
    "crimson": dict(
        bg=(25, 15, 18), bg2=(36, 20, 25), accent=(226, 66, 92),
        accent_dim=(194, 51, 80), fg=(247, 232, 235), muted=(191, 160, 166),
    ),
}


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def vertical_gradient(size, top, bottom):
    w, h = size
    img = Image.new("RGB", size)
    draw = ImageDraw.Draw(img)
    for y in range(h):
        draw.line([(0, y), (w, y)], fill=lerp(top, bottom, y / max(h - 1, 1)))
    return img


def new_overlay():
    return Image.new("RGBA", SIZE, (0, 0, 0, 0))


def finish(base_rgb, overlay):
    """Composite the translucent overlay onto the opaque base exactly once."""
    return Image.alpha_composite(base_rgb.convert("RGBA"), overlay).convert("RGB")


def apply_radial_glow(base_rgb, center, radius, color, intensity=0.4):
    """Blend a soft radial glow of `color` into base_rgb (opaque result)."""
    w, h = SIZE
    cx, cy = center
    mask = Image.new("L", SIZE, 0)
    md = ImageDraw.Draw(mask)
    md.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), fill=int(255 * intensity))
    mask = mask.filter(ImageFilter.GaussianBlur(radius / 2.5))
    glow = Image.new("RGB", SIZE, color)
    return Image.composite(glow, base_rgb, mask)


def starfield(draw, size, count, seed, color):
    rnd = random.Random(seed)
    w, h = size
    for _ in range(count):
        x, y = rnd.uniform(0, w), rnd.uniform(0, h)
        r = rnd.uniform(0.5, 2.2)
        draw.ellipse((x - r, y - r, x + r, y + r), fill=color)


# --- 15 concept draw functions -------------------------------------------
# Each returns a final RGB image. Each builds an opaque `base`, draws every
# translucent element onto a transparent `overlay`, then calls finish().

def c01_infinite_computing(p):
    base = vertical_gradient(SIZE, p["bg"], p["bg2"])
    ov = new_overlay()
    d = ImageDraw.Draw(ov)
    w, h = SIZE
    cx, cy = w * 0.5, h * 0.52
    n = 18
    for i in range(n, 0, -1):
        t = i / n
        size_w, size_h = w * 0.9 * t, h * 0.9 * t
        alpha = int(70 + 120 * (1 - t))
        d.rectangle((cx - size_w / 2, cy - size_h / 2, cx + size_w / 2, cy + size_h / 2),
                    outline=p["accent"] + (alpha,), width=2)
    d.ellipse((cx - 6, cy - 6, cx + 6, cy + 6), fill=p["accent"] + (255,))
    return finish(base, ov)


def c02_neural_intelligence(p):
    base = Image.new("RGB", SIZE, p["bg"])
    ov = new_overlay()
    d = ImageDraw.Draw(ov)
    w, h = SIZE
    rnd = random.Random(2)
    nodes = [(rnd.uniform(w * 0.15, w * 0.85), rnd.uniform(h * 0.15, h * 0.85)) for _ in range(28)]
    for i, (x1, y1) in enumerate(nodes):
        for (x2, y2) in nodes[i + 1:]:
            dist = math.hypot(x1 - x2, y1 - y2)
            if dist < 260:
                alpha = int(170 * (1 - dist / 260))
                d.line((x1, y1, x2, y2), fill=p["accent_dim"] + (alpha,), width=1)
    for x, y in nodes:
        r = rnd.uniform(3, 7)
        d.ellipse((x - r, y - r, x + r, y + r), fill=p["accent"] + (230,))
    return finish(base, ov)


def c03_flow_of_information(p):
    base = vertical_gradient(SIZE, p["bg2"], p["bg"])
    ov = new_overlay()
    d = ImageDraw.Draw(ov)
    w, h = SIZE
    rnd = random.Random(3)
    for _ in range(46):
        y = rnd.uniform(0, h)
        length = rnd.uniform(120, 420)
        x = rnd.uniform(-length, w)
        thickness = rnd.uniform(1, 3)
        alpha = int(rnd.uniform(60, 190))
        color = p["accent"] if rnd.random() > 0.5 else p["fg"]
        d.line((x, y, x + length, y + rnd.uniform(-30, 30)), fill=color + (alpha,), width=int(thickness))
    return finish(base, ov)


def c04_cosmic_perspective(p):
    base = Image.new("RGB", SIZE, p["bg"])
    base = apply_radial_glow(base, (int(SIZE[0] * 0.72), int(SIZE[1] * 0.32)), 420, p["accent_dim"], 0.5)
    ov = new_overlay()
    d = ImageDraw.Draw(ov)
    starfield(d, SIZE, 180, 4, p["fg"] + (210,))
    cx, cy = SIZE[0] * 0.72, SIZE[1] * 0.32
    d.ellipse((cx - 70, cy - 70, cx + 70, cy + 70), fill=p["accent"] + (255,))
    for r in (120, 170, 230):
        d.ellipse((cx - r, cy - r * 0.4, cx + r, cy + r * 0.4), outline=p["muted"] + (90,), width=1)
    return finish(base, ov)


def c05_living_circuits(p):
    base = Image.new("RGB", SIZE, p["bg"])
    ov = new_overlay()
    d = ImageDraw.Draw(ov)
    w, h = SIZE

    def branch(x, y, angle, length, depth, rnd):
        if depth == 0 or length < 10:
            return
        x2 = x + length * math.cos(angle)
        y2 = y + length * math.sin(angle)
        alpha = int(90 + depth * 20)
        d.line((x, y, x2, y2), fill=p["accent"] + (min(alpha, 220),), width=max(1, depth // 2))
        if rnd.random() > 0.3:
            d.ellipse((x2 - 3, y2 - 3, x2 + 3, y2 + 3), fill=p["accent_dim"] + (210,))
        for _ in range(2):
            branch(x2, y2, angle + rnd.uniform(-0.6, 0.6), length * 0.72, depth - 1, rnd)

    rnd = random.Random(5)
    for bx in (w * 0.2, w * 0.5, w * 0.8):
        branch(bx, h * 1.02, -math.pi / 2 + rnd.uniform(-0.2, 0.2), h * 0.32, 6, rnd)
    return finish(base, ov)


def c06_mathematical_order(p):
    base = Image.new("RGB", SIZE, p["bg"])
    ov = new_overlay()
    d = ImageDraw.Draw(ov)
    w, h = SIZE
    step = 90
    rnd = random.Random(6)
    for gy in range(0, h + step, step):
        for gx in range(0, w + step, step):
            s = step * 0.32
            jitter = rnd.uniform(0.85, 1.0)
            alpha = int(140 * jitter)
            x, y = gx + step / 2, gy + step / 2
            d.polygon([(x, y - s), (x + s, y + s * 0.6), (x - s, y + s * 0.6)],
                      outline=p["accent"] + (alpha,), width=1)
    return finish(base, ov)


def c07_architecture_of_thought(p):
    base = vertical_gradient(SIZE, p["bg2"], p["bg"])
    ov = new_overlay()
    d = ImageDraw.Draw(ov)
    w, h = SIZE
    base_y = h * 0.78
    rnd = random.Random(7)
    x = 0.0
    while x < w:
        bw = rnd.uniform(60, 160)
        bh = rnd.uniform(h * 0.08, h * 0.32)
        d.rectangle((x, base_y - bh, x + bw, base_y), fill=p["bg2"] + (255,), outline=p["accent_dim"] + (170,))
        x += bw + rnd.uniform(4, 14)
    for _ in range(14):
        cx = rnd.uniform(w * 0.1, w * 0.9)
        cy = rnd.uniform(h * 0.1, base_y - h * 0.15)
        r = rnd.uniform(14, 34)
        d.polygon([(cx, cy - r), (cx + r, cy), (cx, cy + r), (cx - r, cy)],
                  outline=p["accent"] + (190,), width=2)
    return finish(base, ov)


def c08_digital_nature(p):
    base = Image.new("RGB", SIZE, p["bg"])
    ov = new_overlay()
    d = ImageDraw.Draw(ov)
    w, h = SIZE

    def grow(x, y, angle, length, depth, rnd):
        if depth == 0:
            return
        x2 = x + length * math.cos(angle)
        y2 = y + length * math.sin(angle)
        d.line((x, y, x2, y2), fill=p["accent"] + (190,), width=max(1, depth))
        if depth <= 2:
            d.ellipse((x2 - 2, y2 - 2, x2 + 2, y2 + 2), fill=p["fg"] + (160,))
        for _ in range(2):
            grow(x2, y2, angle + rnd.uniform(-0.5, 0.5), length * 0.74, depth - 1, rnd)

    rnd = random.Random(8)
    for bx in (w * 0.15, w * 0.45, w * 0.7, w * 0.92):
        grow(bx, h * 1.0, -math.pi / 2, h * 0.38, 7, rnd)
    return finish(base, ov)


def c09_mapping_the_unknown(p):
    base = Image.new("RGB", SIZE, p["bg"])
    ov = new_overlay()
    d = ImageDraw.Draw(ov)
    w, h = SIZE
    rnd = random.Random(9)
    for ring in range(10):
        cx = w * 0.4 + ring * 14
        cy = h * 0.5 + math.sin(ring) * 60
        rx, ry = 160 + ring * 46, 90 + ring * 24
        d.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), outline=p["muted"] + (100,), width=1)
    for _ in range(22):
        x, y = rnd.uniform(0, w), rnd.uniform(0, h)
        r = rnd.uniform(2, 5)
        d.ellipse((x - r, y - r, x + r, y + r), fill=p["accent"] + (230,))
    return finish(base, ov)


def c10_refraction_of_reality(p):
    base = Image.new("RGB", SIZE, p["bg"])
    ov = new_overlay()
    d = ImageDraw.Draw(ov)
    w, h = SIZE
    cx, cy = w * 0.5, h * 0.5
    d.polygon([(cx, cy - 220), (cx + 190, cy + 140), (cx - 190, cy + 140)],
              outline=p["fg"] + (190,), width=2)
    bands = [p["accent"], p["accent_dim"], p["fg"], p["muted"]]
    for i, col in enumerate(bands):
        angle = math.radians(20 + i * 14)
        x2 = cx + 900 * math.cos(angle)
        y2 = cy + 900 * math.sin(angle)
        d.line((cx, cy, x2, y2), fill=col + (140,), width=5 + i)
    return finish(base, ov)


def c11_time_and_computation(p):
    base = Image.new("RGB", SIZE, p["bg"])
    ov = new_overlay()
    d = ImageDraw.Draw(ov)
    w, h = SIZE
    cx, cy = w * 0.5, h * 0.5
    r = min(w, h) * 0.32
    d.ellipse((cx - r, cy - r, cx + r, cy + r), outline=p["accent"] + (220,), width=3)
    for i in range(60):
        angle = math.radians(i * 6)
        inner = r * (0.88 if i % 5 else 0.78)
        x1, y1 = cx + inner * math.cos(angle), cy + inner * math.sin(angle)
        x2, y2 = cx + r * math.cos(angle), cy + r * math.sin(angle)
        d.line((x1, y1, x2, y2), fill=p["muted"] + (180,), width=1 if i % 5 else 2)
    rnd = random.Random(11)
    for i in range(80):
        angle = rnd.uniform(0, math.tau)
        dist = rnd.uniform(r * 1.1, r * 1.6)
        x, y = cx + dist * math.cos(angle), cy + dist * math.sin(angle)
        bit = rnd.choice("01")
        d.text((x, y), bit, fill=p["accent_dim"] + (190,))
    return finish(base, ov)


def c12_connected_world(p):
    base = Image.new("RGB", SIZE, p["bg"])
    ov = new_overlay()
    d = ImageDraw.Draw(ov)
    w, h = SIZE
    cx, cy = w * 0.5, h * 0.52
    r = min(w, h) * 0.3
    d.ellipse((cx - r, cy - r, cx + r, cy + r), outline=p["fg"] + (200,), width=2)
    for i in range(1, 5):
        rr = r - (r / 5) * i
        d.ellipse((cx - rr, cy - rr, cx + rr, cy + rr), outline=p["muted"] + (100,), width=1)
    for i in range(7):
        x0 = cx - r + (2 * r / 6) * i
        d.arc((x0, cy - r, x0 + 2, cy + r), 0, 360, fill=p["muted"] + (100,))
    rnd = random.Random(12)
    for _ in range(10):
        angle = rnd.uniform(0, math.tau)
        x2, y2 = cx + (r + rnd.uniform(60, 220)) * math.cos(angle), cy + (r + rnd.uniform(40, 150)) * math.sin(angle)
        ex, ey = cx + r * math.cos(angle), cy + r * math.sin(angle)
        d.line((ex, ey, x2, y2), fill=p["accent"] + (190,), width=1)
        d.ellipse((x2 - 4, y2 - 4, x2 + 4, y2 + 4), fill=p["accent"] + (230,))
    return finish(base, ov)


def c13_pursuit_of_knowledge(p):
    base = vertical_gradient(SIZE, p["bg"], p["bg2"])
    ov = new_overlay()
    d = ImageDraw.Draw(ov)
    w, h = SIZE
    bx, by, bw, bh = w * 0.5 - 180, h * 0.62, 360, 110
    d.polygon([(bx, by), (bx + bw / 2, by - 18), (bx + bw, by), (bx + bw, by + bh),
               (bx + bw / 2, by + bh - 18), (bx, by + bh)], outline=p["fg"] + (220,), width=2)
    d.line((bx + bw / 2, by - 18, bx + bw / 2, by + bh - 18), fill=p["fg"] + (180,), width=1)
    rnd = random.Random(13)
    for _ in range(40):
        t = rnd.uniform(0, 1)
        x = bx + bw / 2 + rnd.uniform(-40, 40) * t
        y = by - 18 - t * h * 0.5 + rnd.uniform(-10, 10)
        r = rnd.uniform(1, 3) * (1 - t * 0.5)
        alpha = int(220 * (1 - t))
        d.ellipse((x - r, y - r, x + r, y + r), fill=p["accent"] + (max(alpha, 30),))
    return finish(base, ov)


def c14_workstation_in_pocket(p):
    base = Image.new("RGB", SIZE, p["bg"])
    cx, cy = SIZE[0] * 0.5, SIZE[1] * 0.5
    base = apply_radial_glow(base, (int(cx), int(cy)), 300, p["accent"], 0.22)
    ov = new_overlay()
    d = ImageDraw.Draw(ov)
    dw, dh = 260, 460
    d.rounded_rectangle((cx - dw / 2, cy - dh / 2, cx + dw / 2, cy + dh / 2), radius=28,
                         outline=p["fg"] + (230,), width=3, fill=p["bg2"] + (255,))
    inset = 16
    d.rounded_rectangle((cx - dw / 2 + inset, cy - dh / 2 + inset, cx + dw / 2 - inset, cy + dh / 2 - inset),
                         radius=10, fill=tuple(p["bg"]) + (255,))
    rnd = random.Random(14)
    rows = 6
    for i in range(rows):
        y = cy - dh / 2 + inset + 26 + i * 48
        bar_w = rnd.uniform(60, dw - 2 * inset - 20)
        d.rounded_rectangle((cx - dw / 2 + inset + 10, y, cx - dw / 2 + inset + 10 + bar_w, y + 14),
                             radius=6, fill=p["accent_dim"] + (200,))
    return finish(base, ov)


def c15_beyond_the_horizon(p):
    base = vertical_gradient(SIZE, p["bg2"], p["bg"])
    w, h = SIZE
    horizon_y = h * 0.62
    base = apply_radial_glow(base, (int(w * 0.5), int(horizon_y)), 520, p["accent"], 0.45)
    ov = new_overlay()
    d = ImageDraw.Draw(ov)
    cx = w * 0.5
    d.ellipse((cx - 110, horizon_y - 110, cx + 110, horizon_y + 110), fill=p["accent"] + (235,))
    rnd = random.Random(15)
    layers = 3
    for layer in range(layers):
        pts = [(0, horizon_y + 40 + layer * 50)]
        x = 0
        while x < w:
            x += rnd.uniform(80, 180)
            pts.append((x, horizon_y + 40 + layer * 50 + rnd.uniform(-30, 30)))
        pts.append((w, h))
        pts.append((0, h))
        shade = lerp(p["bg2"], p["bg"], layer / layers)
        d.polygon(pts, fill=shade + (255,))
    return finish(base, ov)


CONCEPTS = [
    ("01-infinite-computing", "Infinite Computing",
     "Nested diminishing frames converging toward a vanishing point, evoking recursive, boundless computation.",
     c01_infinite_computing),
    ("02-neural-intelligence", "Neural Intelligence",
     "A dense web of nodes and weighted connections, modeling a neural network's distributed thought.",
     c02_neural_intelligence),
    ("03-flow-of-information", "Flow of Information",
     "Streaming horizontal lines of varying weight and length, representing continuous data in motion.",
     c03_flow_of_information),
    ("04-cosmic-perspective", "Cosmic Perspective",
     "A distant glowing body set against a quiet starfield, framed by faint orbital rings.",
     c04_cosmic_perspective),
    ("05-living-circuits", "Living Circuits",
     "Branching circuit traces that grow like roots, blurring the line between organic and engineered.",
     c05_living_circuits),
    ("06-mathematical-order", "Mathematical Order",
     "A disciplined grid of repeating geometric forms, quietly asserting structure and proportion.",
     c06_mathematical_order),
    ("07-architecture-of-thought", "The Architecture of Thought",
     "A skyline of abstract structures beneath floating geometric fragments, like ideas taking shape.",
     c07_architecture_of_thought),
    ("08-digital-nature", "Digital Nature",
     "Circuit-like branches growing upward in place of trees, nature rendered in the language of technology.",
     c08_digital_nature),
    ("09-mapping-the-unknown", "Mapping the Unknown",
     "Topographic contour rings and scattered waypoints, charting territory not yet understood.",
     c09_mapping_the_unknown),
    ("10-refraction-of-reality", "Refraction of Reality",
     "A prism splitting a single path into divergent colored bands of light.",
     c10_refraction_of_reality),
    ("11-time-and-computation", "Time and Computation",
     "A clock face ringed with binary digits, pairing the measure of time with the language of machines.",
     c11_time_and_computation),
    ("12-connected-world", "Connected World",
     "A globe traced with latitude lines and reaching connection arcs, mapping a networked planet.",
     c12_connected_world),
    ("13-the-pursuit-of-knowledge", "The Pursuit of Knowledge",
     "An open book releasing a rising column of light and particles, knowledge in quiet ascent.",
     c13_pursuit_of_knowledge),
    ("14-workstation-in-your-pocket", "Workstation in Your Pocket",
     "A handheld device rendered as a glowing, structured screen — the literal tagline, illustrated.",
     c14_workstation_in_pocket),
    ("15-beyond-the-horizon", "Beyond the Horizon",
     "A glowing horizon line layered with soft silhouettes, suggesting what lies just past the edge.",
     c15_beyond_the_horizon),
]


def generate_all():
    OUT_ROOT.mkdir(parents=True, exist_ok=True)
    manifest = {"schema": "ternux.wallpapers/v1", "wallpapers": []}
    for wid, name, description, draw_fn in CONCEPTS:
        concept_dir = OUT_ROOT / wid
        concept_dir.mkdir(parents=True, exist_ok=True)
        entry = {
            "id": wid,
            "concept": name,
            "description": description,
            "resolution": f"{SIZE[0]}x{SIZE[1]}",
            "colorways": {},
        }
        for colorway, palette in PALETTES.items():
            img = draw_fn(palette)
            source_path = concept_dir / f"{colorway}-source.png"
            asset_path = concept_dir / f"{colorway}.webp"
            preview_path = concept_dir / f"{colorway}-preview.webp"
            img.save(source_path, optimize=True)
            img.save(asset_path, "WEBP", quality=88)
            img.resize(PREVIEW_SIZE, Image.LANCZOS).save(preview_path, "WEBP", quality=80)
            entry["colorways"][colorway] = {
                "source_path": str(source_path.relative_to(REPO_ROOT)),
                "asset_path": str(asset_path.relative_to(REPO_ROOT)),
                "preview_path": str(preview_path.relative_to(REPO_ROOT)),
            }
        manifest["wallpapers"].append(entry)
        print(f"generated {wid}")
    (OUT_ROOT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"wrote manifest with {len(manifest['wallpapers'])} wallpapers")


if __name__ == "__main__":
    generate_all()
