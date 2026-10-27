"""Builds Gold Coast's buildings in Blender and exports each one for Godot.

The style follows the village pictures in blender/buildings/reference/:
chunky houses on raised plinths with front steps, a dark band along the
bottom of the walls, deep roof overhangs (corrugated zinc, clay tiles, or
thatch), wooden doors and shutters, barred windows, small awnings, verandas
on posts, and patches of peeling plaster. Colors come from the game's palette.

Each building also gets an invisible collision box: an object whose name ends
in "-convcolonly". When Godot imports the file, it turns that object into a
solid shape, so the player can't walk through the building. A second one,
"RoofOccluder", is a copy of the roof that the game only uses to tell when the
roof hides the player.

Everything is built in code. To change a building, change its entry in
BUILDINGS and run the script again. Never edit the mesh by hand.

Run from the repo root (kayayo/):

    /Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup \
        --python blender/scripts/build_buildings.py -- \
        --palette gold-coast/art/palette/palette.gd \
        --out gold-coast/art/models/buildings \
        --blend blender/buildings/buildings.blend \
        --renders /tmp/building_renders

Blender's axes: Z is up, and each building's front faces -Y (that's +Z in
Godot). The origin is the middle of the walls, at ground level.
"""

import argparse
import math
import random
import re
import sys
from dataclasses import dataclass
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Vector

X = Vector((1.0, 0.0, 0.0))
Y = Vector((0.0, 1.0, 0.0))
Z = Vector((0.0, 0.0, 1.0))

PLINTH_MARGIN = 0.3  # how far the plinth sticks out past the walls
BAND_HEIGHT = 0.45  # the dark band along the bottom of the walls
STEP_DEPTH = 0.3
DOOR_HEIGHT = 2.1
WINDOW_SIZE = 0.9
SHUTTER_WIDTH = 0.45


@dataclass
class Spec:
    """Everything that makes one building different from another."""

    name: str  # file name, e.g. "compound_house"
    width: float  # walls, along X (metres)
    depth: float  # walls, along Y
    wall: str  # palette color of the walls
    roof: str  # "gable", "hip", "shed", or "flat"
    roof_cover: str  # "zinc", "tile", "thatch", or "concrete"
    roof_color: str = "ZINC_LIGHT"  # palette color for tile and thatch roofs
    pitch: float = 22.0  # roof slope, in degrees
    overhang: float = 0.45
    floors: int = 1
    wall_height: float = 3.0  # per floor
    plinth_height: float = 0.3
    plinth_color: str = "CONCRETE"
    band: bool = True  # dark band along the bottom of the walls
    veranda: float = 0.0  # depth of a covered porch in front (0 = none)
    door: str = "double"  # "single", "double", "open", or "hatch"
    windows_front: int = 2  # per floor
    windows_side: int = 1  # per floor, on the +X side (the side the game camera sees)
    # Which side gets those windows: 1 = +X, or -1 = -X for a building the game
    # turns to face +X (then its -X side is the one the camera sees).
    camera_side: float = 1.0
    shutters: bool = False
    awnings: bool = False
    patches: int = 0  # patches of peeling plaster
    polytank: bool = False
    seed: int = 1  # changes where the random bits (patches, straw) go


