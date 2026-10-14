"""মিথ্যার মাইক — scene construction and animation.

Five scenes, cut into twelve shots. One camera is keyed with constant
interpolation, so a key change is an instant cut rather than a move.
"""

import json
import math
import os
import random

import bpy
from mathutils import Vector

import environment as ENV
import humans as H

FPS = 24
SCENE_FRAMES = [240, 288, 312, 312, 288]          # 10 + 12 + 13 + 13 + 12 = 60 s
HERE = os.path.dirname(os.path.abspath(__file__))
LIPSYNC = json.load(open(os.path.join(HERE, "..", "assets", "lipsync.json")))

# dialogue start, in seconds from the start of its own scene
CUES = {
    "s1_pol": (1, 3.4), "s2_pol": (2, 1.5), "s3_jour": (3, 4.0),
    "s3_pol": (3, 8.4), "s4_pol": (4, 1.0), "s5_child": (5, 1.8),
}


def key(obj, path, frame, value=None, interp="BEZIER"):
    if value is not None:
        setattr(obj, path, value)
    obj.keyframe_insert(data_path=path, frame=frame)
    # sub-structs such as camera DOF settings keep their curves on the owning ID
    if not (hasattr(obj, "animation_data") and obj.animation_data and obj.animation_data.action):
        return
    for fc in obj.animation_data.action.fcurves:
        if fc.data_path != path:
            continue
        for kp in fc.keyframe_points:
            if abs(kp.co.x - frame) < 0.01:
                kp.interpolation = interp
                if interp == "BEZIER":
                    kp.easing = "EASE_IN_OUT"


# --------------------------------------------------------------------- cast

def crowd_figure(name, loc, facing, params, rnd):
    """A background person: the same silhouette, none of the facial detail."""
    scale_h = params.get("height", 1.68) / 1.72
    root = bpy.data.objects.new(f"{name}_root", None)
    bpy.context.collection.objects.link(root)

    cloth = H.mat(f"{name}_cloth", params["cloth"], rough=0.85, sheen=0.3)
    skin = H.mat(f"{name}_skin", params.get("tone", (0.15, 0.075, 0.042)), rough=0.5, sss=0.1)

    prof = [(z * scale_h, w * 1.02 + 0.012, df * 1.02 + 0.012, db * 1.02 + 0.012, s)
            for (z, w, df, db, s) in H.BODY_PROFILE_M]
    prof.append((0.62 * scale_h, 0.17, 0.14, 0.14, 0.9))
    body, _, _ = __import__("head").loft(f"{name}_body", prof, rings=18, segments=24)
    body.data.materials.append(cloth)
    H.smooth(body, subsurf=1)
    H.attach(body, root)

    for sx in (-1, 1):
        arm = H.limb(f"{name}_arm{sx}", [(sx * 0.17 * scale_h, 0, 1.40 * scale_h),
                                         (sx * 0.19 * scale_h, 0.03, 1.10 * scale_h),
                                         (sx * 0.18 * scale_h, 0.05, 0.86 * scale_h)],
                     [0.048, 0.036, 0.030], segments=10)
        arm.data.materials.append(cloth)
        H.smooth(arm, subsurf=1)
        H.attach(arm, root)
        leg = H.limb(f"{name}_leg{sx}", [(sx * 0.07, 0, 0.94 * scale_h), (sx * 0.075, 0.01, 0.03)],
                     [0.080, 0.050], segments=10)
        leg.data.materials.append(H.mat(f"{name}_tr", params.get("trouser", (0.09, 0.09, 0.1)), rough=0.85))
        H.smooth(leg, subsurf=1)
        H.attach(leg, root)

    neck = H.limb(f"{name}_neck", [(0, 0, 1.40 * scale_h), (0, 0.004, 1.48 * scale_h)],
                  [0.042, 0.040], segments=12)
    neck.data.materials.append(skin)
    H.smooth(neck, subsurf=1)
    H.attach(neck, root)

    headm = H.noisy_sphere(f"{name}_head", (0, 0.004, 1.575 * scale_h),
                           (0.080, 0.094, 0.110), 0.03, 6.0, segs=24, rings=16,
                           seed=rnd.randint(0, 99))
    headm.data.materials.append(skin)
    H.smooth(headm, subsurf=1)
    H.attach(headm, root)
    hair = H.noisy_sphere(f"{name}_hair", (0, 0.012, 1.615 * scale_h),
                          (0.082, 0.090, 0.075), 0.06, 8.0, segs=20, rings=12,
                          seed=rnd.randint(0, 99))
    hair.data.materials.append(H.mat(f"{name}_hairm", params.get("hair", (0.028, 0.02, 0.016)), rough=0.5))
    H.smooth(hair, subsurf=1)
    H.attach(hair, root)
    root.location = loc
    root.rotation_euler = (0, 0, math.radians(facing))
    return dict(root=root, head=headm)


