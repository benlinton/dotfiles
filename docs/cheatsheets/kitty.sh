# KITTY CHEATSHEET
# Modifier: kitty_mod = ctrl+shift (default). On macOS many actions also have a cmd shortcut.
# [*] marks bindings customized in this dotfiles config (dot_config/kitty/kitty.conf).

## CLI — LAUNCH
kitty                                 # Open a new kitty window
kitty <cmd> [args]                    # Run a command instead of the shell
kitty --hold <cmd>                    # Keep window open after cmd exits
kitty --title <name>                  # Set the OS window title
kitty -o font_size=18                 # Override a config option at launch
kitty --session <file>                # Start from a session file (layout/tabs/windows)
kitty --single-instance               # Reuse a running kitty instance (alias: -1)
kitty +runpy '<python>'               # Run Python in kitty's embedded interpreter

## CLI — KITTENS (built-in tools)
kitten ssh <host>                     # SSH that auto-installs kitty terminfo on remote [aliased to `ssh`]
kitten icat <image>                   # Display an image inline in the terminal
kitten diff <a> <b>                   # Side-by-side diff with image/syntax support
kitten clipboard <file>               # Copy file/stdin to the system clipboard
kitten hyperlinked-grep <pattern>     # ripgrep with clickable file:// hyperlinks
kitten choose-fonts                   # Interactive font picker UI
kitten themes                         # Browse and apply color themes
kitten @ <command>                    # Remote-control a running kitty (see below)
kitten --help                         # List all available kittens

## REMOTE CONTROL (allow_remote_control yes [*])
kitty @ ls                            # JSON tree of all OS windows / tabs / windows
kitty @ launch --type=tab <cmd>       # Open a new tab running cmd
kitty @ launch --type=os-window       # Open a new OS window
kitty @ send-text "hello\n"           # Type text into the active window
kitty @ set-tab-title <title>         # Rename the current tab
kitty @ focus-tab --match title:foo   # Focus a tab matching a query
kitty @ close-window                  # Close the active window
kitty @ set-font-size 18              # Change font size live (0 = reset)
kitty @ get-text                      # Dump the screen/scrollback text
kitty @ set-colors -a background=#222 # Change colors on the fly

## TABS
cmd+t                                 # New tab in the current working directory [*]
ctrl+shift+t                          # New tab (default)
cmd+w                                 # Close tab
cmd+opt+right                         # Next tab [*]
cmd+opt+left                          # Previous tab [*]
ctrl+shift+right / ctrl+shift+left    # Next / previous tab (default)
cmd+1 .. cmd+9                        # Jump to tab N (macOS)
ctrl+shift+. / ctrl+shift+,           # Move tab forward / backward
ctrl+shift+alt+t                      # Set tab title

## WINDOWS (splits within a tab)
cmd+enter                             # New window (split)
ctrl+shift+enter                      # New window (default)
cmd+shift+d                           # Close window
ctrl+shift+] / ctrl+shift+[           # Focus next / previous window
ctrl+shift+f / ctrl+shift+b           # Move window forward / backward
ctrl+shift+` (backtick)               # Move window to top (first position)
ctrl+shift+1 .. 0                     # Focus the Nth window
ctrl+shift+l                          # Cycle to the next layout
ctrl+shift+r                          # Start resizing the active window

## SCROLLING & SCROLLBACK
cmd+up / cmd+down                      # Scroll line up / down (macOS)
ctrl+shift+up / ctrl+shift+down        # Scroll line up / down (default)
cmd+page_up / cmd+page_down            # Scroll page up / down
ctrl+shift+home / ctrl+shift+end       # Scroll to top / bottom
ctrl+shift+h                           # Browse full scrollback in the pager (less)
ctrl+shift+g                           # Show last command output in pager (needs shell integration)

## CLIPBOARD
cmd+c / cmd+v                          # Copy / paste (macOS)
ctrl+shift+c / ctrl+shift+v            # Copy / paste (default)
# Middle-click paste is disabled in this config (mouse_map middle -> no-op) [*]

## FONT SIZE
cmd+plus / cmd+minus                   # Increase / decrease font size (macOS)
ctrl+shift+= / ctrl+shift+-            # Increase / decrease (default)
cmd+0                                  # Reset font size
ctrl+shift+backspace                   # Reset font size (default)

## HINTS (keyboard-driven selection)
ctrl+shift+e                           # Open a URL on screen in the browser
ctrl+shift+p>f                         # Pick a file path and type it
ctrl+shift+p>l                         # Pick a line and type it
ctrl+shift+p>w                         # Pick a word and type it
ctrl+shift+p>h                         # Pick a git hash
kitten hints --type path --program -   # Custom hints invocation (many --type options)

## MOUSE
ctrl+shift+click                       # Open the link under the cursor (works even when a program
                                       #   like tmux/vim/less has grabbed the mouse; also skips the
                                       #   plain-click delay). Plain click opens links only when ungrabbed.

## MISC
ctrl+shift+f2                          # Edit kitty.conf in $EDITOR (chezmoi-managed — see note)
ctrl+cmd+, (macOS) / ctrl+shift+f5     # Reload config without restart
ctrl+shift+escape                      # Open the kitty command shell (kitty @ without prefix)
ctrl+shift+u                           # Unicode character input
ctrl+cmd+f (macOS) / ctrl+shift+f11    # Toggle fullscreen
ctrl+shift+f6                          # Toggle maximized
ctrl+shift+delete                      # Clear terminal and scrollback
ctrl+shift+f1                          # Open kitty documentation

# NOTE: kitty.conf is managed by chezmoi. Editing the live ~/.config/kitty/kitty.conf
# causes drift — edit the source in ~/.local/share/chezmoi and run `chezmoi apply`.
# See docs/managed-dotfiles-policy.md.
