# MacOS Runbook

Install xcode.

    xcode-select --install

Install dotfiles.

    export GITHUB_USERNAME=benlinton
    sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply $GITHUB_USERNAME

This will also install `ansible`, `brew`, casks, fonts, applications, and more.

Create ssh key.

    ssh-keygen -t ed25519 -C "user@host"  # or email address

Add public key to [github](https://github.com/settings/keys).

After ssh key is added to github, edit this repo's git config to use ssh.

    sed -i '' 's|https://github.com/|git@github.com:|g' ~/.local/share/chezmoi/.git/config
    
