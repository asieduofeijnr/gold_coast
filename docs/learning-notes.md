# Learning notes

Plain-language notes on the ideas behind each job, newest at the bottom.

## Job 1: Walk around

- **Git** is a save system for code. Each *commit* is a snapshot you can go
  back to, so if a later job breaks something, we can undo just that job.
- **Nodes and scenes.** Everything in Godot is built from *nodes*: small
  building blocks that each do one job (a mesh you can see, a collision shape,
  a light, a camera). A *scene* is a group of nodes saved as a file (`.tscn`),
  and scenes can be placed inside other scenes. `main.tscn` is put together
  from smaller scenes: lighting, ground, road, player, and camera.
- **Bodies and collision shapes.** A `StaticBody3D` is something solid that
  never moves (the ground). A `CharacterBody3D` is something you move with code
  (the player). Neither can bump into anything until it has a
  `CollisionShape3D` child that gives it a shape. What you *see* (the mesh) and
  what you *bump into* (the collision shape) are separate, which is why the
  ground script keeps them the same size.
- **The Input Map** gives keys names. The code asks "is `move_forward`
  pressed?" instead of "is W pressed?", so W and the Up arrow both work, and you
  can change keys in Project Settings → Input Map without touching code.
  "Camera-relative" movement means the player script takes the camera's
  forward and right directions, flattens them onto the ground, and walks along
  them. That's why W always means "up the screen".
- **`@export` and `@tool`.** `@export` puts a script's setting in the
  Inspector so you can tweak it without editing code (try the player's Walk
  Speed). `@tool` makes a script run inside the editor too, which is why you
  can see the road and the palette colors before you press Play.

## First character

- **Building a model with a script.** Instead of sculpting by hand, a Python
  script tells Blender "put a tube here, a sphere there". To change the
  character, you change a number in the script and run it again, so nothing
  is ever lost or hard to redo.
- **Skeleton and bones.** A skeleton (Blender calls it an *armature*) is a set
  of invisible bones: hips, spine, arms, legs, and so on. You animate the bones,
  and the mesh follows them.
- **Skin weights.** Each point on the mesh is told which bones move it and how
  much. Near the elbow, a point is shared between the upper arm and the
  forearm, so the arm bends smoothly instead of creasing. The skirt is shared
  between both legs, so it stretches between them like cloth.
- **Animations and loops.** An animation is a list of bone poses over time.
  The walk's last pose matches its first, so it can repeat forever without a
  hitch. The game plays `idle` when she stands and `walk` when she moves.
- **Matching speed to steps.** If a character moves faster than their legs
  step, their feet slide like they're on ice. We measured how fast her walk
  travels (about 1.7 m/s), and the game speeds the animation up or slows it
  down to match how fast she's really moving.
- **`.glb` files** carry a model, its skeleton, its colors, and its animations
  in one file that Blender writes and Godot reads.

## Job 2: Neighborhood

- **One scene, many buildings.** All five buildings come from the same scene,
  `placeholder_building.tscn`. Each copy in the main scene is an *instance*
  with its own settings (name, size, color, roof). Make the scene better once,
  and every building gets better.
- **Solid things.** A building is a `StaticBody3D`: a physics body that never
  moves. It only blocks the player because it has a collision shape the same
  size as its walls. The door and windows are just pictures on the wall; they
  have no collision, so you can't walk through the door yet.
- **Generated pieces.** The building script makes its walls, roof, windows, and
  sign in code each time a setting changes. They're *internal* children, so
  they don't clutter the scene tree and aren't saved: only the settings are.
- **Text in 3D.** `Label3D` shows text in the 3D world. The building names use
  *billboard mode*, so they always turn to face the camera. The words on the
  billboard don't: they're painted on its front, like a real sign.
- **Testing by walking.** The test puts the player 3 m in front of each
  building and holds W + D (which walks straight at the wall). She should stop
  0.35 m away, exactly the radius of her collision capsule. When we broke the
  collision on purpose, she walked into the walls and the test failed, which
  proves the test really checks something.
