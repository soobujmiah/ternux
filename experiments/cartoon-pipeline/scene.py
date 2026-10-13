"""Shared world: materials, environment, the character, and the hero flower.

Everything is built from Blender primitives in code. Nothing is downloaded and
nothing is modelled by hand, so a checkout plus Blender reproduces the film
exactly.
"""

import math

import bpy

FPS = 24
RES = (1280, 720)
SAMPLES = 16


# ----------------------------------------------------------------- primitives

def new_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    s = bpy.context.scene
    s.render.engine = "BLENDER_EEVEE_NEXT"
    s.render.resolution_x, s.render.resolution_y = RES
    s.render.resolution_percentage = 100
    s.render.fps = FPS
    s.eevee.taa_render_samples = SAMPLES
    # Flat cartoon response: AgX desaturates the palette, and raytraced AO only
    # adds grain at 16 samples.
    s.view_settings.view_transform = "Standard"
    s.view_settings.look = "None"
    if hasattr(s.eevee, "use_shadows"):
        s.eevee.use_shadows = True
    if hasattr(s.eevee, "use_raytracing"):
        s.eevee.use_raytracing = False
    return s


def mat(name, rgb, rough=0.55, emit=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*rgb, 1.0)
    b.inputs["Roughness"].default_value = rough
    if emit:
        b.inputs["Emission Color"].default_value = (*rgb, 1.0)
        b.inputs["Emission Strength"].default_value = emit
    return m


def shade(obj, material, smooth=True):
    obj.data.materials.append(material)
    if smooth:
        for p in obj.data.polygons:
            p.use_smooth = True
    return obj


def sphere(name, loc, scale, segs=32, rings=16):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segs, ring_count=rings, location=loc)
    o = bpy.context.object
    o.name = name
    o.scale = scale
    return o


def attach(child, parent):
    """Parent without moving the child. Every position in this project is
    written in world space, so the parent inverse absorbs the parent's offset."""
    bpy.context.view_layer.update()
    child.parent = parent
    child.matrix_parent_inverse = parent.matrix_world.inverted()
    return child


def empty(name, loc, parent=None):
    e = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(e)
    e.location = loc
    e.empty_display_size = 0.25
    if parent:
        attach(e, parent)
    return e


def key(obj, path, frame, value=None, interp="BEZIER", index=-1):
    if value is not None:
        setattr(obj, path, value)
    obj.keyframe_insert(data_path=path, frame=frame)
    if not (obj.animation_data and obj.animation_data.action):
        return
    for fc in obj.animation_data.action.fcurves:
        if fc.data_path != path:
            continue
        for kp in fc.keyframe_points:
            if abs(kp.co.x - frame) < 0.01:
                kp.interpolation = interp
                if interp == "BEZIER":
                    kp.easing = "EASE_IN_OUT"


# --------------------------------------------------------------- environment

def world(strength=0.55):
    w = bpy.data.worlds.new("sky")
    bpy.context.scene.world = w
    w.use_nodes = True
    bg = w.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = (0.42, 0.72, 0.95, 1.0)
    bg.inputs["Strength"].default_value = strength


def lights():
    bpy.ops.object.light_add(type="SUN", location=(4, -5, 8))
    sun = bpy.context.object
    sun.data.energy = 2.6
    sun.data.angle = math.radians(3)
    sun.rotation_euler = (math.radians(50), math.radians(10), math.radians(35))

    bpy.ops.object.light_add(type="AREA", location=(-5, -4, 3))
    fill = bpy.context.object
    fill.data.energy = 90
    fill.data.size = 6
    fill.data.color = (0.75, 0.85, 1.0)
    fill.rotation_euler = (math.radians(70), 0, math.radians(-55))

    bpy.ops.object.light_add(type="AREA", location=(0, 5.5, 3.5))
    rim = bpy.context.object
    rim.data.energy = 140
    rim.data.size = 4
    rim.data.color = (1.0, 0.92, 0.75)
    rim.rotation_euler = (math.radians(-60), 0, 0)


