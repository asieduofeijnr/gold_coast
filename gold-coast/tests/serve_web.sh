#!/bin/sh
# Builds the web versions of the game and serves them on this computer, to try
# them in a browser:
#   http://127.0.0.1:8060/web/        the game, as it goes on itch.io
#   http://127.0.0.1:8060/web_check/  the web check: it shows its results on
#                                     the page (WEB CHECK PASS, and the frame rate)
# Run it from a Terminal window, and leave it running while you try them:
#   sh tests/serve_web.sh
# Press Ctrl+C to stop it. It needs Godot's Web export templates.

cd "$(dirname "$0")/.." || exit 1
GODOT=${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}
PYTHON=${PYTHON:-/Users/nanaasiedu-ofeijnr/env/apple_base/bin/python}
PORT=8060

echo "Building the game and the web check..."
mkdir -p build/web build/web_check
if ! "$GODOT" --headless --path . --export-release "Web" build/web/index.html > build/web/export.log 2>&1; then
	echo "The game's build failed:"
	grep -E "ERROR|error" build/web/export.log
	exit 1
fi
if ! "$GODOT" --headless --path . --export-debug "Web check" build/web_check/index.html > build/web_check/export.log 2>&1; then
	echo "The web check's build failed:"
	grep -E "ERROR|error" build/web_check/export.log
	exit 1
fi

echo
echo "The game:      http://127.0.0.1:$PORT/web/"
echo "The web check: http://127.0.0.1:$PORT/web_check/"
echo "Press Ctrl+C to stop."
exec "$PYTHON" -I -m http.server "$PORT" --bind 127.0.0.1 --directory build
