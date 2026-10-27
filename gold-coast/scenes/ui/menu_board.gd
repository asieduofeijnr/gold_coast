class_name MenuBoard
extends Control
## A chop bar's menu, painted on a wooden board like the hand-painted signs
## outside real chop bars: every dish with a little picture, how filling it is,
## and its price, plus your mobile money balance along the bottom. Prices you
## can't afford are painted red.
##
## Under the shop's name, the owner talks to you (see `line`).
## Choose a dish with the arrow keys (or W and S) and Enter (or E), or point
## and click. Esc, the X, or a click outside the board closes it.
## It covers the whole screen (dimming the game behind it), and it keeps
## working while the game is paused.

## Sent when you choose a dish, with its number in `foods`.
signal chosen(index: int)
## Sent when the board closes.
signal closed

## The board's size with six rows (a board with more or fewer rows is taller or shorter).
const BOARD_SIZE := Vector2(480, 562)
const BOARD_ROWS := 6
const FRAME := 12.0
const HEADER := 84.0
const STRIPE := 10.0
const SPEECH := 38.0
const ROW := 52.0
const MOTTO := 28.0
const FOOTER := 58.0
const CLOSE_RADIUS := 15.0
## The colors of the kente stripe under the shop's name, in order.
const STRIPE_COLORS := [Palette.ColorName.KENTE_GOLD, Palette.ColorName.PALM_GREEN, Palette.ColorName.KENTE_GOLD,
		Palette.ColorName.TILE_RED, Palette.ColorName.DARK_BROWN]

## The small words above the shop's name.
@export var owner_line := "MAAME ESI'S"
## The color of the band the shop's name is painted on.
@export var header_color := Palette.ColorName.TILE_RED
## The shop's name, painted big across the top.
@export var shop_name := "CHOP BAR"
## A saying painted along the bottom.
@export var motto := "NO FOOD FOR LAZY MAN"
## Who runs the shop and talks to you from the board, and the color of her duku.
@export var speaker := "Maame Esi"
@export var speaker_headwrap := Palette.ColorName.TILE_RED
## What the Enter key does, in the hints along the bottom.
@export var accept_hint := "buy"

## What the shop owner is saying to you, shown under the shop's name.
var line := "":
	set(value):
		line = value
		_line_pop = 1.0
		var tween := create_tween()
		tween.tween_property(self, "_line_pop", 0.0, 0.35)
		queue_redraw()

## The dishes on the board.
var foods: Array[Food] = []
## Which dish is picked (highlighted).
var selected := 0:
	set(value):
		selected = value
		_red_row = -1
		queue_redraw()

var _open := false
var _tween: Tween
# How big the board is drawn while it pops open (1 = full size). Only the
# drawing grows: the board always covers the whole screen, so clicks land
# even while it's opening.
var _pop := 1.0:
	set(value):
		_pop = value
		queue_redraw()
var _shake := 0.0:
	set(value):
		_shake = value
		queue_redraw()
# A row whose price stays red because you just couldn't afford it.
var _red_row := -1
var _close_hovered := false
# Lights up the owner's words for a moment when they change.
var _line_pop := 0.0:
	set(value):
		_line_pop = value
		queue_redraw()


func _ready() -> void:
	visible = false
	GameState.money_changed.connect(_on_money_changed)


## Opens the board with these dishes.
func open(menu: Array[Food]) -> void:
	foods = menu
	_show_board()


# Pops the board open, with whatever rows it has (see _row_count()).
func _show_board() -> void:
	selected = clampi(selected, 0, maxi(_row_count() - 1, 0))
	_open = true
	visible = true
	_pop = 0.92
	modulate.a = 0.0
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_parallel()
	_tween.tween_property(self, "_pop", 1.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate:a", 1.0, 0.12)
	queue_redraw()


## Closes the board (and sends `closed`).
func close() -> void:
	if not _open:
		return
	_open = false
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, 0.1)
	_tween.tween_callback(hide)
	closed.emit()


## Whether the board is open.
func is_open() -> bool:
	return _open


## Shakes the board, like shaking your head. If `red_row` is a dish's number,
## its price stays red until you pick something else.
func shake(red_row := -1) -> void:
	_red_row = red_row
	var tween := create_tween()
	for offset in [9.0, -9.0, 6.0, -6.0, 3.0, 0.0]:
		tween.tween_property(self, "_shake", offset, 0.045)


## The middle of a dish's row, in the board's own coordinates (for clicking it).
func row_center(index: int) -> Vector2:
	return _row_rect(index).get_center()


