"""Builds the Gold Coast characters in Blender and exports them for Godot.

The player is a young woman in a kaba and slit (a fitted top with puff sleeves
and a long wrap skirt), with a duku (headwrap), gold jewelry, and sandals. The
style follows the reference picture: a slim figure, simple shapes, and flat
warm colors. The colors come from the game's palette file.

The same script also builds the townspeople's other bodies on the same
skeleton, with the same animations: a man (a shirt, trousers, short hair, and
shoes) and a schoolboy (the same, in shorts, with sandals). Godot shrinks the
schoolboy and the woman to make children, and recolors everyone's clothes.

Everything is built from simple shapes in code. To change her, change a number
in this file and run it again. Never hand-edit the mesh.

Run from the repo root (kayayo/):

    /Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup \
        --python blender/scripts/build_player_character.py -- \
        --palette gold-coast/art/palette/palette.gd \
        --glb gold-coast/art/models/characters/player_character.glb \
        --blend blender/characters/player_character.blend \
        --renders /tmp/player_character_renders \
        --townsman gold-coast/art/models/characters/townsman.glb \
        --schoolboy gold-coast/art/models/characters/schoolboy.glb

Blender's axes: Z is up, she faces -Y, and her left hand is on the +X side.
"""

import argparse
import math
import re
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Quaternion, Vector

# ---------------------------------------------------------------------------
# Settings you can change
# ---------------------------------------------------------------------------

FPS = 30
WALK_FRAMES = 24  # one walk cycle (two steps) = 0.8 seconds
IDLE_FRAMES = 90  # one slow breath = 3 seconds
EAT_FRAMES = 60  # one mouthful = 2 seconds
WASH_FRAMES = 30  # one scrub = 1 second
RUN_FRAMES = 16  # one run cycle (two strides) = 0.53 seconds
SIT_FRAMES = 90  # one slow breath, sitting = 3 seconds
AMPE_FRAMES = 24  # two ampe jumps = 0.8 seconds
TEACH_FRAMES = 120  # pointing along the blackboard and looking back at the class = 4 seconds
SEW_FRAMES = 30  # one push of the treadle = 1 second
SIDES = 12  # how round the tubes are (more = smoother, but more triangles)

STRIDE_DEGREES = 22.0  # how far the legs swing forward and back
ARM_SWING_DEGREES = 16.0  # how far the arms swing
SEAT_HEIGHT = 0.42  # the game's benches (scenes/props/chop_table.gd): she sits with her hips just above
SIT_DROP = 0.43  # how far her hips drop to sit on one

# Which palette color each part uses (names from palette.gd).
SKIN = "SKIN_DEEP"
TOP = "CLOTH_CREAM"
SKIRT = "CLOTH_MAROON"
TRIM = "CLOTH_OCHRE"
HEADWRAP = "CLOTH_RED"
GOLD = "GOLD_JEWELRY"
DARK = "DARK_BROWN"
MATERIALS = [SKIN, TOP, SKIRT, TRIM, HEADWRAP, GOLD, DARK]

# Joint positions for her left side, in metres. The right side is a mirror image.
SHOULDER = Vector((0.165, 0.0, 1.375))
ELBOW = Vector((0.204, 0.0, 1.098))
WRIST = Vector((0.239, 0.0, 0.85))
HAND_END = Vector((0.252, 0.0, 0.761))
HIP_JOINT = Vector((0.085, 0.0, 0.90))
KNEE = Vector((0.08, 0.0, 0.48))
ANKLE = Vector((0.075, 0.0, 0.075))
TOE = Vector((0.075, -0.13, 0.02))

X = Vector((1.0, 0.0, 0.0))
Y = Vector((0.0, 1.0, 0.0))
Z = Vector((0.0, 0.0, 1.0))


def mirror(v):
    return Vector((-v.x, v.y, v.z))


# The skeleton. Bone names follow Godot's humanoid naming, so animations from
# other sources (like Mixamo) can be retargeted onto her later.
# (name, head, tail, parent, connected to parent)
BONES = [
    ("Hips", Vector((0, 0, 0.92)), Vector((0, 0, 1.02)), None, False),
    ("Spine", Vector((0, 0, 1.02)), Vector((0, 0, 1.17)), "Hips", True),
    ("Chest", Vector((0, 0, 1.17)), Vector((0, 0, 1.38)), "Spine", True),
    ("Neck", Vector((0, 0, 1.38)), Vector((0, 0, 1.49)), "Chest", True),
    ("Head", Vector((0, 0, 1.49)), Vector((0, 0, 1.72)), "Neck", True),
]
for _side, _flip in (("Left", lambda v: v.copy()), ("Right", mirror)):
    BONES += [
        (f"{_side}Shoulder", _flip(Vector((0.02, 0, 1.36))), _flip(SHOULDER), "Chest", False),
        (f"{_side}UpperArm", _flip(SHOULDER), _flip(ELBOW), f"{_side}Shoulder", True),
        (f"{_side}LowerArm", _flip(ELBOW), _flip(WRIST), f"{_side}UpperArm", True),
        (f"{_side}Hand", _flip(WRIST), _flip(HAND_END), f"{_side}LowerArm", True),
        (f"{_side}UpperLeg", _flip(HIP_JOINT), _flip(KNEE), "Hips", False),
        (f"{_side}LowerLeg", _flip(KNEE), _flip(ANKLE), f"{_side}UpperLeg", True),
        (f"{_side}Foot", _flip(ANKLE), _flip(TOE), f"{_side}LowerLeg", True),
    ]


# ---------------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------------


def read_palette(path):
    """Reads the colors out of palette.gd, so the game's palette stays the one
    place colors are defined."""
    text = Path(path).read_text()
    pattern = r'ColorName\.([A-Z_]+):\s*Color\("#([0-9A-Fa-f]{6})"\)'
    return {
        name: tuple(int(value[i : i + 2], 16) / 255.0 for i in (0, 2, 4))
        for name, value in re.findall(pattern, text)
    }


def srgb_to_linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def make_materials(palette):
    materials = []
    for name in MATERIALS:
        linear = (*(srgb_to_linear(c) for c in palette[name]), 1.0)
        material = bpy.data.materials.new(name.lower())
        bsdf = next(n for n in material.node_tree.nodes if n.bl_idname == "ShaderNodeBsdfPrincipled")
        bsdf.inputs["Base Color"].default_value = linear
        bsdf.inputs["Roughness"].default_value = 0.35 if name == GOLD else 0.85
        bsdf.inputs["Metallic"].default_value = 0.7 if name == GOLD else 0.0
        material.diffuse_color = linear
        material.use_backface_culling = True
        materials.append(material)
    return materials


