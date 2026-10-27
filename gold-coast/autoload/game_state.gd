extends Node
## Game-wide state that every scene shares: your money, the time of day, and
## your needs (hunger and energy), including sleep, the things that keep her
## busy for a while (like eating a meal), the load she's carrying, the rent,
## and what she's learned at the training college.
## It's an autoload called GameState, so any script can use GameState.money,
## GameState.minutes, GameState.hunger, and so on.
##
## It also saves and loads the game: going to bed at home saves everything that
## matters to a file (see save_game()), and load_game() brings it back.

## Fires whenever your money changes, with the new amount (in pesewas).
signal money_changed(new_amount: int)
## Fires when a mobile money payment goes through, with the amount (in
## pesewas) and who it went to.
signal payment_sent(amount: int, payee: String)
## Fires when a mobile money payment fails because there isn't enough money.
signal payment_failed(amount: int, payee: String)
## Fires when mobile money comes in, with the amount and who sent it.
signal payment_received(amount: int, payer: String)
## Fires when the clock reaches a new game minute (at most once a minute), with
## the day number and the minutes since midnight.
signal time_changed(day: int, minutes: float)
## Fires when hunger or energy changes by at least a whole point.
signal needs_changed(hunger: float, energy: float)
## Fires when she falls asleep or wakes up.
signal sleep_changed(asleep: bool)
## Fires when you try to sleep but she can't, with the reason to show on the
## phone, like "NOT SLEEPY".
signal sleep_refused(reason: String)
## Fires when mosquitoes wake her up because she's sleeping outside.
signal mosquitoes_woke_her
## Fires when she starts something that keeps her busy for a while (like
## eating), with its name, and again with "" when she's free.
signal activity_changed(activity: String)
## Fires when an activity ends. `completed` is false if it was cut short.
signal activity_finished(activity: String, completed: bool)
## Fires when she picks up a load to carry, and again (with null) when she
## hands it over, gives it back, or drops it.
signal load_changed(headload: Delivery)
## Fires when she drops a load without delivering it, because she passed out.
signal load_dropped(headload: Delivery)
## Fires when the week's rent is paid, with the amount.
signal rent_paid(amount: int)
## Fires when rent is due but she can't pay it, with what she owes. Her room is
## locked until she pays (see pay_rent()).
signal rent_missed(owed: int)
## Fires the evening before rent day, as a reminder, with the rent.
signal rent_reminder(amount: int)
## Fires when the game has been saved.
signal game_saved
## Fires when she enrolls in a course at the training college (and pays its fees).
signal enrolled(course: Course)
## Fires when she's been to a class, with how many of the course's she's done.
signal class_attended(course: Course, classes_done: int)
## Fires when she's been to every class of a course: she has its certificate,
## and the skill to go with it.
signal skill_learned(course: Course)

## What you start the game with: GH₵100.00.
const STARTING_MONEY := 10000
## The game starts on day 1 at 07:00.
const START_DAY := 1
const START_MINUTES := 7.0 * 60.0
const MINUTES_PER_DAY := 24.0 * 60.0
## Needs go from FULL down to 0. Below LOW she's hungry or sleepy.
const FULL := 100.0
const LOW := 25.0
## The rent for her room, in pesewas (GH₵140.00), due every Monday at 08:00.
## The first week is already paid, so the first rent day is day 8.
const RENT := 14000
const RENT_TIME := 8.0 * 60.0
const FIRST_RENT_DAY := 8
## Who the rent goes to, as the phone's texts show it.
const LANDLADY := "LANDLADY"
## The rent reminder comes the evening before, at this time.
const REMINDER_TIME := 18.0 * 60.0
## Who course fees go to, as the phone's texts show it.
const COLLEGE := "COLLEGE"
## Bump this when the save file's layout changes, so old saves aren't misread.
## (Version 1 saves, from before the training college, still load.)
const SAVE_VERSION := 2

