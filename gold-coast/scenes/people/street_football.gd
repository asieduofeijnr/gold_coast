@tool
class_name StreetFootball
extends Node3D
## Children playing football on the open ground, with stones for goalposts.
## The ball rolls where it's kicked, slowing as it goes. Whoever's nearest runs
## after it, dribbles a moment, and passes it on or shoots at a goal. Walk into
## the ball and you'll kick it too, and the children will have something to say.
##
## The pitch runs along X, centered on this node.

## Sent when the player kicks the ball.
signal player_kicked

const BALL_RADIUS := 0.12
## How quickly the ball slows down as it rolls (metres per second, per second).
const ROLLING_FRICTION := 1.6
const KICK_REACH := 0.55 # how close you need to be to kick it, in metres

## How big the pitch is (along X and Z), in metres.
@export var pitch := Vector2(9.0, 7.0):
	set(value):
		pitch = value
		_rebuild()

## The ball (for tests).
var ball: Node3D
## The ball's speed and direction, in metres per second.
var ball_velocity := Vector3.ZERO
## The children playing (for tests).
var kids: Array[Townsperson] = []

var _player: CharacterBody3D
var _kicked_by_player_at := -INF
# Everything this script made (internal children, not saved in scenes).
var _generated: Array[Node] = []


func _ready() -> void:
	_rebuild()
	if Engine.is_editor_hint():
		return
	if not GameState.town_life:
		return
	for i in 4:
		var kid := Townsperson.new()
		kid.body = Townsperson.Body.BOY if i != 2 else Townsperson.Body.GIRL
		kid.top_color = Palette.ColorName.KENTE_GOLD # school uniform: yellow and brown
		kid.bottom_color = Palette.ColorName.WOOD_DARK
		kid.walk_speed = 1.0
		kid.run_speed = 2.4
		kid.visible = false
		add_child(kid)
		kids.append(kid)
	for i in 3:
		await get_tree().physics_frame # let the walkable area finish baking
	_play()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or ball == null:
		return
	# The ball rolls, slows down, and bounces back off the edges of the pitch.
	var speed := ball_velocity.length()
	if speed > 0.0:
		ball_velocity = ball_velocity.normalized() * maxf(speed - ROLLING_FRICTION * delta, 0.0)
		ball.position += ball_velocity * delta
		var half := pitch / 2.0
		if absf(ball.position.x) > half.x:
			ball.position.x = clampf(ball.position.x, -half.x, half.x)
			ball_velocity.x *= -0.6
		if absf(ball.position.z) > half.y:
			ball.position.z = clampf(ball.position.z, -half.y, half.y)
			ball_velocity.z *= -0.6
		# Roll it the way it's going.
		var axis := Vector3.UP.cross(ball_velocity).normalized()
		if axis != Vector3.ZERO:
			ball.rotate(axis, ball_velocity.length() * delta / BALL_RADIUS)
	_check_player_kick()


## Kicks the ball toward `target` (a point on the ground), hard enough to get
## there.
func kick_toward(target: Vector3) -> void:
	var gap := target - ball.global_position
	gap.y = 0.0
	var power := sqrt(2.0 * ROLLING_FRICTION * gap.length()) + 0.5
	ball_velocity = gap.normalized() * minf(power, 7.0)


# The children's game: whoever's nearest the ball chases it and plays it on;
# the others drift about the pitch. At night they go home.
func _play() -> void:
	while is_inside_tree():
		if not TownLife.is_daytime():
			for kid in kids:
				kid.vanish()
			while not TownLife.is_daytime():
				await _wait(5.0)
		for kid in kids:
			if not kid.visible:
				kid.appear_at(_random_spot())
		var chaser := _nearest_kid()
		chaser.walk_to(ball.global_position, true)
		for kid in kids:
			if kid != chaser and not kid.walking and randf() < 0.25:
				kid.walk_to(_random_spot(), randf() < 0.5)
		var gap := Vector2(chaser.global_position.x - ball.global_position.x, chaser.global_position.z - ball.global_position.z)
		if gap.length() < KICK_REACH and ball_velocity.length() < 2.5:
			_kick_on(chaser)
			await _wait(0.6)
		await _wait(0.25)


# `kicker` plays the ball on: a pass to a friend, or a shot at a goal.
func _kick_on(kicker: Townsperson) -> void:
	var half := pitch / 2.0
	var target := Vector3.ZERO
	if randf() < 0.35:
		var goal_x := half.x if kicker.global_position.x < global_position.x else -half.x
		target = to_global(Vector3(goal_x, 0.0, randf_range(-0.6, 0.6)))
		if randf() < 0.5:
			kicker.say(["Shoot!", "Goal!", "Goaaal!"].pick_random())
	else:
		var friend: Townsperson = kids.filter(func(kid: Townsperson) -> bool: return kid != kicker).pick_random()
		target = friend.global_position
		if randf() < 0.3:
			kicker.say(["Pass!", "Here!", "My ball!"].pick_random())
	kick_toward(target)


# Walking into the ball kicks it the way she's going.
func _check_player_kick() -> void:
	if not is_instance_valid(_player):
		# Find her (again, if the town was reloaded and the old her is gone).
		_player = get_tree().get_first_node_in_group("player") as CharacterBody3D
		if _player == null:
			return
	var gap := Vector2(ball.global_position.x - _player.global_position.x, ball.global_position.z - _player.global_position.z)
	var moving := Vector2(_player.velocity.x, _player.velocity.z)
	if gap.length() < KICK_REACH and moving.length() > 0.5 and gap.dot(moving) > 0.0:
		var now := Time.get_ticks_msec() / 1000.0
		if now - _kicked_by_player_at < 0.5:
			return
		_kicked_by_player_at = now
		ball_velocity = Vector3(moving.x, 0.0, moving.y).normalized() * 5.5
		player_kicked.emit()
		if not kids.is_empty():
			_nearest_kid().say(["Ei! Sister can play!", "Pass it back!", "Auntie, join us!"].pick_random())


func _nearest_kid() -> Townsperson:
	var nearest: Townsperson = kids[0]
	for kid in kids:
		if kid.global_position.distance_to(ball.global_position) < nearest.global_position.distance_to(ball.global_position):
			nearest = kid
	return nearest


func _random_spot() -> Vector3:
	var half := pitch / 2.0 - Vector2(0.5, 0.5)
	return to_global(Vector3(randf_range(-half.x, half.x), 0.0, randf_range(-half.y, half.y)))


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, false).timeout


func _rebuild() -> void:
	if not is_node_ready():
		return
	for node in _generated:
		node.free()
	_generated.clear()
	# A white ball with a dark band, so you can see it roll.
	ball = Node3D.new()
	ball.position = Vector3(0, BALL_RADIUS, 0)
	_add(ball)
	ball.add_child(Shapes.sphere(BALL_RADIUS, Vector3.ZERO, Palette.ColorName.PAPER))
	var band := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = BALL_RADIUS - 0.01
	torus.outer_radius = BALL_RADIUS + 0.005
	band.mesh = torus
	band.material_override = Palette.material(Palette.ColorName.DARK_BROWN)
	band.rotation.x = PI / 2.0
	ball.add_child(band)
	# Stones for goalposts at each end.
	var half := pitch / 2.0
	for x in [-half.x - 0.2, half.x + 0.2]:
		for z in [-0.9, 0.9]:
			_add(Shapes.sphere(0.16, Vector3(x, 0.08, z), Palette.ColorName.ZINC_DARK, 0.6))


func _add(node: Node3D) -> void:
	add_child(node, false, Node.INTERNAL_MODE_FRONT)
	_generated.append(node)
