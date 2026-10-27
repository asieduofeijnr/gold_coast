@tool
class_name Phone
extends Control
## An old button phone (in the style of the Nokia 1100) whose little green
## screen shows the time, the day, your mobile money balance, and your needs.
## It's all drawn in code. The screen has its own pixel font, so the cedi sign
## (₵) always shows.
##
## Where an old Nokia had its signal and battery bars, down the sides of the
## screen, this phone has a food bar (left) and an energy bar (right).
##
## Set `screen_value` to change the big text; the backlight flashes each time.
## show_sms() shows a text message, like the ones mobile money sends after
## every payment: the phone buzzes and beeps the old text message tone.

const SIZE := Vector2(160, 318)
const LCD_DOTS := Vector2i(84, 48) # the screen's resolution, like old Nokias
const DOT := 1.5 # how big each screen dot is
const LCD_POSITION := Vector2(17, 51)
## Below this, a need's bar and icon blink.
const LOW_NEED := 25.0
const BAR_SEGMENTS := 8
## The most characters that fit across the screen.
const MAX_CHARACTERS := 14
## The most lines a text message can have.
const SMS_LINES := 4
## The text message tone: how high it beeps (in hertz) and how loud it is.
const TONE_PITCH := 1400.0
const TONE_VOLUME_DB := -14.0

## The screen's pixel font: 5 x 7 dots per letter, rows split by spaces ("#" = on).
const LCD_FONT := {
	"A": ".###. #...# #...# ##### #...# #...# #...#",
	"B": "####. #...# #...# ####. #...# #...# ####.",
	"C": ".###. #...# #.... #.... #.... #...# .###.",
	"D": "####. #...# #...# #...# #...# #...# ####.",
	"E": "##### #.... #.... ####. #.... #.... #####",
	"F": "##### #.... #.... ####. #.... #.... #....",
	"G": ".###. #...# #.... #.### #...# #...# .###.",
	"H": "#...# #...# #...# ##### #...# #...# #...#",
	"I": ".###. ..#.. ..#.. ..#.. ..#.. ..#.. .###.",
	"J": "..### ...#. ...#. ...#. ...#. #..#. .##..",
	"K": "#...# #..#. #.#.. ##... #.#.. #..#. #...#",
	"L": "#.... #.... #.... #.... #.... #.... #####",
	"M": "#...# ##.## #.#.# #.#.# #...# #...# #...#",
	"N": "#...# #...# ##..# #.#.# #..## #...# #...#",
	"O": ".###. #...# #...# #...# #...# #...# .###.",
	"P": "####. #...# #...# ####. #.... #.... #....",
	"Q": ".###. #...# #...# #...# #.#.# #..#. .##.#",
	"R": "####. #...# #...# ####. #.#.. #..#. #...#",
	"S": ".#### #.... #.... .###. ....# ....# ####.",
	"T": "##### ..#.. ..#.. ..#.. ..#.. ..#.. ..#..",
	"U": "#...# #...# #...# #...# #...# #...# .###.",
	"V": "#...# #...# #...# #...# #...# .#.#. ..#..",
	"W": "#...# #...# #...# #.#.# #.#.# #.#.# .#.#.",
	"X": "#...# #...# .#.#. ..#.. .#.#. #...# #...#",
	"Y": "#...# #...# .#.#. ..#.. ..#.. ..#.. ..#..",
	"Z": "##### ....# ...#. ..#.. .#... #.... #####",
	"0": ".###. #...# #..## #.#.# ##..# #...# .###.",
	"1": "..#.. .##.. ..#.. ..#.. ..#.. ..#.. .###.",
	"2": ".###. #...# ....# ...#. ..#.. .#... #####",
	"3": "##### ...#. ..#.. ...#. ....# #...# .###.",
	"4": "...#. ..##. .#.#. #..#. ##### ...#. ...#.",
	"5": "##### #.... ####. ....# ....# #...# .###.",
	"6": "..##. .#... #.... ####. #...# #...# .###.",
	"7": "##### ....# ...#. ..#.. .#... .#... .#...",
	"8": ".###. #...# #...# .###. #...# #...# .###.",
	"9": ".###. #...# #...# .#### ....# ...#. .##..",
	"₵": "..#.. .#### #.#.. #.#.. #.#.. .#### ..#..",
	".": "..... ..... ..... ..... ..... .##.. .##..",
	",": "..... ..... ..... ..... .##.. ..#.. .#...",
	"-": "..... ..... ..... ##### ..... ..... .....",
	":": "..... .##.. .##.. ..... .##.. .##.. .....",
	"!": "..#.. ..#.. ..#.. ..#.. ..#.. ..... ..#..",
	"?": ".###. #...# ....# ...#. ..#.. ..... ..#..",
	" ": "..... ..... ..... ..... ..... ..... .....",
}
const FOOD_ICON := [".#.#.", "#.#..", ".....", "#####", "#####", ".###.", "....."] # a steaming bowl
const ENERGY_ICON := ["...##", "..##.", ".##..", "#####", "..##.", ".##..", "##..."] # a lightning bolt
const MESSAGE_ICON := ["#######", "##...##", "#.#.#.#", "#..#..#", "#######"] # an envelope
## The keypad: each key's number and the letters printed beside it.
const KEYS := [["1", ""], ["2", "abc"], ["3", "def"], ["4", "ghi"], ["5", "jkl"], ["6", "mno"],
		["7", "pqrs"], ["8", "tuv"], ["9", "wxyz"], ["*", "+"], ["0", ""], ["#", ""]]