def build_cast():
    rnd = random.Random(21)
    cast = {}

    cast["politician"] = H.make_character("politician", dict(
        height=1.74, build=1.18, seed=11, age=0.6, jaw=1.15, nose=0.95, cheek=1.05,
        tone=(0.168, 0.085, 0.048), hair="combed", grey=0.5, moustache=True,
        garment="panjabi", waistcoat=True, cloth=(0.72, 0.70, 0.64),
        vest=(0.030, 0.034, 0.048), trouser=(0.12, 0.12, 0.13),
        location=(0, 5.78, 1.10), facing=0))

    cast["journalist"] = H.make_character("journalist", dict(
        height=1.68, build=0.98, seed=23, age=0.35, jaw=0.95, nose=1.0,
        tone=(0.155, 0.078, 0.045), hair="combed", grey=0.0, moustache=False,
        garment="shirt", waistcoat=False, cloth=(0.30, 0.34, 0.42),
        trouser=(0.07, 0.075, 0.09), location=(1.95, 3.35, 0), facing=186))

    cast["citizen"] = H.make_character("citizen", dict(
        height=1.70, build=1.05, seed=31, age=0.5, jaw=1.05,
        tone=(0.14, 0.07, 0.04), hair="combed", grey=0.2, moustache=True,
        garment="shirt", cloth=(0.36, 0.30, 0.22), trouser=(0.10, 0.09, 0.08),
        location=(3.45, 2.70, 0), facing=205))

    cast["youth"] = H.make_character("youth", dict(
        height=1.66, build=0.92, seed=43, age=0.15, jaw=0.9, nose=0.92,
        tone=(0.16, 0.082, 0.05), hair="long", grey=0.0,
        garment="shirt", cloth=(0.12, 0.26, 0.20), trouser=(0.08, 0.085, 0.11),
        location=(-1.95, 3.45, 0), facing=178))

    cast["mother"] = H.make_character("mother", dict(
        height=1.60, build=0.95, seed=57, age=0.35, jaw=0.85, nose=0.9, cheek=1.1,
        tone=(0.17, 0.088, 0.052), hair="long", grey=0.05, mouth_w=0.92,
        garment="sari", cloth=(0.40, 0.10, 0.22), trouser=(0.30, 0.08, 0.18),
        location=(-2.52, 0.78, 0), facing=172))

    cast["child"] = H.make_character("child", dict(
        height=1.14, build=0.80, seed=67, age=0.05, child=True, head_scale=0.90,
        jaw=0.8, nose=0.85, cheek=1.2, mouth_w=0.9,
        tone=(0.175, 0.092, 0.055), hair="combed", grey=0.0,
        garment="shirt", cloth=(0.55, 0.42, 0.12), trouser=(0.12, 0.14, 0.2),
        location=(-2.14, 0.70, 0), facing=170))

    # the phone travels with the hand that holds it
    bpy.context.view_layer.update()
    wrist = cast["youth"]["arms"]["r"]["wrist"]
    w = wrist.matrix_world.translation
    phone = ENV.box("phone", (w.x + 0.02, w.y - 0.075, w.z - 0.055), (0.072, 0.012, 0.145),
                    H.mat("phone_m", (0.02, 0.02, 0.025), rough=0.25))
    screen = ENV.box("phone_screen", (w.x + 0.02, w.y - 0.082, w.z - 0.055), (0.063, 0.002, 0.129),
                     H.mat("phone_screen_m", (0.10, 0.16, 0.22), rough=0.1, emit=1.6))
    H.attach(phone, wrist)
    H.attach(screen, wrist)
    cast["phone"] = phone

    # the microphone, in the journalist's hand rather than beside it
    bpy.context.view_layer.update()
    jwrist = cast["journalist"]["arms"]["r"]["wrist"]
    jw = jwrist.matrix_world.translation
    jmic = H.limb("jmic", [(jw.x, jw.y - 0.02, jw.z - 0.10), (jw.x, jw.y - 0.06, jw.z + 0.10)],
                  [0.016, 0.023], segments=10)
    jmic.data.materials.append(H.mat("jmic_m", (0.05, 0.05, 0.055), rough=0.45))
    H.smooth(jmic, subsurf=1)
    H.attach(jmic, jwrist)
    cast["jmic"] = jmic

    palette = [(0.52, 0.50, 0.46), (0.22, 0.28, 0.38), (0.40, 0.16, 0.14), (0.18, 0.30, 0.22),
               (0.55, 0.45, 0.20), (0.30, 0.30, 0.34), (0.46, 0.38, 0.30)]
    crowd = []
    # nobody stands in a sight-line: the speaking characters keep a clear metre
    spots = [(-4.5, 1.3), (-4.6, 2.9), (-3.3, 1.7), (-1.1, 2.7), (-0.2, 1.1),
             (0.5, 2.4), (1.5, 0.5), (0.1, 0.3), (2.4, 0.8), (5.2, 2.9), (3.8, 1.0),
             (4.4, 2.4), (-4.9, 3.0), (-5.8, 2.3), (2.1, 1.6), (4.7, 1.4), (-5.4, 1.9)]
    for i, (x, y) in enumerate(spots):
        crowd.append(crowd_figure(f"crowd{i}", (x, y, 0), 180 + rnd.uniform(-16, 16),
                                  dict(height=rnd.uniform(1.55, 1.78),
                                       cloth=palette[i % len(palette)],
                                       trouser=(0.08, 0.08, 0.09)), rnd))
    cast["crowd"] = crowd
    return cast


