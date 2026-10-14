"""Procedural human characters: a math-sculpted head and a skinned body.

No sculpting by hand and no downloaded assets. The head is a subdivided sphere
displaced by anatomical features; the body is a vertex skeleton grown by the
Skin modifier and deformed by a matching armature. Faces carry shape keys for
acting and for Bengali speech shapes.
"""

import math
import random

import bpy
from mathutils import Vector


# ----------------------------------------------------------------- utilities

def mat(name, rgb, rough=0.5, metallic=0.0, sheen=0.0, sss=0.0,
        sss_radius=(0.6, 0.25, 0.15), sss_scale=0.01, emit=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*rgb, 1.0)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metallic
    if "Sheen Weight" in b.inputs:
        b.inputs["Sheen Weight"].default_value = sheen
    if sss and "Subsurface Weight" in b.inputs:
        b.inputs["Subsurface Weight"].default_value = sss
        b.inputs["Subsurface Radius"].default_value = sss_radius
        if "Subsurface Scale" in b.inputs:
            b.inputs["Subsurface Scale"].default_value = sss_scale
    if emit:
        b.inputs["Emission Color"].default_value = (*rgb, 1.0)
        b.inputs["Emission Strength"].default_value = emit
    return m


def skin_material(name, tone=(0.44, 0.27, 0.18), age=0.4, pore=1.0):
    """Skin: subsurface scattering, procedural pore bump, and a little colour
    variation so the surface is not a flat plastic shell."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes["Principled BSDF"]
    out = nt.nodes["Material Output"]
    b.location = (300, 0)
    out.location = (600, 0)

    tex = nt.nodes.new("ShaderNodeTexCoord")
    tex.location = (-900, 0)

    # large-scale colour variation
    big = nt.nodes.new("ShaderNodeTexNoise")
    big.location = (-700, 200)
    big.inputs["Scale"].default_value = 14.0
    big.inputs["Detail"].default_value = 4.0
    nt.links.new(tex.outputs["Object"], big.inputs["Vector"])

    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.location = (-480, 200)
    ramp.color_ramp.elements[0].position = 0.35
    ramp.color_ramp.elements[0].color = (tone[0] * 0.86, tone[1] * 0.84, tone[2] * 0.86, 1)
    ramp.color_ramp.elements[1].position = 0.68
    ramp.color_ramp.elements[1].color = (min(1, tone[0] * 1.12), tone[1] * 1.05, tone[2] * 1.02, 1)
    nt.links.new(big.outputs["Fac"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], b.inputs["Base Color"])

    # pores
    pores = nt.nodes.new("ShaderNodeTexVoronoi")
    pores.location = (-700, -120)
    pores.inputs["Scale"].default_value = 420.0
    nt.links.new(tex.outputs["Object"], pores.inputs["Vector"])

    fine = nt.nodes.new("ShaderNodeTexNoise")
    fine.location = (-700, -320)
    fine.inputs["Scale"].default_value = 90.0
    fine.inputs["Detail"].default_value = 8.0
    nt.links.new(tex.outputs["Object"], fine.inputs["Vector"])

    mix = nt.nodes.new("ShaderNodeMix")
    mix.data_type = "FLOAT"
    mix.location = (-470, -200)
    mix.inputs["Factor"].default_value = 0.45
    nt.links.new(pores.outputs["Distance"], mix.inputs[2])
    nt.links.new(fine.outputs["Fac"], mix.inputs[3])

    bump = nt.nodes.new("ShaderNodeBump")
    bump.location = (-220, -200)
    bump.inputs["Strength"].default_value = 0.12 + 0.10 * pore
    bump.inputs["Distance"].default_value = 0.0012
    nt.links.new(mix.outputs[0], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], b.inputs["Normal"])

    # roughness varies, which is most of what sells skin under a key light
    rough = nt.nodes.new("ShaderNodeMapRange")
    rough.location = (-220, 60)
    rough.inputs["From Min"].default_value = 0.0
    rough.inputs["From Max"].default_value = 1.0
    rough.inputs["To Min"].default_value = 0.38
    rough.inputs["To Max"].default_value = 0.62
    nt.links.new(fine.outputs["Fac"], rough.inputs["Value"])
    nt.links.new(rough.outputs["Result"], b.inputs["Roughness"])

    b.inputs["Subsurface Weight"].default_value = 0.14
    b.inputs["Subsurface Radius"].default_value = (0.9, 0.35, 0.22)
    if "Subsurface Scale" in b.inputs:
        b.inputs["Subsurface Scale"].default_value = 0.012
    b.inputs["IOR"].default_value = 1.4
    if "Specular IOR Level" in b.inputs:
        b.inputs["Specular IOR Level"].default_value = 0.42
    return m


def smooth(obj, subsurf=2, render_subsurf=None):
    for p in obj.data.polygons:
        p.use_smooth = True
    if subsurf:
        m = obj.modifiers.new("subsurf", "SUBSURF")
        m.levels = 1
        m.render_levels = subsurf if render_subsurf is None else render_subsurf
    return obj


def attach(child, parent):
    bpy.context.view_layer.update()
    child.parent = parent
    child.matrix_parent_inverse = parent.matrix_world.inverted()
    return child


def gaussian(d, sigma):
    return math.exp(-(d * d) / (2.0 * sigma * sigma))


# ---------------------------------------------------------------------- head

HEAD_W, HEAD_D, HEAD_H = 0.082, 0.098, 0.115   # half-extents, metres


def sculpt_head(name, params):
    """A head shaped by displacing a sphere. Local space: the face looks toward
    -Y, up is +Z, and the origin sits at the centre of the skull."""
    seed = params.get("seed", 1)
    rnd = random.Random(seed)
    jaw_w = params.get("jaw", 1.0)
    nose_len = params.get("nose", 1.0)
    cheek = params.get("cheek", 1.0)
    age = params.get("age", 0.45)
    child = params.get("child", False)

    bpy.ops.mesh.primitive_uv_sphere_add(segments=72, ring_count=52, radius=1.0)
    head = bpy.context.object
    head.name = name

    for v in head.data.vertices:
        p = Vector(v.co)
        q = Vector((p.x * HEAD_W, p.y * HEAD_D, p.z * HEAD_H))

        # child skulls are rounder, with a smaller face and bigger cranium
        if child:
            q.z *= 0.92
            q.y *= 0.95

        n = Vector(q)
        n.normalize()

        # --- cranium: flatten the back and the sides a little
        if q.y > 0:
            q.y *= 0.95
        q.x *= 0.98

        # --- the face is a plane, not a bulge
        if q.y < -0.02 and -0.06 < q.z < 0.06:
            q.y += (abs(q.y) - 0.02) * 0.10

        # --- jaw taper and chin
        if q.z < -0.02:
            t = min(1.0, (-0.02 - q.z) / 0.11)
            q.x *= (1.0 - 0.30 * t) * (0.94 + 0.12 * jaw_w)
            if q.y < 0:
                q.y *= (1.0 - 0.16 * t)
        chin = gaussian((q - Vector((0, -0.070, -0.098))).length, 0.030)
        q.y -= 0.013 * chin * (1.1 if not child else 0.7)
        q.z -= 0.004 * chin

        # jaw angle, the corner that makes a face male
        for sx in (-1, 1):
            jg = gaussian((q - Vector((sx * 0.068, -0.012, -0.062))).length, 0.032)
            q.x += sx * 0.009 * jg * jaw_w
            q.y += 0.004 * jg

        # --- brow ridge
        for sx in (-1, 1):
            bg = gaussian((q - Vector((sx * 0.032, -0.082, 0.030))).length, 0.030)
            q.y -= 0.011 * bg * (0.5 if child else 1.0)
            q.z += 0.002 * bg
        mid_brow = gaussian((q - Vector((0, -0.086, 0.026))).length, 0.016)
        q.y -= 0.004 * mid_brow

        # --- eye sockets
        for sx in (-1, 1):
            eg = gaussian((q - Vector((sx * 0.034, -0.076, 0.009))).length, 0.023)
            q.y += 0.012 * eg

        # --- cheekbones and cheeks
        for sx in (-1, 1):
            cg = gaussian((q - Vector((sx * 0.052, -0.055, -0.012))).length, 0.034)
            q.x += sx * 0.006 * cg * cheek
            q.y -= 0.005 * cg * cheek
            hollow = gaussian((q - Vector((sx * 0.046, -0.052, -0.045))).length, 0.026)
            q.y += 0.004 * hollow * age

        # --- nose: bridge, tip, wings
        bridge = gaussian(abs(q.x) / 0.9, 0.013) * gaussian((q.z - 0.012) / 1.0, 0.030)
        q.y -= 0.013 * bridge * nose_len
        tip = gaussian((q - Vector((0, -0.095, -0.022))).length, 0.018)
        q.y -= 0.019 * tip * nose_len
        q.z -= 0.004 * tip
        for sx in (-1, 1):
            wing = gaussian((q - Vector((sx * 0.016, -0.086, -0.030))).length, 0.013)
            q.y -= 0.010 * wing
            q.x += sx * 0.004 * wing
        septum = gaussian((q - Vector((0, -0.088, -0.038))).length, 0.010)
        q.y += 0.004 * septum

        # --- lips
        upper = gaussian((q - Vector((0, -0.080, -0.052))).length, 0.019)
        lower = gaussian((q - Vector((0, -0.079, -0.068))).length, 0.019)
        q.y -= 0.007 * upper + 0.008 * lower
        crease = gaussian((q - Vector((0, -0.082, -0.060))).length, 0.006)
        q.y += 0.006 * crease
        philtrum = gaussian((q - Vector((0, -0.084, -0.044))).length, 0.008)
        q.y += 0.003 * philtrum

        # --- nasolabial folds and forehead lines, by age
        for sx in (-1, 1):
            fold = gaussian((q - Vector((sx * 0.026, -0.078, -0.052))).length, 0.013)
            q.y += 0.0035 * fold * age
        for z0 in (0.050, 0.064):
            line = gaussian((q.z - z0) / 1.0, 0.004) * gaussian(q.y / 1.0, 0.05) if q.y < -0.04 else 0
            q.y += 0.0016 * line * age

        # a little asymmetry: no real face is mirror-perfect
        q.y += 0.0012 * (rnd.random() - 0.5) * (1 if abs(q.x) > 0.02 else 0)

        v.co = q

    smooth(head, subsurf=2)
    return head


SPEECH_KEYS = ("jaw_open", "smile", "brow_raise", "mouth_wide", "mouth_round", "squint")


def add_face_keys(head, child=False):
    """Shape keys for acting and for speech shapes. Each one displaces the
    region it owns, weighted so the deformation falls off smoothly."""
    head.shape_key_add(name="basis", from_mix=False)
    keys = {}
    for kname in SPEECH_KEYS:
        keys[kname] = head.shape_key_add(name=kname, from_mix=False)

    basis = head.data.shape_keys.key_blocks["basis"]
    for i, bv in enumerate(basis.data):
        p = Vector(bv.co)

        # jaw: everything below the mouth swings down and slightly back
        if p.z < -0.030:
            t = min(1.0, (-0.030 - p.z) / 0.085)
            d = keys["jaw_open"].data[i].co
            d.z -= 0.030 * t * t
            d.y += 0.006 * t * t
        lipl = gaussian((p - Vector((0, -0.082, -0.060))).length, 0.026)
        keys["jaw_open"].data[i].co.z -= 0.012 * lipl

        # smile: the corners travel out and up, the cheeks lift
        for sx in (-1, 1):
            corner = gaussian((p - Vector((sx * 0.026, -0.076, -0.058))).length, 0.022)
            d = keys["smile"].data[i].co
            d.x += sx * 0.013 * corner
            d.z += 0.011 * corner
            d.y += 0.003 * corner
            cheeklift = gaussian((p - Vector((sx * 0.044, -0.064, -0.030))).length, 0.028)
            d.z += 0.006 * cheeklift
            d.y -= 0.004 * cheeklift

        # brows up, with forehead compression
        for sx in (-1, 1):
            brow = gaussian((p - Vector((sx * 0.032, -0.082, 0.030))).length, 0.032)
            keys["brow_raise"].data[i].co.z += 0.012 * brow
            sq = gaussian((p - Vector((sx * 0.034, -0.078, 0.012))).length, 0.026)
            keys["squint"].data[i].co.z += 0.006 * sq
            keys["squint"].data[i].co.y -= 0.002 * sq

        # viseme widths
        mouth = gaussian((p - Vector((0, -0.082, -0.058))).length, 0.030)
        keys["mouth_wide"].data[i].co.x += math.copysign(0.010, p.x) * mouth
        keys["mouth_wide"].data[i].co.z += 0.002 * mouth
        keys["mouth_round"].data[i].co.x -= math.copysign(0.011, p.x) * mouth
        keys["mouth_round"].data[i].co.y -= 0.010 * mouth

    for kname in SPEECH_KEYS:
        keys[kname].value = 0.0
        keys[kname].slider_min = -0.5
        keys[kname].slider_max = 1.5
    return keys


# ---------------------------------------------------------------- eye, hair

def eye_material(name, iris=(0.14, 0.07, 0.03)):
    """One sphere carries sclera, iris and pupil, keyed off its own object
    coordinates: the radius from the forward axis selects the band."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes["Principled BSDF"]
    tex = nt.nodes.new("ShaderNodeTexCoord")
    tex.location = (-900, 0)
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    sep.location = (-700, 0)
    nt.links.new(tex.outputs["Object"], sep.inputs["Vector"])

    # radius around the forward (-Y) axis
    sq = nt.nodes.new("ShaderNodeVectorMath")
    sq.operation = "LENGTH"
    sq.location = (-520, -60)
    comb = nt.nodes.new("ShaderNodeCombineXYZ")
    comb.location = (-620, -140)
    nt.links.new(sep.outputs["X"], comb.inputs["X"])
    nt.links.new(sep.outputs["Z"], comb.inputs["Y"])
    nt.links.new(comb.outputs["Vector"], sq.inputs[0])

    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.location = (-320, 0)
    e = ramp.color_ramp.elements
    e[0].position = 0.11
    e[0].color = (0.004, 0.004, 0.005, 1)                      # pupil
    e[1].position = 0.145
    e[1].color = (*iris, 1)
    i2 = ramp.color_ramp.elements.new(0.34)
    i2.color = (min(1, iris[0] * 1.7), iris[1] * 1.8, iris[2] * 1.9, 1)  # iris edge
    i3 = ramp.color_ramp.elements.new(0.375)
    i3.color = (0.018, 0.010, 0.008, 1)                         # limbal ring
    i4 = ramp.color_ramp.elements.new(0.40)
    i4.color = (0.88, 0.845, 0.80, 1)                           # sclera
    nt.links.new(sq.outputs["Value"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], b.inputs["Base Color"])

    # iris fibres
    fib = nt.nodes.new("ShaderNodeTexNoise")
    fib.location = (-520, 220)
    fib.inputs["Scale"].default_value = 60.0
    fib.inputs["Detail"].default_value = 6.0
    nt.links.new(tex.outputs["Object"], fib.inputs["Vector"])
    bump = nt.nodes.new("ShaderNodeBump")
    bump.location = (-200, -260)
    bump.inputs["Strength"].default_value = 0.08
    nt.links.new(fib.outputs["Fac"], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], b.inputs["Normal"])

    b.inputs["Roughness"].default_value = 0.09
    b.inputs["IOR"].default_value = 1.38
    if "Specular IOR Level" in b.inputs:
        b.inputs["Specular IOR Level"].default_value = 0.72
    return m


