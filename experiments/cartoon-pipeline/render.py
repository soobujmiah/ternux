"""Render one shot of the film.

    blender -b --factory-startup --python render.py -- --shot 2 [--still 70] [--range 1:48]

Writes PNG frames to out/shotN/f_####.png. One Blender process renders a whole
shot: shader compilation is paid once per process, so rendering frame by frame
in separate processes wastes roughly twenty seconds each.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bpy  # noqa: E402

import scene  # noqa: E402
from shots import SHOTS  # noqa: E402

ARGV = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
HERE = os.path.dirname(os.path.abspath(__file__))


def arg(name, default=None):
    return ARGV[ARGV.index(name) + 1] if name in ARGV else default


def build(shot_index):
    s = scene.new_scene()
    scene.world()
    scene.lights()
    scene.meadow()
    flower = scene.hero_flower()
    rig = scene.build_bulbul()
    length = SHOTS[shot_index - 1](rig, flower)
    s.frame_start, s.frame_end = 1, length
    return s, length


def main():
    shot = int(arg("--shot", "1"))
    out = arg("--out", os.path.join(HERE, "out"))
    s, length = build(shot)
    s.render.image_settings.file_format = "PNG"
    s.render.image_settings.color_mode = "RGB"

    still = arg("--still")
    if still:
        s.frame_set(int(still))
        s.render.filepath = os.path.join(out, f"still_shot{shot}_{int(still):04d}")
        bpy.ops.render.render(write_still=True)
        return

    rng = arg("--range")
    if rng:
        a, b = (int(x) for x in rng.split(":"))
        s.frame_start, s.frame_end = a, b
    s.render.filepath = os.path.join(out, f"shot{shot}", "f_")
    if "--save-blend" in ARGV:
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out, f"shot{shot}.blend"))
    bpy.ops.render.render(animation=True)
    print(f"SHOT {shot} RENDERED frames 1..{length}")


main()
