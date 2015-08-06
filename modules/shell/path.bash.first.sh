#!/usr/bin/env bash

# ---------------------------------------------------------------------------
# PATH - Insert on Front
# ---------------------------------------------------------------------------

# Put local sbin on front; override system sbin
export PATH="/usr/local/sbin:$PATH"

# Put local bin on front; override system bin & local sbin
export PATH="/usr/local/bin:$PATH"

# Put $HOME/bin on front (if exists)
test -d "$HOME/bin" &&
export PATH="$HOME/bin:$PATH"

# Put $DOTFILES_HOME/bin on front
export PATH="$DOTFILES_HOME/bin:$PATH"

# ---------------------------------------------------------------------------
# PATH - Append to End
# ---------------------------------------------------------------------------

# Put ~/Applications on rear (for OS X if exists)
test -d "$HOME/Applications" &&
export PATH="$PATH:$HOME/Applications"

# ---------------------------------------------------------------------------
# MANPATH
# ---------------------------------------------------------------------------

# Put local man on front of MANPATH
export MANPATH="/usr/local/man:$MANPATH"
