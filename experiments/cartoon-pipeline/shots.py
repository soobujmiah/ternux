"""The four shots of "Bulbul and the stubborn flower".

Each shot sets its own camera and its own keyframes on the shared rig, and
returns its length in frames. Shots are rendered independently, one Blender
process each, so shader compilation is paid once per shot rather than per frame.
"""

import math

from scene import blink, camera, hop, key

FLOWER_X = 2.60


def _breathe(rig, start, end, period=22):
    """Idle breathing, so a held pose is never completely dead."""
    f = start
    while f < end:
        key(rig["squash"], "scale", f, (1.0, 1.0, 1.0))
        key(rig["squash"], "scale", min(f + period // 2, end), (1.03, 1.03, 0.97))
        f += period
    key(rig["squash"], "scale", end, (1.0, 1.0, 1.0))


def _eye_pop(rig, frame, amount=1.5):
    for p in rig["pupils"]:
        base = tuple(p.scale)
        key(p, "scale", frame - 2, base)
        key(p, "scale", frame + 2, tuple(v * amount for v in base))
        key(p, "scale", frame + 14, base)


def shot1_arrival(rig, flower):
    """Wide. He drops into the meadow, lands hard, looks around, spots it."""
    ctrl, squash, head, lean = rig["ctrl"], rig["squash"], rig["head"], rig["lean"]
    cam = camera("cam1", (0, -7.8, 2.35), (math.radians(84), 0, 0), lens=40)
    key(cam, "location", 1, (0, -8.1, 2.45))
    key(cam, "location", 144, (0, -7.2, 2.2))

    key(ctrl, "location", 1, (-0.8, 0.2, 7.5), interp="LINEAR")
    key(squash, "scale", 1, (0.78, 0.78, 1.35))
    key(squash, "scale", 9, (0.80, 0.80, 1.30), interp="LINEAR")
    key(ctrl, "location", 10, (-0.8, 0.2, 0.0))
    key(squash, "scale", 12, (1.38, 1.38, 0.58), interp="LINEAR")
    key(ctrl, "location", 12, (-0.8, 0.2, 0.0), interp="LINEAR")
    key(squash, "scale", 17, (0.90, 0.90, 1.14))
    key(ctrl, "location", 17, (-0.8, 0.2, 0.30))
    key(squash, "scale", 22, (1.04, 1.04, 0.97))
    key(ctrl, "location", 22, (-0.8, 0.2, 0.0))
    key(squash, "scale", 26, (1.0, 1.0, 1.0))

    key(head, "rotation_euler", 26, (0, 0, 0))
    key(head, "rotation_euler", 36, (0, 0, math.radians(34)))
    key(head, "rotation_euler", 48, (0, 0, math.radians(-32)))
    blink(rig, 54)
    key(head, "rotation_euler", 60, (0, 0, 0))

    # he notices the flower, off to his right
    key(head, "rotation_euler", 74, (0, 0, math.radians(-38)))
    _eye_pop(rig, 78)
    key(lean, "rotation_euler", 74, (0, 0, 0))
    key(lean, "rotation_euler", 86, (math.radians(-9), 0, 0))
    key(lean, "rotation_euler", 104, (0, 0, 0))
    for t in rig["tufts"]:
        base = tuple(t.scale)
        key(t, "scale", 76, base)
        key(t, "scale", 80, tuple(v * 1.35 for v in base), interp="LINEAR")
        key(t, "scale", 88, base)

    _breathe(rig, 96, 140)
    blink(rig, 120)
    key(head, "rotation_euler", 144, (0, 0, math.radians(-30)))
    return 144


def shot2_reach(rig, flower):
    """Medium. Two hops in, then a long reach the flower keeps dodging."""
    ctrl, head, lean = rig["ctrl"], rig["head"], rig["lean"]
    arm_r, bend = rig["arms"]["arm_r"], flower["bend"]
    cam = camera("cam2", (1.35, -7.3, 2.10), (math.radians(85), 0, 0), lens=48)
    key(cam, "location", 1, (1.25, -7.5, 2.15))
    key(cam, "location", 144, (1.45, -6.9, 2.00))

    key(head, "rotation_euler", 1, (0, 0, math.radians(-30)))
    key(head, "rotation_euler", 20, (0, 0, math.radians(-12)))
    hop(rig, 8, 32, (-0.8, 0.2), (0.15, 0.3))
    hop(rig, 46, 70, (0.15, 0.3), (1.30, 0.35))
    key(ctrl, "location", 84, (1.30, 0.35, 0))

    # the reach, and the flower leaning out of range
    key(arm_r, "rotation_euler", 84, (0, 0, 0))
    key(arm_r, "rotation_euler", 98, (0, math.radians(-58), 0))
    key(lean, "rotation_euler", 84, (0, 0, 0))
    key(lean, "rotation_euler", 100, (math.radians(-16), 0, 0))
    key(bend, "rotation_euler", 92, (0, 0, 0))
    key(bend, "rotation_euler", 108, (math.radians(-2), math.radians(16), 0))
    key(arm_r, "rotation_euler", 118, (0, math.radians(-74), 0))
    key(lean, "rotation_euler", 118, (math.radians(-24), 0, 0))
    key(bend, "rotation_euler", 126, (math.radians(-3), math.radians(24), 0))
    blink(rig, 130)
    key(arm_r, "rotation_euler", 144, (0, math.radians(-80), 0))
    key(lean, "rotation_euler", 144, (math.radians(-26), 0, 0))
    key(bend, "rotation_euler", 144, (math.radians(-3), math.radians(22), 0))
    return 144


def shot3_boing(rig, flower):
    """Close. He finally grabs it, pulls, and it snaps back into him."""
    ctrl, squash, head, lean = rig["ctrl"], rig["squash"], rig["head"], rig["lean"]
    arm_r, bend = rig["arms"]["arm_r"], flower["bend"]
    cam = camera("cam3", (1.60, -7.15, 1.85), (math.radians(85), 0, 0), lens=50)
    key(cam, "location", 1, (1.55, -7.25, 1.90))
    key(cam, "location", 168, (1.70, -6.80, 1.75))

    key(ctrl, "location", 1, (1.30, 0.35, 0))
    key(arm_r, "rotation_euler", 1, (0, math.radians(-80), 0))
    key(lean, "rotation_euler", 1, (math.radians(-26), 0, 0))
    key(bend, "rotation_euler", 1, (math.radians(-3), math.radians(22), 0))

    # grab: the flower is caught and dragged back toward him
    # The pull bends the stem toward him and toward the camera at once, so the
    # flower head stays clear of his silhouette instead of hiding behind it.
    key(ctrl, "location", 14, (1.30, 0.35, 0))
    key(ctrl, "location", 40, (0.92, 0.30, 0))
    key(ctrl, "location", 50, (0.92, 0.30, 0))
    key(bend, "rotation_euler", 14, (math.radians(5), math.radians(-8), 0))
    key(arm_r, "rotation_euler", 14, (0, math.radians(-64), 0))
    key(lean, "rotation_euler", 20, (math.radians(-10), 0, 0))
    # the pull, held at full stretch
    key(bend, "rotation_euler", 40, (math.radians(40), math.radians(-16), 0))
    key(lean, "rotation_euler", 40, (math.radians(18), 0, 0))
    key(squash, "scale", 40, (1.08, 1.08, 0.94))
    key(bend, "rotation_euler", 48, (math.radians(44), math.radians(-18), 0))
    # release and whip forward
    key(bend, "rotation_euler", 53, (math.radians(-18), math.radians(14), 0), interp="LINEAR")
    key(arm_r, "rotation_euler", 52, (0, math.radians(10), 0), interp="LINEAR")
    key(bend, "rotation_euler", 58, (math.radians(7), math.radians(-13), 0), interp="LINEAR")
    key(bend, "rotation_euler", 64, (math.radians(-4), math.radians(7), 0))
    key(bend, "rotation_euler", 72, (math.radians(2), math.radians(-3), 0))
    key(bend, "rotation_euler", 82, (0, 0, 0))

    # the bonk, the spin, and the fall
    key(squash, "scale", 54, (1.34, 1.34, 0.70), interp="LINEAR")
    key(lean, "rotation_euler", 54, (math.radians(-6), 0, 0), interp="LINEAR")
    key(lean, "rotation_euler", 68, (math.radians(-6), 0, math.radians(360)))
    key(squash, "scale", 62, (0.92, 0.92, 1.1))
    key(ctrl, "location", 56, (0.92, 0.30, 0), interp="LINEAR")
    key(ctrl, "location", 74, (0.75, 0.65, 0.0))
    key(lean, "rotation_euler", 84, (math.radians(74), 0, math.radians(360)))
    key(squash, "scale", 84, (1.12, 1.12, 0.9))
    key(lean, "rotation_euler", 92, (math.radians(66), 0, math.radians(360)))

    # dizzy, then upright again
    key(head, "rotation_euler", 92, (0, 0, 0))
    for i, f in enumerate(range(100, 130, 8)):
        key(head, "rotation_euler", f, (0, 0, math.radians(26 if i % 2 == 0 else -26)))
    key(head, "rotation_euler", 134, (0, 0, 0))
    blink(rig, 118)
    key(lean, "rotation_euler", 134, (math.radians(6), 0, math.radians(360)))
    key(lean, "rotation_euler", 146, (0, 0, math.radians(360)))
    key(squash, "scale", 146, (1.0, 1.0, 1.0))
    blink(rig, 150)
    key(head, "rotation_euler", 162, (0, 0, math.radians(-26)))
    _eye_pop(rig, 156, 1.35)
    return 168


def shot4_bloom(rig, flower):
    """Wide, pushing in. The flower blooms, and he takes the credit."""
    ctrl, squash, head, lean = rig["ctrl"], rig["squash"], rig["head"], rig["lean"]
    arm_l, arm_r = rig["arms"]["arm_l"], rig["arms"]["arm_r"]
    bend, core = flower["bend"], flower["core"]
    cam = camera("cam4", (1.00, -7.2, 2.2), (math.radians(84), 0, 0), lens=42)
    key(cam, "location", 1, (0.90, -8.3, 2.35))
    key(cam, "location", 192, (1.15, -7.2, 2.10))

    key(ctrl, "location", 1, (0.75, 0.65, 0))
    key(head, "rotation_euler", 1, (0, 0, math.radians(-26)))
    key(bend, "rotation_euler", 1, (0, 0, 0))

    # the bloom: the first ring opens, a second ring grows out of nothing
    for p in flower["petals"]:
        base = tuple(p.scale)
        key(p, "scale", 20, base)
        key(p, "scale", 56, tuple(v * 2.1 for v in base))
    for p in flower["petals2"]:
        key(p, "scale", 26, (0.0001, 0.0001, 0.0001))
        key(p, "scale", 62, (0.38, 0.38, 0.11))
    base_core = tuple(core.scale)
    key(core, "scale", 20, base_core)
    key(core, "scale", 58, tuple(v * 1.9 for v in base_core))
    key(bend, "rotation_euler", 30, (0, 0, 0))
    key(bend, "rotation_euler", 44, (math.radians(-4), 0, 0))
    key(bend, "rotation_euler", 64, (0, 0, 0))

    # he puffs up with pride
    _eye_pop(rig, 44, 1.6)
    key(squash, "scale", 36, (1.0, 1.0, 1.0))
    key(squash, "scale", 52, (1.18, 1.18, 1.12))
    key(squash, "scale", 70, (1.0, 1.0, 1.0))
    for t in rig["tufts"]:
        b = tuple(t.scale)
        key(t, "scale", 40, b)
        key(t, "scale", 50, tuple(v * 1.5 for v in b), interp="LINEAR")
        key(t, "scale", 66, b)

    # three happy bounces
    f = 72
    for _ in range(3):
        key(ctrl, "location", f, (0.75, 0.65, 0))
        key(squash, "scale", f, (1.0, 1.0, 1.0))
        key(ctrl, "location", f + 6, (0.75, 0.65, 0.55), interp="LINEAR")
        key(squash, "scale", f + 6, (0.9, 0.9, 1.12))
        key(ctrl, "location", f + 12, (0.75, 0.65, 0), interp="LINEAR")
        key(squash, "scale", f + 13, (1.2, 1.2, 0.84), interp="LINEAR")
        f += 16

    # a wave at the camera
    key(arm_r, "rotation_euler", 122, (0, 0, 0))
    for i, fr in enumerate(range(128, 152, 7)):
        key(arm_r, "rotation_euler", fr, (0, math.radians(-150 if i % 2 == 0 else -92), 0))
    key(arm_r, "rotation_euler", 158, (0, 0, 0))
    blink(rig, 140)

    # and out of frame, leaving the flower
    key(squash, "scale", 162, (1.0, 1.0, 1.0))
    key(squash, "scale", 168, (1.30, 1.30, 0.66))
    key(ctrl, "location", 168, (0.75, 0.65, 0))
    key(squash, "scale", 173, (0.74, 0.74, 1.42), interp="LINEAR")
    key(ctrl, "location", 173, (0.65, 0.65, 1.6), interp="LINEAR")
    key(ctrl, "location", 182, (0.35, 0.65, 8.5), interp="LINEAR")
    key(arm_l, "rotation_euler", 166, (0, 0, 0))
    key(arm_l, "rotation_euler", 176, (0, math.radians(-40), 0))
    key(arm_r, "rotation_euler", 176, (0, math.radians(-40), 0))
    # hold on the flower alone
    key(core, "scale", 192, tuple(v * 1.9 for v in base_core))
    return 192


SHOTS = [shot1_arrival, shot2_reach, shot3_boing, shot4_bloom]
