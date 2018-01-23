#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# init nvm
# ------------------------------------------------------------------------------

# Set path to optional nvm init script
NVM_INIT="/usr/local/opt/nvm/nvm.sh"
  
# If init script exists, create $NVM_DIR and source the init script
[ -s $NVM_INIT ] && 
  export NVM_DIR="$HOME/.nvm" &&
  mkdir -p $NVM_DIR &&
  . $NVM_INIT
