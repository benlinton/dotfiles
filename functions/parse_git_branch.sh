#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Function: parse_git_branch()
# Requires: git, sed
#
# Returns current git branch
# ------------------------------------------------------------------------------
parse_git_branch() {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}
