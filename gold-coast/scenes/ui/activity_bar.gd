class_name ActivityBar
extends WorldLabel
## Shows what she's busy doing over her head, like "Eating waakye...", with a
## bar that fills up as she gets it done.

const FONT_SIZE := 14
const PADDING := Vector2(10, 6)
const BAR_HEIGHT := 5.0

## What she's doing, like "Eating waakye".
var text := "":
	set(value):
		text = value
		queue_redraw()
## How much of it is done, from 0 to 1.
var progress := 0.0:
	set(value):
		progress = value
		queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var words := text + "..."
	var inside := Vector2(maxf(font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x, 110.0),
			FONT_SIZE + 6.0 + BAR_HEIGHT)
	var box := Rect2(Vector2(-inside.x / 2.0 - PADDING.x, -inside.y - PADDING.y * 2.0), inside + PADDING * 2.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.color(Palette.ColorName.PHONE_BEZEL) * Color(1, 1, 1, 0.85)
	style.set_corner_radius_all(8)
	draw_style_box(style, box)
	var top_left := box.position + PADDING
	draw_string(font, top_left + Vector2(0, FONT_SIZE), words, HORIZONTAL_ALIGNMENT_CENTER, inside.x, FONT_SIZE,
			Palette.color(Palette.ColorName.PAPER))
	var bar := Rect2(top_left + Vector2(0, FONT_SIZE + 6.0), Vector2(inside.x, BAR_HEIGHT))
	draw_rect(bar, Palette.color(Palette.ColorName.PHONE_EDGE))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(progress, 0.0, 1.0), bar.size.y)),
			Palette.color(Palette.ColorName.KENTE_GOLD))
