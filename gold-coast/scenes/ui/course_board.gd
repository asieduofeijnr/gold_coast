class_name CourseBoard
extends MenuBoard
## The training college's board of courses, painted like the chop bar's menu:
## each course with what its certificate lets her do, its fees, and how far
## she's got with it. Choosing a course enrolls her (she pays the fees), or,
## once she's on it, sends her to its next class.

## The courses on the board.
var courses: Array[Course] = []


func _ready() -> void:
	super()
	# How far she's got shows on the board, so redraw it when that changes.
	GameState.enrolled.connect(_on_progress.unbind(1))
	GameState.class_attended.connect(_on_progress.unbind(2))
	GameState.skill_learned.connect(_on_progress.unbind(1))


## Opens the board with these courses.
func open_courses(list: Array[Course]) -> void:
	courses = list
	_show_board()


func _row_count() -> int:
	return courses.size()


func _on_progress() -> void:
	queue_redraw()


func _draw_row(font: Font, index: int) -> void:
	var course := courses[index]
	var row := _row_rect(index)
	var ink := _color(Palette.ColorName.DARK_BROWN)
	var green := _color(Palette.ColorName.PALM_GREEN)
	_draw_row_backing(row, index)
	_draw_icon(course, Vector2(row.position.x + 38.0, row.get_center().y))
	draw_string(font, row.position + Vector2(68, 23), course.title, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, ink)
	draw_string(font, row.position + Vector2(68, 41), course.description, HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
			_color(Palette.ColorName.WOOD_DARK))
	# On the right: the fees, or how far she's got.
	var right := row.end.x - 12.0
	var below := ""
	if GameState.has_skill(course.id):
		_draw_right(font, right, row.position.y + 24.0, "Certified", 17, green)
		below = "well done!"
	elif GameState.is_enrolled(course.id):
		_draw_right(font, right, row.position.y + 24.0,
				"Class %d of %d" % [GameState.classes_done(course.id) + 1, course.classes], 17, ink)
		below = "next class tomorrow" if GameState.had_class_today(course.id) else "go to class"
	else:
		var too_dear := course.fee > GameState.money or index == _red_row
		CediText.draw_right(self, font, right, row.position.y + 24.0, Format.cedis(course.fee), 18,
				_color(Palette.ColorName.TILE_RED) if too_dear else ink)
		below = "1 class" if course.classes == 1 else "%d classes" % course.classes
	_draw_right(font, right, row.position.y + 41.0, below, 12, green)


func _draw_right(font: Font, right: float, baseline: float, words: String, font_size: int, color: Color) -> void:
	var width := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, Vector2(right - width, baseline), words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


# A little painted picture of what the course is for.
func _draw_icon(course: Course, center: Vector2) -> void:
	var ink := _color(Palette.ColorName.DARK_BROWN)
	match course.id:
		"teaching": # a blackboard with chalk on it
			draw_rect(Rect2(center - Vector2(18, 13), Vector2(36, 24)), _color(Palette.ColorName.WOOD_DARK))
			draw_rect(Rect2(center - Vector2(15, 10), Vector2(30, 18)), _color(Palette.ColorName.SHITO_BLACK))
			var chalk := _color(Palette.ColorName.PAPER)
			draw_line(center + Vector2(-10, -4), center + Vector2(4, -4), chalk, 1.5)
			draw_line(center + Vector2(-10, 1), center + Vector2(9, 1), chalk, 1.5)
			draw_line(center + Vector2(-10, 13), center + Vector2(-14, 18), ink, 2.0)
			draw_line(center + Vector2(10, 13), center + Vector2(14, 18), ink, 2.0)
		"dressmaking": # a kaba and slit
			draw_colored_polygon(PackedVector2Array([center + Vector2(-9, -14), center + Vector2(9, -14),
					center + Vector2(15, -6), center + Vector2(9, -2), center + Vector2(-9, -2), center + Vector2(-15, -6)]),
					_color(Palette.ColorName.KENTE_GOLD))
			draw_colored_polygon(PackedVector2Array([center + Vector2(-9, -2), center + Vector2(9, -2),
					center + Vector2(11, 16), center + Vector2(-11, 16)]), _color(Palette.ColorName.PALM_GREEN))
			draw_line(center + Vector2(-10, 9), center + Vector2(10, 9), _color(Palette.ColorName.TILE_RED), 2.0)
			draw_line(center + Vector2(13, -16), center + Vector2(17, 4), _color(Palette.ColorName.ALUMINIUM), 1.5) # a needle
		"momo_agent": # a phone with money on its screen
			var phone := _style(Palette.ColorName.PHONE_BODY, 5)
			draw_style_box(phone, Rect2(center - Vector2(10, 16), Vector2(20, 32)))
			draw_rect(Rect2(center - Vector2(6, 12), Vector2(12, 11)), _color(Palette.ColorName.LCD_GLOW))
			draw_line(center + Vector2(-3, -9), center + Vector2(3, -4), ink, 1.5)
			draw_line(center + Vector2(3, -9), center + Vector2(-3, -4), ink, 1.5)
			for key in 3:
				draw_rect(Rect2(center + Vector2(-6 + key * 4.5, 3), Vector2(3, 3)), _color(Palette.ColorName.PHONE_KEY))
		_: # a certificate with a red seal
			draw_rect(Rect2(center - Vector2(15, 11), Vector2(30, 22)), _color(Palette.ColorName.PAPER))
			draw_circle(center + Vector2(8, 5), 5.0, _color(Palette.ColorName.TILE_RED))
