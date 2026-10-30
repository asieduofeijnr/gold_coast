class_name PauseMenu
extends Node
## The game's menu, on her phone. Press M or Esc (or click the phone's middle
## key), and she holds the phone up, big, while the game pauses. Its menu has:
## - RESUME: back to the game
## - SAVE GAME: saves right now, if she's free (not while she's busy, or asleep
##   anywhere but her bed); otherwise the phone says why not
## - LOAD GAME: back to the saved game (it asks first)
## - NEW GAME: starts again (it asks first)
## - HOW TO PLAY: the controls and the basics, a page at a time
## Choose with the phone's scroll key (or the arrow keys, or W and S), and pick
## with its middle key (or Enter, or E). C (or Esc, or M) goes back. A click
## beside the phone closes the menu.

## Sent when you choose to load the saved game ("load") or to start a new one
## ("new"). The main scene does the rest.
signal restart_requested(how: String)

const ITEMS: Array[String] = ["RESUME", "SAVE GAME", "LOAD GAME", "NEW GAME", "HOW TO PLAY"]
## How to play, a page at a time: three lines of up to 14 letters, in the
## phone's own font.
const HOW_TO_PLAY := [
	["WALK: WASD OR", "ARROW KEYS, OR", "CLICK GROUND."],
	["E: USE, BUY,", "TALK OR WORK.", "OR CLICK IT."],
	["Z: SLEEP.", "HER BED AT", "HOME SAVES."],
	["WHEEL: ZOOM.", "SPACE: BACK", "TO HER."],
	["EARN: CARRY", "LOADS FROM", "THE MARKET."],
	["LEARN SKILLS", "AT SANKOFA", "COLLEGE."],
	["RENT: GH₵140", "EVERY MONDAY.", "EAT WELL!"],
	["M OR ESC:", "THIS MENU.", "SAVE ANYTIME!"],
]
## How dark the game gets behind the phone while the menu is open.
const SHADE := 0.35

## The phone the menu is on, and the shade that dims the game behind it.
@export var phone: Phone
@export var shade: ColorRect

var _open := false
# What the phone's page is for: "" (no page: the menu), "message", "load",
# "new", or "help"; which help page is showing; and the item to go back to.
var _page := ""
var _help_page := 0
var _item := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # it works while the game is paused
	phone.menu_key_pressed.connect(open)
	phone.item_chosen.connect(_on_item_chosen)
	phone.page_accepted.connect(_on_page_accepted)
	phone.page_scrolled.connect(_on_page_scrolled)
	phone.back_pressed.connect(_on_back_pressed)
	shade.visible = false
	shade.gui_input.connect(_on_shade_input)


## Whether the menu is open.
func is_open() -> bool:
	return _open


## Opens the menu and pauses the game, unless something else (another menu,
## or the title screen) already has the game paused.
func open() -> void:
	if _open or get_tree().paused:
		return
	_open = true
	get_tree().paused = true
	shade.color = Color(0.0, 0.0, 0.0, SHADE)
	shade.visible = true
	phone.hold_up(true)
	_show_menu(0)


## Closes the menu, and the game carries on.
func close() -> void:
	if not _open:
		return
	_open = false
	_page = ""
	shade.visible = false
	phone.show_home()
	phone.hold_up(false)
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		if event.is_action_pressed("phone_menu") and not get_tree().paused:
			open()
			get_viewport().set_input_as_handled()
		return
	var key := Phone.key_for(event)
	if key != "":
		phone.press(key)
		get_viewport().set_input_as_handled()


func _on_item_chosen(index: int) -> void:
	if not _open or _page != "":
		return
	_item = index
	match ITEMS[index]:
		"RESUME":
			close()
		"SAVE GAME":
			_save()
		"LOAD GAME":
			_ask_to_load()
		"NEW GAME":
			_page = "new"
			phone.show_page(PackedStringArray(["START AGAIN?", "UNSAVED PLAY", "WILL BE LOST."]), "YES", "NEW GAME")
		"HOW TO PLAY":
			_page = "help"
			_help_page = 0
			_show_help()


# Saves now if she's free; either way, the phone says what happened.
func _save() -> void:
	_page = "message"
	var reason := GameState.save_refusal()
	if reason != "":
		phone.show_page(PackedStringArray(["CANNOT SAVE:", reason, "TRY LATER."]), "OK", "SAVE GAME")
	elif GameState.save_game():
		phone.show_page(PackedStringArray(["GAME SAVED.", "%s DAY %d" % [Format.weekday(GameState.day), GameState.day],
				"AT " + Format.clock(GameState.minutes)]), "OK", "SAVE GAME")
	else:
		phone.show_page(PackedStringArray(["IT COULD NOT", "BE SAVED.", "SORRY!"]), "OK", "SAVE GAME")


# Asks before loading the saved game, showing when it was saved.
func _ask_to_load() -> void:
	var saved := GameState.peek_save()
	if saved.is_empty():
		_page = "message"
		phone.show_page(PackedStringArray(["THERE IS NO", "SAVED GAME", "YET."]), "OK", "LOAD GAME")
		return
	_page = "load"
	var day := int(saved.day)
	phone.show_page(PackedStringArray(["LOAD THE SAVE?", "%s DAY %d" % [Format.weekday(day), day],
			"AT " + Format.clock(float(saved.minutes))]), "YES", "LOAD GAME")


func _on_page_accepted() -> void:
	if not _open:
		return
	match _page:
		"load", "new":
			var how := _page
			close()
			restart_requested.emit(how)
		"help":
			if _help_page < HOW_TO_PLAY.size() - 1:
				_help_page += 1
				_show_help()
			else:
				_show_menu(_item)
		_:
			_show_menu(_item)


func _on_page_scrolled(step: int) -> void:
	if _open and _page == "help":
		_help_page = clampi(_help_page + step, 0, HOW_TO_PLAY.size() - 1)
		_show_help()


# C goes back: from a page to the menu, and from the menu back to the game.
func _on_back_pressed() -> void:
	if not _open:
		return
	if _page == "":
		close()
	else:
		_show_menu(_item)


func _show_menu(selected: int) -> void:
	_page = ""
	phone.show_menu("MENU", PackedStringArray(ITEMS), selected)


func _show_help() -> void:
	var last := _help_page == HOW_TO_PLAY.size() - 1
	phone.show_page(PackedStringArray(HOW_TO_PLAY[_help_page]), "DONE" if last else "NEXT",
			"HELP %d/%d" % [_help_page + 1, HOW_TO_PLAY.size()])


# A click beside the phone closes the menu.
func _on_shade_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.pressed:
		close()