def hair_material(name, rgb=(0.035, 0.022, 0.018), rough=0.42):
    m = mat(name, rgb, rough=rough)
    nt = m.node_tree
    b = nt.nodes["Principled BSDF"]
    tex = nt.nodes.new("ShaderNodeTexCoord")
    tex.location = (-700, -200)
    strand = nt.nodes.new("ShaderNodeTexNoise")
    strand.location = (-500, -200)
    strand.inputs["Scale"].default_value = 230.0
    strand.inputs["Detail"].default_value = 6.0
    nt.links.new(tex.outputs["Object"], strand.inputs["Vector"])
    bump = nt.nodes.new("ShaderNodeBump")
    bump.location = (-260, -200)
    bump.inputs["Strength"].default_value = 0.55
    bump.inputs["Distance"].default_value = 0.0015
    nt.links.new(strand.outputs["Fac"], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], b.inputs["Normal"])
    if "Anisotropic" in b.inputs:
        b.inputs["Anisotropic"].default_value = 0.6
    return m


def noisy_sphere(name, loc, scale, amount, freq, segs=48, rings=32, seed=0):
    """A sphere roughened by value noise — hair masses, fabric lumps, stones."""
    rnd = random.Random(seed)
    offs = [rnd.random() * 10 for _ in range(3)]
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segs, ring_count=rings, radius=1.0, location=loc)
    o = bpy.context.object
    o.name = name
    for v in o.data.vertices:
        p = Vector(v.co)
        n = (math.sin(p.x * freq + offs[0]) * math.sin(p.y * freq * 1.3 + offs[1])
             * math.sin(p.z * freq * 0.8 + offs[2]))
        v.co = p * (1.0 + amount * n)
    o.scale = scale
    return o