def lighting(scene):
    bpy.ops.object.light_add(type="SUN", location=(-7, -4, 9))
    sun = bpy.context.object
    sun.data.energy = 3.4
    sun.data.angle = math.radians(2.2)
    sun.data.color = (1.0, 0.90, 0.78)
    sun.rotation_euler = (math.radians(50), 0, math.radians(-38))

    bpy.ops.object.light_add(type="AREA", location=(5, -5, 4))
    fill = bpy.context.object
    fill.data.energy = 220
    fill.data.size = 9
    fill.data.color = (0.72, 0.82, 1.0)
    fill.data.use_shadow = False          # a sky fill does not need its own shadow map
    fill.rotation_euler = (math.radians(66), 0, math.radians(44))

    w = bpy.data.worlds.new("sky")
    scene.world = w
    w.use_nodes = True
    nt = w.node_tree
    bg = nt.nodes["Background"]
    grad = nt.nodes.new("ShaderNodeTexGradient")
    grad.gradient_type = "EASING"
    mapn = nt.nodes.new("ShaderNodeMapping")
    texc = nt.nodes.new("ShaderNodeTexCoord")
    mapn.inputs["Rotation"].default_value = (math.radians(90), 0, 0)
    nt.links.new(texc.outputs["Generated"], mapn.inputs["Vector"])
    nt.links.new(mapn.outputs["Vector"], grad.inputs["Vector"])
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.42
    ramp.color_ramp.elements[0].color = (0.62, 0.55, 0.44, 1)      # hazy horizon
    ramp.color_ramp.elements[1].position = 0.78
    ramp.color_ramp.elements[1].color = (0.20, 0.33, 0.52, 1)      # sky
    nt.links.new(grad.outputs["Fac"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], bg.inputs["Color"])
    bg.inputs["Strength"].default_value = 0.85
    return sun


