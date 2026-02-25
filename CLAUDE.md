# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles managed with [Chezmoi](https://chezmoi.io) (file management/templating) and [Ansible](https://github.com/ansible/ansible) (system provisioning). The philosophy is **minimal customization** to stay productive on shared environments.

## Chezmoi file naming conventions

Chezmoi uses filename prefixes/suffixes to determine how files are handled:

- `dot_*` → becomes a dotfile (e.g., `dot_bashrc` → `~/.bashrc`)
- `run_once_*` → script run once on first apply
- `run_onchange_*` → script re-run whenever its content changes
- `*.tmpl` → processed as a Go template before applying
- `dot_bootstrap/` → becomes `~/.bootstrap/` (Ansible playbook location)

## Architecture

### Bootstrap flow

1. Chezmoi is initialized via `sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply $GITHUB_USERNAME`
2. `run_once_install_ansible.sh` installs Ansible (supports macOS/Debian/Fedora) and runs `~/.bootstrap/setup.yml`
3. `run_onchange_bootstrap.sh.tmpl` re-runs the Ansible playbook whenever `dot_bootstrap/setup.yml` changes (uses sha256 of the file in the script header as the change trigger)
4. `dot_bootstrap/setup.yml` is the Ansible playbook — currently installs packages and JetBrains Mono Nerd Font

### Template data

`.chezmoi.toml.tmpl` prompts for `name`, `email`, and `githubUser` on first run. These values are available in templates as `{{ .chezmoi.config.data.name }}` etc.

### Shell config

- `dot_shellrc` → shared POSIX-compatible config sourced by both `.bashrc` and `.zshrc`; sets `EDITOR`, `HISTSIZE`, PATH, and optional tool integrations (pyenv, nvm)
- `dot_bash_profile` → sources `~/.bashrc` for login shells
- `dot_bashrc` → sources `~/.shellrc`, adds bash-specific history settings and nvm bash completion
- `dot_zshrc` → sources `~/.shellrc`
- `dot_inputrc` → readline config (history search with arrows, case-insensitive completion)

When adding shell config that should apply to both bash and zsh, put it in `dot_shellrc` and keep it POSIX-compatible (no bash/zsh-specific syntax).

## Key commands

```bash
# Init (clones repo into ~/.local/share/chezmoi/ and applies)
chezmoi init --apply $GITHUB_USERNAME

# Init for non-standard local path (then add sourceDir to ~/.config/chezmoi/chezmoi.toml)
chezmoi init --apply --source /local/path/to/dotfiles

# Apply dotfiles from source dir
chezmoi apply

# See what changes would be made
chezmoi diff

# Edit a managed file (opens in $EDITOR, applies on save)
chezmoi edit ~/.bashrc

# Re-run a run_once script after changes
chezmoi state delete-bucket --bucket=scriptOnce && chezmoi apply

# Run Ansible playbook manually (add --ask-become-pass on Linux)
ansible-playbook ~/.bootstrap/setup.yml
```

## Notes

- `.chezmoiignore` excludes `CLAUDE.md`, `README.md`, `docs/`, and `.gitignore` from being deployed to the home directory