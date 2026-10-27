class_name SpeechBubble
extends WorldLabel
## A speech bubble over someone's head, with their name on top. say() shows it
## for a few seconds (longer for longer lines), then it fades away.
## Passing remarks (chatter, animals, sellers calling out) use a small bubble
## with no name, so the street doesn't fill up with words. What people say to
## her uses the normal size.

const FONT_SIZE := 13
const NAME_SIZE := 9
const MAX_WIDTH := 210.0 # lines longer than this wrap onto the next line
const PADDING := Vector2(10, 6)
const TAIL := 10.0
## The small bubble's sizes.
const SMALL_FONT_SIZE := 9
const SMALL_MAX_WIDTH := 130.0
const SMALL_PADDING := Vector2(6, 3)
const SMALL_TAIL := 6.0

## Who's talking, shown above what they say (not in a small bubble).
var speaker := "":
	set(value):
		speaker = value
		queue_redraw()
## What they're saying right now.
var text := ""
## Whether it's a small bubble, for a passing remark.
var small := false

var _time_left := 0.0


## Shows `line` in the bubble for a few seconds: in a small bubble if it's
## just a passing remark.
func say(line: String, as_remark := false) -> void:
	text = line
	small = as_remark
	_time_left = 2.0 + 0.05 * line.length()
	queue_redraw()
	appear()


## How big the bubble is, in pixels (not counting its tail).
func box_size() -> Vector2:
	return _box().size


func _process(delta: float) -> void:
	super(delta)
	if _time_left > 0.0:
		_time_left -= delta
		if _time_left <= 0.0:
			disappear()


# The name shown on top ("" in a small bubble, which has no room for one).
func _title() -> String:
	return "" if small else speaker.to_upper()


# The bubble's outline, above (0, 0), where its tail points.
func _box() -> Rect2:
	var font := ThemeDB.fallback_font
	var padding := SMALL_PADDING if small else PADDING
	var text_size := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT,
			SMALL_MAX_WIDTH if small else MAX_WIDTH, SMALL_FONT_SIZE if small else FONT_SIZE)
	var inside := text_size
	if _title() != "":
		inside.x = maxf(inside.x, font.get_string_size(_title(), HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE).x)
		inside.y += NAME_SIZE + 3.0
	var tail := SMALL_TAIL if small else TAIL
	return Rect2(Vector2(-inside.x / 2.0 - padding.x, -tail - inside.y - padding.y * 2.0), inside + padding * 2.0)


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var ink := Palette.color(Palette.ColorName.DARK_BROWN)
	var box := _box()
	var font_size := SMALL_FONT_SIZE if small else FONT_SIZE
	var line_width := 1.5 if small else 2.0

	var style := StyleBoxFlat.new()
	style.bg_color = Palette.color(Palette.ColorName.PAPER)
	style.set_corner_radius_all(6 if small else 10)
	style.border_color = ink
	style.set_border_width_all(1 if small else 2)
	style.shadow_color = Color(0, 0, 0, 0.22)
	style.shadow_size = 2 if small else 4
	style.shadow_offset = Vector2(1, 2)
	draw_style_box(style, box)
	# The tail pointing down at whoever's talking, drawn over the bubble's edge.
	var tail_width := 8.0 if small else 13.0
	var tail := PackedVector2Array([Vector2(-tail_width * 0.8, box.end.y - 1.5), Vector2(tail_width * 0.2, box.end.y - 1.5),
			Vector2(-tail_width * 0.25, 0)])
	draw_colored_polygon(tail, style.bg_color)
	draw_polyline(PackedVector2Array([tail[0], tail[2], tail[1]]), ink, line_width)

	var top_left := box.position + (SMALL_PADDING if small else PADDING)
	if _title() != "":
		draw_string(font, top_left + Vector2(0, NAME_SIZE), _title(), HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE,
				Palette.color(Palette.ColorName.TILE_RED))
		top_left.y += NAME_SIZE + 3.0
	draw_multiline_string(font, top_left + Vector2(0, font.get_ascent(font_size)), text, HORIZONTAL_ALIGNMENT_LEFT,
			SMALL_MAX_WIDTH if small else MAX_WIDTH, font_size, -1, ink)
