# Kitty tab status icons for Claude Code

Each kitty tab shows a small coloured glyph reflecting the Claude Code session
running in it:

| Glyph | Colour | Meaning | Written by |
|---|---|---|---|
| `▸` | green (`0x00CC66`) | working | `UserPromptSubmit`, `PreToolUse`, `PostToolUse` |
| `⏸` | amber (`0xFFB000`) | waiting / needs you | `Stop`, `Notification` (permission prompts only — see below) |
| *(none)* | — | idle | `SessionStart`, `SessionEnd` (file removed) |

This doc is the pickup point for the **known "wrong icon" bug** (see below) and
the diagnostic instrumentation currently wired up to chase it. For the mechanics,
read the live files — they carry their own header comments:

- `dot_config/kitty/tab_bar.py` → `~/.config/kitty/tab_bar.py` (renderer)
- `dot_claude/executable_tab-state.sh` → `~/.claude/tab-state.sh` (state writer)
- `dot_claude/settings.json` → `~/.claude/settings.json` (hook → event wiring)

## How it works

State is a **single last-writer-wins file per kitty window** at
`/tmp/claude-kitty-state/<KITTY_WINDOW_ID>`, containing the literal word
`working` or `waiting` (absent = idle). Claude Code hooks run `tab-state.sh
<state>`; the script writes the file. `tab_bar.py` is imported by kitty once at
startup and, on every tab-bar redraw, reads the state file(s) for the windows in
each tab and prepends the glyph before handing off to kitty's powerline renderer.

Design notes worth knowing:

- **Why a file, not an escape sequence:** Claude Code runs hooks without a
  controlling tty, so writing to `/dev/tty` fails. A file needs no kitty remote
  control (which is disabled by default — see commit `9fb38ac`).
- **Precedence:** `waiting` outranks `working` when a tab has multiple windows
  (a split that needs you wins). See `STATES` in `tab_bar.py`.
- **Stale-session sweep:** kitty reuses window ids (1, 2, 3…) across restarts,
  but state files survive until reboot, so `tab_bar.py` records its import time
  (`_SESSION_START`) and `_sweep_stale()` drops any state file older than that on
  the first tab of each redraw. This is *cross-session* hygiene only — it does
  not fix the in-session bug below.

## Gotchas / hard-won facts (learned 2026-07-17)

Things that cost real debugging time — read these before re-deriving them:

- **`working` is stamped only at tool *boundaries*, not during execution.**
  `PreToolUse` writes `working` when a tool starts, `PostToolUse` when it ends —
  nothing in between. So during a long tool the state file's mtime looks *stale*
  even though the session is genuinely working. Do **not** treat a stale
  `working` mtime as "stopped."
- **No continuous "working" heartbeat exists.** The statusline is *not* one — it
  fires only at activity boundaries (zero beats during a 3-min silent `Bash`, and
  silent through a 26-min idle). Statusline *silence* therefore means nothing on
  its own; it looks identical during a long tool and during a true idle. This
  rules out any freshness/TTL reconciler in `tab_bar.py`.
- **Multiple concurrent Claude sessions share one `debug.log`,** each writing its
  own `wid=`. When reading logs, **always filter to the window you care about**
  (`grep 'wid=<ID> '`) — mixing two sessions' timelines is the fastest way to
  misdiagnose. (This exact trap first looked like an id mismatch; it was two
  sessions.)
- **`KITTY_WINDOW_ID` is captured at process launch and inherited by children,**
  so a session's `claude` process, its hooks, and its `Bash` sub-shells all agree
  on the id, and it matches the `w.id` the renderer iterates. Verify with:
  ```sh
  # id in the live claude process's environment (walk `ppid` to find the pid)
  ps eww -o command= -p <claude-pid> | tr ' ' '\n' | grep '^KITTY_WINDOW_ID='
  ```
- **Window ids are monotonic within a kitty run and never recycled** — closing
  tabs does not free an id for reuse (observed sequence across opens/closes: 2, 4,
  36, 39). To re-test if ever in doubt:
  ```sh
  grep SessionStart /tmp/claude-kitty-state/debug.log | grep -oE 'wid=[0-9]+'
  # strictly increasing, no repeats => a closed tab can never feed a live window
  # another session's file. (Cross-*restart* reuse is handled by _sweep_stale.)
  ```

## Known bug: intermittent wrong icon

Reported 2026-07-17. Icons are *usually* right but occasionally stick. Because
the state file is last-writer-wins with **no ordering or ground-truth check**, a
missed or out-of-order write persists until the next event happens to correct it
(it self-heals on the next turn). There are **two opposite failure modes**:

1. **Stuck `working`** (▸ play shown while the session is actually stopped). The
   corrective `waiting` write never landed. Prime suspect: **interrupts** — ESC
   aborts a turn and the `Stop` hook does not reliably fire, so nothing writes
   `waiting`.
