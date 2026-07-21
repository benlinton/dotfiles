# IMPORTANT: Managed by chezmoi - do not edit this copy directly.
# Source: ~/.local/share/chezmoi - edit there, then run `chezmoi apply`.
# If you edit this file directly, notify the user and reconcile with the chezmoi source.
#
# Custom kitty tab bar: prepends a coloured state glyph, then hands the tab off
# to kitty's built-in powerline renderer (so tab_bar_style powerline +
# tab_powerline_style and the tab_title_template are all preserved, and the
# window title itself is left untouched).
#
# State is written per-window by Claude Code hooks (see ~/.claude/tab-state.sh,
# wired up in ~/.claude/settings.json) into /tmp/claude-kitty-state/<window-id>:
#
#   UserPromptSubmit/PreToolUse/PostToolUse -> "working" -> ▸ green
#   Notification (permission prompt)        -> "waiting" -> ⏸ amber (needs your input)
#   Stop                                    -> "stop"    -> ⏹ blue  (turn ended, your move)
#   SessionStart/End -> file removed        -> idle      -> no glyph
#
# Tweak the glyphs/colours/precedence in STATES below.

import os
import time

from kitty.fast_data_types import add_timer
from kitty.tab_bar import as_rgb, draw_tab_with_powerline, get_boss

STATE_DIR = "/tmp/claude-kitty-state"

# kitty imports this module once at startup, so this stamps ~this kitty
# session's start. kitty reuses window ids (1, 2, 3, ...) on every relaunch,
# but the per-window state files in STATE_DIR survive across restarts (only
# cleared on reboot), so a new window can inherit a previous session's stale
# "waiting". Any state file older than this stamp is from a prior kitty
# session and must be ignored/removed.
_SESSION_START = time.time()


def _sweep_stale():
    # Drop state files left over from previous kitty sessions (see above).
    try:
        names = os.listdir(STATE_DIR)
    except OSError:
        return
    for name in names:
        path = os.path.join(STATE_DIR, name)
        try:
            if os.stat(path).st_mtime < _SESSION_START:
                os.remove(path)
        except OSError:
            pass

# checked in order -> first match wins. For a split tab with multiple panes:
# waiting (needs you) > working (running) > stop (turn ended, your move).
# (state name, glyph, 0xRRGGBB)
STATES = (
    ("waiting", "⏸", 0xFFB000),  # amber — needs your input (permission prompt)
    ("working", "▸", 0x00CC66),  # green — running
    ("stop",    "⏹", 0x3B82F6),  # blue  — turn ended, your move
)


def _states_for_tab(tab_id):
    boss = get_boss()
    if boss is None:
        return set()
    try:
        tab = boss.tab_for_id(tab_id)
    except Exception:
        return set()
    if tab is None:
        return set()
    # collect this tab's window ids (defensive across kitty versions)
    wids = []
    try:
        wids = [w.id for w in tab]
    except TypeError:
        active = getattr(tab, "active_window", None)
        if active is not None:
            wids.append(active.id)
        wids += list(getattr(tab, "all_window_ids_except_active_window", []) or [])
    except Exception:
        return set()
    found = set()
    for wid in wids:
        try:
            with open(os.path.join(STATE_DIR, str(wid))) as fh:
                found.add(fh.read().strip())
        except OSError:
            pass
    return found


# --- periodic redraw so glyphs track their state files -------------------
# kitty only repaints the tab bar on its own triggers (focus change, keypress,
# focused-window output, bell, title change). A state file changing on disk is
# NOT one of them, so a tab that transitions working<->waiting while you are not
# interacting with it (a background tab, or the tab that just finished a turn)
# keeps showing its previous glyph until some unrelated event happens to repaint
# -- the "wrong icon that heals when you touch it" bug. We fix it by polling the
# state dir on a timer and marking the tab bar dirty ONLY when a state file
# actually changed. When nothing changed (idle sessions, or no Claude open at
# all) a tick is just one listdir + a few stats and forces no repaint, so the
# cost is negligible; kitty also skips the repaint entirely for occluded windows.
_REDRAW_INTERVAL = 2.0  # seconds; how quickly a glyph catches up to its file
_last_sig = None


def _state_signature():
    # Cheap fingerprint of the state dir: (window-id, mtime_ns) per state file.
    # Only numeric names are state files -- skip debug.log/statusline.log/.debug
    # so diagnostic logging churn never triggers a redraw.
    try:
        names = os.listdir(STATE_DIR)
    except OSError:
        return ()
    sig = []
    for name in names:
        if not name.isdigit():
            continue
        try:
            sig.append((name, os.stat(os.path.join(STATE_DIR, name)).st_mtime_ns))
        except OSError:
            pass
    sig.sort()
    return tuple(sig)


def _poll_redraw(timer_id):
    global _last_sig
    sig = _state_signature()
    if sig == _last_sig:
        return  # nothing changed -> no repaint (the common, near-free case)
    _last_sig = sig
    boss = get_boss()
    if boss is None:
        return
    try:
        managers = list(boss.os_window_map.values())
    except Exception:
        tm = getattr(boss, "active_tab_manager", None)
        managers = [tm] if tm is not None else []
    for tm in managers:
        try:
            tm.mark_tab_bar_dirty()
        except Exception:
            pass


try:
    # seed the signature with the state at import so the first tick only fires on
    # a real change (the import-time render already reflects the current files).
    _last_sig = _state_signature()
    add_timer(_poll_redraw, _REDRAW_INTERVAL, True)
except Exception:
    # if the timer can't be registered, fall back to kitty's native repaint
    # triggers -- degraded (laggy glyphs) but never broken.
    pass


def draw_tab(
    draw_data, screen, tab, before, max_tab_length, index, is_last, extra_data
):
    try:
        if index == 0:
            # once per tab-bar redraw, before any tab reads its state
            _sweep_stale()
        states = _states_for_tab(tab.tab_id)
        for name, glyph, color in STATES:
            if name in states:
                orig_fg = screen.cursor.fg
                screen.draw(" ")
                screen.cursor.fg = as_rgb(color)
                screen.draw(glyph)
                screen.cursor.fg = orig_fg
                # no trailing space: the tab_title_template's own leading
                # space (" {index}: ...") keeps the glyph off the title
                break
    except Exception:
        # never let a rendering error break the whole tab bar
        pass
    return draw_tab_with_powerline(
        draw_data, screen, tab, before, max_tab_length, index, is_last, extra_data
    )
