# Lagos Life Simulator: AI game dev prompt

> **Current job: Job 1, "Walk around"** (details in section 8)

**How to use this file:** start a fresh Codex session for each job and tell it
to read this file and do the current job. The AI does only that job. When the
job's tests pass, it commits, marks the job done in the Roadmap, and moves
**Current job** to the next one.

## 1. Your role
You are my AI game development partner. I'm a beginner in Godot, Blender, and
game development. You write most of the code, and I want to understand what
we're building.
- Explain things in plain, beginner-friendly language. The first time you use a
  Godot term (node, scene, signal, autoload…), explain it in one sentence.
- Work incrementally: small steps, and run something after each step.
- Don't overwrite or rewrite working features unless the job requires it.
  Inspect before you change.
- If a decision is mine to make (game design, art direction, adding a new tool
  or service), ask me instead of guessing.

## 2. Project overview
- **Game:** Lagos Life Simulator, an African city exploration and life-simulation
  game set in Lagos, Nigeria
- **Inspiration:** Naija Life Lagos Simulator, and the city look of Cities: Skylines
- **Engine:** Godot 4.7.2 (`/Applications/Godot.app`)
- **Language:** GDScript with static typing (`var speed: float = 4.5`)
- **3D modeling:** Blender 5.2.2 LTS (`/Applications/Blender.app`)
- **Coding assistant:** Codex
- **Camera:** isometric (orthographic), looking down on a fully 3D city
- **Machine:** Mac with Apple Silicon (M4 Pro)
- **Locations:**
  - Repo root: `/Users/nanaasiedu-ofeijnr/Documents/Projects/kayayo` (this file)
  - Godot project: `kayayo/gold-coast/`, which is `res://` (the folder name stays as is)
  - Blender sources and scripts: `kayayo/blender/` (outside the Godot project)

## 3. Game vision
**Core loop (proposed, not final): the daily hustle.**
Wake up in a rented room → choose how to make money today → get there (walk for
free, or pay for a danfo or keke to save time) → work → spend ₦ on food,
transport, and rent → get home and sleep. In the long run: save up, find better
hustles, and move from a mainland room to a better home. You start with ₦10,000.

**The look:** a fully 3D Lagos neighborhood seen from a fixed isometric angle.
Clean, readable, and slightly stylized, like Cities: Skylines rather than
photorealism. Use simple shapes and let the lighting do most of the work. Lagos
details to add over time: painted compound walls with gates, rusted corrugated
roofs, rooftop water tanks, generators, kiosks and container shops, umbrellas,
hand-painted signboards, "This house is not for sale" painted on walls, power
poles with tangled wires, open gutters along the roads, yellow danfos, kekes,
okadas, palm trees, harmattan haze, and orange streetlights at night.

**Color rule:** every color in code comes from one palette file,
`res://art/palette/palette.gd`. Colors picked in the editor also use palette
values. Until we build the real color bible (Job 10), use this provisional palette:

| Name | Hex | Use |
|---|---|---|
| `danfo_yellow` | `#F2B705` | buses, accents |
| `laterite` | `#A9532D` | bare ground, road edges |
| `asphalt` | `#4A4A48` | roads |
| `road_marking` | `#E8E4D8` | lane lines |
| `concrete` | `#B9B2A3` | sidewalks, plain walls |
| `wall_cream` | `#E9DCC0` | buildings |
| `wall_blue` | `#8DB8D0` | buildings |
| `wall_mint` | `#A8CFA6` | buildings |
| `wall_salmon` | `#E3A08C` | buildings |
| `rust_roof` | `#8B4A2B` | roofs |
| `palm_green` | `#3F7A3A` | plants |
| `player_blue` | `#2B59C3` | placeholder player |

## 4. Current state (inspected 2026-10-21)
`gold-coast/` is a brand-new, empty Godot project:
- It contains only the files Godot creates for a new project: `project.godot`,
  `icon.svg`, `.gitignore`, `.gitattributes`, `.editorconfig`
- There are no scenes, scripts, or assets, and no main scene is set (pressing
  Play asks you to pick one)
- The display name is "Gold Coast"
- The renderer is **GL Compatibility**, which runs on old hardware and the web
  but leaves out much of Godot's better lighting. Job 1 switches it to **Forward+**.
- The physics engine is Jolt and the UI stretch mode is `canvas_items`. Both
  are good; keep them.
- It's not a git repository yet. The Godot command-line tool isn't on PATH, so
  use the full path below.