# ---------------------------------------------------------------------------
# Skin weights: how strongly each bone moves each vertex
# ---------------------------------------------------------------------------


def smoothstep(edge0, edge1, x):
    t = max(0.0, min(1.0, (x - edge0) / (edge1 - edge0)))
    return t * t * (3.0 - 2.0 * t)


def only(bone):
    return lambda p: {bone: 1.0}


def by_height(bones, heights, blend):
    """For upright parts (body, neck): bones[i] owns the heights between
    heights[i] and heights[i + 1], and neighbours share a band of `blend`
    metres around each boundary so the mesh bends smoothly."""

    def weights(p):
        i = 0
        while i < len(bones) - 1 and p.z >= heights[i + 1]:
            i += 1
        w = {bones[i]: 1.0}
        if i > 0 and p.z - heights[i] < blend:
            share = 0.5 - 0.5 * (p.z - heights[i]) / blend
            w = {bones[i]: 1.0 - share, bones[i - 1]: share}
        elif i < len(bones) - 1 and heights[i + 1] - p.z < blend:
            share = 0.5 - 0.5 * (heights[i + 1] - p.z) / blend
            w = {bones[i]: 1.0 - share, bones[i + 1]: share}
        return w

    return weights


def along_chain(bones, joints, blend=0.04):
    """For limbs: bones[i] runs from joints[i] to joints[i + 1]. Each vertex
    belongs to its nearest bone, shared with the neighbouring bone near a joint."""

    def weights(p):
        best = None
        for i in range(len(bones)):
            a, b = joints[i], joints[i + 1]
            ab = b - a
            t = max(0.0, min(1.0, (p - a).dot(ab) / ab.length_squared))
            distance = (p - (a + ab * t)).length
            if best is None or distance < best[0]:
                best = (distance, i, t * ab.length, ab.length)
        _, i, along, length = best
        w = {bones[i]: 1.0}
        if i > 0 and along < blend:
            share = 0.5 - 0.5 * along / blend
            w = {bones[i]: 1.0 - share, bones[i - 1]: share}
        elif i < len(bones) - 1 and length - along < blend:
            share = 0.5 - 0.5 * (length - along) / blend
            w = {bones[i]: 1.0 - share, bones[i + 1]: share}
        return w

    return weights


def skirt_weights(p):
    """The skirt hangs from the hips and, lower down, follows the legs. The
    middle of the skirt is shared by both legs, so it stretches between them
    like cloth when she walks."""
    leg = 0.8 * smoothstep(0.86, 0.55, p.z)  # 0 at the hips, 0.8 from the knees down
    lower = smoothstep(0.62, 0.35, p.z)  # how much the lower legs take over
    left = smoothstep(-0.07, 0.07, p.x)  # 1 on her left side, 0 on her right
    return {
        "Hips": 1.0 - leg,
        "LeftUpperLeg": leg * left * (1.0 - lower),
        "LeftLowerLeg": leg * left * lower,
        "RightUpperLeg": leg * (1.0 - left) * (1.0 - lower),
        "RightLowerLeg": leg * (1.0 - left) * lower,
    }


def finalize(weights):
    """Keeps the 4 strongest bones (the most game engines use per vertex) and
    makes the weights add up to 1."""
    strongest = sorted(((w, bone) for bone, w in weights.items() if w > 1e-4), reverse=True)[:4]
    total = sum(w for w, _ in strongest)
    return {bone: w / total for w, bone in strongest}


# ---------------------------------------------------------------------------
# Shapes
# ---------------------------------------------------------------------------


class MeshBuilder:
    """Collects every shape into one mesh, remembering each vertex's bone
    weights (in the order the vertices are made)."""

    def __init__(self):
        self.bm = bmesh.new()
        self.weights = []

    def vert(self, position, weights):
        self.weights.append(weights(position))
        return self.bm.verts.new(position)

    def face(self, verts, material, smooth=True):
        face = self.bm.faces.new(verts)
        face.material_index = MATERIALS.index(material)
        face.smooth = smooth
        return face


def tube(builder, rings, material, weights, u=None, cap_start=False, cap_end=False, segment_materials=None):
    """A tube through `rings`, a list of (center, radius_u, radius_v). All rings
    face along the tube's overall direction."""
    direction = (rings[-1][0] - rings[0][0]).normalized()
    if u is None:
        reference = Y if abs(direction.y) < 0.9 else X
        u = direction.cross(reference).normalized()
    v = direction.cross(u).normalized()
    loops = []
    for center, radius_u, radius_v in rings:
        loop = []
        for i in range(SIDES):
            angle = 2.0 * math.pi * i / SIDES
            loop.append(builder.vert(center + u * (radius_u * math.cos(angle)) + v * (radius_v * math.sin(angle)), weights))
        loops.append(loop)
    for k in range(len(loops) - 1):
        segment_material = segment_materials[k] if segment_materials else material
        for i in range(SIDES):
            j = (i + 1) % SIDES
            builder.face([loops[k][i], loops[k][j], loops[k + 1][j], loops[k + 1][i]], segment_material)
    if cap_start:
        builder.face(list(reversed(loops[0])), material)
    if cap_end:
        builder.face(loops[-1], material)


def ellipsoid(builder, center, radii, material, weights, rings=8, sides=SIDES, rotation=None):
    rotation = rotation or Quaternion()
    rx, ry, rz = radii
    top = builder.vert(center + rotation @ Vector((0, 0, rz)), weights)
    bottom = builder.vert(center + rotation @ Vector((0, 0, -rz)), weights)
    loops = []
    for r in range(1, rings):
        polar = math.pi * r / rings
        loop = []
        for i in range(sides):
            angle = 2.0 * math.pi * i / sides
            offset = Vector((rx * math.sin(polar) * math.cos(angle), ry * math.sin(polar) * math.sin(angle), rz * math.cos(polar)))
            loop.append(builder.vert(center + rotation @ offset, weights))
        loops.append(loop)
    for i in range(sides):
        j = (i + 1) % sides
        builder.face([top, loops[0][i], loops[0][j]], material)
        builder.face([bottom, loops[-1][j], loops[-1][i]], material)
    for k in range(len(loops) - 1):
        for i in range(sides):
            j = (i + 1) % sides
            builder.face([loops[k][i], loops[k + 1][i], loops[k + 1][j], loops[k][j]], material)


