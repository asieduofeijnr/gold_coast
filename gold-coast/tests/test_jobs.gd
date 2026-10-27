extends TestCase
## Checks the other skilled work. With dressmaking she sews kaba and slit at the
## sewing machine by Sister Abena's cloth stall (GH₵80, twice a day, while the
## market's open). With mobile money agent training she minds Auntie Dede's
## MoMo kiosk while Auntie Dede goes to the bank (GH₵45, twice a day), and
## customers come. Without the skill, they tell her where to learn it.

const MAIN_SCENE := preload("res://scenes/main/main.tscn")

var _player: Player
var _phone: Phone


func run_tests() -> void:
	GameState.reset()
	GameState.time_speed = 0.0
	GameState.set_time(1, 9 * 60.0)
	var main := MAIN_SCENE.instantiate()
	add_child(main)
	_player = main.get_node("Player")
	_phone = main.get_node("HUD/Phone")
	await wait_physics_frames(10)
	await _check_sewing(main.get_node("Market") as Market)
	await _check_kiosk(main.get_node("MomoKiosk") as MomoKiosk)
	main.queue_free()
	await get_tree().process_frame
	GameState.reset()


func _check_sewing(market: Market) -> void:
	var sewing := market.sew_job
	var abena := market.get_node("ClothSeller") as Vendor
	var model := _player.get_node("Model") as PlayerModel
	await _press_at(sewing, Vector3(0.0, 0.05, 1.3))
	check(sewing.prompt.begins_with("Sew a kaba and slit (needs") and "Sankofa" in abena.saying() and GameState.activity == "",
			"without dressmaking, Sister Abena sends her to the training college: \"%s\"" % abena.saying())
	GameState.skills.append("dressmaking")
	sewing.refresh()
	var money := GameState.money
	await _press_at(sewing, Vector3(0.0, 0.05, 1.3))
	var started: bool = await wait_until(func() -> bool: return GameState.activity == "Sewing a kaba and slit", 6.0)
	await wait_physics_frames(30)
	check(started and model.animation_player.current_animation == "sew" and market.sewing_machine.sewing,
			"with it, she sits down at the sewing machine and sews (its wheels turning)")
	await wait_until(func() -> bool: return GameState.activity == "", 10.0)
	var text := _phone.shown_sms()
	check(GameState.money == money + 8000 and text.size() == 4 and text[2] == "FROM ABENA" and not market.sewing_machine.sewing
			and "Ayekoo" in abena.saying(), "a kaba and slit takes two game hours and pays GH₵80.00: %s" % " / ".join(text))
	await wait_physics_frames(30)
	await _press_at(sewing, Vector3(0.0, 0.05, 1.3))
	await wait_until(func() -> bool: return GameState.activity == "Sewing a kaba and slit", 6.0)
	await wait_until(func() -> bool: return GameState.activity == "", 10.0)
	await wait_physics_frames(30)
	check(GameState.money == money + 16000 and sewing.prompt == "No more work today", "  ...twice a day")
	GameState.set_time(1, 20 * 60.0)
	await wait_physics_frames(2)
	check(not abena.is_here() and not sewing.enabled and not market.sewing_machine.visible,
			"at night Sister Abena has gone home with her sewing machine")
	GameState.set_time(2, 9 * 60.0)
	await wait_physics_frames(2)


func _check_kiosk(kiosk: MomoKiosk) -> void:
	var shift := kiosk.shift
	var dede := kiosk.dede
	var model := _player.get_node("Model") as PlayerModel
	await _press_at(shift, Vector3(0.0, 0.05, 1.0))
	check(shift.prompt.begins_with("Run the kiosk (needs") and "Sankofa" in dede.saying() and GameState.activity == "",
			"without MoMo agent training, Auntie Dede sends her to the training college: \"%s\"" % dede.saying())
	GameState.skills.append("momo_agent")
	shift.refresh()
	var money := GameState.money
	await _press_at(shift, Vector3(0.0, 0.05, 1.0))
	var started: bool = await wait_until(func() -> bool: return GameState.activity == "Running the MoMo kiosk", 6.0)
	await wait_physics_frames(20)
	check(started and not dede.is_here() and model.animation_player.current_animation == "sit",
			"with it, she takes Auntie Dede's stool while Auntie Dede goes to the bank")
	var served: bool = await wait_until(func() -> bool:
		return kiosk.customers.any(func(customer: Townsperson) -> bool: return customer.visible and customer.saying() != ""), 6.0)
	check(served, "  ...and customers come to her")
	await wait_until(func() -> bool: return GameState.activity == "", 10.0)
	await wait_physics_frames(60)
	var text := _phone.shown_sms()
	check(GameState.money == money + 4500 and text.size() == 4 and text[2] == "FROM DEDE" and dede.is_here()
			and "commission" in dede.saying(), "after two game hours Auntie Dede is back and pays GH₵45.00: %s" % " / ".join(text))
	GameState.set_time(2, 21 * 60.0)
	await wait_physics_frames(2)
	check(not dede.is_here() and not shift.enabled, "at night the kiosk is closed")


# Puts her a little way from `spot` (by `offset`) and presses E.
func _press_at(spot: Interactable, offset: Vector3) -> void:
	teleport(_player, spot.global_position + offset)
	await wait_physics_frames(3)
	await press_action("interact")
