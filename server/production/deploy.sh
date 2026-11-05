#!/bin/bash
# Puts Gold Coast's server on a DigitalOcean droplet, or updates it there.
# Run it on your Mac, in Terminal, from the kayayo folder:
#   bash server/production/deploy.sh root@<the droplet's IP address>
# It copies server/production and server/modules to /opt/gold-coast/ on the
# droplet, then runs setup.sh there, which sets it up (the first time) and
# (re)starts it. Run it again whenever server/modules changes.
# The server's name and the game's key come from gold-coast/scripts/live_server.gd.
set -euo pipefail
cd "$(dirname "$0")/../.."
TARGET="${1:?Say which droplet: bash server/production/deploy.sh root@<IP address>}"
LIVE=gold-coast/scripts/live_server.gd
DOMAIN=$(sed -n 's/^const HOST := "\(.*\)"$/\1/p' "$LIVE")
KEY=$(sed -n 's/^const SERVER_KEY := "\(.*\)"$/\1/p' "$LIVE")
if [ -z "$DOMAIN" ]; then
	echo "First put the server's name in $LIVE, like: const HOST := \"api.yourgame.com\""
	exit 1
fi
if [ -z "$KEY" ] || [ "$KEY" = "defaultkey" ]; then
	echo "$LIVE needs its own SERVER_KEY (not Nakama's default)."
	exit 1
fi

echo "== Copying the server to $TARGET:/opt/gold-coast"
ssh "$TARGET" 'mkdir -p /opt/gold-coast/modules'
# The game's rules (an exact copy: anything deleted here goes there too)...
rsync -rlt --delete server/modules/ "$TARGET:/opt/gold-coast/modules/"
# ...and the server's own files. Its .env (passwords) and backups stay as they are.
rsync -rlt --exclude README.md server/production/ "$TARGET:/opt/gold-coast/"

echo "== Setting it up and starting it, on the droplet"
ssh "$TARGET" "bash /opt/gold-coast/setup.sh '$DOMAIN' '$KEY'"

echo
echo "Next: bash server/production/check.sh (it checks the server from here)."
