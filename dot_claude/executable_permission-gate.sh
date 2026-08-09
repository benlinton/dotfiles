#!/bin/sh
# IMPORTANT: Managed by chezmoi - do not edit this copy directly.
# Source: ~/.local/share/chezmoi - edit there, then run `chezmoi apply`.
# If you edit this file directly, notify the user and reconcile with the chezmoi source.
#
# PreToolUse gate. Matches Bash plus the file tools (Read/Write/Edit), because
# the temp-dir rules below have to hold for both or they hold for neither.
#
#   Tier 0 — temp-dir work (/tmp, /private/tmp). Explicitly ALLOWED in every
#            mode, ahead of every other check, so scratchpad commands —
#            `rm -rf /tmp/x` included — never prompt.
#            It emits an explicit "allow" rather than exiting silently because a
#            silent exit falls through to the native `ask` rules in settings.json,
#            which fire in every mode (`Bash(rm -r*)` would otherwise still
#            prompt; that the allow wins is verified, not assumed).
#
#            INVARIANT: tier 0 never overrides another gate, except `curl` —
#            see GATED_CMD for why that one is carved out. Because its allow
#            outranks native `ask`, a command that tier 1, tier 2 or
#            settings.json would have stopped must not ride an incidental temp
#            mention past them — `git push --force origin main && ls /tmp/x` is
#            a force push, not scratch work. The one carve-out is recursive rm,
#            the case tier 0 exists for, admitted only when EVERY token of the
#            command is provably temp-scoped.
#
#            Crucially, a temp path is confirmed against the FILESYSTEM, not
#            just pattern-matched. `/tmp/x` is a symlink to anywhere as far as
#            the string is concerned — see resolve_root() / under_tmp().
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
# jq stderr is discarded throughout: on malformed input every field comes back
# empty, the script reaches no decision and the normal permission flow takes
# over. That is the right outcome, but the parse errors would otherwise land in
# the UI on every call.
input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // ""' 2>/dev/null)
mode=$(printf '%s' "$input" | jq -r '.permission_mode // "default"' 2>/dev/null)
set -f   # no pathname expansion when we word-split $cmd below

# Recursive rm: `rm` as a command word, then within its own argument list (not
# crossing a |, & or ; separator) a flag cluster containing r/R, or --recursive.
REC_RM='(^|[^[:alnum:]_])rm[[:space:]]+([^|&;]*[[:space:]])?(-[[:alpha:]]*[rR][[:alpha:]]*|--recursive)([[:space:]]|$)'
# /tmp and /private/tmp as whole path words: `/tmp`, `/tmp/...`, quoted forms;
# not `/tmpfoo`, `./tmp` or `mytmp`.
TMP_WORD='(^|[^[:alnum:]_.-])(/private)?/tmp(/|[^[:alnum:]_.-]|$)'
# `rm` as a command word, bare or fully qualified. Broader than REC_RM on
# purpose: tier 0 holds EVERY rm to the strict whole-command check, not just the
# recursive ones, since `rm -f ~/.zshrc` is no less final for lacking a -r.
RM_ANY='(^|[^[:alnum:]_])(/bin/|/usr/bin/)?rm([[:space:]]|$)'
# Commands another gate already stops — tier 1, tier 2, or a native `ask` rule.
# Tier 0 must never launder one of these, so a command naming any of them is
# simply not eligible for an allow, temp paths or not. `git` is here whole
# rather than as `git push`, because `git clean -fdx` is just as destructive and
# no git operation is ever really "about tmp".
#
# `curl` is the one deliberate exception to the invariant, and it is an exception
# on purpose: fetching a reference file into a scratchpad is the single most
# common thing that interrupted real work, and it is what this exemption was
# built for. It stays safe only because the other conditions still hold around
# it — the command must name a temp path, every filesystem path it names must
# resolve inside tmp, and every command word must be on the allowlist. So
# `curl -o ~/.zshrc`, `curl … > ~/x` and `curl … | sh` are all still stopped,
# by conditions 3 and 5 rather than by this list.
#
# What it does concede: network egress with no prompt, when the command is
# otherwise confined to tmp. `curl -T /tmp/x https://…` uploads a temp file
# unattended. That is the accepted cost — data already sitting in a scratchpad.
# `wget` stays gated, since curl covers the workflow and one door is enough.
GATED_CMD='(^|[^[:alnum:]_./-])(ssh|sudo|wget|git)([[:space:]]|$)'

has() { printf '%s' "$cmd" | grep -Eq "$1"; }

ask() {
  printf '%s' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"'"$1"'"}}'
  exit 0
}

allow() {
  printf '%s' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"'"$1"'"}}'
  exit 0
}

