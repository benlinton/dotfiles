# dotfiles

Utilizes:
- [chezmoi](https://chezmoi.io) - as dotfile manager 
- [ansible](https://github.com/ansible/ansible) - for provisioning

Supports:
- Debian
- Fedora
- MacOS
- Windows (`wsl`)


## Philosophy

Long ago, I heavily customized my tools and environments for maximize efficiency. 
Over time I found that approach slowed me down on shared environments.
As a result I now aim for minimal customization across all tooling.
In addition, I generally prefer containers over local installs to maintain a more predictable, reproducible, and controlled environment.


## Quick start

Either use a [package manager](https://www.chezmoi.io/install) **(recommended)** or install  `chezmoi` natively.
```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
```

Apply dotfiles and run ansible.
```bash
export GITHUB_USERNAME=benlinton
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply $GITHUB_USERNAME
```
> For macOS, installs `brew` if missing.


## Useful commands

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

# View the current chezmoi state
chezmoi state dump

# Re-run a run_once script after changes
chezmoi state delete-bucket --bucket=scriptOnce && chezmoi apply

# Run Ansible playbook manually
ansible-playbook ~/.bootstrap/provision-workstation-macos.yml   # macOS
ansible-playbook ~/.bootstrap/provision-workstation-linux.yml --ask-become-pass  # Linux
```

## Playbook run scenarios

| Scenario | `run_once_*.sh` | `run_onchange_*.sh.tmpl` |
|----------|-----------------|--------------------------|
| Fresh machine (`init --apply`) | Runs (never ran before) | Runs (hash not in state) |
| Re-apply, playbook unchanged | Skipped | Skipped |
| Re-apply, playbook edited | Skipped | Runs (hash changed) |

> Important Pitfall: `install_ansible` needs to remain alphabetically ahead of `provision` runner.