def meadow():
    grass = mat("grass", (0.20, 0.52, 0.18), rough=0.8)
    hill = mat("hill", (0.16, 0.44, 0.20), rough=0.85)
    trunk = mat("trunk", (0.35, 0.22, 0.12), rough=0.9)
    leaf = mat("leaf", (0.13, 0.46, 0.17), rough=0.75)
    stone_c = mat("stone", (0.55, 0.55, 0.58), rough=0.9)
    petal_c = mat("petal", (0.95, 0.35, 0.55), rough=0.6)
    core_c = mat("core", (1.0, 0.85, 0.25), rough=0.5, emit=0.15)
    stem_c = mat("stem", (0.18, 0.45, 0.16), rough=0.8)

    bpy.ops.mesh.primitive_plane_add(size=60, location=(0, 0, 0))
    shade(bpy.context.object, grass, smooth=False).name = "ground"

    for i, (x, y, r) in enumerate([(-7, 9, 3.4), (6, 12, 4.2), (13, 16, 5.0)]):
        shade(sphere(f"hill{i}", (x, y, -r * 0.55), (r, r, r * 0.7), 24, 12), hill)

    for i, (x, y, sc) in enumerate([(-4.2, 4.5, 1.0), (4.8, 6.0, 1.25), (-8.5, 7.0, 1.1)]):
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.16 * sc, depth=1.6 * sc,
                                            location=(x, y, 0.8 * sc))
        shade(bpy.context.object, trunk, smooth=False).name = f"trunk{i}"
        for j, (dx, dz, r) in enumerate([(0, 1.9, 0.95), (0.45, 1.5, 0.6), (-0.4, 1.6, 0.55)]):
            shade(sphere(f"leaf{i}_{j}", (x + dx * sc, y, dz * sc),
                         (r * sc, r * sc, r * sc * 0.9), 20, 10), leaf)

    for i, (x, y, r) in enumerate([(-2.6, 1.2, 0.22), (3.1, 2.4, 0.3), (-3.9, 2.9, 0.17)]):
        shade(sphere(f"stone{i}", (x, y, r * 0.45), (r, r * 1.3, r * 0.6), 14, 8), stone_c)

    for i, (x, y) in enumerate([(-2.0, -0.6), (2.9, 0.1), (-3.0, 0.9), (3.4, -0.4), (1.4, 1.8)]):
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.025, depth=0.34,
                                            location=(x, y, 0.17))
        shade(bpy.context.object, stem_c, smooth=False).name = f"stem{i}"
        for k in range(5):
            a = math.radians(72 * k)
            shade(sphere(f"petal{i}_{k}", (x + 0.1 * math.cos(a), y + 0.1 * math.sin(a), 0.36),
                         (0.07, 0.07, 0.03), 10, 6), petal_c)
        shade(sphere(f"core{i}", (x, y, 0.38), (0.05, 0.05, 0.035), 10, 6), core_c)


def hero_flower(x=2.60, y=0.35):
    """The tall flower the short is about. Its head sits on a bend empty at the
    base of the stem, so one rotation bends the whole plant like a spring."""
    stem_c = mat("hero_stem", (0.20, 0.50, 0.18), rough=0.75)
    petal_c = mat("hero_petal", (1.0, 0.42, 0.62), rough=0.5)
    core_c = mat("hero_core", (1.0, 0.82, 0.22), rough=0.45, emit=0.25)
    leaf_c = mat("hero_leaf", (0.17, 0.47, 0.17), rough=0.7)

    bend = empty("flower_bend", (x, y, 0.0))
    head = empty("flower_head", (x, y, 2.00), bend)

    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.055, depth=2.05, location=(x, y, 1.02))
    shade(bpy.context.object, stem_c, smooth=False).name = "hero_stem"
    attach(bpy.context.object, bend)

    for i, (side, z) in enumerate([(-1, 0.75), (1, 1.20)]):
        lf = sphere(f"hero_leaf{i}", (x + 0.22 * side, y, z), (0.2, 0.1, 0.07), 16, 8)
        shade(lf, leaf_c)
        lf.rotation_euler = (0, math.radians(35 * side), 0)
        attach(lf, bend)

    petals = []
    for k in range(6):
        a = math.radians(60 * k)
        p = sphere(f"hero_petal{k}", (x + 0.28 * math.cos(a), y + 0.28 * math.sin(a), 2.02),
                   (0.20, 0.20, 0.06), 16, 8)
        shade(p, petal_c)
        attach(p, head)
        petals.append(p)

    petals2 = []
    for k in range(6):
        a = math.radians(60 * k + 30)
        p = sphere(f"hero_petal2_{k}", (x + 0.28 * math.cos(a), y + 0.28 * math.sin(a), 1.98),
                   (0.0001, 0.0001, 0.0001), 16, 8)
        shade(p, petal_c)
        attach(p, head)
        petals2.append(p)

    core = sphere("hero_core", (x, y, 2.05), (0.16, 0.16, 0.10), 16, 8)
    shade(core, core_c)
    attach(core, head)

    return dict(bend=bend, head=head, petals=petals, petals2=petals2,
                core=core, pos=(x, y))


# ------------------------------------------------------------------ character

