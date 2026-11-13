class_name TitleScreen
extends Control
## The title screen, when the game starts: GOLD COAST painted on a sign in
## Ghana's colors. First, if nobody's logged in, the account card
## (AccountScreen) asks you to make an account, log in, or play offline; if you
## logged in before, it logs you in again by itself. Logged in, it checks her
## save against her cloud save (Online.check_cloud()): a newer one from another
## computer comes down, and if both have changed, her phone asks which to keep
## (THIS COMPUTER or THE CLOUD), with both described under the sign. Then her
## phone, held up, shows the start menu:
## - CONTINUE (only if there's a saved game): carries on from it. Under the
##   sign it says when it was saved, and how much money she had.
## - NEW GAME: a fresh start. If there's a saved game it asks first; the old
##   save stays until the new game saves over it.
## - HOW TO PLAY: the controls and the basics, a page at a time
## - LOG OUT (or, playing offline, LOG IN): back to the account card
## The game waits, paused, until you choose. (In a web browser, choosing is also
## the click the browser waits for before the game may play sounds.)

## Sent when you've chosen how to start: `continuing` is true to carry on from
## the saved game, and false for a new game.
signal started(continuing: bool)

const SIGN := Rect2(430.0, 88.0, 650.0, 300.0)
## Where the sign goes while the account card is showing: on the left.
const ACCOUNT_SIGN := Rect2(40.0, 110.0, 570.0, 263.0)

## The phone the start menu is on.
@export var phone: Phone

var _open := false
var _items := PackedStringArray()
var _saved := {}
# What the phone's page is for: "" (the menu), "new", or "help".
var _page := ""
var _help_page := 0
var _account: AccountScreen
var _logging_in := false
var _checking := false


func _ready() -> void:
	visible = false
	phone.item_chosen.connect(_on_item_chosen)
	phone.page_accepted.connect(_on_page_accepted)
	phone.page_scrolled.connect(_on_page_scrolled)
	phone.back_pressed.connect(_on_back_pressed)
	_account = AccountScreen.new()
	add_child(_account)
	_account.done.connect(_on_account_done)


## Shows the title screen, and pauses the game until you choose how to start.
func open() -> void:
	_saved = GameState.peek_save()
	_open = true
	visible = true
	get_tree().paused = true
	var problem := ""
	if not Online.is_ready_to_play() and Online.has_saved_login():
		_logging_in = true
		phone.visible = false
		queue_redraw()
		problem = await Online.restore()
		_logging_in = false
	if Online.is_ready_to_play():
		if not await _check_cloud():
			_show_start()
	else:
		_show_account()
		if problem != "":
			_account.say(problem, 1) # on Log in: she has an account


## Whether the account card is showing (to make an account, log in, or play offline).
func is_asking_for_account() -> bool:
	return _account.is_open()


## The account card (for tests).
func get_account_screen() -> AccountScreen:
	return _account


## Whether the title screen is showing.
func is_open() -> bool:
	return _open


## The items on the phone's start menu.
func items() -> PackedStringArray:
	return _items


## Whether her phone is asking which of two saves to keep (this computer's or
## the cloud's).
func is_asking_which() -> bool:
	return _page == "keep"


## What the title screen says about the saved game ("" if there isn't one).
func saved_game_line() -> String:
	return "" if _saved.is_empty() else "Saved game: " + describe(_saved)


## The two saves she can choose between, as the title screen describes them:
## this computer's, then the cloud's (empty if it isn't asking).
func which_lines() -> PackedStringArray:
	if not is_asking_which() or Online.cloud_question.is_empty():
		return PackedStringArray()
	return PackedStringArray(["This computer:  " + describe(Online.cloud_question.here),
			"The cloud:  " + describe(Online.cloud_question.cloud)])


## A saved game in a few words: the day and time in the game, her money, and
## (for saves that know it) when it was saved, like "MON, day 5, 14:20  ·
## GH₵230.00  ·  saved 13 Nov, 16:20".
static func describe(save: Dictionary) -> String:
	var day := int(save.get("day", 1))
	var line := "%s, day %d, %s  ·  %s" % [Format.weekday(day), day, Format.clock(float(save.get("minutes", 0.0))),
			Format.cedis(int(save.get("money", 0)))]
	if save.get("saved_at") is float or save.get("saved_at") is int:
		line += "  ·  saved " + Format.date_time(int(save.saved_at))
	return line


func _unhandled_input(event: InputEvent) -> void:
	if not _open or _account.is_open() or _logging_in or _checking:
		return
	var key := Phone.key_for(event)
	if key != "":
		phone.press(key)
		get_viewport().set_input_as_handled()


