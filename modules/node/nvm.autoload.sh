#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# init nvm
# ------------------------------------------------------------------------------

export NVM_DIR="$HOME/.nvm"
export NVM_INIT="/usr/local/opt/nvm/nvm.sh"

[ -s $NVM_INIT ] && . $NVM_INIT
