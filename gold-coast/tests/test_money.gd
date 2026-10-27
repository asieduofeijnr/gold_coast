extends TestCase
## Checks money: the Ghana cedi formatting, earning and spending, paying and
## receiving by mobile money, and that the phone on screen always shows the
## right mobile money balance.

const MAIN_SCENE := preload("res://scenes/main/main.tscn")


func run_tests() -> void:
	_check_formatting()
	_check_earning_and_spending()
	_check_mobile_money()
	await _check_phone()


func _check_formatting() -> void:
	var cases := [
		[10000, "GH₵100.00"], [650, "GH₵6.50"], [123456789, "GH₵1,234,567.89"], [0, "GH₵0.00"],
		[-50000, "-GH₵500.00"], [99, "GH₵0.99"], [100000, "GH₵1,000.00"],
	]
	for case in cases:
		var shown := Format.cedis(case[0])
		check(shown == case[1], "%d pesewas shows as %s (got %s)" % [case[0], case[1], shown])


func _check_earning_and_spending() -> void:
	GameState.reset()
	check(GameState.money == 10000, "you start with GH₵100.00")

	var heard := []
	var listen := func(new_amount: int) -> void: heard.append(new_amount)
	GameState.money_changed.connect(listen)
	check(GameState.spend_money(2500) and GameState.money == 7500, "spending GH₵25.00 when you have enough works")
	check(not GameState.spend_money(10000) and GameState.money == 7500,
			"spending more than you have fails and changes nothing")
	GameState.add_money(650)
	check(GameState.money == 8150, "earning GH₵6.50 adds it")
	check(heard == [7500, 8150], "every change is announced with the new amount (heard %s)" % [heard])
	GameState.money_changed.disconnect(listen)
	GameState.reset()


func _check_mobile_money() -> void:
	GameState.reset()
	var texts := []
	var sent := func(amount: int, payee: String) -> void: texts.append(["sent", amount, payee])
	var failed := func(amount: int, payee: String) -> void: texts.append(["failed", amount, payee])
	var received := func(amount: int, payer: String) -> void: texts.append(["received", amount, payer])
	GameState.payment_sent.connect(sent)
	GameState.payment_failed.connect(failed)
	GameState.payment_received.connect(received)

	check(GameState.pay(2500, "CHOP BAR") and GameState.money == 7500 and texts == [["sent", 2500, "CHOP BAR"]],
			"paying GH₵25.00 by mobile money takes it and sends a payment text")
	texts.clear()
	check(not GameState.pay(9000, "CHOP BAR") and GameState.money == 7500 and texts == [["failed", 9000, "CHOP BAR"]],
			"paying more than you have fails, changes nothing, and sends a failed text")
	texts.clear()
	GameState.receive(2000, "CHOP BAR")
	check(GameState.money == 9500 and texts == [["received", 2000, "CHOP BAR"]],
			"receiving GH₵20.00 adds it and sends a received text")

	GameState.payment_sent.disconnect(sent)
	GameState.payment_failed.disconnect(failed)
	GameState.payment_received.disconnect(received)
	GameState.reset()


func _check_phone() -> void:
	GameState.reset()
	var main := MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame
	var phone := main.get_node_or_null("HUD/Phone") as Phone
	check(phone != null, "there's a phone on screen")
	if phone == null:
		main.queue_free()
		return

	check(phone.screen_value == "GH₵100.00", "the phone shows the starting balance, GH₵100.00")
	check(phone.can_show(phone.screen_value), "  ...and its screen can draw every character, including ₵")
	check(phone.screen_title == "MOBILE MONEY", "  ...on a mobile money screen")

	GameState.add_money(1000)
	check(phone.screen_value == "GH₵110.00", "the phone updates as soon as money changes")

	await press_action("debug_add_money")
	check(GameState.money == 12000 and phone.screen_value == "GH₵120.00", "F2 (debug) adds GH₵10.00")
	await press_action("debug_spend_money")
	check(GameState.money == 11000 and phone.screen_value == "GH₵110.00", "F3 (debug) spends GH₵10.00")

	main.queue_free()
	GameState.reset()
