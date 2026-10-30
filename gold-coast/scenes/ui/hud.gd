extends CanvasLayer
## Everything drawn on top of the game: a phone in the corner that shows the
## time, the day, your mobile money balance, and your needs, plus a dark shade
## over the screen while she sleeps. Every mobile money payment arrives on the
## phone as a text message. While she carries a load, the phone shows where it's
## going and how many minutes are left. Rent, its reminder, and the bedtime
## save (with what she earned and spent that day) come as texts too.
##
## It also holds the title screen (TitleScreen) and the game's menu, which is
## on the phone (PauseMenu: M, Esc, or the phone's middle key).
##
## It keeps working while the game is paused (when a menu is open), so the
## phone can still show texts then.

## How much the money debug keys (F2 and F3) add or take away: GH₵10.00.
const DEBUG_AMOUNT := 1000
## How much faster time runs while fast time (F5) is on.
const FAST_TIME_SPEED := 30.0
## How dark the screen gets while she sleeps (0 = not at all, 1 = black).
const SLEEP_SHADE := 0.55

var _shade_tween: Tween

@onready var phone: Phone = $Phone
@onready var _sleep_shade: ColorRect = $SleepShade


func _ready() -> void:
	_sleep_shade.color = Palette.color(Palette.ColorName.SKY_TOP_NIGHT) * Color(1, 1, 1, 0.0)
	GameState.money_changed.connect(_show_money)
	GameState.time_changed.connect(_show_time)
	GameState.needs_changed.connect(_show_needs)
	GameState.sleep_changed.connect(_show_sleep)
	GameState.sleep_refused.connect(phone.show_message)
	GameState.payment_sent.connect(_show_payment_sent)
	GameState.payment_failed.connect(_show_payment_failed)
	GameState.payment_received.connect(_show_payment_received)
	GameState.mosquitoes_woke_her.connect(_show_mosquitoes)
	GameState.load_changed.connect(_on_load_changed)
	GameState.load_dropped.connect(_show_load_dropped)
	GameState.rent_missed.connect(_show_rent_missed)
	GameState.rent_reminder.connect(_show_rent_reminder)
	GameState.rent_paid.connect(_on_rent_paid)
	GameState.game_saved.connect(_show_saved)
	GameState.skill_learned.connect(_show_certificate)
	_show_money(GameState.money)
	_show_time(GameState.day, GameState.minutes)
	_show_needs(GameState.hunger, GameState.energy)


func _show_money(pesewas: int) -> void:
	phone.screen_value = Format.cedis(pesewas)


func _show_time(day: int, minutes: float) -> void:
	phone.status_time = Format.clock(minutes)
	if GameState.delivery != null:
		phone.screen_day = "TO " + GameState.delivery.phone_place
		_show_status() # one minute less to deliver it
	else:
		phone.screen_day = "%s DAY %d" % [Format.weekday(day), day]


func _on_load_changed(_headload: Delivery) -> void:
	_show_time(GameState.day, GameState.minutes)
	_show_status()


func _show_needs(hunger: float, energy: float) -> void:
	phone.hunger = hunger
	phone.energy = energy
	_show_status()


func _show_sleep(asleep: bool) -> void:
	if _shade_tween != null:
		_shade_tween.kill()
	_shade_tween = create_tween()
	_shade_tween.tween_property(_sleep_shade, "color:a", SLEEP_SHADE if asleep else 0.0, 0.6)
	_show_status()


func _show_payment_sent(amount: int, payee: String) -> void:
	phone.show_sms(PackedStringArray(["PAYMENT SENT", Format.cedis(amount), "TO " + payee, _balance_line()]))


func _show_payment_failed(amount: int, _payee: String) -> void:
	phone.show_sms(PackedStringArray(["PAYMENT FAILED", "NEED " + Format.cedis(amount), _balance_line(),
			"GET A HUSTLE!"]))


