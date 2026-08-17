#!/bin/sh
# IMPORTANT: Managed by chezmoi - do not edit this copy directly.
# Source: ~/.local/share/chezmoi - edit there, then run `chezmoi apply`.
# If you edit this file directly, notify the user and reconcile with the chezmoi source.
#
# PreToolUse gate. Two independent jobs:
#
#   1. FILE TOOLS (Read/Write/Edit/...) are re-checked against the filesystem,
#      because settings.json allows them under //tmp by STRING match and a
#      symlink defeats that. See the block below. Not policy-driven.
#
#   2. BASH commands are gated by a per-project policy resolved at call time
#      from ~/.config/luma. Every gated command class (ssh, curl, sudo, ...)
#      carries one of these values:
#
#        allow    no opinion — the normal permission flow decides
#        ask      prompt, but bypassPermissions (and trust="full") silence it
#        always   prompt in EVERY mode, bypass included
#        deny     the hook refuses outright, every mode
#        trusted  (ssh only)  allow a host on ssh_hosts, otherwise ask
#        safe     (curl/wget) allow a plain fetch, ask when the command writes
#                             to disk, uploads, or pipes into an interpreter
#
#      "always"/"deny" are evaluated ABOVE the bypass short-circuit; "ask" and
#      the refined values below it. That is the tier-1 / tier-2 split the old
#      hardcoded version had, now expressed as data.
#
#      Defaults reproduce the previous hardcoded behaviour exactly, so a machine
#      with no config files under ~/.config/luma behaves as it always did.
#
# Policy resolution, per key, most specific wins:
#   ~/.config/luma/projects/<slug>.toml   <- the project the session is in
#   ~/.config/luma/policy.toml            <- global fallback
#   the def_* values below                <- built-in
#
# <slug> is the project's absolute path with "/" and "." both replaced by "-",
# matching how Claude Code names directories under ~/.claude/projects. The path
# is the repository root (nearest ancestor containing .git) so that every
# session in a repo shares one policy regardless of which subdirectory it
# started in; outside a repo it is the session cwd. Git worktrees have their
# own .git and therefore their own policy, which is deliberate.
#
# See docs/claude-permission-gating.md for how this interacts with the native
# rules in settings.json. Both layers must be kept in sync.

LUMA_HOME=${LUMA_POLICY_HOME:-$HOME/.config/luma}

# --- Input -------------------------------------------------------------------
# One jq call, not five: this runs before every Bash/Read/Write tool call and
# process spawns dominate its cost. @sh quotes each value for the eval.
tool='' cmd='' mode=default cwd='' fpath=''
input=$(cat)
eval "$(printf '%s' "$input" | jq -r '[
  "tool=\(.tool_name // ""                                              | @sh)",
  "cmd=\(.tool_input.command // ""                                      | @sh)",
  "mode=\(.permission_mode // "default"                                 | @sh)",
  "cwd=\(.cwd // ""                                                     | @sh)",
  "fpath=\(.tool_input.file_path // .tool_input.notebook_path // ""     | @sh)"
] | join("\n")' 2>/dev/null)"