@export_group("Needs")
## Hunger lost per game hour. At 6, she's empty about 16 hours after eating.
@export var hunger_per_hour := 6.0
## Energy lost per game hour while she's awake.
@export var energy_per_hour := 4.0
## Extra energy lost per game hour while she's walking.
@export var walking_energy_per_hour := 2.0
## When she's starving (hunger at 0), energy drains this many times faster.
@export var starving_energy_multiplier := 2.0
## Outside, she can only fall asleep when her energy is below this.
@export var sleepy_below := 90.0

@export_group("Sleep")
## Energy gained per game hour of sleep outside. At 12.5, 8 hours fills her up from empty.
@export var sleep_energy_per_hour := 12.5
## Energy gained per game hour of sleep in her bed at home. At 20, 5 hours fills her up.
@export var bed_energy_per_hour := 20.0
## In her bed she can fall asleep when her energy is below this, so even a
## little tired is enough.
@export var bed_sleepy_below := 98.0
## Sleeping outside, mosquitoes wake her up after this many game hours.
@export var mosquito_hours := 4.0
## While she sleeps, hunger drains this much slower (0.5 = half as fast).
@export var sleep_hunger_multiplier := 0.5
## How fast time runs while she sleeps, in game minutes per real second
## (60 = an hour every second).
@export var sleep_time_speed := 60.0

@export_group("Carrying")
## Extra energy lost per game hour while she carries a load on her head.
@export var carrying_energy_per_hour := 3.0

## Your money in pesewas (100 pesewas = GH₵1), so amounts like GH₵6.50 add
## up exactly. Show it to the player with Format.cedis(money).
var money := STARTING_MONEY:
	set(value):
		if value > money:
			earned_today += value - money
		else:
			spent_today += money - value
		money = value
		money_changed.emit(money)
## What she's earned and spent since she last woke up in her bed (for the
## bedtime summary on the phone), in pesewas.
var earned_today := 0
var spent_today := 0

## How fast game time passes, in game minutes per real second. At 1, a game
## hour takes a real minute and a whole day takes 24 minutes.
var time_speed := 1.0
## The day number, counting from 1.
var day := START_DAY
## Minutes since midnight, from 0 up to 1440 (with fractions). Show it to the
## player with Format.clock(minutes).
var minutes := START_MINUTES

## How full she is, from 100 (just eaten) to 0 (starving).
var hunger := FULL
## How rested she is, from 100 (wide awake) to 0 (she passes out).
var energy := FULL
## Whether she's asleep.
var sleeping := false
## Whether she fell asleep because her energy ran out. Then she can't be woken
## until she's had some rest (her energy is back above LOW).
var passed_out := false
## Whether she's asleep in her bed at home, rather than outside.
var in_bed := false
## Whether she's walking right now. The player sets this every step.
var is_walking := false
## What's keeping her busy, like "Eating waakye", or "" when she's free. While
## she's busy, time runs faster. See start_activity().
var activity := ""
## The load she's carrying on her head, or null. See pick_up().
var delivery: Delivery
## Rent she owes, in pesewas. While she owes rent, her room is locked.
var rent_owed := 0
## The next day rent is due (a Monday).
var next_rent_day := FIRST_RENT_DAY
## The day she last washed Maame Esi's bowls (0 = never), so it's once a day.
var bowls_washed_day := 0
## The courses she's enrolled in, by id, with how many of their classes she's
## been to. A course leaves this list once she has its certificate.
var courses := {}
## The day she last went to a class of each course, by id (one class a day).
var class_days := {}
## The skills she's learned: the ids of the courses she has certificates for.
var skills: Array[String] = []

## The file the game is saved to. Tests use a file of their own.
var save_path := "user://save.json"
## Whether townspeople and the trotro go about their day. Tests switch this off
## so nothing wanders into their way.
var town_life := true