# ---------------------------------------------------------------- performance

def speak(member, line_id, start):
    """Drive the mouth from the dialogue's own envelope, frame by frame."""
    env = LIPSYNC[line_id]["openness"]
    face = member["head"]
    up, low, cav = face["lips"]["upper"], face["lips"]["lower"], face["cavity"]
    uz, lz = up.location.z, low.location.z
    cs = tuple(cav.scale)
    key(up, "location", start - 2, interp="LINEAR")
    key(low, "location", start - 2, interp="LINEAR")
    key(cav, "scale", start - 2, interp="LINEAR")
    for i, o in enumerate(env):
        f = start + i
        low.location.z = lz - 0.0165 * o
        up.location.z = uz + 0.0042 * o
        cav.scale = (cs[0] * (1 + 0.25 * o), cs[1] * (1 + 0.5 * o), cs[2] * (1 + 1.9 * o))
        key(low, "location", f, interp="LINEAR")
        key(up, "location", f, interp="LINEAR")
        key(cav, "scale", f, interp="LINEAR")
    low.location.z, up.location.z, cav.scale = lz, uz, cs
    key(low, "location", start + len(env) + 3, interp="LINEAR")
    key(up, "location", start + len(env) + 3, interp="LINEAR")
    key(cav, "scale", start + len(env) + 3, interp="LINEAR")
    return start + len(env)


def blink(member, frame):
    for pivot in member["head"]["lids"]:
        rest = pivot.rotation_euler.x
        key(pivot, "rotation_euler", frame - 2, interp="LINEAR")
        pivot.rotation_euler.x = math.radians(44)
        key(pivot, "rotation_euler", frame, interp="LINEAR")
        pivot.rotation_euler.x = rest
        key(pivot, "rotation_euler", frame + 3, interp="LINEAR")


def blinks(member, start, end, every=58, phase=0):
    f = start + phase
    while f < end:
        blink(member, f)
        f += every


def head_turn(member, frame, yaw=0.0, pitch=0.0, interp="BEZIER"):
    p = member["head_pivot"]
    p.rotation_euler = (math.radians(pitch), 0, math.radians(yaw))
    key(p, "rotation_euler", frame, interp=interp)


def arm(member, side, frame, shoulder=None, elbow=None, interp="BEZIER"):
    a = member["arms"][side]
    if shoulder is not None:
        a["shoulder"].rotation_euler = tuple(math.radians(v) for v in shoulder)
        key(a["shoulder"], "rotation_euler", frame, interp=interp)
    if elbow is not None:
        a["elbow"].rotation_euler = tuple(math.radians(v) for v in elbow)
        key(a["elbow"], "rotation_euler", frame, interp=interp)


def sway(member, start, end, amount=2.0, period=70):
    """A standing figure is never still."""
    f = start
    i = 0
    while f <= end:
        member["spine"].rotation_euler = (math.radians(amount * math.sin(i * 1.1)), 0,
                                          math.radians(amount * 0.6 * math.cos(i * 0.7)))
        key(member["spine"], "rotation_euler", f)
        f += period
        i += 1


# ------------------------------------------------------------------- camera

def aim(loc, target):
    """Euler XYZ that points a Blender camera from loc at target.

    A camera looks down its own -Z. With rotation (rx, 0, rz) its forward is
    (-sin rx sin rz, sin rx cos rz, -cos rx), which inverts cleanly.
    """
    d = Vector(target) - Vector(loc)
    d.normalize()
    rx = math.acos(max(-1.0, min(1.0, -d.z)))
    rz = math.atan2(-d.x, d.y)
    return (math.degrees(rx), 0.0, math.degrees(rz))


def distance(a, b):
    return (Vector(a) - Vector(b)).length


