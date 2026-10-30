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

## Buildings from Blender

- **A kit of parts.** The building script doesn't model five houses one by one.
  It has a kit (plinth, steps, walls, band, door, window, shutters, awning,
  zinc, tile, and thatch roofs, veranda posts, plaster patches), and each
  building is one line saying which pieces to use and how big. A new house in
  the same style is one more line.
- **Collision that travels with the model.** In Blender, the script adds an
  extra box called `Collision-convcolonly`. Godot has naming rules for imports:
  anything ending in `-convcolonly` becomes an invisible solid shape instead of
  something you see. So the file carries both the look and the solid parts,
  and they can't drift apart.
- **Why the test checks the base.** She can't climb the plinth or the steps, so
  the solid box has to cover them exactly. The test compares the collision with
  the `Base` mesh (the plinth and steps). When we removed the special name
  ending, the buildings stopped being solid and the test failed, as it should.
- **Unique names in Blender.** Every object in a Blender file needs its own
  name, so a second "Base" quietly becomes "Base.001". The script exports each
  building first, then renames its parts, so every exported file gets plain
  names.

## Job 3: Money

- **An autoload** is a script Godot loads once when the game starts and keeps
  for the whole game, reachable from anywhere by its name. `GameState` is one,
  so the phone, and later shops and jobs, all see the same money.
- **Signals** are announcements. `GameState` announces `money_changed` with the
  new amount, and the HUD listens and updates the phone. Nothing has to check
  the money every frame, and `GameState` doesn't need to know a phone exists.
- **Why pesewas?** Computers store decimals like 0.1 slightly inaccurately, so
  adding GH₵0.10 many times can drift. Whole numbers of pesewas never drift:
  GH₵6.50 is exactly 650. We only add the "GH₵" and the decimal point when
  showing it.
- **Drawing in code.** The phone is a `Control` with a `_draw()` function that
  paints rounded rectangles, text, and dots. The screen's letters are tiny
  pictures made of `#` and `.`, one 5 × 7 grid per letter, so you can edit a
  letter just by changing its dots.
- **Tweens** animate a value over time. The backlight jumps to 1 when money
  changes, waits, then a tween fades it back to 0.
- **Debug keys** are shortcuts for testing (F2 adds money, F3 spends it).
  `OS.is_debug_build()` keeps them out of the finished game.

## Job 4: See-through buildings, camera, and clicking

- **Lines of sight.** To know whether a building hides her, the game shoots
  invisible lines (*raycasts*) from her feet, middle, and head toward the
  camera. Whatever they pass through is in the way.
- **Physics layers** are like separate channels. Walls are on layer 1, which
  blocks the player. The roof copies are on layer 2, which only the lines of
  sight look at, so they hide her from view without ever blocking her path.
- **Fading** uses `transparency` on each mesh of that one building, so faded
  buildings never affect the others.
- **Screen to ground.** A click is a point on your screen. The game turns it
  into a line going into the world and finds where that line meets the ground
  (height 0). That's where she walks.
- **The walkable area** (a *navigation mesh*) is a map of everywhere she can
  walk, worked out at start-up from the ground and everything solid. Asking it
  for a path gives a list of corners that go around buildings; she walks from
  corner to corner.
- **Edge scrolling and zoom.** The camera has a *focus* point it looks at.
  Normally the focus follows her; pushing the mouse against an edge slides the
  focus instead. Zoom changes the camera's *size*: how many metres of the world
  fit the height of the screen.
- **Testing without a window.** The tests run in a hidden window that is 0 × 0
  pixels, so Godot moved simulated clicks off-screen. Sending clicks straight
  into the game's own coordinates fixed it. When a test fails, the bug can be
  in the test setup, not the game.

## Job 5: Day clock

- **Game time vs. real time.** Every frame, `GameState` adds a little game time:
  real seconds × `time_speed`. At speed 1 that's a game minute per real second,
  so a game day takes 24 real minutes. F5 makes it 30× faster.
