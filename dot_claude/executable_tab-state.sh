#!/bin/sh
# IMPORTANT: Managed by chezmoi - do not edit this copy directly.
# Source: ~/.local/share/chezmoi - edit there, then run `chezmoi apply`.
# If you edit this file directly, notify the user and reconcile with the chezmoi source.
#
# Record this Claude session's state for the kitty tab bar to render
# (read by ~/.config/kitty/tab_bar.py). We write a small per-window file
# instead of emitting a terminal escape, because Claude Code runs hooks
# without a controlling tty (writing to /dev/tty fails), and this needs no
# kitty remote control. Always exits 0 so a hook can never surface an error.
#
# Usage: tab-state.sh working|waiting|idle
#
# DIAGNOSTIC LOGGING (temporary): if the flag file $dir/.debug exists, every
# invocation appends a line to $dir/debug.log capturing the hi-res time, pid,
# window id, the state we were told to write, and the real hook event name /
# tool / subagent id parsed from the hook JSON on stdin. This lets us build an
# exact per-window timeline to diagnose intermittent wrong icons. Turn it off
# by removing the flag file (no chezmoi apply needed): rm /tmp/claude-kitty-state/.debug

[ -n "$KITTY_WINDOW_ID" ] || exit 0

dir=/tmp/claude-kitty-state
file="$dir/$KITTY_WINDOW_ID"
mkdir -p "$dir" 2>/dev/null

state=$1

# --- diagnostic logging (opt-in via flag file) ---------------------------
if [ -f "$dir/.debug" ]; then
    # Capture the hook JSON from stdin (hooks always pipe JSON + EOF; guard
    # against blocking if run by hand from a terminal).
    payload=""
    if [ ! -t 0 ]; then
        payload=$(cat 2>/dev/null)
    fi
    field() {
        printf '%s' "$payload" | sed -n \
            "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -n1
    }
    event=$(field hook_event_name)
    tool=$(field tool_name)
    aid=$(field agent_id)
    atype=$(field agent_type)
    ts=$(perl -MTime::HiRes -e 'printf "%.3f", Time::HiRes::time()' 2>/dev/null) \
        || ts=$(date +%s)
    printf '%s pid=%s wid=%s wrote=%s event=%s tool=%s agent=%s/%s\n' \
        "$ts" "$$" "$KITTY_WINDOW_ID" "${state:-?}" "${event:-?}" \
        "${tool:-}" "${atype:-}" "${aid:-}" >> "$dir/debug.log" 2>/dev/null
fi
# -------------------------------------------------------------------------

case "$state" in
    idle) rm -f "$file" 2>/dev/null ;;
    working | waiting) printf '%s' "$state" >"$file" 2>/dev/null ;;
esac

exit 0
