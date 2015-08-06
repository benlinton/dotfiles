#!/usr/bin/env bash
#
# ------------------------------------------------------------------------------
# First bash file loaded.
# ------------------------------------------------------------------------------
#
# TODO: support loading filenames with spaces
# TODO: don't assume dotfiles resides in $HOME; auto-detect

# ------------------------------------------------------------------------------
# Export core constants
# ------------------------------------------------------------------------------
export DOTFILES_HOME=$HOME/.dotfiles

# ------------------------------------------------------------------------------
# Load files that end with `.bash.first.sh`
# ------------------------------------------------------------------------------
for module in $(find $DOTFILES_HOME -type f -iname '*.bash.first.sh' -print) ; do
  source "$module"
done

# ------------------------------------------------------------------------------
# Load files that end with `.bash.sh`
# ------------------------------------------------------------------------------
for module in `find $DOTFILES_HOME -type f -iname '*.bash.sh' -print` ; do
  source "$module"
done

# ------------------------------------------------------------------------------
# Load files that end with `.bash.last.sh`
# ------------------------------------------------------------------------------
for module in `find $DOTFILES_HOME -type f -iname '*.bash.last.sh' -print` ; do
  source "$module"
done