Before starting any job, re-check the project. If something was added since this
was written, keep it working and build on it.

## 5. Rules for every job
1. **One job per session.** Do only the current job. If you notice something else
   that needs doing, put it in your report instead of doing it.
2. **Inspect first.** Read the relevant files before changing anything.
3. **Small steps.** Run the project or the tests after each step.
4. **Every job ends with a test:**
   - Automated: headless tests that print PASS or FAIL for each check and exit
     with code 0 (all passed) or 1 (something failed)
   - Manual: a short checklist I can follow in the Godot editor
5. **Commit when the tests pass**, with one commit per job (e.g. `Job 1: walk around`).
   Never run destructive git commands (`reset --hard`, `clean -fd`, force push)
   without asking me first.
6. **Placeholders first.** Use simple shapes for now; real Blender models come
   later. Make every placeholder its own scene so it can be swapped for a real
   model without changing code.
7. **No addons or downloads** unless the job calls for them. Any third-party asset
   must be CC0 or CC-BY, with its source and license recorded in `CREDITS.md`.
8. **Use Input Map actions** (`move_forward`, etc.) in code, never raw key codes.
9. **Explain what you changed** using the report format in section 9, and add the
   "New concepts" part to `docs/learning-notes.md`.

### Commands
```bash
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
cd /Users/nanaasiedu-ofeijnr/Documents/Projects/kayayo/gold-coast

$GODOT --headless --path . --import                      # register files added from outside the editor
$GODOT --headless --path . --quit-after 300              # smoke test: run the main scene for 300 frames, then quit
$GODOT --headless --path . res://tests/test_runner.tscn  # automated tests (exit code 0 = all passed)
$GODOT --path .                                          # play the game in a window
$GODOT --path . --editor                                 # open the editor
```
Any `ERROR` or `SCRIPT ERROR` line in the output counts as a failure, even if
the tests pass.

Blender scripts (later jobs) run inside Blender's own Python, not any other
Python environment:
`/Applications/Blender.app/Contents/MacOS/Blender --background --python blender/scripts/<name>.py`

### Known Godot pitfalls
- **Open scenes:** if a scene is open in the editor while you change its file on
  disk, Godot asks what to do. Tell me to choose **Reload**, because "Resave"
  overwrites your changes.
- **`project.godot`:** the editor rewrites this file when it saves settings.
  Change it only while the editor is closed, or tell me to restart the editor
  right after.
- **`.uid` files:** Godot creates `.uid` files next to scripts. Commit them and
  never delete them.
- **Curbs:** a CharacterBody3D can't step up even a small ledge without extra
  code. Keep walkable surfaces such as roads and sidewalks flat for now.
- **Orthographic camera:** place it far enough back along its view direction
  (about 40 m) that nothing gets clipped. If shadows disappear, increase the
  sun's shadow max distance.
- **₦ symbol:** check that it actually renders. If it shows up as a box, bundle a
  font that includes ₦ (e.g. Noto Sans, OFL license) and credit it.

## 6. Project structure
This is the target layout. Create folders as jobs need them.
```text
kayayo/                       repo root
  PROMPT.md                   this file
  CREDITS.md                  third-party assets and licenses (create when first needed)
  docs/
    learning-notes.md         plain-language notes on new concepts, added after every job
  blender/                    Blender sources: generator scripts (*.py) and .blend files
  gold-coast/                 the Godot project (res://)
    project.godot
    autoload/                 global singletons, e.g. game_state.gd (money)
    scenes/
      main/                   main.tscn, the entry point that assembles the world
      player/                 player.tscn + player.gd
      camera/                 iso_camera.tscn + iso_camera.gd
      world/                  ground, roads, environment and lighting
      buildings/              placeholder_building.tscn (later: real buildings)
      ui/                     hud.tscn, later menus and panels
    scripts/                  shared helpers not tied to one scene, e.g. format.gd
    art/
      palette/                palette.gd, the single source of colors
      models/                 .glb files exported from Blender
      materials/
    tests/                    test_runner.tscn + test_*.gd
```
Keep each scene and its script in the same folder. Use `snake_case` for file
and folder names.

## 7. Roadmap
Each job takes one session and ends with a test. Mark a job `[x]` when it's done.

**Phase 1: Prototype**
- [ ] **Job 1: Walk around.** Ground, a road, a capsule player with
  camera-relative WASD, a fixed isometric camera that follows the player, and
  sun and environment lighting. *Test:* holding W moves the player up the screen.
