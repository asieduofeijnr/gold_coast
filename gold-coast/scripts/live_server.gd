class_name LiveServer
## Where Gold Coast's online server is, once it's on the internet: Nakama on a
## DigitalOcean droplet (see server/production/README.md). The game on itch.io
## uses it. The editor, the tests, and the web build served on this computer
## keep using the server on this computer (server/docker-compose.yml).
##
## server/production/deploy.sh reads both lines below, so keep their shape.

## The server's name, like "api.yourgame.com". Empty means there's no online
## server yet, so the game on itch.io plays offline.
const HOST := ""
## The key every copy of the game sends with its requests. It isn't a secret
## (it travels inside the game), but it isn't Nakama's default, either.
const SERVER_KEY := "gc_50d93c514c991c4ec17e185863b21c7d"
