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
# Usage: tab-state.sh working|waiting|idle|notify
#
#   working|waiting|idle -> write the state verbatim (waiting) / remove file (idle)
#   notify               -> a Claude "Notification" hook fired; resolve it (see below)
#
# Why `notify` is special: Claude fires the Notification hook for TWO unrelated
# things -- (1) it needs you (a permission prompt), and (2) the input box has been
# idle ~60s. Case (2) also fires *while a long tool or subagent Task is running*
# (the input box is idle the whole time), which would wrongly flip the tab to
# `waiting` for the tool's entire duration -- it only self-heals at the next
# PostToolUse. So a notify only counts as `waiting` when it's a permission prompt;
# the idle nudge is dropped. Normal turn-end `waiting` comes from the Stop hook,
# which is unaffected. Permission vs idle is told apart by the `message` field.
#
# DIAGNOSTIC LOGGING (temporary): if the flag file $dir/.debug exists, every
# invocation appends a line to $dir/debug.log capturing the hi-res time, pid,
# window id, the state we resolved to, and the real hook event name / tool /
# subagent id / notification message parsed from the hook JSON on stdin. This
# lets us build an exact per-window timeline to diagnose intermittent wrong
# icons. Turn it off by removing the flag file (no chezmoi apply needed):
# rm /tmp/claude-kitty-state/.debug

[ -n "$KITTY_WINDOW_ID" ] || exit 0

dir=/tmp/claude-kitty-state
file="$dir/$KITTY_WINDOW_ID"
mkdir -p "$dir" 2>/dev/null

state=$1

# Read the hook JSON from stdin once, but only when we actually need it (a notify
# decision, or debug logging) -- the hot working/waiting path skips it. Hooks
# always pipe JSON + EOF; guard against blocking if run by hand from a terminal.
payload=""
if { [ "$state" = notify ] || [ -f "$dir/.debug" ]; } && [ ! -t 0 ]; then
    payload=$(cat 2>/dev/null)
fi
field() {
    printf '%s' "$payload" | sed -n \
        "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -n1
}

# Resolve a Notification into a concrete state (see header). Default to `waiting`
# for anything we can't classify so we never *lose* a genuine "needs you" signal;
# only the recognisably-idle nudge is dropped.
msg=""
if [ "$state" = notify ]; then
    msg=$(field message)
    case "$msg" in
        *[Pp]ermission*) state=waiting ;;  # permission prompt -> needs you
        *[Ii]nput*)      state=ignore  ;;  # "...waiting for your input" idle nudge
        *)               state=waiting ;;  # unknown -> keep the signal, don't drop
    esac
fi

# --- diagnostic logging (opt-in via flag file) ---------------------------
if [ -f "$dir/.debug" ]; then
    event=$(field hook_event_name)
    tool=$(field tool_name)
    aid=$(field agent_id)
    atype=$(field agent_type)
    ts=$(perl -MTime::HiRes -e 'printf "%.3f", Time::HiRes::time()' 2>/dev/null) \
        || ts=$(date +%s)
    printf '%s pid=%s wid=%s wrote=%s event=%s tool=%s agent=%s/%s msg=%s\n' \
        "$ts" "$$" "$KITTY_WINDOW_ID" "${state:-?}" "${event:-?}" \
        "${tool:-}" "${atype:-}" "${aid:-}" "${msg:-}" >> "$dir/debug.log" 2>/dev/null
fi
# -------------------------------------------------------------------------

case "$state" in
    idle) rm -f "$file" 2>/dev/null ;;
    working | waiting) printf '%s' "$state" >"$file" 2>/dev/null ;;
    # ignore -> leave the current state file untouched
esac

exit 0