def torus(builder, center, axis, major, minor, material, weights, segments=12, ring_sides=5):
    axis = axis.normalized()
    reference = X if abs(axis.x) < 0.9 else Y
    a = axis.cross(reference).normalized()
    b = axis.cross(a).normalized()
    loops = []
    for i in range(segments):
        t = 2.0 * math.pi * i / segments
        radial = a * math.cos(t) + b * math.sin(t)
        ring_center = center + radial * major
        loops.append([
            builder.vert(ring_center + radial * (minor * math.cos(s)) + axis * (minor * math.sin(s)), weights)
            for s in (2.0 * math.pi * k / ring_sides for k in range(ring_sides))
        ])
    for i in range(segments):
        i2 = (i + 1) % segments
        for k in range(ring_sides):
            k2 = (k + 1) % ring_sides
            builder.face([loops[i][k], loops[i2][k], loops[i2][k2], loops[i][k2]], material)


def box(builder, low, high, material, weights):
    (x0, y0, z0), (x1, y1, z1) = low, high
    corners = [Vector(c) for c in [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0),
                                   (x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)]]
    v = [builder.vert(c, weights) for c in corners]
    for face in [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]:
        builder.face([v[i] for i in face], material, smooth=False)


# ---------------------------------------------------------------------------
# The character
# ---------------------------------------------------------------------------


def build_face(builder, earrings=True):
    head = only("Head")
    ellipsoid(builder, Vector((0, -0.005, 1.595)), (0.085, 0.1, 0.115), SKIN, head)
    ellipsoid(builder, Vector((0, -0.1, 1.582)), (0.013, 0.016, 0.022), SKIN, head, rings=4, sides=6)  # nose
    for flip in (1, -1):
        ellipsoid(builder, Vector((0.084 * flip, 0.005, 1.588)), (0.012, 0.018, 0.026), SKIN, head, rings=4, sides=6)  # ear
        if earrings:
            torus(builder, Vector((0.088 * flip, 0.0, 1.548)), X, 0.016, 0.0035, GOLD, head, segments=10, ring_sides=4)
        ellipsoid(builder, Vector((0.031 * flip, -0.096, 1.603)), (0.014, 0.004, 0.0045), DARK, head,
                  rings=4, sides=6, rotation=Quaternion(Y, math.radians(8 * flip)))  # closed eye
    neck = by_height(["Chest", "Neck", "Head"], [1.17, 1.38, 1.49], blend=0.03)
    tube(builder, [(Vector((0, 0, 1.36)), 0.041, 0.043), (Vector((0, 0, 1.52)), 0.039, 0.041)], SKIN, neck)


def build_duku(builder):
    """The duku (headwrap): a dome over the head, a knot at the back, and two fans on top."""
    head = only("Head")
    ellipsoid(builder, Vector((0, 0.012, 1.66)), (0.102, 0.116, 0.092), HEADWRAP, head, sides=14)
    ellipsoid(builder, Vector((0, 0.105, 1.69)), (0.042, 0.036, 0.04), HEADWRAP, head, rings=6, sides=10)
    for x, turn, size in ((-0.025, 20, (0.07, 0.022, 0.05)), (0.03, -25, (0.05, 0.02, 0.04))):
        fan_rotation = Quaternion(Z, math.radians(turn)) @ Quaternion(X, math.radians(-15))
        ellipsoid(builder, Vector((x, -0.005, 1.762)), size, HEADWRAP, head, rings=6, sides=10, rotation=fan_rotation)


def build_hair(builder):
    """Short hair: a cap over the top, sides, and back of the head that starts
    just above the forehead."""
    ellipsoid(builder, Vector((0, 0.012, 1.625)), (0.09, 0.103, 0.1), DARK, only("Head"), sides=14)


def build_top(builder):
    """The kaba: a fitted top with a little peplum flare at the waist and puff sleeves."""
    body = by_height(["Hips", "Spine", "Chest"], [0.92, 1.02, 1.17], blend=0.05)
    rings = [  # (height, half-width, half-depth, forward offset)
        (0.935, 0.182, 0.144, 0.0),
        (0.975, 0.158, 0.122, 0.0),
        (1.01, 0.138, 0.104, 0.0),
        (1.08, 0.13, 0.099, 0.0),
        (1.18, 0.143, 0.114, -0.008),
        (1.26, 0.153, 0.124, -0.012),
        (1.33, 0.158, 0.106, -0.004),
        (1.385, 0.148, 0.086, 0.0),
        (1.43, 0.07, 0.055, 0.0),
    ]
    tube(builder, [(Vector((0, y, z)), rx, ry) for z, rx, ry, y in rings], TOP, body, cap_end=True)
    torus(builder, Vector((0, -0.01, 1.418)), Vector((0, -0.35, 1.0)), 0.068, 0.007, GOLD, only("Chest"), segments=16, ring_sides=4)  # necklace
    for side, flip in (("Left", lambda v: v.copy()), ("Right", mirror)):
        shoulder, elbow = flip(SHOULDER), flip(ELBOW)
        d = (elbow - shoulder).normalized()
        sleeve = along_chain([f"{side}Shoulder", f"{side}UpperArm"], [flip(Vector((0.02, 0, 1.36))), shoulder, elbow])
        puff = [(-0.03, 0.049), (0.0, 0.058), (0.05, 0.064), (0.10, 0.061), (0.13, 0.053), (0.145, 0.049)]
        tube(builder, [(shoulder + d * t, r, r) for t, r in puff], TOP, sleeve)


def build_arms(builder, bangles=True):
    for side, flip in (("Left", lambda v: v.copy()), ("Right", mirror)):
        shoulder, elbow, wrist, hand_end = flip(SHOULDER), flip(ELBOW), flip(WRIST), flip(HAND_END)
        upper = (elbow - shoulder).normalized()
        lower = (wrist - elbow).normalized()
        arm = along_chain([f"{side}Shoulder", f"{side}UpperArm", f"{side}LowerArm"],
                          [flip(Vector((0.02, 0, 1.36))), shoulder, elbow, wrist])
        tube(builder, [
            (shoulder - upper * 0.02, 0.046, 0.046),
            (shoulder + upper * 0.06, 0.045, 0.045),
            (elbow - upper * 0.05, 0.036, 0.036),
            (elbow, 0.033, 0.033),
            (elbow + lower * 0.06, 0.037, 0.037),
            (wrist - lower * 0.04, 0.031, 0.031),
            (wrist, 0.026, 0.026),
        ], SKIN, arm)
        hand_direction = (hand_end - wrist).normalized()
        hand = along_chain([f"{side}LowerArm", f"{side}Hand"], [elbow, wrist, hand_end])
        tube(builder, [
            (wrist - hand_direction * 0.01, 0.016, 0.025),
            (wrist + hand_direction * 0.04, 0.017, 0.032),
            (hand_end - hand_direction * 0.01, 0.013, 0.026),
            (hand_end, 0.008, 0.015),
        ], SKIN, hand, cap_end=True)
        if bangles:
            torus(builder, wrist - lower * 0.035, lower, 0.034, 0.006, GOLD, only(f"{side}LowerArm"))


