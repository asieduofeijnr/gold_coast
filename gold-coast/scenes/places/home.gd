class_name Home
extends Node3D
## Her room in the compound house. Press E at the door (or click the house) to
## go to bed: she goes inside, and "Z z z" floats over the door until she wakes.
## Her own bed is better than the street: she can sleep when she's only a little
## tired, she rests faster, and there are no mosquitoes. Going to bed saves the
## game.
## Auntie Adwoa, the landlady, sits outside. Rent is due every Monday (see
## GameState). If she owes rent, the room is locked: E at the door pays it.
## Place it at the same spot as the Compound House building.

## The Compound House building. Clicking it walks her to the door.
@export var building: Node3D
## Where the "Z z z" floats while she's asleep inside.
@export var zzz_position := Vector3(0.0, 3.0, 4.3)

var _zzz: Label3D

@onready var door: Interactable = $Door
@onready var landlady: Vendor = $Landlady


func _ready() -> void:
	door.click_targets = [building]
	door.used.connect(_go_to_bed)
	GameState.sleep_changed.connect(_on_sleep_changed)
	GameState.needs_changed.connect(_on_needs_changed)
	GameState.rent_missed.connect(_on_rent_missed)
	GameState.rent_paid.connect(_on_rent_paid)
	_zzz = Shapes.name_label("Z z z")
	_zzz.position = zzz_position
	_zzz.no_depth_test = true # show through the roof's overhang
	_zzz.visible = false
	add_child(_zzz, false, Node.INTERNAL_MODE_FRONT)
	_update_door_sign()


func _process(_delta: float) -> void:
	if _zzz.visible:
		_zzz.position.y = zzz_position.y + 0.12 * sin(Time.get_ticks_msec() / 400.0) # bob gently


## Whether the "Z z z" is showing over the door (she's asleep inside).
func is_snoring() -> bool:
	return _zzz.visible


func _go_to_bed(user: Node3D) -> void:
	if GameState.is_room_locked():
		if GameState.pay_rent():
			landlady.say("Thank you, my daughter. Your room is open again.")
		else:
			landlady.say("No money, no room o! Go and hustle, then come back.")
		return
	if not GameState.can_sleep(true):
		GameState.sleep(true) # she isn't tired at all: this just makes the phone say NOT SLEEPY
		return
	(user as Player).act_at(door, &"", _sleep_in_bed)


func _sleep_in_bed() -> void:
	GameState.sleep(true)


func _on_sleep_changed(_asleep: bool) -> void:
	_zzz.visible = GameState.in_bed


func _on_needs_changed(_hunger: float, _energy: float) -> void:
	_update_door_sign()


func _on_rent_missed(_owed: int) -> void:
	landlady.say("Rent day! You owe me a hundred and forty cedis. No rent, no room o!")
	_update_door_sign()


func _on_rent_paid(_amount: int) -> void:
	_update_door_sign()


func _update_door_sign() -> void:
	if GameState.is_room_locked():
		door.prompt = "Pay rent  " + Format.cedis(GameState.rent_owed)
	elif GameState.can_sleep(true):
		door.prompt = "Go to bed"
	else:
		door.prompt = "Home (not sleepy yet)"
