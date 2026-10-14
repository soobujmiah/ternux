"""Save the project scene file without rendering it.

    blender -b --factory-startup --python save_blend.py -- [--scene 3]
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy
import film

ARGV = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
scene_no = int(ARGV[ARGV.index("--scene") + 1]) if "--scene" in ARGV else 3
root = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
out = os.path.join(root, "scenes", "mithyar_mic.blend")
os.makedirs(os.path.dirname(out), exist_ok=True)
film.build_scene(scene_no, samples=24)
bpy.ops.wm.save_as_mainfile(filepath=out)
print("SAVED", out, f"(scene {scene_no})")