ask() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}' "$1"
  exit 0
}
deny() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}' "$1"
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
    case "$fpath" in
      /tmp|/tmp/*|/private/tmp|/private/tmp/*)
        under_tmp "$(resolve_root "$fpath")" \
          || ask 'Temp-looking path resolves outside /tmp'
        ;;
    esac
    # Anything not temp-looking gets no opinion — the normal permission flow,
    # including the deny rules, decides.
    exit 0
    ;;
esac

# --- Policy ------------------------------------------------------------------

# Built-in defaults. These reproduce the behaviour that used to be hardcoded.
def_trust=normal
def_recursive_rm=always
def_ssh=ask
def_curl=ask
def_wget=ask
def_sudo=ask
def_git_push=ask
def_downloads=allow
def_policy_write=always
def_ssh_hosts=''

KEYS='recursive_rm ssh curl wget sudo git_push downloads policy_write'

# Nearest ancestor of $1 containing .git — a file or a directory, so worktrees
# and submodules resolve too. Prints nothing and returns 1 when there is none.
repo_root() {
  d=$1
  case "$d" in /*) ;; *) return 1 ;; esac
  while [ -n "$d" ] && [ "$d" != / ]; do
    [ -e "$d/.git" ] && { printf '%s' "$d"; return 0; }
    d=${d%/*}
  done
  return 1
}

# Canonicalize before slugging. luma-policy computes its slug from `pwd -P`, and
# the two MUST agree or the hook reads a file the CLI never writes. On macOS
# /tmp is a symlink to /private/tmp, which is exactly how this drifts.
cwd_real=$(cd "$cwd" 2>/dev/null && pwd -P) || cwd_real=''
[ -n "$cwd_real" ] || cwd_real=$cwd

project_dir=$(repo_root "$cwd_real") || project_dir=$cwd_real
project_slug=$(printf '%s' "$project_dir" | tr '/.' '--')

global_file=$LUMA_HOME/policy.toml
project_file=$LUMA_HOME/projects/$project_slug.toml

# Read both files in one awk pass, global first so the project file wins per
# key. The accepted format is a documented SUBSET of TOML: top-level
# `key = "value"` lines and # comments. Tables are skipped, not parsed — a
# value containing # or a quote is not supported and never needs to be.
set -- ; [ -r "$global_file" ] && set -- "$@" "$global_file"
[ -r "$project_file" ] && set -- "$@" "$project_file"
if [ $# -gt 0 ]; then
  eval "$(awk '
    /^[[:space:]]*[#[]/ { next }
    {
      eq = index($0, "=")
      if (eq == 0) next
      k = substr($0, 1, eq - 1); v = substr($0, eq + 1)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", k)
      sub(/[[:space:]]*#.*$/, "", v)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
      gsub(/^"|"$/, "", v); gsub(/^\x27|\x27$/, "", v)
      if (k !~ /^[a-z_][a-z0-9_]*$/) next
      if (v ~ /[^A-Za-z0-9_., @:\/-]/) next   # reject anything needing quoting
      P[k] = v
    }
    END { for (k in P) printf "pol_%s=%s\n", k, "\x27" P[k] "\x27" }
  ' "$@" 2>/dev/null)"
fi

# Resolve every key once into cur_* with no subshells — this loop runs on every
# Bash tool call.
for k in $KEYS trust ssh_hosts; do
  eval "cur_$k=\${pol_$k:-\$def_$k}"
done

# --- Command classification --------------------------------------------------

# Is $1 invoked as a command word (optionally by absolute path), anywhere in the
# command including inside a compound? Matches textually, so it over-prompts on
# string literals like echo "curl x". That is intentional: it fails safe toward
# prompting. See docs/claude-permission-gating.md.
has_word() {
  printf '%s' "$cmd" | grep -Eq "(^|[^[:alnum:]_.-])([[:alnum:]_./-]*/)?$1([[:space:]]|\$)"
}

matches() {
  case $1 in
    recursive_rm)
      # `rm` as a command word, then within its own argument list (not crossing
      # a |, & or ; separator) a flag cluster containing r/R, or --recursive.
      # The recursive flag is what matters; -f is not required.
      case $cmd in *rm*) ;; *) return 1 ;; esac
      printf '%s' "$cmd" | grep -Eq \
        '(^|[^[:alnum:]_])rm[[:space:]]+([^|&;]*[[:space:]])?(-[[:alpha:]]*[rR][[:alpha:]]*|--recursive)([[:space:]]|$)'
      ;;
    ssh)  case $cmd in *ssh*)  ;; *) return 1 ;; esac; has_word ssh  ;;
    curl) case $cmd in *curl*) ;; *) return 1 ;; esac; has_word curl ;;
    wget) case $cmd in *wget*) ;; *) return 1 ;; esac; has_word wget ;;
    sudo) case $cmd in *sudo*) ;; *) return 1 ;; esac; has_word sudo ;;
    git_push)
      case $cmd in *push*) ;; *) return 1 ;; esac
      printf '%s' "$cmd" | grep -Eq '(^|[^[:alnum:]_.-])git([[:space:]]+-[^[:space:]]+)*[[:space:]]+push([[:space:]]|$)'
      ;;
    downloads)
      # Package managers that fetch and then execute what they fetched. This is
      # a convenience gate, NOT a boundary: it lists the common front doors and
      # cannot enumerate every way a command reaches the network.
      printf '%s' "$cmd" | grep -Eq \
        '(^|[^[:alnum:]_.-])(npm|pnpm|yarn|bun)[[:space:]]+(i|install|add|ci)([[:space:]]|$)|(^|[^[:alnum:]_.-])(pip|pip3|uv)[[:space:]]+(install|add)([[:space:]]|$)|(^|[^[:alnum:]_.-])go[[:space:]]+(get|install)([[:space:]]|$)|(^|[^[:alnum:]_.-])(cargo[[:space:]]+(add|install|fetch)|gem[[:space:]]+install|brew[[:space:]]+install|apt-get[[:space:]]+install)([[:space:]]|$)'
      ;;
    policy_write)
      # Writes to the policy files themselves. Without this the agent can hand
      # itself any permission it likes by editing its own rulebook. The native
      # Edit(~/.config/luma/**) deny in settings.json covers the file tools;
      # this covers Bash.
      case $cmd in *luma*) ;; *) return 1 ;; esac
      # The CLI's own mutating subcommands. Keep this list in step with the
      # dispatch table in luma-policy: anything that writes belongs here. The
      # reads — show, list, keys, projects, path — stay ungated on purpose.
      printf '%s' "$cmd" | grep -Eq \
        '(^|[^[:alnum:]_.-])luma-policy[[:space:]]+(-[^[:space:]]+[[:space:]]+)*(set|unset|reset|edit|allow|ask|deny)([[:space:]]|$)' && return 0
      # Any shell-level write aimed at the policy files. Reading them is fine.
      printf '%s' "$cmd" | grep -Eq '(\.config/luma|LUMA_POLICY_HOME)' || return 1
      printf '%s' "$cmd" | grep -Eq '(>|>>|tee|sed[[:space:]]+-i|cp|mv|rm|install|truncate|chmod|chown|ln)'
      ;;
    *) return 1 ;;
  esac
}