def build_eyes(head, params, parent):
    """Eyeballs, lids and brows, all parented to the head."""
    child = params.get("child", False)
    r = 0.0122 * (0.92 if child else 1.0)
    eye_m = eye_material(f"{head.name}_eye", params.get("iris", (0.12, 0.06, 0.028)))
    skin_m = head.data.materials[0]
    brow_m = hair_material(f"{head.name}_brow", params.get("hair_rgb", (0.03, 0.02, 0.016)))

    eyes, lids = [], []
    for sx, side in ((-1, "l"), (1, "r")):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=48, ring_count=32, radius=r,
                                             location=(sx * 0.0335, -0.0585, 0.010))
        ball = bpy.context.object
        ball.name = f"{head.name}_eye_{side}"
        ball.data.materials.append(eye_m)
        smooth(ball, subsurf=1)
        attach(ball, parent)
        eyes.append(ball)

        # upper lid: a shell that rotates down to close
        pivot = bpy.data.objects.new(f"{head.name}_lid_{side}", None)
        bpy.context.collection.objects.link(pivot)
        pivot.location = (sx * 0.0335, -0.0585, 0.010)
        attach(pivot, parent)

        bpy.ops.mesh.primitive_uv_sphere_add(segments=40, ring_count=26, radius=r * 1.16,
                                             location=(sx * 0.0335, -0.0585, 0.0168))
        lid = bpy.context.object
        lid.name = f"{head.name}_lidmesh_{side}"
        lid.scale = (1.06, 1.0, 0.62)
        lid.data.materials.append(skin_m)
        smooth(lid, subsurf=1)
        attach(lid, pivot)
        lids.append(pivot)

        low = bpy.data.objects.new(f"{head.name}_lowlid_{side}", None)  # placeholder pivot
        bpy.context.collection.objects.link(low)
        attach(low, parent)

        # brow: three masses forming an arch
        for k, (dx, dz, sc) in enumerate(((-0.014, 0.0, 1.0), (0.0, 0.004, 1.15), (0.015, 0.001, 0.9))):
            b = noisy_sphere(f"{head.name}_brow_{side}{k}",
                             (sx * 0.033 + sx * dx, -0.0795, 0.0295 + dz),
                             (0.0115 * sc, 0.006, 0.0042), 0.22, 9.0, segs=24, rings=14,
                             seed=k + (0 if sx < 0 else 7))
            b.data.materials.append(brow_m)
            smooth(b, subsurf=1)
            attach(b, parent)

    return eyes, lids