class Camera:
    def __init__(self, cam):
        self.cam = cam

    def shot(self, frame, loc, target, lens=50, fstop=4.0):
        """A cut: place, aim, focus on the target."""
        self.cut(frame, loc, aim(loc, target), lens=lens,
                 focus=distance(loc, target), fstop=fstop)

    def to(self, frame, loc, target):
        """A move within the shot, still aimed at the target."""
        self.move(frame, loc, aim(loc, target), focus=distance(loc, target))

    def cut(self, frame, loc, rot, lens=None, focus=None, fstop=4.0):
        c = self.cam
        if frame > 1:
            key(c, "location", frame - 1, interp="CONSTANT")
            key(c, "rotation_euler", frame - 1, interp="CONSTANT")
            key(c.data, "lens", frame - 1, interp="CONSTANT")
        c.location = loc
        c.rotation_euler = tuple(math.radians(v) for v in rot)
        key(c, "location", frame)
        key(c, "rotation_euler", frame)
        if lens:
            c.data.lens = lens
            key(c.data, "lens", frame)
        if focus is not None:
            c.data.dof.use_dof = True
            c.data.dof.focus_distance = focus
            c.data.dof.aperture_fstop = fstop
            key(c.data.dof, "focus_distance", frame)
            key(c.data.dof, "aperture_fstop", frame)

    def move(self, frame, loc=None, rot=None, focus=None):
        c = self.cam
        if loc:
            c.location = loc
            key(c, "location", frame)
        if rot:
            c.rotation_euler = tuple(math.radians(v) for v in rot)
            key(c, "rotation_euler", frame)
        if focus is not None:
            c.data.dof.focus_distance = focus
            key(c.data.dof, "focus_distance", frame)


# -------------------------------------------------------------------- scenes

def water_burst(world, frame, strength=1.0):
    """The pipe gives way: a jet, a scatter of drops, and a spreading puddle."""
    jet = world["jet"]
    key(jet, "scale", frame - 1, (0.001, 0.001, 0.001), interp="LINEAR")
    key(jet, "scale", frame + 3, (1.25 * strength, 1.25 * strength, 1.35 * strength), interp="LINEAR")
    key(jet, "scale", frame + 9, (0.95 * strength, 0.95 * strength, 1.0 * strength))
    for i, d in enumerate(world["drops"]):
        f0 = frame + 2 + (i % 7) * 2
        key(d, "scale", f0 - 1, (0.001, 0.001, 0.001), interp="LINEAR")
        key(d, "scale", f0 + 2, (1.0, 1.0, 1.0), interp="LINEAR")
        base = tuple(d.location)
        key(d, "location", f0, base, interp="LINEAR")
        key(d, "location", f0 + 26, (base[0] - 0.55 - 0.1 * i, base[1], 0.05), interp="LINEAR")
        key(d, "scale", f0 + 26, (0.4, 0.4, 0.3), interp="LINEAR")
        key(d, "scale", f0 + 28, (0.001, 0.001, 0.001), interp="LINEAR")
    p = world["puddle"]
    key(p, "scale", frame, (0.001, 0.001, 0.001), interp="LINEAR")
    key(p, "scale", frame + 90, (1.0, 1.0, 1.0))


def scene1(world, cast, cam):
    """জনসভা — the square, the stage, the first claim."""
    pol = cast["politician"]
    cam.shot(1, (0, -6.4, 4.0), (0, 5.2, 1.7), lens=30, fstop=6.0)
    cam.to(96, (0, -4.4, 3.0), (0, 5.4, 1.8))
    cam.shot(97, (0.95, 3.45, 2.00), (0, 5.78, 2.32), lens=46, fstop=3.5)
    cam.to(240, (0.78, 3.80, 2.06), (0, 5.78, 2.42))

    sway(pol, 1, 240)
    blinks(pol, 20, 240, every=62)
    head_turn(pol, 1, -12)
    head_turn(pol, 60, 10)
    head_turn(pol, 104, 0)
    arm(pol, "r", 1, shoulder=(3, 5, 0))
    arm(pol, "r", 112, shoulder=(-26, 18, 0), elbow=(-34, 0, 0))
    arm(pol, "r", 150, shoulder=(-12, 10, 0), elbow=(-18, 0, 0))
    arm(pol, "r", 196, shoulder=(-30, 16, 0), elbow=(-40, 0, 0))
    arm(pol, "r", 236, shoulder=(3, 5, 0), elbow=(0, 0, 0))
    speak(pol, "s1_pol", 110)
    for m in cast["crowd"][:6]:
        key(m["root"], "rotation_euler", 1)
    cam.cam.data.dof.use_dof = False      # wide and medium: nothing to throw out of focus
    return 240


