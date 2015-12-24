#!/usr/bin/env bash
#
# This main bootstrap file loads all bash functions and modules

# ------------------------------------------------------------------------------
# Export global variables
# ------------------------------------------------------------------------------
#export FOO=bar

# ------------------------------------------------------------------------------
# Source functions first
# ------------------------------------------------------------------------------
for file in $DOTFILES_HOME/functions/*; do source $file; done

# ------------------------------------------------------------------------------
# Source files that end with `.autoload.first.sh`
# ------------------------------------------------------------------------------
find_and_source "*.autoload.first.sh" $DOTFILES_HOME

# ------------------------------------------------------------------------------
# Source files that end with `.autoload.sh`
# ------------------------------------------------------------------------------
find_and_source "*.autoload.sh" $DOTFILES_HOME

# ------------------------------------------------------------------------------
# Source files that end with `.autoload.last.sh`
# ------------------------------------------------------------------------------
find_and_source "*.autoload.last.sh" $DOTFILES_HOME