# The last values announced, so each change is only announced once.
var _announced_time := Vector2i(-1, -1)
var _announced_needs := Vector2i(-1, -1)
# The time speed to go back to after waking up or finishing an activity.
var _normal_time_speed := 1.0
# When she fell asleep (as now() gives it), for the mosquitoes.
var _asleep_since := 0.0
# The current activity: when it ends, how long it lasts, and how much hunger
# it gives back over that time.
var _activity_end := 0.0
var _activity_minutes := 0.0
var _activity_hunger := 0.0
# The rent day the reminder was last sent for, so it's only sent once.
var _reminded_for := 0
# True while a saved game is being loaded (so going back to bed doesn't save again).
var _loading := false
# How many times she's done each kind of work today (see did_job()), and which
# day that was.
var _jobs_today := {}
var _jobs_day := 0


func _process(delta: float) -> void:
	advance(delta * time_speed)


## The game time as minutes since the game began, counting across midnight,
## so you can measure how long something has been going on.
func now() -> float:
	return (day - START_DAY) * MINUTES_PER_DAY + minutes


## Adds `amount` pesewas, for example wages.
func add_money(amount: int) -> void:
	assert(amount >= 0, "add_money() takes a positive amount; use spend_money() to take money away")
	money += amount


## Takes away `amount` pesewas and returns true. If there isn't enough money,
## it changes nothing and returns false.
func spend_money(amount: int) -> bool:
	assert(amount >= 0, "spend_money() takes a positive amount")
	if amount > money:
		return false
	money -= amount
	return true


## Pays `amount` pesewas to `payee` with mobile money, and returns true. If
## there isn't enough money, it changes nothing and returns false. Either way,
## the phone gets a text message about it.
func pay(amount: int, payee: String) -> bool:
	if not spend_money(amount):
		payment_failed.emit(amount, payee)
		return false
	payment_sent.emit(amount, payee)
	return true


## Receives `amount` pesewas from `payer` with mobile money, like wages.
func receive(amount: int, payer: String) -> void:
	add_money(amount)
	payment_received.emit(amount, payer)


## Moves the clock forward by `game_minutes`, starting a new day at midnight.
## Her needs change by the same amount of game time.
func advance(game_minutes: float) -> void:
	_update_needs(game_minutes / 60.0)
	minutes += game_minutes
	while minutes >= MINUTES_PER_DAY:
		minutes -= MINUTES_PER_DAY
		day += 1
	_announce_time()
	if activity != "" and now() + 0.001 >= _activity_end:
		_end_activity(true)
	if sleeping and not in_bed and now() - _asleep_since >= mosquito_hours * 60.0 and wake_up():
		mosquitoes_woke_her.emit()
	_check_rent()


## Sets the clock to `new_minutes` past midnight on day `new_day`.
func set_time(new_day: int, new_minutes: float) -> void:
	day = new_day
	minutes = fposmod(new_minutes, MINUTES_PER_DAY)
	_announce_time()


## Sets hunger and energy (each from 0 to 100).
func set_needs(new_hunger: float, new_energy: float) -> void:
	hunger = clampf(new_hunger, 0.0, FULL)
	energy = clampf(new_energy, 0.0, FULL)
	_announce_needs()


## Whether she's tired enough to fall asleep. In her bed at home (`at_home`),
## a little tired is enough; outside she has to be properly tired.
func can_sleep(at_home := false) -> bool:
	return energy < (bed_sleepy_below if at_home else sleepy_below)


## Tries to fall asleep, outside or in her bed at home (`at_home`). Returns
## false if she's busy, if she's carrying a load, or if she isn't tired enough
## (then it also sends sleep_refused with the reason).
func sleep(at_home := false) -> bool:
	if sleeping:
		return true
	if activity != "":
		return false
	if delivery != null:
		sleep_refused.emit("DELIVER IT!")
		return false
	if at_home and is_room_locked():
		sleep_refused.emit("PAY RENT!")
		return false
	if not can_sleep(at_home):
		sleep_refused.emit("NOT SLEEPY")
		return false
	_fall_asleep(false, at_home)
	return true