def build_hair(head, params, parent):
    """A hair cap plus optional moustache, both mesh masses with strand bump."""
    hm = hair_material(f"{head.name}_hair", params.get("hair_rgb", (0.035, 0.024, 0.02)),
                       rough=params.get("hair_rough", 0.45))
    grey = params.get("grey", 0.0)
    if grey:
        b = hm.node_tree.nodes["Principled BSDF"]
        c = params.get("hair_rgb", (0.035, 0.024, 0.02))
        b.inputs["Base Color"].default_value = (
            c[0] + grey * 0.30, c[1] + grey * 0.29, c[2] + grey * 0.28, 1.0)

    style = params.get("hair", "combed")
    parts = []
    if style != "bald":
        cap = noisy_sphere(f"{head.name}_haircap", (0, 0.004, 0.030),
                           (0.0875, 0.1005, 0.097), 0.05, 7.0, seed=params.get("seed", 1))
        cap.data.materials.append(hm)
        smooth(cap, subsurf=1)
        attach(cap, parent)
        parts.append(cap)
        # a side mass, so the silhouette is not a helmet
        side = noisy_sphere(f"{head.name}_hairside", (0.0, 0.028, 0.052),
                            (0.080, 0.070, 0.045), 0.10, 9.0, seed=params.get("seed", 1) + 3)
        side.data.materials.append(hm)
        smooth(side, subsurf=2)
        attach(side, parent)
        parts.append(side)

    if params.get("moustache"):
        for sx in (-1, 1):
            m = noisy_sphere(f"{head.name}_must_{sx}", (sx * 0.011, -0.0865, -0.0415),
                             (0.0125, 0.0055, 0.0045), 0.2, 11.0, segs=24, rings=14,
                             seed=5 + sx)
            m.data.materials.append(hm)
            smooth(m, subsurf=1)
            attach(m, parent)
            parts.append(m)

    if params.get("stubble"):
        pass  # carried by the skin shader's roughness variation, not geometry
    return parts