def scene2(world, cast, cam):
    """বড় দাবি — the low angle, and the big claim."""
    pol = cast["politician"]
    cam.shot(1, (1.15, 4.05, 1.16), (0, 5.78, 2.28), lens=46, fstop=3.2)
    cam.to(168, (0.98, 4.22, 1.22), (0, 5.78, 2.38))
    cam.shot(176, (-0.35, 7.6, 3.15), (0, 1.5, 1.35), lens=34, fstop=5.0)
    cam.to(288, (0.35, 7.3, 3.00), (0, 1.2, 1.30))

    sway(pol, 1, 180, amount=2.6)
    blinks(pol, 24, 180, every=54)
    head_turn(pol, 1, 6)
    head_turn(pol, 48, -8)
    head_turn(pol, 96, 4)
    head_turn(pol, 150, 0)
    arm(pol, "r", 1, shoulder=(0, 6, 0))
    arm(pol, "r", 40, shoulder=(-54, 22, 0), elbow=(-28, 0, 0))
    arm(pol, "l", 44, shoulder=(-30, -16, 0), elbow=(-24, 0, 0))
    arm(pol, "r", 92, shoulder=(-22, 12, 0), elbow=(-52, 0, 0))
    arm(pol, "r", 140, shoulder=(-60, 26, 0), elbow=(-20, 0, 0))
    arm(pol, "r", 180, shoulder=(0, 6, 0), elbow=(0, 0, 0))
    arm(pol, "l", 180, shoulder=(0, -6, 0), elbow=(0, 0, 0))
    speak(pol, "s2_pol", 36)

    for i, m in enumerate(cast["crowd"]):
        if i % 3:
            continue
        key(m["root"], "rotation_euler", 190)
        m["root"].rotation_euler.z += math.radians(12)
        key(m["root"], "rotation_euler", 230)
        m["root"].rotation_euler.z -= math.radians(12)
        key(m["root"], "rotation_euler", 275)
    return 288


def scene3(world, cast, cam):
    """বাস্তবতা সামনে — the pipe bursts, and the question lands."""
    pol, jour, cit = cast["politician"], cast["journalist"], cast["citizen"]
    cam.shot(1, (1.75, 5.55, 1.85), (3.55, 7.86, 0.95), lens=40, fstop=3.5)
    cam.to(80, (2.05, 5.85, 1.70), (3.55, 7.86, 0.80))
    water_burst(world, 22)

    cam.shot(84, (2.55, 4.20, 1.68), (3.95, 2.82, 1.26), lens=42, fstop=4.0)
    cam.to(106, (2.70, 4.05, 1.64), (4.10, 2.86, 1.22))
    # the citizen points at the dry tap; the journalist raises the microphone
    arm(cit, "r", 86, shoulder=(0, 6, 0))
    arm(cit, "r", 100, shoulder=(-78, 30, 0), elbow=(-10, 0, 0))
    arm(cit, "r", 180, shoulder=(-72, 28, 0), elbow=(-8, 0, 0))
    head_turn(cit, 86, 0)
    head_turn(cit, 104, -26)

    cam.shot(110, (2.72, 4.32, 1.66), (1.95, 3.38, 1.58), lens=55, fstop=2.8)
    cam.to(188, (2.62, 4.20, 1.64), (1.95, 3.38, 1.55))
    arm(jour, "r", 90, shoulder=(0, 6, 0))
    arm(jour, "r", 112, shoulder=(-96, 10, 0), elbow=(-44, 0, 0))
    blinks(jour, 120, 190, every=48)
    head_turn(jour, 112, 4)
    head_turn(jour, 150, -4)
    speak(jour, "s3_jour", 116)

    cam.shot(192, (0.45, 4.00, 2.05), (0, 5.78, 2.62), lens=58, fstop=2.8)
    cam.to(312, (0.42, 4.30, 2.02), (0, 5.78, 2.60))
    # he is caught, then recovers into certainty
    head_turn(pol, 192, 0)
    head_turn(pol, 198, -16, pitch=4)
    blink(pol, 200)
    head_turn(pol, 206, 2)
    head_turn(pol, 230, -6)
    head_turn(pol, 280, 2)
    blinks(pol, 240, 310, every=46)
    arm(pol, "r", 192, shoulder=(0, 6, 0))
    arm(pol, "r", 212, shoulder=(-48, 20, 0), elbow=(-36, 0, 0))
    arm(pol, "r", 262, shoulder=(-26, 12, 0), elbow=(-54, 0, 0))
    arm(pol, "r", 306, shoulder=(-2, 6, 0), elbow=(0, 0, 0))
    speak(pol, "s3_pol", 197)
    return 312