func _on_item_chosen(index: int) -> void:
	if _open and _page == "keep":
		_page = "keeping" # one choice: the keys wait until it's kept
		await Online.keep_save("here" if index == 0 else "cloud")
		_saved = GameState.peek_save()
		_show_start()
		return
	if not _open or _page != "":
		return
	match _items[index]:
		"CONTINUE":
			_start(true)
		"NEW GAME":
			if _saved.is_empty():
				_start(false)
			else:
				_page = "new"
				phone.show_page(PackedStringArray(["NEW GAME?", "NEXT SAVE", "REPLACES OLD."]), "YES", "NEW GAME")
		"HOW TO PLAY":
			_page = "help"
			_help_page = 0
			_show_help()
		"LOG OUT", "LOG IN":
			Online.log_out()
			_show_account()


func _on_page_accepted() -> void:
	if not _open:
		return
	if _page == "new":
		_start(false)
	elif _page == "help":
		if _help_page < PauseMenu.HOW_TO_PLAY.size() - 1:
			_help_page += 1
			_show_help()
		else:
			_show_menu(_items.find("HOW TO PLAY"))


func _on_page_scrolled(step: int) -> void:
	if _open and _page == "help":
		_help_page = clampi(_help_page + step, 0, PauseMenu.HOW_TO_PLAY.size() - 1)
		_show_help()


# C goes back from a page to the start menu (but she must choose which save to keep).
func _on_back_pressed() -> void:
	if _open and _page != "" and _page not in ["keep", "keeping"]:
		_show_menu(_items.find("NEW GAME" if _page == "new" else "HOW TO PLAY"))


func _show_account() -> void:
	phone.hold_up(false)
	phone.visible = false
	_account.open()
	queue_redraw()


func _on_account_done() -> void:
	_account.close()
	if not await _check_cloud():
		_show_start()


# Logged in, her save on this computer and her cloud save are brought into step
# first (see Online.check_cloud()). Returns true if her phone is asking which
# of the two to keep.
func _check_cloud() -> bool:
	if not Online.is_logged_in():
		return false
	_checking = true
	phone.visible = false
	queue_redraw()
	var answer: String = await Online.check_cloud()
	_checking = false
	_saved = GameState.peek_save()
	if answer != "ask":
		return false
	_page = "keep"
	phone.visible = true
	phone.hold_up(true)
	phone.show_menu("KEEP WHICH?", PackedStringArray(["THIS COMPUTER", "THE CLOUD"]), 0)
	queue_redraw()
	return true


func _show_start() -> void:
	phone.visible = true
	phone.hold_up(true)
	_show_menu(0)
	queue_redraw()


func _show_menu(selected: int) -> void:
	_page = ""
	_items = PackedStringArray(["CONTINUE", "NEW GAME", "HOW TO PLAY"] if not _saved.is_empty()
			else ["NEW GAME", "HOW TO PLAY"])
	_items.append("LOG OUT" if Online.is_logged_in() else "LOG IN")
	phone.show_menu("GOLD COAST", _items, selected)


func _show_help() -> void:
	var pages := PauseMenu.HOW_TO_PLAY
	phone.show_page(PackedStringArray(pages[_help_page]), "DONE" if _help_page == pages.size() - 1 else "NEXT",
			"HELP %d/%d" % [_help_page + 1, pages.size()])


func _start(continuing: bool) -> void:
	_open = false
	_page = ""
	visible = false
	phone.show_home()
	phone.hold_up(false)
	get_tree().paused = false
	started.emit(continuing)


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var paper := Palette.color(Palette.ColorName.PAPER)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.07, 0.04, 0.02, 0.62)) # dim the town behind
	if _account.is_open():
		_draw_sign(ACCOUNT_SIGN)
		draw_string(font, Vector2(ACCOUNT_SIGN.position.x, ACCOUNT_SIGN.end.y + 40.0),
				"Make an account to play online, in one town with everyone.", HORIZONTAL_ALIGNMENT_CENTER,
				ACCOUNT_SIGN.size.x, 19, paper)
		return
	_draw_sign(SIGN)
	# What's saved, who's playing, and how to choose.
	var below := SIGN.end.y + 44.0
	if _logging_in or _checking:
		draw_string(font, Vector2(SIGN.position.x, below), "Logging in..." if _logging_in else "Checking your cloud save...",
				HORIZONTAL_ALIGNMENT_CENTER, SIGN.size.x, 20, paper)
		return
	if _page in ["keep", "keeping"]:
		_draw_which(font, below)
		return
	var saved := saved_game_line()
	if saved == "":
		draw_string(font, Vector2(SIGN.position.x, below), "No saved game yet. Start a new one!", HORIZONTAL_ALIGNMENT_CENTER,
				SIGN.size.x, 20, paper)
	else:
		var width := CediText.width(font, saved, 20)
		CediText.draw(self, font, Vector2(SIGN.get_center().x - width / 2.0, below), saved, 20, paper)
	draw_string(font, Vector2(SIGN.position.x, below + 34.0), "Choose on her phone: the arrow keys and Enter, or click its keys.",
			HORIZONTAL_ALIGNMENT_CENTER, SIGN.size.x, 15, Palette.color(Palette.ColorName.PLINTH_LIGHT))
	var who := "Logged in as @%s%s" % [Online.username, _cloud_note()] if Online.is_logged_in() \
			else "Playing offline, without an account"
	draw_string(font, Vector2(SIGN.position.x, below + 64.0), who, HORIZONTAL_ALIGNMENT_CENTER, SIGN.size.x, 15,
			Palette.color(Palette.ColorName.KENTE_GOLD))


