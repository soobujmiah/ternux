"""A head built by lofting anatomical cross-sections, with separate nose, lips,
ears, eyes and lids.

Displacing a sphere does not converge: a feature large enough to read drags its
neighbours with it. Lofting gives direct control — each horizontal slice of the
skull has its own width, front depth, back depth and squareness — and the parts
that have to move for speech are their own objects.

Local space: the face looks toward -Y, up is +Z, origin at the centre of the
skull. Units are metres; an adult head here is 0.23 m tall.
"""

import math

import bpy
from mathutils import Vector

# z, half-width, front depth, back depth, squareness (1 = ellipse, <1 = boxier)
ADULT_PROFILE = [
    (0.1150, 0.016, 0.022, 0.026, 1.00),
    (0.1050, 0.045, 0.052, 0.058, 1.00),
    (0.0900, 0.063, 0.070, 0.078, 0.98),
    (0.0700, 0.072, 0.080, 0.086, 0.95),
    (0.0500, 0.077, 0.085, 0.090, 0.92),
    (0.0350, 0.079, 0.087, 0.091, 0.90),   # brow
    (0.0150, 0.080, 0.085, 0.092, 0.88),   # eye line
    (-0.0050, 0.079, 0.086, 0.092, 0.86),  # cheekbone
    (-0.0250, 0.076, 0.085, 0.090, 0.84),
    (-0.0450, 0.070, 0.082, 0.088, 0.82),  # mouth
    (-0.0650, 0.062, 0.078, 0.085, 0.80),
    (-0.0850, 0.050, 0.070, 0.080, 0.80),  # jaw
    (-0.1000, 0.034, 0.057, 0.070, 0.84),
    (-0.1120, 0.018, 0.036, 0.055, 0.92),  # chin
    (-0.1180, 0.008, 0.015, 0.030, 1.00),
]


def _lerp(a, b, t):
    return a + (b - a) * t


def _sample(profile, z):
    if z >= profile[0][0]:
        return profile[0][1:]
    if z <= profile[-1][0]:
        return profile[-1][1:]
    for i in range(len(profile) - 1):
        z0, *p0 = profile[i]
        z1, *p1 = profile[i + 1]
        if z1 <= z <= z0:
            t = (z0 - z) / (z0 - z1)
            return tuple(_lerp(a, b, t) for a, b in zip(p0, p1))
    return profile[-1][1:]


def loft(name, profile, rings=46, segments=48, scale=(1.0, 1.0, 1.0)):
    """Build a closed surface from a table of cross-sections."""
    zs = [_lerp(profile[0][0], profile[-1][0], i / (rings - 1)) for i in range(rings)]
    verts, faces = [], []
    for z in zs:
        w, df, db, sq = _sample(profile, z)
        for j in range(segments):
            a = 2.0 * math.pi * j / segments
            s, c = math.sin(a), math.cos(a)
            x = w * math.copysign(abs(s) ** sq, s)
            depth = df if c > 0 else db
            y = -depth * math.copysign(abs(c) ** sq, c)
            verts.append((x * scale[0], y * scale[1], z * scale[2]))
    for i in range(rings - 1):
        for j in range(segments):
            a = i * segments + j
            b = i * segments + (j + 1) % segments
            faces.append((a, b, b + segments, a + segments))
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], faces)
    me.validate()
    ob = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(ob)
    return ob, segments, rings


def _falloff(d, r):
    if d >= r:
        return 0.0
    t = 1.0 - d / r
    return t * t * (3 - 2 * t)


def build_skull(name, profile=None, scale=(1.0, 1.0, 1.0), eye=(0.0335, 0.012),
                socket_depth=0.030, brow_ridge=0.006, temple=0.004):
    """The skull, with eye apertures deep enough for an eyeball to show through
    and a brow ridge above them."""
    prof = profile or ADULT_PROFILE
    ob, segs, rings = loft(name, prof, scale=scale)
    ex, ez = eye
    for v in ob.data.vertices:
        p = Vector(v.co)
        if p.y >= 0:
            continue
        for sx in (-1, 1):
            # elliptical aperture, wider than tall
            dx = (p.x - sx * ex) / 0.030
            dz = (p.z - ez) / 0.019
            d = math.hypot(dx, dz)
            k = _falloff(d, 1.0)
            p.y += socket_depth * k
            # brow ridge just above the aperture
            bz = (p.z - (ez + 0.024)) / 0.017
            bx = (p.x - sx * ex) / 0.034
            p.y -= brow_ridge * _falloff(math.hypot(bx, bz), 1.0)
            # temple hollow, which reads as bone structure
            tx = (p.x - sx * 0.070) / 0.028
            tz = (p.z - (ez + 0.030)) / 0.030
            p.x -= sx * temple * _falloff(math.hypot(tx, tz), 1.0)
        # muzzle: the mouth sits on a forward mass, not on a flat plane
        mz = (p.z + 0.050) / 0.040
        mx = p.x / 0.045
        p.y -= 0.0075 * _falloff(math.hypot(mx, mz), 1.0)
        v.co = p
    return ob