func _unhandled_input(event: InputEvent) -> void:
	if not _open or _row_count() == 0:
		return
	if event.is_action_pressed("ui_up", true) or event.is_action_pressed("move_forward", true):
		selected = posmod(selected - 1, _row_count())
	elif event.is_action_pressed("ui_down", true) or event.is_action_pressed("move_back", true):
		selected = posmod(selected + 1, _row_count())
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		chosen.emit(selected)
	elif event.is_action_pressed("ui_cancel"):
		close()
	else:
		return
	get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if not _open:
		return
	if event is InputEventMouseMotion:
		var point := (event as InputEventMouseMotion).position
		var row := _row_at(point)
		if row >= 0 and row != selected:
			selected = row
		var over_close := _close_center().distance_to(point) <= CLOSE_RADIUS
		if over_close != _close_hovered:
			_close_hovered = over_close
			queue_redraw()
	elif event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		if not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
			return
		accept_event()
		if _close_center().distance_to(click.position) <= CLOSE_RADIUS or not _board_rect().has_point(click.position):
			close()
			return
		var row := _row_at(click.position)
		if row >= 0:
			selected = row
			chosen.emit(row)


func _on_money_changed(_money: int) -> void:
	queue_redraw()


# --- Layout -------------------------------------------------------------------

# How many rows the board has: one per dish. (A board of something else, like
# CourseBoard, counts its own rows.)
func _row_count() -> int:
	return foods.size()


func _board_rect() -> Rect2:
	var board_size := Vector2(BOARD_SIZE.x, BOARD_SIZE.y + (_row_count() - BOARD_ROWS) * ROW)
	return Rect2((size - board_size) / 2.0 + Vector2(_shake, 0.0), board_size)


func _inner_rect() -> Rect2:
	return _board_rect().grow(-FRAME)


func _row_rect(index: int) -> Rect2:
	var inner := _inner_rect()
	return Rect2(inner.position + Vector2(8.0, HEADER + STRIPE + SPEECH + 6.0 + index * ROW),
			Vector2(inner.size.x - 16.0, ROW))


func _row_at(point: Vector2) -> int:
	for i in _row_count():
		if _row_rect(i).has_point(point):
			return i
	return -1


func _close_center() -> Vector2:
	var board := _board_rect()
	return Vector2(board.end.x - 4.0, board.position.y + 4.0)


# --- Drawing ------------------------------------------------------------------

func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.35)) # dim the game behind
	draw_set_transform(size / 2.0 * (1.0 - _pop), 0.0, Vector2.ONE * _pop) # grow from the middle as it opens
	var board := _board_rect()
	var frame := _style(Palette.ColorName.WOOD_DARK, 16)
	frame.border_color = _color(Palette.ColorName.DARK_BROWN)
	frame.set_border_width_all(3)
	frame.shadow_color = Color(0, 0, 0, 0.35)
	frame.shadow_size = 12
	frame.shadow_offset = Vector2(4, 6)
	draw_style_box(frame, board)
	for corner in [Vector2(7, 7), Vector2(board.size.x - 7, 7), Vector2(7, board.size.y - 7),
			Vector2(board.size.x - 7, board.size.y - 7)]:
		draw_circle(board.position + corner, 2.5, _color(Palette.ColorName.ALUMINIUM)) # nails

	var inner := _inner_rect()
	draw_rect(inner, _color(Palette.ColorName.WALL_CREAM))
	_draw_header(font, Rect2(inner.position, Vector2(inner.size.x, HEADER)))
	var stripe_top := inner.position.y + HEADER
	var block := 16.0
	var x := 0.0
	var i := 0
	while x < inner.size.x:
		draw_rect(Rect2(inner.position.x + x, stripe_top, minf(block, inner.size.x - x), STRIPE),
				_color(STRIPE_COLORS[i % STRIPE_COLORS.size()]))
		x += block
		i += 1
	_draw_speech(font, Rect2(inner.position.x, stripe_top + STRIPE, inner.size.x, SPEECH))
	for row in _row_count():
		_draw_row(font, row)
	var motto_top := _row_rect(_row_count()).position.y
	draw_string(font, Vector2(inner.position.x, motto_top + 19.0), motto, HORIZONTAL_ALIGNMENT_CENTER, inner.size.x, 13,
			_color(Palette.ColorName.TILE_RED))
	_draw_footer(font, Rect2(Vector2(inner.position.x, inner.end.y - FOOTER), Vector2(inner.size.x, FOOTER)))
	_draw_close_button()


