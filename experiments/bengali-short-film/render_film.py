"""Render one scene of the film.

    blender -b --factory-startup --python render_film.py -- --scene 3 [--still 120] [--range a:b]
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy
import film

ARGV = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
def arg(n, d=None): return ARGV[ARGV.index(n) + 1] if n in ARGV else d

scene_no = int(arg("--scene", "1"))
out = arg("--out", os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "renders"))
samples = int(arg("--samples", "24"))
s, length = film.build_scene(scene_no, samples=samples)
s.render.image_settings.file_format = "PNG"
s.render.image_settings.color_mode = "RGB"

stills = arg("--stills") or arg("--still")
if stills:
    for fr in (int(x) for x in str(stills).split(",")):
        s.frame_set(fr)
        s.render.filepath = os.path.join(out, f"still_s{scene_no}_{fr:04d}")
        bpy.ops.render.render(write_still=True)
else:
    rng = arg("--range")
    if rng:
        a, b = (int(x) for x in rng.split(":"))
        s.frame_start, s.frame_end = a, b
    if "--save-blend" in ARGV:
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out, "..", "scenes", "mithyar_mic.blend"))
    s.render.filepath = os.path.join(out, f"shot_{scene_no:02d}", "f_")
    bpy.ops.render.render(animation=True)
    print(f"SCENE {scene_no} RENDERED 1..{length}")