def scene4(world, cast, cam):
    """মাইকের জোর — louder, and the banner gives up."""
    pol, youth = cast["politician"], cast["youth"]
    cam.shot(1, (0.82, 4.00, 0.88), (0, 5.78, 2.44), lens=48, fstop=3.2)
    cam.to(146, (0.70, 4.18, 0.94), (0, 5.78, 2.54))
    speak(pol, "s4_pol", 26)
    arm(pol, "r", 1, shoulder=(0, 6, 0))
    arm(pol, "r", 30, shoulder=(-72, 24, 0), elbow=(-18, 0, 0))
    arm(pol, "r", 78, shoulder=(-96, 30, 0), elbow=(-10, 0, 0))
    arm(pol, "r", 126, shoulder=(-40, 16, 0), elbow=(-30, 0, 0))
    head_turn(pol, 1, 0)
    head_turn(pol, 40, -10, pitch=-6)
    head_turn(pol, 100, 8, pitch=-4)
    blinks(pol, 20, 145, every=52)
    # he turns the microphone up: the heads tilt and the speaker cones pulse
    for i, m in enumerate(world["mics"]):
        key(m, "rotation_euler", 120)
        m.rotation_euler = (math.radians(-18 - 6 * i), 0, 0)
        key(m, "rotation_euler", 134)

    cam.shot(150, (-1.55, 4.80, 1.86), (-1.95, 3.45, 1.50), lens=44, fstop=3.5)
    cam.to(234, (-1.68, 4.62, 1.82), (-1.95, 3.45, 1.47))
    # the young person lifts the phone; neighbours exchange looks
    arm(youth, "r", 150, shoulder=(0, 6, 0))
    arm(youth, "r", 172, shoulder=(-104, 16, 0), elbow=(-52, 0, 0))
    for i, m in enumerate(cast["crowd"][:9]):
        f = 160 + i * 6
        key(m["root"], "rotation_euler", f)
        m["root"].rotation_euler.z += math.radians(20 if i % 2 else -18)
        key(m["root"], "rotation_euler", f + 22)
        m["root"].rotation_euler.z -= math.radians(20 if i % 2 else -18)
        key(m["root"], "rotation_euler", f + 54)

    cam.shot(238, (0.30, 2.40, 2.70), (0, 8.30, 3.15), lens=38, fstop=4.5)
    cam.to(268, (0.28, 2.30, 2.62), (-0.60, 8.30, 2.20))
    cam.to(312, (0.22, 2.10, 2.45), (-1.20, 8.30, 1.15))
    # one corner lets go and the banner swings down from the other, hanging
    # upside down. The camera follows it rather than losing it below frame.
    banner = world["banner"]
    key(banner, "rotation_euler", 244)
    banner.rotation_euler = (0, math.radians(34), 0)
    key(banner, "rotation_euler", 254, interp="LINEAR")
    banner.rotation_euler = (0, math.radians(72), 0)
    key(banner, "rotation_euler", 266, interp="LINEAR")
    banner.rotation_euler = (0, math.radians(58), 0)
    key(banner, "rotation_euler", 280)
    banner.rotation_euler = (0, math.radians(67), 0)
    key(banner, "rotation_euler", 296)
    banner.rotation_euler = (0, math.radians(64), 0)
    key(banner, "rotation_euler", 312)
    cam.cam.data.dof.use_dof = False
    return 312


