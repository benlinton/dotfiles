# CHEZMOI CHEATSHEET

# INIT
chezmoi init --apply <github-user>       # Clone repo and apply dotfiles
chezmoi init --apply --source <path>     # Use local source directory

# APPLYING
chezmoi apply                            # Apply source → home directory
chezmoi apply --dry-run                  # Preview without making changes
chezmoi diff                             # Show pending changes (like git diff)
chezmoi update                           # Pull latest changes and apply

# EDITING
chezmoi edit ~/.bashrc                   # Edit managed file (applies on save)
chezmoi edit-config                      # Edit chezmoi config
chezmoi cd                               # Open shell in source directory

# ADDING & SYNCING FILES
chezmoi add ~/.config/foo                # Track a new file (home → source)
chezmoi add --template ~/.gitconfig      # Track as Go template
chezmoi re-add ~/.bashrc                 # Sync edits made in home dir back to source
chezmoi forget ~/.config/foo             # Stop tracking file (keep deployed copy)

# INSPECTING
chezmoi status                           # Show files that differ from source
chezmoi managed                          # List all managed files
chezmoi unmanaged                        # List untracked files in home dir
chezmoi cat ~/.bashrc                    # Print what chezmoi would write

# SCRIPTS
# Re-run a run_once_ script after modifying it
chezmoi state delete-bucket --bucket=scriptOnce && chezmoi apply

# FILE NAMING CONVENTIONS
# dot_<name>                             # ~/.<name>  (dotfile)
# <name>.tmpl                            # processed as Go template before applying
# run_once_<name>                        # run once on first apply
# run_onchange_<name>                    # re-run when file content changes
# private_<name>                         # set mode 0600

# TEMPLATES
# {{ .chezmoi.config.data.name }}        # Name from chezmoi.toml
# {{ .chezmoi.config.data.githubUser }}  # GitHub username
# {{ .chezmoi.os }}                      # Operating system (linux, darwin)
# {{ .chezmoi.arch }}                    # Architecture (amd64, arm64)

# ANSIBLE PLAYBOOKS
ansible-playbook ~/.bootstrap/provision-workstation-macos.yml
ansible-playbook ~/.bootstrap/provision-workstation-linux.yml --ask-become-pass