def build_nose(name, length=1.0, width=1.0, bridge_z=0.040, base_z=-0.038):
    """A separate wedge: the nose is the feature a skull displacement cannot
    produce without dragging the forehead with it."""
    rings, segs = 16, 24
    verts, faces = [], []
    for i in range(rings):
        t = i / (rings - 1)
        z = _lerp(bridge_z, base_z, t)
        # the bridge is narrow and shallow, the tip wide and forward
        w = _lerp(0.0085, 0.0165, t ** 1.5) * width
        out = _lerp(0.004, 0.0215, t ** 1.3) * length
        back = 0.030
        for j in range(segs):
            a = 2.0 * math.pi * j / segs
            s, c = math.sin(a), math.cos(a)
            x = w * s
            y = -out * max(c, 0.0) + back * min(c, 0.0)
            verts.append((x, y, z + (0.004 * length if c > 0 else 0) * t))
    for i in range(rings - 1):
        for j in range(segs):
            a = i * segs + j
            b = i * segs + (j + 1) % segs
            faces.append((a, b, b + segs, a + segs))
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], faces)
    me.validate()
    ob = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(ob)

    # nostril wings and a septum notch
    for v in ob.data.vertices:
        p = Vector(v.co)
        for sx in (-1, 1):
            d = math.hypot((p.x - sx * 0.0135) / 0.010, (p.z - (base_z + 0.004)) / 0.008)
            k = _falloff(d, 1.0)
            p.x += sx * 0.0035 * k
            p.y -= 0.002 * k
        d = math.hypot(p.x / 0.005, (p.z - (base_z - 0.001)) / 0.006)
        p.y += 0.004 * _falloff(d, 1.0)
        v.co = p
    return ob


def build_lip(name, upper=True, width=0.026, thickness=0.0062, protrude=0.008):
    """A lip as a tube swept along a horizontal arc: thickest in the middle,
    tapering and curving back at the corners, so it has volume rather than
    reading as a drawn line."""
    cols, segs = 26, 14
    verts, faces = [], []
    for i in range(cols):
        u = -1.0 + 2.0 * i / (cols - 1)
        c = max(0.0, 1.0 - u * u)                  # 1 in the middle, 0 at the corners
        x = width * u
        cy = -protrude * (0.35 + 0.65 * c)
        cz = (0.0022 if upper else -0.0022) * (1.0 - c)
        ry = thickness * (0.30 + 0.70 * c)
        rz = thickness * (0.42 + 0.58 * c) * (1.0 if upper else 1.15)
        for j in range(segs):
            a = 2.0 * math.pi * j / segs
            verts.append((x, cy - ry * math.cos(a), cz + rz * math.sin(a)))
    for i in range(cols - 1):
        for j in range(segs):
            a = i * segs + j
            b = i * segs + (j + 1) % segs
            faces.append((a, b, b + segs, a + segs))
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], faces)
    me.validate()
    ob = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(ob)
    return ob


def build_ear(name, side=1.0):
    rings, segs = 12, 20
    verts, faces = [], []
    for i in range(rings):
        t = i / (rings - 1)
        rz = 0.0215 * math.sin(math.pi * (0.10 + 0.86 * t))
        for j in range(segs):
            a = 2.0 * math.pi * j / segs
            y = rz * 1.25 * math.cos(a) + 0.004 * math.sin(2 * a)
            x = side * (0.003 + 0.0085 * (0.5 + 0.5 * math.cos(a)) * (1.0 - 0.35 * t))
            z = -0.023 + 0.046 * t + rz * 0.55 * math.sin(a)
            verts.append((x, y, z))
    for i in range(rings - 1):
        for j in range(segs):
            a = i * segs + j
            b = i * segs + (j + 1) % segs
            faces.append((a, b, b + segs, a + segs))
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], faces)
    me.validate()
    ob = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(ob)
    return ob