BUILDINGS = [
    # A pink house with a corrugated zinc roof, shutters, and peeling plaster.
    Spec("compound_house", width=10.5, depth=7.5, wall="WALL_PINK", roof="gable", roof_cover="zinc",
         pitch=20, band=False, door="double", windows_front=2, windows_side=2, shutters=True,
         patches=7, seed=3),
    # A small blue shop with a red tile roof over a front veranda.
    Spec("provisions_store", width=5.0, depth=4.5, wall="WALL_BLUE", roof="gable", roof_cover="tile",
         roof_color="TILE_RED", pitch=26, plinth_height=0.35, veranda=1.6, door="single",
         windows_front=2, windows_side=1, seed=5),
    # A mud house with a pale thatched roof, a veranda on posts, and a high earth plinth.
    Spec("chop_bar", width=7.0, depth=5.5, wall="WALL_MUD", roof="hip", roof_cover="thatch",
         roof_color="THATCH_GOLD", pitch=30, overhang=0.5, wall_height=2.9, plinth_height=0.45,
         plinth_color="PLINTH_DARK", veranda=1.8, door="open", windows_front=2, windows_side=1, seed=7),
    # Three floors with shutters and awnings, a flat roof, and a polytank.
    Spec("apartment_block", width=9.0, depth=7.0, wall="WALL_OLIVE", roof="flat", roof_cover="concrete",
         overhang=0.15, floors=3, door="double", windows_front=3, windows_side=2, shutters=True,
         awnings=True, polytank=True, patches=4, seed=11),
    # A tiny kiosk with a serving hatch under a sloping zinc roof.
    Spec("mobile_money_kiosk", width=2.6, depth=2.2, wall="KENTE_GOLD", roof="shed", roof_cover="zinc",
         pitch=12, overhang=0.35, wall_height=2.5, plinth_height=0.2, door="hatch",
         windows_front=0, windows_side=0, seed=13),
    # A two-storey college with shutters, a tall veranda on posts, and a terracotta hip roof.
    Spec("training_college", width=11.0, depth=7.0, wall="WALL_SALMON", roof="hip", roof_cover="tile",
         roof_color="TILE_TERRACOTTA", pitch=24, floors=2, wall_height=2.9, veranda=1.8, door="double",
         windows_front=3, windows_side=2, shutters=True, patches=3, seed=17),
    # A long classroom block: cream walls with a dark band, a row of windows, a deep
    # veranda, and a zinc roof. The game turns it to face +X, beside its schoolyard.
    Spec("basic_school", width=12.0, depth=5.5, wall="WALL_CREAM", roof="gable", roof_cover="zinc",
         pitch=16, veranda=2.0, door="double", windows_front=4, windows_side=2, patches=3,
         camera_side=-1.0, seed=19),
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


class Materials:
    """One Blender material per palette color, made the first time it's used."""

    def __init__(self, palette):
        self.palette = palette
        self.made = {}

    def get(self, name):
        if name not in self.made:
            linear = (*(srgb_to_linear(c) for c in self.palette[name]), 1.0)
            material = bpy.data.materials.new(name.lower())
            bsdf = next(n for n in material.node_tree.nodes if n.bl_idname == "ShaderNodeBsdfPrincipled")
            bsdf.inputs["Base Color"].default_value = linear
            bsdf.inputs["Roughness"].default_value = 0.9
            material.diffuse_color = linear
            material.use_backface_culling = True
            self.made[name] = material
        return self.made[name]


# ---------------------------------------------------------------------------
# Shapes
# ---------------------------------------------------------------------------


class Part:
    """Collects closed shapes (boxes, prisms, ...) into one mesh object."""

    def __init__(self, name):
        self.name = name
        self.bm = bmesh.new()
        self.colors = []  # one material slot per color, in order of first use

    def _slot(self, color):
        if color not in self.colors:
            self.colors.append(color)
        return self.colors.index(color)

    def solid(self, points, faces, color):
        """A closed shape from corner points and faces (lists of point indexes)."""
        verts = [self.bm.verts.new(p) for p in points]
        slot = self._slot(color)
        for face in faces:
            self.bm.faces.new([verts[i] for i in face]).material_index = slot

    def box(self, center, size, color, rotation=None):
        """A box of `size` around `center`, optionally turned by `rotation` (a 3x3 Matrix)."""
        hx, hy, hz = size.x / 2, size.y / 2, size.z / 2
        corners = [Vector(c) for c in [(-hx, -hy, -hz), (hx, -hy, -hz), (hx, hy, -hz), (-hx, hy, -hz),
                                       (-hx, -hy, hz), (hx, -hy, hz), (hx, hy, hz), (-hx, hy, hz)]]
        if rotation is not None:
            corners = [rotation @ c for c in corners]
        faces = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
        self.solid([center + c for c in corners], faces, color)

    def prism(self, outline, offset, color):
        """A flat shape `outline` (points in one plane) pushed out along `offset`."""
        n = len(outline)
        points = list(outline) + [p + offset for p in outline]
        faces = [tuple(range(n)), tuple(range(n, 2 * n))]
        faces += [(i, (i + 1) % n, n + (i + 1) % n, n + i) for i in range(n)]
        self.solid(points, faces, color)

    def cylinder(self, bottom, radius, height, color, sides=14):
        ring = [Vector((math.cos(2 * math.pi * i / sides), math.sin(2 * math.pi * i / sides), 0)) * radius
                for i in range(sides)]
        self.prism([bottom + p for p in ring], Z * height, color)

    def to_object(self, materials, parent):
        bmesh.ops.recalc_face_normals(self.bm, faces=self.bm.faces[:])
        mesh = bpy.data.meshes.new(self.name)
        self.bm.to_mesh(mesh)
        self.bm.free()
        for color in self.colors:
            mesh.materials.append(materials.get(color))
        obj = bpy.data.objects.new(self.name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        obj.parent = parent
        return obj


@dataclass
class Facade:
    """One outside wall: things are placed on it by `u` (along the wall),
    `z` (height), and `out` (distance out from the wall)."""

    origin: Vector  # a point on the wall surface at u = 0, z = 0
    u: Vector  # along the wall, horizontally (X or Y)
    n: Vector  # straight out of the wall

    def point(self, u, z, out=0.0):
        return self.origin + self.u * u + self.n * out + Z * z

    def box(self, part, u, z, size_u, size_z, depth, color, out=0.0):
        """A box flat against the wall, centred at (u, z) and `depth` thick."""
        size = Vector((abs(self.u.x) * size_u + abs(self.n.x) * depth,
                       abs(self.u.y) * size_u + abs(self.n.y) * depth, size_z))
        part.box(self.point(u, z, out + depth / 2), size, color)

    def tilted_board(self, part, u, z, size_u, length, angle, color):
        """A board fixed to the wall at height z, sticking out `length` metres and
        tilted down by `angle` degrees (awnings and hatch flaps)."""
        a = math.radians(angle)
        out = self.n * math.cos(a) - Z * math.sin(a)
        up = Z * math.cos(a) + self.n * math.sin(a)
        rotation = Matrix((self.u, out, up)).transposed()
        part.box(self.point(u, z) + out * (length / 2), Vector((size_u, length, 0.05)), color, rotation)


# ---------------------------------------------------------------------------
# Building pieces
# ---------------------------------------------------------------------------


def slots(length, count, item, keep_clear=0.0):
    """Centres for up to `count` windows (each `item` wide) along a wall
    `length` long. With keep_clear, the middle stays free for the door and the
    windows are split between the two sides. Only as many as fit are returned."""
    if count <= 0:
        return []
    edge = length / 2 - 0.3 - item / 2  # furthest a centre can be from the middle
    gap = item + 0.2
    if keep_clear > 0:
        start = keep_clear + item / 2
        if edge < start:
            return []
        per_side = min(count // 2, 1 + int((edge - start) // gap))
        if per_side == 0:
            return []
        if per_side == 1:
            centres = [(start + edge) / 2]
        else:
            centres = [start + (edge - start) * i / (per_side - 1) for i in range(per_side)]
        return [sign * c for c in centres for sign in (-1, 1)]
    count = min(count, 1 + int((2 * edge) // gap)) if edge > 0 else 1
    if count == 1:
        return [0.0]
    return [-edge + 2 * edge * i / (count - 1) for i in range(count)]


def build_door(part, front, spec, openings):
    z0 = spec.plinth_height
    if spec.door == "hatch":
        # A serving hatch: a dark opening, a counter below, and a flap propped open above.
        width, height, sill = spec.width * 0.6, 0.8, z0 + 1.0
        front.box(part, 0, sill + height / 2, width + 0.12, height + 0.12, 0.04, "WOOD_DARK")
        front.box(part, 0, sill + height / 2, width, height, 0.05, "DARK_BROWN")
        front.box(part, 0, sill - 0.03, width + 0.3, 0.06, 0.32, "WOOD_LIGHT")
        front.tilted_board(part, 0, sill + height + 0.08, width + 0.2, 0.6, 20, "WOOD_DARK")
        openings.append((front, 0, sill - 0.1, width + 0.3, height + 0.3))
        return
    width = 1.4 if spec.door == "double" else 0.95
    front.box(part, 0, z0 + (DOOR_HEIGHT + 0.08) / 2, width + 0.16, DOOR_HEIGHT + 0.08, 0.04, "WOOD_DARK")
    if spec.door == "open":
        # A dark doorway, with the edge of the door showing where it swung inwards.
        front.box(part, 0, z0 + DOOR_HEIGHT / 2, width, DOOR_HEIGHT, 0.05, "DARK_BROWN")
        front.box(part, -width / 2 + 0.12, z0 + DOOR_HEIGHT / 2, 0.2, DOOR_HEIGHT - 0.05, 0.06, "WOOD_LIGHT")
    else:
        leaves = 2 if spec.door == "double" else 1
        leaf = width / leaves
        for i in range(leaves):
            u = -width / 2 + leaf * (i + 0.5)
            front.box(part, u, z0 + DOOR_HEIGHT / 2, leaf - 0.04, DOOR_HEIGHT, 0.06, "WOOD_LIGHT")
            for panel_z in (0.6, 1.5):  # two raised panels on each leaf
                front.box(part, u, z0 + panel_z, leaf - 0.22, 0.62, 0.075, "WOOD_DARK")
    openings.append((front, 0, z0, width + 0.3, DOOR_HEIGHT + 0.2))


def build_window(part, facade, u, z, spec, openings):
    half = WINDOW_SIZE / 2
    facade.box(part, u, z, WINDOW_SIZE + 0.14, WINDOW_SIZE + 0.14, 0.04, "WOOD_DARK")  # frame
    facade.box(part, u, z, WINDOW_SIZE, WINDOW_SIZE, 0.05, "DARK_BROWN")  # the dark room behind
    for i in range(4):  # bars
        facade.box(part, u - half + WINDOW_SIZE * (i + 0.5) / 4, z, 0.035, WINDOW_SIZE, 0.065, "BAR_GREEN")
    facade.box(part, u, z - half - 0.1, WINDOW_SIZE + 0.3, 0.07, 0.1, "PLINTH_LIGHT")  # sill
    if spec.shutters:  # wooden shutters swung open flat against the wall
        for side in (-1, 1):
            shutter_u = u + side * (half + 0.07 + SHUTTER_WIDTH / 2)
            facade.box(part, shutter_u, z, SHUTTER_WIDTH, WINDOW_SIZE + 0.1, 0.05, "WOOD_DARK")
            for slat_z in (-0.25, 0.0, 0.25):
                facade.box(part, shutter_u, z + slat_z, SHUTTER_WIDTH - 0.12, 0.05, 0.06, "WOOD_LIGHT")
    if spec.awnings:
        facade.tilted_board(part, u, z + half + 0.14, WINDOW_SIZE + 0.4, 0.55, 25, "WOOD_DARK")
    width = WINDOW_SIZE + (2 * SHUTTER_WIDTH + 0.2 if spec.shutters else 0.3)
    openings.append((facade, u, z - half - 0.15, width, WINDOW_SIZE + 0.45))


def build_patches(part, facades, spec, openings, top):
    """Irregular patches of brick where the plaster has fallen off."""
    for _ in range(spec.patches):
        facade, length = random.choice(facades)
        for _attempt in range(40):
            u = random.uniform(-length / 2 + 0.6, length / 2 - 0.6)
            z = random.uniform(spec.plinth_height + 0.7, top - 0.5)
            r = random.uniform(0.18, 0.38)
            clear = all(
                f is not facade or abs(u - ou) > ow / 2 + r * 1.3 or not (oz - r < z < oz + oh + r)
                for f, ou, oz, ow, oh in openings
            )
            if clear:
                break
        else:
            continue
        outline = []
        for k in range(7):
            angle = 2 * math.pi * k / 7 + random.uniform(-0.3, 0.3)
            radius = r * random.uniform(0.6, 1.15)
            outline.append(facade.point(u + math.cos(angle) * radius * 1.3, z + math.sin(angle) * radius, 0.004))
        part.prism(outline, facade.n * 0.008, "PATCH_BRICK")
        openings.append((facade, u, z - r, r * 2.6, r * 2))  # so patches don't pile up


def fringe(part, start, direction, length, outward, color):
    """The ragged bottom edge of a thatched roof: little hanging triangles."""
    count = max(1, round(length / 0.26))
    step = length / count
    for i in range(count):
        a = start + direction * (step * i)
        b = start + direction * (step * (i + 1))
        tip = (a + b) / 2 - Z * random.uniform(0.12, 0.2)
        part.prism([a, b, tip], outward * 0.06, color)


def roof_slope(part, spec, eave, up_slope, normal, width, length):
    """One sloping side of a roof, `width` across and `length` from the eave to the ridge."""
    across = up_slope.cross(normal).normalized()
    turn = Matrix((across, up_slope, normal)).transposed()
    if spec.roof_cover == "zinc":
        # Corrugated sheets: stripes of light and dark, every other one raised.
        count = max(1, round(width / 0.22))
        strip = width / count
        for i in range(count):
            center = eave + across * (-width / 2 + strip * (i + 0.5)) + up_slope * (length / 2)
            center += normal * (0.03 + (0.025 if i % 2 else 0.0))
            part.box(center, Vector((strip * 1.02, length, 0.06)), "ZINC_DARK" if i % 2 else "ZINC_LIGHT", turn)
    elif spec.roof_cover == "tile":
        # Rows of tiles, every other row raised so the rows show.
        rows = max(1, round(length / 0.3))
        row = length / rows
        for j in range(rows):
            center = eave + up_slope * (row * (j + 0.5)) + normal * (0.04 + (0.03 if j % 2 else 0.0))
            part.box(center, Vector((width, row * 1.04, 0.08)), spec.roof_color, turn)
    else:
        # Thatch: one thick layer with darker streaks of straw and a ragged edge.
        part.box(eave + up_slope * (length / 2) + normal * 0.11, Vector((width, length, 0.22)), spec.roof_color, turn)
        for _ in range(int(width / 0.5)):
            streak = random.uniform(0.4, 0.85) * length
            center = eave + across * random.uniform(-width / 2 + 0.1, width / 2 - 0.1)
            center += up_slope * (length - streak / 2) + normal * 0.225
            part.box(center, Vector((0.05, streak, 0.01)), "THATCH_BROWN", turn)
        outward = (-up_slope.copy())
        outward.z = 0.0
        fringe(part, eave - across * (width / 2), across, width, outward.normalized(), spec.roof_color)


def ridge_color(spec):
    return {"zinc": "ZINC_DARK", "tile": "TILE_TERRACOTTA", "thatch": "THATCH_BROWN"}.get(spec.roof_cover, "CONCRETE")


def fill_ends(walls, spec, top, height_at):
    """Fills the gap between the top of the side walls and a sloping roof.
    `height_at(y)` is the height of the underside of the roof above the line y."""
    hd = spec.depth / 2
    ys = sorted({-hd, hd, *[y for y in height_at.peaks if -hd < y < hd]})
    for x, inward in ((-spec.width / 2, X * 0.2), (spec.width / 2, X * -0.2)):
        outline = [Vector((x, -hd, top)), Vector((x, hd, top))]
        outline += [Vector((x, y, height_at(y))) for y in reversed(ys)]
        walls.prism(outline, inward, spec.wall)


class RoofHeight:
    """The height of the underside of a gable or shed roof above a line y."""

    def __init__(self, top, slope, front, back, peak=None):
        self.top, self.slope, self.front, self.back, self.peak = top, slope, front, back, peak
        self.peaks = [peak] if peak is not None else []

    def __call__(self, y):
        if self.peak is None:  # shed: highest at the front
            return self.top + (self.back - y) * self.slope
        if y <= self.peak:
            return self.top + (y - self.front) * self.slope
        return self.top + (self.back - y) * self.slope


def build_roof(roof, walls, spec, top):
    hw, hd, ov = spec.width / 2, spec.depth / 2, spec.overhang
    x0, x1 = -hw - ov, hw + ov
    y0, y1 = -hd - spec.veranda - ov, hd + ov  # front edge, back edge
    a = math.radians(spec.pitch)
    if spec.roof == "gable":
        # Two slopes meeting at a ridge that runs along the width.
        peak = (y0 + y1) / 2
        run = (y1 - y0) / 2
        rise = run * math.tan(a)
        for eave_y, sign in ((y0, 1), (y1, -1)):
            up_slope = Vector((0, sign * math.cos(a), math.sin(a)))
            normal = Vector((0, -sign * math.sin(a), math.cos(a)))
            roof_slope(roof, spec, Vector((0, eave_y, top)), up_slope, normal, x1 - x0, run / math.cos(a))
        roof.box(Vector((0, peak, top + rise + 0.05)), Vector((x1 - x0 + 0.04, 0.3, 0.08)), ridge_color(spec))
        fill_ends(walls, spec, top, RoofHeight(top, math.tan(a), y0, y1, peak))
    elif spec.roof == "shed":
        # One slope, high at the front and low at the back.
        run = y1 - y0
        up_slope = Vector((0, -math.cos(a), math.sin(a)))
        normal = Vector((0, math.sin(a), math.cos(a)))
        roof_slope(roof, spec, Vector((0, y1, top)), up_slope, normal, x1 - x0, run / math.cos(a))
        height = RoofHeight(top, math.tan(a), y0, y1)
        fill_ends(walls, spec, top, height)
        for y, z in ((-hd + 0.1, height(-hd)), (hd - 0.1, height(hd))):  # strips along the front and back
            walls.box(Vector((0, y, (top + z) / 2)), Vector((spec.width, 0.2, z - top)), spec.wall)
    elif spec.roof == "hip":
        hip_roof(roof, spec, top, x0, x1, y0, y1, a)
    else:
        flat_roof(roof, spec, top, x0, x1, y0, y1)


def hip_roof(roof, spec, top, x0, x1, y0, y1, a):
    """Four slopes: two long sides and two short ends, over a thick eave."""
    sx, sy = (x1 - x0) / 2, (y1 - y0) / 2
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    half = min(sx, sy)
    rise = half * math.tan(a)
    fascia = 0.12
    t = [Vector((x0, y0, top)), Vector((x1, y0, top)), Vector((x1, y1, top)), Vector((x0, y1, top))]
    b = [p - Z * fascia for p in t]
    if sx >= sy:  # ridge along X
        r0, r1 = Vector((cx - (sx - half), cy, top + rise)), Vector((cx + (sx - half), cy, top + rise))
        slopes = [(4, 5, 9, 8), (5, 6, 9), (6, 7, 8, 9), (7, 4, 8)]
    else:  # ridge along Y
        r0, r1 = Vector((cx, cy - (sy - half), top + rise)), Vector((cx, cy + (sy - half), top + rise))
        slopes = [(4, 5, 8), (5, 6, 9, 8), (6, 7, 9), (7, 4, 8, 9)]
    faces = [(0, 1, 2, 3), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)] + slopes
    roof.solid(b + t + [r0, r1], faces, spec.roof_color)
    if spec.roof_cover == "thatch":
        edges = [(b[0], X, x1 - x0, -Y), (b[1], Y, y1 - y0, X), (b[2], -X, x1 - x0, Y), (b[3], -Y, y1 - y0, -X)]
        for start, direction, length, outward in edges:
            fringe(roof, start, direction, length, outward, spec.roof_color)


def flat_roof(roof, spec, top, x0, x1, y0, y1):
    """A concrete slab with a low wall (parapet) around the edge, and maybe a water tank."""
    slab, wall_height, wall = 0.2, 0.6, 0.15
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    roof.box(Vector((cx, cy, top + slab / 2)), Vector((x1 - x0, y1 - y0, slab)), "CONCRETE")
    z = top + slab + wall_height / 2
    for center, size in [
        (Vector((cx, y0 + wall / 2, z)), Vector((x1 - x0, wall, wall_height))),
        (Vector((cx, y1 - wall / 2, z)), Vector((x1 - x0, wall, wall_height))),
        (Vector((x0 + wall / 2, cy, z)), Vector((wall, y1 - y0, wall_height))),
        (Vector((x1 - wall / 2, cy, z)), Vector((wall, y1 - y0, wall_height))),
    ]:
        roof.box(center, size, spec.wall)
    if spec.polytank:  # a black polytank near the back corner, with a lid
        tank = Vector((x1 - 1.4, y1 - 1.4, top + slab))
        roof.cylinder(tank, 0.6, 1.3, "DARK_BROWN")
        roof.cylinder(tank + Z * 1.3, 0.25, 0.08, "DARK_BROWN", sides=10)


def build(spec, materials):
    random.seed(spec.seed)
    root = bpy.data.objects.new(spec.name, None)  # holds all of this building's parts
    bpy.context.scene.collection.objects.link(root)

    hw, hd = spec.width / 2, spec.depth / 2
    top = spec.plinth_height + spec.floors * spec.wall_height  # where the walls end
    base, walls, details, roof = Part("Base"), Part("Walls"), Part("Details"), Part("Roof")

    # The base: a raised plinth (which is also the veranda floor) and steps up to the door.
    front_edge = -hd - PLINTH_MARGIN - spec.veranda
    back_edge = hd + PLINTH_MARGIN
    side_edge = hw + PLINTH_MARGIN
    base.box(Vector((0, (front_edge + back_edge) / 2, spec.plinth_height / 2)),
             Vector((2 * side_edge, back_edge - front_edge, spec.plinth_height)), spec.plinth_color)
    steps = 0 if spec.door == "hatch" else max(1, round(spec.plinth_height / 0.16))
    for k in range(steps):
        height = spec.plinth_height * (steps - k) / (steps + 1)
        base.box(Vector((0, front_edge - STEP_DEPTH * (k + 0.5), height / 2)),
                 Vector((1.7 if spec.door == "double" else 1.3, STEP_DEPTH, height)), spec.plinth_color)
    base_front = front_edge - STEP_DEPTH * steps

    # Walls, the dark band along their bottom, and ledges between floors.
    wall_total = spec.floors * spec.wall_height
    walls.box(Vector((0, 0, spec.plinth_height + wall_total / 2)), Vector((spec.width, spec.depth, wall_total)), spec.wall)
    if spec.band:
        walls.box(Vector((0, 0, spec.plinth_height + BAND_HEIGHT / 2)),
                  Vector((spec.width + 0.03, spec.depth + 0.03, BAND_HEIGHT)), "WALL_BAND")
    for floor in range(1, spec.floors):
        walls.box(Vector((0, 0, spec.plinth_height + floor * spec.wall_height)),
                  Vector((spec.width + 0.12, spec.depth + 0.12, 0.14)), "PLINTH_LIGHT")

    # Doors and windows on the front, and windows on the side the camera sees.
    front = Facade(Vector((0, -hd, 0)), X, -Y)
    side = Facade(Vector((spec.camera_side * hw, 0, 0)), Y * spec.camera_side, X * spec.camera_side)
    openings = []
    build_door(details, front, spec, openings)
    door_clear = 0.0 if spec.door == "hatch" else (0.7 if spec.door == "double" else 0.475) + 0.45
    item = WINDOW_SIZE + (2 * SHUTTER_WIDTH + 0.14 if spec.shutters else 0.0)
    for floor in range(spec.floors):
        z = spec.plinth_height + floor * spec.wall_height + 1.45
        clear = door_clear if floor == 0 else 0.0
        for u in slots(spec.width, spec.windows_front, item, clear):
            build_window(details, front, u, z, spec, openings)
        for u in slots(spec.depth, spec.windows_side, item):
            build_window(details, side, u, z, spec, openings)
    build_patches(walls, [(front, spec.width), (side, spec.depth)], spec, openings, top)

    # A veranda: posts along the front of the plinth holding up the roof.
    if spec.veranda > 0:
        post_y = front_edge + 0.15
        count = 2 if spec.width < 6 else 3
        for i in range(count):
            x = -hw + 0.12 + (spec.width - 0.24) * i / (count - 1)
            details.box(Vector((x, post_y, (spec.plinth_height + top) / 2)),
                        Vector((0.14, 0.14, top - spec.plinth_height)), "WOOD_LIGHT")
        details.box(Vector((0, post_y, top - 0.08)), Vector((spec.width, 0.16, 0.16)), "WOOD_DARK")

    build_roof(roof, walls, spec, top)

    # The invisible solid box Godot turns into collision: the whole base, up to the roof.
    collision = Part("Collision-convcolonly")
    collision.box(Vector((0, (base_front + back_edge) / 2, top / 2)),
                  Vector((2 * side_edge, back_edge - base_front, top)), spec.wall)

    for part in (base, walls, details, roof):
        part.to_object(materials, root)
    collider = collision.to_object(materials, root)
    collider.display_type = "WIRE"
    collider.hide_render = True
    # A copy of the roof, which Godot turns into an invisible solid shape that only
    # the "see-through" check uses: it tells when the roof hides the player.
    roof_object = next(child for child in root.children if child.name == "Roof")
    occluder = bpy.data.objects.new("RoofOccluder-convcolonly", roof_object.data.copy())
    bpy.context.scene.collection.objects.link(occluder)
    occluder.parent = root
    occluder.display_type = "WIRE"
    occluder.hide_render = True
    return root, {"base_front": base_front, "base_back": back_edge, "half_width": side_edge, "top": top}


# ---------------------------------------------------------------------------
# Preview renders
# ---------------------------------------------------------------------------


def render_previews(roots, out_dir):
    out_dir.mkdir(parents=True, exist_ok=True)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x, scene.render.resolution_y = 640, 520
    scene.view_settings.view_transform = "Standard"
    world = bpy.data.worlds.new("World")
    scene.world = world
    background = next(n for n in world.node_tree.nodes if n.bl_idname == "ShaderNodeBackground")
    background.inputs["Color"].default_value = (0.62, 0.66, 0.7, 1.0)
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN"))
    sun.data.energy = 3.2
    # Roughly the game's sun: from the front left, about 45 degrees up.
    sun.rotation_euler = Vector((0.354, 0.612, -0.707)).to_track_quat("-Z", "Y").to_euler()
    scene.collection.objects.link(sun)
    camera = bpy.data.objects.new("Camera", bpy.data.cameras.new("Camera"))
    camera.data.type = "ORTHO"
    scene.collection.objects.link(camera)
    scene.camera = camera
    for root, size, camera_side in roots:
        for other, _, _ in roots:
            for child in other.children:
                child.hide_render = other is not root or "Collision" in child.name
        target = root.location + Z * (size.z * 0.4)
        camera.data.ortho_scale = max(size.x, size.y, size.z) * 1.45 + 1.0
        # The game camera's angle: from the front right (or the front left, for a
        # building the game turns to face +X), looking down 30 degrees.
        camera.location = target + Vector((camera_side, -1.0, 0.82)).normalized() * 40.0
        camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
        scene.render.filepath = str(out_dir / f"{root.name}.png")
        bpy.ops.render.render(write_still=True)


# ---------------------------------------------------------------------------


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--palette", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--blend")
    parser.add_argument("--renders")
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1 :])

    bpy.ops.wm.read_factory_settings(use_empty=True)
    materials = Materials(read_palette(args.palette))
    out = Path(args.out).resolve()
    out.mkdir(parents=True, exist_ok=True)

    scene = bpy.context.scene
    roots, x = [], 0.0
    for spec in BUILDINGS:
        root, info = build(spec, materials)
        for obj in scene.objects:
            obj.select_set(obj is root or obj.parent is root)
        bpy.context.view_layer.objects.active = root
        bpy.ops.export_scene.gltf(
            filepath=str(out / f"{spec.name}.glb"),
            export_format="GLB",
            use_selection=True,
            export_apply=True,
            export_animations=False,
            export_materials="EXPORT",
        )
        triangles = sum(len(p.vertices) - 2 for obj in root.children if obj.type == "MESH"
                        and not obj.name.startswith("Collision") for p in obj.data.polygons)
        # Blender needs every object name to be unique, so once this building is
        # exported, rename its parts. Then the next building can use plain names too.
        for child in root.children:
            child.name = f"{spec.name}.{child.name}"
        print(f"BUILDING {spec.name}: base {2 * info['half_width']:.2f} m wide, "
              f"front edge {info['base_front']:+.2f}, back edge {info['base_back']:+.2f} (Blender y), "
              f"walls end at {info['top']:.2f} m, {triangles} triangles")
        # Line the buildings up side by side in the .blend file, for looking at.
        size = Vector((2 * info["half_width"], info["base_back"] - info["base_front"], info["top"] + 3.0))
        root.location.x = x + size.x / 2
        x += size.x + 3.0
        roots.append((root, size, spec.camera_side))

    if args.renders:
        render_previews(roots, Path(args.renders))
    if args.blend:
        Path(args.blend).parent.mkdir(parents=True, exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=str(Path(args.blend).resolve()))


main()