func _draw_header(font: Font, header: Rect2) -> void:
	draw_rect(header, _color(header_color))
	draw_string(font, header.position + Vector2(0, 25), owner_line, HORIZONTAL_ALIGNMENT_CENTER, header.size.x, 15,
			_color(Palette.ColorName.KENTE_GOLD))
	var title_at := header.position + Vector2(0, 68)
	draw_string_outline(font, title_at, shop_name, HORIZONTAL_ALIGNMENT_CENTER, header.size.x, 40, 9,
			_color(Palette.ColorName.DARK_BROWN))
	draw_string(font, title_at, shop_name, HORIZONTAL_ALIGNMENT_CENTER, header.size.x, 40, _color(Palette.ColorName.PAPER))


# The owner talking to you: a little portrait, their name, and what they say.
func _draw_speech(font: Font, strip: Rect2) -> void:
	draw_rect(strip, _color(Palette.ColorName.PLINTH_LIGHT) * Color(1, 1, 1, 0.35 + 0.4 * _line_pop))
	var face := Vector2(strip.position.x + 26.0, strip.get_center().y + 1.0)
	draw_circle(face, 13.0, _color(Palette.ColorName.DARK_BROWN))
	draw_circle(face, 11.5, _color(Palette.ColorName.SKIN_DEEP))
	draw_rect(Rect2(face - Vector2(12, 14), Vector2(24, 9)), _color(speaker_headwrap)) # her duku
	draw_circle(face + Vector2(-4, 1), 1.5, _color(Palette.ColorName.DARK_BROWN))
	draw_circle(face + Vector2(4, 1), 1.5, _color(Palette.ColorName.DARK_BROWN))
	var text_x := strip.position.x + 48.0
	draw_string(font, Vector2(text_x, strip.position.y + 14.0), speaker.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 10,
			_color(Palette.ColorName.TILE_RED))
	# Shrink long lines until they fit.
	var room := strip.end.x - text_x - 10.0
	var font_size := 15
	while font_size > 10 and font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > room:
		font_size -= 1
	draw_string(font, Vector2(text_x, strip.position.y + 31.0), line, HORIZONTAL_ALIGNMENT_LEFT, room, font_size,
			_color(Palette.ColorName.DARK_BROWN))