def scene5(world, cast, cam):
    """শিশুর প্রশ্ন — the question that ends it, and the pullback."""
    child, mother, pol = cast["child"], cast["mother"], cast["politician"]
    cam.shot(1, (-3.38, 2.98, 1.30), (-2.35, 0.84, 1.06), lens=44, fstop=2.8)
    cam.to(200, (-3.30, 2.80, 1.32), (-2.35, 0.84, 1.08))
    head_turn(child, 1, 0)
    head_turn(child, 30, -18, pitch=-16)      # he looks up at his mother
    head_turn(child, 190, -14, pitch=-14)
    blinks(child, 40, 200, every=50)
    speak(child, "s5_child", 44)
    head_turn(mother, 1, 10, pitch=4)
    head_turn(mother, 56, -14, pitch=16)      # she looks down at him
    head_turn(mother, 150, -8, pitch=10)
    blinks(mother, 30, 200, every=56)
    arm(mother, "l", 1, shoulder=(0, -6, 0))
    arm(mother, "l", 70, shoulder=(-28, -22, 0), elbow=(-30, 0, 0))

    cam.shot(206, (-3.22, 2.14, 1.58), (-2.52, 0.84, 1.50), lens=58, fstop=2.4)
    cam.to(244, (-3.16, 2.02, 1.56), (-2.52, 0.84, 1.49))
    head_turn(mother, 210, -4, pitch=6)
    head_turn(mother, 240, 2, pitch=2)
    blink(mother, 228)

    cam.shot(248, (0, -2.4, 2.30), (0, 5.60, 1.90), lens=30, fstop=6.0)
    cam.to(288, (0, -11.0, 4.70), (0, 5.60, 1.70))
    # he is still going, smaller and smaller
    arm(pol, "r", 248, shoulder=(-40, 18, 0), elbow=(-30, 0, 0))
    arm(pol, "r", 272, shoulder=(-82, 26, 0), elbow=(-14, 0, 0))
    arm(pol, "r", 288, shoulder=(-36, 16, 0), elbow=(-34, 0, 0))
    return 288


SCENES = [scene1, scene2, scene3, scene4, scene5]


def build_scene(index, samples=16):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    s = bpy.context.scene
    s.render.engine = "BLENDER_EEVEE_NEXT"
    s.render.resolution_x, s.render.resolution_y = 1280, 720
    s.render.fps = FPS
    s.eevee.taa_render_samples = samples
    s.view_settings.view_transform = "Standard"
    if hasattr(s.eevee, "use_shadows"):
        s.eevee.use_shadows = True
    if hasattr(s.eevee, "use_raytracing"):
        s.eevee.use_raytracing = False
    for attr, value in (("shadow_ray_count", 1), ("shadow_step_count", 4),
                        ("use_volumetric_lights", False)):
        if hasattr(s.eevee, attr):
            setattr(s.eevee, attr, value)
    world = ENV.build_world()
    cast = build_cast()
    lighting(s)
    bpy.ops.object.camera_add(location=(0, -8, 3), rotation=(math.radians(75), 0, 0))
    cam = bpy.context.object
    cam.name = "filmcam"
    cam.data.lens = 35
    cam.data.dof.use_dof = True
    s.camera = cam
    length = SCENES[index - 1](world, cast, Camera(cam))
    s.frame_start, s.frame_end = 1, length
    return s, length
