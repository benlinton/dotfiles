#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Function: find_and_source(<name> <basedir>)
# Requires: find
#
# Find files to source.
#
# `read -d ''` reads until the next \0 byte, so you don't have to worry about
# strange characters in filenames. similarly, `-print0` uses \0 to terminate
# each generated filename instead of \n. `cmd2 < <(cmd1)` is the same as
# `cmd1 | cmd2` except that cmd2 is run in the main shell and not a subshell.
# the call to `source` is redirected from /dev/null to ensure it doesn't
# accidentally read from the pipe.
# ------------------------------------------------------------------------------
function find_and_source() {
  while read -d '' filename; do
    source "${filename}" </dev/null
  done < <(find "${2}" -iname "${1}" -type f -print0)
}
