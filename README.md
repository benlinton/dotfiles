# Dotfiles

These are my versioned configuration files for vim, bash, git, screen, and etc.

## Install

#### Clone dotfiles

In terminal:

    git clone https://github.com/benlinton/dotfiles.git ~/.dotfiles

#### Install symlinks

    ~/.dotfiles/script/install-symlinks

#### Install template files

Some files require templates (instead of symlinks) because they contain sensitive data.

    ~/.dotfiles/script/gitconfig-global-update

#### Configure sensitive git settings

Update .gitconfig with your personal credentials:

    git config --global user.name "Firstname Lastname"
    git config --global user.email "your_email@example.com"
    git config --global github.user "your_github_username"
    git config --global github.token "1234567890abcdefghijklmnop"

## Uninstall

    ~/.dotfiles/script/uninstall-symlinks
    rm -rf ~/.dotfiles

## Environments

This repository attempts to support:

* OS X
* Linux (primarily Debian / CentOS)
* Unix
* Windows XP (using Cygwin; minimal support)

