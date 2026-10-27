class_name DeliverySpot
extends Interactable
## A place a kayayo can carry loads to, like the Chop Bar or the trotro stop.
## It only switches on while she's carrying a load that's going here. Then a
## gold ring marks it on the ground, an arrow shows the way (even from off the
## screen), and E here hands the load over. Whoever takes it says thank you,
## or tells her off if she's late.

## The group every DeliverySpot joins, so the market can find them all.
const SPOTS_GROUP := &"delivery_spots"

## The place's name, the way people say it: "the Chop Bar".
@export var place_name := "the Chop Bar"
## The same place, short enough for the phone's screen (11 letters at most).
@export var phone_name := "CHOP BAR"
## Who takes the loads here, like "Maame Esi".
@export var receiver := "Maame Esi"
## What carrying a load here pays, in pesewas.
@export var pay := 1000
## How long she has to get a load here, in game minutes.
@export var minutes := 25.0
## The building (or anything else) the loads go to. Clicking it walks her here.
@export var building: Node3D
## Where whoever takes the loads answers from, from this spot: their doorway,
## a little way in front of her (she faces -Z).
@export var doorway := Vector3(0.0, 0.0, -1.5)

var _ring: MeshInstance3D
var _guide: GuideMarker
var _bubble: SpeechBubble


func _init() -> void:
	works_while_carrying = true
	add_to_group(SPOTS_GROUP)


func _ready() -> void:
	super()
	if building != null:
		click_targets = [building]
	_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.45
	torus.outer_radius = 0.58
	torus.rings = 32
	torus.ring_segments = 6
	_ring.mesh = torus
	_ring.material_override = Palette.material(Palette.ColorName.KENTE_GOLD)
	_ring.position.y = 0.03
	add_child(_ring, false, Node.INTERNAL_MODE_FRONT)
	var layer := CanvasLayer.new()
	add_child(layer, false, Node.INTERNAL_MODE_FRONT)
	_guide = GuideMarker.new()
	_guide.anchor = self
	_guide.height = 2.3
	_guide.visible = false
	layer.add_child(_guide)
	var voice := Node3D.new()
	voice.position = doorway
	add_child(voice, false, Node.INTERNAL_MODE_FRONT)
	_bubble = SpeechBubble.new()
	_bubble.anchor = voice
	_bubble.height = 2.8
	_bubble.speaker = receiver
	_bubble.visible = false
	layer.add_child(_bubble)
	used.connect(_hand_over)
	GameState.load_changed.connect(_on_load_changed)
	_on_load_changed(GameState.delivery)


func _process(_delta: float) -> void:
	if _ring.visible:
		_ring.scale = Vector3.ONE * (1.0 + 0.08 * sin(Time.get_ticks_msec() / 200.0)) # a gentle pulse


## Whether she's carrying a load that's going here.
func is_destination() -> bool:
	return GameState.delivery != null and GameState.delivery.place == place_name


## Whether the ring and the arrow are showing the way here.
func is_marked() -> bool:
	return _ring.visible


## The arrow showing the way here (for tests).
func get_guide() -> GuideMarker:
	return _guide


## What whoever takes the loads here is saying ("" if nothing).
func saying() -> String:
	return _bubble.text if _bubble.is_showing() else ""


func _on_load_changed(headload: Delivery) -> void:
	var here := headload != null and headload.place == place_name
	enabled = here
	_ring.visible = here
	if here:
		prompt = "Deliver the " + headload.goods
		var short_name := place_name.trim_prefix("the ")
		_guide.text = short_name.left(1).to_upper() + short_name.substr(1)
		_guide.traveller = get_tree().get_first_node_in_group("player") as Node3D
		_guide.appear()
	else:
		_guide.disappear()


# The sign takes over from the arrow once she's close enough to use it.
func _update_sign() -> void:
	super()
	if _guide == null or not is_destination():
		return
	if focused:
		_guide.disappear()
	else:
		_guide.appear()


func _hand_over(user: Node3D) -> void:
	var late := GameState.delivery_minutes_left() < 0.0
	var paid := GameState.deliver_load()
	_bubble.say("Ei, you're late o! Only half pay." if late else "Ayekoo! Medaase, my dear.")
	FloatingText.pop(user, "+" + Format.cedis(paid), Palette.color(Palette.ColorName.KENTE_GOLD))
