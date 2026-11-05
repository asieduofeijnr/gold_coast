# Gold Coast's server on the internet (DigitalOcean)

The same server as on the Mac (Nakama and PostgreSQL), on a rented computer
(a DigitalOcean "droplet"), so the game on itch.io can use accounts and the
shared town. Caddy sits in front of it for HTTPS: a page on itch.io is secure
(https://), and a secure page can only talk to a secure server.

## What's here

- `docker-compose.yml`: Caddy, Nakama, and the database, as they run on the droplet.
- `Caddyfile`: HTTPS for the server's name, passed on to Nakama.
- `setup.sh`: runs on the droplet. It installs Docker, a firewall, and automatic
  security updates, makes the server's passwords and keys there (in
  `/opt/gold-coast/.env`, never in git), sets up nightly backups, and starts it.
- `backup.sh`: backs the database up (setup.sh runs it every night at 03:30).
- `deploy.sh`: runs on the Mac. It copies the server to the droplet and runs setup.sh.
- `check.sh`: runs on the Mac. It checks the server from the outside.

The game finds the server through `gold-coast/scripts/live_server.gd`: its
`HOST` (the server's name) and `SERVER_KEY` (the key every copy of the game
sends). deploy.sh reads both from there, so the game and the server always
match.

## Putting it online, the first time

1. **A domain name.** Buy one (Namecheap, Porkbun, or Cloudflare: about $10–15
   a year). The server will be `api.` that name, like `api.yourgame.com`.
2. **An SSH key** (how you log in to the droplet, without a password). If
   `ls ~/.ssh/id_ed25519.pub` shows nothing, make one: `ssh-keygen -t ed25519`
   (press Enter at each question). `cat ~/.ssh/id_ed25519.pub` shows the key to
   give DigitalOcean.
3. **The droplet.** On DigitalOcean: Create > Droplets.
   - Region: London (the closest to Ghana)
   - Image: Ubuntu 24.04 (LTS)
   - Size: Basic, Regular, 2 GB memory (about $12 a month)
   - Authentication: SSH key (paste the key from step 2)
   - Backups: weekly (about 20% more), as well as the nightly database backups
   Note its IP address when it's made.
4. **Point the name at it.** Where you bought the domain: a DNS record of type
   `A`, name `api`, value the droplet's IP address. After a few minutes,
   `dig +short api.yourgame.com` shows that address.
5. **Tell the game.** In `gold-coast/scripts/live_server.gd`:
   `const HOST := "api.yourgame.com"`.
6. **Put the server on it.** In Terminal, from the kayayo folder:
   ```
   bash server/production/deploy.sh root@<the droplet's IP address>
   ```
   The first time, ssh asks whether to trust the droplet: type `yes`. At the
   end it shows the console's password once: keep it in your password manager.
7. **Check it:** `bash server/production/check.sh`. Every line should say ok.
8. **Put the game on itch.io:** commit the change to `live_server.gd` and merge
   it into main. The pipeline builds the game and uploads it, and from then on
   the itch.io version shows the account card and the shared town.

## Looking after it

- **Changed the game's rules** (`server/modules/`)? Run deploy.sh again.
- **What it's doing:** `ssh root@<IP> 'cd /opt/gold-coast && docker compose logs -f nakama'`
- **The console** (accounts, the town): open a tunnel from the Mac, and leave it open:
  `ssh -L 7351:127.0.0.1:7351 root@<IP>`. Then open http://127.0.0.1:7351
  (username `admin`, and the password from step 6). The console is never open
  to the internet itself.
- **Backups** are in `/opt/gold-coast/backups/` on the droplet (the last 14
  nights). To keep one on the Mac:
  `scp root@<IP>:/opt/gold-coast/backups/nakama-<date>.sql.gz .`
- **Restoring a backup** replaces every account with the backup's, so try it on
  a spare droplet first. On the droplet, in `/opt/gold-coast`:
  `docker compose stop nakama`, then
  `docker compose exec -T database dropdb -U postgres nakama`,
  `docker compose exec -T database createdb -U postgres nakama`,
  `gunzip -c backups/nakama-<date>.sql.gz | docker compose exec -T database psql -U postgres nakama`,
  and `docker compose start nakama`.
- **Updates:** Ubuntu installs its security updates by itself. To move to a
  newer Nakama, change its version in both docker-compose.yml files, try it on
  the Mac, then run deploy.sh.

## Before the itch.io page goes public

- Emails to confirm an account or reset a password: Nakama doesn't send email,
  so the server needs an email service (like Postmark or Resend).
  DigitalOcean blocks ordinary email from new droplets.
- Cloud saves (the rest of Job 18): until then, each browser keeps its own save.
- A lawyer's look at the five pages (`gold-coast/scripts/legal.gd`). The
  privacy page should say what's kept (name, email, date of birth) and where
  (London), and whether Gold Coast must register with Ghana's Data Protection
  Commission.