# What the cloud is like, after "Logged in as @...".
func _cloud_note() -> String:
	match Online.cloud:
		CloudSave.State.UP_TO_DATE:
			return "  ·  your save is in the cloud"
		CloudSave.State.WAITING:
			return "  ·  your save goes to the cloud when it can"
		CloudSave.State.DIFFERS:
			return "  ·  the cloud has another save"
	return ""


# Two saves that differ, and which to keep: this computer's and the cloud's.
func _draw_which(font: Font, below: float) -> void:
	var paper := Palette.color(Palette.ColorName.PAPER)
	var light := Palette.color(Palette.ColorName.PLINTH_LIGHT)
	draw_string(font, Vector2(SIGN.position.x, below), "You have two different saved games. Which one do you keep?",
			HORIZONTAL_ALIGNMENT_CENTER, SIGN.size.x, 20, paper)
	var lines := which_lines() if _page == "keep" else PackedStringArray()
	for i in lines.size():
		var width := CediText.width(font, lines[i], 16)
		CediText.draw(self, font, Vector2(SIGN.get_center().x - width / 2.0, below + 34.0 + 26.0 * i), lines[i], 16,
				Palette.color(Palette.ColorName.KENTE_GOLD))
	draw_string(font, Vector2(SIGN.position.x, below + 112.0),
			"Choose on her phone. The other one is replaced by the one you keep.", HORIZONTAL_ALIGNMENT_CENTER,
			SIGN.size.x, 15, light)


# The sign in `rect`: a wooden frame round Ghana's red, gold, and green, with
# AKWAABA!, GOLD COAST, and HUSTLE · LEARN · RISE. Its writing grows with it.
func _draw_sign(rect: Rect2) -> void:
	var font := ThemeDB.fallback_font
	var paper := Palette.color(Palette.ColorName.PAPER)
	var ink := Palette.color(Palette.ColorName.DARK_BROWN)
	var grow := rect.size.x / SIGN.size.x
	var frame := StyleBoxFlat.new()
	frame.bg_color = Palette.color(Palette.ColorName.WOOD_DARK)
	frame.set_corner_radius_all(18)
	frame.border_color = ink
	frame.set_border_width_all(3)
	frame.shadow_color = Color(0, 0, 0, 0.4)
	frame.shadow_size = 14
	frame.shadow_offset = Vector2(5, 7)
	draw_style_box(frame, rect)
	var inner := rect.grow(-14.0)
	var band := inner.size.y / 3.0
	var bands := [Palette.ColorName.TILE_RED, Palette.ColorName.KENTE_GOLD, Palette.ColorName.PALM_GREEN]
	for i in 3:
		draw_rect(Rect2(inner.position + Vector2(0.0, band * i), Vector2(inner.size.x, band)), Palette.color(bands[i]))
	for corner in [Vector2(8, 8), Vector2(rect.size.x - 8, 8), Vector2(8, rect.size.y - 8), Vector2(rect.size.x - 8, rect.size.y - 8)]:
		draw_circle(rect.position + corner, 3.0, Palette.color(Palette.ColorName.ALUMINIUM)) # nails
	draw_string(font, inner.position + Vector2(0.0, band * 0.68), "AKWAABA!", HORIZONTAL_ALIGNMENT_CENTER, inner.size.x,
			int(34 * grow), paper)
	var title_at := inner.position + Vector2(0.0, band * 1.5 + 28.0 * grow)
	draw_string_outline(font, title_at, "GOLD COAST", HORIZONTAL_ALIGNMENT_CENTER, inner.size.x, int(80 * grow),
			int(12 * grow), paper)
	draw_string(font, title_at, "GOLD COAST", HORIZONTAL_ALIGNMENT_CENTER, inner.size.x, int(80 * grow), ink)
	for x in [inner.position.x + 34.0 * grow, inner.end.x - 34.0 * grow]:
		_star(Vector2(x, inner.position.y + band * 1.5), 20.0 * grow, Palette.color(Palette.ColorName.SHITO_BLACK))
	draw_string(font, inner.position + Vector2(0.0, band * 2.66), "HUSTLE  ·  LEARN  ·  RISE", HORIZONTAL_ALIGNMENT_CENTER,
			inner.size.x, int(26 * grow), paper)


# A five-pointed star, like the black star on Ghana's flag.
func _star(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var angle := -PI / 2.0 + i * PI / 5.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius * (1.0 if i % 2 == 0 else 0.4))
	draw_colored_polygon(points, color)
