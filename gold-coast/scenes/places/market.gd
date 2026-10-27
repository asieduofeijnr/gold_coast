class_name Market
extends Node3D
## The market across the road, where Madam Serwaa hires kayayei (head porters)
## to carry her customers' loads.
## - E at her stall (or a click on it) puts a headpan of goods on your head.
##   Carry it to the place shown before the time runs out: in time, she pays
##   in full by mobile money; late, she pays half.
## - E at her stall while you're carrying gives the load back, for no pay.
## - The market is open from 06:00 to 18:00. After closing, the sellers pack up
##   one by one and go home (Madam Serwaa last), so at night it's empty. They're
##   back before it opens.
## - With dressmaking from the training college, she can sew kaba and slit at
##   the sewing machine by Sister Abena's cloth stall (see SkilledJob).

## Sent when a seller packs up and goes home (TownLife walks her home with her
## goods on her head).
signal seller_left(seller: Vendor, goods_color: Palette.ColorName)

## Who pays for the carrying, as the phone's texts show it (short, to fit).
const PAYER := "SERWAA"
## When the market opens and closes, in minutes after midnight.
const OPENS := 6.0 * 60.0
const CLOSES := 18.0 * 60.0
## When the first seller arrives in the morning and leaves in the evening; the
## others follow, SELLER_GAP minutes apart.
const SELLERS_ARRIVE := 5.5 * 60.0
const SELLERS_LEAVE := 18.0 * 60.0
const SELLER_GAP := 3.0
## What her customers buy, and its color in the headpan.
const GOODS := [
	["tomatoes", Palette.ColorName.LIGHT_SOUP],
	["onions", Palette.ColorName.WAAKYE_BROWN],
	["yams", Palette.ColorName.WOOD_LIGHT],
	["plantain", Palette.ColorName.PALM_GREEN],
	["oranges", Palette.ColorName.KELEWELE_ORANGE],
	["kenkey", Palette.ColorName.KENKEY_BEIGE],
	["smoked fish", Palette.ColorName.FRIED_FISH],
	["charcoal", Palette.ColorName.SHITO_BLACK],
]

## The load she's offering right now, waiting for a kayayo (null if none).
var offer: Delivery

# Everyone who sells here, in the order they leave (Madam Serwaa last).
var _sellers: Array[Vendor] = []

@onready var trader: Vendor = $Trader
@onready var hire_spot: Interactable = $HireSpot
@onready var sew_job: SkilledJob = $SewJob
@onready var sewing_machine: SewingMachine = $SewingMachine


func _ready() -> void:
	hire_spot.click_targets = [$TraderStall as Node3D]
	hire_spot.used.connect(_on_hire_spot_used)
	sew_job.click_targets = [sewing_machine as Node3D]
	sew_job.started.connect(_on_sewing.bind(true))
	sew_job.finished.connect(_on_sewing.bind(false).unbind(1)) # however it went, she's stopped
	GameState.load_changed.connect(_on_load_changed)
	GameState.time_changed.connect(_on_time_changed)
	for child in get_children():
		if child is Vendor and child != trader:
			_sellers.append(child)
	_sellers.append(trader)
	_update_sellers(true)
	# Wait a frame, so every DeliverySpot in the world is ready to be chosen.
	make_offer.call_deferred()


## Everyone who sells at the market, in the order they go home.
func sellers() -> Array[Vendor]:
	return _sellers.duplicate()


## The stalls where townspeople shop (all but Madam Serwaa's, where kayayei
## get their loads).
func shopping_stalls() -> Array[MarketStall]:
	var found: Array[MarketStall] = []
	for child in get_children():
		if child is MarketStall and child != $TraderStall:
			found.append(child)
	return found


## Where kayayei pick up their loads: by Madam Serwaa's pile of headpans.
func load_pile_spot() -> Vector3:
	return ($LoadPile as Node3D).global_position + Vector3(0.0, 0.0, 0.9)