## Wakes her up. Returns false if she can't be woken yet, because she passed
## out and hasn't rested enough.
func wake_up() -> bool:
	if not sleeping:
		return true
	if passed_out and energy < LOW:
		return false
	if in_bed:
		# A new day starts when she gets up from her bed.
		earned_today = 0
		spent_today = 0
	sleeping = false
	passed_out = false
	in_bed = false
	time_speed = _normal_time_speed
	sleep_changed.emit(false)
	return true


## Keeps her busy with `activity_name` (like "Eating waakye") for `game_minutes`
## of game time, which go by in `real_seconds` of real time. Over that time she
## gets `hunger_gain` hunger back, bit by bit (for a meal). Returns false if
## she's asleep or already busy.
func start_activity(activity_name: String, game_minutes: float, real_seconds: float, hunger_gain := 0.0) -> bool:
	if sleeping or activity != "":
		return false
	activity = activity_name
	_activity_minutes = maxf(game_minutes, 0.001)
	_activity_end = now() + _activity_minutes
	_activity_hunger = hunger_gain
	_normal_time_speed = time_speed
	time_speed = _activity_minutes / maxf(real_seconds, 0.001)
	activity_changed.emit(activity)
	return true


## How far through her activity she is, from 0 (just started) to 1 (done).
func activity_progress() -> float:
	if activity == "":
		return 0.0
	return clampf(1.0 - (_activity_end - now()) / _activity_minutes, 0.0, 1.0)


## Stops her activity before it's done. She keeps what she's gained so far.
func stop_activity() -> void:
	if activity != "":
		_end_activity(false)


## Puts `headload` on her head to carry, due `headload.minutes` from now.
## Returns false if she can't: she's asleep, busy, or already carrying something.
func pick_up(headload: Delivery) -> bool:
	if delivery != null or sleeping or activity != "":
		return false
	delivery = headload
	headload.due = now() + headload.minutes
	load_changed.emit(headload)
	return true


## How many game minutes are left to deliver her load (below 0 when she's late).
func delivery_minutes_left() -> float:
	return delivery.due - now() if delivery != null else 0.0


## Hands over the load she's carrying, at its destination, and she's paid by
## mobile money: the full pay if it's in time, half if she's late. Returns what
## she was paid.
func deliver_load() -> int:
	if delivery == null:
		return 0
	var headload := delivery
	@warning_ignore("integer_division")
	var amount := headload.pay if now() <= headload.due else headload.pay / 2
	delivery = null
	load_changed.emit(null)
	receive(amount, headload.payer)
	return amount


## Gives her load back without delivering it, for no pay.
func give_back_load() -> void:
	if delivery != null:
		delivery = null
		load_changed.emit(null)


## Whether her room is locked because she owes rent.
func is_room_locked() -> bool:
	return rent_owed > 0


## Pays the rent she owes by mobile money, if she has enough, and returns
## whether it's all paid now. If she can't, nothing changes.
func pay_rent() -> bool:
	if rent_owed == 0:
		return true
	if money < rent_owed:
		return false
	var amount := rent_owed
	pay(amount, LANDLADY)
	rent_owed = 0
	rent_paid.emit(amount)
	return true


## Today's day of the week, as a number: 1 is Monday, 7 is Sunday.
func weekday() -> int:
	return posmod(day - 1, 7) + 1


## Enrolls her in `course` at the training college, paying its fees by mobile
## money. If she's already enrolled, already has its certificate, or can't
## afford it, nothing changes and it returns false.
func enroll(course: Course) -> bool:
	if courses.has(course.id) or has_skill(course.id):
		return false
	if not pay(course.fee, COLLEGE):
		return false
	courses[course.id] = 0
	enrolled.emit(course)
	return true


## Whether she's enrolled in the course with this id (and hasn't finished it).
func is_enrolled(course_id: String) -> bool:
	return courses.has(course_id)


## How many classes of the course with this id she's been to.
func classes_done(course_id: String) -> int:
	return courses.get(course_id, 0)


