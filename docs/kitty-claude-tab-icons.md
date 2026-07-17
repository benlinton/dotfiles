# Kitty tab status icons for Claude Code

Each kitty tab shows a small coloured glyph reflecting the Claude Code session
running in it:

| Glyph | Colour | Meaning | Written by |
|---|---|---|---|
| `▸` | green (`0x00CC66`) | working | `UserPromptSubmit`, `PreToolUse`, `PostToolUse` |
| `⏸` | amber (`0xFFB000`) | waiting / needs you | `Stop`, `Notification` |
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
   Observed during **repeated subagent shell-outs** (Task tool), *not* an
   interrupt. A `waiting` was written and the expected `working` refresh didn't
   overwrite it.

Open questions the docs don't answer (hence the instrumentation):

- Does `Stop` fire on ESC interrupt? (Empirically: seems **not**.)
- Do a subagent's `PreToolUse`/`PostToolUse` fire the **parent window's** hooks?
- Does the statusline command tick while the session is **idle**, or only while
  working? (Early data: fires irregularly on activity, 0.5–12s gaps *while
  working* — so any freshness-based reconciler needs a generous threshold.)

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

What to look for: a final `wrote=working` with the statusline going silent right
after (→ stuck-working / interrupt), or a `wrote=waiting` from `Notification`
landing mid-work with no following `working` (→ stuck-waiting).

## Fix direction (not yet implemented)

Likely a combination of: (a) an interrupt-safe way to mark `waiting` when a turn
ends for any reason, and (b) a freshness/ground-truth reconciler in `tab_bar.py`
so a stale `working` downgrades instead of sticking. Nail the open questions from
the logs *first* — the two failure modes have different causes and a speculative
single fix risks trading one wrong-direction error for another.
