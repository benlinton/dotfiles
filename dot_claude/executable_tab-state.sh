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

[ -n "$KITTY_WINDOW_ID" ] || exit 0

dir=/tmp/claude-kitty-state
file="$dir/$KITTY_WINDOW_ID"
mkdir -p "$dir" 2>/dev/null

case "$1" in
    idle) rm -f "$file" 2>/dev/null ;;
    working | waiting) printf '%s' "$1" >"$file" 2>/dev/null ;;
esac

exit 0
