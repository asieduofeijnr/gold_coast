class_name SkilledJob
extends Interactable
## Work that takes a skill from the training college, like teaching a lesson at
## the school or sewing a kaba and slit at the market. Using it walks her to
## this spot, where she takes up a pose (like "teach") and works for a while;
## then she's paid by mobile money. Without the skill, at the wrong time, or
## once she's done enough for the day, whoever's in charge (the `boss`) says
## so. It's only there while the boss is.

## Sent when she starts working.
signal started
## Sent when she stops. `completed` is false if she was cut short (say, by
## passing out).
signal finished(completed: bool)

## The skill it takes (a course's id, like "teaching"), and what the sign says
## she needs when she hasn't got it.
@export var skill := ""
@export var needs := "needs a certificate"
## The work, as the sign shows it ("Teach a lesson"), and as it shows over her
## head while she does it ("Teaching a lesson").
@export var work := "Work"
@export var doing := "Working"
## What it pays, in pesewas, and who pays it, as the phone's texts show it.
@export var pay := 5000
@export var payer := "SCHOOL"
## How long the work takes, in game minutes, and the real seconds that goes by in.
@export var game_minutes := 60.0
@export var real_seconds := 5.0
## The animation she holds while she works ("" to stand).
@export var pose := &""
## How many times a day there's work for her.
@export var per_day := 3
## When work can start (minutes after midnight), and on which days of the week
## (1 is Monday, 7 is Sunday). At other times the sign says `hours`.
@export var opens := 8.0 * 60.0
@export var closes := 13.0 * 60.0
@export var days: Array[int] = [1, 2, 3, 4, 5, 6, 7]
@export var hours := "Closed now"
## Who's in charge. They explain when there's no work for her, and say well done.
@export var boss: Vendor
@export var needs_line := ""
@export var hours_line := ""
@export var done_line := ""
@export var start_line := ""
@export var thanks_line := ""

## Whether she's working here right now.
var working := false

var _worker: Player


func _ready() -> void:
	super()
	used.connect(_on_used)
	GameState.activity_finished.connect(_on_activity_finished)
	GameState.time_changed.connect(_on_time_changed)
	GameState.skill_learned.connect(_on_skill_learned)
	refresh()


## Whether there's work at this time on this day (skill or not, done or not).
func is_open() -> bool:
	return GameState.weekday() in days and GameState.minutes >= opens and GameState.minutes < closes


## Brings the sign up to date (and switches it off while the boss is away).
## Whoever sends the boss home calls this afterwards.
func refresh() -> void:
	enabled = boss == null or boss.is_here() or working
	var words := "%s  +%s" % [work, Format.cedis(pay)]
	if not GameState.has_skill(skill):
		words = "%s (%s)" % [work, needs]
	elif not is_open():
		words = hours
	elif GameState.jobs_done_today(skill) >= per_day:
		words = "No more work today"
	if prompt != words:
		prompt = words


func _on_used(user: Node3D) -> void:
	if not GameState.has_skill(skill):
		_boss_says(needs_line)
	elif not is_open():
		_boss_says(hours_line)
	elif GameState.jobs_done_today(skill) >= per_day:
		_boss_says(done_line)
	else:
		_worker = user as Player
		_worker.act_at(self, pose, _start)


# She's in place: the work begins, and the clock runs fast while she does it.
func _start() -> void:
	if GameState.start_activity(doing, game_minutes, real_seconds):
		working = true
		_boss_says(start_line)
		started.emit()


func _on_activity_finished(activity: String, completed: bool) -> void:
	if activity != doing or not working:
		return
	working = false
	if completed:
		GameState.did_job(skill)
		GameState.receive(pay, payer)
		if _worker != null:
			FloatingText.pop(_worker, "+" + Format.cedis(pay), Palette.color(Palette.ColorName.KENTE_GOLD))
	finished.emit(completed)
	if completed:
		_boss_says(thanks_line)
	refresh()


func _on_time_changed(_day: int, _minutes: float) -> void:
	refresh()


func _on_skill_learned(_course: Course) -> void:
	refresh()


func _boss_says(line: String) -> void:
	if boss != null and line != "":
		boss.say(line)