def build_skirt(builder):
    """The slit: a long wrap skirt, fitted below the hips, with two trim bands."""
    rings = [  # (height, half-width, half-depth)
        (1.03, 0.118, 0.09), (0.97, 0.15, 0.115), (0.92, 0.172, 0.132), (0.85, 0.18, 0.138),
        (0.78, 0.178, 0.14), (0.62, 0.165, 0.132), (0.45, 0.152, 0.126), (0.30, 0.146, 0.122),
        (0.26, 0.146, 0.122), (0.24, 0.147, 0.123), (0.20, 0.149, 0.124), (0.17, 0.152, 0.127),
    ]
    bands = [SKIRT] * 8 + [TRIM, SKIRT, TRIM]  # one color per gap between rings
    tube(builder, [(Vector((0, 0, z)), rx, ry) for z, rx, ry in rings], SKIRT, skirt_weights, segment_materials=bands)


def build_legs(builder):
    for side, flip in (("Left", lambda v: v.copy()), ("Right", mirror)):
        hip, knee, ankle = flip(HIP_JOINT), flip(KNEE), flip(ANKLE)
        leg = along_chain([f"{side}UpperLeg", f"{side}LowerLeg"], [hip, knee, ankle])
        tube(builder, [
            (hip, 0.068, 0.068),
            (knee + (hip - knee) * 0.6, 0.064, 0.064),
            (knee, 0.046, 0.046),
            (knee + (ankle - knee) * 0.3, 0.05, 0.05),
            (knee + (ankle - knee) * 0.75, 0.037, 0.037),
            (ankle, 0.031, 0.031),
        ], SKIN, leg)
        foot = along_chain([f"{side}LowerLeg", f"{side}Foot"], [knee, ankle, flip(TOE)])
        tube(builder, [
            (ankle + Vector((0, 0.035, -0.035)), 0.03, 0.03),
            (ankle + Vector((0, 0.0, -0.02)), 0.036, 0.04),
            (ankle + Vector((0, -0.06, -0.04)), 0.04, 0.026),
            (ankle + Vector((0, -0.11, -0.052)), 0.038, 0.016),
        ], SKIN, foot, u=X, cap_start=True, cap_end=True)
        box(builder, (ankle.x - 0.045, -0.14, 0.0), (ankle.x + 0.045, 0.068, 0.014), DARK, only(f"{side}Foot"))


def build_shirt(builder):
    """A short-sleeved shirt, tucked into the trousers: straight down the body,
    with a collar."""
    body = by_height(["Hips", "Spine", "Chest"], [0.92, 1.02, 1.17], blend=0.05)
    rings = [  # (height, half-width, half-depth, forward offset)
        (0.955, 0.162, 0.124, 0.0),
        (1.02, 0.158, 0.118, 0.0),
        (1.10, 0.158, 0.116, 0.0),
        (1.20, 0.166, 0.122, -0.006),
        (1.28, 0.172, 0.124, -0.01),
        (1.34, 0.17, 0.108, -0.004),
        (1.39, 0.152, 0.086, 0.0),
        (1.43, 0.07, 0.055, 0.0),
    ]
    tube(builder, [(Vector((0, y, z)), rx, ry) for z, rx, ry, y in rings], TOP, body, cap_end=True)
    torus(builder, Vector((0, -0.006, 1.412)), Vector((0, -0.3, 1.0)), 0.058, 0.012, TOP, only("Chest"), segments=16, ring_sides=4)  # collar
    for side, flip in (("Left", lambda v: v.copy()), ("Right", mirror)):
        shoulder, elbow = flip(SHOULDER), flip(ELBOW)
        d = (elbow - shoulder).normalized()
        sleeve = along_chain([f"{side}Shoulder", f"{side}UpperArm"], [flip(Vector((0.02, 0, 1.36))), shoulder, elbow])
        tube(builder, [(shoulder + d * t, r, r) for t, r in [(-0.03, 0.052), (0.05, 0.056), (0.15, 0.053)]], TOP, sleeve)


def build_trousers(builder, shorts=False):
    """Trousers (or school shorts): a seat over the hips, a belt, and a leg
    around each leg."""
    seat = [(1.0, 0.148, 0.114), (0.93, 0.163, 0.126), (0.86, 0.168, 0.128), (0.80, 0.15, 0.12)]
    tube(builder, [(Vector((0, 0, z)), rx, ry) for z, rx, ry in seat], SKIRT, only("Hips"))
    torus(builder, Vector((0, 0, 0.948)), Z, 0.158, 0.011, TRIM, only("Hips"), segments=16, ring_sides=4)  # belt
    for side, flip in (("Left", lambda v: v.copy()), ("Right", mirror)):
        hip, knee, ankle = flip(HIP_JOINT), flip(KNEE), flip(ANKLE)
        leg = along_chain([f"{side}UpperLeg", f"{side}LowerLeg"], [hip, knee, ankle])
        if shorts:
            rings = [(hip + Vector((0, 0, 0.04)), 0.086, 0.086), (knee + (hip - knee) * 0.2, 0.074, 0.074)]
        else:
            rings = [
                (hip + Vector((0, 0, 0.04)), 0.084, 0.084),
                (knee + (hip - knee) * 0.5, 0.072, 0.072),
                (knee, 0.058, 0.058),
                (ankle + Vector((0, 0, 0.03)), 0.05, 0.05),
            ]
        tube(builder, rings, SKIRT, leg, cap_end=shorts)


def build_shoes(builder):
    """Closed shoes for the men, covering the feet."""
    for side, flip in (("Left", lambda v: v.copy()), ("Right", mirror)):
        ankle = flip(ANKLE)
        box(builder, (ankle.x - 0.048, -0.15, 0.0), (ankle.x + 0.048, 0.07, 0.075), DARK, only(f"{side}Foot"))


