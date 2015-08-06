#!/usr/bin/env bash

# ---------------------------------------------------------------------------
# Add rbenv to front of PATH
# ---------------------------------------------------------------------------

# Add rbenv to PATH for user home
test -d "$HOME/.rbenv/bin" &&
  export PATH="$HOME/.rbenv/bin:$PATH"

# Add rbenv to PATH for system wide install
test -d "/usr/local/rbenv/bin" &&
  export PATH="/usr/local/rbenv/bin:$PATH"

# ---------------------------------------------------------------------------
# rbenv init
# ---------------------------------------------------------------------------

# Initialize rbenv if found on PATH
if command_exists rbenv ; then
  eval "$(rbenv init -)"
fi

