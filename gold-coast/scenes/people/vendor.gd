class_name Vendor
extends Node3D
## Someone who runs a shop or a stall, like Maame Esi at the chop bar. She's the
## same 3D character as the player, dressed in her own colors. She turns to
## look at the player when they're nearby, calls out as they walk up (but not
## while they're carrying a load: they're busy working), and talks in a speech
## bubble. She faces -Z, like the player. Market sellers go home at night
## (see Market): leave() takes her and her things away, and come_back() brings
## them back.

## Her name, shown on her speech bubble.
@export var person_name := "Maame Esi"
## The colors of her kaba (top), slit (wrap skirt), its trim, and her duku (headwrap).
@export var top_color := Palette.ColorName.PALM_GREEN
@export var skirt_color := Palette.ColorName.KENTE_GOLD
@export var trim_color := Palette.ColorName.DARK_BROWN
@export var headwrap_color := Palette.ColorName.TILE_RED
## What she might call out when the player walks up (one at random).
@export var greetings: Array[String] = ["Akwaaba! Come and chop!", "My sister, come and eat!",
		"Hot waakye dey o!", "Fresh banku, come!"]
## How close the player has to come for her to call out, in metres.
@export var greet_distance := 7.0
## How close the player has to be for her to turn and look at them, in metres.
@export var look_distance := 9.0
## How long before she'll call out to the player again, in seconds.
@export var greet_again_after := 40.0
## The animation she holds: "idle" to stand, or "sit" to sit on a stool.
@export var pose := &"idle"
## Things that come and go with her, like her stool and her basin of oranges.
@export var belongings: Array[Node3D] = []

var _bubble: SpeechBubble
var _here := true
var _player: Node3D
var _player_was_near := false
var _greeted_at := -INF
# The way she faces when nobody's around.
var _rest_angle := 0.0

@onready var _character: Node3D = $Character
@onready var _animation_player: AnimationPlayer = find_child("AnimationPlayer")


func _ready() -> void:
	_rest_angle = rotation.y
	_dress()
	for body: MeshInstance3D in _character.find_children("*", "MeshInstance3D"):
		CharacterParts.merge(body) # one part instead of one per color: much quicker to draw
	var animation := pose if _animation_player.has_animation(pose) else &"idle"
	_animation_player.get_animation(animation).loop_mode = Animation.LOOP_LINEAR
	_animation_player.play(animation)
	_animation_player.seek(randf() * _animation_player.current_animation_length) # don't breathe in time with the player
	Townsperson._animate_only_on_screen(self, _animation_player)
	var layer := CanvasLayer.new()
	layer.process_mode = Node.PROCESS_MODE_ALWAYS # so she can talk while a menu has the game paused
	add_child(layer, false, Node.INTERNAL_MODE_FRONT)
	_bubble = SpeechBubble.new()
	_bubble.anchor = self
	_bubble.height = 2.3
	_bubble.speaker = person_name
	_bubble.visible = false
	layer.add_child(_bubble)


## Says `line` to the player, in a speech bubble over her head (not while
## she's gone home).
func say(line: String) -> void:
	if _here:
		_bubble.say(line)


## Calls out `line` in passing ("Fresh fish, come and buy!"), in a small bubble.
func call_out(line: String) -> void:
	if _here:
		_bubble.say(line, true)


## What she's saying right now ("" if her bubble isn't showing).
func saying() -> String:
	return _bubble.text if _bubble.is_showing() else ""


## Her speech bubble (for tests).
func get_bubble() -> SpeechBubble:
	return _bubble


## Stops talking: her speech bubble fades away.
func hush() -> void:
	_bubble.disappear()


## Whether she's here, rather than gone home for the night.
func is_here() -> bool:
	return _here


## Packs up and goes home: she and her things are gone until she comes back.
func leave() -> void:
	_here = false
	hush()
	visible = false
	for thing in belongings:
		thing.visible = false


## Back at her place, with her things.
func come_back() -> void:
	_here = true
	visible = true
	for thing in belongings:
		thing.visible = true
	_player_was_near = false


func _process(delta: float) -> void:
	if not _here:
		return
	if not is_instance_valid(_player):
		# Find her (again, if the town was reloaded and the old her is gone).
		_player = get_tree().get_first_node_in_group("player") as Node3D
		if _player == null:
			return
	var to_player := _player.global_position - global_position
	var distance := Vector2(to_player.x, to_player.z).length()
	# Turn to look at the player while they're nearby, but not all the way round.
	var goal := _rest_angle
	if distance < look_distance:
		var toward := atan2(-to_player.x, -to_player.z)
		goal = _rest_angle + clampf(wrapf(toward - _rest_angle, -PI, PI), -1.2, 1.2)
	rotation.y = lerp_angle(rotation.y, goal, 1.0 - exp(-4.0 * delta))
	# Call out when they walk up (not every time they wander back and forth).
	var near := distance < greet_distance
	var now := Time.get_ticks_msec() / 1000.0
	var busy := GameState.delivery != null
	if near and not _player_was_near and not busy and now - _greeted_at > greet_again_after and saying() == "":
		call_out(greetings.pick_random())
		_greeted_at = now
	_player_was_near = near


# Her own clothes: swaps the player's cloth colors for hers.
func _dress() -> void:
	var colors := {
		"cloth_cream": top_color, "cloth_maroon": skirt_color, "cloth_ochre": trim_color, "cloth_red": headwrap_color,
	}
	for mesh: MeshInstance3D in _character.find_children("*", "MeshInstance3D"):
		for i in mesh.mesh.get_surface_count():
			var original := mesh.mesh.surface_get_material(i)
			if original != null and colors.has(original.resource_name):
				mesh.set_surface_override_material(i, Palette.material(colors[original.resource_name]))
