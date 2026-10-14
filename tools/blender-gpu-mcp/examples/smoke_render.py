"""One-frame EEVEE smoke render — proof that the GPU path is live.

Run through this directory's MCP server (`render_script`), or directly:

    DISPLAY=:9 GALLIUM_DRIVER=zink blender -b --factory-startup \
        --python examples/smoke_render.py -- /absolute/output/frame.png

It renders the startup cube small and cheap: the point is whether EEVEE Next
reaches the Adreno at all, not what the picture looks like.
"""

import sys

import bpy

output = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else "/tmp/ternux-blender-smoke.png"

scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE_NEXT"
scene.render.resolution_x = 320
scene.render.resolution_y = 180
scene.render.resolution_percentage = 100
scene.eevee.taa_render_samples = 4
scene.render.image_settings.file_format = "PNG"
scene.render.filepath = output
scene.view_settings.view_transform = "Standard"

bpy.ops.render.render(write_still=True)
print(f"smoke_render wrote {output}")