## The brand printed above the screen.
@export var brand := "CHALE":
	set(value):
		brand = value
		queue_redraw()
## The time in the top bar, between the food and energy icons.
@export var status_time := "07:00":
	set(value):
		status_time = value
		queue_redraw()
## The day line, under the top bar.
@export var screen_day := "MON DAY 1":
	set(value):
		screen_day = value
		queue_redraw()
## The line above the big text.
@export var screen_title := "MOBILE MONEY":
	set(value):
		screen_title = value
		queue_redraw()
## The big text in the middle of the screen. The backlight flashes when it changes.
@export var screen_value := "GH₵100.00":
	set(value):
		screen_value = value
		queue_redraw()
		if is_node_ready() and not Engine.is_editor_hint():
			_flash()
## The food bar down the left edge, from 0 (starving) to 100 (full).
@export_range(0.0, 100.0) var hunger := 100.0:
	set(value):
		hunger = value
		queue_redraw()
## The energy bar down the right edge, from 0 (exhausted) to 100 (rested).
@export_range(0.0, 100.0) var energy := 100.0:
	set(value):
		energy = value
		queue_redraw()

## How brightly the backlight is on, from 0 (off) to 1 (fully on).
var backlight := 0.0:
	set(value):
		backlight = value
		queue_redraw()

## How far the phone is shaken sideways while it buzzes, in pixels.
var shake := 0.0:
	set(value):
		shake = value
		queue_redraw()

var _flash_tween: Tween
var _buzz_tween: Tween
var _blink_time := 0.0
var _message := ""
var _message_time_left := 0.0
var _sms := PackedStringArray()
var _sms_time_left := 0.0
var _tone: AudioStreamPlayer


## Whether the screen's pixel font has every character in `text`.
func can_show(text: String) -> bool:
	for character in text.to_upper():
		if not LCD_FONT.has(character):
			return false
	return true


## Shows `text` instead of the title line for a few seconds, like a quick
## phone notification.
func show_message(text: String, seconds := 2.5) -> void:
	_message = text
	_message_time_left = seconds
	queue_redraw()


## The title line as it shows right now (a message, if one is showing).
func shown_title() -> String:
	return _message if _message_time_left > 0.0 else screen_title


## Shows a text message for a few seconds, using the whole screen: up to four
## short lines (MAX_CHARACTERS each), like "PAYMENT SENT" and "GH₵25.00". The
## backlight comes on and the phone buzzes.
func show_sms(lines: PackedStringArray, seconds := 4.0) -> void:
	_sms = lines.slice(0, SMS_LINES)
	_sms_time_left = seconds
	queue_redraw()
	_flash()
	_buzz()
	_beep()


