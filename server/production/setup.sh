#!/bin/bash
# Sets up Gold Coast's server on a new Ubuntu 24.04 droplet, and starts it.
# deploy.sh copies this folder to /opt/gold-coast/ on the droplet and runs it
# there, as root, with the server's name and the game's key:
#   bash /opt/gold-coast/setup.sh api.yourgame.com <the game's server key>
# It's safe to run again: it only adds what's missing, then (re)starts the server.
set -euo pipefail
cd "$(dirname "$0")"
DOMAIN="${1:?usage: setup.sh <server name> <server key>}"
SERVER_KEY="${2:?usage: setup.sh <server name> <server key>}"

echo "== Docker, the firewall, and automatic security updates"
export DEBIAN_FRONTEND=noninteractive
# A new droplet often runs its own updates first: wait for them (up to 10 minutes).
apt() { apt-get -o DPkg::Lock::Timeout=600 -yq "$@"; }
apt update >/dev/null
apt install docker.io docker-compose-v2 ufw unattended-upgrades >/dev/null
systemctl enable --now docker
# Only SSH (to manage it) and the web (80 and 443) are open. The console and the
# database aren't published to the internet at all (see docker-compose.yml).
ufw allow OpenSSH >/dev/null
ufw allow 80/tcp >/dev/null
ufw allow 443/tcp >/dev/null
ufw --force enable >/dev/null
systemctl enable --now unattended-upgrades >/dev/null 2>&1 || true

echo "== SSH: keys only, no passwords"
if [ -s /root/.ssh/authorized_keys ]; then
	printf '%s\n' "# Gold Coast: log in with SSH keys only." "PasswordAuthentication no" \
		"KbdInteractiveAuthentication no" "PermitRootLogin prohibit-password" > /etc/ssh/sshd_config.d/90-gold-coast.conf
	systemctl reload ssh 2>/dev/null || systemctl reload sshd 2>/dev/null || true
else
	echo "   (skipped: this droplet has no SSH key for root, so passwords stay on to keep you from being locked out)"
fi

echo "== Passwords and keys (made here, kept in /opt/gold-coast/.env)"
NEW=""
if [ ! -f .env ]; then
	key() { openssl rand -hex 24; }
	NEW=1
	(umask 077; cat > .env <<EOF
# Gold Coast's server: its passwords and keys, made by setup.sh on this droplet.
# Never copy this file into git or a chat.
DOMAIN=$DOMAIN
SERVER_KEY=$SERVER_KEY
POSTGRES_PASSWORD=$(key)
SESSION_KEY=$(key)
REFRESH_KEY=$(key)
HTTP_KEY=$(key)
CONSOLE_USERNAME=admin
CONSOLE_PASSWORD=$(key)
CONSOLE_SIGNING_KEY=$(key)
EOF
	)
fi
# The name and the game's key come from the game (gold-coast/scripts/live_server.gd).
sed -i "s/^DOMAIN=.*/DOMAIN=$DOMAIN/; s/^SERVER_KEY=.*/SERVER_KEY=$SERVER_KEY/" .env
chmod 600 .env

echo "== Nightly backups of the database (kept 14 days, in /opt/gold-coast/backups)"
chmod +x backup.sh
echo "30 3 * * * root /opt/gold-coast/backup.sh" > /etc/cron.d/gold-coast-backup

echo "== Starting the server"
docker compose pull -q
docker compose up -d --remove-orphans
# Nakama reads its modules (the game's rules) when it starts, so a new copy needs a restart.
docker compose restart nakama >/dev/null

echo
echo "Gold Coast's server is up. In a minute or two (once its certificate"
echo "arrives) it answers at https://$DOMAIN"
if [ -n "$NEW" ]; then
	echo
	echo "Its console's password is below. Keep it in your password manager, and"
	echo "don't paste it anywhere else. (It's also in /opt/gold-coast/.env.)"
	echo "   console username: admin"
	echo "   console password: $(sed -n 's/^CONSOLE_PASSWORD=//p' .env)"
fi
