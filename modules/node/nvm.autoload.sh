#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# init nvm
# ------------------------------------------------------------------------------

# Export ~/.nvm
test -d "$HOME/.nvm" &&
  export NVM_DIR="$HOME/.nvm"

# Source the nvm init script
export NVM_INIT="/usr/local/opt/nvm/nvm.sh"
[ -s $NVM_INIT ] && . $NVM_INIT
