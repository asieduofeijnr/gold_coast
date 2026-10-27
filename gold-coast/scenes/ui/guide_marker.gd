class_name GuideMarker
extends WorldLabel
## Shows the way to where she's taking her load. When the spot is on the screen,
## a gold arrow bobs over it, pointing down. When it's off the screen, a round
## arrow at the edge of the screen points the way instead, with how far it is.

const EDGE := 60.0 # how far in from the screen's edge the round arrow stays, in pixels
const FONT_SIZE := 13

## The place's name, shown with the arrow.
var text := "":
	set(value):
		text = value
		queue_redraw()
## Whoever is going there (the player), to show how far away it is.
var traveller: Node3D

var _off_screen := false
var _toward := Vector2.DOWN


func _init() -> void:
	super()
	bob = 5.0


## Whether the spot is off the screen, so the arrow is waiting at the edge.
func is_off_screen() -> bool:
	return _off_screen


func follow() -> void:
	super()
	if anchor == null or get_viewport().get_camera_3d() == null:
		return
	var view := get_viewport().get_visible_rect()
	var middle := view.get_center()
	var room := view.size / 2.0 - Vector2(EDGE, EDGE)
	var offset := position - middle
	var off := absf(offset.x) > room.x or absf(offset.y) > room.y
	if off:
		# Slide back along the line from the middle of the screen until it fits.
		var shrink := minf(room.x / maxf(absf(offset.x), 0.001), room.y / maxf(absf(offset.y), 0.001))
		position = middle + offset * shrink
		_toward = offset.normalized()
	if off or off != _off_screen:
		queue_redraw() # the distance changes as she walks
	_off_screen = off


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var gold := Palette.color(Palette.ColorName.KENTE_GOLD)
	var dark := Palette.color(Palette.ColorName.DARK_BROWN)
	if _off_screen:
		draw_circle(Vector2.ZERO, 19.0, dark)
		draw_circle(Vector2.ZERO, 16.0, gold)
		var side := _toward.orthogonal()
		draw_colored_polygon(PackedVector2Array([_toward * 11.0, -_toward * 6.0 + side * 8.0, -_toward * 6.0 - side * 8.0]),
				dark)
		var words := "%s  %d m" % [text, roundi(_distance())]
		# The words go on the side of the arrow toward the middle of the screen.
		var words_size := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
		var at := -_toward * (30.0 + words_size.x / 2.0 * absf(_toward.x)) - Vector2(words_size.x / 2.0, -FONT_SIZE / 3.0)
		_pill(Rect2(at - Vector2(6, FONT_SIZE), words_size + Vector2(12, 6)))
		draw_string(font, at, words, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Palette.color(Palette.ColorName.PAPER))
	else:
		draw_colored_polygon(PackedVector2Array([Vector2(-15, -36), Vector2(15, -36), Vector2(0, -8)]), dark)
		draw_colored_polygon(PackedVector2Array([Vector2(-11, -33), Vector2(11, -33), Vector2(0, -12)]), gold)
		var words_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
		var at := Vector2(-words_size.x / 2.0, -46.0)
		_pill(Rect2(at - Vector2(6, FONT_SIZE), words_size + Vector2(12, 6)))
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Palette.color(Palette.ColorName.PAPER))


func _pill(box: Rect2) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.color(Palette.ColorName.PHONE_BEZEL) * Color(1, 1, 1, 0.85)
	style.set_corner_radius_all(6)
	draw_style_box(style, box)


# How far the traveller is from the spot, measured flat along the ground.
func _distance() -> float:
	if traveller == null or anchor == null:
		return 0.0
	var gap := anchor.global_position - traveller.global_position
	return Vector2(gap.x, gap.z).length()