# --- Does this path REALLY live in the temp dir? ------------------------------
#
# Everything about the temp exemption rests on these two functions, because a
# path that reads like `/tmp/x` is a symlink to anywhere at all — verified: a
# plain `echo hi > /tmp/link` overwrote a file in $HOME. Pattern-matching the
# string cannot see that; the filesystem can.
#
# realpath fails outright on a path that doesn't exist yet, and a write target
# usually doesn't, so resolve the deepest EXISTING ancestor instead: a symlink
# can only exist in the part of the path that already exists.
#
# The -L test is load-bearing. -e follows symlinks, so a DANGLING symlink looks
# nonexistent, the loop climbs past it to /tmp, and the path reads as temp —
# while the shell still creates the file at the link target. `echo x >
# /tmp/link` with link -> ~/.zshenv would land in $HOME, and a file that does
# not exist yet is exactly the interesting case (~/.zshenv is sourced by every
# shell). Stopping on -L hands the dangling link to realpath, which fails on it,
# and under_tmp() rejects the empty result.
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

# Both roots are listed on purpose, because this file also deploys to Linux and
# WSL: macOS resolves /tmp to /private/tmp, everywhere else /tmp resolves to
# itself. Accepting only the macOS form would make under_tmp() reject every temp
# path on Linux, and the exemption would invert into prompting on everything.
# An empty argument (realpath missing or failed) falls through to 1 — fail safe.
under_tmp() {
  case "$1" in
    /private/tmp|/private/tmp/*) return 0 ;;
    /tmp|/tmp/*) return 0 ;;
  esac
  return 1
}

# Strip shell decoration a word-split leaves attached: redirections (`>`, `2>`,
# `>>`, `<`) and surrounding quotes. Without this, `echo x >/tmp/link` hides its
# path inside the token `>/tmp/link` and escapes the check entirely.
clean_tok() {
  tok=$1
  while :; do
    case "$tok" in
      [0-9]'>'*) tok=${tok#?>} ;;
      '>>'*)     tok=${tok#>>} ;;
      '>'*|'<'*) tok=${tok#?} ;;
      '"'*|"'"*) tok=${tok#?} ;;
      *) break ;;
    esac
  done
  case "$tok" in *'"'|*"'"|*';') tok=${tok%?} ;; esac
}

# Every temp-looking path in the command actually lands inside /private/tmp.
# A glob is checked by the directory holding it, walking left until the glob is
# gone — `/tmp/link/*` is only safe if `/tmp/link` itself stays in tmp.
tmp_paths_resolve() {
  for raw in $cmd; do
    clean_tok "$raw"
    case "$tok" in
      /tmp|/tmp/*|/private/tmp|/private/tmp/*) ;;
      *) continue ;;
    esac
    while :; do
      case "$tok" in
        *'*'*|*'?'*|*'['*)
          new=${tok%/*}
          [ "$new" = "$tok" ] && return 1
          tok=$new
          ;;
        *) break ;;
      esac
    done
    under_tmp "$(resolve_root "$tok")" || return 1
  done
  return 0
}

# Every path-like token in the command points into a temp root. This is the
# difference between a command that *mentions* /tmp and one that only *touches*
# /tmp — without it, `cd /tmp/x && rm -rf ~/Workspace` launders a real delete
# through an incidental temp mention, and `ls /tmp/x && chmod -R 777 /` walks
# out the same door.
#
# Applied to EVERY tier-0 candidate, not just the deletions. A command's danger
# is not announced by its name: `chmod`, `mv` and `tee` are as capable of
# wrecking $HOME as rm is, and the only thing that reliably distinguishes
# scratch work is that nothing it names lives outside tmp.
#
# Refused outright, because each can reach outside tmp and no inspection here
# can tell that it doesn't:
#   `..`               — climbs out of the temp root
#   `$(...)` / backtick — target isn't known until the shell runs it
#
# An http(s) URL is exempt. It contains slashes, so it reads as path-like, but it
# is not a filesystem path and cannot be a write or delete target — the risk it
# carries is network reach, which conditions 4 and 5 govern by restricting which
# commands may run at all. Without this exemption `curl https://x` could never
# satisfy tmp_scoped and the curl carve-out above would be dead on arrival.
# Only http/https: `file://` is a filesystem path in disguise, and scp-style
# `user@host:path` is a remote write, so neither is listed.
tmp_scoped() {
  case "$cmd" in
    # `$` covers `$(...)` and plain `$VAR` alike. A bare `$HOME` has no slash,
    # so it does not read as path-like and would sail through as a harmless
    # word — `cd /tmp/x && chmod -R 777 $HOME` was verified allowed. Nothing
    # here can know what a variable holds, which is the same reason `..` and
    # command substitution are refused.
    *'..'*|*'$'*|*'`'*) return 1 ;;
  esac
  for raw in $cmd; do
    clean_tok "$raw"
    case "$tok" in
      -*)
        # A flag may carry its path ATTACHED: `-o/etc/x`, `--out=/etc/x`,
        # `-d@/etc/passwd`. Skipping every `-*` token wholesale let that path
        # escape unexamined, which is how `curl … -o$HOME/.zshenv` earned an
        # allow while the spaced form `-o $HOME/.zshenv` was correctly stopped.
        # Re-anchor on the first `/` or `~` and judge what follows as a path.
        case "$tok" in
          *[/~]*) tok=${tok#"${tok%%[/~]*}"} ;;
          *) continue ;;           # a real flag, no path inside it
        esac
        ;;
      http://*|https://*) continue ;;  # URL, not a filesystem path
      */*|'~'*) ;;                 # path-like, so it has to be a temp path
      *) continue ;;               # bare word: rm, &&, echo, ...
    esac
    case "$tok" in
      /tmp|/tmp/*|/private/tmp|/private/tmp/*) ;;
      *) return 1 ;;
    esac
  done
  return 0
}

# The command word of every segment is one tier 0 will run unprompted.
#
# tmp_scoped() constrains path-like tokens, but a bare word is not path-like,
# so `ls /tmp/x && npm publish` clears it with nothing to object to. Operands
# stay unrestricted — `echo hi > /tmp/x` has to keep working — but the command
# word itself must be recognized, or tier 0 is a general-purpose bypass that
# any command can reach by appending `&& ls /tmp/x`.
#
# Separators are padded with spaces first so `a;rm` splits into `a ; rm`; a word
# split alone would hide the command word inside the previous token. `<` and `>`
# are deliberately NOT padded — they do not start a new command, and splitting
# them would leave the redirect target sitting in command position.
cmd_words_safe() {
  want_cmd=1
  for raw in $(printf '%s' "$cmd" | sed 's/[;&|()]/ & /g'); do
    # Test the RAW token for separators. clean_tok strips a bare `>` or `2>` to
    # the empty string, and an empty token must NOT reset command position or
    # the redirect target lands there instead: `echo hi > /tmp/x` would ask
    # whether `/tmp/x` is a command word we trust.
    case "$raw" in
      ';'|'&'|'|'|'('|')') want_cmd=1; continue ;;
    esac
    clean_tok "$raw"
    [ -z "$tok" ] && continue
    [ "$want_cmd" = 1 ] || continue
    want_cmd=0
    case "$tok" in
      /bin/*|/usr/bin/*) tok=${tok##*/} ;;
    esac
    case "$tok" in
      rm|rmdir|cp|mv|ln|mkdir|touch|cat|head|tail|ls|echo|printf|pwd|cd) ;;
      stat|file|wc|sort|uniq|cut|tr|sed|awk|grep|egrep|fgrep|rg|find) ;;
      jq|diff|realpath|dirname|basename|du|chmod|tee|test|true|false) ;;
      curl) ;;   # see GATED_CMD: allowed only inside an otherwise tmp-confined command
      *) return 1 ;;
    esac
  done
  return 0
}

