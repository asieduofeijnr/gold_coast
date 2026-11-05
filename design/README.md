# Coaster Life: the design board

Gold Coast's life design: what a Coaster needs, what they can become, and the world they live it in.

- `coaster_life.json`: the design. Everything is here: needs, traits, routines, the life map's steps
  (`opportunities`), achievements, places, actions, people, events, the story, the tutorial's lessons
  (`tutorial`), and the build plan (`jobs`).
- `coaster_life.html`: the board that shows it, and changes it.
- `serve.py`: opens the board, and saves its changes into `coaster_life.json`.

## Opening it

In Terminal, in the `kayayo` folder:

```
python3 design/serve.py
```

The board opens in your browser, and every change saves straight into `coaster_life.json`.
Older versions are kept in `design/backups/` (not in git). Ctrl+C stops it.

Without `serve.py`: open `coaster_life.html` in Chrome and press *Open coaster_life.json…*.
Chrome then saves into that file. Other browsers download the file when you press Save.

## Changing it

- **Add a branch:** on *Life progression*, click a step and press *＋ Add a step after this*, or press *＋ New branch*.
- **Remove a branch:** click a step and press *Remove…*: just that step, or the steps that only come after it too.
- **Anything else:** move over a card and press ✎, or edit `coaster_life.json` in any text editor.
  The board's *Data* tab says what each part of the file is.
- The ⚠ chip at the top checks the links: every link points somewhere, nothing loops, and money alone never opens a step.

## Building it

The *Build plan* tab breaks the design into Jobs 19 to 41, one session each, each ending with a test.
Click a job's status to move it on (to do, doing now, done), and use ↑ and ↓ to change the order.
Its chips show what the job brings into the game; every step, need and place shows its job too.
The *Tutorial* tab has the lessons the game will teach as you play. Each one comes in with its job.
