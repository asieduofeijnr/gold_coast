extends TestCase
## Checks the rules for learning skills at the training college (in GameState):
## enrolling pays the fees (and fails cleanly without the money), there's one
## class a day, the last class gives her the certificate, the day's work is
## counted, and it's all saved and loaded. Saves from before the college still
## load.

var _learned: Array[String] = []


func run_tests() -> void:
	GameState.reset()
	GameState.time_speed = 0.0
	GameState.skill_learned.connect(_on_skill_learned)
	var teaching := _course("teaching", 35000, 3)

	GameState.money = 30000
	check(not GameState.enroll(teaching) and GameState.money == 30000 and not GameState.is_enrolled("teaching"),
			"enrolling without enough money for the fees fails, and nothing changes")
	GameState.money = 50000
	check(GameState.enroll(teaching) and GameState.money == 15000 and GameState.is_enrolled("teaching")
			and GameState.classes_done("teaching") == 0, "enrolling pays the fees (GH₵350.00) by mobile money")
	check(not GameState.enroll(teaching) and GameState.money == 15000, "  ...and she can't enroll (and pay) twice")

	GameState.attend_class(teaching)
	check(GameState.classes_done("teaching") == 1 and GameState.had_class_today("teaching")
			and not GameState.has_skill("teaching"), "after her first class she's done 1 of 3, and that's it for today")
	GameState.set_time(2, 9 * 60.0)
	check(not GameState.had_class_today("teaching"), "  ...the next day there's another class")
	GameState.attend_class(teaching)
	GameState.set_time(3, 9 * 60.0)
	GameState.attend_class(teaching)
	check(GameState.has_skill("teaching") and not GameState.is_enrolled("teaching") and _learned == ["teaching"],
			"after the third class she has the teaching certificate")
	check(not GameState.enroll(teaching) and GameState.money == 15000, "  ...and can't pay for it again")

	check(GameState.jobs_done_today("teaching") == 0, "no lessons taught yet today")
	GameState.did_job("teaching")
	GameState.did_job("teaching")
	check(GameState.jobs_done_today("teaching") == 2, "  ...the day's work is counted (2 lessons)")
	GameState.set_time(4, 9 * 60.0)
	check(GameState.jobs_done_today("teaching") == 0, "  ...and the count starts again the next day")

	var days: Array[int] = []
	for day in [1, 5, 6, 7, 8]:
		GameState.set_time(day, 9 * 60.0)
		days.append(GameState.weekday())
	check(days == [1, 5, 6, 7, 1], "day 1 is a Monday, day 7 a Sunday, and day 8 a Monday again (%s)" % str(days))

	# Saving and loading.
	GameState.set_time(4, 10 * 60.0)
	var dressmaking := _course("dressmaking", 20000, 2)
	GameState.money = 30000
	GameState.enroll(dressmaking)
	GameState.attend_class(dressmaking)
	GameState.did_job("teaching")
	check(GameState.save_game(), "the game saves")
	GameState.reset()
	check(GameState.skills.is_empty() and GameState.courses.is_empty(), "a new game starts with no certificates or courses")
	check(GameState.load_game() and GameState.skills.size() == 1 and GameState.skills[0] == "teaching"
			and GameState.classes_done("dressmaking") == 1 and GameState.had_class_today("dressmaking")
			and GameState.jobs_done_today("teaching") == 1,
			"loading brings back her certificates, the courses she's on, and the day's work")

	# A save from before the training college (version 1) still loads.
	var old_save := FileAccess.open(GameState.save_path, FileAccess.WRITE)
	old_save.store_string(JSON.stringify({"version": 1, "money": 4200, "day": 2, "minutes": 600.0,
			"hunger": 70.0, "energy": 60.0}))
	old_save.close()
	check(GameState.load_game() and GameState.money == 4200 and GameState.skills.is_empty() and GameState.courses.is_empty(),
			"a game saved before the training college still loads (with no certificates)")

	GameState.skill_learned.disconnect(_on_skill_learned)
	GameState.delete_save()
	GameState.reset()


func _course(id: String, fee: int, classes: int) -> Course:
	var course := Course.new()
	course.id = id
	course.title = id.capitalize()
	course.phone_title = id.to_upper()
	course.fee = fee
	course.classes = classes
	return course


func _on_skill_learned(course: Course) -> void:
	_learned.append(course.id)