## The text message on the screen right now, or an empty list if there isn't one.
func shown_sms() -> PackedStringArray:
	return _sms if _sms_time_left > 0.0 else PackedStringArray()


## Whether the text message tone is playing.
func is_beeping() -> bool:
	return _tone != null and _tone.playing


## Whether a low need is blinking on the screen.
func is_warning() -> bool:
	return hunger < LOW_NEED or energy < LOW_NEED


func _process(delta: float) -> void:
	if _message_time_left > 0.0:
		_message_time_left -= delta
		if _message_time_left <= 0.0:
			queue_redraw()
	if _sms_time_left > 0.0:
		_sms_time_left -= delta
		if _sms_time_left <= 0.0:
			queue_redraw()
	if is_warning():
		var was_on := _blink_on()
		_blink_time += delta
		if _blink_on() != was_on:
			queue_redraw()


# Blinking: on for half a second, off for half a second.
func _blink_on() -> bool:
	return fmod(_blink_time, 1.0) < 0.5


# Turn the backlight on, then let it fade, like a phone when you press a key.
func _flash() -> void:
	if _flash_tween != null:
		_flash_tween.kill()
	backlight = 1.0
	_flash_tween = create_tween()
	_flash_tween.tween_interval(0.4)
	_flash_tween.tween_property(self, "backlight", 0.0, 0.8)


# Shake from side to side for a moment, like a phone on vibrate.
func _buzz() -> void:
	if _buzz_tween != null:
		_buzz_tween.kill()
	_buzz_tween = create_tween()
	for i in 6:
		_buzz_tween.tween_property(self, "shake", 2.5 if i % 2 == 0 else -2.5, 0.04)
	_buzz_tween.tween_property(self, "shake", 0.0, 0.04)


# Beep the text message tone that old phones played: "SMS" in Morse code.
func _beep() -> void:
	if _tone == null:
		_tone = AudioStreamPlayer.new()
		_tone.stream = _make_tone()
		_tone.volume_db = TONE_VOLUME_DB
		add_child(_tone, false, Node.INTERNAL_MODE_FRONT)
	_tone.play()


# Makes the tone's sound wave in code, so there's no sound file: short and long
# beeps (S is · · ·, M is — —) with gaps between them.
static func _make_tone() -> AudioStreamWAV:
	var rate := 22050 # sound samples per second
	var dot := 0.06 # seconds
	var parts := [] # [seconds, beeping?]
	for letter in ["...", "--", "..."]:
		for mark in letter:
			parts.append([dot * 3.0 if mark == "-" else dot, true])
			parts.append([dot, false])
		parts.append([dot * 2.0, false])
	var data := PackedByteArray()
	var sample_count := 0
	for part: Array in parts:
		sample_count += int(part[0] * rate)
	data.resize(sample_count * 2) # two bytes per sample
	var n := 0
	for part: Array in parts:
		var length := int(part[0] * rate)
		for i in length:
			var value := 0.0
			if part[1]:
				var wave := TAU * TONE_PITCH * n / rate
				var fade := minf(1.0, minf(i, length - i) / 80.0) # soften the click at each end
				value = (0.6 * sin(wave) + 0.2 * sin(3.0 * wave)) * fade # a buzzy beep, like a phone speaker
			data.encode_s16(n * 2, int(value * 32767.0))
			n += 1
	var tone := AudioStreamWAV.new()
	tone.format = AudioStreamWAV.FORMAT_16_BITS
	tone.mix_rate = rate
	tone.data = data
	return tone


func _draw() -> void:
	draw_set_transform(Vector2(shake, 0.0))
	_draw_body()
	_draw_screen()
	_draw_navigation_keys()
	_draw_keypad()


