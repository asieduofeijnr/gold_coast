class_name TrainingCollege
extends Node3D
## Sankofa Training College, where she can learn a skill (see Course):
## - At the registrar's desk (press E there, or click the college), the board
##   of courses opens, and the game pauses while you choose. It shows each
##   course's fees, how many classes it takes, and what its certificate lets
##   her do. Choosing a course she isn't on enrolls her: the fees go by mobile
##   money. Choosing one she's on sends her in to its next class.
## - A class takes two game hours, indoors, out of sight. There's one class a
##   day for each course, starting between 08:00 and 15:00. After the last
##   one she has the certificate, and the phone says so.
## - The registrar, Madam Afriyie, is at her desk Monday to Saturday, 07:00 to
##   17:30.
## Place it at the college building's spot.

## When the registrar is at her desk (minutes after midnight), and on which
## days of the week (1 is Monday).
const OPENS := 7.0 * 60.0
const CLOSES := 17.5 * 60.0
const DAYS := [1, 2, 3, 4, 5, 6]
## When classes can start.
const CLASSES_FROM := 8.0 * 60.0
const CLASSES_UNTIL := 15.0 * 60.0
## A class takes two game hours, which go by in a few real seconds.
const CLASS_MINUTES := 120.0
const CLASS_SECONDS := 6.0

## The courses on offer. Edit them in the Inspector.
@export var courses: Array[Course] = []
## The college building. Clicking it walks her to the registrar's desk.
@export var building: Node3D

var _student: Player
# The course whose class she's in, and the activity it is ("" when she isn't).
var _course: Course
var _class := ""

@onready var desk_spot: Interactable = $DeskSpot
@onready var door: Marker3D = $ClassDoor
@onready var registrar: Vendor = $Registrar
@onready var board: CourseBoard = $BoardLayer/CourseBoard


func _ready() -> void:
	desk_spot.click_targets = [building, $Desk as Node3D]
	desk_spot.used.connect(_open_board)
	board.chosen.connect(_choose)
	board.closed.connect(_on_board_closed)
	GameState.activity_finished.connect(_on_activity_finished)
	GameState.time_changed.connect(_on_time_changed)
	_update_registrar()


func _exit_tree() -> void:
	# Never leave the game paused if the college goes away with its board open.
	if board.is_open():
		get_tree().paused = false


## Whether the registrar is at her desk right now.
func is_open() -> bool:
	return GameState.weekday() in DAYS and GameState.minutes >= OPENS and GameState.minutes < CLOSES


## Whether a class can start right now.
func classes_running() -> bool:
	return is_open() and GameState.minutes >= CLASSES_FROM and GameState.minutes < CLASSES_UNTIL


## The course with this id, or null.
func course(course_id: String) -> Course:
	for offered in courses:
		if offered.id == course_id:
			return offered
	return null


func _open_board(user: Node3D) -> void:
	_student = user as Player
	board.open_courses(courses)
	registrar.hush()
	_say("Welcome to Sankofa! What would you like to learn?")
	get_tree().paused = true # the clock stops while you choose


func _on_board_closed() -> void:
	get_tree().paused = false


func _choose(index: int) -> void:
	var chosen := courses[index]
	if GameState.has_skill(chosen.id):
		_say("You have that certificate already. Well done, my dear!")
		board.shake()
	elif not GameState.is_enrolled(chosen.id):
		if GameState.enroll(chosen):
			_say("You're in! Come to your first class when you're ready.")
		else:
			_say("Your momo won't cover the fees yet. Save up and come back!")
			board.shake(index)
	elif GameState.had_class_today(chosen.id):
		_say("One class a day, my dear. Come back tomorrow!")
		board.shake()
	elif not classes_running():
		_say("Classes start from eight in the morning until three. Come back then!")
		board.shake()
	else:
		board.close()
		_say("Go in, your class is starting!")
		_course = chosen
		if _student != null:
			_student.act_at(door, &"", _start_class)


# She's at the door: in she goes, and the class begins.
func _start_class() -> void:
	var activity := "In class: " + _course.title
	if GameState.start_activity(activity, CLASS_MINUTES, CLASS_SECONDS):
		_class = activity
		_student.indoors = true


func _on_activity_finished(activity: String, completed: bool) -> void:
	if _class == "" or activity != _class:
		return
	_class = ""
	_student.indoors = false # out she comes
	if not completed:
		return
	GameState.attend_class(_course)
	var gold := Palette.color(Palette.ColorName.KENTE_GOLD)
	if GameState.has_skill(_course.id):
		_say("Congratulations! Here is your certificate.")
		FloatingText.pop(_student, "Certificate!", gold)
	else:
		_say("Well done! Your next class is tomorrow.")
		FloatingText.pop(_student, "Class %d of %d done" % [GameState.classes_done(_course.id), _course.classes], gold)


func _on_time_changed(_day: int, _minutes: float) -> void:
	_update_registrar()


# She's at her desk while the college is open, and goes home the rest of the
# time, and the desk can only be used while she's there.
func _update_registrar() -> void:
	var here := is_open()
	if here != registrar.is_here():
		if here:
			registrar.come_back()
		else:
			registrar.leave()
	desk_spot.enabled = here


# Madam Afriyie says `line`: on the board while it's open (her speech bubble
# would be hidden behind it), otherwise in her speech bubble.
func _say(line: String) -> void:
	if board.is_open():
		board.line = line
	else:
		registrar.say(line)
