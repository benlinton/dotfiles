#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Prompt
#
# TODO: write a script that makes it easy to switch prompts:
#
# prompt-manager
# prompt-manager help
# prompt-manager list
# prompt-manager load
# prompt-manager save
# prompt-manager remove
# prompt-manager set
# prompt-manager colors
# prompt-manager set-colors
#
# #alias prompt='prompt-manager'
#
# Components of a prompt:
#   * default:              user@server [~](master) $
#   * base:                 $
#   * short-path:           [~]
#   * full-path:            [/path/to/home]
#   * user/server:          user@server
#   * git branch:           (master)
#   * colors:               default|...|none
#
# Day 2, add support for flags
#   * --with-full-path
#   * --with-short-path
#   * --with-current-branch
#   * --without-brackets
# Add popular presets.
# Support saving and reloading favorites?
# Track history?
# Set should set colors as well; list should list colors
# ------------------------------------------------------------------------------

if [ $(id -u) -eq 0 ];
then # root
  export PS1="\[\e[1;31m\]\u@\h \W\[\033[32m\]\$(parse_git_branch)\[\033[00m\] $ "
else # normal
  export PS1="\u@\h \W\[\033[32m\]\$(parse_git_branch)\[\033[00m\] $ "
fi
