# Gold Coast: AI game dev prompt

> **Current job: Job 17, "On itch.io"**, in phase two: online (details in
> section 8). Phase one (Jobs 1–9 and skills), Job 15, and Job 16 are done.
> The itch.io account and the first upload are done too.

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

Building colors, picked from the village pictures in `blender/buildings/reference/`:

| Name | Hex | Use |
|---|---|---|
| `wall_mud` | `#926C47` | mud-brown walls |
| `wall_pink` | `#C96E84` | pink painted walls |
| `wall_olive` | `#8F8A62` | olive painted walls |
| `wall_band` | `#5A3A28` | dark band along the bottom of walls |
| `plinth_dark` | `#3E2B1C` | raised earth plinths |
| `plinth_light` | `#BA9D7A` | cement plinths, sills, and ledges |
| `zinc_light` | `#D6D4CE` | corrugated zinc roofs (light stripes) |
| `zinc_dark` | `#8F8C86` | corrugated zinc roofs (dark stripes) |
| `tile_red` | `#B0453A` | red tile and sheet roofs |
| `tile_terracotta` | `#AD6149` | terracotta tile roofs |
| `thatch_gold` | `#BA932E` | fresh thatch |
| `thatch_tan` | `#C8B364` | pale thatch |
| `thatch_brown` | `#A46E44` | old thatch |
| `wood_dark` | `#5A3220` | doors, frames, shutters, awnings |
| `wood_light` | `#9A6C38` | posts, counters, door panels |
| `bar_green` | `#2D4A3A` | window bars |
| `patch_brick` | `#8A5A45` | brick showing through peeling plaster |

The mobile money phone (an old Nokia 1100 style):

| Name | Hex | Use |
|---|---|---|
| `phone_body` | `#2B3340` | the dark blue-grey body |
| `phone_edge` | `#4A5568` | its rim |
| `phone_bezel` | `#12161D` | the black frame around the screen |
| `phone_key` | `#C3CAD3` | rubber keys |
| `phone_key_edge` | `#7F8897` | key outlines |
| `phone_print` | `#1E2530` | numbers printed on the keys |
| `phone_logo` | `#AEB6C2` | the brand name |
| `phone_light` | `#E8ECF1` | the flashlight on top |
| `lcd_background` | `#A3B38A` | the green-grey screen |
| `lcd_glow` | `#CBE39B` | the screen with its backlight on |
| `lcd_pixel` | `#1E2A1A` | the dark dots on the screen |

The light through the day (blended in `scenes/world/lighting.gd`):

| Name | Hex | Use |
|---|---|---|
| `sun_dawn` | `#FFA86B` | the rising sun |
| `sun_noon` | `#FFF3DC` | the midday sun |
| `sun_dusk` | `#FF8547` | the setting sun |
| `moon_light` | `#8DA6D8` | moonlight |
| `sky_horizon_dawn` | `#F0B089` | the horizon at sunrise and sunset |
| `sky_top_night` | `#0B1430` | the night sky overhead |
| `sky_horizon_night` | `#1F2A4A` | the night sky at the horizon |
| `ground_night` | `#24180F` | past the edge of the map at night |

Chop bar food, kitchenware, and pop-up signs (Job 7):

| Name | Hex | Use |
|---|---|---|
| `waakye_brown` | `#74392C` | waakye (rice and beans cooked with sorghum leaves) |
| `shito_black` | `#2E1A12` | shito, the black pepper sauce |
| `banku_white` | `#EDE6D2` | banku and fufu |
| `tilapia_grey` | `#7F857C` | grilled tilapia |
| `light_soup` | `#D0602F` | light soup |
| `kenkey_beige` | `#DCCFA5` | kenkey, groundnuts |
| `fried_fish` | `#9A6232` | fried fish |
| `kelewele_orange` | `#DB8A2C` | kelewele (spicy fried plantain) |
| `sachet_blue` | `#B8DDF0` | pure water sachets |
| `enamel_white` | `#F2F0EA` | enamel bowls |
| `enamel_rim` | `#2E5AA6` | the blue rim of enamel bowls |
| `aluminium` | `#B9BDC1` | cooking pots and the washing basin |
| `paper` | `#FBF6EA` | speech bubbles |
| `wash_water` | `#6E9FB4` | soapy washing-up water |

**Building style** (from those pictures): chunky houses on raised plinths with
front steps, a dark band along the bottom of the walls, deep roof overhangs
(corrugated zinc, clay tiles, or thatch with a ragged edge), wooden doors with
panels, barred windows with shutters or awnings, verandas on posts, and patches
of peeling plaster. Flat colors, simple shapes.

## 4. Current state (updated 2026-10-25, after Jobs 1–9, the first character, and the Blender buildings)
- **Job 1 is done.** Pressing Play opens `scenes/main/main.tscn`: a sunlit
  80 × 80 m patch of laterite with one road, and the player character you walk
  with WASD or the arrow keys, seen from a fixed isometric camera.
- **Job 2 is done.** Five solid buildings stand on the far side of the road
  (−Z, the upper right on screen), all placed with one reusable scene:
  - Compound House, Provisions Store, Chop Bar, Apartment Block, and Mobile
    Money kiosk
  - The front of each building's base sits at z = −7.0, doors facing the road
  - At the end of the row stands an "AKWAABA!" billboard in Ghana's flag colors
  - The cross street from the original plan is postponed: there's still one road
- **The buildings are real Blender models (Job 12, done early for buildings).**
  - `blender/scripts/build_buildings.py` builds all seven (the five in the
    row, plus the training college and the school) in the village style
    (section 3) and exports `gold-coast/art/models/buildings/<name>.glb`. Each
    building is one entry in its `BUILDINGS` list. `camera_side` puts the side
    windows on the -X side, for a building the game turns to face +X (the
    school).
  - Each model has parts named `Base` (plinth and steps), `Walls`, `Details`,
    and `Roof`, plus a `Collision-convcolonly` box. Godot's importer turns
    anything ending in `-convcolonly` into an invisible solid shape.
  - `blender/buildings/buildings_preview.png` shows all seven.
