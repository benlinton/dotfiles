#!/usr/bin/env bash

# Only run if git command is found
if command_exists git ; then
  source $DOTFILES_HOME/modules/git/git-completion.sh
fi
