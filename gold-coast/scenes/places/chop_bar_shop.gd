class_name ChopBarShop
extends Node3D
## Maame Esi's chop bar: everything you can do at the Chop Bar building.
## - At the counter (press E there, or click the building), her menu board
##   opens and the game pauses while you choose. You pay by mobile money, then
##   she sits at the table outside and eats, and her hunger comes back.
## - With too little money, the payment fails: nothing changes, the phone says
##   so, and Maame Esi offers you some work.
## - At the basin, she can wash bowls for a game hour to earn GH₵20.00, once a day.
## Place it at the same spot as the Chop Bar building.

## The name on the phone's payment texts.
const BUSINESS := "CHOP BAR"
## What washing the bowls pays, in pesewas (GH₵20.00).
const WAGE := 2000
## Washing the bowls takes a game hour, which goes by in a few real seconds.
const WASH_MINUTES := 60.0
const WASH_SECONDS := 3.0
## A meal takes this many real seconds, however long it is in game time.
const EAT_SECONDS := 3.0
## She's too full to eat when her hunger is above this.
const FULL_UP := 95.0
const WASHING := "Washing bowls"

## The dishes on the menu. Edit them in the Inspector.
@export var menu: Array[Food] = []
## The Chop Bar building. Clicking it (or the food stall) walks her to the counter.
@export var building: Node3D

var _customer: Player
var _meal: Food
var _eating := ""

@onready var counter: Interactable = $Counter
@onready var basin_spot: Interactable = $BasinSpot
@onready var vendor: Vendor = $Vendor
@onready var table: ChopTable = $Table
@onready var board: MenuBoard = $MenuLayer/MenuBoard


func _ready() -> void:
	counter.click_targets = [building, $FoodCounter as Node3D]
	basin_spot.click_targets = [$Basin as Node3D]
	counter.used.connect(_open_menu)
	basin_spot.used.connect(_wash_bowls)
	board.chosen.connect(_buy)
	board.closed.connect(_on_menu_closed)
	GameState.activity_finished.connect(_on_activity_finished)
	GameState.time_changed.connect(_on_time_changed)
	_update_basin_sign()


func _exit_tree() -> void:
	# Never leave the game paused if the chop bar goes away with its menu open.
	if board.is_open():
		get_tree().paused = false


func _open_menu(user: Node3D) -> void:
	_customer = user as Player
	board.open(menu)
	vendor.hush()
	_say("Akwaaba! What will you chop?")
	# Pausing stops the clock and the world while you choose. The menu, the
	# phone, and Maame Esi's speech bubble keep working (their process_mode is
	# "Always").
	get_tree().paused = true


func _on_menu_closed() -> void:
	get_tree().paused = false


func _buy(index: int) -> void:
	var food := menu[index]
	if GameState.hunger > FULL_UP:
		_say("Ei! You're already full o!")
		board.shake()
		return
	if not GameState.pay(food.price, BUSINESS):
		_say("Chale, your momo no reach o! Wash my bowls, I'll pay you.")
		board.shake(index)
		return
	board.close()
	_say("Enjoy your %s, my dear!" % food.title.to_lower())
	_meal = food
	if _customer != null:
		_customer.act_at(table.seat, &"eat", _start_meal)


# She's sitting at the table: the food arrives and she starts eating.
func _start_meal() -> void:
	_eating = "Eating " + _meal.title.to_lower()
	if GameState.start_activity(_eating, _meal.minutes, EAT_SECONDS, _meal.hunger):
		table.serve(_meal)
	else:
		_eating = "" # she couldn't eat after all (she fell asleep on the way)


func _wash_bowls(user: Node3D) -> void:
	if GameState.bowls_washed_day == GameState.day:
		_say("They're all clean, thank you! Come back tomorrow.")
		return
	_customer = user as Player
	_customer.act_at(basin_spot, &"wash", _start_washing)


func _start_washing() -> void:
	if GameState.start_activity(WASHING, WASH_MINUTES, WASH_SECONDS):
		GameState.bowls_washed_day = GameState.day
		_update_basin_sign()


func _on_activity_finished(activity: String, completed: bool) -> void:
	if activity == WASHING:
		if completed:
			GameState.receive(WAGE, BUSINESS)
			_say("Ayekoo! Here's your twenty cedis.")
			if _customer != null:
				FloatingText.pop(_customer, "+" + Format.cedis(WAGE), Palette.color(Palette.ColorName.KENTE_GOLD))
		else:
			GameState.bowls_washed_day = 0 # she didn't finish, so she can try again
		_update_basin_sign()
	elif activity == _eating and _eating != "":
		table.clear()
		if completed and _customer != null:
			FloatingText.pop(_customer, "+%d food" % roundi(_meal.hunger), Palette.color(Palette.ColorName.KENTE_GOLD))
		_eating = ""
		_meal = null


# Maame Esi says `line`: on the menu board while it's open (her speech bubble
# would be hidden behind it), otherwise in her speech bubble.
func _say(line: String) -> void:
	if board.is_open():
		board.line = line
	else:
		vendor.say(line)


func _on_time_changed(_day: int, _minutes: float) -> void:
	_update_basin_sign() # a new day means fresh dirty bowls


func _update_basin_sign() -> void:
	var words := "Wash bowls  +" + Format.cedis(WAGE) if GameState.bowls_washed_day != GameState.day else "Bowls done. Come back tomorrow"
	if basin_spot.prompt != words:
		basin_spot.prompt = words
