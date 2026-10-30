"""Builds Gold Coast's vehicles in Blender and exports each one for Godot.

The style follows the pictures in blender/vehicles/: flat colors, friendly
rounded shapes, dark windows, and chunky wheels.
- The trotro: a classic cream minibus with a blue stripe along it, a raised
  roof behind the cab, four windows down each side (with the seats showing),
  and a sliding door on its right.
- The Uber: a silver Toyota Yaris, a small five-door hatchback.

Each body is built from its side profile (its outline seen from the side),
pushed out to its width, cut into bands of color, and rounded off with a
bevel. Windows, lights, bumpers, and the rest go on top as thin plates. The
wheels are objects of their own, centred on their axles, so the game can turn
them, and so is the trotro's sliding door, so it can slide. Empty objects mark
where the game writes on them: the trotro's sayings and where it's going, and
the Uber's stickers.

Everything is built in code. To change a vehicle, change its numbers here and
run the script again. Never edit the mesh by hand.

Run from the repo root (kayayo/):

    /Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup \\
        --python blender/scripts/build_vehicles.py -- \\
        --palette gold-coast/art/palette/palette.gd \\
        --out gold-coast/art/models/vehicles \\
        --blend blender/vehicles/vehicles.blend \\
        --renders /tmp/vehicle_renders

Blender's axes: Z is up, and each vehicle's front faces +Y (that's -Z in
Godot, the way the game's vehicles drive), with its right side on +X. The
origin is the middle of the vehicle, on the ground.
"""

import argparse
import math
import re
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector

X = Vector((1.0, 0.0, 0.0))
Y = Vector((0.0, 1.0, 0.0))
Z = Vector((0.0, 0.0, 1.0))

BEVEL = 0.045  # how much the body's edges are rounded off, in metres
PROUD = 0.006  # how far plates (windows, lights) stand off the body
PLATE = 0.008  # how thick they are


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
    """One Blender material per palette color, made the first time it's used.
    Glass and paint are a little shiny; everything else is matt."""

    ROUGHNESS = {"CAR_GLASS": 0.3, "CAR_SILVER": 0.45, "TROTRO_CREAM": 0.65, "TROTRO_BLUE": 0.6}

    def __init__(self, palette):
        self.palette = palette
        self.made = {}

    def get(self, name):
        if name not in self.made:
            linear = (*(srgb_to_linear(c) for c in self.palette[name]), 1.0)
            material = bpy.data.materials.new(name.lower())
            bsdf = next(n for n in material.node_tree.nodes if n.bl_idname == "ShaderNodeBsdfPrincipled")
            bsdf.inputs["Base Color"].default_value = linear
            bsdf.inputs["Roughness"].default_value = self.ROUGHNESS.get(name, 0.9)
            material.diffuse_color = linear
            material.use_backface_culling = True
            self.made[name] = material
        return self.made[name]


# ---------------------------------------------------------------------------
# Shapes
# ---------------------------------------------------------------------------


