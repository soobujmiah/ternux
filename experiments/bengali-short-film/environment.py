"""The rally: ground, stage, podium, sound system, banner, street, water, crowd.

Everything is generic — no party marks, no slogans, no real place names. The
objects the story needs to move (the banner, the burst pipe, the water, the
puddle) are returned so the animation can key them.
"""

import math
import random

import bpy
from mathutils import Vector

import head as HEAD
import humans as H


def box(name, loc, size, material=None, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc, rotation=rot)
    o = bpy.context.object
    o.name = name
    o.scale = (size[0] / 2, size[1] / 2, size[2] / 2)
    if material:
        o.data.materials.append(material)
    return o


def concrete(name, rgb=(0.17, 0.165, 0.155), rough=0.92, scale=22.0, strength=0.25):
    m = H.mat(name, rgb, rough=rough)
    nt = m.node_tree
    b = nt.nodes["Principled BSDF"]
    tex = nt.nodes.new("ShaderNodeTexCoord")
    n1 = nt.nodes.new("ShaderNodeTexNoise")
    n1.inputs["Scale"].default_value = scale
    n1.inputs["Detail"].default_value = 8.0
    nt.links.new(tex.outputs["Object"], n1.inputs["Vector"])
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.38
    ramp.color_ramp.elements[0].color = (rgb[0] * 0.72, rgb[1] * 0.72, rgb[2] * 0.72, 1)
    ramp.color_ramp.elements[1].position = 0.66
    ramp.color_ramp.elements[1].color = (rgb[0] * 1.25, rgb[1] * 1.22, rgb[2] * 1.18, 1)
    nt.links.new(n1.outputs["Fac"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], b.inputs["Base Color"])
    bump = nt.nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = strength
    nt.links.new(n1.outputs["Fac"], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], b.inputs["Normal"])
    return m