## Whether she's already been to a class of the course with this id today.
func had_class_today(course_id: String) -> bool:
	return class_days.get(course_id, 0) == day


## Counts a class of `course` she's just been to. After the last one, she has
## its certificate: its skill.
func attend_class(course: Course) -> void:
	if not courses.has(course.id):
		return
	courses[course.id] = classes_done(course.id) + 1
	class_days[course.id] = day
	class_attended.emit(course, courses[course.id])
	if courses[course.id] >= course.classes:
		courses.erase(course.id)
		skills.append(course.id)
		skill_learned.emit(course)


## Whether she has the skill (the certificate) from the course with this id.
func has_skill(course_id: String) -> bool:
	return course_id in skills


## How many times she's done the work called `job` today (like teaching a lesson).
func jobs_done_today(job: String) -> int:
	return _jobs_today.get(job, 0) if _jobs_day == day else 0


## Counts one more time she's done the work called `job` today.
func did_job(job: String) -> void:
	if _jobs_day != day:
		_jobs_today.clear()
		_jobs_day = day
	_jobs_today[job] = jobs_done_today(job) + 1


## Saves the game to `save_path`. Returns whether it worked.
func save_game() -> bool:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(_save_data(), "\t"))
	file.close()
	game_saved.emit()
	return true


## Whether there's a saved game to load.
func has_save() -> bool:
	return FileAccess.file_exists(save_path)


## Loads the saved game from `save_path`. Returns false, and changes nothing,
## if there isn't one or it can't be read.
func load_game() -> bool:
	if not has_save():
		return false
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(save_path)) != OK:
		return false # not a saved game (or a damaged one)
	var data: Variant = json.data
	if not data is Dictionary or not (data.get("version") is float or data.get("version") is int):
		return false
	var version := int(data.version)
	if version < 1 or version > SAVE_VERSION:
		return false
	for key in ["money", "day", "minutes", "hunger", "energy"]:
		if not data.has(key):
			return false
	_loading = true
	reset()
	money = int(data.money)
	rent_owed = int(data.get("rent_owed", 0))
	next_rent_day = int(data.get("next_rent_day", FIRST_RENT_DAY))
	bowls_washed_day = int(data.get("bowls_washed_day", 0))
	set_time(int(data.day), float(data.minutes))
	set_needs(float(data.hunger), float(data.energy))
	earned_today = int(data.get("earned_today", 0))
	spent_today = int(data.get("spent_today", 0))
	courses = _whole_numbers(data.get("courses", {}))
	class_days = _whole_numbers(data.get("class_days", {}))
	var saved_skills: Variant = data.get("skills", [])
	if saved_skills is Array:
		for skill: Variant in saved_skills:
			if skill is String:
				skills.append(skill)
	_jobs_today = _whole_numbers(data.get("jobs_today", {}))
	_jobs_day = int(data.get("jobs_day", 0))
	if data.get("sleeping", false):
		_fall_asleep(data.get("passed_out", false), data.get("in_bed", false))
	_loading = false
	return true


## Deletes the saved game, for a new game.
func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(save_path)


## Starts over: the starting money, day 1 at 07:00, full needs, awake, not
## busy or carrying anything, no rent owed, and normal speed (for a new game,
## and for tests).
func reset() -> void:
	money = STARTING_MONEY
	sleeping = false
	passed_out = false
	in_bed = false
	is_walking = false
	activity = ""
	delivery = null
	rent_owed = 0
	next_rent_day = FIRST_RENT_DAY
	bowls_washed_day = 0
	courses = {}
	class_days = {}
	skills.clear()
	_jobs_today = {}
	_jobs_day = 0
	_reminded_for = 0
	time_speed = 1.0
	set_needs(FULL, FULL)
	set_time(START_DAY, START_MINUTES)
	earned_today = 0
	spent_today = 0


