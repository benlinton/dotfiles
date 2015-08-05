#!/usr/bin/env bash

if command_exists direnv ; then
  eval "$(direnv hook bash)"
fi
