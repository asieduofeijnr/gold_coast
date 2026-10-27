class_name Nameplate
extends WorldLabel
## A building's name, floating over its roof while you point at it: what kind of
## building it is ("Apartment Block"), with its own name underneath ("Adom
## Court"). It stays on the screen, even when the roof is off the top edge.

const TITLE_SIZE := 15
const SUBTITLE_SIZE := 12
const PADDING := Vector2(12, 6)
const POINTER := 7.0
## How close it comes to the edge of the screen, in pixels.
const MARGIN := 6.0

## The first line, like "Apartment Block".
var title := "":
	set(value):
		title = value
		_measure()
## The second line, like "Adom Court" ("" for none).
var subtitle := "":
	set(value):
		subtitle = value
		_measure()

var _plate := Vector2.ZERO


## How big the plate is, in pixels.
func plate_size() -> Vector2:
	return _plate


func follow() -> void:
	super()
	# Keep the whole plate on the screen.
	var screen := get_viewport_rect().size
	position.x = clampf(position.x, _plate.x / 2.0 + MARGIN, screen.x - _plate.x / 2.0 - MARGIN)
	position.y = clampf(position.y, _plate.y + POINTER + MARGIN, screen.y - MARGIN)


func _measure() -> void:
	var font := ThemeDB.fallback_font
	var inside := Vector2(font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, TITLE_SIZE).x,
			font.get_height(TITLE_SIZE))
	if subtitle != "":
		inside.x = maxf(inside.x, font.get_string_size(subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, SUBTITLE_SIZE).x)
		inside.y += font.get_height(SUBTITLE_SIZE)
	_plate = inside + PADDING * 2.0
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var box := Rect2(Vector2(-_plate.x / 2.0, -POINTER - _plate.y), _plate)
	var gold := Palette.color(Palette.ColorName.KENTE_GOLD)
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.color(Palette.ColorName.PHONE_BEZEL) * Color(1, 1, 1, 0.9)
	style.set_corner_radius_all(8)
	style.border_color = gold
	style.set_border_width_all(2)
	style.shadow_color = Color(0, 0, 0, 0.25)
	style.shadow_size = 4
	style.shadow_offset = Vector2(1, 2)
	draw_style_box(style, box)
	# A little pointer down to the roof.
	draw_colored_polygon(PackedVector2Array([Vector2(-6, box.end.y - 1), Vector2(6, box.end.y - 1), Vector2(0, 0)]), gold)

	var baseline := box.position.y + PADDING.y + font.get_ascent(TITLE_SIZE)
	draw_string(font, Vector2(box.position.x, baseline), title, HORIZONTAL_ALIGNMENT_CENTER, box.size.x, TITLE_SIZE,
			Palette.color(Palette.ColorName.PAPER))
	if subtitle != "":
		baseline += font.get_descent(TITLE_SIZE) + font.get_ascent(SUBTITLE_SIZE)
		draw_string(font, Vector2(box.position.x, baseline), subtitle, HORIZONTAL_ALIGNMENT_CENTER, box.size.x,
				SUBTITLE_SIZE, gold)