# ------------------------------------------------------------- assembled head

import head as HEAD  # noqa: E402


def make_head(name, params, parent=None):
    """Assemble a head from lofted parts and return its animation controls."""
    child = params.get("child", False)
    sc = params.get("head_scale", 0.86 if child else 1.0)
    scale = (sc * params.get("head_w", 1.0), sc, sc)

    root = bpy.data.objects.new(f"{name}_head_root", None)
    bpy.context.collection.objects.link(root)
    if parent:
        attach(root, parent)

    skin = skin_material(f"{name}_skin", tone=params.get("tone", (0.165, 0.082, 0.047)),
                         age=params.get("age", 0.4))
    lip_m = mat(f"{name}_lip", params.get("lip_tone", (0.155, 0.068, 0.050)), rough=0.34, sss=0.25)
    dark = mat(f"{name}_mouth", (0.035, 0.016, 0.016), rough=0.6)
    teeth_m = mat(f"{name}_teeth", (0.82, 0.80, 0.76), rough=0.25)

    skull = HEAD.build_skull(f"{name}_skull", scale=scale,
                             socket_depth=0.030 * sc, brow_ridge=params.get("brow", 0.006) * sc)
    skull.data.materials.append(skin)
    smooth(skull, subsurf=2)
    attach(skull, root)

    nose = HEAD.build_nose(f"{name}_nose", length=params.get("nose", 0.92),
                           width=params.get("nose_w", 1.05))
    nose.location = (0, -0.0815 * sc, 0.000 * sc)
    nose.scale = (sc, sc, sc)
    nose.data.materials.append(skin)
    smooth(nose, subsurf=2)
    attach(nose, root)

    lips = {}
    for which, z, prot in (("upper", -0.0452, 0.0076), ("lower", -0.0556, 0.0074)):
        lp = HEAD.build_lip(f"{name}_lip_{which}", upper=(which == "upper"),
                            width=0.0258 * params.get("mouth_w", 1.0), protrude=prot, thickness=0.0055)
        lp.location = (0, -0.0792 * sc, z * sc)
        lp.scale = (sc, sc, sc)
        lp.data.materials.append(lip_m)
        smooth(lp, subsurf=1)
        attach(lp, root)
        lips[which] = lp

    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=16, radius=1.0,
                                         location=(0, -0.0635 * sc, -0.0492 * sc))
    cavity = bpy.context.object
    cavity.name = f"{name}_cavity"
    cavity.scale = (0.0205 * sc, 0.0115 * sc, 0.0082 * sc)
    cavity.data.materials.append(dark)
    smooth(cavity, subsurf=1)
    attach(cavity, root)

    bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=12, radius=1.0,
                                         location=(0, -0.0705 * sc, -0.0455 * sc))
    teeth = bpy.context.object
    teeth.name = f"{name}_teeth"
    teeth.scale = (0.0145 * sc, 0.005 * sc, 0.0038 * sc)
    teeth.data.materials.append(teeth_m)
    smooth(teeth, subsurf=1)
    attach(teeth, root)

    for sx, side in ((-1, "l"), (1, "r")):
        ear = HEAD.build_ear(f"{name}_ear_{side}", side=sx)
        ear.location = (sx * 0.0700 * sc, 0.020 * sc, 0.004 * sc)
        ear.scale = (sc * 1.15, sc * 1.3, sc * 1.3)
        ear.data.materials.append(skin)
        smooth(ear, subsurf=1)
        attach(ear, root)

    # eyes: the ball sits behind the face plane and shows through the aperture
    eye_m = eye_material(f"{name}_eye", params.get("iris", (0.11, 0.055, 0.025)))
    r = 0.0118 * sc
    eyes, lids = [], []
    for sx, side in ((-1, "l"), (1, "r")):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=44, ring_count=30, radius=1.0,
                                             location=(sx * 0.0335 * sc, -0.0698 * sc, 0.012 * sc))
        ball = bpy.context.object
        ball.name = f"{name}_eyeball_{side}"
        ball.scale = (r, r, r)
        ball.data.materials.append(eye_m)
        smooth(ball, subsurf=1)
        attach(ball, root)
        eyes.append(ball)

        pivot = bpy.data.objects.new(f"{name}_lidpivot_{side}", None)
        bpy.context.collection.objects.link(pivot)
        pivot.location = (sx * 0.0335 * sc, -0.0698 * sc, 0.012 * sc)
        attach(pivot, root)
        bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=20, radius=1.0,
                                             location=(sx * 0.0335 * sc, -0.0745 * sc, 0.0245 * sc))
        lid = bpy.context.object
        lid.name = f"{name}_upperlid_{side}"
        lid.scale = (0.0172 * sc, 0.0130 * sc, 0.0080 * sc)
        lid.data.materials.append(skin)
        smooth(lid, subsurf=1)
        attach(lid, pivot)
        pivot.rotation_euler = (math.radians(-19), 0, 0)
        lids.append(pivot)

        bpy.ops.mesh.primitive_uv_sphere_add(segments=28, ring_count=16, radius=1.0,
                                             location=(sx * 0.0335 * sc, -0.0745 * sc, -0.0022 * sc))
        low = bpy.context.object
        low.name = f"{name}_lowerlid_{side}"
        low.scale = (0.0160 * sc, 0.0118 * sc, 0.0048 * sc)
        low.data.materials.append(skin)
        smooth(low, subsurf=1)
        attach(low, root)

        brow_m = hair_material(f"{name}_brow_{side}", params.get("hair_rgb", (0.03, 0.02, 0.016)))
        for k, (dx, dz, w) in enumerate(((-0.015, -0.001, 1.0), (0.0, 0.0035, 1.2), (0.016, 0.0015, 0.85))):
            b = noisy_sphere(f"{name}_brow_{side}{k}",
                             (sx * (0.0335 + dx) * sc, -0.0805 * sc, (0.0345 + dz) * sc),
                             (0.0125 * w * sc, 0.0062 * sc, 0.0045 * sc), 0.25, 10.0,
                             segs=24, rings=14, seed=k * 3 + (0 if sx < 0 else 11))
            b.data.materials.append(brow_m)
            smooth(b, subsurf=1)
            attach(b, root)

    build_hair_v2(name, params, root, sc)

    return dict(root=root, skull=skull, nose=nose, lips=lips, cavity=cavity, teeth=teeth,
                eyes=eyes, lids=lids, scale=sc, skin=skin)