def build_character(palette, outfit="woman"):
    """Builds one of the characters: "woman" (the player), "man", or "boy"."""
    materials = make_materials(palette)

    # Skeleton
    armature = bpy.data.armatures.new("Armature")
    rig = bpy.data.objects.new("Armature", armature)
    bpy.context.scene.collection.objects.link(rig)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="EDIT")
    for name, head, tail, parent, connected in BONES:
        bone = armature.edit_bones.new(name)
        bone.head, bone.tail = head, tail
        if parent:
            bone.parent = armature.edit_bones[parent]
            bone.use_connect = connected
    bpy.ops.object.mode_set(mode="OBJECT")

    # Mesh
    builder = MeshBuilder()
    if outfit == "woman":
        build_face(builder)
        build_duku(builder)
        build_top(builder)
        build_arms(builder)
        build_skirt(builder)
        build_legs(builder)
    else:
        build_face(builder, earrings=False)
        build_hair(builder)
        build_shirt(builder)
        build_arms(builder, bangles=False)
        build_trousers(builder, shorts=(outfit == "boy"))
        if outfit == "boy":
            build_legs(builder)  # bare legs below the shorts, and sandals
        else:
            build_shoes(builder)
    bmesh.ops.recalc_face_normals(builder.bm, faces=builder.bm.faces[:])
    mesh = bpy.data.meshes.new("Body")
    builder.bm.to_mesh(mesh)
    builder.bm.free()
    body = bpy.data.objects.new("Body", mesh)
    bpy.context.scene.collection.objects.link(body)
    for material in materials:
        mesh.materials.append(material)

    # Skinning: vertex groups named after bones, plus an Armature modifier.
    groups = {name: body.vertex_groups.new(name=name) for name, *_ in BONES}
    for index, weights in enumerate(builder.weights):
        for bone, weight in finalize(weights).items():
            groups[bone].add([index], weight, "REPLACE")
    body.parent = rig
    body.modifiers.new("Armature", "ARMATURE").object = rig
    return rig, body


# ---------------------------------------------------------------------------
# Animations
# ---------------------------------------------------------------------------


def walk_pose(t):
    """Bone rotations (degrees around world axes) and the hip offset at time t
    (0 to 1) of the walk. At 0 her left foot is forward; at 0.5 her right."""
    phase = 2.0 * math.pi * t
    pose = {
        "Hips": [(Z, -6.0 * math.cos(phase))],
        "Spine": [(X, 3.0)],
        "Chest": [(Z, 5.0 * math.cos(phase))],
        "Head": [(X, -3.0), (Z, -2.0 * math.cos(phase))],
    }
    for side, offset in (("Left", 0.0), ("Right", math.pi)):
        p = phase + offset
        thigh = -STRIDE_DEGREES * math.cos(p)  # negative = forward
        knee = 4.0 + 32.0 * ((1.0 - math.sin(p)) / 2.0) ** 2  # bends while the foot swings forward
        pose[f"{side}UpperLeg"] = [(X, thigh)]
        pose[f"{side}LowerLeg"] = [(X, knee)]
        toe_off = 25.0 * max(0.0, math.cos(p - 1.1 * math.pi)) ** 3  # heel lifts as the back foot pushes off
        heel_strike = -10.0 * max(0.0, math.cos(p)) ** 4  # toes up as the front foot lands
        pose[f"{side}Foot"] = [(X, -(thigh + knee) + toe_off + heel_strike)]  # otherwise keep the foot level
        swing = math.cos(p)  # 1 when this side's leg is forward, so the arm goes back
        pose[f"{side}UpperArm"] = [(X, ARM_SWING_DEGREES * swing)]
        pose[f"{side}LowerArm"] = [(X, -10.0 - 12.0 * (1.0 - swing) / 2.0)]
    hips = Vector((0.015 * math.sin(phase), 0.0, -0.02 - 0.02 * math.cos(2.0 * phase)))
    return pose, hips


def idle_pose(t):
    """Standing still: slow breathing, a small weight shift, and a glance around."""
    phase = 2.0 * math.pi * t
    breath = math.sin(phase)
    pose = {
        "Hips": [(Z, 0.0)],
        "Spine": [(X, 0.0)],
        "Chest": [(X, 1.2 * breath)],
        "Head": [(Z, 3.0 * math.sin(phase)), (X, 1.0 * math.sin(2.0 * phase))],
    }
    for side in ("Left", "Right"):
        pose[f"{side}UpperLeg"] = [(X, 0.0)]
        pose[f"{side}LowerLeg"] = [(X, 2.0)]
        pose[f"{side}Foot"] = [(X, -2.0)]
        pose[f"{side}UpperArm"] = [(X, 1.5 * breath)]
        pose[f"{side}LowerArm"] = [(X, -8.0)]
    hips = Vector((0.005 * breath, 0.0, -0.004 + 0.003 * breath))
    return pose, hips


def eat_pose(t):
    """Sitting on a bench at a table, eating with her right hand the Ghanaian
    way. Her thighs rest level on the seat with her feet flat on the ground,
    her left forearm rests on the table, and her right hand goes from the bowl
    to her mouth and back."""
    lift = smoothstep(0.08, 0.32, t) * (1.0 - smoothstep(0.62, 0.88, t))  # 0 at the bowl, 1 at her mouth
    chew = math.sin(2.0 * math.pi * 4.0 * t) * smoothstep(0.3, 0.45, t) * (1.0 - smoothstep(0.85, 1.0, t))
    lean = 13.0  # how far her body leans toward the table (spine + chest)
    pose = {
        "Hips": [(X, 0.0)],
        "Spine": [(X, 8.0)],
        "Chest": [(X, lean - 8.0)],
        "Head": [(X, 16.0 - 14.0 * lift + 1.5 * chew)],  # looking down at the bowl, up as she eats
    }
    for side in ("Left", "Right"):
        pose[f"{side}UpperLeg"] = [(X, -86.0)]  # thighs level along the seat
        pose[f"{side}LowerLeg"] = [(X, 86.0)]  # shins hanging straight down
        pose[f"{side}Foot"] = [(X, 0.0)]
    # Arm angles add the body's lean back on, so they're measured from upright.
    pose["LeftUpperArm"] = [(X, -54.0 - lean), (Y, 8.0)]  # elbow on the table's edge...
    pose["LeftLowerArm"] = [(X, -36.0)]  # ...and forearm lying on the table
    pose["LeftHand"] = [(X, 0.0)]
    pose["RightUpperArm"] = [(X, -40.0 - lean - 20.0 * lift), (Y, -10.0 - 8.0 * lift), (Z, 15.0 + 25.0 * lift)]
    pose["RightLowerArm"] = [(X, -40.0 - 106.0 * lift)]
    pose["RightHand"] = [(X, -15.0 * lift)]
    return pose, Vector((0.0, 0.0, -SIT_DROP))


def wash_pose(t):
    """Bent over a basin on the ground, scrubbing a bowl: her body tips forward
    from the hips, her knees bend a little, and her hands rub back and forth
    in the water."""
    phase = 2.0 * math.pi * t
    hips_tip = 40.0
    bend = hips_tip + 28.0 + 14.0  # how far her body is tipped forward in all
    pose = {
        "Hips": [(X, hips_tip)],
        "Spine": [(X, 28.0)],
        "Chest": [(X, 14.0 + 1.5 * math.sin(2.0 * phase))],
        "Head": [(X, -38.0)],  # looking down into the basin
    }
    for side in ("Left", "Right"):
        pose[f"{side}UpperLeg"] = [(X, -hips_tip - 12.0)]  # legs stay upright, knees bend forward a little
        pose[f"{side}LowerLeg"] = [(X, 24.0)]
        pose[f"{side}Foot"] = [(X, -12.0)]  # feet flat
    for side, offset in (("Left", 0.0), ("Right", math.pi)):
        scrub = math.sin(phase + offset)
        # Arms reach down into the water (undoing the body's tip), and rub in turn.
        pose[f"{side}UpperArm"] = [(X, -bend - 15.0 + 10.0 * scrub)]
        pose[f"{side}LowerArm"] = [(X, -20.0 - 12.0 * scrub)]
    return pose, Vector((0.0, 0.12, -0.1))


