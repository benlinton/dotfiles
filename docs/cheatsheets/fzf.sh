# FZF CHEATSHEET
# General-purpose fuzzy finder. Shell integration is enabled in dot_shellrc
# (Ctrl-R, Ctrl-T, Alt-C) and powers zoxide's interactive `zi` picker.

## KEY BINDINGS (shell integration)
# Ctrl-R                        # fuzzy-search command history, then edit the line
# Ctrl-T                        # insert file/dir path(s) under the cursor
# Alt-C                         # cd into a selected subdirectory
# (macOS: Alt = Option; enable "Use Option as Meta key" in the terminal)

## PICKER CONTROLS (inside the fzf UI)
# Enter                         # accept the highlighted item
# Tab / Shift-Tab               # mark/unmark for multi-select (-m mode)
# Ctrl-J / Ctrl-K               # move down / up (also arrow keys)
# Ctrl-/                        # toggle the preview window
# Esc / Ctrl-C                  # cancel without selecting

## SEARCH SYNTAX (query field)
# foo bar                       # AND: items matching fuzzy "foo" and "bar"
# 'foo                          # exact-match items containing "foo"
# ^foo                          # prefix-anchored match
# foo$                          # suffix-anchored match
# !foo                          # negate: exclude items matching "foo"
# foo | bar                     # OR within a term

## COMMAND LINE
fzf                             # filter stdin lines, print the selection
fzf -m                          # allow multiple selections (Tab to mark)
fzf -q foo                      # start with an initial query
fzf --preview 'cat {}'          # show a preview of the highlighted item ({} = line)
vim "$(fzf)"                    # open the picked file in vim

## PIPELINES
kill -9 "$(ps -ef | fzf | awk '{print $2}')"   # pick a process to kill
git switch "$(git branch | fzf)"               # pick a branch to switch to
cd "$(find . -type d | fzf)"                    # pick a directory to cd into

## CONFIG (environment variables, set in dot_shellrc if desired)
# FZF_DEFAULT_COMMAND           # command used to feed fzf when reading from a dir
# FZF_DEFAULT_OPTS              # default flags, e.g. --height 40% --layout=reverse
# FZF_CTRL_T_COMMAND            # source command for the Ctrl-T widget
# FZF_ALT_C_COMMAND             # source command for the Alt-C widget