- [ ] **Job 2: Neighborhood.** A main road with a cross street, and five
  placeholder buildings with collision, all made from one reusable building
  scene. *Test:* walking into any building stops the player.
- [ ] **Job 3: Money.** A `GameState` autoload that owns money (starting at
  10,000) and a HUD that shows `₦10,000`. *Test:* the formatting and
  earn/spend tests pass, and the HUD updates when money changes.

**Phase 2: First gameplay loop**
- [ ] **Job 4: See-through buildings.** Buildings between the camera and the
  player fade out. *Test:* the player stays visible behind every building.
- [ ] **Job 5: Day clock.** Time passes, the sun moves, and the HUD shows the day
  and time. *Test:* a fast-forwarded day reaches the right clock times and sun angles.
- [ ] **Job 6: Needs.** Hunger and energy drain over time and show on the HUD.
  *Test:* the drain rates match their settings.
- [ ] **Job 7: Interactions.** A "Press E" interaction system. Buy food at a
  buka (costs ₦, restores hunger) and sleep at home (skips to morning, restores
  energy). *Test:* buying food with too little money fails cleanly.
- [ ] **Job 8: First hustle.** One simple job that earns ₦, e.g. carrying
  deliveries between shops within a time limit. *Test:* I can play one full day:
  earn, eat, sleep.
- [ ] **Job 9: Rent and saving.** Weekly rent, plus save and load (saving when
  you sleep). *Test:* saving and loading restores money, time, and needs.

**Phase 3: Make it look like Lagos**
- [ ] **Job 10: Color bible.** Built from one reference image I choose, with a
  day version and a night version of every color. It replaces the provisional
  palette, and nothing goes into the game without it.
- [ ] **Job 11: Lighting lab.** An in-game debug panel with sliders (sun angle,
  sun color, ambient light, fog, exposure) and presets: harmattan morning,
  midday, golden hour, night, blackout night ("NEPA took light"), and rainy season.
- [ ] **Job 12: Blender pipeline.** Python scripts that build low-poly buildings
  and props in Blender and export `.glb` files. To fix a model, change a line of
  the script and run it again; never hand-edit the mesh. Keep shapes simple
  rather than aiming for realism.
- [ ] **Job 13: Real character.** Concept art → a rigged, animated mesh (e.g.
  from Meshy or Mixamo), recolored to the color bible.
- [ ] **Job 14: Enterable home.** When you step inside, the roof and front wall
  hide. It's the same scene, with no loading screen.

**Phase 4: Living city (to be planned later)**
Pedestrians; danfos and kekes driving routes; go-slow traffic; more
neighborhoods; weather and events (harmattan, rainy-season flooding, power
cuts); a phone UI (map, bank app).

## 8. Job details

### Job 1: Walk around (current)
**Goal:** the smallest playable thing. You press Play and walk a character along
a sunlit Lagos road, seen from a fixed isometric camera.

**Steps** (run something after each one):
1. **Inspect** the project and confirm the current state in section 4. Report
   anything that's different.
2. **Git:** initialize a repository at the repo root (`kayayo/`). Add a root
   `.gitignore` containing `.DS_Store`, then commit the existing files *before*
   changing anything. Explain git to me in a sentence or two.