def build_hair_v2(name, params, root, sc):
    style = params.get("hair", "combed")
    hm = hair_material(f"{name}_hair", params.get("hair_rgb", (0.035, 0.024, 0.02)))
    grey = params.get("grey", 0.0)
    if grey:
        b = hm.node_tree.nodes["Principled BSDF"]
        c = params.get("hair_rgb", (0.035, 0.024, 0.02))
        b.inputs["Base Color"].default_value = (c[0] + grey * 0.26, c[1] + grey * 0.25,
                                                c[2] + grey * 0.24, 1.0)
    parts = []
    if style != "bald":
        long_hair = style == "long"
        cap = noisy_sphere(f"{name}_haircap", (0, 0.010 * sc, 0.0555 * sc),
                           (0.0890 * sc, 0.0960 * sc, 0.0765 * sc), 0.05, 7.0,
                           seed=params.get("seed", 1))
        cap.data.materials.append(hm)
        smooth(cap, subsurf=1)
        attach(cap, root)
        parts.append(cap)
        back = noisy_sphere(f"{name}_hairback", (0, 0.042 * sc, (0.000 if long_hair else 0.026) * sc),
                            (0.0845 * sc, 0.062 * sc, (0.095 if long_hair else 0.062) * sc),
                            0.09, 9.0, seed=params.get("seed", 1) + 4)
        back.data.materials.append(hm)
        smooth(back, subsurf=1)
        attach(back, root)
        parts.append(back)
    if params.get("moustache"):
        for sx in (-1, 1):
            m = noisy_sphere(f"{name}_moust_{sx}", (sx * 0.0108 * sc, -0.0845 * sc, -0.0318 * sc),
                             (0.0125 * sc, 0.0055 * sc, 0.0042 * sc), 0.2, 11.0,
                             segs=24, rings=14, seed=5 + sx)
            m.data.materials.append(hm)
            smooth(m, subsurf=1)
            attach(m, root)
            parts.append(m)
    return parts


# ---------------------------------------------------------------------- body

BODY_PROFILE_M = [     # z from ground, half-width, front depth, back depth, squareness
    (1.455, 0.058, 0.052, 0.058, 1.00),   # neck base
    (1.420, 0.148, 0.080, 0.092, 0.80),   # shoulders
    (1.330, 0.162, 0.104, 0.110, 0.78),   # chest
    (1.230, 0.150, 0.110, 0.104, 0.80),
    (1.120, 0.143, 0.113, 0.098, 0.84),   # waist
    (1.020, 0.150, 0.116, 0.106, 0.86),   # hips
    (0.930, 0.152, 0.118, 0.110, 0.88),
]


def build_torso(name, params):
    """Torso as a lofted solid. Clothing is built from the same profile a few
    millimetres out, so a garment never intersects the body it covers."""
    build = params.get("build", 1.0)
    prof = [(z, w * build, df * build, db * build, s) for (z, w, df, db, s) in BODY_PROFILE_M]
    scale_h = params.get("height", 1.72) / 1.72
    prof = [(z * scale_h, w, df, db, s) for (z, w, df, db, s) in prof]
    ob, _, _ = HEAD.loft(name, prof, rings=34, segments=40)
    return ob


def limb(name, points, radii, segments=18):
    """A tube through a polyline: arms, legs, microphone stands, pipes."""
    verts, faces = [], []
    n = len(points)
    for i, (p, r) in enumerate(zip(points, radii)):
        p = Vector(p)
        if i < n - 1:
            d = (Vector(points[i + 1]) - p).normalized()
        else:
            d = (p - Vector(points[i - 1])).normalized()
        up = Vector((0, 0, 1))
        if abs(d.dot(up)) > 0.95:
            up = Vector((0, 1, 0))
        a1 = d.cross(up).normalized()
        a2 = d.cross(a1).normalized()
        for j in range(segments):
            ang = 2.0 * math.pi * j / segments
            verts.append(tuple(p + a1 * (r * math.cos(ang)) + a2 * (r * math.sin(ang))))
    for i in range(n - 1):
        for j in range(segments):
            a = i * segments + j
            b = i * segments + (j + 1) % segments
            faces.append((a, b, b + segments, a + segments))
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], faces)
    me.validate()
    ob = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(ob)
    return ob