def run_pose(t):
    """Running: long strides with the knees lifting high, arms bent and pumping,
    and a lean forward. Children chase the football like this."""
    phase = 2.0 * math.pi * t
    pose = {
        "Hips": [(Z, -8.0 * math.cos(phase))],
        "Spine": [(X, 12.0)],
        "Chest": [(Z, 8.0 * math.cos(phase))],
        "Head": [(X, -8.0)],
    }
    for side, offset in (("Left", 0.0), ("Right", math.pi)):
        p = phase + offset
        thigh = -38.0 * math.cos(p)  # negative = forward
        knee = 12.0 + 80.0 * ((1.0 - math.sin(p)) / 2.0) ** 2  # the back foot kicks up behind
        pose[f"{side}UpperLeg"] = [(X, thigh)]
        pose[f"{side}LowerLeg"] = [(X, knee)]
        pose[f"{side}Foot"] = [(X, -(thigh + knee) + 20.0 * max(0.0, math.cos(p - 1.1 * math.pi)) ** 2)]
        pose[f"{side}UpperArm"] = [(X, 40.0 * math.cos(p) - 8.0)]  # opposite to the leg on the same side
        pose[f"{side}LowerArm"] = [(X, -80.0)]
    hips = Vector((0.0, 0.0, -0.05 + 0.05 * abs(math.sin(phase))))  # up a little with each stride
    return pose, hips


def sit_pose(t):
    """Sitting on a stool or a bench: hips on the seat, thighs level, feet flat,
    and hands resting on her lap, breathing slowly and looking around."""
    phase = 2.0 * math.pi * t
    pose = {
        "Hips": [(X, 0.0)],
        "Spine": [(X, 4.0)],
        "Chest": [(X, 1.0 * math.sin(phase))],
        "Head": [(Z, 12.0 * math.sin(phase)), (X, 2.0)],
    }
    for side in ("Left", "Right"):
        pose[f"{side}UpperLeg"] = [(X, -86.0)]
        pose[f"{side}LowerLeg"] = [(X, 86.0)]
        pose[f"{side}Foot"] = [(X, 0.0)]
        pose[f"{side}UpperArm"] = [(X, -10.0)]
        pose[f"{side}LowerArm"] = [(X, -44.0)]  # forearms down along the thighs
    return pose, Vector((0.0, 0.0, -SIT_DROP))


def ampe_pose(t):
    """Ampe, a game Ghanaian girls play: jump, clap at the top, and kick one
    foot forward, then jump again with the other. Two jumps in one loop."""
    air = math.sin(math.pi * ((2.0 * t) % 1.0))  # 0 on the ground, 1 at the top of a jump
    pose = {
        "Hips": [(X, 0.0)],
        "Spine": [(X, 3.0)],
        "Chest": [(X, 0.0)],
        "Head": [(X, -6.0 * air)],
    }
    for side, sign in (("Left", 1.0), ("Right", -1.0)):
        forward = max(0.0, sign * math.sin(2.0 * math.pi * t))  # the left foot kicks on the first jump, the right on the second
        thigh = -5.0 - 40.0 * forward
        knee = 5.0 + 30.0 * (1.0 - air)  # knees bend to land and spring
        pose[f"{side}UpperLeg"] = [(X, thigh)]
        pose[f"{side}LowerLeg"] = [(X, knee)]
        pose[f"{side}Foot"] = [(X, -(thigh + knee))]
        pose[f"{side}UpperArm"] = [(X, -10.0 - 50.0 * air), (Y, sign * 25.0 * air)]  # hands meet in front to clap
        pose[f"{side}LowerArm"] = [(X, -30.0 - 40.0 * air)]
    hips = Vector((0.0, 0.0, -0.05 * (1.0 - air) + 0.13 * air))
    return pose, hips


def teach_pose(t):
    """Teaching: standing in front of the class with a book held at her waist,
    pointing at the blackboard on her right. She taps along the words on the
    board, then turns back to look at the class."""
    phase = 2.0 * math.pi * t
    look = smoothstep(0.0, 0.12, t) * (1.0 - smoothstep(0.5, 0.62, t))  # 1 while she looks at the board
    tap = math.sin(2.0 * math.pi * 6.0 * t) * look  # small taps along the words
    pose = {
        "Hips": [(Z, -4.0 * look)],
        "Spine": [(X, 1.0)],
        "Chest": [(Z, -10.0 * look), (X, 1.0 * math.sin(phase))],
        "Head": [(Z, -32.0 * look + 6.0 * math.sin(phase) * (1.0 - look)), (X, -3.0 * look)],
    }
    for side in ("Left", "Right"):
        pose[f"{side}UpperLeg"] = [(X, 0.0)]
        pose[f"{side}LowerLeg"] = [(X, 2.0)]
        pose[f"{side}Foot"] = [(X, -2.0)]
    # Her right arm points out to the side at the board (lower when she turns back).
    pose["RightUpperArm"] = [(Y, 55.0 + 30.0 * look + 4.0 * tap), (X, -30.0)]
    pose["RightLowerArm"] = [(Y, 8.0 + 10.0 * (1.0 - look))]
    pose["RightHand"] = [(Y, 5.0)]
    # Her left forearm holds the book against her waist.
    pose["LeftUpperArm"] = [(X, -18.0), (Y, -6.0)]
    pose["LeftLowerArm"] = [(X, -92.0)]
    pose["LeftHand"] = [(X, 0.0)]
    return pose, Vector((0.006 * math.sin(phase), 0.0, -0.004))


