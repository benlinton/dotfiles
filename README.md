# dotfiles

Utilizes [chezmoi](https://chezmoi.io) as the dotfile manager 
with [ansible](https://github.com/ansible/ansible) for provisioning.

## Setup

    export GITHUB_USERNAME=benlinton
    sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply $GITHUB_USERNAME

## Customization philosophy

Long ago, I would heavily customize my tools and environments for maximize efficiency. 
Over time I found that approach slowed me down while using shared environments.
As a result I now aim for minimal customization.
