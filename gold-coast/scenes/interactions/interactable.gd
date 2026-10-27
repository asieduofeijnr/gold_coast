class_name Interactable
extends Marker3D
## Something in the world she can use, like the Chop Bar's counter or her bed.
## Walk up to it and press E, or click it (see `click_targets`) and she walks
## over and uses it. When she's close enough and it's the nearest one, a sign
## like "E  Buy food" floats above it.
##
## This node marks the spot where she stands to use it, and she faces the way
## it faces (its -Z axis). Connect the `used` signal to whatever should happen.

## Sent when she uses it. `user` is the player.
signal used(user: Node3D)

## The group every Interactable joins, so the player can find them all.
const GROUP := &"interactables"

## What using it does, shown in the sign (like "Buy food").
@export var prompt := "Use":
	set(value):
		prompt = value
		if _sign != null:
			_sign.text = value
## How close she has to be to use it, in metres.
@export var reach := 2.0
## Clicking any of these (or anything inside them, like a whole building)
## walks her here and uses it.
@export var click_targets: Array[Node3D] = []
## How high above the spot the sign floats, in metres.
@export var sign_height := 2.4
## Whether she can use it while she's carrying a load on her head. Most things
## can't be (she has to deliver it first); the place it's going can.
@export var works_while_carrying := false

## Whether it can be used at all right now. Switched off, it's ignored and its
## sign hides.
var enabled := true:
	set(value):
		enabled = value
		if not value:
			focused = false
			hovered = false

## Whether she's close enough to use it with E. The player sets this on the
## nearest one.
var focused := false:
	set(value):
		focused = value
		_update_sign()
## Whether the mouse is pointing at one of its click targets. The player sets this.
var hovered := false:
	set(value):
		hovered = value
		_update_sign()

var _sign: InteractionPrompt


func _ready() -> void:
	add_to_group(GROUP)
	var layer := CanvasLayer.new()
	# Keep working while the game is paused, so the sign can fade away when a
	# menu opens.
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer, false, Node.INTERNAL_MODE_FRONT)
	_sign = InteractionPrompt.new()
	_sign.anchor = self
	_sign.height = sign_height
	_sign.text = prompt
	_sign.visible = false
	layer.add_child(_sign)


## Uses it: hides its sign and sends `used`.
func use(user: Node3D) -> void:
	focused = false
	hovered = false
	used.emit(user)


## Whether `node` is one of its click targets, or part of one.
func is_clicked(node: Node) -> bool:
	for target in click_targets:
		if target != null and node != null and (node == target or target.is_ancestor_of(node)):
			return true
	return false


## Whether its sign is showing.
func is_sign_showing() -> bool:
	return _sign != null and _sign.is_showing()


## The sign itself (for tests).
func get_sign() -> InteractionPrompt:
	return _sign


func _update_sign() -> void:
	if _sign == null:
		return
	_sign.with_mouse = hovered and not focused
	if focused or hovered:
		_sign.appear()
	else:
		_sign.disappear()
