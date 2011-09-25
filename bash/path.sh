#!/usr/bin/env bash

# ---------------------------------------------------------------------------
# PATH - Insert on Front
# ---------------------------------------------------------------------------

# Put local sbin on front; override system sbin
PATH="/usr/local/sbin:$PATH"

# Put local bin on front; override system bin & local sbin
PATH="/usr/local/bin:$PATH"

# Put $HOME/bin on front (if exists)
test -d "$HOME/bin" &&
PATH="$HOME/bin:$PATH"

# Put $DOTFILES_HOME/bin on front
PATH="$DOTFILES_HOME/bin:$PATH"

# ---------------------------------------------------------------------------
# PATH - Append to End
# ---------------------------------------------------------------------------

# Put ~/Applications on rear (for OS X if exists)
test -d "$HOME/Applications" &&
PATH="$PATH:$HOME/Applications"

# ---------------------------------------------------------------------------
# MANPATH
# ---------------------------------------------------------------------------

# Put local man on front of MANPATH
MANPATH="/usr/local/man:$MANPATH"
