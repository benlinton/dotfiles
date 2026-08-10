#!/bin/sh
# Tests for dot_claude/executable_permission-gate.sh.
#
#   sh tests/permission-gate-test.sh [path-to-hook]
#
# The file-tool cases are the point. settings.json allows Read/Edit under
# //tmp/**, and those rules match the path as a STRING — so a symlink at
# /tmp/x pointing to ~/.zshrc satisfies them. The hook re-checks against the
# filesystem; these tests pin that it does.
#
# Expectations:
#   ask    the hook forced a prompt
#   none   no opinion — the normal permission flow (and the allow rules) decide
#
# Nothing here executes the commands under test; they are only fed to the hook.
set -u

HOOK=${1:-$(dirname "$0")/../dot_claude/executable_permission-gate.sh}
[ -r "$HOOK" ] || { echo "cannot read hook: $HOOK" >&2; exit 2; }
command -v jq >/dev/null || { echo "jq is required" >&2; exit 2; }

T=$(mktemp -d /tmp/pgt.XXXXXX) || exit 2
trap 'rm -rf "$T"' EXIT INT TERM
touch "$T/real"
ln -sfn "$HOME" "$T/livelink"                       # resolves OUT of tmp
ln -sfn "$HOME/.pgt-does-not-exist" "$T/deadlink"   # dangling, also out of tmp

pass=0 fail=0
check() { # check <expect> <label> <got>
  got=${3:-none}
  if [ "$got" = "$1" ]; then pass=$((pass + 1)); else
    fail=$((fail + 1)); printf 'FAIL  want=%-5s got=%-5s %s\n' "$1" "$got" "$2"
  fi
}
tf() { # tf <expect> <tool> <path>
  check "$1" "$2 $3" "$(jq -nc --arg t "$2" --arg p "$3" \
    '{tool_name:$t,permission_mode:"default",tool_input:{file_path:$p}}' \
    | sh "$HOOK" 2>/dev/null | jq -r '.hookSpecificOutput.permissionDecision // empty' 2>/dev/null)"
}
tb() { # tb <expect> <command> [mode]
  check "$1" "$2 [${3:-default}]" "$(jq -nc --arg c "$2" --arg m "${3:-default}" \
    '{tool_name:"Bash",permission_mode:$m,tool_input:{command:$c}}' \
    | sh "$HOOK" 2>/dev/null | jq -r '.hookSpecificOutput.permissionDecision // empty' 2>/dev/null)"
}

# A path that really is in temp gets no opinion, so the allow rule applies.
tf none Read  "$T/real"
tf none Edit  "$T/real"
tf none Write "$T/does-not-exist-yet"

# A temp-LOOKING path that resolves elsewhere must prompt. The dangling case is
# the subtle one: -e follows symlinks, so without the -L test in resolve_root()
# the walk climbs past it to /tmp and the write lands at the link target.
for tool in Read Write Edit MultiEdit NotebookEdit; do
  tf ask "$tool" "$T/livelink"
  tf ask "$tool" "$T/deadlink"
done
tf ask Read "$T/livelink/.ssh/id_rsa"

# Paths outside temp are not this hook's business — the deny rules handle them.
tf none Edit "$HOME/.zshrc"
tf none Read "$HOME/.env"

# Bash tiers, unchanged by the file-tool block.
tb ask  'rm -rf /tmp/x'                      # tier 1: every mode...
tb ask  'rm -rf /tmp/x' bypassPermissions    # ...including bypass
tb ask  'cd x && rm -rf y'                   # tier 1 catches compounds
tb ask  '/bin/rm --recursive /tmp/x'
tb ask  'curl https://example.com'           # tier 2: outside bypass
tb none 'curl https://example.com' bypassPermissions
tb ask  'ssh host'
tb ask  'sudo ls'
tb none 'ls -la'
tb none 'git status'

printf '%s\n' "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
