# Gold Coast: AI game dev prompt

> **Current job: Job 3, "Money"** (details in section 8)

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
- **Game:** Gold Coast, an exploration and life-simulation game about everyday
  life in Ghana
- **Inspiration:** Naija Life Lagos Simulator (for gameplay only; the setting is
  Ghana), and the city look of Cities: Skylines
- **Engine:** Godot 4.7.2 (`/Applications/Godot.app`)
- **Language:** GDScript with static typing (`var speed: float = 4.5`)
- **3D modeling:** Blender 5.2.2 LTS (`/Applications/Blender.app`)
- **Coding assistant:** Codex
- **Camera:** isometric (orthographic), looking down on a fully 3D city
- **Machine:** Mac with Apple Silicon (M4 Pro)
- **Locations:**
  - Repo root: `/Users/nanaasiedu-ofeijnr/Documents/Projects/kayayo` (this file)
  - Godot project: `kayayo/gold-coast/`, which is `res://`
  - Blender sources and scripts: `kayayo/blender/` (outside the Godot project)

## 3. Game vision
**Core loop (proposed, not final): the daily hustle.**
Wake up in a rented room in a compound house → choose how to make money today
(for example carrying loads at the market, selling in traffic, or running a
chop bar) → get there (walk for free, or pay for a trotro or taxi to save
time) → work → spend cedis on food, transport, and rent → get home and sleep.
In the long run: save up the rent advance landlords ask for, find better
hustles, and move from a single room to a chamber and hall, then to a place of
your own. You start with GH₵100.

**The look:** a fully 3D Ghanaian neighborhood seen from a fixed isometric
angle. Clean, readable, and slightly stylized, like Cities: Skylines rather
than photorealism. Use simple shapes and let the lighting do most of the work.
Ghanaian details to add over time: compound houses around shared courtyards,
painted walls and gates, rusted "zinc" roofs, black polytanks on the roofs,
kiosks and container shops painted in bright telecom colors, roadside
umbrellas, hand-painted signboards with names like "God Is Great Enterprise",
"REMOVE BY ORDER" painted on walls, power poles with tangled wires, open
gutters along the roads, trotros with slogans painted on the back, taxis with
painted corners, okadas, aboboyaas, kayayei carrying loads on their heads, palm
and neem trees, red laterite earth, harmattan haze, and orange streetlights at
night.

**Color rule:** every color in code comes from one palette file,
`res://art/palette/palette.gd`. Colors picked in the editor also use palette
values. Until we build the real color bible (Job 10), use this provisional palette:

| Name | Hex | Use |
|---|---|---|
| `kente_gold` | `#F2B705` | accents, taxi corners, signboards |
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
| `skin_deep` | `#7A4433` | the player's skin |
| `cloth_maroon` | `#6A1C15` | her slit (wrap skirt) |
| `cloth_red` | `#A3362A` | her duku (headwrap) |
| `cloth_cream` | `#EAD3B4` | her kaba (top) |
| `cloth_ochre` | `#E0A878` | trim bands on her skirt |
| `gold_jewelry` | `#D9A55B` | earrings, necklace, bangles |
| `dark_brown` | `#3D1A14` | sandals, eyes |

`palette.gd` also holds the sun and sky colors. The character colors were picked
from the reference picture in `blender/characters/reference/`.

## 4. Current state (updated 2026-10-24, after Jobs 1 and 2 and the first character)
- **Job 1 is done.** Pressing Play opens `scenes/main/main.tscn`: a sunlit
  80 × 80 m patch of laterite with one road, and the player character you walk
  with WASD or the arrow keys, seen from a fixed isometric camera.
- **Job 2 is done.** Five solid placeholder buildings stand on the far side of
  the road (−Z, the upper right on screen), all built from one reusable scene:
  - Compound House, Provisions Store, Chop Bar, Apartment Block, and Mobile
    Money kiosk
  - Their fronts sit at z = −7.5, doors facing the road
  - At the end of the row stands an "AKWAABA!" billboard in Ghana's flag colors
  - The cross street from the original plan is postponed: there's still one road
