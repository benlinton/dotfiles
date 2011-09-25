#!/usr/bin/env bash

# ---------------------------------------------------------------------------
# History
# ---------------------------------------------------------------------------

# For HISTCONTROL:
#   ignorespace flag tells bash to ignore commands that start with spaces
#   ignoredups flag tells bash to ignore duplicate successive entries
#   ignoreboth flag is equivalent to ignorespace:ignoredups
export HISTCONTROL=ignoreboth

# Set maximum history size
export HISTFILESIZE=10000
export HISTSIZE=10000