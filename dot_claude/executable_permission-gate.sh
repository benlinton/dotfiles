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
#
# It also re-checks the FILE tools (Read/Write/Edit/...) against the filesystem,
# because settings.json allows them under //tmp. See the block below.
input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // ""' 2>/dev/null)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null)
mode=$(printf '%s' "$input" | jq -r '.permission_mode // "default"' 2>/dev/null)

ask() {
  printf '%s' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"'"$1"'"}}'
  exit 0
}

# --- File tools: is this temp-looking path REALLY in temp? --------------------
#
# The native Read(//tmp/**) and Edit(//tmp/**) allow rules match the path as a
# STRING. A symlink at /tmp/x pointing to ~/.zshrc satisfies them, and the write
# lands in $HOME with no prompt. So resolve against the filesystem and force a
# prompt whenever the string and the real location disagree. This ONLY ever adds
# prompts — a path that is genuinely in temp is untouched.
#
# realpath fails outright on a path that doesn't exist yet, and a write target
# usually doesn't, so resolve the deepest EXISTING ancestor: a symlink can only
# live in the part of the path that already exists.
#
# The -L test is load-bearing. -e FOLLOWS symlinks, so a dangling link looks
# nonexistent, the walk climbs past it to /tmp, and the path reads as temp —
# while the write still creates the file at the link target. A file that doesn't
# exist yet is exactly the interesting case: ~/.zshenv doesn't either, and every
# shell sources it.
resolve_root() {
  p=$1
  while [ ! -e "$p" ] && [ ! -L "$p" ]; do
    parent=${p%/*}
    [ "$parent" = "$p" ] && parent=.
    [ -z "$parent" ] && parent=/
    p=$parent
  done
  realpath "$p" 2>/dev/null
}

# Both roots on purpose: macOS resolves /tmp to /private/tmp, Linux and WSL to
# itself, and this file deploys to all three. An empty argument (realpath absent
# or failed) matches nothing and returns 1 — fail safe.
under_tmp() {
  case "$1" in
    /private/tmp|/private/tmp/*|/tmp|/tmp/*) return 0 ;;
  esac
  return 1
}

case "$tool" in
  Read|Write|Edit|MultiEdit|NotebookEdit)
    path=$(printf '%s' "$input" \
      | jq -r '.tool_input.file_path // .tool_input.notebook_path // ""' 2>/dev/null)
    case "$path" in
      /tmp|/tmp/*|/private/tmp|/private/tmp/*)
        under_tmp "$(resolve_root "$path")" \
          || ask 'Temp-looking path resolves outside /tmp'
        ;;
    esac
    # Anything not temp-looking gets no opinion — the normal permission flow,
    # including the deny rules, decides.
    exit 0
    ;;
esac

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