func _draw_body() -> void:
	# The flashlight on the top edge, peeking out above the body.
	draw_style_box(_rounded(Palette.ColorName.PHONE_LIGHT, 3, Palette.ColorName.PHONE_KEY_EDGE, 1),
			Rect2(SIZE.x / 2.0 - 16.0, -4.0, 32.0, 9.0))
	var body := _rounded(Palette.ColorName.PHONE_BODY, 28, Palette.ColorName.PHONE_EDGE, 2)
	body.corner_radius_bottom_left = 36
	body.corner_radius_bottom_right = 36
	body.shadow_color = Palette.color(Palette.ColorName.PHONE_BEZEL) * Color(1, 1, 1, 0.5)
	body.shadow_size = 8
	body.shadow_offset = Vector2(3, 4)
	draw_style_box(body, Rect2(Vector2.ZERO, SIZE))
	# The earpiece slot and the brand name.
	draw_style_box(_rounded(Palette.ColorName.PHONE_BEZEL, 2), Rect2(SIZE.x / 2.0 - 18.0, 14.0, 36.0, 4.0))
	draw_string(ThemeDB.fallback_font, Vector2(0, 37), brand, HORIZONTAL_ALIGNMENT_CENTER, SIZE.x, 12,
			Palette.color(Palette.ColorName.PHONE_LOGO))


func _draw_screen() -> void:
	var lcd_size := Vector2(LCD_DOTS) * DOT
	draw_style_box(_rounded(Palette.ColorName.PHONE_BEZEL, 9),
			Rect2(LCD_POSITION - Vector2(6, 7), lcd_size + Vector2(12, 14)))
	var screen_color := Palette.color(Palette.ColorName.LCD_BACKGROUND).lerp(
			Palette.color(Palette.ColorName.LCD_GLOW), backlight)
	draw_rect(Rect2(LCD_POSITION, lcd_size), screen_color)
	# A faint grid of unlit dots, like a real LCD.
	var unlit := Palette.color(Palette.ColorName.LCD_PIXEL) * Color(1, 1, 1, 0.045)
	for y in LCD_DOTS.y:
		for x in LCD_DOTS.x:
			_dot(x, y, unlit)
	var ink := Palette.color(Palette.ColorName.LCD_PIXEL)
	if not shown_sms().is_empty():
		# A text message takes over the screen, under the time.
		_pattern(MESSAGE_ICON, Vector2i(0, 1), ink)
		_text(status_time, 0, 1, ink)
		for i in _sms.size():
			_text(_sms[i], 11 + i * 9, 1, ink)
		return
	_need_bar(hunger, FOOD_ICON, false, ink, unlit)
	_need_bar(energy, ENERGY_ICON, true, ink, unlit)
	_text(status_time, 0, 1, ink)
	_text(screen_day, 10, 1, ink)
	_text(shown_title(), 19, 1, ink)
	_text(screen_value, 29, 2, ink)


## A need's icon (at the top corner) and bar (down the edge). Like a Nokia's
## signal and battery bars, the segments get wider toward the top. A low need blinks.
func _need_bar(level: float, icon: Array, on_right: bool, ink: Color, unlit: Color) -> void:
	if level < LOW_NEED and not _blink_on():
		return
	_pattern(icon, Vector2i(LCD_DOTS.x - 5 if on_right else 0, 0), ink)
	var lit := ceili(level / (100.0 / BAR_SEGMENTS))
	for segment in BAR_SEGMENTS:
		@warning_ignore("integer_division")
		var width := 2 + segment / 2
		var bottom := LCD_DOTS.y - 1 - segment * 5
		for row in range(bottom - 3, bottom + 1):
			for i in width:
				_dot(LCD_DOTS.x - 1 - i if on_right else i, row, ink if segment < lit else unlit * Color(1, 1, 1, 3.0))