func _update_needs(hours: float) -> void:
	if hours <= 0.0:
		return
	if sleeping:
		hunger -= hunger_per_hour * sleep_hunger_multiplier * hours
		energy += (bed_energy_per_hour if in_bed else sleep_energy_per_hour) * hours
	else:
		var tiring := energy_per_hour + (walking_energy_per_hour if is_walking else 0.0)
		if delivery != null:
			tiring += carrying_energy_per_hour
		if hunger <= 0.0:
			tiring *= starving_energy_multiplier
		hunger -= hunger_per_hour * hours
		energy -= tiring * hours
		if activity != "":
			# A meal gives its hunger back bit by bit, up to the end of the meal.
			var busy_minutes := clampf(_activity_end - now(), 0.0, hours * 60.0)
			hunger += _activity_hunger * busy_minutes / _activity_minutes
	hunger = clampf(hunger, 0.0, FULL)
	energy = clampf(energy, 0.0, FULL)
	_announce_needs()
	if sleeping and energy >= FULL:
		wake_up()
	elif not sleeping and energy <= 0.0:
		_fall_asleep(true) # she's run out of energy: she passes out where she stands


func _fall_asleep(from_exhaustion: bool, at_home := false) -> void:
	if activity != "":
		_end_activity(false) # nobody eats or works in their sleep
	if delivery != null:
		var dropped := delivery # she passed out with it on her head
		delivery = null
		load_changed.emit(null)
		load_dropped.emit(dropped)
	sleeping = true
	passed_out = from_exhaustion
	in_bed = at_home
	is_walking = false
	_asleep_since = now()
	_normal_time_speed = time_speed
	time_speed = sleep_time_speed
	sleep_changed.emit(true)
	if at_home and not _loading:
		save_game() # her bed is where the game saves


# Charges the week's rent on rent day, and reminds her the evening before.
func _check_rent() -> void:
	while day > next_rent_day or (day == next_rent_day and minutes >= RENT_TIME):
		next_rent_day += 7
		rent_owed += RENT
		if not pay_rent():
			rent_missed.emit(rent_owed)
			if in_bed:
				wake_up() # the landlady wants her rent: no more sleeping in that room
	var reminder_day := next_rent_day - 1
	if _reminded_for != next_rent_day and (day > reminder_day or (day == reminder_day and minutes >= REMINDER_TIME)):
		_reminded_for = next_rent_day
		if day < next_rent_day or minutes < RENT_TIME:
			rent_reminder.emit(RENT)


func _save_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"money": money,
		"day": day,
		"minutes": minutes,
		"hunger": hunger,
		"energy": energy,
		"sleeping": sleeping,
		"passed_out": passed_out,
		"in_bed": in_bed,
		"rent_owed": rent_owed,
		"next_rent_day": next_rent_day,
		"bowls_washed_day": bowls_washed_day,
		"earned_today": earned_today,
		"spent_today": spent_today,
		"courses": courses,
		"class_days": class_days,
		"skills": skills,
		"jobs_today": _jobs_today,
		"jobs_day": _jobs_day,
	}


# A copy of `value` (a dictionary read from a saved game) with whole numbers for
# its values. JSON stores every number as a decimal, like 2.0.
func _whole_numbers(value: Variant) -> Dictionary:
	var whole := {}
	if value is Dictionary:
		for key: Variant in value:
			if key is String and (value[key] is float or value[key] is int):
				whole[key] = int(value[key])
	return whole


func _end_activity(completed: bool) -> void:
	var finished := activity
	activity = ""
	time_speed = _normal_time_speed
	activity_changed.emit("")
	activity_finished.emit(finished, completed)


func _announce_time() -> void:
	var now_shown := Vector2i(day, floori(minutes))
	if now_shown != _announced_time:
		_announced_time = now_shown
		time_changed.emit(day, minutes)


func _announce_needs() -> void:
	var now_shown := Vector2i(ceili(hunger), ceili(energy))
	if now_shown != _announced_needs:
		_announced_needs = now_shown
		needs_changed.emit(hunger, energy)