2. **Stuck `waiting`** (⏸ pause shown while the session is actually running).
   **Root cause found (2026-07-17) and fixed** — see below. Was mis-attributed to
   subagents; the real trigger is `Notification`'s idle nudge firing mid-tool.

Open questions the docs don't answer (hence the instrumentation):

- Does `Stop` fire on ESC interrupt? (Empirically: seems **not** — this is the
  remaining cause of stuck `working` #1, still unfixed.)
- Do a subagent's `PreToolUse`/`PostToolUse` fire the **parent window's** hooks?
- ~~Does the statusline tick as a heartbeat while working?~~ **Answered: no.** Log
  analysis showed **zero** statusline beats during a 3-min silent `Bash` and none
  during a 26-min idle. It fires only at activity boundaries. `working` is
  likewise stamped only at tool *start*/*end*, so there is **no continuous
  working signal** — which rules out any freshness/TTL reconciler (a TTL short
  enough to catch an interrupt would blank the icon mid-long-tool).

### Root cause of stuck `waiting` (fixed 2026-07-17)

`Notification` fires for **two unrelated** things: (1) a permission prompt
(genuinely needs you), and (2) a ~60s idle-input nudge. The idle nudge **also
fires while a long tool or subagent `Task` is running** (the input box is idle
the whole time), so the old unconditional `Notification → waiting` flipped the
tab to ⏸ for the tool's entire duration, healing only at the next `PostToolUse`.
Confirmed in the log: a `Notification` 7s into a 3-min `Bash` held ⏸ from
10:54:24 until 10:57:19.

**Fix:** `Notification` now calls `tab-state.sh notify`, which inspects the hook
`message` and writes `waiting` only for permission prompts; the idle nudge is
dropped (unknown messages still default to `waiting` so no genuine "needs you" is
lost). Normal turn-end ⏸ is unaffected — it comes from the `Stop` hook. The
message-matching is deliberately loose (`*permission*` / `*input*`); the debug
log now records `msg=` so the patterns can be verified/tuned against real
notifications.

**Not** the cause: window-id reuse on tab close. Within one kitty run, window ids
are monotonic and never recycled (ids observed: 2, 4, 36, 39 — strictly
increasing), and each window's hooks/renderer agree on its id. Closing a tab can
orphan a state file, but no live window ever reads it. Cross-*restart* reuse is
handled by `_sweep_stale()`.

## Diagnostic instrumentation (temporary)

Opt-in logging, gated by a flag file so it costs nothing when off:

```sh
# Enable
mkdir -p /tmp/claude-kitty-state && touch /tmp/claude-kitty-state/.debug
# Disable (no chezmoi apply needed)
rm /tmp/claude-kitty-state/.debug
```

When the flag exists:

- `tab-state.sh` appends to `/tmp/claude-kitty-state/debug.log` — hi-res
  timestamp, pid, window id, the state written, and the real `hook_event_name` /
  `tool_name` / `agent_type`+`agent_id` parsed from the hook JSON on stdin.
- `statusline.sh` appends to `/tmp/claude-kitty-state/statusline.log` — hi-res
  timestamp + window id, i.e. statusline invocation cadence.

Both logging blocks are clearly fenced in their scripts and are **meant to be
removed** once the bug is fixed. If you're reading this after the fix shipped and
those blocks are still there, delete them (and this section).

### Analysing a report

When an icon is wrong, note the window and what it showed vs reality, then
reconstruct the merged per-window timeline (state writes interleaved with
statusline beats) and compare against the current on-disk state. Ad-hoc:

```sh
# merged timeline for one window, oldest first
{ sed 's/$/ KIND=state/' /tmp/claude-kitty-state/debug.log
  sed 's/$/ event=beat KIND=beat/' /tmp/claude-kitty-state/statusline.log; } \
  | sort -n | grep 'wid=<ID>'
# what the renderer currently sees
cat /tmp/claude-kitty-state/<ID>
```

What to look for: the **last state write** for the window vs. what the tab
actually showed. A final `wrote=working` with no following `Stop` → stuck-working
(interrupt — see #1). A `wrote=waiting event=Notification` landing between a
`PreToolUse` and its matching `PostToolUse` → the mid-tool false-⏸ that was fixed
(should no longer occur; if it does, check the `msg=` field — an idle nudge
should now resolve to `ignore`, only `*permission*` writes `waiting`).

Note: statusline *silence* is **not** a signal (see Gotchas) — it is silent
during long tools and during idle alike. Read the state writes, not the beats.

## Fix direction

- **Stuck `waiting` (#2): DONE** — `Notification` no longer writes `waiting` for
  its idle nudge (see "Root cause of stuck `waiting`" above).
- **Stuck `working` (#1): still open.** On ESC interrupt no hook fires, so the
  `working` file is never corrected; it self-heals only when the next turn ends
  (`Stop`). A freshness/TTL reconciler is **not** viable — there's no continuous
  working heartbeat (see the answered open question), so a TTL can't tell a
  long-running tool from an aborted turn. Needs a real interrupt-time signal
  (does Claude Code expose one?) before it's worth touching.
