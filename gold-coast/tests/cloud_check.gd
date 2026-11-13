extends Node
## A check of cloud saves against a real Gold Coast server: the one on this
## computer (server/docker-compose.yml), which must be running. The automated
## tests use a pretend server (tests/test_cloud_save.gd); this checks what only
## the real one can show:
## 1. a save goes up to the server's storage, and comes back down the same
## 2. a save only goes up over the copy it looked at (Nakama's versions): one
##    that's out of date is turned down, and the game can tell that's why
## 3. only she can read her save (owner-only), and nobody else can
## It makes two accounts of its own on that server the first time
## (cloud_check_a and cloud_check_b), and logs in to them after. Run it from the
## gold-coast folder, in your own Terminal (the AI's sandbox can't reach the
## server), with the server running:
##   /Applications/Godot.app/Contents/MacOS/Godot --headless --path . res://tests/cloud_check.tscn
## It prints PASS or FAIL for each check, then CLOUD CHECK PASS (exit code 0)
## or CLOUD CHECK FAIL (exit code 1).

const PEOPLE := [
	{"email": "cloud_check_a@example.com", "username": "cloud_check_a"},
	{"email": "cloud_check_b@example.com", "username": "cloud_check_b"},
]
const PASSWORD := "cloud-check-only"

var _failures := 0


func _ready() -> void:
	if Online.host != "127.0.0.1":
		print("The cloud check makes accounts of its own, so it only runs against the server on this computer.")
		get_tree().quit(1)
		return
	print("Cloud check, against the server at %s://%s:%d" % [Online.scheme, Online.host, Online.port])
	var backend := NakamaBackend.new(Online.host, Online.port, Online.scheme, Online.server_key)
	var a := await _log_in(backend, PEOPLE[0])
	var b := await _log_in(backend, PEOPLE[1])
	_check(not a.is_empty() and not b.is_empty(), "logging in to the check's two accounts")
	if a.is_empty() or b.is_empty():
		print("  Is the server running? From kayayo/: docker compose -f server/docker-compose.yml up -d")
		_finish()
		return
	var save := {"version": GameState.SAVE_VERSION, "money": 4321, "day": 3, "minutes": 612.5, "hunger": 80.25,
			"energy": 70.5, "player": {"x": -4.99360370635986, "y": 0.0, "z": 2.5, "facing": 1.25},
			"saved_at": int(Time.get_unix_time_from_system())}
	var text := JSON.stringify(save, "\t")

	# 1. Up, and back down the same.
	var before: Dictionary = await backend.read_save(a.token, a.refresh_token)
	var there := String(before.get("version", ""))
	var up: Dictionary = await backend.write_save(a.token, a.refresh_token, text, there if there != "" else "*")
	_check(up.get("ok", false) and String(up.get("version", "")) != "", "a save goes up to the server's storage")
	var back: Dictionary = await backend.read_save(a.token, a.refresh_token)
	var json := JSON.new()
	json.parse(text)
	_check(back.get("ok", false) and back.get("version") == up.get("version") and GameState.is_save(back.get("save"))
			and back.get("save") == json.data,
			"  ...and comes back down the same game (so two saves of the same game count as the same)")

	# 2. Versions: only over the copy it looked at.
	save.money = 5000
	var newer := JSON.stringify(save, "\t")
	var out_of_date: Dictionary = await backend.write_save(a.token, a.refresh_token, newer, "*")
	_check(not out_of_date.get("ok", false) and out_of_date.get("conflict", false),
			"a save going up as if there were nothing there yet is turned down, and the game can tell why (%s)"
			% out_of_date.get("error", ""))
	var stale := String(there if there != "" else "not-a-version")
	var old_look: Dictionary = await backend.write_save(a.token, a.refresh_token, newer, stale)
	_check(not old_look.get("ok", false) and old_look.get("conflict", false),
			"  ...so is one going up over a copy that's changed since it looked")
	var over: Dictionary = await backend.write_save(a.token, a.refresh_token, newer, String(up.get("version", "")))
	_check(over.get("ok", false) and over.get("version") != up.get("version"),
			"  ...one going up over the copy it looked at is taken, with a new version")

	# 3. Only she can read it.
	var client := Nakama.create_client(Online.server_key, Online.host, Online.port, Online.scheme, 10,
			NakamaLogger.LOG_LEVEL.ERROR)
	var hers := NakamaStorageObjectId.new(NakamaBackend.SAVES, NakamaBackend.SAVE_KEY, String(a.user_id))
	var as_her: NakamaAPI.ApiStorageObjects = await client.read_storage_objects_async(
			NakamaSession.new(a.token, false, a.refresh_token), [hers])
	var mine: NakamaAPI.ApiStorageObject = null
	if not as_her.is_exception() and as_her.objects.size() == 1:
		mine = as_her.objects[0]
	_check(mine != null and mine.permission_read == NakamaBackend.OWNER_ONLY and mine.permission_write == NakamaBackend.OWNER_ONLY,
			"her save is kept as hers alone (read and write: owner only)")
	var as_him: NakamaAPI.ApiStorageObjects = await client.read_storage_objects_async(
			NakamaSession.new(b.token, false, b.refresh_token), [hers])
	_check(not as_him.is_exception() and as_him.objects.is_empty(), "  ...another account can't read it")
	_finish()


# Logs in to one of the check's accounts, making it the first time. Returns the
# login (as NakamaBackend gives it), or {} if it didn't work.
func _log_in(backend: NakamaBackend, who: Dictionary) -> Dictionary:
	var login: Dictionary = await backend.log_in(who.email, PASSWORD)
	if not login.get("ok", false) and not login.get("unreachable", false):
		login = await backend.sign_up(who.email, PASSWORD, who.username,
				{"name": "Cloud check", "birthdate": "1990-01-01", "terms": Online.TERMS_VERSION})
	if not login.get("ok", false):
		print("  %s: %s" % [who.username, login.get("error", "")])
		return {}
	return login


func _check(passed: bool, description: String) -> void:
	if not passed:
		_failures += 1
	print("  %s  %s" % ["PASS" if passed else "FAIL", description])


func _finish() -> void:
	print("CLOUD CHECK PASS" if _failures == 0 else "CLOUD CHECK FAIL (%d)" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)
