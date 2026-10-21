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
