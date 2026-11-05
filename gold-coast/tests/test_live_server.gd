extends TestCase
## Checks how the game finds its online server (LiveServer, Online.use_server_for()):
## - on itch.io, once there's an online server, it uses that, over HTTPS
## - with no online server yet, it keeps this computer's, so it plays offline there
## - the editor and the web build served on this computer keep this computer's
## - server/production/deploy.sh can read the server's name and key from LiveServer


func run_tests() -> void:
	var saved := [Online.host, Online.port, Online.scheme, Online.server_key]
	_check_itch_io()
	_check_this_computer()
	_check_no_server_yet()
	_check_live_server_file()
	Online.host = saved[0]
	Online.port = saved[1]
	Online.scheme = saved[2]
	Online.server_key = saved[3]


# Back to this computer's server, as the game starts.
func _local() -> void:
	Online.host = "127.0.0.1"
	Online.port = 7350
	Online.scheme = "http"
	Online.server_key = "defaultkey"


func _check_itch_io() -> void:
	_local()
	Online.use_server_for("html-classic.itch.zone", "api.goldcoast.example", "gc_test_key")
	check(Online.host == "api.goldcoast.example" and Online.port == 443 and Online.scheme == "https"
			and Online.server_key == "gc_test_key",
			"on itch.io, the game uses the online server, over HTTPS, with its key")
	check(Online.can_reach(Online.host, "html-classic.itch.zone"), "and on itch.io it can reach it, so it plays online")


func _check_this_computer() -> void:
	for page: String in ["127.0.0.1", "localhost", ""]:
		_local()
		Online.use_server_for(page, "api.goldcoast.example", "gc_test_key")
		check(Online.host == "127.0.0.1" and Online.port == 7350 and Online.scheme == "http"
				and Online.server_key == "defaultkey",
				"on this computer (%s), the game keeps this computer's server" % (page if page != "" else "the editor"))


func _check_no_server_yet() -> void:
	_local()
	Online.use_server_for("html-classic.itch.zone", "", "gc_test_key")
	check(Online.host == "127.0.0.1" and Online.server_key == "defaultkey",
			"with no online server yet, the game keeps this computer's")
	check(not Online.can_reach(Online.host, "html-classic.itch.zone"), "so on itch.io it plays offline, as before")


func _check_live_server_file() -> void:
	var text := FileAccess.get_file_as_string("res://scripts/live_server.gd")
	# The same lines deploy.sh reads (with sed), so the server gets the game's name and key.
	var host := RegEx.create_from_string("(?m)^const HOST := \"(.*)\"$").search_all(text)
	var key := RegEx.create_from_string("(?m)^const SERVER_KEY := \"(.*)\"$").search_all(text)
	check(host.size() == 1 and host[0].get_string(1) == LiveServer.HOST,
			"deploy.sh can read the server's name from live_server.gd")
	check(key.size() == 1 and key[0].get_string(1) == LiveServer.SERVER_KEY,
			"deploy.sh can read the server's key from live_server.gd")
	check(LiveServer.SERVER_KEY != "defaultkey" and LiveServer.SERVER_KEY.length() >= 16
			and RegEx.create_from_string("^[A-Za-z0-9_]+$").search(LiveServer.SERVER_KEY) != null,
			"the online server's key isn't Nakama's default, and is only letters, numbers and _")
	check(LiveServer.HOST == "" or RegEx.create_from_string("^[a-z0-9.-]+$").search(LiveServer.HOST) != null,
			"the server's name is just a name (like api.yourgame.com), without https:// or a slash")
