class_name FloatingText
extends WorldLabel
## Words that float up from a spot and fade away, like "+45 food" after a meal.

const FONT_SIZE := 24
const RISE := 0.9 # how far it floats up, in metres
const SECONDS := 1.6

## The words.
var text := ""
## Their color.
var color := Color.WHITE


## Shows `text` floating up from `anchor` (a node in the 3D world), starting
## `start_height` metres above it. It makes its own layer to draw on, and removes
## itself when it's done.
static func pop(anchor: Node3D, words: String, words_color: Color, start_height := 2.2) -> FloatingText:
	var layer := CanvasLayer.new()
	anchor.add_child(layer, false, Node.INTERNAL_MODE_BACK)
	var label := FloatingText.new()
	label.anchor = anchor
	label.height = start_height
	label.text = words
	label.color = words_color
	layer.add_child(label)
	label.follow()
	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "height", start_height + RISE, SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(SECONDS - 0.5)
	tween.chain().tween_callback(layer.queue_free)
	return label


func _draw() -> void:
	CediText.draw_centered(self, ThemeDB.fallback_font, 0.0, 0.0, text, FONT_SIZE, color, 6,
			Palette.color(Palette.ColorName.DARK_BROWN))