- **Announce, don't nag.** The clock only sends `time_changed` when the minute on
  the clock changes, not every frame. That's all the phone needs, and it stays
  cheap.
- **The sun's path is a curve.** The sun's height follows a sine curve: 0° at
  sunrise, rising to 65° around midday, back to 0° at sunset, and below the
  horizon at night. Its direction turns from east to west through the day, and
  the light is pointed from there toward the ground.
- **Blending between moments.** Instead of a formula for every color, there's a
  short table of moments (night, dawn, morning, midday, afternoon, sunset,
  night). Any time in between mixes the two nearest moments, so changes are
  smooth.
- **Some things are costly.** Redrawing the sky takes real work for the
  computer, so it's only updated once per game minute. The sun moves every frame
  because that's cheap.
- **Stopping time in tests.** Tests that need an exact time set
  `time_speed = 0` first, so the clock can't move while they check it.

## Job 6: Needs and sleep

- **Needs are numbers that drain with game time.** Every time the clock moves,
  hunger and energy drop by their rate × the game hours that passed. Because
  it's game time, fast time (F5) or sleeping drains them faster too. That's why
  the test can fast-forward 5 hours and know exactly what they should be.
- **Rates are settings.** `hunger_per_hour`, `energy_per_hour` and the others
  sit at the top of `game_state.gd`, so you can change how hard the game is
  without touching the logic.
- **Needs affect each other.** Starving doubles how fast she tires. Being
  sleepy slows her walking. Running out of energy makes her pass out.
- **States.** Asleep and awake are two *states*. While asleep, the rules change:
  energy goes up instead of down, time runs fast, clicks are ignored, and a key
  wakes her. `sleep_changed` tells everyone (the phone, the shade, her model)
  when the state switches.
- **Clamping** keeps a number inside its limits. Needs are clamped between 0
  and 100, so eating can't overfill her and draining can't go negative.
- **Blinking on a timer.** The phone keeps a little clock of its own and
  redraws only when the blink flips on or off, not every frame.

## Job 7: Interactions

- **Groups** are labels you can give nodes, so you can find them all at once.
  Every `Interactable` joins the `interactables` group. Each physics step, the
  player asks for the whole group, measures how far each one is, and focuses
  the nearest one in reach. That's the one whose sign shows and that E uses.
- **One thing, many uses.** An `Interactable` doesn't know what it does. It
  only marks a spot and sends a `used` signal. The chop bar connects that signal
  to "open the menu", the basin to "wash bowls", and the house door to "go to
  bed". A new thing to use is one more Interactable and one connection.
- **Resources are data you edit in the Inspector.** Each dish is a `Food`
  resource: a name, a price, how filling it is, and two colors. The menu board
  draws whatever dishes are in the chop bar's `menu` list, so you can change a
  price or add a dish without touching code.
- **Pausing.** `get_tree().paused = true` freezes everything: the clock, the
  people, and physics. Nodes whose *process mode* is set to Always keep going
  (the menu board, the phone, and the speech bubbles), so the menu works while
  the world waits for you.
