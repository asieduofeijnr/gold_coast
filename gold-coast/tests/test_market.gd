extends TestCase
## Checks the market through the evening: when it closes at 18:00, the sellers
## pack up one by one (Madam Serwaa last), taking their goods, stools, and
## basins and folding their umbrellas, so at night it's empty. They're all back
## and set up by the time it opens at 06:00. And its name is on a painted sign,
## not floating over it.

const MAIN_SCENE := preload("res://scenes/main/main.tscn")

var _market: Market
var _stalls: Array[MarketStall] = []
var _belongings: Array[Node3D] = []


func run_tests() -> void:
	GameState.reset()
	GameState.time_speed = 0.0
	GameState.set_time(1, 17 * 60.0)
	var main := MAIN_SCENE.instantiate()
	add_child(main)
	await wait_physics_frames(10)
	_market = main.get_node("Market") as Market
	for child in _market.get_children():
		if child is MarketStall:
			_stalls.append(child)
	for seller in _market.sellers():
		_belongings.append_array(seller.belongings)
	var sellers := _market.sellers()

	check(sellers.size() == 9 and _everyone_here(true) and _belongings.size() == 6, # stools, basins, loads, sewing machine
			"in the afternoon, all %d sellers are at their places with their goods out" % sellers.size())
	GameState.set_time(1, 18 * 60.0 + 4.0)
	check(not sellers[0].is_here() and not sellers[1].is_here() and sellers[2].is_here() and _market.trader.is_here(),
			"after 18:00 they pack up one by one: 2 have gone by 18:04, and Madam Serwaa is still there")
	check(not _stall_of(sellers[0]).goods_out() and not _stall_of(sellers[0]).umbrella_up() and _stall_of(sellers[2]).goods_out(),
			"  ...a stall packs up with its seller: the goods go and the umbrella folds")
	GameState.set_time(1, 18 * 60.0 + 30.0)
	check(_everyone_here(false) and not _market.hire_spot.enabled,
			"by 18:30 everyone has gone home: no sellers, no goods, no stools or basins, and the market is empty")
	GameState.set_time(2, 5 * 60.0)
	check(_everyone_here(false), "  ...and it stays empty all night (05:00)")
	GameState.set_time(2, 6 * 60.0)
	check(_everyone_here(true) and _market.hire_spot.enabled and _market.is_open(),
			"they're all back and set up by 06:00, when the market opens")

	var signboard := main.get_node("Market/MarketSign") as Signboard
	var camera := main.get_node("IsoCamera") as Camera3D
	var to_camera := camera.global_position - signboard.global_position
	var facing := signboard.global_basis.z
	check(signboard.text.ends_with("MARKET") and signboard.text != "MARKET" and signboard.post_height > 2.0
			and Vector2(facing.x, facing.z).dot(Vector2(to_camera.x, to_camera.z).normalized()) > 0.5,
			"the market's name is on a painted sign on posts, facing the camera: \"%s\"" % signboard.text)
	var floating := 0
	for child in _market.get_children(true):
		if child is Label3D:
			floating += 1
	check(floating == 0, "  ...instead of a name floating over it")
	main.queue_free()
	await get_tree().process_frame
	GameState.reset()


# Whether every seller is here (or, with false, gone), with her stall and her
# things to match.
func _everyone_here(here: bool) -> bool:
	for seller in _market.sellers():
		if seller.is_here() != here or seller.visible != here:
			return false
	for stall in _stalls:
		if stall.goods_out() != here or stall.umbrella_up() != here:
			return false
	for thing in _belongings:
		if thing.visible != here:
			return false
	return true


func _stall_of(seller: Vendor) -> MarketStall:
	for stall in _stalls:
		if stall.seller == seller:
			return stall
	return null