def build_bulbul():
    body_c = mat("body", (0.98, 0.62, 0.18), rough=0.45)
    belly_c = mat("belly", (1.0, 0.86, 0.55), rough=0.5)
    beak_c = mat("beak", (0.95, 0.38, 0.12), rough=0.4)
    white_c = mat("eyewhite", (1.0, 1.0, 1.0), rough=0.25)
    dark_c = mat("pupil", (0.05, 0.05, 0.08), rough=0.3)
    foot_c = mat("foot", (0.92, 0.45, 0.14), rough=0.5)
    tuft_c = mat("tuft", (0.35, 0.18, 0.45), rough=0.5)
    glint_c = mat("glint", (1, 1, 1), rough=0.1, emit=0.6)

    ctrl = empty("ctrl", (0, 0, 0))            # where he is in the world
    squash = empty("squash", (0, 0, 0), ctrl)  # squash and stretch, from the feet
    lean = empty("lean", (0, 0, 0.9), squash)  # whole-body tilt

    shade(attach(sphere("body", (0, 0, 0.95), (0.95, 0.9, 1.0)), lean), body_c)
    shade(attach(sphere("belly", (0, -0.54, 0.76), (0.55, 0.46, 0.58)), lean), belly_c)

    head = empty("head_pivot", (0, 0, 1.45), lean)
    eyes, pupils = [], []
    for name, side in (("eye_l", -1), ("eye_r", 1)):
        w = shade(attach(sphere(name + "_white", (0.34 * side, -0.74, 1.62),
                                (0.27, 0.22, 0.30)), head), white_c)
        p = shade(attach(sphere(name + "_pupil", (0.37 * side, -0.92, 1.62),
                                (0.13, 0.10, 0.15)), head), dark_c)
        shade(attach(sphere(name + "_glint", (0.42 * side, -1.0, 1.70),
                            (0.045, 0.035, 0.05)), head), glint_c)
        eyes.append(w)
        pupils.append(p)

    bpy.ops.mesh.primitive_cone_add(vertices=16, radius1=0.22, depth=0.5,
                                    location=(0, -1.0, 1.38),
                                    rotation=(math.radians(-90), 0, 0))
    beak = bpy.context.object
    beak.name = "beak"
    shade(attach(beak, head), beak_c)

    tufts = []
    for j, (dx, dz, r) in enumerate([(0, 0.52, 0.17), (0.16, 0.66, 0.12), (-0.14, 0.64, 0.11)]):
        tufts.append(shade(attach(sphere(f"tuft{j}", (dx, 0.05, 1.45 + dz),
                                         (r, r, r * 1.3), 16, 8), head), tuft_c))

    arms = {}
    for name, side in (("arm_l", -1), ("arm_r", 1)):
        pivot = empty(name + "_pivot", (0.70 * side, 0, 1.24), lean)
        a = shade(attach(sphere(name, (1.24 * side, -0.08, 0.86), (0.42, 0.2, 0.17), 20, 10),
                         pivot), body_c)
        a.rotation_euler = (0, math.radians(22 * side), math.radians(-14 * side))
        arms[name] = pivot

    for name, side in (("foot_l", -1), ("foot_r", 1)):
        shade(attach(sphere(name, (0.33 * side, -0.14, 0.11), (0.3, 0.42, 0.13), 20, 10),
                     lean), foot_c)

    return dict(ctrl=ctrl, squash=squash, lean=lean, head=head, arms=arms,
                eyes=eyes, pupils=pupils, tufts=tufts)


# ------------------------------------------------------------------- acting

def blink(rig, frame):
    """A two-frame blink, as the eye whites flattening."""
    for e in rig["eyes"]:
        base = tuple(e.scale)
        key(e, "scale", frame - 1, base)
        key(e, "scale", frame + 1, (base[0], base[1], base[2] * 0.08), interp="LINEAR")
        key(e, "scale", frame + 3, base, interp="LINEAR")


def hop(rig, start, end, from_xy, to_xy, height=1.1, squash_amount=0.28):
    """One cartoon hop: anticipation crouch, stretched arc, landing squash."""
    squash, ctrl = rig["squash"], rig["ctrl"]
    mid = (start + end) // 2
    x0, y0 = from_xy
    x1, y1 = to_xy
    key(ctrl, "location", start, (x0, y0, 0))
    key(squash, "scale", start, (1.0, 1.0, 1.0))
    key(squash, "scale", start + 4, (1 + squash_amount, 1 + squash_amount, 1 - squash_amount))
    key(squash, "scale", start + 7, (1 - squash_amount * 0.7, 1 - squash_amount * 0.7,
                                     1 + squash_amount * 0.9), interp="LINEAR")
    key(ctrl, "location", start + 7, (x0, y0, 0.15), interp="LINEAR")
    key(ctrl, "location", mid, ((x0 + x1) / 2, (y0 + y1) / 2, height))
    key(squash, "scale", mid, (0.92, 0.92, 1.08))
    key(ctrl, "location", end, (x1, y1, 0), interp="LINEAR")
    key(squash, "scale", end + 1, (1 + squash_amount, 1 + squash_amount, 1 - squash_amount),
        interp="LINEAR")
    key(squash, "scale", end + 5, (0.95, 0.95, 1.05))
    key(squash, "scale", end + 9, (1.0, 1.0, 1.0))


def camera(name, loc, rot, lens=40):
    bpy.ops.object.camera_add(location=loc, rotation=rot)
    cam = bpy.context.object
    cam.name = name
    cam.data.lens = lens
    bpy.context.scene.camera = cam
    return cam
