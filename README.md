# dotfiles

This project uses:
- [chezmoi](https://chezmoi.io) - as dotfile manager 
- [ansible](https://github.com/ansible/ansible) - for provisioning


## Philosophy

Long ago, I heavily customized my tools and environments for maximize efficiency. 
Over time I found that approach slowed me down on shared environments.
As a result I now aim for minimal customization.


## Quick start

For macOS first install `brew`.

```bash
export GITHUB_USERNAME=benlinton
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply $GITHUB_USERNAME
```


## Key commands

```bash
# Manually make changes and commits from here
cd ~/.local/share/chezmoi

# Recommended init approach - clones the repo into ~/.local/share/chezmoi/
chezmoi init --apply $GITHUB_USERNAME

# (Optional) Init for non-standard local path - then add sourceDir to the generated chezmoi.toml config
chezmoi init --apply --source /local/path/to/dotfiles

# Apply dotfiles from source dir
chezmoi apply

# See what changes would be made
chezmoi diff

# Edit a managed file (opens in $EDITOR, applies on save)
chezmoi edit ~/.bashrc

# Re-run a run_once script after changes
chezmoi state delete-bucket --bucket=scriptOnce && chezmoi apply

# Run Ansible playbook manually
ansible-playbook ~/.bootstrap/setup.yml --ask-become-pass
```