def build_hand(name, side, base=(0, 0, 0), scale=1.0):
    """Palm plus five tapered fingers, built at a world position because every
    part in this project keeps its world transform when it is parented."""
    bx, by, bz = base
    parts = []

    def P(x, y, z):
        return (bx + x, by + y, bz + z)

    palm = limb(f"{name}_palm",
                [P(0, 0, 0), P(side * 0.010, 0, -0.050), P(side * 0.014, 0, -0.080)],
                [0.028 * scale, 0.032 * scale, 0.028 * scale], segments=14)
    parts.append(palm)
    for k in range(4):
        x = side * (-0.020 + 0.0145 * k)
        ln = (0.066, 0.074, 0.070, 0.056)[k] * scale
        f = limb(f"{name}_f{k}",
                 [P(x, 0, -0.078), P(x * 1.06, -0.004, -0.078 - ln * 0.5),
                  P(x * 1.10, -0.012, -0.078 - ln)],
                 [0.0098 * scale, 0.0088 * scale, 0.0072 * scale], segments=10)
        parts.append(f)
    thumb = limb(f"{name}_thumb",
                 [P(side * -0.024, -0.004, -0.028), P(side * -0.042, -0.014, -0.048),
                  P(side * -0.052, -0.022, -0.066)],
                 [0.0118 * scale, 0.0100 * scale, 0.0082 * scale], segments=10)
    parts.append(thumb)
    return parts


# ------------------------------------------------------- assembled character

def _cloth_profile(scale_h, build, extra, z_top, z_bot, flare=1.0):
    out = []
    for (z, w, df, db, s) in BODY_PROFILE_M:
        zz = z * scale_h
        if zz > z_top or zz < z_bot:
            continue
        out.append((zz, w * build + extra, df * build + extra, db * build + extra, s))
    if out and out[0][0] < z_top:
        z0, w0, f0, b0, s0 = out[0]
        out.insert(0, (z_top, w0 * 0.86, f0 * 0.86, b0 * 0.86, s0))
    if out:
        zl, wl, fl, bl, sl = out[-1]
        out.append((z_bot, wl * flare, fl * flare, bl * flare, sl))
    return out


