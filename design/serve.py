"""Opens the Coaster Life design board, and saves its changes into coaster_life.json.

Run it from the kayayo folder:

    python3 design/serve.py

It opens http://127.0.0.1:8070/ in your browser. The board loads coaster_life.json
from this folder, and every change you make there is saved back into it. Every few
minutes the last version is kept in design/backups/ (the newest 30), in case you want
something back. Only this computer can reach it. Press Ctrl+C to stop.

Only Python's standard library: nothing to install.
"""

import argparse
import datetime
import http.server
import json
import os
import pathlib
import sys
import threading
import webbrowser

HERE = pathlib.Path(__file__).resolve().parent
DATA = HERE / "coaster_life.json"
BACKUPS = HERE / "backups"
KEEP = 30                       # backups kept
BACKUP_EVERY = 5 * 60           # seconds between backups, at most
MOST_BYTES = 5 * 1024 * 1024    # the design is about 0.2 MB; anything this big isn't it
HOST = "127.0.0.1"


def save(body: bytes) -> str:
    """Checks that `body` is the design and writes it into coaster_life.json.

    Keeps a copy of the old file in backups/ first, if the newest backup is a few
    minutes old. Returns the time it saved, like "14:05:09".
    """
    text = body.decode("utf-8")
    data = json.loads(text)
    if not isinstance(data, dict) or not isinstance(data.get("opportunities"), list):
        raise ValueError("That isn't the Coaster Life design (it has no opportunities list).")
    now = datetime.datetime.now()
    if DATA.exists():
        BACKUPS.mkdir(exist_ok=True)
        old = sorted(BACKUPS.glob("coaster_life-*.json"))
        if not old or now.timestamp() - old[-1].stat().st_mtime > BACKUP_EVERY:
            (BACKUPS / f"coaster_life-{now:%Y%m%d-%H%M%S}.json").write_bytes(DATA.read_bytes())
        for extra in sorted(BACKUPS.glob("coaster_life-*.json"))[:-KEEP]:
            extra.unlink()
    part = DATA.with_name(DATA.name + ".part")
    part.write_text(text if text.endswith("\n") else text + "\n", encoding="utf-8")
    os.replace(part, DATA)  # all at once, so the file is never half-written
    return f"{now:%H:%M:%S}"


class Board(http.server.SimpleHTTPRequestHandler):
    """Serves this folder to this computer's browser, and takes saves of coaster_life.json."""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(HERE), **kwargs)

    def end_headers(self):
        self.send_header("Cache-Control", "no-store")   # always the newest file
        self.send_header("X-Coaster-Save", "1")         # tells the board it can save here
        super().end_headers()

    def do_GET(self):
        if not self._trusted():
            return
        if self.path in ("/", "/index.html"):
            self.send_response(302)
            self.send_header("Location", "/coaster_life.html")
            self.end_headers()
            return
        super().do_GET()

    def do_HEAD(self):
        if self._trusted():
            super().do_HEAD()

    def do_PUT(self):
        if not self._trusted():
            return
        if self.path.split("?")[0] != "/coaster_life.json":
            self.send_error(404, "Only coaster_life.json can be saved")
            return
        length = int(self.headers.get("Content-Length") or 0)
        if not 0 < length <= MOST_BYTES:
            self.send_error(413, "That's not the size of the design")
            return
        try:
            when = save(self.rfile.read(length))
        except (UnicodeDecodeError, ValueError) as error:  # bad JSON is a ValueError too
            self._reply(400, {"ok": False, "error": str(error)})
            return
        self._reply(200, {"ok": True, "savedAt": when})
        print(f"{when}  saved coaster_life.json")

    def _trusted(self) -> bool:
        """Only pages from this server, on this computer, can use it (not other websites)."""
        port = self.server.server_address[1]
        allowed = {f"127.0.0.1:{port}", f"localhost:{port}"}
        origin = self.headers.get("Origin")
        if self.headers.get("Host") not in allowed or (origin and origin.split("://", 1)[-1] not in allowed):
            self.send_error(403, "Only this computer's browser can use the board")
            return False
        return True

    def _reply(self, code: int, payload: dict):
        body = json.dumps(payload).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_request(self, code="-", size="-"):
        if isinstance(code, int) and code >= 400:  # quiet, apart from problems
            super().log_request(code, size)


def main():
    parser = argparse.ArgumentParser(description="Open the Coaster Life design board.")
    parser.add_argument("--port", type=int, default=8070, help="the first port to try (default 8070)")
    parser.add_argument("--no-browser", action="store_true", help="don't open the browser")
    args = parser.parse_args()
    server = None
    for port in range(args.port, args.port + 10):
        try:
            server = http.server.ThreadingHTTPServer((HOST, port), Board)
            break
        except OSError:
            continue  # busy: try the next one
    if server is None:
        sys.exit(f"Ports {args.port} to {args.port + 9} are all busy.")
    url = f"http://{HOST}:{server.server_address[1]}/coaster_life.html"
    print(f"The Coaster Life board is at {url}")
    print(f"Changes save into {DATA}")
    print("Press Ctrl+C to stop.")
    if not args.no_browser:
        threading.Timer(0.6, webbrowser.open, [url]).start()
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopped.")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
