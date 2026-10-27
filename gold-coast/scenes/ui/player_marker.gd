class_name PlayerMarker
extends WorldLabel
## A little gold pin with Ghana's black star, floating over the player's head,
## so you can always pick her out from the townspeople.

const RADIUS := 9.0
const POINTER := 8.0


func _init() -> void:
	super()
	bob = 2.0


func _draw() -> void:
	var gold := Palette.color(Palette.ColorName.KENTE_GOLD)
	var ink := Palette.color(Palette.ColorName.DARK_BROWN)
	var center := Vector2(0.0, -POINTER - RADIUS)
	# A pointer down to her head, then the round pin, outlined in dark brown.
	var pointer := PackedVector2Array([Vector2(-6.5, center.y + 4.0), Vector2(6.5, center.y + 4.0), Vector2(0.0, 0.0)])
	draw_colored_polygon(pointer, ink)
	draw_circle(center, RADIUS + 1.5, ink)
	draw_colored_polygon(PackedVector2Array([Vector2(-4.5, center.y + 4.0), Vector2(4.5, center.y + 4.0),
			Vector2(0.0, -2.5)]), gold)
	draw_circle(center, RADIUS, gold)
	# The black star, as on Ghana's flag.
	var star := PackedVector2Array()
	for i in 10:
		var angle := -PI / 2.0 + i * PI / 5.0
		star.append(center + Vector2(cos(angle), sin(angle)) * RADIUS * (0.72 if i % 2 == 0 else 0.3))
	draw_colored_polygon(star, Palette.color(Palette.ColorName.SHITO_BLACK))