def make_character(name, params):
    """A complete figure: head, torso, garments, arms, hands and legs, hung off
    a hierarchy of empties so each part can be posed."""
    scale_h = params.get("height", 1.72) / 1.72
    build = params.get("build", 1.0)
    child = params.get("child", False)

    root = bpy.data.objects.new(f"{name}_root", None)
    bpy.context.collection.objects.link(root)
    # the figure is built around the origin and placed at the end: attach()
    # preserves world transforms, so moving the root first would cancel out.

    spine = bpy.data.objects.new(f"{name}_spine", None)
    bpy.context.collection.objects.link(spine)
    spine.location = (0, 0, 1.10 * scale_h)
    attach(spine, root)

    skin = skin_material(f"{name}_bodyskin", tone=params.get("tone", (0.165, 0.082, 0.047)),
                         age=params.get("age", 0.4))
    cloth_main = mat(f"{name}_cloth", params.get("cloth", (0.62, 0.60, 0.56)),
                     rough=0.82, sheen=0.35)
    cloth_vest = mat(f"{name}_vest", params.get("vest", (0.045, 0.048, 0.062)),
                     rough=0.74, sheen=0.25)
    trouser = mat(f"{name}_trouser", params.get("trouser", (0.10, 0.10, 0.115)),
                  rough=0.85, sheen=0.2)
    shoe_m = mat(f"{name}_shoe", (0.02, 0.018, 0.016), rough=0.35)

    # torso skin, mostly hidden but it gives the neck and collar something to sit on
    torso = build_torso(f"{name}_torso", params)
    torso.data.materials.append(skin)
    smooth(torso, subsurf=1)
    attach(torso, root)

    neck = limb(f"{name}_neck", [(0, 0.004, 1.40 * scale_h), (0, 0.006, 1.49 * scale_h)],
                [0.047 * build, 0.043 * build], segments=24)
    neck.data.materials.append(skin)
    smooth(neck, subsurf=1)
    attach(neck, root)

    # head
    head_pivot = bpy.data.objects.new(f"{name}_neckpivot", None)
    bpy.context.collection.objects.link(head_pivot)
    head_pivot.location = (0, 0.006, 1.46 * scale_h)
    attach(head_pivot, root)
    hp = dict(params)
    hp.setdefault("seed", 3)
    face = make_head(name, hp, parent=head_pivot)
    face["root"].location = (0, 0.008, 1.462 * scale_h + 0.112 * face["scale"])

    # garment
    garment = params.get("garment", "panjabi")
    z_top = 1.435 * scale_h
    if garment == "panjabi":
        prof = _cloth_profile(scale_h, build, 0.012, z_top, 0.72 * scale_h, flare=1.22)
    elif garment == "sari":
        prof = _cloth_profile(scale_h, build, 0.016, z_top, 0.10 * scale_h, flare=1.45)
    else:
        prof = _cloth_profile(scale_h, build, 0.010, z_top, 1.00 * scale_h, flare=1.05)
    body_cloth, _, _ = HEAD.loft(f"{name}_garment", prof, rings=30, segments=40)
    # vertical folds, so fabric is not a shrink-wrapped tube
    for v in body_cloth.data.vertices:
        p = Vector(v.co)
        ang = math.atan2(p.x, -p.y)
        drop = max(0.0, (z_top - p.z))
        fold = math.sin(ang * 9.0) * 0.0035 + math.sin(ang * 23.0 + p.z * 11) * 0.0014
        k = min(1.0, drop / 0.28)
        v.co = Vector((p.x + fold * math.sin(ang) * k, p.y - fold * math.cos(ang) * k, p.z))
    body_cloth.data.materials.append(cloth_main)
    smooth(body_cloth, subsurf=1)
    attach(body_cloth, root)

    if params.get("waistcoat"):
        vprof = _cloth_profile(scale_h, build, 0.015, 1.385 * scale_h, 1.075 * scale_h, flare=1.01)
        vest, _, _ = HEAD.loft(f"{name}_waistcoat", vprof, rings=18, segments=36)
        vest.data.materials.append(cloth_vest)
        smooth(vest, subsurf=1)
        attach(vest, root)

    # arms: shoulder and elbow pivots, sleeves over them
    arms = {}
    for sx, side in ((-1, "l"), (1, "r")):
        sh = bpy.data.objects.new(f"{name}_shoulder_{side}", None)
        bpy.context.collection.objects.link(sh)
        sh.location = (sx * 0.158 * build, 0.0, 1.395 * scale_h)
        attach(sh, root)

        sx0, sz0 = sx * 0.158 * build, 1.395 * scale_h
        upper = limb(f"{name}_upperarm_{side}",
                     [(sx0, 0, sz0), (sx0 + sx * 0.014, 0.004, sz0 - 0.135),
                      (sx0 + sx * 0.020, 0.006, sz0 - 0.268)],
                     [0.050 * build, 0.044 * build, 0.038 * build], segments=18)
        upper.data.materials.append(cloth_main if garment != "shirt" else cloth_main)
        smooth(upper, subsurf=1)
        attach(upper, sh)

        el = bpy.data.objects.new(f"{name}_elbow_{side}", None)
        bpy.context.collection.objects.link(el)
        el.location = (sx0 + sx * 0.020, 0.006, sz0 - 0.268)
        attach(el, sh)

        ex, ez = sx0 + sx * 0.020, sz0 - 0.268
        fore = limb(f"{name}_forearm_{side}",
                    [(ex, 0.006, ez), (ex, 0.010, ez - 0.120), (ex, 0.012, ez - 0.242)],
                    [0.037 * build, 0.032 * build, 0.027 * build], segments=18)
        fore.data.materials.append(cloth_main)
        smooth(fore, subsurf=1)
        attach(fore, el)

        wr = bpy.data.objects.new(f"{name}_wrist_{side}", None)
        bpy.context.collection.objects.link(wr)
        wr.location = (ex, 0.012, ez - 0.242)
        attach(wr, el)
        for part in build_hand(f"{name}_hand_{side}", sx, base=(ex, 0.012, ez - 0.242), scale=0.92 * build):
            part.data.materials.append(skin)
            smooth(part, subsurf=1)
            attach(part, wr)
        cap = noisy_sphere(f"{name}_shouldercap_{side}", (sx0, 0.002, sz0 - 0.012),
                           (0.050 * build, 0.050 * build, 0.047 * build), 0.03, 6.0,
                           segs=24, rings=16, seed=2)
        cap.data.materials.append(cloth_main)
        smooth(cap, subsurf=1)
        attach(cap, sh)
        arms[side] = dict(shoulder=sh, elbow=el, wrist=wr)
        sh.rotation_euler = (math.radians(3), math.radians(sx * 5), 0)

    # legs and shoes, visible when the figure is not behind a podium
    for sx, side in ((-1, "l"), (1, "r")):
        hip = bpy.data.objects.new(f"{name}_hip_{side}", None)
        bpy.context.collection.objects.link(hip)
        hip.location = (sx * 0.072 * build, 0, 0.94 * scale_h)
        attach(hip, root)
        hx, hz = sx * 0.072 * build, 0.94 * scale_h
        leg = limb(f"{name}_leg_{side}",
                   [(hx, 0, hz), (hx, 0.004, hz - 0.44 * scale_h), (hx, 0.010, 0.030 * scale_h)],
                   [0.088 * build, 0.068 * build, 0.052 * build], segments=16)
        leg.data.materials.append(trouser)
        smooth(leg, subsurf=1)
        attach(leg, hip)
        shoe = limb(f"{name}_shoe_{side}",
                    [(hx, 0.010, 0.030 * scale_h), (hx, -0.060, 0.022 * scale_h)],
                    [0.045 * build, 0.034 * build], segments=14)
        shoe.data.materials.append(shoe_m)
        smooth(shoe, subsurf=1)
        attach(shoe, hip)

    root.location = params.get("location", (0, 0, 0))
    root.rotation_euler = (0, 0, math.radians(params.get("facing", 0)))
    return dict(name=name, root=root, spine=spine, head=face, head_pivot=head_pivot,
                arms=arms, garment=body_cloth, scale=scale_h)
