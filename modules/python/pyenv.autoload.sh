#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# pyenv init
# ------------------------------------------------------------------------------

# Add pyenv to PATH for user home
test -d "$HOME/.pyenv" &&
  export PYENV_ROOT="$HOME/.pyenv"

# Initialize pyenv shims if command found
if command_exists pyenv ; then
  export PATH="$(pyenv root)/shims:$PATH"
fi
