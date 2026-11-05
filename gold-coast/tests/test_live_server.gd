extends TestCase
## Checks how the game finds its online server (LiveServer, Online.use_server_for()):
## - on itch.io, once there's an online server, it uses that, over HTTPS
## - with no online server yet, it keeps this computer's, so it plays offline there
## - the editor and the web build served on this computer keep this computer's,
##   unless they're asked for the online one, to try it out first
##   (?server=live on the page, or --server=live for Godot)
## - the online server's login is kept apart from this computer's
## - server/production/deploy.sh can read the server's name and key from LiveServer

const LIVE := "api.goldcoast.example"


func run_tests() -> void:
	var saved := [Online.host, Online.port, Online.scheme, Online.server_key, Online.account_file]
	_check_itch_io()
	_check_this_computer()
	_check_trying_it_first()
	_check_no_server_yet()
	_check_live_server_file()
	Online.host = saved[0]
	Online.port = saved[1]
	Online.scheme = saved[2]
	Online.server_key = saved[3]
	Online.account_file = saved[4]


# Back to this computer's server, as the game starts.
func _local() -> void:
	Online.host = "127.0.0.1"
	Online.port = 7350
	Online.scheme = "http"
	Online.server_key = "defaultkey"
	Online.account_file = Online.ACCOUNT_FILE


func _is_local() -> bool:
	return (Online.host == "127.0.0.1" and Online.port == 7350 and Online.scheme == "http"
			and Online.server_key == "defaultkey" and Online.account_file == Online.ACCOUNT_FILE)


func _is_live() -> bool:
	return (Online.host == LIVE and Online.port == 443 and Online.scheme == "https"
			and Online.server_key == "gc_test_key" and Online.account_file == Online.LIVE_ACCOUNT_FILE)


func _check_itch_io() -> void:
	_local()
	Online.use_server_for("html-classic.itch.zone", false, LIVE, "gc_test_key")
	check(_is_live(), "on itch.io, the game uses the online server, over HTTPS, with its key")
	check(Online.can_reach(Online.host, "html-classic.itch.zone"), "and on itch.io it can reach it, so it plays online")
	check(Online.LIVE_ACCOUNT_FILE != Online.ACCOUNT_FILE,
			"the online server's login is kept apart from this computer's")


func _check_this_computer() -> void:
	for page: String in ["127.0.0.1", "localhost", ""]:
		_local()
		Online.use_server_for(page, false, LIVE, "gc_test_key")
		check(_is_local(), "on this computer (%s), the game keeps this computer's server"
				% (page if page != "" else "the editor"))


func _check_trying_it_first() -> void:
	check(Online.wants_live_server("?server=live", PackedStringArray())
			and Online.wants_live_server("", PackedStringArray(["--server=live"]))
			and not Online.wants_live_server("?lang=en", PackedStringArray(["--verbose"])),
			"?server=live on the page, or --server=live for Godot, asks for the online server")
	for page: String in ["127.0.0.1", ""]:
		_local()
		Online.use_server_for(page, true, LIVE, "gc_test_key")
		check(_is_live(), "asked for it, this computer's copy (%s) uses the online server, to try it before itch.io"
				% ("the web page" if page != "" else "the editor"))
	check(Online.can_reach(Online.host, "127.0.0.1"), "  ...and a page on this computer can reach it")


func _check_no_server_yet() -> void:
	_local()
	Online.use_server_for("html-classic.itch.zone", false, "", "gc_test_key")
	check(_is_local(), "with no online server yet, the game keeps this computer's")
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
