class_name School
extends Node3D
## Nkabom M/A Basic School: a classroom block with its yard, where she can teach
## once she has a teaching certificate from the training college.
## - In the yard: Ghana's flag on its pole, a big mango tree, and the lesson
##   place, a blackboard with two benches of pupils in front of it.
## - The headmistress, Mrs. Ofori, is there on school days (Monday to Friday),
##   07:00 to 16:00.
## - Teaching a lesson (at the blackboard) takes a game hour and pays GH₵50 by
##   mobile money, up to three a day, starting from 08:00 until 13:00. The
##   pupils come and sit on the benches for it, and run off to play after.
## Place it at the school building's spot. Its parts are laid out in the
## world's directions (the yard is on the building's +X side).

## When the headmistress is at school, in minutes after midnight, and on which
## days of the week (1 is Monday).
const ARRIVES := 7.0 * 60.0
const LEAVES := 16.0 * 60.0
const SCHOOL_DAYS: Array[int] = [1, 2, 3, 4, 5]
## What pupils call out during a lesson.
const PUPIL_LINES := ["A for apple!", "B for ball!", "Two plus three is five!", "Yes, Madam!", "Madam, I know it!",
		"Ghana, our motherland!", "Madam, please, may I go out?", "C for cat!"]

## The classroom block. Clicking it walks her to the blackboard.
@export var building: Node3D

## The pupils, on the benches during a lesson and off playing otherwise.
var pupils: Array[Townsperson] = []

@onready var headmistress: Vendor = $Headmistress
@onready var lesson: SkilledJob = $Lesson
@onready var playground: Marker3D = $Playground


func _ready() -> void:
	lesson.click_targets = [building, $Blackboard as Node3D]
	lesson.started.connect(_on_lesson_started)
	lesson.finished.connect(_on_lesson_finished)
	GameState.time_changed.connect(_on_time_changed)
	for bench: SchoolBench in [$Bench as SchoolBench, $Bench2 as SchoolBench]:
		for seat in bench.seats:
			var pupil := Townsperson.new()
			pupil.body = Townsperson.Body.GIRL if pupils.size() % 2 == 0 else Townsperson.Body.BOY
			pupil.top_color = Palette.ColorName.KENTE_GOLD # the uniform: yellow and brown
			pupil.bottom_color = Palette.ColorName.WOOD_DARK
			pupil.visible = false
			add_child(pupil)
			pupil.set_meta(&"seat", seat)
			pupils.append(pupil)
	_update_headmistress()


## Whether it's a school day and the headmistress is in.
func is_open() -> bool:
	return GameState.weekday() in SCHOOL_DAYS and GameState.minutes >= ARRIVES and GameState.minutes < LEAVES


# The lesson starts: the pupils come and sit, greet her, and chime in.
func _on_lesson_started() -> void:
	for pupil in pupils:
		var seat: Marker3D = pupil.get_meta(&"seat")
		pupil.appear_at(seat.global_position)
		pupil.place_at(seat)
		pupil.hold(&"sit")
	await _wait(1.0)
	if lesson.working:
		pupils.pick_random().say("Gooood mor-ning, Ma-dam!")
	while lesson.working:
		await _wait(randf_range(1.2, 2.0))
		if lesson.working:
			pupils.pick_random().say(PUPIL_LINES.pick_random())


# The lesson's over: "Thank you, Madam!", and off they run to play.
func _on_lesson_finished(_completed: bool) -> void:
	pupils.pick_random().say("Thank you, Madam!")
	for pupil in pupils:
		_run_off(pupil)


func _run_off(pupil: Townsperson) -> void:
	await _wait(randf_range(0.3, 1.2))
	pupil.hold(&"")
	await pupil.walk_to(playground.global_position + Vector3(randf_range(-2.0, 2.0), 0.0, randf_range(-2.0, 2.0)), true)
	await pupil.vanish()


func _on_time_changed(_day: int, _minutes: float) -> void:
	_update_headmistress()


# She's at school on school days, and home the rest of the time; the lesson's
# sign only shows while she's there.
func _update_headmistress() -> void:
	var here := is_open()
	if here != headmistress.is_here():
		if here:
			headmistress.come_back()
		else:
			headmistress.leave()
	lesson.refresh()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, false).timeout
