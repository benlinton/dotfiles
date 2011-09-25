#!/usr/bin/env bash

# Compgen shortcuts
# You can use the bash(1) built-in compgen
#
# compgen -c will list all the commands you could run.
# compgen -a will list all the aliases you could run.
# compgen -b will list all the built-ins you could run.
# compgen -k will list all the keywords you could run.
# compgen -A function will list all the functions you could run.
# compgen -A function -abck will list all the above in one go.
# compgen -ac | grep searchstr
alias aliases='compgen -a'

# http://stackoverflow.com/questions/948008/linux-command-to-list-all-available-commands-and-aliases
# If you want to process the lines rather than just output them, replace echo with the processing.
# for i in `echo $PATH | sed "s/:/ /g"`
# do
#   echo $i
# done
# Otherwise:
alias path-list='echo $PATH | tr -s ":" "\n"'

# ---------------------------------------------------------------------------
# ls
# ---------------------------------------------------------------------------

# Colorized, special characters (after dirs, executables, symlinks, etc.)
alias ls='ls -GF'

# Show all, colorized, special characters
alias la='ls -aGF'

# Listed, show all, human readable sizes, colorized, special characters
alias ll='ls -lahGF'

# ---------------------------------------------------------------------------
#
# ---------------------------------------------------------------------------

# Output filesize of everything in pwd
alias du_pwd='du -hd 1'

# ---------------------------------------------------------------------------
# TODO: add a workspace command:
#   workspace               # calls -> wordspace help
#   workspace help
#   workspace [path]        # calls -> workspace cd [path]
#   workspace save          # calls -> workspace save pwd
#   workspace save [alias]  #
#   workspace load          # loads last save
#   workspace load [alias]  # loads
#   workspace list
#   alias ws='workspace'
# ---------------------------------------------------------------------------

# Add a 'ws' command if the ~/Workspace directory exists; TODO: move this into a set
# of commands
[ -d ~/Workspace ] &&
alias ws='cd ~/Workspace'

#
#
# TODO: move this into a modular file or command set
alias dotfiles='cd ~/.dotfiles'

