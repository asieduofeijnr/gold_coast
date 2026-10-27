class_name InteractionPrompt
extends WorldLabel
## The little sign over something she can use: the E key and what it does, like
## "E  Buy food". When you point at it with the mouse from further away, it shows
## a mouse instead of the key, because clicking walks her over to use it.

const FONT_SIZE := 16
const KEY_SIZE := 22.0
const PADDING := 7.0
const GAP := 8.0
const POINTER := 7.0

## What using it does, like "Buy food". It can show prices (with ₵).
var text := "":
	set(value):
		text = value
		queue_redraw()
## Shows a mouse instead of the E key.
var with_mouse := false:
	set(value):
		with_mouse = value
		queue_redraw()


func _init() -> void:
	super()
	bob = 2.0


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var size_of_box := Vector2(PADDING + KEY_SIZE + GAP + CediText.width(font, text, FONT_SIZE) + PADDING + 2.0,
			KEY_SIZE + PADDING * 2.0)
	var box := Rect2(Vector2(-size_of_box.x / 2.0, -POINTER - size_of_box.y), size_of_box)
	var back := Palette.color(Palette.ColorName.PHONE_BEZEL) * Color(1, 1, 1, 0.88)
	var gold := Palette.color(Palette.ColorName.KENTE_GOLD)
	var style := StyleBoxFlat.new()
	style.bg_color = back
	style.set_corner_radius_all(9)
	style.border_color = gold
	style.set_border_width_all(2)
	style.shadow_color = Color(0, 0, 0, 0.25)
	style.shadow_size = 4
	style.shadow_offset = Vector2(1, 2)
	draw_style_box(style, box)
	# A little pointer down to the spot.
	draw_colored_polygon(PackedVector2Array([Vector2(-6, box.end.y - 1), Vector2(6, box.end.y - 1), Vector2(0, 0)]), gold)

	var key := Rect2(box.position + Vector2(PADDING, PADDING), Vector2(KEY_SIZE, KEY_SIZE))
	if with_mouse:
		_draw_mouse(key)
	else:
		_draw_key(key, font)
	var text_x := key.end.x + GAP
	var baseline := box.position.y + box.size.y / 2.0 + FONT_SIZE * 0.36
	CediText.draw(self, font, Vector2(text_x, baseline), text, FONT_SIZE, Palette.color(Palette.ColorName.PAPER))


# A keyboard key with an E on it.
func _draw_key(key: Rect2, font: Font) -> void:
	var cap := StyleBoxFlat.new()
	cap.bg_color = Palette.color(Palette.ColorName.PHONE_KEY)
	cap.set_corner_radius_all(5)
	cap.border_color = Palette.color(Palette.ColorName.PHONE_KEY_EDGE)
	cap.set_border_width_all(1)
	cap.border_width_bottom = 3 # a thicker bottom edge makes it look like a key you can press
	draw_style_box(cap, key)
	draw_string(font, Vector2(key.position.x, key.position.y + 16.0), "E", HORIZONTAL_ALIGNMENT_CENTER, key.size.x,
			14, Palette.color(Palette.ColorName.PHONE_PRINT))


# A computer mouse with its left button lit up.
func _draw_mouse(key: Rect2) -> void:
	var body := Rect2(key.get_center() - Vector2(7, 11), Vector2(14, 22))
	var paper := Palette.color(Palette.ColorName.PAPER)
	var shell := StyleBoxFlat.new()
	shell.bg_color = Color(0, 0, 0, 0)
	shell.set_corner_radius_all(7)
	shell.border_color = paper
	shell.set_border_width_all(2)
	draw_style_box(shell, body)
	draw_rect(Rect2(body.position + Vector2(2, 2), Vector2(5, 7)), Palette.color(Palette.ColorName.KENTE_GOLD))
	draw_line(Vector2(body.get_center().x, body.position.y + 1), Vector2(body.get_center().x, body.position.y + 9), paper, 1.5)