3. **Project settings:**
   - Display name: `Lagos Life Simulator`
   - Renderer: Forward+ (tell me to restart the editor if it's open)
   - Input Map actions: `move_forward` (W, Up), `move_back` (S, Down),
     `move_left` (A, Left), `move_right` (D, Right)
4. **Palette:** create `art/palette/palette.gd` (`class_name Palette`) with the
   provisional colors from section 3 as constants.
5. **World:** create `scenes/main/main.tscn` and set it as the main scene. It contains:
   - Ground: an 80 × 80 m StaticBody3D with flat box collision, colored `laterite`
   - One straight, flat road (visual only): 8 m of `asphalt` with a dashed
     `road_marking` center line and `concrete` sidewalks on both sides
   - A WorldEnvironment: procedural sky, ambient light from the sky, Filmic or
     AgX tonemapping, SSAO (turn it off if it looks wrong with the orthographic
     camera), and subtle glow
   - A DirectionalLight3D named "Sun": warm afternoon light about 45° above the
     horizon, with shadows on
6. **Player:** create `scenes/player/player.tscn` and `player.gd`:
   - A CharacterBody3D with capsule collision (about 1.8 m tall), a capsule
     mesh, and a small "nose" box showing which way it faces
   - Camera-relative movement: W moves up the screen, S down, A left, and D
     right, whatever the camera angle (project the camera's forward and right
     vectors onto the ground)
   - Walk speed of about 4.5 m/s with quick acceleration and deceleration (not
     instant), gravity, and smooth turning toward the direction of movement
   - Tunable values as `@export` variables so I can tweak them in the Inspector
7. **Camera:** create `scenes/camera/iso_camera.tscn` and `iso_camera.gd`:
   - An orthographic Camera3D pitched −30° and yawed 45° (the classic 2:1
     isometric look), with an orthographic size of about 20
   - It follows a target (the player) smoothly. The angle never changes, and the
     player can't move the camera.
8. **Tests:** create `tests/test_runner.tscn` and `tests/test_player_movement.gd`. They:
   - load `main.tscn`
   - simulate holding `move_forward` for 1 second, then check that the player
     moved toward the top of the screen (use the camera's flattened vectors or
     `Camera3D.unproject_position`)
   - repeat that for the other three directions
   - check that the player stays on the ground (doesn't fall through or float)
9. **Run** the smoke test and the tests, fix anything that fails, and commit.
10. **Update this file:** mark Job 1 `[x]`, update section 4, and point
    **Current job** at Job 2.

**Done when:**
- Pressing Play (F5) starts `main.tscn` with no errors in the Output panel
- WASD (including diagonals) moves the player in the right screen directions,
  and the camera follows smoothly
- The player casts a shadow, and the scene is lit by the sun and sky
- All tests pass, and the smoke test shows no errors

### Job 2: Neighborhood
**Goal:** a small neighborhood you can walk around, where buildings block you.
1. **Reusable building:** create `scenes/buildings/placeholder_building.tscn`
   and `placeholder_building.gd`. The root is a StaticBody3D with a box mesh, a
   matching box collision, and a simple `rust_roof` roof. Expose `@export` values
   for size (Vector3) and wall color (a palette name). Make it a `@tool` script
   so changes show up in the editor right away, and keep the mesh and collision
   the same size automatically.
2. **Roads:** extend the Job 1 road into a main road with one cross street (a T
   or + junction). Keep it flat and visual only. Make the road its own reusable
   scene if that keeps `main.tscn` tidy.
3. **Five buildings:** place them along the roads, each with its own name, size,
   and color. For example: a two-storey face-me-I-face-you house, a provisions
   shop, a buka, a three-storey apartment block, and a bank. Give each one a
   floating Label3D sign with its name.
4. **Tests:** for each building, start the player 3 m in front of it, push toward
   it for 2 seconds, and check the player never ends up inside its footprint.
   Also check that each building's collision size matches its mesh.

**Done when:** you can't walk through any building, you can still walk around
all of them, and the tests pass.

### Job 3: Money
**Goal:** show the player's money on screen, starting at ₦10,000, with one place
in the code that owns it.
1. **GameState:** create `autoload/game_state.gd` and register it as the
   `GameState` autoload. It has `money: int = 10000`, a
   `money_changed(new_amount: int)` signal, `add_money(amount: int)`, and
   `spend_money(amount: int) -> bool`. If there isn't enough money,
   `spend_money` returns false and changes nothing.
2. **Formatting:** create `scripts/format.gd` with `format_naira(amount: int) -> String`.
   It should give 10000 → `₦10,000`, 1234567 → `₦1,234,567`, 0 → `₦0`, and
   -500 → `-₦500`.
3. **HUD:** create `scenes/ui/hud.tscn`, a CanvasLayer with a large, readable
   money label in the top-left corner on a subtle background panel. It updates
   from the `money_changed` signal, never by checking every frame.
4. **Debug key:** in debug builds only, F2 adds ₦1,000 so I can watch the HUD update.
5. **Tidy-up:** make sure everything matches the structure in section 6.
6. **Tests:** cover the formatting cases above, spending with enough money,
   spending with too little (returns false and money is unchanged), and the
   signal firing with the new amount.

**Done when:** the HUD shows ₦10,000 at the start (the ₦ renders properly, not
as a box), F2 updates it immediately, and the tests pass.

## 9. Report format (end of every job)
1. **What I built:** 2–3 sentences
2. **Files:** each new or changed file, with one line on what it does
3. **Try it yourself:** numbered steps in the Godot editor, and what I should see
4. **Test results:** the commands you ran and the pass/fail summary
5. **New concepts:** 2–4 plain-language explanations (also added to
   `docs/learning-notes.md`)
6. **Notes and next:** anything you noticed but didn't do, and the next job
