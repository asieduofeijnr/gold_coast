# Credits

Third-party work in Gold Coast, and its license. Everything else (the code,
the models, the colors) is made for the game, in this repository.

## Code

- **Nakama client for Godot** by Heroic Labs: talks to the game's Nakama
  server (accounts, cloud saves, multiplayer).
  - Source: https://github.com/heroiclabs/nakama-godot (commit `6dc7b39`, 2026-09-22)
  - In: `gold-coast/addons/com.heroiclabs.nakama/` (the Nakama part only; the
    Satori and C# parts are left out)
  - License: Apache License 2.0 (`gold-coast/addons/com.heroiclabs.nakama/LICENSE`)

## Server

- **Nakama** by Heroic Labs, the game server (Apache License 2.0), and
  **PostgreSQL**, its database (PostgreSQL License). Both run from their
  official Docker images (`server/docker-compose.yml`); neither is copied into
  this repository.