# ssh = "trusted": allow only hosts named in ssh_hosts. Anything we cannot parse
# with confidence falls through to a prompt.
ssh_trusted() {
  [ -n "$cur_ssh_hosts" ] || return 1
  # More than one ssh invocation in a compound: don't try, just prompt.
  [ "$(printf '%s' "$cmd" | grep -Eo '(^|[^[:alnum:]_.-])([[:alnum:]_./-]*/)?ssh([[:space:]]|$)' | wc -l)" -eq 1 ] || return 1
  host=$(printf '%s' "$cmd" | awk '
    { n = split($0, a, /[[:space:]]+/)
      for (i = 1; i <= n; i++) if (a[i] ~ /(^|\/)ssh$/) {
        for (j = i + 1; j <= n; j++) {
          if (a[j] ~ /^-/) { if (a[j] ~ /^-[bcDEeFIiJLlmOoPpQRSWw]$/) j++; continue }
          h = a[j]; sub(/^[^@]*@/, "", h); print h; exit
        }
      }
    }')
  [ -n "$host" ] || return 1
  for h in $(printf '%s' "$cur_ssh_hosts" | tr ',' ' '); do
    [ "$h" = "$host" ] && return 0
  done
  return 1
}

# curl/wget = "safe": a plain fetch to stdout is fine. Writing the response to
# disk, uploading a body, or piping into an interpreter is not.
#
# Note what this canNOT do: the hook sees only the command string, so it has no
# idea what a URL will actually return. "safe" is a statement about the SHAPE of
# the command, never about the content that comes back.
fetch_unsafe() {
  printf '%s' "$cmd" | grep -Eq '\|[[:space:]]*(sudo[[:space:]]+)?(sh|bash|zsh|ksh|dash|python[0-9.]*|perl|ruby|node)([[:space:]]|$)' && return 0
  printf '%s' "$cmd" | grep -Eq '<\([[:space:]]*(curl|wget)|\$\([[:space:]]*(curl|wget)|`[[:space:]]*(curl|wget)' && return 0
  printf '%s' "$cmd" | grep -Eq '(^|[[:space:]])(-[oOT]|--output|--output-document|--remote-name|--upload-file|-d|--data|--data-binary|--data-raw|-F|--form)([[:space:]=]|$)' && return 0
  return 1
}

# --- Decide ------------------------------------------------------------------

# Pass 1 — "always" and "deny" run before the bypass short-circuit, so they
# fire in every mode. A native ask rule in settings.json backs up recursive_rm
# in case this script goes missing.
for k in $KEYS; do
  eval "v=\$cur_$k"
  case $v in
    always) matches "$k" && ask "Gated in every mode by policy ($k=always)" ;;
    deny)   matches "$k" && deny "Refused by policy ($k=deny)" ;;
  esac
done

# bypassPermissions is a per-session opt-out; trust="full" is a per-project one.
[ "$mode" = bypassPermissions ] && exit 0
[ "$cur_trust" = full ] && exit 0

# Pass 2 — gated during ordinary work, silent under bypass or full trust.
for k in $KEYS; do
  eval "v=\$cur_$k"
  case $v in
    allow|always|deny) continue ;;
  esac
  matches "$k" || continue
  case $v in
    ask)     ask "Gated outside bypass mode ($k=ask)" ;;
    trusted) [ "$k" = ssh ] && { ssh_trusted || ask 'ssh host is not on ssh_hosts'; } ;;
    safe)    fetch_unsafe && ask "$k writes to disk, uploads, or pipes to a shell" ;;
    *)       ask "Unknown policy value for $k: $v" ;;
  esac
done
exit 0
