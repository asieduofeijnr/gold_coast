class_name TownPlayers
extends Node3D
## The other players in the shared Gold Coast. While she's logged in, the game
## joins the town on the server (see Online), and this node:
## - tells the town where she is, 10 times a second (move_of())
## - keeps a RemotePlayer for everyone else there, walking where they walk,
##   and takes them away when they leave
## - keeps her clock with the town's, so everyone has the same time of day
##   (GameState.shared_clock and follow_world_clock())
## Offline, or with no server, the town is just hers. main.gd makes it.

## How often it tells the town where she is, in seconds.
const SEND_EVERY := 0.1

## The player here.
var player: Player

var _players := {} # each other player's id -> their RemotePlayer
var _since_sent := 0.0


func _ready() -> void:
	Online.town_player_moved.connect(_on_player_moved)
	Online.town_player_left.connect(_on_player_left)
	Online.account_changed.connect(_join)
	Online.world_clock_changed.connect(_follow_clock)
	# Whoever was in town already (when the scene starts again, say).
	for id: String in Online.town_players:
		_on_player_moved(id, Online.town_players[id].username, Online.town_players[id].move)
	_join()


## The other players here now: their id -> their RemotePlayer.
func players() -> Dictionary:
	return _players


## What the town is told about where she is, and what she's doing: her
## position (x, y, z), which way she faces (f), how fast she's walking (s), her
## pose (p, like "eat", or ""), and whether she's asleep (sl) or indoors (in).
static func move_of(who: Player) -> Dictionary:
	var model := who.get_node("Model") as PlayerModel
	var at := who.global_position
	return {"x": snappedf(at.x, 0.01), "y": snappedf(at.y, 0.01), "z": snappedf(at.z, 0.01),
			"f": snappedf(who.rotation.y, 0.01), "s": snappedf(model.move_speed, 0.1), "p": String(model.pose),
			"sl": model.sleeping, "in": model.inside}


func _physics_process(delta: float) -> void:
	GameState.shared_clock = Online.in_town
	if not Online.in_town or player == null:
		return
	if Online.world_clock_known and not GameState.is_clock_synced():
		_follow_clock() # just joined, or a game was loaded or started
	_since_sent += delta
	if _since_sent >= SEND_EVERY:
		_since_sent = 0.0
		Online.send_move(move_of(player))


func _follow_clock() -> void:
	if Online.in_town:
		GameState.follow_world_clock(Online.world_minutes())


func _join() -> void:
	if Online.is_logged_in():
		Online.join_town()


func _on_player_moved(id: String, username: String, move: Dictionary) -> void:
	var other: RemotePlayer = _players.get(id)
	if other == null:
		other = RemotePlayer.new()
		other.username = username
		add_child(other)
		_players[id] = other
	other.move_to(move)


func _on_player_left(id: String) -> void:
	var other: RemotePlayer = _players.get(id)
	if other != null:
		other.queue_free()
		_players.erase(id)