def sew_pose(t):
    """Sewing at a treadle machine: sitting on a stool at its table, leaning in
    and looking down at the needle, both forearms on the table feeding the
    cloth through, and her feet rocking the treadle underneath."""
    phase = 2.0 * math.pi * t
    lean = 16.0  # spine + chest
    pose = {
        "Hips": [(X, 0.0)],
        "Spine": [(X, 10.0)],
        "Chest": [(X, lean - 10.0)],
        "Head": [(X, 22.0), (Z, 2.0 * math.sin(phase))],  # looking down at the needle
    }
    for side, sign in (("Left", 1.0), ("Right", -1.0)):
        pose[f"{side}UpperLeg"] = [(X, -86.0)]
        pose[f"{side}LowerLeg"] = [(X, 86.0)]
        pose[f"{side}Foot"] = [(X, 12.0 * math.sin(phase))]  # heel down, toes down: the treadle rocks
        # Forearms resting on the table, the hands feeding the cloth forward.
        pose[f"{side}UpperArm"] = [(X, -54.0 - lean + 3.0 * math.sin(phase + sign)), (Y, sign * 10.0)]
        pose[f"{side}LowerArm"] = [(X, -36.0)]
        pose[f"{side}Hand"] = [(X, 0.0)]
    return pose, Vector((0.0, 0.0, -SIT_DROP))


def steady_the_load(pose):
    """Her right hand goes up to steady the headpan on her head: the arm swings
    up and out to the side, and the forearm bends in so her hand rests on the
    pan's rim."""
    pose["RightUpperArm"] = [(Y, 124.0), (X, -12.0)]
    pose["RightLowerArm"] = [(Y, 72.0)]
    pose["RightHand"] = [(Y, 20.0)]


def carry_pose(t):
    """Walking with a load on her head, like a kayayo: her legs walk as usual
    and her left arm swings, while her right hand steadies the headpan and her
    head stays level."""
    pose, hips = walk_pose(t)
    steady_the_load(pose)
    pose["Head"] = [(X, -2.0)]
    pose["Chest"] = [(Z, 2.0 * math.cos(2.0 * math.pi * t))]  # less twist, to keep the load still
    return pose, hips


def carry_idle_pose(t):
    """Standing with a load on her head, her right hand steadying it."""
    pose, hips = idle_pose(t)
    steady_the_load(pose)
    pose["Head"] = [(X, 0.0)]
    return pose, hips


def bake_action(rig, name, pose_at, frame_count):
    """Keys every frame of one loop. The last frame matches the first, so the
    animation loops without a hitch."""
    action = bpy.data.actions.new(name)
    action.use_fake_user = True
    rig.animation_data.action = action
    for frame in range(frame_count + 1):
        pose, hips_offset = pose_at(frame / frame_count)
        for bone_name, rotations in pose.items():
            rest = rig.data.bones[bone_name].matrix_local.to_quaternion()
            world = Quaternion()
            for axis, degrees in rotations:
                world = world @ Quaternion(axis, math.radians(degrees))
            pose_bone = rig.pose.bones[bone_name]
            pose_bone.rotation_mode = "QUATERNION"
            # Turn a rotation around world axes into the bone's own axes.
            pose_bone.rotation_quaternion = rest.inverted() @ world @ rest
            pose_bone.keyframe_insert("rotation_quaternion", frame=frame)
        hips = rig.pose.bones["Hips"]
        hips.location = rig.data.bones["Hips"].matrix_local.to_quaternion().inverted() @ hips_offset
        hips.keyframe_insert("location", frame=frame)
    return action


# Every character's animations: (name, pose function, frames in one loop).
ANIMATIONS = [
    ("walk", walk_pose, WALK_FRAMES),
    ("idle", idle_pose, IDLE_FRAMES),
    ("eat", eat_pose, EAT_FRAMES),
    ("wash", wash_pose, WASH_FRAMES),
    ("carry", carry_pose, WALK_FRAMES),
    ("carry_idle", carry_idle_pose, IDLE_FRAMES),
    ("run", run_pose, RUN_FRAMES),
    ("sit", sit_pose, SIT_FRAMES),
    ("ampe", ampe_pose, AMPE_FRAMES),
    ("teach", teach_pose, TEACH_FRAMES),
    ("sew", sew_pose, SEW_FRAMES),
]


def make_character(palette, outfit):
    """Builds a character and bakes all its animations onto NLA tracks (the
    exporter saves every animation it finds there). Returns (rig, body, actions)."""
    rig, body = build_character(palette, outfit)
    rig.animation_data_create()
    actions = {name: bake_action(rig, name, pose, frames) for name, pose, frames in ANIMATIONS}
    rig.animation_data.action = None
    for action in actions.values():
        track = rig.animation_data.nla_tracks.new()
        track.name = action.name
        track.strips.new(action.name, 0, action)
    return rig, body, actions


def export_character(rig, body, path):
    """Exports just the character (not the preview camera or light) to a .glb file."""
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    for obj in bpy.context.scene.objects:
        obj.select_set(obj in (rig, body))
    bpy.context.view_layer.objects.active = rig
    bpy.ops.export_scene.gltf(
        filepath=str(Path(path).resolve()),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_animation_mode="ACTIONS",
        export_force_sampling=True,
        export_materials="EXPORT",
    )


def report(name, rig, body):
    triangles = sum(len(p.vertices) - 2 for p in body.data.polygons)
    height = max((body.matrix_world @ v.co).z for v in body.data.vertices)
    print(f"{name}: {len(body.data.vertices)} vertices, {triangles} triangles, {len(rig.data.bones)} bones, "
          f"{height:.2f} m tall, animations: {', '.join(name for name, *_ in ANIMATIONS)}")


# ---------------------------------------------------------------------------
# Preview renders
# ---------------------------------------------------------------------------


def preview_stage(out_dir):
    """Sets up a light grey stage with a sun and an orthographic camera, and
    returns a function that takes a picture: shoot(filename, direction, frame,
    middle height, view height)."""
    out_dir.mkdir(parents=True, exist_ok=True)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x, scene.render.resolution_y = 420, 640
    scene.view_settings.view_transform = "Standard"
    world = bpy.data.worlds.new("World")
    scene.world = world
    background = next(n for n in world.node_tree.nodes if n.bl_idname == "ShaderNodeBackground")
    background.inputs["Color"].default_value = (0.55, 0.55, 0.55, 1.0)
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN"))
    sun.data.energy = 3.0
    sun.rotation_euler = (math.radians(50), 0.0, math.radians(-30))
    scene.collection.objects.link(sun)
    camera = bpy.data.objects.new("Camera", bpy.data.cameras.new("Camera"))
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 2.0
    scene.collection.objects.link(camera)
    scene.camera = camera

    def shoot(filename, direction, frame=0, middle=0.9, view_height=2.0):
        scene.frame_set(frame)
        camera.data.ortho_scale = view_height
        target = Vector((0, 0, middle))
        camera.location = target + direction.normalized() * 6.0
        camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
        scene.render.filepath = str(out_dir / filename)
        bpy.ops.render.render(write_still=True)

    return shoot


