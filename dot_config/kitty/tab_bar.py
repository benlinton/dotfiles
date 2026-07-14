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
#   UserPromptSubmit -> "working"  -> ▸ green
#   Stop/Notification -> "waiting" -> ⏸ amber (takes precedence: it needs you)
#   SessionStart/End -> file removed -> idle -> no glyph
#
# Tweak the glyphs/colours/precedence in STATES below.

import os

from kitty.tab_bar import as_rgb, draw_tab_with_powerline, get_boss

STATE_DIR = "/tmp/claude-kitty-state"

# checked in order -> first match wins (waiting outranks working)
# (state name, glyph, 0xRRGGBB)
STATES = (
    ("waiting", "⏸", 0xFFB000),  # amber
    ("working", "▸", 0x00CC66),  # green
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


def draw_tab(
    draw_data, screen, tab, before, max_tab_length, index, is_last, extra_data
):
    try:
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
