class_name MomoKiosk
extends Node3D
## Auntie Dede's mobile money kiosk. She sits on her stool beside it from 07:00
## to 20:00, doing mobile money for the neighborhood: cash in, cash out, sending
## money. With mobile money agent training from the training college, the
## player can mind it for a two-hour shift (GH₵45, twice a day): Auntie Dede
## goes off to the bank, the player takes her stool, and customers come.
## Place it at the kiosk building's spot.

## When Auntie Dede is at her kiosk, in minutes after midnight.
const OPENS := 7.0 * 60.0
const CLOSES := 20.0 * 60.0
## What customers ask her for.
const CUSTOMER_LINES := ["Cash out fifty cedis, please!", "I want to send money to my mother.",
		"Sell me credit, ten cedis!", "Momo, cash in for me!", "Please, check my balance."]

## The kiosk building. Clicking it walks her to Auntie Dede's stool.
@export var building: Node3D

## The customers who come to her during her shift.
var customers: Array[Townsperson] = []

# Auntie Dede walking off to the bank (looking just like her).
var _going_out: Townsperson

@onready var dede: Vendor = $AuntieDede
@onready var shift: SkilledJob = $Shift
@onready var customer_spot: Marker3D = $CustomerSpot
@onready var street: Marker3D = $Street
@onready var station_side: Marker3D = $StationSide


func _ready() -> void:
	shift.click_targets = [building]
	shift.started.connect(_on_shift_started)
	shift.finished.connect(_on_shift_finished)
	GameState.time_changed.connect(_on_time_changed)
	for body in [Townsperson.Body.WOMAN, Townsperson.Body.MAN]:
		var customer := Townsperson.new()
		customer.body = body
		customer.top_color = TownLife.TOPS.pick_random()
		customer.bottom_color = TownLife.BOTTOMS.pick_random()
		customer.headwrap_color = TownLife.TOPS.pick_random()
		customer.visible = false
		add_child(customer)
		customers.append(customer)
	_going_out = Townsperson.new()
	_going_out.person_name = dede.person_name
	_going_out.top_color = dede.top_color
	_going_out.bottom_color = dede.skirt_color
	_going_out.trim_color = dede.trim_color
	_going_out.headwrap_color = dede.headwrap_color
	_going_out.visible = false
	add_child(_going_out)
	_update_dede()


## Whether the kiosk is open (Auntie Dede is there, or minding it for her).
func is_open() -> bool:
	return GameState.minutes >= OPENS and GameState.minutes < CLOSES


# The shift starts: Auntie Dede gets up and heads off to the bank (by trotro),
# the player takes her stool, and customers come.
func _on_shift_started() -> void:
	dede.leave()
	_going_out.appear_at(dede.global_position)
	_going_out.rotation.y = dede.rotation.y
	_going_out.say("I'm going to the bank. Take care of my kiosk!")
	_going_out.walk_to(station_side.global_position)
	for i in customers.size():
		_serve(customers[i], 1.5 + i * 3.2)
	await _wait(3.0)
	await _going_out.vanish()


func _serve(customer: Townsperson, after: float) -> void:
	await _wait(after)
	if not shift.working:
		return
	customer.appear_at(street.global_position + Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-0.5, 0.5)))
	await customer.walk_to(customer_spot.global_position)
	customer.face(shift.global_position)
	customer.say(CUSTOMER_LINES.pick_random())
	await _wait(2.0)
	await customer.walk_to(station_side.global_position + Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-0.5, 0.5)))
	await customer.vanish()


# Back from the bank, once the player is off her stool: Auntie Dede takes over
# again, and thanks her (she's been paid her commission).
func _on_shift_finished(completed: bool) -> void:
	await _wait(0.8)
	_update_dede()
	if completed:
		dede.say("Ayekoo! Here's your commission.")


func _on_time_changed(_day: int, _minutes: float) -> void:
	_update_dede()


# She's at her kiosk from morning to evening (unless the player is minding it).
func _update_dede() -> void:
	var here := is_open() and not shift.working
	if here != dede.is_here():
		if here:
			dede.come_back()
		else:
			dede.leave()
	shift.refresh()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, false).timeout