- **Job 3 is done.** Money is in Ghana cedis, shown on an old-phone mobile money
  screen:
  - The `GameState` autoload (`autoload/game_state.gd`) owns the money. It's
    counted in pesewas (100 = GH₵1) and starts at 10,000 (GH₵100.00). It has a
    `money_changed(new_amount)` signal, `add_money()`, `spend_money() -> bool`
    (false and no change if you can't afford it), and `reset()`.
  - `Format.cedis(pesewas)` (`scripts/format.gd`) gives text like `GH₵1,234.50`.
  - `scenes/ui/hud.tscn` (a CanvasLayer in `main.tscn`) puts
    `scenes/ui/phone.tscn` (`Phone`) in the bottom-left corner.
  - The phone is a Nokia 1100-style handset drawn in code, with a "CHALE" brand
    (a made-up name instead of the real logo), a flashlight, nav keys, and a
    12-key keypad. Its green LCD shows MOBILE MONEY / BALANCE / the amount, in
    its own 5 × 7 pixel font, which has ₵. The backlight flashes when money
    changes.
  - The HUD updates from the signal, not by checking every frame.
  - Debug builds only: F2 adds GH₵10, and F3 spends GH₵10 (Input Map actions
    `debug_add_money`, `debug_spend_money`).
- **Job 4 is done, plus camera and mouse controls I asked for.**
  - **See-through buildings:** `scenes/world/see_through.gd` (`SeeThrough`, in
    `main.tscn`) casts lines of sight each physics step from the player's feet,
    middle, and head toward the camera. Any building whose walls (layer 1) or
    roof copy (`RoofOccluder`, layer 2: blocks the view, never the player) is in
    the way fades to 70% see-through via `Building.fade`, which sets each mesh's
    `transparency`, so no material copies are needed.
  - **Camera** (`IsoCamera`):
    - edge scrolling (mouse within 24 px of the window's edge; only while the
      mouse is inside the window), kept within 38 m of the map's middle
    - zoom (orthographic size 8–50) with the mouse wheel, a trackpad pinch or
      two-finger scroll, or `=` and `-`
    - after sliding away it stops following; WASD or Space (`recenter_camera`)
      brings it back
    - zoomed out, it backs off and stretches the sun's shadow distance to match
  - **Click to move:** a left click (`move_to_click`) on the ground calls
    `Player.walk_to()`, which asks the navigation map for a path and walks its
    corners, measuring flat along the ground. Movement keys cancel it. A gold ring
    (`scenes/effects/move_marker.tscn`) marks the spot. The phone blocks clicks.
  - **Walkable area:** `WalkableArea` (a NavigationRegion3D with
    `scenes/world/walkable_area.gd`) is baked at start-up from the static
    colliders in the `navigation_source` group (Ground, Buildings, Billboard).
    Baking is limited to y −1 to 2.5 so roofs aren't walkable, with agent radius
    0.5. Its paths float about 0.5 m above the ground.
- **Job 5 is done.** Time passes, and the light follows it:
  - **Clock** (in `GameState`):
    - `day` (from 1) and `minutes` since midnight, starting on day 1 at 07:00
    - `time_speed` in game minutes per real second (1 = a game hour per real
      minute)
    - `time_changed(day, minutes)`, sent at most once per game minute
    - `advance(game_minutes)` and `set_time(day, minutes)`
    - `Format.clock(minutes)` gives `07:00`; `Format.weekday(day)` gives `MON`
      (day 1 is a Monday)
  - **Lighting** (`Lighting`, `scenes/world/lighting.gd`):
    - follows `GameState.minutes` every frame
    - the sun rises in the east (+X) at 06:00, peaks at 65° in the south (+Z)
      around 12:15, and sets in the west at 18:30
    - colors and strengths blend between "moments" in `MOMENTS`
    - at night the sun turns off and a blue `Moon` light (strength 0.45) takes
      over
    - the sky only redraws once per game minute
    - in the editor, its `time_of_day` slider previews any time
  - **Phone:** shows the time in its top bar (between the signal and battery
    icons), then the day (`MON DAY 1`), MOBILE MONEY, and the balance.
  - **Debug builds only:** F4 skips ahead an hour (`debug_skip_hour`), and F5
    turns fast time (30×) on and off (`debug_fast_time`).
- **Job 6 is done, plus sleep.** She gets hungry and tired, and can sleep:
  - **Needs** (in `GameState`): `hunger` and `energy` from 100 (full) to 0.
    - Settings: `hunger_per_hour` 6, `energy_per_hour` 4,
      `walking_energy_per_hour` +2 (the player sets `GameState.is_walking` each
      step), and `starving_energy_multiplier` 2 (when hunger is 0).
    - They drain with game time inside `advance()`.
    - `needs_changed` is sent when a need changes by a whole point.
    - `set_needs()` sets them directly.
  - **Sleep** (in `GameState`):
    - `sleep()` works only when energy is below 90; otherwise it sends
      `sleep_refused`.
    - While asleep, time runs at `sleep_time_speed` (60 = an hour per second),
      energy gains 12.5 an hour, and hunger drains at half speed. She wakes by
      herself when energy is full.
    - At 0 energy she passes out (`passed_out`), and `wake_up()` refuses until
      her energy is back to 25.
    - `sleep_changed(asleep)` is sent on both falling asleep and waking.
  - **Player:**
    - Z (`sleep`) sleeps or wakes her, and a movement key wakes her.
    - Clicks are ignored while she's asleep.
    - Below 25 energy she walks at 70% speed (`sleepy_speed`).
    - `PlayerModel` lies her down on her back with a bobbing "Z z z" label
      (`lying()` gives 0 to 1).
  - **HUD:** a `SleepShade` dims the screen while she sleeps.
  - **Phone:**
    - In place of a Nokia's signal and battery bars, it has a food bar (left)
      and an energy bar (right), each 8 segments that widen toward the top,
      with a bowl and a bolt icon. Low needs (below 25) blink.
    - The title line shows SLEEPING... or PASSED OUT!, then Z TO SLEEP, then
      HUNGRY!, then MOBILE MONEY, whichever comes first.
    - `show_message()` shows short notes like NOT SLEEPY.
  - **Debug builds only:** F6 (`debug_fill_needs`) fills both needs.
- **Job 7 is done: interactions, the chop bar, and home.** Things you can use,
  and a first taste of the daily hustle:
  - **Interactables** (`scenes/interactions/interactable.gd`, `Interactable`):
    a Marker3D marking where she stands to use something (she faces its -Z),
    in the `interactables` group. Settings: `prompt` (like "Buy food"), `reach`
    (2 m), `click_targets`, and a `used(user)` signal for the owner to connect.
    - Each physics step the player focuses the nearest one in reach, and its
      sign (`InteractionPrompt`: an E key and the prompt) floats above it.
      E (`interact`) uses it.
    - Clicking a click target (a ray on layers 1 and 2, so a whole building
      counts) walks her over and uses it when she arrives. Pointing at one
      shows its sign with a mouse instead of the E key, and a hand pointer
      (`Player.point_at()`).
  - **Activities** (in `GameState`): `start_activity(name, game_minutes,
    real_seconds, hunger_gain)` keeps her busy while time runs faster, gives a
    meal's hunger back bit by bit, and sends `activity_changed` and
    `activity_finished(name, completed)`. Passing out cuts it short.
    `GameState.now()` is the time in minutes since the game began.
    `Player.act_at(spot, pose, then)` walks her to a spot, takes up a pose (an
    animation), and calls `then`. She gets up once she's awake and not busy.
  - **Mobile money** (in `GameState`): `pay(amount, payee) -> bool` and
    `receive(amount, payer)`, with `payment_sent`, `payment_failed`, and
    `payment_received`. The HUD turns each into a text message on the phone
    (`Phone.show_sms()`, up to 4 lines of 14 characters), which buzzes and
    beeps "SMS" in Morse code, a tone generated in code.
  - **Maame Esi's chop bar** (`scenes/places/chop_bar_shop.tscn`,
    `ChopBarShop`, at the Chop Bar): a roadside food stall (`FoodCounter`),
    Maame Esi, a table with benches (`ChopTable`), and a wash basin (`WashBasin`).
    - Maame Esi (`scenes/people/vendor.tscn`, `Vendor`) is the player's model
      in her own colors. She calls out as you walk up, turns to look at you, and
      talks in a `SpeechBubble`.
    - E at the stall, or a click on the building or stall, opens the
      `MenuBoard` (a painted board, `scenes/ui/menu_board.gd`) and pauses the
      game with `get_tree().paused`. The menu, phone, HUD, and speech bubbles
      have `process_mode` Always.
    - The 6 dishes are `Food` resources (`scripts/food.gd`) in the shop's
      `menu`:

      | Dish | Price | Hunger |
      |---|---|---|
      | waakye | GH₵25 | +45 |
      | banku & tilapia | GH₵60 | +70 |
      | fufu & light soup | GH₵45 | +60 |
      | kenkey & fish | GH₵30 | +50 |
      | kelewele | GH₵10 | +20 |
      | pure water | GH₵1 | +5 |

      Prices she can't afford are painted red. Maame Esi talks from the board's
      top strip while it's open.
    - Controls: the arrow keys (or W/S) and Enter (or E), or the mouse. Esc,
      the X, or a click outside closes it.
    - Paying sends her to the table. She sits and eats (the `eat` animation,
      the bowl on the table, "Eating waakye..." with a bar over her head) for 3
      real seconds while the clock runs the meal's minutes. Hunger comes back
      bit by bit, then "+45 food" floats up (`FloatingText`).
    - With too little money, nothing changes. The phone says PAYMENT FAILED /
      NEED GH₵25.00 / BAL / GET A HUSTLE!, and Maame Esi offers work. Above 95
      hunger she won't sell.
  - **Washing bowls:** E at the basin. An hour of washing (3 real seconds, the
    `wash` animation) pays GH₵20.00 by mobile money, once a game day.
  - **Home** (`scenes/places/home.tscn`, `Home`, at the Compound House):
    - E at the door, or a click on the house, puts her to bed when her energy
      is below 98 (`bed_sleepy_below`); the street needs below 90.
    - She fades indoors, "Z z z" floats over the door, and energy refills at 20
      an hour (`bed_energy_per_hour`) instead of 12.5. The phone says SWEET
      DREAMS, and she comes back out when she wakes.
    - Sleeping outside with Z, mosquitoes wake her after 4 hours
      (`mosquito_hours`) with a MOSQUITOES! text.
  - **Character:** two new animations: `eat` (sitting on a bench, eating with
    her right hand) and `wash` (bent over a basin, scrubbing).
  - **UI helpers:**
    - `WorldLabel` (`scenes/ui/world_label.gd`) is 2D drawing that floats over
      a spot in the 3D world (using `Camera3D.unproject_position()`). The
      prompt, speech bubble, activity bar, and floating text extend it.
    - `CediText` (`scripts/cedi_text.gd`) draws ₵ as a C with a line through it,
      because Godot's default font has no ₵.
  - **Palette:** shared materials are kept on the scene tree (as metadata), not
    in a static variable, because a static variable made Godot report leaks
    when the game closed.