# For any command naming `rm`, every token must be individually accounted for:
# a flag, a temp path, or one of a few benign words. Nothing may be a bare word.
#
# This is stricter than tmp_scoped() because a delete has no partial failure
# mode. `ls /tmp/x && rm -rf build` passes tmp_scoped — `build` has no slash, so
# it is not path-like — and would recursively delete a directory in the
# project's cwd, which this hook never sees. Requiring rm's operands to be
# ABSOLUTE temp paths is the only way to be sure of what gets deleted.
#
# Also refused here:
#   trailing `/`  — `rm -rf /tmp/link/` deletes THROUGH a symlink (verified)
#   bare /tmp     — wiping the root takes out every other session's scratch
#
# A relative target (`rm -rf ./build`, `rm -rf build`) prompts, always.
rm_tokens_scoped() {
  for raw in $cmd; do
    clean_tok "$raw"
    case "$tok" in
      ''|-*) continue ;;                         # empty or flag
      */) return 1 ;;                            # trailing slash: symlink traversal
      /tmp/?*|/private/tmp/?*) continue ;;       # an actual temp target
      rm|/bin/rm|/usr/bin/rm|cd|ls|mkdir|touch|true) continue ;;
      '&&'|'||'|';'|'&'|'|') continue ;;
      *) return 1 ;;                             # bare word, relative path, $VAR
    esac
  done
  return 0
}