func _draw_row(font: Font, index: int) -> void:
	var food := foods[index]
	var row := _row_rect(index)
	var ink := _color(Palette.ColorName.DARK_BROWN)
	_draw_row_backing(row, index)
	_draw_dish(food, Vector2(row.position.x + 38.0, row.get_center().y + 3.0))
	draw_string(font, row.position + Vector2(68, 23), food.title, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, ink)
	draw_string(font, row.position + Vector2(68, 41), food.description, HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
			_color(Palette.ColorName.WOOD_DARK))
	var too_dear := food.price > GameState.money or index == _red_row
	CediText.draw_right(self, font, row.end.x - 12.0, row.position.y + 24.0, Format.cedis(food.price), 19,
			_color(Palette.ColorName.TILE_RED) if too_dear else ink)
	var filling := "+%d food" % roundi(food.hunger)
	draw_string(font, Vector2(row.end.x - 12.0 - font.get_string_size(filling, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x,
			row.position.y + 41.0), filling, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, _color(Palette.ColorName.PALM_GREEN))


# The row's backing: gold with a red pointer if it's the one picked, otherwise
# a dotted line under it (except under the last row).
func _draw_row_backing(row: Rect2, index: int) -> void:
	if index == selected:
		draw_style_box(_style(Palette.ColorName.KENTE_GOLD, 9), row)
		var middle := row.get_center().y
		draw_colored_polygon(PackedVector2Array([Vector2(row.position.x + 3, middle - 7),
				Vector2(row.position.x + 11, middle), Vector2(row.position.x + 3, middle + 7)]),
				_color(Palette.ColorName.TILE_RED))
	elif index < _row_count() - 1:
		# A dotted line between rows.
		var y := row.end.y
		var dot_x := row.position.x + 12.0
		while dot_x < row.end.x - 12.0:
			draw_rect(Rect2(dot_x, y - 1.0, 3.0, 2.0), _color(Palette.ColorName.PLINTH_LIGHT))
			dot_x += 7.0


# A little painted picture of the dish: a bowl of it, or a sachet of water.
func _draw_dish(food: Food, center: Vector2) -> void:
	var outline := _color(Palette.ColorName.DARK_BROWN)
	if not food.in_bowl:
		var sachet := _style(food.color, 7)
		sachet.border_color = _color(Palette.ColorName.ENAMEL_RIM)
		sachet.set_border_width_all(2)
		draw_style_box(sachet, Rect2(center - Vector2(14, 12), Vector2(28, 22)))
		draw_line(center + Vector2(-8, -5), center + Vector2(6, -5), _color(Palette.ColorName.PAPER), 2.0)
		return
	_ellipse(center + Vector2(0, -3), Vector2(16, 9), _color(food.color))
	draw_circle(center + Vector2(4, -8), 5.5, _color(food.topping))
	var bowl := PackedVector2Array()
	for step in 13:
		var angle := PI * step / 12.0
		bowl.append(center + Vector2(cos(angle) * 20.0, sin(angle) * 13.0))
	draw_colored_polygon(bowl, _color(Palette.ColorName.ENAMEL_WHITE))
	draw_polyline(bowl, outline, 1.5)
	draw_line(center + Vector2(-20, 0), center + Vector2(20, 0), _color(Palette.ColorName.ENAMEL_RIM), 3.0)


func _draw_footer(font: Font, footer: Rect2) -> void:
	draw_rect(footer, _color(Palette.ColorName.PALM_GREEN))
	var paper := _color(Palette.ColorName.PAPER)
	# A little phone, then the mobile money balance.
	var phone := Rect2(footer.position + Vector2(14, 11), Vector2(20, 36))
	draw_style_box(_style(Palette.ColorName.PHONE_BODY, 5), phone)
	draw_rect(Rect2(phone.position + Vector2(4, 5), Vector2(12, 10)), _color(Palette.ColorName.LCD_GLOW))
	draw_string(font, footer.position + Vector2(44, 23), "MoMo balance", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, paper)
	CediText.draw(self, font, footer.position + Vector2(44, 46), Format.cedis(GameState.money), 21, paper)
	# What the keys do.
	var right := footer.end.x - 12.0
	var line_1 := footer.position.y + 24.0
	var line_2 := footer.position.y + 46.0
	var buy_starts := _draw_hint(font, right, line_1, accept_hint, "Enter")
	_draw_hint(font, buy_starts - 10.0, line_1, "choose", "", true)
	_draw_hint(font, right, line_2, "leave", "Esc")


# One key hint, like [Enter] buy, ending at `right`. Returns where it starts.
# `arrows` draws up and down arrow keys instead of a named key.
func _draw_hint(font: Font, right: float, baseline: float, words: String, key: String, arrows := false) -> float:
	var paper := _color(Palette.ColorName.PAPER)
	var words_width := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	var x := right - words_width
	draw_string(font, Vector2(x, baseline), words, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, paper)
	var keys: Array = [["▼", 18.0], ["▲", 18.0]] if arrows else [[key, font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 10.0]]
	for key_info: Array in keys:
		var width: float = key_info[1]
		x -= width + 5.0
		var cap := Rect2(x, baseline - 14.0, width, 18.0)
		var style := _style(Palette.ColorName.PHONE_KEY, 4)
		style.border_width_bottom = 2
		style.border_color = _color(Palette.ColorName.PHONE_KEY_EDGE)
		draw_style_box(style, cap)
		var ink := _color(Palette.ColorName.PHONE_PRINT)
		if arrows:
			var middle := cap.get_center()
			var up: bool = key_info[0] == "▲"
			var tip := -4.0 if up else 4.0
			draw_colored_polygon(PackedVector2Array([middle + Vector2(-4, -tip * 0.6), middle + Vector2(4, -tip * 0.6),
					middle + Vector2(0, tip)]), ink)
		else:
			draw_string(font, Vector2(cap.position.x, baseline), key_info[0], HORIZONTAL_ALIGNMENT_CENTER, width, 11, ink)
	return x


func _draw_close_button() -> void:
	var center := _close_center()
	draw_circle(center, CLOSE_RADIUS + 2.0, _color(Palette.ColorName.DARK_BROWN))
	draw_circle(center, CLOSE_RADIUS, _color(Palette.ColorName.KENTE_GOLD if _close_hovered else Palette.ColorName.TILE_RED))
	var paper := _color(Palette.ColorName.PAPER)
	draw_line(center + Vector2(-5, -5), center + Vector2(5, 5), paper, 3.0)
	draw_line(center + Vector2(5, -5), center + Vector2(-5, 5), paper, 3.0)


func _ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for step in 24:
		var angle := TAU * step / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)


func _style(fill: Palette.ColorName, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = _color(fill)
	style.set_corner_radius_all(radius)
	return style


func _color(color_name: Palette.ColorName) -> Color:
	return Palette.color(color_name)