func _draw_navigation_keys() -> void:
	var y := 140.0
	var key := Palette.ColorName.PHONE_KEY
	var edge := Palette.ColorName.PHONE_KEY_EDGE
	var ink := Palette.color(Palette.ColorName.PHONE_PRINT)
	# A wide select key in the middle, with a dash on it.
	draw_style_box(_rounded(key, 10, edge, 1), Rect2(SIZE.x / 2.0 - 28.0, y, 56.0, 20.0))
	draw_rect(Rect2(SIZE.x / 2.0 - 9.0, y + 9.0, 18.0, 2.0), ink)
	# A scroll key (up and down arrows) on the left.
	var scroll := Rect2(16.0, y + 2.0, 28.0, 16.0)
	draw_style_box(_rounded(key, 8, edge, 1), scroll)
	var middle := scroll.get_center().x
	draw_colored_polygon(PackedVector2Array([Vector2(middle - 4, y + 9), Vector2(middle + 4, y + 9),
			Vector2(middle, y + 5)]), ink)
	draw_colored_polygon(PackedVector2Array([Vector2(middle - 4, y + 11), Vector2(middle + 4, y + 11),
			Vector2(middle, y + 15)]), ink)
	# A "C" (clear) key on the right.
	var clear := Rect2(SIZE.x - 44.0, y + 2.0, 28.0, 16.0)
	draw_style_box(_rounded(key, 8, edge, 1), clear)
	draw_string(ThemeDB.fallback_font, Vector2(clear.position.x, y + 15.0), "C", HORIZONTAL_ALIGNMENT_CENTER,
			clear.size.x, 12, ink)


func _draw_keypad() -> void:
	var font := ThemeDB.fallback_font
	var key_size := Vector2(40, 24)
	var gap := Vector2(7, 7)
	var start := Vector2((SIZE.x - (3.0 * key_size.x + 2.0 * gap.x)) / 2.0, 184.0)
	var ink := Palette.color(Palette.ColorName.PHONE_PRINT)
	var letters := Palette.color(Palette.ColorName.PHONE_KEY_EDGE)
	for i in KEYS.size():
		@warning_ignore("integer_division")
		var at := start + Vector2(i % 3, i / 3) * (key_size + gap)
		draw_style_box(_rounded(Palette.ColorName.PHONE_KEY, 11, Palette.ColorName.PHONE_KEY_EDGE, 1),
				Rect2(at, key_size))
		draw_string(font, at + Vector2(0, 17), KEYS[i][0], HORIZONTAL_ALIGNMENT_CENTER, key_size.x * 0.62, 14, ink)
		draw_string(font, at + Vector2(key_size.x * 0.5, 16), KEYS[i][1], HORIZONTAL_ALIGNMENT_CENTER,
				key_size.x * 0.45, 8, letters)
	# The microphone hole at the bottom.
	draw_circle(Vector2(SIZE.x / 2.0, SIZE.y - 7.0), 1.6, Palette.color(Palette.ColorName.PHONE_BEZEL))


## Writes `text` in the screen's pixel font, centred, starting at dot row `row`.
## `tall` is 1 for normal letters or 2 for tall ones.
func _text(text: String, row: int, tall: int, color: Color) -> void:
	text = text.to_upper()
	@warning_ignore("integer_division")
	var x := (LCD_DOTS.x - (text.length() * 6 - 1)) / 2
	for character in text:
		var rows: PackedStringArray = (LCD_FONT.get(character, LCD_FONT["?"]) as String).split(" ")
		for r in 7:
			for c in 5:
				if rows[r][c] == "#":
					for t in tall:
						_dot(x + c, row + r * tall + t, color)
		x += 6


func _pattern(rows: Array, at: Vector2i, color: Color) -> void:
	for r in rows.size():
		var row: String = rows[r]
		for c in row.length():
			if row[c] == "#":
				_dot(at.x + c, at.y + r, color)


func _dot(x: int, y: int, color: Color) -> void:
	if x < 0 or y < 0 or x >= LCD_DOTS.x or y >= LCD_DOTS.y:
		return
	draw_rect(Rect2(LCD_POSITION + Vector2(x, y) * DOT, Vector2.ONE * DOT * 0.92), color)


## A rounded rectangle in a palette color, with an optional outline.
func _rounded(fill: Palette.ColorName, radius: int, outline := Palette.ColorName.PHONE_EDGE,
		outline_width := 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.color(fill)
	style.set_corner_radius_all(radius)
	style.border_color = Palette.color(outline)
	style.set_border_width_all(outline_width)
	return style
