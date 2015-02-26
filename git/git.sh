#!/usr/bin/env bash

# Only run if git command is found
if command_exists rbenv ; then
  source $DOTFILES_HOME/git/completion/git-completion.bash.sh
fi
