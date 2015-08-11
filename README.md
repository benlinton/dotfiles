# Dotfiles

These are my versioned configuration files for bash, git, screen, and etc.


## Environments

This repository attempts to support:

* OS X
* Linux (primarily Debian / CentOS)
* Unix
* Windows XP (using Cygwin; minimal support)


## Architecture

#### Directory structure

* `bash/` - contains core bash files required to load bash
* `bin/` - executables available via $PATH
* `docs/` - help files, tutorials, cheatsheets, etc.
* `modules/` - config files grouped by library/feature/package
* `script/` - utility executables not available via $PATH (e.g. installers)


## File extension magic

#### `.bash.sh`

The `bash/bootstrap.sh` will find all files appended with `.bash.sh` and load
them using the built-in `source` command. The bootstrap loader will take
multiple passes:

1. first loading files ending in `.bash.first.sh`
2. then `.bash.sh`
3. and finally `.bash.last.sh`

During each pass, files will load in alphabetical order of directory name
followed by filename.

#### `.symlink`

Files or directories ending with `.symlink` will get automatically symlinked
into the `$HOME` directly when you run the dotfiles installer.

NOTE: The symlink source should not start with a dot, and the symlink installer
will automatically add a preceeding dot to the symlink destination for you. For
example, `~/.bashrc -> ~/.dotfiles/bash/bashrc.symlink`

#### `.template`

Files or directories ending with `.template` will get copied into the `$HOME`
directory when you run the dotfiles installer.

NOTE: This functionality is not fully supported yet.


## Bin commands

* `crashplan-remote` - helps start crashplan on a remote headless server
* `git-wtf` - displays state of your git repository
* `reload` - reloads the shell without exiting
* `slugify` - convert filenames into a web friendly format


## Install

#### Clone dotfiles

    git clone https://github.com/benlinton/dotfiles.git ~/.dotfiles

#### Install symlinks

Find dotfiles ending with `.symlink` and symlink in `$HOME`:

    ~/.dotfiles/script/symlinks-install

#### Install template files

Some files require templates (instead of symlinks) because they contain
sensitive data.

    ~/.dotfiles/script/gitconfig-restore

#### Configure sensitive git settings

Update `~/.gitconfig` with your secret credentials:

    git config --global user.name "Firstname Lastname"
    git config --global user.email "your_email@example.com"
    git config --global github.user "your_github_username"
    git config --global github.token "1234567890abcdefghijklmnop"

#### Run optional installers

    ~/.dotfiles/script/sublime-install
    ~/.dotfiles/script/iterm2-restore


## Uninstall

    ~/.dotfiles/script/symlinks-uninstall
    rm -rf ~/.dotfiles
