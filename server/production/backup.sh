#!/bin/bash
# Backs up Gold Coast's database (every account) into /opt/gold-coast/backups,
# and keeps the last 14 days. setup.sh runs it every night at 03:30 (cron);
# you can also run it by hand on the droplet: bash /opt/gold-coast/backup.sh
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p backups
chmod 700 backups
file="backups/nakama-$(date +%Y-%m-%d).sql.gz"
docker compose exec -T database pg_dump -U postgres nakama | gzip > "$file.part"
mv "$file.part" "$file"
find backups -name 'nakama-*.sql.gz' -mtime +14 -delete
echo "Backed up to /opt/gold-coast/$file"