- **First character is done (Job 13, done early).** A young woman in a kaba and
  slit with a duku, gold jewelry, and sandals, in a slim, flat-color style.
  - She's built by `blender/scripts/build_player_character.py`, which exports
    `gold-coast/art/models/characters/player_character.glb` (about 3,000
    triangles, 19 bones with Godot humanoid names, and looping `idle` and `walk`
    animations). The script reads her colors from `palette.gd`.
  - `blender/characters/player_character_preview.png` shows her from every side.
  - `scenes/player/player_model.tscn` (`PlayerModel`) plays idle or walk and
    scales the walk to match her speed. She walks at 1.8 m/s; the walk
    animation was made for 1.7 m/s.
- **Settings:** the display name is "Gold Coast". The renderer is
  Forward+ (Metal on Apple Silicon) and the physics engine is Jolt. Physics
  interpolation is on (smooth movement on 120 Hz screens), and 4× MSAA smooths
  edges. The UI stretch mode is `canvas_items`. The Input Map actions are
  `move_forward`, `move_back`, `move_left`, and `move_right`.
- **Colors:** `art/palette/palette.gd` (`Palette`) holds every color,
  including the sun, sky, and character colors. `art/palette/palette_mesh.gd`
  (`PaletteMesh`) is a mesh whose color you pick from a dropdown of palette names.
- **Scenes:**
  - `scenes/world/` holds `lighting.tscn` (the sun and sky), `ground.tscn`
    (ground with invisible walls at the edge), and `road.tscn` (built in code
    from its settings; runs along X)
  - `scenes/buildings/` holds `placeholder_building.tscn` (`PlaceholderBuilding`):
    - It has `@export` settings for name, size, wall color, and roof style
      (flat concrete, or a gable zinc roof)
    - Its script builds the walls, a matching collision box, a door (or a
      serving hatch if it's narrower than 4 m), windows, the roof (with a
      polytank on flat roofs at least 6 m wide), and a floating name label
    - The front faces +Z
  - `scenes/props/` holds `billboard.tscn` (`Billboard`): a headline and tagline,
    a red/gold/green board with black stars and two spotlights. The posts are
    solid, and you can walk under the board.
  - `scenes/player/` holds `player.tscn`, whose `Model` is `player_model.tscn`.
    The old capsule, `player_placeholder_model.tscn`, is kept as a fallback.
  - `scenes/camera/` holds `iso_camera.tscn`
- **Shared helpers:** `scripts/shapes.gd` (`Shapes`) makes palette-colored boxes
  and solid boxes.
- **Editor scripts:** the palette mesh, ground, road, lighting, camera,
  building, and billboard scripts are `@tool` scripts, so they also run in the
  editor and the scene looks right before you press Play. The pieces they make
  are "internal" children: hidden in the scene tree and never saved.
- **Tests:** `tests/test_runner.tscn` runs every `tests/test_*.gd` file.
  `tests/test_case.gd` (`TestCase`) is the base class, with `check()` and
  `wait_physics_frames()`. There are 38 checks so far, all passing.
- **Git:** the repo is at `kayayo/` on branch `main`, with one commit per job.
  The reference picture is ignored by git: it's a Vecteezy download with its own
  license, used only for inspiration.
- The Godot command-line tool isn't on PATH, so use the full path below.
- **Git:** the repo is at `kayayo/` on branch `main`, with one commit per job.
  The reference picture is ignored by git: it's a Vecteezy download with its own
  license, used only for inspiration.
- The Godot command-line tool isn't on PATH, so use the full path below.

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
$GODOT --path . --write-movie /tmp/shots/frame.png --quit-after 60  # save 60 frames as images to check the look
```
Any `ERROR` or `SCRIPT ERROR` line in the output counts as a failure, even if
the tests pass. After adding a new `class_name` script from outside the editor,
run `--import` before anything else, or other scripts can't find the class.

Blender scripts run inside Blender's own Python, not any other Python
environment. Run them from the repo root (`kayayo/`). To rebuild the player
character after changing her script or her palette colors:
```bash
/Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup \
  --python blender/scripts/build_player_character.py -- \
  --palette gold-coast/art/palette/palette.gd \
  --glb gold-coast/art/models/characters/player_character.glb \
  --blend blender/characters/player_character.blend \
  --renders /tmp/player_character_renders
