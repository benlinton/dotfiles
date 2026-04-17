# CLAUDE CODE CHEATSHEET
# Built-in slash commands for the Claude Code CLI

## SESSION
/clear                                 # New conversation, empty context (also /reset, /new)
/resume [session]                      # Resume a conversation by ID or name (also /continue)
/branch [name]                         # Fork the current conversation (also /fork)
/rewind                                # Rewind conversation to a previous point (also /undo)
/compact [instructions]                # Compress context with optional focus
/exit                                  # Exit the CLI (also /quit)

## NAVIGATION & CONTEXT
/context                               # Visualize current context usage
/btw <question>                        # Side question without polluting context
/recap                                 # One-line summary of current session
/add-dir <path>                        # Add a working directory for this session
/diff                                  # Interactive diff viewer for uncommitted changes
/copy [N]                              # Copy last response to clipboard
/export [filename]                     # Export conversation as plain text

## MODEL & EXECUTION
/model [model]                         # Change the AI model
/effort [level|auto]                   # Set effort (low/medium/high/xhigh/max/auto)
/fast [on|off]                         # Toggle fast mode
/plan [description]                    # Enter plan mode

## CODE REVIEW
/review [PR]                           # Review a pull request locally
/ultrareview [PR]                      # Deep multi-agent code review in cloud sandbox
/security-review                       # Analyze pending changes for vulnerabilities
/simplify [focus]                      # Review changed files for quality issues and fix them

## PROJECT SETUP
/init                                  # Initialize project with CLAUDE.md
/memory                                # Edit CLAUDE.md memory files
/permissions                           # Manage tool allow/ask/deny rules (also /allowed-tools)
/hooks                                 # View hook configurations

## CONFIGURATION
/config                                # Open settings UI (also /settings)
/theme                                 # Change color theme
/color [color]                         # Set prompt bar color for this session
/terminal-setup                        # Configure terminal keybindings
/keybindings                           # Open keybindings config
/statusline                            # Configure status line UI
/tui [default|fullscreen]              # Set terminal renderer
/focus                                 # Toggle focus view (last prompt/response only)

## CLOUD & REMOTE
/autofix-pr [prompt]                   # Watch current PR and push fixes via cloud
/remote-control                        # Make session available from claude.ai (also /rc)
/remote-env                            # Configure default remote environment
/teleport                              # Pull a web session into this terminal (also /tp)
/ultraplan <prompt>                    # Draft plan in cloud, review in browser, execute

## ACCOUNT & AUTH
/login                                 # Sign in to Anthropic account
/logout                                # Sign out
/setup-bedrock                         # Configure Amazon Bedrock
/setup-vertex                          # Configure Google Vertex AI
/mcp                                   # Manage MCP server connections

## USAGE & DIAGNOSTICS
/cost                                  # Show token usage statistics
/usage                                 # Show plan limits and rate limit status
/doctor                                # Diagnose installation and settings
/status                                # Show version, model, account info
/heapdump                              # Heap snapshot for memory diagnostics
/tasks                                 # List and manage background tasks (also /bashes)

## INTEGRATIONS
/ide                                   # Manage IDE integrations
/chrome                                # Configure Claude in Chrome
/install-github-app                    # Set up Claude GitHub Actions app
/install-slack-app                     # Install Claude Slack app
/web-setup                             # Connect GitHub to Claude Code web
/desktop                               # Continue session in desktop app (also /app)

## SKILLS & PLUGINS
/skills                                # List available skills
/plugin                                # Manage plugins
/reload-plugins                        # Reload plugins without restarting
/agents                                # Manage agent configurations

## LEARNING & MISC
/help                                  # Show help and available commands
/powerup                               # Interactive feature lessons
/release-notes                         # View changelog
/feedback                              # Submit feedback (also /bug)
/insights                              # Analyze your Claude Code sessions
/stats                                 # Visualize usage, streaks, model preferences
/rename [name]                         # Rename current session
/mobile                                # QR code for mobile app (also /ios, /android)
/upgrade                               # Open plan upgrade page
/extra-usage                           # Configure extra usage for rate limits
/privacy-settings                      # View/update privacy settings
