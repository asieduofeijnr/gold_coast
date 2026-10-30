#!/bin/sh
# The web build's check, in a real web browser. It builds the "Web check" version
# of the game (it starts with tests/web_check.gd instead of the title screen),
# serves it on this computer, opens it in Chrome with no window (headless), and
# waits for the result in Chrome's console. It prints what was checked, and exits
# with 0 if everything passed:
#   sh tests/web_check.sh
# It needs Godot's Web export templates, and Google Chrome. It can't run in a
# sandbox that stops programs from opening network connections on this computer
# (like the AI's, unless you allow this script in it): then run
# tests/serve_web.sh yourself, and open the web check's address in any browser.

cd "$(dirname "$0")/.." || exit 1
GODOT=${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}
CHROME=${CHROME:-"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"}
PYTHON=${PYTHON:-/Users/nanaasiedu-ofeijnr/env/apple_base/bin/python}
OUT=build/web_check
PORT=8061

mkdir -p "$OUT"
if ! "$GODOT" --headless --path . --export-debug "Web check" "$OUT/index.html" > "$OUT/export.log" 2>&1; then
	echo "The Web check build failed:"
	grep -E "ERROR|error" "$OUT/export.log"
	exit 1
fi

"$PYTHON" -I -m http.server "$PORT" --bind 127.0.0.1 --directory "$OUT" > /dev/null 2>&1 &
SERVER=$!
# A fresh browser profile, so nothing from before is in its storage. Chrome's
# own temporary files go in it too (on a Mac, Chrome reads MAC_CHROMIUM_TMPDIR,
# not TMPDIR). The other settings stop it fetching updates and asking for the
# Mac's keychain, which a test browser doesn't need.
PROFILE=$(mktemp -d /tmp/gold_coast_web_check.XXXXXX)
sleep 1
MAC_CHROMIUM_TMPDIR="$PROFILE" "$CHROME" --headless=new --user-data-dir="$PROFILE" \
	--no-first-run --no-default-browser-check --disable-background-networking \
	--disable-component-update --disable-sync --use-mock-keychain \
	--enable-logging=stderr --v=0 --window-size=1152,648 \
	"http://127.0.0.1:$PORT/index.html" 2> "$PROFILE/console.log" &
BROWSER=$!

# Wait up to two minutes for the result.
for i in $(seq 120); do
	if grep -q "WEB CHECK PASS\|WEB CHECK FAIL" "$PROFILE/console.log"; then
		break
	fi
	sleep 1
done
kill "$BROWSER" "$SERVER" 2> /dev/null
grep -o "WEB CHECK[^\"]*" "$PROFILE/console.log" | sed 's/\\n$//'
if grep -q "WEB CHECK PASS" "$PROFILE/console.log"; then
	sleep 1 # Chrome finishes closing
	rm -rf "$PROFILE"
	exit 0
fi
echo "No pass. Errors in the browser's console:"
grep -iE "error|exception" "$PROFILE/console.log" | head -20
echo "(All of it is in $PROFILE/console.log)"
exit 1