class Part:
    """Collects closed shapes into one mesh object, with one material slot per color."""

    def __init__(self, name):
        self.name = name
        self.bm = bmesh.new()
        self.colors = []  # in order of first use

    def slot(self, color):
        if color not in self.colors:
            self.colors.append(color)
        return self.colors.index(color)

    def solid(self, points, faces, color):
        """A closed shape from corner points and faces (lists of point indexes)."""
        verts = [self.bm.verts.new(p) for p in points]
        slot = self.slot(color)
        for face in faces:
            self.bm.faces.new([verts[i] for i in face]).material_index = slot

    def box(self, low, high, color):
        """A box between two opposite corners."""
        (x0, y0, z0), (x1, y1, z1) = low, high
        points = [Vector(p) for p in [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0),
                                      (x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)]]
        faces = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
        self.solid(points, faces, color)

    def plate(self, corners, normal, color, lift=PROUD, depth=PLATE):
        """A thin plate on a surface (a window, a light, a sticker): `corners`
        are its four corners on the surface, in order around it, and `normal`
        points out of the surface. It stands `lift` off it, `depth` thick."""
        back = [c + normal * lift for c in corners]
        front = [c + normal * (lift + depth) for c in corners]
        faces = [(0, 1, 2, 3), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
        self.solid(back + front, faces, color)

    def cylinder_x(self, center, radius, width, color, sides=16):
        """A cylinder lying along X (like a wheel), with `center` in its middle."""
        ring = [center + Vector((-width / 2, radius * math.cos(2 * math.pi * i / sides),
                                 radius * math.sin(2 * math.pi * i / sides))) for i in range(sides)]
        n = sides
        points = ring + [p + X * width for p in ring]
        faces = [tuple(range(n)), tuple(range(n, 2 * n))]
        faces += [(i, (i + 1) % n, n + (i + 1) % n, n + i) for i in range(n)]
        self.solid(points, faces, color)

    def to_object(self, materials, parent, location=(0.0, 0.0, 0.0)):
        bmesh.ops.recalc_face_normals(self.bm, faces=self.bm.faces[:])
        mesh = bpy.data.meshes.new(self.name)
        self.bm.to_mesh(mesh)
        self.bm.free()
        for color in self.colors:
            mesh.materials.append(materials.get(color))
        obj = bpy.data.objects.new(self.name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        obj.parent = parent
        obj.location = location
        return obj


class Shell:
    """A vehicle's body: its side profile pushed out to its width, in bands of
    color by height, with the sides leaning in toward the roof (`taper`). It
    knows where its surface is, so plates can be put on it."""

    def __init__(self, profile, width, bands, taper):
        self.profile = profile  # (y, z) points going round the outline seen from the side
        self.half = width / 2
        self.bands = bands  # (height, color), lowest first: each color reaches up to its height
        self.taper = taper  # (from, top, amount): narrower by `amount` at `top`

    def side_x(self, z, side):
        """Where its side is at height `z`, on its right (`side` 1) or left (-1)."""
        start, top, amount = self.taper
        return side * self.half * (1.0 - amount * max(0.0, (z - start) / (top - start)))

    def build(self, part):
        bm = part.bm
        left = [bm.verts.new((-self.half, y, z)) for y, z in self.profile]
        right = [bm.verts.new((self.half, y, z)) for y, z in self.profile]
        n = len(self.profile)
        bm.faces.new(left)
        bm.faces.new(list(reversed(right)))
        for i in range(n):
            j = (i + 1) % n
            bm.faces.new((left[i], left[j], right[j], right[i]))
        # Cut it into bands, and color each face by the height of its middle.
        for height, _ in self.bands[:-1]:
            geom = bm.verts[:] + bm.edges[:] + bm.faces[:]
            bmesh.ops.bisect_plane(bm, geom=geom, plane_co=(0.0, 0.0, height), plane_no=(0.0, 0.0, 1.0))
        slots = [part.slot(color) for _, color in self.bands]
        for face in bm.faces:
            z = face.calc_center_median().z
            face.material_index = next(slot for (height, _), slot in zip(self.bands, slots)
                                       if height is None or z < height)
        for vert in bm.verts:
            vert.co.x = self.side_x(vert.co.z, 1.0 if vert.co.x > 0 else -1.0)

    def side_plate(self, part, side, points, color, lift=PROUD, depth=PLATE):
        """A plate on its right (`side` 1) or left (-1) side, at four (y, z) points."""
        corners = [Vector((self.side_x(z, side), y, z)) for y, z in points]
        part.plate(corners, X * side, color, lift, depth)


def arch(center_y, center_z, radius, bottom, steps=7):
    """A wheel arch in a side profile: points from the front of the arch, up
    over the wheel, and down to its back, starting and ending at `bottom`."""
    start = math.asin(max(-1.0, min(1.0, (bottom - center_z) / radius)))
    angles = [start + (math.pi - 2 * start) * i / steps for i in range(steps + 1)]
    return [(center_y + radius * math.cos(a), center_z + radius * math.sin(a)) for a in angles]


def along(a, b, t):
    """The (y, z) point `t` of the way from `a` to `b`."""
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)


def slope_normal(a, b):
    """The outward normal of a sloping part of a profile (a windscreen) that
    goes from `a` (its bottom, at the front) up to `b`."""
    direction = Vector((0.0, b[0] - a[0], b[1] - a[1])).normalized()
    return Vector((0.0, direction.z, -direction.y))


def slope_plate(part, a, b, x0, x1, t0, t1, color, lift=PROUD):
    """A plate on a slope from `a` to `b` (as in slope_normal), from `x0` to
    `x1` across, and from `t0` to `t1` of the way up."""
    (ya, za), (yb, zb) = along(a, b, t0), along(a, b, t1)
    corners = [Vector((x0, ya, za)), Vector((x1, ya, za)), Vector((x1, yb, zb)), Vector((x0, yb, zb))]
    part.plate(corners, slope_normal(a, b), color, lift)


def end_plate(part, y, normal_y, x0, x1, z0, z1, color, lift=PROUD, depth=PLATE):
    """A plate on the front (`normal_y` 1) or the back (-1), at `y`."""
    corners = [Vector((x0, y, z0)), Vector((x1, y, z0)), Vector((x1, y, z1)), Vector((x0, y, z1))]
    part.plate(corners, Y * normal_y, color, lift, depth)


def build_wheel(materials, root, name, location, radius, width, side):
    """A wheel: a tyre, a silver hubcap, its middle, and four wheel nuts. Its
    origin is its axle, so the game can turn it."""
    wheel = Part(name)
    wheel.cylinder_x(Vector((0.0, 0.0, 0.0)), radius, width, "TYRE_BLACK", sides=18)
    outer = side * width / 2
    wheel.cylinder_x(Vector((outer, 0.0, 0.0)), radius * 0.56, 0.02, "ALUMINIUM")
    face = outer + side * 0.012
    wheel.cylinder_x(Vector((face, 0.0, 0.0)), radius * 0.2, 0.02, "CAR_TRIM", sides=10)
    for i in range(4):
        a = math.pi / 4 + i * math.pi / 2
        nut = Vector((face, radius * 0.38 * math.cos(a), radius * 0.38 * math.sin(a)))
        wheel.box(nut - Vector((0.01, 0.022, 0.022)), nut + Vector((0.01, 0.022, 0.022)), "CAR_TRIM")
    return wheel.to_object(materials, root, location)


def marker(name, root, location, normal):
    """An empty object where the game writes something: its -Y points out of
    the surface (that's +Z in Godot, the way Godot's writing faces)."""
    empty = bpy.data.objects.new(name, None)
    empty.empty_display_size = 0.2
    bpy.context.scene.collection.objects.link(empty)
    empty.parent = root
    empty.location = location
    empty.rotation_euler = normal.to_track_quat("-Y", "Z").to_euler()
    return empty


def new_root(name):
    root = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(root)
    return root


def round_off(obj):
    """Rounds off the body's edges (not the flat seams between its colors)."""
    bevel = obj.modifiers.new("Bevel", "BEVEL")
    bevel.width = BEVEL
    bevel.segments = 2
    bevel.limit_method = "ANGLE"
    bevel.angle_limit = math.radians(35.0)


# ---------------------------------------------------------------------------
# The trotro
# ---------------------------------------------------------------------------

TROTRO_LENGTH = 4.9
TROTRO_WIDTH = 1.95
TROTRO_WHEEL = (0.34, 0.24)  # radius and width
TROTRO_WHEELS_Y = (1.6, -1.55)  # front and back axles
TROTRO_STRIPE = (0.92, 1.16)  # the blue stripe, from and to (heights)
TROTRO_WINDOWS = (1.32, 2.12)  # the side windows, from and to
# The passengers' windows along each side, front to back. On the right, the
# first is in the sliding door.
TROTRO_PASSENGER_WINDOWS = [(0.20, 0.98), (-0.62, 0.08), (-1.44, -0.74), (-2.30, -1.56)]
TROTRO_DOOR = (0.60, 0.43)  # the sliding door: where its middle is (y), and half its width


def build_trotro(materials):
    root = new_root("Trotro")
    half_l = TROTRO_LENGTH / 2
    bottom = 0.42
    windscreen = ((2.30, 1.15), (1.92, 2.05))  # from its bottom to its top
    profile = [
        (-half_l, bottom), (-half_l, 2.20), (-2.43, 2.30), (-2.37, 2.36), (-2.28, 2.38),  # the back, into the roof
        (0.95, 2.38), (1.12, 2.36), (1.27, 2.30), (1.42, 2.20),  # the raised roof rounds down to the cab
        (1.62, 2.10), windscreen[1], windscreen[0],  # the cab's roof, and down the windscreen
        (2.41, 1.08), (half_l, 0.98), (half_l, bottom),  # the short nose, and down the front
    ] + arch(TROTRO_WHEELS_Y[0], 0.36, 0.42, bottom) + arch(TROTRO_WHEELS_Y[1], 0.36, 0.42, bottom)
    stripe_low, stripe_high = TROTRO_STRIPE
    shell = Shell(profile, TROTRO_WIDTH, [(stripe_low, "KENKEY_BEIGE"), (stripe_high, "TROTRO_BLUE"),
                                           (None, "TROTRO_CREAM")], taper=(1.30, 2.38, 0.04))
    body = Part("Body")
    shell.build(body)
    round_off(body.to_object(materials, root))

    details = Part("Details")
    low, high = TROTRO_WINDOWS
    door_y, door_half = TROTRO_DOOR
    for side in (-1, 1):
        # The cab's window, its front edge following the windscreen.
        shell.side_plate(details, side, [(1.10, low), (2.12, low), (1.86, 2.00), (1.10, 2.00)], "CAR_GLASS")
        # The passengers' windows, each with a seat's headrest showing.
        for y0, y1 in TROTRO_PASSENGER_WINDOWS[1 if side == 1 else 0 :]:
            shell.side_plate(details, side, [(y0, low), (y1, low), (y1, high), (y0, high)], "CAR_GLASS")
            middle = (y0 + y1) / 2
            shell.side_plate(details, side, [(middle - 0.12, 1.50), (middle + 0.12, 1.50), (middle + 0.12, 1.74),
                                             (middle - 0.12, 1.74)], "TYRE_BLACK", lift=PROUD + PLATE)
        # A rubbing strip along the side (on the right, it stops at the door),
        # the front door's handle, and a red reflector at the back.
        strip_end = door_y - door_half - 0.05 if side == 1 else 1.0
        shell.side_plate(details, side, [(-2.30, 0.74), (strip_end, 0.74), (strip_end, 0.77), (-2.30, 0.77)],
                         "CAR_TRIM")
        shell.side_plate(details, side, [(1.16, 1.18), (1.30, 1.18), (1.30, 1.23), (1.16, 1.23)], "CAR_TRIM")
        shell.side_plate(details, side, [(-2.40, 0.62), (-2.33, 0.62), (-2.33, 0.86), (-2.40, 0.86)], "TILE_RED")
    # The doorway behind the sliding door: dark inside, when it slides open.
    shell.side_plate(details, 1, [(door_y - door_half + 0.03, 0.46), (door_y + door_half - 0.03, 0.46),
                                  (door_y + door_half - 0.03, 2.15), (door_y - door_half + 0.03, 2.15)], "TYRE_BLACK")
    # The windscreen in two panes, with the card that says where it's going.
    slope_plate(details, *windscreen, -0.84, 0.84, 0.06, 0.95, "CAR_GLASS")
    slope_plate(details, *windscreen, -0.025, 0.025, 0.06, 0.95, "TROTRO_CREAM", lift=PROUD + PLATE)
    slope_plate(details, *windscreen, 0.12, 0.72, 0.10, 0.27, "PAPER", lift=PROUD + PLATE)
    card_y, card_z = along(*windscreen, 0.185)
    normal = slope_normal(*windscreen)
    marker("DestinationCard", root, Vector((0.42, card_y, card_z)) + normal * (PROUD + 2 * PLATE + 0.002), normal)
    # The front: a grille with chrome bars between square headlights, the
    # indicators, and a bumper with a yellow number plate.
    end_plate(details, half_l, 1, -0.42, 0.42, 0.55, 0.86, "CAR_TRIM")
    for z in (0.62, 0.70, 0.78):
        end_plate(details, half_l, 1, -0.36, 0.36, z, z + 0.025, "ALUMINIUM", lift=PROUD + PLATE)
    for side in (-1, 1):
        x0, x1 = sorted((side * 0.50, side * 0.90))
        end_plate(details, half_l, 1, x0, x1, 0.55, 0.86, "CAR_TRIM")
        x0, x1 = sorted((side * 0.56, side * 0.78))
        end_plate(details, half_l, 1, x0, x1, 0.61, 0.80, "PAPER", lift=PROUD + PLATE)
        x0, x1 = sorted((side * 0.80, side * 0.86))
        end_plate(details, half_l, 1, x0, x1, 0.60, 0.82, "KELEWELE_ORANGE", lift=PROUD + PLATE)
    details.box((-1.0, half_l - 0.07, 0.33), (1.0, half_l + 0.11, 0.53), "CAR_TRIM")
    end_plate(details, half_l + 0.11, 1, -0.26, 0.26, 0.37, 0.49, "KENTE_GOLD")
    # The back: a window, the lights, a number plate, and a bumper.
    end_plate(details, -half_l, -1, -0.80, 0.80, 1.40, 2.14, "CAR_GLASS")
    for side in (-1, 1):
        x0, x1 = sorted((side * 0.72, side * 0.92))
        end_plate(details, -half_l, -1, x0, x1, 0.60, 0.88, "TILE_RED")
    end_plate(details, -half_l, -1, -0.24, 0.24, 0.60, 0.72, "KENTE_GOLD")
    details.box((-1.0, -half_l - 0.11, 0.33), (1.0, -half_l + 0.07, 0.53), "CAR_TRIM")
    # Mirrors on stalks at the front corners.
    for side in (-1, 1):
        x0, x1 = sorted((side * 1.05, side * 1.19))
        details.box((x0, 1.93, 1.40), (x1, 1.99, 1.72), "CAR_TRIM")
        x0, x1 = sorted((side * 0.95, side * 1.06))
        details.box((x0, 1.95, 1.43), (x1, 1.98, 1.47), "CAR_TRIM")
    details.to_object(materials, root)

    # The sliding door, on its own so the game can slide it back along the side.
    # Its origin is its middle, on the ground.
    door = Part("Door")
    for z0, z1, color in ((0.45, stripe_low, "KENKEY_BEIGE"), (stripe_low, stripe_high, "TROTRO_BLUE"),
                          (stripe_high, 2.16, "TROTRO_CREAM")):
        door.box((0.0, -door_half, z0), (0.03, door_half, z1), color)
    door.plate([Vector((0.03, y, z)) for y, z in [(-0.36, low), (0.36, low), (0.36, 2.08), (-0.36, 2.08)]],
               X, "CAR_GLASS")
    door.plate([Vector((0.03, y, z)) for y, z in [(-0.12, 1.50), (0.12, 1.50), (0.12, 1.74), (-0.12, 1.74)]],
               X, "TYRE_BLACK", lift=PROUD + PLATE)
    door.plate([Vector((0.03, y, z)) for y, z in [(0.30, 1.06), (0.35, 1.06), (0.35, 1.22), (0.30, 1.22)]],
               X, "CAR_TRIM", depth=0.02)
    door.to_object(materials, root, (TROTRO_WIDTH / 2 + 0.012, door_y, 0.0))

    radius, width = TROTRO_WHEEL
    for axle, y in (("Front", TROTRO_WHEELS_Y[0]), ("Back", TROTRO_WHEELS_Y[1])):
        for label, side in (("Left", -1), ("Right", 1)):
            build_wheel(materials, root, f"Wheel{axle}{label}",
                        (side * (TROTRO_WIDTH / 2 - width / 2), y, radius), radius, width, side)

    # Where its sayings go: one along the left side (the side the game camera
    # sees), one across the back under the window.
    marker("SideSlogan", root, Vector((-TROTRO_WIDTH / 2 - 0.012, -0.55, 0.66)), -X)
    marker("BackSlogan", root, Vector((0.0, -half_l - 0.012, 1.28)), -Y)
    return root, {"length": TROTRO_LENGTH, "width": TROTRO_WIDTH, "height": 2.38}


# ---------------------------------------------------------------------------
# The Uber: a Toyota Yaris
# ---------------------------------------------------------------------------

CAR_LENGTH = 3.9
CAR_WIDTH = 1.7
CAR_WHEEL = (0.30, 0.20)
CAR_WHEELS_Y = (1.25, -1.25)
CAR_BELT = 0.94  # the bottom of the side windows, where the sides start to lean in
CAR_ROOF = 1.56
CAR_WINDOWS = (0.98, 1.47)  # the side windows, from and to


def build_uber(materials):
    root = new_root("UberCar")
    half_l = CAR_LENGTH / 2
    bottom = 0.30
    # A Yaris is short at both ends: a short bonnet, a long sloping windscreen,
    # and an upright hatch with a little spoiler on top.
    windscreen = ((1.22, 0.94), (0.24, 1.53))
    hatch = ((-1.87, 1.02), (-1.58, 1.50))  # the back window's slope, from its bottom to its top
    profile = [
        (-half_l, bottom), (-half_l, 0.86), (-1.92, 0.96), hatch[0], hatch[1],  # the back, up the hatch
        (-1.60, CAR_ROOF), (-1.48, CAR_ROOF), (0.10, CAR_ROOF), windscreen[1], windscreen[0],  # the spoiler and roof
        (1.32, 0.91), (1.86, 0.78), (1.94, 0.72), (1.97, 0.60), (1.97, bottom),  # the bonnet, and down the front
    ] + arch(CAR_WHEELS_Y[0], 0.30, 0.36, bottom) + arch(CAR_WHEELS_Y[1], 0.30, 0.36, bottom)
    shell = Shell(profile, CAR_WIDTH, [(None, "CAR_SILVER")], taper=(CAR_BELT, CAR_ROOF, 0.12))
    body = Part("Body")
    shell.build(body)
    round_off(body.to_object(materials, root))

    details = Part("Details")
    for side in (-1, 1):
        # The windows: the front door's (its front edge following the
        # windscreen), the back door's, and a small one behind it.
        low, high = CAR_WINDOWS
        shell.side_plate(details, side, [(0.0, low), (1.06, low), (0.44, high), (0.0, high)], "CAR_GLASS")
        shell.side_plate(details, side, [(-0.98, low), (-0.10, low), (-0.10, high), (-0.98, high)], "CAR_GLASS")
        shell.side_plate(details, side, [(-1.68, low), (-1.08, low), (-1.08, high), (-1.48, high)], "CAR_GLASS")
        # The doors' edges and handles, and a darker strip along the bottom.
        for y in (0.86, -0.05, -1.00):
            shell.side_plate(details, side, [(y - 0.006, 0.44), (y + 0.006, 0.44), (y + 0.006, 0.93),
                                             (y - 0.006, 0.93)], "ZINC_DARK")
        for y in (0.10, -0.84):
            shell.side_plate(details, side, [(y, 0.82), (y + 0.12, 0.82), (y + 0.12, 0.86), (y, 0.86)], "CAR_TRIM")
        shell.side_plate(details, side, [(-0.89, 0.31), (0.89, 0.31), (0.89, 0.42), (-0.89, 0.42)], "ZINC_DARK")
        # A mirror on the front door.
        x0, x1 = sorted((side * 0.84, side * 0.98))
        details.box((x0, 0.98, 0.94), (x1, 1.08, 1.06), "CAR_SILVER")
    # The windscreen and the back window, each with a little black Uber sticker
    # in its corner on the passengers' side.
    slope_plate(details, *windscreen, -0.66, 0.66, 0.07, 0.93, "CAR_GLASS")
    slope_plate(details, *windscreen, 0.30, 0.58, 0.10, 0.24, "CAR_TRIM", lift=PROUD + PLATE)
    sticker_y, sticker_z = along(*windscreen, 0.17)
    normal = slope_normal(*windscreen)
    marker("StickerFront", root, Vector((0.44, sticker_y, sticker_z)) + normal * (PROUD + 2 * PLATE + 0.002), normal)
    back_normal = slope_normal(hatch[1], hatch[0])  # the hatch slopes the other way: from its top, down
    (ya, za), (yb, zb) = along(*hatch, 0.08), along(*hatch, 0.9)
    details.plate([Vector((-0.62, ya, za)), Vector((0.62, ya, za)), Vector((0.56, yb, zb)), Vector((-0.56, yb, zb))],
                  back_normal, "CAR_GLASS")
    (ya, za), (yb, zb) = along(*hatch, 0.14), along(*hatch, 0.32)
    details.plate([Vector((x, y, z)) for x, y, z in [(-0.56, ya, za), (-0.30, ya, za), (-0.30, yb, zb),
                                                      (-0.56, yb, zb)]], back_normal, "CAR_TRIM", lift=PROUD + PLATE)
    sticker_y, sticker_z = along(*hatch, 0.23)
    marker("StickerBack", root, Vector((-0.43, sticker_y, sticker_z)) + back_normal * (PROUD + 2 * PLATE + 0.002),
           back_normal)
    # The front: headlights with orange corners, a small grille, a dark bumper,
    # and a white number plate.
    end_plate(details, 1.97, 1, -0.26, 0.26, 0.48, 0.57, "CAR_TRIM")
    for side in (-1, 1):
        x0, x1 = sorted((side * 0.36, side * 0.68))
        end_plate(details, 1.97, 1, x0, x1, 0.48, 0.59, "PAPER")
        x0, x1 = sorted((side * 0.68, side * 0.76))
        end_plate(details, 1.97, 1, x0, x1, 0.48, 0.59, "KELEWELE_ORANGE")
    details.box((-0.86, 1.87, 0.27), (0.86, 2.04, 0.46), "CAR_TRIM")
    end_plate(details, 2.04, 1, -0.22, 0.22, 0.30, 0.41, "ROAD_MARKING")
    # The back: tall red lights at the corners, a dark bumper, and a number plate.
    for side in (-1, 1):
        x0, x1 = sorted((side * 0.58, side * 0.80))
        end_plate(details, -half_l, -1, x0, x1, 0.60, 0.84, "TILE_RED")
    details.box((-0.86, -2.03, 0.27), (0.86, -1.87, 0.46), "CAR_TRIM")
    end_plate(details, -half_l, -1, -0.22, 0.22, 0.50, 0.60, "ROAD_MARKING")
    details.to_object(materials, root)

    radius, width = CAR_WHEEL
    for axle, y in (("Front", CAR_WHEELS_Y[0]), ("Back", CAR_WHEELS_Y[1])):
        for label, side in (("Left", -1), ("Right", 1)):
            build_wheel(materials, root, f"Wheel{axle}{label}",
                        (side * (CAR_WIDTH / 2 - width / 2), y, radius), radius, width, side)
    return root, {"length": CAR_LENGTH, "width": CAR_WIDTH, "height": CAR_ROOF}


VEHICLES = [("trotro", build_trotro), ("uber_car", build_uber)]


# ---------------------------------------------------------------------------
# Preview pictures
# ---------------------------------------------------------------------------


def render_previews(roots, out_dir):
    """Pictures of each vehicle: from its front right (like the drawings in
    blender/vehicles/), from where the game camera sees it, and from behind."""
    out_dir.mkdir(parents=True, exist_ok=True)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x, scene.render.resolution_y = 720, 480
    scene.view_settings.view_transform = "Standard"
    world = bpy.data.worlds.new("World")
    scene.world = world
    background = next(n for n in world.node_tree.nodes if n.bl_idname == "ShaderNodeBackground")
    background.inputs["Color"].default_value = (0.62, 0.66, 0.7, 1.0)
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN"))
    sun.data.energy = 3.2
    sun.rotation_euler = Vector((0.354, 0.612, -0.707)).to_track_quat("-Z", "Y").to_euler()
    scene.collection.objects.link(sun)
    camera = bpy.data.objects.new("Camera", bpy.data.cameras.new("Camera"))
    camera.data.type = "ORTHO"
    scene.collection.objects.link(camera)
    scene.camera = camera
    for root, info, game_view in roots:
        for other, _, _ in roots:
            for child in other.children:
                child.hide_render = other is not root
        target = root.location + Z * (info["height"] * 0.45)
        camera.data.ortho_scale = info["length"] * 1.25
        views = [("front_right", Vector((1.0, 1.1, 0.45))), ("game_angle", game_view),
                 ("back", Vector((-0.6, -1.0, 0.5)))]
        for label, direction in views:
            camera.location = target + direction.normalized() * 30.0
            camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
            scene.render.filepath = str(out_dir / f"{root.name}_{label}.png")
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
    # How the game camera sees each one: the trotro drives west, showing its
    # back and left side; the Uber drives east, showing its front and right side.
    game_views = {"trotro": Vector((-1.0, -1.0, 0.82)), "uber_car": Vector((1.0, 1.0, 0.82))}
    for name, build in VEHICLES:
        root, info = build(materials)
        for obj in scene.objects:
            obj.select_set(obj is root or obj.parent is root)
        bpy.context.view_layer.objects.active = root
        bpy.ops.export_scene.gltf(
            filepath=str(out / f"{name}.glb"),
            export_format="GLB",
            use_selection=True,
            export_apply=True,
            export_animations=False,
            export_materials="EXPORT",
        )
        meshes = [obj for obj in root.children if obj.type == "MESH"]
        depsgraph = bpy.context.evaluated_depsgraph_get()
        triangles = sum(sum(len(p.vertices) - 2 for p in obj.evaluated_get(depsgraph).data.polygons) for obj in meshes)
        print(f"VEHICLE {name}: {info['length']:.2f} m long, {info['width']:.2f} m wide, {info['height']:.2f} m tall, "
              f"{triangles} triangles, parts: {', '.join(sorted(child.name for child in root.children))}")
        # Blender needs every object name to be unique, so once this vehicle is
        # exported, rename its parts. Then the next one can use plain names too.
        for child in root.children:
            child.name = f"{name}.{child.name}"
        # Line them up side by side in the .blend file, for looking at.
        root.location.x = x + info["width"] / 2
        x += info["width"] + 2.0
        roots.append((root, info, game_views[name]))

    if args.renders:
        render_previews(roots, Path(args.renders))
    if args.blend:
        Path(args.blend).parent.mkdir(parents=True, exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=str(Path(args.blend).resolve()))


main()
