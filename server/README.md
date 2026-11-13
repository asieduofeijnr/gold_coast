# Gold Coast's server

Gold Coast's online side (accounts, the shared town, and cloud saves) runs on
[Nakama](https://heroiclabs.com/nakama/), an open-source game server, with a
PostgreSQL database for everyone's accounts and saves.

## On this computer

1. Open **Docker Desktop** and wait until it says it's running.
2. In Terminal, from the repo's folder (`kayayo/`):
   ```
   docker compose -f server/docker-compose.yml up -d
   ```
   The first time, it downloads Nakama and PostgreSQL (a few hundred MB).
3. The game (in the Godot editor, or the web version from
   `sh gold-coast/tests/serve_web.sh`) now finds the server at
   `127.0.0.1:7350`.
4. To see the accounts, open Nakama's console in a browser:
   http://127.0.0.1:7351 (username `admin`, password `password`). Each
   player's cloud save is under Storage: collection `saves`, key `game`.
5. To check cloud saves against it, from `gold-coast/`:
   `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . res://tests/cloud_check.tscn`
   (it makes two accounts of its own, `cloud_check_a` and `cloud_check_b`).

To stop it: `docker compose -f server/docker-compose.yml down` (the accounts
stay). To see what it's doing: `docker compose -f server/docker-compose.yml logs -f nakama`.

## What's here

- `docker-compose.yml`: the two programs (Nakama 3.22.0 and PostgreSQL 16), and
  their settings. To move to a newer Nakama, change its version there.
- `modules/gold_coast.lua`: Gold Coast's rules on the server. It checks new
  accounts (a username, a name, 18 or older, agreeing to the terms) and keeps
  the name, date of birth, and agreement with the account. Its "town"
  function finds the shared town for the game (or starts it).
- `modules/town.lua`: the shared town, a match everyone logged in joins. It
  passes each player's position on to everyone else, and keeps Gold Coast's
  clock (a day lasts 24 real minutes), so everyone has the same time of day.
- Cloud saves need no code here: the game keeps each player's save in
  Nakama's own storage (one object per account, that only its owner can read
  or change), and Nakama's versions stop one computer's save writing over
  another's (see `gold-coast/scripts/cloud_save.gd`).

Nakama reads `modules/` when it starts. After changing them:
`docker compose -f server/docker-compose.yml restart nakama`.

## Online

For players on itch.io, the server has to be on the internet with HTTPS (a
secure page can only talk to a secure server): a small rented server, a
domain name, and its own passwords and keys instead of the ones here.
`production/` has all of it, ready for a DigitalOcean droplet: see
`production/README.md`. The game finds that server through
`gold-coast/scripts/live_server.gd`.