func _show_payment_received(amount: int, payer: String) -> void:
	phone.show_sms(PackedStringArray(["RECEIVED", Format.cedis(amount), "FROM " + payer, _balance_line()]))


func _show_load_dropped(_headload: Delivery) -> void:
	phone.show_sms(PackedStringArray(["LOAD DROPPED!", "YOU PASSED OUT", "NO PAY"]))


func _show_rent_missed(owed: int) -> void:
	phone.show_sms(PackedStringArray(["RENT DUE!", "OWE " + Format.cedis(owed), "ROOM LOCKED", "PAY LANDLADY"]))
	_show_status()


func _show_rent_reminder(amount: int) -> void:
	phone.show_sms(PackedStringArray(["REMINDER", "RENT TOMORROW", Format.cedis(amount), "AT 08:00"]))


# She's finished a course at the training college.
func _show_certificate(course: Course) -> void:
	phone.show_sms(PackedStringArray(["CERTIFICATE!", course.phone_title, "SANKOFA", "COLLEGE"]))


func _on_rent_paid(_amount: int) -> void:
	_show_status()


# Bedtime: the game is saved, with the day's money in and out.
func _show_saved() -> void:
	phone.show_sms(PackedStringArray(["GAME SAVED", "DAY %d" % GameState.day,
			_fit("IN +", Format.cedis(GameState.earned_today)), _fit("OUT -", Format.cedis(GameState.spent_today))]))


func _show_mosquitoes() -> void:
	phone.show_sms(PackedStringArray(["MOSQUITOES!", "BZZZ... OUCH!", "SLEEP AT HOME", "NEXT TIME"]))


# "BAL GH₵75.00", or just the amount if that's too long for the screen.
func _balance_line() -> String:
	return _fit("BAL ", Format.cedis(GameState.money))


# `label` and then `amount`, or just the amount if both don't fit on the screen.
func _fit(label: String, amount: String) -> String:
	var line := label + amount
	return line if line.length() <= Phone.MAX_CHARACTERS else amount


## The title line on the phone says what matters most right now.
func _show_status() -> void:
	if GameState.sleeping:
		if GameState.passed_out:
			phone.screen_title = "PASSED OUT!"
		else:
			phone.screen_title = "SWEET DREAMS" if GameState.in_bed else "SLEEPING..."
	elif GameState.delivery != null:
		var left := ceili(GameState.delivery_minutes_left())
		phone.screen_title = "%d MIN LEFT" % left if left > 0 else "LATE! HURRY"
	elif GameState.energy < GameState.LOW:
		phone.screen_title = "Z TO SLEEP"
	elif GameState.hunger < GameState.LOW:
		phone.screen_title = "HUNGRY!"
	elif GameState.is_room_locked():
		phone.screen_title = "RENT OWED!"
	else:
		phone.screen_title = "MOBILE MONEY"


# Debug keys, only in builds made for testing: F2 adds money, F3 spends it,
# F4 skips ahead an hour, F5 turns fast time on or off, F6 fills her needs, and
# F7 starts a new game straight away (deleting the saved one).
func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event.is_action_pressed("debug_add_money"):
		GameState.add_money(DEBUG_AMOUNT)
	elif event.is_action_pressed("debug_spend_money"):
		GameState.spend_money(DEBUG_AMOUNT)
	elif event.is_action_pressed("debug_skip_hour"):
		GameState.advance(60.0)
	elif event.is_action_pressed("debug_fast_time"):
		GameState.time_speed = 1.0 if GameState.time_speed > 1.0 else FAST_TIME_SPEED
	elif event.is_action_pressed("debug_fill_needs"):
		GameState.set_needs(GameState.FULL, GameState.FULL)
	elif event.is_action_pressed("debug_new_game"):
		GameState.delete_save()
		GameState.reset()
		GameState.start_with = "new" # no title screen
		get_tree().paused = false
		get_tree().reload_current_scene()
