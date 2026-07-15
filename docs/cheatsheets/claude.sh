# CLAUDE CHEATSHEET
# Launching the Claude Code CLI, permission modes, and scoping tool access.
# For in-session slash commands, see: cheatsheet claude-code

## LAUNCHING
claude                                 # Start an interactive session
claude "prompt"                        # Start with an initial prompt
claude -c                              # Continue the most recent session (also --continue)
claude -r [session]                    # Resume a session by ID or name (also --resume)
claude --fork-session                  # On resume, branch a new session ID (with -r/-c)
claude --from-pr [num]                 # Resume the session linked to a PR (picker if omitted)
claude -n <name>                       # Name the session (prompt box, picker, terminal title)
claude --model <model>                 # Launch with a model (alias: opus/sonnet/fable)
claude --effort <level>                # low | medium | high | xhigh | max
claude --add-dir <path>                # Grant an extra working directory up front
claude -w [name]                       # Create a git worktree for this session (also --worktree)

## PRINT / SCRIPTING MODE
claude -p "prompt"                     # Run once, print result, exit (useful for pipes)
claude -p "prompt" --output-format json      # Structured output (text | json | stream-json)
claude -p "prompt" --json-schema '<schema>'  # Validate output against a JSON Schema
claude -p "prompt" --fallback-model <model>  # Fall back if the primary is overloaded
claude -p "prompt" --max-budget-usd <n>      # Cap dollars spent on API calls

## PERMISSION MODES
# default             prompts on first use of each tool/command
# acceptEdits         auto-approves file edits (mkdir/touch too); still prompts for other commands
# plan                read-only; can't edit, run, or commit until you approve a plan
# bypassPermissions   approves everything, no prompts (the "yolo" mode)
claude --permission-mode acceptEdits   # Launch in accept-edits mode
claude --permission-mode plan          # Launch read-only in plan mode
claude --permission-mode bypassPermissions   # Launch approving everything
claude --dangerously-skip-permissions  # Alias for bypassPermissions

## SWITCH MODE MID-SESSION
# Shift+Tab cycles: default -> acceptEdits -> plan -> bypassPermissions (if enabled)
# Per-session and non-persistent; nothing is written to config.

## SCOPE PERMISSIONS (less than full bypass)
claude --allowedTools "Bash(git*)" "Edit"    # Pre-approve only these tools
claude --disallowedTools "Bash(rm*)"         # Pre-deny specific tools
# settings.json -> permissions.allow          # Persistent allowlist (edited via /permissions)
# /fewer-permission-prompts                    # Skill: scan history, propose a scoped allowlist

## CONFIG INJECTION
claude --settings <file-or-json>       # Load extra settings from a file or JSON string
claude --mcp-config <file...>          # Load MCP servers from JSON files/strings
claude --agents '<json>'               # Define custom agents inline
claude --append-system-prompt "<txt>"  # Append to the default system prompt
claude --safe-mode                     # Disable all customizations (troubleshoot broken config)
claude --bare                          # Minimal mode: skip hooks, LSP, CLAUDE.md, plugins, etc.

## IN-SESSION STATUS (slash commands)
/status                                # Version, model, account, and session info
/context                               # Visualize context window usage (tokens remaining)
/cost                                  # Token usage and cost for this session
/usage                                 # Plan limits and rate-limit status
/model [model]                         # Show or change the current model
# For the full slash-command list: cheatsheet claude-code

## SUBCOMMANDS
claude update                          # Check for and install updates (also upgrade)
claude doctor                          # Diagnose installation and settings health
claude mcp                             # Configure and manage MCP servers
claude auth                            # Manage authentication
claude agents                          # Manage background agents
claude install [target]               # Install a native build (stable/latest/version)
claude -v                              # Print the version (also --version)

## NOTES
# bypassPermissions is refused when running as root/sudo on some setups.
# It is also blocked if your org/settings set disableBypassPermissions.
# Prefer an allowlist over full bypass when the same commands keep prompting —
# it keeps guardrails on genuinely destructive actions while killing the noise.
