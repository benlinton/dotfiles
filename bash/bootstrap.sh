##
# Core
# First bash file loaded.
##

# ---------------------------------------------------------------------------
# Export core constants
# TODO: don't assume dotfiles resides in $HOME; auto-detect
# ---------------------------------------------------------------------------
export DOTFILES_HOME=$HOME/.dotfiles

# ---------------------------------------------------------------------------
# Load functions
# TODO: automatically load BASH_HOME/functions
# ---------------------------------------------------------------------------
source $BASH_HOME/functions/command_exists.sh
source $BASH_HOME/functions/parse_git_branch.sh

# ---------------------------------------------------------------------------
# Load bash modules
# TODO: automatically load .sh files
# ---------------------------------------------------------------------------
source $BASH_HOME/aliases.sh
source $BASH_HOME/history.sh
source $BASH_HOME/path.sh
source $BASH_HOME/prompt.sh

# ---------------------------------------------------------------------------
# Load OS modules
# TODO: automatically load .sh files depending on OS
# ---------------------------------------------------------------------------

# TODO: check for Darwin
source $DOTFILES_HOME/osx/aliases.sh

# ---------------------------------------------------------------------------
# Load other modules
# TODO: automatically load .sh files
# ---------------------------------------------------------------------------

# Git
source $DOTFILES_HOME/git/git.sh

# Ruby
source $DOTFILES_HOME/ruby/rbenv.sh
source $DOTFILES_HOME/ruby/aliases.sh
source $DOTFILES_HOME/ruby/heroku.sh

# Node
source $DOTFILES_HOME/node/nvm.sh

