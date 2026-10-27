class_name CediText
## Draws text that can contain the cedi sign (₵). The game's default font
## doesn't have that sign, so each ₵ is drawn as a C with a line through it,
## which is what the sign is. (The phone doesn't need this: its pixel font has ₵.)

const SIGN := "₵"


## How wide `text` is when drawn at `font_size`.
static func width(font: Font, text: String, font_size: int) -> float:
	return font.get_string_size(text.replace(SIGN, "C"), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x


## Draws `text` on `canvas` with the left end of its baseline at `at`. With an
## `outline` width above 0, it gets an outline in `outline_color` first.
static func draw(canvas: CanvasItem, font: Font, at: Vector2, text: String, font_size: int, color: Color,
		outline := 0, outline_color := Color.BLACK) -> void:
	var x := at.x
	var pieces := text.split(SIGN)
	for i in pieces.size():
		if i > 0:
			x += _draw_sign(canvas, font, Vector2(x, at.y), font_size, color, outline, outline_color)
		var piece := pieces[i]
		if piece.is_empty():
			continue
		if outline > 0:
			canvas.draw_string_outline(font, Vector2(x, at.y), piece, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size,
					outline, outline_color)
		canvas.draw_string(font, Vector2(x, at.y), piece, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
		x += font.get_string_size(piece, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x


## Draws `text` centred on `center_x`, with its baseline at `baseline`.
static func draw_centered(canvas: CanvasItem, font: Font, center_x: float, baseline: float, text: String,
		font_size: int, color: Color, outline := 0, outline_color := Color.BLACK) -> void:
	draw(canvas, font, Vector2(center_x - width(font, text, font_size) / 2.0, baseline), text, font_size, color,
			outline, outline_color)


## Draws `text` so that it ends at `right_x`, with its baseline at `baseline`.
static func draw_right(canvas: CanvasItem, font: Font, right_x: float, baseline: float, text: String,
		font_size: int, color: Color) -> void:
	draw(canvas, font, Vector2(right_x - width(font, text, font_size), baseline), text, font_size, color)


# A C with an upright line through its middle. Returns how wide it is.
static func _draw_sign(canvas: CanvasItem, font: Font, at: Vector2, font_size: int, color: Color,
		outline: int, outline_color: Color) -> float:
	var c_width := font.get_string_size("C", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var middle := at.x + c_width * 0.53
	var top := Vector2(middle, at.y - font_size * 0.86)
	var bottom := Vector2(middle, at.y + font_size * 0.14)
	var thickness := maxf(1.0, font_size * 0.09)
	if outline > 0:
		canvas.draw_string_outline(font, at, "C", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline, outline_color)
		canvas.draw_line(top, bottom, outline_color, thickness + outline)
	canvas.draw_string(font, at, "C", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
	canvas.draw_line(top, bottom, color, thickness)
	return c_width
