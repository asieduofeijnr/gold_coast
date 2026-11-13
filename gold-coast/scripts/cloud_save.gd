class_name CloudSave
extends RefCounted
## Cloud saves: the rules for keeping the save on this computer and its copy in
## the cloud (in her account, on the server) in step. Online does the talking to
## the server; this only decides what to do, so the rules can be checked without
## one (tests/test_cloud_save.gd).
##
## Every computer (every browser) keeps notes (Online.cloud_file): for each
## account that has played here, where the two saves stood the last time they
## were the same. That's a fingerprint of the save on this computer (a short
## code made from its text, which changes whenever the save does) and the cloud
## copy's version (the server gives the copy a new version each time it's
## written). Comparing now with then says which one has changed since:
## - neither: they're the same (SAME)
## - only this computer's: it goes up to the cloud (UPLOAD)
## - only the cloud's (she played on another computer): it comes down (DOWNLOAD)
## - both: only she can say which to keep (ASK)
## A save here that's another account's, already safe in their cloud, makes way
## for hers: hers comes down (DOWNLOAD), or, if she has none, it's cleared from
## this computer (CLEAR), so she starts afresh. And a save from before cloud
## saves, or from playing offline, goes up if she has nothing in the cloud yet.

## What the cloud is like, as the phone's little cloud shows it.
enum State {
	OFF, ## playing offline (no account): no cloud
	UP_TO_DATE, ## her save on this computer is the one in the cloud
	WAITING, ## her save hasn't gone up yet (no internet, say): it tries again
	DIFFERS, ## the cloud has another game (from another computer): she chooses next time she starts
}

## What to do with the two saves (see next_step()).
enum Step { SAME, UPLOAD, DOWNLOAD, CLEAR, ASK }


## Notes with nothing in them yet: no account has played on this computer.
## "accounts" has each account's {"save": fingerprint, "cloud": version} from
## when they were last the same, and "last" the account that last played here.
static func empty_notes() -> Dictionary:
	return {"accounts": {}, "last": ""}


## A short code made from a save's text that changes whenever the save does
## ("" when there's no save): its SHA-256, 64 letters and numbers.
static func fingerprint(text: String) -> String:
	return "" if text == "" else text.sha256_text()


## What to do for the account `me`, given the save on this computer
## (`local_text`, "" if there isn't one), the version of the copy in the cloud
## (`cloud_version`, "" if there isn't one), and this computer's `notes`.
static func next_step(local_text: String, cloud_version: String, notes: Dictionary, me: String) -> Step:
	var here := fingerprint(local_text)
	var accounts: Dictionary = notes.get("accounts", {})
	var mine: Dictionary = accounts.get(me, {})
	if here == "":
		return Step.DOWNLOAD if cloud_version != "" else Step.SAME
	if mine.get("save", "") == here:
		# This computer's save hasn't changed since it was last the cloud's.
		if cloud_version == "":
			return Step.UPLOAD # the cloud's copy has gone: put it back
		return Step.SAME if mine.get("cloud", "") == cloud_version else Step.DOWNLOAD
	for account: String in accounts:
		var theirs: Dictionary = accounts[account]
		if account != me and theirs.get("save", "") == here:
			# Another account's game, already safe in their cloud: it makes way for hers.
			return Step.DOWNLOAD if cloud_version != "" else Step.CLEAR
	# This computer's save has play in it that the cloud hasn't seen.
	if cloud_version == "":
		return Step.UPLOAD
	if mine.get("cloud", "") == cloud_version and notes.get("last", "") == me:
		return Step.UPLOAD # she played on from her own game, here, and the cloud hasn't changed since
	return Step.ASK