- **2D drawings that follow 3D things.** The signs, speech bubbles, and
  "Eating waakye..." bar are drawn in 2D, which is crisp and easy to style.
  Every frame, `unproject_position()` works out where a 3D spot (like Maame
  Esi's head) shows on the screen, and the drawing moves there.
- **Busy for a while.** Eating and washing are *activities*. Like sleep, they
  make time run faster, and their effect is spread over the game minutes they
  take: a 30-minute meal gives back half its hunger after 15 minutes. That's why
  the test can check her hunger at any moment.
- **Paying by mobile money** goes through `GameState.pay()`, which returns false
  and changes nothing if there isn't enough. It also announces the payment, so
  the phone can show it as a text message. The shop never touches the phone.
- **Making a pose from rotations.** To sit, her hips drop 0.43 m, her thighs
  swing forward 86° to lie level along the bench, and her knees bend back 86°
  so her shins hang straight down. Rotations add up along the skeleton (hips,
  spine, chest, arm), so when her body leans toward the table, her arm angles
  have to make up for that lean.
- **Breaking it on purpose (again).** We made `pay()` take money even when
  there wasn't enough. Six checks failed, and the balance went down to
  -GH₵20.00, so the tests really do guard the "not enough money" rule.

## Job 8: First hustle

- **Attaching things to bones.** The headpan isn't part of her model. It's a
  separate prop inside a `BoneAttachment3D`, a node that follows one bone of the
  skeleton, here her head. Wherever the animation moves her head, the pan goes
  too. The same trick will put things in her hands later.
- **Deadlines in game time.** When she picks up a load, it's stamped with when
  it's due: `GameState.now()` plus its time limit. Minutes left is due minus
  now, and handing it over after that pays half. Because it's game time, F4
  (skip an hour) makes her late, just as wandering off would.
- **Picking at random.** Madam Serwaa's next load uses `pick_random()` twice:
  once on the list of goods, and once on the group of delivery spots. Adding a
  new destination is just placing another `DeliverySpot`; the market finds it
  through the group.
- **An arrow at the edge of the screen.** The guide arrow works out where the
  destination shows on the screen. If that's off the screen, it slides back
  along the line from the screen's middle until it's just inside the edge, and
  turns to point along that line.
- **One rule, many reasons.** "Can she sleep?" used to have one answer: not if
  she isn't tired. Now a load on her head is another reason, so
  `sleep_refused` carries the reason as text, and the phone shows whichever it
  is.
- **Testing a whole day quickly.** The day test doesn't walk anywhere. It jumps
  her between places and moves the clock on by the time each walk would take.
  It still uses the real market, delivery spots, chop bar, and bed, so a broken
  rule anywhere shows up. When we made handing over a load pay nothing, the day
  ended on GH₵45 (down from GH₵100) and the test failed.

## Job 9: Rent, saving, and a living town

- **Saving to a file.** A saved game is just text. `save_game()` puts
  everything that matters (money, day, time, needs, rent) into a dictionary of
  names and values and writes it as JSON, a common text format for exactly
  that, to `user://save.json`. `user://` is a folder Godot gives each game for
  its own files (on a Mac, inside `~/Library/Application Support/Godot/`).
  Loading reads the text back and checks it before trusting it. A missing,
  broken, or wrong-version file is ignored, and the game starts fresh.
- **A weekly schedule.** Rent day is just a number, `next_rent_day`. Each time
  the clock moves, `_check_rent()` asks "is it past 08:00 on rent day?" If so,
  it charges the rent and moves rent day on by 7. It's a loop rather than a
  single check, so skipping two weeks at once charges both.
- **Routines with `await`.** Each townsperson's day is written as a list of
  steps: come out of the door, `await` walking to the station, `await` the
  trotro, stay away a while, come back. `await` pauses just that one function
  until what it's waiting for happens (they arrive, a timer runs out), while
  the rest of the game carries on. Everyone's routine runs at the same time.
  `walk_to()` hands back the `arrived` signal, which is what makes
  `await person.walk_to(spot)` possible.
- **Stopping in time.** A vehicle going at speed `v` that slows down by `a`
  metres per second, every second, needs `v² ÷ 2a` metres to stop. The trotro
  uses that twice: to start braking at the right moment so its door stops at
  the station, and to look far enough ahead for people in the road. Without the
  second, it saw them too late at full speed.
- **Freed at the end of the frame.** `queue_free()` doesn't remove a node
  straight away. It waits until the end of the frame. In the full test run, a
  new town started while the last test's town was still waiting to go, so the
  football pitch found the *old* player and never noticed the real one kick
  its ball. The test passed alone and failed in the full run, which is the
  clue to look for. Now the pitch looks for her again once the one it has is
  gone.

## After Job 9: names on hover, smaller bubbles, and a market that closes

- **Pointing with the mouse.** To find what's under the mouse, the game shoots
  a ray (an invisible straight line) from the camera through the mouse's spot
  on the screen, and asks the physics engine what it hits first. The hit is
  one small part, like a wall's collision shape, so the code walks up the
  scene tree from it (parent, grandparent, ...) until it finds the `Building`
  it belongs to. Clicking to walk uses the same trick.
- **Show it only when it's wanted.** A name over every building all the time
  is clutter, especially when the name is painted on already. Showing it only
  while you point at something keeps the screen clear but the information one
  move away. The same goes for speech: chatter is background, so it gets a
  small bubble, while words meant for her get a normal one.
- **Staggered times.** The sellers don't all vanish at 18:00. Seller number
  `i` leaves at 18:00 + 3 × `i` minutes, so they go one by one, the way a real
  market empties. Every minute, the market checks each seller against her own
  times. That also means skipping the clock (sleeping, F4) can't leave anyone
  in the wrong place.
- **Swapping a prop for an actor.** A seller at her stall is a `Vendor`, who
  can't walk. To walk her home, at the moment she disappears, a `Townsperson`
  dressed exactly like her appears on the same spot and walks off. You never
  see the swap, a trick games use all the time.

## Skills: the training college, the school, and work

- **One script, many jobs.** Teaching, sewing, and minding the kiosk follow the
  same rules: you need the skill, there are set hours and a daily limit, she
  takes up a pose, works for a while, and gets paid. So one script,
  `SkilledJob`, has those rules, and each job is that script with different
  settings in the Inspector (the skill, the hours, the pay, the pose, what the
  boss says). A new skilled job is a new node, not new code.
- **Signals for the special touches.** `SkilledJob` sends `started` and
  `finished`. The school listens and sits the pupils down; the market spins the
  sewing machine's wheels; the kiosk sends Auntie Dede to the bank. The job
  doesn't need to know about any of that.
- **Days of the week from a day number.** Day 1 is a Monday, so the weekday is
  the day number counted round in sevens: `posmod(day - 1, 7) + 1` gives 1
  (Monday) to 7 (Sunday). `posmod` is like `%`, but it never goes negative.
- **Keeping old saves working.** The saved game now has her courses and
  certificates, so its version number went up to 2. Loading still accepts
  version 1 and fills in the new parts as empty, so a game saved before the
  college still loads.
- **A ray can't see a shape it starts inside.** In the first try, she minded
  the kiosk from inside it, and stayed hidden: the see-through check looks along
  lines from her toward the camera, and a line starting inside the kiosk's
  solid box never "hits" it, so the kiosk never faded. Sitting outside on
  Auntie Dede's stool fixed it, and that's how MoMo agents really work anyway.

## Job 15: The menu on her phone, saving anywhere, and the title screen

- **A menu that belongs to the world.** Instead of a plain box, the game's menu
  is on her phone, the same Nokia-style phone that shows her money. Game
  makers call this a *diegetic* menu: something the character herself could
  be looking at. The phone already had a screen, a pixel font, and keys, so the
  menu just needed a new kind of screen (a list with the picked item lit up)
  and keys that do something.
- **One way in for every kind of input.** The phone's keys can be clicked, and
  the keyboard can stand in for them (arrows, Enter, Esc). Both end up calling
  the same `press("down")` or `press("select")`, so the menu only has to
  understand one thing. `Phone.key_for()` turns a keyboard key into the phone
  key it stands for.
- **Saving what the scene knows.** `GameState` doesn't know where she's
  standing (that's the Player node's job), so the player writes her spot and
  facing into `GameState` every step, and the save takes them from there. On
  loading, `Player.place()` puts her back, and the camera snaps to her.
- **Starting afresh by reloading.** Loading a save mid-game, or starting a new
  one, reloads the whole town scene, so every townsperson, stall, and timer
  starts clean. A flag in the autoload (`GameState.start_with`) survives the
  reload and tells the new scene what to do: autoloads aren't part of the
  scene, so they stay put when it reloads.
- **Pausing, and what keeps running.** While the menu is open, the game is
  paused (`get_tree().paused`). Only nodes set to keep going (process mode
  Always), like the HUD with the phone and its menu, still work. That's why the
  clock, the townspeople, and the trotro all freeze while you read the phone.