```
Then run Godot's `--import` and the tests. If you change her walk, re-measure its
speed and update `walk_animation_speed` in `player_model.gd`, or her feet will
slide.

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
- **₵ symbol (the cedi sign in GH₵):** check that it actually renders. If it
  shows up as a box, bundle a font that includes ₵ (e.g. Noto Sans, OFL
  license) and credit it.

## 6. Project structure
This is the target layout. Create folders as jobs need them.
```text
kayayo/                       repo root
  PROMPT.md                   this file
  CREDITS.md                  third-party assets and licenses (create when first needed)
  docs/
    learning-notes.md         plain-language notes on new concepts, added after every job
  blender/                    Blender files (outside the Godot project)
    scripts/                  scripts that build models, e.g. build_player_character.py
    characters/               .blend files and preview pictures; reference/ (not in git)
  gold-coast/                 the Godot project (res://)
    project.godot
    autoload/                 global singletons, e.g. game_state.gd (money)
    scenes/
      main/                   main.tscn, the entry point that assembles the world
      player/                 player.tscn + player.gd
      camera/                 iso_camera.tscn + iso_camera.gd
      world/                  ground, roads, environment and lighting
      buildings/              placeholder_building.tscn (later: real buildings)
      props/                  billboard.tscn, later streetlights, kiosks, trees
      ui/                     hud.tscn, later menus and panels
    scripts/                  shared helpers not tied to one scene, e.g. shapes.gd, format.gd
    art/
      palette/                palette.gd, the single source of colors
      models/                 .glb files exported from Blender, e.g. characters/player_character.glb
      materials/
    tests/                    test_runner.tscn + test_*.gd
```
Keep each scene and its script in the same folder. Use `snake_case` for file
and folder names.

## 7. Roadmap
Each job takes one session and ends with a test. Mark a job `[x]` when it's done.

**Phase 1: Prototype**
- [x] **Job 1: Walk around.** Ground, a road, a capsule player with
  camera-relative WASD, a fixed isometric camera that follows the player, and
  sun and environment lighting. *Test:* holding W moves the player up the screen.
- [x] **Job 2: Neighborhood.** Five placeholder buildings with collision on the
  far side of the road, all made from one reusable building scene, plus an
  "AKWAABA!" billboard at the end of the row. (The cross street is postponed.)
  *Test:* walking into any building stops the player.
- [ ] **Job 3: Money.** A `GameState` autoload that owns money (starting at
  GH₵100) and a HUD that shows `GH₵100.00`. *Test:* the formatting and
  earn/spend tests pass, and the HUD updates when money changes.

**Phase 2: First gameplay loop**
- [ ] **Job 4: See-through buildings.** Buildings between the camera and the
  player fade out. *Test:* the player stays visible behind every building.
- [ ] **Job 5: Day clock.** Time passes, the sun moves, and the HUD shows the day
  and time. *Test:* a fast-forwarded day reaches the right clock times and sun angles.
- [ ] **Job 6: Needs.** Hunger and energy drain over time and show on the HUD.
  *Test:* the drain rates match their settings.
- [ ] **Job 7: Interactions.** A "Press E" interaction system. Buy food at a
  chop bar (costs cedis, restores hunger) and sleep at home (skips to morning, restores
  energy). *Test:* buying food with too little money fails cleanly.
- [ ] **Job 8: First hustle.** One simple job that earns cedis, e.g.
  carrying a shopper's load across the market on your head like a kayayo,
  within a time limit. *Test:* I can play one full day:
  earn, eat, sleep.
- [ ] **Job 9: Rent and saving.** Weekly rent, plus save and load (saving when
  you sleep). *Test:* saving and loading restores money, time, and needs.

**Phase 3: Make it look like Ghana**
- [ ] **Job 10: Color bible.** Built from one reference image I choose, with a
  day version and a night version of every color. It replaces the provisional
  palette, and nothing goes into the game without it.
- [ ] **Job 11: Lighting lab.** An in-game debug panel with sliders (sun angle,
  sun color, ambient light, fog, exposure) and presets: harmattan morning,
  midday, golden hour, night, dumsor night (a power cut), and rainy season.
- [ ] **Job 12: Blender pipeline.** Python scripts that build low-poly buildings
  and props in Blender and export `.glb` files. To fix a model, change a line of
  the script and run it again; never hand-edit the mesh. Keep shapes simple
  rather than aiming for realism.
- [x] **Job 13: Real character** (done early). Built with a Blender script
  instead of AI tools: `blender/scripts/build_player_character.py`. Later
  characters can follow the same pattern, or use concept art → Meshy or Mixamo.
- [ ] **Job 14: Enterable home.** When you step inside, the roof and front wall
  hide. It's the same scene, with no loading screen.

**Phase 4: Living city (to be planned later)**
Pedestrians; trotros and taxis driving routes, with a mate calling out the
stops; traffic jams; cross streets and more neighborhoods; weather and events (harmattan,
rainy-season flooding, dumsor); a phone UI (map, mobile money).

## 8. Job details

### Job 1: Walk around (done)
**Goal:** the smallest playable thing. You press Play and walk a character along
a sunlit Ghanaian road, seen from a fixed isometric camera.

**Steps** (run something after each one):
1. **Inspect** the project and confirm the current state in section 4. Report
   anything that's different.
2. **Git:** initialize a repository at the repo root (`kayayo/`). Add a root
   `.gitignore` containing `.DS_Store`, then commit the existing files *before*
   changing anything. Explain git to me in a sentence or two.
3. **Project settings:**
   - Display name: `Gold Coast`
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

### Job 2: Neighborhood (done)
**Goal:** a small neighborhood you can walk around, where buildings block you.
What was built (changed from the original plan at my request: one road,
buildings on one side only, and a billboard):
1. **Reusable building:** `scenes/buildings/placeholder_building.tscn` and
   `placeholder_building.gd`, a `@tool` StaticBody3D. Its walls and collision
   box are always the same size. It also has a door or hatch, windows, a flat
   concrete or gable zinc roof, an optional polytank, and a floating name label.
2. **Five buildings** on the far side of the road, each with its own name, size,
   color, and roof: a compound house, a provisions store, a chop bar, a
   three-storey apartment block, and a mobile money kiosk.
3. **Billboard:** `scenes/props/billboard.tscn` at the end of the row, turned
   25° toward the camera. It's styled like Red Alert 2's roadside billboards
   (small, bright, on posts, with spotlights) and The Sims' cheerful ads.
4. **Tests:** `tests/test_buildings.gd`, 17 checks:
   - each building's collision matches its mesh
   - walking into each building's front stops the player 0.35 m from the wall
     (her capsule's radius)
   - the billboard is at the end of the row and faces the camera
   - its posts are solid, and she can walk under the board

**Done when:** you can't walk through any building, you can still walk around
all of them, and the tests pass.

### Job 3: Money (current)
**Goal:** show the player's money on screen, starting at GH₵100, with one place
in the code that owns it.
1. **GameState:** create `autoload/game_state.gd` and register it as the
   `GameState` autoload. Count money in whole pesewas (100 pesewas = GH₵1) so
   prices like GH₵6.50 work without rounding errors. It has
   `money: int = 10000` (GH₵100.00), a `money_changed(new_amount: int)` signal,
   `add_money(amount: int)`, and `spend_money(amount: int) -> bool`. If there
   isn't enough money, `spend_money` returns false and changes nothing.
2. **Formatting:** create `scripts/format.gd` with
   `format_cedis(pesewas: int) -> String`. It should give 10000 → `GH₵100.00`,
   650 → `GH₵6.50`, 123456789 → `GH₵1,234,567.89`, 0 → `GH₵0.00`, and
   -50000 → `-GH₵500.00`.
3. **HUD:** create `scenes/ui/hud.tscn`, a CanvasLayer with a large, readable
   money label in the top-left corner on a subtle background panel. It updates
   from the `money_changed` signal, never by checking every frame.
4. **Debug key:** in debug builds only, F2 adds GH₵10 so I can watch the HUD update.
5. **Tidy-up:** make sure everything matches the structure in section 6.
6. **Tests:** cover the formatting cases above, spending with enough money,
   spending with too little (returns false and money is unchanged), and the
   signal firing with the new amount.

**Done when:** the HUD shows GH₵100.00 at the start (the ₵ renders properly,
not as a box), F2 updates it immediately, and the tests pass.

## 9. Report format (end of every job)
1. **What I built:** 2–3 sentences
2. **Files:** each new or changed file, with one line on what it does
3. **Try it yourself:** numbered steps in the Godot editor, and what I should see
4. **Test results:** the commands you ran and the pass/fail summary
5. **New concepts:** 2–4 plain-language explanations (also added to
   `docs/learning-notes.md`)
6. **Notes and next:** anything you noticed but didn't do, and the next job