## Whether the market is open right now.
func is_open() -> bool:
	return GameState.minutes >= OPENS and GameState.minutes < CLOSES


## When the seller `index` places along leaves in the evening, in minutes after midnight.
func leaving_time(index: int) -> float:
	return SELLERS_LEAVE + index * SELLER_GAP


## Gets a new load ready to carry: to `destination`, or to a place picked at
## random if it's null.
func make_offer(destination: DeliverySpot = null) -> void:
	if destination == null:
		var spots := get_tree().get_nodes_in_group(DeliverySpot.SPOTS_GROUP)
		destination = spots.pick_random() if not spots.is_empty() else null
	if destination == null:
		offer = null
	else:
		var goods: Array = GOODS.pick_random()
		offer = Delivery.new()
		offer.goods = goods[0]
		offer.color = goods[1]
		offer.place = destination.place_name
		offer.phone_place = destination.phone_name
		offer.receiver = destination.receiver
		offer.payer = PAYER
		offer.pay = destination.pay
		offer.minutes = destination.minutes
	_update_sign()


func _on_hire_spot_used(_user: Node3D) -> void:
	if GameState.delivery != null:
		GameState.give_back_load()
		trader.say("Eh! Okay, bring it. I'll find another kayayo.")
		return
	if not is_open():
		trader.say("The market is closed, my dear. Come back at six in the morning!")
		return
	if offer == null:
		make_offer()
	var headload := offer
	if headload != null and GameState.pick_up(headload):
		trader.say("Take the %s to %s at %s. Before %s o!" % [headload.goods, headload.receiver, headload.place,
				Format.clock(headload.due)])
		make_offer() # the next one is ready for when she's back


func _on_load_changed(_headload: Delivery) -> void:
	_update_sign()


func _on_time_changed(_day: int, _minutes: float) -> void:
	_update_sellers()
	_update_sign() # the market opens and closes


# Each seller is at her place from her arrival time until her leaving time,
# and gone home the rest of the night. Her stall closes while she's away.
# `quietly` is for when the game starts: nobody is seen leaving.
func _update_sellers(quietly := false) -> void:
	for i in _sellers.size():
		var seller := _sellers[i]
		var arrives := SELLERS_ARRIVE + i * SELLER_GAP
		var here := GameState.minutes >= arrives and GameState.minutes < leaving_time(i)
		if here == seller.is_here():
			continue
		var stall := _stall_of(seller)
		if stall != null:
			stall.closed = not here
		if here:
			seller.come_back()
		else:
			seller.leave()
			# Only walk her home if it's just gone her time (not on skipping the clock).
			if not quietly and GameState.minutes - leaving_time(i) < 30.0:
				seller_left.emit(seller, _goods_color(seller, stall))
	hire_spot.enabled = trader.is_here() # nobody to hire her while Madam Serwaa's gone
	sew_job.refresh() # or to give her sewing while Sister Abena's gone


# The machine's wheels turn while she sews.
func _on_sewing(sewing: bool) -> void:
	sewing_machine.sewing = sewing


func _stall_of(seller: Vendor) -> MarketStall:
	for child in get_children():
		if child is MarketStall and (child as MarketStall).seller == seller:
			return child
	return null


# What she carries home in her headpan: her goods.
func _goods_color(seller: Vendor, stall: MarketStall) -> Palette.ColorName:
	if stall != null:
		return Palette.ColorName.KENTE_GOLD if stall.cloth else stall.produce
	for thing in seller.belongings:
		if thing is HeadPan:
			return (thing as HeadPan).goods_color
	return Palette.ColorName.KENTE_GOLD


func _update_sign() -> void:
	var words := "No loads right now"
	if GameState.delivery != null:
		words = "Give the load back"
	elif not is_open():
		words = "Market closed (opens 06:00)"
	elif offer != null:
		words = "Carry %s  +%s" % [offer.goods, Format.cedis(offer.pay)]
	if hire_spot.prompt != words:
		hire_spot.prompt = words
