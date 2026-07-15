#!/bin/sh
# IMPORTANT: Managed by chezmoi - do not edit this copy directly.
# Source: ~/.local/share/chezmoi - edit there, then run `chezmoi apply`.
# If you edit this file directly, notify the user and reconcile with the chezmoi source.
#
# PreToolUse (Bash) gate, two tiers:
#
#   Tier 1 — recursive rm (rm -r / -R / -rf / -fr / bundles / --recursive,
#            including /bin/rm and compound commands). Checked BEFORE the
#            bypass short-circuit, so it prompts in EVERY mode, bypass included.
#            The recursive (-r/-R) flag is what matters; -f is not required.
#            A native "Bash(rm -r*)" ask rule in settings.json backs this up.
#
#   Tier 2 — ssh / git push / curl / wget / sudo. Prompt only when NOT in
#            bypassPermissions mode; under bypass they run silently.
#
# Truly dangerous git push --force / -f use native `ask` rules in settings.json,
# so they prompt in every mode too.
input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')
mode=$(printf '%s' "$input" | jq -r '.permission_mode // "default"')

ask() {
  printf '%s' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"'"$1"'"}}'
  exit 0
}

# Tier 1 — recursive rm, every mode (before the bypass short-circuit below).
# Match `rm` as a command word, then within its own argument list (not crossing
# a |, & or ; separator) a flag cluster containing r/R, or --recursive.
if printf '%s' "$cmd" | grep -Eq \
  '(^|[^[:alnum:]_])rm[[:space:]]+([^|&;]*[[:space:]])?(-[[:alpha:]]*[rR][[:alpha:]]*|--recursive)([[:space:]]|$)'; then
  ask 'Recursive rm always prompts'
fi

[ "$mode" = "bypassPermissions" ] && exit 0   # bypass: skip the tier-2 gate

# Tier 2 — gated only outside bypass mode.
case "$cmd" in
  *'ssh '*|*'git push'*|*'curl '*|*'wget '*|*'sudo '*)
    ask 'Gated outside bypass mode'
    ;;
esac
exit 0