def build_world(detail=1.0):
    rnd = random.Random(7)
    out = {}

    road_m = concrete("road", (0.085, 0.083, 0.082), rough=0.95, scale=30)
    dust_m = concrete("dust", (0.20, 0.165, 0.125), rough=0.96, scale=18)
    stage_m = concrete("stagewood", (0.11, 0.085, 0.062), rough=0.8, scale=40, strength=0.12)
    cloth_red = H.mat("stage_cloth", (0.22, 0.035, 0.045), rough=0.85, sheen=0.4)
    metal = H.mat("metal", (0.22, 0.225, 0.235), rough=0.34, metallic=0.85)
    dark_metal = H.mat("dark_metal", (0.045, 0.045, 0.05), rough=0.45, metallic=0.7)
    plastic_blue = H.mat("plastic_blue", (0.045, 0.09, 0.22), rough=0.42)
    plastic_white = H.mat("plastic_white", (0.52, 0.52, 0.50), rough=0.45)
    banner_m = H.mat("banner", (0.42, 0.075, 0.09), rough=0.78, sheen=0.3)
    banner_stripe = H.mat("banner_stripe", (0.55, 0.47, 0.10), rough=0.75)
    wall_m = concrete("wall", (0.26, 0.23, 0.195), rough=0.9, scale=12)
    wall2_m = concrete("wall2", (0.17, 0.19, 0.185), rough=0.9, scale=10)
    glass = H.mat("glass", (0.03, 0.05, 0.07), rough=0.12, metallic=0.2)
    water_m = H.mat("water", (0.06, 0.10, 0.12), rough=0.07, metallic=0.0)
    wm = water_m.node_tree.nodes["Principled BSDF"]
    wm.inputs["IOR"].default_value = 1.33
    if "Transmission Weight" in wm.inputs:
        wm.inputs["Transmission Weight"].default_value = 0.55

    # ---- ground: road in front, dusty square under the crowd
    bpy.ops.mesh.primitive_plane_add(size=120, location=(0, 4, 0))
    ground = bpy.context.object
    ground.name = "ground"
    ground.data.materials.append(dust_m)
    bpy.ops.mesh.primitive_plane_add(size=1, location=(0, -9.5, 0.004))
    road = bpy.context.object
    road.name = "road"
    road.scale = (60, 7, 1)
    road.data.materials.append(road_m)

    # ---- stage
    stage = box("stage", (0, 6.6, 0.55), (7.4, 4.2, 1.1), stage_m)
    skirt = box("stage_skirt", (0, 4.52, 0.52), (7.5, 0.06, 1.06), cloth_red)
    out["stage"] = stage

    # podium
    pod = box("podium", (0, 5.35, 1.63), (0.80, 0.52, 1.06), stage_m)
    box("podium_top", (0, 5.33, 2.18), (0.92, 0.60, 0.05), stage_m)
    box("podium_panel", (0, 5.08, 1.72), (0.66, 0.03, 0.70), cloth_red)
    out["podium"] = pod

    # microphones on the podium
    mics = []
    for i, (dx, tilt) in enumerate(((-0.16, -12), (0.16, 10))):
        stand = H.limb(f"mic_stand{i}", [(dx, 5.30, 2.20), (dx * 1.35, 5.22, 2.33),
                                         (dx * 1.6, 5.16, 2.41)],
                       [0.011, 0.009, 0.008], segments=10)
        stand.data.materials.append(dark_metal)
        H.smooth(stand, subsurf=1)
        head_ = H.noisy_sphere(f"mic_head{i}", (dx * 1.7, 5.13, 2.44),
                               (0.026, 0.026, 0.032), 0.04, 9.0, segs=20, rings=12, seed=i)
        head_.data.materials.append(dark_metal)
        H.smooth(head_, subsurf=1)
        mics.append(head_)
    out["mics"] = mics

    # ---- loudspeakers on poles, angled at the crowd
    for sx in (-1, 1):
        pole = H.limb(f"sp_pole{sx}", [(sx * 3.9, 5.2, 0.0), (sx * 3.9, 5.2, 3.3)],
                      [0.055, 0.045], segments=10)
        pole.data.materials.append(metal)
        H.smooth(pole, subsurf=1)
        for k, z in enumerate((2.62, 3.06)):
            s = box(f"speaker{sx}_{k}", (sx * 3.75, 5.0, z), (0.42, 0.36, 0.42), dark_metal,
                    rot=(0, 0, math.radians(-sx * 18)))
            H.smooth(s, subsurf=0)
            cone = H.noisy_sphere(f"spcone{sx}_{k}", (sx * 3.58, 4.84, z),
                                  (0.13, 0.05, 0.13), 0.02, 8.0, segs=18, rings=10, seed=k)
            cone.data.materials.append(H.mat(f"cone{sx}{k}", (0.03, 0.03, 0.035), rough=0.7))
            H.smooth(cone, subsurf=1)

    # ---- banner behind the stage, hung from a frame; it can fall later
    for sx in (-1, 1):
        p = H.limb(f"banner_pole{sx}", [(sx * 3.2, 8.3, 0), (sx * 3.2, 8.3, 4.2)],
                   [0.05, 0.042], segments=10)
        p.data.materials.append(metal)
        H.smooth(p, subsurf=1)
    banner_pivot = bpy.data.objects.new("banner_pivot", None)
    bpy.context.collection.objects.link(banner_pivot)
    banner_pivot.location = (-3.2, 8.3, 3.88)   # the left top corner it swings from
    banner = box("banner", (0, 8.3, 3.25), (6.4, 0.03, 1.25), banner_m)
    for k, z in enumerate((3.72, 2.78)):
        st = box(f"banner_stripe{k}", (0, 8.27, z), (6.3, 0.02, 0.10), banner_stripe)
        H.attach(st, banner_pivot)
    H.attach(banner, banner_pivot)
    out["banner"] = banner_pivot

    # ---- buildings, poles and wires
    for i in range(9):
        x = -22 + i * 5.6 + rnd.uniform(-0.8, 0.8)
        d = rnd.uniform(5.0, 8.0)
        h = rnd.uniform(6.0, 13.0)
        y = 15.0 + rnd.uniform(0, 5)
        b = box(f"bldg{i}", (x, y, h / 2), (rnd.uniform(5, 8), d, h),
                wall_m if i % 2 else wall2_m)
        for fl in range(int(h // 3.0)):
            for wx in range(3):
                box(f"win{i}_{fl}_{wx}", (x - 1.9 + wx * 1.9, y - d / 2 - 0.05, 1.6 + fl * 3.0),
                    (1.0, 0.08, 1.2), glass)
    for i in range(7):
        x = -18 + i * 6.0
        p = H.limb(f"pole{i}", [(x, 11.5, 0), (x, 11.5, 7.4)], [0.10, 0.07], segments=10)
        p.data.materials.append(concrete(f"polec{i}", (0.20, 0.19, 0.18), scale=8))
        H.smooth(p, subsurf=1)
        if i:
            for k in range(4):
                sag = 0.55 + 0.12 * k
                pts = []
                for t in range(9):
                    u = t / 8.0
                    pts.append((x - 6.0 + 6.0 * u, 11.5 + 0.12 * k,
                                7.0 - 0.18 * k - sag * math.sin(math.pi * u)))
                w = H.limb(f"wire{i}_{k}", pts, [0.012] * 9, segments=6)
                w.data.materials.append(dark_metal)

    # ---- plastic chairs, a few rows, most of the crowd standing
    for row in range(3):
        for col in range(9):
            if rnd.random() < 0.25:
                continue
            x = -3.6 + col * 0.9 + rnd.uniform(-0.05, 0.05)
            y = 2.9 - row * 0.85
            seat = box(f"chair{row}_{col}", (x, y, 0.44), (0.44, 0.44, 0.075),
                       plastic_blue if (row + col) % 3 else plastic_white,
                       rot=(0, 0, rnd.uniform(-0.2, 0.2)))
            back = box(f"chairb{row}_{col}", (x, y + 0.205, 0.70), (0.44, 0.075, 0.48),
                       plastic_blue if (row + col) % 3 else plastic_white)
            for lx in (-0.17, 0.17):
                for ly in (-0.17, 0.17):
                    box(f"chairl{row}_{col}_{lx}_{ly}", (x + lx, y + ly, 0.21),
                        (0.055, 0.055, 0.42), plastic_blue if (row + col) % 3 else plastic_white)

    # ---- tea stall
    stall = box("stall", (-6.4, 5.2, 1.1), (2.6, 2.0, 2.2), concrete("stallwall", (0.26, 0.22, 0.17)))
    box("stall_roof", (-6.4, 5.2, 2.28), (3.0, 2.4, 0.12), H.mat("tin", (0.26, 0.26, 0.27), rough=0.55, metallic=0.6))
    box("stall_counter", (-6.4, 4.1, 0.9), (2.4, 0.5, 0.09), concrete("counter", (0.22, 0.19, 0.16)))
    kettle = H.noisy_sphere("kettle", (-7.1, 4.05, 1.06), (0.12, 0.12, 0.14), 0.03, 7.0,
                            segs=20, rings=12, seed=3)
    kettle.data.materials.append(metal)
    H.smooth(kettle, subsurf=1)

    # ---- the water: a standpipe with an empty tap, and a feed pipe that bursts
    base = box("tap_base", (4.6, 3.0, 0.42), (0.34, 0.34, 0.84),
               concrete("tapbase", (0.23, 0.22, 0.20)))
    riser = H.limb("tap_riser", [(4.6, 3.0, 0.84), (4.6, 3.0, 1.28)], [0.030, 0.028], segments=12)
    riser.data.materials.append(metal)
    H.smooth(riser, subsurf=1)
    spout = H.limb("tap_spout", [(4.6, 3.0, 1.26), (4.6, 2.86, 1.24), (4.6, 2.80, 1.14)],
                   [0.026, 0.023, 0.020], segments=12)
    spout.data.materials.append(metal)
    H.smooth(spout, subsurf=1)
    handle = H.noisy_sphere("tap_handle", (4.6, 3.10, 1.30), (0.055, 0.035, 0.016), 0.05, 8.0,
                            segs=18, rings=10, seed=4)
    handle.data.materials.append(H.mat("tap_handle_m", (0.25, 0.045, 0.045), rough=0.5))
    H.smooth(handle, subsurf=1)
    out["tap"] = spout

    pipe = H.limb("feed_pipe", [(6.6, 7.9, 0.22), (3.6, 7.9, 0.22), (2.0, 7.6, 0.22)],
                  [0.085, 0.085, 0.080], segments=14)
    pipe.data.materials.append(concrete("pipe_m", (0.20, 0.195, 0.185), rough=0.8, scale=25))
    H.smooth(pipe, subsurf=1)
    out["pipe"] = pipe

    # the jet: a cone of water that can be scaled up when the pipe gives way
    jet = H.noisy_sphere("water_jet", (3.55, 7.86, 0.95), (0.16, 0.16, 0.78), 0.18, 11.0,
                         segs=24, rings=16, seed=8)
    jet.data.materials.append(water_m)
    H.smooth(jet, subsurf=1)
    jet.scale = (0.001, 0.001, 0.001)
    out["jet"] = jet

    drops = []
    for i in range(14):
        d = H.noisy_sphere(f"drop{i}", (3.55 + rnd.uniform(-0.5, 0.9), 7.86 + rnd.uniform(-0.35, 0.35),
                                        0.6 + rnd.uniform(0.0, 1.5)),
                           (0.045, 0.045, 0.060), 0.25, 14.0, segs=12, rings=8, seed=20 + i)
        d.data.materials.append(water_m)
        H.smooth(d, subsurf=1)
        d.scale = (0.001, 0.001, 0.001)
        drops.append(d)
    out["drops"] = drops

    puddle = H.noisy_sphere("puddle", (3.3, 7.6, 0.012), (1.0, 0.8, 0.012), 0.12, 5.0,
                            segs=28, rings=14, seed=9)
    puddle.data.materials.append(water_m)
    H.smooth(puddle, subsurf=1)
    puddle.scale = (0.001, 0.001, 0.001)
    out["puddle"] = puddle

    return out
