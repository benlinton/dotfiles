#!/usr/bin/env bash

# ---------------------------------------------------------------------------
# Function: command_exists(string command_name)
# Returns true if the command exists, otherwise returns false.
# ---------------------------------------------------------------------------

command_exists() {
  command -v "$1" &> /dev/null ;
}

