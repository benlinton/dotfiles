#!/usr/bin/env bash

# Read this for ideas on how to support aliases
# https://github.com/direnv/direnv/issues/73

if command_exists direnv ; then
  eval "$(direnv hook bash)"
fi