# --- Is this URL fetching something inert? ------------------------------------
#
# A downloaded file is harmless until something runs it, and condition 5 already
# keeps every interpreter, package manager, build tool and archive extractor off
# the allowlist — `sh /tmp/x`, `python3 /tmp/x`, `npm install` and `tar -xf` all
# prompt. So this is NOT the boundary that stops malicious downloads; that one
# is, and it holds regardless of file type.
#
# What this adds is visibility. `curl https://…/install.sh -o /tmp/x` is worth
# seeing even though the follow-up would prompt anyway, because fetching an
# executable is a statement of intent. An allowlist of inert types, mirroring
# conditions 5 and 6: anything unrecognized merely falls through to tier 2's
# existing curl prompt.
#
# BE HONEST ABOUT WHAT THIS IS: the extension describes what was REQUESTED, not
# what the server sends. `https://evil.example/cat.jpg` may return a script and
# would pass. It is a speed bump against the careless case, not a control
# against an adversary — do not let it justify loosening anything else. The real
# control over what curl may reach is the sandbox's network allowlist.
url_is_inert() {
  u=${1%%#*}      # drop fragment
  u=${u%%\?*}     # drop query string — it can hide the real extension
  u=${u##*/}      # last path segment
  case "$u" in
    *.*) ;;
    *) return 1 ;;  # no extension at all: unknown, so ask
  esac
  case "$(printf '%s' "${u##*.}" | tr '[:upper:]' '[:lower:]')" in
    pdf|html|htm|txt|text|md|json|csv|tsv|xml|yaml|yml|log|rtf) return 0 ;;
    png|jpg|jpeg|gif|webp|bmp|ico|svg|avif|tiff) return 0 ;;
    mp4|webm|mov|mkv|mp3|wav|ogg|m4a|flac) return 0 ;;
    *) return 1 ;;
  esac
}

# Every URL in the command fetches an inert type. Vacuously true when there is
# no URL, so commands that touch no network are unaffected.
urls_inert() {
  for raw in $cmd; do
    clean_tok "$raw"
    case "$tok" in
      http://*|https://*) url_is_inert "$tok" || return 1 ;;
    esac
  done
  return 0
}

# --- File tools (Read / Write / Edit) -----------------------------------------
# The native Read(/tmp/**) and Write(/tmp/**) allow rules in settings.json match
# the path as a STRING, so a `/tmp/x` that symlinks to ~/.zshrc satisfies them
# and the write lands in $HOME with no prompt. Re-check against the filesystem
# and force a prompt when a temp-looking path resolves somewhere real. Anything
# not temp-looking gets no opinion here — the normal permission flow handles it.
case "$tool" in
  Read|Write|Edit|NotebookEdit)
    path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // ""' 2>/dev/null)
    case "$path" in
      /tmp|/tmp/*|/private/tmp|/private/tmp/*)
        under_tmp "$(resolve_root "$path")" \
          || ask 'Temp-looking path resolves outside /tmp'
        ;;
    esac
    exit 0
    ;;
esac

cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null)

# Tier 0 — temp dirs, every mode, before tier 1 so `rm -rf /tmp/x` stays silent.
#
# An allow here outranks every other rule, so the bar is that the command must
# be provably confined to tmp — not merely that it mentions tmp. Each condition
# closes a different way back out:
#
#   1. it names a temp path                                     TMP_WORD
#   2. every temp path it names really is in tmp                tmp_paths_resolve
#   3. no path-like token points anywhere but tmp               tmp_scoped
#   4. no other gate already stops this command                 GATED_CMD
#   5. every command word is one we run unprompted              cmd_words_safe
#   6. if it names rm, every token is accounted for             rm_tokens_scoped
#   7. every URL it fetches names an inert file type            urls_inert
#
# Failing 2 is different from failing the rest: an unresolvable temp path is a
# positive danger signal, so it ASKS. Failing 3-7 only means "no opinion" — the
# command falls through to tier 1, tier 2 and the native rules, exactly as if
# tier 0 did not exist.
if has "$TMP_WORD"; then
  # Must ASK, not merely decline to allow: falling through here lands on the
  # native allow list, and `Bash(echo *)` would happily run
  # `echo x > /tmp/link` straight into $HOME with no prompt.
  tmp_paths_resolve || ask 'Temp-looking path resolves outside /tmp'

  if ! has "$GATED_CMD" && tmp_scoped && cmd_words_safe && urls_inert; then
    if ! has "$RM_ANY"; then
      allow 'Temp-scoped command, never gated'
    elif rm_tokens_scoped; then
      allow 'Temp-scoped rm, never gated'
    fi
  fi
fi

# Tier 1 — recursive rm, every mode (before the bypass short-circuit below).
if has "$REC_RM"; then
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
