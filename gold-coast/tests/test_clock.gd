extends TestCase
## Checks the day clock: time passes on its own, fast-forwarding lands on the
## right clock times, the day goes up at midnight, the sun is where it should
## be at each time of day, and the phone shows the time.

const MAIN_SCENE := preload("res://scenes/main/main.tscn")


func run_tests() -> void:
	GameState.reset()
	check(GameState.day == 1 and Format.clock(GameState.minutes) == "07:00", "the game starts on day 1 at 07:00")
	await _check_time_passes()
	_check_fast_forward()
	_check_text()
	await _check_sun_and_phone()
	GameState.reset()


func _check_time_passes() -> void:
	GameState.reset()
	var start := GameState.minutes
	await wait_physics_frames(120) # about 2 real seconds
	var passed := GameState.minutes - start
	check(passed > 1.5 and passed < 2.6,
			"time passes on its own, about a game minute each second (%.2f minutes in 2 s)" % passed)


func _check_fast_forward() -> void:
	GameState.reset()
	GameState.time_speed = 0.0 # stop the clock so only fast-forwarding moves it
	var announced := []
	var listen := func(_day: int, minutes: float) -> void: announced.append(Format.clock(minutes))
	GameState.time_changed.connect(listen)

	var wrong := []
	for hour in range(1, 25):
		GameState.advance(60.0)
		var expected := "%02d:00" % ((7 + hour) % 24)
		if Format.clock(GameState.minutes) != expected:
			wrong.append("%s instead of %s" % [Format.clock(GameState.minutes), expected])
	check(wrong.is_empty(), "fast-forwarding a whole day, hour by hour, reaches the right clock times %s" % [wrong])
	check(GameState.day == 2 and Format.clock(GameState.minutes) == "07:00", "  ...ending on day 2 at 07:00")
	check(announced.size() == 24, "  ...and announces each new time once (%d announcements)" % announced.size())

	GameState.set_time(1, 23 * 60 + 59)
	GameState.advance(2.0)
	check(GameState.day == 2 and Format.clock(GameState.minutes) == "00:01", "the day number goes up at midnight")

	announced.clear()
	for i in 3:
		GameState.advance(0.4) # 00:01.0 → 00:02.2, crossing one new minute
	check(announced.size() == 1, "the clock announces at most once per game minute")
	GameState.time_changed.disconnect(listen)


func _check_text() -> void:
	check(Format.clock(0.0) == "00:00" and Format.clock(754.9) == "12:34" and Format.clock(1439.99) == "23:59",
			"times show on a 24-hour clock, 00:00 to 23:59")
	check(Format.weekday(1) == "MON" and Format.weekday(7) == "SUN" and Format.weekday(8) == "MON",
			"the days of the week go MON to SUN and around again")


func _check_sun_and_phone() -> void:
	GameState.reset()
	GameState.time_speed = 0.0
	var main := MAIN_SCENE.instantiate()
	add_child(main)
	var lighting := main.get_node("Lighting") as Lighting
	var phone := main.get_node("HUD/Phone") as Phone

	var sun_checks := [
		[6 * 60, -3.0, 3.0, "at sunrise (06:00) the sun is on the horizon"],
		[12 * 60, 60.0, 66.0, "at midday (12:00) the sun is high"],
		[18 * 60, 3.0, 15.0, "at 18:00 the sun is low"],
	]
	for sun_check in sun_checks:
		await _go_to(sun_check[0])
		var height := lighting.sun_height()
		check(height >= sun_check[1] and height <= sun_check[2], "%s (%.1f° up)" % [sun_check[3], height])

	await _go_to(8 * 60)
	var morning := lighting.toward_sun()
	await _go_to(16 * 60)
	var afternoon := lighting.toward_sun()
	check(morning.x > 0.3 and afternoon.x < -0.3, "the sun moves from the east (morning) to the west (afternoon)")

	await _go_to(22 * 60)
	check(not lighting.is_sun_up() and lighting.is_moon_up(), "at night (22:00) the sun is down and the moon gives light")
	await _go_to(9 * 60)
	check(lighting.is_sun_up() and not lighting.is_moon_up(), "  ...and in the morning (09:00) the sun is back")

	await _go_to(12 * 60)
	check(phone.status_time == "12:00" and phone.screen_day == "MON DAY 1",
			"the phone shows the time and day (%s, %s)" % [phone.status_time, phone.screen_day])
	await press_action("debug_skip_hour")
	check(phone.status_time == "13:00", "  ...and F4 (debug) skips ahead an hour")
	GameState.set_time(3, 8 * 60)
	check(phone.screen_day == "WED DAY 3", "  ...and the day changes with the clock (%s)" % phone.screen_day)

	main.queue_free()


## Sets the clock to `minutes` past midnight on day 1 and lets the lighting catch up.
func _go_to(minutes: float) -> void:
	GameState.set_time(1, minutes)
	await wait_physics_frames(3)
