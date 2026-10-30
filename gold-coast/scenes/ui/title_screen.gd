class_name TitleScreen
extends Control
## The title screen, when the game starts: GOLD COAST painted on a sign in
## Ghana's colors, and her phone, held up, with the start menu:
## - CONTINUE (only if there's a saved game): carries on from it. Under the
##   sign it says when it was saved, and how much money she had.
## - NEW GAME: a fresh start. If there's a saved game it asks first; the old
##   save stays until the new game saves over it.
## - HOW TO PLAY: the controls and the basics, a page at a time
## The game waits, paused, until you choose. (In a web browser, choosing is also
## the click the browser waits for before the game may play sounds.)

## Sent when you've chosen how to start: `continuing` is true to carry on from
## the saved game, and false for a new game.
signal started(continuing: bool)

const SIGN := Rect2(430.0, 88.0, 650.0, 300.0)

## The phone the start menu is on.
@export var phone: Phone

var _open := false
var _items := PackedStringArray()
var _saved := {}
# What the phone's page is for: "" (the menu), "new", or "help".
var _page := ""
var _help_page := 0


func _ready() -> void:
	visible = false
	phone.item_chosen.connect(_on_item_chosen)
	phone.page_accepted.connect(_on_page_accepted)
	phone.page_scrolled.connect(_on_page_scrolled)
	phone.back_pressed.connect(_on_back_pressed)


## Shows the title screen, and pauses the game until you choose how to start.
func open() -> void:
	_saved = GameState.peek_save()
	_open = true
	visible = true
	get_tree().paused = true
	phone.hold_up(true)
	_show_menu(0)
	queue_redraw()


## Whether the title screen is showing.
func is_open() -> bool:
	return _open


## The items on the phone's start menu.
func items() -> PackedStringArray:
	return _items


## What the title screen says about the saved game ("" if there isn't one).
func saved_game_line() -> String:
	if _saved.is_empty():
		return ""
	var day := int(_saved.day)
	return "Saved game: %s, day %d, %s  ·  %s" % [Format.weekday(day), day, Format.clock(float(_saved.minutes)),
			Format.cedis(int(_saved.money))]


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	var key := Phone.key_for(event)
	if key != "":
		phone.press(key)
		get_viewport().set_input_as_handled()


func _on_item_chosen(index: int) -> void:
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


# C goes back from a page to the start menu.
func _on_back_pressed() -> void:
	if _open and _page != "":
		_show_menu(_items.find("NEW GAME" if _page == "new" else "HOW TO PLAY"))


func _show_menu(selected: int) -> void:
	_page = ""
	_items = PackedStringArray(["CONTINUE", "NEW GAME", "HOW TO PLAY"] if not _saved.is_empty()
			else ["NEW GAME", "HOW TO PLAY"])
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
	var ink := Palette.color(Palette.ColorName.DARK_BROWN)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.07, 0.04, 0.02, 0.62)) # dim the town behind
	# The sign: a wooden frame round Ghana's red, gold, and green.
	var frame := StyleBoxFlat.new()
	frame.bg_color = Palette.color(Palette.ColorName.WOOD_DARK)
	frame.set_corner_radius_all(18)
	frame.border_color = ink
	frame.set_border_width_all(3)
	frame.shadow_color = Color(0, 0, 0, 0.4)
	frame.shadow_size = 14
	frame.shadow_offset = Vector2(5, 7)
	draw_style_box(frame, SIGN)
	var inner := SIGN.grow(-14.0)
	var band := inner.size.y / 3.0
	var bands := [Palette.ColorName.TILE_RED, Palette.ColorName.KENTE_GOLD, Palette.ColorName.PALM_GREEN]
	for i in 3:
		draw_rect(Rect2(inner.position + Vector2(0.0, band * i), Vector2(inner.size.x, band)), Palette.color(bands[i]))
	for corner in [Vector2(8, 8), Vector2(SIGN.size.x - 8, 8), Vector2(8, SIGN.size.y - 8), Vector2(SIGN.size.x - 8, SIGN.size.y - 8)]:
		draw_circle(SIGN.position + corner, 3.0, Palette.color(Palette.ColorName.ALUMINIUM)) # nails
	draw_string(font, inner.position + Vector2(0.0, band * 0.68), "AKWAABA!", HORIZONTAL_ALIGNMENT_CENTER, inner.size.x,
			34, paper)
	var title_at := inner.position + Vector2(0.0, band * 1.5 + 28.0)
	draw_string_outline(font, title_at, "GOLD COAST", HORIZONTAL_ALIGNMENT_CENTER, inner.size.x, 80, 12, paper)
	draw_string(font, title_at, "GOLD COAST", HORIZONTAL_ALIGNMENT_CENTER, inner.size.x, 80, ink)
	for x in [inner.position.x + 34.0, inner.end.x - 34.0]:
		_star(Vector2(x, inner.position.y + band * 1.5), 20.0, Palette.color(Palette.ColorName.SHITO_BLACK))
	draw_string(font, inner.position + Vector2(0.0, band * 2.66), "HUSTLE  ·  LEARN  ·  RISE", HORIZONTAL_ALIGNMENT_CENTER,
			inner.size.x, 26, paper)
	# What's saved, and how to choose.
	var below := SIGN.end.y + 44.0
	var saved := saved_game_line()
	if saved == "":
		draw_string(font, Vector2(SIGN.position.x, below), "No saved game yet. Start a new one!", HORIZONTAL_ALIGNMENT_CENTER,
				SIGN.size.x, 20, paper)
	else:
		var width := CediText.width(font, saved, 20)
		CediText.draw(self, font, Vector2(SIGN.get_center().x - width / 2.0, below), saved, 20, paper)
	draw_string(font, Vector2(SIGN.position.x, below + 34.0), "Choose on her phone: the arrow keys and Enter, or click its keys.",
			HORIZONTAL_ALIGNMENT_CENTER, SIGN.size.x, 15, Palette.color(Palette.ColorName.PLINTH_LIGHT))


# A five-pointed star, like the black star on Ghana's flag.
func _star(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var angle := -PI / 2.0 + i * PI / 5.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius * (1.0 if i % 2 == 0 else 0.4))
	draw_colored_polygon(points, color)