def render_previews(rig, walk, idle, out_dir, eat=None, wash=None, carry=None, carry_idle=None, teach=None, sew=None):
    shoot = preview_stage(out_dir)
    rig.animation_data.action = idle
    shoot("1_front.png", Vector((0, -1, 0)))
    shoot("2_side.png", Vector((1, 0, 0)))
    shoot("3_back.png", Vector((0, 1, 0)))
    shoot("4_game_angle.png", Vector((1, -1, 0.82)))
    rig.animation_data.action = walk
    for i, frame in enumerate([0, WALK_FRAMES // 4, WALK_FRAMES // 2, 3 * WALK_FRAMES // 4]):
        shoot(f"{5 + i}_walk_{frame:02d}.png", Vector((1, 0, 0)), frame)
    if eat is not None:
        # A stand-in bench and table, the same sizes as the game's, to check she sits on the seat.
        props = [
            preview_box("Bench", (1.4, 0.3, 0.05), (0.0, 0.0, SEAT_HEIGHT - 0.025)),
            preview_box("Table", (1.3, 0.7, 0.05), (0.0, -0.56, 0.695)),
        ]
        rig.animation_data.action = eat
        shoot("9_eat_bowl.png", Vector((1, 0, 0)), 0)
        shoot("10_eat_mouth.png", Vector((1, 0, 0)), EAT_FRAMES // 2)
        shoot("11_eat_front.png", Vector((0.3, -1, 0.35)), EAT_FRAMES // 2)
        shoot("12_eat_game_angle.png", Vector((1, -1, 0.82)), 0)
        for prop in props:
            bpy.data.objects.remove(prop)
    if wash is not None:
        rig.animation_data.action = wash
        shoot("13_wash_side.png", Vector((1, 0, 0)), 0)
        shoot("14_wash_side_b.png", Vector((1, 0, 0)), WASH_FRAMES // 2)
        shoot("15_wash_game_angle.png", Vector((1, -1, 0.82)), WASH_FRAMES // 4)
    if carry is not None:
        # A stand-in headpan, the size of the game's, sitting on her duku.
        pan = preview_box("Headpan", (0.6, 0.6, 0.13), (0.0, 0.0, 1.81 + 0.05 + 0.065))
        rig.animation_data.action = carry_idle
        shoot("16_carry_front.png", Vector((0, -1, 0)), 0, 1.05, 2.3)
        shoot("17_carry_game_angle.png", Vector((1, -1, 0.82)), 0, 1.05, 2.3)
        rig.animation_data.action = carry
        shoot("18_carry_walk_side.png", Vector((1, 0, 0)), 0, 1.05, 2.3)
        shoot("19_carry_walk_game_angle.png", Vector((1, -1, 0.82)), WALK_FRAMES // 4, 1.05, 2.3)
        bpy.data.objects.remove(pan)
    if teach is not None:
        rig.animation_data.action = teach
        shoot("20_teach_front.png", Vector((0, -1, 0.15)), TEACH_FRAMES // 4)
        shoot("21_teach_game_angle.png", Vector((1, -1, 0.82)), TEACH_FRAMES // 4)
        shoot("22_teach_looking_back.png", Vector((0.4, -1, 0.3)), 3 * TEACH_FRAMES // 4)
    if sew is not None:
        # A stand-in stool and machine table, the sizes of the game's.
        props = [
            preview_box("Stool", (0.38, 0.34, 0.05), (0.0, 0.0, SEAT_HEIGHT - 0.025)),
            preview_box("Table", (0.9, 0.48, 0.05), (0.0, -0.5, 0.695)),
        ]
        rig.animation_data.action = sew
        shoot("23_sew_side.png", Vector((1, 0, 0)), 0)
        shoot("24_sew_game_angle.png", Vector((1, -1, 0.82)), SEW_FRAMES // 2)
        for prop in props:
            bpy.data.objects.remove(prop)
    rig.animation_data.action = idle


def render_person(rig, actions, out_dir, name):
    """Preview pictures of one of the townspeople's bodies, and of the new
    animations: standing, walking, running, sitting on a stool, and ampe."""
    shoot = preview_stage(out_dir)
    stool = preview_box("Stool", (0.38, 0.34, 0.42), (0.0, 0.0, 0.21))
    stool.hide_render = True
    for action, label, frame, direction in (
        ("idle", "front", 0, Vector((0, -1, 0))),
        ("idle", "game_angle", 0, Vector((1, -1, 0.82))),
        ("walk", "walk", WALK_FRAMES // 4, Vector((1, 0, 0))),
        ("run", "run", RUN_FRAMES // 4, Vector((1, 0, 0))),
        ("sit", "sit", 0, Vector((1, -0.4, 0.3))),
        ("ampe", "ampe", AMPE_FRAMES // 4, Vector((0.4, -1, 0.2))),
    ):
        rig.animation_data.action = actions[action]
        stool.hide_render = action != "sit"
        shoot(f"{name}_{label}.png", direction, frame)
    bpy.data.objects.remove(stool)
    rig.animation_data.action = actions["idle"]


def preview_box(name, size, center):
    """A plain grey box for the preview pictures only (it isn't exported)."""
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=Vector(size), verts=bm.verts)
    bmesh.ops.translate(bm, vec=Vector(center), verts=bm.verts)
    bm.to_mesh(mesh)
    bm.free()
    box = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(box)
    return box


# ---------------------------------------------------------------------------


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--palette", required=True)
    parser.add_argument("--glb", required=True)
    parser.add_argument("--blend")
    parser.add_argument("--renders")
    parser.add_argument("--townsman", help="where to export the man's body (.glb)")
    parser.add_argument("--schoolboy", help="where to export the schoolboy's body (.glb)")
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1 :])

    palette = read_palette(args.palette)
    missing = [name for name in MATERIALS if name not in palette]
    if missing:
        raise SystemExit(f"These colors are missing from the palette: {missing}")

    # The player.
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.render.fps = FPS
    rig, body, actions = make_character(palette, "woman")
    export_character(rig, body, args.glb)
    if args.renders:
        render_previews(rig, actions["walk"], actions["idle"], Path(args.renders), actions["eat"], actions["wash"],
                        actions["carry"], actions["carry_idle"], actions["teach"], actions["sew"])
    if args.blend:
        Path(args.blend).parent.mkdir(parents=True, exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=str(Path(args.blend).resolve()))
    report("CHARACTER", rig, body)

    # The townspeople's other bodies.
    for outfit, path in (("man", args.townsman), ("boy", args.schoolboy)):
        if not path:
            continue
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.context.scene.render.fps = FPS
        rig, body, actions = make_character(palette, outfit)
        export_character(rig, body, path)
        if args.renders:
            render_person(rig, actions, Path(args.renders), outfit)
        report(outfit.upper(), rig, body)


main()
