#!/bin/bash
# Checks Gold Coast's server on the internet, from your Mac:
#   bash server/production/check.sh
# HTTPS works and Nakama answers; plain http:// goes to https://; and the
# console, Nakama's own port, and the database can't be reached from outside.
set -uo pipefail
cd "$(dirname "$0")/../.."
DOMAIN=$(sed -n 's/^const HOST := "\(.*\)"$/\1/p' gold-coast/scripts/live_server.gd)
if [ -z "$DOMAIN" ]; then
	echo "There's no server name in gold-coast/scripts/live_server.gd yet."
	exit 1
fi
failed=0
check() { # check "what it checks" command...
	local what="$1"
	shift
	if "$@" >/dev/null 2>&1; then echo "ok    $what"; else echo "FAIL  $what"; failed=1; fi
}
closed() { ! nc -z -G 5 "$DOMAIN" "$1"; } # nothing answers on that port (-G: give up after 5 s)
redirects() { curl -sI --max-time 10 "http://$DOMAIN/" | grep -qi '^location: https://'; }
check "https://$DOMAIN answers, with a valid certificate" curl -fsS --max-time 10 "https://$DOMAIN/healthcheck"
check "plain http:// sends you on to https://" redirects
check "the console (port 7351) is closed to the internet" closed 7351
check "Nakama's own port (7350) is closed to the internet" closed 7350
check "the database (port 5432) is closed to the internet" closed 5432
if [ "$failed" = 0 ]; then
	echo "All good: the game on itch.io can use https://$DOMAIN."
else
	echo "Something's wrong (see FAIL above). A new server needs a minute or two for its certificate,"
	echo "and the name needs to point at the droplet: dig +short $DOMAIN should show its IP address."
fi
exit "$failed"
