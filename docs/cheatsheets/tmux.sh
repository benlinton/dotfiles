# TMUX CHEATSHEET
# Prefix key: Ctrl-b (default)

# SESSIONS
tmux                                  # Start new session
tmux new -s <name>                    # Start named session
tmux ls                               # List sessions
tmux attach                           # Attach to last session
tmux attach -t <name>                 # Attach to named session
tmux kill-session -t <name>           # Kill named session

# PREFIX COMMANDS — SESSIONS
Prefix $                              # Rename current session
Prefix d                              # Detach from session
Prefix s                              # List and switch sessions (interactive)
Prefix (                              # Previous session
Prefix )                              # Next session

# WINDOWS
Prefix c                              # Create new window
Prefix ,                              # Rename current window
Prefix &                              # Kill current window
Prefix w                              # List and switch windows (interactive)
Prefix n                              # Next window
Prefix p                              # Previous window
Prefix 0-9                            # Switch to window by number
Prefix .                              # Move window (enter new index)

# PANES
Prefix "                              # Split horizontally (top/bottom)
Prefix %                              # Split vertically (left/right)
Prefix x                              # Kill current pane
Prefix o                              # Cycle through panes
Prefix ;                              # Toggle to last active pane
Prefix h/j/k/l                        # Move between panes (if bound)
Prefix arrow                          # Move between panes
Prefix Ctrl-arrow                     # Resize pane (hold prefix, tap arrow)
Prefix z                              # Toggle pane zoom (fullscreen)
Prefix {                              # Swap pane with previous
Prefix }                              # Swap pane with next
Prefix !                              # Break pane into new window

# COPY MODE
Prefix [                              # Enter copy mode
q                                     # Exit copy mode
/                                     # Search forward
?                                     # Search backward
Space                                 # Start selection (vi mode)
Enter                                 # Copy selection and exit
Prefix ]                              # Paste

# CONFIG
Prefix :                              # Open command prompt
Prefix r                              # Reload config (if bound: bind r source-file ~/.tmux.conf)

# Useful ~/.tmux.conf settings
set -g mouse on                       # Enable mouse support
set -g base-index 1                   # Number windows from 1
set -g history-limit 10000            # Scrollback buffer size
set -g mode-keys vi                   # Vi keys in copy mode
set -g status-right '%H:%M %d-%b-%y'  # Clock in status bar

# MISC
Prefix ?                              # Show all keybindings
Prefix t                              # Show clock
Prefix i                              # Show pane info
tmux show-options -g                  # Show all global options
tmux list-keys                        # List all keybindings