- **Job 8 is done: the first hustle, carrying loads like a kayayo.**
  - **The market** (`scenes/places/market.tscn`, `Market`, across the road at
    (−2, 0, 12)): three `MarketStall`s (a produce table with an umbrella behind
    the seller) with their sellers (`Vendor`s). Madam Serwaa, the third,
    hires kayayei. The market is open from 06:00 to 18:00.
  - **Loads** (`scripts/delivery.gd`, `Delivery`): the goods, the place, the
    receiver, the pay, the time limit, and when it's due.
    - `GameState.pick_up(load)`, `deliver_load()` (full pay in time, half
      if late, by mobile money from SERWAA), and `give_back_load()`.
    - `GameState.delivery` is the load she's carrying, and `load_changed` and
      `load_dropped` announce changes. Passing out drops the load.
    - Carrying costs 3 extra energy an hour (`carrying_energy_per_hour`), and
      she walks at 85% speed (`Player.carry_speed`).
    - Z is refused with a load on her head: `sleep_refused` now carries the
      reason, "DELIVER IT!" or "NOT SLEEPY".
  - **Places to deliver to** (`scenes/interactions/delivery_spot.gd`,
    `DeliverySpot`, an Interactable under `DeliverySpots` in `main.tscn`):

    | Place | Pay | Time limit |
    |---|---|---|
    | the Chop Bar | GH₵10 | 22 min |
    | the Apartment Block | GH₵10 | 22 min |
    | the MoMo kiosk | GH₵12 | 25 min |
    | the trotro station (since Job 9; it was a signpost) | GH₵12 | 25 min |
    | the Provisions Store | GH₵14 | 28 min |
    | the Compound House | GH₵18 | 34 min |

    The time limits are about 1.5 times the walk at carrying speed.
    - Each spot switches on only while her load is going there. Then a
      pulsing gold ring marks it, a `GuideMarker` arrow bobs over it or waits
      at the screen's edge pointing the way (with the distance), and the
      receiver thanks her from their doorway (or tells her off if she's late).
  - **Interaction rules:** Interactables can be switched off (`enabled`).
    While she carries a load, only those with `works_while_carrying` (the
    destination, and Madam Serwaa's stall to give it back) can be used
    (`Player.can_use()`).
  - **Phone:** while carrying, the day line shows TO STORE and the title shows
    28 MIN LEFT (LATE! HURRY once it's late). LOAD DROPPED! arrives if she
    passes out.
  - **Character:** the headpan (`HeadPan`, on a cloth ring) rides on her head
    bone through a `BoneAttachment3D`. Two new animations steady it with her
    right hand: `carry` (walking) and `carry_idle`.
  - **See-through:** `SeeThrough` also fades anything in the `see_through` group
    that has a `fade` setting. Market umbrellas use it, with a view-only canopy
    copy on layer 2.
  - **Sellers** don't call out to her while she's carrying a load.
- **Job 9 is done: rent, saving, and a living town.**
  - **Rent** (in `GameState`): GH₵140 (`RENT`) every Monday at 08:00
    (`RENT_TIME`), starting on day 8 (`FIRST_RENT_DAY`), paid to LANDLADY by
    mobile money (the usual PAYMENT SENT text).
    - At 18:00 the evening before, the phone texts REMINDER / RENT TOMORROW.
    - If she's short, she owes it (`rent_owed`, which adds up week by week).
      `rent_missed` brings RENT DUE! / OWE GH₵140.00 / ROOM LOCKED / PAY
      LANDLADY, and the phone's title shows RENT OWED!.
    - While she owes rent, her room is locked (`is_room_locked()`). If she's in
      bed she's woken, and `sleep(true)` is refused with PAY RENT!.
    - `pay_rent()` pays everything owed if she can afford it.
  - **Auntie Adwoa, the landlady**, is a `Vendor` sitting on a stool by the
    compound house door (vendors have a new `pose` setting).
    - On rent day, if the rent wasn't paid, she says so ("No rent, no room
      o!").
    - While the room is locked, the door's sign says "Pay rent GH₵140.00". E
      pays her and unlocks it ("Thank you, my daughter..."). Without the money,
      it stays locked: "No money, no room o! Go and hustle, then come back."
  - **Saving** (`GameState.save_game()`): going to bed at home saves to
    `user://save.json` (`save_path`) as JSON text. It holds the money, the day
    and time, her needs and sleep, the rent owed, the next rent day, the bowls
    washed, and the day's money in and out (`earned_today`, `spent_today`).
    - The phone sums up the day: GAME SAVED / DAY 3 / IN +GH₵54.00 / OUT
      -GH₵25.00.
    - A load is never saved, because she can't go to bed carrying one.
  - **Loading:** `scenes/main/main.gd` loads the save when the game starts
    (`GameState.load_game()`) and puts her back in bed, asleep. With no save, or
    a broken one, it returns false and changes nothing. F7 (`debug_new_game`,
    debug builds only) deletes the save and starts again.
  - **Townspeople** (`scenes/people/townsperson.gd`, `Townsperson`), in their own
    clothes:
    - Women use the player's model, men `townsman.glb`, and boys
      `schoolboy.glb`. Girls are the woman model, scaled down.
    - They walk paths on the walkable area (`walk_to()` returns a signal to
      `await`), run, sit, and carry headpans. They fade in and out at doors
      (`appear_at()`, `vanish()`) and talk in speech bubbles.
  - **Town life** (`scenes/people/town_life.gd`, `TownLife`, in `main.tscn`):
    each person runs a routine, written step by step with `await`.
    - 6 travellers come out of the apartment block and the compound house,
      wait at the nearest station, ride away, and come back on a later trotro.
    - 3 walkers stroll and chat in Twi and Pidgin ("Chale, the sun dey hot!").
    - 2 chop bar customers order from Maame Esi and eat at the far side of her
      table (`ChopTable.guest_seat`), leaving the player's place free.
    - 3 shoppers haggle at the stalls ("Auntie, reduce it small!").
    - 2 other kayayei carry loads from Madam Serwaa's stall around town.
    - 3 schoolgirls play ampe.
    - They're out from 05:30 to 21:00 (`TownLife.is_daytime()`), and none of
      them changes the game's state.
  - **The trotro** (`scenes/vehicles/trotro.gd`, `Trotro`, an
    `AnimatableBody3D` on physics layer 3) is a minibus built in code:
    - a Ghana-flag stripe, "GOD'S TIME IS THE BEST" on the back, and "SEA NEVER
      DRY" on the side
    - a loaded roof rack, a sliding door, and a two-note horn made in code
    - In the daytime, every 35 to 70 seconds, it drives in from the east end of
      the road (the bottom of the screen) to the west end (the top). It brakes
      so that its door stops at each `TrotroStation`.
    - Its mate hops out, goes round to the back corner, and calls "Circle!
      Circle! Circle!". Passengers get off and on, then he calls "Let's go!
      Driver, move!".
    - It honks and waits for anyone in its lane, including her.
  - **Trotro stations** (`scenes/places/trotro_station.gd`, `TrotroStation`):
    - the big station by the MoMo kiosk, with a bench and a zinc shelter
    - a small TROTRO STOP by the compound house, with just a bench
    - People wait on the bench (`wait_for_trotro()`) or ride to the station
      (`get_off_here()`).
    - Madam Serwaa's loads now go to the big station.
  - **Children** (`scenes/people/street_football.gd`, `StreetFootball`): four
    children in yellow-and-brown school uniforms play football between stone
    goalposts on the open ground, passing and shooting ("Goal!"). If she walks
    into the ball, she kicks it, and a child calls "Ei! Sister can play!".
  - **Animals:** goats (`Goat`) and chickens (`Chicken`), built from boxes in
    code, wander their patches, bleating "Meeeh!" and clucking "Kok-ko-kooo!".
  - **The market** is bigger:
    - seven stalls in two rows (fish, tomatoes, yams, Madam Serwaa's, cloth,
      pepper, plantain) on a packed-earth floor
    - two sellers on stools with basins (oranges, groundnuts)
  - **Street:**
    - wooden power poles (`PowerLine`) with sagging wires, a tangle of old
      wire, and orange street lamps that come on from 18:15 to 06:15
    - hand-painted signs (`Signboard`): "GOD IS GREAT ENTERPRISE", "MAAME ESI'S
      CHOP BAR", "MOMO · CASH IN · CASH OUT", and "REMOVE BY ORDER" painted on
      a wall
    - open gutters along the road
  - **Character:** three new animations, `run`, `sit`, and `ampe`. The character
    script also builds the townsman and the schoolboy.
- **Changes after Job 9 (2026-10-26), as I asked:**
  - **Names on hover:** no more names floating over the buildings, because most
    have theirs painted on. Pointing at a building with the mouse shows a
    `Nameplate` over its roof (kept on the screen): what it is (`building_name`)
    and its own name underneath (`subtitle`). `BuildingNames` (in `main.tscn`)
    casts the mouse's ray each physics step, but not while a menu is open, the
    mouse is off the window, or it's over the phone.

    | Building | Shows |
    |---|---|
    | Compound House | Your home · Auntie Adwoa's |
    | Provisions Store | God Is Great Enterprise |
    | Chop Bar | Maame Esi's Chop Bar |
    | Apartment Block | Adom Court |
    | Mobile Money Vendor | MoMo Cash In, Cash Out |

  - **Smaller speech bubbles:** passing remarks use a small bubble (9 px text, no
    name): townspeople, the mate, children, goats and chickens, sellers calling
    out (`Vendor.call_out()`), and Maame Esi and the sellers answering
    townspeople. What people say to her (`Vendor.say()`, receivers, the
    landlady) uses the normal bubble, a bit smaller than before (13 px text).
    `SpeechBubble.say(line, as_remark)` picks the size.
  - **The market's sign:** "NKABOM MARKET" (Nkabom is Twi for unity) on a green
    `Signboard` standing on two posts at the market's back edge, instead of a
    floating "Market". Signboards have a new `post_height` setting: posts that
    are solid, and a sign that fades like a building when it hides her.
  - **The market closes at night:**
    - From 18:00 the sellers pack up one by one, 3 minutes apart (Madam Serwaa
      last, at 18:24). Their stalls close (`MarketStall.closed`: bare tables
      and folded umbrellas), and their `belongings` (stools, basins, Madam
      Serwaa's load pile) go with them (`Vendor.leave()`).
    - With the townspeople on, each one walks home with her goods in a headpan
      (the `Market.seller_left` signal). It's a `Townsperson` dressed like her,
      appearing just where she stood.
    - They're back from 05:30 (`Vendor.come_back()`), all set up by 06:00.
    - While Madam Serwaa's away, her stall can't be used.
    - Shoppers and other kayayei come only while the market is open, and walk
      home when it closes. Anyone walking home is gone within an hour of game
      time, even if the clock races on while she sleeps.
- **Skills, the last part of phase one (2026-10-26).** She can learn a skill at
  a training college and use it to earn more:
  - **Her pin:** a gold pin with Ghana's black star floats over her head
    (`PlayerMarker`, made by `PlayerModel`), so she stands out from the
    townspeople. It hides while she's indoors, asleep, or busy (her activity
    bar shows then), and floats higher over a headpan.
  - **Courses and skills** (in `GameState`):
    - A `Course` (`scripts/course.gd`) has an id (also the skill's name), a
      title, what its certificate is for, a short phone title, its fees, and
      how many classes it takes.
    - `enroll(course)` pays the fees to COLLEGE by mobile money (false, and no
      change, if she can't afford it or is already on it).
    - `attend_class(course)` counts a class. After the last one, the course id
      goes into `skills` and `skill_learned` fires; the phone texts
      CERTIFICATE! / TEACHING / SANKOFA / COLLEGE.
    - `courses`, `class_days` (one class a day), and `skills` are saved. The
      save is version 2 now; version 1 saves still load.
    - `did_job(job)` and `jobs_done_today(job)` count the day's work.
    - `weekday()` gives 1 (Monday) to 7 (Sunday).
  - **Sankofa Training College** (`scenes/places/training_college.tscn`,
    `TrainingCollege`, south-east across the road, at (27, 0, 12.5)):
    - The registrar, Madam Afriyie, is at her desk Monday to Saturday, 07:00
      to 17:30.
    - E at her desk (or a click on the college) opens a `CourseBoard`: the
      chop bar's painted board, reused (`MenuBoard` now takes any kind of row).
      It shows each course's fees, or how far she's got.
    - Choosing a course enrolls her. Choosing it again (08:00 to 15:00) sends
      her in to its next class: two game hours indoors (`Player.indoors`), one
      class a day per course.

    | Course | Fees | Classes | Lets her |
    |---|---|---|---|
    | Mobile Money Agent | GH₵80 | 1 | mind Auntie Dede's MoMo kiosk |
    | Dressmaking | GH₵200 | 2 | sew kaba and slit at the market |
    | Teaching Certificate | GH₵350 | 3 | teach at the school |

  - **Skilled work** (`scenes/interactions/skilled_job.gd`, `SkilledJob`, an
    Interactable): one script for all three jobs, set up in the Inspector.
    - It takes a skill, a `boss` who explains why there's no work (no skill,
      the wrong time, enough for today), the days and hours work can start, a
      daily limit, the pose she holds, the time it takes, and the pay.
    - It walks her to its spot, poses her, and runs an activity, then pays by
      mobile money with a "+GH₵" floating up. Its `started` and `finished`
      signals let each place add its own touches.
  - **Nkabom M/A Basic School** (`scenes/places/school.tscn`, `School`,
    south-west beside the football pitch). The classroom block faces +X, onto
    its yard:
    - In the yard: the Ghana flag (`Flagpole`, waving), a mango tree
      (`ShadeTree`, which fades when it hides her), a blackboard, and two low
      benches (`SchoolBench`). The ampe girls play there now.
    - Mrs. Ofori, the headmistress, is in Monday to Friday, 07:00 to 16:00.
    - With the teaching certificate, a lesson at the blackboard (08:00 to
      13:00 starts, three a day) takes a game hour and pays GH₵50. Eight
      pupils sit on the benches, greet her ("Gooood mor-ning, Ma-dam!"), chime
      in, then run off to play.
  - **Dressmaking:** a treadle `SewingMachine` by Sister Abena's cloth stall.
    Sewing a kaba and slit takes two game hours and pays GH₵80, twice a day,
    starting 06:00 to 16:00. The machine's wheels turn while she sews, and it
    goes home with Sister Abena at night.
  - **Mobile money agent:** Auntie Dede (`scenes/places/momo_kiosk.tscn`,
    `MomoKiosk`) sits on her stool beside the kiosk, 07:00 to 20:00.
    - A shift takes two game hours and pays GH₵45, twice a day, starting 07:00
      to 18:00.
    - Auntie Dede walks off to the bank by trotro, the player takes her stool,
      and customers come up.
  - **Animations:** `teach` (pointing at the board, a book at her waist) and
    `sew` (leaning over the machine, feet on the treadle).
  - **Also:** Madam Serwaa's loads go to the school (GH₵16, 32 min) and the
    college (GH₵16, 30 min) too. The goats moved to the far south, and
    townspeople come and go from the school gate and the college door.
- **Job 15 is done: the menu on her phone, saving anywhere, and the title screen.**
  - **The phone's menu** (`scenes/ui/pause_menu.gd`, `PauseMenu`, in the HUD):
    - M or Esc (the `phone_menu` action), or a click on the phone's middle
      key, opens it.
    - She holds the phone up (`Phone.hold_up()`: bigger, beside the middle of
      the screen), the game dims behind it, and the game pauses.
    - The menu has RESUME, SAVE GAME, LOAD GAME, NEW GAME, and HOW TO PLAY (8
      pages: `PauseMenu.HOW_TO_PLAY`).
    - Keys: the scroll key or arrow keys (or W and S) move, the middle key or
      Enter (or E) picks, and C, Esc, or M goes back. A click beside the phone
      closes it.
  - **The phone** (`Phone`) can now show:
    - a menu (`show_menu()`): a list with the picked item lit up, a scroll bar,
      and SELECT over the middle key, like an old Nokia's
    - a page (`show_page()`): a title, three lines, and the middle key's label
      (OK, YES, NEXT)
    - Its keys work, clicked or through `press()`, and they light up when
      pressed. Its font gained "/".
  - **Saving anywhere:**
    - The save (version 3, now `user://gold_coast_save.json`) also holds where
      she's standing and which way she faces, and the load on her head with
      when it's due (`Delivery.to_save()` and `from_save()`).
    - The player keeps `GameState.player_position` and `player_facing` up to
      date, and `Player.place()` puts her back.
    - `GameState.save_refusal()` says why not ("SHE IS BUSY", "SHE IS
      ASLEEP"); saving is fine in her bed.
    - Loading puts her back on the spot (`GameState.spot_loaded`), and the
      camera jumps to her (`IsoCamera.snap()`).
    - The market's next offer isn't saved: it makes a new one.
  - **The title screen** (`scenes/ui/title_screen.gd`, `TitleScreen`, in the
    HUD): AKWAABA! / GOLD COAST / HUSTLE · LEARN · RISE on a sign in Ghana's
    colors, the saved game's day, time, and money (`GameState.peek_save()`),
    and the start menu on her phone, held up: CONTINUE (if there's a save),
    NEW GAME, and HOW TO PLAY.
  - **Starting:** `main.gd` shows the title screen when the game starts.
    Loading or starting a new game from the menu reloads the scene, and
    `GameState.start_with` ("new" or "load") skips the title screen then. F7
    skips it too. In tests, where the main scene isn't the game's own scene,
    `restart()` does it in place instead.
- **Job 16 is done: the web version.** On 2026-10-30 I uploaded it to itch.io,
  and it plays in the browser.
  - **Exporting:** `export_presets.cfg` has two presets.
    - "Web" builds the game into `build/web/`, without threads (so any web
      host works) and without the tests. Git ignores `build/`, and
      `build/.gdignore` stops Godot importing the built files (or they'd end
      up inside the next build).
    - "Web check" is a test build: its `web_check` feature makes it start with
      `tests/web_check.tscn` instead of the title screen
      (`application/run/main_scene.web_check`).
  - **The web's look:** browsers draw with the Compatibility renderer (WebGL
    2). `Lighting.compatibility_environment()` gives it a linear tone map,
    exposure 0.94, contrast 0.86, and saturation 1.15, so daylight isn't
    washed out. It's used only with that renderer: the Mac's look is
    unchanged.
  - **Speed:**
    - `CharacterParts.merge()` draws each character in one part instead of
      one per color, keeping the colors as vertex colors. Gold jewelry stays a
      shiny part of its own on the Mac; with the web renderer it's merged too.
    - Townspeople and vendors only animate while they're on the screen
      (`Townsperson._animate_only_on_screen()`).
    - With the web renderer on the Mac, the town went from 30–62 fps to
      87–124. Smaller shadows and less MSAA made no difference, so they're
      unchanged.
  - **F8** shows the frame rate, in builds made for testing.
  - **Trying it:** `tests/serve_web.sh` builds both versions and serves them on
    this computer. `tests/web_check.sh` runs the web check in Chrome with no
    window. The web check shows its results on the page, too.
  - The phone's font gained "+" (the bedtime GAME SAVED text showed "IN ?GH₵").
- **After Job 16: a new trotro, an Uber, and fixes from playing it.**
  - **Vehicles from Blender** (`blender/scripts/build_vehicles.py`, from the
    drawings in `blender/vehicles/`):
    - `art/models/vehicles/trotro.glb`: a classic cream minibus with a blue
      stripe, a raised roof, four side windows with the seats showing, a
      sliding door on its right, and square headlights. About 2,000 triangles.
    - `art/models/vehicles/uber_car.glb`: a silver Toyota Yaris hatchback.
    - Each body is its side outline pushed out to its width, cut into bands of
      color, and rounded with a bevel. The wheels (`Wheel...`) and the
      trotro's `Door` are separate, so they can turn and slide. Empty markers
      (`SideSlogan`, `BackSlogan`, `DestinationCard`, `StickerFront`,
      `StickerBack`) face outward where the game writes on them.
    - The palette gained `TROTRO_CREAM`, `TROTRO_BLUE`, `CAR_GLASS`,
      `CAR_SILVER`, `CAR_TRIM`, and `TYRE_BLACK` (at the end of the list,
      because scenes store colors by number).
  - **Driving** (`scenes/vehicles/vehicle.gd`, `Vehicle`): what every vehicle
    does, written once. It comes in at `start_x`, makes its trip, and leaves
    at `end_x`; then it comes again after `gap_seconds`, but not late at
    night. It speeds up and brakes smoothly, turns its wheels, dips when it
    brakes, and honks and waits for anyone in its lane. It writes on its model
    with `_write()`.
  - `Trotro` now extends `Vehicle`: its stations, mate, sliding door
    (`is_door_open()`), and sayings are its own. Its door is at
    `DOOR` (1.45, 0, -0.6).
  - **The Uber** (`scenes/vehicles/car.gd`, `Car`, the `Uber` node): it drives
    east in the south lane (z = 1.9, the trotro's is z = -1.9), from x = -46
    to 46, every 25 to 50 seconds. It has Uber stickers front and back and a
    higher horn.
  - **Sitting in a slit:** the skirt's skin weights changed. Below her hips,
    her legs carry all of it, so when she sits it covers her lap and her shins
    down to her ankles. The character script has sitting previews (25 to 27).
  - **The trotro station's sign:** `Signpost.board_width()` makes the board as
    wide as its words, and the station stands it clear of the shelter's roof
    (`TrotroStation.ROOF`).
  - **The school:** the mango tree moved into the yard (local (10.4, 0, -0.5)),
    out of the line between the school's sign and the camera.
- **First character is done (Job 13, done early).** A young woman in a kaba and
  slit with a duku, gold jewelry, and sandals, in a slim, flat-color style.
  - She's built by `blender/scripts/build_player_character.py`, which exports
    `gold-coast/art/models/characters/player_character.glb` (about 3,000
    triangles, 19 bones with Godot humanoid names, and looping `idle` and `walk`
    animations, plus `eat` and `wash` from Job 7 and `carry` and `carry_idle`
    from Job 8). The script reads her colors from `palette.gd`.
  - `blender/characters/player_character_preview.png` shows her from every side.
  - `scenes/player/player_model.tscn` (`PlayerModel`) plays idle or walk and
    scales the walk to match her speed. She walks at 1.8 m/s; the walk
    animation was made for 1.7 m/s.
- **Settings:** the display name is "Gold Coast". The renderer is
  Forward+ (Metal on Apple Silicon) and the physics engine is Jolt. Physics
  interpolation is on (smooth movement on 120 Hz screens), and 4× MSAA smooths
  edges. The UI stretch mode is `canvas_items`. The Input Map actions are
  `move_forward`, `move_back`, `move_left`, `move_right`, `zoom_in`,
  `zoom_out`, `recenter_camera`, `move_to_click`, `sleep` (Z), `interact` (E),
  `phone_menu` (M and Esc), and the debug keys F2 to F8. Menus use Godot's
  built-in `ui_*` actions. Web builds use the Compatibility renderer
  (`rendering_method.web`).
- **Colors:** `art/palette/palette.gd` (`Palette`) holds every color,
  including the sun, sky, character, and vehicle colors. `art/palette/palette_mesh.gd`
  (`PaletteMesh`) is a mesh whose color you pick from a dropdown of palette names.
- **Scenes:**
  - `scenes/world/` holds `lighting.tscn` (the sun, moon, and sky, following
    the clock), `ground.tscn` (ground with invisible walls at the edge), and
    `road.tscn` (built in code from its settings; runs along X)
  - `scenes/buildings/` holds two scenes:
    - `building.tscn` (`Building`), used for all five buildings: it shows a
      `.glb` model (the `model` setting). Pointing at it shows its
      `building_name` and `subtitle` (see `BuildingNames`). The model brings its
      own collision.
    - `placeholder_building.tscn` (`PlaceholderBuilding`), not used in the main
      scene right now but kept for quickly blocking out new buildings. It has
      `@export` settings for name, size, wall color, and roof style, and its
      script builds box walls with matching collision, a door or hatch,
      windows, a roof, and a name label.
    - Both face +Z
  - `scenes/props/` holds `billboard.tscn` (`Billboard`): a headline and tagline,
    a red/gold/green board with black stars and two spotlights. The posts are
    solid, and you can walk under the board.
  - `scenes/player/` holds `player.tscn`, whose `Model` is `player_model.tscn`.
    The old capsule, `player_placeholder_model.tscn`, is kept as a fallback.
  - `scenes/camera/` holds `iso_camera.tscn`
  - `scenes/interactions/` holds `interactable.gd`
  - `scenes/people/` holds `vendor.tscn` (people who run shops)
  - `scenes/places/` holds `chop_bar_shop.tscn` and `home.tscn` (what you can
    do at a building; each sits at its building's position), `market.tscn`,
    and the skills places: `training_college.tscn`, `school.tscn`, and
    `momo_kiosk.tscn`
  - `scenes/props/` also holds the chop bar's props (`food_bowl.gd`,
    `food_counter.gd`, `chop_table.gd`, `wash_basin.gd`), Job 8's
    (`head_pan.gd`, `market_stall.gd`, `signpost.gd`), and the skills props
    (`blackboard.gd`, `school_bench.gd`, `flagpole.gd`, `shade_tree.gd`,
    `desk.gd`, `sewing_machine.gd`)
  - `scenes/interactions/` also holds `skilled_job.gd`, and `scenes/ui/` holds
    `course_board.gd`, `player_marker.gd`, `pause_menu.gd`, and `title_screen.gd`
  - `scenes/interactions/` also holds `delivery_spot.gd`
  - `scenes/ui/` also holds the menu board and the floating labels, including
    `guide_marker.gd`, `nameplate.gd`, and `building_names.gd` (names on hover)
  - `scenes/main/main.gd` loads the saved game when the game starts
  - `scenes/people/` also holds `townsperson.gd`, `town_life.gd`,
    `street_football.gd`, `goat.gd`, and `chicken.gd` (Job 9)
  - `scenes/vehicles/` holds `vehicle.gd` (`Vehicle`, driving along the road),
    `trotro.gd`, and `car.gd` (`Car`, the Uber). `scenes/places/` also holds
    `trotro_station.gd`
  - `scenes/props/` also holds `power_line.gd` and `signboard.gd`
- **Shared helpers:** `scripts/shapes.gd` (`Shapes`) makes palette-colored boxes,
  cylinders, and balls, solid boxes, and floating name labels.
  `scripts/format.gd` (`Format`) turns money and times into text,
  `scripts/cedi_text.gd` (`CediText`) draws ₵, `scripts/food.gd` (`Food`)
  describes a dish, `scripts/delivery.gd` (`Delivery`) describes a load, and
  `scripts/character_parts.gd` (`CharacterParts`) merges a character's parts.
- **Editor scripts:** the palette mesh, ground, road, lighting, camera,
  building, and billboard scripts are `@tool` scripts, so they also run in the
  editor and the scene looks right before you press Play. The pieces they make
  are "internal" children: hidden in the scene tree and never saved. Job 9's
  trotro, stations, power line, signboards, football pitch, goats, and chickens
  work the same way.
- **Tests:** `tests/test_runner.tscn` runs every `tests/test_*.gd` file (or only
  the files named after `--`). `tests/test_case.gd` (`TestCase`) is the base
  class, with `check()`, `wait_physics_frames()`, `press_action()`,
  `teleport()`, `wait_until()`, `click_at()`, and `move_mouse_to()`. There are
  404 checks so far, all passing. `tests/web_check.gd` is different: it runs
  in a browser, in the "Web check" build (see Commands). The runner saves to `user://test_save.json`,
  never your real save. It also switches the townspeople off
  (`GameState.town_life = false`) so they don't get in the way;
  `test_town.gd` switches them back on. Tests that need exact times stop the clock with
  `GameState.time_speed = 0.0` (`GameState.reset()` starts it again). In the
  hidden (headless) test window, mouse clicks must be sent with
  `get_viewport().push_input(event, true)`, because that window is 0 × 0 and
  Godot would otherwise move the click off-screen.
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
5. **Commit when the tests pass**, with one commit per job (e.g. `Job 1: walk around`),
   on a branch of its own (like `job-15`). It's merged into main when I say so.
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
$GODOT --headless --path . res://tests/test_runner.tscn -- test_chop_bar.gd  # only the files you name
$GODOT --path .                                          # play the game in a window
$GODOT --path . --editor                                 # open the editor
$GODOT --path . --write-movie /tmp/shots/frame.png --quit-after 60  # save 60 frames as images to check the look
$GODOT --path . --rendering-method gl_compatibility      # play with the web's renderer, on the Mac

mkdir -p build/web && $GODOT --headless --path . --export-release "Web" build/web/index.html  # build the web version
sh tests/serve_web.sh   # build both web versions and serve them: the game at http://127.0.0.1:8060/web/,
                        # the web check at http://127.0.0.1:8060/web_check/ (Ctrl+C stops it)
sh tests/web_check.sh   # the web check in Chrome with no window (exit code 0 = it passed)
```
The AI's sandbox can't run the last two: it stops programs opening network
connections, even on this computer. Run them in your own Terminal window.
Any `ERROR` or `SCRIPT ERROR` line in the output counts as a failure, even if
the tests pass. After adding a new `class_name` script from outside the editor,
run `--import` before anything else, or other scripts can't find the class.

Blender scripts run inside Blender's own Python, not any other Python
environment. Run them from the repo root (`kayayo/`). To rebuild the buildings
after changing their script or their palette colors:
```bash
/Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup \
  --python blender/scripts/build_buildings.py -- \
  --palette gold-coast/art/palette/palette.gd \
  --out gold-coast/art/models/buildings \
  --blend blender/buildings/buildings.blend \
  --renders /tmp/building_renders
```
It prints each building's base size and front edge; use those numbers to place
a new or resized building so its front lines up with the others (Blender's −y is
Godot's +z).

To rebuild the player character after changing her script or her palette colors:
```bash
/Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup \
  --python blender/scripts/build_player_character.py -- \
  --palette gold-coast/art/palette/palette.gd \
  --glb gold-coast/art/models/characters/player_character.glb \
  --blend blender/characters/player_character.blend \
  --renders /tmp/player_character_renders \
  --townsman gold-coast/art/models/characters/townsman.glb \
  --schoolboy gold-coast/art/models/characters/schoolboy.glb
```
The last two lines also rebuild the townsman and the schoolboy, who share her
skeleton and animations. Its preview pictures 25 to 27 show her sitting on a
stool: her slit must cover her legs down to her ankles. Then run Godot's `--import` and the tests. If you change her walk, re-measure its
speed and update `walk_animation_speed` in `player_model.gd`, or her feet will
slide.

To rebuild the trotro and the Uber after changing their script or their
palette colors:
```bash
/Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup \
  --python blender/scripts/build_vehicles.py -- \
  --palette gold-coast/art/palette/palette.gd \
  --out gold-coast/art/models/vehicles \
  --blend blender/vehicles/vehicles.blend \
  --renders /tmp/vehicle_renders
```
It prints each one's size, triangles, and parts. If you rename a part or a
marker, change the scripts that look for it (`Vehicle`, `Trotro`, `Car`).

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
- **₵ symbol (the cedi sign in GH₵):** Godot's default font (Open Sans) has no
  ₵. The phone uses its own pixel font. Anything else that draws prices uses
  `CediText`, which draws ₵ as a C with a line through it. Label3D can't, so
  keep ₵ out of 3D labels and out of speech (people say "twenty cedis").
- **Static variables:** a `static var` in a `class_name` script makes Godot
  report that script (and whatever it holds) as leaked when the game closes.
  Keep shared things somewhere else, like the scene tree's metadata (see
  `Palette.material()`).
- **Pausing:** `get_tree().paused = true` stops every node whose
  `process_mode` is Inherit or Pausable, including the `GameState` clock.
  Anything that must keep working (menus, the HUD, speech bubbles) needs
  `process_mode` Always. Tests still advance while paused, because the scene
  tree's `process_frame` and `physics_frame` signals keep coming. Always unpause
  when a test ends.
- **Typed arrays:** assigning a plain `[...]` array from a variable to an
  `Array[Food]` property fails; build it as a typed array first. A literal
  assigned straight to a typed property is fine.
- **Scripts that hang:** a `-s` script with an error after an `await` never
  quits. macOS has no `timeout` command, so wrap Godot runs in
  `perl -e 'alarm 120; exec @ARGV' $GODOT ...`.
- **Rotations in `.tscn` files:** `Transform3D(...)` lists the basis row by row,
  not axis by axis.
  - Turned +90° about Y: `Transform3D(0, 0, 1, 0, 1, 0, -1, 0, 0, x, y, z)`
  - Turned −90° about Y: `Transform3D(0, 0, -1, 0, 1, 0, 1, 0, 0, x, y, z)`
  - Getting this backwards made the trotro drive backwards with its door on the
    wrong side.
- **Low obstacles:** the walkable area treats anything up to 0.25 m higher than
  the cell below (`agent_max_climb`) as a step. A low collider, like a 0.34 m
  basin, can end up inside the walkable area, so paths go straight over it. Make
  obstacle colliders about 1 m tall.
- **JSON:** `JSON.parse_string()` prints an error when the text isn't valid
  JSON. To check a file quietly, use `JSON.new().parse()` and look at what it
  returns.
- **Routines with `await`:** if a node is freed while one of its functions is
  waiting, Godot quietly drops the rest of that function. Wait with
  `get_tree().create_timer(seconds, false)` so routines pause with the game.
- **Finding the player:** a freed scene stays in the tree until the end of the
  frame, so a new scene starting in the same frame (as in tests) can find the old
  player with `get_first_node_in_group("player")`. Look her up again whenever the
  one you have is no longer valid (`is_instance_valid()`), as `Vendor` and
  `StreetFootball` do.
- **Names that hide built-ins:** don't name a variable `load` or `sign`. They
  hide Godot's built-in `load()` and `sign()`.
- **Physics layers:** 1 is walls and solid things, 2 is view-only (roof and
  umbrella copies that block the view but never the player), and 3 is vehicles.
  Her collision mask includes layer 3, so she bumps into the trotro, but clicks
  and the see-through checks ignore it.
- **Rays from inside a shape:** a ray that starts inside a collision shape
  doesn't hit it. So if she stands inside a building (the kiosk, say), the
  see-through check never fades it, and she's hidden. Put work spots outside
  buildings.
- **Labels over hidden people:** a CanvasLayer (like a speech bubble's) still
  draws when the 3D node above it is hidden. So a vendor who's gone home
  mustn't talk: `Vendor.say()` does nothing while she's away.
- **`bind()` and `unbind()` order:** `f.bind(false).unbind(1)` drops the
  signal's argument, then adds `false`. `f.unbind(1).bind(false)` drops the
  `false` instead.
- **Sounds at quit:** quitting while a sound plays (like the phone's text beep)
  makes Godot report it as leaked. The test runner waits a moment before it
  quits.
- **Reloading in tests:** in a test, `get_tree().reload_current_scene()` would
  reload the test runner, not the town, so `main.gd`'s `restart()` only
  reloads when the main scene is the game's own scene.
- **Loading starts the clock:** `GameState.load_game()` resets first, so the
  clock runs again (`time_speed` 1). A test that wants it stopped stops it
  again after loading.
- **The web renderer and animated characters:** the Compatibility renderer
  bends (skins) each part of an animated character on its own, every frame, so
  a character in seven colored parts costs seven times as much as one in a
  single part. Keep characters to one or two parts (`CharacterParts.merge()`),
  and don't animate what's off the screen. Forward+ doesn't have this problem,
  so it only shows up with the web renderer.
- **The web renderer's look:** it has no ambient occlusion (SSAO), and its
  tone mapping looks different, so the same settings come out washed out. To
  see it on the Mac, run with `--rendering-method gl_compatibility`.
- **The AI's sandbox:** it can't download from GitHub's release files or from
  godotengine.org, so export templates are installed in the editor (Editor >
  Manage Export Templates). It also can't serve the web build or start
  Chrome, so the browser checks run in your own Terminal.
- **The first export** after installing the templates printed a few "leaked"
  errors. Every export after that was clean.
- **The editor's update check:** the editor's network mode is Online (needed
  to download the templates), so every editor start, `--import` included,
  checks for a new Godot. In the AI's sandbox that prints "Connection to remote
  host failed!" errors. They aren't the project's; to stop them, set Editor
  Settings > Network > Connection > Network Mode back to Offline.
- **Skin weights and sitting:** a point of a skinned mesh goes where its bones'
  shares (weights) put it, on average. The slit gave her hips a fifth of its
  lower part, so when she sat and her knees went 42 cm forward, the bottom of
  the slit stopped 8 cm short, and her shins came out in front of it. Clothes
  that hang over a joint should go with the bones below it.
- **Writing that fits:** a Label3D doesn't wrap or shrink to fit anything. To
  fit a board or a vehicle, measure the words with
  `ThemeDB.fallback_font.get_string_size()` (Label3D's own font), as
  `Signpost.board_width()` and `Vehicle._write()` do.

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
    buildings/                buildings.blend and buildings_preview.png; reference/ (not in git)
    vehicles/                 vehicles.blend and vehicles_preview.png; the drawings they follow (not in git)
  gold-coast/                 the Godot project (res://)
    project.godot
    autoload/                 global singletons, e.g. game_state.gd (money, time, needs, rent, saving)
    scenes/
      main/                   main.tscn, the entry point that assembles the world
      player/                 player.tscn + player.gd
      camera/                 iso_camera.tscn + iso_camera.gd
      world/                  ground, roads, environment and lighting
      buildings/              placeholder_building.tscn (later: real buildings)
      props/                  billboard.tscn, power_line.gd (poles and street lamps), signboard.gd, later trees
      interactions/           interactable.gd (things you can use with E or a click)
      people/                 vendor.tscn (people who run shops), townsperson.gd, town_life.gd (their routines), children, animals
      vehicles/               vehicle.gd (driving), trotro.gd, car.gd (the Uber), later taxis
      places/                 chop_bar_shop.tscn, home.tscn, market.tscn, trotro_station.gd, training_college.tscn,
                              school.tscn, momo_kiosk.tscn: what happens at each place
      ui/                     hud.tscn, phone.tscn, menu_board.gd, floating labels, later more menus
      effects/                move_marker.tscn (the ring where you click), later other effects
    scripts/                  shared helpers not tied to one scene, e.g. shapes.gd, format.gd, food.gd, delivery.gd, course.gd
    art/
      palette/                palette.gd, the single source of colors
      models/                 .glb files exported from Blender: characters/, buildings/, vehicles/
      materials/
    tests/                    test_runner.tscn + test_*.gd; web_check.gd/.tscn/.sh and serve_web.sh (the web version's checks)
    export_presets.cfg        the Web and Web check export settings
    build/                    web builds (not in git, except build/.gdignore)
```
Keep each scene and its script in the same folder. Use `snake_case` for file
and folder names.

## 7. Roadmap
Each job takes one session and ends with a test. Mark a job `[x]` when it's done.

**Phase one, part 1: Prototype** (done)
- [x] **Job 1: Walk around.** Ground, a road, a capsule player with
  camera-relative WASD, a fixed isometric camera that follows the player, and
  sun and environment lighting. *Test:* holding W moves the player up the screen.
- [x] **Job 2: Neighborhood.** Five placeholder buildings with collision on the
  far side of the road, all made from one reusable building scene, plus an
  "AKWAABA!" billboard at the end of the row. (The cross street is postponed.)
  *Test:* walking into any building stops the player.
- [x] **Job 3: Money.** A `GameState` autoload that owns money (starting at
  GH₵100) and an old Nokia 1100-style phone that shows the mobile money
  balance, `GH₵100.00`. *Test:* the formatting and earn/spend tests pass, and
  the phone updates when money changes.

**Phase one, part 2: First gameplay loop** (done)
- [x] **Job 4: See-through buildings.** Buildings between the camera and the
  player fade out. Also added: edge scrolling, zoom, and click to move with
  pathfinding. *Test:* the player stays visible behind every building.
- [x] **Job 5: Day clock.** Time passes, the sun moves, and the phone shows the
  day and time. *Test:* a fast-forwarded day reaches the right clock times and sun angles.
- [x] **Job 6: Needs.** Hunger and energy drain over time and show on the phone,
  plus sleep: sleepy below 25 energy, sleeping with Z, and passing out at 0.
  *Test:* the drain rates match their settings.
- [x] **Job 7: Interactions.** A "Press E" (or click) interaction system.
  Maame Esi's chop bar with a painted menu board, mobile money payments with
  texts on the phone, sitting down to eat, and washing bowls for GH₵20 a day.
  A bed at home that beats the street (where mosquitoes wake you). *Test:*
  buying food with too little money fails cleanly.
- [x] **Job 8: First hustle.** Carrying loads on her head like a kayayo: Madam
  Serwaa's market across the road hires her, and she has a time limit to carry
  each load to one of six places (in time: full pay by mobile money; late:
  half). Washing bowls at the chop bar stays as a small daily job. *Test:* a
  simulated full day (earn, eat, sleep) ends with more money and needs above
  zero.
- [x] **Job 9: Rent and saving.** GH₵140 rent every Monday to Auntie Adwoa,
  the landlady (her room locks until it's paid), and saving when she goes to
  bed, with the day's money in and out on the phone. Also a living town: a
  trotro and its mate running between two stations, townspeople with daily
  routines (travellers, shoppers, customers, other kayayei), children playing
  football and ampe, goats and chickens, a bigger market, street lamps, and
  painted signs. *Test:* saving and loading restores money, time, and needs.

- [x] **Skills (the last part of phase one).** A gold star pin over her head;
  Sankofa Training College (courses, fees, one class a day, certificates);
  teaching at Nkabom M/A Basic School; sewing kaba and slit at the market;
  minding the MoMo kiosk. *Test:* she can't do the work without the
  certificate, and the certificate takes the fees and every class.

**Phase two: Online** (current, agreed on 2026-10-27). Anyone can play from an
itch.io link in their browser, with one save (plus the automatic save in bed)
that can follow them to any computer as a cloud save.
- [x] **Job 15: Save button and title screen.** A title screen (Continue, New
  game, How to play) and the game's menu, both on her phone (Resume, Save,
  Load, New game, How to play), and saving anywhere she's free, with her spot
  and her load. *Test:* saving on the street and loading puts her back on the
  spot, with her load, at the saved time.
- [x] **Job 16: Web build.** A Web export (without threads), the daylight colors
  fixed for the web renderer, and a speed pass to 60 fps on an ordinary laptop.
  *Test:* it builds and starts with no errors, and it plays, saves, and
  continues after a reload in Chrome, Safari, and Firefox.
- [ ] **Job 17: On itch.io.** A private, password-protected page first, with
  screenshots and the controls, and the steps for uploading new versions.
  *Test:* on another computer: play, save, close the browser, and continue.
- [ ] **Job 18: Cloud saves.** Sign in, and your save follows you to any
  computer: every save is also uploaded, and Continue offers the newer save. It
  still works without the internet. Then the itch.io page goes public.
  *Test:* save on one computer and continue on another.

**Later: Make it look like Ghana**
- [ ] **Job 10: Color bible.** Built from one reference image I choose, with a
  day version and a night version of every color. It replaces the provisional
  palette, and nothing goes into the game without it.
- [ ] **Job 11: Lighting lab.** An in-game debug panel with sliders (sun angle,
  sun color, ambient light, fog, exposure) and presets: harmattan morning,
  midday, golden hour, night, dumsor night (a power cut), and rainy season.
- [x] **Job 12: Blender pipeline** (done early for buildings).
  `blender/scripts/build_buildings.py` builds the buildings (seven now) in the
  village style and exports `.glb` files with their own collision. To fix a model,
  change its line and run the script again; never hand-edit the mesh. Keep
  shapes simple rather than aiming for realism. Still to do in the same style:
  props from the pictures (round thatched huts, fences, trees, palms, banana
  plants).
- [x] **Job 13: Real character** (done early). Built with a Blender script
  instead of AI tools: `blender/scripts/build_player_character.py`. Later
  characters can follow the same pattern, or use concept art → Meshy or Mixamo.
- [ ] **Job 14: Enterable home.** When you step inside, the roof and front wall
  hide. It's the same scene, with no loading screen.

**Later: Living city (to be planned later)**
Pedestrians; trotros and taxis driving routes, with a mate calling out the
stops (Job 9 added townspeople and one trotro route early); traffic jams; cross streets and more neighborhoods; weather and events (harmattan,
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

### Job 3: Money (done)
**Goal:** show the player's money on screen, starting at GH₵100, with one place
in the code that owns it. What was built (with the phone added at my request):
1. **GameState:** `autoload/game_state.gd`, registered as the `GameState`
   autoload. Money is counted in whole pesewas (100 pesewas = GH₵1) so prices
   like GH₵6.50 work without rounding errors: `money: int = 10000`
   (GH₵100.00), a `money_changed(new_amount: int)` signal, `add_money()`,
   `spend_money() -> bool`, and `reset()`.
2. **Formatting:** `scripts/format.gd` with `Format.cedis(pesewas)`: 10000 →
   `GH₵100.00`, 650 → `GH₵6.50`, 123456789 → `GH₵1,234,567.89`, 0 → `GH₵0.00`,
   and -50000 → `-GH₵500.00`.
3. **Phone HUD:** `scenes/ui/hud.tscn` with `scenes/ui/phone.tscn` in the
   bottom-left corner. It's an old Nokia 1100-style phone whose green LCD shows
   the mobile money balance in a pixel font (so ₵ always shows). The
   backlight flashes on every change. It updates from the `money_changed`
   signal, never by checking every frame.
4. **Debug keys:** in debug builds only, F2 adds GH₵10 and F3 spends GH₵10.
5. **Tests:** `tests/test_money.gd`, 19 checks:
   - the formatting cases above
   - spending with enough money, and with too little (returns false; money is
     unchanged)
   - earning, and the signal announcing every new amount
   - the phone showing the balance, being able to draw ₵, and updating
     immediately, including on F2 and F3

**Done when:** the phone shows GH₵100.00 at the start (the ₵ renders properly),
F2 updates it immediately, and the tests pass.

### Job 4: See-through buildings (done)
**Goal:** the player never disappears behind a building. Anything standing
between the camera and her fades out, and fades back when she moves on.
What was built (plus camera and mouse controls I asked for):
1. **Find what's in the way:** each physics step, lines of sight from her feet,
   middle, and head toward the camera (with an orthographic camera they all run
   along its +Z). They hit walls (layer 1) and an invisible copy of each roof
   (layer 2), which the Blender script exports as `RoofOccluder-convcolonly`.
2. **Fade:** buildings in the way fade over 0.2 s to 70% see-through, and back
   when they're clear. They use `GeometryInstance3D.transparency` per mesh, so
   faded buildings never change the others.
3. **Camera:** edge scrolling, zoom (wheel, pinch, two-finger scroll, `=`/`-`),
   and recentering with WASD or Space.
4. **Click to move:** a path from the navigation map, around buildings; a marker
   ring; movement keys take over.
5. **Tests:**
   - `tests/test_see_through.gd`: behind each building it fades and buildings
     off to the side stay solid, then everything turns solid again on the road
   - `tests/test_camera_controls.gd`: the edges, panning and its limit,
     recentering, and zoom with its limits
   - `tests/test_click_to_move.gd`: click, marker, arrival, a path around the
     Chop Bar, and keys cancelling a click

**Done when:** walking behind any building shows her through it, and the tests
pass.

### Job 5: Day clock (done)
**Goal:** time passes in the game: the sun moves across the sky, and the phone
shows the day and time. What was built:
1. **Clock** in `GameState`:
   - `day` and `minutes`, starting on day 1 at 07:00
   - `time_speed`, 1 game minute per real second
   - `time_changed(day, minutes)`, at most once per game minute
   - `advance()` and `set_time()`
2. **Sun and moon:** `Lighting` follows the clock. The sun rises in the east at
   06:00, is highest (65°) around midday in the south, and sets in the west at
   18:30, glowing warm at both ends. At night it switches off and a dim blue moon
   takes over. Colors blend between palette "moments", and there's a
   `time_of_day` preview slider in the editor.
3. **Phone:** the time in the top bar and the day (`MON DAY 1`) above the balance.
4. **Debug keys:** F4 skips an hour; F5 turns fast time (30×) on and off.
5. **Tests:** `tests/test_clock.gd`, 18 checks:
   - the start time, time passing on its own, and a whole fast-forwarded day
     hitting every hour
   - midnight rolling over the day, and at most one announcement per minute
   - clock and weekday text
   - the sun's height at 06:00, 12:00, and 18:00, east-to-west movement, and the
     sun and moon by day and night
   - the phone showing the time and day, and F4

**Done when:** you can watch a whole day go by, the light changes with the
time, and the tests pass.

### Job 6: Needs (done)
**Goal:** she gets hungry and tired as time passes, and you can see it. What
was built (with sleep added at my request: being tired should make her sleepy
and need sleep):
1. **Needs** in `GameState`: hunger and energy from 100 to 0, draining with game
   time. The rates are settings: 6 hunger and 4 energy an hour, +2 energy while
   walking, and twice the energy drain while starving.
2. **Sleep:**
   - Z when energy is below 90; she lies down, the screen dims, and time runs at
     an hour per second. Energy gains 12.5 an hour while hunger drains at half
     speed, and she wakes when rested or when you press a movement key.
   - Below 25 she's sleepy and walks at 70% speed.
   - At 0 she passes out and can't be woken until energy is back to 25.
3. **Phone:** food and energy bars down the screen's edges, styled like a Nokia's
   signal and battery bars, blinking when low, and a status line (HUNGRY!,
   Z TO SLEEP, SLEEPING..., PASSED OUT!, NOT SLEEPY).
4. **Debug keys:** F6 fills both needs.
5. **Tests:** `tests/test_needs.gd`, 22 checks:
   - the set drain rates, walking, starving, staying within 0–100, and
     announcements
   - sleeping (refused when rested, refilling, waking by herself) and passing
     out (and waking only after rest)
   - in the game: slow sleepy walking, Z lying her down and dimming the screen,
     a key waking her, the phone's bars and status lines, and F6

**Done when:** you can watch hunger and energy go down over the day, and the
tests pass.

### Job 7: Interactions (done)
**Goal:** things in the world you can use: walk up to something and press E.
What was built (made extra interactive at my request):
1. **Interaction system:** `Interactable` marks a spot she can use, with a
   prompt, a reach of 2 m, click targets, and a `used` signal. The nearest one
   in reach shows a floating sign ("E  Buy food"), and E uses it. Clicking a
   building walks her there and uses it. Pointing at one shows its sign and a
   hand pointer.
2. **Mobile money:** `GameState.pay()` and `receive()`. Every payment arrives
   on the phone as a text message that buzzes and beeps.
3. **Maame Esi's chop bar:**
   - Maame Esi stands at her roadside stall. She greets you and turns to look at
     you.
   - Her painted menu board pauses the game and lists 6 Ghanaian dishes with
     prices and how filling they are. Prices you can't afford are red.
   - Paying sends her to sit at the table and eat (a new animation), with
     "Eating waakye..." over her head and the clock skipping the meal's time.
   - With too little money, nothing changes: PAYMENT FAILED ... GET A HUSTLE!
     arrives on the phone, and Maame Esi offers work.
4. **First little job:** washing bowls at the basin, an hour for GH₵20, once a
   day (a new animation).
5. **Home:** E at the Compound House door puts her to bed, even when she's
   only a little tired. She rests at 20 an hour instead of 12.5, with
   "Z z z" over the door. Outside, mosquitoes wake her after 4 hours.
6. **Tests** (204 checks in all):
   - `tests/test_interactions.gd`: signs near and far, the nearest one,
     pointing and clicking
   - `tests/test_chop_bar.gd`: the menu and pausing, buying and eating, too
     little money, too full, the mouse, washing bowls once a day
   - `tests/test_home.gd`: bed versus street, going inside, the faster rest,
     clicking home, mosquitoes
   - `tests/test_activities.gd`: activities
   - additions to `test_money.gd` (mobile money) and `test_needs.gd` (bed and
     mosquito rates)

**Done when:** she can buy food at the Chop Bar and sleep in her bed at home,
and the tests pass.

### Job 8: First hustle (done)
**Goal:** a real way to make a living: carry loads on her head like a kayayo (a
head porter), and play one full day: earn, eat, sleep. What was built:
1. **The market:** three stalls with umbrellas and sellers across the road from
   where she starts, open from 06:00 to 18:00. Madam Serwaa hires kayayei.
2. **Carrying a load:**
   - E at her stall, or a click on it, puts a headpan of goods on her head.
     Madam Serwaa says where it goes and by when.
   - She steadies the load with one hand (new `carry` and `carry_idle`
     animations), walks at 85% speed, and tires 3 energy an hour faster.
   - The phone shows TO STORE and 28 MIN LEFT. A gold ring marks the place,
     and an arrow points the way, from the screen's edge if it's off-screen.
   - At the place, E (or a click on the building) hands it over: full pay by
     mobile money in time, half if late. The receiver answers from the
     doorway.
   - E at Madam Serwaa's stall again gives the load back (no pay). Passing out
     drops it (LOAD DROPPED!). She can't sleep or use other things until it's
     delivered.
3. **Six destinations** (`DeliverySpot`s): the five buildings and a new trotro
   stop, paying GH₵10 to GH₵18, with time limits about 1.5 times the walk.
4. **Polish:** market umbrellas fade when they hide her, and sellers don't call
   out to her while she's working.
5. **Tests** (234 checks in all): `tests/test_hustle.gd`, 30 checks:
   - the load rules (in time, late, giving back, one at a time, no sleep with a
     load, dropping it, extra tiredness)
   - in the game: the offer, the headpan and pose, the trader's words, the
     phone, the ring and arrow, other things locked, slower walking, delivering
     in time and late, giving back, click to deliver, closing time, passing out
   - a whole simulated day: 14 loads, two meals at the chop bar, and a night
     in bed take her from GH₵100 to GH₵233, with needs above zero

**Done when:** you can play a whole day of work, food, and sleep, and the tests
pass.

### Job 9: Rent and saving (done)
**Goal:** a reason to save, and a game that remembers. Her room isn't free,
and the day's progress survives quitting. I also asked for a living town: a
trotro running between two stations, people coming out of the buildings to
take it, townspeople buying food, shopping, and carrying loads, children
playing, a bigger market, and more of Ghana. What was built:
1. **Rent:** GH₵140 every Monday at 08:00 (from day 8), paid by mobile money
   to the landlady, Auntie Adwoa, who sits by the compound house door. (This is
   the suggested amount; it's `RENT` in `game_state.gd`.)
   - The phone reminds her at 18:00 the evening before (RENT TOMORROW).
   - If she can't pay: RENT DUE! / ROOM LOCKED. Her room stays locked (no
     sleeping in her bed, and she's woken if she's in it) until she pays at the
     door. Unpaid weeks add up.
2. **Saving:** going to bed at home saves to `user://save.json`, and the phone
   sums up the day (GAME SAVED / DAY / IN / OUT).
3. **Loading:** starting the game continues from the save, in bed. F7 starts a
   new game.
4. **The living town:** townspeople with routines, the trotro and its mate, two
   stations, children playing football and ampe (you can kick their ball),
   goats and chickens, the bigger market, power poles and street lamps, painted
   signs, and gutters (details in section 4).
5. **Tests** (270 checks in all, 292 after the follow-up below):
   - `tests/test_save.gd`, 21 checks:
     - saving and loading (money, time, needs, rent, sleep)
     - missing and broken saves
     - the rent reminder, paying, owing, and the locked room
     - paying at the door, the bedtime summary, and loading back into bed
   - `tests/test_town.gd`, 15 checks:
     - the trotro stopping with its door at both stations, the mate calling,
       and people getting on and off
     - honking and waiting for her
     - a customer eating at the chop bar, and other kayayei carrying loads
     - football (including her kick), ampe, goats, and the street lamps

**Done when:** you can play, sleep, quit, start again, and carry on where you
were, rent comes out every week, and the tests pass.

**Follow-up (2026-10-26), as I asked after playing it:**
1. Buildings' names show only when you point at one: what it is, with its own
   name underneath.
2. Passing remarks (chatter, the mate, animals, sellers calling out) are in
   small bubbles, so they don't cover the screen.
3. The market's name is on a painted sign, "NKABOM MARKET".
4. At night the market is empty: the sellers pack up after 18:00 and walk home
   with their goods, and come back in the morning.
5. Tests: `tests/test_market.gd` (8 checks: packing up one by one, an empty
   market all night, everyone back by 06:00, the sign). There are also new
   checks in `test_buildings.gd` (names on hover), `test_town.gd` (small
   bubbles, walking home), `test_chop_bar.gd`, and `test_hustle.gd`.

### Skills: the training college, the school, and work (done)
**Goal:** a way up from carrying loads. She pays to learn a skill, then uses it
for better-paid work. This was the last part of phase one. What was built (see
section 4 for the details):
1. **Her pin:** a gold star pin over her head, so she stands out in a crowd.
2. **Sankofa Training College:** three courses with fees, classes (two game
   hours, one a day), and a certificate texted to the phone at the end.
3. **Work with the certificates:**
   - teaching at Nkabom M/A Basic School: GH₵50 a lesson, three a day, school days
   - sewing kaba and slit at the market: GH₵80, twice a day
   - minding the MoMo kiosk: GH₵45 a shift, twice a day
4. **New buildings** (the college and the classroom block, from the Blender
   script), new props, and the `teach` and `sew` animations.
5. **Tests** (357 checks in all):
   - `tests/test_skills.gd`: the rules and saving
   - `tests/test_college.gd`: the board, enrolling, classes, certificates, and hours
   - `tests/test_school.gd`: teaching
   - `tests/test_jobs.gd`: sewing and the kiosk
   - `tests/test_player_model.gd`: the pin

**Done when:** she can save up, get a certificate, and earn with it, and the
tests pass.

### Job 15: Save button and title screen (done)
**Goal:** save whenever you like, and pick up from the title screen. Built as
planned below, with the menu on her phone as I asked; the market's next offer
isn't saved (it simply makes a new one). Tests: `tests/test_menu.gd`, 25
checks (382 in all).
1. **A title screen** when the game starts: GOLD COAST, and then:
   - **Continue**, showing the save's day, time, and money (like "Day 5,
     14:20, GH₵230")
   - **New game**, which asks first if there's a save
   - **How to play**: the keys and the mouse
   - Browsers only let a game play sound after the first click, and this
     screen gives them that click.
2. **A pause menu**, opened from a menu key on the phone (on screen, so you can
   click it) or with Esc. In a browser at full screen, Esc is taken by the
   browser, so the on-screen key matters. The menu has Resume, Save game, Load
   game, New game, and How to play, and the game pauses while it's open.
3. **Save anywhere she's free:**
   - The save gains where she's standing and which way she faces, the load on
     her head (with its time left), and the market's next offer.
   - Saving is refused, with a reason, while she's busy (eating, in class,
     teaching) or asleep on the street.
   - The phone texts GAME SAVED, and going to bed still saves too.
4. **Loading** puts her back on her spot, with her load, at the saved time.
   Townspeople pick up their day from that time.
5. **The save file's name** becomes Gold Coast's own (like
   `user://gold_coast_save.json`), so other Godot games in the same browser
   can't mix with it. Older saves still load.
6. **Tests:**
   - saving on the street and loading puts her back on the spot, with her
     load and the time
   - saving while she's busy is refused
   - New game and Load ask first
   - the title screen's Continue shows the save
   - the usual sabotage checks

**Done when:** you can save anywhere she's free, quit, start again, choose
Continue, and carry on from the same spot.

### Job 16: Web build (done)
**Goal:** the game runs well in Chrome, Safari, and Firefox on an ordinary laptop.
Built as planned below. The templates were installed in the editor (the AI's
sandbox blocks their download). The look: a linear tone map with a little less
exposure and contrast and more color, for the web renderer only. The speed:
the characters' parts merged, and only those on the screen animate (fewer
shadows and less MSAA didn't help). With the web renderer on the Mac, the town
went from 30–62 fps to 87–124. Tests: `tests/test_web_ready.gd`, 8 checks (391
in all), and the web check (`tests/web_check.gd`), which runs in a browser.
On 2026-10-30 I uploaded it to itch.io, and it plays in the browser. Saving and
continuing there, on another computer, is Job 17's test.
1. **Templates:** download Godot 4.7.2's export templates, about 1 GB. You can
   do it in the editor (Editor > Manage Export Templates > Download and
   Install), or the AI can fetch them from GitHub if you're happy with that.
2. **Export setup:** a "Web" export preset, without threads. Without threads,
   any ordinary web host works, with no special server settings. One command
   builds it into `gold-coast/build/web/`, which git ignores.
3. **The look:** web builds draw with Godot's Compatibility renderer (WebGL 2),
   and the project switches to it by itself (`rendering_method.web`). A test on
   2026-10-27 showed daylight comes out washed out with it. Fix that for the
   web renderer only, without changing how it looks on the Mac, with before
   and after pictures.
4. **Speed:** that test ran at 41 to 76 fps on an M4 Pro. Measure the frame
   rate in the browser, then trim what's expensive (shadow quality, the street
   lamps' lights, far-away townspeople) until it holds 60 fps on an ordinary
   laptop.
5. **Try it on the Mac:** serve the build from the computer, open it in each
   browser, play, save, reload the page, and continue.
6. **Tests:** the export builds with no errors, the game starts with the web
   renderer with no errors, and a checklist for each browser (it starts, you
   can play, it saves, and it continues after a reload).

**Done when:** it plays smoothly in all three browsers, and saves and continues
there.

**Follow-up (2026-10-28), as I asked after playing it:**
1. The school's sign was hidden behind the mango tree: the tree moved into the
   yard, so the whole sign shows (the sign stays by the road and the flag).
2. The trotro, rebuilt from my drawing in Blender: cream, with a blue stripe,
   a raised roof, and a sliding door. The mate, the stations, and the sayings
   work as before.
3. An Uber: a silver Toyota Yaris from my drawing, driving through town the
   other way. (The other drawings, a sedan and a Ghana taxi, can be added the
   same way.)
4. When a woman sat, her legs came out of her slit: now it covers them, down
   to her ankles.
5. "TROTRO STATION" ran off its sign: the board fits its words now, and stands
   clear of the shelter's roof.
6. Tests: `tests/test_road.gd` (11 checks: the trotro's wheels, door, and
   sayings; the Uber's trip, lane, horn, and stickers; the station signs), and
   new checks in `test_school.gd` (the sign in view) and
   `test_player_model.gd` (sitting in her slit). 404 in all.

### Job 17: On itch.io (current)
**Goal:** a link you can send to anyone.
**Done so far (2026-10-30):** I made the account and the project, as a draft.
The settings: kind of project HTML, the upload `gold-coast/build/gold-coast-web.zip`
(the files of `build/web`, with `index.html` at the top) played in the browser,
a 1152 × 648 viewport, a fullscreen button, and no SharedArrayBuffer (the game
doesn't need it) or mobile option. The page's tagline and description are in
`docs/itch-page.txt`.
1. **The account:** I make a free itch.io account; the AI prepares everything
   to upload.
2. **The page:** the title, a short description, screenshots, the controls, and
   a full-screen button. It's private (with a password) at first, for me and
   friends to try.
3. **Updating it:** the steps (or one script) to rebuild and upload a new
   version after each job.
4. **Tests:** open the link on a different computer, play, save, close the
   browser, open it again, and continue.

**Done when:** the private link works on another computer.

### Job 18: Cloud saves
**Goal:** sign in once, and carry on from any computer.
1. **Decide together first:**
   - the online service: Firebase or Supabase. Both have free plans.
     Firebase's free projects keep running; Supabase's go to sleep after a
     week with nobody using them, until you wake them in its dashboard.
   - how players sign in: an email and a password (they can reset a
     forgotten password), or a save code the game makes (no personal data,
     but losing the code means losing the cloud save)
2. **The service:** I make the free project, following the AI's steps. The game
   only holds its public key. The service's rules make sure each player can
   read and write only their own save.
3. **In the game:**
   - Sign up, Sign in, and Sign out on the title screen and in the pause menu
   - a little cloud on the phone showing whether the save is up to date
4. **Saving:** every save (the Save button and bed) also goes to the cloud.
   Continue fetches the cloud save and uses the newer one, asking if they
   differ.
5. **Offline:** with no internet, the game carries on with the browser's save
   and uploads it later.
6. **Privacy:** only the email (if used) and the save are stored. There's a
   button to delete your cloud save, and a short privacy note on the itch.io
   page.
7. **Tests:**
   - automated, with a pretend service (no internet needed): signing in (and
     failing), uploading, downloading, choosing the newer save, and working
     offline
   - a check on the real service from two computers
8. **Then** the itch.io page goes public.

**Done when:** you can save on one computer and continue on another, and the
tests pass.

## 9. Report format (end of every job)
1. **What I built:** 2–3 sentences
2. **Files:** each new or changed file, with one line on what it does
3. **Try it yourself:** numbered steps in the Godot editor, and what I should see
4. **Test results:** the commands you ran and the pass/fail summary
5. **New concepts:** 2–4 plain-language explanations (also added to
   `docs/learning-notes.md`)
6. **Notes and next:** anything you noticed but didn't do, and the next job
